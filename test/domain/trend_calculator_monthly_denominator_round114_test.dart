// R114 B1-5: monthlyBreakdown 当月分母用整月天数 → 依从率系统性偏低
// (2026-08-16 标准审计 · 11-bottom-core-domain 发现 5)
//
// 修前: `totalDays = nextMonth.difference(m).inDays` 对当前月 (i=0) 返回完整
// 月长 (8 月=31), 但 checkedDays 最多只到今天 → 月中报告依从率被稀释
// (8/16 时上限 16/31=52%), 柱状图首柱永久偏低。
// 修后: 当前月分母 = 已过天数 (today.day, 从月首到 now); 历史月保留整月天数。
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/logic/trend_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

CheckInEntity _ciAt(DateTime t) {
  return CheckInEntity(
    id: 0,
    timestamp: t,
    type: CheckInType.fromWire('normal'),
    medicationId: null,
    note: null,
  );
}

void main() {
  group('monthlyBreakdown 当月分母 = 已过天数 (R114 B1-5)', () {
    test('月中 8/16: 当月分母 16 (非整月 31), 依从率不被稀释', () {
      final now = DateTime(2026, 8, 16, 20, 0);
      final list = TrendCalculator.monthlyBreakdown(
        checkIns: [
          _ciAt(DateTime(2026, 8, 1, 9, 0)),
          _ciAt(DateTime(2026, 8, 2, 9, 0)),
        ],
        months: 3,
        now: now,
      );
      // months 正序: 6 月, 7 月, 8 月 (i=0 是最后一项 = 当前月)
      final aug = list.last;
      expect(aug.month, DateTime(2026, 8, 1));
      expect(aug.totalDays, 16);
      expect(aug.checkedDays, 2);
      expect(aug.rate, closeTo(2 / 16, 1e-9));
    });

    test('历史月: 分母 = 整月天数 (7 月 31 天)', () {
      final list = TrendCalculator.monthlyBreakdown(
        checkIns: [_ciAt(DateTime(2026, 7, 15))],
        months: 3,
        now: DateTime(2026, 8, 16, 12, 0),
      );
      final jul = list[1];
      expect(jul.month, DateTime(2026, 7, 1));
      expect(jul.totalDays, 31);
    });

    test('月末 23:59: 分母 = 当月完整天数', () {
      final list = TrendCalculator.monthlyBreakdown(
        checkIns: const [],
        months: 1,
        now: DateTime(2026, 8, 31, 23, 59),
      );
      expect(list.single.totalDays, 31);
    });

    test('月首 00:00: 分母 = 1 (当天已开始)', () {
      final list = TrendCalculator.monthlyBreakdown(
        checkIns: const [],
        months: 1,
        now: DateTime(2026, 8, 1, 0, 0),
      );
      expect(list.single.totalDays, 1);
    });

    test('跨年窗口: 上月是 12 月 (31 天) + 当前 1 月按已过天数', () {
      final list = TrendCalculator.monthlyBreakdown(
        checkIns: const [],
        months: 2,
        now: DateTime(2027, 1, 5, 8, 0),
      );
      expect(list[0].month, DateTime(2026, 12, 1));
      expect(list[0].totalDays, 31);
      expect(list[1].month, DateTime(2027, 1, 1));
      expect(list[1].totalDays, 5);
    });
  });
}
