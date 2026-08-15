// R102 (P2): 日期工具函数单一来源
//
// 之前 safety_config_service.dart / safety_detector.dart / assessment_comparison.dart
// 各自内联 daysBetween / isSameDay, 3 份重复代码。
// 抽到 core/shared/ 供所有层共用 (shared/ 约束: 至少被 2 层用)。
//
// 1.1.0 round 4b (emotion-first refactor): safety_config_service /
// safety_detector 随外联服务整摘, 本文件唯一消费者剩 domain 层
// assessment_comparison — 从 core/shared/ 移入 domain/logic/ (满足
// shared/ 至少 2 层用约束, check_all 守门员)。

/// 跨日的"日历差"
///
/// 不直接用 Duration.inDays, 因为 DST / 时区可能导致 23.98 小时 ≈ 1 天
/// 之类边界。
int calendarDaysBetween(DateTime a, DateTime b) {
  final aDay = DateTime(a.year, a.month, a.day);
  final bDay = DateTime(b.year, b.month, b.day);
  return bDay.difference(aDay).inDays;
}

/// 判断两个 DateTime 是否在同一天 (本地日期)
bool isSameCalendarDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
