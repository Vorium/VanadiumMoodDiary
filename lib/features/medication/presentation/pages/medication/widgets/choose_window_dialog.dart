import 'package:flutter/material.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/presentation/widgets/dialog_actions_row.dart';

/// 选择时间窗口的 AlertDialog
///
/// 选项：近 7 / 14 / 30 天（默认 14）
/// 返回：选中的天数（int），或 null（用户取消）
///
/// v0.17 round 7 (A7 emil 动效): AlertDialog 默认动画
/// - showDialog() 默认 fade + scale from center (M3 标准)
/// - emil 决策框架: modals 居中 + 150-300ms standard animation
/// - 替代项: PageRouteBuilder 配合 CustomTransitionPage 可覆盖，但项目用默认够用
/// - 找 bug 方法： 用户报"弹窗出现／消失太突兀"再考虑自定义
class ChooseWindowDialog extends StatefulWidget {
  const ChooseWindowDialog({super.key});

  @override
  State<ChooseWindowDialog> createState() => _ChooseWindowDialogState();
}

class _ChooseWindowDialogState extends State<ChooseWindowDialog> {
  int _selected = 14;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context).settingsMedReportChooseTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppLocalizations.of(context).settingsMedReportChooseSubtitle,
            style: TextStyle(
              fontSize: AppTokens.fontSizeCaption,
              color: AppTokens.textSecondaryColor(context),
            ),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          // RadioGroup 替代 deprecated 的 RadioListTile.groupValue/onChanged（Flutter 3.32+）
          RadioGroup<int>(
            groupValue: _selected,
            onChanged: (v) => setState(() => _selected = v ?? 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<int>(
                  title: Text(
                    AppLocalizations.of(context).settingsMedReportWindow7,
                  ),
                  subtitle: Text(AppLocalizations.of(context).window7Subtitle),
                  value: 7,
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<int>(
                  title: Text(
                    AppLocalizations.of(context).settingsMedReportWindow14,
                  ),
                  subtitle: Text(AppLocalizations.of(context).window14Subtitle),
                  value: 14,
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<int>(
                  title: Text(
                    AppLocalizations.of(context).settingsMedReportWindow30,
                  ),
                  subtitle: Text(AppLocalizations.of(context).window30Subtitle),
                  value: 30,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // v0.27 round 67 (C-3): 走 DialogActionsRow 集中器
        DialogActionsRow(
          cancelLabel: AppLocalizations.of(context).commonCancel,
          onCancel: () => Navigator.pop(context),
          confirmLabel:
              AppLocalizations.of(context).settingsActionGenerateReport,
          onConfirm: () => Navigator.pop(context, _selected),
        ),
      ],
    );
  }
}
