// v0.22 round 34 (emil A4): 抽 [LabelledTextField] 通用 widget
//
// 之前 4+ 处 `TextField(controller, decoration: InputDecoration(labelText, hintText, border))` 重复:
// - mood_dialog.dart:103-111 (自由备注)
// - medication/temp_medication_dialog.dart (药品名/剂量)
// - contact 添加 (联系人姓名/电话)
// - setup 4 step (用户名/紧急联系人)
//
// 抽 1 个 widget,统一 label/hint/border 行为,支持 maxLines + errorText。
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';

/// 带 label + hint 的 TextField (OutlineInputBorder)
class LabelledTextField extends StatelessWidget {
  const LabelledTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.errorText,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final String? errorText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        border: const OutlineInputBorder(),
        // v0.22 round 34: 跟 M3 默认一致的 error border 表现
        // (errorText != null 时自动变红)
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacingMd,
          vertical: AppTokens.spacingSm,
        ),
      ),
    );
  }
}
