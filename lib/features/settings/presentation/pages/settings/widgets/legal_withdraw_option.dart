// v1.1.0+167 R122 P2-2 (legal_page 555L 拆 3 facade 模式):
// 抽 _WithdrawOption 公开 widget — vent 撤回 3 选 1 dialog 内部选项
//
// 公开 widget 命名: _WithdrawOption → LegalWithdrawOption
// v1.1.0 R113 (BUG 8b): 修前是裸 Row — 无 onTap/InkWell/GestureDetector,
// "立即删除"/"加密封存"两个选项点不了 (R82.5 引入即存在), 用户只能点
// "取消"。修: choice 字段 + InkWell 包裹, tap = pop(choice) 让
// _showVentWithdrawDialog 的 showDialog<LegalWithdrawChoice> 结果
// 传回 _toggle。

import 'package:flutter/material.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/legal_withdraw_choice.dart';

/// vent 撤回 3 选 1 dialog 内部选项 (立即删除 / 加密封存)
class LegalWithdrawOption extends StatelessWidget {
  final LegalWithdrawChoice choice;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const LegalWithdrawOption({
    super.key,
    required this.choice,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(choice),
      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacingXs,
          vertical: AppTokens.spacingXs,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: AppTokens.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTokens.textStyleBodyStrong(context),
                  ),
                  const SizedBox(height: AppTokens.spacingXxs),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: AppTokens.fontSizeCaption,
                      color: AppTokens.textHintColor(context),
                      height: AppTokens.lineHeightSnug,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
