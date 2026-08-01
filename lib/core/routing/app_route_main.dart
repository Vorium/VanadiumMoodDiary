// v0.26 round 57 (spen P1 #4 god class 拆分): 主导航路由
//
// 拆 app_routes.dart 14 路由按 feature 5 文件:
//   - app_route_main.dart       (本文件) — / setup / home / settings / 邮件预览
//   - app_route_assessment.dart — /assessment, /assessment/history, /assessment/:id
//   - app_route_medication.dart — /settings/reminders, /settings/refills, /medication/calendar
//   - app_route_vent.dart       — /vent, /vent/compose, /vent/detail/:id
//   - app_route_check_in.dart   — /check-in/medication/:id, /check-in/today
//
// 进度延续 R59 (app_router 拆 2 文件) 的渐进 facade 模式 — app_routes.dart
// 退化为 3 transition helper + errorBuilder, 14 路由按 feature 子文件分布。
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/routing/app_routes.dart';
import 'package:chroniccare/core/routing/app_shell.dart';
import 'package:chroniccare/presentation/pages/home/home_page.dart';
import 'package:chroniccare/presentation/pages/settings/email_preview.dart';
import 'package:chroniccare/presentation/pages/settings/settings_page.dart';
import 'package:chroniccare/presentation/pages/setup/setup_page.dart';

/// v0.26 round 57: 主导航 + 设置流程 + 邮件预览
class AppRouteMain {
  AppRouteMain._();

  /// 主导航路由 (3 类) + 顶层 /setup
  static List<RouteBase> all() {
    return [
      // 设置流程不进 shell (全屏引导) — rare 频度 → slide-up
      GoRoute(
        path: '/setup',
        pageBuilder: (context, state) =>
            AppRoutes.slideUpPage(state.pageKey, const SetupPage(), context),
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
                AppRoutes.fadePage(state.pageKey, const HomePage(), context),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => AppRoutes.fadePage(
                state.pageKey, const SettingsPage(), context,),
          ),
          // 子页 (occasional → slide-from-right)
          GoRoute(
            path: '/email-preview',
            pageBuilder: (context, state) => AppRoutes.slideRightPage(
              state.pageKey,
              const EmailPreviewPage(),
              context,
            ),
          ),
        ],
      ),
    ];
  }
}
