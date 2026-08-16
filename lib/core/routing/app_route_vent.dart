// v0.26 round 57 (spen P1 #4 god class 拆分): 树洞路由
//
// 拆 app_routes.dart 14 路由按 feature 5 文件, 本文件管树洞类:
// 隐私边界: vent 路由仅作导航入口, 不引入任何分析/通知/关怀依赖。
//
// 1.1.0 round 5 (emotion-first refactor): R110 同款 — 树洞 3 路由移进
// ShellRoute (app_route_main), 底栏常驻 + tab 高亮。
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/routing/app_routes.dart';
import 'package:chroniccare/presentation/pages/vent/vent_compose_page.dart';
import 'package:chroniccare/presentation/pages/vent/vent_detail_page.dart';
import 'package:chroniccare/presentation/pages/vent/vent_list_page.dart';

/// v0.26 round 57: 树洞路由 (3 个 — 根 fade / compose+detail slide-up 全屏深页)
class AppRouteVent {
  AppRouteVent._();

  /// 1.1.0 round 5: 树洞 3 路由移进 ShellRoute (底栏常驻 + tab 高亮)
  ///
  /// R114 Wave B2 (B2-1, emil F1): /vent 根路由改 fadePage — 4 个 shell
  /// tab 是同一动作 (tens/day), 修前 /vent 用 slideUpPage 400ms 全屏
  /// modal 感, 跟 / /settings 的 fade 不同体感。统一 fade; slideUpPage
  /// 只留给 push 子页 (compose / detail)。
  static List<RouteBase> shellRoutes() {
    return [
      GoRoute(
        path: '/vent',
        pageBuilder: (context, state) =>
            AppRoutes.fadePage(state.pageKey, const VentListPage(), context),
      ),
      GoRoute(
        path: '/vent/compose',
        pageBuilder: (context, state) => AppRoutes.slideUpPage(
          state.pageKey,
          const VentComposePage(),
          context,
        ),
      ),
      GoRoute(
        path: '/vent/detail/:id',
        pageBuilder: (context, state) => AppRoutes.slideUpPage(
          state.pageKey,
          VentDetailPage(
            // v0.16 round 19C fix: 用 tryParse 替代 parse, URL 是 '/abc' 时
            // 不会崩, 回退到 0 (找不到对应条目 → 详情页显示"找不到了")
            id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          ),
          context,
        ),
      ),
    ];
  }
}
