// v0.32 R109 (god class 拆 round 4): 抽 MedicationConfirmRow 公开 widget
//
// 改前: `_ConfirmRow` 是 `add_medication_page.dart` 598L 内的 private
//   sub-widget (line 564-598, 35L), 跟 3 step inline widget + 8 个 state
//   field + 5 个 helper 混在 1 个 page 文件.
// 改后: 移到 `widgets/medication_confirm_row.dart` 公开 widget, 跟
//   `medication_list_cell.dart` (R109 round 3) / `medication_empty_state_cards.dart`
//   (R109 round 3) / `medication_pill_icon` 同目录. 跟 R31 R108 子 widget
//   抽模式一致.
//
// 4 层架构: presentation/widgets/ 抽公开 widget, 跨 feature 复用.

import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';

/// 用药向导 Step 3 确认行 (label + value 横向布局)
///
/// v0.32 R109 (god class 拆 round 4): 公开化 + 移 `widgets/` 目录.
/// 替代原 `_ConfirmRow` (presentation private).
///
/// 用法:
/// ```dart
/// MedicationConfirmRow(
///   label: l10n.medNameLabel,
///   value: draft.name,
/// )
/// ```
class MedicationConfirmRow extends StatelessWidget {
  const MedicationConfirmRow({
    super.key,
    required this.label,
    required this.value,
  });

  /// 左侧 label (固定 80pt 宽, hint 色)
  final String label;

  /// 右侧 value (扩展, body w500)
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppTokens.fontSizeCaption,
                color: AppTokens.textHintColor(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: AppTokens.fontSizeBody,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
