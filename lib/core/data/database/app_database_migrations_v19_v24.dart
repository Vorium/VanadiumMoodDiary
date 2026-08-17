// v1.1.0+161 R121 P1-3 (emil 维度): app_database_migrations 480L 拆 4 sub-part
// 之 v19-v24 sub-part (~75L, 6 步迁移)。
//
// v19-v24 范围: 6 步迁移, 含 v18→v19 vent_entries DROP contentText (PIPL §28 cleanup)
// + v19→v20 medications +form/colorIndex/notes + v22→v23 emotion-first 重构
// (contacts 整摘 + tagsJson + statusPhrase) + v23→v24 worry 闭环。

part of 'app_database.dart';

/// R121 P1-3: 1.1.0 round 12k R119 拆出。onUpgrade body v19 → v24 子步骤
///
/// 包含:
/// - v18→v19: vent_entries DROP content_text (PIPL §28 cleanup)
/// - v19→v20: medications +form / colorIndex / notes (R101)
/// - v20→v21: mood_entries +influenceFactorsJson (R101)
/// - v21→v22: mood_entries +recordingMode (R105)
/// - v22→v23: emotion-first 重构 (contacts 整摘 + tagsJson + statusPhrase)
/// - v23→v24: worry 闭环 (worry_threads 表 + worryThreadId 列)
Future<void> _runAppDatabaseMigrationsV19ToV24(
  AppDatabase db,
  Migrator m,
  int from,
  int to,
) async {
  // v18 to v19: vent_entries DROP contentText TEXT column (PIPL §28 cleanup)
  // - R21 v0.21 added contentTextEnc (BLOB encrypted) while keeping contentText (TEXT plaintext)
  // - v8 to v9 migration one-time encrypt contentText back to contentTextEnc,
  //   but contentText column still kept, R22-R91 5+ year users DB still has duplicate
  // - device root / backup steal → field-level plaintext leak violates PIPL §28
  // - R92 DROP column, one-time cleanup
  // - guard `if (from < 19)` matches v15 to v17 / v17 to v18 pattern
  // - drift 2.x TableMigration doesn't support explicit deletedColumns, use raw SQL
  //   ALTER TABLE drop column (SQLite supports ALTER TABLE DROP COLUMN since 3.35.0)
  if (from < 19) {
    // 1.1.0 round 8 (P3): DROP 用列存在性守卫包住 —
    // from<=5 老用户新表无 content_text, 直接 DROP 会崩
    if (await _columnExists(db, 'vent_entries', 'content_text')) {
      await db.customStatement(
        'ALTER TABLE vent_entries DROP COLUMN content_text',
      );
    }
  }
  // v19 to v20: db.medications +3 columns (form/colorIndex/notes)
  // - form: 药物剂型, 默认 'tablet'
  // - colorIndex: 药丸颜色索引, 默认 0
  // - notes: 备注, nullable
  // - 3 列全部有默认值, 老数据自动兼容
  if (from < 20) {
    await m.addColumn(db.medications, db.medications.form);
    await m.addColumn(db.medications, db.medications.colorIndex);
    await m.addColumn(db.medications, db.medications.notes);
  }
  // v20 to v21: mood_entries +1 column (influenceFactorsJson)
  // - 影响因素 JSON 数组, 默认 '[]'
  // - 老数据自动兼容 (空列表)
  if (from < 21) {
    await _addColumnIfMissing(
      db,
      m,
      db.moodEntries,
      db.moodEntries.influenceFactorsJson,
    );
  }
  // v21 to v22: mood_entries +1 column (recordingMode)
  // - 记录模式 ('momentary' / 'daily'), nullable
  // - 老数据自动兼容 (null)
  if (from < 22) {
    await _addColumnIfMissing(
      db,
      m,
      db.moodEntries,
      db.moodEntries.recordingMode,
    );
  }
  // v22 to v23: vent_entries +tagsJson, mood_entries +statusPhrase
  // (v1.1.0 情绪优先重构)
  // - tagsJson: 默认 '[]', 老数据自动空列表
  // - statusPhrase: nullable, 老数据自动 null
  // 1.1.0 round 4b: 彻底删除外联推送 — contacts 表整删
  // (用户决策 D1, 不可逆), deleteTable 必须在 addColumn 之前
  // (表删除不依赖新列)
  if (from < 23) {
    await m.deleteTable('contacts');
    await _addColumnIfMissing(
      db,
      m,
      db.ventEntries,
      db.ventEntries.tagsJson,
    );
    await _addColumnIfMissing(
      db,
      m,
      db.moodEntries,
      db.moodEntries.statusPhrase,
    );
  }
  // v23 to v24 (v1.1.0 round 9 F1 烦恼闭环):
  // - 新表 worry_threads (烦恼主题)
  // - mood_entries +worryThreadId (关联烦恼, nullable, 老数据 null)
  if (from < 24) {
    await m.createTable(db.worryThreads);
    await _addColumnIfMissing(
      db,
      m,
      db.moodEntries,
      db.moodEntries.worryThreadId,
    );
  }
}
