// v0.26 round 57 (spen P1 #4 god class 拆分): 打卡 Deep Linking 路由
//
// 拆 app_routes.dart 14 路由按 feature 5 文件, 本文件管打卡 Deep Linking:
// 点 medication 通知 → 直接跳 home 并自动打卡该药
// 不经过 3 步首页流程 (参考 HealthReminder)
import 'package:go_router/go_router.dart';

/// v0.26 round 57: 打卡 Deep Linking 路由 (2 个 redirect)
class AppRouteCheckIn {
  AppRouteCheckIn._();

  static List<RouteBase> all() {
    return [
      // 点 medication 通知 → 直接跳 home 并自动打卡该药
      // 不经过 3 步首页流程 (参考 HealthReminder)
      GoRoute(
        path: '/check-in/medication/:id',
        redirect: (_, state) {
          final medId = state.pathParameters['id'] ?? '0';
          return '/?medId=$medId&autofire=1';
        },
      ),
      // 点 default / soft 通知 → 跳 home
      // 1.1.0 round 4b: reason=safety 分支随 safety-alert deep link 整摘
      GoRoute(
        path: '/check-in/today',
        redirect: (_, state) {
          return '/';
        },
      ),
    ];
  }
}
