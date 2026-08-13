// R104 (P0-2 fix): presentation 层扩展, 将 domain 的 int 转为 Flutter 类型
//
// domain/entities/tracking_item_config.dart 用 int 代替 IconData/Color,
// 本文件提供 presentation 层便捷访问。
//
// v0.32 round 8 (R111 warning 清零): IconData 构造参数 @mustBeConst (Flutter
// 3.41 icon tree-shaking), 运行时 int 不能直接构造。7 个默认追踪项全部映射
// 到 const `Icons.*` 常量 (switch 全 const 分支), 未知 codepoint 走
// `Icons.help_outline` 兜底 (iconCodePoint 只来自 kDefaultTrackingItems,
// 无用户自定义路径)。

import 'package:flutter/material.dart';

import 'package:chroniccare/domain/entities/tracking_item_config.dart';

extension DailyTrackingItemConfigExt on DailyTrackingItemConfig {
  /// 从 iconCodePoint (int) 恢复 IconData
  ///
  /// switch 分支跟 kDefaultTrackingItems 的 7 个 codepoint 一一对应,
  /// 新增追踪项时必须同步加分支 (const 保证 tree-shaking 兼容)。
  IconData get icon => switch (iconCodePoint) {
        0xf1e5 => Icons.mood_outlined,
        0xf2d2 => Icons.psychology_outlined,
        0xeecb => Icons.bedtime_outlined,
        0xf1e2 => Icons.monitor_weight_outlined,
        0xf339 => Icons.schedule_outlined,
        0xeedd => Icons.bolt_outlined,
        0xf1be => Icons.medical_services_outlined,
        _ => Icons.help_outline,
      };

  /// 从 colorValue (int) 恢复 Color
  Color get color => Color(colorValue);
}
