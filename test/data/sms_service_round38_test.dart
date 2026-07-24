import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/core/data/services/sms_service.dart';

/// v0.23 round 38 (P0-1 fix): SMS provider release-mode 守卫测试
///
/// 关键场景:
/// 1. MockSmsProvider.isProductionReady == false → release 模式启动抛错
/// 2. AliyunSmsProvider.isProductionReady == true → release 模式启动不抛
/// 3. SmsService.send 用 mock → 返 SmsResult.fail (UnimplementedError 被 catch)
/// 4. SmsProviderNotConfiguredError 携带 provider name
///
/// **重要**: [SmsService.validateForRelease] 在 flutter test 默认 kReleaseMode
/// 是 false,会直接 return。要测 release 分支,用 provider 是 MockSmsProvider +
/// 手动模拟 — 不,实际不测 validateForRelease 的 release 分支(因为 test env 是
/// 非 release),只测它**不抛错**当 kReleaseMode == false;测 [SmsProvider.isProductionReady]
/// 直接覆盖业务意图。
void main() {
  group('v0.23 round 38 (P0-1) — SmsProvider.isProductionReady', () {
    test('MockSmsProvider.isProductionReady = false', () {
      expect(MockSmsProvider().isProductionReady, isFalse);
    });

    test('AliyunSmsProvider.isProductionReady = true', () {
      final provider = AliyunSmsProvider(
        accessKeyId: 'fake-id',
        accessKeySecret: 'fake-secret',
        signName: 'fake-sign',
        templateCode: 'fake-template',
      );
      expect(provider.isProductionReady, isTrue);
    });
  });

  group('v0.23 round 38 (P0-1) — SmsProvider.name', () {
    test('MockSmsProvider.name = "mock"', () {
      expect(MockSmsProvider().name, 'mock');
    });

    test('AliyunSmsProvider.name = "aliyun"', () {
      final provider = AliyunSmsProvider(
        accessKeyId: 'fake',
        accessKeySecret: 'fake',
        signName: 'fake',
        templateCode: 'fake',
      );
      expect(provider.name, 'aliyun');
    });
  });

  group('v0.23 round 38 (P0-1) — SmsProviderNotConfiguredError', () {
    test('携带 provider name', () {
      final err = SmsProviderNotConfiguredError('mock');
      expect(err.providerName, 'mock');
      expect(err.toString(), contains('mock'));
      expect(err.toString(), contains('SmsProviderNotConfiguredError'));
    });
  });

  group('v0.23 round 38 (P0-1) — SmsService.validateForRelease', () {
    test('test env (kReleaseMode=false) + mock → 不抛 (dev 是正常流程)', () {
      // flutter test 默认 kReleaseMode == false,validateForRelease 直接 return
      expect(
        () => SmsService.validateForRelease(MockSmsProvider()),
        returnsNormally,
      );
    });

    test('test env (kReleaseMode=false) + aliyun → 不抛', () {
      expect(
        () => SmsService.validateForRelease(
          AliyunSmsProvider(
            accessKeyId: 'a',
            accessKeySecret: 'b',
            signName: 'c',
            templateCode: 'd',
          ),
        ),
        returnsNormally,
      );
    });
  });

  group('v0.23 round 38 (P0-1) — SmsService.send', () {
    test('default provider = mock → send() 返 SmsResult.fail', () async {
      // SmsService() 不传 provider,默认 MockSmsProvider
      final service = SmsService();
      final result = await service.send(
        to: '13800138000',
        body: 'test message',
      );
      expect(result.success, isFalse);
      expect(result.error, isNotNull);
      expect(result.error, contains('UnimplementedError'));
    });

    test('显式注入 mock → send() 返 SmsResult.fail', () async {
      final service = SmsService(provider: MockSmsProvider());
      final result = await service.send(
        to: '13800138000',
        body: 'test',
      );
      expect(result.success, isFalse);
      expect(result.error, contains('MockSmsProvider'));
    });

    test('注入 aliyun (未实现) → send() 返 SmsResult.fail (不是抛 UnimplementedError)', () async {
      final service = SmsService(
        provider: AliyunSmsProvider(
          accessKeyId: 'a',
          accessKeySecret: 'b',
          signName: 'c',
          templateCode: 'd',
        ),
      );
      final result = await service.send(
        to: '13800138000',
        body: 'test',
      );
      expect(result.success, isFalse);
      expect(result.error, contains('AliyunSmsProvider'));
    });
  });

  group('v0.23 round 38 (P0-1) — SmsService.provider getter', () {
    test('SmsService() 默认 provider = MockSmsProvider', () {
      expect(SmsService().provider, isA<MockSmsProvider>());
    });

    test('SmsService(provider: X) provider = X', () {
      final mock = MockSmsProvider();
      expect(SmsService(provider: mock).provider, same(mock));
    });
  });
}
