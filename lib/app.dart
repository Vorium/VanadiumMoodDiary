import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:chroniccare/core/data/services/assessment_reminder_service.dart';
import 'package:chroniccare/core/data/services/pii_safe_log.dart';
import 'package:chroniccare/core/routing/notification_navigation.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/data_providers.dart';
import 'package:chroniccare/core/routing/app_router.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/core/theme/app_theme.dart';
import 'package:chroniccare/core/theme/theme_provider.dart';
import 'package:chroniccare/presentation/widgets/last_startup_error_banner.dart';

/// App 根 Widget
class AppRoot extends ConsumerStatefulWidget {
  const AppRoot({super.key});

  @override
  ConsumerState<AppRoot> createState() => _AppRootState();
}

/// v0.17 round 4: 计算距离下一个 00:00:05 的 Duration
///
/// 加 5s buffer,避免跨 00:00:00 race(00:00:00 跟 23:59:59 算 streak 结果不同)。
/// 如果 now 已经在 00:00:00-00:00:05 区间内，用当天的 00:00:05(而不是下一天)。
/// 暴露成 top-level 函数(不是 _AppRootState 私有)让 test 能直接测。
@visibleForTesting
Duration nextMidnightRefresh(tz.TZDateTime now) {
  // v0.23 round 40 (sp-zh D-06 fix): 改用 tz.TZDateTime 替代 DateTime
  // 之前 `DateTime now` 用 device local, 但 DST 切换 (海外用户, 美国/欧洲) 时
  // "下一天 00:00:05" 可能跨过 DST 跳变点导致 0/负数 delay
  // 改 tz.TZDateTime 让 timezone 包处理 DST
  final todayBufferEnd = tz.TZDateTime(
    now.location,
    now.year,
    now.month,
    now.day,
    0,
    0,
    5,
  );
  if (now.isBefore(todayBufferEnd)) {
    return todayBufferEnd.difference(now);
  }
  final tomorrow = tz.TZDateTime(
    now.location,
    now.year,
    now.month,
    now.day + 1,
    0,
    0,
    5,
  );
  return tomorrow.difference(now);
}

/// v0.21 (P0-4 fix): 判断 `now` 跟 `lastCheck` 之间是否跨过至少一次 00:00:05。
///
/// **bug 现象**: 之前只有"app 一直前台"的 timer,无法覆盖:
/// 1. 用户后台挂着 → 系统时钟漂移 / 时区切换 / 系统时间被改 → timer 失效
/// 2. app 被杀后重启 → 第一次回前台时如果跨过 midnight, streak 不会自动刷新
/// 3. 飞国际航班 (UTC+8 → UTC-5) → 跨日 0 点被跳过
///
/// **修法**: app 每次回前台(resumed) + 首次 initState 时, 用本函数检查
/// "上次记录时间 跟 现在 是否跨过 00:00:05", 如果跨了 → invalidate streak
/// + reschedule 安全网 timer。
///
/// 暴露成 top-level 让 test 直接测,跟 [nextMidnightRefresh] 风格一致。
@visibleForTesting
bool crossedMidnightSince(DateTime lastCheck, DateTime now) {
  if (lastCheck.isAfter(now)) return true; // 系统时间被拨回
  // 跨过 0:00:05 的判定: 两次都在 00:00:05 之后 且 日期不一样
  final lastCutoff = DateTime(
    lastCheck.year,
    lastCheck.month,
    lastCheck.day,
    0,
    0,
    5,
  );
  final nowCutoff = DateTime(now.year, now.month, now.day, 0, 0, 5);
  // v0.22 round 29 (spen-bug-05): 删空 if 块 (注释与逻辑矛盾, 编译为 no-op)
  return nowCutoff.isAfter(lastCutoff);
}

class _AppRootState extends ConsumerState<AppRoot> with WidgetsBindingObserver {
  Timer? _midnightTimer;
  // v0.21 (P0-4 fix): 记录"上次检查时间", 用于 didChangeAppLifecycleState 检测跨日
  DateTime? _lastCheck;

  @override
  void initState() {
    super.initState();
    // v0.21 (P0-4 fix): 注册 WidgetsBindingObserver 监听 app 生命周期
    // 回前台时检查跨日 + invalidate streak
    WidgetsBinding.instance.addObserver(this);
    // v0.11 (Round 5): AppRoot 第一帧后绑定 GoRouter 到 NotificationNavigation
    // 让通知回调能用 router 跳页
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = ref.read(routerProvider);
      NotificationNavigation.bind(router);
    });
    // v0.21 (P2-3 fix): 把 AssessmentReminderService.onAppStart() 从 main.dart
    // 移到 AppRoot.initState 的 addPostFrameCallback。
    // 之前 main.dart 用 Future.delayed(100ms) 等待 DB ready — 100ms 是 magic
    // number, 弱机可能 100ms 内 DB 还没 ready。 改用 addPostFrameCallback
    // 保证 provider tree 跟 DB 都就绪后跑。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_runAssessmentReminderOnStart());
    });
    // v0.17 round 4: 跨 midnight 自动 refresh streak
    // 不挂 timer → 跨过 23:59:59 streak 还在用"昨天"算的 (B8 fix 只防 build 内多次,
    // 跨 midnight 后新 build 会用 today 算，但 streak 数本身依赖 yesterday data)
    _lastCheck = DateTime.now();
    _scheduleMidnightRefresh();
  }

  /// v0.21 (P2-3 fix): 跑 AssessmentReminderService.onAppStart() (app 启动时)
  ///
  /// 从 main.dart 的 _scheduleAssessmentReminderOnStart 迁过来。
  /// 之前用 Future.delayed(100ms) 等待 DB ready, 现在改用
  /// addPostFrameCallback 确定性等 widget tree 就绪。
  ///
  /// v0.23 round 38 (P0-4 fix): 复用 [checkInRepositoryProvider] 而不是
  /// `new CheckInRepositoryImpl(sharedDb)`,避免第 2 个 CheckInRepository
  /// 实例(每个实例会 subscribe drift stream,导致 stream 重复订阅内存漏)。
  Future<void> _runAssessmentReminderOnStart() async {
    try {
      final notificationService = ref.read(notificationServiceProvider);
      final service = AssessmentReminderService(
        checkInRepo: ref.read(checkInRepositoryProvider),
        notificationService: notificationService,
      );
      await service.onAppStart();
    } catch (e) {
      // swallow — 评估提醒失败不影响核心功能
      // v0.18 (P2-P0-3): global error handler 已捕获, 这里只 log
      // v0.23 round 38 (P1-11): 改用 piiSafeLog,不再 print
      piiSafeLog(
        'AppRoot._runAssessmentReminderOnStart',
        '⚠️ AssessmentReminder.onAppStart 失败: $e',
        error: e,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!mounted) return;
    // v0.21 (P0-4 fix): app 回前台时检查跨日
    // 覆盖: 1) 飞国际航班改时区  2) 系统时间被改  3) app 被杀后重启跨日
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      final last = _lastCheck;
      if (last != null && crossedMidnightSince(last, now)) {
        ref.invalidate(streakSummaryProvider);
        // v0.21 (P0-6 fix): 同时 tick 显式的"今天已变更" provider,
        // 让 medication_calendar_page 等 watch 它的 widget 也跨日 rebuild
        ref.read(dayChangeTickProvider.notifier).tick();
        // 跨日后重置 timer, 防止 timer 在错误时间触发
        _scheduleMidnightRefresh();
      }
      _lastCheck = now;
    }
  }

  /// 算离 midnight 还差多少，挂一次性 timer,到点 invalidate streakSummaryProvider
  /// 触发所有 watch streak 的 widget rebuild
  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    // v0.23 round 40 (sp-zh D-06 fix): 用 tz.local 替代 DateTime.now()
    // 海外用户 (美国/欧洲) 在 DST 跳变点 (春进秋退) 用 DateTime.now() 算
    // 下一天 00:00:05 会因为 DST 跳过 1 小时或重复 1 小时,delay 异常
    // tz.TZDateTime.now(tz.local) 走 timezone 包处理 DST
    final delay = nextMidnightRefresh(tz.TZDateTime.now(tz.local));
    _midnightTimer = Timer(delay, () {
      if (!mounted) return;
      // 触发所有 watch streakSummaryProvider 的 widget 重建
      ref.invalidate(streakSummaryProvider);
      // v0.21 (P0-6 fix): tick dayChangeTickProvider 通知所有 watch 它的 widget
      ref.read(dayChangeTickProvider.notifier).tick();
      // 递归挂下一天的
      _scheduleMidnightRefresh();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      // v0.21 Round 25 (P3-1): 主题切换淡入动画
      // Flutter 默认有 200ms 淡入,但部分场景不触发(例如冷启动 dark→light)
      // 显式声明 durNormal + curveDecelerate 让切换永远平滑
      themeAnimationDuration: AppTokens.durNormal,
      // v0.22 round 29 (emil-36): 改 curveStandard (easeOutCubic) 替代
      // curveDecelerate (easeOutQuart 偏慢, 主题切换显得迟疑)
      themeAnimationCurve: AppTokens.curveStandard,
      // v0.17 round 14 (P1-6): 接 flutter_localizations,
      // 让 presentation 文字走 AppLocalizations.of(context) 而不是 Strings.xxx
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      // v0.22 round 33 (sp-en P0): LastStartupErrorBanner
      // release 模式 runZonedGuarded 之前直接 swallow, 用户看不到任何信号。
      // 改: error 存 SharedPreferences, 下次启动 AppRoot 通过 builder 显示
      // 顶部 banner "上次启动出错，请截图反馈"。
      builder: (context, child) =>
          LastStartupErrorBanner(child: child ?? const SizedBox.shrink()),
    );
  }
}
