// v1.1.0+161 R121 P1-3 (emil 维度): app_database_migrations 480L 拆 4 sub-part
// 之 v1-v5 sub-part (25L)。
//
// 拆解动机 (emil 优先级 1, R120 综合审视):
// - app_database_migrations.dart 480L 仍接近 god class 阈值 (R108 §六 候选 400-500L 区间)
// - 24 个 if guard 集中一处, 未来 schemaVersion bump 改 1 个版本仍要改主文件
// - 拆 4 sub-part 后, 未来加 v25 step = 1 个新 sub-part (v19-v24 → v19-v25), 主 orchestrator
//   1 行新增, 0 改旧 sub-part
//
// 拆解模式 (R119 R121 跟):
// - 4 sub-part 都 `part of 'app_database.dart'`, 共享 library scope
// - drift 生成的 `db.moodEntries` / `db.ventEntries` / `db.medications` 顶层引用无需 import
// - `_columnExists` / `_addColumnIfMissing` 跨 sub-part 调用, 同 library scope OK
// - 顶层 `_runAppDatabaseMigrations` 4 行编排 4 sub-part
//
// v1-v5 范围: 5 步迁移, 含 1 个 if (from == 1) + 4 个 if (from <= N)

part of 'app_database.dart';

/// R121 P1-3: 1.1.0 round 12k R119 拆出。onUpgrade body v1 → v5 子步骤
///
/// 包含:
/// - v1→v2: medication add dosage / dosageUnit
/// - v2→v3: new report_histories table
/// - v3→v4: new mood_entries table
/// - v4→v5: medication add refillAt / refillReminderDays
/// - v5→v6: new vent_entries table
Future<void> _runAppDatabaseMigrationsV1ToV5(
  AppDatabase db,
  Migrator m,
  int from,
  int to,
) async {
  // v1 to v2: contact email change to phone (历史: contacts 已随
  // v1.1.0 round 4b 整摘, from < 23 步统一 deleteTable),
  // medication add dosage / dosageUnit / remove frequencyPerDay
  if (from == 1) {
    // Medications: add dosage / dosageUnit
    await m.addColumn(db.medications, db.medications.dosage);
    await m.addColumn(db.medications, db.medications.dosageUnit);
  }
  // v2 to v3: new report_histories table (medication report history)
  if (from <= 2) {
    await m.createTable(db.reportHistories);
  }
  // v3 to v4: new mood_entries table (mood diary)
  if (from <= 3) {
    await m.createTable(db.moodEntries);
  }
  // v4 to v5: db.medications add refill fields refillAt + refillReminderDays
  // old data no migration needed: null = never set refill reminder
  if (from <= 4) {
    await m.addColumn(db.medications, db.medications.refillAt);
    await m.addColumn(db.medications, db.medications.refillReminderDays);
  }
  // v5 to v6: new vent_entries table (vent)
  if (from <= 5) {
    await m.createTable(db.ventEntries);
  }
}
