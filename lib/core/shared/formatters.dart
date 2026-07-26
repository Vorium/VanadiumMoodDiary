// v0.25 round 56d (spen P0 #15 cleanup): formatters 改走 intl DateFormat
//
// 之前手动 _pad + 字符串拼接, 改用 `intl` package 的 DateFormat:
// - locale-aware (未来 zh/en 切换不用改这里)
// - 不需手写 _pad
// - 业界标准格式模式 (yyyy-MM-dd / HH:mm)
//
// public API 不变 (Formatters.date / monthDay / time / dateTime / dateCompact),
// 现有 9 个 caller (medication_report / stat_calculator / widgets 等) 不动.
//
// 注: 现在用 fixed format pattern (yyyy-MM-dd 等), 跨 locale 输出相同.
//   真要 zh locale "2026年07月13日" 等再换 'yyyy年MM月dd日' + 'zh' locale.
import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:intl/intl.dart';

/// 统一格式化工具(共享层: domain + data + presentation 均可使用)
class Formatters {
  Formatters._();

  // 静态 DateFormat 实例 (避免每次调用 new DateFormat, 性能 + 1)
  // pattern 固定所以可以 const-equivalent (实际不能 const, 但只 1 次 lazy init).
  static final DateFormat _dateFmt = DateFormat('yyyy-MM-dd');
  static final DateFormat _monthDayFmt = DateFormat('MM/dd');
  static final DateFormat _timeFmt = DateFormat('HH:mm');
  static final DateFormat _dateCompactFmt = DateFormat('yyyyMMdd');

  /// 完整日期:2026-07-13
  static String date(DateTime d) => _dateFmt.format(d);

  /// 月-日:07/13
  static String monthDay(DateTime d) => _monthDayFmt.format(d);

  /// 时:分:14:08
  static String time(DateTime d) => _timeFmt.format(d);

  /// 完整日期 + 时:分:2026-07-13 14:08
  static String dateTime(DateTime d) => '${date(d)} ${time(d)}';

  /// 紧凑年月日(用于文件名):20260713
  static String dateCompact(DateTime d) => _dateCompactFmt.format(d);

  /// 剂量:整数无小数,否则原样
  static String dosage(double value, DosageUnit unit) {
    // 标准四舍五入(Dart round() 用银行家舍入,医疗场景应用 round-half-up)
    final rounded = (value + 0.5).floorToDouble().toInt();
    if ((value - rounded).abs() < 1e-9) {
      return '$rounded${unit.id}';
    }
    return '$value${unit.id}';
  }
}
