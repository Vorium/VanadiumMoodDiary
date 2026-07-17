// ScaleRegistry 测试
// 验证多量表注册 + id 查询正确

import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/domain/logic/scale_registry.dart';

void main() {
  group('ScaleRegistry.allScales', () {
    test('至少包含 PHQ-9 + GAD-7', () {
      final scales = allScales();
      final ids = scales.map((s) => s.id).toList();
      expect(ids, containsAll(['phq9', 'gad7']));
    });

    test('顺序固定：PHQ-9 在前', () {
      final scales = allScales();
      expect(scales.first.id, 'phq9');
    });
  });

  group('ScaleRegistry.scaleById', () {
    test('phq9 → Phq9Scale', () {
      final s = scaleById('phq9');
      expect(s, isNotNull);
      expect(s!.id, 'phq9');
      expect(s.displayName, contains('PHQ-9'));
    });

    test('gad7 → Gad7Scale', () {
      final s = scaleById('gad7');
      expect(s, isNotNull);
      expect(s!.id, 'gad7');
      expect(s.displayName, contains('GAD-7'));
    });

    test('未知 id → null', () {
      final s = scaleById('foo');
      expect(s, isNull);
    });
  });

  group('量表数据完整性', () {
    test('所有量表的 items / options / totalRange 一致', () {
      for (final s in allScales()) {
        // totalRange = items.length * 3（每题 0-3 分）
        expect(s.totalRange, s.items.length * 3,
            reason: '量表 ${s.id} 的 totalRange 与 items 不一致',);
        // options 必须是 0..3 四个值
        expect(s.options.keys.toList()..sort(), [0, 1, 2, 3],
            reason: '量表 ${s.id} 的 options 不是 0-3',);
      }
    });
  });
}
