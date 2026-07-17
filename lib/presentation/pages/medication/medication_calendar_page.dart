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
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/providers/calendar_window_provider.dart';
import 'package:chroniccare/presentation/providers/data_providers.dart';
import 'package:chroniccare/presentation/widgets/animations/animations.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';

class MedicationCalendarPage extends ConsumerWidget {
  const MedicationCalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // v0.17 round 7 (B1+B2): 状态从 setState 提到 Notifier
    final days = ref.watch(calendarWindowProvider);
    final medsAsync = ref.watch(medicationsProvider);
    final checkInsAsync = ref.watch(allCheckInsProvider);
    return PageScaffold(
      title: '用药日历',
      child: ListView(
        children: [
          const SizedBox(height: AppTokens.spacingMd),

          // 顶部说明
          Container(
            padding: const EdgeInsets.all(AppTokens.spacingMd),
            decoration: BoxDecoration(
              color: AppTokens.primaryLight,
              borderRadius: BorderRadius.circular(AppTokens.radiusChip),
            ),
            child: const Row(
              children: [
                Icon(Icons.medication_outlined, color: AppTokens.primary),
                SizedBox(width: AppTokens.spacingSm),
                Expanded(
                  child: Text(
                    '以药为单位的依从性热力图。颜色越深 = 当天打卡次数越接近期望次数。',
                    style: TextStyle(fontSize: AppTokens.fontSizeBody),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTokens.spacingSm),

          // 时间窗口选择
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppTokens.spacingMd),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 7, label: Text('7 天')),
                ButtonSegment(value: 30, label: Text('30 天')),
                ButtonSegment(value: 90, label: Text('90 天')),
              ],
              selected: {days},
              onSelectionChanged: (s) =>
                  ref.read(calendarWindowProvider.notifier).setDays(s.first),
            ),
          ),

          const SizedBox(height: AppTokens.spacingMd),

          medsAsync.when(
            data: (meds) => checkInsAsync.when(
              data: (checkIns) => _buildGrid(meds, checkIns, days),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载打卡失败: $e')),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('加载药物失败: $e')),
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
  ) {
    // Bug G fix: 排除没排程的药（times=[]），否则 expected=1 永远 0% 红色
    final schedulableMeds =
        meds.where((m) => m.isInUse && m.times.isNotEmpty).toList();
    if (meds.where((m) => m.isInUse).isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppTokens.spacingXl),
        child: Center(
          child: Text(
            '还没有在用药物',
            style: TextStyle(color: AppTokens.textHint),
          ),
        ),
      );
    }
    if (schedulableMeds.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppTokens.spacingXl),
        child: Center(
          child: Text(
            '在用药物未设置服用时间，无法生成依从性日历',
            style: TextStyle(color: AppTokens.textHint),
          ),
        ),
      );
    }

    final today = DateTime.now();
    final startDay = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: days - 1));

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
                delay: Duration(milliseconds: i * 40),
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
        const SizedBox(width: _labelWidth, child: Text('')),
        Expanded(
          child: Row(
            children: [
              for (int i = 0; i < days; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      _dayLabel(i),
                      style: const TextStyle(
                        fontSize: 8,
                        color: AppTokens.textHint,
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
            width: _labelWidth,
            child: Text(
              row.med.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
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
            color: _colorFor(cell.ratio),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Color _colorFor(double ratio) {
    if (ratio == 0) return AppTokens.divider; // 漏服 - 灰
    if (ratio < 0.5) return Colors.orange.shade200; // 部分 - 浅橙
    if (ratio < 1) return Colors.lightGreen.shade200; // 接近但未满
    return AppTokens.primary; // 满 - 深绿
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
            const Text(
              '依从：',
              style: TextStyle(
                fontSize: AppTokens.fontSizeCaption,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: AppTokens.spacingSm),
            _legendItem(AppTokens.divider, '漏服'),
            _legendItem(Colors.orange.shade200, '< 50%'),
            _legendItem(Colors.lightGreen.shade200, '< 100%'),
            _legendItem(AppTokens.primary, '100%'),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color c, String label) {
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
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style:
                const TextStyle(fontSize: 10, color: AppTokens.textSecondary),
          ),
        ],
      ),
    );
  }
}

const double _labelWidth = 60;
