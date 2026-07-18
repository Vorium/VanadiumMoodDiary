/// 报告历史（domain 实体）
///
/// 对应 Drift 表 `report_histories`，row → entity 翻译在 data 层 mapper 里。
class ReportHistoryEntity {
  final int id;
  final int windowDays;
  final DateTime generatedAt;
  final String userName;
  final String reportText;

  const ReportHistoryEntity({
    required this.id,
    required this.windowDays,
    required this.generatedAt,
    required this.userName,
    required this.reportText,
  });
}
