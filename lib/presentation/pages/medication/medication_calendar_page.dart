// v0.14 (Round 13C) 用药日历 — 医生视角的依从性热力图
//
// 数据组织：
// - 行 = 1 种在用药物
// - 列 = 1 天（近 30 天）
// - 颜色 = 当天该药打卡次数 / 期望次数
//   - 0 = 漏服（红/灰）
//   - 部分 = 浅色
//   - 满 = 深绿
//
// 用 CheckInEntity + MedicationEntity 计算
// 不画新组件，直接 GridView + Container
//
// v0.17 round 7 (B1+B2): _days setState 状态提到 calendarWindowProvider
// (Notifier). 跨 page 共享 + test 友好 + Notifier 内 ref.mounted 守卫

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/app_semantics.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/providers/calendar_window_provider.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/animations/animations.dart';
import 'package:chroniccare/presentation/widgets/empty_state.dart';
import 'package:chroniccare/presentation/widgets/error_state.dart';
import 'package:chroniccare/presentation/widgets/info_banner.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';

class MedicationCalendarPage extends ConsumerWidget {
  const MedicationCalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // v0.17 round 7 (B1+B2): 状态从 setState 提到 Notifier
    final days = ref.watch(calendarWindowProvider);
    final medsAsync = ref.watch(medicationsProvider);
    final checkInsAsync = ref.watch(allCheckInsProvider);
    // v0.21 (P0-6 fix): watch dayChangeTickProvider 让跨 midnight 时本页自动 rebuild,
    // 否则 "今天" 格子 / 窗口起算日 还显示昨天的数据
    ref.watch(dayChangeTickProvider);
    return PageScaffold(
      title: AppLocalizations.of(context).medsCalendarTitle,
      child: ListView(
        children: [
          const SizedBox(height: AppTokens.spacingMd),

          // 顶部说明
          // v0.27 round 67 (C-2): 走 InfoBanner 集中器
          InfoBanner(
            icon: Icons.medication_outlined,
            text: AppLocalizations.of(context).medsCalendarHeatmapDesc,
          ),

          const SizedBox(height: AppTokens.spacingSm),

          // 时间窗口选择
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppTokens.spacingMd),
            // v0.22 round 29 (emil-34): Semantics 描述时间窗口
            // (TalkBack 读"时间窗口 7/30/90 天，当前 30" 让用户知道是单选)
            child: AppSemantics.container(
              label: AppLocalizations.of(context)
                  .medicationTimeWindowSemantics(days),
              // v0.26 round 57 (emil EMIL-INC-06): 走 PressFeedback 集中器
              // 替代裸 SegmentedButton (无 :active scale 反馈)
              child: PressFeedback(
                child: SegmentedButton<int>(
                  segments: [
                    ButtonSegment(
                      value: 7,
                      label: Text(
                          AppLocalizations.of(context).medsCalendarWindow7),
                    ),
                    ButtonSegment(
                      value: 30,
                      label: Text(
                        AppLocalizations.of(context).medsCalendarWindow30,
                      ),
                    ),
                    ButtonSegment(
                      value: 90,
                      label: Text(
                        AppLocalizations.of(context).medsCalendarWindow90,
                      ),
                    ),
                  ],
                  selected: {days},
                  // v0.22 round 29 (emil-49): 跟 trend_page.dart:252 一致 showSelectedIcon: false
                  // (避免 list/calendar 切换时 check 图标跳动)
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => ref
                      .read(calendarWindowProvider.notifier)
                      .setDays(s.first),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppTokens.spacingMd),

          medsAsync.when(
            data: (meds) => checkInsAsync.when(
              data: (checkIns) => _buildGrid(meds, checkIns, days, context),
              loading: () => const LoadingSkeleton.fullScreen(),
              error: (e, _) => ErrorState(
                title: AppLocalizations.of(context)
                    .medsCalendarLoadCheckinFailed(''),
                detail: e.toString(),
                onRetry: () => ref.invalidate(allCheckInsProvider),
              ),
            ),
            loading: () => const LoadingSkeleton.fullScreen(),
            error: (e, _) => ErrorState(
              title: AppLocalizations.of(context).medsCalendarLoadMedFailed(''),
              detail: e.toString(),
              onRetry: () => ref.invalidate(medicationsProvider),
            ),
          ),

          const SizedBox(height: AppTokens.spacingMd),

          // 图例
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppTokens.spacingMd),
            child: _Legend(days: days),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(
    List<MedicationEntity> meds,
    List<CheckInEntity> checkIns,
    int days,
    BuildContext context,
  ) {
    // Bug G fix: 排除没排程的药（times=[]），否则 expected=1 永远 0% 红色
    final schedulableMeds =
        meds.where((m) => m.isInUse && m.times.isNotEmpty).toList();
    if (meds.where((m) => m.isInUse).isEmpty) {
      // v0.21 Round 22 (P0-11 修复): 改用统一 EmptyState
      return EmptyState(
        icon: Icons.medication_outlined,
        title: AppLocalizations.of(context).medsCalendarNoActive,
        actionLabel: AppLocalizations.of(context).medsCalendarNoActiveAction,
        onAction: () => GoRouter.of(context).push('/medication/new'),
      );
    }
    if (schedulableMeds.isEmpty) {
      // v0.21 Round 22 (P0-11 修复): 改用统一 EmptyState
      return EmptyState(
        icon: Icons.schedule_outlined,
        title: AppLocalizations.of(context).medsCalendarNoSchedule,
        subtitle: AppLocalizations.of(context).medsCalendarNoScheduleHint,
        actionLabel: AppLocalizations.of(context).medsCalendarNoScheduleAction,
        onAction: () => GoRouter.of(context).push('/medication/list'),
      );
    }

    // v0.23 round 40 (sp-en R8 fix): 抽 _computeWindow pure function
    // 之前 `final today = DateTime.now()` 紧接 `DateTime(today.year, today.month, today.day)`
    // 虽然 single-capture 但 inline 不易测试,跨 0:00:05 由 dayChangeTickProvider 兜住
    final startDay = _computeWindowStartDay(DateTime.now(), days);

    // Bug H fix: 预 group check-ins 到 Map<medId, Map<dayBucket, count>>
    // 把 O(meds·days·checkIns) 降到 O(meds·days + checkIns)
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
      // 只统计窗口内的打卡
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
          _Cell(
            day: day,
            actual: actual,
            expected: expectedPerDay,
          ),
        );
      }
      rows.add(_MedRow(med: m, cells: cells));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingSm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 表头：日期标签
            _HeaderRow(days: days, startDay: startDay),
            const SizedBox(height: AppTokens.spacingXs),
            // v0.17 round 14 (P2-5): staggered fade-in
            // 每行 delay 40ms (i * 40),让多药日历逐行出现而不是一起
            // 用 FadeIn 抽的 widget (occasional 频度,user 1-2 次进日历)
            for (int i = 0; i < rows.length; i++)
              FadeIn(
                delay: Duration(
                  milliseconds: (i * AppTokens.staggerStepMs)
                      .clamp(0, AppTokens.staggerCapMs),
                ),
                child: _DataRow(row: rows[i]),
              ),
          ],
        ),
      ),
    );
  }
}

class _MedRow {
  final MedicationEntity med;
  final List<_Cell> cells;
  const _MedRow({required this.med, required this.cells});
}

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

class _HeaderRow extends StatelessWidget {
  final int days;
  final DateTime startDay;
  const _HeaderRow({required this.days, required this.startDay});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: AppTokens.calendarLabelWidth, child: Text('')),
        Expanded(
          child: Row(
            children: [
              for (int i = 0; i < days; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      _dayLabel(i),
                      style: TextStyle(
                        // v0.22 round 29 (emil-16): 用 fontSizeXxxSmall token
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
      // 90 天视图：只显示每周第一天
      if (d.weekday != DateTime.monday && i != 0) return '';
      return '${d.month}/${d.day}';
    }
    if (days > 7) {
      // 30 天视图：只显示每 5 天
      if (i % 5 != 0 && i != days - 1) return '';
    }
    return '${d.month}/${d.day}';
  }
}

class _DataRow extends StatelessWidget {
  final _MedRow row;
  const _DataRow({required this.row});

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
                // v0.22 round 29 (emil-16): 用 fontSizeMicro token
                fontSize: AppTokens.fontSizeMicro,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                for (final cell in row.cells)
                  Expanded(child: _CellBox(cell: cell)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CellBox extends StatelessWidget {
  final _Cell cell;
  const _CellBox({required this.cell});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(1),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: _colorFor(cell.ratio, context),
            // v0.21 (P1-10 fix): 改用 token,统一设计语言
            borderRadius: BorderRadius.circular(AppTokens.radiusCell),
          ),
        ),
      ),
    );
  }

  Color _colorFor(double ratio, BuildContext context) {
    if (ratio == 0) return AppTokens.dividerColor(context); // 漏服 - 灰
    if (ratio < 0.5) return AppTokens.adherencePartial; // 部分 - 浅橙
    if (ratio < 1) return AppTokens.adherenceAlmost; // 接近但未满
    return AppTokens.primaryColor(context); // 满 - 深绿
  }
}

class _Legend extends StatelessWidget {
  final int days;
  const _Legend({required this.days});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingSm),
        child: Row(
          children: [
            Text(
              AppLocalizations.of(context).medsCalendarLegendLabel,
              style: const TextStyle(
                fontSize: AppTokens.fontSizeCaption,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: AppTokens.spacingSm),
            _legendItem(
              AppTokens.dividerColor(context),
              AppLocalizations.of(context).medsCalendarLegendMissed,
              context,
            ),
            _legendItem(AppTokens.adherencePartial, '< 50%', context),
            _legendItem(AppTokens.adherenceAlmost, '< 100%', context),
            _legendItem(AppTokens.primaryColor(context), '100%', context),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color c, String label, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppTokens.spacingSm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: c,
              // v0.21 (P1-10 fix): 改用 token
              borderRadius: BorderRadius.circular(AppTokens.radiusCell),
            ),
          ),
          const SizedBox(width: AppTokens.spacingXxs),
          Text(
            label,
            style: TextStyle(
              // v0.22 round 29 (emil-16): 用 fontSizeMicro token
              fontSize: AppTokens.fontSizeMicro,
              color: AppTokens.textSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
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
