// v0.32 round 8 (R112-08 emil + R112-06 emil): mood_label 直接测试
//
// 背景:
// - R111 EM-21 修 en locale 情绪标签显示中文后, mood_label.dart (5 档
//   switch) 一直 0 直接测试 (只有 scale_strings lock-in 顺带扫 ARB)
//
// 验证:
// 1. moodLabel 5 档 → zh / en 正确标签
// 2. 越界分数 (0 / 6 / -1) → fallback moodLabel3 (一般 / Fair)
//
// P3-CLEAN-2: MoodQuickButton 死 widget 删除后, 原 MoodQuickButton 参数化
// 拼接测试随 widget 移除 (R112-06 moodTodayLabelWithValue 的 caller 已无)。

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/mood_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AppLocalizations _l10n(String locale) => lookupAppLocalizations(Locale(locale));

void main() {
  group('mood_label (R112-08 emil)', () {
    test('zh 5 档标签 1:1 映射', () {
      final l10n = _l10n('zh');
      expect(moodLabel(l10n, 1), '很差');
      expect(moodLabel(l10n, 2), '差');
      expect(moodLabel(l10n, 3), '一般');
      expect(moodLabel(l10n, 4), '好');
      expect(moodLabel(l10n, 5), '很好');
    });

    test('en 5 档标签 1:1 映射 (R111 EM-21 回归)', () {
      final l10n = _l10n('en');
      expect(moodLabel(l10n, 1), 'Very bad');
      expect(moodLabel(l10n, 2), 'Bad');
      expect(moodLabel(l10n, 3), 'Fair');
      expect(moodLabel(l10n, 4), 'Good');
      expect(moodLabel(l10n, 5), 'Very good');
    });

    test('越界分数 fallback moodLabel3 (0 / 6 / -1)', () {
      final l10n = _l10n('zh');
      expect(moodLabel(l10n, 0), '一般');
      expect(moodLabel(l10n, 6), '一般');
      expect(moodLabel(l10n, -1), '一般');
    });
  });
}
