// v1.1.0+161 R121 P1-3 (emil 维度): app_database_migrations 480L 拆 4 sub-part
// 之 v13-v18 sub-part (~85L, 3 步迁移)。
//
// v13-v18 范围: 3 步迁移, 含 v15→v17 mood_entries +8 CBT columns (50L 列操作)
// + v17→v18 daily tracking 6 new tables。

part of 'app_database.dart';

/// R121 P1-3: 1.1.0 round 12k R119 拆出。onUpgrade body v13 → v18 子步骤
///
/// 包含:
/// - v13→v14: report_histories add generated_at index
/// - v14→v15: (1.1.0 round 4b 跳过 — contacts 表整摘, 跟 4b 一致跳过 consent 列)
/// - v15→v17: mood_entries +8 CBT columns (situation / automaticThought / etc)
/// - v17→v18: mood_entries +period + 6 daily tracking tables
Future<void> _runAppDatabaseMigrationsV13ToV18(
  AppDatabase db,
  Migrator m,
  int from,
  int to,
) async {
  // v13 to v14: report_histories add index (P2 optimization)
  // 1.1.0 round 4b: 原 contacts index 行随 contacts 表整摘删除
  // (表本身 from < 23 步 deleteTable, 无需再建索引)
  if (from <= 13) {
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_report_gen_at ON report_histories(generated_at)',
    );
  }
  // v14 to v15 (1.1.0 round 4b): 原 contacts 4 consent 列迁移块随
  // contacts 表整摘删除 — 老用户 contacts 数据在 from < 23 步统一
  // deleteTable, 无需再管 consent 列。
  // v15 to v17: mood_entries +8 CBT columns (v0.29 round 84)
  // note: code diff is actually 15 to 17 (no intermediate v16), spec mistakenly wrote '16 to 17'
  // (e14c6b3 fix spec 12 to 16 didn't correspond to any code schema bump).
  // guard `if (from <= 16)` covers current v15 users + future actual v16 schema
  // safety net (avoid missing migration). If v16 intermediate schema is actually introduced, need to insert
  // `if (from == 16) { /* v16 to v17 step */ }` placeholder, see above doc comment.
  // - all 8 columns nullable, old data auto null (3-column mode rendering, behavior unchanged)
  // - after upgrade, DayDetailCard takes '3-column + free note' branch, 5/7 column users use only when actively upgrading
  if (from <= 16) {
    await _addColumnIfMissing(
      db,
      m,
      db.moodEntries,
      db.moodEntries.situation,
    );
    await _addColumnIfMissing(
      db,
      m,
      db.moodEntries,
      db.moodEntries.automaticThought,
    );
    await _addColumnIfMissing(
      db,
      m,
      db.moodEntries,
      db.moodEntries.evidenceFor,
    );
    await _addColumnIfMissing(
      db,
      m,
      db.moodEntries,
      db.moodEntries.evidenceAgainst,
    );
    await _addColumnIfMissing(
      db,
      m,
      db.moodEntries,
      db.moodEntries.alternativeThought,
    );
    await _addColumnIfMissing(
      db,
      m,
      db.moodEntries,
      db.moodEntries.reratedScore,
    );
    await _addColumnIfMissing(
      db,
      m,
      db.moodEntries,
      db.moodEntries.coreBelief,
    );
    await _addColumnIfMissing(
      db,
      m,
      db.moodEntries,
      db.moodEntries.behaviorResponse,
    );
  }
  // v17 to v18: daily tracking 6 new tables + mood_entries add period column (v0.30 round 91)
  // - 1. mood_entries add period column (TextColumn, nullable, 'unspecified' default)
  // - 2. create 6 new tables: sleep_entries / social_rhythm_entries /
  //      stress_events / treatment_entries / weight_entries /
  //      anxiety_agitation_entries
  // - old user upgrade 0 data migration (new tables empty, new column nullable)
  // - guard `if (from < 18)` matches v15 to v17 pattern: compatible with future v18 upgrade
  if (from < 18) {
    // 1. period column added to mood_entries
    // (1.1.0 round 8 P3: 守卫 — from<=3 老用户表已含 period 列, 跳过)
    await _addColumnIfMissing(db, m, db.moodEntries, db.moodEntries.period);
    // 2. create 6 new tables
    await m.createTable(db.sleepEntries);
    await m.createTable(db.socialRhythmEntries);
    await m.createTable(db.stressEvents);
    await m.createTable(db.treatmentEntries);
    await m.createTable(db.weightEntries);
    await m.createTable(db.anxietyAgitationEntries);
  }
}
