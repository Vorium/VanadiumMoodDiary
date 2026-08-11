import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/data/services/assessment_reminder_sender_impl.dart';
import 'package:chroniccare/core/data/services/assessment_reminder_service.dart';
import 'package:chroniccare/core/data/services/data_export_service.dart';
import 'package:chroniccare/core/data/services/reminder_scheduler.dart';
import 'package:chroniccare/core/data/services/safety_config_service.dart';
import 'package:chroniccare/core/data/services/safety_watch_service.dart';
import 'package:chroniccare/domain/repositories/assessment_reminder_sender.dart';
import 'package:chroniccare/domain/repositories/reminder_checker.dart';
import 'package:chroniccare/domain/usecases/schedule_assessment_reminder.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';

/// v0.17 round 14 (P1-3 拆 core_providers): 业务服务 provider
///
/// 之前在 core_providers.dart 里，现在按"业务服务"维度拆出来。
///
/// 包含:
///   - reminderService / reminderChecker: 提醒服务
///   - safetyWatchService: 死了么 (失联检测)
///   - assessmentReminderService: PHQ-9 / GAD-7 周期提醒
///   - dataExportService: 数据导出
///
/// 依赖: 7 个 repo (core_providers) + notificationService + smsService
///       (本身在 core_providers)

/// 提醒服务
final reminderServiceProvider = Provider<ReminderService>(
  (ref) => ReminderService(
    checkInRepo: ref.watch(checkInRepositoryProvider),
    contactRepo: ref.watch(contactRepositoryProvider),
    medicationRepo: ref.watch(medicationRepositoryProvider),
    userProfileRepo: ref.watch(userProfileRepositoryProvider),
    smsService: ref.watch(smsServiceProvider),
  ),
);

/// v0.16 (Round 7): ReminderChecker 抽象 provider
/// UseCase 拿这个，不直接拿 ReminderService。
final reminderCheckerProvider = Provider<ReminderChecker>(
  (ref) => ref.watch(reminderServiceProvider),
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

/// v0.27 round 61 (P1-12 god class 拆分收尾): SafetyConfigService 独立 provider
///
/// 之前 8 个 SharedPreferences 配置 API (`isEnabled` / `setEnabled` /
/// `getThresholdDays` / `setThresholdDays` / `getDoNotDisturb` /
/// `setDoNotDisturb` / `getLastAlertAt` / `setLastAlertAt`) 标了
/// `@Deprecated` 但 `safetyConfigServiceProvider` 一直没加, caller
/// (reminders_hub_provider + 3 个 test) 只能继续走 facade。
///
/// R61: 加本 provider, caller 改走本 provider, 然后删 facade 那 8 个 method。
final safetyConfigServiceProvider = Provider<SafetyConfigService>(
  (ref) => SafetyConfigService(),
);

/// v0.13 (Round 7) 心理评估周期提醒服务
///
/// Apple Health 思路：每 N 天提醒做 PHQ-9 / GAD-7。
/// 默认关闭。用户在 settings 开启 + 评估。
///
/// v0.31.1 R109 (god class 拆 round 1):
/// service 退化 thin facade, 业务编排 (算 fire time + 调 sender) 搬到
/// `ScheduleAssessmentReminderUseCase`. provider 链:
///   notificationService → sender impl → use case → service
final assessmentReminderSenderProvider = Provider<AssessmentReminderSender>(
  (ref) => AssessmentReminderSenderImpl(
    ref.watch(notificationServiceProvider),
  ),
);

/// v0.31.1 R109: use case 拿 abstract sender, 0 Flutter / 0 service 依赖
final scheduleAssessmentReminderUseCaseProvider =
    Provider<ScheduleAssessmentReminderUseCase>(
  (ref) => ScheduleAssessmentReminderUseCase(
    ref.watch(assessmentReminderSenderProvider),
  ),
);

final assessmentReminderServiceProvider = Provider<AssessmentReminderService>(
  (ref) => AssessmentReminderService(
    checkInRepo: ref.watch(checkInRepositoryProvider),
    scheduleUseCase: ref.watch(scheduleAssessmentReminderUseCaseProvider),
  ),
);

/// 数据导出服务 provider
final dataExportServiceProvider = Provider<DataExportService>(
  (ref) => DataExportService(ref.watch(databaseProvider)),
);
