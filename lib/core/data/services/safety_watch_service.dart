import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

import 'package:chroniccare/domain/repositories/check_in_repository.dart';
import 'package:chroniccare/domain/repositories/contact_repository.dart';
import 'package:chroniccare/domain/repositories/user_profile_repository.dart';
import 'package:chroniccare/core/data/services/notification_service.dart';
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
class SafetyWatchService {
  static const _kEnabled = 'safety_watch_enabled';
  static const _kThresholdDays = 'safety_watch_threshold_days';
  static const _kLastAlertAt = 'safety_watch_last_alert_at';
  static const _kDoNotDisturbStart = 'safety_watch_dnd_start'; // "22"
  static const _kDoNotDisturbEnd = 'safety_watch_dnd_end'; // "08"

  /// 默认阈值：2 天
  static const int defaultThresholdDays = 2;

  final CheckInRepository _checkInRepo;
  final ContactRepository _contactRepo;
  final UserProfileRepository _userProfileRepo;
  final SmsService _smsService;
  final NotificationService _notificationService;

  SafetyWatchService({
    required CheckInRepository checkInRepo,
    required ContactRepository contactRepo,
    required UserProfileRepository userProfileRepo,
    required SmsService smsService,
    required NotificationService notificationService,
  })  : _checkInRepo = checkInRepo,
        _contactRepo = contactRepo,
        _userProfileRepo = userProfileRepo,
        _smsService = smsService,
        _notificationService = notificationService;

  // ============== 配置 API（给 settings_page 用）==============

  /// 是否启用安全开关
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kEnabled) ?? false;
  }

  /// 切换启用状态
  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, value);
  }

  /// 阈值天数（连续多少天没打卡触发）
  Future<int> getThresholdDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kThresholdDays) ?? defaultThresholdDays;
  }

  Future<void> setThresholdDays(int days) async {
    if (days < 1 || days > 14) {
      throw ArgumentError('阈值必须在 1..14 天之间');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThresholdDays, days);
  }

  /// DND 时段（小时，24h 制，start < end 同一天；跨天用 start > end 表示）
  Future<({int? start, int? end})> getDoNotDisturb() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      start: prefs.getInt(_kDoNotDisturbStart),
      end: prefs.getInt(_kDoNotDisturbEnd),
    );
  }

  Future<void> setDoNotDisturb({int? startHour, int? endHour}) async {
    final prefs = await SharedPreferences.getInstance();
    if (startHour == null) {
      await prefs.remove(_kDoNotDisturbStart);
    } else {
      await prefs.setInt(_kDoNotDisturbStart, startHour);
    }
    if (endHour == null) {
      await prefs.remove(_kDoNotDisturbEnd);
    } else {
      await prefs.setInt(_kDoNotDisturbEnd, endHour);
    }
  }

  /// 上次告警时间（ISO string）
  Future<DateTime?> getLastAlertAt() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_kLastAlertAt);
    if (s == null) return null;
    return DateTime.tryParse(s);
  }

  Future<void> _setLastAlertAt(DateTime when) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastAlertAt, when.toIso8601String());
  }

  // ============== 触发入口 ==============

  /// App 启动时调用（main.dart 调）
  Future<SafetyCheckResult> onAppStart() async {
    return _checkAndAlert(trigger: 'app_start');
  }

  /// 打卡成功后调用（home_page 调）
  Future<SafetyCheckResult> onCheckIn() async {
    final result = await _checkAndAlert(trigger: 'check_in');
    if (result.kind == SafetyCheckKind.alerted) {
      developer.log(
        '⚠️ 用户打卡后仍触发告警 — 可能本地时间错乱或打卡未及时入库',
        name: 'SafetyWatchService',
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
      final daysSinceLast = _daysBetween(lastCheckIn, effectiveNow);

      if (daysSinceLast < threshold) {
        return SafetyCheckResult(
          kind: SafetyCheckKind.ok,
          daysSinceLast: daysSinceLast,
        );
      }

      // 2. 超过阈值：检查今天是不是已经发过了
      final lastAlert = await getLastAlertAt();
      if (lastAlert != null && _isSameDay(lastAlert, effectiveNow)) {
        return SafetyCheckResult(
          kind: SafetyCheckKind.alertedToday,
          daysSinceLast: daysSinceLast,
        );
      }

      // 3. 检查 DND 时段
      if (await _isInDnd(effectiveNow)) {
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
      final contacts = await _contactRepo.watchAll().first;
      if (contacts.isEmpty) {
        return SafetyCheckResult(
          kind: SafetyCheckKind.noContacts,
          daysSinceLast: daysSinceLast,
        );
      }

      // 5. 发短信给所有联系人
      int smsOk = 0;
      int smsFail = 0;
      for (final c in contacts) {
        if (!c.isActive) continue;
        final body = _buildAlertSms(
          userName: profile.userName,
          daysSinceLast: daysSinceLast,
        );
        final result = await _smsService.send(to: c.phone, body: body);
        if (result.success) {
          smsOk++;
        } else {
          smsFail++;
        }
      }

      // 6. 推本地通知（用户可能只是忘了打卡）
      await _notificationService.showSafetyAlert(
        userName: profile.userName,
        daysWithoutCheckIn: daysSinceLast,
        lastCheckIn: lastCheckIn,
      );

      // 7. 写 audit log
      await _setLastAlertAt(effectiveNow);

      developer.log(
        '🚨 SafetyWatch 触发: trigger=$trigger days=$daysSinceLast '
        'smsOk=$smsOk smsFail=$smsFail',
        name: 'SafetyWatchService',
      );

      return SafetyCheckResult(
        kind: SafetyCheckKind.alerted,
        daysSinceLast: daysSinceLast,
        contactsNotified: smsOk,
        contactsFailed: smsFail,
      );
    } catch (e, st) {
      developer.log(
        '❌ SafetyWatch error: $e',
        name: 'SafetyWatchService',
        error: e,
        stackTrace: st,
      );
      return SafetyCheckResult(
        kind: SafetyCheckKind.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// 构造发给联系人的短信内容
  ///
  /// 短信有长度限制（中文 70 字 / 条），精简到一屏
  String _buildAlertSms({
    required String userName,
    required int daysSinceLast,
  }) {
    return '[慢病管家] $userName 已 $daysSinceLast 天未打卡吃药。'
        '如确认安全请回复 1，无回复请联系本人或社区。';
  }

  // ============== 工具 ==============

  /// 跨日的"日历差"
  ///
  /// 不直接用 Duration.inDays，因为 DST / 时区可能导致 23.98 小时 ≈ 1 天之类边界
  static int _daysBetween(DateTime a, DateTime b) {
    final aDay = DateTime(a.year, a.month, a.day);
    final bDay = DateTime(b.year, b.month, b.day);
    return bDay.difference(aDay).inDays;
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<bool> _isInDnd(DateTime now) async {
    final dnd = await getDoNotDisturb();
    if (dnd.start == null || dnd.end == null) return false;
    final h = now.hour;
    if (dnd.start! < dnd.end!) {
      return h >= dnd.start! && h < dnd.end!;
    } else {
      // 跨天：例如 22 ~ 08 表示 22:00-08:00
      return h >= dnd.start! || h < dnd.end!;
    }
  }
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
