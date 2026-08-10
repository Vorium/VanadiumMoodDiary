// v0.30 round 87 (sub-spec 3 mood 列表页): mood list 路由
//
// 拆 app_routes.dart 14 路由按 feature 5 文件, R87 新增 mood list feature
// 文件 (6 个 feature file): 本文件管 mood list 完整列表页 (1 个 GoRoute)。
//
// 跟 assessment (slide-right) / vent (slide-up) 区别: mood list 是从主页
// 跳的次要查看页, 跟 trend 同 occasional 频度, 用 slide-right + fade。
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/routing/app_routes.dart';
import 'package:chroniccare/presentation/pages/mood_list/mood_list_page.dart';
import 'package:chroniccare/presentation/pages/mood_list/mood_trend_page.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/mood_recorder_page.dart';

/// v0.30 round 87: mood list 路由 (1 个 slide-right 子页)
class AppRouteMoodList {
  AppRouteMoodList._();

  static List<RouteBase> all() {
    return [
      // /mood-list: 完整 mood entry 列表 + search + filter (date/score/CBT) + sort
      // 从主页次要操作行 "📋 Mood 历史" 入口跳入 (occasional 频度, slide-right)
      GoRoute(
        path: '/mood-list',
        pageBuilder: (context, state) => AppRoutes.slideRightPage(
          state.pageKey,
          const MoodListPage(),
          context,
        ),
      ),
      // /mood-trend: 情绪趋势图 (周/月折线 + 分布直方图)
      GoRoute(
        path: '/mood-trend',
        pageBuilder: (context, state) => AppRoutes.slideRightPage(
          state.pageKey,
          const MoodTrendPage(),
          context,
        ),
      ),
      // R104: /mood/create — 新建情绪日记 (MoodRecorderPage 作为页面)
      GoRoute(
        path: '/mood/create',
        pageBuilder: (context, state) => AppRoutes.slideUpPage(
          state.pageKey,
          const MoodRecorderPage(),
          context,
        ),
      ),
    ];
  }
}
