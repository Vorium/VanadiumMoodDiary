// v0.23 round 40 (emil F4 fix): 抽 [SectionHeader] public widget
//
// 之前 settings_page 抽了 `_SectionHeader` (private),但 trend_page 4 处
// 重复 inline 完全相同的 TextStyle(fontSize/fontWeight/color)。
// emil "DRY for taste" — 同一 App 两套写法就是破窗。
// 把 _SectionHeader 提到 public,trend_page 复用。
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';

/// section 标题文字
///
/// 用法:
/// ```dart
/// SectionHeader(title: '最近 30 天')
/// ```
///
/// v0.23 round 40 (emil F4 fix): 之前是 settings_page.dart:714 私有,
/// 提到 public 供 trend_page 4 处 inline 复用
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: AppTokens.fontSizeLabel,
        color: AppTokens.textSecondaryColor(context),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
