import 'package:chroniccare/core/data/services/pii_safe_log.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;

import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/logic/email_template.dart';

/// 失联通知服务（邮件 / 短信 — 跟 SmsService 平行）
///
/// v0.6：联系人改 phone 后，"邮件发送" 改成 mock 短信。
/// - MVP 阶段：useMock=true 时只打印日志，不发真实消息
/// - v1.0+：接入真实 SMS provider（阿里云/腾讯云），`to` 字段语义改成手机号
///
/// v0.16 简化: 删除未用的 Dio 字段和未用的 html 变量。
/// v0.16 抽象: 参数 Medication (drift row) → MedicationEntity (domain entity)。
///
/// v0.27 round 67 (B-1 修复): 跟 R63 SmsService 守门员 1:1 平行
///
/// 修复前: EmailService 0 守门员。`useMock=false + apiKey=real` 但 send 路径
/// 仍 "v1.0+ TODO 真实 SMS 发送未实现" → release 模式静默返 false → 上层
/// 走 "失败" 路径 → UI 提示"未连接"但**没有**启动 banner 显眼告警。
/// 精神心理患者和家属以为邮件能发,实际 100% 失败,跟 SmsService R63 修复前
/// 一样的"假失败"陷阱。
///
/// 修复后:
/// - `_isFullyImplemented` 默认 false (跟 AliyunSmsProvider 1:1)
/// - `isProductionReady` getter: `_isFullyImplemented && !_useMock && _apiKey != null`
/// - `validateForRelease(EmailService)` 静态方法: release + 未就绪 → 抛
/// - main.dart 在 SMS 守卫紧跟一行调 EmailService.validateForRelease 阻断
/// - `isMock` getter 保留, 跟 R63 SmsService 行为一致, UI 已有
///   `emailProviderNameProvider == 'mock'` 检测不会破坏
///
/// 真接 SendGrid (R55+) 时同步把 `_isFullyImplemented` 改 true, 跟 send()
/// 实际工作状态保持一致, 避免"4 字段齐全但 send 未接"的 hidden 状态。
class EmailService {
  final String? _apiKey;
  final bool _useMock;

  /// v0.27 round 67 (B-1 修复): 跟 SmsService 守门员 1:1 平行
  ///
  /// 默认 false: send() 当前是 v1.0+ TODO 状态 (`'真实 SMS 发送未实现'`),
  /// 即使 useMock=false + apiKey 配齐, 仍不算 production-ready。
  /// R55 真接 SendGrid 时同步改 true (跟 send() 实现同步)。
  final bool _isFullyImplemented;

  EmailService({
    String? apiKey,
    bool useMock = true,
    bool isFullyImplemented = false,
  })  : _apiKey = apiKey,
        _useMock = useMock,
        _isFullyImplemented = isFullyImplemented;

  /// v0.27 round 67 (B-1 修复): 是否生产可用 (跟 SmsService.isProductionReady 1:1)
  ///
  /// 三者必须同时满足:
  /// - `_isFullyImplemented` true (send() 实际能工作, R55 真接时改 true)
  /// - `_useMock` false (不是 mock 模式)
  /// - `_apiKey != null` (SendGrid API key 已配)
  ///
  /// 任何一项缺失 → release 模式启动时 `validateForRelease` 会阻断,
  /// banner 显眼提示"邮件未配置", 跟 SMS 守卫行为一致。
  bool get isProductionReady =>
      _isFullyImplemented && !_useMock && _apiKey != null;

  /// v0.23 round 39 (P1-8 fix): 当前是否 mock 模式 (给 UI 检测)
  ///
  /// 保留向后兼容: reminders_hub 的 SafetyReminderCard 已有
  /// `emailProviderNameProvider == 'mock'` 检测 (跟 SMS 一致), UI 拿这个
  /// getter 显示"未配置" banner。
  ///
  /// v0.27 round 67 (B-1 修复): 跟 R63 SmsService 行为对齐, 加 `_isFullyImplemented`
  /// 检查 (4 字段齐但 send 未接 → 也算 mock 状态, 跟 release 守卫一致)。
  bool get isMock => _useMock || _apiKey == null || !_isFullyImplemented;

  /// v0.27 round 67 (B-1 修复): 启动时 release-mode 守卫 (跟 SmsService 1:1)
  ///
  /// 流程:
  /// 1. release 模式 (kReleaseMode == true) 下, 如果 [isProductionReady]
  ///    是 false → 抛 Error, 状态 [EmailProviderNotConfiguredError]
  /// 2. dev / profile / test 模式: 什么都不做 (mock 是正常开发工具)
  ///
  /// main.dart 在 SmsService.validateForRelease 紧跟一行调本方法。
  /// 本方法抛错会被 runZonedGuarded 抓住并通过 LastErrorCapture 记录,
  /// AppRoot 启动后顶部 banner 显眼提示。
  ///
  /// 返回非 null 错误字符串: 给 caller 显式 log 用的 (跟 SmsService 返回
  /// void 不一样, 保留调试信息)。
  static String? validateForRelease(EmailService service) {
    if (kReleaseMode && !service.isProductionReady) {
      final reason = 'EmailService is not production-ready: '
          'useMock=${service._useMock}, '
          'apiKey=${service._apiKey != null ? "***" : "null"}, '
          'isFullyImplemented=${service._isFullyImplemented}. '
          'R55+ 真接 SendGrid 时改 _isFullyImplemented = true';
      piiSafeLog(
        'EmailService.validateForRelease',
        '🚨 release 模式检测到邮件 provider 未配置, 失联通知功能不可用',
        error: EmailProviderNotConfiguredError(reason),
      );
      throw EmailProviderNotConfiguredError(reason);
    }
    return null;
  }

  /// 发送失联通知（mock 阶段只打日志）
  ///
  /// [to] 现在是手机号（v0.6 之前是 email）
  /// v0.21 Round 23 (P1-24): userName 改 nullable
  /// 未填姓名时退化为 "您的家人",保持邮件/短信语法自然
  ///
  /// v0.24 round 48 (spen P0-4): 传 `DateTime.now()` 给 referenceNow,
  /// 让邮件时区基于当前系统 tz 推断(海外紧急联系人看到正确时区)
  ///
  /// v0.27 round 67 (B-1 修复): 入口验证 isProductionReady (跟 SmsService.send 1:1)
  ///
  /// 修复前: `_useMock || _apiKey == null` → mock 模式返 false
  /// 修复后: `!isProductionReady` 涵盖 3 种未就绪 (mock / 缺 apiKey /
  /// send 未接) → 一致返 false, 跟 SmsService mock 行为 1:1。
  Future<bool> sendMedicationReminder({
    required String to,
    String? userName,
    required int daysWithoutCheckIn,
    required DateTime? lastCheckIn,
    required MedicationEntity? medication,
    required int cycleHours,
  }) async {
    final now = DateTime.now();
    final subject = EmailTemplate.buildSubject(
      userName: userName,
      daysWithoutCheckIn: daysWithoutCheckIn,
    );

    final body = EmailTemplate.buildBody(
      userName: userName,
      daysWithoutCheckIn: daysWithoutCheckIn,
      lastCheckIn: lastCheckIn,
      medication: medication,
      cycleHours: cycleHours,
      referenceNow: now,
    );

    if (!isProductionReady) {
      piiSafeLog('EmailService', '=' * 60);
      piiSafeLog('EmailService', '🟠 [MOCK] 发送失联通知');
      piiSafeLog('EmailService', '  To (phone): ${maskPhone(to)}');
      piiSafeLog('EmailService', '  Subject: $subject');
      piiSafeLog('EmailService', '  ---');
      piiSafeLog('EmailService', body);
      piiSafeLog('EmailService', '=' * 60);
      // v0.23 round 39 (P1-8 fix): mock 状态 user-facing 透明
      // 之前返 true 让上层以为"已发送",实际只是 log
      // 改成返 false + 把 mock 标记透过 UI 提示
      // 真实接入 SDK 后这里返 true,SafetyWatchService 算 smsOk
      return false;
    }

    // 真实 SMS provider 占位——v1.0+ 替换
    // 注：v1.0 接入真实 SDK 时，try/catch 应包住实际网络调用（参考 AliyunSmsProvider）
    // v0.27 round 67 (B-1 修复): 入口已 isProductionReady 守门, 到这里说明
    // _isFullyImplemented=true (R55+ SendGrid 真接完成)。当前仍是占位
    // 实现, 跟 R67 前保持一致返 false。
    piiSafeLog('EmailService', '真实邮件 发送未实现（v1.0+ TODO）');
    return false;
  }
}

/// v0.27 round 67 (B-1 修复): release 模式启动时如果邮件未配置, 抛本错
///
/// 跟 SmsProviderNotConfiguredError 平行, 同样被 runZonedGuarded 抓住,
/// LastErrorCapture 记录, AppRoot banner 显眼提示。
class EmailProviderNotConfiguredError extends Error {
  final String reason;
  EmailProviderNotConfiguredError(this.reason);
  @override
  String toString() => 'EmailProviderNotConfiguredError: 启动检测到邮件 provider 未配置, '
      'release 模式必须注入真实 Email provider。reason=$reason';
}
