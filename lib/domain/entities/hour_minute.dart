// 领域层时间结构体，替代 Flutter 的 `TimeOfDay`
//
// domain 层不依赖 `package:flutter/material.dart`，
// 用此纯 Dart 记录表示"时：分"。
//
// 用法：
// - domain entity 用 `List<HourMinute>`
// - presentation widget 拿到 entity 后转 `TimeOfDay` 渲染（如 picker）
class HourMinute {
  final int hour;
  final int minute;

  const HourMinute({required this.hour, required this.minute})
      : assert(hour >= 0 && hour <= 23, 'hour must be 0-23, got $hour'),
        assert(minute >= 0 && minute <= 59, 'minute must be 0-59, got $minute');

  /// v0.30 round 95 (sub-spec 7 R96b fix): 容错工厂 — 越界值 clamp 而不是 assert
  ///
  /// 主构造 `HourMinute(hour: X, minute: Y)` 越界会触发 assert,debug 模式崩;
  /// `safe()` 给"用户输入 / DB 老数据 / import 外部数据"场景用,clamp 兜底。
  /// 用法: `HourMinute.safe(hour: -5, minute: 0)` → `HourMinute(0, 0)`。
  ///
  /// 跟 R91 mood_period_aggregator.now optional 参数模式一致: caller 传
  /// 越界值是**已知**风险, 业务方用 safe() 主动吞。
  factory HourMinute.safe({required int hour, required int minute}) {
    return HourMinute(
      hour: hour.clamp(0, 23),
      minute: minute.clamp(0, 59),
    );
  }

  HourMinute copyWith({int? hour, int? minute}) {
    return HourMinute(
      hour: (hour ?? this.hour).clamp(0, 23),
      minute: (minute ?? this.minute).clamp(0, 59),
    );
  }

  /// 从 "HH:mm" 字符串解析
  factory HourMinute.fromString(String s) {
    final parts = s.split(':');
    if (parts.length != 2) return const HourMinute(hour: 0, minute: 0);
    return HourMinute(
      hour: (int.tryParse(parts[0]) ?? 0).clamp(0, 23),
      minute: (int.tryParse(parts[1]) ?? 0).clamp(0, 59),
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
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => toTimeString();
}
