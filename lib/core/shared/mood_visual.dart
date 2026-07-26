// v0.16 (Round 9) MoodVisual — 情绪分数 → emoji / 中文 / ARGB 颜色
//
// 从原来的 MoodRepository 静态方法中抽离。
// 4 层架构纯化：返回 int (ARGB) 而非 Color，UI 层 wrap 成 Color。
// 这样 shared/ 不依赖 flutter，domain/ 也能用。
//
// v0.23 (P2 Q1 fix): labelFor() 中文标签集中到 core/l10n/strings.dart,
// shared/ 不再 hardcoded 中文。presentation 层应使用 AppLocalizations 的
// moodLabelN 键。

// ignore_for_file: prefer_const_constructors

import 'package:chroniccare/core/l10n/strings.dart';

/// 情绪分数 → 展示 helper
class MoodVisual {
  MoodVisual._();

  // ===== emoji =====

  /// 分数 → emoji（1-5 映射）
  static String emojiFor(int score) {
    switch (score) {
      case 1:
        return '😢';
      case 2:
        return '😟';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      case 5:
        return '😄';
      default:
        return '😐';
    }
  }

  // ===== 中文 label =====

  /// 分数 → 中文（委托 Strings.moodLabel）
  ///
  /// presentation 层应使用 AppLocalizations 的 moodLabelN 键替代此方法。
  static String labelFor(int score) => Strings.moodLabel(score);

  // ===== 颜色（ARGB int，UI 层包成 Color）=====

  /// 分数 → ARGB int（0xAARRGGBB）
  ///
  /// 返回 int 而非 Color，shared/ 不依赖 flutter/material。
  /// UI 层用 `Color(MoodVisual.colorArgbFor(score))` 包一下。
  static int colorArgbFor(int score) {
    switch (score) {
      case 1:
        return 0xFF6B7280;
      case 2:
        return 0xFF60A5FA;
      case 3:
        return 0xFF9CA3AF;
      case 4:
        return 0xFF6BCF7F;
      case 5:
        return 0xFF4FB05F;
      default:
        return 0xFF9CA3AF;
    }
  }
}
