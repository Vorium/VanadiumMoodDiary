// v1.1.0 R116 (god class 拆 round 4): 抽 add_medication_page 底部按钮
//
// 改前: `add_medication_page.dart` 247L, 底部 SafeArea + Row + 2 PrimaryButton
//   (line 211-241) inline 31 行嵌在 build 内, 状态耦合 (_saving +
//   _currentStep + 2 回调 + 2 l10n 标签)。
// 改后: 抽 AddMedicationStepFooter 公开 widget, 0 state, 注入
//   currentStep + saving + 2 标签字符串 (nextLabel / saveLabel) +
//   2 回调 (onPrev / onNext)。footer 根据 currentStep == totalSteps-1
//   自动切换 next 按钮文案 (callNext 文本 vs save 文本)。
//   跟 R116 round 3 抽 MedicationSlotEntryRow 同款 "值 + 回调注入" 模式。
//
// 4 层架构: presentation/widgets 公开 widget, 0 state。值注入:
//   [currentStep] + [totalSteps] + [saving] + [nextLabel] + [saveLabel]
//   + [prevLabel] + [onPrev] + [onNext] (page 提供)。

import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/primary_button.dart';

/// 3 步添加用药向导的底部 prev/next 按钮 footer
///
/// R116 round 4: 原 SafeArea + Row + 2 PrimaryButton (page line 211-241)
/// 1:1 迁移。currentStep == 0 时只显示 next (全宽, flex 2);
/// currentStep > 0 时显示 prev (flex 1) + next (flex 2), 中间 8pt gap。
/// 最后一步时 next 按钮显示 [saveLabel] 而非 [nextLabel]。
/// next 在 [saving] == true 时禁用 (防双击重复提交)。
class AddMedicationStepFooter extends StatelessWidget {
  const AddMedicationStepFooter({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.saving,
    required this.prevLabel,
    required this.nextLabel,
    required this.saveLabel,
    required this.onPrev,
    required this.onNext,
  });

  /// 当前步骤 (0-indexed)
  final int currentStep;

  /// 总步数, 默认 3
  final int totalSteps;

  /// 是否正在保存 (禁用 next 按钮, 防双击)
  final bool saving;

  /// 上一步按钮文字
  final String prevLabel;

  /// 下一步按钮文字 (非最后一步时显示)
  final String nextLabel;

  /// 保存按钮文字 (最后一步时显示)
  final String saveLabel;

  /// 上一步回调 (currentStep > 0 时触发)
  final VoidCallback onPrev;

  /// 下一步 / 保存回调
  final VoidCallback onNext;

  bool get _isLastStep => currentStep >= totalSteps - 1;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppTokens.pageMarginH),
        child: Row(
          children: [
            if (currentStep > 0)
              Expanded(
                child: PrimaryButton(
                  variant: PrimaryButtonVariant.secondary,
                  isFullWidth: true,
                  onPressed: onPrev,
                  child: Text(prevLabel),
                ),
              ),
            if (currentStep > 0) const SizedBox(width: AppTokens.spacingSm),
            Expanded(
              flex: 2,
              child: PrimaryButton(
                isFullWidth: true,
                onPressed: saving ? null : onNext,
                child: Text(_isLastStep ? saveLabel : nextLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
