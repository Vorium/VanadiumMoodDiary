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
// 1.1.0 round 4 (emotion-first refactor): safety rerun 路径整摘 —
// scheduleSafetyRerun action / reason=safety 分支 / race guard Timer /
// dispose 全删 (safety check 已从主页移除)。
//
// 公共 API:
// - [HomeDeepLinkHandler] — controller class, 接受 [WidgetRef] 用于 provider 读
// - [DeepLinkAction] enum — inspect() 返回的动作类型
// - [DeepLinkDecision] data class — inspect() 返回的完整决策 (含 nextLifecycle)
// - [AutofireResult] data class — autofireMedicationCheckIn() 返回结果
// - [inspect] — 解析 deep link URI + 决定下一步动作 (同步)
// - [autofireMedicationCheckIn] — 实际自动打卡 (异步, 返回结果给 caller 决定是否显示庆祝)
// - [showMedicationHint] — 显示"该吃了"提示 (同步)
// - [clearQuery] — 清除 query 防止刷新重复触发
//
// 跟 state class 协作:
// - state class 传 [HomeLifecycleState] 给 inspect(), controller 算 nextLifecycle
//   返回, state class 应用: `_lifecycle = decision.nextLifecycle`
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

import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
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
/// _showMedicationHint (90L)。1.1.0 round 4: race guard Timer 删除
/// (safety rerun 路径已摘)。
class HomeDeepLinkHandler {
  final WidgetRef ref;

  HomeDeepLinkHandler(this.ref);

  /// v0.11 (Round 5): 处理 ?medId=N&autofire=1
  ///
  /// 用户点 medication 通知 → 路由跳到 /check-in/medication/N
  /// → redirect 到 /?medId=N&autofire=1 → home_page 收到参数
  /// → 这里自动打卡 + 显示庆祝
  ///
  /// 抽 controller 后设计:
  /// - 解析 [uri] + [currentLifecycle] 同步返回 [DeepLinkDecision]
  /// - state class 应用 nextLifecycle + 按 action 路由 (调
  ///   autofireMedicationCheckIn / showMedicationHint)
  /// - 不做实际副作用, 副作用都在对应 method 里 (打卡 + hint)
  ///
  /// 1.1.0 round 4: reason=safety 分支删除 (safety check 已从主页移除),
  /// lifecycle 2 态, 已处理 guard 只查 deepLinkHandled。
  DeepLinkDecision inspect({
    required Uri uri,
    required HomeLifecycleState currentLifecycle,
  }) {
    if (currentLifecycle == HomeLifecycleState.deepLinkHandled) {
      return DeepLinkDecision(
        nextLifecycle: currentLifecycle,
        action: DeepLinkAction.noop,
      );
    }
    final medIdParam = uri.queryParameters['medId'];
    final autofire = uri.queryParameters['autofire'] == '1';
    if (medIdParam == null) {
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
      // v0.32 round 8 (R112 卫生): 加 context.mounted guard 消
      // use_build_context_synchronously (isMounted 闭包 analyzer 不识别)
      if (!isMounted() || !context.mounted) {
        return const AutofireResult(success: false);
      }
      final medName =
          med?.name ?? AppLocalizations.of(context).homeAutofireFallbackName;
      // v0.22 round 30 (emil P2-4): 走 Haptics.success 集中器
      // (打卡成功触感,emil 频度: tens/day)
      // R97-P1-12: unawaited 显式标记 fire-and-forget (haptic 不阻塞 UI)
      unawaited(Haptics.success());
      return AutofireResult(success: true, medName: medName);
    } catch (e) {
      // v0.32 round 8 (R112 卫生): context.mounted guard 消 lint
      if (!isMounted() || !context.mounted) {
        return const AutofireResult(success: false);
      }
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
  /// R114 BUG 8: 修前直接 `homeMedHint(medId)` → 用户看到 "准备打卡药物
  /// #5" 裸数据库 id。修: 从 medicationsProvider 缓存查药名 (跟
  /// autofireMedicationCheckIn 同款), 查不到 fallback 通用名
  /// (homeAutofireFallbackName), 不再泄漏内部 id。
  void showMedicationHint(int medId, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final meds =
        ref.read(medicationsProvider).value ?? const <MedicationEntity>[];
    final med = meds.where((m) => m.id == medId).firstOrNull;
    final name = med?.name ?? l10n.homeAutofireFallbackName;
    AppSnackBar.showInfo(
      context,
      l10n.homeMedHint(name),
    );
  }

  /// v0.30 R108 (P1 home_page_state 拆): 清除 query 防止刷新页面重复触发
  ///
  /// 抽自原 home_page_state._autofireMedicationCheckIn 末尾
  /// `GoRouter.of(context).go('/')`。
  void clearQuery(BuildContext context) {
    GoRouter.of(context).go('/');
  }
}
