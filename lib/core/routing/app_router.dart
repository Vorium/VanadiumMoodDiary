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
// v0.26 round 57 (spen P2 #8): routerProvider 性能修复
//   之前用 `ref.watch(userProfileProvider)`, profile 变化时整个 GoRouter
//   重建 — 14 GoRoute + ShellRoute 全部重新构造, 浪费 + 偶发 fling。
//   改法: `ref.read` + 内部 cache, profile 变化只 invalidate cache, GoRouter
//   实例不重建。redirect 回调里用 cache + 手动 listen (via ref.listen)。
//
// 架构说明: 此文件位于 core/routing/ 并 import 了 presentation/pages/,
// 这是 go_router 的固有限制 — 路由必须知道页面 widget 才能构建路由.
// 将其移至 presentation/ 会导致循环依赖 (presentation → core for theme/l10n,
// core → presentation for pages). 接受此 trade-off, 已在 AGENTS.md 架构检查中豁免.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/routing/app_routes.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';

/// v0.26 round 57 (spen P2 #8): go_router Provider 入口 — ref.read + cache
///
/// **性能修复**: 之前 `ref.watch(userProfileProvider)` 每次 profile 变化
/// 重建整个 GoRouter (含 14 GoRoute)。改用 `ref.read` 拿当前值, profile
/// 变化时用 `ref.listen` 仅 invalidate 内部 cache, GoRouter 实例复用。
///
/// **redirect 决策**: 内部存 `_isSetupDone` 缓存, redirect 回调读缓存。
/// 缓存由 ref.listen 在 profile 变化时更新。
final routerProvider = Provider<GoRouter>((ref) {
  // ref.read 拿初始值, 不 watch — 不再随 profile 变化重建 GoRouter
  final initialProfile = ref.read(userProfileProvider).value;
  final cache = _RouterProfileCache._(initialProfile != null);

  // 监听 profile 变化 → 仅更新 cache, GoRouter 不重建
  ref.listen(userProfileProvider, (_, next) {
    cache.isSetupDone = next.value != null;
  });

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isSetupDone = cache.isSetupDone;
      final goingToSetup = state.matchedLocation == '/setup';

      if (!isSetupDone && !goingToSetup) return '/setup';
      if (isSetupDone && goingToSetup) return '/';
      return null;
    },
    routes: AppRoutes.all(),
    errorBuilder: AppRoutes.errorBuilder,
  );
});

/// 内部 cache: 装当前 isSetupDone 状态 (避免 ref.watch 触发 GoRouter 重建)
///
/// **生命周期**: 由 routerProvider Provider 闭包持有, routerProvider dispose
/// 时 GC 自动回收。Ref.listen 也只随 routerProvider 存活, 不会 leak。
class _RouterProfileCache {
  bool isSetupDone;
  _RouterProfileCache._(this.isSetupDone);
}
