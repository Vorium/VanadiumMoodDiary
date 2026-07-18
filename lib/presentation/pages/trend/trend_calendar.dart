// trend_calendar.dart — 趋势页日历视图组件
//
// 从 trend_page.dart 拆分，v0.19 (P1-15)
import 'package:flutter/material.dart';

import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/core/shared/mood_visual.dart';
import 'package:chroniccare/domain/logic/day_detail.dart';
import 'package:chroniccare/domain/logic/trend_calculator.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';

/// 日历视图
///
/// - 7×6 网格
/// - 周一开头
/// - 上月/下月灰显
/// - 选中日有边框高亮
/// - 下方显示选中日详情（v0.13 Round 10 展开）
class CalendarView extends StatefulWidget {
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
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  late DateTime _selected;
  final _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    final today = DateTime(_today.year, _today.month, _today.day);
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

  static const _weekdayLabels = ['一', '二', '三', '四', '五', '六', '日'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: widget.onPrevMonth,
              tooltip: '上个月',
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${widget.calendar.month.year} 年 '
                  '${widget.calendar.month.month} 月',
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
              tooltip: '下个月',
            ),
          ],
        ),
        Row(
          children: [
            for (final l in _weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    l,
                    style: TextStyle(
                      fontSize: AppTokens.fontSizeCaption,
                      color: theme.colorScheme.onSurfaceVariant,
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
                        DateTime(_today.year, _today.month, _today.day),
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
      bg = theme.colorScheme.primary.withValues(alpha: 0.18);
    } else if (day.hasNormalCheckIn) {
      bg = theme.colorScheme.primary.withValues(alpha: 0.85);
    } else if (day.moodScore != null) {
      bg = Color(MoodVisual.colorArgbFor(day.moodScore!));
    } else {
      bg = null;
    }

    final fg =
        day.hasNormalCheckIn ? Colors.white : theme.colorScheme.onSurface;
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
                        fontSize: 13,
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
                        style: const TextStyle(fontSize: 8),
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
    final theme = Theme.of(context);
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
                    color: theme.colorScheme.onSurfaceVariant,
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
                      color: AppTokens.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                    ),
                    child: const Text(
                      '已打卡',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTokens.primary,
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
                      color: AppTokens.divider,
                      borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                    ),
                    child: const Text(
                      '未打卡',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTokens.textHint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const Spacer(),
                if (detail.events.isNotEmpty)
                  Text(
                    '${detail.events.length} 个事件',
                    style: const TextStyle(
                      fontSize: AppTokens.fontSizeCaption,
                      color: AppTokens.textHint,
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
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    detail.bestMoodScore == detail.worstMoodScore
                        ? '${detail.totalMoodEntries} 条情绪记录 · ${MoodVisual.emojiFor(detail.bestMoodScore!)}'
                        : '情绪 ${detail.totalMoodEntries} 条 · '
                            '${MoodVisual.emojiFor(detail.worstMoodScore!)}→'
                            '${MoodVisual.emojiFor(detail.bestMoodScore!)}',
                    style: const TextStyle(
                      fontSize: AppTokens.fontSizeCaption,
                      color: AppTokens.textSecondary,
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
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '这一天没有记录',
                      style: TextStyle(
                        color: AppTokens.textHint,
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
    final theme = Theme.of(context);
    final (icon, color, timePrefix) = _kindVisuals(event, theme);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            child: Text(
              timePrefix,
              style: const TextStyle(
                fontSize: AppTokens.fontSizeCaption,
                color: AppTokens.textHint,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
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
                  const SizedBox(height: 2),
                  Text(
                    event.subtitle!,
                    style: TextStyle(
                      fontSize: AppTokens.fontSizeCaption,
                      color: theme.colorScheme.onSurfaceVariant,
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

  (IconData, Color, String) _kindVisuals(DayEvent e, ThemeData theme) {
    final time = '${e.time.hour.toString().padLeft(2, '0')}:'
        '${e.time.minute.toString().padLeft(2, '0')}';
    switch (e.kind) {
      case DayEventKind.checkInNormal:
        return (Icons.check_circle, AppTokens.primary, time);
      case DayEventKind.checkInTemp:
        return (Icons.healing_outlined, AppTokens.warning, time);
      case DayEventKind.assessment:
        return (Icons.psychology_outlined, theme.colorScheme.tertiary, time);
      case DayEventKind.mood:
        return (
          Icons.mood_outlined,
          e.moodScore != null
              ? Color(MoodVisual.colorArgbFor(e.moodScore!))
              : theme.colorScheme.onSurfaceVariant,
          time,
        );
    }
  }
}
