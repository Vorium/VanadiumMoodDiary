import 'package:chroniccare/core/data/services/pii_safe_log.dart';

import 'package:chroniccare/domain/entities/contact_entity.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/repositories/check_in_repository.dart';
import 'package:chroniccare/domain/repositories/contact_repository.dart';
import 'package:chroniccare/domain/repositories/medication_repository.dart';
import 'package:chroniccare/domain/repositories/reminder_checker.dart';
import 'package:chroniccare/domain/repositories/user_profile_repository.dart';
import 'package:chroniccare/domain/logic/reminder_scheduler.dart' as logic;
import 'package:chroniccare/core/data/services/sms_service.dart';

// ReminderLevel / ReminderCheckResult / SmsResultEntry 已搬到 domain
// (v0.16 Round 7 合并，data 层只管 SMS 真实发送，不重复定义业务结果)

/// 失联通知服务（应用层）
///
/// v0.7 升级：
/// - 通知逻辑分级（24h / 36h / 48h / 72h+）
/// - 多联系人轮询发送（不只是第一个）
/// - 用 [SmsService] 真发短信（不再 mock log）
/// - 发送状态记录在日志
class ReminderService implements ReminderChecker {
  final CheckInRepository _checkInRepo;
  final ContactRepository _contactRepo;
  final MedicationRepository _medicationRepo;
  final UserProfileRepository _userProfileRepo;
  final SmsService _smsService;

  ReminderService({
    required CheckInRepository checkInRepo,
    required ContactRepository contactRepo,
    required MedicationRepository medicationRepo,
    required UserProfileRepository userProfileRepo,
    required SmsService smsService,
  })  : _checkInRepo = checkInRepo,
        _contactRepo = contactRepo,
        _medicationRepo = medicationRepo,
        _userProfileRepo = userProfileRepo,
        _smsService = smsService;

  /// 失联分级：返回建议的通知级别
  ///
  /// - [RemindersLevel.none] - 正常
  /// - [RemindersLevel.soft] - 24h 未打卡（用户自己内部提醒，不打扰紧急联系人）
  /// - [RemindersLevel.medium] - 36h（通知紧急联系人邮件）
  /// - [RemindersLevel.hard] - 48h+（通知紧急联系人短信 + 邮件）
  /// - [RemindersLevel.urgent] - 72h+（每天重复，直到打卡）
  ///
  /// P18 fix: 用 inMinutes 替代 inHours,避免 24h/36h/48h 边界整数截断。
  /// 之前 35.9h 误判为 soft,实际已经漏 1.5 天该升级 medium。
  static ReminderLevel evaluateLevel({
    required DateTime? lastCheckIn,
    required int cycleHours,
    required DateTime now,
  }) {
    if (lastCheckIn == null) return ReminderLevel.none;
    final minutes = now.difference(lastCheckIn).inMinutes;
    if (minutes < 24 * 60) return ReminderLevel.none;
    if (minutes < 36 * 60) return ReminderLevel.soft;
    if (minutes < 48 * 60) return ReminderLevel.medium;
    if (minutes < 72 * 60) return ReminderLevel.hard;
    return ReminderLevel.urgent;
  }

  /// 发送失联通知（按级别）
  ///
  /// 返回发送结果摘要
  @override
  Future<ReminderCheckResult> checkAndSend() async {
    final profile = await _userProfileRepo.get();
    if (profile == null) {
      piiSafeLog('ReminderService', '⚠️ 用户档案不存在，跳过');
      return ReminderCheckResult.empty();
    }

    // P0 fix: DB 级查询最近一次 normal 打卡，不再全表扫描+Dart 过滤
    final latestNormal = await _checkInRepo.getLatestNormalCheckIn();
    final lastCheckIn = latestNormal?.timestamp;

    // v0.19: 缓存 now 一次，避免跨 await 后 DateTime.now() 不一致
    // （之前 evaluateLevel 和 daysSince 各调一次，跨 2 个 await，可能跨阈值边界）
    final now = DateTime.now();

    final level = evaluateLevel(
      lastCheckIn: lastCheckIn,
      cycleHours: profile.checkInCycleHours,
      now: now,
    );

    // 24h 内不打扰
    if (level == ReminderLevel.none) {
      return ReminderCheckResult.empty();
    }

    // P0 fix: 并行获取联系人和药物（互相独立）
    final fetched = await Future.wait([
      _contactRepo.watchAll().first,
      _medicationRepo.watchAll().first,
    ]);
    final contacts = fetched[0] as List<ContactEntity>;
    final medications = fetched[1] as List<MedicationEntity>;
    // v0.22 round 30 (sp-en P0-1): 显式按 startDate 升序取 firstMed。
    // drift `watchAll()` 无 `orderBy`（已 grep 确认）→ 返回值是插入序。
    // 之前 v0.16 round 19 修过 5 个 service 的 `.first` 隐式序，
    // 这里漏了第 6 个。reminder UI 显示"当前药物"会随机。
    final sortedMeds = [...medications]
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final firstMed = sortedMeds.isEmpty ? null : sortedMeds.first;

    final daysSince = lastCheckIn == null ? 0 : _daysBetween(lastCheckIn, now);
    final hoursSince =
        lastCheckIn == null ? 0 : now.difference(lastCheckIn).inHours;

    piiSafeLog('ReminderService', '=' * 60);
    piiSafeLog('ReminderService', '⚠️ 失联检测');
    piiSafeLog('ReminderService', '  用户: ${maskName(profile.userName)}');
    piiSafeLog(
      'ReminderService',
      '  距上次打卡: $hoursSince 小时 ($daysSince 天)',
    );
    piiSafeLog('ReminderService', '  级别: ${level.name}');
    piiSafeLog(
      'ReminderService',
      '  联系人: ${contacts.length} 个',
    );

    // soft 级别（24-36h）：只 UI 提示，不发紧急通知
    if (level == ReminderLevel.soft) {
      piiSafeLog(
        'ReminderService',
        '  → soft 级别：仅用户内部提示，不打扰紧急联系人',
      );
      return ReminderCheckResult(
        level: level,
        smsResults: const [],
      );
    }

    // medium/hard/urgent 级别：发给所有启用的紧急联系人
    final activeContacts =
        logic.ReminderScheduler.selectAllActiveContacts(contacts);
    if (activeContacts.isEmpty) {
      piiSafeLog('ReminderService', '  ⚠️ 没有启用的紧急联系人');
      return ReminderCheckResult(level: level, smsResults: const []);
    }

    // 构造通知内容
    final body = _buildSmsBody(
      userName: profile.userName,
      daysSince: daysSince,
      hoursSince: hoursSince,
      medication: firstMed,
    );

    // 轮询发送给所有联系人
    final results = <SmsResultEntry>[];
    for (final c in activeContacts) {
      final r = await _smsService.send(to: c.phone, body: body);
      results.add(
        SmsResultEntry(
          contactId: c.id,
          contactName: c.name,
          phone: c.phone,
          success: r.success,
          error: r.error,
        ),
      );
      piiSafeLog(
        'ReminderService',
        '  → ${maskName(c.name)} (${maskPhone(c.phone)}): ${r.success ? "✅" : "❌ ${r.error}"}',
      );
    }

    piiSafeLog('ReminderService', '=' * 60);
    return ReminderCheckResult(level: level, smsResults: results);
  }

  /// 构造短信正文
  ///
  /// v0.21 Round 23 (P1-24): userName 改 nullable
  /// 未填姓名时退化为 "您的家人",保持短信语法自然
  String _buildSmsBody({
    String? userName,
    required int daysSince,
    required int hoursSince,
    required MedicationEntity? medication,
  }) {
    final name = (userName == null || userName.isEmpty) ? '您的家人' : userName;
    final buffer = StringBuffer();
    if (daysSince >= 2) {
      buffer.writeln('【慢病管家】$name 已 $daysSince 天没打卡。');
    } else {
      buffer.writeln('【慢病管家】$name 已 $hoursSince 小时没打卡。');
    }
    buffer.writeln('请你方便的时候提醒 TA 按时吃药。');
    if (medication != null) {
      buffer.writeln(
        '常吃药: ${medication.name} ${medication.dosage}${medication.dosageUnit}',
      );
    }
    buffer.writeln('—— 这是一条自动提醒，请勿回复');
    return buffer.toString();
  }

  /// 按"天"计算两时刻差（不直接用 Duration.inDays）
  ///
  /// 不直接用 Duration.inDays，因为：
  /// - 23.98h 会被报成 0 天
  /// - DST / 时区跨日可能少算 1 天
  static int _daysBetween(DateTime a, DateTime b) {
    final aDay = DateTime(a.year, a.month, a.day);
    final bDay = DateTime(b.year, b.month, b.day);
    return bDay.difference(aDay).inDays;
  }
}
