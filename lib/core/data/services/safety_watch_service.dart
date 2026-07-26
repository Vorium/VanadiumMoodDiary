import 'dart:async';
import 'dart:convert';

import 'package:chroniccare/domain/entities/contact_entity.dart';
import 'package:chroniccare/domain/repositories/check_in_repository.dart';
import 'package:chroniccare/domain/repositories/contact_repository.dart';
import 'package:chroniccare/domain/repositories/user_profile_repository.dart';
import 'package:chroniccare/core/data/services/notification_service.dart';
import 'package:chroniccare/core/data/services/pii_safe_log.dart';
import 'package:chroniccare/core/data/services/safety_alert_dispatcher.dart';
import 'package:chroniccare/core/data/services/safety_config_service.dart';
import 'package:chroniccare/core/data/services/sms_service.dart';

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
class SafetyWatchService {
  // v0.25 round 57: 旧 key 常量移到 SafetyConfigService 内部 (private)
  // 保留 defaultThresholdDays 静态常量兼容旧调用方
  static const int defaultThresholdDays = 2;

  final CheckInRepository _checkInRepo;
  final ContactRepository _contactRepo;
  final UserProfileRepository _userProfileRepo;
  final SmsService _smsService;
  final NotificationService _notificationService;

  /// v0.25 round 57: 2 个 sub
  late final SafetyConfigService _config =
      SafetyConfigService();
  late final SafetyAlertDispatcher _alertDispatcher = SafetyAlertDispatcher(
    smsService: _smsService,
    notificationService: _notificationService,
    config: _config,
  );

  /// v0.23 round 38 (P0-3 fix): _contactRepo.watchAll().first 的 timeout 时长
  /// 默认 5s,测试可注入短值(50ms)避免 5s 等待
  final Duration _contactWatchTimeout;

  SafetyWatchService({
    required CheckInRepository checkInRepo,
    required ContactRepository contactRepo,
    required UserProfileRepository userProfileRepo,
    required SmsService smsService,
    required NotificationService notificationService,
    Duration contactWatchTimeout = const Duration(seconds: 5),
  })  : _checkInRepo = checkInRepo,
        _contactRepo = contactRepo,
        _userProfileRepo = userProfileRepo,
        _smsService = smsService,
        _notificationService = notificationService,
        _contactWatchTimeout = contactWatchTimeout;

  // ============== 配置 API（给 settings_page 用，R57 facade 委托）==============

  /// 是否启用安全开关
  Future<bool> isEnabled() => _config.isEnabled();

  /// 切换启用状态
  Future<void> setEnabled(bool value) => _config.setEnabled(value);

  /// 阈值天数（连续多少天没打卡触发）
  Future<int> getThresholdDays() => _config.getThresholdDays();

  Future<void> setThresholdDays(int days) => _config.setThresholdDays(days);

  /// DND 时段（小时，24h 制，start < end 同一天；跨天用 start > end 表示）
  Future<({int? start, int? end})> getDoNotDisturb() =>
      _config.getDoNotDisturb();

  Future<void> setDoNotDisturb({int? startHour, int? endHour}) =>
      _config.setDoNotDisturb(startHour: startHour, endHour: endHour);

  /// 上次告警时间（ISO string）
  Future<DateTime?> getLastAlertAt() => _config.getLastAlertAt();

  // ============== 触发入口 ==============

  /// App 启动时调用（main.dart 调）
  Future<SafetyCheckResult> onAppStart() async {
    return _checkAndAlert(trigger: 'app_start');
  }

  /// 打卡成功后调用（home_page 调）
  Future<SafetyCheckResult> onCheckIn() async {
    final result = await _checkAndAlert(trigger: 'check_in');
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
  Future<SafetyCheckResult> checkNow({DateTime? now}) async {
    return _checkAndAlert(trigger: 'manual', now: now);
  }

  // ============== 核心 ==============

  Future<SafetyCheckResult> _checkAndAlert({
    required String trigger,
    DateTime? now,
  }) async {
    try {
      final enabled = await isEnabled();
      if (!enabled) {
        return const SafetyCheckResult(kind: SafetyCheckKind.disabled);
      }

      final threshold = await getThresholdDays();

      // 1. 拉最近一次正常打卡（P0 fix: DB 级 LIMIT 1，不再全表扫描）
      final latestNormal = await _checkInRepo.getLatestNormalCheckIn();
      if (latestNormal == null) {
        // 用户从没打过卡，**不算异常**（新用户不打扰）
        return const SafetyCheckResult(kind: SafetyCheckKind.noData);
      }
      final lastCheckIn = latestNormal.timestamp;
      // P0-4 fix: 接受外部 now 注入，避免测试跨 midnight flake。
      // 同一函数内不重复调 DateTime.now()(v0.16 round 19B 已立的规矩)。
      // 用 effectiveNow 避免跟参数 now 同名导致 Dart 推断为 nullable。
      final effectiveNow = now ?? DateTime.now();
      final daysSinceLast = SafetyConfigService.daysBetween(lastCheckIn, effectiveNow);

      if (daysSinceLast < threshold) {
        return SafetyCheckResult(
          kind: SafetyCheckKind.ok,
          daysSinceLast: daysSinceLast,
        );
      }

      // 2. 超过阈值：检查今天是不是已经发过了
      final lastAlert = await getLastAlertAt();
      if (lastAlert != null && SafetyConfigService.isSameDay(lastAlert, effectiveNow)) {
        return SafetyCheckResult(
          kind: SafetyCheckKind.alertedToday,
          daysSinceLast: daysSinceLast,
        );
      }

      // 3. 检查 DND 时段
      if (await _config.isInDnd(effectiveNow)) {
        return SafetyCheckResult(
          kind: SafetyCheckKind.dndSuppressed,
          daysSinceLast: daysSinceLast,
        );
      }

      // 4. 拉用户档案 + 联系人
      final profile = await _userProfileRepo.get();
      if (profile == null) {
        return const SafetyCheckResult(kind: SafetyCheckKind.noData);
      }
      // v0.23 round 38 (P0-3 fix): 加 5s timeout + 异常降级
      // 之前 `_contactRepo.watchAll().first` 在以下情况会 hang:
      //   a) drift stream 内部异常 (罕见,通常是 DB lock)
      //   b) stream 关闭 (没关闭 listener)
      // 整个 `_checkAndAlert` 阻塞 → 失联检测核心路径失败 → SMS 通知永远不发出
      // 修法: [_contactWatchTimeout] 默认 5s 返回空列表,降级到 noContacts kind
      //      内部异常也 catch,降级到 noContacts
      //      safety_watch_service 自身不动 — 整个降级链路最简
      final List<ContactEntity> contacts;
      try {
        contacts = await _contactRepo
            .watchAll()
            .first
            .timeout(_contactWatchTimeout, onTimeout: () => const <ContactEntity>[]);
      } catch (e, st) {
        piiSafeLog(
          'SafetyWatchService',
          '⚠️ _contactRepo.watchAll().first 异常: $e — 降级到 noContacts',
          error: e,
          stackTrace: st,
        );
        return SafetyCheckResult(
          kind: SafetyCheckKind.noContacts,
          daysSinceLast: daysSinceLast,
        );
      }
      if (contacts.isEmpty) {
        return SafetyCheckResult(
          kind: SafetyCheckKind.noContacts,
          daysSinceLast: daysSinceLast,
        );
      }

      // 5+6+7. v0.25 round 57 (god class 拆分): 委托给 SafetyAlertDispatcher
      // 发 SMS + 推本地通知 + 写 audit log + 计数
      final dispatched = await _alertDispatcher.dispatchAlert(
        contacts: contacts,
        userName: profile.userName,
        daysSinceLast: daysSinceLast,
        lastCheckIn: lastCheckIn,
        effectiveNow: effectiveNow,
        trigger: trigger,
      );

      return SafetyCheckResult(
        kind: SafetyCheckKind.alerted,
        daysSinceLast: daysSinceLast,
        contactsNotified: dispatched.smsOk,
        contactsFailed: dispatched.smsFail,
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

  // v0.25 round 57: _buildAlertSms 跟 _setLastAlertAt 已移到
  // SafetyAlertDispatcher / SafetyConfigService, safety_watch_service
  // 作为 facade 不再持有这些 method. caller 可通过 dispatcher / config
  // 直接调, 或继续用 facade 的 8 个 public method 转发.
}

/// 安全检查结果
enum SafetyCheckKind {
  /// 关闭
  disabled,

  /// 正常（< 阈值）
  ok,

  /// 没数据（新用户）
  noData,

  /// 今天已经发过告警
  alertedToday,

  /// 在 DND 时段，跳过
  dndSuppressed,

  /// 没有联系人（开启但没法通知）
  noContacts,

  /// 真的发告警了
  alerted,

  /// 出错
  error,
}

class SafetyCheckResult {
  final SafetyCheckKind kind;
  final int? daysSinceLast;
  final int contactsNotified;
  final int contactsFailed;
  final String? errorMessage;

  const SafetyCheckResult({
    required this.kind,
    this.daysSinceLast,
    this.contactsNotified = 0,
    this.contactsFailed = 0,
    this.errorMessage,
  });

  /// 给 UI 用的可读文案
  String get displayMessage {
    switch (kind) {
      case SafetyCheckKind.disabled:
        return '安全开关已关闭';
      case SafetyCheckKind.ok:
        return '正常（$daysSinceLast 天前打卡）';
      case SafetyCheckKind.noData:
        return '新用户，暂无打卡';
      case SafetyCheckKind.alertedToday:
        return '今天已经发过告警（$daysSinceLast 天前打卡）';
      case SafetyCheckKind.dndSuppressed:
        return 'DND 时段，跳过告警';
      case SafetyCheckKind.noContacts:
        return '无紧急联系人，未发送';
      case SafetyCheckKind.alerted:
        return '已告警：$daysSinceLast 天前打卡，'
            '已通知 $contactsNotified 位联系人'
            '${contactsFailed > 0 ? '（$contactsFailed 失败）' : ''}';
      case SafetyCheckKind.error:
        return '错误：$errorMessage';
    }
  }

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
