// v1.1.0 论文落地 (F3 心理技巧知识库): 心理技巧路由
//
// /tips (列表) + /tips/:id (详情) 2 个 GoRoute。
// 从 settings ProfileGroup 心理技巧入口跳入 (occasional 频度, slide-right)。
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/routing/app_routes.dart';
import 'package:chroniccare/presentation/pages/tips/tips_detail_page.dart';
import 'package:chroniccare/presentation/pages/tips/tips_list_page.dart';

/// 心理技巧路由 (2 个 slide-right 子页)
class AppRouteTips {
  AppRouteTips._();

  static List<RouteBase> all() {
    return [
      GoRoute(
        path: '/tips',
        pageBuilder: (context, state) => AppRoutes.slideRightPage(
          state.pageKey,
          const TipsListPage(),
          context,
        ),
      ),
      GoRoute(
        path: '/tips/:id',
        pageBuilder: (context, state) => AppRoutes.slideRightPage(
          state.pageKey,
          TipsDetailPage(tipId: state.pathParameters['id'] ?? ''),
          context,
        ),
      ),
    ];
  }
}
