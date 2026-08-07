// v0.30 round 87 (sub-spec 3 mood 列表页): mood list filter bar
//
// 3 个 ActionChip (日期/分数/CBT 档位) + 1 个 DropdownButton<MoodListSort> (排序)。
// 每个 chip tap 弹 showModalBottomSheet / showDateRangePicker 让用户选值,
// 选完通过 moodListFilterProvider.notifier 的 setter (setDateRange / setMinScore /
// setMaxScore / setCbtLevel) 改 state, 派生 filteredMoodEntriesProvider 自动重算。
//
// 设计要点:
// - ConsumerWidget (跟 R85 task 2 / R87 task 1 同模式, ref.watch state + ref.read notifier)
// - 横向 SingleChildScrollView 包 Row: 屏幕窄时 3 chip + dropdown 可滑动
// - chip 标签只用 filter 名字 ("日期"/"分数"/"CBT 档位"),不显示当前值
//   (active state 用 Material 的 chip 选中态视觉区分; 测试用 find.text 精确匹配名字)
// - 复用 AppTokens (spacing/iconSize) + R85 PressFeedback 让 chip 有 :active scale 反馈
// - 4 层架构: 只引 flutter material + theme tokens + l10n + domain (via provider) + 同 page widget
//
// 跟 R85 task 2 区别: R85 在 trend page 用 SizedBox + Wrap 横排; 本 widget 走
// SingleChildScrollView (horizontal) 因为 chip + dropdown 一起排可能溢出窄屏。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/mood_list_filter_provider.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';

/// mood list 顶部的 filter + sort bar
///
/// 3 ActionChip (日期 / 分数 / CBT 档位) + 1 DropdownButton (排序)。
/// 任何 chip / dropdown 操作直接改 moodListFilterProvider state,
/// 上层 MoodListPage 用 ref.watch(filteredMoodEntriesProvider) 自动重渲染。
class MoodListFilterBar extends ConsumerWidget {
  const MoodListFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final filter = ref.watch(moodListFilterProvider);
    final notifier = ref.read(moodListFilterProvider.notifier);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingMd,
        vertical: AppTokens.spacingXs,
      ),
      child: Row(
        children: [
          // 日期 chip
          PressFeedback(
            child: ActionChip(
              avatar: const Icon(
                Icons.calendar_today,
                size: AppTokens.iconSizeMicro,
              ),
              label: Text(l10n.moodListFilterDate),
              onPressed: () => _pickDateRange(context, notifier, filter.dateRange),
            ),
          ),
          const SizedBox(width: AppTokens.spacingXs),

          // 分数 chip
          PressFeedback(
            child: ActionChip(
              avatar: const Icon(
                Icons.star_outline,
                size: AppTokens.iconSizeMicro,
              ),
              label: Text(l10n.moodListFilterScore),
              onPressed: () => _pickScoreRange(
                context,
                notifier,
                filter.minScore,
                filter.maxScore,
              ),
            ),
          ),
          const SizedBox(width: AppTokens.spacingXs),

          // CBT 档位 chip
          PressFeedback(
            child: ActionChip(
              avatar: const Icon(
                Icons.psychology_outlined,
                size: AppTokens.iconSizeMicro,
              ),
              label: Text(l10n.moodListFilterCbt),
              onPressed: () => _pickCbtLevel(context, notifier, filter.cbtLevel),
            ),
          ),
          const SizedBox(width: AppTokens.spacingMd),

          // 排序 dropdown
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.moodListSortBy,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: AppTokens.spacingXxs),
              DropdownButton<MoodListSort>(
                value: filter.sort,
                isDense: true,
                underline: const SizedBox.shrink(),
                onChanged: (s) {
                  if (s != null) notifier.setSort(s);
                },
                items: [
                  DropdownMenuItem(
                    value: MoodListSort.timestampDesc,
                    child: Text(l10n.moodListSortTimestamp),
                  ),
                  DropdownMenuItem(
                    value: MoodListSort.scoreAsc,
                    child: Text(l10n.moodListSortScoreAsc),
                  ),
                  DropdownMenuItem(
                    value: MoodListSort.scoreDesc,
                    child: Text(l10n.moodListSortScoreDesc),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───── pickers ─────

  /// 日期范围: 用 Flutter showDateRangePicker (Material 自带,不用自己写)。
  /// 选完调 setDateRange(null) 清空 或 setDateRange(DateTimeRange) 设置。
  Future<void> _pickDateRange(
    BuildContext context,
    MoodListFilterNotifier notifier,
    DateTimeRange? current,
  ) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: current ??
          DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: DateTime(now.year, now.month + 1, 0),
          ),
    );
    if (picked == null) return;
    notifier.setDateRange(picked);
  }

  /// 分数范围: 底部 sheet, 6 选 1 (全部 / 1 / 2 / 3 / 4 / 5)。
  /// UI 简化: 一次性选单值 (min == max), 跟 R85 cbtReratedEntriesProvider
  /// 的 score filter 一致。如果以后需要范围, 加双 slider。
  ///
  /// 用 [_MaybePicked] 包装区分 "用户取消" (null) vs "用户选了 null=全部" (value=null, picked=true)。
  /// 否则 dismiss 会把 active filter 意外清空。
  Future<void> _pickScoreRange(
    BuildContext context,
    MoodListFilterNotifier notifier,
    int? currentMin,
    int? currentMax,
  ) async {
    final picked = await showModalBottomSheet<_MaybePicked<int?>>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        // 5 档分数: null = 全部, 1..5 = 固定值
        return SafeArea(
          child: RadioGroup<int?>(
            groupValue: currentMin == currentMax ? currentMin : null,
            onChanged: (val) => Navigator.pop(ctx, _MaybePicked.picked(val)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final v in const <int?>[null, 1, 2, 3, 4, 5])
                  RadioListTile<int?>(
                    value: v,
                    title: Text(v == null ? l10n.moodListPeriodAll : '$v'),
                  ),
              ],
            ),
          ),
        );
      },
    );
    // picked == null → 用户 dismiss (不动 state)
    // picked.picked == true → 用户选了 (value 可能是 null = 全部)
    if (picked == null || !picked.wasPicked) return;
    if (!context.mounted) return;
    notifier.setMinScore(picked.value);
    notifier.setMaxScore(picked.value);
  }

  /// CBT 档位: 底部 sheet, 4 选 1 (全部 / 3 / 5 / 7)。
  /// null = 全部档位, int = 只显示该档位。
  Future<void> _pickCbtLevel(
    BuildContext context,
    MoodListFilterNotifier notifier,
    int? current,
  ) async {
    final picked = await showModalBottomSheet<_MaybePicked<int?>>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return SafeArea(
          child: RadioGroup<int?>(
            groupValue: current,
            onChanged: (val) => Navigator.pop(ctx, _MaybePicked.picked(val)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final v in const <int?>[null, 3, 5, 7])
                  RadioListTile<int?>(
                    value: v,
                    title: Text(
                      v == null ? l10n.moodListPeriodAll : l10n.moodCbtColumns(v),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (picked == null || !picked.wasPicked) return;
    if (!context.mounted) return;
    notifier.setCbtLevel(picked.value);
  }
}

/// 区分 "user dismissed modal" vs "user picked null (= 全部)"
///
/// showModalBottomSheet 在用户 dismiss (tap outside / swipe) 时返回 null,
/// 跟 "user picked the null option" (选 "全部" / 清空 filter) 没法区分。
/// 用 wrapper 显式标 `wasPicked`, 避免 dismiss 时把 active filter 意外清掉。
///
/// 调用方判别:
/// - `result == null`           → user dismissed (不动 state)
/// - `result.wasPicked == true` → user picked (可能 value 是 null = 全部)
class _MaybePicked<T> {
  final T value;
  final bool wasPicked;
  const _MaybePicked.picked(this.value) : wasPicked = true;
}
