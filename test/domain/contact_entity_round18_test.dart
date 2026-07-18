/// v0.18 round 18 (P1-14) ContactEntity.isValidPhone 5 region 同步测试
///
/// domain 层不能 import PhoneValidator (data 层),所以 entity 内联了同样的
/// regex 逻辑。本测试同时覆盖 5 个 region,验证 entity 行为正确。
///
/// 如果 PhoneValidator regex 改了但 ContactEntity 没同步,本测试仍能
/// 覆盖 entity 自身正确性。同步性靠 CI review。
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/domain/entities/contact_entity.dart';

ContactEntity _c(String phone) => ContactEntity(
      id: 1,
      name: 'Test',
      phone: phone,
    );

void main() {
  group('ContactEntity.isValidPhone - 中国大陆', () {
    test('11 位 1[3-9] 开头有效', () {
      expect(_c('13800138000').isValidPhone, isTrue);
      expect(_c('15912345678').isValidPhone, isTrue);
    });

    test('+86 前缀有效', () {
      expect(_c('+8613800138000').isValidPhone, isTrue);
      expect(_c('+86-13800138000').isValidPhone, isTrue);
    });

    test('1[0-2] 开头无效', () {
      expect(_c('10888888888').isValidPhone, isFalse);
      expect(_c('11888888888').isValidPhone, isFalse);
    });
  });

  group('ContactEntity.isValidPhone - 港澳台/国际', () {
    test('HK 8 位 [45789] 有效', () {
      expect(_c('91234567').isValidPhone, isTrue);
      expect(_c('+85291234567').isValidPhone, isTrue);
    });

    test('MO 8 位 6 开头有效', () {
      expect(_c('61234567').isValidPhone, isTrue);
      expect(_c('+85361234567').isValidPhone, isTrue);
    });

    test('TW 9 位 9 开头有效', () {
      expect(_c('912345678').isValidPhone, isTrue);
      expect(_c('+886912345678').isValidPhone, isTrue);
    });

    test('国际 E.164 有效', () {
      expect(_c('+14155551234').isValidPhone, isTrue);
      expect(_c('+442071234567').isValidPhone, isTrue);
    });
  });

  group('ContactEntity.isValidPhone - 边界', () {
    test('空 / 纯空格 / null-like 无效', () {
      expect(_c('').isValidPhone, isFalse);
      expect(_c('   ').isValidPhone, isFalse);
    });

    test('0 开头 11 位无效(防大陆座机)', () {
      expect(_c('01012345678').isValidPhone, isFalse);
    });

    test('+ 后面 5 位或 17 位无效', () {
      expect(_c('+12345').isValidPhone, isFalse);
      expect(_c('+12345678901234567').isValidPhone, isFalse);
    });

    test('+ 但区号跟号码不匹配:8 位 6 开头带 + 走 intl', () {
      // +61234567 9 位数字,_intl \+\d{6,15} 接受 → intl
      expect(_c('+61234567').isValidPhone, isTrue);
    });
  });
}
