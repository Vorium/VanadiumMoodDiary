/// 手机号校验（v0.18 P1-14: 扩展支持港澳台/国际）
///
/// 支持的号码格式：
/// - 中国大陆 +86: 1[3-9] 开头的 11 位数字（`^1[3-9]\d{9}$`）
/// - 中国香港 +852: [45789] 开头的 8 位数字（`^[45789]\d{7}$`）
/// - 中国澳门 +853: 6 开头的 8 位数字（`^6\d{7}$`）
/// - 中国台湾 +886: 9 开头的 9 位数字（`^9\d{8}$`）
/// - 国际 E.164: `+` 后 6-15 位数字（`^\+\d{6,15}$`）
///
/// 5 个 regex 之间无歧义（位数 + 开头数字都不同）。
///
/// 历史：v0.6-v0.17 只支持大陆 11 位手机号。海外华人、港澳台用户的紧急联系
/// 人无法录入。v0.18 P1-14 扩展。
class PhoneValidator {
  PhoneValidator._();

  // ===== 5 个 region 的 regex =====

  /// 中国大陆 11 位
  static final _cn = RegExp(r'^1[3-9]\d{9}$');

  /// 中国大陆 11 位,可选 +86 / 86 / +86- / +86 空格 前缀
  static final _cnWithPrefix =
      RegExp(r'^(\+?86[-\s]?)?1[3-9]\d{9}$');

  /// 中国香港 8 位手机（4/5/7/8/9 开头,6 开头已停用归澳门）
  static final _hk = RegExp(r'^[45789]\d{7}$');

  /// 中国香港 8 位,可选 +852 / 852 前缀
  static final _hkWithPrefix =
      RegExp(r'^(\+?852[-\s]?)?[45789]\d{7}$');

  /// 中国澳门 8 位（6 开头）
  static final _mo = RegExp(r'^6\d{7}$');

  /// 中国澳门 8 位,可选 +853 / 853 前缀
  static final _moWithPrefix =
      RegExp(r'^(\+?853[-\s]?)?6\d{7}$');

  /// 中国台湾 9 位（9 开头,实际是 09xxxxxxxx 共 10 位去掉 0）
  static final _tw = RegExp(r'^9\d{8}$');

  /// 中国台湾 9 位,可选 +886 / 886 前缀
  static final _twWithPrefix =
      RegExp(r'^(\+?886[-\s]?)?9\d{8}$');

  /// 国际 E.164: `+` 后 6-15 位数字
  static final _intl = RegExp(r'^\+\d{6,15}$');

  // ===== 公共 API =====

  /// 解析手机号,返回 PhoneNumber 或 null
  ///
  /// 自动探测规则:
  /// 1. `+` 开头 → 优先匹配 +86/+852/+853/+886,匹配不上走国际 E.164
  /// 2. 纯数字 → 按位数 + 开头匹配 cn(11)/hk(8)/mo(8,优先)/tw(9)
  static PhoneNumber? parse(String input) {
    final raw = input.trim();
    if (raw.isEmpty) return null;

    // 去掉号码内部分隔符（空格 / 短横线）,保留开头的 +
    // +86 138 0013 8000 → +8613800138000
    // +852-9123-4567 → +85291234567
    final s = raw.startsWith('+')
        ? '+${raw.substring(1).replaceAll(RegExp(r'[\s-]'), '')}'
        : raw.replaceAll(RegExp(r'[\s-]'), '');

    // 带 + 前缀
    if (s.startsWith('+')) {
      if (_cnWithPrefix.hasMatch(s)) {
        return PhoneNumber(PhoneRegion.cn, _stripPrefix(s, '86'));
      }
      if (_hkWithPrefix.hasMatch(s)) {
        return PhoneNumber(PhoneRegion.hk, _stripPrefix(s, '852'));
      }
      if (_moWithPrefix.hasMatch(s)) {
        return PhoneNumber(PhoneRegion.mo, _stripPrefix(s, '853'));
      }
      if (_twWithPrefix.hasMatch(s)) {
        return PhoneNumber(PhoneRegion.tw, _stripPrefix(s, '886'));
      }
      if (_intl.hasMatch(s)) {
        return PhoneNumber(PhoneRegion.intl, s.substring(1));
      }
      return null;
    }

    // 纯数字（无 + 前缀）
    // 优先级:cn(11) > tw(9) > hk(8) > mo(8,6 开头)
    if (_cn.hasMatch(s)) return PhoneNumber(PhoneRegion.cn, s);
    if (_tw.hasMatch(s)) return PhoneNumber(PhoneRegion.tw, s);
    if (_hk.hasMatch(s)) return PhoneNumber(PhoneRegion.hk, s);
    if (_mo.hasMatch(s)) return PhoneNumber(PhoneRegion.mo, s);

    // 兜底:无 + 但可能带区号 prefix 的纯数字（如 8613800138000 = 86 + 13800138000）
    // _cnWithPrefix 等要求 prefix 后紧接 1[3-9]/[45789]/6/9,但
    // "8613800138000" 这种写法 86 跟 1 直接拼在一起 = 12 位数字,regex 不匹配。
    // 手动按区号长度拆分重试。
    for (final entry in const [
      ('86', PhoneRegion.cn, 11),  // 86 + 11 位
      ('852', PhoneRegion.hk, 8),  // 852 + 8 位
      ('853', PhoneRegion.mo, 8),  // 853 + 8 位
      ('886', PhoneRegion.tw, 9),  // 886 + 9 位
    ]) {
      if (s.startsWith(entry.$1) && s.length == entry.$1.length + entry.$3) {
        final tail = s.substring(entry.$1.length);
        final tailValid = switch (entry.$2) {
          PhoneRegion.cn => _cn.hasMatch(tail),
          PhoneRegion.hk => _hk.hasMatch(tail),
          PhoneRegion.mo => _mo.hasMatch(tail),
          PhoneRegion.tw => _tw.hasMatch(tail),
          PhoneRegion.intl => false,
        };
        if (tailValid) {
          return PhoneNumber(entry.$2, tail);
        }
      }
    }

    return null;
  }

  /// 是否有效手机号（任意 region）
  static bool isValid(String input) => parse(input) != null;

  /// 校验并返回规范化结果
  ///
  /// 返回 E.164 格式:中国大陆 → `+86` + 11 位数字,
  /// 港澳台 → `+852`/`+853`/`+886` + 号码,国际 → `+` + 号码。
  ///
  /// v0.18 P1-14 行为变更:之前大陆号码返回纯 11 位数字(如 `13800138000`),
  /// 现在统一返回 E.164 格式(`+8613800138000`)。DB schema 不变(都是 string),
  /// 失联通知 SMS API 一致(都接 E.164)。
  static String? normalize(String input) => parse(input)?.e164;

  /// 严格大陆校验(只接受 11 位无前缀)——保留供老测试使用
  static bool isStrictValid(String input) {
    return _cn.hasMatch(input.trim());
  }

  // ===== 私有 helper =====

  /// 去掉 + / +区号 / 短横线 / 空格,返回纯数字
  static String _stripPrefix(String s, String dialCode) {
    var t = s.substring(1); // 去 +
    if (t.startsWith(dialCode)) {
      t = t.substring(dialCode.length);
    }
    return t.replaceAll(RegExp(r'[-\s]'), '');
  }
}

/// 区号枚举
enum PhoneRegion {
  cn,
  hk,
  mo,
  tw,
  intl;

  /// 显示名(中文)
  String get displayName {
    switch (this) {
      case PhoneRegion.cn:
        return '中国大陆';
      case PhoneRegion.hk:
        return '中国香港';
      case PhoneRegion.mo:
        return '中国澳门';
      case PhoneRegion.tw:
        return '中国台湾';
      case PhoneRegion.intl:
        return '国际';
    }
  }

  /// 国际拨号区号(无 +)
  String get dialCode {
    switch (this) {
      case PhoneRegion.cn:
        return '86';
      case PhoneRegion.hk:
        return '852';
      case PhoneRegion.mo:
        return '853';
      case PhoneRegion.tw:
        return '886';
      case PhoneRegion.intl:
        return '';
    }
  }
}

/// 解析后的手机号
class PhoneNumber {
  final PhoneRegion region;
  final String digits; // 纯数字(无 + 前缀)

  const PhoneNumber(this.region, this.digits);

  /// E.164 格式:`+` + 区号(若 region 有) + 号码
  /// 国际 region 直接是 `+` + digits(因为区号已含)
  String get e164 {
    if (region == PhoneRegion.intl) {
      return '+$digits';
    }
    return '+${region.dialCode}$digits';
  }

  /// 显示格式:`+86 138 0013 8000`(cn 简单分组)
  String get display {
    switch (region) {
      case PhoneRegion.cn:
        if (digits.length == 11) {
          return '+86 ${digits.substring(0, 3)} ${digits.substring(3, 7)} ${digits.substring(7)}';
        }
        return e164;
      case PhoneRegion.hk:
        if (digits.length == 8) {
          return '+852 ${digits.substring(0, 4)} ${digits.substring(4)}';
        }
        return e164;
      case PhoneRegion.mo:
        if (digits.length == 8) {
          return '+853 ${digits.substring(0, 4)} ${digits.substring(4)}';
        }
        return e164;
      case PhoneRegion.tw:
        if (digits.length == 9) {
          return '+886 ${digits.substring(0, 4)} ${digits.substring(4)}';
        }
        return e164;
      case PhoneRegion.intl:
        return e164;
    }
  }

  @override
  String toString() => 'PhoneNumber(${region.name}, $digits)';

  @override
  bool operator ==(Object other) =>
      other is PhoneNumber &&
      other.region == region &&
      other.digits == digits;

  @override
  int get hashCode => Object.hash(region, digits);
}
