// v1.1.0+171 R125 (R110 feature-first 阶段 1) — 焦虑急躁水平快速评估表
// (样板: 1 子表 5 file 端到端迁移)
//
// 拆解动机 (R110 阶段 1):
// - 当前 6 子表散在 lib/core/data/database/tables/daily_tracking/ + 6 repo
//   散在 lib/core/data/repositories/daily_tracking/, daily_tracking 实际是 1 个
//   feature 包, 物理上是 6 个分散
// - R110 阶段 1 样板: 选 anxiety_agitation 1 子表 (最纯, 0 跨子表依赖) 做
//   端到端迁移验证
// - R110 阶段 1 范围: 1 子表 5 file 端到端 (table + mapper + repo_impl +
//   entity + abstract), 不动其他 5 子表, 不动 app_database
// - 旧路径 lib/core/data/database/tables/daily_tracking/anxiety_agitation_entries.dart
//   加 deprecation 注释指向新路径, 不删 (R110 阶段 2+ 才会删)
//
// 跟 R120 notification_service 7 facade 模式一致: 新路径先行, 旧路径
// deprecation 过渡, 阶段 2 批量删旧路径。
//
// 4 层架构纯度: drift table 必须在同 database 跟其他 table 一起, 现阶段留
// 共享 (R110 阶段 3 pub workspace 拆时会跨 package 共享 app_database, 届时
// 跨包共享 type + drift 编译限制挑战), 本批不动 app_database。

import 'package:drift/drift.dart';

/// 焦虑急躁水平快速评估表 (R110 阶段 1 样板迁移)
@DataClassName('AnxietyAgitationEntry')
class AnxietyAgitationEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime()();
  IntColumn get anxietyScore => integer()();
  IntColumn get agitationScore => integer()();
  TextColumn get note => text().nullable()();
}
