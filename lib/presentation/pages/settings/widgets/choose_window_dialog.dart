import 'package:flutter/material.dart';

import 'package:chroniccare/core/l10n/strings.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';

/// 选择时间窗口的 AlertDialog
///
/// 选项：近 7 / 14 / 30 天（默认 14）
/// 返回：选中的天数（int），或 null（用户取消）
///
/// v0.17 round 7 (A7 emil 动效): AlertDialog 默认动画
/// - showDialog() 默认 fade + scale from center (M3 标准)
/// - emil 决策框架: modals 居中 + 150-300ms standard animation
/// - 替代项: PageRouteBuilder 配合 CustomTransitionPage 可覆盖,但项目用默认够用
/// - 找 bug 方法: 用户报"弹窗出现/消失太突兀"再考虑自定义
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
      title: const Text(Strings.settingsMedReportChooseTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            Strings.settingsMedReportChooseSubtitle,
            style: TextStyle(
              fontSize: AppTokens.fontSizeCaption,
              color: AppTokens.textSecondary,
            ),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          // RadioGroup 替代 deprecated 的 RadioListTile.groupValue/onChanged（Flutter 3.32+）
          RadioGroup<int>(
            groupValue: _selected,
            onChanged: (v) => setState(() => _selected = v ?? 14),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<int>(
                  title: Text(Strings.settingsMedReportWindow7),
                  subtitle: Text('一周内（适合周复诊）'),
                  value: 7,
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<int>(
                  title: Text(Strings.settingsMedReportWindow14),
                  subtitle: Text('两周内（推荐）'),
                  value: 14,
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<int>(
                  title: Text(Strings.settingsMedReportWindow30),
                  subtitle: Text('一个月内（适合月度评估）'),
                  value: 30,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(Strings.commonCancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('生成报告'),
        ),
      ],
    );
  }
}
