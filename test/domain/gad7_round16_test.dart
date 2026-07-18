// GAD-7 量表逻辑测试
// 验证总分 → severity 映射 + AssessmentScale 接口契约

import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/domain/logic/gad7.dart';

void main() {
  group('gad7 常量', () {
    test('7 道题', () {
      expect(gad7Items.length, 7);
    });

    test('4 个选项 0-3', () {
      expect(gad7Options.length, 4);
      expect(gad7Options[0], '完全不会');
      expect(gad7Options[3], '几乎每天');
    });
  });

  group('Gad7Scale 接口契约', () {
    final s = gad7Scale;

    test('id = gad7', () {
      expect(s.id, 'gad7');
    });

    test('displayName 非空', () {
      expect(s.displayName.contains('GAD-7'), isTrue);
    });

    test('totalRange = 21', () {
      expect(s.totalRange, 21);
    });

    test('items / options 不为空且长度一致', () {
      expect(s.items.length, s.totalRange ~/ 3); // 21/3=7
      expect(s.options.length, 4);
    });
  });

  group('Gad7Scale.computeResult 严重度切分', () {
    final s = gad7Scale;
    List<int> scores(int n) => List.filled(n, 1).toList(); // n 个 1 分

    test('0 → 几乎没有', () {
      final r = s.computeResult([0, 0, 0, 0, 0, 0, 0]);
      expect(r.total, 0);
      expect(r.summary, '几乎没有焦虑倾向');
      expect(r.recommendDoctorVisit, isFalse);
      expect(r.urgentDoctorVisit, isFalse);
    });

    test('4 → 几乎没有（边界）', () {
      final r = s.computeResult(scores(4));
      expect(r.summary, '几乎没有焦虑倾向');
    });

    test('5 → 轻度', () {
      final r = s.computeResult(scores(5));
      expect(r.summary, '轻度焦虑倾向');
    });

    test('9 → 轻度（边界）', () {
      final r = s.computeResult(scores(9));
      expect(r.summary, '轻度焦虑倾向');
    });

    test('10 → 中度（开始建议就医）', () {
      final r = s.computeResult(scores(10));
      expect(r.summary, '中度焦虑倾向');
      expect(r.recommendDoctorVisit, isTrue);
      expect(r.urgentDoctorVisit, isFalse);
    });

    test('14 → 中度（边界）', () {
      final r = s.computeResult(scores(14));
      expect(r.summary, '中度焦虑倾向');
    });

    test('15 → 重度（强烈建议就医）', () {
      final r = s.computeResult(scores(15));
      expect(r.summary, '重度焦虑倾向');
      expect(r.recommendDoctorVisit, isTrue);
      expect(r.urgentDoctorVisit, isTrue);
    });

    test('21 → 重度（最大）', () {
      final r = s.computeResult([3, 3, 3, 3, 3, 3, 3]);
      expect(r.total, 21);
      expect(r.summary, '重度焦虑倾向');
    });
  });

  group('Gad7Scale.detectCrisis', () {
    test('GAD-7 不触发危机（无自杀念头相关题）', () {
      final r = gad7Scale.computeResult([3, 3, 3, 3, 3, 3, 3]); // 21 重度
      final crisis = gad7Scale.detectCrisis([3, 3, 3, 3, 3, 3, 3], r);
      expect(crisis, isNull);
    });
  });
}
