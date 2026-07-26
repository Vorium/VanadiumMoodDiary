// v0.23 (Round 43 spen-2): 抽 EncryptedAudioStorage 基类
//
// 之前 VentAudioStorage (v0.18 round 14 P0-2) 跟 MoodAudioStorage (v0.23 round 31)
// 各 184 / 215 行,99% 同构 (AES-256 加密 + 4 位 random suffix + temp 清理)。
// 抽到 EncryptedAudioStorage 基类,两个子类只剩:
//
// - 自己的 directory 名 (vent_audio / mood_audio)
// - 自己的 file naming prefix (vent_ / mood_)
// - 自己的 debug tag (用于 swallowError 定位)
//
// 抽基类的额外收益:
// 1. vent 跟 mood 的 encryptAndWrite 同款 bug (写 enc 成功但删明文失败) 修法统一
// 2. 新增 audio privacy feature 不用再 copy-paste ~150 行
// 3. 1 个地方修 bug 2 个 storage 都受益
//
// **关键约束**: 子类**不能**覆盖 `encryptAndWrite` / `decryptToTemp` (sealed contract)。
// 任何改这俩方法的尝试都该走 PR review, 避免 reintroduce round 22 / spen-5 PII 残留。
//
// **隐私边界 (重要)**: 树洞 vent 跟 情绪 mood 是 2 个独立 privacy 模块,
// 不复用同一个 EncryptionService 实例的 filesystem key 命名空间 (实际上
// EncryptionService 共享 32-byte key, 但 path 目录分开 = 加密文件不跨目录混读)。
library;

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:chroniccare/core/data/services/encryption_service.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';

/// v0.23 (Round 43 spen-2): 加密 audio 文件管理基类
///
/// 抽 vent_audio_storage (v0.18 round 14 P0-2) 跟 mood_audio_storage
/// (v0.23 round 31) 的 99% 同构部分,具体差异 (目录名 / 文件名前缀) 由子类
/// override 4 个 getter 提供。
///
/// **典型用法** (子类):
/// ```dart
/// class VentAudioStorage extends EncryptedAudioStorage {
///   VentAudioStorage({super.encryption});
///   @override String get dirName => 'vent_audio';
///   @override String get filePrefix => 'vent_';
///   @override String get tempRecordPrefix => 'vent_record_';
///   @override String get decryptPrefix => 'vent_decrypt_';
///   @override String get debugTag => 'vent_audio_storage';
/// }
/// ```
///
/// **测试模式**: 走 [EncryptionService.setKeyForTest] 注入固定 key
/// (避免 SecureStorage platform channel 不可用),然后用真 temp dir 测
/// encryptAndWrite / decryptToTemp round-trip。
abstract class EncryptedAudioStorage {
  /// 加密文件后缀。所有 DB 存的 audioPath 都是 .m4a.enc 格式
  static const String encryptedSuffix = '.m4a.enc';

  /// 旧明文文件后缀 (迁移前存在, vent 跟 mood 通用)
  static const String legacyPlainSuffix = '.m4a';

  /// 加密/解密服务注入(便于 test 替换)
  final EncryptionService _encryption;

  EncryptedAudioStorage({EncryptionService? encryption})
      : _encryption = encryption ?? EncryptionService();

  // ============================================================
  // 子类必须 override 的 metadata getter
  // ============================================================

  /// 子目录名 (app docs 下)。如 'vent_audio' / 'mood_audio'
  String get dirName;

  /// 加密文件名前缀。如 'vent_' / 'mood_'
  ///
  /// 生成路径格式: `{app_docs}/{dirName}/{filePrefix}{ts}_{rand4}.m4a.enc`
  String get filePrefix;

  /// 临时录音文件名前缀 (在 OS temp dir)。
  ///
  /// 生成路径格式: `{os_temp}/{tempRecordPrefix}{ts}_{rand4}.m4a`
  String get tempRecordPrefix;

  /// 临时解密文件名前缀 (在 OS temp dir)。
  ///
  /// 生成路径格式: `{os_temp}/{decryptPrefix}{ts}_{rand4}.m4a`
  String get decryptPrefix;

  /// Debug tag,用于 swallowError 的 `where:` 字段。
  /// 子类提供以便日志定位 (e.g. 'vent_audio_storage' / 'mood_audio_storage')
  String get debugTag;

  // ============================================================
  // 共享 API
  // ============================================================

  /// 取 audio 目录(不存在则创建)
  Future<Directory> getDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, dirName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 生成新的加密 audio 文件路径(不创建文件)
  ///
  /// 路径格式: `{app_docs}/{dirName}/{filePrefix}{ts}_{rand4}.m4a.enc`
  ///
  /// v0.16 round 19 fix: 之前只用 millisecondsSinceEpoch,同毫秒内录 2 段
  ///   会文件名相同 → 后录的覆盖前录的。 加 4 位 random suffix 避免冲突
  Future<String> newAudioPath() async {
    final dir = await getDir();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(10000).toString().padLeft(4, '0');
    final name = '$filePrefix${ts}_$rand$encryptedSuffix';
    return p.join(dir.path, name);
  }

  /// 生成临时录音文件路径(明文, 在 OS temp 目录)
  ///
  /// 跟 [newAudioPath] 一样加 4 位 random suffix,避免同毫秒录 2 段覆盖。
  Future<String> newTempRecordPath() async {
    final tempDir = Directory.systemTemp;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(10000).toString().padLeft(4, '0');
    return p.join(tempDir.path, '$tempRecordPrefix${ts}_$rand.m4a');
  }

  /// 加密明文 audio 并写到 [encryptedPath]
  ///
  /// 流程: 读 plainPath → 加密 → 写 encryptedPath → 删明文
  ///
  /// **安全保证 (v0.22 round 22 P1 + v0.23 round 43 spen-5)**:
  /// 任何一步失败会抛错,**已写的加密文件 + 残留明文都会清理 (try/finally 兜底)**。
  /// 防止"加密文件存在 + 明文也残留"双写 → PII 泄漏。
  ///
  /// 调用方传 recorder.stop() 返回的明文路径 + newAudioPath() 生成的加密路径。
  Future<void> encryptAndWrite({
    required String plainPath,
    required String encryptedPath,
  }) async {
    final plainFile = File(plainPath);
    final encFile = File(encryptedPath);
    var writeSucceeded = false;

    try {
      if (!await plainFile.exists()) {
        throw FileSystemException('Plain audio not found', plainPath);
      }
      final bytes = await plainFile.readAsBytes();
      final encrypted = await _encryption.encrypt(Uint8List.fromList(bytes));
      await encFile.writeAsBytes(encrypted, flush: true);
      writeSucceeded = true;
    } finally {
      // v0.23 round 43 (spen-5): try/finally 兜底 — 写加密文件失败时
      // 也要删明文,否则 PII 残留(精神心理患者隐私 = 最高敏感度)。
      // 之前 (vent round 22 P1 同款 bug) `writeAsBytes` 抛错时
      // 后续 `plainFile.delete()` 不跑,明文 audio 永远留在磁盘。
      if (!writeSucceeded) {
        try {
          if (await plainFile.exists()) {
            await plainFile.delete();
          }
        } catch (cleanupErr, cleanupSt) {
          swallowError(
            where: '$debugTag.encryptAndWrite',
            error: cleanupErr,
            stack: cleanupSt,
            note: 'cleanup: failed to delete plain after encrypt error — '
                'PII may linger, requires manual intervention',
          );
        }
      }
    }

    // 成功路径: 删明文 (best-effort, 失败不抛 — 加密文件已存在, 至少保护到位)
    try {
      await plainFile.delete();
    } catch (e, st) {
      swallowError(
        where: '$debugTag.encryptAndWrite',
        error: e,
        stack: st,
        note: 'failed to delete plain after encrypt '
            '(security: encrypted file exists, but plain may linger)',
      );
    }
  }

  /// 解密加密 audio 到临时文件, 返回临时路径
  ///
  /// 播放时调用: 解密到 temp 目录 → audioplayer 播 → 播完自己删
  ///
  /// 临时文件命名: `{decryptPrefix}{ts}_{rand4}.m4a`
  Future<String> decryptToTemp(String encryptedPath) async {
    final encFile = File(encryptedPath);
    if (!await encFile.exists()) {
      throw FileSystemException('Encrypted audio not found', encryptedPath);
    }
    final blob = await encFile.readAsBytes();
    final plain = await _encryption.decrypt(Uint8List.fromList(blob));

    // 写临时文件 (操作系统 temp 目录, App 退出后自动清)
    final tempDir = Directory.systemTemp;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(10000).toString().padLeft(4, '0');
    final tempPath = p.join(tempDir.path, '${decryptPrefix}${ts}_$rand.m4a');
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
        where: '$debugTag.deleteTempFile',
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
        where: '$debugTag.deleteAudio',
        error: e,
        stack: st,
        note: 'audio file delete failed',
      );
      return false;
    }
  }

  /// 清空所有 audio 文件(用于"清空所有数据"功能 / 隐私清除)
  Future<int> deleteAll() async {
    final dir = await getDir();
    if (!await dir.exists()) return 0;
    var count = 0;
    await for (final entity in dir.list()) {
      if (entity is File) {
        try {
          await entity.delete();
          count++;
        } catch (e, st) {
          swallowError(
            where: '$debugTag.deleteAll',
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
    final dir = await getDir();
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list()) {
      if (entity is File) {
        try {
          total += await entity.length();
        } catch (e, st) {
          // 单文件 stat 失败 → 跳过这个文件, 继续累加其它
          // v0.17 round 14 (P1-5): 之前静默, 现在 dev 模式可见
          swallowError(
            where: '$debugTag.totalSizeBytes',
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
