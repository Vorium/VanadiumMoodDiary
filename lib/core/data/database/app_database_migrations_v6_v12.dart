// v1.1.0+161 R121 P1-3 (emil 维度): app_database_migrations 480L 拆 4 sub-part
// 之 v6-v12 sub-part (~140L, 7 步迁移)。
//
// v6-v12 范围: 7 步迁移, 含 v8→v9 vent text field-level encryption (P0-1 fix,
// 50L backfill logic) + v9→v10 user consent + v11→v12 audio recording
//
// 跨 sub-part 调用 `_columnExists` / `_addColumnIfMissing` (顶层 helper, 跟
// v1-v5 一样), 同 library scope OK。

part of 'app_database.dart';

/// R121 P1-3: 1.1.0 round 12k R119 拆出。onUpgrade body v6 → v12 子步骤
///
/// 包含:
/// - v6→v7: mood_entries add energy / sleep / anxiety (3 列)
/// - v7→v8: 4 query indexes (check_in / mood / vent / medication)
/// - v8→v9: vent text field-level encryption (P0-1 fix, AES-256 contentTextEnc + backfill)
/// - v9→v10: user_profiles add 4 consent columns (PIPL §13)
/// - v11→v12: mood_entries add audio recording 3 columns (audioPath / transcript / durationMs)
Future<void> _runAppDatabaseMigrationsV6ToV12(
  AppDatabase db,
  Migrator m,
  int from,
  int to,
) async {
  // v6 to v7: mood_entries add 4-dimension 3 new columns (energy / sleep / anxiety)
  // old data 3 columns default null (single score mode), new data 4 dimensions filled
  // 1.1.0 round 8 (P3): addColumn → _addColumnIfMissing 守卫
  // (from<=3 老用户表已含当前 schema 全列, 幂等跳过)
  if (from <= 6) {
    await _addColumnIfMissing(db, m, db.moodEntries, db.moodEntries.energy);
    await _addColumnIfMissing(db, m, db.moodEntries, db.moodEntries.sleep);
    await _addColumnIfMissing(
      db,
      m,
      db.moodEntries,
      db.moodEntries.anxiety,
    );
  }
  // v7 to v8: add 4 query indexes, large table (1+ year users) avoid full table scan
  // - check_ins (timestamp, type) — covers streak / assessment / watchAll
  // - mood_entries (timestamp) — query mood by day/month
  // - vent_entries (timestamp DESC) — vent watchAll descending
  // - db.medications (isActive, startDate) — watchAll filter + refill sort
  if (from <= 7) {
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_checkin_ts_type ON check_ins(timestamp, type)',
    );
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_mood_ts ON mood_entries(timestamp)',
    );
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_vent_ts ON vent_entries(timestamp DESC)',
    );
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_med_active_start ON medications(is_active, start_date)',
    );
  }
  // v8 to v9: vent text field-level encryption (P0-1 fix)
  // - add contentTextEnc (BLOB nullable) column
  // - read old contentText, encrypt, write back to new column
  // - keep old contentText column (no longer used in code), fully clean in v10+
  // - v0.30 R92: db.ventEntries.contentText field already removed, old v8 upgrade (from <= 8) uses raw query
  //   directly read contentText column (DB actually has it, just schema doesn't expose)
  // 1.1.0 round 8 (P3): contentTextEnc addColumn → 守卫 + backfill 用
  // content_text 列存在性包住 (from<=5 老用户新表无明文 content_text,
  // 跳过 addColumn + backfill)
  if (from <= 8) {
    await _addColumnIfMissing(
      db,
      m,
      db.ventEntries,
      db.ventEntries.contentTextEnc,
    );
    // one-time encrypt all historical vent text
    // after R92 schema has no contentText, switch to raw query (drift typed select can't get it)
    // raw query via SQL, directly read old contentText column
    if (await _columnExists(db, 'vent_entries', 'content_text')) {
      final oldRows = await db.customSelect(
        'SELECT id, contentText FROM vent_entries WHERE contentText IS NOT NULL',
        readsFrom: {db.ventEntries},
      ).get();
      final enc = EncryptionService();
      for (final row in oldRows) {
        try {
          final oldText = row.read<String?>('contentText');
          if (oldText == null || oldText.isEmpty) continue;
          final encrypted = await enc
              .encrypt(Uint8List.fromList(utf8.encode(oldText)));
          await db.customStatement(
            'UPDATE vent_entries SET content_text_enc = ? WHERE id = ?',
            [encrypted, row.read<int>('id')],
          );
        } catch (e, st) {
          // v0.27 round 63 (P1-7 fix): use swallowError sink
          // (R39 P1-10 pattern), replace the only 1 `catch (e) {}` in entire lib
          // completely silent. dev mode devtools / `flutter logs` visible.
          // single entry encrypt failure doesn't block entire upgrade, that row's contentTextEnc stays null,
          // when user opens that vent entry, VentMapper.toEntity will fallback to show empty content.
          final id = row.read<int>('id');
          swallowError(
            where: 'app_database.v8v9_vent_encrypt_fail',
            error: e,
            stack: st,
            note:
                'ventId=$id contentText encrypt failed, contentTextEnc stays null',
          );
        }
      }
    }
  }
  // v9 to v10: UserProfile add 4 consent columns (P1-22 fix)
  // - all 4 columns nullable, old data auto null
  // - after setup step 0 completes, writes version + timestamp
  if (from <= 9) {
    await m.addColumn(db.userProfiles, db.userProfiles.userAgreementVersion);
    await m.addColumn(db.userProfiles, db.userProfiles.privacyPolicyVersion);
    await m.addColumn(
      db.userProfiles,
      db.userProfiles.sensitiveDataConsentAt,
    );
    await m.addColumn(db.userProfiles, db.userProfiles.consentRevokedAt);
  }
  // v10 to v11: userName change to nullable (P1-24 fix)
  // - user_profiles.userName + report_histories.userName
  // - old data "" still writes back "" (empty string), but allow null
  // - in practice: drift's alter table doesn't support column property change, SQLite has no ALTER COLUMN
  //   so this change **only takes effect in createAll** (new install users auto get new schema)
  //   upgrading users keep old schema; code reads userName defensively
  //   (null/"" both tolerated) so old data "" and new data null are compatible
  // v11 to v12: mood_entries add voice recording 3 columns (v0.23 round 31)
  // - audioPath / audioTranscript / audioDurationMs all nullable
  // - old data auto null, text-only mode behavior completely unchanged
  // - new data: audioPath required (recording always has file), transcript/durationMs optional
  if (from <= 11) {
    await _addColumnIfMissing(
      db,
      m,
      db.moodEntries,
      db.moodEntries.audioPath,
    );
    await _addColumnIfMissing(
      db,
      m,
      db.moodEntries,
      db.moodEntries.audioTranscript,
    );
    await _addColumnIfMissing(
      db,
      m,
      db.moodEntries,
      db.moodEntries.audioDurationMs,
    );
  }
  // v12 to v13: check_ins add medicationId index (P2 optimization)
  // - medication check-in query filter by medicationId, no index does full table scan
  if (from <= 12) {
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_checkin_med_id ON check_ins(medication_id)',
    );
  }
}
