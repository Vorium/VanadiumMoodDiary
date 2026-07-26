// v0.24 round 46 (emil B-12 god class 续拆): 30 天热力图
//
// 从 trend_charts.dart 拆出
//
// 高内聚：只关心 daily → 热力图网格
// 低耦合：被 trend_page 调
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/logic/trend_calculator.dart';

class HeatmapGrid extends StatelessWidget {
  final List<DailyCheckIn> daily;
  const HeatmapGrid({super.key, required this.daily});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final d in daily)
              _HeatCell(
                date: d.date,
                checked: d.checked,
                size: ((constraints.maxWidth - 4 * 4) / 5).clamp(28.0, 48.0),
              ),
          ],
        );
      },
    );
  }
}

class _HeatCell extends StatelessWidget {
  final DateTime date;
  final bool checked;
  final double size;
  const _HeatCell({
    required this.date,
    required this.checked,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final color = checked
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    return Tooltip(
      message: '${date.month}/${date.day} ${checked ? "✓" : ""}',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppTokens.radiusCellLg),
        ),
      ),
    );
  }
}
