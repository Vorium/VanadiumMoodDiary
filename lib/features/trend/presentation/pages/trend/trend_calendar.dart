// trend_calendar.dart — 趋势页日历视图主壳 (v0.30 round 95 sub-spec 4 task 6 拆解)
//
// 职责: 7×6 网格日历 + 选中日详情 (走 widgets/trend_day_detail_card.dart)
// 跨日期: 4 月切换 (prev/next), 选中日高亮 + today 边框
// 跨日刷新: watch dayChangeTickProvider (R28 fix 跨日不刷)
//
// 历史:
// - 从 trend_page.dart 拆分, v0.19 (P1-15)
// - v0.22 round 28: 改 ConsumerStatefulWidget watch dayChangeTickProvider
// - v0.30 round 95 (sub-spec 4 task 6): 拆出 DayDetailCard → widgets/trend_day_detail_card.dart
//   + 拆出 _EventRow → widgets/trend_event_row.dart (public EventRow),
//   主壳瘦到 250 行 (R95 前 668)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/entities/worry_thread_entity.dart';
import 'package:chroniccare/core/shared/mood_visual.dart';
import 'package:chroniccare/domain/logic/trend_calculator.dart';
import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';
import 'package:chroniccare/presentation/widgets/press_feedback_icon_button.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/pages/trend/widgets/trend_day_detail_card.dart';

/// 日历视图
///
/// - 7×6 网格
/// - 周一开头
/// - 上月/下月灰显
/// - 选中日有边框高亮
/// - 下方显示选中日详情（v0.13 Round 10 展开）
class CalendarView extends ConsumerStatefulWidget {
  final CalendarMonth calendar;
  final List<CheckInEntity> allCheckIns;
  final List<MoodEntryEntity> moodEntries;
  final List<MedicationEntity> medications;

  /// R128e (论文3 §5.6 烦恼次数日历): 烦恼时间线 (统计当天创建的烦恼数)
  final List<WorryThreadEntity> worryThreads;

  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  const CalendarView({
    super.key,
    required this.calendar,
    required this.allCheckIns,
    required this.moodEntries,
    required this.medications,
    this.worryThreads = const [],
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
  late DateTime _selected;
  // v0.22 round 28: _today 改成 build 内取,跨日时 dayChangeTickProvider 触发 rebuild 自动刷新"今天"高亮
  // (v0.21 P0-6 修了 streakSummaryProvider 跨日,本 round 补 trend 页同样问题)

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (today.year == widget.calendar.month.year &&
        today.month == widget.calendar.month.month) {
      _selected = today;
    } else {
      _selected = widget.calendar.month;
    }
  }

  @override
  void didUpdateWidget(covariant CalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selected.year != widget.calendar.month.year ||
        _selected.month != widget.calendar.month.month) {
      _selected = widget.calendar.month;
    }
  }

  // v0.22 round 30 (sp-zh P0-2): 改用 l10n.trendWeekdayMon-Sun (build() 内取)
  // 之前 static const _weekdayLabels 7 个中文字符串硬编码, en 模式 100% 降级。

  @override
  Widget build(BuildContext context) {
    // v0.22 round 28: watch dayChangeTickProvider 让跨日时本页 rebuild,修复 trend 页
    // "今天" 格子 / _selected 不刷新 (跟 medication_calendar_page 同款 fix)
    ref.watch(dayChangeTickProvider);
    final l10n = AppLocalizations.of(context);
    final weekdayLabels = [
      l10n.trendWeekdayMon,
      l10n.trendWeekdayTue,
      l10n.trendWeekdayWed,
      l10n.trendWeekdayThu,
      l10n.trendWeekdayFri,
      l10n.trendWeekdaySat,
      l10n.trendWeekdaySun,
    ];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // v0.27 round 62 (P1-15 修复): 改用 PressFeedbackIconButton 集中器
            PressFeedbackIconButton(
              icon: Icons.chevron_left,
              onPressed: widget.onPrevMonth,
              tooltip: l10n.trendPrevMonth,
            ),
            Expanded(
              child: Center(
                child: Text(
                  l10n.trendMonthYear(
                    widget.calendar.month.year,
                    widget.calendar.month.month,
                  ),
                  style: AppTokens.textStyleBodyStrong(context),
                ),
              ),
            ),
            // v0.27 round 62 (P1-15 修复): 改用 PressFeedbackIconButton 集中器
            PressFeedbackIconButton(
              icon: Icons.chevron_right,
              onPressed: widget.onNextMonth,
              tooltip: l10n.trendNextMonth,
            ),
          ],
        ),
        Row(
          children: [
            for (final l in weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    l,
                    // v0.27 R77: textStyleCaption token (textSecondary) + w500 加粗
                    style: AppTokens.textStyleCaption(context)
                        .copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppTokens.spacingXs),
        for (int row = 0; row < 6; row++)
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: AppTokens.spacingXxxs),
            child: Row(
              children: [
                for (int col = 0; col < 7; col++)
                  Expanded(
                    child: _CalendarCell(
                      day: widget.calendar.cells[row * 7 + col],
                      inMonth:
                          widget.calendar.cells[row * 7 + col].date.month ==
                                  widget.calendar.month.month &&
                              widget.calendar.cells[row * 7 + col].date.year ==
                                  widget.calendar.month.year,
                      selected: _sameDate(
                        widget.calendar.cells[row * 7 + col].date,
                        _selected,
                      ),
                      isToday: _sameDate(
                        widget.calendar.cells[row * 7 + col].date,
                        today,
                      ),
                      onTap: () {
                        setState(() {
                          _selected = widget.calendar.cells[row * 7 + col].date;
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: AppTokens.spacingMd),
        DayDetailCard(
          date: _selected,
          allCheckIns: widget.allCheckIns,
          moodEntries: widget.moodEntries,
          medications: widget.medications,
          // R128e (论文3 §5.6 烦恼次数日历): 传烦恼时间线供当天烦恼计数
          worryThreads: widget.worryThreads,
        ),
      ],
    );
  }

  static bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// 日历单元格
class _CalendarCell extends StatelessWidget {
  final CalendarDay day;
  final bool inMonth;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;
  const _CalendarCell({
    required this.day,
    required this.inMonth,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color? bg;
    if (selected) {
      // v0.22 round 29 (emil-01~12): 改用 tintedPrimaryDeep 集中器 (0.15 接近原 0.18)
      bg = AppTokens.tintedPrimaryDeep(context);
    } else if (day.hasNormalCheckIn) {
      // v0.24 round 45 (emil P1-13): 走 tintedPrimaryHigh 集中器 (alpha 0.85)
      // 替代 hardcode `withValues(alpha: 0.85)` — emil "decisions should be nameable"
      // 命名: tintedPrimaryHigh = primary check-in bg, 区别于 primary soft (0.1)
      bg = AppTokens.tintedPrimaryHigh(context);
    } else if (day.moodScore != null) {
      bg = AppColors.moodScoreColor(day.moodScore!);
    } else {
      bg = null;
    }

    final fg = day.hasNormalCheckIn
        ? AppTokens.fgOnPrimary(context)
        : theme.colorScheme.onSurface;
    final opacity = inMonth ? 1.0 : 0.35;

    return AspectRatio(
      aspectRatio: 1,
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingXxxs),
        child: Material(
          color: bg ?? theme.colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusChip),
            side: isToday
                ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
                : BorderSide.none,
          ),
          // R114 Wave B2 (B2-9, emil F4): 包 PressFeedback (mode 2) —
          // 日历日 cell tens/day 点击, 修前只有 ripple 无 scale 0.97
          child: PressFeedback(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppTokens.radiusChip),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: opacity,
                      child: Text(
                        '${day.date.day}',
                        style: TextStyle(
                          fontSize: AppTokens.fontSizeBodySm,
                          fontWeight:
                              isToday ? FontWeight.w700 : FontWeight.w500,
                          color: fg,
                        ),
                      ),
                    ),
                    if (day.moodScore != null && inMonth)
                      Positioned(
                        right: 2,
                        bottom: 1,
                        child: Text(
                          MoodVisual.emojiFor(day.moodScore!),
                          style: AppTokens.textStyleMicro(context),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
