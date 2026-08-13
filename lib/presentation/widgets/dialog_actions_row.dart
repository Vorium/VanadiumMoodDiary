// v0.27 round 67 (C-3 重构): Dialog 底部 Cancel/Save 按钮行集中器
//
// 背景: 4 处 dialog 底部同款 `actions: [TextButton(cancel), X(save/confirm)]`:
//       - choose_window_dialog.dart    PrimaryButton (sync confirm)
//       - refill_days_dialog.dart      ElevatedButton (sync confirm, 应迁 M3 FilledButton)
//       - edit_medication_dialog.dart  LoadingTextButton (async save with isLoading)
//
// emil "DRY for taste" 原则: 同款视觉 = 同一 widget。
// 抽到 DialogActionsRow 集中器, 统一用 [LoadingTextButton] (variant=filled) 作
// 为 confirm 按钮, 它原生支持 isLoading + label + onPressed, 覆盖 sync confirm
// (isLoading=false) 和 async save (isLoading=true) 两种场景。
//
// 备注: setup_step_welcome / setup_step_medication / setup_step_done 三处是
// 页面级 back/next 导航, 布局是 `Row(TextButton(back), Spacer, PrimaryButton(next))`
// 用 Spacer 把按钮推到两端, 跟 dialog 底部按钮右对齐不同, 不在本重构范围。

import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/loading_text_button.dart';

/// Dialog 底部 Cancel/Confirm 按钮行
///
/// 视觉: 右对齐, TextButton(cancel) + spacingSm + LoadingTextButton(confirm)
/// 用法:
/// ```dart
/// DialogActionsRow(
///   cancelLabel: l10n.commonCancel,
///   onCancel: () => Navigator.pop(context),
///   confirmLabel: l10n.commonSave,
///   onConfirm: _saving ? null : _save,
///   isLoading: _saving,
/// )
/// ```
class DialogActionsRow extends StatelessWidget {
  const DialogActionsRow({
    super.key,
    required this.cancelLabel,
    this.onCancel,
    required this.confirmLabel,
    this.onConfirm,
    this.isLoading = false,
  });

  /// Cancel 按钮文字 (通常是 "取消")
  final String cancelLabel;

  /// Cancel 按钮回调, null = disabled
  final VoidCallback? onCancel;

  /// Confirm 按钮文字 (通常是 "保存" / "确定")
  final String confirmLabel;

  /// Confirm 按钮回调, null = disabled (跟 isLoading 二选一控制禁用)
  final VoidCallback? onConfirm;

  /// Confirm 按钮 loading 态 (true = 文字被 spinner 覆盖, 按钮不可点)
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: isLoading ? null : onCancel,
          child: Text(cancelLabel),
        ),
        const SizedBox(width: AppTokens.spacingSm),
        LoadingTextButton(
          label: confirmLabel,
          isLoading: isLoading,
          onPressed: isLoading ? null : onConfirm,
        ),
      ],
    );
  }
}
