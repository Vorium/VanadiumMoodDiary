import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../data/repositories/check_in_repository_impl.dart';
import '../../data/repositories/contact_repository_impl.dart';
import '../../data/repositories/medication_repository_impl.dart';
import '../../data/repositories/mood_repository_impl.dart';
import '../../data/repositories/report_history_repository_impl.dart';
import '../../data/repositories/user_profile_repository_impl.dart';
import '../../data/repositories/vent_repository_impl.dart';
import '../../data/services/assessment_reminder_service.dart';
import '../../data/services/crypto_service.dart';
import '../../data/services/data_export_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/reminder_scheduler.dart';
import '../../data/services/safety_watch_service.dart';
import '../../data/services/sms_service.dart';
import '../../data/services/vent_audio_storage.dart';
import '../../domain/entities/report_history_entity.dart';
import '../../domain/entities/vent_entry.dart';
import '../../domain/repositories/check_in_repository.dart';
import '../../domain/repositories/contact_repository.dart';
import '../../domain/repositories/medication_repository.dart';
import '../../domain/repositories/mood_repository.dart';
import '../../domain/repositories/report_history_repository.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../../domain/repositories/vent_repository.dart';

/// 数据库 Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// v0.14 (Round 12A) 4 层架构：domain 抽象 + data impl
final checkInRepositoryProvider = Provider<CheckInRepository>(
  (ref) => CheckInRepositoryImpl(ref.watch(databaseProvider)),
);

final contactRepositoryProvider = Provider<ContactRepository>(
  (ref) => ContactRepositoryImpl(ref.watch(databaseProvider)),
);

final medicationRepositoryProvider = Provider<MedicationRepository>(
  (ref) => MedicationRepositoryImpl(ref.watch(databaseProvider)),
);

/// v0.16 (Round 19): data class → impl，provider 暴露 domain 接口
final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) => UserProfileRepositoryImpl(ref.watch(databaseProvider)),
);

final moodRepositoryProvider = Provider<MoodRepository>(
  (ref) => MoodRepositoryImpl(ref.watch(databaseProvider)),
);

/// v0.15 (Round 18) 树洞仓库 provider
final ventRepositoryProvider = Provider<VentRepository>(
  (ref) => VentRepositoryImpl(ref.watch(databaseProvider), ref.watch(ventAudioStorageProvider)),
);

/// v0.16 (Round 19): 报告历史仓库（domain 接口 + data impl）
final reportHistoryRepositoryProvider = Provider<ReportHistoryRepository>(
  (ref) => ReportHistoryRepositoryImpl(ref.watch(databaseProvider)),
);

/// 树洞 audio 文件管理（独立 service）
final ventAudioStorageProvider = Provider<VentAudioStorage>(
  (ref) => VentAudioStorage(),
);

/// 树洞条目流（按时间倒序，UI 监听用）
final ventEntriesProvider = StreamProvider<List<VentEntryEntity>>(
  (ref) => ref.watch(ventRepositoryProvider).watchAll(),
);

/// 单条树洞（详情页用）
final ventEntryByIdProvider = FutureProvider.family<VentEntryEntity?, int>(
  (ref, id) => ref.watch(ventRepositoryProvider).getById(id),
);

/// 服务 Providers
final cryptoServiceProvider = Provider<CryptoService>((ref) => CryptoService());

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

final reminderServiceProvider = Provider<ReminderService>(
  (ref) => ReminderService(
    checkInRepo: ref.watch(checkInRepositoryProvider),
    contactRepo: ref.watch(contactRepositoryProvider),
    medicationRepo: ref.watch(medicationRepositoryProvider),
    userProfileRepo: ref.watch(userProfileRepositoryProvider),
    smsService: ref.watch(smsServiceProvider),
  ),
);

/// SMS 服务 provider
///
/// 默认 MockSmsProvider。v1.0+ 接入阿里云时改成从 .env 读取 key 后
/// 用 AliyunSmsProvider。
final smsServiceProvider = Provider<SmsService>((ref) => SmsService());

/// 数据导出服务 provider
final dataExportServiceProvider = Provider<DataExportService>(
  (ref) => DataExportService(ref.watch(databaseProvider)),
);

/// SafetyWatch 服务（v0.10 / Round 4 死了么思路）
///
/// 默认关闭。用户在 settings 里开启后，每次 app 启动 / 打卡后跑 check。
final safetyWatchServiceProvider = Provider<SafetyWatchService>(
  (ref) => SafetyWatchService(
    checkInRepo: ref.watch(checkInRepositoryProvider),
    contactRepo: ref.watch(contactRepositoryProvider),
    userProfileRepo: ref.watch(userProfileRepositoryProvider),
    smsService: ref.watch(smsServiceProvider),
    notificationService: ref.watch(notificationServiceProvider),
  ),
);

/// v0.13 (Round 7) 心理评估周期提醒服务
///
/// Apple Health 思路：每 N 天提醒做 PHQ-9 / GAD-7。
/// 默认关闭。用户在 settings 开启 + 评估。
final assessmentReminderServiceProvider =
    Provider<AssessmentReminderService>(
  (ref) => AssessmentReminderService(
    checkInRepo: ref.watch(checkInRepositoryProvider),
    notificationService: ref.watch(notificationServiceProvider),
  ),
);
