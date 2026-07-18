import '../../providers/service_providers.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/data/services/safety_watch_service.dart';
import 'package:chroniccare/domain/logic/care_engine.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/core/theme/theme_toggle_button.dart';
import 'package:chroniccare/presentation/providers/check_in_notifier.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/data_providers.dart';
import 'package:chroniccare/main.dart' show notificationInitResultProvider;
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/pages/home/widgets/celebration_overlay.dart';
import 'package:chroniccare/presentation/pages/home/widgets/encouragement_text.dart';
import 'package:chroniccare/presentation/pages/home/widgets/home_footer.dart';
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

class _HomePageState extends ConsumerState<HomePage> {
  /// SafetyWatch 启动检查是否已跑过(避免重复触发)
  bool _safetyCheckTriggered = false;

  /// Deep link 强制重跑 safety 检查的请求(独立 flag,
  /// v0.14 修:旧实现用 `!_safetyCheckTriggered` 守卫,结果第一次
  /// 跑已起来后 deep link 路径永远走不进去)
  bool _safetyRerunRequested = false;

  /// Deep link 自动打卡是否已处理(避免重复)
  bool _deepLinkHandled = false;

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

  /// v0.11 (Round 5): 处理 ?medId=N&autofire=1
  ///
  /// 用户点 medication 通知 → 路由跳到 /check-in/medication/N
  /// → redirect 到 /?medId=N&autofire=1 → home_page 收到参数
  /// → 这里自动打卡 + 显示庆祝
  Future<void> _handleDeepLink() async {
    if (_deepLinkHandled) return;
    final medIdParam = GoRouterState.of(context).uri.queryParameters['medId'];
    final autofire =
        GoRouterState.of(context).uri.queryParameters['autofire'] == '1';
    if (medIdParam == null) {
      // 不是 deep link 跳来的,处理 safety reason
      final reason = GoRouterState.of(context).uri.queryParameters['reason'];
      if (reason == 'safety') {
        // 强制重跑一次 (从通知跳来的场景)
        // v0.14 fix: 用独立 flag,不受 _safetyCheckTriggered 影响
        // 旧实现 `!_safetyCheckTriggered` 在第一跑已起来后永远 false
        if (_safetyRerunRequested) return; // 已请求过
        _safetyRerunRequested = true;
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await _runSafetyCheck(force: true);
      }
      return;
    }
    _deepLinkHandled = true;
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
      // P0-11 fix: med 读挪到 mounted guard 之内,避免 widget 已 dispose 但
      // 还在 race 读 provider;再加一道 mounted guard 防 await 间隙 unmount。
      // (superpowers-en P0-11 原始 evidence: "med?.name 在 guard 之前读")
      final med = await ref
          .read(medicationRepositoryProvider)
          .watchAll()
          .first
          .then((list) => list.where((m) => m.id == medId).firstOrNull);
      if (!mounted) return;
      final medName = med?.name ?? '该药';
      HapticFeedback.mediumImpact();
      _showCelebrationOverlay(context, '已打卡:$medName ✅');
      // 清除 query 防止刷新页面重复触发
      GoRouter.of(context).go('/');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTokens.error,
          content: Text('自动打卡失败:${e.toString().split('\n').first}'),
        ),
      );
    }
  }

  void _showMedicationHint(int medId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('💊 准备打卡药物 #$medId'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 调 SafetyWatch.onAppStart,按结果显示一次性 SnackBar
  /// 调 SafetyWatch.onAppStart,按结果显示一次性 SnackBar
  ///
  /// [force] = true 时忽略 [_safetyCheckTriggered] 守卫(用于 deep link 重跑)
  Future<void> _runSafetyCheck({bool force = false}) async {
    if (_safetyCheckTriggered && !force) return;
    _safetyCheckTriggered = true;
    try {
      final result = await ref.read(safetyWatchServiceProvider).onAppStart();
      if (!mounted) return;
      if (result.kind == SafetyCheckKind.alerted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTokens.error,
            content: Text(
              '⚠️ ${result.displayMessage}(请尽快打卡或联系家人)',
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (_) {
      // 静默
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayAsync = ref.watch(todayCheckInProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final checkInState = ref.watch(checkInNotifierProvider);
    final isChecking = checkInState.isLoading;
    // P10 (B8) fix: streak 只算一次,所有 widget 看到同一个值
    final streakAsync = ref.watch(streakSummaryProvider);
    final streakSnapshot = streakAsync.maybeWhen(
      data: (s) => s,
      orElse: () =>
          const StreakSnapshot(streak: 0, shouldShowStreakBroken: false),
    );
    // P17 fix: 通知初始化失败时,在主页顶部显示一条提示
    final notifResult = ref.watch(notificationInitResultProvider);

    // 打卡失败时给用户一个反馈
    ref.listen<AsyncValue<void>>(checkInNotifierProvider, (prev, next) {
      if (next.hasError && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('打卡失败:${next.error.toString().split('\n').first}'),
            backgroundColor: AppTokens.error,
          ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // v0.18 (P1-27) fix: home_page god-page 拆 5 widget,build 主体减肥
          // 顶部 header
          HomeHeader(userName: userName),

          // P17 fix: 通知失败 banner(一次性提示,可关闭)
          if (!notifResult.ok)
            NotificationFailureBanner(error: notifResult.error),

          const Spacer(flex: 1),

          // 鼓励文案(按 streak 动态切换)
          EncouragementText(streak: streakSnapshot.streak),

          const SizedBox(height: AppTokens.spacingSm),

          // 主操作行:打卡按钮 + 临时吃药 + snooze 5min
          todayAsync.when(
            data: (today) => PrimaryActionRow(
              isChecked: today != null,
              streakDays: streakSnapshot.streak,
              isLoading: isChecking,
              onCheckIn: () => _onCheckIn(context, streakSnapshot.streak),
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

          // 次要操作行:情绪日记 + 树洞
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
  Future<void> _onCheckIn(BuildContext context, int currentStreak) async {
    HapticFeedback.mediumImpact();
    await ref.read(checkInNotifierProvider.notifier).checkIn();
    if (!context.mounted) return;
    final newStreak = currentStreak + 1;
    // 显示庆祝 overlay
    _showCelebrationOverlay(context, _celebrationFor(newStreak));
    // 打卡成功:取消 soft 提醒 + snooze
    try {
      await ref.read(notificationServiceProvider).cancelSoftReminder();
      await ref.read(notificationServiceProvider).cancelAllSnoozes();
    } catch (e, st) {
      // 通知清理失败 → 主流程已完成,清理失败只意味着今天还可能再响一次
      swallowError(
        where: 'home_page._onCheckIn',
        error: e,
        stack: st,
        note: 'cancel soft reminder / snoozes failed, today may ring once more',
      );
    }
    // v0.10 (Round 4): 打卡后跑 SafetyWatch (也可能触发,例如打卡是补卡)
    unawaited(_runAfterCheckIn());
    // AI 关怀:打卡后评估是否触发(rule-based)
    unawaited(_fireCareEngine());
  }

  /// 打卡后跑 SafetyWatch
  ///
  /// 设计:用户刚补卡理论上不该再触发,但系统可能因为日期错乱或打卡未及时入库
  /// 仍认为"长期没打卡",所以这里也调一次。
  Future<void> _runAfterCheckIn() async {
    try {
      final result = await ref.read(safetyWatchServiceProvider).onCheckIn();
      if (!mounted) return;
      if (result.kind == SafetyCheckKind.alerted) {
        // 罕见:打卡后仍触发告警
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTokens.error,
            content: Text('⚠️ ${result.displayMessage}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e, st) {
      // SafetyWatch 失败 → 用户已经看到打卡成功的庆祝,失联检测后台再跑就行
      swallowError(
        where: 'home_page._runSafetyCheck',
        error: e,
        stack: st,
        note: 'SafetyWatch failed, check-in celebration already shown',
      );
    }
  }

  /// CareEngine 触发(rule-based)
  Future<void> _fireCareEngine() async {
    try {
      final all = await ref.read(checkInRepositoryProvider).watchAll().first;
      final trigger = CareEngine.evaluate(checkIns: all, now: DateTime.now());
      if (!trigger.shouldFire) return;
      final notif = ref.read(notificationServiceProvider);
      await CareEngine.fire(trigger, notif);
    } catch (_) {
      // 静默失败,不打扰用户
    }
  }

  /// Snooze 5min: 调度 5min 后的一次性本地通知
  ///
  /// 用 medicationId=0 表示"通用打卡提醒 snooze"(避开真实 med id)
  Future<void> _snooze5Min() async {
    HapticFeedback.lightImpact();
    try {
      await ref.read(notificationServiceProvider).snoozeOnce(
            medicationId: 0, // 0 = 通用 snooze
            minutes: 5,
            title: '⏰ 该打卡了(5min 后)',
            body: '刚才你点了「snooze」,是时候点一下 = 打卡了',
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('好,5 分钟后会再提醒你 👌'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTokens.error,
          content: Text('Snooze 失败:${e.toString().split('\n').first}'),
        ),
      );
    }
  }

  String _celebrationFor(int streak) {
    if (streak == 1) return '已记录!第 1 天 🌱';
    if (streak < 7) return '已记录!连击 $streak 天 🌿';
    if (streak < 30) return '已记录!连击 $streak 天 🌳';
    if (streak < 100) return '已记录!$streak 天连击 🌲';
    return '已记录!$streak 天--你太厉害了 🏔️';
  }

  /// 顶部 overlay 庆祝(短暂显示,自动消失)
  void _showCelebrationOverlay(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: MediaQuery.of(ctx).size.height * 0.35,
        left: 0,
        right: 0,
        child: IgnorePointer(
          child: Center(
            child: AnimatedCelebration(message: message),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (entry.mounted) entry.remove();
    });
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
