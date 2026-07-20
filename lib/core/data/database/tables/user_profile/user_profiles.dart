import 'package:drift/drift.dart';

/// 用户档案表
/// 全局单条记录（id 永远是 1）
@DataClassName('UserProfile')
class UserProfiles extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();

  /// 用户姓名（用于邮件中"我是 XXX"，可空 — 不愿透露真实姓名也可）
  ///
  /// v0.21 Round 23 (P1-24 修复): 从 `text()()` 改 `text().nullable()`
  /// 隐私考虑: 部分用户不愿提供真实姓名, 也不希望 App 默认用 "" 或 "Friend" 占位
  /// — 留 null, UI 端 "我是" 时退化为空字符串
  TextColumn get userName => text().nullable()();

  /// 失联判定周期（小时），默认 48
  IntColumn get checkInCycleHours =>
      integer().withDefault(const Constant(48))();

  /// 首次启动时间
  DateTimeColumn get firstLaunchAt => dateTime()();

  /// 最后打卡时间（冗余字段，方便查询）
  DateTimeColumn get lastCheckInAt => dateTime().nullable()();

  // v0.21 Round 22 (P1-22 修复): PIPL §14 同意记录字段
  // 合规审计要求"用户授权时刻 + 协议版本"
  // 之前 setup 步骤 0 勾选只活在内存,无法证明用户当时同意了哪一版

  /// 用户协议版本号（e.g. "v0.21-2026-07-20"）
  TextColumn get userAgreementVersion => text().nullable()();

  /// 隐私政策版本号
  TextColumn get privacyPolicyVersion => text().nullable()();

  /// 敏感数据处理同意时刻（点击"同意"时记录）
  DateTimeColumn get sensitiveDataConsentAt => dateTime().nullable()();

  /// 撤回同意时刻（用户撤回时记录,null = 未撤回）
  DateTimeColumn get consentRevokedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
