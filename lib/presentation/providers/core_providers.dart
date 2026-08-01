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
import 'package:chroniccare/core/data/services/email_service.dart';
import 'package:chroniccare/presentation/services/legal_version.dart';
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
/// **P0-1 fix (v0.22)**: MockSmsProvider.send() 现在 throw UnimplementedError,
/// 任何生产 release 都必须显式注入真实 provider。UI 用
/// [smsProviderNameProvider] 检测当前是不是 mock,在 reminders hub 显示
/// 显眼"SMS 未连接"banner。
///
/// **P0-1 fix (v0.23 round 38)**: 启动时 main.dart bootstrap 调
/// [SmsService.validateForRelease],release 模式 + 未配置 provider →
/// 抛 [SmsProviderNotConfiguredError],被 runZonedGuarded 抓住,LastErrorCapture
/// 记录,AppRoot 启动后顶部 banner 显眼提示。比之前"send() 时静默 fail +
/// UI 显示 banner"更前置,把"假成功"风险降到 0。
final smsServiceProvider = Provider<SmsService>((ref) => SmsService());

/// 当前 SMS provider 名称(给 UI 检测用)
final smsProviderNameProvider = Provider<String>(
  (ref) => ref.watch(smsServiceProvider).provider.name,
);

/// v0.27 round 67 (B-1 修复): EmailService provider
///
/// 跟 [smsServiceProvider] 1:1 平行。当前 EmailService 暂无 caller
/// (SmsService 是 reminderService 的依赖, EmailService 之前是 dead code),
/// R67 后 home_page._fireCareEngine 在 use case 返回 fireEmail 时会读这个
/// provider 调 sendMedicationReminder (R55+ 真接 SendGrid 走真实路径)。
///
/// **R67 B-1 修复**: 跟 R63 SmsService 守门员平行, 启动时
/// [EmailService.validateForRelease] 检查 [isProductionReady], release + 未就绪
/// → 抛 [EmailProviderNotConfiguredError] 阻断, banner 显眼提示。
final emailServiceProvider = Provider<EmailService>((ref) => EmailService());

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
/// reminder / safety / assessment / data export 服务挪到
/// lib/presentation/providers/service_providers.dart。
