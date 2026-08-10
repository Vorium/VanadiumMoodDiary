import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/press_feedback_icon_button.dart';

/// 通用页面骨架（响应式）
///
/// - 窄屏（< 840）：全宽 + pageMarginH/V
/// - 宽屏（>= 840）：内容居中，最大 720 宽，左右留白
/// - R104: 自动显示返回按钮（当有上一级路由时）
class PageScaffold extends StatelessWidget {
  final String? title;
  final Widget child;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final List<Widget>? actions;
  final PreferredSizeWidget? appBarBottom;
  final Widget? leading;
  final bool? automaticallyImplyLeading;

  const PageScaffold({
    super.key,
    this.title,
    required this.child,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.actions,
    this.appBarBottom,
    this.leading,
    this.automaticallyImplyLeading,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppTokens.breakpointExpanded;
        // R104: 自动判断是否显示返回按钮
        final canPop = GoRouter.of(context).canPop();
        final showLeading = leading ??
            (canPop
                ? PressFeedbackIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: AppLocalizations.of(context).commonBack,
                    onPressed: () => context.pop(),
                  )
                : null);
        return Scaffold(
          // 宽屏下不显示 AppBar（NavigationRail 在 AppShell 里负责导航）
          appBar: (title != null && !isWide)
              ? AppBar(
                  title: Text(title!),
                  actions: actions,
                  bottom: appBarBottom,
                  leading: showLeading,
                  automaticallyImplyLeading:
                      automaticallyImplyLeading ?? false,
                )
              : null,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      isWide ? AppTokens.contentMaxWidth : double.infinity,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        isWide ? AppTokens.spacingLg : AppTokens.pageMarginH,
                    vertical: AppTokens.pageMarginV,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
          floatingActionButton: floatingActionButton,
          bottomNavigationBar: bottomNavigationBar,
        );
      },
    );
  }
}
