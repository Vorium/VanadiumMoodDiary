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
//
// **v0.23 (Round 43 spen-2)**: 99% 同构的 encrypt/decrypt/file 管理抽到
// [EncryptedAudioStorage] 基类,本文件只剩 mood-specific 配置 (目录名 + 前缀)。

import 'package:chroniccare/core/data/privacy/encrypted_audio_storage.dart';

export 'package:chroniccare/core/data/privacy/encrypted_audio_storage.dart'
    show EncryptedAudioStorage;

/// 情绪日记 audio 文件管理
///
/// 独立于 VentAudioStorage,各自的目录 + 各自的清理策略。
/// 大部分 file 管理逻辑在 [EncryptedAudioStorage] 基类。
class MoodAudioStorage extends EncryptedAudioStorage {
  static const _dirName = 'mood_audio';

  /// 临时录音文件名前缀 (明文, OS temp dir)
  static const _tempRecordPrefix = 'mood_record_';

  /// 临时解密文件名前缀 (OS temp dir)
  static const _decryptPrefix = 'mood_decrypt_';

  /// 加密文件名前缀
  static const _filePrefix = 'mood_';

  /// 加密文件后缀。DB 存的 audioPath 都是 .m4a.enc 格式
  ///
  /// 向后兼容: 老代码引用 `MoodAudioStorage.encryptedSuffix`,现指向
  /// 基类常量。
  static const String encryptedSuffix = EncryptedAudioStorage.encryptedSuffix;

  /// 旧明文文件后缀 (迁移前存在, 跟 vent 一致)
  static const String legacyPlainSuffix =
      EncryptedAudioStorage.legacyPlainSuffix;

  MoodAudioStorage({super.encryption});

  @override
  String get dirName => _dirName;

  @override
  String get filePrefix => _filePrefix;

  @override
  String get tempRecordPrefix => _tempRecordPrefix;

  @override
  String get decryptPrefix => _decryptPrefix;

  @override
  String get debugTag => 'mood_audio_storage';
}
