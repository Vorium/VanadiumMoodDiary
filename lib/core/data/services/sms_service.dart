import 'dart:async';
import 'package:chroniccare/core/shared/pii_safe_log.dart';

/// SMS 服务抽象层
///
/// v0.7：之前 ReminderService 用 mock log 通知紧急联系人，但用户买了
/// 8 块钱后这是核心承诺——必须能真发短信。
///
/// 抽象成 [SmsProvider] 接口：
/// - MockSmsProvider：开发/MVP 阶段，只打日志（v0.7 现状）
/// - AliyunSmsProvider：阿里云短信 SDK（v1.0+ 接，TODO）
/// - TwilioSmsProvider：国际号码（v2.0+ 接，TODO）
///
/// 这样切换 provider 不用改业务代码。
abstract class SmsProvider {
  String get name;

  /// 发送单条短信
  /// 返回 true 表示发送成功（或者队列成功），false 表示失败
  Future<bool> send({
    required String to,
    required String body,
    String? templateId,
  });
}

/// Mock 实现：只打日志，不真发
///
/// **P0-1 fix**: 之前 `return true` 让上层以为发出去了 — 实际只是日志。
/// 改成抛 `UnimplementedError`,`SmsService.send` 会 catch 住并返
/// `SmsResult.fail`,`SafetyWatchService` 把这次算 `contactsFailed`。
/// UI 拿到 `error` kind,显示"未连接"。
///
/// ⚠️ 任何生产 release 都必须显式注入 `AliyunSmsProvider`(或其它真实 provider),
/// 不能让 mock 进 release。
class MockSmsProvider implements SmsProvider {
  @override
  String get name => 'mock';

  @override
  Future<bool> send({
    required String to,
    required String body,
    String? templateId,
  }) async {
    piiSafeLog('MockSmsProvider', '=' * 60);
    piiSafeLog('MockSmsProvider', '📱 [MOCK SMS — NOT SENT]');
    piiSafeLog('MockSmsProvider', '  To: \${maskPhone(to)}');
    piiSafeLog('MockSmsProvider', '  Body:');
    for (final line in body.split('\n')) {
      piiSafeLog('MockSmsProvider', '    $line');
    }
    piiSafeLog('MockSmsProvider', '=' * 60);
    // 仍 log 详细，方便 dev 看，但实际没发出去
    throw UnimplementedError(
      'MockSmsProvider.send() — no real SMS sent. '
      'Production must inject AliyunSmsProvider (or other real provider).',
    );
  }
}

/// 阿里云短信 SDK 接入（v1.0+ TODO）
///
/// 接入步骤：
/// 1. `pubspec.yaml` 加 `aliyun_sms: ^x.x.x`（目前没这个包，需要用 dio 直连 API）
/// 2. 在 .env 加 ALIYUN_ACCESS_KEY_ID / ALIYUN_ACCESS_KEY_SECRET / ALIYUN_SMS_SIGN_NAME
/// 3. 实现 send 方法：
///    - 签名生成（HMAC-SHA1）
///    - POST 到 https://dysmsapi.aliyuncs.com/
///    - 处理 CommonResponse
///
/// 参考：https://help.aliyun.com/zh/sms/developer-reference/api-error-codes
class AliyunSmsProvider implements SmsProvider {
  final String accessKeyId;
  final String accessKeySecret;
  final String signName;
  final String templateCode;

  AliyunSmsProvider({
    required this.accessKeyId,
    required this.accessKeySecret,
    required this.signName,
    required this.templateCode,
  });

  @override
  String get name => 'aliyun';

  @override
  Future<bool> send({
    required String to,
    required String body,
    String? templateId,
  }) async {
    // P0-1 fix: 之前 silently 返 false,上层可能误判"已发送但失败"。
    // 改成 throw UnimplementedError,SmsService.send catch 后返
    // SmsResult.fail,UI 看到 error kind。
    throw UnimplementedError(
      'AliyunSmsProvider.send() 未实现 (v1.0+ TODO — 需要 accessKey/secret/signName)',
    );
  }
}

/// SMS 发送结果
class SmsResult {
  final bool success;
  final String? error;
  final String? providerMessageId;

  const SmsResult({
    required this.success,
    this.error,
    this.providerMessageId,
  });

  factory SmsResult.ok() => const SmsResult(success: true);
  factory SmsResult.fail(String error) =>
      SmsResult(success: false, error: error);
}

/// SMS 服务（业务层）
///
/// 用法：
/// ```dart
/// final service = SmsService(provider: MockSmsProvider());
/// await service.send(to: '13800138000', body: '...');
/// ```
///
/// v1.0 切换到阿里云：
/// ```dart
/// final service = SmsService(provider: AliyunSmsProvider(...));
/// ```
class SmsService {
  final SmsProvider _provider;

  SmsService({SmsProvider? provider})
      : _provider = provider ?? MockSmsProvider();

  SmsProvider get provider => _provider;

  /// 发送单条短信
  Future<SmsResult> send({
    required String to,
    required String body,
  }) async {
    try {
      final ok = await _provider.send(to: to, body: body);
      if (ok) {
        piiSafeLog('SmsService', '✅ SMS sent to $to via ${_provider.name}',
        );
        return SmsResult.ok();
      }
      return SmsResult.fail('${_provider.name} returned false');
    } catch (e, st) {
      piiSafeLog('SmsService', '❌ SMS failed to $to: $e',
        error: e,
        stackTrace: st,
      );
      return SmsResult.fail(e.toString());
    }
  }
}
