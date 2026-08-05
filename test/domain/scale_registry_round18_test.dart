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
        // v0.30 round 90 (Task 2): options 0..N 连续 (PHQ-9/GAD-7/Level2×3 = 0..3,
        // ISI/PSS/WHODAS/ASRM = 0..4)。按 max 选项动态算 totalRange = items.length * maxOption
        final maxOption = s.options.keys.reduce((a, b) => a > b ? a : b);
        expect(
          s.totalRange,
          s.items.length * maxOption,
          reason: '量表 ${s.id} 的 totalRange 与 items / maxOption 不一致',
        );
        // options 必须是 0..maxOption 连续
        final expectedKeys = List.generate(maxOption + 1, (i) => i);
        expect(
          s.options.keys.toList()..sort(),
          expectedKeys,
          reason: '量表 ${s.id} 的 options 不连续 (期望 0..$maxOption)',
        );
      }
    });
  });
}
