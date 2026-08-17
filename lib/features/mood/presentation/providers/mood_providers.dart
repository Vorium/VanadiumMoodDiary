// v0.23 (Round 31) mood_providers — 情绪日记 voice 录入相关 provider
//
// 跟 vent_providers.dart (v0.17 round 14 拆出) 同模式:
// - audio storage / audio service 跟 mood 业务紧绑,放 core_providers 不合适
// - 单独文件避免 cross-feature 循环 import
//
// audio storage 跟 vent 的 storage 平行 (独立 mood_audio/ 目录),
// audio service 包装 record + speech_to_text 编排,page 用 ProviderScope
// override 注入 fake 实现做 widget test。

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/features/mood/data/services/mood_audio_service.dart';
import 'package:chroniccare/features/mood/data/services/mood_audio_storage.dart';

/// 情绪日记 audio 文件管理(独立 mood_audio/ 目录,跟 vent 隔离)
final moodAudioStorageProvider = Provider<MoodAudioStorage>(
  (ref) => MoodAudioStorage(),
);

/// v0.23 (Round 31) 情绪日记录音 + STT 编排 service
///
/// 抽 abstract + impl 是为 widget test:
/// ProviderScope.overrides 里塞 FakeMoodAudioService 就能完全不走
/// record / speech_to_text,纯 UI 流程测试。
final moodAudioServiceProvider = Provider<MoodAudioService>(
  (ref) => MoodAudioServiceImpl(
    storage: ref.watch(moodAudioStorageProvider),
  ),
);
