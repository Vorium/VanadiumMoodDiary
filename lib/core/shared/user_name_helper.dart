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
// 放 `core/shared/` 而非 `domain/entities/`，因为它属于"跨层共享的
// 纯工具"（presentation / data / domain 都用得上），跟 `formatters` /
// `mood_visual` 同类。

import 'package:chroniccare/core/l10n/strings.dart';

/// 把可空的 `userName` 转为可显示的展示文本。
///
/// [fallback] 默认 `Strings.userNamePolite` ("您")。
/// 通知 / 邮件场景常用 `Strings.userNameFamily` ("您的家人") 更礼貌。
///
/// v0.27 round 62 (P1-8 修复): 把 hardcode 中文默认值从 '您'
/// 改到 `Strings.userNamePolite` 集中常量, 跟 email_template /
/// reminder_scheduler / safety_alert_dispatcher / notification_service
/// 4 处 hardcode 一起走 Strings 集中, 方便后续 i18n override 模式。
String safeUserName(String? value, {String fallback = Strings.userNamePolite}) {
  if (value == null || value.isEmpty) return fallback;
  return value;
}
