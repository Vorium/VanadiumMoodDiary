// home_care_engine_dispatcher.dart — Home 主页 care engine dispatcher controller
//
// v0.30 R108 (P1 home_page_state 拆): 抽打卡后 care engine 编排
// 到独立 controller (R107 报告 §3.2 home_page_state god class 拆 3 controller
// 方案, 4 视角共识: emil + spen + architecture + bottom-up)。
//
// 拆出原因:
// - 原 home_page_state 597 行单 ConsumerState 类, 含 9 业务方法
// - _runAfterCheckIn (30L) + _fireCareEngine (89L) = 119L 跟 safety + care
//   engine 业务强相关, 跟 build() / onCheckIn 编排解耦
// - 抽出后 care engine 业务可在 widget test 里直接覆盖 (mock ref 即可),
//   跟 _onCheckIn 主流程解耦
//
// 公共 API:
// - [HomeCareEngineDispatcher] — controller class, 接受 [WidgetRef]
// - [runAfterCheckIn] — 打卡后跑一次 SafetyWatch (异步, 含 SnackBar 副作用)
// - [fireCareEngine] — 打卡后跑 FireCareStrategyUseCase (异步, 含通知副作用)
//
// 跟 state class 协作:
// - [runAfterCheckIn] 需要 BuildContext (l10n + SnackBar) + mounted 闭包
//   (异步边界后判 widget 是否还活着) — 由 state class 传入
// - [fireCareEngine] 不需要 context / mounted (纯 ref 业务 + 通知副作用),
//   state class 直接 await / unawaited 即可
//
// 4 层架构纯度: 本文件 import `flutter` (BuildContext) + `flutter_riverpod`
// (WidgetRef), 跟原 home_page_state 一样在 presentation 层, 0 violation。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/data/services/safety_watch_service.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare/domain/usecases/fire_care_strategy.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/care_strategy_providers.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/legal_consent_provider.dart';
import 'package:chroniccare/presentation/providers/service_providers.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';

/// v0.30 R108 (P1 home_page_state 拆): 打卡后 SafetyWatch + CareEngine 编排
///
/// 抽自原 home_page_state._runAfterCheckIn (30L) + _fireCareEngine (89L) = 119L。
class HomeCareEngineDispatcher {
  /// v0.32 R110 (B1-1): care push 固定带 id 基数 (5M+ 带,
  /// 远离 med [2000,202000) / refill [6000,206000) / snooze [300000,2300000))
  static const int kCarePushBaseId = 5000010;

  final WidgetRef ref;

  HomeCareEngineDispatcher(this.ref);

  /// 打卡后跑 SafetyWatch
  ///
  /// 设计：用户刚补卡理论上不该再触发，但系统可能因为日期错乱或打卡未及时入库
  /// 仍认为"长期没打卡",所以这里也调一次。
  ///
  /// [isMounted] 是 mounted 闭包, async 边界后调用判 widget 是否还活着。
  Future<void> runAfterCheckIn({
    required BuildContext context,
    required bool Function() isMounted,
  }) async {
    try {
      // v0.27 round 60 (P0-3 修正): 传 l10n, 通知 3 态分流 + UI 文案走 l10n
      final l10n = AppLocalizations.of(context);
      final result =
          await ref.read(safetyWatchServiceProvider).onCheckIn(l10n: l10n);
      if (!isMounted()) return;
      if (result.kind == SafetyCheckKind.alerted) {
        // 罕见：打卡后仍触发告警
        // v0.21 Round 22 (P0-10 修复): 走 AppSnackBar.error 集中器
        // R99 (BUG-1): 同 _runSafetyCheck, 走 displayMessageL10n(l10n) 翻译版
        AppSnackBar.showError(
          context,
          action: '⚠️ ${result.displayMessageL10n(l10n)}',
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
  /// - R100 (F-4/N-2): `CareEngine.evaluate` / `CareEngine.fire` legacy API
  ///   已删 (v0.28 起承诺, 拖到本轮落地), 编排全走 use case。
  Future<void> fireCareEngine() async {
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
          // v0.32 R110 (B1-1): 原 8000+index 落入 medication/refill cancel
          // 区间被误杀, 迁 5M+ 固定带 (跟 safety/assessment/mood/badge 同带)
          final id = kCarePushBaseId + result.strategy.index;
          await notif.showNow(id: id, title: result.title, body: result.body);
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
}
