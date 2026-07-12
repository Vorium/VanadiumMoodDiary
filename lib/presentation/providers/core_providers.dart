import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../data/repositories/check_in_repository.dart';
import '../../data/repositories/contact_repository.dart';
import '../../data/repositories/medication_repository.dart';
import '../../data/repositories/user_profile_repository.dart';
import '../../data/services/crypto_service.dart';
import '../../data/services/email_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/reminder_scheduler.dart';

/// 数据库 Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// 仓库 Providers
final checkInRepositoryProvider = Provider<CheckInRepository>(
  (ref) => CheckInRepository(ref.watch(databaseProvider)),
);

final contactRepositoryProvider = Provider<ContactRepository>(
  (ref) => ContactRepository(ref.watch(databaseProvider)),
);

final medicationRepositoryProvider = Provider<MedicationRepository>(
  (ref) => MedicationRepository(ref.watch(databaseProvider)),
);

final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) => UserProfileRepository(ref.watch(databaseProvider)),
);

/// 服务 Providers
final cryptoServiceProvider = Provider<CryptoService>((ref) => CryptoService());

final emailServiceProvider = Provider<EmailService>(
  (ref) => EmailService(),
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

final reminderServiceProvider = Provider<ReminderService>(
  (ref) => ReminderService(
    checkInRepo: ref.watch(checkInRepositoryProvider),
    contactRepo: ref.watch(contactRepositoryProvider),
    medicationRepo: ref.watch(medicationRepositoryProvider),
    userProfileRepo: ref.watch(userProfileRepositoryProvider),
    emailService: ref.watch(emailServiceProvider),
  ),
);
