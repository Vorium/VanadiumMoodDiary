// R104 (P0-2 fix): presentation 层扩展, 将 domain 的 int 转为 Flutter 类型
//
// domain/entities/tracking_item_config.dart 用 int 代替 IconData/Color,
// 本文件提供 presentation 层便捷访问。

import 'package:flutter/material.dart';

import 'package:chroniccare/domain/entities/tracking_item_config.dart';

extension DailyTrackingItemConfigExt on DailyTrackingItemConfig {
  /// 从 iconCodePoint (int) 恢复 IconData
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  /// 从 colorValue (int) 恢复 Color
  Color get color => Color(colorValue);
}
