// home_deep_link_handler.dart — Home 主页 deep link 处理 controller
//
// v0.30 R108 (P1 home_page_state 拆): 抽 deep link + autofire + hint 业务
// 到独立 controller (R107 报告 §3.2 home_page_state god class 拆 3 controller
// 方案, 4 视角共识: emil + spen + architecture + bottom-up)。
//
// 拆出原因:
// - 原 home_page_state 597 行单 ConsumerState 类, 含 9 业务方法
// - _handleDeepLink (54L) + _autofireMedicationCheckIn (30L) + _showMedicationHint (5L)
//   = 89L 跟 deep link 业务强相关, 但跟 state class 的 _lifecycle enum 状态机
//   紧耦合, 不抽出来 god class 缩不到目标 < 350L
// - 抽出后 deep link 业务可在 widget test 里直接覆盖 (mock ref 即可),
//   跟 runSafetyCheck / build 解耦
//
// 公共 API:
// - [HomeDeepLinkHandler] — controller class, 接受 [WidgetRef] 用于 provider 读
// - [DeepLinkAction] enum — inspect() 返回的动作类型
// - [DeepLinkDecision] data class — inspect() 返回的完整决策 (含 nextLifecycle)
// - [AutofireResult] data class — autofireMedicationCheckIn() 返回结果
// - [inspect] — 解析 deep link URI + 决定下一步动作 (同步)
// - [autofireMedicationCheckIn] — 实际自动打卡 (异步, 返回结果给 caller 决定是否显示庆祝)
// - [showMedicationHint] — 显示"该吃了"提示 (同步)
// - [scheduleRaceTimer] — 调度 race guard Timer (替代原 state class _deepLinkRaceTimer)
// - [dispose] — 取消 race Timer, 防 leak
//
// 跟 state class 协作:
// - state class 传 [HomeLifecycleState] 给 inspect(), controller 算 nextLifecycle
//   返回, state class 应用: `_lifecycle = decision.nextLifecycle`
// - race Timer 触发回调走 state class 的 [onRaceTimerFire] (闭包) — 检查 mounted
//   + 调 state class 的 _runSafetyCheck(force: true)
// - autofire 成功后返回 [AutofireResult] 含 medName, state class 据此调
//   celebration controller 显示庆祝 overlay
//
// 4 层架构纯度: 本文件 import `flutter` (Material / BuildContext) +
// `flutter_riverpod` (WidgetRef), 跟原 home_page_state 一样在 presentation
// 层, 0 violation (cross_feature 守门员覆盖)。
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/pages/home/home_page.dart'
    show HomeLifecycleState;
import 'package:chroniccare/presentation/providers/check_in_notifier.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/feedback.dart' show Haptics;

/// v0.30 R108 (P1 home_page_state 拆): deep link 解析后决定做什么动作
enum DeepLinkAction {
  /// 无事可做 (lifecycle 已处理 / query 解析失败 / 路径不匹配)
  noop,

  /// reason=safety 路径: 调度 race guard Timer, 到点重跑 safety check
  scheduleSafetyRerun,

  /// medId 路径 + autofire=1: 实际打卡该药
  autofire,

  /// medId 路径 + 无 autofire: 显示"该吃了"提示
  showHint,
}

/// v0.30 R108 (P1 home_page_state 拆): deep link 解析结果
///
/// 含 [nextLifecycle] (state class 应用) + [action] (state class 路由) +
/// [medId] (autofire / showHint 用)。
class DeepLinkDecision {
  final HomeLifecycleState nextLifecycle;
  final DeepLinkAction action;
  final int? medId;

  const DeepLinkDecision({
    required this.nextLifecycle,
    required this.action,
    this.medId,
  });
}

/// v0.30 R108 (P1 home_page_state 拆): autofire 结果
///
/// 成功时 [medName] 是药物名 (供 caller 显示庆祝), 失败时 [medName] 为 null。
class AutofireResult {
  final bool success;
  final String? medName;

  const AutofireResult({required this.success, this.medName});
}

/// v0.30 R108 (P1 home_page_state 拆): Home 主页 deep link handler
///
/// 抽自原 home_page_state._handleDeepLink + _autofireMedicationCheckIn +
/// _showMedicationHint + _deepLinkRaceTimer (90L)。
class HomeDeepLinkHandler {
  final WidgetRef ref;

  /// v0.27 round 63 (P1-4 修复): race guard Timer
  ///
  /// 之前 `_handleDeepLink` 用 `await Future<void>.delayed(...)`, dispose 后
  /// 回调 fire 触发 setState 撞 defunct widget。改 Timer + dispose cancel,
  /// 跟 `_celebrationTimer` 模式一致 (R62 P1-6 同样修)。
  Timer? _raceTimer;

  HomeDeepLinkHandler(this.ref);

  /// v0.11 (Round 5): 处理 ?medId=N&autofire=1
  ///
  /// 用户点 medication 通知 → 路由跳到 /check-in/medication/N
  /// → redirect 到 /?medId=N&autofire=1 → home_page 收到参数
  /// → 这里自动打卡 + 显示庆祝
  ///
  /// 抽 controller 后设计:
  /// - 解析 [uri] + [currentLifecycle] 同步返回 [DeepLinkDecision]
  /// - state class 应用 nextLifecycle + 按 action 路由 (调 scheduleRaceTimer /
  ///   autofireMedicationCheckIn / showMedicationHint)
  /// - 不做实际副作用, 副作用都在对应 method 里 (race Timer 调度 + 打卡 + hint)
  ///
  /// v0.27 round 64: lifecycle guard 改走 _lifecycle 状态机
  /// bothHandled 也算"已处理"(_handleDeepLink 路径 + safety check 都完成)
  DeepLinkDecision inspect({
    required Uri uri,
    required HomeLifecycleState currentLifecycle,
  }) {
    if (currentLifecycle == HomeLifecycleState.deepLinkHandled ||
        currentLifecycle == HomeLifecycleState.bothHandled) {
      return DeepLinkDecision(
        nextLifecycle: currentLifecycle,
        action: DeepLinkAction.noop,
      );
    }
    final medIdParam = uri.queryParameters['medId'];
    final autofire = uri.queryParameters['autofire'] == '1';
    if (medIdParam == null) {
      // 不是 deep link 跳来的，处理 safety reason
      final reason = uri.queryParameters['reason'];
      if (reason == 'safety') {
        // 强制重跑一次 (从通知跳来的场景)
        // v0.14 fix: 用独立 flag,不受 _safetyCheckTriggered 影响
        // 旧实现 `!_safetyCheckTriggered` 在第一跑已起来后永远 false
        // v0.27 round 64: 改用 _lifecycle 状态机,onRerunRequested() 内部
        // 保证 safetyRerunRequested / bothHandled 重复请求 idempotent
        if (currentLifecycle == HomeLifecycleState.safetyRerunRequested) {
          return DeepLinkDecision(
            nextLifecycle: currentLifecycle,
            action: DeepLinkAction.noop,
          );
        }
        return DeepLinkDecision(
          nextLifecycle: currentLifecycle.onRerunRequested(),
          action: DeepLinkAction.scheduleSafetyRerun,
        );
      }
      return DeepLinkDecision(
        nextLifecycle: currentLifecycle,
        action: DeepLinkAction.noop,
      );
    }
    final nextLifecycle = currentLifecycle.onDeepLinkHandled();
    final medId = int.tryParse(medIdParam);
    if (medId == null) {
      return DeepLinkDecision(
        nextLifecycle: nextLifecycle,
        action: DeepLinkAction.noop,
      );
    }
    return DeepLinkDecision(
      nextLifecycle: nextLifecycle,
      action: autofire ? DeepLinkAction.autofire : DeepLinkAction.showHint,
      medId: medId,
    );
  }

  /// v0.30 R108 (P1 home_page_state 拆): 实际自动打卡该药
  ///
  /// 抽自原 home_page_state._autofireMedicationCheckIn (30L)。
  /// 走 notifier.checkIn(medicationId:) → 返回 [AutofireResult] (含 medName),
  /// 由 caller (state class) 决定是否显示庆祝 overlay + 清除 query。
  ///
  /// [isMounted] 是 mounted 闭包, async 边界后调用判 widget 是否还活着。
  Future<AutofireResult> autofireMedicationCheckIn({
    required int medId,
    required bool Function() isMounted,
    required BuildContext context,
  }) async {
    try {
      await ref
          .read(checkInNotifierProvider.notifier)
          .checkIn(medicationId: medId);
      if (!isMounted()) return const AutofireResult(success: false);
      // P0 fix: 复用 provider 树已缓存的药物数据，不再重复查库
      final meds = ref.read(medicationsProvider).value ?? [];
      final med = meds.where((m) => m.id == medId).firstOrNull;
      if (!isMounted()) return const AutofireResult(success: false);
      final medName =
          med?.name ?? AppLocalizations.of(context).homeAutofireFallbackName;
      // v0.22 round 30 (emil P2-4): 走 Haptics.success 集中器
      // (打卡成功触感,emil 频度: tens/day)
      // R97-P1-12: unawaited 显式标记 fire-and-forget (haptic 不阻塞 UI)
      unawaited(Haptics.success());
      return AutofireResult(success: true, medName: medName);
    } catch (e) {
      if (!isMounted()) return const AutofireResult(success: false);
      AppSnackBar.showError(
        context,
        action: AppLocalizations.of(context).snackbarActionAutoCheckin,
        error: e,
      );
      return const AutofireResult(success: false);
    }
  }

  /// v0.30 R108 (P1 home_page_state 拆): 显示"该吃了"提示
  ///
  /// 抽自原 home_page_state._showMedicationHint (5L)。
  void showMedicationHint(int medId, BuildContext context) {
    AppSnackBar.showInfo(
      context,
      AppLocalizations.of(context).homeMedHint(medId),
    );
  }

  /// v0.30 R108 (P1 home_page_state 拆): 调度 race guard Timer
  ///
  /// 抽自原 home_page_state._handleDeepLink 内部 _deepLinkRaceTimer 设置逻辑。
  /// Timer 触发时调 [onRaceTimerFire] (state class 闭包, 内含 mounted 检查 +
  /// _runSafetyCheck(force: true) 调用)。
  ///
  /// v0.27 round 63 (P1-4 修复): 用 Timer 替代 Future.delayed, 跟
  /// _celebrationTimer 模式一致。Future.delayed 不可 cancel, widget dispose
  /// 后 fire 触发 _runSafetyCheck 撞 defunct widget。
  void scheduleRaceTimer(VoidCallback onRaceTimerFire) {
    _raceTimer?.cancel();
    _raceTimer = Timer(
      AppTokens.kDeepLinkRaceGuard,
      () {
        // Timer 自身 cancel 已在 dispose 跑, 这里让 caller 负责 mounted 双重保险
        onRaceTimerFire();
        _raceTimer = null;
      },
    );
  }

  /// v0.30 R108 (P1 home_page_state 拆): dispose 取消 race Timer
  ///
  /// 防 widget dispose 后 race guard timer 仍 fire 调 state class 方法
  /// 撞 defunct widget。
  void dispose() {
    _raceTimer?.cancel();
    _raceTimer = null;
  }

  /// v0.30 R108 (P1 home_page_state 拆): 清除 query 防止刷新页面重复触发
  ///
  /// 抽自原 home_page_state._autofireMedicationCheckIn 末尾
  /// `GoRouter.of(context).go('/')`。
  void clearQuery(BuildContext context) {
    GoRouter.of(context).go('/');
  }
}
