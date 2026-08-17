// v0.30 round 87 (sub-spec 3 mood 列表页): MoodListPage orchestrator
//
// 1 page = 1 directory 模式 (跟 vent_list_page.dart / assessment_history_page.dart
// 一致)。本文件是 orchestrator, 不含具体业务 widget, 都委托:
// - MoodListFilterBar (Task 3) — 3 chip + sort dropdown
// - MoodListItem (Task 2) — 单行 entry
// - filteredMoodEntriesProvider (Task 1) — 过滤 + 搜索 + 排序 pipeline
//
// 4 层架构: 本文件只引 flutter material + theme tokens + l10n + 同 page widget +
// 派生 provider (注: 派生 provider 来自 presentation/providers/, 是当前 feature
// 的 facade, 不算"data 层")
//
// 设计要点:
// - 顶部 search TextField (debounce 不加, R87 MVP 先直连, 用户感受 OK)
//   + l10n.moodListSearchHint 占位
// - 中部 MoodListFilterBar (横向 SingleChildScrollView)
// - 主体 ListView.builder 渲染 filteredMoodEntriesProvider
//   - 空数据 → EmptyState (l10n.moodListEmpty)
//   - 有数据但搜索/过滤后 0 条 → 不同的 empty 文案 (l10n.moodListNoMatch)
//   - 有数据 → 列表 + 顶部 entry count (l10n.moodListEntryCount)
// - 隐私边界 (AGENTS.md): mood list 跟 trend / care engine / 安全 / 通知 无关,
//   跟 vent 严格隔离 (vent 独立表, 绝对不进任何分析)。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/features/mood/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/mood_list/widgets/mood_list_filter_bar.dart';
import 'package:chroniccare/presentation/pages/mood_list/widgets/mood_list_item.dart';
import 'package:chroniccare/presentation/pages/mood_list/widgets/mood_list_period_filter_bar.dart';
import 'package:chroniccare/presentation/widgets/worry_section.dart';
import 'package:chroniccare/presentation/providers/mood_list_filter_provider.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/empty_state.dart';
import 'package:chroniccare/presentation/widgets/error_state.dart';
import 'package:chroniccare/presentation/widgets/lazy_apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';

/// v0.30 round 87 (sub-spec 3 mood 列表页): 全部 mood entry 列表
///
/// 组合 search TextField + MoodListFilterBar + ListView, watch
/// `filteredMoodEntriesProvider` 拿过滤+搜索+排序后的 `List<MoodEntryEntity>`。
class MoodListPage extends ConsumerStatefulWidget {
  const MoodListPage({super.key});

  @override
  ConsumerState<MoodListPage> createState() => _MoodListPageState();
}

class _MoodListPageState extends ConsumerState<MoodListPage> {
  // v0.30 R87: 搜索用 TextEditingController 本地持有, dispose() 释放。
  // 走 notifier.setSearchQuery 推到 provider, 让 filteredMoodEntriesProvider
  // 派生重算。
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // R114 B1-7: 直接 watch allMoodProvider 的 AsyncValue — DB 读失败时
    // 显示 ErrorState + 重试 (修前 filteredMoodEntriesProvider 的 sync 链
    // `.value ?? const []` 吞 error, 用户看到"0 条"且无重试入口)。
    final allAsync = ref.watch(allMoodProvider);
    final hasActiveFilter = ref.watch(
      moodListFilterProvider.select(
        (f) =>
            f.searchQuery.isNotEmpty ||
            f.dateRange != null ||
            f.minScore != null ||
            f.maxScore != null ||
            f.cbtLevel != null ||
            f.period != null,
      ),
    );

    return PageScaffold(
      title: l10n.moodListPageTitle,
      // R104: 添加新建情绪日记 FAB
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/mood/create'),
        tooltip: l10n.moodDialogTitle,
        child: const Icon(Icons.add),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // search TextField
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.pageMarginH,
              vertical: AppTokens.spacingXs,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.moodListSearchHint,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              onChanged: (q) =>
                  ref.read(moodListFilterProvider.notifier).setSearchQuery(q),
            ),
          ),

          // filter bar (3 chip + sort dropdown)
          const MoodListFilterBar(),

          // v0.30 round 91: 心境时段 chip filter (6 chip: 全部/早/中/晚/夜/未指定)
          const MoodListPeriodFilterBar(),

          // v1.1.0 round 9 (F1 烦恼闭环): 烦恼心事入口 (进行中 + 忆往昔)
          const WorrySection(),

          // 主体 list
          Expanded(
            child: _buildBody(l10n, allAsync, hasActiveFilter),
          ),
        ],
      ),
    );
  }

  /// 主体: loading / error / empty / no-match / list
  ///
  /// R114 B1-7: error 不再被吞 — AsyncValue.when 渲染 ErrorState。
  /// 区分两种 empty:
  /// - 真没数据 (DB 空) → "还没有 mood 记录" + 📋 icon
  /// - 有数据但 filter / search 后 0 条 → "没有匹配的记录" (引导清空 filter)
  Widget _buildBody(
    AppLocalizations l10n,
    AsyncValue<List<MoodEntryEntity>> allAsync,
    bool hasActiveFilter,
  ) {
    return allAsync.when(
      loading: () => const LoadingSkeleton.fullScreen(),
      error: (e, _) => ErrorState(
        title: l10n.commonLoadFailed(e.toString()),
        detail: e.toString(),
        onRetry: () => ref.invalidate(allMoodProvider),
      ),
      data: (_) {
        final entries = ref.watch(filteredMoodEntriesProvider);
        if (entries.isEmpty) {
          return EmptyState(
            icon: Icons.mood_outlined,
            title: hasActiveFilter ? l10n.moodListNoMatch : l10n.moodListEmpty,
          );
        }
        // R114 B1-1: 懒加载恢复 — ListView(children:[AppleListSection(children:
        // [for ...])]) 全量构建回归 → LazyAppleListSection (sliver 化,
        // 只建 viewport 内的 cell), 视觉保留 AppleListSection 外观
        // (title 显示 entry count, R87 设计"列表 + 顶部 entry count")。
        return LazyAppleListSection(
          title: l10n.moodListEntryCount(entries.length),
          scrollPadding: const EdgeInsets.only(
            top: AppTokens.spacingXs,
            bottom: AppTokens.spacingLg,
          ),
          itemCount: entries.length,
          itemBuilder: (context, i) {
            final entry = entries[i];
            return MoodListItem(
              entry: entry,
              // v0.32 R112-02: 点击条目 → 详情页 (路由在
              // core/routing/app_route_mood_list.dart 注册 /mood/detail/:id)
              onTap: () => context.push('/mood/detail/${entry.id}'),
            );
          },
        );
      },
    );
  }
}
