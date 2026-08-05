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
//
// v0.28 round 65 (spzh P2-H): `label` 从硬编中文 getter → i18n 方法
// ([labelL10n])，caller 传 AppLocalizations 走 zh/en/zh_Hant。
// 4 个 i18n key: `checkInTypeDaily` / `checkInTypeTemp` /
// `checkInTypePhq9` / `checkInTypeGad7`。
//
// 注意：domain 层 0 flutter 边界 — [labelL10n] 接受 caller 注入的
// `String? override` (i18n 字符串由 caller 解析), 不直接 import
// flutter_localizations。`String` 注入同 `core/l10n/strings.dart` 模式。

import 'package:chroniccare/core/shared/domain_value.dart';

/// 打卡类型
///
/// 原 Drift 存的是 string (`'normal'` / `'temp'` / `'phq9'` / `'gad7'`)。
/// 这里用 enum 替代，UI 和 domain 层不再写裸 string 比较。
///
/// v0.30 round 91 (fix): 加 8 个 R90 新量表 enum 值
/// (isi / pss / whodas / level2_depression / level2_anxiety /
/// level2_mania / asrm / level2_psychosis) — 之前 R90 reader (DAO) 解析
/// `whodas` / `level2_depression` 等 wire string 时, mapper `fromWire`
/// fallback 到 `normal`, `isAssessment` 只识别 phq9/gad7 → 新量表 entry
/// 在 day_detail / assessment_history 看不见。
enum CheckInType {
  /// 每日打卡
  normal('normal'),

  /// 临时吃药（不影响 streak）
  temp('temp'),

  /// PHQ-9 抑郁筛查
  phq9('phq9'),

  /// GAD-7 焦虑筛查
  gad7('gad7'),

  /// ISI 失眠严重指数
  isi('isi'),

  /// PSS 压力量表
  pss('pss'),

  /// WHODAS 2.0 残疾评定
  whodas('whodas'),

  /// DSM-5 Level 2 抑郁严重度
  level2Depression('level2_depression'),

  /// DSM-5 Level 2 焦虑严重度
  level2Anxiety('level2_anxiety'),

  /// DSM-5 Level 2 躁狂严重度
  level2Mania('level2_mania'),

  /// ASRM 自评躁狂量表
  asrm('asrm'),

  /// DSM-5 Level 2 精神病性症状
  level2Psychosis('level2_psychosis');

  /// 数据库存的字面量
  final String wire;
  const CheckInType(this.wire);

  /// 10 个评估量表的 wire string 集合
  ///
  /// v0.30 round 91 (fix): 集中维护, 跟 `CheckInDao.watchAssessments` 10 type
  /// IN 列表对齐。`isAssessment` getter 走这个集合判断。
  static const Set<String> _assessmentScaleIds = {
    'phq9',
    'gad7',
    'isi',
    'pss',
    'whodas',
    'level2_depression',
    'level2_anxiety',
    'level2_mania',
    'asrm',
    'level2_psychosis',
  };

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
  /// i18n 简短描述 — caller 传 AppLocalizations 拿 zh/en/zh_Hant
  ///
  /// v0.28 round 65 (spzh P2-H): 替代之前的硬编中文 `label` getter。
  /// domain 0 flutter 边界用 override 模式同 `Strings` — 传 l10n 即
  /// 走 ARB, 不传返中文 fallback (老 test 兼容 / 单测用)。
  ///
  /// v0.30 round 91 (fix): 8 个新量表 (R90) 走 generic 兜底
  /// `'心理量表评估'` — 它们没有 `checkInTypeXxx` l10n key (R65 只加
  /// 了 phq9 / gad7, R90 i18n 跟 R78 一致, 题目 + 名称走 ARB,
  /// `checkInType*` label 留 v1.0)。Caller 应优先用 scale registry
  /// `scaleById(type.wire).displayName` 拿量表名, 而不是这个 fallback。
  String labelL10n({String? override}) {
    if (override != null) return override;
    switch (this) {
      case CheckInType.normal:
        return '每日打卡';
      case CheckInType.temp:
        return '临时吃药';
      case CheckInType.phq9:
        return 'PHQ-9 评估';
      case CheckInType.gad7:
        return 'GAD-7 评估';
      case CheckInType.isi:
      case CheckInType.pss:
      case CheckInType.whodas:
      case CheckInType.level2Depression:
      case CheckInType.level2Anxiety:
      case CheckInType.level2Mania:
      case CheckInType.asrm:
      case CheckInType.level2Psychosis:
        return '心理量表评估';
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
  ///
  /// v0.30 round 91 (fix): 跨 10 量表 (R60 phq9/gad7 + R90 8 个新) — 用
  /// `CheckInType._assessmentScaleIds` 集合判断, 不写裸 enum 比较。
  /// 影响: day_detail / assessment_history / assessment_record.tryFromEntity
  /// 3 处 `c.isAssessment` 门控现在能识别新量表, 新量表 entry 不再被吞。
  bool get isAssessment =>
      CheckInType._assessmentScaleIds.contains(type.wire);

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
