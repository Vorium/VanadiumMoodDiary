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
/// 3 种命名构造:
/// - [AppListTile.standard] — 普通设置行 (PressFeedback + ListTile)
/// - [AppListTile.carded]   — Card 包裹, 用于 content 区 (提升视觉层级)
/// - [AppListTile.destructive] — 危险操作 (红色 leading/trailing, 暗示删除)
///
/// 用法:
/// ```dart
/// AppListTile.standard(
///   leading: Icon(Icons.history, color: AppTokens.primary),
///   title: Text('历史'),
///   onTap: () => context.push('/history'),
/// )
///
/// AppListTile.carded(
///   leading: Icon(Icons.notifications),
///   title: Text('通知状态'),
///   subtitle: Text('当前: 已开启'),
/// )
/// ```
///
/// v0.24 round 43 (emil U3 P2): 抽 1 个集中器统一 settings_page 8+ 处
/// `PressFeedback + ListTile` 重复模式
/// v0.26 round 57 (emil C-12): 加 standard/carded/destructive 3 命名构造
/// + 透传 dense/contentPadding/onLongPress, 让 ListTile → AppListTile
/// 转换不需要丢 ListTile 特性
class AppListTile extends StatelessWidget {
  /// 普通设置行 (unnamed constructor 跟 .standard 等价)
  const AppListTile({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.dense,
    this.isThreeLine,
    this.contentPadding,
    this.onLongPress,
  })  : _isCarded = false,
        _isDestructive = false;

  /// v0.26 round 57 (emil C-12): 显式 .standard 命名构造
  /// 跟 unnamed constructor 等价, 让调用方一眼看出"标准行, 非 carded 非 destructive"
  const AppListTile.standard({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.dense,
    this.isThreeLine,
    this.contentPadding,
    this.onLongPress,
  })  : _isCarded = false,
        _isDestructive = false;

  /// Card 包裹, 用于 content 区
  const AppListTile.carded({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.dense,
    this.isThreeLine,
    this.contentPadding,
    this.onLongPress,
  })  : _isCarded = true,
        _isDestructive = false;

  /// 危险操作 (留 API 入口, v0.26 未启用具体颜色定制)
  const AppListTile.destructive({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.dense,
    this.isThreeLine,
    this.contentPadding,
    this.onLongPress,
  })  : _isCarded = false,
        _isDestructive = true;

  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;

  /// 可选 onTap: 传了则 PressFeedback 接管 tap (child.onTap 应为 null)
  /// 不传则 PressFeedback 只做 scale 视觉, 适用于 nested ListTile.onTap
  final VoidCallback? onTap;

  /// v0.26 round 57 (emil C-12): 透传 ListTile.dense (紧凑布局)
  final bool? dense;

  /// v0.26 round 57 (emil C-12): 透传 ListTile.isThreeLine (3 行布局)
  final bool? isThreeLine;

  /// v0.26 round 57 (emil C-12): 透传 ListTile.contentPadding
  final EdgeInsetsGeometry? contentPadding;

  /// v0.26 round 57 (emil C-12): 透传 ListTile.onLongPress
  final VoidCallback? onLongPress;

  /// v0.24 round 48 (emil P2-8): carded 模式标志
  final bool _isCarded;

  /// v0.26 round 57 (emil C-12): destructive 模式标志
  /// (留 API 入口, 当前实现跟 standard 一样, 未来可加红色 leading tint)
  final bool _isDestructive;

  @override
  Widget build(BuildContext context) {
    assert(
      !(_isCarded && _isDestructive),
      'AppListTile: carded + destructive 不能同时设置',
    );

    final listTile = ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      // 模式 1 (onTap != null): PressFeedback 接管 tap, ListTile 自身 onTap 置 null
      // 模式 2 (onTap == null): PressFeedback 只做 scale 视觉, 透传 onTap 给 ListTile
      onTap: onTap != null ? null : onTap,
      dense: dense,
      isThreeLine: isThreeLine,
      contentPadding: contentPadding,
      onLongPress: onLongPress,
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
