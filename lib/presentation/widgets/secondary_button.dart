import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';

/// 通用次要按钮（v0.9 重构：抽出共用 widget）
///
/// 用途：临时吃药、记一下情绪等"次要操作"
/// 视觉：主色描边 + 圆角 + label 居中，跟主打卡按钮视觉区分但不抢眼
///
/// 之前 home_page、mood_quick_button、settings 等多处重复同样的
/// `OutlinedButton.styleFrom(side: ... foregroundColor: ... shape: ...)`。
///
/// v0.17 round 12: 从 presentation/pages/home/widgets/home_secondary_button.dart
/// 移到 presentation/widgets/,类名 HomeSecondaryButton → SecondaryButton
/// (实际是跨 feature 通用 widget,不是 home 专属)。
///
/// v0.17 round 14 (P1-2): 简化 — 不再 wrapper styleFrom,直接用 OutlinedButton。
/// 项目的 OutlinedButtonTheme (app_theme.dart:_outlinedButtonTheme) 已经设好
/// minimumSize / side / foregroundColor / shape / textStyle,跟之前的
/// manual styleFrom 完全一致。删除重复声明，避免 theme 改 style 后这边不同步。
///
/// v0.24 round 48 (emil P2-11): 加 isLoading prop
/// 之前 5+ 处手动 `OutlinedButton(onPressed: null, child: CircularProgressIndicator(strokeWidth: 2))`
/// 抽 SecondaryButton.isLoading 默认显示 spinner + 禁用按钮
class SecondaryButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool isLoading;

  const SecondaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // 视觉跟之前完全一样 (项目 OutlinedButtonTheme 提供 side/shape/textStyle)
    // v0.24 round 48 (emil P2-11): loading 模式 → 显示小 spinner + 禁用按钮
    if (isLoading) {
      return const OutlinedButton(
        onPressed: null, // 禁用
        child: SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTokens.primary,
          ),
        ),
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      child: child,
    );
  }
}
