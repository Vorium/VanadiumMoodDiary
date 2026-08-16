// home_page_state.dart — HomePage state 主壳
//
// v0.30 round 95 (sub-spec 4 task 5): 从 home_page.dart 抽出
// v0.30 R108 (P1 home_page_state 拆 3 controller): 进一步抽 deep link /
// care engine / celebration 业务到 controllers/ 子目录, state class 缩到
// ~370L (R107 报告 §3.2 方案, 4 视角共识: emil + spen + architecture +
// bottom-up)。
//
// 职责: HomePageState ConsumerState 类 (initState / dispose / build +
// 3 业务方法: _onCheckIn / _snooze5Min / _nextReminderTime)
// + 2 controller 编排入口 + 旁路 helper。
//
// **拆出历史**:
// - R95 (sub-spec 4 task 5): 731 行 → 主壳 138 行 + state 590 行
// - R108 (P1 home_page_state 拆): state 597 行 → ~370 行, 3 controller
//   各 50-80L 抽到 controllers/ 子目录
//   - controllers/home_deep_link_handler.dart (~220L 含注释)
//   - controllers/home_care_engine_dispatcher.dart (~150L 含注释)
//   - controllers/home_celebration_controller.dart (~110L 含注释)
// - 1.1.0 round 4 (emotion-first refactor): safety check 整摘 —
//   home_care_engine_dispatcher 删除, _runSafetyCheck 删除, care engine
//   编排 (_onCheckIn 内 runAfterCheckIn + fireCareEngine) 删除,
//   lifecycle 5 态 → 2 态。
//
// **state class 当前职责**:
// - 1 lifecycle enum (deep link 推进, 留 state class)
// - 1 ScrollController (主屏滚动, 留 state class)
// - initState (调度 postFrameCallback 跑 deep link)
// - dispose (取消 2 controller 内部 Timer + ScrollController)
// - build (180L 主页 6 区域 widget tree)
// - _onCheckIn (打卡主流程: haptic + checkIn + 庆祝 + 取消 snooze)
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

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/pages/home/controllers/home_celebration_controller.dart';
import 'package:chroniccare/presentation/pages/home/controllers/home_deep_link_handler.dart';
import 'package:chroniccare/presentation/providers/check_in_notifier.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/notification_init_provider.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/feedback.dart' show Haptics;
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/widgets/animations/animations.dart';
import 'package:chroniccare/presentation/pages/home/widgets/encouragement_text.dart';
import 'package:chroniccare/presentation/pages/home/widgets/home_fab_toolbar.dart';
import 'package:chroniccare/presentation/pages/home/widgets/home_footer.dart';
import 'package:chroniccare/presentation/pages/home/widgets/home_header.dart';
import 'package:chroniccare/presentation/pages/home/widgets/mood_hero_card.dart';
import 'package:chroniccare/presentation/pages/home/widgets/today_summary_card.dart';
import 'package:chroniccare/presentation/pages/home/widgets/notification_failure_banner.dart';
import 'package:chroniccare/presentation/pages/home/widgets/primary_action_row.dart';
import 'package:chroniccare/presentation/pages/home/widgets/vent_hero_card.dart';
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
  /// 1.1.0 round 4: safety check 路径整摘后只剩 deep link 一个推进源,
  /// 5 状态简化为 2 状态 (initial / deepLinkHandled), 见 [HomeLifecycleState]。
  HomeLifecycleState _lifecycle = HomeLifecycleState.initial;

  /// v0.30 R108 (P1 home_page_state 拆): 2 controller 实例
  ///
  /// - [_deepLink]: deep link 业务 (解析 + autofire + hint)
  /// - [_celebration]: 顶部庆祝 overlay (含 celebration Timer)
  late final HomeDeepLinkHandler _deepLink;
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
    // v0.30 R108 (P1 home_page_state 拆): 初始化 2 controller
    _deepLink = HomeDeepLinkHandler(ref);
    _celebration = HomeCelebrationController();
    // v0.11 (Round 5): 首帧后处理 deep link query param
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_handleDeepLink());
      // Wave 7 (Task A, R113): 入场动画开始后标记"已播放" — 后续 mount
      // (tab 切回) 直接 Duration.zero 跳终态, 不再重播 ~650ms 入场。
      ref.read(homeEntryPlayedProvider.notifier).markPlayed();
    });
  }

  @override
  void dispose() {
    // v0.30 R108 (P1 home_page_state 拆): celebration controller dispose
    // (内部 cancel 自己的 Timer, 防 leak)
    _celebration.dispose();
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
  /// 1.1.0 round 4: safety rerun 分支删除 (reason=safety 路径已摘)。
  Future<void> _handleDeepLink() async {
    final decision = _deepLink.inspect(
      uri: GoRouterState.of(context).uri,
      currentLifecycle: _lifecycle,
    );
    _lifecycle = decision.nextLifecycle;
    switch (decision.action) {
      case DeepLinkAction.noop:
        break;
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

    // Wave 7 (Task A, R113): 入场动画只播一次 — tab 切回不再重播。
    // entryPlayed=true 时 FadeIn duration/delay = Duration.zero (直接终态),
    // CheckInButton animateEntry=false (_EntrySpring 跳到 1.0)。首次启动
    // 完整播放 (FadeIn durSlow 400ms + stagger 30/60ms + spring)。
    final entryPlayed = ref.watch(homeEntryPlayedProvider);
    final entryDuration = entryPlayed ? Duration.zero : AppTokens.durSlow;
    final entryDelay1 = entryPlayed
        ? Duration.zero
        : const Duration(milliseconds: AppTokens.staggerStepMs);
    final entryDelay2 = entryPlayed
        ? Duration.zero
        : const Duration(milliseconds: 2 * AppTokens.staggerStepMs);

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
            // spacingLg 24, 简化 stagger (2 处: checkIn delay 1*step + summary
            // delay 2*step), 移除 HeroIllustration (Apple Health 风格无大图,
            // 用 section 列表代替).
            //
            // 1.1.0 round 5b (Task 12): 双主卡重构 —
            // QuickMoodCarousel / SecondaryActionRow 整删 (树洞/心情升格
            // hero 卡), 插入 MoodHeroCard + VentHeroCard, CheckInButton 降级
            // compact (打卡不再是最核心主 CTA), PrimaryActionRow 换血
            // 用药/量表/情绪回顾/日常追踪。
            //
            // 顺序 (跟 task-12 brief 1:1):
            // 1. 通知失败 banner (顶部, 保留)
            // 2. HomeHeader (FadeIn delay 0)
            // 3. MoodHeroCard (Duration.zero)
            // 4. VentHeroCard (Duration.zero)
            // 5. CheckInButton compact (FadeIn delay 1*staggerStepMs=30ms)
            // 6. AppleListSection("今日指标") + TodaySummaryCard (FadeIn delay 2*30=60ms)
            // 7. AppleListSection("快捷操作") + PrimaryActionRow (Duration.zero)
            // 8. EncouragementText (Duration.zero)
            // 9. HomeFooter (Duration.zero)
            //
            // stagger 累加最大 = 60ms (2 * staggerStepMs=30), 远低于前庭敏感
            // 阈值 250ms, 跟 R108 P0#5 决策一致 (home 100+/day 频度).

            // P17 fix: 通知失败 banner(一次性提示，可关闭)
            if (!notifResult.ok)
              NotificationFailureBanner(error: notifResult.error),

            // 2: HomeHeader (28pt greeting + 15pt 日期 + 32x32 theme toggle)
            FadeIn(
              duration: entryDuration,
              child: HomeHeader(userName: userName),
            ),

            const SizedBox(height: AppTokens.spacingXs),

            // 3: 情绪大卡 — 最新状态短语 + 记录/回顾入口
            const MoodHeroCard(),

            const SizedBox(height: AppTokens.spacingMd),

            // 4: 树洞卡 — 最新倾诉 1 行预览 + 写心事入口
            const VentHeroCard(),

            const SizedBox(height: AppTokens.spacingMd),

            // 5: CheckInButton 打卡降级 compact (48pt pill, 主 CTA 位让给双主卡)
            FadeIn(
              duration: entryDuration,
              delay: entryDelay1,
              child: todayAsync.when(
                data: (today) => CheckInButton(
                  isChecked: today != null,
                  streakDays: streakSnapshot.streak,
                  isLoading: isChecking,
                  compact: true,
                  animateEntry: !entryPlayed,
                  onPressed: () => _onCheckIn(streakSnapshot.streak),
                ),
                loading: () => CheckInButton(
                  isChecked: false,
                  streakDays: 0,
                  isLoading: true,
                  compact: true,
                  animateEntry: !entryPlayed,
                  onPressed: _noop,
                ),
                error: (_, __) => CheckInButton(
                  isChecked: false,
                  streakDays: 0,
                  isLoading: false,
                  compact: true,
                  animateEntry: !entryPlayed,
                  onPressed: _noop,
                ),
              ),
            ),

            const SizedBox(height: AppTokens.spacingMd),

            // 6: 今日指标 4 项 2x2 网格
            FadeIn(
              duration: entryDuration,
              delay: entryDelay2,
              child: const TodaySummaryCard(),
            ),

            const SizedBox(height: AppTokens.spacingMd),

            // 7: 快捷操作 2x2 彩色 tile 网格 (用药/量表/情绪回顾/日常追踪)
            PrimaryActionRow(
              onMedicationTap: () => context.push('/medication'),
              onAssessmentTap: () => context.push('/assessment-center'),
              onMoodReviewTap: () => context.push('/mood-review'),
              onDailyTrackingTap: () => context.push('/daily-tracking'),
            ),

            const SizedBox(height: AppTokens.spacingSm),

            // 鼓励文案(按 streak 动态切换)
            EncouragementText(streak: streakSnapshot.streak),

            const SizedBox(height: AppTokens.spacingSm),

            // 8: 底部信息 (R114 B2-8: 接 entryDuration/entryDelay 门控,
            // Wave 7 同款 — tab 切回不再重播 400ms+30ms)
            todayAsync.when(
              data: (today) => HomeFooter(
                lastCheckIn: today,
                nextReminder: nextReminder,
                showStreakBroken: streakSnapshot.shouldShowStreakBroken,
                entryDuration: entryDuration,
                entryDelay: entryPlayed ? Duration.zero : entryDelay1,
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
  /// 取消 snooze + 庆祝 overlay)。
  ///
  /// 1.1.0 round 4: care engine 编排整摘 (runAfterCheckIn + fireCareEngine
  /// 及 dispatcher 删除), 打卡主流程只剩 haptic + checkIn + 庆祝 + 取消 snooze。
  Future<void> _onCheckIn(int currentStreak) async {
    // v0.22 round 30 (emil P2-4): 走 Haptics.success 集中器
    // R97-P1-12: unawaited 显式标记 fire-and-forget
    unawaited(Haptics.success());
    await ref.read(checkInNotifierProvider.notifier).checkIn();
    if (!mounted) return;
    // R113 (BUG 2): 打卡失败 (AsyncValue.guard 把异常吞进 state) →
    // 只走 ref.listen 的错误 snackbar, 不再弹成功庆祝 + streak+1 文案。
    // 修前: 用户看到 错误 snackbar + 成功庆祝 同时出现。
    if (ref.read(checkInNotifierProvider).hasError) return;
    final newStreak = currentStreak + 1;
    // 显示庆祝 overlay
    _celebration.show(
      context,
      _celebration.pickStreakMessage(context, newStreak),
    );
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
