import 'package:chroniccare/core/data/services/preset_medication_templates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('preset_medication_templates', () {
    test('4 个预置方案全部存在', () {
      expect(kMedicationTemplates.length, 4);
    });

    test('每个方案的 id 唯一', () {
      final ids = kMedicationTemplates.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'id 重复: $ids');
    });

    test('每个方案至少 1 个药、每个药有剂量+单位+时间', () {
      for (final t in kMedicationTemplates) {
        expect(t.meds, isNotEmpty, reason: '${t.id} 没有药');
        for (final m in t.meds) {
          expect(m.name, isNotEmpty, reason: '${t.id} 药名空');
          expect(m.dosage, greaterThan(0), reason: '${t.id} 剂量 <= 0');
          expect(m.dosageUnit, anyOf('mg', '片'),
              reason: '${t.id} 单位异常: ${m.dosageUnit}',);
          expect(m.times, isNotEmpty, reason: '${t.id} 时间空');
          for (final t in m.times) {
            expect(t.hour, inInclusiveRange(0, 23));
            expect(t.minute, inInclusiveRange(0, 59));
          }
        }
      }
    });

    test('同一药内时间点不重复', () {
      for (final template in kMedicationTemplates) {
        for (final med in template.meds) {
          final seen = <int>[];
          for (final t in med.times) {
            final key = t.hour * 60 + t.minute;
            expect(seen.contains(key), isFalse,
                reason: '${template.id} ${med.name} 时间重复: $t',);
            seen.add(key);
          }
        }
      }
    });

    test('联合方案 (combo_*) 至少 2 个药', () {
      final combos =
          kMedicationTemplates.where((t) => t.id.startsWith('combo_')).toList();
      expect(combos, isNotEmpty);
      for (final c in combos) {
        expect(c.meds.length, greaterThanOrEqualTo(2),
            reason: '${c.id} 联合方案药数 < 2',);
      }
    });
  });
}
