// v0.26 round 57: AliyunSmsProvider 测试 (原 .disabled, v0.32 R110 round 6 恢复)
//
// 历史: R57 写了 dio 真接测试 (MockHttpClientAdapter 验签/HTTPS 响应),
// 但 send() 至今未真接 (R55 依赖阿里云 AccessKey, 外部阻塞) →
// R63 守门: send() throw StateError, isProductionReady=false。
// 旧测试断言"假成功" (isProductionReady=true + HTTP 200 路径), 与 R63
// 守门设计直接冲突 → 被 .disabled (静默覆盖率洞, SP-en-6)。
//
// 恢复为"当前 stub 契约"测试 (R63 语义):
// 1. isProductionReady: 4 字段齐全也 false — 防"看起来配齐"静默失效
// 2. send() throw StateError — 守门痕迹, 不会假成功
// 3. R55 真接后: 本文件需重写回 dio MockAdapter 版本 (验签 + 响应码)
import 'package:chroniccare/core/data/services/sms_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AliyunSmsProvider (R57, 当前为 R63 守门 stub)', () {
    AliyunSmsProvider full() => AliyunSmsProvider(
          accessKeyId: 'test-key-id',
          accessKeySecret: 'test-key-secret',
          signName: '慢病管家',
          templateCode: 'SMS_999999',
        );

    AliyunSmsProvider empty() => AliyunSmsProvider(
          accessKeyId: '',
          accessKeySecret: '',
          signName: '',
          templateCode: '',
        );

    test('name = "aliyun" (供 UI 检测)', () {
      expect(full().name, 'aliyun');
    });

    test('isProductionReady = false 即使 4 字段齐全 (R63 守门)', () {
      // R63 设计: send() 未真接 → 4 字段齐全也 false → release 启动
      // validateForRelease 阻断 + banner 显眼告警, 防"假成功"静默失效
      expect(full().isProductionReady, false,
          reason: 'send() 未真接 (R55 阿里云 AccessKey 外部阻塞) 前必须 false',);
    });

    test('isProductionReady = false 字段缺失', () {
      expect(empty().isProductionReady, false);
    });

    test('send() throw StateError (v1.0 TODO 痕迹, 不静默假成功)', () {
      expect(
        () => full().send(to: '13800138000', body: 'hello'),
        throwsStateError,
      );
    });

    test('send() throw 不论参数如何 (stub 阶段)', () async {
      expect(
        () => empty().send(to: '13800138000', body: 'x', templateId: 'SMS_1'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('SmsService 集成 (R57, R63 契约)', () {
    test('aliyun stub → isProductionReady false → release 阻断前提成立', () {
      final service = SmsService(
        provider: AliyunSmsProvider(
          accessKeyId: 'a',
          accessKeySecret: 'b',
          signName: 'c',
          templateCode: 'd',
        ),
      );
      // validateForRelease 是 static + kReleaseMode 才抛 (debug 静默),
      // 这里验证阻断前提: provider 未就绪 → release 启动必抛
      // SmsProviderNotConfiguredError (见 sms_service.dart:294-303)
      expect(service.provider.isProductionReady, false);
    });

    test('SmsProviderNotConfiguredError 类型可被 runZonedGuarded 捕获', () {
      final err = SmsProviderNotConfiguredError('aliyun');
      expect(err.toString(), contains('aliyun'));
      expect(err, isA<Error>());
    });
  });
}