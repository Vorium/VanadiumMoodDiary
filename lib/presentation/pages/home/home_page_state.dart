// home_page_state.dart — HomePage state 主壳
//
// v0.30 round 95 (sub-spec 4 task 5): 从 home_page.dart 抽出
// v0.30 R108 (P1 home_page_state 拆 3 controller): 进一步抽 deep link /
// care engine / celebration 业务到 controllers/ 子目录, state class 缩到
// ~370L (R107 报告 §3.2 方案, 4 视角共识: emil + spen + architecture +
// bottom-up)。
//
// 职责: HomePageState ConsumerState 类 (initState / dispose / build +
// 4 业务方法: _onCheckIn / _snooze5Min / _runSafetyCheck / _nextReminderTime)
// + 3 controller 编排入口 + 旁路 helper。
//
// **拆出历史**:
// - R95 (sub-spec 4 task 5): 731 行 → 主壳 138 行 + state 590 行
// - R108 (P1 home_page_state 拆): state 597 行 → ~370 行, 3 controller
//   各 50-80L 抽到 controllers/ 子目录
//   - controllers/home_deep_link_handler.dart (~220L 含注释)
//   - controllers/home_care_engine_dispatcher.dart (~150L 含注释)
//   - controllers/home_celebration_controller.dart (~110L 含注释)
//
// **state class 当前职责**:
// - 1 lifecycle enum (跟 deep link + safety check 共享, 留 state class)
// - 1 ScrollController (主屏滚动, 留 state class)
// - initState (调度 postFrameCallback 跑 safety check + deep link)
// - dispose (取消 3 controller 内部 Timer + ScrollController)
// - build (180L 主页 6 区域 widget tree)
// - _onCheckIn (打卡主流程, 调 2 controller)
// - _snooze5Min (5min 后通知)
// - _runSafetyCheck (跟 _lifecycle 紧耦合, 留 state class)
// - _nextReminderTime (20:00 计算, 跟 midnight timer 配合)
//
// 公共 API:
// - [HomePageState] (public, 替换原 _HomePageState) — state class
//   public 是为了打破 home_page.dart ↔ home_page_state.dart 循环 import
//
// 4 层架构纯度: 本文件 import `flutter` / `flutter_riverpod` / `go_router`,
// 跟 home_page 一样在 presentation 层, 0 violation (cross_feature 守门员覆盖)。
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/data/services/safety_watch_service.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/pages/home/controllers/home_care_engine_dispatcher.dart';
import 'package:chroniccare/presentation/pages/home/controllers/home_celebration_controller.dart';
import 'package:chroniccare/presentation/pages/home/controllers/home_deep_link_handler.dart';
import 'package:chroniccare/presentation/providers/check_in_notifier.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/notification_init_provider.dart';
import 'package:chroniccare/presentation/providers/service_providers.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/feedback.dart' show Haptics;
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/widgets/animations/animations.dart';
import 'package:chroniccare/presentation/pages/home/widgets/encouragement_text.dart';
import 'package:chroniccare/presentation/pages/home/widgets/home_fab_toolbar.dart';
import 'package:chroniccare/presentation/pages/home/widgets/home_footer.dart';
import 'package:chroniccare/presentation/pages/home/widgets/home_header.dart';
import 'package:chroniccare/presentation/pages/home/widgets/today_summary_card.dart';
import 'package:chroniccare/presentation/pages/home/widgets/notification_failure_banner.dart';
import 'package:chroniccare/presentation/pages/home/widgets/primary_action_row.dart';
import 'package:chroniccare/presentation/pages/home/widgets/quick_mood_carousel.dart';
import 'package:chroniccare/presentation/pages/home/widgets/secondary_action_row.dart';
import 'package:chroniccare/presentation/pages/medication/today_med_schedule.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/mood_recorder_page.dart';
import 'package:chroniccare/presentation/widgets/check_in_button.dart';
import 'package:chroniccare/presentation/pages/home/home_page.dart'
    show HomeLifecycleState, HomePage;

/// v0.30 round 95 (sub-spec 4 task 5): HomePage state class
/// (原 `_HomePageState` 改成 public 打破循环 import, 命名跟 R84 DayDetailCard
/// 私有→public 改造模式一致, 老 caller 0 改动因为 `ConsumerState` 泛型
/// createState() 还是返回同一个对象, type 兼容)
///
/// v0.30 R108 (P1 home_page_state 拆): 进一步抽 3 controller, state class
/// 保留 build + onCheckIn + snooze + runSafetyCheck + nextReminderTime,
/// 目标 < 370L (R107 报告 §3.2 方案)。
class HomePageState extends ConsumerState<HomePage> {
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
  ///
  /// 留 state class 原因: _lifecycle 跟 _runSafetyCheck + _handleDeepLink 路径
  /// 共享 (deep link 推进 _lifecycle, safety check 读 _lifecycle 判是否已跑),
  /// 3 controller 不应独占。
  HomeLifecycleState _lifecycle = HomeLifecycleState.initial;

  /// v0.30 R108 (P1 home_page_state 拆): 3 controller 实例
  ///
  /// - [_deepLink]: deep link 业务 (解析 + autofire + hint + race Timer)
  /// - [_careDispatcher]: 打卡后 care engine 编排 (safety check + use case)
  /// - [_celebration]: 顶部庆祝 overlay (含 celebration Timer)
  late final HomeDeepLinkHandler _deepLink;
  late final HomeCareEngineDispatcher _careDispatcher;
  late final HomeCelebrationController _celebration;

  /// v0.30 round 92 (audit-fixes / P0 #13): homeFabTop 滚到顶用
  ///
  /// 修前: homeFabTop onPressed 调 AppSnackBar.showInfo 占位
  /// (lib/presentation/pages/home/widgets/home_fab_toolbar.dart R81)。
  /// 修法: 主屏 SingleChildScrollView 接 controller, HomeFabToolbar 通过
  /// scrollController prop 拿到, 末项 onPressed 调 Scrollable.ensureVisible
  /// 把主屏滚到 minScrollExtent (顶)。homeFabHotline 走 context.push 路由,
  /// 跟 controller 无关。
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // v0.30 R108 (P1 home_page_state 拆): 初始化 3 controller
    _deepLink = HomeDeepLinkHandler(ref);
    _careDispatcher = HomeCareEngineDispatcher(ref);
    _celebration = HomeCelebrationController();
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
    // v0.30 R108 (P1 home_page_state 拆): 3 controller dispose
    // (每个 controller 内部 cancel 自己的 Timer, 防 leak)
    _deepLink.dispose();
    _celebration.dispose();
    // _careDispatcher 无 Timer 字段, 不需 dispose
    // v0.30 round 92 (audit-fixes / P0 #13): dispose 释放 ScrollController
    // (R17 通用模式, widget leak guard)
    _scrollController.dispose();
    super.dispose();
  }

  /// v0.11 (Round 5): 处理 ?medId=N&autofire=1
  ///
  /// 用户点 medication 通知 → 路由跳到 /check-in/medication/N
  /// → redirect 到 /?medId=N&autofire=1 → home_page 收到参数
  /// → 这里自动打卡 + 显示庆祝
  ///
  /// v0.30 R108 (P1 home_page_state 拆): 抽到 [HomeDeepLinkHandler],
  /// 本方法只做 inspect + 路由 + 调 controller, 25L (原 80L)。
  Future<void> _handleDeepLink() async {
    final decision = _deepLink.inspect(
      uri: GoRouterState.of(context).uri,
      currentLifecycle: _lifecycle,
    );
    _lifecycle = decision.nextLifecycle;
    switch (decision.action) {
      case DeepLinkAction.noop:
        break;
      case DeepLinkAction.scheduleSafetyRerun:
        // 调度 race guard Timer, 到点重跑 safety check
        _deepLink.scheduleRaceTimer(() {
          if (!mounted) return;
          unawaited(_runSafetyCheck(force: true));
        });
      case DeepLinkAction.autofire:
        // 自动打卡该药
        await _handleAutofire(decision.medId!);
      case DeepLinkAction.showHint:
        // 只显示该药的"该吃了"信息
        _deepLink.showMedicationHint(decision.medId!, context);
    }
  }

  /// v0.30 R108 (P1 home_page_state 拆): autofire 编排 wrapper
  ///
  /// 调 [HomeDeepLinkHandler.autofireMedicationCheckIn] 实际打卡,
  /// 成功后调 [HomeCelebrationController.show] 显示庆祝 overlay,
  /// 清除 query 防刷新重复触发。
  Future<void> _handleAutofire(int medId) async {
    final result = await _deepLink.autofireMedicationCheckIn(
      medId: medId,
      isMounted: () => mounted,
      context: context,
    );
    if (!mounted) return;
    if (result.success && result.medName != null) {
      _celebration.show(
        context,
        AppLocalizations.of(context).homeAutofireCelebration(result.medName!),
      );
    }
    // 清除 query 防止刷新页面重复触发
    _deepLink.clearQuery(context);
  }

  /// 调 SafetyWatch.onAppStart,按结果显示一次性 SnackBar
  ///
  /// [force] = true 时忽略 [_safetyCheckTriggered] 守卫(用于 deep link 重跑)
  ///
  /// 留 state class 原因: 直接读 / 写 _lifecycle 状态机, 跟 deep link 路径
  /// 共享 lifecycle 推进逻辑。
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
        // R99 (BUG-1): displayMessageL10n(l10n) 拿翻译文案 — displayMessage
        // 返 i18n key 字符串, 直接显示会让用户看到 'safetyCheckResultAlerted'
        AppSnackBar.showError(
          context,
          action: '⚠️ ${result.displayMessageL10n(l10n)}',
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
      // v0.31 R9a: actions: [ThemeToggleButton()] 移到 HomeHeader 内,
      // 主页 AppBar 走空 actions, 主题切换从右上角 in-body toggle 走。
      actions: null,
      // v0.28 R81 (emil design-3): 浮动 FAB 工具栏
      // B 站"哗哩哗哩能量加油站" 4 工具入口, 收起 1 FAB / 展开 4 圆角按钮
      // (心情测试 / 心情树洞 / 紧急热线 / 回到顶端)
      // emil 频度: tens/day (toggle), standard animation OK
      //
      // v0.30 round 92 (audit-fixes / P0 #13): 传 _scrollController 给
      // toolbar, 让 homeFabTop 走 Scrollable.ensureVisible 滚到顶。
      floatingActionButton: HomeFabToolbar(scrollController: _scrollController),
      // v0.30 round 92 (audit-fixes / P0 #13): Column → SingleChildScrollView
      // 让 homeFabTop 有可滚动的内容 (主屏填满视口时不需要滚, 但小屏 /
      // 文字放大场景可能需要)。Spacer 保留主屏元素 stretch 排版。
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // v0.31 R9a (Apple Health 仪表盘): build 整合
            //
            // 整体改 AppleListSection 包装各区块, 用 spacingMd 16 替代
            // spacingLg 24, 简化 stagger (2 处: header delay 0 + summary delay 30),
            // 移除 HeroIllustration (Apple Health 风格无大图, 用 section 列表代替).
            //
            // 顺序 (跟 spec §5.1 1:1):
            // 1. 通知失败 banner (顶部, 保留)
            // 2. HomeHeader (FadeIn delay 0)
            // 3. CheckInButton (FadeIn delay 1*staggerStepMs=30ms)
            // 4. AppleListSection("今日指标") + TodaySummaryCard (FadeIn delay 2*30=60ms)
            // 5. AppleListSection("心情") + QuickMoodCarousel (Duration.zero)
            // 6. AppleListSection("快捷操作") + PrimaryActionRow (Duration.zero)
            // 7. AppleListSection("更多") + SecondaryActionRow (Duration.zero)
            // 8. HomeFooter (Duration.zero)
            // 9. EncouragementText (Duration.zero)
            //
            // stagger 累加最大 = 60ms (2 * staggerStepMs=30), 远低于前庭敏感
            // 阈值 250ms, 跟 R108 P0#5 决策一致 (home 100+/day 频度).

            // P17 fix: 通知失败 banner(一次性提示，可关闭)
            if (!notifResult.ok)
              NotificationFailureBanner(error: notifResult.error),

            // 2: HomeHeader (28pt greeting + 15pt 日期 + 32x32 theme toggle)
            FadeIn(
              child: HomeHeader(userName: userName),
            ),

            const SizedBox(height: AppTokens.spacingXs),

            // 3: CheckInButton 巨型 pill 64pt (Apple Health 风格)
            FadeIn(
              delay: const Duration(milliseconds: AppTokens.staggerStepMs),
              child: todayAsync.when(
                data: (today) => CheckInButton(
                  isChecked: today != null,
                  streakDays: streakSnapshot.streak,
                  isLoading: isChecking,
                  onPressed: () => _onCheckIn(streakSnapshot.streak),
                ),
                loading: () => CheckInButton(
                  isChecked: false,
                  streakDays: 0,
                  isLoading: true,
                  onPressed: _noop,
                ),
                error: (_, __) => CheckInButton(
                  isChecked: false,
                  streakDays: 0,
                  isLoading: false,
                  onPressed: _noop,
                ),
              ),
            ),

            const SizedBox(height: AppTokens.spacingMd),

            // 4: 今日指标 4 项 2x2 网格
            const FadeIn(
              delay: Duration(milliseconds: 2 * AppTokens.staggerStepMs),
              child: TodaySummaryCard(),
            ),

            const SizedBox(height: AppTokens.spacingMd),

            // 5: 心情 5 档圆形 button
            QuickMoodCarousel(
              onOpenFullDialog: () => context.push('/mood-list'),
            ),

            const SizedBox(height: AppTokens.spacingMd),

            // 6: 快捷操作 2x2 彩色 tile 网格
            PrimaryActionRow(
              onMedicationTap: () => context.push('/medication'),
              onMoodTap: () => MoodRecorderPage.show(context, ref),
              onVentTap: () => context.push('/vent'),
              onAssessmentTap: () => context.push('/assessment-center'),
            ),

            const SizedBox(height: AppTokens.spacingMd),

            // 7: 更多 4 项 icon-row cell
            SecondaryActionRow(
              onMoodTap: () => MoodRecorderPage.show(context, ref),
            ),

            const SizedBox(height: AppTokens.spacingSm),

            // 鼓励文案(按 streak 动态切换)
            EncouragementText(streak: streakSnapshot.streak),

            const SizedBox(height: AppTokens.spacingSm),

            // 8: 底部信息
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
      ),
    );
  }

  static void _noop() {}

  /// 打卡:haptic + 触发实际打卡
  ///
  /// v0.30 R108 (P1 home_page_state 拆): care engine 编排移到
  /// [HomeCareEngineDispatcher], 本方法保留主流程 (haptic + checkIn +
  /// 取消 snooze + 调 2 controller)。
  Future<void> _onCheckIn(int currentStreak) async {
    // v0.22 round 30 (emil P2-4): 走 Haptics.success 集中器
    // R97-P1-12: unawaited 显式标记 fire-and-forget
    unawaited(Haptics.success());
    await ref.read(checkInNotifierProvider.notifier).checkIn();
    if (mounted) {
      final newStreak = currentStreak + 1;
      // 显示庆祝 overlay
      _celebration.show(
        context,
        _celebration.pickStreakMessage(context, newStreak),
      );
    }
    // 打卡成功：取消所有 snooze
    // v0.22 round 29 (spen-bug-04): 删 cancelSoftReminder 死代码 (scheduleSoftReminder
    // 已在 v0.18 P2-P0-5 删除, cancelSoftReminder 跟着成 no-op)
    try {
      await ref.read(notificationServiceProvider).delegate.cancelAllSnoozes();
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
    unawaited(_careDispatcher.runAfterCheckIn(
      context: context,
      isMounted: () => mounted,
    ));
    // AI 关怀：打卡后评估是否触发(rule-based)
    unawaited(_careDispatcher.fireCareEngine());
  }

  /// Snooze 5min: 调度 5min 后的一次性本地通知
  ///
  /// 用 medicationId=0 表示"通用打卡提醒 snooze"(避开真实 med id)
  Future<void> _snooze5Min() async {
    // v0.22 round 30 (emil P2-4): 走 Haptics.light 集中器
    // R97-P1-12: unawaited 显式标记 fire-and-forget
    unawaited(Haptics.light());
    try {
      await ref.read(notificationServiceProvider).delegate.snoozeOnce(
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
