import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/primary_button.dart';

/// v0.18 round 14 (P1-2): 通用空态 widget
///
/// 5+ 处页面（vent_list / assessment_history / medication_calendar /
/// report_history / contact_list 等）有重复的 "if (xxx.isEmpty) return
/// const Card(child: Padding(child: Text('还没有...')));" 模式。
/// 抽统一 EmptyState 统一风格（icon + title + subtitle + action）。
///
/// 用法:
/// ```dart
/// if (records.isEmpty) {
///   return EmptyState(
///     icon: Icons.history,
///     title: '还没有评估记录',
///     subtitle: '做一次评估开始追踪',
///     actionLabel: '开始评估',
///     onAction: () => context.push('/assessment/phq9'),
///   );
/// }
/// ```
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    // v0.18 (P1-5): 用 dynamic Color getter 替代硬编码 light 颜色,
    // dark mode 下视觉正确。代价:TextStyle 不能 const(theme-aware 必须 dynamic)。
    //
    // v0.30 R101: 增强视觉 (参照 Apple Health 空态插画):
    // - icon 外加渐变圆形背景
    // - 整体更柔和的视觉引导
    final primaryColor = AppTokens.primaryColor(context);
    return Center(
      child: Padding(
        padding: AppTokens.edgeInsetsXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 渐变圆形背景 + icon
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor.withValues(alpha: 0.08),
                    primaryColor.withValues(alpha: 0.02),
                  ],
                ),
              ),
              child: Icon(
                icon,
                size: AppTokens.iconSizeEmpty,
                color: primaryColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppTokens.spacingMd),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTokens.fontSizeHeadline,
                fontWeight: FontWeight.w500,
                color: AppTokens.textSecondaryColor(context),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppTokens.spacingSm),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTokens.fontSizeBody,
                  color: AppTokens.textHintColor(context),
                  height: AppTokens.lineHeightSnug,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppTokens.spacingLg),
              PrimaryButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
