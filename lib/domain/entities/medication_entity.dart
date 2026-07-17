// v0.16 (Round 19) MedicationEntity — 纯 Dart domain entity
//
// 4 层架构示范：domain 层不依赖 Drift / Flutter UI 渲染。
// 用 `HourMinute` 纯 Dart 记录表示时间（替代 Flutter 的 `TimeOfDay`）。
// `medication_times` 的 JSON 编解码放 mapper（infra 层）。
//
// 设计要点：
// - 不可变（所有 final 字段 + copyWith）
// - equals / hashCode / toString 标准实现
// - 含业务方法（isActive, hasRefill, isRefillOverdue），不只做数据容器
library;

import '../../shared/domain_value.dart';
import 'hour_minute.dart';

/// 药物（领域实体）
///
/// 字段含义见 `lib/data/database/tables/medications.dart`。
class MedicationEntity {
  final int id;
  final String name;
  final double dosage;
  final String dosageUnit;
  final List<HourMinute> times;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime? refillAt;
  final int refillReminderDays;

  const MedicationEntity({
    required this.id,
    required this.name,
    required this.dosage,
    required this.dosageUnit,
    required this.times,
    required this.startDate,
    this.endDate,
    required this.isActive,
    this.refillAt,
    required this.refillReminderDays,
  });

  /// 业务方法：是否在用
  bool get isInUse => isActive;

  /// 业务方法：是否设过续方日期
  bool get hasRefill => refillAt != null;

  /// 业务方法：续方是否已过期
  ///
  /// [refillAt] 存的是当天 00:00，按"天"判断：
  /// - 同一天 = "今天"（不算过期）
  /// - 超过 refillAt 的"次日"开始 = 过期
  bool isRefillOverdue([DateTime? now]) {
    if (refillAt == null) return false;
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final refillDay = DateTime(
      refillAt!.year, refillAt!.month, refillAt!.day,
    );
    return today.isAfter(refillDay);
  }

  /// 业务方法：是否在"提醒窗口"内（refillAt - reminderDays <= now <= refillAt 当天 23:59:59）
  ///
  /// 含 refillAt 当天（不算过期，窗口最后一天是 refillAt 整天）
  bool isInRefillWindow([DateTime? now]) {
    if (refillAt == null) return false;
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final windowStart = DateTime(
      refillAt!.year,
      refillAt!.month,
      refillAt!.day,
    ).subtract(Duration(days: refillReminderDays));
    final windowEnd = DateTime(
      refillAt!.year,
      refillAt!.month,
      refillAt!.day,
    );
    return !today.isBefore(windowStart) && !today.isAfter(windowEnd);
  }

  MedicationEntity copyWith({
    int? id,
    String? name,
    double? dosage,
    String? dosageUnit,
    List<HourMinute>? times,
    DateTime? startDate,
    DomainValue<DateTime?>? endDate,
    bool? isActive,
    DomainValue<DateTime?>? refillAt,
    int? refillReminderDays,
  }) {
    return MedicationEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      dosageUnit: dosageUnit ?? this.dosageUnit,
      times: times ?? this.times,
      startDate: startDate ?? this.startDate,
      endDate: endDate == null ? this.endDate : endDate.value,
      isActive: isActive ?? this.isActive,
      refillAt: refillAt == null ? this.refillAt : refillAt.value,
      refillReminderDays: refillReminderDays ?? this.refillReminderDays,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MedicationEntity &&
        other.id == id &&
        other.name == name &&
        other.dosage == dosage &&
        other.dosageUnit == dosageUnit &&
        _listEq(other.times, times) &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.isActive == isActive &&
        other.refillAt == refillAt &&
        other.refillReminderDays == refillReminderDays;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        dosage,
        dosageUnit,
        Object.hashAll(times),
        startDate,
        endDate,
        isActive,
        refillAt,
        refillReminderDays,
      );

  @override
  String toString() =>
      'MedicationEntity(id=$id, name=$name, dosage=$dosage$dosageUnit, '
      'isActive=$isActive, refillAt=$refillAt)';

  /// List<HourMinute> 相等比较（业务层用 ==,不能用默认 identity）
  static bool _listEq(List<HourMinute> a, List<HourMinute> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].hour != b[i].hour || a[i].minute != b[i].minute) return false;
    }
    return true;
  }
}
