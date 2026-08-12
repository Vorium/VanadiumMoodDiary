// v0.14 (Round 12A) ContactEntity — 纯 Dart domain entity
//
// 4 层架构示范：domain 层不依赖 Drift。
//
// v0.27 round 63 (P0-2 修复): 加 4 个 consent 字段 (PIPL §13 留痕)
// - consentAt: DateTime? 同意时间
// - consentKind: ConsentKind? 同意类型 (5 值 enum, nullable)
// - consentBy: String? 同意主体 (默认 "user")
// - consentVersion: String? 同意版本号 (法务模板版本)
// - 4 字段全部 nullable, 旧数据 (schemaVersion <= 14) 升级时为 null
// - 新加联系人 (schemaVersion 15+) 必有值
// - consentKind 用 nullable enum 而非 DomainValue 是因为:
//   1) DomainValue 无 absent() 工厂
//   2) nullable enum 直接表达"缺席",语义最清晰
//   3) copyWith 不能用 `?? this.consentKind` 区分"保持"和"清空", 但本 entity
//      不需要清空语义 (consent 一旦同意就不可清空, 撤回走 LegalConsentStore)

import 'package:chroniccare/domain/entities/consent_artifact.dart';

/// 紧急联系人（领域实体）
///
/// 字段含义见 `lib/data/database/tables/contacts.dart`。
class ContactEntity {
  final int id;
  final String name;
  final String phone;
  final int sortOrder;
  final bool isActive;

  /// v0.27 round 63 (P0-2 修复): PIPL §13 留痕 4 字段
  final DateTime? consentAt;
  final ConsentKind? consentKind;
  final String? consentBy;
  final String? consentVersion;

  const ContactEntity({
    required this.id,
    required this.name,
    required this.phone,
    this.sortOrder = 0,
    this.isActive = true,
    this.consentAt,
    this.consentKind,
    this.consentBy,
    this.consentVersion,
  });

  // ===== 业务方法 =====

  /// 是否启用
  bool get active => isActive;

  /// 是否手机号格式正确
  ///
  /// v0.18 P1-14: 扩展支持 5 个 region（cn / hk / mo / tw / intl）。
  /// 必须跟 `lib/core/shared/phone_validator.dart` 保持同步
  /// （R110 round 3: phone_validator 移 core/shared 后 domain 可直连,
  /// 但 contact_entity 的 regex 仍为 0 依赖自带副本, 两边保持一致）。
  /// CI 曾用 `phone_validator_sync_test.dart` 验证两边 regex 一致
  /// （R109 清理时已删, 现在靠 round18 test 兜底）。
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
    DateTime? consentAt,
    ConsentKind? consentKind,
    String? consentBy,
    String? consentVersion,
  }) {
    return ContactEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      consentAt: consentAt ?? this.consentAt,
      consentKind: consentKind ?? this.consentKind,
      consentBy: consentBy ?? this.consentBy,
      consentVersion: consentVersion ?? this.consentVersion,
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
        other.isActive == isActive &&
        other.consentAt == consentAt &&
        other.consentKind == consentKind &&
        other.consentBy == consentBy &&
        other.consentVersion == consentVersion;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        phone,
        sortOrder,
        isActive,
        consentAt,
        consentKind,
        consentBy,
        consentVersion,
      );

  @override
  String toString() =>
      'ContactEntity(id=$id, name=$name, phone=$phone, order=$sortOrder, '
      'active=$isActive, consentAt=$consentAt, consentKind=$consentKind, '
      'consentBy=$consentBy, consentVersion=$consentVersion)';
}
