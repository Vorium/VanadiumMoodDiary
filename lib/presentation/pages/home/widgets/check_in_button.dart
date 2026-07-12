import 'package:flutter/material.dart';

import '../../../../theme/app_tokens.dart';

/// 主页大按钮：「我今天吃了药」
class CheckInButton extends StatelessWidget {
  final bool isChecked;
  final int streakDays;
  final VoidCallback onPressed;

  const CheckInButton({
    super.key,
    required this.isChecked,
    required this.streakDays,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppTokens.buttonHeight,
      child: ElevatedButton(
        onPressed: isChecked ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isChecked ? AppTokens.disabled : AppTokens.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusButton),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isChecked ? '今天已打卡 ✓' : '我今天吃了药',
              style: const TextStyle(
                fontSize: AppTokens.fontSizeButton,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '已坚持 $streakDays 天',
              style: TextStyle(
                fontSize: AppTokens.fontSizeLabel,
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
