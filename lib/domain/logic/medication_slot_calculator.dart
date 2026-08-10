// medication_slot_calculator.dart — 用药时间段分类 (纯 domain 逻辑)
//
// v0.30 R108 (P1 medication_page 拆): 抽时间段算法到 domain
// (R107 报告 §3.3 medication_page 540L god class 拆方案, P1 优先级)。
//
// 拆出原因:
// - 原 medication_page.dart 540 行单 ConsumerWidget, 含 1 _TimeSlot enum
//   (morning/afternoon/evening/bedtime 含 contains(hour) 算法) + 1 _SlotEntry
//   class + 1 _buildTimeSlots 180 行 helper
// - _TimeSlot.contains + fromHour 是纯业务, 应进 domain/logic/ 跟其他
//   calculator (StreakCalculator / SleepCalculator / MedicationStatCalculator)
//   一起, 可在 test 中直接覆盖, 0 Flutter 依赖
// - 抽出后 medication_page 缩到 ~400L (减 _TimeSlot enum ~20L + _buildTimeSlots
//   内部 slot 判断改调 fromHour, 减 ~10L)
//
// 时段定义 (跟原 _TimeSlot 一致, 保留用户实际行为):
// - morning  (5-11)   — 早晨 5:00 到 11:59
// - afternoon (12-16)  — 下午 12:00 到 16:59
// - evening  (17-20)  — 傍晚 17:00 到 20:59
// - bedtime  (21-4)   — 睡前 21:00 到次日 04:59 (跨日)
//
// 设计选择:
// - 用 const 构造 + == / hashCode 实现值相等 (Dart const 数据正确性)
// - 4 个 const 时段定义放在 class 内部, 跟 StreakCalculator 模式一致
// - [fromHour] 工厂遍历 [all] 找第一个 contains 的 slot, fallback morning
//   (正常情况所有 hour 0-23 都能匹配, fallback 兜底)
// - [contains] 处理跨日: startHour <= endHour 同日 (用 <=), 否则跨日
//   (startHour..23 || 0..endHour, 用 <=)。跟原 _TimeSlot.contains 完全一致。
//
// 4 层架构纯度: 0 Flutter 0 Drift 0 presentation, 跟其他 logic calculator
// 一致 (check_all.dart 守门员覆盖 — `domain/` 不 import `package:flutter/`).
/// v0.30 R108 (P1 medication_page 拆): 用药时间段
///
/// 4 时段定义 + [contains] 跨日判定 + [fromHour] 工厂。
///
/// 跟 [HourMinute] (R96b fix) 模式一致: 用 const 构造 + 显式 == / hashCode
/// 实现不可变值相等, 不依赖 @immutable annotation (避免 `package:flutter/`
// 依赖, 保持 domain 纯 Dart)。
class MedicationTimeSlot {
  /// 时段名 (i18n key, presentation 层映射 icon + l10n label)
  final String name;

  /// 起始小时 (inclusive, 0-23)
  final int startHour;

  /// 结束小时 (inclusive, 0-23)。当 [startHour] > [endHour] 时表示跨日。
  final int endHour;

  const MedicationTimeSlot({
    required this.name,
    required this.startHour,
    required this.endHour,
  });

  /// 早晨 5:00-11:59
  static const morning =
      MedicationTimeSlot(name: 'morning', startHour: 5, endHour: 11);

  /// 下午 12:00-16:59
  static const afternoon =
      MedicationTimeSlot(name: 'afternoon', startHour: 12, endHour: 16);

  /// 傍晚 17:00-20:59
  static const evening =
      MedicationTimeSlot(name: 'evening', startHour: 17, endHour: 20);

  /// 睡前 21:00-04:59 (跨日: startHour=21 > endHour=4)
  static const bedtime =
      MedicationTimeSlot(name: 'bedtime', startHour: 21, endHour: 4);

  /// 4 个时段 (按时间顺序: morning → afternoon → evening → bedtime)
  static const all = <MedicationTimeSlot>[
    morning,
    afternoon,
    evening,
    bedtime,
  ];

  /// 根据 [hour] (0-23) 判定属于哪个时段
  ///
  /// 遍历 [all] 找第一个 [contains] 命中的 slot, fallback [morning] (兜底,
  /// 正常情况所有 hour 0-23 都能匹配, 4 个时段覆盖无 gap)。
  ///
  /// 抽自原 medication_page._TimeSlot.values 遍历 + slot.contains 匹配
  /// 逻辑 (R108 P1 medication_page 拆)。
  static MedicationTimeSlot fromHour(int hour) {
    for (final slot in all) {
      if (slot.contains(hour)) return slot;
    }
    return morning; // fallback
  }

  /// 判定 [hour] (0-23) 是否属于本时段
  ///
  /// 同日时段 (startHour <= endHour): hour 在 [startHour, endHour] 闭区间内
  /// 跨日时段 (startHour > endHour, 如 bedtime 21-4): hour 在
  /// [startHour, 23] 或 [0, endHour]
  ///
  /// 抽自原 medication_page._TimeSlot.contains (R108 P1 拆)。
  bool contains(int hour) {
    if (startHour <= endHour) {
      return hour >= startHour && hour <= endHour;
    }
    // 跨 midnight (bedtime: 21-4)
    return hour >= startHour || hour <= endHour;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationTimeSlot &&
          other.name == name &&
          other.startHour == startHour &&
          other.endHour == endHour;

  @override
  int get hashCode => Object.hash(name, startHour, endHour);

  @override
  String toString() =>
      'MedicationTimeSlot($name, $startHour-$endHour)';
}
