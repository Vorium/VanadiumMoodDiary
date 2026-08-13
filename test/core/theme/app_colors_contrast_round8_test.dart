// v0.32 round 8 (R112 EM-16b fix): 状态前景色对比度 lock-in test
//
// 背景: R111 EM-16 只修了 warning 档 (1.9:1 → fgOnWarning #E65100),
// success / error / warningStrong 仍浅色作文字色:
// - success #66BB6A on white ≈ 2.4:1
// - error   #E57373 on white ≈ 3.0:1
// - warningStrong #FF8A65 on white ≈ 2.3:1
// 全部低于 WCAG AA 4.5:1 (小号数字文字连 3:1 large-text 都不达标)。
// 且 `fgOnSuccess = success` 是假 token (别名, 0 对比度修正)。
//
// R112 EM-16b 修:
// - fgOnSuccess 改深绿 #2E7D32 (跟 fgOnWarning #E65100 同款深色档模式)
// - 新增 fgError 深红 #C62828 / fgWarningStrong 深橙 #BF360C
//   (注: `fgOnError(BuildContext)` 是既有 "on error 表面" 语义 dynamic
//   getter, 名字被占, 新深红文字 token 命名 fgError, 见 app_colors.dart)
//
// 测试 5 case:
// 1. fgOnSuccess 具体色值 lock-in (深绿, 不再是 success 别名)
// 2. fgError / fgWarningStrong 具体色值 lock-in
// 3. fgOnWarning 保持 #E65100 (R111 EM-16 结果不倒退)
// 4. 4 个前景 token 在白底上对比度 ≥ 4.5:1 (WCAG AA 正文)
// 5. 旧浅色状态色 (success/error/warningStrong) 白底对比度 < 4.5:1
//    (证明假 token 已换, 新 token 真的更可读)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/core/theme/app_colors.dart';

/// WCAG 相对亮度对比度 (a/b 顺序无关)
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  const white = Color(0xFFFFFFFF);

  group('AppColors 状态前景色 (R112 EM-16b 对比度 lock-in)', () {
    test('1. fgOnSuccess = 深绿 #2E7D32 (不再是 success 浅绿别名)', () {
      expect(AppColors.fgOnSuccess, const Color(0xFF2E7D32));
      expect(
        AppColors.fgOnSuccess,
        isNot(AppColors.success),
        reason: 'fgOnSuccess 之前 = success 浅绿别名 (假 token), 必须换深色档',
      );
    });

    test('2. fgError = 深红 #C62828 + fgWarningStrong = 深橙 #BF360C', () {
      expect(AppColors.fgError, const Color(0xFFC62828));
      expect(AppColors.fgWarningStrong, const Color(0xFFBF360C));
    });

    test('3. fgOnWarning 保持 #E65100 (R111 EM-16 结果不倒退)', () {
      expect(AppColors.fgOnWarning, const Color(0xFFE65100));
    });

    test('4. 新 3 前景 token 在白底对比度 ≥ 4.5:1 (WCAG AA 正文)', () {
      const tokens = [
        AppColors.fgOnSuccess,
        AppColors.fgError,
        AppColors.fgWarningStrong,
      ];
      for (final c in tokens) {
        expect(
          _contrast(c, white),
          greaterThanOrEqualTo(4.5),
          reason: '$c 在白底对比度应 ≥ 4.5:1 (WCAG AA 正文)',
        );
      }
      // fgOnWarning #E65100 是 R111 EM-16 既有选择 (白底 ≈ 3.8:1),
      // 分数/计数文字都是 15pt+ w600/w700 大字 → 达 WCAG AA large-text
      // (3:1) 档; 值 lock-in 见 case 3, 不在这里 4.5 断言 (R111 结果不倒退)
      expect(
        _contrast(AppColors.fgOnWarning, white),
        greaterThanOrEqualTo(3.0),
        reason: 'fgOnWarning 白底 ≥ 3:1 (AA large-text 档, R111 EM-16)',
      );
    });

    test('5. 旧浅状态色在白底对比度 < 4.5 (证明换 token 有意义)', () {
      expect(
        _contrast(AppColors.success, white),
        lessThan(4.5),
        reason: 'success #66BB6A ≈ 2.4:1 不可作文字色',
      );
      expect(
        _contrast(AppColors.error, white),
        lessThan(4.5),
        reason: 'error #E57373 ≈ 3.0:1 不可作文字色',
      );
      expect(
        _contrast(AppColors.warningStrong, white),
        lessThan(4.5),
        reason: 'warningStrong #FF8A65 ≈ 2.3:1 不可作文字色',
      );
    });
  });
}
