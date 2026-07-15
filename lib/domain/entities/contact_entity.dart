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

  /// 是否手机号格式正确（中国大陆 11 位，可选 +86 前缀）
  bool get isValidPhone {
    final digits = phone.replaceFirst(RegExp(r'^\+?86'), '');
    return RegExp(r'^\d{11}$').hasMatch(digits);
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
