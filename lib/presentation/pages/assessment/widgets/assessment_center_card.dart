// v0.30 round 90 (sub-spec 6 量表中心): 10 开放量表卡片 widget
//
// - 量表名 (大) + 短描述 (caption)
// - 上次得分 (大数字 + 严重度 badge)
// - 上次时间 ("3 天前")
// - "开始" 按钮 (CTA) → 跳 /assessment/:scaleId (R60 老路由)
//
// 复用 R60 AssessmentScale interface + scale.displayName / shortDescription.
// 风格跟 R60 assessment_history_list + R45 settings Card widget 同款.
// v0.30 R90 Task 6: 量表名/描述 走 l10n.xxxName/ShortDescription (Task 6 ARB),
// 卡片文案 (上次得分/尚未填写过/开始评估) 走 l10n.assessmentCenterXxx.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/assessment_entry.dart';
import 'package:chroniccare/domain/logic/assessment_scale.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

/// 开放量表卡片 (10 张之一, 跳 R60 /assessment/:scaleId 答题页)
///
/// 通过 switch (scale.id) 派发到对应 l10n getter; const class 的 displayName /
/// shortDescription 是 const 中文 fallback (单测 / 老 caller 用), presentation
/// 路径一律走 l10n。
class AssessmentCenterCard extends StatelessWidget {
  final AssessmentScale scale;
  final AssessmentEntry? latestEntry;

  const AssessmentCenterCard({
    super.key,
    required this.scale,
    this.latestEntry,
  });

  /// 量表名 l10n 派发 (跟 AppLocalizationsScaleTranslations 平行)
  String _l10nName(AppLocalizations l10n) {
    switch (scale.id) {
      case 'phq9':
        return l10n.assessmentScalePhq9;
      case 'gad7':
        return l10n.assessmentScaleGad7;
      case 'isi':
        return l10n.isiName;
      case 'pss':
        return l10n.pssName;
      case 'whodas':
        return l10n.whodasName;
      case 'level2_depression':
        return l10n.level2DepressionName;
      case 'level2_anxiety':
        return l10n.level2AnxietyName;
      case 'level2_mania':
        return l10n.level2ManiaName;
      case 'asrm':
        return l10n.asrmName;
      case 'level2_psychosis':
        return l10n.level2PsychosisName;
      default:
        return scale.displayName;
    }
  }

  /// 量表短描述 l10n 派发
  String _l10nShortDesc(AppLocalizations l10n) {
    switch (scale.id) {
      case 'isi':
        return l10n.isiShortDescription;
      case 'pss':
        return l10n.pssShortDescription;
      case 'whodas':
        return l10n.whodasShortDescription;
      case 'level2_depression':
        return l10n.level2DepressionShortDescription;
      case 'level2_anxiety':
        return l10n.level2AnxietyShortDescription;
      case 'level2_mania':
        return l10n.level2ManiaShortDescription;
      case 'asrm':
        return l10n.asrmShortDescription;
      case 'level2_psychosis':
        return l10n.level2PsychosisShortDescription;
      default:
        return scale.shortDescription;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: InkWell(
        onTap: () => context.push('/assessment/${scale.id}'),
        child: Padding(
          padding: AppTokens.edgeInsetsMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 量表名 (大) — 走 l10n
              Text(
                _l10nName(l10n),
                style: AppTokens.textStyleTitle(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppTokens.spacingXxs),
              // 短描述 (caption) — 走 l10n (PHQ-9 / GAD-7 走现有 shortDesc 兜底)
              Text(
                _l10nShortDesc(l10n),
                style: AppTokens.textStyleCaption(context),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              // 上次得分 / fallback 文案
              if (latestEntry != null) ...[
                Text(
                  l10n.assessmentCenterLastScore(latestEntry!.score),
                  style: AppTokens.textStyleHeadline(context),
                ),
                Text(
                  l10n.assessmentCenterLastTime(
                    _formatTime(latestEntry!.timestamp, l10n),
                  ),
                  style: AppTokens.textStyleCaption(context),
                ),
              ] else
                Text(
                  l10n.assessmentCenterNoData,
                  style: AppTokens.textStyleCaption(context),
                ),
              const SizedBox(height: AppTokens.spacingXs),
              // CTA 按钮 (走 FilledButton.tonal, 跟 settings 按钮风格一致)
              FilledButton.tonal(
                onPressed: () => context.push('/assessment/${scale.id}'),
                child: Text(l10n.assessmentCenterStartButton),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 相对时间显示 ("3 天前" / "5 小时前" / "刚刚")
  ///
  /// v0.30 R95 sub-spec 7 task 55: 走 l10n.timeAgoXxx 集中器, 替代 hardcoded
  /// 中文 "刚刚" / "N 天前" / "N 小时前" (R60 之前的 fallback)。
  ///
  /// 跟 R60 mood_list "3 天前" 风格一致; 跨 midnight 自动 stale 但 Material
  /// build 内取 DateTime.now() 是常见模式, 不再单独监听时间 (跟 streak summary
  /// 一样, 跨日由 AppRoot midnight timer refresh 触发).
  String _formatTime(DateTime ts, AppLocalizations l10n) {
    final diff = DateTime.now().difference(ts);
    if (diff.inDays > 0) return l10n.timeAgoDaysAgo(diff.inDays);
    if (diff.inHours > 0) return l10n.timeAgoHoursAgo(diff.inHours);
    return l10n.timeAgoJustNow;
  }
}
