// 1.1.0 round 7b (P1 i18n): 预设内容显示层本地化 helper
//
// v1.1.0 新增的预设内容 (树洞预设标签 8 / 状态短语 17 / 情绪回顾鼓励文案 5)
// 存储层保持 canonical 中文 (DB / 导出 / domain 常量不动, 兼容性),
// 显示层按 locale 走 ARB。未知值 (自定义标签 / 自定义短语) 原样透传。
//
// 放 `lib/l10n/` 而非 `core/l10n/strings.dart` (跟 medication_unit_label.dart
// 先例一致): 需要 BuildContext + AppLocalizations, 是 presentation 层 helper;
// strings.dart 是 domain 层 fallback, 不能 import flutter。
//
// canonical zh 键 = domain 常量 (VentTagLibrary.presetTags /
// StatusPhraseLibrary), switch 用字面量是存储层 canonical 映射表,
// 新增/改名由 test/l10n/preset_content_l10n_round7_test.dart 全量映射断言锁同步。
import 'package:flutter/widgets.dart';

import 'package:chroniccare/domain/logic/mood_review_aggregator.dart';
import 'package:chroniccare/domain/logic/psychology_tips_library.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

/// 树洞预设标签本地化 — 8 个 canonical zh 预设 → ARB key, 未知 (自定义) 原样返回
String localizedVentTag(BuildContext context, String tag) {
  final l10n = AppLocalizations.of(context);
  return switch (tag) {
    '家庭' => l10n.ventTagFamily,
    '工作' => l10n.ventTagWork,
    '学业' => l10n.ventTagStudy,
    '亲密关系' => l10n.ventTagRelationship,
    '朋友' => l10n.ventTagFriends,
    '身体' => l10n.ventTagHealth,
    '情绪' => l10n.ventTagMood,
    '其他' => l10n.ventTagOther,
    _ => tag,
  };
}

/// 情绪状态短语本地化 — 17 条 canonical zh 预设 → ARB key (按
/// StatusPhraseLibrary 组顺序编号), 未知 (自定义) 原样返回
String localizedStatusPhrase(BuildContext context, String phrase) {
  final l10n = AppLocalizations.of(context);
  return switch (phrase) {
    '有点难过' => l10n.statusPhraseLow1,
    '心情很低落' => l10n.statusPhraseLow2,
    '想哭' => l10n.statusPhraseLow3,
    '提不起劲' => l10n.statusPhraseLow4,
    '疲惫但平静' => l10n.statusPhraseTired1,
    '好累' => l10n.statusPhraseTired2,
    '身体被掏空' => l10n.statusPhraseTired3,
    '只想躺着' => l10n.statusPhraseTired4,
    '平静' => l10n.statusPhraseCalm1,
    '安稳' => l10n.statusPhraseCalm2,
    '淡淡的' => l10n.statusPhraseCalm3,
    '没什么特别' => l10n.statusPhraseCalm4,
    '被治愈了' => l10n.statusPhrasePositive1,
    '心情不错' => l10n.statusPhrasePositive2,
    '充满能量' => l10n.statusPhrasePositive3,
    '有盼头' => l10n.statusPhrasePositive4,
    '很快乐' => l10n.statusPhrasePositive5,
    _ => phrase,
  };
}

/// 情绪回顾鼓励文案本地化 — tier → ARB key
String localizedEncouragement(
  BuildContext context,
  MoodReviewEncouragementTier tier,
) {
  final l10n = AppLocalizations.of(context);
  return switch (tier) {
    MoodReviewEncouragementTier.empty => l10n.moodReviewEncouragementEmpty,
    MoodReviewEncouragementTier.low => l10n.moodReviewEncouragementLow,
    MoodReviewEncouragementTier.mid => l10n.moodReviewEncouragementMid,
    MoodReviewEncouragementTier.high => l10n.moodReviewEncouragementHigh,
    MoodReviewEncouragementTier.noAvg => l10n.moodReviewEncouragementNoAvg,
  };
}

/// 烦恼引导提示本地化 — 索引 (1..5) → ARB key
///
/// R128e (论文3 §5.3): 帮用户打开思路的认知重构引导。
String localizedWorryGuidance(BuildContext context, int index) {
  final l10n = AppLocalizations.of(context);
  return switch (index) {
    1 => l10n.worryGuidance1,
    2 => l10n.worryGuidance2,
    3 => l10n.worryGuidance3,
    4 => l10n.worryGuidance4,
    _ => l10n.worryGuidance5,
  };
}

/// 心理技巧本地化结果 (title / summary / steps 全部按 locale 走 ARB)
class LocalizedPsychologyTip {
  const LocalizedPsychologyTip({
    required this.title,
    required this.summary,
    required this.steps,
  });

  final String title;
  final String summary;
  final List<String> steps;
}

/// 心理技巧本地化 — tip id → ARB key, 未知 id 原样返回 canonical zh
///
/// 新增/改名由 test/l10n/preset_content_l10n_round7_test.dart 全量映射断言锁同步
/// (跟 localizedVentTag / localizedStatusPhrase 同模式)。
LocalizedPsychologyTip localizedPsychologyTip(
  BuildContext context,
  PsychologyTip tip,
) {
  final l10n = AppLocalizations.of(context);
  return switch (tip.id) {
    'mindfulBreathing' => LocalizedPsychologyTip(
        title: l10n.psychoTipBreathTitle,
        summary: l10n.psychoTipBreathSummary,
        steps: [
          l10n.psychoTipBreathStep1,
          l10n.psychoTipBreathStep2,
          l10n.psychoTipBreathStep3,
          l10n.psychoTipBreathStep4,
          l10n.psychoTipBreathStep5,
        ],
      ),
    'nameEmotion' => LocalizedPsychologyTip(
        title: l10n.psychoTipNameTitle,
        summary: l10n.psychoTipNameSummary,
        steps: [
          l10n.psychoTipNameStep1,
          l10n.psychoTipNameStep2,
          l10n.psychoTipNameStep3,
          l10n.psychoTipNameStep4,
          l10n.psychoTipNameStep5,
        ],
      ),
    'cognitiveReframing' => LocalizedPsychologyTip(
        title: l10n.psychoTipCbtTitle,
        summary: l10n.psychoTipCbtSummary,
        steps: [
          l10n.psychoTipCbtStep1,
          l10n.psychoTipCbtStep2,
          l10n.psychoTipCbtStep3,
          l10n.psychoTipCbtStep4,
          l10n.psychoTipCbtStep5,
        ],
      ),
    'grounding54321' => LocalizedPsychologyTip(
        title: l10n.psychoTipGroundTitle,
        summary: l10n.psychoTipGroundSummary,
        steps: [
          l10n.psychoTipGroundStep1,
          l10n.psychoTipGroundStep2,
          l10n.psychoTipGroundStep3,
          l10n.psychoTipGroundStep4,
          l10n.psychoTipGroundStep5,
        ],
      ),
    'progressiveMuscleRelaxation' => LocalizedPsychologyTip(
        title: l10n.psychoTipPmrTitle,
        summary: l10n.psychoTipPmrSummary,
        steps: [
          l10n.psychoTipPmrStep1,
          l10n.psychoTipPmrStep2,
          l10n.psychoTipPmrStep3,
          l10n.psychoTipPmrStep4,
          l10n.psychoTipPmrStep5,
        ],
      ),
    _ => LocalizedPsychologyTip(
        title: tip.title,
        summary: tip.summary,
        steps: tip.steps,
      ),
  };
}
