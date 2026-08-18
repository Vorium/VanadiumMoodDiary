// setup_step_done.dart — 首次设置 Step 3: 完成
//
// 从 setup_page.dart 拆分，v0.19 (Q2)
//
// v0.31 round 10 (Apple Health redesign · Phase 3 Task 3.2):
// 改 Apple 引导流程 (spec §5.2):
// - 顶部 SetupStepHeader 大标题 28pt + 副标题 15pt
// - 64pt systemGreen check icon
// - 底部 PrimaryButton full width → context.go('/')
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/setup/setup_widgets.dart';
import 'package:chroniccare/presentation/widgets/primary_button.dart';

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
          // v0.31 round 10: 64pt systemGreen 大对勾 (iOS checkmark.circle.fill)
          Center(
            child: Icon(
              Icons.check_circle,
              // v0.31 round 10: 64pt 巨对勾 (Apple Health 完成态)
              size: 64,
              color: AppTokens.primaryColor(context),
            ),
          ),
          const SizedBox(height: AppTokens.spacingLg),
          // v0.31 round 10: 大字 "已就绪" (走 SetupStepHeader 28pt)
          SetupStepHeader(
            title: l10n.setupDoneTitle,
            subtitle: l10n.setupDoneSubtitle,
          ),
          const SizedBox(height: AppTokens.spacingXl),
          // v0.31 round 10: 每日提醒 / 隐私 section
          // 走 ALL CAPS section header (用 SectionHeader) 紧跟在 SetupStepHeader 下方
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.pageMarginH,
            ),
            child: Text(
              l10n.setupDailyRoutine,
              style: const TextStyle(
                fontSize: AppTokens.fontSizeBody,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.pageMarginH,
            ),
            child: Text(l10n.setupReminder1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.pageMarginH,
            ),
            child: Text(l10n.setupReminder2),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.pageMarginH,
            ),
            child: Text(l10n.setupReminder3),
          ),
          const SizedBox(height: AppTokens.spacingXl),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.pageMarginH,
            ),
            child: Text(
              l10n.setupPrivacy,
              style: const TextStyle(
                fontSize: AppTokens.fontSizeBody,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.pageMarginH,
            ),
            child: Text(l10n.setupPrivacy1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.pageMarginH,
            ),
            child: Text(l10n.setupPrivacy2),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.pageMarginH,
            ),
            child: Text(l10n.setupPrivacy3),
          ),
          const SizedBox(height: AppTokens.spacingXl),
          // v0.31 round 10: 底部 PrimaryButton full width → context.go('/')
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.pageMarginH,
            ),
            child: PrimaryButton(
              isFullWidth: true,
              onPressed: () => context.go('/'),
              child: Text(l10n.setupStart),
            ),
          ),
          const SizedBox(height: AppTokens.spacingLg),
        ],
      ),
    );
  }
}
