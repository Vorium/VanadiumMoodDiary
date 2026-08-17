// v1.1.0+161 R121 P1-3 (emil 维度): app_database_migrations 480L 拆 4 sub-part
// 后, 本文件变成 60L 薄壳 orchestrator, 24-version onUpgrade body 拆到 4 个
// sub-part (v1-v5 / v6-v12 / v13-v18 / v19-v24)。
//
// 拆解动机 (emil 优先级 1, R120 综合审视):
// - 拆解前 480L 单文件接近 god class 阈值 (R108 §六 候选 400-500L 区间)
// - 24 个 if guard 集中一处, 未来 schemaVersion bump 改 1 个版本仍要改主文件
// - 拆 4 sub-part 后, 未来加 v25 step = 1 个新 sub-part, 主 orchestrator
//   1 行新增, 0 改旧 sub-part
//
// 拆解模式 (跟 R119 R121 一脉相承):
// - 4 sub-part 都 `part of 'app_database.dart'`, 共享 library scope
// - drift 生成的 `db.moodEntries` / `db.ventEntries` / `db.medications` 顶层引用无需 import
// - `_columnExists` / `_addColumnIfMissing` 跨 sub-part 调用, 同 library scope OK
// - 顶层 `_runAppDatabaseMigrations` 4 行编排 4 sub-part
//
// 4 sub-part:
// - `app_database_migrations_v1_v5.dart` (5 步: dosage / report_histories / mood_entries / refill / vent_entries)
// - `app_database_migrations_v6_v12.dart` (7 步: 4 维 mood / 4 index / vent 加密 / consent / audio / checkin_med_id)
// - `app_database_migrations_v13_v18.dart` (3 步: report_gen_at index / +8 CBT 列 / +6 daily tracking 表)
// - `app_database_migrations_v19_v24.dart` (6 步: vent DROP contentText / +3 medication / +1 mood / emotion-first 重构 / worry 闭环)
part of 'app_database.dart';

/// 1.1.0 round 8 (P3 老库升级链修复): 链中 createTable 用当前 schema 建表,
/// 老版本起点用户的后续 addColumn 会撞已存在列 → 幂等守卫。
Future<bool> _columnExists(
  AppDatabase db,
  String table,
  String column,
) async {
  final rows = await db.customSelect('PRAGMA table_info($table)').get();
  return rows.any((r) => r.read<String>('name') == column);
}

/// 列不存在才 addColumn (P3 同款守卫), 老库升级链幂等。
Future<void> _addColumnIfMissing(
  AppDatabase db,
  Migrator m,
  TableInfo<Table, dynamic> table,
  GeneratedColumn column,
) async {
  if (!await _columnExists(db, table.actualTableName, column.name)) {
    await m.addColumn(table, column);
  }
}

/// R121 P1-3 薄壳 orchestrator: 24-version onUpgrade body 拆 4 sub-part
///
/// 4 行调用, 每行 1 个版本段 (v1-v5 / v6-v12 / v13-v18 / v19-v24)
/// 未来加 v25 step = 1 个新 sub-part, 此 orchestrator 1 行新增
Future<void> _runAppDatabaseMigrations(
  AppDatabase db,
  Migrator m,
  int from,
  int to,
) async {
  await _runAppDatabaseMigrationsV1ToV5(db, m, from, to);
  await _runAppDatabaseMigrationsV6ToV12(db, m, from, to);
  await _runAppDatabaseMigrationsV13ToV18(db, m, from, to);
  await _runAppDatabaseMigrationsV19ToV24(db, m, from, to);
}
