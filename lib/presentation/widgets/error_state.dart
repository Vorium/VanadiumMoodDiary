import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';

/// v0.22 round 29 (emil-44): 通用错误态 widget
///
/// 跟 EmptyState 对仗：之前 3+ 处页面 (assessment_history / vent_list /
/// vent_detail) 用 `Center(child: Text('加载失败: xxx'))` 一行字, 用户没重试入口
/// 也不知道发生了什么。抽 ErrorState 统一风格 (icon + title + detail + retry)。
///
/// 错误信息:
/// - title: 通用错误描述 (如 "加载失败")
/// - detail (Optional): 具体错误 (e.toString())
/// - onRetry (Optional): 重新加载按钮 (调 ref.invalidate 等)
///
/// 用法:
/// ```dart
/// error: (e, _) => ErrorState(
///   title: AppLocalizations.of(context).commonLoadFailed,
///   detail: e.toString(),
///   onRetry: () => ref.invalidate(ventEntriesProvider),
/// ),
/// ```
///
/// emil 原则: 错误态跟空态同等重要, 不能 "1 行 Text" 草草了事。
/// 精神心理患者遇错易焦虑, 给清晰反馈 + 重试入口能显著降低挫败感。
class ErrorState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? detail;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const ErrorState({
    super.key,
    this.icon = Icons.error_outline,
    required this.title,
    this.detail,
    this.onRetry,
    this.retryLabel,
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
              size: 56,
              // M3 colorScheme.error 自动适配 light/dark mode
              color: Theme.of(context).colorScheme.error,
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
            if (detail != null) ...[
              const SizedBox(height: AppTokens.spacingSm),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTokens.fontSizeBody,
                  color: AppTokens.textHintColor(context),
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppTokens.spacingLg),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(retryLabel ?? '重试'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
