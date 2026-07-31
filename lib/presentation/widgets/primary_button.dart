// v0.27 round 65 (flutter L10 ElevatedButton 迁移): PrimaryButton 集中器
//
// 背景:
// - 9 处 `ElevatedButton` 散落 (assessment_page 3 / setup 4 / empty_state 1 /
//   choose_window_dialog 1), 违反 M3 "PREFER FilledButton over ElevatedButton"。
// - `LoadingTextButton` 已是 FilledButton 集中器模式参考。
//
// 设计:
// - 包装 FilledButton.tonal (M3 推荐 primary CTA)
// - 接受 onPressed / child / style, 跟 FilledButton 一致 API
// - 默认 full width, 跟 setup 4 处 + assessment 1 处预期一致
// - 自定义 mode: `isFullWidth=false` 用于 dialog 内 (choose_window_dialog 等)
//
// 后续: 9 处全替换, 后续新代码优先用 PrimaryButton 而不是直接 FilledButton。

import 'package:flutter/material.dart';

/// v0.27 round 65 (flutter L10 ElevatedButton 迁移): 主操作按钮
///
/// 包装 M3 FilledButton (推荐 primary CTA), 集中 9 处散落 ElevatedButton:
/// - lib/presentation/pages/assessment/assessment_page.dart (3 处)
/// - lib/presentation/pages/setup/setup_step_consent.dart (1 处)
/// - lib/presentation/pages/setup/setup_step_welcome.dart (1 处)
/// - lib/presentation/pages/setup/setup_step_medication.dart (1 处)
/// - lib/presentation/pages/setup/setup_step_done.dart (1 处)
/// - lib/presentation/widgets/empty_state.dart (1 处)
/// - lib/presentation/pages/medication/widgets/choose_window_dialog.dart (1 处)
///
/// 用法:
/// ```dart
/// // 默认全宽 (setup / assessment 风格)
/// PrimaryButton(
///   onPressed: canSubmit ? _submit : null,
///   child: Text(l10n.assessmentSubmit),
/// )
///
/// // dialog 内 / 非全宽
/// PrimaryButton(
///   isFullWidth: false,
///   onPressed: () => Navigator.pop(context, _selected),
///   child: Text(l10n.commonConfirmOk),
/// )
/// ```
class PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool isFullWidth;

  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: onPressed,
      style: style,
      child: child,
    );

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }
    return button;
  }
}
