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

  /// 分数 → emoji（1-5 映射，标准人脸）
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

  /// 分数 → IP 化太阳 emoji (v0.28 R81)
  ///
  /// 跟 B 站"哗哩哗哩能量加油站" 4 情绪太阳 + 嘴型组合风格对齐, 病耻感
  /// 中性化: 太阳是普遍治愈系符号, 不带疾病标签。
  ///
  /// 5 档映射 (跟 emojiFor 1:1 对齐):
  /// - 1 很差: ⛈ 乌云 + 闪电 (雷暴)
  /// - 2 差:   🌧 乌云 (下雨)
  /// - 3 一般: ⛅ 云 (多云)
  /// - 4 好:   🌤 晴间多云 (sun behind cloud)
  /// - 5 很好: ☀️ 晴 (太阳)
  ///
  /// 频度: tens/day (mood 录入核心动作), 跟 emojiFor 平行存在让 UI
  /// 层按"治愈系/IP 风" vs "标准人脸"切换。R82+ 评估哪种更受欢迎,
  /// 留 A/B 数据决定保留哪个。
  static String ipEmojiFor(int score) {
    switch (score) {
      case 1:
        return '⛈';
      case 2:
        return '🌧';
      case 3:
        return '⛅';
      case 4:
        return '🌤';
      case 5:
        return '☀️';
      default:
        return '⛅';
    }
  }

  // ===== 中文 label =====

  /// 分数 → 中文（委托 Strings.moodLabel）
  ///
  /// presentation 层应使用 AppLocalizations 的 moodLabelN 键替代此方法。
  static String labelFor(int score) => Strings.moodLabel(score);
}
