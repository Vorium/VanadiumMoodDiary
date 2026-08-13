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
// - onTap 可选: 不传时行不可点 (PressFeedback disabled + ListTile.onTap
//   恒 null), 无 scale + haptic 假反馈 (v0.32 round 8 EM-14b)
import 'package:flutter/material.dart';

import 'package:chroniccare/presentation/widgets/press_feedback.dart';

/// ListTile + PressFeedback 集中器
///
/// 2 种命名构造:
/// - [AppListTile.standard] — 普通设置行 (PressFeedback + ListTile)
/// - [AppListTile.carded]   — Card 包裹, 用于 content 区 (提升视觉层级)
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
/// v0.26 round 57 (emil C-12): 加 standard/carded 2 命名构造
/// + 透传 dense/contentPadding/onLongPress, 让 ListTile → AppListTile
/// 转换不需要丢 ListTile 特性
/// v0.32 round 8 (R112 EM-19): 删 destructive 命名构造 + _isDestructive
/// (v0.26 加的"留 API 入口"从 build() 0 读取 = 假 API, 0 caller 实锤后删)
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
  })  : _isCarded = false;

  /// v0.26 round 57 (emil C-12): 显式 .standard 命名构造
  /// 跟 unnamed constructor 等价, 让调用方一眼看出"标准行, 非 carded"
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
  })  : _isCarded = false;

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
  })  : _isCarded = true;

  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;

  /// 可选 onTap: 传了则 PressFeedback 接管 tap (child.onTap 应为 null)
  /// 不传则整行不可点 — PressFeedback disabled (0 scale 0 haptic) +
  /// ListTile.onTap 恒 null (v0.32 round 8 EM-14b fix, 修前无 onTap 行
  /// 仍有 scale + haptic 假反馈)
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

  @override
  Widget build(BuildContext context) {
    final listTile = ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      // 模式 1 (onTap != null): PressFeedback 接管 tap, ListTile 自身 onTap 置 null
      // 模式 2 (onTap == null): 行不可点, ListTile.onTap 恒 null —
      //   PressFeedback 也 disabled (v0.32 round 8 EM-14b fix, 无假反馈)
      onTap: onTap != null ? null : onTap,
      dense: dense,
      isThreeLine: isThreeLine,
      contentPadding: contentPadding,
      onLongPress: onLongPress,
    );

    // v0.32 round 8 (R112 EM-14b fix): enabled = onTap != null —
    // 无 onTap 的不可点行 PressFeedback disabled (0 scale 0 haptic),
    // 修前不可点行 (settings 关于/免责声明行) 按下仍有 scale +
    // Haptics.light 假反馈 (视觉"能按"、行为"没反应")
    final core = PressFeedback(
      enabled: onTap != null,
      onTap: onTap,
      child: listTile,
    );

    // v0.24 round 48 (emil P2-8): carded 模式 — 包 Card 提升视觉层级
    // (settings 平面 list vs content 区 Card 阴影)
    if (_isCarded) {
      return Card(child: core);
    }
    return core;
  }
}
