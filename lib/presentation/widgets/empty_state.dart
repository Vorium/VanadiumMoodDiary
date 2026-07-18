import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';

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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppTokens.textHint,
            ),
            const SizedBox(height: AppTokens.spacingMd),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppTokens.fontSizeHeadline,
                fontWeight: FontWeight.w500,
                color: AppTokens.textSecondary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppTokens.spacingSm),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: AppTokens.fontSizeBody,
                  color: AppTokens.textHint,
                  height: 1.4,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppTokens.spacingLg),
              ElevatedButton(
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
