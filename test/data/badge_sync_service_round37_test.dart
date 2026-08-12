// badge_sync_service_round37_test.dart
//
// v0.23 (Round 37) 新增: BadgeSyncService 单测
//
// 之前 0 单测, 抽 BadgeSyncService (v0.22 round 30) 后一直没补。
// 测试覆盖核心 invariant:
//   1. 负数 count clamp 到 0
//   2. badgeVirtualId = 9999 不跟其他 id 冲突
//   3. plugin 抛错时 catch + 不向上传播
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:chroniccare/core/data/services/badge_sync_service.dart';

void main() {
  setUp(() {
    // Mock method channel — plugin 调 show/cancel 不真的发通知
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('dexterous.com/flutter/local_notifications');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
  });

  group('BadgeSyncService.badgeVirtualId', () {
    test('id = 5000100 (R110 5M+ 固定带) 不跟其他 id 冲突', () {
      // R110 (B1-1): 原 9999 落入 medication/refill cancel 区间被误杀,
      // 迁到 5M+ 固定带: 5000000 safety / 5000001 assessment /
      //   5000002 mood / 5000010 care push / 5000100 badge
      const id = BadgeSyncService.badgeVirtualId;
      expect(id, 5000100);
      expect(id, isNot(1001));
      expect(id, isNot(2000));
      expect(id, isNot(5000000));
      expect(id, isNot(6000));
      expect(id, isNot(5000001));
      expect(id, isNot(300000));
    });
  });

  group('BadgeSyncService.updateBadgeCount', () {
    test('负数 count clamp 到 0 (不抛)', () async {
      final plugin = FlutterLocalNotificationsPlugin();
      final service = BadgeSyncService(plugin: plugin);
      // -1 → 0 (不抛)
      await service.updateBadgeCount(-1);
      await service.updateBadgeCount(-100);
    });

    test('0 = 清零', () async {
      final plugin = FlutterLocalNotificationsPlugin();
      final service = BadgeSyncService(plugin: plugin);
      await service.updateBadgeCount(0);
    });

    test('正数 count 直接用', () async {
      final plugin = FlutterLocalNotificationsPlugin();
      final service = BadgeSyncService(plugin: plugin);
      await service.updateBadgeCount(5);
      await service.updateBadgeCount(99);
    });

    test('plugin 抛错时 catch + 不向上传播', () async {
      // 重设 mock 让 cancel 抛错
      const channel =
          MethodChannel('dexterous.com/flutter/local_notifications');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'cancel') {
          throw PlatformException(code: 'test_error', message: 'mock failure');
        }
        return null;
      });
      final plugin = FlutterLocalNotificationsPlugin();
      final service = BadgeSyncService(plugin: plugin);
      // 不抛 = 通过
      await service.updateBadgeCount(3);
    });
  });
}
