// v1.1.0 论文落地 (F1 烦恼闭环): worry 路由
//
// - /worry/:id: 烦恼时间线 (从情绪列表烦恼 section / 忆往昔 进入)
// - /worry/archive: 忆往昔 (已放下烦恼收藏)
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/routing/app_routes.dart';
import 'package:chroniccare/presentation/pages/worry/worry_archive_page.dart';
import 'package:chroniccare/presentation/pages/worry/worry_timeline_page.dart';

class AppRouteWorry {
  AppRouteWorry._();

  static List<RouteBase> all() {
    return [
      // R113 bug fix (BUG 1): 字面量路由必须排在参数路由之前 —
      // go_router first-match-wins, /worry/archive 若排在后会被 /worry/:id
      // 吞成 id='archive' → int.tryParse ?? 0 → WorryTimelinePage(threadId: 0)
      // 永远转圈 ("忆往昔"入口假死)。
      GoRoute(
        path: '/worry/archive',
        pageBuilder: (context, state) => AppRoutes.slideRightPage(
          state.pageKey,
          const WorryArchivePage(),
          context,
        ),
      ),
      GoRoute(
        path: '/worry/:id',
        pageBuilder: (context, state) => AppRoutes.slideRightPage(
          state.pageKey,
          WorryTimelinePage(
            threadId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          ),
          context,
        ),
      ),
    ];
  }
}
