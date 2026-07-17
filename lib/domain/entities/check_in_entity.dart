// v0.14 (Round 12A) CheckInEntity — 纯 Dart domain entity
//
// 4 层架构示范：domain 层不依赖 Drift。
// `type` 用枚举（`CheckInType`）替代之前的自由 string，
// 业务代码不再用裸 string 比较。
//
// 设计要点：
// - 不可变（所有 final 字段 + copyWith）
// - `type` 改成枚举 + `fromWire` 容错解析
// - `isNormal` / `isTemp` / `isAssessment` getter 取代 `c.type == 'xxx'`
// - equals / hashCode / toString 标准实现
library;

import '../../shared/domain_value.dart';

/// 打卡类型
///
/// 原 Drift 存的是 string (`'normal'` / `'temp'` / `'phq9'` / `'gad7'`)。
/// 这里用 enum 替代，UI 和 domain 层不再写裸 string 比较。
enum CheckInType {
  /// 每日打卡
  normal('normal'),

  /// 临时吃药（不影响 streak）
  temp('temp'),

  /// PHQ-9 抑郁筛查
  phq9('phq9'),

  /// GAD-7 焦虑筛查
  gad7('gad7');

  /// 数据库存的字面量
  final String wire;
  const CheckInType(this.wire);

  /// 从数据库字面量反序列化
  ///
  /// 未知字符串 fallback 到 [normal]（兜底，避免崩）。
  static CheckInType fromWire(String s) {
    for (final t in CheckInType.values) {
      if (t.wire == s) return t;
    }
    return CheckInType.normal;
  }
}

extension CheckInTypeX on CheckInType {
  /// 简短中文描述
  String get label {
    switch (this) {
      case CheckInType.normal:
        return '每日打卡';
      case CheckInType.temp:
        return '临时吃药';
      case CheckInType.phq9:
        return 'PHQ-9 评估';
      case CheckInType.gad7:
        return 'GAD-7 评估';
    }
  }
}

/// 打卡（领域实体）
///
/// 字段含义见 `lib/data/database/tables/check_ins.dart`。
class CheckInEntity {
  final int id;
  final DateTime timestamp;

  /// 类型（已从 string 升级为枚举）
  final CheckInType type;

  /// 关联 medication_id（临时吃药可为空）
  final int? medicationId;

  /// 备注（临时吃药 / 评估 时为 JSON）
  final String? note;

  const CheckInEntity({
    required this.id,
    required this.timestamp,
    required this.type,
    this.medicationId,
    this.note,
  });

  // ===== 业务方法 =====

  /// 是否每日打卡
  bool get isNormal => type == CheckInType.normal;

  /// 是否临时吃药
  bool get isTemp => type == CheckInType.temp;

  /// 是否心理量表评估
  bool get isAssessment => type == CheckInType.phq9 || type == CheckInType.gad7;

  /// 是否 PHQ-9
  bool get isPhq9 => type == CheckInType.phq9;

  /// 是否 GAD-7
  bool get isGad7 => type == CheckInType.gad7;

  /// 是否关联某个 medication
  bool isForMedication(int medicationId) => this.medicationId == medicationId;

  CheckInEntity copyWith({
    int? id,
    DateTime? timestamp,
    CheckInType? type,
    DomainValue<int?>? medicationId,
    DomainValue<String?>? note,
  }) {
    return CheckInEntity(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      medicationId:
          medicationId == null ? this.medicationId : medicationId.value,
      note: note == null ? this.note : note.value,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CheckInEntity &&
        other.id == id &&
        other.timestamp == timestamp &&
        other.type == type &&
        other.medicationId == medicationId &&
        other.note == note;
  }

  @override
  int get hashCode => Object.hash(
        id,
        timestamp,
        type,
        medicationId,
        note,
      );

  @override
  String toString() =>
      'CheckInEntity(id=$id, type=${type.wire}, at=$timestamp, med=$medicationId)';
}
