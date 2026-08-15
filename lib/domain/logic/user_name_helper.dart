// 安全地获取可显示的用户名
//
// v0.21 Round 23 (P1-24): `user_profiles.userName` 改 nullable。
// 升级用户 schema 没改（drift alter table 限制），老数据仍是 "" 空字符串。
// 所有读 userName 的代码必须用这个 helper 统一兼容：
// - 老数据 `""`（空字符串）
// - 新数据 `null`
// - 用户未填 → `fallback`（默认 `"您"`）
//
// v0.22 round 31 (sp-en P0-3): 抽到 `core/shared/`，消除 5+ 处
// `(userName == null || userName.isEmpty)` 重复逻辑。
//
// v0.32 round 8 (R111 B1-5 联动): 从 `core/shared/` 移到 `domain/logic/`。
// 删 SafetyAlertBuilder.buildFor 死 userName 参数后, 唯一剩下的调用方是
// domain 层 (lost_contact_sms / email_template), check_all.dart 一致性
// 规则要求 shared/ 文件至少被 2 层使用 → 移到 domain/logic/ 满足规则。

import 'package:chroniccare/core/l10n/strings.dart';

/// 把可空的 `userName` 转为可显示的展示文本。
///
/// [fallback] 默认 `Strings.userNamePolite` ("您")。
///
/// 1.1.0 round 4b: 原 `Strings.userNameFamily` ("您的家人", 失联 SMS/邮件
/// 场景) 已随外联服务整摘删除。
///
/// v0.27 round 62 (P1-8 修复): 把 hardcode 中文默认值从 '您'
/// 改到 `Strings.userNamePolite` 集中常量, 跟 email_template /
/// reminder_scheduler / safety_alert_dispatcher / notification_service
/// 4 处 hardcode 一起走 Strings 集中, 方便后续 i18n override 模式。
String safeUserName(String? value, {String fallback = Strings.userNamePolite}) {
  if (value == null || value.isEmpty) return fallback;
  return value;
}
