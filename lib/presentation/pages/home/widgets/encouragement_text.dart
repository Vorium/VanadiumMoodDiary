import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

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
        _textFor(context, streak),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: AppTokens.fontSizeBody,
          color: AppTokens.textSecondaryColor(context),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static String _textFor(BuildContext context, int streak) {
    final l10n = AppLocalizations.of(context);
    if (streak <= 0) return l10n.homeStreakRestart;
    if (streak == 1) return l10n.homeStreakDay1;
    if (streak < 7) return l10n.homeStreakDays(streak);
    if (streak < 30) return l10n.homeStreakGreat(streak);
    if (streak < 100) return l10n.homeStreakAmazing(streak);
    return l10n.homeStreakMaster(streak);
  }
}
