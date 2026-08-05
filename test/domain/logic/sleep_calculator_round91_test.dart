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

    test('7 天 bedtime 波动 5h+ → score = 1 (最不规律)', () {
      // 故意波动大: 22:00, 03:00, 04:00, 22:00, 03:00, 04:00, 22:00
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
  });
}
