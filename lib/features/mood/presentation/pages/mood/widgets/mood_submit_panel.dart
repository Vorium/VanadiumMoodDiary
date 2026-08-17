// v0.28 (round 64 MoodRecorder god-split): submit panel 从 mood_dialog_actions.dart 重命名
//
// 历史:
// - v0.24 Sprint #5: 从 mood_dialog.dart 抽出 AlertDialog actions 行 (取消 + 保存按钮)
// - v0.28 round 64: mood_dialog_actions → mood_submit_panel (emil P2-2.21 命名一致)
//
// **职责**: 保存按钮 (含 saving 态 spinner) + 取消按钮
// **接口**: stateless, 2 callback + 1 bool
//
// v1.1.0 R114 (Wave D): TextButton/LoadingTextButton → PrimaryButton pill
// (spec §4.2: 50pt height / 14pt radius / w600 / scale 0.97 press feedback):
// - 保存 = PrimaryButton primary (saving 时 child 切 spinner + disabled)
// - 取消 = PrimaryButton secondary
// Row 两等宽, 跟 iOS dialog 按钮行惯例一致。
//
// emil 设计决策 (保留自 v0.24):
// - Stateless, 2 callback + 1 bool
// - emil 频度决策: tens/day 频度, 走 PressFeedback 标准反馈
//
// 已知限制 (跟 emil P2-2.21 任务描述差距):
// - 任务说"save 按钮 + 庆祝动画 + 错误处理 + 上次心情 链接", 但本项目 R24
//   已按职责拆: 错误处理走 _MoodRecorderPageState._save() 内部 (l10n
//   snackbar), 庆祝动画 / 上次心情链接是产品新功能, 不在本 god-split 范围。
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/widgets/primary_button.dart';

/// 提交面板 (取消 + 保存按钮)
///
/// saving=true 时保存按钮变 spinner, 取消按钮禁用。
class MoodSubmitPanel extends StatelessWidget {
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const MoodSubmitPanel({
    super.key,
    required this.saving,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: PrimaryButton(
            variant: PrimaryButtonVariant.secondary,
            onPressed: saving ? null : onCancel,
            child: Text(l10n.commonCancel),
          ),
        ),
        const SizedBox(width: AppTokens.spacingSm),
        Expanded(
          child: PrimaryButton(
            variant: PrimaryButtonVariant.primary,
            onPressed: saving ? null : onSave,
            child: saving
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LoadingSpinner(
                        size: AppTokens.iconSizeInline,
                        color: AppTokens.fgOnPrimary(context),
                      ),
                      const SizedBox(width: AppTokens.spacingXs),
                      Text(l10n.commonSave),
                    ],
                  )
                : Text(l10n.commonSave),
          ),
        ),
      ],
    );
  }
}
