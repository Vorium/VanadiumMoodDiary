// v0.30 round 91 (sub-spec 7 日常追踪 / Task 4 UI): 6 子功能 provider
//
// 4 层架构: presentation/providers/ 跨 feature 共享, 0 跨 page/ 引用。
// 跟 assessment_providers.dart / vent_providers.dart 同模式。
//
// 不开 domain 抽象接口 (跟 assessment_providers 1:1): R91 6 repo 直接
// 由 data 层 impl 提供, UI 直接用 impl type 注册。后续 v0.31+ 真要换 impl
// (e.g. cache layer / sync) 时, 再加 abstract interface 跟 R16 R60 模式。
//
// 6 个 StreamProvider.autoDispose (跟 ventEntriesProvider 同款):
// - 离开 daily_tracking_page 时 stream subscription 自动取消
// - 重新进入 re-fetch 一次性重订阅
// - 跟 R17 round 8 ventEntriesProvider C5 决策一致 (隐私边界 + 省资源)
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/data/repositories/daily_tracking/anxiety_agitation_repository_impl.dart';
import 'package:chroniccare/core/data/repositories/daily_tracking/sleep_repository_impl.dart';
import 'package:chroniccare/core/data/repositories/daily_tracking/social_rhythm_repository_impl.dart';
import 'package:chroniccare/core/data/repositories/daily_tracking/stress_event_repository_impl.dart';
import 'package:chroniccare/core/data/repositories/daily_tracking/weight_repository_impl.dart';
import 'package:chroniccare/domain/entities/anxiety_agitation_entry.dart';
import 'package:chroniccare/domain/entities/sleep_entry.dart';
import 'package:chroniccare/domain/entities/social_rhythm_entry.dart';
import 'package:chroniccare/domain/entities/stress_event.dart';
import 'package:chroniccare/domain/entities/weight_entry.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';

// ============== 6 仓库 provider (跟 core_providers 7 repo 同模式) ==============

/// 睡眠仓库
final sleepRepositoryProvider = Provider<SleepRepositoryImpl>(
  (ref) => SleepRepositoryImpl(ref.watch(databaseProvider)),
);

/// 社会节律仓库
final socialRhythmRepositoryProvider = Provider<SocialRhythmRepositoryImpl>(
  (ref) => SocialRhythmRepositoryImpl(ref.watch(databaseProvider)),
);

/// 应激源仓库
final stressEventRepositoryProvider = Provider<StressEventRepositoryImpl>(
  (ref) => StressEventRepositoryImpl(ref.watch(databaseProvider)),
);

/// 体重仓库
final weightRepositoryProvider = Provider<WeightRepositoryImpl>(
  (ref) => WeightRepositoryImpl(ref.watch(databaseProvider)),
);

/// 焦虑急躁仓库
final anxietyAgitationRepositoryProvider =
    Provider<AnxietyAgitationRepositoryImpl>(
  (ref) => AnxietyAgitationRepositoryImpl(ref.watch(databaseProvider)),
);

// ============== 6 仓库 stream provider (UI 监听用, autoDispose) ==============

/// 睡眠条目流 (按 date DESC 倒序, DAO 排好)
final sleepEntriesProvider =
    StreamProvider.autoDispose<List<SleepEntryEntity>>(
  (ref) => ref.watch(sleepRepositoryProvider).watchAll(),
);

/// 社会节律条目流
final socialRhythmEntriesProvider =
    StreamProvider.autoDispose<List<SocialRhythmEntryEntity>>(
  (ref) => ref.watch(socialRhythmRepositoryProvider).watchAll(),
);

/// 应激源条目流
final stressEventEntriesProvider =
    StreamProvider.autoDispose<List<StressEventEntity>>(
  (ref) => ref.watch(stressEventRepositoryProvider).watchAll(),
);

/// 体重条目流
final weightEntriesProvider =
    StreamProvider.autoDispose<List<WeightEntryEntity>>(
  (ref) => ref.watch(weightRepositoryProvider).watchAll(),
);

/// 焦虑急躁条目流
final anxietyAgitationEntriesProvider =
    StreamProvider.autoDispose<List<AnxietyAgitationEntryEntity>>(
  (ref) => ref.watch(anxietyAgitationRepositoryProvider).watchAll(),
);
