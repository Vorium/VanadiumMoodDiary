// v0.17 round 14 (P1-5): swallowError 单元测试
//
// 覆盖:
// 1. kDebugMode 守卫: dev 模式调用 developer.log, 不抛
// 2. release 模式: 不抛, 不输出 (手动验证)
// 3. note 可选

import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/core/shared/swallow_error.dart';

void main() {
  group('swallowError', () {
    test('does not throw on basic call', () {
      expect(
        () => swallowError(
          where: 'test',
          error: Exception('boom'),
        ),
        returnsNormally,
      );
    });

    test('accepts stack trace + note', () {
      StackTrace? captured;
      try {
        throw StateError('inner');
      } catch (_, st) {
        captured = st;
      }
      expect(
        () => swallowError(
          where: 'test',
          error: Exception('outer'),
          stack: captured,
          note: 'context',
        ),
        returnsNormally,
      );
    });

    test('all params null-safe defaults', () {
      expect(
        () => swallowError(
          where: 'test',
          error: 'string error',
        ),
        returnsNormally,
      );
    });
  });
}
