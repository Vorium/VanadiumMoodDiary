import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/repositories/check_in/check_in_repository_impl.dart';
import 'package:chroniccare/core/data/repositories/contact/contact_repository_impl.dart';
import 'package:chroniccare/core/data/repositories/medication/medication_repository_impl.dart';
import 'package:chroniccare/core/data/repositories/mood/mood_repository_impl.dart';
import 'package:chroniccare/core/data/repositories/report_history/report_history_repository_impl.dart';
import 'package:chroniccare/core/data/repositories/user_profile/user_profile_repository_impl.dart';
import 'package:chroniccare/core/data/services/encryption_service.dart';
import 'package:chroniccare/core/data/services/notification_service.dart';
import 'package:chroniccare/core/data/services/sms_service.dart';
import 'package:chroniccare/domain/repositories/check_in_repository.dart';
import 'package:chroniccare/domain/repositories/contact_repository.dart';
import 'package:chroniccare/domain/repositories/medication_repository.dart';
import 'package:chroniccare/domain/repositories/mood_repository.dart';
import 'package:chroniccare/domain/repositories/report_history_repository.dart';
import 'package:chroniccare/domain/repositories/user_profile_repository.dart';

/// v0.17 round 14 (P1-3 拆 core_providers): 数据库 + 基础服务 + 仓库 provider
///
/// 之前一个文件 25+ provider (6.6KB),跨 feature 修改容易冲突。
/// 拆 3 个文件:
///   - core_providers.dart (本文件):  db + 基础服务 (crypto/notification/sms) + 7 个 repo
///   - service_providers.dart:        reminder + safety watch + assessment reminder + data export
///   - vent_providers.dart:           vent audio storage + vent entries stream + vent entry by id

/// 数据库 Provider (跨 feature 共享)
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// v0.16 (Round 19): data class → impl，provider 暴露 domain 接口
final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) => UserProfileRepositoryImpl(ref.watch(databaseProvider)),
);

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

final moodRepositoryProvider = Provider<MoodRepository>(
  (ref) => MoodRepositoryImpl(ref.watch(databaseProvider)),
);

/// v0.15 (Round 18) 树洞仓库 provider 已挪到 vent_providers.dart (round 14 避免循环 import)

/// v0.16 (Round 19): 报告历史仓库（domain 接口 + data impl）
final reportHistoryRepositoryProvider = Provider<ReportHistoryRepository>(
  (ref) => ReportHistoryRepositoryImpl(ref.watch(databaseProvider)),
);

/// 基础服务 provider (无 feature 依赖)

/// 加密服务 (v0.22 round 28 合并自 CryptoService, 走 EncryptionService 单例 + String API)
final encryptionServiceProvider =
    Provider<EncryptionService>((ref) => EncryptionService());

/// 通知服务 (本地 + 自动展示)
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

/// SMS 服务 provider
///
/// 默认 MockSmsProvider (开发/MVP)。v1.0+ 接入阿里云时改成从 .env 读取 key 后
/// 用 AliyunSmsProvider。
///
/// **P0-1 fix**: MockSmsProvider.send() 现在 throw UnimplementedError,
/// 任何生产 release 都必须显式注入真实 provider。UI 用
/// [smsProviderNameProvider] 检测当前是不是 mock,在 reminders hub 显示
/// 显眼"SMS 未连接"banner。
final smsServiceProvider = Provider<SmsService>((ref) => SmsService());

/// 当前 SMS provider 名称(给 UI 检测用)
final smsProviderNameProvider = Provider<String>(
  (ref) => ref.watch(smsServiceProvider).provider.name,
);

/// v0.17 round 14 提示: vent 相关的 repo / audio storage / stream provider 整组
/// 挪到 lib/presentation/providers/vent_providers.dart (避免循环 import)。
/// reminder / safety / assessment / data export 服务挪到
/// lib/presentation/providers/service_providers.dart。
