// v0.22 round 34 (emil A1): 抽 [LoadingTextButton] 通用 widget
//
// 之前 4+ 处 `Stack([Text, if saving Spinner])` 重复:
// - mood_dialog.dart:149-165 (保存按钮 saving 态)
// - medication/temp_medication_dialog.dart:128-141 (保存按钮)
// - vent/vent_compose_page.dart:418-431 (保存按钮)
// - settings/settings_page.dart:680-688 (清空数据按钮)
//
// emil 原则 4 "Handle edge cases invisibly" — spinner 中心对齐 + 不响应点击
// + 颜色不破坏 button 文字 = 4 个属性要每次手写,违反"good defaults matter more
// than options"。抽 1 个 widget 一行替代。
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';

/// "保存中/提交中" 状态的 button
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
  });

  /// 按钮文字
  final String label;

  /// 是否显示 loading (true = 文字被 spinner 盖住,按钮不可点)
  final bool isLoading;

  /// 点击回调
  final VoidCallback? onPressed;

  /// 样式: filled (主操作) / text (次要操作) / tonal (中性)
  final LoadingTextButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      LoadingTextButtonVariant.filled => FilledButton(
          onPressed: isLoading ? null : onPressed,
          child: _ChildStack(label: label, isLoading: isLoading),
        ),
      LoadingTextButtonVariant.text => TextButton(
          onPressed: isLoading ? null : onPressed,
          child: _ChildStack(label: label, isLoading: isLoading),
        ),
      LoadingTextButtonVariant.tonal => FilledButton.tonal(
          onPressed: isLoading ? null : onPressed,
          child: _ChildStack(label: label, isLoading: isLoading),
        ),
    };
  }
}

enum LoadingTextButtonVariant { filled, text, tonal }

class _ChildStack extends StatelessWidget {
  const _ChildStack({required this.label, required this.isLoading});

  final String label;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(label),
        if (isLoading)
          IgnorePointer(
            child: SizedBox(
              width: 18,
              height: 18,
              child: LoadingSpinner(
                size: 18,
                // v0.22 round 34: fgOnPrimary 是函数, 没法在 const 构造里用,
                // 把 IgnorePointer 改成 runtime 版本 (去掉 const)
                color: AppTokens.fgOnPrimary(context),
              ),
            ),
          ),
      ],
    );
  }
}
