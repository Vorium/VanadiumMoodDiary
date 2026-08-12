// PhoneRegion 显示名 i18n helper
//
// v0.28 round 65 (spzh P2-F 修复): 5 region 硬编中文 → 走 i18n override 模式
// (同 `core/l10n/strings.dart` 模式: domain 0 flutter 边界 + override 注入)
//
// caller 模式:
//   regionDisplayName(PhoneRegion.cn, override: l10n.phoneRegionCn)
//
// 不传 override = 走中文 fallback (domain 单元测 / 老 caller 兼容)
//
// 5 region 各自 ARB key:
//   phoneRegionCn / phoneRegionHk / phoneRegionMo / phoneRegionTw / phoneRegionIntl
import 'package:chroniccare/core/shared/phone_validator.dart';

/// region 显示名 (中文 fallback, override 模式同 Strings)
///
/// 实现委托 enum 的 [PhoneRegion.displayNameL10n] 保证 single source of truth。
String regionDisplayName(
  PhoneRegion region, {
  String? override,
}) =>
    region.displayNameL10n(override: override);
