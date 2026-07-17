// v0.18 round 14 (P0-1) SMS Provider 测试
//
// P0-1 fix 之前 superpowers-en 报:
// 1. MockSmsProvider.send() 返 true 让上层以为已发送 — 实际只是 log
// 2. AliyunSmsProvider.send() silently 返 false — 同样误导
// 3. UI 没有任何"未连接"提示
//
// 修法: MockSmsProvider + AliyunSmsProvider 都 throw UnimplementedError,
// SmsService.send catch 后返 SmsResult.fail,SafetyWatchService 算
// contactsFailed。UI 用 smsProviderNameProvider 检测 + 显 banner。
import 'package:chroniccare/core/data/services/sms_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MockSmsProvider', () {
    test('P0-1: send() throw UnimplementedError (不再 silently 返 true)', () async {
      final provider = MockSmsProvider();
      expect(
        () => provider.send(
          to: '13800138000',
          body: 'test',
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('P0-1: name = "mock" 供 UI 检测', () {
      expect(MockSmsProvider().name, 'mock');
    });
  });

  group('AliyunSmsProvider', () {
    test('P0-1: send() throw UnimplementedError (不再 silently 返 false)',
        () async {
      final provider = AliyunSmsProvider(
        accessKeyId: 'fake-id',
        accessKeySecret: 'fake-secret',
        signName: '慢性病管家',
        templateCode: 'SMS_000000',
      );
      expect(
        () => provider.send(
          to: '13800138000',
          body: 'test',
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });

  group('SmsService (业务层)', () {
    test('P0-1: provider 抛 throw → SmsService.send 返 SmsResult.fail',
        () async {
      // 真实 mock provider 现在 throw,SmsService 应该 catch
      final svc = SmsService(provider: MockSmsProvider());
      final result = await svc.send(to: '13800138000', body: 'test');
      expect(result.success, false);
      expect(result.error, isNotNull);
    });

    test('provider 返 true → SmsService.send 返 SmsResult.ok', () async {
      // 自定义 provider 返 true (用于 test / dev 接管)
      final svc = SmsService(
        provider: _AlwaysOkProvider(),
      );
      final result = await svc.send(to: '13800138000', body: 'test');
      expect(result.success, true);
    });

    test('provider 返 false → SmsService.send 返 SmsResult.fail', () async {
      final svc = SmsService(
        provider: _AlwaysFailProvider(),
      );
      final result = await svc.send(to: '13800138000', body: 'test');
      expect(result.success, false);
      expect(result.error, isNotNull);
    });
  });
}

class _AlwaysOkProvider implements SmsProvider {
  @override
  String get name => 'always-ok-test';

  @override
  Future<bool> send({
    required String to,
    required String body,
    String? templateId,
  }) async {
    return true;
  }
}

class _AlwaysFailProvider implements SmsProvider {
  @override
  String get name => 'always-fail-test';

  @override
  Future<bool> send({
    required String to,
    required String body,
    String? templateId,
  }) async {
    return false;
  }
}
