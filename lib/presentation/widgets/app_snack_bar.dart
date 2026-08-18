import 'package:flutter/material.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

/// v0.17 round 14 (P1-7): 集中 SnackBar 文案 + 时长
///
/// 之前 30+ 处 SnackBar 各自 hardcode 中文 ('保存失败：$e', '删除失败：$e' 等),
/// v0.17 集中到 AppLocalizations.arb,本文件提供统一 helper:
///   - error(action, error) → SnackBar
///   - info(message) → SnackBar
///
/// 时长统一:
///   - 错误: 4 秒 (用户需要时间读错误信息)
///   - 信息: 2 秒 (短确认)
///
/// 用法:
/// ```dart
/// ScaffoldMessenger.of(context).showSnackBar(
///   AppSnackBar.error(context, action: '保存', error: e),
/// );
/// ```
class AppSnackBar {
  AppSnackBar._();

  /// 错误消息 SnackBar
  ///
  /// [action] 短中文动作名 (e.g. '保存', '删除', '导出'),
  /// 会拼到 '$action 失败：$error' 模板
  static SnackBar error(
    BuildContext context, {
    required String action,
    Object? error,
  }) {
    final l10n = AppLocalizations.of(context);
    final msg = l10n.snackbarErrorTemplate(
      action,
      error?.toString() ?? 'unknown',
    );
    return SnackBar(
      content: Text(msg),
      duration: AppTokens.snackBarDurationLong,
    );
  }

  /// 短信息 SnackBar
  static SnackBar info(BuildContext context, String message) {
    return SnackBar(
      content: Text(message),
      duration: AppTokens.snackBarDurationShort,
    );
  }

  /// v0.21 Round 23 (P1-26): 带 Undo 操作的 SnackBar
  ///
  /// 用于 Dismissible swipe-to-dismiss 后,让用户反悔。
  /// 时长 4 秒,长于 info(2s),给用户反应窗口。
  /// [onUndo] 异步操作(重新插入条目),在 Scaffold 关闭前完成。
  /// 注意: caller 需保证 [onUndo] 内部捕获异常(不应让 undo 失败再
  /// 触发另一个 error SnackBar)。
  static SnackBar undo(
    BuildContext context, {
    required String message,
    required Future<void> Function() onUndo,
  }) {
    final l10n = AppLocalizations.of(context);
    return SnackBar(
      content: Text(message),
      duration: AppTokens.snackBarDurationLong,
      action: SnackBarAction(
        label: l10n.snackbarActionUndo,
        onPressed: () {
          // fire-and-forget: undo 操作内部应自带错误处理
          onUndo();
        },
      ),
    );
  }

  /// v0.23 (Round 31): 带 action 按钮的持久 SnackBar
  ///
  /// 用于"已保存情绪日记" + "回放"按钮 场景:默认 4 秒不够用户点回放,
  /// 加 [persistentDuration] = 6 秒 (>= long 但不超过 8 秒避免占屏太久)。
  ///
  /// [onAction] 异步或同步操作,内部应自行处理异常 (fire-and-forget)。
  /// action 文字走 l10n.moodActionPlay 复用现有 '回放' 翻译键。
  static SnackBar withAction(
    BuildContext context, {
    required String message,
    required String actionLabel,
    required Future<void> Function() onAction,
  }) {
    return SnackBar(
      content: Text(message),
      duration: AppTokens.snackBarDurationLong * 2, // 8 秒 — 比 undo 长
      action: SnackBarAction(
        label: actionLabel,
        onPressed: () {
          onAction();
        },
      ),
    );
  }

  // ============= v0.23 (Round 37) P1: showX 便捷工厂 =============
  //
  // 之前 55+ 处直接 `ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(...)))`
  // 绕开集中器。补 showX 系列直接接管 showSnackBar,调用方 1 行搞定。
  //
  // 用法:
  // ```dart
  // AppSnackBar.showInfo(context, l10n.someKey);
  // AppSnackBar.showError(context, action: '保存', error: e);
  // AppSnackBar.showUndo(context, message: l10n.deletedMsg, onUndo: () => ...);
  // AppSnackBar.showWithAction(context, message: ..., actionLabel: ..., onAction: ...);
  // ```

  /// 弹出 error SnackBar
  static void showError(
    BuildContext context, {
    required String action,
    Object? error,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      AppSnackBar.error(context, action: action, error: error),
    );
  }

  /// 弹出 info SnackBar
  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      AppSnackBar.info(context, message),
    );
  }

  /// 弹出 undo SnackBar
  static void showUndo(
    BuildContext context, {
    required String message,
    required Future<void> Function() onUndo,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      AppSnackBar.undo(context, message: message, onUndo: onUndo),
    );
  }

  /// 弹出带 action SnackBar
  static void showWithAction(
    BuildContext context, {
    required String message,
    required String actionLabel,
    required Future<void> Function() onAction,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      AppSnackBar.withAction(
        context,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );
  }
}
