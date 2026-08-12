// v0.30 round 91 (sub-spec 7 日常追踪): SleepCalculator 纯函数 行为锁定
//
// 覆盖 (TDD red→green):
// 1. durationMin 跨午夜 (23:00 → 07:30 = 510 min) — 精神心理用户常见
// 2. durationMin 不跨午夜 (22:00 → 06:00 next day = 480 min)
// 3. durationMin 0 min edge (bedtime = wakeTime, 罕见但需 0)
// 4. regularityScore 7 天 bedtime 一致 → 5
// 5. regularityScore 7 天 bedtime 乱 → 1
// 6. regularityScore < 3 天 → null
//
// 复用 R60 R90 logic calculator 模式: StreakCalculator, AssessmentComparison
// 等都是纯函数 + static method, 0 flutter 0 drift。

import 'package:chroniccare/domain/logic/sleep_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SleepCalculator.durationMin (跨午夜支持)', () {
    test('23:00 → 07:30 跨午夜 = 510 min (8h30min)', () {
      final bedtime = DateTime(2026, 8, 1, 23, 0);
      final wakeTime = DateTime(2026, 8, 2, 7, 30);
      expect(SleepCalculator.durationMin(bedtime, wakeTime), 510);
    });

    test('22:00 → 06:00 跨午夜 = 480 min (8h)', () {
      final bedtime = DateTime(2026, 8, 1, 22, 0);
      final wakeTime = DateTime(2026, 8, 2, 6, 0);
      expect(SleepCalculator.durationMin(bedtime, wakeTime), 480);
    });

    test('0:00 → 0:00 同时间 = 0 min (edge case)', () {
      // 罕见但 spec 没排除, 0 min 表示"没睡"
      final ts = DateTime(2026, 8, 1, 0, 0);
      expect(SleepCalculator.durationMin(ts, ts), 0);
    });
  });

  group('SleepCalculator.regularityScore (7 天 bedtime 标准差 → 1-5)', () {
    test('7 天 bedtime 完全一致 → score = 5 (最规律)', () {
      // 7 天都 22:00 入睡
      final entries = List.generate(
        7,
        (i) => DateTime(2026, 7, i + 1, 22, 0),
      );
      expect(SleepCalculator.regularityScore(entries), 5);
    });

    // v0.32 R110 round 7a (B1-3): 圆形统计后重算 — 22:00~04:00 聚簇
    // Mardia σ ≈ 172min ≥ 120 → band 1 (跟原断言一致, bands 未动)
    test('7 天 bedtime 波动 5h+ (22:00-04:00 聚簇) → score = 1 (最不规律)', () {
      // 22:00, 03:00, 04:00 交替, 主导入睡窗口 22:00-04:00
      final entries = [
        DateTime(2026, 7, 1, 22, 0),
        DateTime(2026, 7, 2, 3, 0),
        DateTime(2026, 7, 3, 4, 0),
        DateTime(2026, 7, 4, 22, 0),
        DateTime(2026, 7, 5, 3, 0),
        DateTime(2026, 7, 6, 4, 0),
        DateTime(2026, 7, 7, 22, 0),
      ];
      expect(SleepCalculator.regularityScore(entries), 1);
    });

    test('< 3 天数据 → null (不够算标准差)', () {
      // < 3 天 = 无统计学意义
      final entries = [
        DateTime(2026, 7, 1, 22, 0),
        DateTime(2026, 7, 2, 22, 0),
      ];
      expect(SleepCalculator.regularityScore(entries), isNull);
    });

    // v0.32 R110 round 7a (B1-3): 圆形时间 — 跨午夜交替 (23:50/00:10)
    // 是"最规律"的作息, 线性 mean/stdDev 会算出 ~710min 巨大 stdDev → 1
    test('跨午夜交替 23:50/00:10 → score = 5 (B1-3 circular)', () {
      final entries = [
        DateTime(2026, 7, 1, 23, 50),
        DateTime(2026, 7, 2, 0, 10),
        DateTime(2026, 7, 3, 23, 50),
        DateTime(2026, 7, 4, 0, 10),
        DateTime(2026, 7, 5, 23, 50),
        DateTime(2026, 7, 6, 0, 10),
        DateTime(2026, 7, 7, 23, 50),
      ];
      expect(SleepCalculator.regularityScore(entries), 5,
          reason: '23:50/00:10 交替是跨午夜规律作息, 圆形距离 ~10min');
    });

    test('跨午夜但 3 天交替 → 仍 ≥ 4 (B1-3 circular 小样本)', () {
      final entries = [
        DateTime(2026, 7, 1, 23, 50),
        DateTime(2026, 7, 2, 0, 10),
        DateTime(2026, 7, 3, 23, 50),
      ];
      final score = SleepCalculator.regularityScore(entries);
      expect(score, isNotNull);
      expect(score, greaterThanOrEqualTo(4));
    });

    test('圆形均匀分布 00/08/16 点 → score = 1 (无中心)', () {
      final entries = [
        DateTime(2026, 7, 1, 0, 0),
        DateTime(2026, 7, 2, 8, 0),
        DateTime(2026, 7, 3, 16, 0),
        DateTime(2026, 7, 4, 0, 0),
        DateTime(2026, 7, 5, 8, 0),
        DateTime(2026, 7, 6, 16, 0),
        DateTime(2026, 7, 7, 0, 0),
      ];
      expect(SleepCalculator.regularityScore(entries), 1,
          reason: '无主导入睡时段的均匀分布 = 最不规律');
    });

    test('23:50±40min 跨午夜 (±40 聚簇) → Mardia σ≈31min → 4 (band 边界)', () {
      final entries = [
        DateTime(2026, 7, 1, 23, 50),
        DateTime(2026, 7, 2, 23, 10),
        DateTime(2026, 7, 3, 0, 30),
        DateTime(2026, 7, 4, 23, 50),
        DateTime(2026, 7, 5, 23, 10),
        DateTime(2026, 7, 6, 0, 30),
        DateTime(2026, 7, 7, 23, 50),
      ];
      expect(SleepCalculator.regularityScore(entries), 4);
    });
  });
}
