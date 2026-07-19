// v0.14 (Round 12A) ContactEntity — 纯 Dart domain entity
//
// 4 层架构示范：domain 层不依赖 Drift。
library;

/// 紧急联系人（领域实体）
///
/// 字段含义见 `lib/data/database/tables/contacts.dart`。
class ContactEntity {
  final int id;
  final String name;
  final String phone;
  final int sortOrder;
  final bool isActive;

  const ContactEntity({
    required this.id,
    required this.name,
    required this.phone,
    this.sortOrder = 0,
    this.isActive = true,
  });

  // ===== 业务方法 =====

  /// 是否启用
  bool get active => isActive;

  /// 是否手机号格式正确
  ///
  /// v0.18 P1-14: 扩展支持 5 个 region（cn / hk / mo / tw / intl）。
  /// 必须跟 `lib/core/data/utils/phone_validator.dart` 保持同步
  /// （domain 不能 import data,regex 复制一份）。
  /// CI 用 `phone_validator_sync_test.dart` 验证两边 regex 一致。
  // 缓存正则（避免每次 isValidPhone 调用创建 8 个 RegExp）
  static final _cnWithPrefix = RegExp(r'^(\+?86[-\s]?)?1[3-9]\d{9}$');
  static final _hkWithPrefix = RegExp(r'^(\+?852[-\s]?)?[45789]\d{7}$');
  static final _moWithPrefix = RegExp(r'^(\+?853[-\s]?)?6\d{7}$');
  static final _twWithPrefix = RegExp(r'^(\+?886[-\s]?)?9\d{8}$');
  static final _intlWithPrefix = RegExp(r'^\+\d{6,15}$');
  static final _cnPure = RegExp(r'^1[3-9]\d{9}$');
  static final _twPure = RegExp(r'^9\d{8}$');
  static final _hkPure = RegExp(r'^[45789]\d{7}$');
  static final _moPure = RegExp(r'^6\d{7}$');

  bool get isValidPhone {
    final s = phone.trim();
    if (s.isEmpty) return false;

    // 1. 带 + 前缀
    if (s.startsWith('+')) {
      if (_cnWithPrefix.hasMatch(s)) return true;
      if (_hkWithPrefix.hasMatch(s)) return true;
      if (_moWithPrefix.hasMatch(s)) return true;
      if (_twWithPrefix.hasMatch(s)) return true;
      if (_intlWithPrefix.hasMatch(s)) return true;
      return false;
    }

    // 2. 纯数字:cn(11) > tw(9) > hk(8) > mo(8)
    if (_cnPure.hasMatch(s)) return true;
    if (_twPure.hasMatch(s)) return true;
    if (_hkPure.hasMatch(s)) return true;
    if (_moPure.hasMatch(s)) return true;
    return false;
  }

  /// 用于排序 / 选择最低 sortOrder 优先
  static int Function(ContactEntity, ContactEntity) get bySortOrder =>
      (a, b) => a.sortOrder.compareTo(b.sortOrder);

  ContactEntity copyWith({
    int? id,
    String? name,
    String? phone,
    int? sortOrder,
    bool? isActive,
  }) {
    return ContactEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactEntity &&
        other.id == id &&
        other.name == name &&
        other.phone == phone &&
        other.sortOrder == sortOrder &&
        other.isActive == isActive;
  }

  @override
  int get hashCode => Object.hash(id, name, phone, sortOrder, isActive);

  @override
  String toString() =>
      'ContactEntity(id=$id, name=$name, phone=$phone, order=$sortOrder, active=$isActive)';
}
