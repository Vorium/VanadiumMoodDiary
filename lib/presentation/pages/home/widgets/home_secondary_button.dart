import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';

/// 主页辅助按钮（v0.9 重构：抽出共用 style）
///
/// 用途：临时吃药、记一下情绪等"次要操作"
/// 视觉：主色描边 + 圆角 + label 居中,跟主打卡按钮视觉区分但不抢眼
///
/// 之前 home_page、mood_quick_button、settings 等多处重复同样的
/// `OutlinedButton.styleFrom(side: ... foregroundColor: ... shape: ...)`。
class HomeSecondaryButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  const HomeSecondaryButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppTokens.buttonHeightSmall,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
          foregroundColor: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusButton),
          ),
        ),
        child: child,
      ),
    );
  }
}
