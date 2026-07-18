import 'package:flutter/material.dart';

/// 通用次要按钮（v0.9 重构：抽出共用 widget）
///
/// 用途：临时吃药、记一下情绪等"次要操作"
/// 视觉：主色描边 + 圆角 + label 居中,跟主打卡按钮视觉区分但不抢眼
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
/// manual styleFrom 完全一致。删除重复声明,避免 theme 改 style 后这边不同步。
class SecondaryButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  const SecondaryButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // 视觉跟之前完全一样 (项目 OutlinedButtonTheme 提供 side/shape/textStyle)
    return OutlinedButton(
      onPressed: onPressed,
      child: child,
    );
  }
}
