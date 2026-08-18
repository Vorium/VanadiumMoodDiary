// v1.1.0 R128e+ round 1 (CN Domestic Icon Redesign): 主题色 accentAppleHealth →
// accentSunsetPeach (#FFB088) — emotion-first 品牌色重定义
//
// 2 个 case:
// 1. accentSunsetPeach 是 #FFB088 (橙色 sunset peach) — 新品牌色
// 2. accentAppleHealth 不再存在 (breaking rename) — 旧 Apple Health 绿色 (#34C759)
//    退场,访问抛 StateError 提示用户用 accentSunsetPeach
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare_theme/chroniccare_theme.dart';

void main() {
  test('accentSunsetPeach is sunset peach hex #FFB088', () {
    expect(AppColors.accentSunsetPeach.value, 0xFFFFB088);
  });

  test('accentAppleHealth no longer exists (breaking rename)', () {
    expect(() => AppColors.accentAppleHealth, throwsA(anything));
  });
}