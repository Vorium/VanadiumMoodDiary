import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/data/services/assessment_reminder_sender_impl.dart';
import 'package:chroniccare/core/data/services/assessment_reminder_service.dart';
import 'package:chroniccare/core/data/services/data_export_service.dart';
import 'package:chroniccare/domain/repositories/assessment_reminder_sender.dart';
import 'package:chroniccare/domain/usecases/schedule_assessment_reminder.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';

/// v0.17 round 14 (P1-3 拆 core_providers): 业务服务 provider
///
/// 之前在 core_providers.dart 里，现在按"业务服务"维度拆出来。
///
/// 包含:
///   - assessmentReminderService: PHQ-9 / GAD-7 周期提醒
///   - dataExportService: 数据导出
///
/// 1.1.0 round 4b (emotion-first refactor): 外联 6 个 provider 整摘
///   (reminderServiceProvider / reminderCheckerProvider /
///   safetyAlertSenderProvider / dispatchSafetyAlertUseCaseProvider /
///   safetyWatchServiceProvider / safetyConfigServiceProvider, 随
///   ReminderService / SafetyWatchService / SMS 服务整链删除)。
///
/// 依赖: 6 个 repo (core_providers) + notificationService (core_providers)

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
