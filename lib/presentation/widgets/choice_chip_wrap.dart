// v0.27 round 67 (C-5 重构): ChoiceChipWrap 集中器
//
// 背景: 2 处 `Wrap(spacing: 8, runSpacing: 8, [ChoiceChip])` 同款
//       (reminders_hub_page.dart:305-320 / :446-461)。
//       emil "cohesion" 原则: 视觉同款 = 同一 widget。
//
// 抽到 ChoiceChipWrap<T> 集中器, 顺便把硬编码 8 改走 AppTokens.spacingXs。

import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';

/// 单选 chip 组 (Wrap 排版, 只允许选 1 个)
///
/// 用法:
/// ```dart
/// ChoiceChipWrap<int>(
///   options: [3, 5, 7, 14, 30],
///   selected: _days,
///   labelOf: (d) => l10n.reminderHubEveryNDays(d),
///   onSelect: (d) => setState(() => _days = d),
///   // 异步操作期间禁用:
///   disabled: _busy,
/// )
/// ```
///
/// 泛型 [T] 让 caller 用 int / enum / String 任何类型, 标签转换由 [labelOf] 完成。
class ChoiceChipWrap<T> extends StatelessWidget {
  const ChoiceChipWrap({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelect,
    this.disabled = false,
  });

  final List<T> options;

  final T selected;

  /// 选项 → 显示文字
  final String Function(T) labelOf;

  /// 选中某项回调 (传入被选中的值, 不会因"取消选中"被调)
  final ValueChanged<T> onSelect;

  /// 是否禁用 (true = 所有 chip 不可点, 用于异步操作期间)
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTokens.spacingXs,
      runSpacing: AppTokens.spacingXs,
      children: options.map((o) {
        return ChoiceChip(
          label: Text(labelOf(o)),
          selected: o == selected,
          onSelected: disabled
              ? null
              : (isSelected) {
                  // ChoiceChip.onSelected 是 nullable → 当 null 时 chip 不可点
                  // 选中时 isSelected=true, 取消时 isSelected=false
                  // 我们要的是"单选 = 选了才切", 取消 (deselect) 不响应
                  if (isSelected) onSelect(o);
                },
        );
      }).toList(growable: false),
    );
  }
}
