import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';

/// 主页鼓励文案（按 streak 动态切换）
///
/// v0.18 round 18 (P1-27): 从 home_page 抽出。
///
/// v0.18 round 14 (P1-8) fix: 100+/day 频度(用户每天看 N 次),无动画
/// (MotionScheme.none)。之前用 durNormal + scale/fade 过渡感觉"迟疑",
/// 像在"庆祝"打卡。改 100+/day 频度 → 直接切换无动画。
class EncouragementText extends StatelessWidget {
  final int streak;

  const EncouragementText({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.spacingSm),
      child: Text(
        _textFor(streak),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: AppTokens.fontSizeBody,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static String _textFor(int streak) {
    if (streak <= 0) return '今天重新开始，加油 🌱';
    if (streak == 1) return '第 1 天，迈出第一步 🌱';
    if (streak < 7) return '坚持 $streak 天，继续 🌿';
    if (streak < 30) return '已坚持 $streak 天，真棒 🌳';
    if (streak < 100) return '$streak 天连击，太厉害了 🌲';
    return '$streak 天--你已经是这个习惯的主人了 🏔️';
  }
}
