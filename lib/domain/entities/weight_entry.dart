// v0.30 round 91 (sub-spec 7 日常追踪): WeightEntryEntity
//
// 4 层架构: domain 0 flutter 0 drift。

import 'package:chroniccare/core/shared/domain_value.dart';

/// 体重记录（领域实体）
class WeightEntryEntity {
  final int id;
  final DateTime timestamp;

  /// 体重 (kg, 1 decimal, 范围 30-200)
  final double weightKg;

  /// 自动算 (nullable, profile.height 缺失时 null)
  final double? bmi;

  final String? note;

  const WeightEntryEntity({
    required this.id,
    required this.timestamp,
    required this.weightKg,
    this.bmi,
    this.note,
  });

  /// 是否有效体重 (30-200 kg)
  bool get isValidWeight => weightKg >= 30 && weightKg <= 200;

  /// BMI 类别 (需 bmi 已知)
  String? get bmiCategory {
    final b = bmi;
    if (b == null) return null;
    if (b < 18.5) return 'underweight';
    if (b < 24) return 'normal';
    if (b < 28) return 'overweight';
    return 'obese';
  }

  WeightEntryEntity copyWith({
    int? id,
    DateTime? timestamp,
    double? weightKg,
    DomainValue<double?>? bmi,
    DomainValue<String?>? note,
  }) {
    return WeightEntryEntity(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      weightKg: weightKg ?? this.weightKg,
      bmi: bmi == null ? this.bmi : bmi.value,
      note: note == null ? this.note : note.value,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeightEntryEntity &&
        other.id == id &&
        other.timestamp == timestamp &&
        other.weightKg == weightKg &&
        other.bmi == bmi &&
        other.note == note;
  }

  @override
  int get hashCode => Object.hash(id, timestamp, weightKg, bmi, note);

  @override
  String toString() =>
      'WeightEntryEntity(id=$id, weight=${weightKg}kg, bmi=$bmi)';
}
