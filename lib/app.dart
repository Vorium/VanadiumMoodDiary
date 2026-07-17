import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/data/services/notification_navigation.dart';
import 'package:chroniccare/core/l10n/strings.dart';
import 'package:chroniccare/presentation/providers/data_providers.dart';
import 'package:chroniccare/core/routing/app_router.dart';
import 'package:chroniccare/core/theme/app_theme.dart';
import 'package:chroniccare/core/theme/theme_provider.dart';

/// App 根 Widget
class AppRoot extends ConsumerStatefulWidget {
  const AppRoot({super.key});

  @override
  ConsumerState<AppRoot> createState() => _AppRootState();
}

/// v0.17 round 4: 计算距离下一个 00:00:05 的 Duration
///
/// 加 5s buffer,避免跨 00:00:00 race(00:00:00 跟 23:59:59 算 streak 结果不同)。
/// 如果 now 已经在 00:00:00-00:00:05 区间内,用当天的 00:00:05(而不是下一天)。
/// 暴露成 top-level 函数(不是 _AppRootState 私有)让 test 能直接测。
@visibleForTesting
Duration nextMidnightRefresh(DateTime now) {
  final todayBufferEnd = DateTime(now.year, now.month, now.day, 0, 0, 5);
  if (now.isBefore(todayBufferEnd)) {
    // now 在 00:00:00 之前(不可能)或 00:00:00-00:00:04 之间
    return todayBufferEnd.difference(now);
  }
  // 否则下一天的 00:00:05
  final tomorrow = DateTime(now.year, now.month, now.day + 1, 0, 0, 5);
  return tomorrow.difference(now);
}

class _AppRootState extends ConsumerState<AppRoot> {
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    // v0.11 (Round 5): AppRoot 第一帧后绑定 GoRouter 到 NotificationNavigation
    // 让通知回调能用 router 跳页
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = ref.read(routerProvider);
      NotificationNavigation.bind(router);
    });
    // v0.17 round 4: 跨 midnight 自动 refresh streak
    // 不挂 timer → 跨过 23:59:59 streak 还在用"昨天"算的 (B8 fix 只防 build 内多次,
    // 跨 midnight 后新 build 会用 today 算,但 streak 数本身依赖 yesterday data)
    _scheduleMidnightRefresh();
  }

  /// 算离 midnight 还差多少,挂一次性 timer,到点 invalidate streakSummaryProvider
  /// 触发所有 watch streak 的 widget rebuild
  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final delay = nextMidnightRefresh(DateTime.now());
    _midnightTimer = Timer(delay, () {
      if (!mounted) return;
      // 触发所有 watch streakSummaryProvider 的 widget 重建
      ref.invalidate(streakSummaryProvider);
      // 递归挂下一天的
      _scheduleMidnightRefresh();
    });
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: Strings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
