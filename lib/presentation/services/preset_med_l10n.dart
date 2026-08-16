// v0.32 R112 (AR-16): 预置方案 l10n 解析 (presentation extension)
//
// 背景: `MedicationDraft.nameL10n/hintL10n` + `MedicationTemplate.nameL10n/
// descriptionL10n` 原在 data 层 `preset_medication_templates.dart` 接受
// AppLocalizations — data→l10n 循环 (AR-16)。R112 移到 presentation
// extension, data 文件只保留 i18n key 数据, caller 语法不变
// (`t.nameL10n(l10n)` 走 extension, 需 import 本文件)。
//
// 原方法语义 (v0.28 round 65 spzh P2-G) 保持不变:
// - key 未注册 → 返 key 本身 (兜底不崩)
import 'package:chroniccare/core/data/services/preset_medication_templates.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

/// 药物草稿 i18n 解析 (name / hint)
extension MedicationDraftL10n on MedicationDraft {
  /// i18n 药名 — caller 传 AppLocalizations 拿 zh/en/zh_Hant 文案
  String nameL10n(AppLocalizations l10n) => switch (nameKey) {
        'presetMedSsriName' => l10n.presetMedSsriName,
        'presetMedMoodStabilizerName' => l10n.presetMedMoodStabilizerName,
        'presetMedSleepAidName' => l10n.presetMedSleepAidName,
        'presetMedAntipsychoticName' => l10n.presetMedAntipsychoticName,
        'presetMedSedativeAnxiolyticName' =>
          l10n.presetMedSedativeAnxiolyticName,
        _ => nameKey,
      };

  /// i18n 备注 (可空) — caller 传 AppLocalizations 拿 zh/en/zh_Hant 文案
  String? hintL10n(AppLocalizations l10n) => hintKey == null
      ? null
      : switch (hintKey!) {
          'presetMedSsriHint' => l10n.presetMedSsriHint,
          'presetMedMoodStabilizerHint' => l10n.presetMedMoodStabilizerHint,
          'presetMedSleepAidHint' => l10n.presetMedSleepAidHint,
          'presetMedAntipsychoticHint' => l10n.presetMedAntipsychoticHint,
          'presetMedSedativeAnxiolyticHint' =>
            l10n.presetMedSedativeAnxiolyticHint,
          _ => hintKey,
        };
}

/// 预置方案 i18n 解析 (name / description)
extension MedicationTemplateL10n on MedicationTemplate {
  /// i18n 方案名
  String nameL10n(AppLocalizations l10n) => switch (nameKey) {
        'presetMedSsriMorningTitle' => l10n.presetMedSsriMorningTitle,
        'presetMedMoodStabilizerTwiceTitle' =>
          l10n.presetMedMoodStabilizerTwiceTitle,
        'presetMedComboSsriBedtimeTitle' => l10n.presetMedComboSsriBedtimeTitle,
        'presetMedComboAntipsychoticFullTitle' =>
          l10n.presetMedComboAntipsychoticFullTitle,
        _ => nameKey,
      };

  /// i18n 方案描述
  String descriptionL10n(AppLocalizations l10n) => switch (descriptionKey) {
        'presetMedSsriMorningDesc' => l10n.presetMedSsriMorningDesc,
        'presetMedMoodStabilizerTwiceDesc' =>
          l10n.presetMedMoodStabilizerTwiceDesc,
        'presetMedComboSsriBedtimeDesc' => l10n.presetMedComboSsriBedtimeDesc,
        'presetMedComboAntipsychoticFullDesc' =>
          l10n.presetMedComboAntipsychoticFullDesc,
        _ => descriptionKey,
      };
}
