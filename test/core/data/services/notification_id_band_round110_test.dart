// v0.32 R110 (B1-1) 回归测试: 通知 ID 固定带必须远离所有 cancel 区间
//
// 背景 (BUG): 固定 ID (safety 5000 / assessment 7000 / mood 8000 /
// badge 9999 / care push 8000+) 全部落在 medication [2000, 202000) 与
// refill 的 cancelByIdRange 区间内 — 每次启动 / 改药 /
// 续方重排都会静默删除这些 pending 通知。
//
// 修法: 全部迁到 5,000,000+ 固定带, 远离:
//   - med   cancel [medicationReminderBaseId, +kReminderCancelRange) = [2000, 202000)
//   - refill cancel [refillBaseId, +kReminderCancelRange)          = [2500000, 2700000)
//       (R114 B1-3: 从 [6000, 206000) 迁出, 与 medication cancel 分家)
//   - snooze base 300000 + cancel 2000000                          = [300000, 2300000)
//   - defaultReminderId 1001 (在 2000 之下, 天然安全)
//
// 若未来有人把固定 ID 改回低位带, 这个 test 会立刻红。
//
// 1.1.0 round 4 (emotion-first refactor): care push (kCarePushBaseId) 随
// HomeCareEngineDispatcher 整摘, 本 test 固定 ID 列表同步删除该项。
// 1.1.0 round 4b: safetyAlertId 随 NotificationService.showSafetyAlert
// 整摘, 固定 ID 剩 3 个。
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/core/data/services/assessment_notifier.dart';
import 'package:chroniccare/core/data/services/badge_sync_service.dart';
import 'package:chroniccare/core/data/services/mood_reminder_notifier.dart';
import 'package:chroniccare/core/data/services/refill_notifier.dart';
import 'package:chroniccare/core/platform/notification/reminder_dispatcher.dart';

void main() {
  // 所有 cancel 区间的上界 (> 任何 base + kReminderCancelRange)
  // R114 B1-3: refill cancel 区间 [2500000, 2700000)
  const int refillCancelMax =
      RefillNotifier.refillBaseId + kReminderCancelRange;
  // snooze 上界 = snoozeBaseId + cancelRange (可配置, 用最坏情形 2300000)
  const int snoozeCancelMax = 300000 + 2000000;

  group('notification ID 固定带 (v0.32 R110 B1-1 回归)', () {
    test('3 个固定 ID 全部 ≥ 5M 带 (远离 med/refill/snooze cancel 区间)', () {
      final fixedIds = <int>[
        AssessmentNotifier.assessmentReminderId,
        MoodReminderNotifier.moodReminderId,
        BadgeSyncService.badgeVirtualId,
      ];

      for (final id in fixedIds) {
        expect(
          id,
          greaterThanOrEqualTo(snoozeCancelMax),
          reason: '固定 ID $id 必须 ≥ snooze cancel 上界 $snoozeCancelMax',
        );
      }
    });

    test('固定 ID 不落在 medication cancel 区间 [2000, 202000)', () {
      final fixedIds = <int>[
        AssessmentNotifier.assessmentReminderId,
        MoodReminderNotifier.moodReminderId,
        BadgeSyncService.badgeVirtualId,
      ];
      // dev note: MedicationNotifier.defaultReminderId (1001) 在 2000 之下也
      // 天然安全, 不在此列表 (它不是"固定带"成员)
      for (final id in fixedIds) {
        expect(
          id < 2000 || id >= 2000 + kReminderCancelRange,
          isTrue,
          reason: '固定 ID $id 不得落入 [2000, 202000)',
        );
      }
    });

    test('固定 ID 不落在 refill cancel 区间 (R114 B1-3: [2500000, 2700000))', () {
      final fixedIds = <int>[
        AssessmentNotifier.assessmentReminderId,
        MoodReminderNotifier.moodReminderId,
        BadgeSyncService.badgeVirtualId,
      ];
      for (final id in fixedIds) {
        expect(
          id < RefillNotifier.refillBaseId || id >= refillCancelMax,
          isTrue,
          reason: '固定 ID $id 不得落入 refill cancel 区间 '
              '[${RefillNotifier.refillBaseId}, $refillCancelMax)',
        );
      }
    });

    test('med/refill 生成 ID 也永不落入对方 cancel 区间 (双向不串)', () {
      // med id 公式: 2000 + medId*10 + i (i ∈ [0,9]);
      // medId 19999 → max = 2000 + 199990 + 9 = 201999 (仍在 med cancel 内)
      const int maxMedId = 19999;
      const maxMedIdValue = 2000 + maxMedId * 10 + 9;
      expect(maxMedIdValue, lessThan(2000 + kReminderCancelRange));

      // refill id 公式: 2500000 + medId (R114 B1-3); 上限 medId 19999 → 2519999
      for (final medId in [0, 1, 398, 399, 19999]) {
        final refillId = RefillNotifier.refillBaseId + medId;
        expect(refillId, greaterThanOrEqualTo(RefillNotifier.refillBaseId));
        expect(refillId, lessThan(refillCancelMax));
      }

      // R114 B1-3 双向不串: refill id 空间 [2500000, 2700000) 与
      // med cancel 上界 202000 不相交 (refill 下界 > med 上界)
      expect(
        RefillNotifier.refillBaseId,
        greaterThan(2000 + kReminderCancelRange),
        reason: 'refill 下界必须大于 medication cancel 上界 (B1-3 分家)',
      );
    });

    test('固定 ID 彼此互不冲突', () {
      final ids = <int>{
        AssessmentNotifier.assessmentReminderId,
        MoodReminderNotifier.moodReminderId,
        BadgeSyncService.badgeVirtualId,
      };
      expect(ids.length, 3, reason: '固定 ID 集合必须全是唯一值');
    });
  });
}
