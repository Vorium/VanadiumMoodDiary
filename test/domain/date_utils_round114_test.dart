// R114 B1-6: calendarDaysBetween 注释称避 DST 但实现用 inDays → 海外 DST 假断
// (2026-08-16 标准审计 · 11-bottom-core-domain 发现 6)
//
// 修前: `bDay.difference(aDay).inDays` 在 DST 春季调表日两个相邻本地午夜只差
// 23h → inDays == 0 → streak 假断 / heatmap 差格 (秋季回拨 25h 同理)。
// 修后: DateTime.utc(y,m,d) 归一化 (UTC 无 DST, 差值恒为 24h 整数倍)。
//
// 测试用 tz 包构造 America/New_York DST 跳变日锁定语义:
// - 2026-03-08 → 03-09 本地午夜差 23h (spring forward)
// - 2026-11-01 → 11-02 本地午夜差 25h (fall back)
// 老实现会先 `DateTime(a.year, a.month, a.day)` 丢 location 再用本机时区相减 —
// 本机无 DST 时碰巧对, 跑在 DST 时区机器 (或 TZ env) 上老实现 fail, 新实现恒对。
import 'package:chroniccare/domain/logic/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tz_data.initializeTimeZones);

  group('calendarDaysBetween', () {
    test('同日不同时刻 → 0', () {
      expect(
        calendarDaysBetween(
          DateTime(2026, 3, 8, 0, 1),
          DateTime(2026, 3, 8, 23, 59),
        ),
        0,
      );
    });

    test('相邻日跨时刻 → 1', () {
      expect(
        calendarDaysBetween(
          DateTime(2026, 3, 8, 23, 59),
          DateTime(2026, 3, 9, 0, 1),
        ),
        1,
      );
    });

    test('DST spring-forward: NY 3/8 → 3/9 本地午夜差 23h → 仍 1 天', () {
      final ny = tz.getLocation('America/New_York');
      final a = tz.TZDateTime(ny, 2026, 3, 8);
      final b = tz.TZDateTime(ny, 2026, 3, 9);
      expect(b.difference(a).inHours, 23, reason: '前置: 确实跨 DST 跳变');
      expect(calendarDaysBetween(a, b), 1);
    });

    test('DST fall-back: NY 11/1 → 11/2 本地午夜差 25h → 仍 1 天', () {
      final ny = tz.getLocation('America/New_York');
      final a = tz.TZDateTime(ny, 2026, 11, 1);
      final b = tz.TZDateTime(ny, 2026, 11, 2);
      expect(b.difference(a).inHours, 25, reason: '前置: 确实跨 DST 回拨');
      expect(calendarDaysBetween(a, b), 1);
    });

    test('跨月 / 跨年', () {
      expect(
        calendarDaysBetween(DateTime(2026, 2, 28), DateTime(2026, 3, 1)),
        1,
      );
      expect(
        calendarDaysBetween(DateTime(2026, 12, 31), DateTime(2027, 1, 1)),
        1,
      );
    });

    test('b 早于 a → 负值', () {
      expect(
        calendarDaysBetween(DateTime(2026, 3, 9), DateTime(2026, 3, 8)),
        -1,
      );
    });

    test('忽略时分秒: 同日内 23h 差距也算 0 天', () {
      // 3/7 是 DST 跳变前一天 (无 DST 干扰), 0:30 → 23:30 正好 23h
      final a =
          tz.TZDateTime(tz.getLocation('America/New_York'), 2026, 3, 7, 0, 30);
      final b =
          tz.TZDateTime(tz.getLocation('America/New_York'), 2026, 3, 7, 23, 30);
      expect(b.difference(a).inHours, 23);
      expect(calendarDaysBetween(a, b), 0);
    });
  });

  group('isSameCalendarDay', () {
    test('同日 true / 异日 false', () {
      expect(
        isSameCalendarDay(
            DateTime(2026, 3, 8, 23, 59), DateTime(2026, 3, 8, 0, 1)),
        isTrue,
      );
      expect(
        isSameCalendarDay(DateTime(2026, 3, 8), DateTime(2026, 3, 9)),
        isFalse,
      );
    });
  });
}
