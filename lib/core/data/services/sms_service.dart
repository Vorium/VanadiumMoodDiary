import 'dart:async';
import 'dart:developer' as developer;

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
class MockSmsProvider implements SmsProvider {
  @override
  String get name => 'mock';

  @override
  Future<bool> send({
    required String to,
    required String body,
    String? templateId,
  }) async {
    developer.log('=' * 60, name: 'MockSmsProvider');
    developer.log('📱 [MOCK SMS]', name: 'MockSmsProvider');
    developer.log('  To: $to', name: 'MockSmsProvider');
    developer.log('  Body:', name: 'MockSmsProvider');
    for (final line in body.split('\n')) {
      developer.log('    $line', name: 'MockSmsProvider');
    }
    developer.log('=' * 60, name: 'MockSmsProvider');
    return true;
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
    // TODO(v1.0): 接入阿里云短信 SDK
    // 当前未实现：调用 SDK 失败时降级到 Mock
    developer.log(
      '⚠️ AliyunSmsProvider.send() 未实现（v1.0+ TODO），降级到 mock log',
      name: 'AliyunSmsProvider',
    );
    return false;
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
        developer.log(
          '✅ SMS sent to $to via ${_provider.name}',
          name: 'SmsService',
        );
        return SmsResult.ok();
      }
      return SmsResult.fail('${_provider.name} returned false');
    } catch (e, st) {
      developer.log(
        '❌ SMS failed to $to: $e',
        name: 'SmsService',
        error: e,
        stackTrace: st,
      );
      return SmsResult.fail(e.toString());
    }
  }
}
