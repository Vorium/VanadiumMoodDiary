// v0.21 Round 22 (P1-18 修复): placeholder
//
// 原本计划从 trend_charts.dart 拆出 AssessmentHistoryChart 单独文件,
// 但 trend_charts 用了 fl_chart 0.69.2 包里未导出的 SpotKey typedef,
// 编译时 SpotKey 未定义。trend_charts 已通过 flutter test 验证可用,
// 不动。后续 trend 拆分工作留 v0.22 round 23 处理。
