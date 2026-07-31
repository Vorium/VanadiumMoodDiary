import 'package:drift/drift.dart';

/// 紧急联系人表
/// 失联通知按 sortOrder 顺序发送给所有启用联系人
/// v0.6：删 email 字段，改用 phone（中国大陆手机号 11 位）
///
/// v0.27 round 63 (P0-2 修复): 加 4 个 consent 字段 (PIPL §13 留痕要求)
/// - consentAt: DateTime 同意时间 (PIPL §17 数据准确性)
/// - consentKind: String 同意类型 (ConsentKind enum.name, 5 个值)
/// - consentBy: String 同意主体 (默认 "user", 未来支持紧急联系人本人代同意)
/// - consentVersion: String 同意版本号 (e.g. "v1" 法务模板版本, 模板更新需重新同意)
/// - 4 字段全部 nullable, 旧数据 (schemaVersion <= 14) 自动为 null
/// - 新加联系人流程 (schemaVersion 15+) 强制 caller 传 ConsentArtifact,
///   ContactRepositoryImpl.add() 把 4 字段写进 ContactsCompanion.insert(...)
/// - 紧急联系人本人独立确认 "Y" (PIPL §13 完整实施) 留 v1.0+ 走 SMS 通道
@DataClassName('Contact')
class Contacts extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 联系人姓名
  TextColumn get name => text()();

  /// 手机号（中国大陆 11 位，可选 +86 前缀）
  TextColumn get phone => text()();

  /// 发送顺序（数字越小越先发）
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// 是否启用
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// v0.27 round 63 (P0-2 修复): PIPL §13 留痕 — 同意时间
  /// nullable: 旧数据 (schemaVersion <= 14) 升级时为 null,
  /// 新加联系人 (ConsentDialog 通过后) 必有值
  DateTimeColumn get consentAt => dateTime().nullable()();

  /// v0.27 round 63 (P0-2 修复): PIPL §13 留痕 — 同意类型
  /// 存 enum.name 字符串 (e.g. "emergencyContactSharing" / "dataExport"),
  /// 读时 ConsentKind.values.firstWhere 还原 enum
  /// 用 String 而非 IntEnumColumn 是因为 enum 可能在 v1.0+ 加值, IntEnum
  /// 受 drift 编译期检查约束, 升级会卡
  TextColumn get consentKind => text().nullable()();

  /// v0.27 round 63 (P0-2 修复): PIPL §13 留痕 — 同意主体
  /// 默认 "user" (用户本人), 未来支持代理人 / 紧急联系人本人
  TextColumn get consentBy => text().nullable()();

  /// v0.27 round 63 (P0-2 修复): PIPL §13 留痕 — 同意版本号
  /// 法务模板更新时需重新同意, 模板有版本号
  TextColumn get consentVersion => text().nullable()();
}
