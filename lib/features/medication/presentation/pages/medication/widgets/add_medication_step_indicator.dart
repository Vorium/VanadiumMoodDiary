// v1.1.0 R116 (god class 拆 round 4): 抽 add_medication_page 进度条
//
// 改前: `add_medication_page.dart` 247L, 进度条 (line 155-176) inline
//   Row + List.generate(3,...) 22 行嵌在 build 内。
// 改后: 抽 AddMedicationStepIndicator 公开 widget, 0 state, 仅注入
//   currentStep + totalSteps。跟 R116 mood_trend_page 抽 3 chart widget
//   同款 "纯展示子 widget 抽" 模式。
//
// 4 层架构: presentation/widgets 公开 widget, 0 state。值注入:
//   [currentStep] (page state 持有) + [totalSteps] (默认 3)。

import 'package:flutter/material.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';

/// 3 步添加用药向导的进度条 (iOS hairline 风格, 高 3pt, 1.5 圆角)
///
/// R116 round 4: 原 inline Row + List.generate (page line 155-176) 1:1
/// 迁移。值注入: [currentStep] + [totalSteps], 0 callback (纯展示)。
class AddMedicationStepIndicator extends StatelessWidget {
  const AddMedicationStepIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
  });

  /// 当前激活步骤 (0-indexed, ≤ 此值的格子被点亮)
  final int currentStep;

  /// 总步数, 默认 3
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.pageMarginH),
      child: Row(
        children: List.generate(totalSteps, (i) {
          final active = i <= currentStep;
          return Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(right: i < totalSteps - 1 ? 4 : 0),
              decoration: BoxDecoration(
                color: active
                    ? AppTokens.primaryColor(context)
                    : AppTokens.dividerColor(context),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          );
        }),
      ),
    );
  }
}
