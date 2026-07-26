// v0.24 round 46 (emil B-13 god class 续拆): vent_compose 抽 3 子 widget
//
// 保存按钮区：取消按钮 (1x) + 保存按钮 (2x, 走 LoadingTextButton)
//
// 高内聚：只关心两个按钮的 UI
// 低耦合：orchestrator 传 isSaving + 2 个 callback
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/loading_text_button.dart';

class VentSaveBar extends StatelessWidget {
  final bool isSaving;
  final String saveLabel;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const VentSaveBar({
    super.key,
    required this.isSaving,
    required this.saveLabel,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isSaving ? null : onCancel,
            child: Text(AppLocalizations.of(context).commonCancel),
          ),
        ),
        const SizedBox(width: AppTokens.spacingSm),
        Expanded(
          flex: 2,
          child: LoadingTextButton(
            label: saveLabel,
            isLoading: isSaving,
            onPressed: isSaving ? null : onSave,
          ),
        ),
      ],
    );
  }
}
