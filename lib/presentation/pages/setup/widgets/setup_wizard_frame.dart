// v0.32 R112 (AR-20 批2a): SetupWizardFrame — 4 步 wizard 壳
//
// 拆自 setup_page_state.dart build(): PopScope + PageScaffold +
// SetupProgressBar + PageTransitionSwitcher 壳 (~50L) 抽成公开 widget,
// state 只传 step + child。
//
// 历史 (原 setup_page_state.build 注释):
// - v0.22 round 29 (emil-38): 走 AppSnackBar.info 集中器
// - v0.31 round 10 (Apple Health redesign · Phase 3 Task 3.2): 顶部 4 段
//   hairline 进度条, currentStep 0-3 控制高亮 (R10 spec §5.2)
// - v0.23 round 40 (emil F5/F7 fix): PageTransitionSwitcher 集中器替代
//   inline AnimatedSwitcher + 自定义 transitionBuilder (40+ 行)
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/setup/setup_widgets.dart';
import 'package:chroniccare/presentation/widgets/animations/animations.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';

/// 4 步 wizard 壳: PopScope + 标题 + 进度条 + 步骤切换动画
///
/// 用法 (SetupPageState.build):
/// ```dart
/// return SetupWizardFrame(
///   step: _step,
///   child: _buildStep(),
/// );
/// ```
class SetupWizardFrame extends StatelessWidget {
  /// 当前步骤 (0-based): 0 consent / 1 welcome / 2 medication / 3 done
  final int step;

  /// 总步骤数 (固定 4)
  final int totalSteps;

  /// 当前步骤内容 (SetupStepConsent/Welcome/Medication/Done)
  final Widget child;

  const SetupWizardFrame({
    super.key,
    required this.step,
    this.totalSteps = 4,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: step != 0,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // v0.22 round 29 (emil-38): 走 AppSnackBar.info 集中器
        AppSnackBar.showInfo(
          context,
          AppLocalizations.of(context).setupConsentRequired,
        );
      },
      child: PageScaffold(
        title: AppLocalizations.of(context).setupStep(step + 1, totalSteps),
        // v0.31 round 10 (Apple Health redesign · Phase 3 Task 3.2):
        // 顶部 4 段 hairline 进度条, 走 currentStep 0-3 控制高亮
        // (R10 spec §5.2 "顶部: 进度条 1/4 (小 hairline)")
        appBarBottom: PreferredSize(
          preferredSize: const Size.fromHeight(
            12, // 4+3+4 (top padding + bar + bottom padding)
          ),
          child: SetupProgressBar(currentStep: step, totalSteps: totalSteps),
        ),
        // v0.23 round 40 (emil F5/F7 fix): 改用 PageTransitionSwitcher 集中器
        child: PageTransitionSwitcher(
          switchKey: step,
          duration: Motion.duration(context, MotionScheme.standard.duration),
          transitionBuilder: (child, anim) {
            return FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey<int>(step),
            child: child,
          ),
        ),
      ),
    );
  }
}
