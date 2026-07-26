// v0.24 round 43 (emil U3 P2): 抽 [AppListTile] 通用 widget
//
// 之前 5+ 处 `PressFeedback(child: ListTile(leading: Icon, title: Text))` 重复:
// - settings_page.dart 8+ 个 (reminders / data export / about / legal / 等等)
// - contact/contacts_list_widget.dart 添加联系人 (D-05 fix)
// - medications_list_widget.dart (Dismissible 包裹, 不在本轮迁移)
// - notification_status_card.dart (settings 自检卡)
//
// emil "cohesion" 原则: 同样的 list 行模式 (PressFeedback + ListTile +
// leading icon primary + title) 重复 5+ 次 = 应该抽 1 个集中器。
//
// 设计选择:
// - 默认包 PressFeedback (scale 反馈必备, emil 原则 #2 "good defaults")
// - leading / title / subtitle / trailing 透传给 ListTile
// - onTap 可选 (null 时 PressFeedback 只做 scale 视觉, child.onTap 接管,
//   跟 PressFeedback 模式 2 一致)
import 'package:flutter/material.dart';

import 'package:chroniccare/presentation/widgets/press_feedback.dart';

/// ListTile + PressFeedback 集中器
///
/// 用法:
/// ```dart
/// AppListTile(
///   leading: Icon(Icons.history, color: AppTokens.primary),
///   title: Text('历史'),
///   onTap: () => context.push('/history'),
/// )
/// ```
///
/// v0.24 round 43 (emil U3 P2): 抽 1 个集中器统一 settings_page 8+ 处
/// `PressFeedback + ListTile` 重复模式
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  }) : _isCarded = false;

  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;

  /// 可选 onTap: 传了则 PressFeedback 接管 tap (child.onTap 应为 null)
  /// 不传则 PressFeedback 只做 scale 视觉, 适用于 nested ListTile.onTap
  final VoidCallback? onTap;

  /// v0.24 round 48 (emil P2-8): carded 模式标志
  final bool _isCarded;

  @override
  Widget build(BuildContext context) {
    final listTile = ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      // 模式 1 (onTap != null): PressFeedback 接管 tap, ListTile 自身 onTap 置 null
      // 模式 2 (onTap == null): PressFeedback 只做 scale 视觉, 透传 onTap 给 ListTile
      onTap: onTap != null ? null : onTap,
    );

    final core = onTap != null
        ? PressFeedback(onTap: onTap, child: listTile)
        : PressFeedback(child: listTile);

    // v0.24 round 48 (emil P2-8): carded 模式 — 包 Card 提升视觉层级
    // (settings 平面 list vs content 区 Card 阴影)
    if (_isCarded) {
      return Card(child: core);
    }
    return core;
  }
}
