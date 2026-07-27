// v0.26 round 57 (spen P1 #4 god class 拆分): 用药 + 提醒路由
//
// 拆 app_routes.dart 14 路由按 feature 5 文件, 本文件管用药类:
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/routing/app_routes.dart';
import 'package:chroniccare/presentation/pages/medication/medication_calendar_page.dart';
import 'package:chroniccare/presentation/pages/medication/refill_manage_page.dart';
import 'package:chroniccare/presentation/pages/settings/legal_page.dart';
import 'package:chroniccare/presentation/pages/settings/reminders_hub_page.dart';

/// v0.26 round 57: 用药 + 提醒 + 法律路由 (4 个)
class AppRouteMedication {
  AppRouteMedication._();

  static List<RouteBase> all() {
    return [
      // v0.14 (Round 12C) 提醒中心
      GoRoute(
        path: '/settings/reminders',
        pageBuilder: (context, state) => AppRoutes.slideRightPage(
            state.pageKey, const RemindersHubPage(), context,),
      ),
      // v0.14 (Round 13A) 续方管理
      GoRoute(
        path: '/settings/refills',
        pageBuilder: (context, state) => AppRoutes.slideRightPage(
            state.pageKey, const RefillManagePage(), context,),
      ),
      // v0.21 Round 22 (P0-2): 法律与隐私页
      GoRoute(
        path: '/settings/legal',
        pageBuilder: (context, state) => AppRoutes.slideRightPage(
            state.pageKey, const LegalPage(), context,),
      ),
      // v0.14 (Round 13C) 用药日历 (医生视角热力图)
      GoRoute(
        path: '/medication/calendar',
        pageBuilder: (context, state) => AppRoutes.slideRightPage(
            state.pageKey, const MedicationCalendarPage(), context,),
      ),
    ];
  }
}
