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
//
// v0.32 R112 (AR-17): 私有 _l10nName/_l10nShortDesc switch 迁到公共 helper
// scaleNameL10n/scaleShortDescL10n (presentation/services), 量表名派发
// 收敛为单一 source (原 AppLocalizationsScaleTranslations 810L 死代码已删).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/assessment_entry.dart';
import 'package:chroniccare/domain/logic/assessment_scale.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/services/scale_name_l10n.dart';

/// 开放量表卡片 (10 张之一, 跳 R60 /assessment/:scaleId 答题页)
///
/// 量表名/短描述走 [scaleNameL10n] / [scaleShortDescL10n] 公共派发 helper
/// (R112 AR-17 收敛 4 源 → 2 源: domain 中文 fallback + 本 helper)。
class AssessmentCenterCard extends StatelessWidget {
  final AssessmentScale scale;
  final AssessmentEntry? latestEntry;

  const AssessmentCenterCard({
    super.key,
    required this.scale,
    this.latestEntry,
  });

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
              // 量表名 (大) — 走公共 scaleNameL10n helper (R112 AR-17)
              Text(
                scaleNameL10n(scale.id, l10n),
                style: AppTokens.textStyleTitle(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppTokens.spacingXxs),
              // 短描述 (caption) — 走公共 scaleShortDescL10n helper
              Text(
                scaleShortDescL10n(scale.id, l10n),
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
