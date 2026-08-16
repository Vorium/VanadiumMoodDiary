// v0.32 R112 (AR-16): AppLocalizations → CbtPdfL10n 适配器 (presentation)
//
// 背景: `CbtThoughtRecordPdf.build` / `CbtLayout` 原接受 AppLocalizations
// (data→l10n 循环, AR-16)。R112 改 data 侧 `CbtPdfL10n` interface
// (cbt_thought_record_pdf_layout.dart), 本适配器把 AppLocalizations 的
// 12 个 getter 委托给 interface, caller 一行构造:
// `CbtThoughtRecordPdf().build(l10n: AppLocalizationsCbtPdfL10n(l10n))`。
import 'package:chroniccare/core/data/services/cbt_thought_record_pdf_layout.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

/// [CbtPdfL10n] 的 AppLocalizations 实现 (12 getter 委托)
class AppLocalizationsCbtPdfL10n implements CbtPdfL10n {
  final AppLocalizations l10n;
  const AppLocalizationsCbtPdfL10n(this.l10n);

  @override
  String get moodCbtSectionSituation => l10n.moodCbtSectionSituation;

  @override
  String get moodCbtSectionAutomaticThought =>
      l10n.moodCbtSectionAutomaticThought;

  @override
  String get moodCbtSectionEvidenceFor => l10n.moodCbtSectionEvidenceFor;

  @override
  String get moodCbtSectionEvidenceAgainst =>
      l10n.moodCbtSectionEvidenceAgainst;

  @override
  String get moodCbtSectionAlternative => l10n.moodCbtSectionAlternative;

  @override
  String get moodCbtSectionRerated => l10n.moodCbtSectionRerated;

  @override
  String get moodCbtScoreReratedLabel => l10n.moodCbtScoreReratedLabel;

  @override
  String get moodCbtSectionCoreBelief => l10n.moodCbtSectionCoreBelief;

  @override
  String get moodCbtSectionBehavior => l10n.moodCbtSectionBehavior;

  @override
  String get cbtExportPdfEmpty => l10n.cbtExportPdfEmpty;

  @override
  String get moodCbtChipBadge5 => l10n.moodCbtChipBadge5;

  @override
  String get moodCbtChipBadge7 => l10n.moodCbtChipBadge7;

  @override
  String get cbtExportPdfMoodLabel => l10n.cbtExportPdfMoodLabel;

  @override
  String get cbtExportPdfOriginalScoreLabel =>
      l10n.cbtExportPdfOriginalScoreLabel;
}
