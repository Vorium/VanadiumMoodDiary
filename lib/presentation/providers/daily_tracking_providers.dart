// v0.30 round 91 (sub-spec 7 日常追踪 / Task 4 + 5 UI): 6 子功能 provider
//
// 4 层架构: presentation/providers/ 跨 feature 共享, 0 跨 page/ 引用。
// 跟 assessment_providers.dart / vent_providers.dart 同模式。
//
// R97-P1-1 (2026-08-07): 修复 4 层架构违规。
// 修前: 6 provider 暴露 `*RepositoryImpl` (data 层 impl type), 违反
// AGENTS.md "presentation provider 用 Provider<X>(...) 暴露 XRepository
// (domain 接口), 不暴露 impl" 硬约束。
// 修后: 6 provider 改 `Provider<XRepository>`, impl 类 `implements XRepository`。
// 后续 v0.31+ 真要换 impl (e.g. cache layer / sync) 时, 直接换 provider 内
// new 的 impl class 即可, UI 无感知 (跟 mood / vent 同款 R16 R60 模式)。
//
// 6 个 StreamProvider.autoDispose (跟 ventEntriesProvider 同款):
// - 离开 daily_tracking_page 时 stream subscription 自动取消
// - 重新进入 re-fetch 一次性重订阅
// - 跟 R17 round 8 ventEntriesProvider C5 决策一致 (隐私边界 + 省资源)
//
// v0.30 R91 Task 5 整合入口: 加 6 个 latestXxxEntryProvider (StreamProvider
// 派生 from entries provider, 整合入口页显示"上次记录"用)。Repository 仍
// 走 Task 4 的 5 个 (sleep/social_rhythm/stress/weight/anxiety), Task 5
// 补 treatmentRepositoryProvider (Task 3 落了 provider, R91 整合页需要
// 拿 latest treatment 显示)。
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/data/repositories/daily_tracking/anxiety_agitation_repository_impl.dart';
import 'package:chroniccare/core/data/repositories/daily_tracking/sleep_repository_impl.dart';
import 'package:chroniccare/core/data/repositories/daily_tracking/social_rhythm_repository_impl.dart';
import 'package:chroniccare/core/data/repositories/daily_tracking/stress_event_repository_impl.dart';
import 'package:chroniccare/core/data/repositories/daily_tracking/treatment_repository_impl.dart';
import 'package:chroniccare/core/data/repositories/daily_tracking/weight_repository_impl.dart';
import 'package:chroniccare/domain/entities/anxiety_agitation_entry.dart';
import 'package:chroniccare/domain/entities/sleep_entry.dart';
import 'package:chroniccare/domain/entities/social_rhythm_entry.dart';
import 'package:chroniccare/domain/entities/stress_event.dart';
import 'package:chroniccare/domain/entities/treatment_entry.dart';
import 'package:chroniccare/domain/entities/weight_entry.dart';
import 'package:chroniccare/domain/repositories/anxiety_agitation_repository.dart';
import 'package:chroniccare/domain/repositories/sleep_repository.dart';
import 'package:chroniccare/domain/repositories/social_rhythm_repository.dart';
import 'package:chroniccare/domain/repositories/stress_event_repository.dart';
import 'package:chroniccare/domain/repositories/treatment_repository.dart';
import 'package:chroniccare/domain/repositories/weight_repository.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';

// ============== 6 仓库 provider (跟 core_providers 7 repo 同模式) ==============
//
// R97-P1-1: 暴露 domain 接口 (`XRepository`), 不暴露 data 层 impl type
// (`XRepositoryImpl`)。Impl 仍由 data 层 import 进来构造, 但暴露给 UI 的
// 类型签名是 abstract — UI 拿到的 ref.read(xRepositoryProvider) 类型是
// `XRepository`, 编译期不依赖 impl 具体类。

/// 睡眠仓库
final sleepRepositoryProvider = Provider<SleepRepository>(
  (ref) => SleepRepositoryImpl(ref.watch(databaseProvider)),
);

/// 社会节律仓库
final socialRhythmRepositoryProvider = Provider<SocialRhythmRepository>(
  (ref) => SocialRhythmRepositoryImpl(ref.watch(databaseProvider)),
);

/// 应激源仓库
final stressEventRepositoryProvider = Provider<StressEventRepository>(
  (ref) => StressEventRepositoryImpl(ref.watch(databaseProvider)),
);

/// 体重仓库
final weightRepositoryProvider = Provider<WeightRepository>(
  (ref) => WeightRepositoryImpl(ref.watch(databaseProvider)),
);

/// 焦虑急躁仓库
final anxietyAgitationRepositoryProvider = Provider<AnxietyAgitationRepository>(
  (ref) => AnxietyAgitationRepositoryImpl(ref.watch(databaseProvider)),
);

/// v0.30 R91 Task 5: 治疗仓库 (Task 3 加了 impl, R91 整合入口页需要 latest
/// treatment 显示"上次记录"。Provider 之前漏注册, R91 补)
final treatmentRepositoryProvider = Provider<TreatmentRepository>(
  (ref) => TreatmentRepositoryImpl(ref.watch(databaseProvider)),
);

// ============== 6 仓库 stream provider (UI 监听用, autoDispose) ==============

/// 睡眠条目流 (按 date DESC 倒序, DAO 排好)
final sleepEntriesProvider = StreamProvider.autoDispose<List<SleepEntryEntity>>(
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

/// v0.30 R91 Task 5: 治疗条目流
final treatmentEntriesProvider =
    StreamProvider.autoDispose<List<TreatmentEntryEntity>>(
  (ref) => ref.watch(treatmentRepositoryProvider).watchAll(),
);

// ============== 6 latestXxxEntryProvider (整合入口页"上次记录"显示用) ==============
//
// 模式: 跟 mood 旁 `latestMoodEntryProvider` 1:1 同步 Provider 风格
// (R91 统一: 7 latestEntry provider 全部 sync, 整合页 card "上次记录" 显示
// 不需要 async/loading/error 包装, .value?.firstOrNull 拿当前 list 的 first)。
// - 6 daily tracking 派生 from [xxxEntriesProvider] (StreamProvider).
//   .value 是 AsyncValue, ?.firstOrNull 拿第一项或 null
// - mood 走 [moodEntriesProvider] (sync wrapper over allMoodProvider)
//   (见 [cbt_rerated_entries_provider.dart] latestMoodEntryProvider)
// - 测试 override 入口: 直接 override entries provider 即可,
///   latestXxxEntryProvider 派生会自动重算。
///
/// 不用 `StreamProvider<Entity?>` (跟 brief 例子不同) 的原因: 6 StreamProvider
/// 派生会让 [daily_tracking_page] 7 个 watch 全部 AsyncValue, 跟 mood
/// 不一致 + 增加 UI 处理 loading/error 复杂度。同步 Provider 更轻。

/// 最新睡眠记录 (整合页 card "上次记录" 用)
final latestSleepEntryProvider = Provider.autoDispose<SleepEntryEntity?>(
  (ref) => ref.watch(sleepEntriesProvider).value?.firstOrNull,
);

/// 最新社会节律记录
final latestSocialRhythmEntryProvider =
    Provider.autoDispose<SocialRhythmEntryEntity?>(
  (ref) => ref.watch(socialRhythmEntriesProvider).value?.firstOrNull,
);

/// 最新应激源记录
final latestStressEventEntryProvider = Provider.autoDispose<StressEventEntity?>(
  (ref) => ref.watch(stressEventEntriesProvider).value?.firstOrNull,
);

/// 最新体重记录
final latestWeightEntryProvider = Provider.autoDispose<WeightEntryEntity?>(
  (ref) => ref.watch(weightEntriesProvider).value?.firstOrNull,
);

/// 最新焦虑急躁记录
final latestAnxietyAgitationEntryProvider =
    Provider.autoDispose<AnxietyAgitationEntryEntity?>(
  (ref) => ref.watch(anxietyAgitationEntriesProvider).value?.firstOrNull,
);

/// 最新治疗记录
final latestTreatmentEntryProvider =
    Provider.autoDispose<TreatmentEntryEntity?>(
  (ref) => ref.watch(treatmentEntriesProvider).value?.firstOrNull,
);
