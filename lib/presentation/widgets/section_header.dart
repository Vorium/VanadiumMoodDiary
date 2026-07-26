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
/// SectionHeader(title: '最近 30 天')                  // 纯文字
/// SectionHeader(title: '设置', leading: Icon(...))    // + 前置 icon
/// SectionHeader(title: '导出', action: TextButton(...))  // + 右侧 action button
/// ```
///
/// v0.23 round 40 (emil F4 fix): 之前是 settings_page.dart:714 私有,
/// 提到 public 供 trend_page 4 处 inline 复用
///
/// v0.24 round 48 (emil P2-9): 加 leading + action 模式
/// 之前 settings_page 多处 inline `Row(Text + IconButton)` / `Row(Text + TextButton)`
/// emil "DRY for taste" — 抽 SectionHeader 的 Row 包装
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.leading,
    this.action,
  });

  /// v0.24 round 48 (emil P2-9): 可选 leading icon (左侧)
  final Widget? leading;

  /// v0.24 round 48 (emil P2-9): 可选 action button (右侧)
  /// 典型用法: TextButton('查看全部')
  final Widget? action;

  final String title;

  @override
  Widget build(BuildContext context) {
    // 纯文字模式: 无 leading + action
    if (leading == null && action == null) {
      return Text(
        title,
        style: TextStyle(
          fontSize: AppTokens.fontSizeLabel,
          color: AppTokens.textSecondaryColor(context),
          fontWeight: FontWeight.w500,
        ),
      );
    }
    // 复合模式: Row(leading + title + action)
    return Row(
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: AppTokens.spacingXs),
        ],
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: AppTokens.fontSizeLabel,
              color: AppTokens.textSecondaryColor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (action != null) ...[
          const SizedBox(width: AppTokens.spacingXs),
          action!,
        ],
      ],
    );
  }
}
