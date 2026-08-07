// v0.15 (Round 18) VentAudioStorage — 树洞 audio 文件本地存储
//
// 文件存 app docs 目录(v0.7 data_export_service 已有类似模式),
// 路径通过 `path_provider` 拿。
//
// **P0-2 fix (v0.18 round 14)**: 音频文件之前完全明文,设备 root 后能直接
// 读出所有树洞录音。现在所有写入都走 [EncryptionService] 加密:
//
//   录音完 → 拿到明文 m4a → encryptAndWrite 加密 → 写 .m4a.enc → 删明文
//   播放前 → decryptToTemp 解密 → 写临时 m4a → audioplayer 播 → 播完清临时
//
// 文件后缀从 .m4a 改 .m4a.enc,DB 存的路径也跟着改。
// 迁移策略(详见 settings_page "音频加密迁移"按钮): 用户主动触发,扫描
// 旧 .m4a 文件逐个加密 in-place (rename + 写 .enc),删明文。
//
// 隐私边界: 加密 key 在 [EncryptionService] 用 SecureStorage 存,绑设备。
//
// **v0.23 (Round 43 spen-2)**: 99% 同构的 encrypt/decrypt/file 管理抽到
// [EncryptedAudioStorage] 基类,本文件只剩 vent-specific 逻辑:
// - deleteAllWithRetry (重试 3 次, sp-en P0 round 33)
// - purgeOrphanPlainFiles (启动时清孤儿 .m4a, sp-en P0 round 33)

import 'dart:io';

import 'package:chroniccare/core/data/database/app_database.dart' show AppDatabase;
import 'package:path/path.dart' as p;

import 'package:chroniccare/core/data/privacy/encrypted_audio_storage.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';

export 'package:chroniccare/core/data/privacy/encrypted_audio_storage.dart'
    show EncryptedAudioStorage;

/// 树洞 audio 文件管理
///
/// 独立于 MoodAudioStorage,各自的目录 + 各自的清理策略。
/// 大部分 file 管理逻辑在 [EncryptedAudioStorage] 基类。
class VentAudioStorage extends EncryptedAudioStorage {
  static const _dirName = 'vent_audio';

  /// v0.21 (P1-3 fix): vent_record_ 临时录音文件名前缀 (明文, OS temp dir)
  static const _tempRecordPrefix = 'vent_record_';

  /// v0.18 round 14 P0-2: vent_decrypt_ 临时解密文件名前缀 (OS temp dir)
  static const _decryptPrefix = 'vent_decrypt_';

  /// v0.18 round 14 P0-2: vent_ 加密文件名前缀
  static const _filePrefix = 'vent_';

  /// P0-2: 加密文件后缀。DB 存的 audioPath 都是 .m4a.enc 格式
  ///
  /// 向后兼容: 老代码引用 `VentAudioStorage.encryptedSuffix`,现指向
  /// 基类常量。
  static const String encryptedSuffix = EncryptedAudioStorage.encryptedSuffix;

  /// P0-2: 旧明文文件后缀 (迁移前存在)
  static const String legacyPlainSuffix =
      EncryptedAudioStorage.legacyPlainSuffix;

  VentAudioStorage({super.encryption});

  @override
  String get dirName => _dirName;

  @override
  String get filePrefix => _filePrefix;

  @override
  String get tempRecordPrefix => _tempRecordPrefix;

  @override
  String get decryptPrefix => _decryptPrefix;

  @override
  String get debugTag => 'vent_audio_storage';

  /// v0.22 round 33 (sp-en P0): 删所有音频文件,**重试 3 次**。
  ///
  /// 跟 [AppDatabase.clearAllUserData] 配对(settings_page 清空数据流程):
  /// DB 事务提交后 audio 文件删除失败 = vent 录音残留(sp-en 标 P0 风险)。
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
  /// v0.18 round 14 P0-2 修后所有录音都走加密(.m4a.enc),但**用户没触发
  /// "音频加密迁移"按钮的**,旧 .m4a 仍可能在磁盘上(纯垃圾,DB 已经指向 .m4a.enc)。
  /// 隐私风险:老明文树洞录音残留。
  ///
  /// 启动时扫一遍,删任何没有对应 .m4a.enc 的 .m4a 文件(孤儿)。
  /// 调用方: AppRoot 启动时调 1 次。
  Future<int> purgeOrphanPlainFiles() async {
    final dir = await getDir();
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

  /// 临时目录路径(录音明文写入目标)
  Future<String> getTempDirPath() async => Directory.systemTemp.path;
}
