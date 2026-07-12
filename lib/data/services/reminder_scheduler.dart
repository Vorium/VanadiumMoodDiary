import 'dart:developer' as developer;

import 'email_service.dart';
import '../repositories/contact_repository.dart';
import '../repositories/medication_repository.dart';
import '../repositories/check_in_repository.dart';
import '../repositories/user_profile_repository.dart';
import '../../domain/logic/reminder_scheduler.dart' as logic;

/// 失联检测服务（应用层）
///
/// 串联：
/// 1. 数据库查询最后打卡 + 联系人 + 吃药
/// 2. 判断是否需要发送
/// 3. 调 EmailService 发送
///
/// MVP 阶段：手动触发（用户调按钮 / 调试用）
/// v1.0+：定时任务 + 推送触发
class ReminderService {
  final CheckInRepository _checkInRepo;
  final ContactRepository _contactRepo;
  final MedicationRepository _medicationRepo;
  final UserProfileRepository _userProfileRepo;
  final EmailService _emailService;

  ReminderService({
    required CheckInRepository checkInRepo,
    required ContactRepository contactRepo,
    required MedicationRepository medicationRepo,
    required UserProfileRepository userProfileRepo,
    required EmailService emailService,
  })  : _checkInRepo = checkInRepo,
        _contactRepo = contactRepo,
        _medicationRepo = medicationRepo,
        _userProfileRepo = userProfileRepo,
        _emailService = emailService;

  /// 检查并发送失联通知
  Future<bool> checkAndSend() async {
    final profile = await _userProfileRepo.get();
    if (profile == null) {
      developer.log('⚠️ 用户档案不存在，跳过', name: 'ReminderService');
      return false;
    }

    final allCheckIns = await _checkInRepo.watchAll().first;
    final normalCheckIns = allCheckIns.where((c) => c.type == 'normal').toList();
    final lastCheckIn = normalCheckIns.isEmpty ? null : normalCheckIns.first.timestamp;

    final contacts = await _contactRepo.watchAll().first;
    final medications = await _medicationRepo.watchAll().first;
    final firstMed = medications.isEmpty ? null : medications.first;

    final shouldSend = logic.ReminderScheduler.shouldSendAlert(
      lastCheckIn: lastCheckIn,
      cycleHours: profile.checkInCycleHours,
      now: DateTime.now(),
    );

    if (!shouldSend) {
      developer.log(
        '✅ 距最后打卡 < ${profile.checkInCycleHours}h，不需要发送',
        name: 'ReminderService',
      );
      return false;
    }

    final firstContact = logic.ReminderScheduler.selectFirstContact(contacts);
    if (firstContact == null) {
      developer.log('⚠️ 没有可用联系人', name: 'ReminderService');
      return false;
    }

    final daysWithoutCheckIn = lastCheckIn == null
        ? 0
        : DateTime.now().difference(lastCheckIn).inDays;

    final success = await _emailService.sendMedicationReminder(
      to: firstContact.email,
      userName: profile.userName,
      daysWithoutCheckIn: daysWithoutCheckIn,
      lastCheckIn: lastCheckIn,
      medication: firstMed,
      cycleHours: profile.checkInCycleHours,
    );

    if (success) {
      developer.log(
        '✅ 邮件发送成功 → ${firstContact.email}',
        name: 'ReminderService',
      );
    } else {
      developer.log('❌ 邮件发送失败', name: 'ReminderService');
    }

    return success;
  }
}
