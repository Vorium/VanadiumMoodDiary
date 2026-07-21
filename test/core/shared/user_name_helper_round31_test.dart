// safeUserName 单元测试 — v0.22 round 31 (sp-en P0-3) 抽 helper 时补
//
// 覆盖 4 类场景：
// 1. 老数据 "" 空字符串
// 2. 新数据 null
// 3. 正常姓名
// 4. 自定义 fallback
import 'package:chroniccare/core/shared/user_name_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('safeUserName — v0.22 round 31', () {
    test('老数据 "" 空字符串 → fallback', () {
      expect(safeUserName(''), '您');
    });

    test('新数据 null → fallback', () {
      expect(safeUserName(null), '您');
    });

    test('正常姓名 → 原样返回', () {
      expect(safeUserName('张三'), '张三');
    });

    test('自定义 fallback 生效', () {
      // 通知 / 邮件场景常用 "您的家人" 更礼貌
      expect(safeUserName(null, fallback: '您的家人'), '您的家人');
      expect(safeUserName('', fallback: '您的家人'), '您的家人');
    });

    test('fallback 不影响正常姓名', () {
      expect(safeUserName('李四', fallback: '您的家人'), '李四');
    });
  });
}
