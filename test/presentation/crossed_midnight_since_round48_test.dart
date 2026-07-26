// v0.24 round 48 (sp-en P1-9): crossedMidnightSince direct unit test
//
// 现状: app.dart:75-89 的 crossedMidnightSince 是个 @visibleForTesting top-level
// 函数, 4 行业务, 之前只在 AppRoot widget 间接用 (didChangeAppLifecycleState)。
// v0.21 (P0-4 fix) 加它的时候没直接测, superpowers-en 视角这是最大 test gap:
// 这是 streakSummaryProvider 跨日 invalidate 的关键防御, 万一实现坏了
// "飞国际航班 / 系统时间被拨回 / app 被杀后重启跨日" 这 3 种场景
// 都会静默失修 (streak 数字冻结, 用户次日打开才看到错的)。
//
// 本 test 锁 4 个核心行为:
// 1. 同日 00:00:05 之前 → false (buffer 之内, 视为同一天)
// 2. 跨过 00:00:05 后到次日 00:00:05 之前 → false (还在同一天)
// 3. 跨到第二天 (00:00:05 之后) → true
// 4. 系统时间被拨回 (lastCheck > now) → true (防御性, invalidate 保险)
//
// 5. 00:00:05 边界精确切: 0:00:04 / 0:00:05 / 0:00:06
//
// 0 flutter 0 drift 纯 Dart 测, 最快。
import 'package:chroniccare/app.dart' show crossedMidnightSince;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('crossedMidnightSince (v0.24 round 48 sp-en P1-9)', () {
    test('同一天 (lastCheck 早于 now 但 都在 00:00:05 之前) → false', () {
      // lastCheck 14:00, now 23:59:59 同一天
      // lastCutoff = 14:00 的 00:00:05 = 14-00-00:00:05
      // nowCutoff = 23:59:59 的 00:00:05 = 14-00-00:00:05
      // 同一时刻 → nowCutoff.isAfter(lastCutoff) = false
      final lastCheck = DateTime(2026, 7, 17, 14, 0);
      final now = DateTime(2026, 7, 17, 23, 59, 59);
      expect(crossedMidnightSince(lastCheck, now), isFalse);
    });

    test('同日 14:00 → 23:00 → false', () {
      // 典型的"用户白天打卡, 晚上回前台" — 不算跨日
      final lastCheck = DateTime(2026, 7, 17, 14, 0);
      final now = DateTime(2026, 7, 17, 23, 0);
      expect(crossedMidnightSince(lastCheck, now), isFalse);
    });

    test('跨 midnight 1 天后 (now 在 00:00:05 之后) → true', () {
      // lastCheck 23:00, now 第二天 00:01:00
      // lastCutoff = 17-00:00:05, nowCutoff = 18-00:00:05
      // nowCutoff.isAfter(lastCutoff) = true
      final lastCheck = DateTime(2026, 7, 17, 23, 0);
      final now = DateTime(2026, 7, 18, 0, 1);
      expect(crossedMidnightSince(lastCheck, now), isTrue);
    });

    test('跨 midnight 但 now 还在 00:00:05 之前 (00:00:01) → true (跨日就报 crossed, buffer 不影响)', () {
      // v0.21 P0-4 立的语义: function 看日期是否已变, 不看 5s buffer
      // (buffer 是 nextMidnightRefresh 算 timer 的事, 不影响"是否跨过")
      // lastCheck 23:00, now 第二天 00:00:01
      // lastCutoff = 17-00:00:05, nowCutoff = 18-00:00:05
      // nowCutoff > lastCutoff → true
      final lastCheck = DateTime(2026, 7, 17, 23, 0);
      final now = DateTime(2026, 7, 18, 0, 0, 1);
      expect(crossedMidnightSince(lastCheck, now), isTrue);
    });

    test('系统时间被拨回 (lastCheck > now) → true (防御性 invalidate)', () {
      // 保护: 用户/系统拨时钟回退, 不应认为没跨日。
      // 保险起见 invalidate, 让 UI 用 today 数据重算。
      final lastCheck = DateTime(2026, 7, 17, 14, 0);
      final now = DateTime(2026, 7, 17, 10, 0); // 拨回 4h
      expect(crossedMidnightSince(lastCheck, now), isTrue);
    });

    test('00:00:05 边界精确 (P1-9 RED-4 锁定)', () {
      // lastCheck = 17-23:30
      // now = 18-00:00:04 (buffer 之内)  → 跨日, 应 true
      //   lastCutoff = 17-00:00:05, nowCutoff = 18-00:00:05, 差 24h, true
      // now = 18-00:00:05 (buffer 刚到)  → 跨日, true
      // now = 18-00:00:06 (buffer 之后)  → 跨日, true
      final lastCheck = DateTime(2026, 7, 17, 23, 30);

      final t1 = DateTime(2026, 7, 18, 0, 0, 4);
      final t2 = DateTime(2026, 7, 18, 0, 0, 5);
      final t3 = DateTime(2026, 7, 18, 0, 0, 6);

      // 跨日, 无论 now 在 0:00:04 / 0:00:05 / 0:00:06 都应该 true
      // (cutoff 用"当天 00:00:05"作为标记, 日期变了 cutoff 必然晚 1 天)
      expect(crossedMidnightSince(lastCheck, t1), isTrue,
          reason: 'lastCheck 17-23:30 vs now 18-00:00:04 (跨日)',);
      expect(crossedMidnightSince(lastCheck, t2), isTrue,
          reason: 'lastCheck 17-23:30 vs now 18-00:00:05 (buffer 边界)',);
      expect(crossedMidnightSince(lastCheck, t3), isTrue,
          reason: 'lastCheck 17-23:30 vs now 18-00:00:06 (buffer 之后)',);
    });

    test('00:00:05 边界反向 (lastCheck 0:00:04 vs now 0:00:04 同日) → false', () {
      // 同一天的两个 0:00:04, cutoff 都在同一天 00:00:05, 同一时刻
      // → false
      final lastCheck = DateTime(2026, 7, 17, 0, 0, 4);
      final now = DateTime(2026, 7, 17, 0, 0, 4);
      expect(crossedMidnightSince(lastCheck, now), isFalse);
    });

    test('同日 00:00:05 之前 (lastCheck 0:00:04, now 0:00:05 同日) → false', () {
      // lastCutoff = 17-00:00:05, nowCutoff = 17-00:00:05
      // 同一时刻 → false (nowCutoff.isAfter(lastCutoff) = false)
      final lastCheck = DateTime(2026, 7, 17, 0, 0, 4);
      final now = DateTime(2026, 7, 17, 0, 0, 5);
      expect(crossedMidnightSince(lastCheck, now), isFalse);
    });

    test('同日 00:00:05 之后 (lastCheck 0:00:04, now 0:00:06) → false', () {
      // lastCutoff = 17-00:00:05, nowCutoff = 17-00:00:05
      // 同一时刻 → false
      final lastCheck = DateTime(2026, 7, 17, 0, 0, 4);
      final now = DateTime(2026, 7, 17, 0, 0, 6);
      expect(crossedMidnightSince(lastCheck, now), isFalse);
    });
  });
}
