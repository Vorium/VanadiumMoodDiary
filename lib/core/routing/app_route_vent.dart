// v0.26 round 57 (spen P1 #4 god class 拆分): 树洞路由
//
// 拆 app_routes.dart 14 路由按 feature 5 文件, 本文件管树洞类:
// 隐私边界: vent 路由仅作导航入口, 不引入任何分析/通知/关怀依赖。
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/routing/app_routes.dart';
import 'package:chroniccare/presentation/pages/vent/vent_compose_page.dart';
import 'package:chroniccare/presentation/pages/vent/vent_detail_page.dart';
import 'package:chroniccare/presentation/pages/vent/vent_list_page.dart';

/// v0.26 round 57: 树洞路由 (3 个, 全 slide-up 全屏深页)
class AppRouteVent {
  AppRouteVent._();

  static List<RouteBase> all() {
    return [
      GoRoute(
        path: '/vent',
        pageBuilder: (context, state) =>
            AppRoutes.slideUpPage(state.pageKey, const VentListPage(), context),
      ),
      GoRoute(
        path: '/vent/compose',
        pageBuilder: (context, state) => AppRoutes.slideUpPage(
            state.pageKey, const VentComposePage(), context,),
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
