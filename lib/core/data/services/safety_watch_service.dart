import 'dart:async';
import 'dart:convert';

import 'package:chroniccare/domain/entities/contact_entity.dart';
import 'package:chroniccare/domain/entities/user_profile_entity.dart';
import 'package:chroniccare/domain/repositories/check_in_repository.dart';
import 'package:chroniccare/domain/repositories/contact_repository.dart';
import 'package:chroniccare/domain/repositories/safety_alert_sender.dart';
import 'package:chroniccare/domain/repositories/user_profile_repository.dart';
import 'package:chroniccare/core/data/services/pii_safe_log.dart';
import 'package:chroniccare/core/data/services/safety_config_service.dart';
import 'package:chroniccare/core/data/feature_flags.dart';
import 'package:chroniccare/domain/logic/safety_detector.dart';
import 'package:chroniccare/domain/usecases/check_safety.dart';
import 'package:chroniccare/domain/usecases/dispatch_safety_alert.dart';

// R101: SafetyCheckKind 移到 domain 层 safety_detector.dart, 这里 re-export
export 'package:chroniccare/domain/logic/safety_detector.dart'
    show SafetyCheckKind;

/// "安全开关" 服务 — 死了么/撸了么 思路
///
/// v0.10 (Round 4) 新增：
/// 精神心理患者服药依从性问题里，**最危险的是完全停药后没人发现**。
/// 本服务检测"连续 N 天没打卡"，触发：
/// 1. 给所有启用的紧急联系人发短信/邮件
/// 2. 推一条高优先级本地通知（用户可能只是忘了打卡，提示后能补）
/// 3. 写入 audit log，避免短时间内重复打扰
///
/// 设计取舍：
/// - **默认关闭**（侵入性功能，用户主动开启）
/// - 用 SharedPreferences 存配置（避免动 schema 迁移）
/// - 不在每次 check-in 都发，只在**超过阈值**才发
/// - 同一天最多触发一次
///
/// v0.25 round 57 (spen P1 #12 god class 拆分): 拆 2 sub
///   - SafetyConfigService: 8 个 SharedPreferences 配置 API
///   - SafetyAlertDispatcher:  SMS + 本地通知 + audit log
/// safety_watch_service 退化为 facade, 协调 _checkAndAlert 核心
///
/// v0.27 round 64 (spen P1-12 收尾): 抽 SafetyDetector 纯函数类
///   - 8 类 early-return decision 全部移到 detector (纯函数, 0 副作用)
///   - facade 仅负责: 加载 inputs (config + repos + stream) + 调 detector +
///     委派 dispatcher
///   - `_checkAndAlert` 122 行 → ~40 行 facade + 2 个 < 20 行 helper
class SafetyWatchService {
  // v0.25 round 57: 旧 key 常量移到 SafetyConfigService 内部 (private)
  // 保留 defaultThresholdDays 静态常量兼容旧调用方
  static const int defaultThresholdDays = 2;

  final CheckInRepository _checkInRepo;
  final ContactRepository _contactRepo;
  final UserProfileRepository _userProfileRepo;
  final DispatchSafetyAlertUseCase _dispatchUseCase;

  /// v0.32 R112 (AR-18): 判定接线 CheckSafetyUseCase (之前直接调
  ///   SafetyDetector.detect 绕过 usecase = 死代码)。可选注入便于测试。
  final CheckSafetyUseCase _checkSafetyUseCase;

  /// v0.25 round 57: 2 个 sub
  late final SafetyConfigService _config = SafetyConfigService();
  // v0.32 R109 (god class 拆 round 2): 删 SafetyAlertDispatcher, 改调
  //   DispatchSafetyAlertUseCase (domain). 业务编排 (feature flag 守卫 +
  //   body 计算) 在 use case, service 只做 l10nResolver tear-off + 委派.

  /// v0.23 round 38 (P0-3 fix): _contactRepo.watchAll().first 的 timeout 时长
  /// 默认 5s,测试可注入短值(50ms)避免 5s 等待
  final Duration _contactWatchTimeout;

  SafetyWatchService({
    required CheckInRepository checkInRepo,
    required ContactRepository contactRepo,
    required UserProfileRepository userProfileRepo,
    required DispatchSafetyAlertUseCase dispatchUseCase,
    CheckSafetyUseCase checkSafetyUseCase = const CheckSafetyUseCase(),
    Duration contactWatchTimeout = const Duration(seconds: 5),
  })  : _checkInRepo = checkInRepo,
        _contactRepo = contactRepo,
        _userProfileRepo = userProfileRepo,
        _dispatchUseCase = dispatchUseCase,
        _checkSafetyUseCase = checkSafetyUseCase,
        _contactWatchTimeout = contactWatchTimeout;

  // ============== 配置 API 已下沉到 SafetyConfigService ==============
  //
  // v0.27 round 61 (P1-12 god class 拆分收尾): 之前 8 个 facade 配置 method
  // (`isEnabled` / `setEnabled` / `getThresholdDays` / `setThresholdDays` /
  // `getDoNotDisturb` / `setDoNotDisturb` / `getLastAlertAt` / `setLastAlertAt`)
  // 全删, caller 改用 `safetyConfigServiceProvider` 直接拿
  // [SafetyConfigService] 调。
  //
  // facade 仅保留 3 个触发入口 (`onAppStart` / `onCheckIn` / `checkNow`)
  // + `_checkAndAlert` 编排, 跟 R57 design 一致 (sub-service 自包含, facade
  // 只协调)。

  // ============== 触发入口 ==============

  /// App 启动时调用（main.dart 调）
  ///
  /// v0.27 round 60 (P0-3 修正): 加 `l10n` 参数, 修正 P0-3 通知 3 态分流
  /// (NotificationService.showSafetyAlert 需要 l10n 走 i18n key)。
  /// 修正前 hardcode "已自动通知紧急联系人", 即使 SMS mock / 失败也这么说,
  /// 对精神心理患者形成"谎言"。修正后 3 态明确。
  ///
  /// v0.32 R112 (AR-16): l10n 改 `SafetyAlertL10nResolver` tear-off 闭包
  /// (caller 从 AppLocalizations 注入), data 0 依赖 l10n/ 生成 ARB。
  ///
  /// v0.27 round 67 (C-7 重构): FeatureFlags.bootReceiverEnabled=false 时
  /// 跳过 rescheduleAll, 避免 v0.28 WorkManager 完善之前 BootReceiver crash。
  Future<SafetyCheckResult> onAppStart({
    required SafetyAlertL10nResolver l10nResolver,
  }) async {
    if (!FeatureFlags.bootReceiverEnabled) {
      piiSafeLog(
        'SafetyWatchService',
        'BootReceiver disabled, skip rescheduleAll',
      );
      return const SafetyCheckResult(kind: SafetyCheckKind.disabled);
    }
    return _checkAndAlert(trigger: 'app_start', l10nResolver: l10nResolver);
  }

  /// 打卡成功后调用（home_page 调）
  Future<SafetyCheckResult> onCheckIn({
    required SafetyAlertL10nResolver l10nResolver,
  }) async {
    final result =
        await _checkAndAlert(trigger: 'check_in', l10nResolver: l10nResolver);
    if (result.kind == SafetyCheckKind.alerted) {
      piiSafeLog(
        'SafetyWatchService',
        '⚠️ 用户打卡后仍触发告警 — 可能本地时间错乱或打卡未及时入库',
      );
    }
    return result;
  }

  /// 主动查一次（settings_page 调试按钮 / 测试用）
  ///
  /// [now] 用于测试注入，生产环境为 null → 内部取 `DateTime.now()`。
  /// 不接受 `now` 时跨 midnight(00:00-06:00)会让 `DateTime.now().subtract(hours: 6)`
  /// 落到前一天,`_daysBetween` 算成 1,触发 flaky test。
  Future<SafetyCheckResult> checkNow({
    required SafetyAlertL10nResolver l10nResolver,
    DateTime? now,
  }) async {
    return _checkAndAlert(
      trigger: 'manual',
      now: now,
      l10nResolver: l10nResolver,
    );
  }

  // ============== 核心 facade (R64 拆分后) ==============

  /// v0.27 round 64: facade 核心 — 加载 inputs + 调 detector + 委派 dispatcher
  ///
  /// 拆分前 122 行混合 8 类判定 + 3 类 sub-service 协调, god method。
  /// 拆分后:
  /// - 7 段 early-return 判定全部移到 [SafetyDetector.detect] (纯函数)
  /// - 加载 inputs (config / repos / stream) 保留在 facade (有副作用)
  /// - 委派 dispatcher 抽 [_dispatchLostContact]
  /// - stream + timeout 抽 [_loadContacts]
  ///
  /// 2026-07-31 联系人软隐藏 (病耻感 + 失联通信业务暂停):
  /// 入口加 [FeatureFlags.emergencyContactEnabled] 守卫 — false 时整个
  /// facade 直接返 disabled, 不查 config / 不查 contacts / 不发任何东西。
  /// 3 个入口 (`onAppStart` / `onCheckIn` / `checkNow`) 都过这道关。
  Future<SafetyCheckResult> _checkAndAlert({
    required String trigger,
    DateTime? now,
    required SafetyAlertL10nResolver l10nResolver,
  }) async {
    // Feature flag 早返 — 暂停整个失联通知业务
    if (!FeatureFlags.emergencyContactEnabled) {
      return const SafetyCheckResult(kind: SafetyCheckKind.disabled);
    }
    try {
      // 1. 加载 inputs (副作用: I/O, DB, SharedPreferences, stream)
      final enabled = await _config.isEnabled();
      final threshold = await _config.getThresholdDays();
      // P0 fix: DB 级 LIMIT 1, 不全表扫描
      final lastCheckInAt =
          (await _checkInRepo.getLatestNormalCheckIn())?.timestamp;
      // P0-4 fix: 接受外部 now 注入,避免测试跨 midnight flake
      final effectiveNow = now ?? DateTime.now();
      final lastAlertAt = await _config.getLastAlertAt();
      final inDnd = await _config.isInDnd(effectiveNow);
      final profile = await _userProfileRepo.get();
      final contacts = await _loadContacts();

      // 2. 判定 (v0.32 R112 AR-18: 走 CheckSafetyUseCase, 替代直接调
      //    SafetyDetector.detect — usecase 从死代码变活)
      final decision = _checkSafetyUseCase(
        CheckSafetyInput(
          enabled: enabled,
          threshold: threshold,
          lastCheckInAt: lastCheckInAt,
          now: effectiveNow,
          lastAlertAt: lastAlertAt,
          inDnd: inDnd,
          profile: profile,
          contacts: contacts,
        ),
      );

      // 3. 委派 (Alert 走 dispatcher, 其余返 SafetyCheckResult)
      return _actOnDecision(
        decision: decision,
        trigger: trigger,
        lastCheckInAt: lastCheckInAt,
        effectiveNow: effectiveNow,
        profile: profile,
        contacts: contacts,
        l10nResolver: l10nResolver,
      );
    } catch (e, st) {
      piiSafeLog(
        'SafetyWatchService',
        '❌ SafetyWatch error: $e',
        error: e,
        stackTrace: st,
      );
      return SafetyCheckResult(
        kind: SafetyCheckKind.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// v0.27 round 64: 把 [SafetyDecision] 翻译成 `Future<SafetyCheckResult>`
  ///
  /// sealed class 8 leaf 走 switch expression 强制穷举, 新加 kind 时编译
  /// 失败提醒。仅 [SafetyDecisionAlert] 需要副作用 (调 dispatcher), 其余
  /// 直接构造 result 后包 Future。
  Future<SafetyCheckResult> _actOnDecision({
    required SafetyDecision decision,
    required String trigger,
    required DateTime? lastCheckInAt,
    required DateTime effectiveNow,
    required UserProfileEntity? profile,
    required List<ContactEntity> contacts,
    required SafetyAlertL10nResolver l10nResolver,
  }) async {
    return switch (decision) {
      SafetyDecisionDisabled() =>
        const SafetyCheckResult(kind: SafetyCheckKind.disabled),
      SafetyDecisionNoData() =>
        const SafetyCheckResult(kind: SafetyCheckKind.noData),
      SafetyDecisionOk(:final daysSinceLast) => SafetyCheckResult(
          kind: SafetyCheckKind.ok,
          daysSinceLast: daysSinceLast,
        ),
      SafetyDecisionAlertedToday(:final daysSinceLast) => SafetyCheckResult(
          kind: SafetyCheckKind.alertedToday,
          daysSinceLast: daysSinceLast,
        ),
      SafetyDecisionDndSuppressed(:final daysSinceLast) => SafetyCheckResult(
          kind: SafetyCheckKind.dndSuppressed,
          daysSinceLast: daysSinceLast,
        ),
      SafetyDecisionNoContacts(:final daysSinceLast) => SafetyCheckResult(
          kind: SafetyCheckKind.noContacts,
          daysSinceLast: daysSinceLast,
        ),
      // 7. 真触发 — 调 dispatcher (副作用), 拿 SmsDispatchOutcome 构 result
      SafetyDecisionAlert(:final daysSinceLast) => await _dispatchLostContact(
          trigger: trigger,
          lastCheckInAt: lastCheckInAt!,
          daysSinceLast: daysSinceLast,
          effectiveNow: effectiveNow,
          profile: profile!,
          contacts: contacts,
          l10nResolver: l10nResolver,
        ),
    };
  }

  /// v0.27 round 64: 失联告警实际发出去 (委派给 SafetyAlertDispatcher)
  ///
  /// 注: Dart switch expression 不支持 await, 所以从 [_actOnDecision] 单独
  /// 调。返回 `Future<SafetyCheckResult>` 跟原 facade 行为一致。
  ///
  /// v0.32 R109 (god class 拆 round 2): dispatcher 改 use case.
  /// use case 拿 `SafetyAlertSender` (abstract), service 把 l10nResolver
  /// 原样透传 (R112 AR-16: caller 注入 tear-off 闭包, data 0 依赖 ARB).
  Future<SafetyCheckResult> _dispatchLostContact({
    required String trigger,
    required DateTime lastCheckInAt,
    required int daysSinceLast,
    required DateTime effectiveNow,
    required UserProfileEntity profile,
    required List<ContactEntity> contacts,
    required SafetyAlertL10nResolver l10nResolver,
  }) async {
    final dispatched = await _dispatchUseCase(
      contacts: contacts,
      userName: profile.userName,
      daysSinceLast: daysSinceLast,
      lastCheckIn: lastCheckInAt,
      now: effectiveNow,
      trigger: trigger,
      l10nResolver: l10nResolver,
    );
    return SafetyCheckResult(
      kind: SafetyCheckKind.alerted,
      daysSinceLast: daysSinceLast,
      contactsNotified: dispatched.smsOk,
      contactsFailed: dispatched.smsFail,
      contactsMocked: dispatched.smsMock,
    );
  }

  /// v0.27 round 64: 加载联系人列表 (含 stream + timeout + 异常降级)
  ///
  /// v0.23 round 38 (P0-3 fix): 加 5s timeout + 异常降级. 之前
  /// `_contactRepo.watchAll().first` 在以下情况会 hang:
  ///   a) drift stream 内部异常 (罕见,通常是 DB lock)
  ///   b) stream 关闭 (没关闭 listener)
  /// 整个 `_checkAndAlert` 阻塞 → 失联检测核心路径失败 → SMS 通知永远不发出
  /// 修法: [_contactWatchTimeout] 默认 5s 返回空列表,降级到 noContacts kind
  ///      内部异常也 catch,降级到 noContacts
  ///      safety_watch_service 自身不动 — 整个降级链路最简
  Future<List<ContactEntity>> _loadContacts() async {
    try {
      return await _contactRepo.watchAll().first.timeout(
            _contactWatchTimeout,
            onTimeout: () => const <ContactEntity>[],
          );
    } catch (e, st) {
      piiSafeLog(
        'SafetyWatchService',
        '⚠️ _contactRepo.watchAll().first 异常: $e — 降级到 noContacts',
        error: e,
        stackTrace: st,
      );
      return const <ContactEntity>[];
    }
  }
}

class SafetyCheckResult {
  final SafetyCheckKind kind;
  final int? daysSinceLast;
  final int contactsNotified;
  final int contactsFailed;
  final int contactsMocked;
  final String? errorMessage;

  const SafetyCheckResult({
    required this.kind,
    this.daysSinceLast,
    this.contactsNotified = 0,
    this.contactsFailed = 0,
    this.contactsMocked = 0,
    this.errorMessage,
  });

  /// 给 UI 用的可读文案 — 已移到 presentation extension
  ///
  /// v0.32 R112 (AR-16): `displayMessageL10n(AppLocalizations)` 原在本类
  /// (data 层直接依赖 l10n/ 生成 ARB), 移到
  /// `lib/presentation/services/safety_check_result_l10n.dart` 的
  /// `SafetyCheckResultL10n` extension — caller 语法不变
  /// (`result.displayMessageL10n(l10n)`), data 层 0 l10n 依赖。
  ///
  /// 8 个 kind 全部覆盖 (旧方法注释保留在 extension 文件):
  /// - disabled / ok / noData / alertedToday / dndSuppressed / noContacts
  /// - alerted (3 态: ok / mocked / failed)
  /// - error

  /// 转成 JSON，给 audit log / settings 显示用
  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'daysSinceLast': daysSinceLast,
        'contactsNotified': contactsNotified,
        'contactsFailed': contactsFailed,
        if (errorMessage != null) 'errorMessage': errorMessage,
      };

  @override
  String toString() => jsonEncode(toJson());
}
