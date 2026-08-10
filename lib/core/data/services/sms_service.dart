import 'dart:async';
import 'package:chroniccare/core/data/services/last_error_capture.dart'
    show LastErrorCapture;
import 'package:chroniccare/core/data/services/pii_safe_log.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;

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

  /// 是否生产可用
  ///
  /// Mock = false；真实 provider（AliyunSmsProvider / TwilioSmsProvider）= true。
  /// v0.23 round 38 (P0-1 fix): release 模式启动时 [SmsService.validateForRelease]
  /// 会用这个 getter 决定抛 [SmsProviderNotConfiguredError] 阻断。
  bool get isProductionReady;

  /// 发送单条短信
  /// 返回 true 表示发送成功（或者队列成功），false 表示失败
  Future<bool> send({
    required String to,
    required String body,
    String? templateId,
  });
}

/// 释放模式启动时如果用了未配置 provider,会抛这个错
///
/// v0.23 round 38 (P0-1 fix): 之前 [MockSmsProvider.send] 抛 UnimplementedError
/// 在 release 模式下静默被 [SmsService.send] catch 返 `SmsResult.fail`,UI 显示
/// "未连接",用户死了 3 天没人通知。改成 [SmsService.validateForRelease] 在启动
/// 时主动 check,release + mock → 抛本错,被 [runZonedGuarded] 抓住后
/// [LastErrorCapture] 记录,启动后顶部 banner 显眼提示。
class SmsProviderNotConfiguredError extends Error {
  final String providerName;
  SmsProviderNotConfiguredError(this.providerName);
  @override
  String toString() =>
      'SmsProviderNotConfiguredError: 启动检测到 "$providerName" 是 mock/未配置,'
      'release 模式必须注入真实 SMS provider (AliyunSmsProvider 等)。';
}

/// Mock 实现：只打日志，不真发
///
/// **P0-1 fix**: 之前 `return true` 让上层以为发出去了 — 实际只是日志。
/// 改成抛 `UnimplementedError`,`SmsService.send` 会 catch 住并返
/// `SmsResult.fail`,`SafetyWatchService` 把这次算 `contactsFailed`。
/// UI 拿到 `error` kind,显示"未连接"。
///
/// ⚠️ 任何生产 release 都必须显式注入 `AliyunSmsProvider`(或其它真实 provider),
/// 不能让 mock 进 release。release 模式启动时 [SmsService.validateForRelease] 会
/// 用 [isProductionReady] 抛 [SmsProviderNotConfiguredError] 阻断。
class MockSmsProvider implements SmsProvider {
  @override
  String get name => 'mock';

  @override
  bool get isProductionReady => false;

  @override
  Future<bool> send({
    required String to,
    required String body,
    String? templateId,
  }) async {
    piiSafeLog('MockSmsProvider', '=' * 60);
    piiSafeLog('MockSmsProvider', '📱 [MOCK SMS — NOT SENT]');
    piiSafeLog('MockSmsProvider', '  To: ${maskPhone(to)}');
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
///
/// v0.23 round 38 (P0-1 fix): [isProductionReady] 返 true（假设配置正确），
/// release 模式启动时 [SmsService.validateForRelease] 不会阻断。
/// 真实 send() 仍 throw UnimplementedError（v1.0+ TODO），但不会"假成功"。
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

  /// v0.27 round 63 (P0-1 收尾): `_isFullyImplemented` 守门。
  ///
  /// 修复前: `isProductionReady` 只看 4 字段是否齐全。4 字段齐全 →
  /// true → release 模式启动时 `validateForRelease` 不阻断 → 后续
  /// `send()` 抛 UnimplementedError → 上层走 `SmsResult.fail` → UI
  /// 提示"未连接"**但**没 banner 显眼告警。精神心理患者和家属以为
  /// 失联通知能发,实际 100% 失败。
  ///
  /// 修复后: `_isFullyImplemented` 默认 false,直到 R55 真接 send() 时
  /// 改返 true。`isProductionReady` = `_isFullyImplemented && 4 字段齐全`
  /// → 4 字段齐全 + send 未接 → false → release 模式启动被
  /// `validateForRelease` 阻断 → banner 显眼告警"未配置 SMS"。
  ///
  /// 设计动机: 让"看起来配齐但实际没接通"的状态在 release 启动时
  /// 就被抓住,而不是运行时静默失败。
  bool get _isFullyImplemented => false; // R55 真接 send() 时改 true

  /// v0.27 round 62 (P0-1 修复) + 63 (收尾): isProductionReady 必须
  /// 同时满足"4 字段齐全"+"send() 实际能工作"。
  ///
  /// 修复 R62: 不再硬编码 true(修复前 4 字段空也返 true)。
  /// 修复 R63: 不只看 4 字段(修复 R62 漏洞:4 字段齐全 + send 仍
  /// throw = 启动通过 + 运行时 100% 失败)。
  ///
  /// 4 字段齐全 + send 已接 R55+ → true (release 启动不阻断, send 真发)
  /// 4 字段齐全 + send 未接    → false (release 启动阻断, banner 提示)
  /// 4 字段缺失               → false (release 启动阻断, banner 提示)
  @override
  bool get isProductionReady =>
      _isFullyImplemented &&
      accessKeyId.isNotEmpty &&
      accessKeySecret.isNotEmpty &&
      signName.isNotEmpty &&
      templateCode.isNotEmpty;

  @override
  Future<bool> send({
    required String to,
    required String body,
    String? templateId,
  }) async {
    // v0.25 round 55 (spzh P0 #6): 真接阿里云 SMS 计划。
    // 当前 throw StateError (R63 改:从 UnimplementedError 改, 明确
    // "业务不可用" 而非 "暂未实现")。
    //
    // 注: 正常流程不会到这里,因为 isProductionReady=false 走 SmsService.send
    // line 284 的 mock 早返路径。只有在测试或外部代码直接调 provider.send()
    // 时才会进这里。
    //
    // 完整接入 plan 见 docs/SMS_PROVIDERS.md §1。
    //
    // 真接步骤 (R55 PR 待做):
    // 1. pubspec.yaml 加 `dio: ^5.0.0` (HTTP) + `crypto: ^3.0.0` (HMAC-SHA1)
    // 2. 申请阿里云 AccessKey + 短信签名 + 模板 (法务, 1-2 月)
    // 3. .env 加 ALIYUN_ACCESS_KEY_ID / ALIYUN_ACCESS_KEY_SECRET /
    //    ALIYUN_SIGN_NAME / ALIYUN_TEMPLATE_CODE_CARE /
    //    ALIYUN_TEMPLATE_CODE_LOST (存 flutter_secure_storage)
    // 4. 实现 _signRequest() (HMAC-SHA1 签名, 见 docs/SMS_PROVIDERS.md §1.3)
    // 5. POST https://dysmsapi.aliyuncs.com/  (5s timeout + 3 次重试)
    // 6. 解析响应: Code='OK' 返 true, 其他走 swallowError
    // 7. 错误处理: 限流/余额不足/模板错误 分别对应不同 SmsResult.fail
    // 8. **关键**: 把第 1 步的 `_isFullyImplemented` getter 改返 true
    //    (跟 send() 真接同步)
    //
    // 模板审核技巧 (法务):
    // - 避用"药"/"病"等敏感词
    // - 措辞示例: "我是${userName}, 已${days}天没打卡App, 请方便时提醒"
    // - 平均需 2-3 次驳回重提
    //
    // 跨境 PIPL §38:
    // - +86 大陆号段 → AliyunSms
    // - +1/+44/+852 海外号段 → TwilioSmsProvider (需 Twilio 境内代理备案)
    // - SmsService.send 入口加号码归属地路由 (R55+)

    throw StateError(
      'AliyunSmsProvider.send() R55 真接 TODO — '
      'isProductionReady=false, 正常流程不会到这里; '
      '若到此说明直接调了 provider.send(), 请改用 SmsService.send() 走 mock 早返路径。',
    );
  }
}

/// SMS 发送结果
///
/// v0.25 round 52 (spen P0 #12): 加 [kind] 区分 ok / fail / mock。
/// 之前 mock 模式抛 UnimplementedError → SmsService.send catch 返
/// SmsResult.fail → safety_watch 算 smsFail++ → UI 显示"已通知 0 位
/// (X 失败)" 实际根本没发。改成 mock 独立 kind,SafetyWatch 跳过
/// 既不算 ok 也不算 fail。
enum SmsResultKind {
  ok,
  fail,

  /// Mock 模式: 没真发,不算 ok 也不算 fail。
  /// 上层 (SafetyWatch / Settings) 应在 UI 显示 "未配置" 状态。
  mock,
}

class SmsResult {
  final SmsResultKind kind;
  bool get success => kind == SmsResultKind.ok;
  final String? error;
  final String? providerMessageId;

  const SmsResult({
    required this.kind,
    this.error,
    this.providerMessageId,
  });

  factory SmsResult.ok() => const SmsResult(kind: SmsResultKind.ok);
  factory SmsResult.fail(String error) =>
      SmsResult(kind: SmsResultKind.fail, error: error);
  factory SmsResult.mock() => const SmsResult(kind: SmsResultKind.mock);
}

/// v0.27 round 60 (P0-3 修正): 一批 SMS 发送的 3 态计数
///
/// `SafetyAlertDispatcher.dispatchAlert` 返这个 record, `NotificationService
/// .showSafetyAlert` 用它决定通知文案走 `sent` / `mocked` / `failed` 哪一支。
///
/// 修正前: 通知 hardcode "已自动通知紧急联系人", 哪怕 mock 模式 / 全部失败
/// 也这么说, 对精神心理患者形成"谎言"。修正后 3 态明确分流。
///
/// 选择规则 (在 NotificationService._resolveSafetyAlertBody):
/// - `smsOk > 0` → sent
/// - `smsOk == 0 && smsMock > 0` → mocked (dev 模式常态)
/// - `smsOk == 0 && smsFail > 0` → failed
typedef SmsDispatchOutcome = ({
  int smsOk,
  int smsFail,
  int smsMock,
});

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
///
/// v0.23 round 38 (P0-1 fix): 启动时调 [validateForRelease] 主动 check,
/// release + mock → 抛 [SmsProviderNotConfiguredError],被 runZonedGuarded
/// 抓住,LastErrorCapture 记录 + 启动 banner 提示。
class SmsService {
  final SmsProvider _provider;

  SmsService({SmsProvider? provider})
      : _provider = provider ?? MockSmsProvider();

  SmsProvider get provider => _provider;

  /// 启动时 release-mode 守卫
  ///
  /// 流程：
  /// 1. release 模式（[kReleaseMode] == true）下,如果 [provider] 的
  ///    [SmsProvider.isProductionReady] 是 false → 抛 [SmsProviderNotConfiguredError]
  /// 2. dev / profile / test 模式：什么都不做（mock 是正常开发工具）
  ///
  /// main.dart 在 bootstrap 期间调本方法,本方法抛错会被
  /// [runZonedGuarded] 抓住并通过 [LastErrorCapture] 记录,AppRoot 启动
  /// 后顶部 banner 显眼提示。
  static void validateForRelease(SmsProvider provider) {
    if (kReleaseMode && !provider.isProductionReady) {
      piiSafeLog(
        'SmsService.validateForRelease',
        '🚨 release 模式检测到 SMS provider "${provider.name}" 未配置,'
            '失联通知功能不可用',
        error: SmsProviderNotConfiguredError(provider.name),
      );
      throw SmsProviderNotConfiguredError(provider.name);
    }
  }

  /// 发送单条短信
  Future<SmsResult> send({
    required String to,
    required String body,
  }) async {
    // v0.25 round 52 (spen P0 #12): mock provider 直接返 SmsResult.mock,
    // 避免 catch UnimplementedError 误判为 fail。mock 模式只 log, 不算
    // smsOk 也不算 smsFail — SafetyWatch 看到 kind=mock 跳过。
    if (!_provider.isProductionReady) {
      piiSafeLog(
        'SmsService',
        '🟡 [MOCK] SMS to ${maskPhone(to)} via ${_provider.name} (no real send)',
      );
      return SmsResult.mock();
    }
    try {
      final ok = await _provider.send(to: to, body: body);
      if (ok) {
        piiSafeLog(
          'SmsService',
          '✅ SMS sent to ${maskPhone(to)} via ${_provider.name}',
        );
        return SmsResult.ok();
      }
      return SmsResult.fail('${_provider.name} returned false');
    } catch (e, st) {
      piiSafeLog(
        'SmsService',
        '❌ SMS failed to ${maskPhone(to)}: $e',
        error: e,
        stackTrace: st,
      );
      return SmsResult.fail(e.toString());
    }
  }
}
