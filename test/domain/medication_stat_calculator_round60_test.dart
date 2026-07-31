// v0.27 round 60 (审计 M1): medication_stat_calculator 修正 — 药物未开始
// (startDate > periodEnd) 时不应报告 phantom missedDates.
//
// Bug 背景 (audit-domain-layer 3.2):
//   - `effectiveStart = med.startDate` (未来)  →  effectiveDays = 负数
//   - clamp(0, days) → expected = 0   ✓
//   - 但 daysWithDose = {} → missedDays = 14 → MissedDateBuilder.build 返回 14 个日期
//   - 报告渲染: "⚠️ 漏服: 7/1、7/2、..." 给"还没开始吃的药"
//
// 修正: 入口检查 `if (effectiveDays <= 0)` → 早返 empty stat.

import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/logic/medication_stat_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 报告窗口 = [2026-07-01, 2026-07-14] (14 天), "今天"= 2026-07-14
  final periodStart = DateTime(2026, 7, 1);
  final periodEnd = DateTime(2026, 7, 14);

  MedicationEntity med({
    int id = 1,
    String name = '氟西汀',
    DateTime? startDate,
  }) {
    return MedicationEntity(
      id: id,
      name: name,
      dosage: 40,
      dosageUnit: DosageUnit.mg,
      times: const [HourMinute(hour: 8, minute: 0)],
      startDate: startDate ?? DateTime(2026, 5, 1),
      endDate: null,
      isActive: true,
      refillAt: null,
      refillReminderDays: 7,
    );
  }

  group('MedicationStatCalculator — startDate 在窗口外', () {
    test('startDate = periodEnd 当天 → 仍计入 1 天 (回归 baseline)', () {
      // startDate = periodEnd → effectiveStart = periodEnd
      // effectiveDays = 14 - 13 = 1
      // 期望 1 次服药, 0 打卡 → 1 次漏服
      final stat = MedicationStatCalculator.calculate(
        med: med(startDate: periodEnd),
        days: 14,
        inWindow: const [],
        periodStart: periodStart,
      );
      expect(stat.expectedDoseCount, 1);
      expect(stat.actualDoseCount, 0);
      expect(stat.actualDoseDays, 0);
      expect(stat.missedDates.length, 1,
          reason: 'startDate = periodEnd 当天应有 1 天可服药');
    });

    test(
        'startDate 在 periodEnd 之后 1 天 (medication 未开始) → 不应有 phantom missedDates',
        () {
      // 修正前: 14 个 phantom 漏服日期
      // 修正后: empty stat (expected=0, missedDates=[])
      final futureStart = periodEnd.add(const Duration(days: 1));
      final stat = MedicationStatCalculator.calculate(
        med: med(startDate: futureStart),
        days: 14,
        inWindow: const [],
        periodStart: periodStart,
      );
      expect(stat.expectedDoseCount, 0, reason: '药物未开始 → 期望次数 = 0');
      expect(stat.actualDoseCount, 0);
      expect(stat.actualDoseDays, 0);
      expect(stat.missedDates, isEmpty, reason: '药物未开始 → 不应报告任何漏服日期');
    });

    test('startDate 远在未来 (3 个月后) → 完全不计入窗口', () {
      final farFuture = DateTime(2026, 10, 1);
      final stat = MedicationStatCalculator.calculate(
        med: med(startDate: farFuture),
        days: 14,
        inWindow: const [],
        periodStart: periodStart,
      );
      expect(stat.expectedDoseCount, 0);
      expect(stat.actualDoseCount, 0);
      expect(stat.actualDoseDays, 0);
      expect(stat.missedDates, isEmpty);
    });

    test(
        'startDate = periodStart (boundary, 早于 periodStart 不存在因为已 clamp) → 完整 14 天',
        () {
      // startDate < periodStart → effectiveStart = periodStart
      // effectiveDays = 14, expected = 14
      final stat = MedicationStatCalculator.calculate(
        med: med(startDate: DateTime(2026, 6, 1)), // 早于 periodStart
        days: 14,
        inWindow: const [],
        periodStart: periodStart,
      );
      expect(stat.expectedDoseCount, 14);
      expect(stat.actualDoseCount, 0);
      expect(stat.actualDoseDays, 0);
      expect(stat.missedDates.length, 14);
    });

    test('startDate = periodStart + 7 (窗口中间开始) → 7 天可服药', () {
      // effectiveStart = startDate, effectiveDays = 14 - 7 = 7
      final stat = MedicationStatCalculator.calculate(
        med: med(startDate: periodStart.add(const Duration(days: 7))),
        days: 14,
        inWindow: const [],
        periodStart: periodStart,
      );
      expect(stat.expectedDoseCount, 7);
      expect(stat.actualDoseCount, 0);
      expect(stat.missedDates.length, 7,
          reason: '7 天窗口中只有 1 天已服 (第 7 天), 还剩 6 天漏服 '
              '+ 1 天窗口外? 实际 effectiveDays=7, 0 打卡 → 7 天漏服');
    });

    test('startDate 在未来 + 已有打卡 (edge case): 未来打卡不算 → 仍 empty', () {
      // 修正后行为: effectiveDays ≤ 0 → 早返, 任何 checkIn (哪怕时间在窗口内) 都忽略
      // 这是修正应该有的语义: 药物未开始时, 不管打没打卡, 都不应计入"漏服"
      // (因为用户可能误打卡, 不应让"漏服"列表把未来打卡前的"空窗期"算成漏服)
      final futureStart = periodEnd.add(const Duration(days: 1));
      final stat = MedicationStatCalculator.calculate(
        med: med(startDate: futureStart),
        days: 14,
        inWindow: [
          CheckInEntity(
            id: 1,
            timestamp: DateTime(2026, 7, 10, 8, 0),
            type: CheckInType.normal,
            medicationId: 1,
            note: null,
          ),
        ],
        periodStart: periodStart,
      );
      expect(stat.expectedDoseCount, 0);
      expect(stat.actualDoseCount, 0,
          reason: 'effectiveDays ≤ 0 → actual 也清零, 不计未来打卡');
      expect(stat.missedDates, isEmpty);
    });
  });
}
