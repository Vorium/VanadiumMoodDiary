// v0.30 R101: 药丸颜色形状图标 — 参照 Apple Health Medications
//
// 每种药物有自定义颜色 (6色) + 固定形状 (圆角矩形药丸)。
// 用于用药主页、药物列表、添加向导确认页。

import 'package:flutter/material.dart';

/// 6 种药物颜色
const List<Color> kMedPillColors = [
  Color(0xFF34C759), // 绿
  Color(0xFFFFCC00), // 黄
  Color(0xFFFF3B30), // 红
  Color(0xFF007AFF), // 蓝
  Color(0xFFAF52DE), // 紫
  Color(0xFF8E8E93), // 灰
];

/// 药丸颜色形状图标
///
/// 圆角矩形 + 渐变色 + 内部药名首字，视觉识别药物。
class MedicationPillIcon extends StatelessWidget {
  const MedicationPillIcon({
    super.key,
    required this.colorIndex,
    this.size = 40,
    this.initial,
  });

  final int colorIndex;
  final double size;
  final String? initial;

  @override
  Widget build(BuildContext context) {
    final baseColor =
        kMedPillColors[colorIndex.clamp(0, kMedPillColors.length - 1)];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor.withValues(alpha: 0.8),
            baseColor,
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: baseColor.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: initial != null
            ? Text(
                initial!.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.w700,
                ),
              )
            : Icon(
                Icons.medication_rounded,
                color: Colors.white,
                size: size * 0.5,
              ),
      ),
    );
  }
}
