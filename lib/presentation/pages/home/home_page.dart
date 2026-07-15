import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/services/safety_watch_service.dart';
import '../../../domain/logic/care_engine.dart';
import '../../../l10n/strings.dart';
import '../../../theme/app_tokens.dart';
import '../../../theme/theme_toggle_button.dart';
import '../../providers/check_in_notifier.dart';
import '../../providers/core_providers.dart';
import '../../providers/data_providers.dart';
import '../../../main.dart' show notificationInitResultProvider;
import '../../widgets/page_scaffold.dart';
import 'widgets/celebration_overlay.dart';
import 'widgets/check_in_button.dart';
import 'widgets/home_secondary_button.dart';
import 'widgets/last_med_info.dart';
import 'widgets/mood_dialog.dart';
import 'widgets/mood_quick_button.dart';
import 'widgets/temp_medication_dialog.dart';

/// 主页
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  /// SafetyWatch 启动检查是否已跑过（避免重复触发）
  bool _safetyCheckTriggered = false;

  /// Deep link 自动打卡是否已处理（避免重复）
  bool _deepLinkHandled = false;

  @override
  void initState() {
    super.initState();
    // v0.10 (Round 4): 首帧后跑一次 SafetyWatch.onAppStart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runSafetyCheck();
    });
    // v0.11 (Round 5): 首帧后处理 deep link query param
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleDeepLink();
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
      if (reason == 'safety' && !_safetyCheckTriggered) {
        // 强制重跑一次 (从通知跳来的场景)
        await Future<void>.delayed(const Duration(milliseconds: 100));
        _safetyCheckTriggered = false;
        await _runSafetyCheck();
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
      // 先查 medication 名字,显示时用
      final med = await ref
          .read(medicationRepositoryProvider)
          .watchAll()
          .first
          .then((list) => list.where((m) => m.id == medId).firstOrNull);
      await ref
          .read(checkInNotifierProvider.notifier)
          .checkIn(medicationId: medId);
      if (!mounted) return;
      final medName = med?.name ?? '该药';
      HapticFeedback.mediumImpact();
      _showCelebrationOverlay(context, '已打卡：$medName ✅');
      // 清除 query 防止刷新页面重复触发
      GoRouter.of(context).go('/');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTokens.error,
          content: Text('自动打卡失败：${e.toString().split('\n').first}'),
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
  Future<void> _runSafetyCheck() async {
    if (_safetyCheckTriggered) return;
    _safetyCheckTriggered = true;
    try {
      final result =
          await ref.read(safetyWatchServiceProvider).onAppStart();
      if (!mounted) return;
      if (result.kind == SafetyCheckKind.alerted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTokens.error,
            content: Text(
              '⚠️ ${result.displayMessage}（请尽快打卡或联系家人）',
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
      orElse: () => const StreakSnapshot(streak: 0, shouldShowStreakBroken: false),
    );
    // P17 fix: 通知初始化失败时,在主页顶部显示一条提示
    final notifResult = ref.watch(notificationInitResultProvider);

    // 打卡失败时给用户一个反馈
    ref.listen<AsyncValue<void>>(checkInNotifierProvider, (prev, next) {
      if (next.hasError && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('打卡失败：${next.error.toString().split('\n').first}'),
            backgroundColor: AppTokens.error,
          ),
        );
      }
    });

    return PageScaffold(
      title: Strings.appName,
      actions: const [ThemeToggleButton()],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 顶部：用户名 + 趋势 + 设置
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  userProfileAsync.maybeWhen(
                    data: (profile) => '${profile?.userName ?? "我"} 还在坚持',
                    orElse: () => '慢病管家',
                  ),
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeHeadline,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.show_chart),
                onPressed: () => context.push('/trend'),
                tooltip: '查看趋势',
              ),
              IconButton(
                icon: const Icon(Icons.psychology_outlined),
                onPressed: () => context.push('/assessment/history'),
                tooltip: '评估历史',
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.push('/settings'),
                tooltip: Strings.settingsAbout,
              ),
            ],
          ),

          // P17 fix: 通知失败 banner（一次性提示,可关闭）
          if (!notifResult.ok) _NotificationFailureBanner(error: notifResult.error),

          const Spacer(flex: 1),

          // 鼓励文案（按 streak 动态切换）
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTokens.spacingSm),
            child: Text(
              _encouragementFor(streakSnapshot.streak),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTokens.fontSizeBody,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: AppTokens.spacingSm),

          // 主打卡按钮
          todayAsync.when(
            data: (today) {
              return CheckInButton(
                isChecked: today != null,
                streakDays: streakSnapshot.streak,
                isLoading: isChecking,
                onPressed: isChecking
                    ? () {}
                    : () => _onCheckIn(context, streakSnapshot.streak),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => CheckInButton(
              isChecked: false,
              streakDays: 0,
              onPressed: () {},
            ),
          ),

          const SizedBox(height: AppTokens.spacingMd),

          // 临时吃药按钮
          HomeSecondaryButton(
            onPressed: () => TempMedicationDialog.show(context, ref),
            child: const Text(
              Strings.homeTempMed,
              style: TextStyle(
                fontSize: AppTokens.fontSizeButton,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: AppTokens.spacingSm),

          // v0.10 (Round 4): Snooze 5min 按钮（参考 Pill Reminder）
          HomeSecondaryButton(
            onPressed: () => _snooze5Min(context),
            child: const Text(
              '⏰ 5 分钟后再提醒',
              style: TextStyle(
                fontSize: AppTokens.fontSizeButton,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: AppTokens.spacingSm),

          // 情绪日记按钮（v0.9 新增）
          MoodQuickButton(
            onTap: () => MoodDialog.show(context, ref),
          ),

          const Spacer(flex: 1),

          // 底部信息
          todayAsync.when(
            data: (today) {
              return LastMedInfo(
                lastCheckIn: today?.timestamp,
                nextReminder: _nextReminderTime(),
                showStreakBroken: streakSnapshot.shouldShowStreakBroken,
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: AppTokens.spacingXl),

          Center(
            child: Text(
              Strings.homeStillOnline,
              style: TextStyle(
                fontSize: AppTokens.fontSizeBody,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 按 streak 切换鼓励文案
  String _encouragementFor(int streak) {
    if (streak <= 0) return '今天重新开始，加油 🌱';
    if (streak == 1) return '第 1 天，迈出第一步 🌱';
    if (streak < 7) return '坚持 $streak 天，继续 🌿';
    if (streak < 30) return '已坚持 $streak 天，真棒 🌳';
    if (streak < 100) return '$streak 天连击，太厉害了 🌲';
    return '$streak 天——你已经是这个习惯的主人了 🏔️';
  }

  /// 打卡：haptic + 触发实际打卡
  Future<void> _onCheckIn(BuildContext context, int currentStreak) async {
    HapticFeedback.mediumImpact();
    await ref.read(checkInNotifierProvider.notifier).checkIn();
    if (!context.mounted) return;
    final newStreak = currentStreak + 1;
    // 显示庆祝 overlay
    _showCelebrationOverlay(context, _celebrationFor(newStreak));
    // 打卡成功：取消 soft 提醒 + snooze
    try {
      await ref.read(notificationServiceProvider).cancelSoftReminder();
      await ref.read(notificationServiceProvider).cancelAllSnoozes();
    } catch (_) {}
    // v0.10 (Round 4): 打卡后跑 SafetyWatch (也可能触发,例如打卡是补卡)
    unawaited(_runAfterCheckIn());
    // AI 关怀：打卡后评估是否触发（rule-based）
    unawaited(_fireCareEngine());
  }

  /// 打卡后跑 SafetyWatch
  ///
  /// 设计：用户刚补卡理论上不该再触发,但系统可能因为日期错乱或打卡未及时入库
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
    } catch (_) {}
  }

  /// CareEngine 触发（rule-based）
  Future<void> _fireCareEngine() async {
    try {
      final all = await ref.read(checkInRepositoryProvider).watchAll().first;
      final trigger =
          CareEngine.evaluate(checkIns: all, now: DateTime.now());
      if (!trigger.shouldFire) return;
      final notif = ref.read(notificationServiceProvider);
      await CareEngine.fire(trigger, notif);
    } catch (_) {
      // 静默失败，不打扰用户
    }
  }

  /// Snooze 5min: 调度 5min 后的一次性本地通知
  ///
  /// 用 medicationId=0 表示"通用打卡提醒 snooze"（避开真实 med id）
  Future<void> _snooze5Min(BuildContext context) async {
    HapticFeedback.lightImpact();
    try {
      await ref.read(notificationServiceProvider).snoozeOnce(
            medicationId: 0, // 0 = 通用 snooze
            minutes: 5,
            title: '⏰ 该打卡了（5min 后）',
            body: '刚才你点了"snooze"，是时候点一下 = 打卡了',
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('好，5 分钟后会再提醒你 👌'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTokens.error,
          content: Text('Snooze 失败：${e.toString().split('\n').first}'),
        ),
      );
    }
  }

  String _celebrationFor(int streak) {
    if (streak == 1) return '已记录！第 1 天 🌱';
    if (streak < 7) return '已记录！连击 $streak 天 🌿';
    if (streak < 30) return '已记录！连击 $streak 天 🌳';
    if (streak < 100) return '已记录！$streak 天连击 🌲';
    return '已记录！$streak 天——你太厉害了 🏔️';
  }

  /// 顶部 overlay 庆祝（短暂显示，自动消失）
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

  /// 计算下次提醒时间（每天 20:00）
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
/// 用户点了主打卡按钮 = 信任 app 在后台提醒。提醒没设上必须让用户知道。
/// 显示原因 + "去系统设置"按钮 + 可关闭。
class _NotificationFailureBanner extends StatefulWidget {
  final String? error;
  const _NotificationFailureBanner({this.error});

  @override
  State<_NotificationFailureBanner> createState() =>
      _NotificationFailureBannerState();
}

class _NotificationFailureBannerState extends State<_NotificationFailureBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: AppTokens.spacingSm),
      padding: const EdgeInsets.all(AppTokens.spacingMd),
      decoration: BoxDecoration(
        color: AppTokens.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(color: AppTokens.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_off_outlined,
              color: AppTokens.warning, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '提醒没设上,可能错过打卡。请到系统设置允许通知。',
              style: TextStyle(
                fontSize: AppTokens.fontSizeCaption,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => setState(() => _dismissed = true),
            tooltip: '知道了',
          ),
        ],
      ),
    );
  }
}
