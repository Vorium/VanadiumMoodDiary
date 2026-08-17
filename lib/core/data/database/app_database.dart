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
import 'package:chroniccare/core/data/database/daos/worry_dao.dart';
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
import 'package:chroniccare/core/data/database/tables/worry/worry_threads.dart';
import 'package:chroniccare/core/data/services/encryption_service.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';

part 'app_database.g.dart';
// R119 P1-1 (1.1.0 round 12j god class split): onUpgrade body + helpers +
// schemaVersion history extracted to this part file. Same library scope,
// so generated `moodEntries`/`ventEntries`/etc. top-level references remain
// visible without import/export plumbing.
// R121 P1-3 (1.1.0 round 12k emil dimension): onUpgrade body 480L 拆 4 sub-part
// (v1-v5 / v6-v12 / v13-v18 / v19-v24), 主 orchestrator 4 行编排。
part 'app_database_migrations.dart';
part 'app_database_migrations_v1_v5.dart';
part 'app_database_migrations_v6_v12.dart';
part 'app_database_migrations_v13_v18.dart';
part 'app_database_migrations_v19_v24.dart';

/// Chronic care database
///
/// 1.1.0 round 4b (emotion-first refactor): Contacts 表整摘 (外联通信业务
/// 删除定版, 用户决策 D1 不可逆) — 老用户走 migration from < 23
/// `deleteTable('contacts')`, 新装 createAll 不再建.
///
/// 1.1.0 round 12j (R119 P1-1 god class split): 24-version migration timeline
/// + 2 column-existence helpers extracted to `app_database_migrations.dart`
/// (part of this library). Main file now owns only: class skeleton, schema
/// version constant, migration getter (1-line delegation), DAO facade (15
/// late finals), and this doc comment.
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
    // v1.1.0 round 9 (F1 烦恼闭环): worry_threads 表
    WorryThreads,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  /// Test constructor: takes in-memory DB (skips path_provider / sqlcipher)
  @visibleForTesting
  AppDatabase.forTesting(super.executor);

  // See `app_database_migrations.dart` for the 24-version history comment.
  // Add new versions there alongside their `if (from < N)` migration step.
  @override
  int get schemaVersion => 24;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) =>
            _runAppDatabaseMigrations(this, m, from, to),
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

  // v1.1.0 round 9 (F1 烦恼闭环): WorryDao
  late final worryDao = WorryDao(this);

  // v0.27 round 65 (spen P1-11): remove 32-line facade delegation (line 264-316), caller
  // fully migrated to _db.xxxDao.xxx() / db.xxxDao.xxx() (94 places).
  //
  // v0.32 架构批 2 (AR-19): saveSetup / clearAllUserData (business
  // orchestration, not pure delegation) 迁到 SetupCommitter
  // (lib/core/data/services/setup_committer.dart)。AppDatabase 只剩
  // DAO facade + schema/migration, transaction 语义原样保留。
  //
  // 1.1.0 round 12j (R119 P1-1): schema/migration code moved to
  // `app_database_migrations.dart` (part of). This class shell is now
  // ~140L: imports + @DriftDatabase + 2 constructors + schemaVersion +
  // migration getter (1-line delegate) + 15 DAO facade + closing notes.
}
