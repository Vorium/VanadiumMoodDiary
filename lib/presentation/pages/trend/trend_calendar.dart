// trend_calendar.dart — 趋势页日历视图组件
//
// 从 trend_page.dart 拆分，v0.19 (P1-15)
// v0.22 round 28: 改 ConsumerStatefulWidget watch dayChangeTickProvider (spen-bug-10 跨日不刷)
// + 6 处静态 AppTokens.{divider,textHint,textSecondary} → dynamic getter (emil-bug-01 dark mode silent bug)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/core/shared/mood_visual.dart';
import 'package:chroniccare/domain/logic/day_detail.dart';
import 'package:chroniccare/domain/logic/trend_calculator.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';

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
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  const CalendarView({
    super.key,
    required this.calendar,
    required this.allCheckIns,
    required this.moodEntries,
    required this.medications,
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
            IconButton(
              icon: const Icon(Icons.chevron_left),
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
                  style: const TextStyle(
                    fontSize: AppTokens.fontSizeBody,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
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
                    style: TextStyle(
                      fontSize: AppTokens.fontSizeCaption,
                      color: AppTokens.textSecondaryColor(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppTokens.spacingXs),
        for (int row = 0; row < 6; row++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
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
        _DayDetailCard(
          date: _selected,
          allCheckIns: widget.allCheckIns,
          moodEntries: widget.moodEntries,
          medications: widget.medications,
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
      bg = Color(MoodVisual.colorArgbFor(day.moodScore!));
    } else {
      bg = null;
    }

    final fg =
        day.hasNormalCheckIn ? AppTokens.fgOnPrimary(context) : theme.colorScheme.onSurface;
    final opacity = inMonth ? 1.0 : 0.35;

    return AspectRatio(
      aspectRatio: 1,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Material(
          color: bg ?? theme.colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusChip),
            side: isToday
                ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
                : BorderSide.none,
          ),
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
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
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
    );
  }
}

/// 选中日详情卡片
class _DayDetailCard extends StatelessWidget {
  final DateTime date;
  final List<CheckInEntity> allCheckIns;
  final List<MoodEntryEntity> moodEntries;
  final List<MedicationEntity> medications;
  const _DayDetailCard({
    required this.date,
    required this.allCheckIns,
    required this.moodEntries,
    required this.medications,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detail = DayDetailCalculator.fromData(
      date: date,
      checkIns: allCheckIns,
      moodEntries: moodEntries,
      medications: medications,
    );
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeLabel,
                    color: AppTokens.textSecondaryColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: AppTokens.spacingSm),
                if (detail.hasNormalCheckIn)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      // v0.22 round 29 (emil-01~12): 改用 tintedPrimaryDeep 集中器
                      color: AppTokens.tintedPrimaryDeep(context),
                      borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                    ),
                    child: Text(
                      l10n.trendCheckedIn,
                      style: TextStyle(
                        // v0.22 round 29 (emil-16): emil 报告原文用 11, 实际是 10 微小字
                        // 改用 fontSizeMicro token
                        fontSize: AppTokens.fontSizeMicro,
                        color: AppTokens.primaryColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTokens.dividerColor(context),
                      borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                    ),
                    child: Text(
                      l10n.trendNotCheckedIn,
                      style: AppTokens.textStyleMicro(context).copyWith(
                        color: AppTokens.textHintColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const Spacer(),
                if (detail.events.isNotEmpty)
                  Text(
                    l10n.trendEventCount(detail.events.length),
                    style: TextStyle(
                      fontSize: AppTokens.fontSizeCaption,
                      color: AppTokens.textHintColor(context),
                    ),
                  ),
              ],
            ),
            if (detail.bestMoodScore != null &&
                detail.worstMoodScore != null) ...[
              const SizedBox(height: AppTokens.spacingXs),
              Row(
                children: [
                  Icon(
                    Icons.mood_outlined,
                    size: AppTokens.iconSizeSmall,
                    color: AppTokens.textSecondaryColor(context),
                  ),
                  const SizedBox(width: AppTokens.spacingXxs),
                  Text(
                    detail.bestMoodScore == detail.worstMoodScore
                        ? l10n.trendMoodEntriesSame(
                            detail.totalMoodEntries,
                            MoodVisual.emojiFor(detail.bestMoodScore!),
                          )
                        : l10n.trendMoodEntriesRange(
                            detail.totalMoodEntries,
                            MoodVisual.emojiFor(detail.worstMoodScore!),
                            MoodVisual.emojiFor(detail.bestMoodScore!),
                          ),
                    style: TextStyle(
                      fontSize: AppTokens.fontSizeCaption,
                      color: AppTokens.textSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppTokens.spacingSm),
            const Divider(height: 1),
            const SizedBox(height: AppTokens.spacingSm),
            if (detail.events.isEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppTokens.spacingSm),
                child: Row(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 20,
                      color: AppTokens.textSecondaryColor(context),
                    ),
                    const SizedBox(width: AppTokens.spacingXs),
                    Text(
                      l10n.trendNoRecords,
                      style: TextStyle(
                        color: AppTokens.textHintColor(context),
                        fontSize: AppTokens.fontSizeBody,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  for (int i = 0; i < detail.events.length; i++) ...[
                    if (i > 0) const Divider(height: 1, indent: 32),
                    _EventRow(event: detail.events[i]),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// 单条事件行
class _EventRow extends StatelessWidget {
  final DayEvent event;
  const _EventRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final (icon, color, timePrefix) = _kindVisuals(event, context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            // v0.26 round 57 (emil C-10): 走 eventTimeColWidth 集中器
            // 替代 inline width: 36 magic (timeline event 时间列宽)
            width: AppTokens.eventTimeColWidth,
            child: Text(
              timePrefix,
              // v0.26 round 57 (emil B-10): 走 textStyleCaption 集中器
              // 替代内联 TextStyle(fontSizeCaption, w500, textHintColor)
              style: AppTokens.textStyleCaption(context).copyWith(
                fontWeight: FontWeight.w500,
                color: AppTokens.textHintColor(context),
              ),
            ),
          ),
          Icon(icon, size: AppTokens.iconSizeInline, color: color),
          const SizedBox(width: AppTokens.spacingXs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: AppTokens.fontSizeBody,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (event.subtitle != null && event.subtitle!.isNotEmpty) ...[
                  const SizedBox(height: AppTokens.spacingXxxs),
                  Text(
                    event.subtitle!,
                    style: TextStyle(
                      fontSize: AppTokens.fontSizeCaption,
                      color: AppTokens.textSecondaryColor(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color, String) _kindVisuals(DayEvent e, BuildContext context) {
    final theme = Theme.of(context);
    final time = '${e.time.hour.toString().padLeft(2, '0')}:'
        '${e.time.minute.toString().padLeft(2, '0')}';
    switch (e.kind) {
      case DayEventKind.checkInNormal:
        return (Icons.check_circle, AppTokens.primaryColor(context), time);
      case DayEventKind.checkInTemp:
        return (Icons.healing_outlined, AppTokens.warningColor(context), time);
      case DayEventKind.assessment:
        return (Icons.psychology_outlined, theme.colorScheme.tertiary, time);
      case DayEventKind.mood:
        return (
          Icons.mood_outlined,
          e.moodScore != null
              ? Color(MoodVisual.colorArgbFor(e.moodScore!))
              : AppTokens.textSecondaryColor(context),
          time,
        );
    }
  }
}
