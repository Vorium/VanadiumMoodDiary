/// 情绪日记加密音频存储 (extends EncryptedAudioStorage 基类, 跟 vent audio shared)
///
/// **R126 续 step 5 (1.1.0+177)**: 实际定义已迁到
/// `lib/features/mood/data/services/mood_audio_storage.dart`。
/// 本文件 re-export 保持旧 import path 兼容 (现有用户 0 改动)。
///
/// **跨 feature 共享**: EncryptedAudioStorage 基类在 lib/core/data/privacy/,
/// 跟 vent audio storage 共享. R128 阶段 4 抽 core/platform/ umbrella 处理.
library;

export 'package:chroniccare/features/mood/data/services/mood_audio_storage.dart';
