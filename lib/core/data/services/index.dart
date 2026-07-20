/// 服务的依赖注入容器
///
/// MVP 阶段：手动 new
/// v1.0+：改用 get_it / Riverpod
library;

import 'package:chroniccare/domain/repositories/medication_repository.dart';
import 'package:chroniccare/domain/repositories/user_profile_repository.dart';
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/repositories/check_in/check_in_repository_impl.dart';
import 'package:chroniccare/core/data/repositories/contact/contact_repository_impl.dart';
import 'package:chroniccare/core/data/repositories/medication/medication_repository_impl.dart';
import 'package:chroniccare/core/data/repositories/user_profile/user_profile_repository_impl.dart';
import 'package:chroniccare/core/data/services/encryption_service.dart';
import 'package:chroniccare/core/data/services/notification_service.dart';
import 'package:chroniccare/core/data/services/reminder_scheduler.dart';
import 'package:chroniccare/core/data/services/sms_service.dart';

class AppServices {
  final AppDatabase database;
  final CheckInRepositoryImpl checkInRepo;
  final ContactRepositoryImpl contactRepo;
  final MedicationRepository medicationRepo;
  final UserProfileRepository userProfileRepo;
  final NotificationService notificationService;
  // v0.22 round 28 (spen-01 + spen-bug-09): CryptoService 删除, 统一用 EncryptionService 单例
  final EncryptionService encryptionService;
  final SmsService smsService;
  late final ReminderService reminderService;

  AppServices({required this.database})
      : checkInRepo = CheckInRepositoryImpl(database),
        contactRepo = ContactRepositoryImpl(database),
        medicationRepo = MedicationRepositoryImpl(database),
        userProfileRepo = UserProfileRepositoryImpl(database),
        notificationService = NotificationService(),
        encryptionService = EncryptionService(),
        smsService = SmsService() {
    reminderService = ReminderService(
      checkInRepo: checkInRepo,
      contactRepo: contactRepo,
      medicationRepo: medicationRepo,
      userProfileRepo: userProfileRepo,
      smsService: smsService,
    );
  }

  /// 初始化所有服务
  Future<void> init() async {
    await notificationService.init();
    await notificationService.scheduleDailyReminder(hour: 20, minute: 0);
  }
}
