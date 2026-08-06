// v0.30 round 95 (sub-spec 6 task 6b): 拆 scale_translations_l10n 785 → 2 文件
//
// 背景 (R95 报告 §2.2 / §4.2):
// - scale_translations_l10n.dart 785 行 (1 个 class AppLocalizationsScaleTranslations
//   含 10 量表 186 method), 是 R95 报告 §2.2 标 "P0 必拆" 的 600+ 行文件之一
// - 跟 R95 sub-spec 4 task 2 拆 scale_translations 模式一致 (abstract 主壳 +
//   static sub-file), 主壳只 re-export
//
// 结构:
// - 本文件 (主壳, 24 行): re-export AppLocalizationsScaleTranslations
//   让老 caller `import 'package:chroniccare/presentation/services/scale_translations_l10n.dart'`
//   0 改动 (跟 R95 sub-spec 4 task 2 拆 scale_translations 0 老 caller 改动模式一致)
// - scale_translations_l10n/static_scale_translations_l10n.dart (impl 760 行):
//   AppLocalizationsScaleTranslations 类实现 (10 量表 186 method i18n 委托给
//   AppLocalizations)
//
// 跟 R95 sub-spec 4 task 2 差异:
// - scale_translations 拆 static_scale_translations 用了不同类名 (abstract
//   ScaleTranslations → static impl StaticScaleTranslations)
// - scale_translations_l10n 保持原类名 AppLocalizationsScaleTranslations 不变
//   (这是 public API, 老 caller 0 改动)
//
// 跟 R95 sub-spec 4 task 5 / task 6 / task 7 模式一致:
// - 主壳 re-export 让老 caller 0 改动
// - 老 37 case scale_strings_arb_lock_in_round95_test 仍全过 (abstract 主壳 + impl sub-file)
// - 0 业务行为变化
export 'package:chroniccare/presentation/services/scale_translations_l10n/static_scale_translations_l10n.dart'
    show AppLocalizationsScaleTranslations;

// 占位: 老 import 'package:chroniccare/domain/logic/assessment_scale.dart' 仍走
// AppLocalizationsScaleTranslations → ScaleTranslations interface, 老 caller
// `translations.phq9Name()` 0 改动
