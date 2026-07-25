// PHQ-9 量表逻辑测试
// 验证总分 → severity 映射正确
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/domain/logic/phq9.dart';

void main() {
  group('Phq9Result.fromTotal', () {
    test('0 → minimal', () {
      final r = Phq9Result.fromTotal(0);
      expect(r.severity, Phq9Severity.minimal);
    });

    test('4 → minimal（边界）', () {
      final r = Phq9Result.fromTotal(4);
      expect(r.severity, Phq9Severity.minimal);
    });

    test('5 → mild', () {
      final r = Phq9Result.fromTotal(5);
      expect(r.severity, Phq9Severity.mild);
    });

    test('9 → mild（边界）', () {
      final r = Phq9Result.fromTotal(9);
      expect(r.severity, Phq9Severity.mild);
    });

    test('10 → moderate（开始建议就医）', () {
      final r = Phq9Result.fromTotal(10);
      expect(r.severity, Phq9Severity.moderate);
      expect(r.recommendDoctorVisit, isTrue);
      expect(r.urgentDoctorVisit, isFalse);
    });

    test('19 → moderatelySevere', () {
      final r = Phq9Result.fromTotal(19);
      expect(r.severity, Phq9Severity.moderatelySevere);
      expect(r.recommendDoctorVisit, isTrue);
      expect(r.urgentDoctorVisit, isFalse);
    });

    test('20 → severe（强烈建议就医）', () {
      final r = Phq9Result.fromTotal(20);
      expect(r.severity, Phq9Severity.severe);
      expect(r.urgentDoctorVisit, isTrue);
    });

    test('27 → severe（最大）', () {
      final r = Phq9Result.fromTotal(27);
      expect(r.severity, Phq9Severity.severe);
      expect(r.total, 27);
    });
  });

  group('phq9 常量', () {
    test('4 个选项 0-3', () {
      expect(phq9Options.length, 4);
      expect(phq9Options[0], '完全不会');
      expect(phq9Options[3], '几乎每天');
    });
  });
}
