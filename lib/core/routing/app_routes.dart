// v0.26 round 57 (spen P1 #4 god class 拆分): AppRoutes 退化为 3 transition + errorBuilder
//
// 拆分前: app_routes.dart 280 行含 3 transition + 14 GoRoute + errorBuilder
// 拆分后:
//   - app_routes.dart (本文件, 115 行): 3 transition helper + errorBuilder + all() 委托
//   - app_route_main.dart       — / setup / home / settings / 邮件预览
//   - app_route_assessment.dart — /trend, /assessment, /assessment/history, /assessment/:id
//   - app_route_medication.dart — /settings/reminders, /settings/refills, /settings/legal, /medication/calendar
//   - app_route_vent.dart       — /vent, /vent/compose, /vent/detail/:id
//   - app_route_check_in.dart   — /check-in/medication/:id, /check-in/today
//
// 进度延续 R59 (app_router 拆 2 文件) 的渐进 facade 模式:
//   R59: app_router 418 → 51 行 (-88%)
//   R57: 14 路由按 feature 拆 5 文件, subagent 加新 route 只碰 1 个 feature 文件
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/routing/app_route_assessment.dart';
import 'package:chroniccare/core/routing/app_route_check_in.dart';
import 'package:chroniccare/core/routing/app_route_main.dart';
import 'package:chroniccare/core/routing/app_route_medication.dart';
import 'package:chroniccare/core/routing/app_route_vent.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

/// v0.26 round 57: 路由 facade — 3 transition helper + 14 route 委托 + errorBuilder
class AppRoutes {
  AppRoutes._();

  // ============== Page transition helpers (v0.17 round 2 / A2 emil 动效) ==============
  //
  // 频度决策 (emil 决策框架):
  // - 主导航 (/, /settings) → 偶尔切 → 简单 fade
  // - 子页 (/trend, /assessment/*, /settings/reminders) → occasional → slide-from-right
  // - 全屏深页 (/setup, /vent/*) → rare → slide-up + fade (full-screen modal 感)
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
  static Page<T> slideRightPage<T>(
    LocalKey key,
    Widget child,
    BuildContext context,
  ) {
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
  static Page<T> slideUpPage<T>(
      LocalKey key, Widget child, BuildContext context) {
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
      ...AppRouteVent.all(),
      ...AppRouteCheckIn.all(),
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
          padding: const EdgeInsets.all(AppTokens.spacingMd),
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
