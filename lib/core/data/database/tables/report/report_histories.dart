import 'package:drift/drift.dart';

/// 报告历史表
///
/// 用户每次生成用药报告就存一条，方便"上次给医生看了啥"
/// 字段尽量精简：避免占空间、不存结构化数据（重新生成更准）
@DataClassName('ReportHistory')
class ReportHistories extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 报告窗口天数（7/14/30）
  IntColumn get windowDays => integer()();

  /// 报告生成时间
  DateTimeColumn get generatedAt => dateTime()();

  /// 当时的用户名（避免日后改名混淆）
  /// v0.21 Round 23 (P1-24): 改 nullable,允许匿名报告
  TextColumn get userName => text().nullable()();

  /// 报告全文（纯文本）
  TextColumn get reportText => text()();
}
