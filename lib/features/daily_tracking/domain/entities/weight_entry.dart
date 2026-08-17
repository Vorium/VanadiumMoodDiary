// v1.1.0+174 R126 (R110 feature-first 阶段 2 step 3) — weight entity
//
// 4 层架构: domain 0 flutter 0 drift, 跟 R110 阶段 1/2 设计一致。
// 含业务方法 (isValidWeight / bmiCategory) 跟旧版一致, 0 break widget 端。

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

  /// BMI 分类 (英文 i18n key, 跟旧版一致)
  String? get bmiCategory {
    final b = bmi;
    if (b == null) return null;
    if (b < 18.5) return 'underweight';
    if (b < 24) return 'normal';
    if (b < 28) return 'overweight';
    return 'obese';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeightEntryEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          timestamp == other.timestamp &&
          weightKg == other.weightKg &&
          bmi == other.bmi &&
          note == other.note;

  @override
  int get hashCode => Object.hash(id, timestamp, weightKg, bmi, note);
}
