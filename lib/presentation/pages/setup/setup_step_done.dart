// setup_step_done.dart — 首次设置 Step 3: 完成
//
// 从 setup_page.dart 拆分，v0.19 (Q2)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';

/// Step 3: 完成页
///
/// 纯展示 + 导航，无状态。
class SetupStepDone extends StatelessWidget {
  final VoidCallback onBack;

  const SetupStepDone({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      key: const ValueKey(3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppTokens.spacingXl),
          const Center(child: Text('🌱', style: TextStyle(fontSize: 64))),
          const SizedBox(height: AppTokens.spacingLg),
          Center(
            child: Text(
              l10n.setupDoneTitle,
              style: const TextStyle(
                fontSize: AppTokens.fontSizeTitle,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          Center(
            child: Text(
              l10n.setupDoneSubtitle,
              style: TextStyle(
                fontSize: AppTokens.fontSizeBody,
                color: AppTokens.textSecondaryColor(context),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spacingXl),
          Text(
            l10n.setupDailyRoutine,
            style: const TextStyle(
              fontSize: AppTokens.fontSizeBody,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          Text(l10n.setupReminder1),
          Text(l10n.setupReminder2),
          Text(l10n.setupReminder3),
          const SizedBox(height: AppTokens.spacingXl),
          Text(
            l10n.setupPrivacy,
            style: const TextStyle(
              fontSize: AppTokens.fontSizeBody,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          Text(l10n.setupPrivacy1),
          Text(l10n.setupPrivacy2),
          Text(l10n.setupPrivacy3),
          const SizedBox(height: AppTokens.spacingXl),
          Row(
            children: [
              TextButton(
                onPressed: onBack,
                child: Text(AppLocalizations.of(context).setupBack),
              ),
              const Spacer(),
              // v0.22 round 28 (emil-31): "开始" ElevatedButton 外包 PressFeedback
              PressFeedback(
                child: ElevatedButton(
                  onPressed: () => context.go('/'),
                  child: Text(l10n.setupStart),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
