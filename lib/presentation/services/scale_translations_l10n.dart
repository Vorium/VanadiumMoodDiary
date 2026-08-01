// v0.27 round 75 (R74 报告 P1-1 修): `AppLocalizationsScaleTranslations` 从
// `lib/domain/entities/scale_translations.dart` 移到 presentation 层。
//
// 原因: domain 层 0 Flutter 0 Drift (4 层架构纯度) — 之前类在 domain
// 但实际依赖 AppLocalizations, 间接 import Flutter, 触发 R74 报告的
// "soft 架构违规" P1-1。
//
// 修法: 类移到 presentation 层, domain 只留 abstract ScaleTranslations + 中文
// fallback StaticScaleTranslations。当前 0 caller 引用 (R65 抽象 + R71 crisis
// i18n 抽走 fallback), 0 回归风险。R76+ 真接 SMS/Email 后, 紧急联系人 + 评估
// 报告 + 失联通知 都需要 l10n, 走 `AppLocalizationsScaleTranslations(l10n)` 包装。
import 'package:chroniccare/domain/entities/scale_translations.dart';
import 'package:chroniccare/domain/logic/assessment_scale.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

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
