// v0.30 round 90 (sub-spec 6 量表中心): 10 开放量表卡片 widget
//
// - 量表名 (大) + 短描述 (caption)
// - 上次得分 (大数字 + 严重度 badge)
// - 上次时间 ("3 天前")
// - "开始" 按钮 (CTA) → 跳 /assessment/:scaleId (R60 老路由)
//
// 复用 R60 AssessmentScale interface + scale.displayName / shortDescription.
// 风格跟 R60 assessment_history_list + R45 settings Card widget 同款.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/assessment_entry.dart';
import 'package:chroniccare/domain/logic/assessment_scale.dart';

/// 开放量表卡片 (10 张之一, 跳 R60 /assessment/:scaleId 答题页)
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
    return Card(
      child: InkWell(
        onTap: () => context.push('/assessment/${scale.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 量表名 (大) + 短描述 (caption)
              Text(
                scale.displayName,
                style: AppTokens.textStyleTitle(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppTokens.spacingXxs),
              Text(
                scale.shortDescription,
                style: AppTokens.textStyleCaption(context),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              // 上次得分 / fallback 文案
              if (latestEntry != null) ...[
                Text(
                  '${latestEntry!.score}',
                  style: AppTokens.textStyleHeadline(context),
                ),
                Text(
                  '上次 ${_formatTime(latestEntry!.timestamp)}',
                  style: AppTokens.textStyleCaption(context),
                ),
              ] else
                Text(
                  '尚未填写过', // Task 6 换 l10n.assessmentCenterNoData
                  style: AppTokens.textStyleCaption(context),
                ),
              const SizedBox(height: AppTokens.spacingXs),
              // CTA 按钮 (走 FilledButton.tonal, 跟 settings 按钮风格一致)
              FilledButton.tonal(
                onPressed: () => context.push('/assessment/${scale.id}'),
                child: const Text('开始评估'), // Task 6 换 l10n.assessmentCenterStartButton
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 相对时间显示 ("3 天前" / "5 小时前" / "刚刚")
  ///
  /// 跟 R60 mood_list "3 天前" 风格一致; 跨 midnight 自动 stale 但 Material
  /// build 内取 DateTime.now() 是常见模式, 不再单独监听时间 (跟 streak summary
  /// 一样, 跨日由 AppRoot midnight timer refresh 触发).
  String _formatTime(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inDays > 0) return '${diff.inDays} 天前';
    if (diff.inHours > 0) return '${diff.inHours} 小时前';
    return '刚刚';
  }
}
