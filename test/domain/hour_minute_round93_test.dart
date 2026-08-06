// v0.28 Round 93 (#69 修复): hour_minute 值对象 0 测试补齐
//
// 覆盖:
// - 主构造函数合法值 / 越界 assert
// - safe() 工厂容错
// - copyWith
// - fromString 解析 (3 段 / 非数字 / 空)
// - toTimeString 格式化 (零填充)
// - == / hashCode / toString
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/domain/entities/hour_minute.dart';

void main() {
  group('HourMinute 主构造 + assert', () {
    test('合法值构造', () {
      const t = HourMinute(hour: 8, minute: 30);
      expect(t.hour, 8);
      expect(t.minute, 30);
    });

    test('边界 0:00 通过 assert', () {
      const t = HourMinute(hour: 0, minute: 0);
      expect(t.hour, 0);
      expect(t.minute, 0);
    });

    test('边界 23:59 通过 assert', () {
      const t = HourMinute(hour: 23, minute: 59);
      expect(t.hour, 23);
      expect(t.minute, 59);
    });

    test('hour < 0 触发 assert (debug)', () {
      expect(
        () => HourMinute(hour: -1, minute: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('hour > 23 触发 assert', () {
      expect(
        () => HourMinute(hour: 24, minute: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('minute > 59 触发 assert', () {
      expect(
        () => HourMinute(hour: 8, minute: 60),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('HourMinute.safe() 工厂容错', () {
    test('hour 越界 clamp 到 [0, 23]', () {
      expect(HourMinute.safe(hour: -5, minute: 0).hour, 0);
      expect(HourMinute.safe(hour: 30, minute: 0).hour, 23);
    });

    test('minute 越界 clamp 到 [0, 59]', () {
      expect(HourMinute.safe(hour: 0, minute: -1).minute, 0);
      expect(HourMinute.safe(hour: 0, minute: 99).minute, 59);
    });
  });

  group('HourMinute.copyWith', () {
    test('改 hour 保持 minute', () {
      const t = HourMinute(hour: 8, minute: 30);
      final t2 = t.copyWith(hour: 10);
      expect(t2.hour, 10);
      expect(t2.minute, 30);
    });

    test('null 参数保留原值', () {
      const t = HourMinute(hour: 8, minute: 30);
      final t2 = t.copyWith();
      expect(t2.hour, 8);
      expect(t2.minute, 30);
    });
  });

  group('HourMinute.fromString 解析', () {
    test('正常 "08:30"', () {
      final t = HourMinute.fromString('08:30');
      expect(t.hour, 8);
      expect(t.minute, 30);
    });

    test('多段 "08:30:45" 走 fallback 0:0', () {
      final t = HourMinute.fromString('08:30:45');
      expect(t, const HourMinute(hour: 0, minute: 0));
    });

    test('非数字 "ab:cd" 走 fallback 0:0', () {
      final t = HourMinute.fromString('ab:cd');
      expect(t, const HourMinute(hour: 0, minute: 0));
    });

    test('空串走 fallback 0:0', () {
      final t = HourMinute.fromString('');
      expect(t, const HourMinute(hour: 0, minute: 0));
    });
  });

  group('HourMinute toTimeString + toString + == / hashCode', () {
    test('toTimeString 零填充', () {
      expect(const HourMinute(hour: 8, minute: 5).toTimeString(), '08:05');
      expect(const HourMinute(hour: 0, minute: 0).toTimeString(), '00:00');
      expect(const HourMinute(hour: 23, minute: 59).toTimeString(), '23:59');
    });

    test('toString 跟 toTimeString 一致', () {
      const t = HourMinute(hour: 8, minute: 30);
      expect(t.toString(), '08:30');
    });

    test('相等 + hashCode 一致', () {
      const a = HourMinute(hour: 8, minute: 30);
      const b = HourMinute(hour: 8, minute: 30);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('不等', () {
      const a = HourMinute(hour: 8, minute: 30);
      const b = HourMinute(hour: 9, minute: 30);
      expect(a, isNot(b));
    });
  });
}
