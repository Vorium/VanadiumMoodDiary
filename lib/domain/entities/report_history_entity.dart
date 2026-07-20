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

  ReportHistoryEntity copyWith({
    int? id,
    int? windowDays,
    DateTime? generatedAt,
    String? userName,
    String? reportText,
  }) {
    return ReportHistoryEntity(
      id: id ?? this.id,
      windowDays: windowDays ?? this.windowDays,
      generatedAt: generatedAt ?? this.generatedAt,
      userName: userName ?? this.userName,
      reportText: reportText ?? this.reportText,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportHistoryEntity &&
          other.id == id &&
          other.windowDays == windowDays &&
          other.generatedAt == generatedAt &&
          other.userName == userName &&
          other.reportText == reportText;

  @override
  int get hashCode =>
      Object.hash(id, windowDays, generatedAt, userName, reportText);

  @override
  String toString() =>
      'ReportHistoryEntity(id: $id, windowDays: $windowDays, generatedAt: $generatedAt)';
}
