import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';
import 'package:chroniccare/presentation/widgets/secondary_button.dart';
import 'package:chroniccare/presentation/pages/check_in/check_in_button.dart';

/// 主页主操作行：打卡按钮 + 临时吃药 + snooze 5min
///
/// v0.18 round 18 (P1-27): 从 home_page 抽出。
/// 之前是 build 内联 3 个按钮 + spacing,现在隔离样式。
///
/// v0.21 Round 22 (P0-9): 3 个按钮外加 PressFeedback 包裹提供
/// scale 0.97 反馈。tens/day 频度,emil 决策框架"微弱反馈"档。
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
        // 打卡按钮: 100+/day,emil 决策"几乎无动画",但 PressFeedback 提供
        // 微弱 scale + InkWell ripple 仍是 tens 频度的必要反馈
        PressFeedback(
          onTap: isLoading ? null : onCheckIn,
          child: CheckInButton(
            isChecked: isChecked,
            streakDays: streakDays,
            isLoading: isLoading,
            onPressed: () {}, // PressFeedback 处理 tap
          ),
        ),
        const SizedBox(height: AppTokens.spacingMd),
        PressFeedback(
          onTap: onTempMed,
          child: SecondaryButton(
            onPressed: () {}, // PressFeedback 处理 tap
            child: Text(
              AppLocalizations.of(context).homeTempMed,
              style: const TextStyle(
                fontSize: AppTokens.fontSizeButton,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTokens.spacingSm),
        PressFeedback(
          onTap: onSnooze,
          child: SecondaryButton(
            onPressed: () {}, // PressFeedback 处理 tap
            child: Text(
              AppLocalizations.of(context).homeSnoozeButton,
              style: const TextStyle(
                fontSize: AppTokens.fontSizeButton,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
