// v0.29 R87 (P1-2/3/4 架构违规修复): SafetyAlertL10n 抽象 interface
//
// 历史: 3 个 data service (`safety_watch_service` / `safety_alert_builder` /
// `safety_alert_dispatcher`) 都 import `package:chroniccare/l10n/app_localizations.dart`
// (presentation 层) — 违反 4 层架构 (data 不能依赖 presentation)。
//
// 修法: 抽 abstract `SafetyAlertL10n` interface 放 `core/l10n/` (domain/shared
// 范畴, data 可依赖)。3 个 data 文件改 import 这个 interface, 调抽象方法。
// presentation 层 `AppLocalizations implements SafetyAlertL10n` 自动满足,
// 所有 caller (传 `AppLocalizations`) 不需改。
//
// R96 修正: 参数名跟 `AppLocalizations` 保持一致 (Dart 3 nominal typing
// 严格检查 parameter name)。`AppLocalizations` 是 ARB 自动生成的, 参数名
// 跟 `.arb` placeholder 一致, 不可改。所以这里用 `days` / `date` 等通用名。
//
// 业务效果: 零功能变更, 仅修复分层 + 提供单测 mock 点 (test 可注入 fake impl)。

/// 失联通知 / safety check 文案抽象 interface
///
/// 实现: `AppLocalizations` (presentation 层) 隐式实现本 interface,
/// 所有 getter 走 ARB i18n。
///
/// 设计原则:
/// - **方法不传 placeholder**: 参数化方法 (e.g. safetyCheckResultOk 需 days)
///   走 method 形式, 不返 String template (避免 i18n 模板 syntax 不一致)
/// - **枚举化**: 不返 enum 引用 (避免 data → domain 双向耦合), 返 final String
abstract interface class SafetyAlertL10n {
  // ===== safetyCheckResult 系列 (SafetyCheckResult.displayMessageL10n 用) =====

  /// 失联通知功能未启用
  String get safetyCheckResultDisabled;

  /// 用户最近 < 阈值天 打卡, 状态 OK
  /// [days] 距上次打卡天数
  String safetyCheckResultOk(int days);

  /// 失联检测无数据 (用户还没 setup 或没打卡过)
  String get safetyCheckResultNoData;

  /// 今天已经发过失联告警 (24h 内不重复发)
  /// [days] 距上次打卡天数
  String safetyCheckResultAlertedToday(int days);

  /// 当前在 DND (Do Not Disturb) 时段, 跳过本次
  String get safetyCheckResultDndSuppressed;

  /// 没添加紧急联系人, 无法发失联通知
  String get safetyCheckResultNoContacts;

  /// 已 mock 模式发 (dev 测试)
  /// [mocked] mock 数量
  String safetyCheckResultAlertedMocked(int mocked);

  /// 真实发结果
  /// [days] 失联天数
  /// [notified] 成功通知数量
  /// [failed] 失败数量
  String safetyCheckResultAlerted(int days, int notified, int failed);

  /// 发失败 (SMS 真实接入失败)
  /// [message] 错误细节
  String safetyCheckResultError(String message);

  // ===== safetyAlert 系列 (SafetyAlertBuilder 用) =====

  /// 失联通知标题 (R32 P0-04 锁屏 PII 跨 3 视角共识: 改静态不含 name)
  /// [days] 失联天数
  String safetyAlertTitle(int days);

  /// 用户从未打卡过
  String get safetyAlertNeverCheckIn;

  /// SMS 真发成功
  /// [date] 上次打卡时间字符串
  String safetyAlertBodySent(String date);

  /// SMS mock 模式 (dev)
  /// [date] 上次打卡时间字符串
  String safetyAlertBodyMocked(String date);

  /// SMS 发送失败
  /// [date] 上次打卡时间字符串
  String safetyAlertBodyFailed(String date);
}
