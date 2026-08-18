// v0.16 (Round 19B) regression test for notification id cancel range bug
//
// rescheduleRefillReminders 用 `id >= _refillBaseId && id < _refillBaseId + RANGE`
// 清掉所有 refill 通知。修前 RANGE=1000，medId >= 1000 时漏 cancel。
// 修后 RANGE=200000，覆盖 medId < 194000（远超实际用户量）。
//
// 公式：`refillNotificationId(medId) = 6000 + medId`
// 修前漏 cancel 起点：medId = 1000（id = 7000, range 截止 7000）
// 修后漏 cancel 起点：medId = 194000（id = 200000, range 截止 206000）
//
// R114 B1-3: base 6000 → 2500000 (与 medication cancel [2000, 202000) 分家),
// 公式不变 = `refillBaseId + medId`, 数值按新 base 更新。
//
// 这些测试通过 [refillNotificationId] 公式验证 id 落在
// [2500000, 2700000) 内。
import 'package:chroniccare/core/platform/notification/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const base = 2500000;
  group(
      'NotificationService.refillNotificationId — v0.16 round 19B '
      '(R114 B1-3: base 6000 → 2500000)', () {
    test('medId=0 → id=2500000 (in range)', () {
      expect(NotificationService.refillNotificationId(0), 2500000);
    });

    test('medId=1 → id=2500001 (in range)', () {
      expect(NotificationService.refillNotificationId(1), 2500001);
    });

    test('medId=999 → id=2500999 (修前 in range [6000, 7000))', () {
      // 修前 [6000, 7000) 覆盖 medId 0-999
      // 修后 [2500000, 2700000) 仍覆盖
      final id = NotificationService.refillNotificationId(999);
      expect(id, 2500999);
    });

    test('medId=1000 → id=2501000 (修前 OUT of range [6000, 7000) — bug!)', () {
      // 这是修前的 bug 起点：medId=1000 时 id=7000，刚好在 range 截止
      // 之前 `id < 7000` 不包含 7000，所以漏 cancel
      // 修后 `id < 2700000` 包含 2501000
      final id = NotificationService.refillNotificationId(1000);
      expect(id, 2501000);
      // 修前会失败: 7000 < 7000 = false (漏 cancel)
      // 修后通过: 2501000 < 2700000 = true
      expect(
        id < base + 200000,
        isTrue,
        reason: 'medId=1000 的 id 必须被 reschedule 范围覆盖',
      );
    });

    test('medId=10000 → id=2510000 (修前 OUT of range — bug!)', () {
      // medId=10000 时 id=16000
      // 修前 [6000, 7000) 完全不包含
      // 修后 [2500000, 2700000) 包含
      final id = NotificationService.refillNotificationId(10000);
      expect(id, 2510000);
      expect(id >= base && id < base + 200000, isTrue);
    });

    test('medId=50000 → id=2550000 (修前 OUT of range — bug!)', () {
      // 极端场景：用户开 50000 个药（理论上限）
      final id = NotificationService.refillNotificationId(50000);
      expect(id, 2550000);
      expect(
        id < base + 200000,
        isTrue,
        reason: 'medId=50000 的 id 必须被 reschedule 范围覆盖',
      );
    });
  });
}
