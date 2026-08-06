// v0.30 round 91 (sub-spec 7 日常追踪): BmiCalculator 纯函数 行为锁定
//
// 覆盖 (TDD red→green):
// 1. compute 标准: 70kg / 175cm = 22.86 (正常 BMI)
// 2. compute heightCm = null → null (profile.height 缺失)
// 3. compute heightCm = 0 → null (除零保护)
// 4. category 4 档全覆盖: underweight / normal / overweight / obese
//
// R91 brief: "BMI 读 profile.height — R91 没存 profile, calculator 接受
// heightCm 参数 (上层 dialog 读 profile)" — calculator 0 依赖 profile,
// 只接受数值, 跟 R60 R90 calculator 模式一致 (0 flutter 0 drift)。

import 'package:chroniccare/domain/logic/bmi_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BmiCalculator.compute (BMI = weight / (height_m)²)', () {
    test('70kg / 175cm = 22.86 (正常)', () {
      final result = BmiCalculator.compute(weightKg: 70, heightCm: 175);
      expect(result, isNotNull);
      expect(result!, closeTo(22.86, 0.01));
    });

    test('heightCm = null → null (profile 缺失兼容)', () {
      final result = BmiCalculator.compute(weightKg: 70, heightCm: null);
      expect(result, isNull);
    });

    test('heightCm = 0 → null (除零保护)', () {
      final result = BmiCalculator.compute(weightKg: 70, heightCm: 0);
      expect(result, isNull);
    });

    test('heightCm 负数 → null (边界保护)', () {
      final result = BmiCalculator.compute(weightKg: 70, heightCm: -10);
      expect(result, isNull);
    });
  });

  group('BmiCalculator.category (4 档)', () {
    test('18.5 边界: < 18.5 = underweight', () {
      expect(BmiCalculator.category(18.4), 'underweight');
      expect(BmiCalculator.category(17.0), 'underweight');
    });

    test('18.5 - 24 = normal', () {
      expect(BmiCalculator.category(18.5), 'normal');
      expect(BmiCalculator.category(22.0), 'normal');
      expect(BmiCalculator.category(23.9), 'normal');
    });

    test('24 - 28 = overweight', () {
      expect(BmiCalculator.category(24.0), 'overweight');
      expect(BmiCalculator.category(26.0), 'overweight');
      expect(BmiCalculator.category(27.9), 'overweight');
    });

    test('>= 28 = obese', () {
      expect(BmiCalculator.category(28.0), 'obese');
      expect(BmiCalculator.category(32.0), 'obese');
    });
  });
}
