// setup_widgets.dart — 首次设置引导页拆分出的辅助类和组件
//
// 从 setup_page.dart 拆分，v0.19 (P1-15)
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';

/// 内存态的药物草稿
class MedDraft {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  String dosageUnit = 'mg';
  final List<TimeOfDay> times = [];

  void attachListener(VoidCallback cb) {
    nameController.addListener(cb);
    dosageController.addListener(cb);
  }

  void dispose() {
    nameController.dispose();
    dosageController.dispose();
  }
}

/// 预置方案应用结果（bottom sheet 返回）
class TemplateApplyResult<T> {
  final T template;
  final bool append;
  const TemplateApplyResult({required this.template, required this.append});
}

/// 法律同意勾选行（checklist + 查看按钮）
class ConsentCheckRow extends StatelessWidget {
  final bool checked;
  final String label;
  final VoidCallback onTap;
  final VoidCallback onView;

  const ConsentCheckRow({
    super.key,
    required this.checked,
    required this.label,
    required this.onTap,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: checked
            ? AppTokens.primaryLightColor(context)
            : AppTokens.surfaceColor(context),
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(
          color: checked ? AppTokens.primary : AppTokens.borderColor(context),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // v0.22 round 29 (emil-50): activeColor 已 deprecated (Flutter 3.32+),
          // 改用 side + fillColor 控制 (M3 标准用法)
          Checkbox(
            value: checked,
            onChanged: (_) => onTap(),
            side: BorderSide(
              color: AppTokens.borderColor(context),
              width: 1.5,
            ),
            fillColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppTokens.primary;
              }
              return null;
            }),
          ),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppTokens.fontSizeLabel,
                color: checked
                    ? AppTokens.textPrimaryColor(context)
                    : AppTokens.textSecondaryColor(context),
                fontWeight: checked ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          // v0.22 round 28 (emil-30): "查看" TextButton 外包 PressFeedback 给 scale 反馈
          // (10+/day 频度, emil 决策框架要求 :active 反馈)
          PressFeedback(
            child: TextButton(
              onPressed: onView,
              child: Text(AppLocalizations.of(context).setupConsentView),
            ),
          ),
          const SizedBox(width: AppTokens.spacingXs),
        ],
      ),
    );
  }
}
