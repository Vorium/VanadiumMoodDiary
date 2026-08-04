// v0.29 round 84 (CBT 思维记录): 5/7 栏 wizard 占位
//
// Task 5 集成需要 switch 引用此 widget, 实际 Stepper + step 内容由 Task 6 实现。
//
// 设计:
// - 占位 widget 让 mood_recorder_page 的 switch 编译通过
// - 5/7 栏用户暂时看到此提示, Task 6 落地后即被替换
// - 频度: 切换到 5/7 栏时显示, 当前 round 内不展示
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';

class CbtWizard extends StatelessWidget {
  const CbtWizard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppTokens.spacingMd),
        child: Text(
          '5/7 栏 wizard\n(Task 6 实现)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
