// 量表翻译抽象 (v0.28 round 65 spzh P1-A 起步)
//
// 背景 (spzh P1-A):
//   PHQ-9 / GAD-7 量表 16 题 + 9 档严重度 + 6 region 危机电话 label 全部 const
//   硬编中文, en / zh_Hant 用户看中文 label, 海外华人危机电话 region 路由被
//   中文 label 抵消 = 医疗法律责任。
//
// 修法 (起步, **不**完全 16 题 9 档 i18n 化):
//   1) 抽 `ScaleTranslations` abstract class
//   2) 改 `AssessmentScale` 抽象类加 `translations: ScaleTranslations` 字段
//   3) `Phq9Scale` / `Gad7Scale` 注入 ScaleTranslations (老 caller 用
//      `const StaticScaleTranslations()` 走中文 fallback)
//   4) `AppLocalizationsScaleTranslations` 走 `AppLocalizations` 包装
//   5) 6 个 i18n key (复用现有 `assessmentScalePhq9` / `assessmentScaleGad7`,
//      新加 `scaleHotlineCn` / `scaleHotlineUs` / `scaleHotlineHk` / `scaleHotlineIntl`)
//
// 16 题全文 i18n 化留 v1.0 (spzh report P1-A 已记 TODO)。
//
// 现有 21 case crisis test (`phq9_detect_crisis_round60_test.dart` + `phq9_round12_test.dart` +
// `gad7_round16_test.dart`) **不破** — 老 caller 走 `const StaticScaleTranslations()` 返中文
// fallback, hotlines 直接用 `hotlineByRegion[region]` const Map (label 是中文)。
// v0.28 起步版本额外: crisis hotlines 在 detectCrisis 时用 `translations.crisisHotlineLabel(region)`
// 翻译 label, region 不在 i18n key 范围 (tw/sg/uk) 走 intl fallback。

import 'package:chroniccare/domain/logic/assessment_scale.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

/// 量表翻译抽象
///
/// 起步覆盖:
/// - 2 个量表名 (phq9 / gad7) — 复用现有 `assessmentScalePhq9` / `assessmentScaleGad7` ARB key
/// - 4 region 危机电话 label (cn / us / hk / intl) — 新 `scaleHotline*` ARB key
///
/// 16 题全文 / 5 严重度 / 4 档选项 / 2 instruction 全文 i18n 化留 v1.0。
abstract class ScaleTranslations {
  const ScaleTranslations();

  /// PHQ-9 量表名
  String phq9Name({String? override});

  /// GAD-7 量表名
  String gad7Name({String? override});

  /// 6 region 危机电话 label (cn / us / hk / tw / sg / uk)
  /// — tw/sg/uk 起步版本走 intl fallback (后续 R65b 补 3 个 region key)
  String crisisHotlineLabel(HotlineRegion region, {String? override});

  /// v0.27 R71 (spzh P1-A 续): 危机弹窗标题 (PHQ-9 Q9 阳性时)
  /// — 之前 detectCrisis 用 const 中文 '我们关心你' 硬编, en / zh_Hant 用户看中文
  String crisisTitle({String? override});

  /// v0.27 R71 (spzh P1-A 续): 危机弹窗正文 (含换行)
  /// — 之前 detectCrisis 用 const 中文 '你提到了想伤害自己的念头...'
  String crisisMessage({String? override});
}

/// 静态中文 fallback (老 caller / 单测 / domain 0 flutter 边界)
class StaticScaleTranslations implements ScaleTranslations {
  const StaticScaleTranslations();

  @override
  String phq9Name({String? override}) => override ?? 'PHQ-9 抑郁筛查';

  @override
  String gad7Name({String? override}) => override ?? 'GAD-7 焦虑筛查';

  @override
  String crisisHotlineLabel(HotlineRegion region, {String? override}) {
    if (override != null) return override;
    // 起步版本: 翻译 key 走 `hotlineByRegion[region].first.label` (中文 fallback)
    final list = hotlineByRegion[region];
    if (list == null || list.isEmpty) return region.name;
    return list.first.label;
  }

  @override
  String crisisTitle({String? override}) => override ?? '我们关心你';

  @override
  String crisisMessage({String? override}) => override ??
      '你提到了想伤害自己的念头。\n请记住：寻求帮助是勇敢的，不是软弱。';
}

/// AppLocalizations 包装 (presentation 层注入, 走 zh / en / zh_Hant)
class AppLocalizationsScaleTranslations implements ScaleTranslations {
  final AppLocalizations l10n;
  const AppLocalizationsScaleTranslations(this.l10n);

  @override
  String phq9Name({String? override}) => override ?? l10n.assessmentScalePhq9;

  @override
  String gad7Name({String? override}) => override ?? l10n.assessmentScaleGad7;

  @override
  String crisisHotlineLabel(HotlineRegion region, {String? override}) {
    if (override != null) return override;
    // v0.28 round 65 起步: 4 region 有独立 i18n key (cn/us/hk/intl),
    // tw/sg/uk 暂时走 intl fallback (TODO R65b 补 3 key)
    switch (region) {
      case HotlineRegion.cn:
        return l10n.scaleHotlineCn;
      case HotlineRegion.us:
        return l10n.scaleHotlineUs;
      case HotlineRegion.hk:
        return l10n.scaleHotlineHk;
      case HotlineRegion.tw:
      case HotlineRegion.sg:
      case HotlineRegion.uk:
        return l10n.scaleHotlineIntl;
    }
  }

  @override
  String crisisTitle({String? override}) => override ?? l10n.scaleCrisisTitle;

  @override
  String crisisMessage({String? override}) =>
      override ?? l10n.scaleCrisisMessage;
}
