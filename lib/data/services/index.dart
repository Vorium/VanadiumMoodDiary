/// 服务的依赖注入容器
///
/// MVP 阶段：手动 new
/// v1.0+：改用 get_it / Riverpod
library;

import '../../domain/repositories/medication_repository.dart';
import '../database/app_database.dart';
import '../repositories/check_in_repository_impl.dart';
import '../repositories/contact_repository_impl.dart';
import '../repositories/medication_repository_impl.dart';
import '../repositories/user_profile_repository.dart';
import 'crypto_service.dart';
import 'notification_service.dart';
import 'reminder_scheduler.dart';
import 'sms_service.dart';

class AppServices {
  final AppDatabase database;
  final CheckInRepositoryImpl checkInRepo;
  final ContactRepositoryImpl contactRepo;
  final MedicationRepository medicationRepo;
  final UserProfileRepository userProfileRepo;
  final NotificationService notificationService;
  final CryptoService cryptoService;
  final SmsService smsService;
  final ReminderService reminderService;

  AppServices({required this.database})
      : checkInRepo = CheckInRepositoryImpl(database),
        contactRepo = ContactRepositoryImpl(database),
        medicationRepo = MedicationRepositoryImpl(database),
        userProfileRepo = UserProfileRepository(database),
        notificationService = NotificationService(),
        cryptoService = CryptoService(),
        smsService = SmsService(),
        reminderService = ReminderService(
          checkInRepo: CheckInRepositoryImpl(database),
          contactRepo: ContactRepositoryImpl(database),
          medicationRepo: MedicationRepositoryImpl(database),
          userProfileRepo: UserProfileRepository(database),
          smsService: SmsService(),
        );

  /// 初始化所有服务
  Future<void> init() async {
    await notificationService.init();
    await notificationService.scheduleDailyReminder(hour: 20, minute: 0);
  }
}
