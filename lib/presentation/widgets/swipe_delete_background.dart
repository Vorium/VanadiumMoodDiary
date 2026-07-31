// v0.27 round 67 (C-6 重构): SwipeDeleteBackground 集中器
//
// 背景: 3 处 Dismissible 左滑删除的"红底 + delete icon"同款:
//       - vent_list_page.dart:178-190        radiusCard 圆角
//       - contacts_list_widget.dart:54-64    无圆角 (ListTile 套 Card 列表)
//       - medication_row.dart:169-178         无圆角 (同上)
//
// emil "cohesion" 原则: 视觉同款 = 同一 widget。
// 抽到 SwipeDeleteBackground 集中器, 用 [rounded] flag 控制是否加 radiusCard
// (vent 卡片独立 Card, 其他在 Card 列表内不需要圆角)。

import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';

/// Dismissible 左滑删除时的"红底 + delete icon" 背景
///
/// 用法:
/// ```dart
/// Dismissible(
///   key: ValueKey('item-${item.id}'),
///   direction: DismissDirection.endToStart,
///   background: const SwipeDeleteBackground(), // 默认无圆角 (Card 列表)
///   // 或: const SwipeDeleteBackground(rounded: true), 独立 Card
///   onDismissed: (_) => _delete(item),
///   child: ...,
/// )
/// ```
class SwipeDeleteBackground extends StatelessWidget {
  const SwipeDeleteBackground({super.key, this.rounded = false});

  /// 是否加圆角 (独立 Card 用 true, Card 列表内用 false)
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingLg),
      decoration: rounded
          ? BoxDecoration(
              color: AppTokens.errorColor(context),
              borderRadius: BorderRadius.circular(AppTokens.radiusCard),
            )
          : BoxDecoration(color: AppTokens.errorColor(context)),
      child: Icon(
        Icons.delete_outline,
        // v0.22 round 30 (emil P2-6): 走 fgOnError (delete bg 是 error 底)
        color: AppTokens.fgOnError(context),
        size: AppTokens.iconSize,
      ),
    );
  }
}
