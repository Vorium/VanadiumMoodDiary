// v0.30 R108 (P1 god class 拆 #1): 启动期占位 App 集合 → lib/main/boot_apps.dart
//
// 拆前: main.dart 488L (实际 ~539L), 含 main + bootstrap + 3 init helper
// + _markAppDocsExcludedFromBackup + 4 占位 widget + controller + dialog
//
// 拆后: main.dart 极简 (~80L), 只留入口 + 启动编排 + 3 init helper +
// _markAppDocsExcludedFromBackup。占位 widget 全部到 lib/main/boot_apps.dart。
//
// ⚠️ 保留 R108 P0#12 守卫 (release 模式不写 Xcode Console, 避免 PII):
//   1) 主 FlutterError 回调: !kReleaseMode 守卫
//   2) runZonedGuarded onError 回调: !kReleaseMode 守卫
//   3) markAppDocsExcludedFromBackup: kDebugMode 守卫 (R108 前已加)
// 总数 = 3 处, lock-in 见 test/main/log_release_guard_round108_test.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;

import 'dart:async';
import 'dart:developer' as developer;

import 'package:chroniccare/app.dart';
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/services/database_migration.dart';
import 'package:chroniccare/core/data/services/notification_service.dart';
import 'package:chroniccare/core/data/services/last_error_capture.dart';
import 'package:chroniccare/core/data/services/pii_safe_log.dart';
import 'package:chroniccare/core/data/utils/skip_backup.dart';
import 'package:chroniccare/core/routing/notification_navigation.dart';
import 'package:chroniccare/main/boot_apps.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';
import 'package:chroniccare/presentation/providers/notification_init_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// v0.30 R108 revisit (P0-031): 删顶层 `final SmsService _smsService` 和
//   `final EmailService _emailService` 顶层 static mutable 实例。
// 之前模式: 顶层持有 + Provider 也定义,两路实例化 (顶层 main() 内
//   validateForRelease 走 _smsService,ProviderScope 内 ref.watch 走
//   Provider 创建的新实例), 违反 Riverpod DI 哲学 (Provider 才是 SOLE
//   source of truth)。
// 修后: _bootstrap() 内创建 local instance, validateForRelease + overrideWithValue
//   共享同一份。Provider 仍是 fallback, 但实际永远被 override,不会两路实例化。
// (历史注释保留在 git blame: R62 / R67 / R95 task 56 / R97-P1-13)
//
// 1.1.0 round 4b (emotion-first refactor): SMS / Email 服务整链删除
//   (外联通信业务删除定版), 上面的 validateForRelease + 2 个 override
//   随 SmsService / EmailService 一起摘掉。

/// 慢病管家 · App 入口
///
/// 启动顺序：
/// 1. **数据库迁移检查**：如果检测到旧非加密 DB,先 runApp 一个最小 MaterialApp,
///    等第一帧后再弹确认对话框（弹 dialog 必须有 Navigator）
/// 2. 初始化通知服务
/// 3. 启动完整 App
///
/// **第二轮审查 fix (N1+N5)**：
/// 之前 `WidgetsBinding.instance.rootElement` 在 runApp 之前永远是 null,
/// 导致 `showMigrationConfirmDialog` 直接降级放行 → 删数据没确认。
/// 现在改成"先 runApp 最小 app,等 first frame,再弹 dialog"的模式。
/// 配合 N12 fix: MigrationAbortedApp 的"重试"按钮调 [main] 重新走流程。
Future<void> main() async {
  // v0.18 (P2-P0-3): 全局错误兜底
  // - FlutterError.onError 捕获 widget build 阶段错误
  // - runZonedGuarded 包裹 main body 捕获所有未 catch 的 async 异常
  // - release 模式 swallow,debug 模式 throw 让 ErrorWidget 显示完整 stack
  FlutterError.onError = (details) {
    // v0.30 R108 (P0#12, spen V-01): kReleaseMode 守卫避免 release 模式
    // 把 FlutterError stack 写到 Xcode Console → PII (精神心理患者 stack 含
    // 文件路径 / 状态 / medication 名等) 风险。release 模式走 LastErrorCapture
    // 记录 (已 R22 round 33 实现), 启动 banner 提示用户截图反馈。
    if (!kReleaseMode) {
      developer.log(
        'FlutterError',
        error: details.exception,
        stackTrace: details.stack,
      );
    }
  };

  // 把整个启动逻辑放进 guarded zone
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await _bootstrap();
    },
    (error, stack) {
      // v0.30 R108 (P0#12, spen V-01): kReleaseMode 守卫避免 release 模式
      // developer.log 把 error/stack 写到 Xcode Console → PII 风险。
      // release 模式走 LastErrorCapture.record() 记录 (SharedPreferences),
      // 下次启动 AppRoot 顶部 banner 提示用户截图反馈, 不写 console。
      if (!kReleaseMode) {
        developer.log('FATAL UNCAUGHT', error: error, stackTrace: stack);
      }
      if (kDebugMode) {
        // dev 模式重新 throw 让 ErrorWidget 显示完整 stack
        FlutterError.reportError(
          FlutterErrorDetails(exception: error, stack: stack),
        );
      }
      // v0.22 round 33 (sp-en P0): release 模式之前直接 swallow, 用户连
      // "哪里出错了"都看不到。改成 LastErrorCapture 记录,下次启动 AppRoot
      // 检测到就显示顶部 banner "上次启动出错，请截图反馈"。
      // R32 (P0-13): 注释里半角逗号 → 全角逗号（守门员 check_fullwidth_punctuation 严格化）
      LastErrorCapture.record(error, stack);
    },
  );
}

/// 实际启动逻辑(v0.18 P2-P0-3 抽出来,被 runZonedGuarded 包裹)
Future<void> _bootstrap() async {
  // R104: 先显示最小 loading UI，再并行初始化
  runApp(const EarlyLoadingApp());

  // 1. 并行启动：timezone + 迁移检查 + 通知初始化 + SharedPreferences
  //    + R114 B1-8 key-DB 失配探测
  //    之前是串行 await,总耗时 = 各步之和；改并行后总耗时 = 最慢一步
  //    (P3-CLEAN-3: flutter_dotenv 只 load 不读, 已删 _loadEnv 任务)
  final results = await Future.wait([
    _initTimezones(),
    DatabaseMigration.needsMigration(),
    _initNotification(),
    SharedPreferences.getInstance(),
    // R114 B1-8: 探测 DB 是否可解密打开 (Android 备份恢复 key 失配场景)
    DatabaseMigration.probeDatabaseReadable(),
  ]);

  // 1b. R108 (P0 #1): 标记整个 app docs 目录不参与 iCloud Backup
  // defense-in-depth: 3 个显式 caller (DB / audio / swallow.log) 已标,
  // 这里再标整个目录 = 未来新加的文件 (未走 SkipBackup) 也 opt-out
  unawaited(_markAppDocsExcludedFromBackup());

  // 展开结果
  final needsMigration = results[1] as bool;
  final notifResult = results[2] as _NotificationInitResult;
  final sharedPrefs = results[3] as SharedPreferences;

  // 2. 升级检查：如果需要迁移,弹确认对话框
  if (needsMigration) {
    final proceedCompleter = MigrationPromptController();
    runApp(MigrationPromptApp(controller: proceedCompleter));
    await WidgetsBinding.instance.endOfFrame;
    final shouldProceed = await showMigrationConfirmDialog(
      proceedCompleter,
    );
    if (shouldProceed != true) {
      runApp(const MigrationAbortedApp(onRetry: main));
      return;
    }
  }

  // 3. 执行迁移（migrateIfNeeded 失败必须 throw,见 database_migration.dart）
  // 1.1.0 round 4b: SMS / Email validateForRelease 守卫块已随外联服务整摘
  try {
    await DatabaseMigration.migrateIfNeeded();
  } on MigrationException catch (e) {
    runApp(MigrationFailedApp(errorMessage: e.message));
    return;
  } catch (e, st) {
    piiSafeLog('Main', '⚠️ 数据库迁移失败：$e\n$st');
    runApp(MigrationFailedApp(errorMessage: e.toString()));
    return;
  }

  // 3b. R114 B1-8: key-DB 失配 → 重置引导 (不静默删, 用户二次确认)
  if (!(results[4] as bool)) {
    runApp(const DatabaseResetPromptApp(onRetry: main));
    return;
  }

  // 5. 启动完整 App
  final sharedDb = AppDatabase();
  runApp(
    ProviderScope(
      overrides: [
        notificationInitResultProvider.overrideWith(
          (ref) => NotificationInitResult(
            ok: notifResult.ok,
            error: notifResult.error,
          ),
        ),
        notificationServiceProvider.overrideWithValue(notifResult.service),
        databaseProvider.overrideWithValue(sharedDb),
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
      child: const AppRoot(),
    ),
  );
}

/// 并行任务 1: 初始化 timezone 数据库（同步 CPU 操作,包一层 Future 让它跑到 isolate pool）
Future<void> _initTimezones() async {
  tz_data.initializeTimeZones();
}

/// 并行任务 2: 初始化通知服务 + 返回结果
///
/// v0.32 R112 (R112-ARCH-02): navigation 回调在 app 层接线 — data service
/// 0 依赖 core/routing (传递 Flutter 依赖)。tap 走
/// NotificationNavigation.handleTap, launch payload 走 setLaunchPayload。
Future<_NotificationInitResult> _initNotification() async {
  final service = NotificationService(
    onNotificationTap: NotificationNavigation.handleTap,
    onLaunchPayload: NotificationNavigation.setLaunchPayload,
  );
  try {
    await service.init();
    // scheduleDailyReminder 延迟到 AppRoot.initState 的 postFrameCallback,
    // 不阻塞启动
    return _NotificationInitResult(service: service, ok: true);
  } catch (e) {
    piiSafeLog('Main', '⚠️ 通知服务初始化失败（不影响核心功能）：$e');
    return _NotificationInitResult(service: service, error: e.toString());
  }
}

/// 通知初始化结果封装
class _NotificationInitResult {
  final NotificationService service;
  final bool ok;
  final String? error;
  const _NotificationInitResult({
    required this.service,
    this.ok = false,
    this.error,
  });
}

/// R108 (P0 #1): 标记整个 app docs 目录不参与 iCloud Backup
///
/// defense-in-depth: 3 个显式 caller (DB / audio / swallow.log) 已标,
/// 这里再标整个目录 = 未来新加的 PII 文件 (未走 SkipBackup) 也 opt-out。
///
/// 4th caller (跟 audit P-05 报告"4 个 path_provider 调用点"对齐):
/// - native.dart:18 — SQLCipher DB
/// - encrypted_audio_storage.dart:99 — vent / mood audio 目录
/// - swallow_log_sink.dart:54 — audit log
/// - main.dart (本函数) — 整个 app docs 目录 (4th defense-in-depth)
///
/// 失败不抛, fire-and-forget (主流程不阻塞)。 SkipBackup 内部 swallowError。
Future<void> _markAppDocsExcludedFromBackup() async {
  try {
    final docs = await getApplicationDocumentsDirectory();
    await SkipBackup.markAsSkipped(docs.path);
  } catch (e, st) {
    // 主流程不阻塞, swallow + log (跟 swallowError 一致, dev 模式可见)
    piiSafeLog(
      'main',
      'R108 P0-1 mark app docs excluded failed: $e',
    );
    if (kDebugMode) {
      developer.log(
        'R108 markAppDocsExcluded failed',
        error: e,
        stackTrace: st,
      );
    }
  }
}
