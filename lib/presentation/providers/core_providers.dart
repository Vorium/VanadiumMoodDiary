import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/services/setup_committer.dart';
import 'package:chroniccare/core/data/repositories/check_in/check_in_repository_impl.dart';
import 'package:chroniccare/core/data/repositories/medication/medication_repository_impl.dart';
import 'package:chroniccare/core/data/repositories/mood/mood_repository_impl.dart';
import 'package:chroniccare/core/data/repositories/report_history/report_history_repository_impl.dart';
import 'package:chroniccare/core/data/repositories/user_profile/user_profile_repository_impl.dart';
import 'package:chroniccare/core/data/services/encryption_service.dart';
import 'package:chroniccare/core/data/services/notification_service.dart';
import 'package:chroniccare/presentation/services/legal_version.dart';
import 'package:chroniccare/domain/repositories/check_in_repository.dart';
import 'package:chroniccare/domain/repositories/medication_repository.dart';
import 'package:chroniccare/domain/repositories/mood_repository.dart';
import 'package:chroniccare/domain/repositories/report_history_repository.dart';
import 'package:chroniccare/domain/repositories/user_profile_repository.dart';

/// v0.17 round 14 (P1-3 拆 core_providers): 数据库 + 基础服务 + 仓库 provider
///
/// 之前一个文件 25+ provider (6.6KB),跨 feature 修改容易冲突。
/// 拆 3 个文件:
///   - core_providers.dart (本文件):  db + 基础服务 (crypto/notification) + 6 个 repo
///   - service_providers.dart:        assessment reminder + data export
///   - vent_providers.dart:           vent audio storage + vent entries stream + vent entry by id
///
/// 1.1.0 round 4b (emotion-first refactor): 外联 4 个 provider 整摘
///   (contactRepositoryProvider / smsServiceProvider / smsProviderNameProvider
///   / emailServiceProvider, 随 contacts 表 / SMS / Email 服务整链删除)。

/// 数据库 Provider (跨 feature 共享)
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// v0.32 round 8 (R112 AR-19): setup/清空数据编排下沉到 data 层
/// SetupCommitter (saveSetup/clearAllUserData 从 AppDatabase 门面抽出,
/// transaction 语义 + PIPL §13 StateError 校验保持)
final setupCommitterProvider = Provider<SetupCommitter>(
  (ref) => SetupCommitter(ref.watch(databaseProvider)),
);

/// v0.16 (Round 19): data class → impl，provider 暴露 domain 接口
final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) => UserProfileRepositoryImpl(ref.watch(databaseProvider)),
);

/// v0.14 (Round 12A) 4 层架构：domain 抽象 + data impl
final checkInRepositoryProvider = Provider<CheckInRepository>(
  (ref) => CheckInRepositoryImpl(ref.watch(databaseProvider)),
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

/// v0.27 round 77 (R76-N6 修): 法律协议版本号 provider
///
/// 启动时算一次 `v{major.minor}-{YYYY-MM-DD}`, 同 session 跨 widget / 跨
/// 调用返回**相同** string (因为 Provider 默认 cache)。跨 midnight 不重算
/// (避免同一 session 同一用户同意 2 次, 第二次 version 跨日跟第一次不同
/// 触发 re-consent, 用户会烦)。
///
/// 升级流程: bump pubspec.yaml version → 改 [kPubspecVersion] → 重 build
/// → 新 session 拿新 version → 旧 consent 跟新 version 不同 → 触发 re-consent。
///
/// 当前不监听系统时间变化 (跟 streakSummaryProvider 不同), 因为法律协议
/// version 跨日不应该变 (user 同意 v0.27 应该一直是 v0.27, 跨 midnight
/// 不需要重新同意)。
final legalVersionProvider = Provider<String>(
  (ref) => computeLegalVersionAt(DateTime.now()),
);

/// v0.17 round 14 提示: vent 相关的 repo / audio storage / stream provider 整组
/// 挪到 lib/presentation/providers/vent_providers.dart (避免循环 import)。
/// assessment reminder / data export 服务挪到
/// lib/presentation/providers/service_providers.dart。
