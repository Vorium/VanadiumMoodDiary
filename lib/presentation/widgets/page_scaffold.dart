import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';
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
        // v0.31 R32 (Apple Health spec §4.9): reduce-transparency 适配 —
        // 用户开 reduce-motion → 走 solid, 否则 translucent。
        // (Flutter 未暴露 iOS reduce-transparency 媒体查询, iOS 保持
        // translucent 跟 Apple Health 一致)
        //
        // v0.32 R112 round 8i (渲染专项): BackdropFilter blur(20) → solid
        // translucent — 修前内容每帧滚动都要重采样 AppBar 背景模糊
        // (Flutter 最贵滤镜之一), Android 中低端机滚动/转场持续掉帧。
        // 修后 surface @ alpha 0.97 (light) / 0.92 (dark) 实色半透明,
        // 视觉几乎无差 (内容只在 bar 下方 1-2px 露出), 零逐帧开销。
        // spec §4.9 已同步 (spec 决策 #7 translucent 从 blur 改为 solid
        // alpha, blur 待 v1.0+ 平台层 blur 方案再评估)。
        final translucentBar = AppBar(
          // P3-CLEAN-9: title 可为 null (窄屏无 title 页面走 appBar: null),
          // 但 translucentBar 无条件构建 — 修前 `Text(title!)` 漏传 title
          // 即 runtime null-check 崩溃。修后空 title 不渲染 title widget。
          title: title == null ? null : Text(title!),
          actions: actions,
          bottom: appBarBottom,
          leading: showLeading,
          automaticallyImplyLeading: automaticallyImplyLeading ?? false,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          elevation: 0,
          flexibleSpace: Container(
            color: Theme.of(context).colorScheme.surface.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.92
                      : 0.97,
                ),
          ),
        );
        return Scaffold(
          // R114 Wave B2 (B2-3, apple F-04): 修前宽屏 (>= 840) 一律不显示
          // AppBar — push 进去的顶层路由 (/tips/:id /worry/:id ...) 无任何
          // 返回入口。修后: 宽屏 + canPop (push 子页) 保留 AppBar (title +
          // 返回按钮); 宽屏 + 不可 pop (shell tab 根) 仍无 AppBar
          // (NavigationRail 在 AppShell 里负责导航)。
          appBar:
              (title != null && (!isWide || canPop)) ? translucentBar : null,
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
