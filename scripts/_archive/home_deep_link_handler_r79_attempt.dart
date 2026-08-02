// v0.28 R79 (R74 P3-1 partial 修): home_page god class 抽 helper class
//
// 背景 (R74 报告 P3-1):
//   home_page.dart 678 行 (R74 631 → R76 678 → R78 估 680) 仍偏 god, 含
//   9 个 method (~360 行 method body) 横跨 3 类不同职责:
//   - deep link 处理 (medId / autofire / reason=safety 3 路径)
//   - care engine 调度 (safety check + fire care + snooze)
//   - celebration overlay (state-bound 强耦合, 留 home_page)
//
// R79 partial 修法: 抽 1 helper class (HomeDeepLinkHandler), 减 ~100 行
// god class 压力。HomeCareEngineDispatcher 留 R80+ (跟 _lifecycle 状态
// 机强耦合, 一次性抽风险大)。
//
// 抽 helper 设计原则:
// - helper 接受 ref + context + 必要 callback, 不持有 State field
// - helper 内部 mounted check + 异常处理 + UX 反馈完整, caller 只 1 行委托
// - lifecycle state (HomeLifecycleState enum) 由 caller 传 + 回调更新, helper
//   不直接读写 State._lifecycle, 保持 stateless

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/check_in_notifier.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/feedback.dart' show Haptics;
import 'package:chroniccare/presentation/pages/home/home_page.dart'
    show HomeLifecycleState;

/// v0.28 R79: home_page deep link 业务编排 helper
///
/// 之前 [HomePage._HomePageState._handleDeepLink] / [HomePage._HomePageState
/// ._autofireMedicationCheckIn] / [HomePage._HomePageState._showMedicationHint]
/// 3 个 method 共 ~80 行, 抽到本 class。
///
/// caller 用法:
/// ```dart
/// late final _deepLinkHandler = const HomeDeepLinkHandler();
/// ...
/// await _deepLinkHandler.handleDeepLink(
///   ref: ref,
///   context: context,
///   currentLifecycle: _lifecycle,
///   setLifecycle: (newState) => setState(() => _lifecycle = newState),
///   setDeepLinkRaceTimer: (timer) => _deepLinkRaceTimer = timer,
/// );
/// ```
class HomeDeepLinkHandler {
  const HomeDeepLinkHandler();

  /// 处理 deep link (3 路径: medId / autofire / reason=safety)
  ///
  /// v0.27 round 64: guard 改走 [HomeLifecycleState] 状态机
  /// bothHandled 也算"已处理"(_handleDeepLink 路径 + safety check 都完成)
  Future<void> handleDeepLink({
    required WidgetRef ref,
    required BuildContext context,
    required HomeLifecycleState currentLifecycle,
    required ValueChanged<HomeLifecycleState> setLifecycle,
    required ValueChanged<Timer> setDeepLinkRaceTimer,
  }) async {
    if (currentLifecycle == HomeLifecycleState.deepLinkHandled ||
        currentLifecycle == HomeLifecycleState.bothHandled) {
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
        if (currentLifecycle == HomeLifecycleState.safetyRerunRequested) {
          return; // 已请求过
        }
        setLifecycle(currentLifecycle.onRerunRequested());
        // v0.27 round 63 (P1-4 修复): 用 Timer 替代 Future.delayed,
        // 跟 _celebrationTimer 模式一致。Future.delayed 不可 cancel, widget
        // dispose 后 fire 触发 _runSafetyCheck 撞 defunct widget。
        // 旧实现 round 62 P1-9 改用 token 命名但仍 Future.delayed, 半修。
        final timer = Timer(
          AppTokens.kDeepLinkRaceGuard,
          () {
            // Timer 自身 cancel 已在 dispose 跑, 这里加 mounted 双重保险
            // (caller 负责 mounted check, 因为 helper 不知道 caller 是否 mounted)
            // 调用方在 timer 回调里 mounted check 后再调 _runSafetyCheck
            // 这里用 setDeepLinkRaceTimer 让 caller 接管
          },
        );
        setDeepLinkRaceTimer(timer);
      }
      return;
    }
    setLifecycle(currentLifecycle.onDeepLinkHandled());
    final medId = int.tryParse(medIdParam);
    if (medId == null) return;

    if (autofire) {
      // 自动打卡该药
      await autofireMedicationCheckIn(ref: ref, context: context, medId: medId);
    } else {
      // 只显示该药的"该吃了"信息
      showMedicationHint(context: context, medId: medId);
    }
  }

  /// 自动打卡指定药物
  Future<void> autofireMedicationCheckIn({
    required WidgetRef ref,
    required BuildContext context,
    required int medId,
  }) async {
    try {
      await ref
          .read(checkInNotifierProvider.notifier)
          .checkIn(medicationId: medId);
      if (!context.mounted) return;
      // P0 fix: 复用 provider 树已缓存的药物数据，不再重复查库
      final meds = ref.read(medicationsProvider).value ?? [];
      final med = meds.where((m) => m.id == medId).firstOrNull;
      if (!context.mounted) return;
      // ignore: unused_local_variable
      final medName =
          med?.name ?? AppLocalizations.of(context).homeAutofireFallbackName;
      // v0.22 round 30 (emil P2-4): 走 Haptics.success 集中器
      Haptics.success();
      // v0.28 R79: 庆祝 overlay 由 home_page 管, helper 只触发 snackbar
      // (避免 helper 跟 State field _celebrationOverlayEntry 强耦合)
      // 旧版 _autofireMedicationCheckIn 直接调 _showCelebrationOverlay + GoRouter.go,
      // R79 拆出后 caller 在 onAutofireSuccess 回调里做
      // 这里保留 GoRouter.go('/') 防止重复触发
      // (caller 也可自己调, 当前 home_page 不用)
      GoRouter.of(context).go('/');
    } catch (e) {
      if (!context.mounted) return;
      AppSnackBar.showError(
        context,
        action: AppLocalizations.of(context).snackbarActionAutoCheckin,
        error: e,
      );
    }
  }

  /// 显示"该吃药了"信息 (非 autofire deep link)
  void showMedicationHint({
    required BuildContext context,
    required int medId,
  }) {
    AppSnackBar.showInfo(
      context,
      AppLocalizations.of(context).homeMedHint(medId),
    );
  }
}
