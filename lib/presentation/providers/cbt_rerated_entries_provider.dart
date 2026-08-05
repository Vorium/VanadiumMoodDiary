// v0.30 round 85 (CBT 重评效果图): 过滤 5/7 栏 entries
//
// 关系链:
//   moodRepository.watchAll()  →  allMoodProvider (StreamProvider, 已有)
//                            →  moodEntriesProvider (本文件, sync 包装)
//                            →  cbtReratedEntriesProvider (本文件, 过滤 cbtLevel >= 5)
//
// 为什么需要 moodEntriesProvider (sync 包装) ?
// - allMoodProvider 是 StreamProvider, .value 异步, UI 想"读" 同步 List
//   必须 await / whenData, 派生 provider 写起来很啰嗦
// - 测试想 overrideWith((ref) => [...]) 注入 sync list, StreamProvider 只能
//   注入 Stream.value([...]), 写起来也啰嗦
// - 加一层 sync 包装: 派生 provider (本文件 cbtReratedEntriesProvider) 和
//   测试 (test 文件) 都直接读 sync List, allMoodProvider 仍管 stream source of truth
// - autoDispose 链: 离开 trend page → cbtReratedEntriesProvider dispose
//   → moodEntriesProvider dispose → allMoodProvider dispose (无 watch)

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';

/// 所有 mood entries (sync 包装 over [allMoodProvider])
///
/// 未到达时返回空 list (UI / 派生 provider 走 fallback 即可)。
/// 派生 provider [cbtReratedEntriesProvider] 直接读 sync List。
final moodEntriesProvider = Provider.autoDispose<List<MoodEntryEntity>>(
  (ref) => ref.watch(allMoodProvider).value ?? const <MoodEntryEntity>[],
);

/// 5/7 栏 CBT entries (cbtLevel >= 5), 给 ReratedScoreChart 用
///
/// cbtLevel 推断规则 (见 [MoodEntryEntity.cbtLevel]):
/// - 7 = coreBelief 或 behaviorResponse 非空
/// - 5 = alternativeThought / reratedScore / situation / automaticThought 任一非空
/// - null = 全空 (3 栏纯情绪打卡)
final cbtReratedEntriesProvider = Provider.autoDispose<List<MoodEntryEntity>>(
  (ref) => ref
      .watch(moodEntriesProvider)
      .where((e) => (e.cbtLevel ?? 0) >= 5)
      .toList(),
);

/// v0.30 R91 Task 5 整合入口: 最新 mood entry (整合页"情绪日记" 卡片显示)
///
/// 同步 Provider (基于 [moodEntriesProvider] sync 包装), 跟其他 6 daily
/// tracking 的 latestXxxEntryProvider (Stream-based) 风格不同 — mood 数据
/// 走 [allMoodProvider] → [moodEntriesProvider] sync 链, 没必要再开一层
/// Stream 包装。整合页 card "上次记录" 用, 包含 score + period。
final latestMoodEntryProvider = Provider.autoDispose<MoodEntryEntity?>(
  (ref) {
    final entries = ref.watch(moodEntriesProvider);
    return entries.isEmpty ? null : entries.first;
  },
);
