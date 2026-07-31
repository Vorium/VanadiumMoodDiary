// v0.26 round 57 (spen P1 #4 god class 拆分): 心理评估路由
//
// 拆 app_routes.dart 14 路由按 feature 5 文件, 本文件管评估类:
//
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/routing/app_routes.dart';
import 'package:chroniccare/presentation/pages/assessment/assessment_history_page.dart';
import 'package:chroniccare/presentation/pages/assessment/assessment_page.dart';
import 'package:chroniccare/presentation/pages/trend/trend_page.dart';

/// v0.26 round 57: 评估 + 趋势路由 (3 个 + 1 个 redirect)
class AppRouteAssessment {
  AppRouteAssessment._();

  static List<RouteBase> all() {
    return [
      GoRoute(
        path: '/trend',
        pageBuilder: (context, state) =>
            AppRoutes.slideRightPage(state.pageKey, const TrendPage(), context),
      ),
      GoRoute(
        path: '/assessment',
        redirect: (_, __) => '/assessment/phq9',
      ),
      // v0.14 (Round 13B) 评估历史独立页
      // ⚠️ 必须在 :id 之前声明, 否则 :id 会先匹配 (GoRouter 按声明顺序匹配)
      GoRoute(
        path: '/assessment/history',
        pageBuilder: (context, state) => AppRoutes.slideRightPage(
          state.pageKey,
          const AssessmentHistoryPage(),
          context,
        ),
      ),
      GoRoute(
        path: '/assessment/:id',
        pageBuilder: (context, state) => AppRoutes.slideRightPage(
          state.pageKey,
          AssessmentPage(scaleId: state.pathParameters['id'] ?? 'phq9'),
          context,
        ),
      ),
    ];
  }
}
