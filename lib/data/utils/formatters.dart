/// 统一格式化工具
///
/// 把散落在 [MedicationReport] / [MedicationReportPdf] 里的
/// `_fmt` / `_fmtDateTime` / `_fmtMd` / `_fmtTime` / `_fmtDosage`
/// 集中到一处。所有展示层（纯文本报告、PDF、UI）共用。
class Formatters {
  Formatters._();

  /// 完整日期：2026-07-13
  static String date(DateTime d) =>
      '${d.year}-${_pad(d.month)}-${_pad(d.day)}';

  /// 月-日：07/13
  static String monthDay(DateTime d) => '${_pad(d.month)}/${_pad(d.day)}';

  /// 时:分：14:08
  static String time(DateTime d) => '${_pad(d.hour)}:${_pad(d.minute)}';

  /// 完整日期 + 时:分：2026-07-13 14:08
  static String dateTime(DateTime d) => '${date(d)} ${time(d)}';

  /// 紧凑年月日（用于文件名）：20260713
  static String dateCompact(DateTime d) =>
      '${d.year}${_pad(d.month)}${_pad(d.day)}';

  /// 剂量：整数无小数，否则原样
  /// 40.0 → "40mg"，0.4 → "0.4mg"
  ///
  /// N23 fix: 用 `abs < 1e-9` 容差替代 `==`,避免
  /// 41.0000000001 这种浮点边界显示成 "41.0000000001mg"
  /// 同时 0.4 仍然走 "0.4mg" 分支
  static String dosage(double value, String unit) {
    final rounded = value.round();
    if ((value - rounded).abs() < 1e-9) {
      return '$rounded$unit';
    }
    return '$value$unit';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
