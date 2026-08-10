// v0.26 round 57 (spen P1 #4 god class 拆分): 用药 + 提醒路由
//
// 拆 app_routes.dart 14 路由按 feature 5 文件, 本文件管用药类:
// v0.30 R101: 新增 /medication (用药主页) + /medication/add (添加向导)
//   + /medication/detail/:id (药物详情)
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/routing/app_routes.dart';
import 'package:chroniccare/presentation/pages/medication/add_medication_page.dart';
import 'package:chroniccare/presentation/pages/medication/medication_calendar_page.dart';
import 'package:chroniccare/presentation/pages/medication/medication_detail_page.dart';
import 'package:chroniccare/presentation/pages/medication/medication_page.dart';
import 'package:chroniccare/presentation/pages/medication/refill_manage_page.dart';
import 'package:chroniccare/presentation/pages/settings/legal_page.dart';
import 'package:chroniccare/presentation/pages/settings/reminders_hub_page.dart';

/// v0.26 round 57: 用药 + 提醒 + 法律路由 (7 个, R101 新增 3 个)
class AppRouteMedication {
  AppRouteMedication._();

  static List<RouteBase> all() {
    return [
      // v0.14 (Round 12C) 提醒中心
      GoRoute(
        path: '/settings/reminders',
        pageBuilder: (context, state) => AppRoutes.slideRightPage(
          state.pageKey,
          const RemindersHubPage(),
          context,
        ),
      ),
      // v0.14 (Round 13A) 续方管理
      GoRoute(
        path: '/settings/refills',
        pageBuilder: (context, state) => AppRoutes.slideRightPage(
          state.pageKey,
          const RefillManagePage(),
          context,
        ),
      ),
      // v0.21 Round 22 (P0-2): 法律与隐私页
      GoRoute(
        path: '/settings/legal',
        pageBuilder: (context, state) => AppRoutes.slideRightPage(
          state.pageKey,
          const LegalPage(),
          context,
        ),
      ),
      // v0.14 (Round 13C) 用药日历 (医生视角热力图)
      GoRoute(
        path: '/medication/calendar',
        pageBuilder: (context, state) => AppRoutes.slideRightPage(
          state.pageKey,
          const MedicationCalendarPage(),
          context,
        ),
      ),
      // v0.30 R101: 用药主页
      GoRoute(
        path: '/medication',
        pageBuilder: (context, state) => AppRoutes.fadePage(
          state.pageKey,
          const MedicationPage(),
          context,
        ),
      ),
      // v0.30 R101: 添加药物向导
      GoRoute(
        path: '/medication/add',
        pageBuilder: (context, state) => AppRoutes.slideUpPage(
          state.pageKey,
          const AddMedicationPage(),
          context,
        ),
      ),
      // v0.30 R101: 药物详情
      GoRoute(
        path: '/medication/detail/:id',
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return AppRoutes.slideRightPage(
            state.pageKey,
            MedicationDetailPage(medicationId: id),
            context,
          );
        },
      ),
    ];
  }
}
