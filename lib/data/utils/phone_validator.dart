/// 中国大陆手机号校验
///
/// 规则：1[3-9] 开头的 11 位数字
/// 可选 +86 / 86 前缀（带或不带空格/短横线）
///
/// 严格模式（无前缀）：`^1[3-9]\d{9}$`
/// 宽松模式（接受 86/+86 前缀）：`^(\+?86[-\s]?)?1[3-9]\d{9}$`
class PhoneValidator {
  PhoneValidator._();

  /// 宽松：接受 13800138000 / +8613800138000 / 86-13800138000 等格式
  /// 整个 +86 / 86 前缀都是可选
  static final _loose = RegExp(r'^(\+?86[-\s]?)?1[3-9]\d{9}$');

  /// 严格：11 位数字，无前缀
  static final _strict = RegExp(r'^1[3-9]\d{9}$');

  /// 是否有效手机号（宽松匹配）
  static bool isValid(String input) {
    final trimmed = input.trim();
    return _loose.hasMatch(trimmed);
  }

  /// 校验并返回规范化结果
  ///
  /// 返回 null 表示无效；返回 11 位纯数字手机号表示已规范化
  static String? normalize(String input) {
    final trimmed = input.trim();
    if (_loose.hasMatch(trimmed)) {
      // 去掉 +86 / 86 / 短横线 / 空格
      return trimmed.replaceAll(RegExp(r'^\+?86[-\s]?'), '');
    }
    return null;
  }

  /// 严格校验（只接受 11 位无前缀）
  static bool isStrictValid(String input) {
    return _strict.hasMatch(input.trim());
  }
}
