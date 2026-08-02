// v0.28 R81: mood_visual.dart 加 IP 化太阳 emoji (5 档)
//
// 背景 (R81 emil design eng 借鉴 B 站"哗哩哗哩能量加油站" 4 情绪太阳):
//   之前 MoodVisual.emojiFor 1-5 用标准人脸 (😢😟😐🙂😄), 病耻感中性化不够。
//   B 站用 4 太阳 + 嘴型组合 (☀️⛅🌧⛈) 治愈系风格, 跟精神心理 App 调性
//   对齐, 用户填写心情时减少"疾病"联想, 提升"温暖感"。
//
// 修法: 加 ipEmojiFor(int score) 方法, 5 档 IP 化太阳 emoji:
// - 1 很差: ⛈ (雷暴)
// - 2 差:   🌧 (下雨)
// - 3 一般: ⛅ (多云)
// - 4 好:   🌤 (晴间多云)
// - 5 很好: ☀️ (晴)
// - 越界:  ⛅ (默认)
//
// 跟 emojiFor 1:1 映射, 平行存在, UI 层按"治愈系/IP 风" vs
// "标准人脸"切换。R82+ 评估哪种更受欢迎, 留 A/B 数据决定保留哪个。
import 'package:chroniccare/core/shared/mood_visual.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MoodVisual.ipEmojiFor (R81: IP 化太阳 emoji 5 档)', () {
    test('5 档全部返 IP 化太阳 emoji (跟 B 站 4 情绪风格对齐)', () {
      expect(MoodVisual.ipEmojiFor(1), '⛈', reason: '1 很差: 雷暴');
      expect(MoodVisual.ipEmojiFor(2), '🌧', reason: '2 差: 下雨');
      expect(MoodVisual.ipEmojiFor(3), '⛅', reason: '3 一般: 多云');
      expect(MoodVisual.ipEmojiFor(4), '🌤', reason: '4 好: 晴间多云');
      expect(MoodVisual.ipEmojiFor(5), '☀️', reason: '5 很好: 晴');
    });

    test('越界 (0 / 6 / 负数) 返 ⛅ 默认', () {
      expect(MoodVisual.ipEmojiFor(0), '⛅');
      expect(MoodVisual.ipEmojiFor(6), '⛅');
      expect(MoodVisual.ipEmojiFor(-1), '⛅');
    });

    test('跟 emojiFor 1:1 平行 (5 档位置一一对应)', () {
      // 验证两套 emoji 数量 + 默认值一致
      expect(MoodVisual.emojiFor(1), isNotEmpty);
      expect(MoodVisual.ipEmojiFor(1), isNotEmpty);
      expect(MoodVisual.emojiFor(5), isNotEmpty);
      expect(MoodVisual.ipEmojiFor(5), isNotEmpty);
      // 越界都返默认
      expect(MoodVisual.emojiFor(0), MoodVisual.emojiFor(3));
      expect(MoodVisual.ipEmojiFor(0), MoodVisual.ipEmojiFor(3));
    });

    test('emojiFor 仍是人脸风格, 不变 (向后兼容 R17 测 + 趋势页)', () {
      expect(MoodVisual.emojiFor(1), '😢');
      expect(MoodVisual.emojiFor(5), '😄');
    });
  });
}
