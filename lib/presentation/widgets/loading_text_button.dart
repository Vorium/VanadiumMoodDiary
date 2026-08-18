// v0.22 round 34 (emil A1): 抽 [LoadingTextButton] 通用 widget
//
// 之前 4+ 处 `Stack([Text, if saving Spinner])` 重复:
// - mood_dialog.dart:149-165 (保存按钮 saving 态)
// - vent/vent_compose_page.dart:418-431 (保存按钮)
// - settings/settings_page.dart:680-688 (清空数据按钮)
//
// emil 原则 4 "Handle edge cases invisibly" — spinner 中心对齐 + 不响应点击
// + 颜色不破坏 button 文字 = 4 个属性要每次手写,违反"good defaults matter more
// than options"。抽 1 个 widget 一行替代。
//
// v0.24 round 43 (emil P1-01 H-03): 加可选 `icon` 参数,让
// medication_report_dialog 的 FilledButton.icon 也能用集中器
// (icon 位置也在 loading 时切 spinner)
import 'package:flutter/material.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';

/// "保存中／提交中" 状态的 button
///
/// 跟 FilledButton/TextButton 风格一致,只是 isLoading=true 时在文字上叠 spinner。
///
/// 用法: 把原来的 `FilledButton(child: Text(label), onPressed: saving ? null : onTap)`
/// 换成 `LoadingTextButton(label: label, isLoading: saving, onPressed: onTap)`
class LoadingTextButton extends StatelessWidget {
  const LoadingTextButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
    this.variant = LoadingTextButtonVariant.filled,
    this.icon,
  });

  /// 按钮文字
  final String label;

  /// 是否显示 loading (true = 文字被 spinner 盖住,按钮不可点)
  final bool isLoading;

  /// 点击回调
  final VoidCallback? onPressed;

  /// 样式: filled (主操作) / text (次要操作) / tonal (中性)
  final LoadingTextButtonVariant variant;

  /// 可选 icon (loading 时切 spinner)
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    // P3-CLEAN-10: spinner 色按 variant 语义映射 (跟各 variant 正常态
    // foreground 一致) — 修前硬编码 fgOnPrimary (白), outlined/text/tonal
    // 浅底 + isLoading 时白 spinner 不可见。
    // filled → onPrimary (白, 主色底) / tonal → onSecondaryContainer /
    // outlined & text → primary。
    final spinnerColor = switch (variant) {
      LoadingTextButtonVariant.filled => AppTokens.fgOnPrimary(context),
      LoadingTextButtonVariant.tonal =>
        Theme.of(context).colorScheme.onSecondaryContainer,
      LoadingTextButtonVariant.outlined ||
      LoadingTextButtonVariant.text =>
        AppTokens.primaryColor(context),
    };
    return switch (variant) {
      LoadingTextButtonVariant.filled => FilledButton(
          onPressed: isLoading ? null : onPressed,
          child: _ChildStack(
            label: label,
            isLoading: isLoading,
            icon: icon,
            spinnerColor: spinnerColor,
          ),
        ),
      LoadingTextButtonVariant.outlined => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: _ChildStack(
            label: label,
            isLoading: isLoading,
            icon: icon,
            spinnerColor: spinnerColor,
          ),
        ),
      LoadingTextButtonVariant.text => TextButton(
          onPressed: isLoading ? null : onPressed,
          child: _ChildStack(
            label: label,
            isLoading: isLoading,
            icon: icon,
            spinnerColor: spinnerColor,
          ),
        ),
      LoadingTextButtonVariant.tonal => FilledButton.tonal(
          onPressed: isLoading ? null : onPressed,
          child: _ChildStack(
            label: label,
            isLoading: isLoading,
            icon: icon,
            spinnerColor: spinnerColor,
          ),
        ),
    };
  }
}

enum LoadingTextButtonVariant { filled, outlined, text, tonal }

class _ChildStack extends StatelessWidget {
  const _ChildStack({
    required this.label,
    required this.isLoading,
    required this.spinnerColor,
    this.icon,
  });

  final String label;
  final bool isLoading;
  final Color spinnerColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    // v0.24 round 43 (emil P1-01 H-03): 支持可选 icon 槽位
    // (icon 存在时,loading 切 spinner 占位 icon 位置, 跟 FilledButton.icon 体感一致)
    final iconWidget = (icon != null)
        ? SizedBox(
            width: 18,
            height: 18,
            child: isLoading
                ? LoadingSpinner(
                    size: AppTokens.iconSizeInline,
                    color: spinnerColor,
                  )
                : Icon(icon, size: AppTokens.iconSizeInline),
          )
        : null;

    return Stack(
      alignment: Alignment.center,
      children: [
        // 真实内容: icon + label (loading 时, label 仍可见, 但 icon 切 spinner)
        if (iconWidget == null)
          Text(label)
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              const SizedBox(width: AppTokens.spacingXs),
              Text(label),
            ],
          ),
        if (isLoading && iconWidget == null)
          IgnorePointer(
            child: SizedBox(
              width: 18,
              height: 18,
              child: LoadingSpinner(
                size: AppTokens.iconSizeInline,
                color: spinnerColor,
              ),
            ),
          ),
      ],
    );
  }
}
