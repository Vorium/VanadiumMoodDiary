// v0.30 round 90 (sub-spec 6 量表中心): 量表 entry domain entity
//
// 跨量表统一 entry, 10 量表共用 (PHQ-9 / GAD-7 / ISI / PSS / WHODAS /
// Level 2 抑郁/焦虑/躁狂/精神病 / ASRM)。
//
// R60 模式: 数据存 check_ins 表 type='<scale_id>', 分数 / 答案 编码进
// note 字段 (JSON 字符串) — 简单但灵活。R90 不开新表 (user 选 keep 兼容,
// schemaVersion 不变, 0 schema change)。
//
// 4 层架构: domain 层 0 flutter / 0 drift / 0 data, 纯 Dart 业务实体。

/// 量表提交记录（领域实体）
///
/// 字段含义：
/// - [id] DB id (check_ins.id)
/// - [timestamp] 提交时间
/// - [scaleId] 量表 id: 'phq9' / 'gad7' / 'whodas' / 'level2_depression' / ...
/// - [score] 总分 (0 - scale.totalRange)
/// - [severityRank] 严重度 rank (0 = 无, 4 = 极重)
/// - [answers] 各题答案列表 (PHQ-9 9 题, ASRM 5 题, ...)
/// - [note] 可选备注 (R60 老格式 free text 也走此字段, 兜底保留原文)
class AssessmentEntry {
  /// DB id (check_ins.id)
  final int id;

  /// 提交时间
  final DateTime timestamp;

  /// 量表 id: 'phq9' / 'gad7' / 'whodas' / 'level2_depression' / ...
  final String scaleId;

  /// 总分 (0 - scale.totalRange)
  final int score;

  /// 严重度 rank (0 = 无, 4 = 极重)
  final int severityRank;

  /// 各题答案 JSON: '[0, 1, 2, 0, 3]' (PHQ-9) / '[0, 1, 2, 0]' (ASRM)
  final List<int> answers;

  /// 可选备注
  ///
  /// R60 老格式: free text (如 '用户备注: 状态一般') → DAO 兜底保留原文
  /// R90 新格式: note 字段存 JSON, 此字段是 JSON 里的 'note' 字段 (用户填的)
  final String? note;

  const AssessmentEntry({
    required this.id,
    required this.timestamp,
    required this.scaleId,
    required this.score,
    required this.severityRank,
    required this.answers,
    this.note,
  });
}
