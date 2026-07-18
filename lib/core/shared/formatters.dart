/// 统一格式化工具（共享层：domain + data + presentation 均可使用）
class Formatters {
  Formatters._();

  /// 完整日期：2026-07-13
  static String date(DateTime d) => '${d.year}-${_pad(d.month)}-${_pad(d.day)}';

  /// 月-日：07/13
  static String monthDay(DateTime d) => '${_pad(d.month)}/${_pad(d.day)}';

  /// 时：分：14:08
  static String time(DateTime d) => '${_pad(d.hour)}:${_pad(d.minute)}';

  /// 完整日期 + 时：分：2026-07-13 14:08
  static String dateTime(DateTime d) => '${date(d)} ${time(d)}';

  /// 紧凑年月日（用于文件名）：20260713
  static String dateCompact(DateTime d) =>
      '${d.year}${_pad(d.month)}${_pad(d.day)}';

  /// 剂量：整数无小数，否则原样
  static String dosage(double value, String unit) {
    final rounded = value.round();
    if ((value - rounded).abs() < 1e-9) {
      return '$rounded$unit';
    }
    return '$value$unit';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
