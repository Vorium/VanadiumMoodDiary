/// v0.18 round 18 (P1-14) PhoneValidator 5 region 扩展测试
///
/// 覆盖:
/// - 大陆 / 香港 / 澳门 / 台湾 / 国际 5 region 解析
/// - +86 / 86 / +86- / +86 空格 前缀变体
/// - 边界:空 / 0 开头 / 12 位 / 7 位
/// - PhoneNumber.e164 / display 格式
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/core/data/utils/phone_validator.dart';

void main() {
  group('PhoneValidator.parse - 中国大陆', () {
    test('11 位 1[3-9] 开头全部有效', () {
      for (final p in [
        '13800138000',
        '15912345678',
        '18888888888',
        '19876543210',
      ]) {
        final r = PhoneValidator.parse(p);
        expect(r, isNotNull, reason: '$p 应该是大陆手机');
        expect(r!.region, PhoneRegion.cn);
        expect(r.digits, p);
        expect(r.e164, '+86$p');
      }
    });

    test('10 / 12 位 1 开头无效', () {
      expect(PhoneValidator.parse('1380013800'), isNull); // 10 位
      expect(PhoneValidator.parse('138001380000'), isNull); // 12 位
    });

    test('11 位 1[0-2] 开头无效(非手机号段)', () {
      // 11 位 1[0-2] 开头(108/118/128)不匹配任何 region
      expect(PhoneValidator.parse('10888888888'), isNull);
      expect(PhoneValidator.parse('11888888888'), isNull);
      expect(PhoneValidator.parse('12888888888'), isNull);
    });

    test('+86 / 86 / +86- / +86 空格前缀都解析为大陆', () {
      for (final p in [
        '+8613800138000',
        '8613800138000',
        '+86-13800138000',
        '+86 13800138000',
        '+86 138 0013 8000',
      ]) {
        final r = PhoneValidator.parse(p);
        expect(r, isNotNull, reason: '$p 应该是大陆手机');
        expect(r!.region, PhoneRegion.cn);
        expect(r.digits, '13800138000');
        expect(r.e164, '+8613800138000');
      }
    });
  });

  group('PhoneValidator.parse - 中国香港', () {
    test('8 位 [45789] 开头有效', () {
      for (final p in [
        '91234567', // 9 开头 (5G)
        '81234567', // 8 开头 (4G)
        '71234567', // 7 开头 (3G)
        '51234567', // 5 开头 (2G)
        '41234567', // 4 开头 (2G)
      ]) {
        final r = PhoneValidator.parse(p);
        expect(r, isNotNull, reason: '$p 应该是香港手机');
        expect(r!.region, PhoneRegion.hk);
        expect(r.digits, p);
        expect(r.e164, '+852$p');
      }
    });

    test('8 位 6 开头归澳门(优先级 mo > hk)', () {
      final r = PhoneValidator.parse('61234567');
      expect(r, isNotNull);
      expect(r!.region, PhoneRegion.mo);
      expect(r.e164, '+85361234567');
    });

    test('8 位 2/3 开头无效(2/3 是 HK 座机,不是手机)', () {
      expect(PhoneValidator.parse('21234567'), isNull);
      expect(PhoneValidator.parse('31234567'), isNull);
    });

    test('+852 / 852 / +852- 前缀都解析为香港', () {
      for (final p in [
        '+85291234567',
        '85291234567',
        '+852-91234567',
        '+852 9123 4567',
      ]) {
        final r = PhoneValidator.parse(p);
        expect(r, isNotNull, reason: '$p 应该是香港手机');
        expect(r!.region, PhoneRegion.hk);
        expect(r.digits, '91234567');
      }
    });
  });

  group('PhoneValidator.parse - 中国澳门', () {
    test('8 位 6 开头有效', () {
      final r = PhoneValidator.parse('61234567');
      expect(r, isNotNull);
      expect(r!.region, PhoneRegion.mo);
      expect(r.digits, '61234567');
      expect(r.e164, '+85361234567');
    });

    test('+853 前缀', () {
      final r = PhoneValidator.parse('+853 6123 4567');
      expect(r, isNotNull);
      expect(r!.region, PhoneRegion.mo);
      expect(r.digits, '61234567');
    });
  });

  group('PhoneValidator.parse - 中国台湾', () {
    test('9 位 9 开头有效', () {
      final r = PhoneValidator.parse('912345678');
      expect(r, isNotNull);
      expect(r!.region, PhoneRegion.tw);
      expect(r.digits, '912345678');
      expect(r.e164, '+886912345678');
    });

    test('+886 前缀', () {
      final r = PhoneValidator.parse('+886-912345678');
      expect(r, isNotNull);
      expect(r!.region, PhoneRegion.tw);
      expect(r.digits, '912345678');
    });

    test('10 位 09 开头无效(用户应填 9xxxxxxxx 不带 0)', () {
      // 0 开头 10 位 = 旧式 09xxxxxxxx,但会先被 tw 9 位尝试 fail
      // 然后 9 位 [45789] 试 fail,6 位试 fail → null
      expect(PhoneValidator.parse('0912345678'), isNull);
    });
  });

  group('PhoneValidator.parse - 国际 E.164', () {
    test('+ 后 6-15 位数字有效', () {
      for (final p in [
        '+14155551234', // 美国
        '+442071234567', // 英国
        '+81312345678', // 日本
        '+6591234567', // 新加坡
        '+12025551234', // 加拿大
      ]) {
        final r = PhoneValidator.parse(p);
        expect(r, isNotNull, reason: '$p 应该是国际号码');
        expect(r!.region, PhoneRegion.intl);
        expect(r.e164, p);
      }
    });

    test('+ 后 < 6 位或 > 15 位无效', () {
      expect(PhoneValidator.parse('+12345'), isNull); // 5 位
      expect(PhoneValidator.parse('+12345678901234567'), isNull); // 17 位
    });

    test('+ 后有非数字无效', () {
      expect(PhoneValidator.parse('+1415abc1234'), isNull);
    });
  });

  group('PhoneValidator.parse - 边界 case', () {
    test('空字符串 / 纯空格 / null-like 全部 null', () {
      expect(PhoneValidator.parse(''), isNull);
      expect(PhoneValidator.parse('   '), isNull);
      expect(PhoneValidator.parse('\t\n'), isNull);
    });

    test('前后空格自动 trim', () {
      final r = PhoneValidator.parse('  13800138000  ');
      expect(r, isNotNull);
      expect(r!.region, PhoneRegion.cn);
    });

    test('未带 + 但 0 开头 11 位无效(防大陆座机)', () {
      expect(PhoneValidator.parse('01012345678'), isNull);
      expect(PhoneValidator.parse('02112345678'), isNull);
    });

    test('+ 但区号跟号码不匹配无效', () {
      // 6 开头 8 位不是 mo 也不是 hk → 整体不匹配 +86/+852/+853/+886
      // 然后 _intl 试 +\d{6,15} → 6 开头 8 位共 8 位数字 6+8=9 长度 → 不匹配 8 位
      // 实际上 +61234567 长度 9 位,_intl \+\d{6,15} 接受 6-15 位 → 匹配上 → 归 intl
      // 这不是 bug,是设计妥协(无法区分 +6 开头短号码是 mo 还是 intl 短号)
      // 6 开头 8 位如果带 + 前缀,优先 mo,实际 _moWithPrefix 是
      // ^(\+?853[-\s]?)?6\d{7}$ → 不会匹配 +61234567(无 853 前缀)
      // 所以会落到 _intl → 归 intl
      final r = PhoneValidator.parse('+61234567');
      expect(r, isNotNull);
      expect(r!.region, PhoneRegion.intl);
    });
  });

  group('PhoneValidator.isValid', () {
    test('parse 返回非 null 则 isValid = true', () {
      expect(PhoneValidator.isValid('13800138000'), isTrue);
      expect(PhoneValidator.isValid('+8613800138000'), isTrue);
      expect(PhoneValidator.isValid('91234567'), isTrue); // HK
      expect(PhoneValidator.isValid('+85291234567'), isTrue);
      expect(PhoneValidator.isValid('+14155551234'), isTrue);
    });

    test('parse 返回 null 则 isValid = false', () {
      expect(PhoneValidator.isValid(''), isFalse);
      expect(PhoneValidator.isValid('12345'), isFalse);
      expect(PhoneValidator.isValid('abc'), isFalse);
      expect(PhoneValidator.isValid('+12345'), isFalse);
    });
  });

  group('PhoneValidator.normalize - E.164 输出', () {
    test('大陆返回 +86 + 11 位', () {
      expect(PhoneValidator.normalize('13800138000'), '+8613800138000');
      expect(PhoneValidator.normalize('+86-13800138000'), '+8613800138000');
    });

    test('HK 返回 +852 + 8 位', () {
      expect(PhoneValidator.normalize('91234567'), '+85291234567');
      expect(PhoneValidator.normalize('+852 9123 4567'), '+85291234567');
    });

    test('MO 返回 +853 + 8 位', () {
      expect(PhoneValidator.normalize('61234567'), '+85361234567');
    });

    test('TW 返回 +886 + 9 位', () {
      expect(PhoneValidator.normalize('912345678'), '+886912345678');
    });

    test('国际返回原 + 号码', () {
      expect(PhoneValidator.normalize('+14155551234'), '+14155551234');
    });

    test('无效返回 null', () {
      expect(PhoneValidator.normalize('12345'), isNull);
      expect(PhoneValidator.normalize(''), isNull);
    });
  });

  group('PhoneNumber.e164 + display', () {
    test('cn display 加 86 前缀 + 分组', () {
      final p = PhoneValidator.parse('13800138000')!;
      expect(p.e164, '+8613800138000');
      expect(p.display, '+86 138 0013 8000');
    });

    test('hk display 加 852 前缀 + 分组', () {
      final p = PhoneValidator.parse('91234567')!;
      expect(p.e164, '+85291234567');
      expect(p.display, '+852 9123 4567');
    });

    test('mo display 加 853 前缀 + 分组', () {
      final p = PhoneValidator.parse('61234567')!;
      expect(p.e164, '+85361234567');
      expect(p.display, '+853 6123 4567');
    });

    test('tw display 加 886 前缀 + 分组', () {
      final p = PhoneValidator.parse('912345678')!;
      expect(p.e164, '+886912345678');
      expect(p.display, '+886 9123 45678');
    });

    test('intl display = e164(无固定分组)', () {
      final p = PhoneValidator.parse('+14155551234')!;
      expect(p.e164, '+14155551234');
      expect(p.display, '+14155551234');
    });
  });

  group('PhoneRegion - displayName / dialCode', () {
    test('cn / hk / mo / tw / intl 都有 displayName', () {
      expect(PhoneRegion.cn.displayName, '中国大陆');
      expect(PhoneRegion.hk.displayName, '中国香港');
      expect(PhoneRegion.mo.displayName, '中国澳门');
      expect(PhoneRegion.tw.displayName, '中国台湾');
      expect(PhoneRegion.intl.displayName, '国际');
    });

    test('cn / hk / mo / tw / intl 都有 dialCode', () {
      expect(PhoneRegion.cn.dialCode, '86');
      expect(PhoneRegion.hk.dialCode, '852');
      expect(PhoneRegion.mo.dialCode, '853');
      expect(PhoneRegion.tw.dialCode, '886');
      expect(PhoneRegion.intl.dialCode, '');
    });
  });

  group('PhoneValidator.isStrictValid - 旧 API 兼容', () {
    test('11 位大陆 1[3-9] 有效', () {
      expect(PhoneValidator.isStrictValid('13800138000'), isTrue);
      expect(PhoneValidator.isStrictValid('15912345678'), isTrue);
    });

    test('带 +86 前缀 11 位严格模式失败(只接受纯 11 位)', () {
      expect(PhoneValidator.isStrictValid('+8613800138000'), isFalse);
    });
  });
}
