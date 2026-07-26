// v0.25 round 59: AppRoutes 抽离 (app_router god class 拆分)
//
// 之前 app_router.dart 418 行含:
//   - 3 个 page transition helper (fade / slideRight / slideUp)
//   - 14 GoRoute 配置 (含 ShellRoute + redirect)
//   - error builder (页面不存在 fallback)
//   - AppShell 响应式 widget
//
// R59 拆 2 个独立文件, app_router.dart 退化为 routerProvider 入口:
//
//   - app_routes.dart  (本文件): 3 transition helper + 14 GoRoute + error builder
//   - app_shell.dart: AppShell + _NavDest
//
// 进度匹配 R53a (app_database 拆 7 DAO) + R57 (safety_watch 拆 3 sub)
// + R58 (medication_report 拆 3 纯函数类) 的渐进 facade 模式.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/assessment/assessment_history_page.dart';
import 'package:chroniccare/presentation/pages/assessment/assessment_page.dart';
import 'package:chroniccare/presentation/pages/home/home_page.dart';
import 'package:chroniccare/presentation/pages/medication/medication_calendar_page.dart';
import 'package:chroniccare/presentation/pages/medication/refill_manage_page.dart';
import 'package:chroniccare/presentation/pages/settings/reminders_hub_page.dart';
import 'package:chroniccare/presentation/pages/settings/settings_page.dart';
import 'package:chroniccare/presentation/pages/settings/legal_page.dart';
import 'package:chroniccare/presentation/pages/settings/email_preview.dart';
import 'package:chroniccare/presentation/pages/setup/setup_page.dart';
import 'package:chroniccare/presentation/pages/trend/trend_page.dart';
import 'package:chroniccare/presentation/pages/vent/vent_compose_page.dart';
import 'package:chroniccare/presentation/pages/vent/vent_detail_page.dart';
import 'package:chroniccare/presentation/pages/vent/vent_list_page.dart';
import 'package:chroniccare/core/routing/app_shell.dart';

/// v0.25 round 59 (spen P1 #12 god class 拆分续): 路由配置 + page 动画
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
  static Page<T> slideUpPage<T>(LocalKey key, Widget child, BuildContext context) {
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

  // ============== 14 个 GoRoute 列表 ==============

  /// 14 个 app 路由 (含 ShellRoute + redirect 逻辑)
  static List<RouteBase> all() {
    return [
      // 设置流程不进 shell (全屏引导) — rare 频度 → slide-up
      GoRoute(
        path: '/setup',
        pageBuilder: (context, state) =>
            slideUpPage(state.pageKey, const SetupPage(), context),
      ),
      // 整个 app shell: 宽屏带 NavigationRail, 窄屏纯 body
      ShellRoute(
        builder: (context, state, child) => AppShell(
          currentLocation: state.matchedLocation,
          child: child,
        ),
        routes: [
          // 主导航: occasional 频度 → fade
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                fadePage(state.pageKey, const HomePage(), context),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                fadePage(state.pageKey, const SettingsPage(), context),
          ),
          // 子页 (occasional → slide-from-right)
          GoRoute(
            path: '/email-preview',
            pageBuilder: (context, state) => slideRightPage(
                state.pageKey, const EmailPreviewPage(), context,),
          ),
          // v0.14 (Round 12C) 提醒中心
          GoRoute(
            path: '/settings/reminders',
            pageBuilder: (context, state) => slideRightPage(
                state.pageKey, const RemindersHubPage(), context,),
          ),
          // v0.14 (Round 13A) 续方管理
          GoRoute(
            path: '/settings/refills',
            pageBuilder: (context, state) => slideRightPage(
                state.pageKey, const RefillManagePage(), context,),
          ),
          // v0.21 Round 22 (P0-2): 法律与隐私页
          GoRoute(
            path: '/settings/legal',
            pageBuilder: (context, state) =>
                slideRightPage(state.pageKey, const LegalPage(), context),
          ),
          GoRoute(
            path: '/trend',
            pageBuilder: (context, state) =>
                slideRightPage(state.pageKey, const TrendPage(), context),
          ),
          GoRoute(
            path: '/assessment',
            redirect: (_, __) => '/assessment/phq9',
          ),
          // v0.14 (Round 13B) 评估历史独立页
          // ⚠️ 必须在 :id 之前声明, 否则 :id 会先匹配 (GoRouter 按声明顺序匹配)
          GoRoute(
            path: '/assessment/history',
            pageBuilder: (context, state) => slideRightPage(
                state.pageKey, const AssessmentHistoryPage(), context,),
          ),
          GoRoute(
            path: '/assessment/:id',
            pageBuilder: (context, state) => slideRightPage(
              state.pageKey,
              AssessmentPage(scaleId: state.pathParameters['id'] ?? 'phq9'),
              context,
            ),
          ),
          // v0.14 (Round 13C) 用药日历 (医生视角热力图)
          GoRoute(
            path: '/medication/calendar',
            pageBuilder: (context, state) => slideRightPage(
                state.pageKey, const MedicationCalendarPage(), context,),
          ),
          // ============== v0.15 (Round 18) 树洞 ==============
          // 全屏深页 (full-screen modal feel) — rare 频度 → slide-up
          GoRoute(
            path: '/vent',
            pageBuilder: (context, state) =>
                slideUpPage(state.pageKey, const VentListPage(), context),
          ),
          GoRoute(
            path: '/vent/compose',
            pageBuilder: (context, state) =>
                slideUpPage(state.pageKey, const VentComposePage(), context),
          ),
          GoRoute(
            path: '/vent/detail/:id',
            pageBuilder: (context, state) => slideUpPage(
              state.pageKey,
              VentDetailPage(
                // v0.16 round 19C fix: 用 tryParse 替代 parse, URL 是 '/abc' 时
                // 不会崩, 回退到 0 (找不到对应条目 → 详情页显示"找不到了")
                id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
              ),
              context,
            ),
          ),
          // ============== Round 5: Deep Linking 路由 ==============
          // 点 medication 通知 → 直接跳 home 并自动打卡该药
          // 不经过 3 步首页流程 (参考 HealthReminder)
          GoRoute(
            path: '/check-in/medication/:id',
            redirect: (_, state) {
              final medId = state.pathParameters['id'] ?? '0';
              return '/?medId=$medId&autofire=1';
            },
          ),
          // 点 default / soft 通知 → 跳 home
          GoRoute(
            path: '/check-in/today',
            redirect: (_, state) {
              final reason = state.uri.queryParameters['reason'];
              if (reason == 'safety') {
                return '/?reason=safety';
              }
              return '/';
            },
          ),
        ],
      ),
    ];
  }

  /// errorBuilder: 页面不存在时 fallback (v0.21 P2-2 fix 加 icon + hint + 引导按钮)
  ///
  /// emil UX 原则: error 出现 = 用户卡住, 必须给明确出口
  static Widget errorBuilder(BuildContext context, GoRouterState state) {
    final l10n =
        Localizations.of<AppLocalizations>(context, AppLocalizations);
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
