import 'dart:ui' show ImageFilter;

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
/// - v0.31 round 11a (Apple Health redesign · R32 hotfix): AppBar 改 translucent
///   风格 (spec §4.9 决策 #7): BackdropFilter blur(20) + white@0.6 + dark@0.4
///   + reduce-transparency 适配 (用户开 reduce-transparency → 走 solid)
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
        // v0.32 R109 round 6 part 2: test 环境没用 MaterialApp.router 包装,
        //   GoRouter.of(context) 抛 "No GoRouter found in context".
        //   优雅降级: 拿不到 router 时 canPop = false (无返回按钮), widget test
        //   仍能 pump + 验证子 widget. 跟 R32 之前 hardcode 行为一致.
        final canPop = _canRouterPop(context);
        final showLeading = leading ??
            (canPop
                ? PressFeedbackIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: AppLocalizations.of(context).commonBack,
                    onPressed: () => context.pop(),
                  )
                : null);
        // v0.31 R32 (Apple Health spec §4.9): reduce-transparency 适配
        // 用户开 reduce-transparency 系统设置 → 走 solid, 否则 translucent
        final reduceTransparency = MediaQuery.disableAnimationsOf(context) ||
            (Theme.of(context).platform == TargetPlatform.iOS &&
                // iOS 风格 reduce-transparency 媒体查询
                // Flutter 暂未暴露, 走 fallback: 始终 translucent
                false);
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
                  // v0.31 R32 (Apple Health spec §4.9): translucent AppBar
                  // - surfaceTintColor: transparent (M3 默认 tint 关闭)
                  // - scrolledUnderElevation: 0 (滚动后不变 elevation)
                  // - flexibleSpace: BackdropFilter blur(20) + Container alpha
                  // - reduce-transparency: 退化到 solid
                  // R109 round 6 (v0.32.0+119): Flutter 3.44.9 linter 严格化,
                  //   ColorScheme 没 transparent getter (旧 SDK 宽松匹配), 改用
                  //   `Colors.transparent` (Material 标准 const Color).
                  //   行为 1:1 (都是完全透明的 Color(0x00000000)).
                  surfaceTintColor: Colors.transparent,
                  scrolledUnderElevation: 0,
                  elevation: 0,
                  flexibleSpace: reduceTransparency
                      ? null
                      : ClipRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withValues(
                                    alpha: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? 0.4
                                        : 0.6,
                                  ),
                            ),
                          ),
                        ),
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

  /// R109 round 6 part 2: 优雅降级, test 环境无 GoRouter 时返 false
  /// (无返回按钮), 不抛 "No GoRouter found in context".
  static bool _canRouterPop(BuildContext context) {
    try {
      return GoRouter.of(context).canPop();
    } on Object {
      return false;
    }
  }
}
