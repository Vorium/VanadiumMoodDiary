// v0.30 R108 (P1 god class 拆 #1): 启动期占位 App 集合
//
// 拆前: lib/main.dart 488L (实际 ~539L, 文档数 488 是 R107 报告数)
// 含 main() / _bootstrap() / _loadEnv() / _initTimezones() / _initNotification() /
// _markAppDocsExcludedFromBackup() + 4 占位 widget (_MigrationPromptApp /
// _MigrationAbortedApp / _MigrationFailedApp / _EarlyLoadingApp) + controller +
// _showMigrationConfirmDialog。
//
// 拆后: lib/main.dart 极简 (~80L, 只留 main + bootstrap + 3 init helper),
// 4 占位 widget + controller + dialog 全部到本文件。
//
// 公开 API 列表 (main.dart caller 仍要 import):
//   - MigrationPromptApp (was _MigrationPromptApp)
//   - MigrationAbortedApp (was _MigrationAbortedApp)
//   - MigrationFailedApp (was _MigrationFailedApp)
//   - EarlyLoadingApp (was _EarlyLoadingApp)
//   - MigrationPromptController (was _MigrationPromptController)
//   - showMigrationConfirmDialog (was _showMigrationConfirmDialog)
//
// 命名: 去掉下划线前缀 → public API, 仍可 import
// ('package:chroniccare/main/boot_apps.dart') 调用。
//
// ⚠️ P0 守卫 (R108 P0#12): 4 widget 都不调 developer.log,
//   developer.log 总数仍 3 处 (全在 main.dart 顶层)。
//   本文件不引入 flutter/foundation, 不需要 kReleaseMode 守卫。
//
// 修复原则:
// 1. 保留所有版本号注释 (R95 / R22 / R104 / R62 / R27 round 63 / R45 / R48 / R108 P0-1)
// 2. 保留 _MigrationPromptController 公开 API
// 3. 不重命名 (除下划线 → public)
// 4. 4 占位 widget 公开化, 供 caller 调

import 'package:flutter/material.dart';

import 'package:chroniccare/core/data/services/database_migration.dart';
import 'package:chroniccare/core/data/services/pii_safe_log.dart';
import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';

// v0.30 R108 revisit (P1-050): 替代散落 5 处 `SizedBox(height: 12)` magic
// 12 = "section gap" 视觉心理学最佳 (不跟 token sequence 4/8/16/24 重复, emil
// 决策框架 — "decisions should be nameable")。
// 加到 file-local 集中器, 不污染 AppTokens 设计系统全局 (本文件 4 个占位
// App 共享这一档间距, 是 start-up UI 专用, 不属于业务 spacing)。
const double _kSectionGap = 12.0;

/// 弹 dialog 用的"启动中"App + navigatorKey
///
/// 等待期间显示一个简单的 loading, 弹完 dialog 就销毁。
class MigrationPromptController {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

/// v0.30 R108 (god class 拆): 公开 widget, 原 _MigrationPromptApp
class MigrationPromptApp extends StatelessWidget {
  final MigrationPromptController controller;
  const MigrationPromptApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    // R114 B1-8: 补 localizationsDelegates — 修前裸 MaterialApp 无
    // AppLocalizations delegate, AppLocalizations.of(context) 返 null →
    // 迁移/重置引导页 build 崩 (TypeError), 用户看到白屏无出口。
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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
///
/// R114 B1-8: l10n 必须从 MaterialApp **内部** 解析 — 修前在 build 顶部
/// `AppLocalizations.of(context)` 拿的是 MaterialApp 之上的 context
/// (无 delegates) → null → 崩。改为 home 子 widget 内解析。
class MigrationAbortedApp extends StatelessWidget {
  final Future<void> Function() onRetry;
  const MigrationAbortedApp({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: _MigrationAbortedBody(onRetry: onRetry),
    );
  }
}

class _MigrationAbortedBody extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _MigrationAbortedBody({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: AppTokens.edgeInsetsMd,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pause_circle_outline,
                size: AppTokens.iconSizeEmpty,
                // v0.27 round 63 (P1-1 修复): 走 AppTokens.warningColor
                // 集中器, 替代硬编 Colors.orange (R40+ 漏掉)
                color: AppTokens.warningColor(context),
              ),
              const SizedBox(height: AppTokens.spacingSm),
              Text(
                l10n.migrationAbortedTitle,
                style: const TextStyle(
                  fontSize: AppTokens.fontSizeButton,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: _kSectionGap),
              Text(
                l10n.migrationAbortedBody,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: Text(l10n.migrationAbortedRetry),
      ),
    );
  }
}

/// 迁移失败时的占位 App
///
/// **N31 fix**: 接受已脱敏的友好消息，不再直接显示内部异常
///
/// **v0.24 round 45 (P0 fix)**: 之前 hardcode 中文，en 模式用户看到中文。
/// 改成走 l10n，跟 [MigrationAbortedApp] 同样模式（顶层 fallback MaterialApp
/// + `AppLocalizations.of(context)`，由 MaterialApp 自动注入 Localizations）。
///
/// **v0.30 R95 (sub-spec 7 task 53)**: 内部 fallback 文本 (无法初始化本地数据
/// / 启动上下文尚未就绪) 走 ARB, 不在 bootstrap 阶段硬编码。`errorMessage` 是
/// 内部异常 (脱敏后), 用 l10n.migrationFailedFooter(error) 拼到 footer 区域。
///
/// R114 B1-8: l10n 改从 MaterialApp 内部的 home 子 widget 解析 (修前在
/// build 顶部拿的是无 delegates 的外层 context → null → 崩)。
class MigrationFailedApp extends StatelessWidget {
  /// 内部异常文本 (脱敏后), 走 l10n.migrationFailedFooter 拼到 footer
  final String errorMessage;

  const MigrationFailedApp({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: _MigrationFailedBody(errorMessage: errorMessage),
    );
  }
}

class _MigrationFailedBody extends StatelessWidget {
  final String errorMessage;
  const _MigrationFailedBody({required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: AppTokens.edgeInsetsMd,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: AppTokens.iconSizeEmpty,
                // v0.27 round 63 (P1-1 修复): 走 AppTokens.errorColor
                // 集中器, 替代硬编 Colors.red (R40+ 漏掉)
                color: AppTokens.errorColor(context),
              ),
              const SizedBox(height: AppTokens.spacingSm),
              Text(
                l10n.migrationFailedTitle,
                style: const TextStyle(
                  fontSize: AppTokens.fontSizeButton,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: _kSectionGap),
              // v0.30 R95 task 53: 内部兜底文案走 ARB, 不再硬编码 "无法初始化本地数据"
              // (R45 之前的硬编码 en 模式用户看到中文)
              Text(
                l10n.migrationFailedBody,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: _kSectionGap),
              // v0.30 R95 task 53: 可操作提示
              Text(
                l10n.migrationFailedActionHint,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTokens.spacingSm),
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
          padding: AppTokens.edgeInsetsSm,
          child: Text(
            // v0.30 R95 task 53: footer 走 l10n.migrationFailedFooter
            // ({error} placeholder 拼脱敏后的 errorMessage)
            l10n.migrationFailedFooter(errorMessage),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTokens.fontSizeCaption,
              color: AppTokens.textHintColor(context),
            ),
          ),
        ),
      ),
    );
  }
}

/// R104: 最小 loading App — 启动时立即显示，让用户看到白屏时间缩短
class EarlyLoadingApp extends StatelessWidget {
  const EarlyLoadingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: LoadingSkeleton.fullScreen(),
      ),
    );
  }
}

/// R114 B1-8: 本地数据库与加密 key 失配时的重置引导 App
///
/// 场景: Android 备份恢复只还原了 DB 文件、没还原 Keystore 里的加密 key
/// (或 key 损坏) → SQLCipher "file is not a database" → 修前用户卡死无法
/// 启动, 无任何恢复入口。修后: main.dart 探测失败时 runApp 本 widget,
/// 弹确认对话框给两个出口:
/// - 重试 (数据可能自己恢复, e.g. 备份 App 完成还原后)
/// - 重置本地数据 (删 DB + key, 全新开始 — 二次确认, 绝不静默删)
class DatabaseResetPromptApp extends StatelessWidget {
  final Future<void> Function() onRetry;
  const DatabaseResetPromptApp({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // dialog 逻辑放 home 子 widget — l10n 必须从 MaterialApp 内部解析
      // (修前在 State 顶层 context 拿无 delegates 的外层 context → null → 崩)
      home: _DatabaseResetHome(onRetry: onRetry),
    );
  }
}

class _DatabaseResetHome extends StatefulWidget {
  final Future<void> Function() onRetry;
  const _DatabaseResetHome({required this.onRetry});

  @override
  State<_DatabaseResetHome> createState() => _DatabaseResetHomeState();
}

class _DatabaseResetHomeState extends State<_DatabaseResetHome> {
  @override
  void initState() {
    super.initState();
    // 跟 MigrationPromptApp 同款: runApp 后第一帧再弹 dialog (必须有 Navigator)
    WidgetsBinding.instance.addPostFrameCallback((_) => _prompt());
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _prompt() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.dbResetPromptTitle),
        content: SingleChildScrollView(
          child: Text(l10n.dbResetPromptBody),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'retry'),
            child: Text(l10n.commonRetry),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'reset'),
            child: Text(l10n.dbResetPromptReset),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (action == 'retry') {
      await widget.onRetry();
      return;
    }
    if (action == 'reset') {
      // 二次确认 — 数据不可恢复, 不静默删
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.dbResetPromptReset),
          content: Text(l10n.dbResetPromptConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                foregroundColor: AppTokens.errorColor(ctx),
              ),
              child: Text(l10n.commonDelete),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (confirmed != true) {
        await _prompt(); // 取消 → 回到第一层选择
        return;
      }
      try {
        await DatabaseMigration.resetLocalData();
      } on MigrationException catch (e) {
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.migrationFailedTitle),
            content: Text(e.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.commonRetry),
              ),
            ],
          ),
        );
        if (mounted) await _prompt();
        return;
      }
      await widget.onRetry();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: LoadingSkeleton.fullScreen(),
    );
  }
}

/// 弹升级确认对话框
///
/// **重要**:必须在 runApp 之后调用，否则 showDialog 拿不到 Navigator。
/// 配合 [MigrationPromptApp] 提供的 navigatorKey。
Future<bool?> showMigrationConfirmDialog(
  MigrationPromptController controller,
) async {
  final ctx = controller.navigatorKey.currentContext;
  if (ctx == null) {
    // 极少见：endOfFrame 后还没拿到 context
    // v0.22 round 31 (sp-en P0-4): 之前降级返 `true` 会**自动确认删旧数据**，
    // race 时用户没看到 dialog 数据就丢了。改成降级返 `false`（保守拒绝），
    // 触发 caller 的 `MigrationAbortedApp` abort UI，用户点"重试"再走一次。
    // v0.30 R95 task 53: 内部降级消息仍走 piiSafeLog (dev-only log, 跟
    // l10n 路径分离, 故意不外露)
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
              const SizedBox(height: _kSectionGap),
              Text(l10n.migrationPromptChangesTitle),
              const SizedBox(height: AppTokens.spacingXxs),
              Text(l10n.migrationPromptChangeEncrypt),
              Text(l10n.migrationPromptChangeClear),
              Text(l10n.migrationPromptChangeWarning),
              const SizedBox(height: _kSectionGap),
              Text(l10n.migrationPromptRecommendExport),
              const SizedBox(height: AppTokens.spacingXxs),
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
