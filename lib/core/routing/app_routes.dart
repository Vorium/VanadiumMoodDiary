// 规则 3 标记: error page 文案中文 fallback (l10n 优先) — v1.0+ i18n
// v0.26 round 57 (spen P1 #4 god class 拆分): AppRoutes 退化为 3 transition + errorBuilder
//
// 拆分前: app_routes.dart 280 行含 3 transition + 14 GoRoute + errorBuilder
// 拆分后:
//   - app_routes.dart (本文件, 115 行): 3 transition helper + errorBuilder + all() 委托
//   - app_route_main.dart       — /setup /crisis-hotline + ShellRoute (/, /settings)
//   - app_route_assessment.dart — shellRoutes: /trend; all(): /assessment-center,
//                                 /assessment (redirect), /assessment/history, /assessment/:id
//   - app_route_medication.dart — shellRoutes: 用药 4 路由; all(): 设置类子路由
//   - app_route_vent.dart       — shellRoutes: /vent /vent/compose /vent/detail/:id
//   - app_route_check_in.dart   — /check-in/medication/:id, /check-in/today
//
// v1.1.0 round 5: /vent /trend 入 ShellRoute (导航 4 tab 心情/树洞/趋势/设置),
// AppRouteVent 不再从 AppRoutes.all() 注册 (go_router duplicate path 会抛)。
//
// 进度延续 R59 (app_router 拆 2 文件) 的渐进 facade 模式:
//   R59: app_router 418 → 51 行 (-88%)
//   R57: 14 路由按 feature 拆 5 文件, subagent 加新 route 只碰 1 个 feature 文件
import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/routing/app_route_assessment.dart';
import 'package:chroniccare/core/routing/app_route_check_in.dart';
import 'package:chroniccare/core/routing/app_route_daily_tracking.dart';
import 'package:chroniccare/core/routing/app_route_main.dart';
import 'package:chroniccare/core/routing/app_route_medication.dart';
import 'package:chroniccare/core/routing/app_route_mood_list.dart';
import 'package:chroniccare/core/routing/app_route_tips.dart';
import 'package:chroniccare/core/routing/app_route_worry.dart';
import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

/// v0.26 round 57: 路由 facade — 3 transition helper + 14 route 委托 + errorBuilder
class AppRoutes {
  AppRoutes._();

  // ============== Page transition helpers (v0.17 round 2 / A2 emil 动效) ==============
  //
  // 频度决策 (emil 决策框架):
  // - 主导航 (/, /settings, /vent, /trend — 4 shell tab 根) → tens/day → 统一 fade
  //   (R114 Wave B2-1: 修前 /vent slide-up 400ms / /trend slide-right, 同动作 3 体感)
  // - 子页 (/assessment/*, /settings/reminders, /medication/*) → occasional → slide-from-right
  //   (iOS 平台走 CupertinoPageRoute 原生 swipe-back — R114 Wave B2-2)
  // - 全屏深页 (/setup, /vent/compose, /vent/detail, /crisis-hotline) → rare → slide-up
  //
  // v0.21 Round 22 (P1-13 修复): helper 接收 BuildContext 用于
  // 尊重 prefers-reduced-motion (Motion.duration 类)

  /// Fade 动画 (主导航偶尔切)
  static Page<T> fadePage<T>(LocalKey key, Widget child, BuildContext context) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: Motion.duration(context, AppTokens.durNormal),
      reverseTransitionDuration: Motion.duration(context, AppTokens.durFast),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    );
  }

  /// Slide-from-right + fade (子页 occasional)
  ///
  /// R114 Wave B2 (B2-2, apple F-05): iOS 平台改走 [_SwipeBackCupertinoPage]
  /// (CupertinoPageRoute) — 原生滑入 + 右滑返回手势 + 33% 视差, 修前
  /// CustomTransitionPage 无 interactive pop。其他平台保留 10% 微滑 +
  /// fade 自定义过渡。
  static Page<T> slideRightPage<T>(
    LocalKey key,
    Widget child,
    BuildContext context,
  ) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _SwipeBackCupertinoPage<T>(key: key, child: child);
    }
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: Motion.duration(context, AppTokens.durNormal),
      reverseTransitionDuration: Motion.duration(context, AppTokens.durFast),
      transitionsBuilder: (_, anim, __, child) {
        // 从右滑入 + 淡入 (emil: 标准的 Material 风格 push 动画)
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: anim, curve: AppTokens.curveStandard),
          ),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
    );
  }

  /// Slide-up + fade (全屏深页 rare)
  ///
  /// R114 Wave B2 (B2-2 裁决): 保持 CustomTransitionPage (各平台一致) —
  /// slide-up 语义 = 全屏 modal (/setup /crisis-hotline /vent/compose /
  /// /vent/detail), iOS 惯例 modal 无 swipe-back, 返回走 AppBar/按钮。
  static Page<T> slideUpPage<T>(
    LocalKey key,
    Widget child,
    BuildContext context,
  ) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: Motion.duration(context, AppTokens.durSlow),
      reverseTransitionDuration: Motion.duration(context, AppTokens.durNormal),
      transitionsBuilder: (_, anim, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: anim, curve: AppTokens.curveStandard),
          ),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
    );
  }

  // ============== 14 个 GoRoute 委托 (R57 拆 5 文件) ==============

  /// 14 个 app 路由 — 委托 5 个 AppRoute*.all()
  ///
  /// 注意: AppRouteMain.all() 已经包了 ShellRoute, 其他 4 个 AppRoute*.all()
  /// 返回的子路由列表嵌在 ShellRoute 内部。R57 重构: 维持原架构, ShellRoute
  /// 仍在 main 里, 其他 feature 文件只贡献子路由, 由 main 拼装。
  ///
  /// 实际做法: 5 个 feature all() 各自返回 1 个 GoRoute 列表, 拼到主列表里
  /// 即可。ShellRoute 包住主导航 + 5 个 feature 的子路由。
  ///
  /// 但当前架构 (R57 拆完) 维持 R59 的 ShellRoute 内部包所有子路由的做法 —
  /// 详见 app_route_main.dart, ShellRoute 里已经全包了。
  ///
  /// 这里保持最小改动: 14 个路由还是由 AppRoutes.all() 统一返回, 但内部
  /// 委托 5 个 AppRoute* 的子路由, 兼容现有 GoRouter 架构。
  static List<RouteBase> all() {
    return [
      ...AppRouteMain.all(),
      ...AppRouteAssessment.all(),
      ...AppRouteMedication.all(),
      // AppRouteVent 已并入 AppRouteMain 的 ShellRoute (1.1.0 round 5),
      // 不再重复注册 (go_router duplicate path 会抛)
      ...AppRouteCheckIn.all(),
      ...AppRouteMoodList.all(),
      ...AppRouteDailyTracking.all(),
      ...AppRouteTips.all(),
      ...AppRouteWorry.all(),
    ];
  }

  /// errorBuilder: 页面不存在时 fallback (v0.21 P2-2 fix 加 icon + hint + 引导按钮)
  ///
  /// emil UX 原则: error 出现 = 用户卡住, 必须给明确出口
  static Widget errorBuilder(BuildContext context, GoRouterState state) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: AppTokens.edgeInsetsMd,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.help_outline,
                size: AppTokens.iconSizeEmpty,
                color: AppTokens.textSecondaryColor(context),
              ),
              const SizedBox(height: AppTokens.spacingMd),
              Text(
                l10n?.errorPageNotFound(state.matchedLocation) ??
                    '页面不存在: ${state.matchedLocation}',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTokens.spacingSm),
              Text(
                l10n?.errorPageHint ?? '',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTokens.textSecondaryColor(context),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTokens.spacingMd),
              FilledButton.icon(
                onPressed: () => GoRouter.of(context).go('/'),
                icon: const Icon(Icons.home),
                label: Text(l10n?.errorPageBackHome ?? '返回首页'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// rule3-whitelist: 180, 196
//   R113 BUG A: 精确行号豁免 (修前文件头 i18n 标记整文件豁免)
//   新增 CJK 字面量需自带 i18n 标记或扩本清单 — 详见 scripts/check_strings_hardcoded.py

/// R114 Wave B2 (B2-2, apple F-05): iOS 原生 swipe-back Page
///
/// go_router 14.x 已移除 MaterialPage/CupertinoPage, 只剩
/// CustomTransitionPage (无 interactive pop)。本类返回 [_SwipeBackCupertinoRoute]
/// (Flutter 原生 CupertinoPageRoute 子类) — 自带 iOS 右滑返回手势 + 上一页
/// 33% 视差跟随 + 可打断过渡。时长走 Motion (navigator context 上读
/// MediaQuery.disableAnimations → reduce-motion 直跳终态, 跟 MaterialPageRoute
/// 从 navigator!.context 取 transitionDuration 同模式)。
///
/// 仅 slideRightPage 在 iOS 用; Android/web 保留 10% 微滑自定义过渡
/// (emil: 微妙滑入 > Material 默认 100%)。
class _SwipeBackCupertinoPage<T> extends Page<T> {
  const _SwipeBackCupertinoPage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    return _SwipeBackCupertinoRoute<T>(
      settings: this,
      builder: (_) => child,
    );
  }
}

/// CupertinoPageRoute 子类 — 时长走 Motion (250 进 / 200 出 +
/// reduce-motion 直跳), 其余行为 (swipe-back 手势 / 33% 视差) 与原生一致。
class _SwipeBackCupertinoRoute<T> extends CupertinoPageRoute<T> {
  _SwipeBackCupertinoRoute({required super.builder, super.settings});

  @override
  Duration get transitionDuration {
    final nav = navigator;
    if (nav == null) return super.transitionDuration;
    return Motion.duration(nav.context, AppTokens.durNormal);
  }

  @override
  Duration get reverseTransitionDuration {
    final nav = navigator;
    if (nav == null) return super.reverseTransitionDuration;
    return Motion.duration(nav.context, AppTokens.durFast);
  }
}
