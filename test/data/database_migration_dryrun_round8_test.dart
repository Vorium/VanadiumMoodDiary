// v0.32 round 8 (R111 SP-111-05/08 fix): migration 真实 dry-run + step 自动比对
//
// 背景:
// - SP-111-05 (P1, ≤1d): round37 只验 schemaVersion==22 + onUpgrade 可调用 +
//   "21 steps" hand-count, 注释自认 "完整 SQLite dry-run 从 v1 模拟升级太重,
//   留给未来补"。R109 round 6 18→22 的 3 个新迁移 step (19→20 medications +3 /
//   20→21 mood influenceFactorsJson / 21→22 mood recordingMode) 0 dry-run 覆盖。
// - SP-111-08 (P2, ≤2h): "21 steps" 断言是 hand-count, 未跟 app_database.dart
//   迁移 block 自动比对 — schemaVersion 再 +1 忘加 block 时, 老测试照样绿。
//
// 修法:
// 1. 真实 dry-run: 建 v23 schema → 手动 DROP 7 个新列 + user_version 降到 19
//    (模拟老用户 v19 库) → 重开 AppDatabase → onUpgrade 走 19→20→21→22→23
//    4 个真实 step → 断言列回归 + 老数据保留 + 默认值正确。
// 2. 自动比对: 解析 app_database.dart 源文件的 onUpgrade guard
//    (`if (from == N)` / `if (from <= N)` / `if (from < N)`),
//    断言每个老版本 v ∈ [1, schemaVersion-1] 都被至少 1 个 guard 覆盖 —
//    schemaVersion bump 忘加 migration block 时本测试直接红。
//
// v1.1.0 round 8 (P3) 追加: 老路径 dry-run v3 / v5 起点
// - 背景: onUpgrade 链中 `from <= 3` / `from <= 5` 的 createTable 用当前
//   schema (含全部后来才加的列) 建表, 老版本起点用户的后续 addColumn 撞
//   已存在列 → "duplicate column name" 崩溃, DB 打不开。
// - 修法: 列存在性守卫 helper (app_database.dart 文件级 _columnExists /
//   _addColumnIfMissing), addColumn / backfill / DROP 全部幂等化。
// - 本 group 模拟真实老库形状 (v5: vent 表不存在 + mood v4 shape;
//   v3: mood/vent/6 daily 表都不存在), 断言升级无崩溃 + 列回归 + 老数据保留。
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/core/data/database/app_database.dart';

void main() {
  group('v0.32 round 8 (SP-111-05) — 真实 dry-run v19 → v24', () {
    late Directory tempDir;
    late File dbFile;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('drift_dryrun');
      dbFile = File('${tempDir.path}/dryrun.db');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('19→20→21→22→23→24 5 个真实 step: 列回归 + 老数据保留 + 默认值正确', () async {
      // ---- 第 1 阶段: 建 v24 schema + 写老数据 ----
      final db1 = AppDatabase.forTesting(NativeDatabase(dbFile));
      await db1.medicationDao.insert(
        MedicationsCompanion.insert(
          name: '舍曲林',
          dosage: 50.0,
          dosageUnit: 'mg',
          startDate: DateTime.utc(2026, 6, 1),
        ),
      );
      await db1.moodDao.insert(
        MoodEntriesCompanion.insert(
          timestamp: DateTime.utc(2026, 7, 1, 21, 0),
          score: 4,
        ),
      );
      await db1.ventDao.insert(
        VentEntriesCompanion.insert(
          timestamp: DateTime.utc(2026, 7, 1, 22, 0),
        ),
      );

      // ---- 第 2 阶段: 手动降级到 v19 (DROP 7 个新列 + user_version=19) ----
      // 模拟 2026 年 R101/R105/v1.1.0 之前的老用户库
      await db1.customStatement('ALTER TABLE medications DROP COLUMN form');
      await db1
          .customStatement('ALTER TABLE medications DROP COLUMN color_index');
      await db1.customStatement('ALTER TABLE medications DROP COLUMN notes');
      await db1.customStatement(
        'ALTER TABLE mood_entries DROP COLUMN influence_factors_json',
      );
      await db1.customStatement(
          'ALTER TABLE mood_entries DROP COLUMN recording_mode');
      await db1.customStatement(
        'ALTER TABLE mood_entries DROP COLUMN status_phrase',
      );
      await db1
          .customStatement('ALTER TABLE vent_entries DROP COLUMN tags_json');
      // v1.1.0 round 9 (F1): 降级到 v23 需再 DROP worry_threads 表 +
      // mood_entries.worry_thread_id 列
      await db1.customStatement(
          'ALTER TABLE mood_entries DROP COLUMN worry_thread_id');
      await db1.customStatement('DROP TABLE worry_threads');
      await db1.customStatement('PRAGMA user_version = 19');
      await db1.close();

      // ---- 第 3 阶段: 重开 → onUpgrade 走 19→20→21→22→23→24 真实 step ----
      final db2 = AppDatabase.forTesting(NativeDatabase(dbFile));

      // user_version 升到 24
      final versionRow =
          await db2.customSelect('PRAGMA user_version').getSingle();
      expect(versionRow.data.values.first, 24);

      // 7 个新列全部回归
      final medCols =
          (await db2.customSelect('PRAGMA table_info(medications)').get())
              .map((r) => r.read<String>('name'))
              .toSet();
      expect(medCols, contains('form'));
      expect(medCols, contains('color_index'));
      expect(medCols, contains('notes'));
      final moodCols =
          (await db2.customSelect('PRAGMA table_info(mood_entries)').get())
              .map((r) => r.read<String>('name'))
              .toSet();
      expect(moodCols, contains('influence_factors_json'));
      expect(moodCols, contains('recording_mode'));
      expect(moodCols, contains('status_phrase'));
      // v1.1.0 round 9 (F1): 新列 worry_thread_id + 新表 worry_threads 回归
      expect(moodCols, contains('worry_thread_id'));
      final worryTables = await db2
          .customSelect(
              "SELECT name FROM sqlite_master WHERE type='table' AND name='worry_threads'")
          .get();
      expect(worryTables.length, 1, reason: 'v24 应重建 worry_threads 表');
      final ventCols =
          (await db2.customSelect('PRAGMA table_info(vent_entries)').get())
              .map((r) => r.read<String>('name'))
              .toSet();
      expect(ventCols, contains('tags_json'));

      // 老数据保留 + 迁移默认值正确
      final meds = await db2.medicationDao.watchActive().first;
      expect(meds.length, 1);
      expect(meds.first.name, '舍曲林');
      expect(meds.first.form, 'tablet', reason: 'ADD COLUMN 默认值应写回老行');
      expect(meds.first.colorIndex, 0);
      expect(meds.first.notes, isNull);
      final moods = await db2.moodDao.getAll();
      expect(moods.length, 1);
      expect(moods.first.score, 4);
      expect(
        moods.first.influenceFactorsJson,
        '[]',
        reason: "ADD COLUMN 默认 '[]' 应写回老行",
      );
      expect(moods.first.recordingMode, isNull);
      expect(
        moods.first.statusPhrase,
        isNull,
        reason: 'ADD COLUMN nullable 老数据应自动 null',
      );
      final vents = await db2.ventDao.watchAll().first;
      expect(vents.length, 1);
      expect(
        vents.first.tagsJson,
        '[]',
        reason: "ADD COLUMN 默认 '[]' 应写回老行",
      );

      await db2.close();
    });
  });

  group('v1.1.0 round 8 (P3) — 老路径 dry-run v3 / v5 起点', () {
    late Directory tempDir;
    late File dbFile;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('drift_dryrun_p3');
      dbFile = File('${tempDir.path}/dryrun_p3.db');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    Future<void> downgrade(AppDatabase db, List<String> sqls) async {
      for (final sql in sqls) {
        await db.customStatement(sql);
      }
    }

    // v4 之后 mood_entries 加的 18 列 (v4 shape = id/timestamp/score/tags_json/note)
    const moodAfterV4Columns = [
      'ALTER TABLE mood_entries DROP COLUMN energy',
      'ALTER TABLE mood_entries DROP COLUMN sleep',
      'ALTER TABLE mood_entries DROP COLUMN anxiety',
      'ALTER TABLE mood_entries DROP COLUMN audio_path',
      'ALTER TABLE mood_entries DROP COLUMN audio_transcript',
      'ALTER TABLE mood_entries DROP COLUMN audio_duration_ms',
      'ALTER TABLE mood_entries DROP COLUMN situation',
      'ALTER TABLE mood_entries DROP COLUMN automatic_thought',
      'ALTER TABLE mood_entries DROP COLUMN evidence_for',
      'ALTER TABLE mood_entries DROP COLUMN evidence_against',
      'ALTER TABLE mood_entries DROP COLUMN alternative_thought',
      'ALTER TABLE mood_entries DROP COLUMN rerated_score',
      'ALTER TABLE mood_entries DROP COLUMN core_belief',
      'ALTER TABLE mood_entries DROP COLUMN behavior_response',
      'ALTER TABLE mood_entries DROP COLUMN period',
      'ALTER TABLE mood_entries DROP COLUMN influence_factors_json',
      'ALTER TABLE mood_entries DROP COLUMN recording_mode',
      'ALTER TABLE mood_entries DROP COLUMN status_phrase',
      'ALTER TABLE mood_entries DROP COLUMN worry_thread_id',
    ];

    // v17→v18 才建的 6 daily 表 (v5 / v3 老库都不存在)
    const dailyTableDrops = [
      'DROP TABLE sleep_entries',
      'DROP TABLE social_rhythm_entries',
      'DROP TABLE stress_events',
      'DROP TABLE treatment_entries',
      'DROP TABLE weight_entries',
      'DROP TABLE anxiety_agitation_entries',
    ];

    test('v5 起点: vent 表不存在 + mood v4 shape → 升级无崩溃', () async {
      // ---- 第 1 阶段: 建 v24 schema + 写 1 条老 mood 数据 ----
      final db1 = AppDatabase.forTesting(NativeDatabase(dbFile));
      await db1.moodDao.insert(
        MoodEntriesCompanion.insert(
          timestamp: DateTime.utc(2026, 7, 1, 21, 0),
          score: 4,
        ),
      );

      // ---- 第 2 阶段: 降级到 v5 老库形状 ----
      // v5 老库: vent 表不存在 (v5→v6 才建) + mood v4 shape +
      // 6 daily 表不存在 (v17→v18 才建) + medications/user_profiles
      // 回到 v5 shape (v5 之后才加的列删掉, 否则对应 addColumn/createTable
      // block 会先崩, 与真实 v5 老库形状不符)
      await downgrade(db1, [
        'DROP TABLE vent_entries',
        ...moodAfterV4Columns,
        ...dailyTableDrops,
        'DROP TABLE worry_threads',
        'ALTER TABLE medications DROP COLUMN form',
        'ALTER TABLE medications DROP COLUMN color_index',
        'ALTER TABLE medications DROP COLUMN notes',
        'ALTER TABLE user_profiles DROP COLUMN user_agreement_version',
        'ALTER TABLE user_profiles DROP COLUMN privacy_policy_version',
        'ALTER TABLE user_profiles DROP COLUMN sensitive_data_consent_at',
        'ALTER TABLE user_profiles DROP COLUMN consent_revoked_at',
      ]);
      await db1.customStatement('PRAGMA user_version = 5');
      await db1.close();

      // ---- 第 3 阶段: 重开 → onUpgrade 走 5→...→24 真实 step ----
      final db2 = AppDatabase.forTesting(NativeDatabase(dbFile));

      final versionRow =
          await db2.customSelect('PRAGMA user_version').getSingle();
      expect(versionRow.data.values.first, 24);

      // vent 表存在 + tags_json 回归 + 无残留明文 content_text
      final ventCols =
          (await db2.customSelect('PRAGMA table_info(vent_entries)').get())
              .map((r) => r.read<String>('name'))
              .toSet();
      expect(ventCols, contains('content_text_enc'));
      expect(ventCols, contains('tags_json'));
      expect(
        ventCols,
        isNot(contains('content_text')),
        reason: 'v5 起点新表无明文 content_text, from<19 DROP 块应被守卫跳过',
      );

      // mood v4 之后的 18 列全部回归
      final moodCols =
          (await db2.customSelect('PRAGMA table_info(mood_entries)').get())
              .map((r) => r.read<String>('name'))
              .toSet();
      for (final col in const [
        'energy',
        'sleep',
        'anxiety',
        'audio_path',
        'audio_transcript',
        'audio_duration_ms',
        'situation',
        'automatic_thought',
        'evidence_for',
        'evidence_against',
        'alternative_thought',
        'rerated_score',
        'core_belief',
        'behavior_response',
        'period',
        'influence_factors_json',
        'recording_mode',
        'status_phrase',
        'worry_thread_id',
      ]) {
        expect(moodCols, contains(col), reason: 'mood 列 $col 应回归');
      }

      // 老数据保留 + 默认值正确
      final moods = await db2.moodDao.getAll();
      expect(moods.length, 1);
      expect(moods.first.score, 4);
      expect(moods.first.tagsJson, '[]');
      expect(
        moods.first.statusPhrase,
        isNull,
        reason: 'ADD COLUMN nullable 老数据应自动 null',
      );
      expect(
        moods.first.worryThreadId,
        isNull,
        reason: 'ADD COLUMN nullable 老数据应自动 null',
      );

      await db2.close();
    });

    test('v3 起点: mood/vent/6 daily 表都不存在 → 升级无崩溃', () async {
      // ---- 第 1 阶段: 建 v24 schema ----
      final db1 = AppDatabase.forTesting(NativeDatabase(dbFile));

      // ---- 第 2 阶段: 降级到 v3 老库形状 ----
      // v3 老库: mood (v3→v4 才建) / vent (v5→v6 才建) / 6 daily
      // (v17→v18 才建) 都不存在 + medications/user_profiles 回到 v3 shape
      await downgrade(db1, [
        'DROP TABLE mood_entries',
        'DROP TABLE vent_entries',
        'DROP TABLE worry_threads',
        ...dailyTableDrops,
        'ALTER TABLE medications DROP COLUMN refill_at',
        'ALTER TABLE medications DROP COLUMN refill_reminder_days',
        'ALTER TABLE medications DROP COLUMN form',
        'ALTER TABLE medications DROP COLUMN color_index',
        'ALTER TABLE medications DROP COLUMN notes',
        'ALTER TABLE user_profiles DROP COLUMN user_agreement_version',
        'ALTER TABLE user_profiles DROP COLUMN privacy_policy_version',
        'ALTER TABLE user_profiles DROP COLUMN sensitive_data_consent_at',
        'ALTER TABLE user_profiles DROP COLUMN consent_revoked_at',
      ]);
      await db1.customStatement('PRAGMA user_version = 3');
      await db1.close();

      // ---- 第 3 阶段: 重开 → onUpgrade 走 3→...→24 真实 step ----
      final db2 = AppDatabase.forTesting(NativeDatabase(dbFile));

      final versionRow =
          await db2.customSelect('PRAGMA user_version').getSingle();
      expect(versionRow.data.values.first, 24);

      // mood 表存在且含 status_phrase (from<=3 用当前 schema 建表,
      // 后续 mood addColumn 块被守卫跳过, 不再撞已存在列)
      final moodCols =
          (await db2.customSelect('PRAGMA table_info(mood_entries)').get())
              .map((r) => r.read<String>('name'))
              .toSet();
      expect(moodCols, contains('status_phrase'));
      expect(moodCols, contains('energy'));
      expect(moodCols, contains('worry_thread_id'));

      // worry_threads 表存在 (from<24 建表块)
      final worryTables = await db2
          .customSelect(
              "SELECT name FROM sqlite_master WHERE type='table' AND name='worry_threads'")
          .get();
      expect(worryTables.length, 1, reason: 'v24 应建 worry_threads 表');

      // vent 表存在含 tags_json, 无残留明文 content_text
      final ventCols =
          (await db2.customSelect('PRAGMA table_info(vent_entries)').get())
              .map((r) => r.read<String>('name'))
              .toSet();
      expect(ventCols, contains('tags_json'));
      expect(
        ventCols,
        isNot(contains('content_text')),
        reason: 'v3 起点新表无明文 content_text, 不应被 from<19 DROP 块重建',
      );

      // 6 daily 表存在
      for (final table in const [
        'sleep_entries',
        'social_rhythm_entries',
        'stress_events',
        'treatment_entries',
        'weight_entries',
        'anxiety_agitation_entries',
      ]) {
        final rows = await db2.customSelect('PRAGMA table_info($table)').get();
        expect(rows, isNotEmpty, reason: 'daily 表 $table 应存在');
      }

      await db2.close();
    });
  });

  group('v0.32 round 8 (SP-111-08) — migration guard 覆盖自动比对', () {
    test('每个老版本 v ∈ [1, schemaVersion-1] 都被 onUpgrade guard 覆盖', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final schemaVersion = db.schemaVersion;
      await db.close();

      // R121 P1-3 (1.1.0 round 12k emil dimension): 24-version onUpgrade body
      // 拆 4 sub-part (v1-v5 / v6-v12 / v13-v18 / v19-v24), 主 part 文件
      // 变成 60L 薄壳 orchestrator。读 5 文件跨 24 guard 覆盖测试
      const migrationFiles = [
        'lib/core/data/database/app_database_migrations.dart',
        'lib/core/data/database/app_database_migrations_v1_v5.dart',
        'lib/core/data/database/app_database_migrations_v6_v12.dart',
        'lib/core/data/database/app_database_migrations_v13_v18.dart',
        'lib/core/data/database/app_database_migrations_v19_v24.dart',
      ];
      final main =
          File('lib/core/data/database/app_database.dart').readAsStringSync();
      final parts = migrationFiles
          .map((p) => File(p).readAsStringSync())
          .join('\n');
      final src = '$main\n$parts';

      // 解析所有 `if (from == N)` / `if (from <= N)` / `if (from < N)` —
      // 不再依赖源文件里 onUpgrade 块位置 (R119 后 block 已拆到 part 文件)
      final guardRe = RegExp(r'if \(from (==|<=|<) (\d+)\)');
      final guards = <(String, int)>[];
      for (final m in guardRe.allMatches(src)) {
        guards.add((m.group(1)!, int.parse(m.group(2)!)));
      }
      expect(guards, isNotEmpty, reason: 'onUpgrade 一个 guard 都没有');

      bool covered(int from, (String, int) guard) {
        final (op, n) = guard;
        return switch (op) {
          '==' => from == n,
          '<=' => from <= n,
          '<' => from < n,
          _ => false,
        };
      }

      // 每个老版本都必须被至少 1 个 guard 覆盖
      // (schemaVersion bump 忘加 migration block → 最高步 uncovered → 红)
      for (var v = 1; v < schemaVersion; v++) {
        final ok = guards.any((g) => covered(v, g));
        expect(
          ok,
          isTrue,
          reason: 'from=$v 没有任何 onUpgrade guard 覆盖 — '
              'schemaVersion $schemaVersion 缺 v→v+1 migration block?',
        );
      }
    });
  });
}
