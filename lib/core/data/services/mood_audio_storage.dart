// v0.23 (Round 31) MoodAudioStorage — 情绪日记 audio 文件本地存储
//
// 仿 vent_audio_storage.dart (v0.18 round 14 P0-2 修后版本),独立 mood_audio/ 目录,
// 不复用 vent 的 storage,保持隐私边界清晰(以后就算做 mood↔vent 联动分析,
// 也好拆分)。
//
// **设计要点** (跟 vent 完全平行):
// - 文件存 app docs/mood_audio/ 目录
// - 录音 → 明文 m4a → encryptAndWrite 加密 → 写 .m4a.enc → 删明文
// - 播放前 → decryptToTemp → 写临时 m4a → audioplayer 播 → 播完清临时
// - 文件名: timestamp + 4 位 random suffix 避免同毫秒 race
// - 加密 key 在 EncryptionService 用 SecureStorage 存,绑设备
//
// **P0-2 fix 复用 vent 的教训**: 必须每个 storage 实例独立,不能跨隐私模块共享。
library;

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:chroniccare/core/data/services/encryption_service.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';

/// 情绪日记 audio 文件管理
///
/// 独立于 VentAudioStorage,各自的目录 + 各自的清理策略。
class MoodAudioStorage {
  static const _dirName = 'mood_audio';

  /// 加密文件后缀。DB 存的 audioPath 都是 .m4a.enc 格式
  static const encryptedSuffix = '.m4a.enc';

  /// 旧明文文件后缀 (迁移前存在, 跟 vent 一致)
  static const legacyPlainSuffix = '.m4a';

  /// 加密/解密服务注入(便于 test 替换)
  final EncryptionService _encryption;

  MoodAudioStorage({EncryptionService? encryption})
      : _encryption = encryption ?? EncryptionService();

  /// 取 audio 目录(不存在则创建)
  Future<Directory> _dir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, _dirName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 生成临时录音文件路径(明文, OS temp 目录)
  ///
  /// 跟 [newAudioPath] 一样加 4 位 random suffix,避免同毫秒录 2 段覆盖。
  Future<String> newTempRecordPath() async {
    final tempDir = Directory.systemTemp;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(10000).toString().padLeft(4, '0');
    return p.join(tempDir.path, 'mood_record_${ts}_$rand.m4a');
  }

  /// 生成新的加密 audio 文件路径(不创建文件)
  ///
  /// 路径格式: {app_docs}/mood_audio/mood_{timestamp_ms}_{rand4}.m4a.enc
  Future<String> newAudioPath() async {
    final dir = await _dir();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(10000).toString().padLeft(4, '0');
    final name = 'mood_${ts}_$rand$encryptedSuffix';
    return p.join(dir.path, name);
  }

  /// 加密明文 audio 并写到 [encryptedPath]
  ///
  /// 流程: 读 [plainPath] → 加密 → 写 [encryptedPath] → 删明文
  /// 任何一步失败都会抛错,已写的文件回滚(尽力)。
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
    // 删明文 (best-effort, 失败不抛)
    try {
      await plainFile.delete();
    } catch (e, st) {
      swallowError(
        where: 'mood_audio_storage.encryptAndWrite',
        error: e,
        stack: st,
        note: 'failed to delete plain after encrypt '
            '(security: still encrypted file exists, but plain may linger)',
      );
    }
  }

  /// 解密加密 audio 到临时文件, 返回临时路径
  ///
  /// 播放时调用: 解密到 temp 目录 → audioplayer 播 → 播完自己删
  Future<String> decryptToTemp(String encryptedPath) async {
    final encFile = File(encryptedPath);
    if (!await encFile.exists()) {
      throw FileSystemException('Encrypted audio not found', encryptedPath);
    }
    final blob = await encFile.readAsBytes();
    final plain = await _encryption.decrypt(Uint8List.fromList(blob));

    final tempDir = Directory.systemTemp;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(10000).toString().padLeft(4, '0');
    final tempPath = p.join(tempDir.path, 'mood_decrypt_${ts}_$rand.m4a');
    await File(tempPath).writeAsBytes(plain, flush: true);
    return tempPath;
  }

  /// 清理临时解密文件(播放完成调)
  Future<void> deleteTempFile(String tempPath) async {
    try {
      final f = File(tempPath);
      if (await f.exists()) {
        await f.delete();
      }
    } catch (e, st) {
      swallowError(
        where: 'mood_audio_storage.deleteTempFile',
        error: e,
        stack: st,
        note: 'temp file delete failed — OS will clean',
      );
    }
  }

  /// 删除单个 audio 文件
  ///
  /// 文件不存在视为成功 (idempotent)。
  Future<bool> deleteAudio(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) {
        await f.delete();
      }
      return true;
    } catch (e, st) {
      swallowError(
        where: 'mood_audio_storage.deleteAudio',
        error: e,
        stack: st,
        note: 'audio file delete failed',
      );
      return false;
    }
  }

  /// 清空所有 audio 文件(用于"清空所有数据"功能 / 隐私清除)
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
            where: 'mood_audio_storage.deleteAll',
            error: e,
            stack: st,
            note: 'skip un deletable file in batch clear',
          );
        }
      }
    }
    return count;
  }

  /// 单个 audio 文件大小(字节)
  Future<int> fileSizeBytes(String path) async {
    final f = File(path);
    if (!await f.exists()) return 0;
    return f.length();
  }

  /// audio 文件总大小(字节),用于统计 / 警告用户
  Future<int> totalSizeBytes() async {
    final dir = await _dir();
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list()) {
      if (entity is File) {
        try {
          total += await entity.length();
        } catch (e, st) {
          swallowError(
            where: 'mood_audio_storage.totalSizeBytes',
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
