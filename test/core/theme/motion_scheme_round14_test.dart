// v0.17 round 14 (P2-14): MotionScheme enum test
//
// 覆盖:
// 1. 4 档 enum 都有 duration + curve
// 2. none 是 0ms (避免误用动画)
// 3. standard 走 durNormal + curveStandard
// 4. delight 走 durSlow + curveDelight

import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';

void main() {
  group('MotionScheme', () {
    test('none: 0 duration, linear curve (no animation)', () {
      expect(MotionScheme.none.duration, Duration.zero);
      expect(MotionScheme.none.curve, Curves.linear);
    });

    test('subtle: fast duration, subtle curve (v0.24 round 48 emil P1-1)', () {
      expect(MotionScheme.subtle.duration, AppTokens.durFast);
      expect(MotionScheme.subtle.curve, AppTokens.curveSubtle);
    });

    test('standard: normal duration, standard curve', () {
      expect(MotionScheme.standard.duration, AppTokens.durNormal);
      expect(MotionScheme.standard.curve, AppTokens.curveStandard);
    });

    test('delight: slow duration, elastic curve', () {
      expect(MotionScheme.delight.duration, AppTokens.durSlow);
      expect(MotionScheme.delight.curve, AppTokens.curveDelight);
    });

    test('all 4 schemes exposed', () {
      expect(MotionScheme.values, hasLength(4));
    });
  });
}
