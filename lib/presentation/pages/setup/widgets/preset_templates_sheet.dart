// v0.32 R109 (god class 拆 round 5): 抽 PresetTemplatesSheetContent 公开 widget
//
// 改前: `setup_page_state.dart` 560L 内嵌 `_showPresetTemplatesSheet` (line 281-389,
//   109L), 包含:
//   1. showModalBottomSheet (line 283-352, 70L) modal content 拼装
//   2. setState 应用 template (line 356-377, 22L)
//   3. snackBar 提示 (line 382-388, 7L)
//   modal content 70L 是纯 widget 渲染, 跟 state 业务逻辑混.
// 改后: 抽 modal content 到 `widgets/preset_templates_sheet.dart` 公开 widget,
//   `setup_page_state` 只负责 showModalBottomSheet 调 + setState 应用结果.
//   跟 R31 R108 + R109 round 3-4 子 widget 抽模式一致.
//
// 4 层架构: presentation/widgets/ 抽公开 widget, 跨 feature 复用.

import 'package:flutter/material.dart';

import 'package:chroniccare/core/data/services/preset_medication_templates.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/setup/setup_widgets.dart';
import 'package:chroniccare/presentation/services/preset_med_l10n.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';

/// Setup Step 2 预设模板选择 modal content
///
/// v0.32 R109 (god class 拆 round 5): 公开化 + 移 `widgets/` 目录.
/// 替代原 `_showPresetTemplatesSheet` 内嵌的 showModalBottomSheet builder.
///
/// 用法:
/// ```dart
/// final result = await showModalBottomSheet<TemplateApplyResult<MedicationTemplate>>(
///   context: context,
///   isScrollControlled: true,
///   builder: (ctx) => PresetTemplatesSheetContent(
///     hasExistingMeds: _meds.isNotEmpty,
///   ),
/// );
/// ```
class PresetTemplatesSheetContent extends StatelessWidget {
  const PresetTemplatesSheetContent({super.key, required this.hasExistingMeds});

  /// 是否已添加药物 (true → 选 template 时 append, false → 替换)
  final bool hasExistingMeds;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacingMd,
          vertical: AppTokens.spacingMd,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTokens.spacingSm),
              child: Text(
                l10n.setupPresetTitle,
                style: const TextStyle(
                  fontSize: AppTokens.fontSizeTitle,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: AppTokens.spacingSm),
              child: Text(
                l10n.setupPresetDescription,
                style: TextStyle(
                  color: AppTokens.textSecondaryColor(context),
                  fontSize: AppTokens.fontSizeLabel,
                ),
              ),
            ),
            const SizedBox(height: AppTokens.spacingSm),
            for (final t in kMedicationTemplates)
              // v0.26 round 57 (emil C-12): 走 AppListTile.carded 集中器
              AppListTile.carded(
                leading:
                    // v0.24 round 48 (sp-zh P1-17): emoji 视觉 < 文字,保持 fontSizeTitle 不变
                    // (不是 token 化遗漏,是 deliberate 选择 — emoji 渲染有 size cap)
                    Text(
                  t.emoji,
                  style: const TextStyle(
                    fontSize: AppTokens.fontSizeTitle,
                  ),
                ),
                title: Text(
                  // v0.28 round 65 (spzh P2-G): name 走 i18n
                  t.nameL10n(l10n),
                  // v0.26 round 57 (emil B-10): 走 textStyleLabelMedium 集中器
                  // 替代内联 TextStyle(w500)  (ListTile.title 默认 fontSizeLabel)
                  style: AppTokens.textStyleLabelMedium(context),
                ),
                subtitle: Text(t.descriptionL10n(l10n)),
                trailing: const Icon(Icons.add_circle_outline),
                onTap: () => Navigator.of(context).pop(
                  TemplateApplyResult(
                    template: t,
                    append: hasExistingMeds,
                  ),
                ),
              ),
            const SizedBox(height: AppTokens.spacingMd),
          ],
        ),
      ),
    );
  }
}
