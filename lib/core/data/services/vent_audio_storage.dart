/// 树洞加密音频存储 (extends EncryptedAudioStorage 基类, 跟 mood_audio shared)
///
/// **R126 续 step 6 (1.1.0+178)**: 实际定义已迁到
/// `lib/features/vent/data/services/vent_audio_storage.dart`。
/// 本文件 re-export 保持旧 import path 兼容 (现有用户 0 改动)。
///
/// **跨 feature 共享**: EncryptedAudioStorage 基类在 lib/core/data/privacy/,
/// 跟 mood audio storage 共享. R128 阶段 4 抽 core/platform/ umbrella 处理.
library;

export 'package:chroniccare/features/vent/data/services/vent_audio_storage.dart';
