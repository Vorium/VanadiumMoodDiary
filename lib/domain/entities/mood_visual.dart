// v0.14 (Round 12A) MoodVisual — 情绪分数 → emoji / 中文 / 颜色
//
// 从原来的 MoodRepository 静态方法中抽离。
// 4 层架构：domain 层的"展示 helper"，和 MedicationEntity 一样
// 允许使用 material 的 Color（只是数据类，非 UI 渲染）。
//
// 替代：MoodRepository.emojiFor / .labelFor / .colorFor / .decodeTags
// - decodeTags 已迁到 MoodEntryEntity.tags getter
// - 剩下三个（emoji/label/color）放本类
library;

import 'package:flutter/material.dart' show Color;

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

  /// 分数 → 中文
  static String labelFor(int score) {
    switch (score) {
      case 1:
        return '很差';
      case 2:
        return '差';
      case 3:
        return '一般';
      case 4:
        return '好';
      case 5:
        return '很好';
      default:
        return '一般';
    }
  }

  // ===== 颜色 =====

  /// 分数 → 颜色
  static Color colorFor(int score) {
    switch (score) {
      case 1:
        return const Color(0xFF6B7280);
      case 2:
        return const Color(0xFF60A5FA);
      case 3:
        return const Color(0xFF9CA3AF);
      case 4:
        return const Color(0xFF6BCF7F);
      case 5:
        return const Color(0xFF4FB05F);
      default:
        return const Color(0xFF9CA3AF);
    }
  }
}
