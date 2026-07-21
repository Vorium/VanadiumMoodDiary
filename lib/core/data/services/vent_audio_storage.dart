// v0.15 (Round 18) VentAudioStorage — 树洞 audio 文件本地存储
//
// 文件存 app docs 目录（v0.7 data_export_service 已有类似模式），
// 路径通过 `path_provider` 拿。
//
// **P0-2 fix (v0.18 round 14)**: 音频文件之前完全明文，设备 root 后能直接
// 读出所有树洞录音。现在所有写入都走 [EncryptionService] 加密:
//
//   录音完 → 拿到明文 m4a → encryptAndWrite 加密 → 写 .m4a.enc → 删明文
//   播放前 → decryptToTemp 解密 → 写临时 m4a → audioplayer 播 → 播完清临时
//
// 文件后缀从 .m4a 改 .m4a.enc,DB 存的路径也跟着改。
// 迁移策略(详见 settings_page "音频加密迁移"按钮): 用户主动触发，扫描
// 旧 .m4a 文件逐个加密 in-place (rename + 写 .enc),删明文。
//
// 隐私边界: 加密 key 在 [EncryptionService] 用 SecureStorage 存，绑设备。
library;

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:chroniccare/core/data/services/encryption_service.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';

/// 树洞 audio 文件管理
class VentAudioStorage {
  static const _dirName = 'vent_audio';

  /// P0-2: 加密文件后缀。DB 存的 audioPath 都是 .m4a.enc 格式
  static const encryptedSuffix = '.m4a.enc';

  /// P0-2: 旧明文文件后缀 (迁移前存在)
  static const legacyPlainSuffix = '.m4a';

  /// P0-2: 加密/解密服务注入(便于 test 替换)
  final EncryptionService _encryption;

  VentAudioStorage({EncryptionService? encryption})
      : _encryption = encryption ?? EncryptionService();

  /// 取 audio 目录（不存在则创建）
  Future<Directory> _dir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, _dirName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// v0.21 (P1-3 fix): 生成临时录音文件路径（明文，在 OS temp 目录）
  ///
  /// **bug 现象**: 之前 `vent_compose_page.dart:141` 临时文件路径用
  /// `vent_record_${DateTime.now().millisecondsSinceEpoch}.m4a`,
  /// 同毫秒内录 2 段 → 文件名相同 → 后录的覆盖前录的（数据丢失）。
  ///
  /// **修法**: 跟 [newAudioPath] / [decryptToTemp] 一样加 4 位 random suffix
  /// `vent_record_{ts}_{rand4}.m4a`。helper 集中避免各处漂移。
  Future<String> newTempRecordPath() async {
    final tempDir = await getTempDirPath();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(10000).toString().padLeft(4, '0');
    return p.join(tempDir, 'vent_record_${ts}_$rand.m4a');
  }

  /// 生成新的加密 audio 文件路径（不创建文件）
  ///
  /// 路径格式：{app_docs}/vent_audio/vent_{timestamp_ms}_{rand4}.m4a.enc
  ///
  /// v0.16 round 19 fix: 之前只用 millisecondsSinceEpoch,同毫秒内录 2 段
  ///   会文件名相同 → 后录的覆盖前录的。 加 4 位 random suffix 避免冲突
  Future<String> newAudioPath() async {
    final dir = await _dir();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(10000).toString().padLeft(4, '0');
    final name = 'vent_${ts}_$rand$encryptedSuffix';
    return p.join(dir.path, name);
  }

  /// P0-2: 加密明文 audio 并写到 [encryptedPath]
  ///
  /// 流程: 读 [plainPath] → 加密 → 写 [encryptedPath] → 删明文
  ///
  /// 调用方传 recorder.stop() 返回的明文路径 + newAudioPath() 生成的加密路径。
  /// 任何一步失败都会抛错，已写的文件回滚(尽力)。
  Future<void> encryptAndWrite({
    required String plainPath,
    required String encryptedPath,
  }) async {
    final plainFile = File(plainPath);
    final encFile = File(encryptedPath);

    if (!await plainFile.exists()) {
      throw FileSystemException('Plain audio not found', plainPath);
    }
    final bytes = await plainFile.readAsBytes();
    final encrypted = await _encryption.encrypt(Uint8List.fromList(bytes));
    await encFile.writeAsBytes(encrypted, flush: true);
    // 删明文 (best-effort,失败不抛)
    try {
      await plainFile.delete();
    } catch (e, st) {
      swallowError(
        where: 'vent_audio_storage.encryptAndWrite',
        error: e,
        stack: st,
        note:
            'failed to delete plain after encrypt (security: still encrypted file exists, but plain may linger)',
      );
    }
  }

  /// P0-2: 解密加密 audio 到临时文件，返回临时路径
  ///
  /// 播放时调用: 解密到 temp 目录 → audioplayer 播 → 播完自己删
  /// 临时文件命名: `vent_decrypt_{ts}_{rand}.m4a`
  Future<String> decryptToTemp(String encryptedPath) async {
    final encFile = File(encryptedPath);
    if (!await encFile.exists()) {
      throw FileSystemException('Encrypted audio not found', encryptedPath);
    }
    final blob = await encFile.readAsBytes();
    final plain = await _encryption.decrypt(Uint8List.fromList(blob));

    // 写临时文件 (操作系统 temp 目录,App 退出后自动清)
    final tempDir = Directory.systemTemp;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(10000).toString().padLeft(4, '0');
    final tempPath = p.join(tempDir.path, 'vent_decrypt_${ts}_$rand.m4a');
    await File(tempPath).writeAsBytes(plain, flush: true);
    return tempPath;
  }

  /// 清理临时解密文件 (播放完成调)
  Future<void> deleteTempFile(String tempPath) async {
    try {
      final f = File(tempPath);
      if (await f.exists()) {
        await f.delete();
      }
    } catch (e, st) {
      swallowError(
        where: 'vent_audio_storage.deleteTempFile',
        error: e,
        stack: st,
        note: 'temp file delete failed — OS will clean',
      );
    }
  }

  /// 删除单个 audio 文件
  ///
  /// 文件不存在视为成功（idempotent）。
  Future<bool> deleteAudio(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) {
        await f.delete();
      }
      return true;
    } catch (e, st) {
      swallowError(
        where: 'vent_audio_storage.deleteAudio',
        error: e,
        stack: st,
        note: 'audio file delete failed',
      );
      return false;
    }
  }

  /// 清空所有 audio 文件（用于"清空树洞"功能 / 隐私清除）
  Future<int> deleteAll() async {
    final dir = await _dir();
    if (!await dir.exists()) return 0;
    var count = 0;
    await for (final entity in dir.list()) {
      if (entity is File) {
        try {
          await entity.delete();
          count++;
        } catch (e, st) {
          swallowError(
            where: 'vent_audio_storage.deleteAll',
            error: e,
            stack: st,
            note: 'skip un deletable file in batch clear',
          );
        }
      }
    }
    return count;
  }

  /// v0.22 round 33 (sp-en P0): 删所有音频文件,**重试 3 次**。
  ///
  /// 跟 [AppDatabase.clearAllUserData] 配对（settings_page 清空数据流程）:
  /// DB 事务提交后 audio 文件删除失败 = vent 录音残留（sp-en 标 P0 风险）。
  /// DB 和 FS 是 2 个独立子系统,无法强一致。重试 + swallow 把残留概率压到最低。
  ///
  /// 返回最终成功的删除数。调用方拿到 0 应当提示用户"部分残留"。
  Future<int> deleteAllWithRetry() async {
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        return await deleteAll();
      } catch (e, st) {
        swallowError(
          where: 'vent_audio_storage.deleteAllWithRetry',
          error: e,
          stack: st,
          note: 'attempt $attempt failed, retrying',
        );
        if (attempt < 3) {
          await Future<void>.delayed(Duration(milliseconds: 100 * attempt));
        }
      }
    }
    return 0; // 3 次都失败
  }

  /// v0.22 round 33 (sp-en P0): 清理孤儿旧明文 .m4a 文件。
  ///
  /// v0.18 round 14 P0-2 修后所有录音都走加密 (.m4a.enc),但**用户没触发
  /// "音频加密迁移"按钮的**,旧 .m4a 仍可能在磁盘上(纯垃圾,DB 已经指向 .m4a.enc)。
  /// 隐私风险:老明文树洞录音残留。
  ///
  /// 启动时扫一遍,删任何没有对应 .m4a.enc 的 .m4a 文件(孤儿)。
  /// 调用方: AppRoot 启动时调 1 次。
  Future<int> purgeOrphanPlainFiles() async {
    final dir = await _dir();
    if (!await dir.exists()) return 0;
    var purged = 0;
    final encNames = <String>{};
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith(encryptedSuffix)) {
        encNames.add(
          p.basenameWithoutExtension(
            p.basenameWithoutExtension(entity.path),
          ),
        );
      }
    }
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith(legacyPlainSuffix)) {
        final base = p.basenameWithoutExtension(entity.path);
        if (!encNames.contains(base)) {
          try {
            await entity.delete();
            purged++;
          } catch (e, st) {
            swallowError(
              where: 'vent_audio_storage.purgeOrphanPlainFiles',
              error: e,
              stack: st,
              note: 'orphan plain delete failed',
            );
          }
        }
      }
    }
    return purged;
  }

  /// 临时目录路径（录音明文写入目标）
  Future<String> getTempDirPath() async => Directory.systemTemp.path;

  /// 单个 audio 文件大小（字节）
  Future<int> fileSizeBytes(String path) async {
    final f = File(path);
    if (!await f.exists()) return 0;
    return f.length();
  }

  /// audio 文件总大小（字节），用于统计 / 警告用户
  Future<int> totalSizeBytes() async {
    final dir = await _dir();
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list()) {
      if (entity is File) {
        try {
          total += await entity.length();
        } catch (e, st) {
          // 单文件 stat 失败 → 跳过这个文件，继续累加其它
          // v0.17 round 14 (P1-5): 之前静默，现在 dev 模式可见
          swallowError(
            where: 'vent_audio_storage.totalSizeBytes',
            error: e,
            stack: st,
            note: 'failed to stat audio file, skipping',
          );
        }
      }
    }
    return total;
  }
}
