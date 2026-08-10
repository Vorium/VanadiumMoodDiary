// v0.30 round 91 (sub-spec 7 日常追踪): 日常追踪路由
//
// 拆 app_routes.dart 路由按 feature 文件, R91 新增 daily_tracking feature
// 文件 (7 个 feature file): 本文件管日常追踪整套路由 (8 个 GoRoute)。
//
// 8 个路由:
// - /daily-tracking: 整合入口页 (Task 5)
// - /mood-diary: 情绪日记子页 (Task 5 兜底, 复用 mood_list_page)
// - /sleep: 睡眠子页 (Task 5 兜底, 包 SleepListWidget)
// - /social-rhythm: 社会节律子页
// - /stress-events: 应激源子页
// - /weight: 体重子页
// - /anxiety-agitation: 焦虑急躁子页
// - /treatment: 治疗子页 (Task 5 兜底, TreatmentPlaceholderPage)
//
// 频度 (emil 决策框架):
// - /daily-tracking: occasional (从主页 FAB 跳), slide-right
// - 7 子功能: occasional (从整合入口页跳), slide-right
// - 跟 assessment (slide-right) / mood_list (slide-right) 同频度
//
// v0.30 R91 Fix Round 1 (I-2): 7 子页面 AppBar title 走 l10n (子 widget
// 自己用 PageScaffold 包, 跟 R87 MoodListPage pattern 一致), 路由 file
// 不再包 PageScaffold wrapper (避免硬编码中文 title).
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/routing/app_routes.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/daily_tracking_page.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/tracking_customize_page.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/treatment_page.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/anxiety_agitation_widgets.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/sleep_widgets.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/social_rhythm_widgets.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/stress_event_widgets.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/weight_widgets.dart';
import 'package:chroniccare/presentation/pages/mood_list/mood_list_page.dart';

/// v0.30 round 91: 日常追踪路由 (8 个 slide-right 子页)
class AppRouteDailyTracking {
  AppRouteDailyTracking._();

  static List<RouteBase> all() {
    return [
      // 整合入口页 (主页 FAB 跳, occasional)
      GoRoute(
        path: '/daily-tracking',
        pageBuilder: (context, state) => AppRoutes.slideRightPage(
          state.pageKey,
          const DailyTrackingPage(),
          context,
        ),
      ),
      // 7 子功能路由 (整合页 7 卡片 tap 跳, occasional, 全部 slide-right)
      // 4 层架构: presentation/pages/daily_tracking/widgets/, 0 跨 feature。
      // AppBar title 走 l10n, 由子 widget 自己 PageScaffold 包 (R87 pattern)。
      GoRoute(
        path: '/mood-diary',
        pageBuilder: (context, state) => AppRoutes.slideRightPage(
          state.pageKey,
          const MoodListPage(),
          context,
        ),
      ),
      GoRoute(
        path: '/sleep',
        pageBuilder: (context, state) => AppRoutes.slideRightPage(
          state.pageKey,
          const SleepListWidget(),
          context,
        ),
      ),
      GoRoute(
        path: '/social-rhythm',
        pageBuilder: (context, state) => AppRoutes.slideRightPage(
          state.pageKey,
          const SocialRhythmListWidget(),
          context,
        ),
      ),
      GoRoute(
        path: '/stress-events',
        pageBuilder: (context, state) => AppRoutes.slideRightPage(
          state.pageKey,
          const StressEventListWidget(),
          context,
        ),
      ),
      GoRoute(
        path: '/weight',
        pageBuilder: (context, state) => AppRoutes.slideRightPage(
          state.pageKey,
          const WeightListWidget(),
          context,
        ),
      ),
      GoRoute(
        path: '/anxiety-agitation',
        pageBuilder: (context, state) => AppRoutes.slideRightPage(
          state.pageKey,
          const AnxietyAgitationListWidget(),
          context,
        ),
      ),
      GoRoute(
        path: '/treatment',
        pageBuilder: (context, state) => AppRoutes.slideRightPage(
          state.pageKey,
          const TreatmentPage(),
          context,
        ),
      ),
      // 自定义追踪项页 (排序/隐藏/收藏)
      GoRoute(
        path: '/daily-tracking/customize',
        pageBuilder: (context, state) => AppRoutes.slideRightPage(
          state.pageKey,
          const TrackingCustomizePage(),
          context,
        ),
      ),
    ];
  }
}
