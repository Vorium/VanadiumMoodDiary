// v0.31 round 5 (Apple Health redesign · Phase 2 Task 2.1): PrimaryButton 重写为 3 variant Apple Pill
//
// 历史:
// - v0.27 round 65 (flutter L10 ElevatedButton 迁移): PrimaryButton 集中器
//   9 处 `ElevatedButton` 散落 (assessment_page 3 / setup 4 / empty_state 1 /
//   choose_window_dialog 1), 违反 M3 "PREFER FilledButton over ElevatedButton"。
//
// v0.31 R5 改造:
// - 3 variant: primary (filled) / secondary (tonal) / tertiary (text)
// - 高度 50 (`AppTokens.buttonHeight`)
// - 圆角 14 (`AppTokens.radiusButton`)
// - 字号 17 (`AppTokens.fontSizeButton`) / w600 (`AppTokens.textStyleButton`)
// - 内部包 `PressFeedback` 提供 scale(0.97) 100ms 反馈
// - 新增 `leadingIcon` 可选参数 (icon 颜色跟 button foreground 一致, size 17)
// - 保留: onPressed / child / style / isFullWidth
// - isFullWidth 默认 true (跟 spec 一致, 老 caller 0 改动)
//
// 设计选择:
// - 3 variant 各自走不同 M3 widget: FilledButton / FilledButton.tonal / TextButton
// - base style 用 ButtonStyle 统一应用 minimumSize / shape / textStyle (走 token)
// - user style 可以 override (style.merge 优先级)
// - PressFeedback 用 mode 2 (Listener, 不接管 tap), FilledButton 的 InkWell
//   仍负责 tap + ripple, 跟 PressFeedback 30+ 现有调用点模式一致
// - 跟 SecondaryButton (OutlinedButton) 并存, 两者语义不同:
//   PrimaryButton 是 M3 primary CTA 集中器 (3 variant), SecondaryButton 是
//   outline 风格专用 (次要操作 / 取消)
//
// 后续: 9 处 ElevatedButton caller 切到 PrimaryButton 后, 自动获得 scale 反馈
// (留给后续 task 改 caller, 本 task 只改 PrimaryButton 自己)。
// Apple Health 风格 (spec §4.2 button (50pt height, 14pt radius, w600 fontWeight, scale 0.97 press feedback)) [R32 集中器注释, 防后续误改为 Material 3 风格]


import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';

/// v0.31 round 5 (Apple Health redesign · Phase 2 Task 2.1): 主操作按钮 (3 variant)
///
/// 3 种 variant:
/// - [PrimaryButtonVariant.primary] (默认) → FilledButton, 跟 setup / assessment 风格
/// - [PrimaryButtonVariant.secondary] → FilledButton.tonal, M3 推荐 secondary CTA
/// - [PrimaryButtonVariant.tertiary] → TextButton, 文字按钮 (skip / cancel)
///
/// 默认全宽 (setup / assessment 风格), `isFullWidth: false` 用于 dialog 内
/// (choose_window_dialog 等)。3 variant 内部统一包 `PressFeedback` 提供
/// scale(0.97) 100ms 反馈, 无需 caller 额外包。
///
/// 用法:
/// ```dart
/// // 默认 primary + 全宽 (setup / assessment 风格)
/// PrimaryButton(
///   onPressed: canSubmit ? _submit : null,
///   child: Text(l10n.assessmentSubmit),
/// )
///
/// // secondary (M3 推荐 secondary CTA, 用于 cancel / 取消)
/// PrimaryButton(
///   variant: PrimaryButtonVariant.secondary,
///   onPressed: () => ...,
///   child: Text(l10n.commonCancel),
/// )
///
/// // tertiary 文字按钮 (用于 skip / 跳过)
/// PrimaryButton(
///   variant: PrimaryButtonVariant.tertiary,
///   onPressed: () => ...,
///   child: Text(l10n.commonSkip),
/// )
///
/// // 带 leading icon (icon 颜色自动跟 button foreground 一致)
/// PrimaryButton(
///   leadingIcon: const Icon(Icons.check),
///   onPressed: () => ...,
///   child: const Text('已完成'),
/// )
///
/// // dialog 内 / 非全宽
/// PrimaryButton(
///   isFullWidth: false,
///   onPressed: () => Navigator.pop(context, _selected),
///   child: Text(l10n.commonConfirmOk),
/// )
/// ```
enum PrimaryButtonVariant {
  /// FilledButton (推荐 primary CTA)
  primary,

  /// FilledButton.tonal (M3 推荐 secondary CTA)
  secondary,

  /// TextButton (文字按钮, 用于 skip / cancel)
  tertiary,
}

class PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool isFullWidth;

  /// v0.31 R5 (Apple Health Pill): variant 切换 (primary / secondary / tertiary)
  final PrimaryButtonVariant variant;

  /// v0.31 R5 (Apple Health Pill): 可选 leading icon
  ///
  /// 显示在文字前 (Row[IconTheme(17), SizedBox(spacingXxs), child])。
  /// icon 颜色自动跟 button foreground 一致:
  /// - primary → colorScheme.onPrimary
  /// - secondary → colorScheme.onSecondaryContainer
  /// - tertiary → colorScheme.primary
  final Widget? leadingIcon;

  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.isFullWidth = true,
    this.variant = PrimaryButtonVariant.primary,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    // v0.31 R5: base style 走 token (buttonHeight / radiusButton / textStyleButton)
    // user style 可以 override (style.merge 优先级)
    final baseStyle = ButtonStyle(
      minimumSize: WidgetStateProperty.all(
        const Size(0, AppTokens.buttonHeight),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusButton),
        ),
      ),
      textStyle: WidgetStateProperty.all(
        AppTokens.textStyleButton(context),
      ),
    );
    final effectiveStyle =
        style == null ? baseStyle : baseStyle.merge(style);

    // v0.31 R5: leadingIcon 走 Row[IconTheme(17), SizedBox(spacingXxs), child]
    final Widget effectiveChild = switch (leadingIcon) {
      null => child,
      final icon => Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconTheme(
              data: IconThemeData(
                size: AppTokens.iconSizeInline,
                color: _leadingIconColor(context),
              ),
              child: icon,
            ),
            const SizedBox(width: AppTokens.spacingXxs),
            child,
          ],
        ),
    };

    // v0.31 R5: 3 variant 各自走不同 M3 widget
    final Widget button = switch (variant) {
      PrimaryButtonVariant.primary => FilledButton(
          onPressed: onPressed,
          style: effectiveStyle,
          child: effectiveChild,
        ),
      PrimaryButtonVariant.secondary => FilledButton.tonal(
          onPressed: onPressed,
          style: effectiveStyle,
          child: effectiveChild,
        ),
      PrimaryButtonVariant.tertiary => TextButton(
          onPressed: onPressed,
          style: effectiveStyle,
          child: effectiveChild,
        ),
    };

    // v0.31 R5: 全宽 → SizedBox(width: infinity, height: buttonHeight)
    final Widget sized = isFullWidth
        ? SizedBox(
            width: double.infinity,
            height: AppTokens.buttonHeight,
            child: button,
          )
        : button;

    // v0.31 R5: 包 PressFeedback 提供 scale(0.97) 100ms 反馈
    // mode 2 (Listener, 不接管 tap) → button 的 InkWell 仍负责 tap + ripple
    // v0.32 round 8 (R111 EM-14 fix): onPressed=null (禁用) → enabled=false,
    // 禁用态无 scale + haptic 假反馈
    return PressFeedback(enabled: onPressed != null, child: sized);
  }

  /// v0.31 R5: leadingIcon 颜色跟 button foreground 一致
  Color _leadingIconColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (variant) {
      case PrimaryButtonVariant.primary:
        return scheme.onPrimary;
      case PrimaryButtonVariant.secondary:
        return scheme.onSecondaryContainer;
      case PrimaryButtonVariant.tertiary:
        return scheme.primary;
    }
  }
}
