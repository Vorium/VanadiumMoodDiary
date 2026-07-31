// v0.23 (Round 43 spen-3) care_strategies.dart 4 function isolated test
//
// 4 strategy 之前 (round 41) 抽出来后只在 care_engine_round17/19/3 综合测试
// 间接覆盖,没有 isolated 直接测。spen-3 标 off-by-one (isLateCheckInHabit
// `> 3` 处理 4 天,改 `> 2` 处理 3 天) 时一并补 isolated test。
//
// 覆盖:
// 1. isLateCheckInHabit — spen-3 off-by-one + 跨月 + 22:00 边界
// 2. isWeekendMissed — 周六 18 点临界 + 跨周末
// 3. isWeekPerfect — 7 天窗口边界 + 22 点后污染
// 4. isSecondDayMissed — 36h 边界 + 早上 10 点临界
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/logic/care_strategies.dart';
import 'package:flutter_test/flutter_test.dart';

/// 测试 helper: 生成 normal type check-in
CheckInEntity _ci(DateTime t) => CheckInEntity(
      id: t.millisecondsSinceEpoch,
      timestamp: t,
      type: CheckInType.normal,
      note: null,
      medicationId: null,
    );

void main() {
  // ============================================================
  // 1. isLateCheckInHabit — spen-3 off-by-one
  // ============================================================
  group('isLateCheckInHabit (spen-3 off-by-one)', () {
    // 固定 now = 2026-07-17 (周五) 14:00
    final now = DateTime(2026, 7, 17, 14, 0);

    test('最近 3 天都 22 点后 → true', () {
      // 7-17 23:00, 7-16 22:30, 7-15 22:00 — 3 天都晚
      final checkIns = [
        _ci(DateTime(2026, 7, 17, 23, 0)),
        _ci(DateTime(2026, 7, 16, 22, 30)),
        _ci(DateTime(2026, 7, 15, 22, 0)),
      ];
      expect(isLateCheckInHabit(checkIns, now), isTrue);
    });

    test('spen-3 修前 off-by-one: 第 4 天前不算 (现在 day 3 不该进入窗口)', () {
      // 关键 off-by-one 测试:
      // day 0/1/2 (7-17/16/15) 都不晚,只有 day 3 (7-14) 晚
      // 修前: 窗口含 7-14 → lateDays = 1 < 3 → false (pass)
      // 修后: 窗口只含 7-17/16/15 → lateDays = 0 < 3 → false (pass)
      // 真正的 off-by-one 区分: 7-15/16/17 都晚 + 7-14 也晚
      // 修前 4 天都晚 → lateDays = 4 >= 3 → true (但只 3 天该算)
      // 修后 3 天都晚 (7-15/16/17) → lateDays = 3 >= 3 → true
      // 区分: 7-15/16/17 都不晚 + 7-14 晚
      // 修前 (含 7-14): lateDays = 1 → false
      // 修后 (不含 7-14): lateDays = 0 → false
      // 这个 case 2 边都 false,无法区分
      // 真正能区分的 case 是: 7-15/16/17 都晚 + 7-14 也不晚
      // 修前: 4 天窗口(7-14/15/16/17)3 天晚 → true
      // 修后: 3 天窗口(7-15/16/17)3 天晚 → true
      // 还是无法区分
      // 区分 off-by-one: 7-15/16/17 中只有 2 天晚 + 7-14 晚
      // 修前 (含 7-14): 3 天晚 (7-14 + 7-15/16/17 中 2 天) → true (BUG: 只 3 天该算)
      // 修后 (不含 7-14): 2 天晚 → false (正确: 3 天窗口只有 2 天晚)
      final checkIns = [
        // 7-14 23:00 (day 3) — 修前会被算入,修后不
        _ci(DateTime(2026, 7, 14, 23, 0)),
        // 7-15 早 8 点 (day 2) — 准时
        _ci(DateTime(2026, 7, 15, 8, 0)),
        // 7-16 23:00 (day 1) — 晚
        _ci(DateTime(2026, 7, 16, 23, 0)),
        // 7-17 23:00 (day 0, today) — 晚
        _ci(DateTime(2026, 7, 17, 23, 0)),
      ];
      expect(
        isLateCheckInHabit(checkIns, now),
        isFalse,
        reason: 'spen-3 修后: 3 天窗口 (7-15/16/17) 只有 2 天晚 → false',
      );
    });

    test('空 list → false', () {
      expect(isLateCheckInHabit([], now), isFalse);
    });

    test('22:00 整点算 "22 点后" (>= 22)', () {
      // 7-17 22:00 整点, 7-16 22:00, 7-15 22:00
      final checkIns = [
        _ci(DateTime(2026, 7, 17, 22, 0)),
        _ci(DateTime(2026, 7, 16, 22, 0)),
        _ci(DateTime(2026, 7, 15, 22, 0)),
      ];
      expect(isLateCheckInHabit(checkIns, now), isTrue);
    });

    test('21:59 算 "22 点前" (< 22)', () {
      // 7-17 21:59 准时
      final checkIns = [
        _ci(DateTime(2026, 7, 17, 21, 59)),
        _ci(DateTime(2026, 7, 16, 21, 59)),
        _ci(DateTime(2026, 7, 15, 21, 59)),
      ];
      expect(isLateCheckInHabit(checkIns, now), isFalse);
    });

    test('同一天多次打卡只算 1 天 (Set 去重)', () {
      // 7-17 23:00 + 7-17 23:30 算同一天
      final checkIns = [
        _ci(DateTime(2026, 7, 17, 23, 0)),
        _ci(DateTime(2026, 7, 17, 23, 30)),
        _ci(DateTime(2026, 7, 16, 22, 30)),
        _ci(DateTime(2026, 7, 15, 22, 0)),
      ];
      expect(isLateCheckInHabit(checkIns, now), isTrue);
    });

    test('未排序输入也能正确处理 (假设 sortedDesc)', () {
      // 调用方约定 sortedDesc,我们自己排序一次再传
      final raw = [
        _ci(DateTime(2026, 7, 15, 22, 0)),
        _ci(DateTime(2026, 7, 17, 23, 0)),
        _ci(DateTime(2026, 7, 16, 22, 30)),
      ];
      // 调方按 timestamp 倒序排
      final sorted = [...raw]
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      expect(isLateCheckInHabit(sorted, now), isTrue);
    });

    test('跨月: 7-31 + 8-1 + 8-2 (now=8-2)', () {
      // now = 2026-08-02 14:00,最近 3 天: 8-2, 8-1, 7-31
      final monthNow = DateTime(2026, 8, 2, 14, 0);
      final checkIns = [
        _ci(DateTime(2026, 8, 2, 23, 0)), // 8-2
        _ci(DateTime(2026, 8, 1, 23, 0)), // 8-1
        _ci(DateTime(2026, 7, 31, 23, 0)), // 7-31
      ];
      expect(isLateCheckInHabit(checkIns, monthNow), isTrue);
    });

    test('跨年: 12-30 + 12-31 + 1-1 (now=1-1)', () {
      // now = 2027-01-01 14:00,最近 3 天: 1-1, 12-31, 12-30
      final yearNow = DateTime(2027, 1, 1, 14, 0);
      final checkIns = [
        _ci(DateTime(2027, 1, 1, 23, 0)), // 1-1
        _ci(DateTime(2026, 12, 31, 23, 0)), // 12-31
        _ci(DateTime(2026, 12, 30, 23, 0)), // 12-30
      ];
      expect(isLateCheckInHabit(checkIns, yearNow), isTrue);
    });
  });

  // ============================================================
  // 2. isWeekendMissed — 周六 18 点临界 + 跨周末
  // ============================================================
  group('isWeekendMissed', () {
    test('周六 17:59 — 之前周日有打卡 → 不触发 (now.hour < 18)', () {
      // 周六 17:59 — i=0 Saturday 被 hour<18 跳过, i=6 (7-12 Sunday) 有打卡
      final saturday = DateTime(2026, 7, 18, 17, 59);
      final checkIns = [
        _ci(saturday.subtract(const Duration(days: 1, hours: 12))), // 7-17 周五
        _ci(saturday.subtract(const Duration(days: 6, hours: 12))), // 7-12 周日
      ];
      expect(isWeekendMissed(checkIns, saturday), isFalse);
    });

    test('周六 18:01 触发 (no check-in on Saturday + hour >= 18)', () {
      // 周六 18:01,周五 12:00 打卡 (30h 内 → 不触发 secondDayMissed)
      // i=0 Saturday has no check-in → return true
      final saturdayEvening = DateTime(2026, 7, 18, 18, 1);
      // 7-12 周日也有打卡,所以触发原因只能是 i=0 Saturday
      final checkIns = [
        _ci(saturdayEvening.subtract(const Duration(hours: 30))), // 7-17 周五
        _ci(saturdayEvening
            .subtract(const Duration(days: 6, hours: 12))), // 7-12 周日
      ];
      expect(isWeekendMissed(checkIns, saturdayEvening), isTrue);
    });

    test('周六 18:01 但今天有打卡 + 之前周日有 → 不触发', () {
      // i=0 Saturday has check-in → continue; i=6 Sunday has check-in → continue
      final saturdayEvening = DateTime(2026, 7, 18, 18, 1);
      final checkIns = [
        _ci(DateTime(2026, 7, 18, 17, 0)), // 周六 17:00 (today)
        _ci(DateTime(2026, 7, 12, 12, 0)), // 7-12 周日
      ];
      expect(isWeekendMissed(checkIns, saturdayEvening), isFalse);
    });

    test('周日 20:00 + 周六 12:00 打卡 + 之前周日有 → 不触发', () {
      // i=0 7-19 Sunday: hour=20, no check-in? Has Sunday 12:00 → continue
      // i=1 7-18 Saturday: has 12:00 → continue
      final sunday = DateTime(2026, 7, 19, 20, 0);
      final checkIns = [
        _ci(DateTime(2026, 7, 19, 12, 0)), // 周日 12:00
        _ci(DateTime(2026, 7, 18, 12, 0)), // 周六 12:00
      ];
      expect(isWeekendMissed(checkIns, sunday), isFalse);
    });

    test('周日 20:00 + 今天没打卡 → 触发 (i=0 Sunday)', () {
      // i=0 7-19 Sunday: hour=20 >= 18, no check-in → return true
      final sunday = DateTime(2026, 7, 19, 20, 0);
      // 提供 7-12 周日 + 7-18 周六打卡, 7-19 (today) 没打卡
      final checkIns = [
        _ci(DateTime(2026, 7, 18, 12, 0)), // 周六 12:00
        _ci(DateTime(2026, 7, 12, 12, 0)), // 7-12 周日
      ];
      expect(isWeekendMissed(checkIns, sunday), isTrue);
    });
  });

  // ============================================================
  // 3. isWeekPerfect — 7 天窗口 + 22 点后污染
  // ============================================================
  group('isWeekPerfect', () {
    final now = DateTime(2026, 7, 17, 14, 0); // 周五 14:00

    test('最近 7 天每天 21 点打卡 → true', () {
      // 7-11 (周六) ~ 7-17 (周五) — 7 天都 21 点准时
      final checkIns = <CheckInEntity>[
        for (int i = 0; i < 7; i++) _ci(DateTime(2026, 7, 11 + i, 21, 0)),
      ];
      expect(isWeekPerfect(checkIns, now), isTrue);
    });

    test('7 天前有 22 点后打卡 + 最近 7 天 22 点前 → true (P3 fix)', () {
      // 8 天前 23 点打卡(应被忽略)
      final longAgo = now.subtract(const Duration(days: 8));
      final checkIns = <CheckInEntity>[
        _ci(longAgo.copyWith(hour: 23)),
        for (int i = 0; i < 7; i++) _ci(DateTime(2026, 7, 11 + i, 21, 0)),
      ];
      expect(isWeekPerfect(checkIns, now), isTrue);
    });

    test('最近 7 天 1 次 22 点后 → false', () {
      // 7-13 23:00 晚打卡
      final checkIns = <CheckInEntity>[
        for (int i = 0; i < 6; i++) _ci(DateTime(2026, 7, 11 + i, 21, 0)),
        _ci(DateTime(2026, 7, 17, 23, 0)), // 今天 23:00
      ];
      expect(isWeekPerfect(checkIns, now), isFalse);
    });

    test('缺 1 天打卡 → false', () {
      // 7-11 跳一天没打
      final checkIns = <CheckInEntity>[
        for (int i = 0; i < 7; i++)
          if (i != 0) _ci(DateTime(2026, 7, 11 + i, 21, 0)),
      ];
      expect(isWeekPerfect(checkIns, now), isFalse);
    });

    test('7 天前打卡不算"今天" (today - 6d 是最早一天)', () {
      // 只看 today, today-1, ..., today-6 共 7 天
      // today-7 之前的不算
      final checkIns = <CheckInEntity>[
        _ci(now.subtract(const Duration(days: 7))), // 7 天前 14:00 — 边界外
        for (int i = 0; i < 7; i++) _ci(DateTime(2026, 7, 11 + i, 21, 0)),
      ];
      // today-7 的 1 次打卡不污染;最近 7 天都准时 → true
      expect(isWeekPerfect(checkIns, now), isTrue);
    });
  });

  // ============================================================
  // 4. isSecondDayMissed — 36h 边界
  // ============================================================
  group('isSecondDayMissed', () {
    test('空 list → false', () {
      expect(isSecondDayMissed([], DateTime(2026, 7, 17, 14, 0)), isFalse);
    });

    test('35.9h 前 → false', () {
      // inMinutes = 35*60 + 54 = 2154 < 36*60=2160 → false
      final now = DateTime(2026, 7, 17, 14, 0);
      final checkIns = [
        _ci(now.subtract(const Duration(hours: 35, minutes: 54)))
      ];
      expect(isSecondDayMissed(checkIns, now), isFalse);
    });

    test('36h 前 + now.hour=14 → true', () {
      final now = DateTime(2026, 7, 17, 14, 0);
      final checkIns = [_ci(now.subtract(const Duration(hours: 36)))];
      expect(isSecondDayMissed(checkIns, now), isTrue);
    });

    test('36h 前 + now.hour=9 (早上 9 点) → false (now.hour < 10)', () {
      // now.hour < 10 — 不到 10 点不打扰
      final morningNow = DateTime(2026, 7, 17, 9, 0);
      final checkIns = [
        _ci(morningNow.subtract(const Duration(hours: 37))),
      ];
      expect(isSecondDayMissed(checkIns, morningNow), isFalse);
    });

    test('10:00 整点 + 36h 前 → true (now.hour >= 10)', () {
      // 10 点整, 36h 1 min 前打卡
      final morningNow = DateTime(2026, 7, 17, 10, 0);
      final checkIns = [
        _ci(morningNow.subtract(const Duration(hours: 36, minutes: 1))),
      ];
      expect(isSecondDayMissed(checkIns, morningNow), isTrue);
    });

    test('9:59 整点 + 36h 前 → false', () {
      final morningNow = DateTime(2026, 7, 17, 9, 59);
      final checkIns = [
        _ci(morningNow.subtract(const Duration(hours: 37))),
      ];
      expect(isSecondDayMissed(checkIns, morningNow), isFalse);
    });
  });
}
