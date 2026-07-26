import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'dart:async';
import 'dart:developer' as developer;

import 'package:chroniccare/app.dart';
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/services/database_migration.dart';
import 'package:chroniccare/core/data/services/notification_service.dart';
import 'package:chroniccare/core/data/services/last_error_capture.dart';
import 'package:chroniccare/core/data/services/pii_safe_log.dart';
import 'package:chroniccare/core/data/services/sms_service.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';

/// 慢病管家 · App 入口
///
/// 启动顺序：
/// 1. 加载 .env（缺失不阻断，走代码默认值）
/// 2. **数据库迁移检查**：如果检测到旧非加密 DB,先 runApp 一个最小 MaterialApp,
///    等第一帧后再弹确认对话框（弹 dialog 必须有 Navigator）
/// 3. 初始化通知服务
/// 4. 启动完整 App
///
/// **第二轮审查 fix (N1+N5)**：
/// 之前 `WidgetsBinding.instance.rootElement` 在 runApp 之前永远是 null,
/// 导致 `_showMigrationConfirmDialog` 直接降级放行 → 删数据没确认。
/// 现在改成"先 runApp 最小 app,等 first frame,再弹 dialog"的模式。
/// 配合 N12 fix:_MigrationAbortedApp 的"重试"按钮调 [main] 重新走流程。
Future<void> main() async {
  // v0.18 (P2-P0-3): 全局错误兜底
  // - FlutterError.onError 捕获 widget build 阶段错误
  // - runZonedGuarded 包裹 main body 捕获所有未 catch 的 async 异常
  // - release 模式 swallow,debug 模式 throw 让 ErrorWidget 显示完整 stack
  // AGENTS.md 已声明"本地 SQLite 错误通过 runZonedGuarded 打印",这是首次实现
  FlutterError.onError = (details) {
    developer.log(
      'FlutterError',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  // 把整个启动逻辑放进 guarded zone
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await _bootstrap();
    },
    (error, stack) {
      developer.log('FATAL UNCAUGHT', error: error, stackTrace: stack);
      if (kDebugMode) {
        // dev 模式重新 throw 让 ErrorWidget 显示完整 stack
        FlutterError.reportError(
          FlutterErrorDetails(exception: error, stack: stack),
        );
      }
      // v0.22 round 33 (sp-en P0): release 模式之前直接 swallow, 用户连
      // "哪里出错了"都看不到。改成 LastErrorCapture 记录，下次启动 AppRoot
      // 检测到就显示顶部 banner "上次启动出错，请截图反馈"。
      LastErrorCapture.record(error, stack);
    },
  );
}

/// 实际启动逻辑(v0.18 P2-P0-3 抽出来,被 runZonedGuarded 包裹)
Future<void> _bootstrap() async {
  // 1. 加载 .env（缺失时静默跳过）
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    piiSafeLog('Main', '⚠️ .env 加载失败（首次启动正常）：$e');
  }

  // 1.5 v0.24 round 48 (sp-zh P1-18): 显式初始化 timezone 数据库 + 设 local tz
  //   背景: 之前未调 tz_data.initializeTimeZones(),tz.local 默认是 UTC
  //   → 所有 .add(Duration(hours: 8)) 之类的"中国时区近似"在海外/系统时区错乱场景
  //     会出现 reminder 跨日漂移、邮件时间错位等 bug
  //   修法: 启动时加载所有 tz 数据,设默认 Asia/Shanghai (中国用户基线)
  //   pubspec.yaml 已有 timezone: ^0.9.4
  //   v1.0+ 计划: settings 里加 "时区" 选项,用户可改
  tz_data.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));

  // 2. 升级检查
  //    如果没有旧 DB（全新安装），直接进入步骤 3
  //    如果有，必须先弹确认对话框（要 Navigator）
  if (await DatabaseMigration.needsMigration()) {
    // 启动一个最小的"启动中"App，用来挂 dialog
    final proceedCompleter = _MigrationPromptController();
    runApp(_MigrationPromptApp(controller: proceedCompleter));
    // 等第一帧：确保 Navigator 已就绪
    await WidgetsBinding.instance.endOfFrame;
    final shouldProceed = await _showMigrationConfirmDialog(
      proceedCompleter,
    );
    if (shouldProceed != true) {
      // 用户取消：切到 abort UI。
      // abort UI 里的"重试"按钮会重新调 main(),重新走整个流程。
      runApp(const _MigrationAbortedApp(onRetry: main));
      return;
    }
  }

  // 3. 初始化通知服务
  //    N30 + P17 fix: 加 try/catch 防止启动失败 + 失败时给用户提示
  //    用户需要知道"提醒没设上",否则漏 1 天没人提醒会很惨
  final notificationService = NotificationService();
  bool notificationOk = false;
  String? notificationError;
  try {
    await notificationService.init();
    await notificationService.scheduleDailyReminder(hour: 20, minute: 0);
    notificationOk = true;
  } catch (e) {
    piiSafeLog('Main', '⚠️ 通知服务初始化失败（不影响核心功能）：$e');
    notificationError = e.toString();
  }

  // 3.5 v0.23 round 38 (P0-1 fix): release 模式启动 SMS 守卫
  //     release + mock → 抛 SmsProviderNotConfiguredError
  //     被 runZonedGuarded 抓住,LastErrorCapture 记录,AppRoot banner 提示
  //     dev/profile 模式: 静默通过(mock 是 dev 工具)
  //     这里故意不用 try/catch:让异常冒泡到外层 runZonedGuarded
  SmsService.validateForRelease(SmsService().provider);

  // 4. 执行迁移（migrateIfNeeded 失败必须 throw,见 database_migration.dart）
  try {
    await DatabaseMigration.migrateIfNeeded();
  } on MigrationException catch (e) {
    // MigrationException.message 已经是面向用户的友好文本
    runApp(_MigrationFailedApp(message: e.message));
    return;
  } catch (e, st) {
    piiSafeLog('Main', '⚠️ 数据库迁移失败：$e\n$st');
    // N31 fix: 给用户友好消息，详细错只 log
    runApp(const _MigrationFailedApp(message: '无法初始化本地数据'));
    return;
  }

  // 5. 启动完整 App
  // P0 fix: 创建单一 AppDatabase 实例，provider tree 和 assessment reminder 共用
  final sharedDb = AppDatabase();
  runApp(
    ProviderScope(
      overrides: [
        // P17 fix: 把通知初始化结果注入到 provider 树,
        // 首页能根据状态显示一次性提示 banner
        notificationInitResultProvider.overrideWith(
          (ref) => NotificationInitResult(
            ok: notificationOk,
            error: notificationError,
          ),
        ),
        // v0.13 (Round 7): 把已经初始化好的 notification service 注入,
        // 避免子 service 重新创建实例
        notificationServiceProvider.overrideWithValue(notificationService),
        // P0 fix: 注入共享 db 实例，避免 provider tree 再创建第二个连接
        databaseProvider.overrideWithValue(sharedDb),
      ],
      child: const AppRoot(),
    ),
  );

  // 6. v0.21 (P2-3 fix): AssessmentReminder.onAppStart() 已经从 main.dart
  //    移到 AppRoot.initState 的 addPostFrameCallback — 等待 widget tree
  //    就绪而非 magic 100ms。这里不再需要。
}

/// 弹升级确认对话框
///
/// **重要**:必须在 runApp 之后调用，否则 showDialog 拿不到 Navigator。
/// 配合 [_MigrationPromptApp] 提供的 navigatorKey。
Future<bool?> _showMigrationConfirmDialog(
  _MigrationPromptController controller,
) async {
  final ctx = controller.navigatorKey.currentContext;
  if (ctx == null) {
    // 极少见：endOfFrame 后还没拿到 context
    // v0.22 round 31 (sp-en P0-4): 之前降级返 `true` 会**自动确认删旧数据**，
    // race 时用户没看到 dialog 数据就丢了。改成降级返 `false`（保守拒绝），
    // 触发 caller 的 `_MigrationAbortedApp` abort UI，用户点"重试"再走一次。
    piiSafeLog(
      'Main',
      '⚠️ migration dialog: navigator context 仍为 null，降级拒绝（保守）',
    );
    return false;
  }
  return showDialog<bool>(
    context: ctx,
    barrierDismissible: false,
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx);
      return AlertDialog(
        title: Text(l10n.migrationPromptTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.migrationPromptDetectedOld),
              const SizedBox(height: 12),
              Text(l10n.migrationPromptChangesTitle),
              const SizedBox(height: 4),
              Text(l10n.migrationPromptChangeEncrypt),
              Text(l10n.migrationPromptChangeClear),
              Text(l10n.migrationPromptChangeWarning),
              const SizedBox(height: 12),
              Text(l10n.migrationPromptRecommendExport),
              const SizedBox(height: 4),
              Text(l10n.migrationPromptDirectContinue),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.migrationPromptCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.migrationPromptContinue),
          ),
        ],
      );
    },
  );
}

/// 弹 dialog 用的"启动中"App + navigatorKey
///
/// 等待期间显示一个简单的 loading,弹完 dialog 就销毁。
class _MigrationPromptController {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

class _MigrationPromptApp extends StatelessWidget {
  final _MigrationPromptController controller;
  const _MigrationPromptApp({required this.controller});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: controller.navigatorKey,
      home: const Scaffold(
        body: LoadingSkeleton.fullScreen(),
      ),
    );
  }
}

/// 用户取消升级时的占位 App
///
/// **N12 fix**: "已备份，重试"按钮调 [main] 重启流程，不必杀进程。
class _MigrationAbortedApp extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _MigrationAbortedApp({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.pause_circle_outline,
                  size: 64,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.migrationAbortedTitle,
                  style: const TextStyle(
                    fontSize: AppTokens.fontSizeButton,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.migrationAbortedBody,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            // 调 main() 重新走迁移流程。runApp 会替换当前 widget tree。
            onRetry();
          },
          icon: const Icon(Icons.refresh),
          label: Text(l10n.migrationAbortedRetry),
        ),
      ),
    );
  }
}

/// 通知初始化结果（注入到 provider 树，首页用）
class NotificationInitResult {
  final bool ok;
  final String? error;
  const NotificationInitResult({required this.ok, this.error});
}

final notificationInitResultProvider = Provider<NotificationInitResult>(
  (ref) => const NotificationInitResult(ok: true, error: null),
);

/// 迁移失败时的占位 App
///
/// **N31 fix**: 接受已脱敏的友好消息，不再直接显示内部异常
///
/// **v0.24 round 45 (P0 fix)**: 之前 hardcode 中文，en 模式用户看到中文。
/// 改成走 l10n，跟 [_MigrationAbortedApp] 同样模式（顶层 fallback MaterialApp
/// + `AppLocalizations.of(context)`，由 MaterialApp 自动注入 Localizations）。
class _MigrationFailedApp extends StatelessWidget {
  final String message;
  const _MigrationFailedApp({required this.message});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  l10n.migrationFailedTitle,
                  style: const TextStyle(
                    fontSize: AppTokens.fontSizeButton,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.migrationFailedBody,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // v0.24 round 48 (sp-zh P1-16): 失败时给用户安抚句,降低焦虑。
                // 中文用户尤其敏感 — 精神心理患者迁移失败时最怕"数据丢了"。
                // 这条文案用 l10n key,中英文都友好。
                Text(
                  l10n.migrationFailedReassure,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeCaption,
                    color: AppTokens.textHintColor(context),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTokens.fontSizeCaption,
                color: AppTokens.textHintColor(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
