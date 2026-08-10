// home_celebration_controller.dart — Home 主页 celebration overlay controller
//
// v0.30 R108 (P1 home_page_state 拆): 抽庆祝 overlay 业务到独立 controller
// (R107 报告 §3.2 home_page_state god class 拆 3 controller 方案,
// 4 视角共识: emil + spen + architecture + bottom-up)。
//
// 拆出原因:
// - 原 home_page_state 597 行单 ConsumerState 类, 含 9 业务方法
// - _celebrationFor (8L) + _showCelebrationOverlay (30L) = 38L
//   跟 overlay 副作用强相关 (含 Timer 字段, 需 dispose cancel)
// - 抽出后 celebration 业务可独立单测 (Timer cancel 测试), 跟 _onCheckIn /
//   _autofireMedicationCheckIn 编排解耦
//
// 公共 API:
// - [HomeCelebrationController] — controller class
// - [pickStreakMessage] — 根据 streak 数选庆祝文案 (5 档: day1 / short /
//   medium / long / master)
// - [show] — 显示顶部 overlay, 自动 Timer 移除 (cancellationDisplayMs)
// - [dispose] — 取消 celebration Timer, 防 leak
//
// 跟 state class 协作:
// - [show] 需要 BuildContext (Overlay.of + MediaQuery), 由 state class 传入
// - [dispose] 由 state class 在自身 dispose 链中调用
//
// 4 层架构纯度: 本文件 import `flutter` (Material/Overlay) + `flutter_riverpod`
// (无), 跟原 home_page_state 一样在 presentation 层, 0 violation。
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/animations/animations.dart';

/// v0.30 R108 (P1 home_page_state 拆): 庆祝 overlay controller
///
/// 抽自原 home_page_state._celebrationFor (8L) + _showCelebrationOverlay (30L)
/// = 38L, 含 _celebrationTimer 字段 (R62 P1-6 修)。
class HomeCelebrationController {
  /// 庆祝 overlay 的 Timer (v0.27 round 62 P1-6 修)
  ///
  /// 之前用 `Future.delayed` 不可 cancel，widget dispose 后 fire 引起 race。
  /// 改 Timer 存字段 + dispose 时 `cancel()`。
  Timer? _celebrationTimer;

  /// 根据 streak 选庆祝文案 (5 档: day1 / short / medium / long / master)
  ///
  /// 抽自原 home_page_state._celebrationFor (8L)。
  String pickStreakMessage(BuildContext context, int streak) {
    final l10n = AppLocalizations.of(context);
    if (streak == 1) return l10n.homeCelebrationDay1;
    if (streak < 7) return l10n.homeCelebrationStreakShort(streak);
    if (streak < 30) return l10n.homeCelebrationStreakMedium(streak);
    if (streak < 100) return l10n.homeCelebrationStreakLong(streak);
    return l10n.homeCelebrationStreakMaster(streak);
  }

  /// 顶部 overlay 庆祝(短暂显示，自动消失)
  ///
  /// 抽自原 home_page_state._showCelebrationOverlay (30L)。
  void show(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        // R69 (emil P1-1 修复): 改 MediaQuery.padding.top + spacingLg,
        // origin-aware 顶部定位, 避免键盘弹起 / 横屏 / 全面屏撞顶
        top: MediaQuery.of(ctx).padding.top + AppTokens.spacingLg,
        left: 0,
        right: 0,
        child: IgnorePointer(
          child: Center(
            // v0.24 round 48 (emil P1-2): 实际走 CelebrationBounce via typedef @Deprecated
            // 未来 v0.25+ 全部迁移后, 可删 celebration_overlay.dart 整个文件
            child: CelebrationBounce(message: message),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    // v0.27 round 62 (P1-6 修复): 用 Timer 替代 Future.delayed,
    // 存字段, dispose 时 cancel, 避免 widget 销毁后回调 fire 引起 race。
    _celebrationTimer?.cancel();
    _celebrationTimer = Timer(
      const Duration(milliseconds: AppTokens.celebrationDisplayMs),
      () {
        if (entry.mounted) entry.remove();
        _celebrationTimer = null;
      },
    );
  }

  /// v0.30 R108 (P1 home_page_state 拆): dispose 取消 celebration Timer
  ///
  /// 防 widget dispose 后回调 fire 触发 `entry.mounted` 检查已经无效,
  /// 进而打 "OverlayEntry removed too many times" 警告。
  void dispose() {
    _celebrationTimer?.cancel();
    _celebrationTimer = null;
  }
}
