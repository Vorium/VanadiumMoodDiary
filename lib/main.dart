import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:async';

import 'package:chroniccare/app.dart';
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/repositories/check_in/check_in_repository_impl.dart';
import 'package:chroniccare/core/data/services/assessment_reminder_service.dart';
import 'package:chroniccare/core/data/services/database_migration.dart';
import 'package:chroniccare/core/data/services/notification_service.dart';
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
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 加载 .env（缺失时静默跳过）
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('⚠️ .env 加载失败（首次启动正常）：$e');
  }

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
    debugPrint('⚠️ 通知服务初始化失败（不影响核心功能）：$e');
    notificationError = e.toString();
  }

  // 4. 执行迁移（migrateIfNeeded 失败必须 throw,见 database_migration.dart）
  try {
    await DatabaseMigration.migrateIfNeeded();
  } on MigrationException catch (e) {
    // MigrationException.message 已经是面向用户的友好文本
    runApp(_MigrationFailedApp(message: e.message));
    return;
  } catch (e, st) {
    debugPrint('⚠️ 数据库迁移失败：$e\n$st');
    // N31 fix: 给用户友好消息,详细错只 log
    runApp(const _MigrationFailedApp(message: '无法初始化本地数据'));
    return;
  }

  // 5. 启动完整 App
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
      ],
      child: const AppRoot(),
    ),
  );

  // 6. v0.13 (Round 7): App 启动后异步跑一次 AssessmentReminder.onAppStart
  //    用 unawaited 防止阻塞 runApp
  //    不放到 runApp 内的 ProviderScope 是因为我们要 db 已经 ready
  unawaited(_scheduleAssessmentReminderOnStart(notificationService));
}

Future<void> _scheduleAssessmentReminderOnStart(
  NotificationService notificationService,
) async {
  // 等 DB / provider tree ready — 一个 frame 就够
  await Future<void>.delayed(const Duration(milliseconds: 100));
  // v0.14 fix: 独立建一条 db connection,函数结束必须 close
  // 旧实现: db 从来没 close,每次启动泄漏一个 connection
  AppDatabase? localDb;
  try {
    // 复用已 init 的 notificationService, 走 provider tree 拿 db
    // 这里不依赖 ProviderScope, 手动构造一条 service 跑
    localDb = AppDatabase();
    final service = AssessmentReminderService(
      checkInRepo: CheckInRepositoryImpl(localDb),
      notificationService: notificationService,
    );
    await service.onAppStart();
  } catch (e) {
    debugPrint('⚠️ AssessmentReminder.onAppStart 失败（不影响核心功能）：$e');
  } finally {
    await localDb?.close();
  }
}

/// 弹升级确认对话框
///
/// **重要**:必须在 runApp 之后调用,否则 showDialog 拿不到 Navigator。
/// 配合 [_MigrationPromptApp] 提供的 navigatorKey。
Future<bool?> _showMigrationConfirmDialog(
  _MigrationPromptController controller,
) async {
  final ctx = controller.navigatorKey.currentContext;
  if (ctx == null) {
    // 极少见：endOfFrame 后还没拿到 context
    debugPrint('⚠️ migration dialog: navigator context 仍为 null，降级放行');
    return true;
  }
  return showDialog<bool>(
    context: ctx,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('升级到 v0.9'),
      content: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('检测到本地有旧版本数据。'),
            SizedBox(height: 12),
            Text('本次升级会：'),
            SizedBox(height: 4),
            Text('• 启用数据库加密（保护你的隐私）'),
            Text('• 清空旧版本的所有打卡记录'),
            Text('（旧版本没有"导出数据"功能，原始数据无法恢复）'),
            SizedBox(height: 12),
            Text('建议：先在旧版 App 内完成"导出数据"备份，再升级。'),
            SizedBox(height: 4),
            Text('若旧版已卸载无法导出，可以直接点"继续升级"。'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('继续升级'),
        ),
      ],
    ),
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
/// **N12 fix**: "已备份,重试"按钮调 [main] 重启流程,不必杀进程。
class _MigrationAbortedApp extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _MigrationAbortedApp({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.pause_circle_outline,
                  size: 64,
                  color: Colors.orange,
                ),
                SizedBox(height: 16),
                Text(
                  '升级已取消',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 12),
                Text(
                  '请先在旧版本 App 内完成"导出数据"备份，\n'
                  '备份完成后点下方按钮继续升级。',
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
          label: const Text('已备份，继续升级'),
        ),
      ),
    );
  }
}

/// 通知初始化结果（注入到 provider 树,首页用）
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
/// **N31 fix**: 接受已脱敏的友好消息,不再直接显示内部异常
class _MigrationFailedApp extends StatelessWidget {
  final String message;
  const _MigrationFailedApp({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  '启动失败',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 12),
                Text(
                  '无法初始化本地数据。\n'
                  '请尝试：\n'
                  '1) 重启 App\n'
                  '2) 卸载后重装\n'
                  '如反复出现，请反馈给我们。',
                  textAlign: TextAlign.center,
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
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        ),
      ),
    );
  }
}
