// v0.30 round 93 (audit-fixes task 1.2): MedicationCalendarGrid
// 拆 medication_calendar_page.dart god page 第 1 步
// - 30 天热力图: 头部日期标签 + N 药 × N 天 cell
// - 颜色编码: 0=漏服灰 / <50%=浅橙 / <100%=almost / 100%=深绿
// - 接受 props: meds, checkIns, days, onCellTap, selectedDate
// - EmptyState 内置处理 (没在用药 / times=[])
// - 复用 PageScaffold / FadeIn / PressFeedback
//
// 之前在 medication_calendar_page._buildGrid L142-238 内联, 96 行
// 跟 _HeaderRow / _DataRow / _CellBox / _MedRow / _Cell 一起 178 行

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/features/medication/domain/entities/medication_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/animations/animations.dart';
import 'package:chroniccare/presentation/widgets/empty_state.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';

/// 用药日历热力图 widget
///
/// 显示 N 种药物 × N 天的依从性热力图。
/// 状态由父 widget 管理 (medication_calendar_page), sub-widget 不读全局 state
/// (R92 模式: 父 widget 传 data + callback, sub-widget 只渲染)。
///
/// 内部处理:
/// - 排除没排程的药 (times=[] 触发 EmptyState 提示)
/// - 排除没在用的药
/// - 30/90 天视图智能日期标签压缩
class MedicationCalendarGrid extends StatelessWidget {
  const MedicationCalendarGrid({
    super.key,
    required this.meds,
    required this.checkIns,
    required this.days,
    this.selectedDate,
    this.onCellTap,
  });

  /// 在用药物 (含 isActive=true 和 isActive=false — 父 widget 已过滤)
  final List<MedicationEntity> meds;

  /// 该药物的所有 normal 打卡 (父 widget 已按窗口过滤)
  final List<CheckInEntity> checkIns;

  /// 时间窗口大小 (7 / 30 / 90)
  final int days;

  /// 当前选中的日期 (cell 高亮用, Step 1.5 接 DayDetail 后才用)
  final DateTime? selectedDate;

  /// cell 点击回调 (R93 task 1.5 接 DayDetail 用)
  final void Function(DateTime day)? onCellTap;

  @override
  Widget build(BuildContext context) {
    // 排除没在用的药
    final activeMeds = meds.where((m) => m.isInUse).toList();
    if (activeMeds.isEmpty) {
      return EmptyState(
        icon: Icons.medication_outlined,
        title: AppLocalizations.of(context).medsCalendarNoActive,
        actionLabel: AppLocalizations.of(context).medsCalendarNoActiveAction,
        onAction: () => GoRouter.of(context).push('/medication/add'),
      );
    }
    // 排除没排程的药 (times=[]) — 否则 expected=1 永远 0% 红色 (Bug G)
    final schedulableMeds =
        activeMeds.where((m) => m.times.isNotEmpty).toList();
    if (schedulableMeds.isEmpty) {
      return EmptyState(
        icon: Icons.schedule_outlined,
        title: AppLocalizations.of(context).medsCalendarNoSchedule,
        subtitle: AppLocalizations.of(context).medsCalendarNoScheduleHint,
        actionLabel: AppLocalizations.of(context).medsCalendarNoScheduleAction,
        onAction: () => GoRouter.of(context).push('/medication'),
      );
    }

    final startDay = _computeWindowStartDay(DateTime.now(), days);

    // 把打卡预 group 到 Map<medId, Map<dayBucket, count>>
    // O(meds·days·checkIns) 降到 O(meds·days + checkIns) (Bug H fix)
    final checkInMap = <int, Map<DateTime, int>>{};
    for (final c in checkIns) {
      if (!c.isNormal) continue;
      final medId = c.medicationId;
      if (medId == null) continue;
      final dayKey = DateTime(
        c.timestamp.year,
        c.timestamp.month,
        c.timestamp.day,
      );
      if (dayKey.isBefore(startDay)) continue;
      final bucket = checkInMap.putIfAbsent(medId, () => <DateTime, int>{});
      bucket[dayKey] = (bucket[dayKey] ?? 0) + 1;
    }

    // 给每种药 × 每天 计算 (actual, expected)
    final rows = <_MedRow>[];
    for (final m in schedulableMeds) {
      final expectedPerDay = m.times.length;
      final medBuckets = checkInMap[m.id] ?? const <DateTime, int>{};
      final cells = <_Cell>[];
      for (int i = 0; i < days; i++) {
        final day = startDay.add(Duration(days: i));
        final actual = medBuckets[day] ?? 0;
        cells.add(
          _Cell(day: day, actual: actual, expected: expectedPerDay),
        );
      }
      rows.add(_MedRow(med: m, cells: cells));
    }

    return Card(
      child: Padding(
        padding: AppTokens.edgeInsetsSm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderRow(days: days, startDay: startDay),
            const SizedBox(height: AppTokens.spacingXs),
            // v0.17 round 14 (P2-5): staggered fade-in
            // 每行 delay 40ms (i * 40), 让多药日历逐行出现而不是一起
            // R114 Wave B2 (B2-8): 显式 durFast 200ms (修前默认 400ms)
            for (int i = 0; i < rows.length; i++)
              FadeIn(
                duration: AppTokens.durFast,
                delay: Duration(
                  milliseconds: (i * AppTokens.staggerStepMs)
                      .clamp(0, AppTokens.staggerCapMs),
                ),
                child: _DataRow(
                  row: rows[i],
                  selectedDate: selectedDate,
                  onCellTap: onCellTap,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 内部: 1 行 = 1 种药 + 该药所有日期 cell
class _MedRow {
  final MedicationEntity med;
  final List<_Cell> cells;
  const _MedRow({required this.med, required this.cells});
}

/// 内部: 1 cell = 1 个 (药, 日期) 单元
class _Cell {
  final DateTime day;
  final int actual;
  final int expected;
  const _Cell({
    required this.day,
    required this.actual,
    required this.expected,
  });
  double get ratio {
    if (expected == 0) return 0;
    return actual / expected;
  }
}

/// 表头日期标签 (顶部)
class _HeaderRow extends StatelessWidget {
  final int days;
  final DateTime startDay;
  const _HeaderRow({required this.days, required this.startDay});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: AppTokens.calendarLabelWidth,
          child: Text(''),
        ),
        Expanded(
          child: Row(
            children: [
              for (int i = 0; i < days; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      _dayLabel(i),
                      style: TextStyle(
                        fontSize: AppTokens.fontSizeXxxSmall,
                        color: AppTokens.textHintColor(context),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _dayLabel(int i) {
    final d = startDay.add(Duration(days: i));
    if (days > 30) {
      // 90 天视图: 只显示每周第一天
      if (d.weekday != DateTime.monday && i != 0) return '';
      return '${d.month}/${d.day}';
    }
    if (days > 7) {
      // 30 天视图: 只显示每 5 天
      if (i % 5 != 0 && i != days - 1) return '';
    }
    return '${d.month}/${d.day}';
  }
}

/// 数据行 (药名 + N 天 cell)
class _DataRow extends StatelessWidget {
  final _MedRow row;
  final DateTime? selectedDate;
  final void Function(DateTime day)? onCellTap;
  const _DataRow({
    required this.row,
    this.selectedDate,
    this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          SizedBox(
            width: AppTokens.calendarLabelWidth,
            child: Text(
              row.med.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: AppTokens.fontSizeMicro,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                for (final cell in row.cells)
                  Expanded(
                    child: _CellBox(
                      cell: cell,
                      isSelected: selectedDate != null &&
                          _isSameDay(cell.day, selectedDate!),
                      onTap:
                          onCellTap == null ? null : () => onCellTap!(cell.day),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// 单个 cell 颜色 box
class _CellBox extends StatelessWidget {
  final _Cell cell;
  final bool isSelected;
  final VoidCallback? onTap;
  const _CellBox({
    required this.cell,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      decoration: BoxDecoration(
        color: _colorFor(cell.ratio, context),
        borderRadius: BorderRadius.circular(AppTokens.radiusCell),
        // 选中态: 黑色描边 1.5px, 在浅色/深色 cell 上都可见
        border: isSelected
            ? Border.all(
                color: AppTokens.textPrimaryColor(context),
                width: 1.5,
              )
            : null,
      ),
    );
    final paddedBox = Padding(
      padding: const EdgeInsets.all(1),
      child: AspectRatio(aspectRatio: 1, child: box),
    );
    // 不可点击 → 直接返回 (无 PressFeedback 包装, 减少 widget 树)
    if (onTap == null) return paddedBox;
    // 可点击 → PressFeedback 包一层给视觉反馈
    return PressFeedback(onTap: onTap, child: paddedBox);
  }

  Color _colorFor(double ratio, BuildContext context) {
    if (ratio == 0) return AppTokens.dividerColor(context); // 漏服 - 灰
    if (ratio < 0.5) return AppTokens.adherencePartial; // 部分 - 浅橙
    if (ratio < 1) return AppTokens.adherenceAlmost; // 接近但未满
    return AppTokens.primaryColor(context); // 满 - 深绿
  }
}

/// v0.23 round 40 (sp-en R8 fix): 抽 pure function 让 window 起点可测
///
/// 算"近 N 天"窗口的起点: 今天 00:00 - (N-1) 天
///
/// 跨 0:00:05 由 v0.17 round 4 dayChangeTickProvider 兜住 invalidate
DateTime _computeWindowStartDay(DateTime now, int days) {
  final today = DateTime(now.year, now.month, now.day);
  return today.subtract(Duration(days: days - 1));
}
