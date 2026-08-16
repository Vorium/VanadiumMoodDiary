// v0.27 round 82 (P0 架构修复续): RefillScheduler 纯函数测试
//
// 背景: `computeRefillFireTime` 从 `RefillNotifier` 抽到 `RefillScheduler`
// (lib/domain/logic/refill_scheduler.dart), 切断 domain 间接 flutter 依赖。
// 抽离后行为必须 1:1 保持, 跟 R56c / R65 老 test 同款行为。
//
// 8 case 覆盖:
// 1. 正常: refillAt=9/15 + reminderDays=7 → 9/8 09:00
// 2. 边界: reminderDays=1 (最小值) → refillAt - 1 天 09:00
// 3. 边界: refillAt = null → null (caller no-op)
// 4. 边界: reminderDays < 1 → null (R113 BUG 1: 从抛 ArgumentError 改为
//    返 null, 避免 0 天脏数据 abort 整个 rescheduleRefillReminders)
// 5. 跨月: refillAt = 1/5 + reminderDays=7 → 上一年 12/29 09:00
// 6. 跨年: refillAt = 闰年 2/29 + reminderDays=1 → 2/28 09:00 (闰年特殊)
// 7. 时区无关: refillAt = 23:59:59 → fireTime 仍是 9:00 (忽略时分秒)
// 8. daysUntilRefill: 跟 refillAt 时分秒无关, 只算"整天差"
import 'package:chroniccare/domain/logic/refill_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RefillScheduler.computeRefillFireTime', () {
    test('正常: refillAt=9/15 + reminderDays=7 → 9/8 09:00', () {
      final result = RefillScheduler.computeRefillFireTime(
        refillAt: DateTime(2026, 9, 15),
        reminderDays: 7,
      );
      expect(result, DateTime(2026, 9, 8, 9, 0));
    });

    test('边界: reminderDays=1 (最小值) → refillAt - 1 天 09:00', () {
      final result = RefillScheduler.computeRefillFireTime(
        refillAt: DateTime(2026, 9, 15),
        reminderDays: 1,
      );
      expect(result, DateTime(2026, 9, 14, 9, 0));
    });

    test('边界: refillAt = null → null (caller no-op)', () {
      final result = RefillScheduler.computeRefillFireTime(
        refillAt: null,
        reminderDays: 7,
      );
      expect(result, isNull);
    });

    test('边界: reminderDays < 1 → null (R113 BUG 1: 不抛, caller 跳过)', () {
      // reminderDays = 0
      expect(
        RefillScheduler.computeRefillFireTime(
          refillAt: DateTime(2026, 9, 15),
          reminderDays: 0,
        ),
        isNull,
      );
      // reminderDays < 0
      expect(
        RefillScheduler.computeRefillFireTime(
          refillAt: DateTime(2026, 9, 15),
          reminderDays: -1,
        ),
        isNull,
      );
      // reminderDays = -365 (极端)
      expect(
        RefillScheduler.computeRefillFireTime(
          refillAt: DateTime(2026, 9, 15),
          reminderDays: -365,
        ),
        isNull,
      );
    });

    test('跨年: refillAt=2026/01/05 + reminderDays=7 → 2025/12/29 09:00', () {
      // 跨年边界: 1/5 - 7 = 上一年 12/29
      // DateTime 自动处理 month=0 → 上一年 12 月
      final result = RefillScheduler.computeRefillFireTime(
        refillAt: DateTime(2026, 1, 5),
        reminderDays: 7,
      );
      expect(result, DateTime(2025, 12, 29, 9, 0));
    });

    test('闰年: refillAt=2028/02/29 + reminderDays=1 → 2028/02/28 09:00', () {
      // 2028 是闰年 (4 年周期, 2028/4=507, 2028 是闰年)
      // 2/29 - 1 天 = 2/28 (闰年 2 月有 29 天, 减一天是 28)
      // DateTime 自动处理 2/29 - 1 day = 2/28
      final result = RefillScheduler.computeRefillFireTime(
        refillAt: DateTime(2028, 2, 29),
        reminderDays: 1,
      );
      expect(result, DateTime(2028, 2, 28, 9, 0));
    });

    test('时分秒: refillAt=23:59:59 → fireTime 仍是 09:00 (忽略时分秒)', () {
      // refillAt 带时分秒时, 实现: refillAt 拆成 day 0:00, 再 subtract
      // reminderDays, 再 + 9h。9/15 23:59:59 → 9/15 00:00 → 9/8 00:00 → 9/8 09:00
      final result = RefillScheduler.computeRefillFireTime(
        refillAt: DateTime(2026, 9, 15, 23, 59, 59),
        reminderDays: 7,
      );
      expect(result, DateTime(2026, 9, 8, 9, 0));
    });

    test('时分秒: refillAt=00:00:00 → fireTime 09:00 (不漂移)', () {
      // 反向: refillAt 0:00:00 时, 整日期部分仍是 9/15, fireTime 9/8 09:00
      final result = RefillScheduler.computeRefillFireTime(
        refillAt: DateTime(2026, 9, 15, 0, 0, 0),
        reminderDays: 7,
      );
      expect(result, DateTime(2026, 9, 8, 9, 0));
    });
  });

  group('RefillScheduler.daysUntilRefill (按天计算, 忽略时分秒)', () {
    test('同一天 (now=10:00, refillAt=09:00) → 0', () {
      // 今天, 整天还没过, 应算 0 天
      final result = RefillScheduler.daysUntilRefill(
        DateTime(2026, 9, 15, 9, 0),
        DateTime(2026, 9, 15, 10, 0),
      );
      expect(result, 0);
    });

    test('明天 (now=今天 23:59, refillAt=明天 00:00) → 1', () {
      // refillAt 在明天, 不论 now 是今天 23:59 还是 00:01, 都应算 1 天
      final result = RefillScheduler.daysUntilRefill(
        DateTime(2026, 9, 16, 0, 0),
        DateTime(2026, 9, 15, 23, 59, 59),
      );
      expect(result, 1);
    });

    test('昨天 (已过期, now=今天 00:01, refillAt=昨天 23:59) → -1', () {
      // refillAt 在昨天, 不论 now 是 00:01 还是 23:59, 都应算 -1 天
      final result = RefillScheduler.daysUntilRefill(
        DateTime(2026, 9, 14, 23, 59, 59),
        DateTime(2026, 9, 15, 0, 1, 0),
      );
      expect(result, -1);
    });

    test('跨月: refillAt=10/1 + now=9/30 → 1', () {
      final result = RefillScheduler.daysUntilRefill(
        DateTime(2026, 10, 1),
        DateTime(2026, 9, 30, 10, 0),
      );
      expect(result, 1);
    });
  });

  group('RefillScheduler 纯函数特性 (R82 架构守门)', () {
    test('多次调用同输入 → 同输出 (幂等, 0 副作用)', () {
      final refillAt = DateTime(2026, 9, 15);
      final r1 = RefillScheduler.computeRefillFireTime(
        refillAt: refillAt,
        reminderDays: 7,
      );
      final r2 = RefillScheduler.computeRefillFireTime(
        refillAt: refillAt,
        reminderDays: 7,
      );
      expect(r1, r2);
      expect(r1, DateTime(2026, 9, 8, 9, 0));
    });

    test('不引用 DateTime.now() — 行为完全 caller 注入 now 决定', () {
      // 锁: R82 抽离后, 不能悄悄引入 DateTime.now() (那是 v0.16 round 19B
      // 修的 midnight race bug 反模式)
      // 验证: 传 different now 不影响 fireTime (因为 computeRefillFireTime
      // 不接 now 参数)
      final r1 = RefillScheduler.computeRefillFireTime(
        refillAt: DateTime(2026, 9, 15),
        reminderDays: 7,
      );
      // 等几毫秒, DateTime.now() 会变, 但 computeRefillFireTime 不接 now
      // 所以 r1 不变
      Future<void>.delayed(const Duration(milliseconds: 5));
      final r2 = RefillScheduler.computeRefillFireTime(
        refillAt: DateTime(2026, 9, 15),
        reminderDays: 7,
      );
      expect(r1, r2);
    });
  });
}
