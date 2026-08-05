// v0.30 round 87 (sub-spec 3 mood 列表页): filter + search + sort state
//
// MoodListPage UI 用:
// - moodListFilterProvider: 持有 filter state (date range / score / CBT level / search / sort)
// - filteredMoodEntriesProvider: 把 filter 套到 moodEntriesProvider 同步 list 上, 返回最终排序结果
//
// 复用 R85 task 1 的 cbt_rerated_entries_provider.dart 里加的 moodEntriesProvider wrapper
// (sync 包装 over allMoodProvider StreamProvider)。allMoodProvider 是真源, 本文件不
// 直接 watch, 走 R85 那层 sync 包装, 测试 / 派生 provider 都直接读 sync List。
//
// 4 层架构: 本文件不依赖 Drift, 只引 flutter/material.dart (DateTimeRange) +
// flutter_riverpod + domain entity。DateTimeRange 是 flutter SDK 的类型, 不是
// Drift, 不是 presentation widgets, 算 infrastructure。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/presentation/providers/cbt_rerated_entries_provider.dart';

/// 排序方式
///
/// - [timestampDesc] 时间倒序（默认, 跟 R85 cbtReratedEntriesProvider 行为一致, 列表页直觉）
/// - [scoreAsc] 分数升序 (1→5)
/// - [scoreDesc] 分数降序 (5→1)
enum MoodListSort { timestampDesc, scoreAsc, scoreDesc }

/// 不可变 filter state
///
/// 所有字段都"null/空 = 不过滤", UI 默认全空, 跟 R85 推 trend page 的设计一致。
/// [cbtLevel] null = 全部档位 (3/5/7 都显示), 设值后只显示该档位 entry。
class MoodListFilter {
  /// 时间范围过滤, null = 不过滤
  final DateTimeRange? dateRange;

  /// 分数下限 (含), null = 不限
  final int? minScore;

  /// 分数上限 (含), null = 不限
  final int? maxScore;

  /// CBT 档位过滤 (3/5/7), null = 全部档位
  final int? cbtLevel;

  /// 搜索 query, 模糊匹配 note / tagsJson
  final String searchQuery;

  /// 排序方式
  final MoodListSort sort;

  const MoodListFilter({
    this.dateRange,
    this.minScore,
    this.maxScore,
    this.cbtLevel,
    this.searchQuery = '',
    this.sort = MoodListSort.timestampDesc,
  });
}

class MoodListFilterNotifier extends Notifier<MoodListFilter> {
  @override
  MoodListFilter build() => const MoodListFilter();

  void setSearchQuery(String q) {
    if (q == state.searchQuery) return; // dedup
    state = MoodListFilter(
      dateRange: state.dateRange,
      minScore: state.minScore,
      maxScore: state.maxScore,
      cbtLevel: state.cbtLevel,
      searchQuery: q,
      sort: state.sort,
    );
  }

  void setDateRange(DateTimeRange? r) {
    state = MoodListFilter(
      dateRange: r,
      minScore: state.minScore,
      maxScore: state.maxScore,
      cbtLevel: state.cbtLevel,
      searchQuery: state.searchQuery,
      sort: state.sort,
    );
  }

  void setMinScore(int? s) {
    state = MoodListFilter(
      dateRange: state.dateRange,
      minScore: s,
      maxScore: state.maxScore,
      cbtLevel: state.cbtLevel,
      searchQuery: state.searchQuery,
      sort: state.sort,
    );
  }

  void setMaxScore(int? s) {
    state = MoodListFilter(
      dateRange: state.dateRange,
      minScore: state.minScore,
      maxScore: s,
      cbtLevel: state.cbtLevel,
      searchQuery: state.searchQuery,
      sort: state.sort,
    );
  }

  void setCbtLevel(int? l) {
    state = MoodListFilter(
      dateRange: state.dateRange,
      minScore: state.minScore,
      maxScore: state.maxScore,
      cbtLevel: l,
      searchQuery: state.searchQuery,
      sort: state.sort,
    );
  }

  void setSort(MoodListSort s) {
    if (s == state.sort) return; // dedup
    state = MoodListFilter(
      dateRange: state.dateRange,
      minScore: state.minScore,
      maxScore: state.maxScore,
      cbtLevel: state.cbtLevel,
      searchQuery: state.searchQuery,
      sort: s,
    );
  }

  void reset() {
    if (identical(state, const MoodListFilter())) return; // dedup
    state = const MoodListFilter();
  }
}

/// Provider 入口
///
/// autoDispose: 用户离开 /mood-list 后 filter state 释放, 下次进入时
/// TextEditingController 也是空, 避免"上次搜的 '难' 字残留在 state 里" 导致
/// 列表页静默被过滤 (Fix #9 final review)。`MoodListPage` 自己不再持有
/// search state, 完全依赖 notifier, 所以 dispose 后 state 也会 reset。
final moodListFilterProvider =
    NotifierProvider.autoDispose<MoodListFilterNotifier, MoodListFilter>(
  MoodListFilterNotifier.new,
);

/// 过滤 + 搜索 + 排序 后的 list
///
/// 派生 pipeline, 跟 R85 cbtReratedEntriesProvider 同模式: watch sync wrapper +
/// watch filter state, 套过滤 + 排序后返回。
///
/// autoDispose: 跟 moodListFilterProvider 一同 release, 避免 stale filter
/// state 在下次进入 /mood-list 时意外应用 (Fix #9 final review)。
///
/// 过滤优先级: date range → min/max score → cbtLevel → search → sort
/// (任意一步不命中就短路, 不进入下一步, 跟 R85 where chain 一致)
final filteredMoodEntriesProvider =
    Provider.autoDispose<List<MoodEntryEntity>>((ref) {
  final all = ref.watch(moodEntriesProvider);
  final filter = ref.watch(moodListFilterProvider);

  Iterable<MoodEntryEntity> result = all;

  if (filter.dateRange != null) {
    final start = filter.dateRange!.start;
    final end = filter.dateRange!.end;
    result = result.where(
      (e) => !e.timestamp.isBefore(start) && !e.timestamp.isAfter(end),
    );
  }
  if (filter.minScore != null) {
    final min = filter.minScore!;
    result = result.where((e) => e.score >= min);
  }
  if (filter.maxScore != null) {
    final max = filter.maxScore!;
    result = result.where((e) => e.score <= max);
  }
  if (filter.cbtLevel != null) {
    final level = filter.cbtLevel!;
    result = result.where((e) => e.cbtLevel == level);
  }
  if (filter.searchQuery.isNotEmpty) {
    final q = filter.searchQuery.toLowerCase();
    result = result.where(
      (e) =>
          (e.note ?? '').toLowerCase().contains(q) ||
          e.tagsJson.toLowerCase().contains(q),
    );
  }

  final list = result.toList();
  switch (filter.sort) {
    case MoodListSort.timestampDesc:
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    case MoodListSort.scoreAsc:
      list.sort((a, b) => a.score.compareTo(b.score));
    case MoodListSort.scoreDesc:
      list.sort((a, b) => b.score.compareTo(a.score));
  }
  return list;
});
