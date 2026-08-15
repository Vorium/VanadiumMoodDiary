import 'package:chroniccare/core/data/database/connection/connection.dart'
    if (dart.library.js_interop) 'connection/web.dart'
    if (dart.library.io) 'connection/native.dart';

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import 'package:chroniccare/core/data/database/daos/assessment_dao.dart';
import 'package:chroniccare/core/data/database/daos/check_in_dao.dart';
import 'package:chroniccare/core/data/database/daos/medication_dao.dart';
import 'package:chroniccare/core/data/database/daos/mood_dao.dart';
import 'package:chroniccare/core/data/database/daos/report_dao.dart';
import 'package:chroniccare/core/data/database/daos/user_profile_dao.dart';
import 'package:chroniccare/core/data/database/daos/vent_dao.dart';
import 'package:chroniccare/core/data/database/daos/anxiety_agitation_dao.dart';
import 'package:chroniccare/core/data/database/daos/sleep_dao.dart';
import 'package:chroniccare/core/data/database/daos/social_rhythm_dao.dart';
import 'package:chroniccare/core/data/database/daos/stress_event_dao.dart';
import 'package:chroniccare/core/data/database/daos/treatment_dao.dart';
import 'package:chroniccare/core/data/database/daos/weight_dao.dart';
import 'package:chroniccare/core/data/database/tables/check_in/check_ins.dart';
import 'package:chroniccare/core/data/database/tables/daily_tracking/anxiety_agitation_entries.dart';
import 'package:chroniccare/core/data/database/tables/daily_tracking/sleep_entries.dart';
import 'package:chroniccare/core/data/database/tables/daily_tracking/social_rhythm_entries.dart';
import 'package:chroniccare/core/data/database/tables/daily_tracking/stress_events.dart';
import 'package:chroniccare/core/data/database/tables/daily_tracking/treatment_entries.dart';
import 'package:chroniccare/core/data/database/tables/daily_tracking/weight_entries.dart';
import 'package:chroniccare/core/data/database/tables/medication/medications.dart';
import 'package:chroniccare/core/data/database/tables/mood/mood_entries.dart';
import 'package:chroniccare/core/data/database/tables/report/report_histories.dart';
import 'package:chroniccare/core/data/database/tables/user_profile/user_profiles.dart';
import 'package:chroniccare/core/data/database/tables/vent/vent_entries.dart';
import 'package:chroniccare/core/data/services/encryption_service.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';

part 'app_database.g.dart';

/// Chronic care database
///
/// 1.1.0 round 4b (emotion-first refactor): Contacts 表整摘 (外联通信业务
/// 删除定版, 用户决策 D1 不可逆) — 老用户走 migration from < 23
/// `deleteTable('contacts')`, 新装 createAll 不再建。
@DriftDatabase(
  tables: [
    CheckIns,
    Medications,
    UserProfiles,
    ReportHistories,
    MoodEntries,
    VentEntries,
    // v0.30 round 91 (sub-spec 7 daily tracking): 6 new tables
    SleepEntries,
    SocialRhythmEntries,
    StressEvents,
    TreatmentEntries,
    WeightEntries,
    AnxietyAgitationEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  /// Test constructor: takes in-memory DB (skips path_provider / sqlcipher)
  @visibleForTesting
  AppDatabase.forTesting(super.executor);

  // v0.18 round 18 (P1-15): schemaVersion 6 to 7
  // - mood_entries: add energy / sleep / anxiety 3 nullable columns
  // - old data auto has null 3 fields (single score mode)
  // - new data fills all 4 dimensions
  // v0.18 round 18 (P2-P0-8): schemaVersion 7 to 8
  // - 4 query indexes (check_ins / mood_entries / vent_entries / medications)
  // v0.21 round 22 (P0-1 fix): schemaVersion 8 to 9
  // - vent_entries: add contentTextEnc (BLOB, AES-256 encrypted) column
  // - one-time encrypt all old contentText (TEXT, plaintext) back to new column
  // - keep old contentText column (no longer used in code), DROP entirely in v10+
  // v0.21 round 22 (P1-22 fix): schemaVersion 9 to 10
  // - user_profiles: add 4 consent columns
  // v0.21 round 23 (P1-24 fix): schemaVersion 10 to 11
  // - user_profiles.userName: change to nullable
  // - report_histories.userName: change to nullable
  // - old data "" still writes back "" (empty string), but allow null
  // - in practice: drift's alter table doesn't support column property change, SQLite has no ALTER COLUMN
  //   so this change **only takes effect in createAll** (new install users auto get new schema)
  //   upgrading user schema unchanged, code layer check if (userName?.isNotEmpty ?? false)
  //   compatible with old data "" and new data null
  // v0.23 round 31 (P0 new feature): schemaVersion 11 to 12
  // - mood_entries: add audioPath / audioTranscript / audioDurationMs 3 nullable columns
  // - old data auto null (text-only mode behavior unchanged)
  // - audioPath references encrypted .m4a.enc file in independent mood_audio/ directory
  //
  // v0.23 round 43: schemaVersion 12 to 13
  // - check_ins: add medicationId index (optimize medication check-in query)
  //
  // v0.23 round 44: schemaVersion 13 to 14
  // - contacts: add (is_active, sort_order) composite index
  // - report_histories: add generated_at index
  //
  // v0.27 round 63 (P0-2 fix): schemaVersion 14 to 15
  // - contacts: add 4 consent columns (PIPL §13 audit trail requirement)
  // - all 4 columns nullable, old data auto null
  // - old data (schemaVersion <= 14) contact 'consent history' only in piiSafeLog
  //   (R62 working tree state), DB persistence is new this round. Consider for v1.0 legal review
  //   whether to give old users 're-consent' flow (not in this round, defer to R64+)
  //
  // v0.29 round 84: schemaVersion 15 to 17 - mood_entries +8 CBT columns
  //   (situation / automaticThought / evidenceFor / evidenceAgainst /
  //    alternativeThought / reratedScore / coreBelief / behaviorResponse)
  //   note: code diff is actually 15 to 17 (no 16 intermediate); spec mistakenly wrote 'current prod is 16'
  //   if v16 schema is actually released later, `if (from <= 15)` guard needs intermediate 16 to 17 step
  // - all 8 columns nullable, old data auto null (3-column mode rendering)
  // - after upgrade, mood entry in DayDetailCard takes '3-column + free note' branch
  //
  // v0.30 round 92: schemaVersion 18 to 19 - vent_entries DROP contentText (PIPL §28)
  //   - R21 v0.21 (schemaVersion 8 to 9) added contentTextEnc (BLOB encrypted) while keeping contentText (TEXT plaintext)
  //   - v8 to v9 migration one-time encrypt contentText back to contentTextEnc
  //   - but old contentText column kept, R22-R91 (10+ round, 5+ year) users still have after upgrade
  //     plaintext + encrypted duplicate in DB, device root / backup steal → PIPL §28 field-level plaintext leak
  //   - R92 DROP contentText column, one-time cleanup
  //   - guard `if (from < 19)` matches v15 to v17 pattern
  //
  // v0.30 R101: schemaVersion 19 to 20 - medications +3 columns (form/colorIndex/notes)
  //   - form: 药物剂型 (tablet/capsule/liquid/patch/injection/other), 默认 'tablet'
  //   - colorIndex: 药丸颜色索引 (0-5), 默认 0
  //   - notes: 备注, nullable
  //   - 3 列全部有默认值, 老数据自动兼容
  //
  // v0.30 R101: schemaVersion 20 to 21 - mood_entries +1 column (influenceFactorsJson)
  //   - influenceFactorsJson: 影响因素 JSON 数组, 默认 '[]'
  //   - 老数据自动兼容 (空列表)
  //
  // v0.30 R105: schemaVersion 21 to 22 - mood_entries +1 column (recordingMode)
  //   - recordingMode: 记录模式 ('momentary' / 'daily'), nullable
  //   - 老数据自动兼容 (null)
  //
  // v1.1.0 round 2: schemaVersion 22 to 23 (v22 + 2 列)
  //   - vent_entries +1 column (tagsJson): 标签 JSON 数组, 默认 '[]'
  //   - mood_entries +1 column (statusPhrase): 状态短语, nullable
  //   - 老数据自动兼容 (tagsJson 空列表 / statusPhrase null)
  @override
  int get schemaVersion => 23;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // v1 to v2: contact email change to phone (历史: contacts 已随
          // v1.1.0 round 4b 整摘, from < 23 步统一 deleteTable),
          // medication add dosage / dosageUnit / remove frequencyPerDay
          if (from == 1) {
            // Medications: add dosage / dosageUnit
            await m.addColumn(medications, medications.dosage);
            await m.addColumn(medications, medications.dosageUnit);
          }
          // v2 to v3: new report_histories table (medication report history)
          if (from <= 2) {
            await m.createTable(reportHistories);
          }
          // v3 to v4: new mood_entries table (mood diary)
          if (from <= 3) {
            await m.createTable(moodEntries);
          }
          // v4 to v5: medications add refill fields refillAt + refillReminderDays
          // old data no migration needed: null = never set refill reminder
          if (from <= 4) {
            await m.addColumn(medications, medications.refillAt);
            await m.addColumn(medications, medications.refillReminderDays);
          }
          // v5 to v6: new vent_entries table (vent)
          if (from <= 5) {
            await m.createTable(ventEntries);
          }
          // v6 to v7: mood_entries add 4-dimension 3 new columns (energy / sleep / anxiety)
          // old data 3 columns default null (single score mode), new data 4 dimensions filled
          if (from <= 6) {
            await m.addColumn(moodEntries, moodEntries.energy);
            await m.addColumn(moodEntries, moodEntries.sleep);
            await m.addColumn(moodEntries, moodEntries.anxiety);
          }
          // v7 to v8: add 4 query indexes, large table (1+ year users) avoid full table scan
          // - check_ins (timestamp, type) — covers streak / assessment / watchAll
          // - mood_entries (timestamp) — query mood by day/month
          // - vent_entries (timestamp DESC) — vent watchAll descending
          // - medications (isActive, startDate) — watchAll filter + refill sort
          if (from <= 7) {
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_checkin_ts_type ON check_ins(timestamp, type)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_mood_ts ON mood_entries(timestamp)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_vent_ts ON vent_entries(timestamp DESC)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_med_active_start ON medications(is_active, start_date)',
            );
          }
          // v8 to v9: vent text field-level encryption (P0-1 fix)
          // - add contentTextEnc (BLOB nullable) column
          // - read old contentText, encrypt, write back to new column
          // - keep old contentText column (no longer used in code), fully clean in v10+
          // - v0.30 R92: ventEntries.contentText field already removed, old v8 upgrade (from <= 8) uses raw query
          //   directly read contentText column (DB actually has it, just schema doesn't expose)
          if (from <= 8) {
            await m.addColumn(ventEntries, ventEntries.contentTextEnc);
            // one-time encrypt all historical vent text
            // after R92 schema has no contentText, switch to raw query (drift typed select can't get it)
            // raw query via SQL, directly read old contentText column
            final oldRows = await customSelect(
              'SELECT id, contentText FROM vent_entries WHERE contentText IS NOT NULL',
              readsFrom: {ventEntries},
            ).get();
            final enc = EncryptionService();
            for (final row in oldRows) {
              try {
                final oldText = row.read<String?>('contentText');
                if (oldText == null || oldText.isEmpty) continue;
                final encrypted =
                    await enc.encrypt(Uint8List.fromList(utf8.encode(oldText)));
                await customStatement(
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
          // v9 to v10: UserProfile add 4 consent columns (P1-22 fix)
          // - all 4 columns nullable, old data auto null
          // - after setup step 0 completes, writes version + timestamp
          if (from <= 9) {
            await m.addColumn(userProfiles, userProfiles.userAgreementVersion);
            await m.addColumn(userProfiles, userProfiles.privacyPolicyVersion);
            await m.addColumn(
              userProfiles,
              userProfiles.sensitiveDataConsentAt,
            );
            await m.addColumn(userProfiles, userProfiles.consentRevokedAt);
          }
          // v10 to v11: userName change to nullable (P1-24 fix)
          // - user_profiles.userName + report_histories.userName
          // - old data "" still writes back "" (empty string), but allow null
          // - in practice: drift's alter table doesn't support column property change, SQLite has no ALTER COLUMN
          //   so this change **only takes effect in createAll** (new install users auto get new schema)
          //   upgrading user schema unchanged, **unified via `domain/logic/user_name_helper.dart`
          //   `safeUserName()` to be compatible with old data "" and new data null**
          //   (v0.22 round 31 sp-en P0-3 extracted helper to centralize 5+ scattered checks)
          // v11 to v12: mood_entries add voice recording 3 columns (v0.23 round 31)
          // - audioPath / audioTranscript / audioDurationMs all nullable
          // - old data auto null, text-only mode behavior completely unchanged
          // - new data: audioPath required (recording always has file), transcript/durationMs optional
          if (from <= 11) {
            await m.addColumn(moodEntries, moodEntries.audioPath);
            await m.addColumn(moodEntries, moodEntries.audioTranscript);
            await m.addColumn(moodEntries, moodEntries.audioDurationMs);
          }
          // v12 to v13: check_ins add medicationId index (P2 optimization)
          // - medication check-in query filter by medicationId, no index does full table scan
          if (from <= 12) {
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_checkin_med_id ON check_ins(medication_id)',
            );
          }
          // v13 to v14: report_histories add index (P2 optimization)
          // 1.1.0 round 4b: 原 contacts index 行随 contacts 表整摘删除
          // (表本身 from < 23 步 deleteTable, 无需再建索引)
          if (from <= 13) {
            await customStatement(
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
            await m.addColumn(moodEntries, moodEntries.situation);
            await m.addColumn(moodEntries, moodEntries.automaticThought);
            await m.addColumn(moodEntries, moodEntries.evidenceFor);
            await m.addColumn(moodEntries, moodEntries.evidenceAgainst);
            await m.addColumn(moodEntries, moodEntries.alternativeThought);
            await m.addColumn(moodEntries, moodEntries.reratedScore);
            await m.addColumn(moodEntries, moodEntries.coreBelief);
            await m.addColumn(moodEntries, moodEntries.behaviorResponse);
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
            await m.addColumn(moodEntries, moodEntries.period);
            // 2. create 6 new tables
            await m.createTable(sleepEntries);
            await m.createTable(socialRhythmEntries);
            await m.createTable(stressEvents);
            await m.createTable(treatmentEntries);
            await m.createTable(weightEntries);
            await m.createTable(anxietyAgitationEntries);
          }
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
            await customStatement(
              'ALTER TABLE vent_entries DROP COLUMN content_text',
            );
          }
          // v19 to v20: medications +3 columns (form/colorIndex/notes)
          // - form: 药物剂型, 默认 'tablet'
          // - colorIndex: 药丸颜色索引, 默认 0
          // - notes: 备注, nullable
          // - 3 列全部有默认值, 老数据自动兼容
          if (from < 20) {
            await m.addColumn(medications, medications.form);
            await m.addColumn(medications, medications.colorIndex);
            await m.addColumn(medications, medications.notes);
          }
          // v20 to v21: mood_entries +1 column (influenceFactorsJson)
          // - 影响因素 JSON 数组, 默认 '[]'
          // - 老数据自动兼容 (空列表)
          if (from < 21) {
            await m.addColumn(moodEntries, moodEntries.influenceFactorsJson);
          }
          // v21 to v22: mood_entries +1 column (recordingMode)
          // - 记录模式 ('momentary' / 'daily'), nullable
          // - 老数据自动兼容 (null)
          if (from < 22) {
            await m.addColumn(moodEntries, moodEntries.recordingMode);
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
            await m.addColumn(ventEntries, ventEntries.tagsJson);
            await m.addColumn(moodEntries, moodEntries.statusPhrase);
          }
        },
        beforeOpen: (details) async {
          // enable foreign keys
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  // ============= CheckIns (v0.25 R53a: delegated to CheckInDao) =============

  // v0.25 round 53a (spen P1 #12 god class split): extract 7 DAO + app_database
  // changed to 1-line delegation. caller temporarily unchanged (preserve facade compat), gradual migration in R53b.
  late final checkInDao = CheckInDao(this);
  // v0.30 round 90 (sub-spec 6 scale center): AssessmentDao cross 10 scale aggregation,
  // depends on CheckInDao.watchAssessments (expand 10 type IN) + CheckIns table.
  late final assessmentDao = AssessmentDao(this, checkInDao);
  late final medicationDao = MedicationDao(this);
  late final userProfileDao = UserProfileDao(this);
  late final reportDao = ReportDao(this);
  late final moodDao = MoodDao(this);
  late final ventDao = VentDao(this);

  // v0.30 round 91 (sub-spec 7 daily tracking): 6 new DAO (manual wrapper pattern)
  late final sleepDao = SleepDao(this);
  late final socialRhythmDao = SocialRhythmDao(this);
  late final stressEventDao = StressEventDao(this);
  late final treatmentDao = TreatmentDao(this);
  late final weightDao = WeightDao(this);
  late final anxietyAgitationDao = AnxietyAgitationDao(this);

  // v0.27 round 65 (spen P1-11): remove 32-line facade delegation (line 264-316), caller
  // fully migrated to _db.xxxDao.xxx() / db.xxxDao.xxx() (94 places).
  //
  // v0.32 架构批 2 (AR-19): saveSetup / clearAllUserData (business
  // orchestration, not pure delegation) 迁到 SetupCommitter
  // (lib/core/data/services/setup_committer.dart)。AppDatabase 只剩
  // DAO facade + schema/migration, transaction 语义原样保留。
}
