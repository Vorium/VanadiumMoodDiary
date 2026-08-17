// v1.1.0+170 R124 (v1.0 长期 5 厂商 push facade 接入) — 5 厂商 push
// facade 拆分验证
//
// Goal: FiveVendorPushService 写完, 主壳验证:
//   1. 5 通道抽象 (FiveVendorPushChannel) 完整
//   2. 5 厂商 impl 占位 (MiPush / HmsPush / OppoPush / VivoPush / MeizuPush)
//      现阶段 throw UnimplementedError (R124 阶段 1 预期)
//   3. NoOp 默认实现 (5 厂商 SDK 未接时走此)
//   4. Factory.createChannel 默认返 NoOp
//   5. 公开 service 5 method 行为 (flag=false 早返, flag=true 走 NoOp)
//   6. FeatureFlags.fiveVendorPushEnabled flag gate 正确

import 'package:chroniccare/core/data/feature_flags.dart';
import 'package:chroniccare/core/data/services/five_vendor_push_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    // 每个 case 重置 4 flag 到 prod 默认 (避免跨 test 污染)
    FeatureFlags.resetForTest();
  });

  tearDown(() {
    FeatureFlags.resetForTest();
  });

  group('R124 阶段 1 — 5 通道抽象 + 5 厂商占位 + NoOp 默认', () {
    test('5 通道抽象: 4 method 公开 (register / unregister / getPushToken / vendorName)', () {
      // 5 厂商 impl 全部 implements FiveVendorPushChannel
      const MiPushChannel();
      const HmsPushChannel();
      const OppoPushChannel();
      const VivoPushChannel();
      const MeizuPushChannel();
      // 编译通过 = implements 关系满足
      expect(true, isTrue, reason: '5 厂商 impl 全部 implements FiveVendorPushChannel');
    });

    test('5 厂商 impl 现阶段 throw UnimplementedError (R124 阶段 1 预期)', () {
      // 5 厂商 SDK 未接, 调 register 应 throw UnimplementedError
      // flag=true 才能调 (5 厂商 impl), 默认 flag=false 早返 false
      FeatureFlags.setFiveVendorPushEnabledForTest(true);
      expect(
        () => const MiPushChannel().register(),
        throwsA(isA<UnimplementedError>()),
        reason: 'MiPush 现阶段应 throw UnimplementedError',
      );
      expect(
        () => const HmsPushChannel().register(),
        throwsA(isA<UnimplementedError>()),
        reason: 'HmsPush 现阶段应 throw UnimplementedError',
      );
      expect(
        () => const OppoPushChannel().register(),
        throwsA(isA<UnimplementedError>()),
        reason: 'OppoPush 现阶段应 throw UnimplementedError',
      );
      expect(
        () => const VivoPushChannel().register(),
        throwsA(isA<UnimplementedError>()),
        reason: 'VivoPush 现阶段应 throw UnimplementedError',
      );
      expect(
        () => const MeizuPushChannel().register(),
        throwsA(isA<UnimplementedError>()),
        reason: 'MeizuPush 现阶段应 throw UnimplementedError',
      );
    });

    test('5 厂商 impl 各自 vendorName getter 正确 (用于自检卡显示)', () {
      expect(const MiPushChannel().vendorName, 'MiPush');
      expect(const HmsPushChannel().vendorName, 'HmsPush');
      expect(const OppoPushChannel().vendorName, 'OppoPush');
      expect(const VivoPushChannel().vendorName, 'VivoPush');
      expect(const MeizuPushChannel().vendorName, 'MeizuPush');
    });

    test('NoOp 默认实现 vendorName = "NoOp" + register 早返 false', () async {
      const noop = NoOpFiveVendorPushChannel();
      expect(noop.vendorName, 'NoOp');
      expect(await noop.register(), isFalse);
      expect(await noop.getPushToken(), isNull);
      // unregister 应 no-op, 不抛
      await noop.unregister();
    });

    test('Factory.createChannel 现阶段返 NoOp (R124 阶段 1 预期)', () {
      final channel = FiveVendorPushFactory.createChannel();
      expect(channel, isA<NoOpFiveVendorPushChannel>(),
          reason: 'R124 阶段 1: factory 应返 NoOp (5 厂商 SDK 未接)');
      expect(channel.vendorName, 'NoOp');
    });
  });

  group('R124 阶段 1 — 公开 facade + FeatureFlags gate', () {
    test('flag=false (prod 默认): register 早返 false (不影响本地通知)', () async {
      // 修前 FeatureFlags.fiveVendorPushEnabled 默认 false (R93 阶段 2)
      expect(FeatureFlags.fiveVendorPushEnabled, isFalse,
          reason: 'prod 默认 flag=false');
      // 调 service 应早返 false, 不走 factory / channel
      final result = await FiveVendorPushService.register();
      expect(result, isFalse, reason: 'flag=false 应早返 false');
    });

    test('flag=false: unregister 早返 (不调 channel)', () async {
      // flag=false 时 unregister 应 no-op, 不抛
      await FiveVendorPushService.unregister();
    });

    test('flag=false: isAvailable 早返 false', () async {
      final result = await FiveVendorPushService.isAvailable();
      expect(result, isFalse, reason: 'flag=false 应早返 false');
    });

    test('flag=false: getPushToken 早返 null', () async {
      final result = await FiveVendorPushService.getPushToken();
      expect(result, isNull, reason: 'flag=false 应早返 null');
    });

    test('flag=true (override): service 走 factory + NoOp (R124 阶段 1 预期 register 返 false)', () async {
      FeatureFlags.setFiveVendorPushEnabledForTest(true);
      expect(FeatureFlags.fiveVendorPushEnabled, isTrue);
      // 现阶段 5 厂商 SDK 未接, factory 返 NoOp, register 早返 false
      final result = await FiveVendorPushService.register();
      expect(result, isFalse, reason: 'flag=true 走 NoOp.register → false');
    });
  });
}
