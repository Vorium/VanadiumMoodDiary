// v0.32 round 8 (R111 R111-02 fix): 量表名/短描述 l10n 派发 (presentation)
//
// 背景: 3 处 en 可见位置 (assessment_page AppBar title / settings
// assessment_section / 趋势图 tooltip legend) 直接 `scale.displayName`,
// 而 scale_registry 的 const 单例走 StaticScaleTranslations 中文 fallback
// → en 用户看到中文量表名 (R111-02)。assessment_center_card 已有私有
// _l10nName switch, 这里抽成公共 helper 让 3 处共享。
//
// v0.32 R112 (AR-17): 原 AppLocalizationsScaleTranslations (810L, 0 运行时
// caller) 已删, 本 helper 成为量表名/短描述唯一 presentation 派发源
// (source of truth = domain StaticScaleTranslations 中文 fallback + 本文件)。
//
// 量表题目 (items) i18n 仍留 v1.0 (R51b backlog), 本 helper 只覆盖
// name / shortDescription (用户第一眼可见的 2 个字段)。
import 'package:chroniccare/l10n/app_localizations.dart';

/// 量表名 l10n 派发 (10 开放量表)
///
/// v0.32 R112 (裸 id 回归修复): default 分支加 assert(false) — 未来新量表
/// 忘记注册 case 时 debug 直接炸 (返 id 裸上屏是 silent bug), release 仍返
/// id 兜底不崩。
String scaleNameL10n(String id, AppLocalizations l10n) => switch (id) {
      'phq9' => l10n.assessmentScalePhq9,
      'gad7' => l10n.assessmentScaleGad7,
      'isi' => l10n.isiName,
      'pss' => l10n.pssName,
      'whodas' => l10n.whodasName,
      'level2_depression' => l10n.level2DepressionName,
      'level2_anxiety' => l10n.level2AnxietyName,
      'level2_mania' => l10n.level2ManiaName,
      'asrm' => l10n.asrmName,
      'level2_psychosis' => l10n.level2PsychosisName,
      _ => _unregisteredId(id),
    };

/// 量表短描述 l10n 派发
///
/// v0.32 R112 (裸 id 回归修复): 补 phq9/gad7 2 case (之前 settings 量表
/// 列表 subtitle 显示裸 id "phq9"/"gad7"); default 分支 assert 同上。
String scaleShortDescL10n(String id, AppLocalizations l10n) => switch (id) {
      'phq9' => l10n.phq9ShortDescription,
      'gad7' => l10n.gad7ShortDescription,
      'isi' => l10n.isiShortDescription,
      'pss' => l10n.pssShortDescription,
      'whodas' => l10n.whodasShortDescription,
      'level2_depression' => l10n.level2DepressionShortDescription,
      'level2_anxiety' => l10n.level2AnxietyShortDescription,
      'level2_mania' => l10n.level2ManiaShortDescription,
      'asrm' => l10n.asrmShortDescription,
      'level2_psychosis' => l10n.level2PsychosisShortDescription,
      _ => _unregisteredId(id),
    };

/// 未注册量表 id 兜底 — debug 断言防未来裸 id 上屏, release 返 id 不崩
String _unregisteredId(String id) {
  assert(false, '未注册量表: $id');
  return id;
}
