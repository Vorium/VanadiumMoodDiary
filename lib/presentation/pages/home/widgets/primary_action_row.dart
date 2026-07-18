import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/secondary_button.dart';
import 'package:chroniccare/presentation/pages/check_in/check_in_button.dart';

/// 主页主操作行:打卡按钮 + 临时吃药 + snooze 5min
///
/// v0.18 round 18 (P1-27): 从 home_page 抽出。
/// 之前是 build 内联 3 个按钮 + spacing,现在隔离样式。
class PrimaryActionRow extends StatelessWidget {
  final bool isChecked;
  final int streakDays;
  final bool isLoading;
  final VoidCallback onCheckIn;
  final VoidCallback onTempMed;
  final VoidCallback onSnooze;

  const PrimaryActionRow({
    super.key,
    required this.isChecked,
    required this.streakDays,
    required this.isLoading,
    required this.onCheckIn,
    required this.onTempMed,
    required this.onSnooze,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CheckInButton(
          isChecked: isChecked,
          streakDays: streakDays,
          isLoading: isLoading,
          onPressed: isLoading ? () {} : onCheckIn,
        ),
        const SizedBox(height: AppTokens.spacingMd),
        SecondaryButton(
          onPressed: onTempMed,
          child: Text(
            AppLocalizations.of(context).homeTempMed,
            style: const TextStyle(
              fontSize: AppTokens.fontSizeButton,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: AppTokens.spacingSm),
        SecondaryButton(
          onPressed: onSnooze,
          child: const Text(
            '⏰ 5 分钟后再提醒',
            style: TextStyle(
              fontSize: AppTokens.fontSizeButton,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
