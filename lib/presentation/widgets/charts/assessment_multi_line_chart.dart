// v0.30 round 90 (sub-spec 6 量表中心): 多线趋势图 widget
//
// 10 量表叠加, 归一化 Y 轴 (各量表 totalRange 不同 → 0-1) + 12 色 + 3 线型
// (实线/虚线/点线 轮换) + 顶部 FilterChip 列表 toggle 显示/隐藏。
//
// 用法:
// - assessment_center_page 顶部 mini 趋势图 (Task 4 placeholder 已留 SizedBox)
// - trend_page 升级 R13 trend_assessment_chart 内部调用
//
// 设计要点:
// - 颜色 / 线型 走 lib/presentation/widgets/charts/assessment_color_palette.dart
//   (int ARGB, presentation 层, 0 flutter dependency in palette)
// - Y 轴归一化: `e.score / scale.totalRange` → 0-1
//   (各量表 totalRange 不同, PHQ-9 27 / GAD-7 21 / WHODAS 48 / ASRM 20 ...)
//   不归一化 → PHQ-9 总分 27 跟 ASRM 总分 20 在同图视觉错
// - 30 天时间窗: 过滤 `e.timestamp.isBefore(now - 30d)`
// - chip 列表: SingleChildScrollView horizontal, 10 chip 不 wrap
// - tooltip: "{scaleName} {date} {score}/{totalRange}", Task 5 实施
// - chip avatar: Color 圆点 显示量表色 (色盲友好)
//
// 4 层架构: presentation 合法用 fl_chart / flutter/material。
// 放 presentation/widgets/charts/ (general) 而非 assessment/ — 让 trend/
// 也能用, 避免跨 feature import 边界违规 (v0.17 R12 rule)。

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/domain/entities/assessment_entry.dart';
import 'package:chroniccare/domain/logic/scale_registry.dart';
import 'package:chroniccare/presentation/services/scale_name_l10n.dart';
import 'package:chroniccare/presentation/widgets/charts/assessment_color_palette.dart';

class AssessmentMultiLineChart extends StatefulWidget {
  /// 量表 entry 列表 (跨量表, 用 scaleId 分组)
  final List<AssessmentEntry> entries;

  /// 显示哪些量表 (默认 = AssessmentColorPalette.allScaleIds = 10 开放)
  final List<String> scaleIds;

  /// 时间窗 (默认 30 天)
  final int daysWindow;

  /// chart 高度 (默认 走 AppTokens.chartPlaceholderHeight 集中器)
  final double chartHeight;

  const AssessmentMultiLineChart({
    super.key,
    required this.entries,
    this.scaleIds = AssessmentColorPalette.allScaleIds,
    this.daysWindow = 30,
    this.chartHeight = AppTokens.chartPlaceholderHeight,
  });

  @override
  State<AssessmentMultiLineChart> createState() =>
      _AssessmentMultiLineChartState();
}

class _AssessmentMultiLineChartState extends State<AssessmentMultiLineChart> {
  /// 用户 toggle 隐藏的量表 id (不在集合内 = 显示)
  late Set<String> _hiddenScales;

  @override
  void initState() {
    super.initState();
    _hiddenScales = <String>{};
  }

  @override
  void didUpdateWidget(covariant AssessmentMultiLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // scaleIds 变了 → 清理不在新列表的 hidden (避免 stale state)
    if (!_listEquals(oldWidget.scaleIds, widget.scaleIds)) {
      _hiddenScales.removeWhere((id) => !widget.scaleIds.contains(id));
    }
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChipRow(context),
        const SizedBox(height: AppTokens.spacingSm),
        SizedBox(
          height: widget.chartHeight,
          child: LineChart(_buildLineChartData(context)),
        ),
      ],
    );
  }

  // ===================== 顶部 chip 列表 =====================

  Widget _buildChipRow(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final id in widget.scaleIds)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.spacingXxs,
              ),
              child: FilterChip(
                label: Text(_scaleName(id)),
                selected: !_hiddenScales.contains(id),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _hiddenScales.remove(id);
                    } else {
                      _hiddenScales.add(id);
                    }
                  });
                },
                avatar: CircleAvatar(
                  backgroundColor:
                      Color(AssessmentColorPalette.colorArgbFor(id)),
                  radius: AppTokens.legendDotSizeLg / 2,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _scaleName(String id) {
    // v0.32 round 8 (R111 R111-02 fix): 走 l10n 派发 (tooltip legend
    // en 用户不再看中文量表名)
    return scaleNameL10n(id, AppLocalizations.of(context));
  }

  /// fl_chart 0.69 在 empty dashArray 上崩 (CircularIntervalList.next
  /// RangeError: Valid value range is empty: 0)。空 list → null 走"实线"分支。
  static List<int>? _resolveDashArray(List<int> dash) =>
      dash.isEmpty ? null : dash;

  // ===================== LineChart data =====================

  LineChartData _buildLineChartData(BuildContext context) {
    // 时间窗: 在窗口内的 entry 才画 (避免早期 entry 撑爆 X 轴)
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: widget.daysWindow));

    // 按 scaleId 聚合 entry, 过滤时间窗
    final byScale = <String, List<AssessmentEntry>>{};
    for (final e in widget.entries) {
      if (_hiddenScales.contains(e.scaleId)) continue;
      if (e.timestamp.isBefore(cutoff)) continue;
      (byScale[e.scaleId] ??= <AssessmentEntry>[]).add(e);
    }

    // 每量表 → 一条 LineChartBarData
    final bars = <LineChartBarData>[];
    for (final scaleId in widget.scaleIds) {
      if (_hiddenScales.contains(scaleId)) continue;
      final scale = scaleById(scaleId);
      if (scale == null) continue;
      final list = byScale[scaleId] ?? <AssessmentEntry>[];
      if (list.isEmpty) continue;

      // 隐式排序: 时序数据必须显式 sort, 不依赖 drift orderBy 隐式顺序
      // (v0.16 round 19/19B 已知坑)
      final sorted = [...list]
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // 归一化 score (0-1) / totalRange
      // (PHQ-9 总分 0-27, ASRM 总分 0-20, 不归一化视觉错)
      final totalRange = scale.totalRange;
      if (totalRange == 0) continue;
      final spots = sorted
          .map(
            (e) => FlSpot(
              e.timestamp.millisecondsSinceEpoch.toDouble(),
              e.score / totalRange,
            ),
          )
          .toList();

      bars.add(
        LineChartBarData(
          spots: spots,
          color: Color(AssessmentColorPalette.colorArgbFor(scaleId)),
          // v0.30 round 90 (R90-A): fl_chart bug — empty list crashes
          // CircularIntervalList.next (RangeError), null = solid line.
          // 实线 (index 0) 用 null, 虚线/点线用非空 list。
          dashArray: _resolveDashArray(AssessmentColorPalette.dashFor(scaleId)),
          isCurved: true,
          barWidth: 2.0,
          dotData: const FlDotData(show: true),
        ),
      );
    }

    return LineChartData(
      lineBarsData: bars,
      minY: 0,
      maxY: 1,
      // 隐藏坐标轴 label (跟 R13 老 chart 的 simple 版一致, Task 6 ARB 暂不接)
      titlesData: const FlTitlesData(show: false),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
    );
  }
}
