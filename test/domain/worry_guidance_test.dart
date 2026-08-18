// R128e (论文3 §5.3): WorryGuidance 引导索引单测
import 'package:chroniccare/domain/logic/worry_guidance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorryGuidance.guidanceIndexFor', () {
    test('返回 1..5 闭区间', () {
      for (var day = 1; day <= 31; day++) {
        for (var hour = 0; hour < 24; hour++) {
          final idx = WorryGuidance.guidanceIndexFor(
            DateTime(2026, 8, day, hour),
          );
          expect(idx, inInclusiveRange(1, 5));
        }
      }
    });

    test('同一 createdAt 稳定返回同一索引 (不随调用闪烁)', () {
      final created = DateTime(2026, 8, 18, 14);
      final a = WorryGuidance.guidanceIndexFor(created);
      final b = WorryGuidance.guidanceIndexFor(created);
      expect(a, b);
    });

    test('不同 createdAt 可轮换出不同索引 (覆盖全部 5 条)', () {
      final seen = <int>{};
      for (var i = 0; i < 20; i++) {
        seen.add(
          WorryGuidance.guidanceIndexFor(DateTime(2026, 8, 1, i)),
        );
      }
      expect(seen, containsAll([1, 2, 3, 4, 5]));
    });
  });
}
