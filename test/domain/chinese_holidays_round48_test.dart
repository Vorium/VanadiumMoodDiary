// v0.24 round 48 (sp-zh P1-19): TDD test for ChineseHolidays
//
// 覆盖场景:
// 1. 春节、国庆、清明、劳动、端午、中秋 是 holiday
// 2. 普通工作日不是 holiday
// 3. 周末不是 holiday (但被 nextWorkdayAfter 跳过)
// 4. nextWorkdayAfter 跳过 holiday + 周末
// 5. 跨年 / 跨月 (DateTime 边界) 正确
//
// 数据 layer 暂时不集成到 reminder_scheduler,v0.25+ 集成
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/domain/logic/chinese_holidays.dart';

void main() {
  group('ChineseHolidays', () {
    group('isHoliday', () {
      test('2026 春节第一天是 holiday', () {
        // 2026-02-16 是除夕 (春节法定假日 2/16-2/22 共 7 天)
        expect(ChineseHolidays.isHoliday(DateTime(2026, 2, 16)), true);
      });

      test('2026 春节最后一天是 holiday', () {
        // 2/22 是初六
        expect(ChineseHolidays.isHoliday(DateTime(2026, 2, 22)), true);
      });

      test('2026 春节后第一天 (初七) 不是 holiday', () {
        // 2/23 是初七,正常上班
        expect(ChineseHolidays.isHoliday(DateTime(2026, 2, 23)), false);
      });

      test('2026 春节前一周不是 holiday', () {
        // 2026-02-09 (周一) 是普通工作日
        expect(ChineseHolidays.isHoliday(DateTime(2026, 2, 9)), false);
      });

      test('2026 国庆节是 holiday', () {
        expect(ChineseHolidays.isHoliday(DateTime(2026, 10, 1)), true);
        expect(ChineseHolidays.isHoliday(DateTime(2026, 10, 7)), true);
      });

      test('2026 清明节是 holiday', () {
        expect(ChineseHolidays.isHoliday(DateTime(2026, 4, 5)), true);
      });

      test('2026 劳动节是 holiday', () {
        expect(ChineseHolidays.isHoliday(DateTime(2026, 5, 1)), true);
      });

      test('2026 端午节是 holiday', () {
        expect(ChineseHolidays.isHoliday(DateTime(2026, 6, 19)), true);
      });

      test('2026 中秋节是 holiday', () {
        // 中秋 9/25 起 3 天
        expect(ChineseHolidays.isHoliday(DateTime(2026, 9, 25)), true);
        expect(ChineseHolidays.isHoliday(DateTime(2026, 9, 27)), true);
      });

      test('普通工作日不是 holiday', () {
        // 2026-07-15 (周三)
        expect(ChineseHolidays.isHoliday(DateTime(2026, 7, 15)), false);
      });

      test('元旦是 holiday', () {
        expect(ChineseHolidays.isHoliday(DateTime(2026, 1, 1)), true);
        expect(ChineseHolidays.isHoliday(DateTime(2027, 1, 1)), true);
        expect(ChineseHolidays.isHoliday(DateTime(2030, 1, 1)), true);
      });

      test('年份外的日期不是 holiday', () {
        // 2025 不在数据范围
        expect(ChineseHolidays.isHoliday(DateTime(2025, 10, 1)), false);
        // 2031 不在数据范围
        expect(ChineseHolidays.isHoliday(DateTime(2031, 1, 1)), false);
      });

      test('时间分量不影响 (只看 date 部分)', () {
        // 春节当天 23:59:59 仍是 holiday
        expect(
          ChineseHolidays.isHoliday(DateTime(2026, 2, 17, 23, 59, 59)),
          true,
        );
        // 春节当天 00:00:01 是 holiday
        expect(
          ChineseHolidays.isHoliday(DateTime(2026, 2, 17, 0, 0, 1)),
          true,
        );
      });
    });

    group('nextWorkdayAfter', () {
      test('普通工作日 → 明天是 workday', () {
        // 2026-07-15 (周三) → 2026-07-16 (周四)
        final next = ChineseHolidays.nextWorkdayAfter(DateTime(2026, 7, 15));
        expect(next, DateTime(2026, 7, 16));
      });

      test('周五 → 跳过周末到周一', () {
        // 2026-07-17 (周五) → 2026-07-20 (周一)
        final next = ChineseHolidays.nextWorkdayAfter(DateTime(2026, 7, 17));
        expect(next, DateTime(2026, 7, 20));
      });

      test('春节前 → 跳过整个春节假期', () {
        // 2026-02-13 (周五) → 2026-02-23 (周二,初七,法定假结束)
        final next = ChineseHolidays.nextWorkdayAfter(DateTime(2026, 2, 13));
        expect(next, DateTime(2026, 2, 23));
      });

      test('国庆中 → 跳过整个国庆假期', () {
        // 2026-10-05 (周一) → 2026-10-08 (周四)
        final next = ChineseHolidays.nextWorkdayAfter(DateTime(2026, 10, 5));
        expect(next, DateTime(2026, 10, 8));
      });

      test('跨年 (元旦假)', () {
        // 2026-12-31 (周四) → 2027-01-04 (周一,因为 1/1-1/3 元旦假)
        final next = ChineseHolidays.nextWorkdayAfter(DateTime(2026, 12, 31));
        expect(next, DateTime(2027, 1, 4));
      });

      test('跨月 (春节跨 2 月)', () {
        // 2026-02-28 (周六,春节假已结束是 2/24 起)→ 2026-03-02 (周一)
        // 2/24-2/27 是工作日,2/28 周六,3/1 周日 → 3/2 周一
        final next = ChineseHolidays.nextWorkdayAfter(DateTime(2026, 2, 28));
        expect(next, DateTime(2026, 3, 2));
      });
    });
  });
}
