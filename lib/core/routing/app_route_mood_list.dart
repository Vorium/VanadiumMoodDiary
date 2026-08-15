// v0.30 round 87 (sub-spec 3 mood 列表页): mood list 路由
//
// 拆 app_routes.dart 14 路由按 feature 5 文件, R87 新增 mood list feature
// 文件 (6 个 feature file): 本文件管 mood list 完整列表页 (1 个 GoRoute)。
//
// 跟 assessment (slide-right) / vent (slide-up) 区别: mood list 是从主页
// 跳的次要查看页, 跟 trend 同 occasional 频度, 用 slide-right + fade。
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/routing/app_routes.dart';
import 'package:chroniccare/presentation/pages/mood_list/mood_detail_page.dart';
import 'package:chroniccare/presentation/pages/mood_list/mood_list_page.dart';
import 'package:chroniccare/presentation/pages/mood_list/mood_review_page.dart';
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
      // v0.32 round 8 (R112-02): /mood/detail/:id — 情绪详情 (列表条目点击进入,
      // occasional 频度, slide-right; R112 前 MoodDetailPage 是无路由死代码)
      GoRoute(
        path: '/mood/detail/:id',
        pageBuilder: (context, state) => AppRoutes.slideRightPage(
          state.pageKey,
          MoodDetailPage(
            entryId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          ),
          context,
        ),
      ),
      // 1.1.0 round 5e (Task 15): /mood-review — 情绪回顾页 (周/月统计摘要)
      // 从首页情绪大卡 review 按钮跳入 (occasional, slide-right),
      // top-level (不进 ShellRoute — 心情 tab 回落由 TabBar 默认选中兜底)
      GoRoute(
        path: '/mood-review',
        pageBuilder: (context, state) => AppRoutes.slideRightPage(
          state.pageKey,
          const MoodReviewPage(),
          context,
        ),
      ),
    ];
  }
}
