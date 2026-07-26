// v0.25 round 59: app_router.dart 退化为 routerProvider 入口 (god class 拆分)
//
// 之前 app_router.dart 418 行含:
//   - 3 个 page transition helper
//   - 14 GoRoute 配置
//   - error builder
//   - AppShell 响应式 widget
//
// R59 拆 2 个独立文件:
//   - app_routes.dart: 3 transition helper + 14 GoRoute + error builder
//   - app_shell.dart: AppShell + _NavDest
//
// app_router.dart 退化为 ~40 行 routerProvider 入口, 协调 redirect +
// AppRoutes.all() + AppRoutes.errorBuilder
//
// 架构说明: 此文件位于 core/routing/ 并 import 了 presentation/pages/,
// 这是 go_router 的固有限制 — 路由必须知道页面 widget 才能构建路由.
// 将其移至 presentation/ 会导致循环依赖 (presentation → core for theme/l10n,
// core → presentation for pages). 接受此 trade-off, 已在 AGENTS.md 架构检查中豁免.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/routing/app_routes.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';

/// v0.25 round 59 (spen P1 #12 god class 拆分续): go_router Provider 入口
///
/// 监听 userProfileProvider 判断是否已 setup:
/// - 未 setup → redirect 到 /setup
/// - 已 setup → 跳 /
final routerProvider = Provider<GoRouter>((ref) {
  // 监听用户档案, 判断是否已设置
  final profileAsync = ref.watch(userProfileProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      // v0.17 round 3: Riverpod 3.x 改名为 .value (之前 .valueOrNull)
      final profile = profileAsync.value;
      final isSetupDone = profile != null;
      final goingToSetup = state.matchedLocation == '/setup';

      if (!isSetupDone && !goingToSetup) return '/setup';
      if (isSetupDone && goingToSetup) return '/';
      return null;
    },
    routes: AppRoutes.all(),
    errorBuilder: AppRoutes.errorBuilder,
  );
});
