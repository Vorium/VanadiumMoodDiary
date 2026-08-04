// v0.29 round 84 (CBT 思维记录): ThoughtRecordLevel enum 单元测试
//
// 覆盖:
// 1. columnCount 三档分别返回 3/5/7
// 2. fromInt 合法值 (3/5/7) 解析正确
// 3. fromInt 非法值 fallback 到 three (跟"老 SP 数据 / 手改配置"容错)
import 'package:chroniccare/domain/entities/thought_record_level.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThoughtRecordLevel (v0.29 round 84)', () {
    test('三档 columnCount 分别是 3/5/7', () {
      expect(ThoughtRecordLevel.three.columnCount, 3);
      expect(ThoughtRecordLevel.five.columnCount, 5);
      expect(ThoughtRecordLevel.seven.columnCount, 7);
    });

    test('fromInt 3/5/7 解析', () {
      expect(ThoughtRecordLevel.fromInt(3), ThoughtRecordLevel.three);
      expect(ThoughtRecordLevel.fromInt(5), ThoughtRecordLevel.five);
      expect(ThoughtRecordLevel.fromInt(7), ThoughtRecordLevel.seven);
    });

    test('fromInt 非法值 fallback 到 three', () {
      expect(ThoughtRecordLevel.fromInt(0), ThoughtRecordLevel.three);
      expect(ThoughtRecordLevel.fromInt(99), ThoughtRecordLevel.three);
      expect(ThoughtRecordLevel.fromInt(-1), ThoughtRecordLevel.three);
    });
  });
}
