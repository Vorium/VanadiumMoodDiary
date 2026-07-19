/// v0.18 round 18 (P2-P0-1) PII 安全日志测试
///
/// 覆盖:
/// - maskPhone 各种格式 (13800138000 / +8613800138000 / 短号 / 港澳台)
/// - maskName 中文 / 英文 / 空
/// - piiSafeLog 在 release 模式 swallow (验证通过 Profile / 环境变量无法在 test 测,
///   改为测 kDebugMode 模式确保 developer.log 走通即可,真实 release 由 CI 验证)
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/core/data/services/pii_safe_log.dart';

void main() {
  group('maskPhone', () {
    test('大陆 11 位 → 138****8000', () {
      expect(maskPhone('13800138000'), '138****8000');
    });

    test('+86 前缀 → +86 138****8000', () {
      expect(maskPhone('+8613800138000'), '+86 138****8000');
    });

    test('带空格 +86 138 0013 8000 → 同样掩码', () {
      expect(maskPhone('+86 138 0013 8000'), '+86 138****8000');
    });

    test('短号 < 7 位原样返回', () {
      expect(maskPhone('12345'), '12345');
      expect(maskPhone('123'), '123');
      expect(maskPhone(''), '');
    });

    test('港澳台 8-9 位也能掩码', () {
      expect(maskPhone('91234567'), '912****4567');
      expect(maskPhone('912345678'), '912****5678');
    });
  });

  group('maskName', () {
    test('中文 2 字 → 张*', () {
      expect(maskName('张三'), '张*');
    });

    test('中文 1 字原样', () {
      expect(maskName('张'), '张');
    });

    test('中文 3 字 → 张**', () {
      expect(maskName('张三丰'), '张**');
    });

    test('英文按词保留首字母', () {
      expect(maskName('John Smith'), 'J*** S****');
    });

    test('空字符串', () {
      expect(maskName(''), '');
    });
  });

  group('piiSafeLog', () {
    test('debug 模式:不抛异常(developer.log 在 test 跑通)', () {
      // 验证 maskPhone / maskName 在 test 环境(kDebugMode)能跑
      // release 模式的 swallow 由 helper 实现,真实 release 由 CI 验证
      // (test 切换 kReleaseMode 需 kDebugMode = false,Flutter test 强制 debug)
      if (kDebugMode) {
        expect(() => piiSafeLog('TestTag', 'test message'), returnsNormally);
      } else {
        // release 模式下应该 no-op
        expect(() => piiSafeLog('TestTag', 'should be swallowed'),
            returnsNormally);
      }
    });
  });
}
