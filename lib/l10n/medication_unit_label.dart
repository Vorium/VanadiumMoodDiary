// v0.27 round 61 (P2): dosage unit 国际化 helper
//
// 之前 widget 直接 `m.dosageUnit.id` → en 用户看 '片' 困惑
// (DosageUnit enum.id 存原 'mg'/'片' 字符串, 跟 DB 兼容, 不迁移)。
//
// 修法: presentation 层调本 helper 走 ARB i18n:
//   - zh: 'mg' / '片'
//   - en: 'mg' / 'tablet'
//   - zh_Hant: 'mg' / '片'
//
// 放 `lib/l10n/` 而非 `core/l10n/strings.dart`:
// - strings.dart 是 domain 层 fallback, 不能 import flutter / AppLocalizations
// - 本 helper 需要 AppLocalizations 类型, 是 presentation 层
// - 跟 app_localizations.dart 同级, i18n 集中器
import 'package:flutter/widgets.dart';

import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

/// 国际化剂量单位标签
///
/// [context] 用于拿 [AppLocalizations]
/// [unit] DosageUnit enum (mg / tablet)
/// 返回走 ARB i18n 路径的单位字符串。
String dosageUnitLabel(BuildContext context, DosageUnit unit) {
  final l10n = AppLocalizations.of(context);
  return switch (unit) {
    DosageUnit.mg => l10n.medicationUnitMg,
    DosageUnit.tablet => l10n.medicationUnitTablet,
  };
}
