/// 服务的依赖注入容器
///
/// MVP 阶段：手动 new
/// v1.0+：改用 get_it / Riverpod
library;

import '../database/app_database.dart';
import '../repositories/check_in_repository.dart';
import '../repositories/contact_repository.dart';
import '../repositories/medication_repository.dart';
import '../repositories/user_profile_repository.dart';
import 'email_service.dart';
import 'notification_service.dart';
import 'crypto_service.dart';
import 'reminder_scheduler.dart';

class AppServices {
  final AppDatabase database;
  final CheckInRepository checkInRepo;
  final ContactRepository contactRepo;
  final MedicationRepository medicationRepo;
  final UserProfileRepository userProfileRepo;
  final EmailService emailService;
  final NotificationService notificationService;
  final CryptoService cryptoService;
  final ReminderService reminderService;

  AppServices({required this.database})
      : checkInRepo = CheckInRepository(database),
        contactRepo = ContactRepository(database),
        medicationRepo = MedicationRepository(database),
        userProfileRepo = UserProfileRepository(database),
        emailService = EmailService(),
        notificationService = NotificationService(),
        cryptoService = CryptoService(),
        reminderService = ReminderService(
          checkInRepo: CheckInRepository(database),
          contactRepo: ContactRepository(database),
          medicationRepo: MedicationRepository(database),
          userProfileRepo: UserProfileRepository(database),
          emailService: EmailService(),
        );

  /// 初始化所有服务
  Future<void> init() async {
    await notificationService.init();
    await notificationService.scheduleDailyReminder(hour: 20, minute: 0);
  }
}
