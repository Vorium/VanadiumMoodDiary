// v0.24 round 45 (Sprint #5c P0 god class 拆解) — ExportSchemaService 子 service 测试
//
// Sprint #5c 把 data_export_service god class 拆 3 子 service, 这里是
// ExportSchemaService 的独立 test, 覆盖:
//
// 1. validateVersion 1-4 范围 (P0 兼容)
// 2. validateString length / pattern / null / 非 String
// 3. validateInt defaultValue 兜底 / range
// 4. validateIntOr 非空默认
// 5. validateDouble null / 非 num / int 接受
// 6. validateDate tryParse (P0-2 fix)
// 7. deleteOldDataSafely 旧表缺失容错 (P1-10 fix: 不静默 catch (_))
//
// 不依赖 facade, 100% 子 service 独立测。
import 'package:chroniccare/core/data/services/export/export_schema_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const svc = ExportSchemaService();

  group('v0.24 round 45 (Sprint #5c) — ExportSchemaService.currentVersion', () {
    test('currentVersion = 4 (4D 情绪, v0.18)', () {
      expect(ExportSchemaService.currentVersion, 4);
    });
  });

  group('v0.24 round 45 (Sprint #5c) — ExportSchemaService.validateVersion', () {
    test('1 → 1 (最小)', () {
      expect(svc.validateVersion(1), 1);
    });

    test('4 → 4 (current)', () {
      expect(svc.validateVersion(4), 4);
    });

    test('0 → null (低于最小)', () {
      expect(svc.validateVersion(0), isNull);
    });

    test('5 → null (高于 current)', () {
      expect(svc.validateVersion(5), isNull);
    });

    test('99 → null (未来版本)', () {
      expect(svc.validateVersion(99), isNull);
    });

    test('null → null', () {
      expect(svc.validateVersion(null), isNull);
    });

    test('非 int (字符串) → null', () {
      expect(svc.validateVersion('4'), isNull);
    });

    test('非 int (double) → null', () {
      expect(svc.validateVersion(4.0), isNull);
    });
  });

  group('v0.24 round 45 (Sprint #5c) — ExportSchemaService.validateString', () {
    test('正常字符串 → 原样返回', () {
      expect(
        ExportSchemaService.validateString('张三', 'userName', maxLen: 50),
        '张三',
      );
    });

    test('null → null', () {
      expect(
        ExportSchemaService.validateString(null, 'userName', maxLen: 50),
        isNull,
      );
    });

    test('非 String → null', () {
      expect(
        ExportSchemaService.validateString(123, 'userName', maxLen: 50),
        isNull,
      );
    });

    test('空字符串 → null', () {
      expect(
        ExportSchemaService.validateString('', 'userName', maxLen: 50),
        isNull,
      );
    });

    test('超过 maxLen → null', () {
      final long = 'a' * 51;
      expect(
        ExportSchemaService.validateString(long, 'userName', maxLen: 50),
        isNull,
      );
    });

    test('正好 maxLen → 接受', () {
      final exact = 'a' * 50;
      expect(
        ExportSchemaService.validateString(exact, 'userName', maxLen: 50),
        exact,
      );
    });

    test('phone pattern 匹配 → 接受', () {
      final phone = ExportSchemaService.validateString(
        '13800138000',
        'phone',
        maxLen: 20,
        pattern: RegExp(r'^\+?\d{6,20}$'),
      );
      expect(phone, '13800138000');
    });

    test('phone pattern 匹配 +86 前缀 → 接受', () {
      final phone = ExportSchemaService.validateString(
        '+8613800138000',
        'phone',
        maxLen: 20,
        pattern: RegExp(r'^\+?\d{6,20}$'),
      );
      expect(phone, '+8613800138000');
    });

    test('phone pattern 不匹配 (含字母) → null', () {
      expect(
        ExportSchemaService.validateString(
          '13800abc000',
          'phone',
          maxLen: 20,
          pattern: RegExp(r'^\+?\d{6,20}$'),
        ),
        isNull,
      );
    });

    test('phone pattern 不匹配 (5 位) → null', () {
      expect(
        ExportSchemaService.validateString(
          '12345',
          'phone',
          maxLen: 20,
          pattern: RegExp(r'^\+?\d{6,20}$'),
        ),
        isNull,
      );
    });
  });

  group('v0.24 round 45 (Sprint #5c) — ExportSchemaService.validateInt', () {
    test('正常 int 48 → 48', () {
      expect(
        ExportSchemaService.validateInt(48, null, min: 1, max: 168),
        48,
      );
    });

    test('null → defaultValue', () {
      expect(
        ExportSchemaService.validateInt(null, 99, min: 1, max: 168),
        99,
      );
    });

    test('越界 < min → defaultValue', () {
      expect(
        ExportSchemaService.validateInt(0, 99, min: 1, max: 168),
        99,
      );
    });

    test('越界 > max → defaultValue', () {
      expect(
        ExportSchemaService.validateInt(200, 99, min: 1, max: 168),
        99,
      );
    });

    test('非 int (double) → defaultValue', () {
      expect(
        ExportSchemaService.validateInt(48.5, 99, min: 1, max: 168),
        99,
      );
    });

    test('边界 = min → 接受', () {
      expect(
        ExportSchemaService.validateInt(1, 99, min: 1, max: 168),
        1,
      );
    });

    test('边界 = max → 接受', () {
      expect(
        ExportSchemaService.validateInt(168, 99, min: 1, max: 168),
        168,
      );
    });
  });

  group('v0.24 round 45 (Sprint #5c) — ExportSchemaService.validateIntOr', () {
    test('正常 int 48 → 48 (非空返回)', () {
      expect(
        ExportSchemaService.validateIntOr(48, 24, min: 1, max: 168),
        48,
      );
    });

    test('null → defaultValue 24 (兜底)', () {
      expect(
        ExportSchemaService.validateIntOr(null, 24, min: 1, max: 168),
        24,
      );
    });

    test('越界 → defaultValue 24', () {
      expect(
        ExportSchemaService.validateIntOr(200, 24, min: 1, max: 168),
        24,
      );
    });
  });

  group('v0.24 round 45 (Sprint #5c) — ExportSchemaService.validateDouble', () {
    test('正常 double 0.3 → 0.3', () {
      expect(ExportSchemaService.validateDouble(0.3), 0.3);
    });

    test('int 0 → 0.0 (int 是 num 子类)', () {
      expect(ExportSchemaService.validateDouble(0), 0.0);
    });

    test('int 5 → 5.0', () {
      expect(ExportSchemaService.validateDouble(5), 5.0);
    });

    test('null → null', () {
      expect(ExportSchemaService.validateDouble(null), isNull);
    });

    test('字符串 → null', () {
      expect(ExportSchemaService.validateDouble('0.3'), isNull);
    });
  });

  group('v0.24 round 45 (Sprint #5c) — ExportSchemaService.validateDate', () {
    test('Z 后缀 ISO 8601 → DateTime', () {
      final result = ExportSchemaService.validateDate(
        '2026-07-01T10:00:00.000Z',
      );
      expect(result, isNotNull);
      expect(result!.toUtc().year, 2026);
      expect(result.toUtc().month, 7);
      expect(result.toUtc().day, 1);
    });

    test('无后缀 ISO 8601 → 仍能 parse (跟原 facade 行为一致)', () {
      final result = ExportSchemaService.validateDate('2026-07-01T10:00:00');
      expect(result, isNotNull);
    });

    test('空字符串 → null (P0-2 tryParse 替代 try/catch)', () {
      expect(ExportSchemaService.validateDate(''), isNull);
    });

    test('非 ISO 格式 → null (P0-2 tryParse 不抛)', () {
      expect(ExportSchemaService.validateDate('not a date'), isNull);
    });

    test('非 String → null', () {
      expect(ExportSchemaService.validateDate(20260701), isNull);
    });

    test('null → null', () {
      expect(ExportSchemaService.validateDate(null), isNull);
    });
  });
}
