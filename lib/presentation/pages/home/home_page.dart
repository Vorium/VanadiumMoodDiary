import 'package:chroniccare/presentation/providers/service_providers.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/data/services/safety_watch_service.dart';
import 'package:chroniccare/domain/usecases/fire_care_strategy.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/theme_toggle_button.dart';
import 'package:chroniccare/presentation/providers/care_strategy_providers.dart';
import 'package:chroniccare/presentation/providers/check_in_notifier.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/legal_consent_provider.dart';
import 'package:chroniccare/presentation/providers/notification_init_provider.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/widgets/feedback.dart' show Haptics;
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/animations/celebration_bounce.dart';
import 'package:chroniccare/presentation/pages/home/widgets/encouragement_text.dart';
import 'package:chroniccare/presentation/pages/home/widgets/hero_illustration.dart';
import 'package:chroniccare/presentation/pages/home/widgets/home_fab_toolbar.dart';
import 'package:chroniccare/presentation/pages/home/widgets/home_footer.dart';
import 'package:chroniccare/presentation/pages/home/widgets/quick_mood_carousel.dart';
import 'package:chroniccare/presentation/pages/home/widgets/home_header.dart';
import 'package:chroniccare/presentation/pages/home/widgets/notification_failure_banner.dart';
import 'package:chroniccare/presentation/pages/home/widgets/primary_action_row.dart';
import 'package:chroniccare/presentation/pages/home/widgets/secondary_action_row.dart';
import 'package:chroniccare/presentation/pages/medication/temp_medication_dialog.dart';
import 'package:chroniccare/presentation/pages/medication/today_med_schedule.dart';
import 'package:chroniccare/presentation/pages/mood/mood_dialog.dart';

/// 主页
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

/// v0.27 round 64 (L2 refactor): 3 bool flag → enum 状态机
///
/// 之前 3 个独立 bool (`_safetyCheckTriggered` / `_safetyRerunRequested` /
/// `_deepLinkHandled`) 理论 8 种组合,实际只有 5 种有意义,另 3 种是 race 风险
/// (e.g. `safetyRerunRequested` 但 safety check 没跑过 / `deepLinkHandled`
/// 但 rerun 已请求 — 两个独立 flag 没法表达这类不变量)。
///
/// 状态机 5 个 named state + 3 个 transition method:
/// - 有效 transition 走 enum 映射 (`switch` expression 强制穷举)
/// - 重复 trigger (e.g. `initial.onSafetyCheckCompleted().onSafetyCheckCompleted()`)
///   idempotent 静默 no-op
/// - 真 race (`onDeepLinkHandled` 和 `onRerunRequested` 互斥) 抛 `StateError`,
///   debug 时早发现 invariant 违反
enum HomeLifecycleState {
  /// 启动初始态, safety check 未触发
  initial,

  /// safety check 跑完, 无 deep link
  safetyCheckCompleted,

  /// deep link 已处理 (from app start, `medId` query param 路径)
  deepLinkHandled,

  /// 强制重跑 safety check (R62 P1-9 race guard,
  /// `reason=safety` query param 路径, Timer 后调 `_runSafetyCheck(force: true)`)
  safetyRerunRequested,

  /// safety check 跑完 + deep link 同时 fire (两路分支都完成)
  bothHandled;

  /// Transition: safety check ran (无论初次还是 force rerun)。
  ///
  /// 允许 from: `initial` (首次) / `deepLinkHandled` / `safetyRerunRequested` (Timer 触发)
  /// idempotent from: `safetyCheckCompleted` / `bothHandled` (重复调用静默 no-op)
  HomeLifecycleState onSafetyCheckCompleted() {
    return switch (this) {
      HomeLifecycleState.initial => HomeLifecycleState.safetyCheckCompleted,
      HomeLifecycleState.deepLinkHandled => HomeLifecycleState.bothHandled,
      HomeLifecycleState.safetyRerunRequested => HomeLifecycleState.bothHandled,
      // idempotent: 已经包含 safety check completed
      HomeLifecycleState.safetyCheckCompleted ||
      HomeLifecycleState.bothHandled =>
        this,
    };
  }

  /// Transition: deep link 带 `medId` 路径已处理。
  ///
  /// 允许 from: `initial` / `safetyCheckCompleted`
  /// idempotent from: `deepLinkHandled` / `bothHandled`
  /// RACE from: `safetyRerunRequested` (mutually exclusive — 同一 deep link
  /// 不会同时有 `medId` 和 `reason=safety`, 出现这种情况是 bug)
  HomeLifecycleState onDeepLinkHandled() {
    return switch (this) {
      HomeLifecycleState.initial => HomeLifecycleState.deepLinkHandled,
      HomeLifecycleState.safetyCheckCompleted => HomeLifecycleState.bothHandled,
      // idempotent
      HomeLifecycleState.deepLinkHandled ||
      HomeLifecycleState.bothHandled =>
        this,
      // race guard: 不变量 `_handleDeepLink` 一次只走 medId 或 reason=safety 一条
      HomeLifecycleState.safetyRerunRequested => throw StateError(
          'HomeLifecycleState invariant violated: '
          'onDeepLinkHandled() called from $this. '
          'Rerun already requested, deep link medId path is mutually exclusive.',
        ),
    };
  }

  /// Transition: deep link 带 `reason=safety` 路径已请求重跑。
  ///
  /// 允许 from: `initial` / `safetyCheckCompleted`
  /// idempotent from: `safetyRerunRequested` / `bothHandled`
  /// RACE from: `deepLinkHandled`
  HomeLifecycleState onRerunRequested() {
    return switch (this) {
      HomeLifecycleState.initial => HomeLifecycleState.safetyRerunRequested,
      HomeLifecycleState.safetyCheckCompleted =>
        HomeLifecycleState.safetyRerunRequested,
      // idempotent
      HomeLifecycleState.safetyRerunRequested ||
      HomeLifecycleState.bothHandled =>
        this,
      // race guard
      HomeLifecycleState.deepLinkHandled => throw StateError(
          'HomeLifecycleState invariant violated: '
          'onRerunRequested() called from $this. '
          'Deep link medId already handled, rerun path is mutually exclusive.',
        ),
    };
  }
}

class _HomePageState extends ConsumerState<HomePage> {
  /// v0.27 round 64 (L2 refactor): 3 bool → 1 enum 状态机
  ///
  /// 之前 3 个独立 bool (`_safetyCheckTriggered` / `_safetyRerunRequested` /
  /// `_deepLinkHandled`) 有 3 种 race-prone 组合:
  ///   1. `_safetyRerunRequested=true` 但 `_safetyCheckTriggered=false` (Timer 触发后却没基础 guard)
  ///   2. `_deepLinkHandled=true` 但 `_safetyCheckTriggered=false` (deep link 路径走时首次 safety 还没跑)
  ///   3. 全部 3 true (逻辑上死路径, 但 flag 组合上可达, 易误读)
  ///
  /// 现在 [HomeLifecycleState] 用 named state 表达 5 种合法组合, transition
  /// 走 enum method 集中, race 组合 (medId + rerun 互斥) 抛 StateError 早发现。
  /// 见 [HomeLifecycleState] 注释。
  HomeLifecycleState _lifecycle = HomeLifecycleState.initial;

  /// 庆祝 overlay 的 Timer (v0.27 round 62 P1-6 修)
  ///
  /// 之前用 `Future.delayed` 不可 cancel，widget dispose 后 fire 引起 race。
  /// 改 Timer 存字段 + dispose 时 `cancel()`。
  Timer? _celebrationTimer;

  /// Deep link race guard Timer (v0.27 round 63 P1-4 修)
  ///
  /// 之前 `_handleDeepLink` 用 `await Future<void>.delayed(...)`, dispose 后
  /// 回调 fire 触发 setState 撞 defunct widget。改 Timer + dispose cancel,
  /// 跟 `_celebrationTimer` 模式一致 (R62 P1-6 同样修)。
  Timer? _deepLinkRaceTimer;

  @override
  void initState() {
    super.initState();
    // v0.10 (Round 4): 首帧后跑一次 SafetyWatch.onAppStart
    // v0.17 round 14 (Bug-4): 用 unawaited 显式标记 fire-and-forget,
    // 之前 _runSafetyCheck() 在 void 上下文里被默默丢弃, linter 看不出
    // "哦这其实是 fire-and-forget" 的意图。unawaited 让代码自描述。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_runSafetyCheck());
    });
    // v0.11 (Round 5): 首帧后处理 deep link query param
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_handleDeepLink());
    });
  }

  @override
  void dispose() {
    // v0.27 round 62 (P1-6 修复): 取消庆祝 overlay 的 Timer,
    // 避免 widget 已 dispose 后回调 fire 触发 `entry.mounted` 检查
    // 已经无效, 进而打 "OverlayEntry removed too many times" 警告。
    _celebrationTimer?.cancel();
    _celebrationTimer = null;
    // v0.27 round 63 (P1-4 修复): 同款 cancel 模式应用到 deep link race guard,
    // 防止 widget dispose 后 race guard timer 仍 fire 调 _runSafetyCheck
    _deepLinkRaceTimer?.cancel();
    _deepLinkRaceTimer = null;
    super.dispose();
  }

  /// v0.11 (Round 5): 处理 ?medId=N&autofire=1
  ///
  /// 用户点 medication 通知 → 路由跳到 /check-in/medication/N
  /// → redirect 到 /?medId=N&autofire=1 → home_page 收到参数
  /// → 这里自动打卡 + 显示庆祝
  Future<void> _handleDeepLink() async {
    // v0.27 round 64: guard 改走 _lifecycle 状态机
    // bothHandled 也算"已处理"(_handleDeepLink 路径 + safety check 都完成)
    if (_lifecycle == HomeLifecycleState.deepLinkHandled ||
        _lifecycle == HomeLifecycleState.bothHandled) {
      return;
    }
    final medIdParam = GoRouterState.of(context).uri.queryParameters['medId'];
    final autofire =
        GoRouterState.of(context).uri.queryParameters['autofire'] == '1';
    if (medIdParam == null) {
      // 不是 deep link 跳来的，处理 safety reason
      final reason = GoRouterState.of(context).uri.queryParameters['reason'];
      if (reason == 'safety') {
        // 强制重跑一次 (从通知跳来的场景)
        // v0.14 fix: 用独立 flag,不受 _safetyCheckTriggered 影响
        // 旧实现 `!_safetyCheckTriggered` 在第一跑已起来后永远 false
        // v0.27 round 64: 改用 _lifecycle 状态机,onRerunRequested() 内部
        // 保证 safetyRerunRequested / bothHandled 重复请求 idempotent
        if (_lifecycle == HomeLifecycleState.safetyRerunRequested) {
          return; // 已请求过
        }
        _lifecycle = _lifecycle.onRerunRequested();
        // v0.27 round 63 (P1-4 修复): 用 Timer 替代 Future.delayed,
        // 跟 _celebrationTimer 模式一致。Future.delayed 不可 cancel, widget
        // dispose 后 fire 触发 _runSafetyCheck 撞 defunct widget。
        // 旧实现 round 62 P1-9 改用 token 命名但仍 Future.delayed, 半修。
        _deepLinkRaceTimer = Timer(
          AppTokens.kDeepLinkRaceGuard,
          () {
            // Timer 自身 cancel 已在 dispose 跑, 这里加 mounted 双重保险
            if (!mounted) return;
            unawaited(_runSafetyCheck(force: true));
          },
        );
      }
      return;
    }
    _lifecycle = _lifecycle.onDeepLinkHandled();
    final medId = int.tryParse(medIdParam);
    if (medId == null) return;

    if (autofire) {
      // 自动打卡该药
      await _autofireMedicationCheckIn(medId);
    } else {
      // 只显示该药的"该吃了"信息
      _showMedicationHint(medId);
    }
  }

  Future<void> _autofireMedicationCheckIn(int medId) async {
    try {
      await ref
          .read(checkInNotifierProvider.notifier)
          .checkIn(medicationId: medId);
      if (!mounted) return;
      // P0 fix: 复用 provider 树已缓存的药物数据，不再重复查库
      final meds = ref.read(medicationsProvider).value ?? [];
      final med = meds.where((m) => m.id == medId).firstOrNull;
      if (!mounted) return;
      final medName =
          med?.name ?? AppLocalizations.of(context).homeAutofireFallbackName;
      // v0.22 round 30 (emil P2-4): 走 Haptics.success 集中器
      // (打卡成功触感,emil 频度: tens/day)
      Haptics.success();
      _showCelebrationOverlay(
        context,
        AppLocalizations.of(context).homeAutofireCelebration(medName),
      );
      // 清除 query 防止刷新页面重复触发
      GoRouter.of(context).go('/');
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        action: AppLocalizations.of(context).snackbarActionAutoCheckin,
        error: e,
      );
    }
  }

  void _showMedicationHint(int medId) {
    AppSnackBar.showInfo(
      context,
      AppLocalizations.of(context).homeMedHint(medId),
    );
  }

  /// 调 SafetyWatch.onAppStart,按结果显示一次性 SnackBar
  ///
  /// [force] = true 时忽略 [_safetyCheckTriggered] 守卫(用于 deep link 重跑)
  Future<void> _runSafetyCheck({bool force = false}) async {
    // v0.27 round 64: guard 改走 _lifecycle 状态机
    // safetyCheckCompleted / bothHandled 都代表 safety check 已跑过, force=false
    // 时跳过。force=true (Timer 触发) 总是跑, 走 onSafetyCheckCompleted() 推进状态
    if (!force) {
      if (_lifecycle == HomeLifecycleState.safetyCheckCompleted ||
          _lifecycle == HomeLifecycleState.bothHandled) {
        return;
      }
    }
    _lifecycle = _lifecycle.onSafetyCheckCompleted();
    try {
      // v0.27 round 60 (P0-3 修正): 传 l10n, 通知 3 态分流 + UI 文案走 l10n
      final l10n = AppLocalizations.of(context);
      final result =
          await ref.read(safetyWatchServiceProvider).onAppStart(l10n: l10n);
      if (!mounted) return;
      if (result.kind == SafetyCheckKind.alerted) {
        // v0.21 Round 22 (P0-10 修复): 走 AppSnackBar.error 集中器
        // 失联告警重要,延长到 6s 保留给用户时间读完
        AppSnackBar.showError(
          context,
          action: '⚠️ ${result.displayMessage}',
          error: l10n.homeSafetyAlertSuffix,
        );
      }
    } catch (e, st) {
      swallowError(
        where: 'home_page._runSafetyCheck',
        error: e,
        stack: st,
        note: 'safety check failed — user may not be notified',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayAsync = ref.watch(todayCheckInProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final checkInState = ref.watch(checkInNotifierProvider);
    final isChecking = checkInState.isLoading;
    // P10 (B8) fix: streak 只算一次，所有 widget 看到同一个值
    final streakAsync = ref.watch(streakSummaryProvider);
    final streakSnapshot = streakAsync.maybeWhen(
      data: (s) => s,
      orElse: () =>
          const StreakSnapshot(streak: 0, shouldShowStreakBroken: false),
    );
    // P17 fix: 通知初始化失败时，在主页顶部显示一条提示
    final notifResult = ref.watch(notificationInitResultProvider);

    // 打卡失败时给用户一个反馈
    ref.listen<AsyncValue<void>>(checkInNotifierProvider, (prev, next) {
      if (next.hasError && context.mounted) {
        AppSnackBar.showError(
          context,
          action: AppLocalizations.of(context).snackbarActionCheckin,
          error: next.error,
        );
      }
    });

    final userName = userProfileAsync.maybeWhen(
      data: (profile) => profile?.userName ?? '',
      orElse: () => '',
    );
    final nextReminder = _nextReminderTime();

    return PageScaffold(
      title: AppLocalizations.of(context).appName,
      actions: const [ThemeToggleButton()],
      // v0.28 R81 (emil design-3): 浮动 FAB 工具栏
      // B 站"哗哩哗哩能量加油站" 4 工具入口, 收起 1 FAB / 展开 4 圆角按钮
      // (心情测试 / 心情树洞 / 紧急热线 / 回到顶端)
      // emil 频度: tens/day (toggle), standard animation OK
      floatingActionButton: const HomeFabToolbar(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // v0.18 (P1-27) fix: home_page god-page 拆 5 widget,build 主体减肥
          // 顶部 header
          HomeHeader(userName: userName),

          // v0.28 R81 (emil design-4): 主页 hero 插画 (B 站治愈系风格)
          // 蓝天 + 太阳 + 云 + 叶子, 4 元素 Stack, 静态 (rare 频度
          // 不动画, 避免频度问题)。140dp 高, 跟功能区视觉分层。
          const HomeHeroIllustration(),

          const SizedBox(height: AppTokens.spacingMd),

          // P17 fix: 通知失败 banner(一次性提示，可关闭)
          if (!notifResult.ok)
            NotificationFailureBanner(error: notifResult.error),

          const Spacer(flex: 1),

          // 鼓励文案(按 streak 动态切换)
          EncouragementText(streak: streakSnapshot.streak),

          const SizedBox(height: AppTokens.spacingMd),

          // v0.28 R81 (emil design-2): 主页快速记心情 carousel
          // B 站"哗哩哗哩能量加油站" 4 情绪横滑 风格, 1 tap 速记 score
          // (其他维度 energy/sleep/anxiety 留 null, 完整 4 维度走 MoodDialog)
          // carousel 默认居中"一般" (score 3), 4 档可见 + 1 档隐藏
          // emil 频度: occasional (跟 checkIn 同 primary action),
          // standard animation OK, PageView 横滑 200ms ease-out
          QuickMoodCarousel(
            onOpenFullDialog: () => MoodDialog.show(context, ref),
          ),

          const SizedBox(height: AppTokens.spacingSm),

          // 主操作行：打卡按钮 + 临时吃药 + snooze 5min
          todayAsync.when(
            data: (today) => PrimaryActionRow(
              isChecked: today != null,
              streakDays: streakSnapshot.streak,
              isLoading: isChecking,
              onCheckIn: () => _onCheckIn(streakSnapshot.streak),
              onTempMed: () => TempMedicationDialog.show(context, ref),
              onSnooze: _snooze5Min,
            ),
            loading: () => const PrimaryActionRow(
              isChecked: false,
              streakDays: 0,
              isLoading: true,
              onCheckIn: _noop,
              onTempMed: _noop,
              onSnooze: _noop,
            ),
            error: (_, __) => const PrimaryActionRow(
              isChecked: false,
              streakDays: 0,
              isLoading: false,
              onCheckIn: _noop,
              onTempMed: _noop,
              onSnooze: _noop,
            ),
          ),

          const SizedBox(height: AppTokens.spacingSm),

          // v0.14 (Round 17) 今日服药计划
          const TodayMedSchedule(),

          const SizedBox(height: AppTokens.spacingSm),

          // 次要操作行：情绪日记 + 树洞
          SecondaryActionRow(
            onMoodTap: () => MoodDialog.show(context, ref),
          ),

          const Spacer(flex: 1),

          // 底部信息
          todayAsync.when(
            data: (today) => HomeFooter(
              lastCheckIn: today,
              nextReminder: nextReminder,
              showStreakBroken: streakSnapshot.shouldShowStreakBroken,
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  static void _noop() {}

  /// 打卡:haptic + 触发实际打卡
  Future<void> _onCheckIn(int currentStreak) async {
    // v0.22 round 30 (emil P2-4): 走 Haptics.success 集中器
    Haptics.success();
    await ref.read(checkInNotifierProvider.notifier).checkIn();
    if (mounted) {
      final newStreak = currentStreak + 1;
      // 显示庆祝 overlay
      _showCelebrationOverlay(context, _celebrationFor(context, newStreak));
    }
    // 打卡成功：取消所有 snooze
    // v0.22 round 29 (spen-bug-04): 删 cancelSoftReminder 死代码 (scheduleSoftReminder
    // 已在 v0.18 P2-P0-5 删除, cancelSoftReminder 跟着成 no-op)
    try {
      await ref.read(notificationServiceProvider).cancelAllSnoozes();
    } catch (e, st) {
      // 通知清理失败 → 主流程已完成，清理失败只意味着今天还可能再响一次
      swallowError(
        where: 'home_page._onCheckIn',
        error: e,
        stack: st,
        note: 'cancel soft reminder / snoozes failed, today may ring once more',
      );
    }
    // v0.10 (Round 4): 打卡后跑 SafetyWatch (也可能触发，例如打卡是补卡)
    unawaited(_runAfterCheckIn());
    // AI 关怀：打卡后评估是否触发(rule-based)
    unawaited(_fireCareEngine());
  }

  /// 打卡后跑 SafetyWatch
  ///
  /// 设计：用户刚补卡理论上不该再触发，但系统可能因为日期错乱或打卡未及时入库
  /// 仍认为"长期没打卡",所以这里也调一次。
  Future<void> _runAfterCheckIn() async {
    try {
      // v0.27 round 60 (P0-3 修正): 传 l10n, 通知 3 态分流 + UI 文案走 l10n
      final l10n = AppLocalizations.of(context);
      final result =
          await ref.read(safetyWatchServiceProvider).onCheckIn(l10n: l10n);
      if (!mounted) return;
      if (result.kind == SafetyCheckKind.alerted) {
        // 罕见：打卡后仍触发告警
        // v0.21 Round 22 (P0-10 修复): 走 AppSnackBar.error 集中器
        AppSnackBar.showError(
          context,
          action: '⚠️ ${result.displayMessage}',
          error: l10n.homeSafetyAlertSuffix,
        );
      }
    } catch (e, st) {
      // SafetyWatch 失败 → 用户已经看到打卡成功的庆祝，失联检测后台再跑就行
      swallowError(
        where: 'home_page._runSafetyCheck',
        error: e,
        stack: st,
        note: 'SafetyWatch failed, check-in celebration already shown',
      );
    }
  }

  /// CareEngine 触发(rule-based)
  ///
  /// v0.27 round 67 (B-2 修复): R65 use case 抽离收尾
  ///
  /// 修复前: 直接调 `CareEngine.evaluate(...)` + `CareEngine.fire(trigger, notif)`
  /// 静态方法。R65 抽了 `FireCareStrategyUseCase` (业务编排下沉到 domain),
  /// 但 home_page 这边没接入 → use case 是 dead code, 业务编排仍跟 UI
  /// 混在 home_page 里。
  ///
  /// 修复后:
  /// - 拿 `fireCareStrategyUseCaseProvider` 调 use case
  /// - 拿 `result` (decision/strategy/title/body), 按 decision 路由分发:
  ///   - `fireCareCopy` (default): 推本地通知 (跟 R67 前行为一致)
  ///   - `fireSms` (v1.0+ 真接阿里云后): 调 smsService.send
  ///   - `fireEmail` (v1.0+ 真接 SendGrid 后): 调 emailService
  ///   - `disabled` / `noAction`: 早返
  /// - `CareEngine.evaluate` / `CareEngine.fire` 留作 legacy API
  ///   (v0.28 删除, 见 docs/LEGACY_API_NOTES.md)
  Future<void> _fireCareEngine() async {
    try {
      // P0 fix: 复用 provider 树已缓存的打卡数据，不再重复查库
      final all = ref.read(allCheckInsProvider).value ?? [];
      // v0.27 round 68 (CC-6 修复): 读 user 撤回失联通知同意状态
      // (PIPL §14 + 隐私政策 §4 / §9 / §12 表格承诺"撤回后 CareEngine.fire 直接 return")
      final isSafetyWithdrawn = await ref
          .read(legalConsentWithdrawnProvider(ConsentKind.safety).future);
      // v0.27 round 67 (B-2 修复): R65 抽离的 use case
      final useCase = ref.read(fireCareStrategyUseCaseProvider);
      final result = useCase(
        FireCareStrategyInput(
          checkIns: all,
          now: DateTime.now(),
          userProfile: null, // v1.0+ 用 (文案内嵌用户名)
          contacts: const [], // v1.0+ 用 (SmsService.send 的 to:)
          config: CareChannelConfig.defaultConfig, // careCopy
          isSafetyConsentWithdrawn: isSafetyWithdrawn, // R68 CC-6 修复
        ),
      );
      if (!result.shouldFire) return;

      // v0.27 round 67 (B-2 修复): dispatch by decision
      // 当前 defaultConfig = careCopy, 推本地通知 (跟 R67 前行为一致)
      // v1.0+ 切 SMS/Email 时改 config.channel, 走下面 2 个分支
      switch (result.decision) {
        case FireCareDecision.fireCareCopy:
          final notif = ref.read(notificationServiceProvider);
          final id = 8000 + result.strategy.index;
          await notif.showNow(id: id, title: result.title, body: result.body);
          break;
        case FireCareDecision.fireSms:
          // v0.27 round 67 (B-2 修复): 调 smsService.send
          // 当前 SMS provider 仍 mock (R55 真接 TODO), send() 走
          // SmsService.send mock 早返路径 → SmsResult.mock (不算 ok
          // 也不算 fail)。R55 真接后这里就直接真发了。
          //
          // v0.27 round 75 (R74-N13 修): 之前硬编码 '00000000000' 占位
          // phone, 真接 R55+ 时拿到 placeholder phone 发到占位号码
          // (静默成功 + 失联告警失败)。改 throw StateError 让 caller 必填
          // input.contacts, 防止生产模式发到占位号码。
          // 当前 defaultConfig=careCopy, 此分支不会被触发, 留作路由占位。
          throw StateError(
            'FireCareDecision.fireSms requires non-empty input.contacts. '
            'R55+ 真接 SMS 时 caller 必填, 当前 defaultConfig=careCopy '
            '此分支不会触发。',
          );
        case FireCareDecision.fireEmail:
          // v0.27 round 67 (B-2 修复): 调 emailService.sendMedicationReminder
          // 当前 EmailService 是 mock, send 返 false (P1-8 fix 行为)。
          // R55+ 真接 SendGrid 后这里就直接真发了。
          //
          // v0.27 round 75 (R74-N14 修): 之前硬编码 'placeholder@invalid.local'
          // 占位 email, 改 throw StateError 防止发到占位地址 (PIPL §6 PII 暴露)。
          throw StateError(
            'FireCareDecision.fireEmail requires non-empty input.contacts. '
            'R55+ 真接 Email 时 caller 必填, 当前 defaultConfig=careCopy '
            '此分支不会触发。',
          );
        case FireCareDecision.disabled:
        case FireCareDecision.noAction:
          // 不会到这里 (shouldFire 已 check, 早返了)
          break;
      }
    } catch (e, st) {
      swallowError(
        where: 'home_page._fireCareEngine',
        error: e,
        stack: st,
        note: 'care engine failed — user may not receive care prompts',
      );
    }
  }

  /// Snooze 5min: 调度 5min 后的一次性本地通知
  ///
  /// 用 medicationId=0 表示"通用打卡提醒 snooze"(避开真实 med id)
  Future<void> _snooze5Min() async {
    // v0.22 round 30 (emil P2-4): 走 Haptics.light 集中器
    Haptics.light();
    try {
      await ref.read(notificationServiceProvider).snoozeOnce(
            medicationId: 0, // 0 = 通用 snooze
            minutes: 5,
            title: AppLocalizations.of(context).homeSnoozeTitle,
            body: AppLocalizations.of(context).homeSnoozeBody,
          );
      if (!mounted) return;
      AppSnackBar.showInfo(
        context,
        AppLocalizations.of(context).homeSnoozeConfirmed,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        action: AppLocalizations.of(context).snackbarActionSnooze,
        error: e,
      );
    }
  }

  String _celebrationFor(BuildContext context, int streak) {
    final l10n = AppLocalizations.of(context);
    if (streak == 1) return l10n.homeCelebrationDay1;
    if (streak < 7) return l10n.homeCelebrationStreakShort(streak);
    if (streak < 30) return l10n.homeCelebrationStreakMedium(streak);
    if (streak < 100) return l10n.homeCelebrationStreakLong(streak);
    return l10n.homeCelebrationStreakMaster(streak);
  }

  /// 顶部 overlay 庆祝(短暂显示，自动消失)
  void _showCelebrationOverlay(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        // R69 (emil P1-1 修复): 改 MediaQuery.padding.top + spacingLg,
        // origin-aware 顶部定位, 避免键盘弹起 / 横屏 / 全面屏撞顶
        top: MediaQuery.of(ctx).padding.top + AppTokens.spacingLg,
        left: 0,
        right: 0,
        child: IgnorePointer(
          child: Center(
            // v0.24 round 48 (emil P1-2): 实际走 CelebrationBounce via typedef @Deprecated
            // 未来 v0.25+ 全部迁移后, 可删 celebration_overlay.dart 整个文件
            child: CelebrationBounce(message: message),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    // v0.27 round 62 (P1-6 修复): 用 Timer 替代 Future.delayed,
    // 存字段, dispose 时 cancel, 避免 widget 销毁后回调 fire 引起 race。
    _celebrationTimer?.cancel();
    _celebrationTimer = Timer(
      const Duration(milliseconds: AppTokens.celebrationDisplayMs),
      () {
        if (entry.mounted) entry.remove();
        _celebrationTimer = null;
      },
    );
  }

  /// 计算下次提醒时间(每天 20:00)
  DateTime? _nextReminderTime() {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, 20, 0);
    if (next.isBefore(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }
}

/// P17 fix: 通知初始化失败时显示的顶部 banner
///
/// v0.18 (P1-21) fix: 抽到 home/widgets/notification_failure_banner.dart
/// 之前是 _NotificationFailureBanner 内联在 home_page.dart(300+ 行 private
/// widget),现在 import 抽出的 public NotificationFailureBanner 让
/// home_page god-page 减肥。
// (banner widget moved to widgets/notification_failure_banner.dart)
