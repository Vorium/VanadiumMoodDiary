/// 领域层时间结构体，替代 Flutter 的 `TimeOfDay`
///
/// domain 层不依赖 `package:flutter/material.dart`，
/// 用此纯 Dart 记录表示"时:分"。
///
/// 用法：
/// - domain entity 用 `List<HourMinute>`
/// - presentation widget 拿到 entity 后转 `TimeOfDay` 渲染（如 picker）
class HourMinute {
  final int hour;
  final int minute;

  const HourMinute({required this.hour, required this.minute});

  /// 从 "HH:mm" 字符串解析
  factory HourMinute.fromString(String s) {
    final parts = s.split(':');
    if (parts.length != 2) return const HourMinute(hour: 0, minute: 0);
    return HourMinute(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  /// 格式化为 "HH:mm"
  String toTimeString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HourMinute && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => hour.hashCode ^ minute.hashCode;

  @override
  String toString() => toTimeString();
}
