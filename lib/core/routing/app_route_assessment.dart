// v0.26 round 57 (spen P1 #4 god class 拆分): 心理评估路由
//
// 拆 app_routes.dart 14 路由按 feature 5 文件, 本文件管评估类:
//
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/routing/app_routes.dart';
import 'package:chroniccare/presentation/pages/assessment/assessment_center_page.dart';
import 'package:chroniccare/presentation/pages/assessment/assessment_history_page.dart';
import 'package:chroniccare/presentation/pages/assessment/assessment_page.dart';
import 'package:chroniccare/presentation/pages/trend/trend_page.dart';

/// v0.26 round 57: 评估 + 趋势路由 (shell 1 个 + 3 个 + 1 个 redirect)
/// v0.30 round 90 (sub-spec 6 量表中心): 加 /assessment-center 中心化入口
/// v1.1.0 round 5: /trend 移入 shellRoutes() (导航 4 tab, 底栏常驻)
class AppRouteAssessment {
  AppRouteAssessment._();

  /// 趋势路由 (1.1.0 round 5 移进 ShellRoute, 底栏常驻 + tab 高亮)
  ///
  /// R114 Wave B2 (B2-1, emil F1): /trend 根路由改 fadePage — 4 个 shell
  /// tab 统一体感 (修前 slideRightPage); slideRightPage 只留给 push 子页
  /// (assessment-center / history / :id)。
  static List<RouteBase> shellRoutes() {
    return [
      GoRoute(
        path: '/trend',
        pageBuilder: (context, state) =>
            AppRoutes.fadePage(state.pageKey, const TrendPage(), context),
      ),
    ];
  }

  static List<RouteBase> all() {
    return [
      // v0.30 round 90: 12 量表中心化入口 (10 开放 + 2 TODO unavailable)
      // 跟 R60 /assessment/:id 单 scale 模式并存, 用户从 home/settings 进来选量表
      GoRoute(
        path: '/assessment-center',
        pageBuilder: (context, state) => AppRoutes.slideRightPage(
          state.pageKey,
          const AssessmentCenterPage(),
          context,
        ),
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
