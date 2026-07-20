import 'package:flutter/material.dart';

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
      duration: const Duration(seconds: 4),
    );
  }

  /// 短信息 SnackBar
  static SnackBar info(BuildContext context, String message) {
    return SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
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
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label: l10n.snackbarActionUndo,
        onPressed: () {
          // fire-and-forget: undo 操作内部应自带错误处理
          onUndo();
        },
      ),
    );
  }
}
