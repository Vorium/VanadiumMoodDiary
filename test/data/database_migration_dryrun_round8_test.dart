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
// 1. 真实 dry-run: 建 v22 schema → 手动 DROP 5 个新列 + user_version 降到 19
//    (模拟老用户 v19 库) → 重开 AppDatabase → onUpgrade 走 19→20→21→22
//    3 个真实 step → 断言列回归 + 老数据保留 + 默认值正确。
// 2. 自动比对: 解析 app_database.dart 源文件的 onUpgrade guard
//    (`if (from == N)` / `if (from <= N)` / `if (from < N)`),
//    断言每个老版本 v ∈ [1, schemaVersion-1] 都被至少 1 个 guard 覆盖 —
//    schemaVersion bump 忘加 migration block 时本测试直接红。
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/core/data/database/app_database.dart';

void main() {
  group('v0.32 round 8 (SP-111-05) — 真实 dry-run v19 → v22', () {
    late Directory tempDir;
    late File dbFile;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('drift_dryrun');
      dbFile = File('${tempDir.path}/dryrun.db');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('19→20→21→22 3 个真实 step: 列回归 + 老数据保留 + 默认值正确',
        () async {
      // ---- 第 1 阶段: 建 v22 schema + 写老数据 ----
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

      // ---- 第 2 阶段: 手动降级到 v19 (DROP 5 个新列 + user_version=19) ----
      // 模拟 2026 年 R101/R105 之前的老用户库
      await db1.customStatement('ALTER TABLE medications DROP COLUMN form');
      await db1
          .customStatement('ALTER TABLE medications DROP COLUMN color_index');
      await db1.customStatement('ALTER TABLE medications DROP COLUMN notes');
      await db1.customStatement(
        'ALTER TABLE mood_entries DROP COLUMN influence_factors_json',
      );
      await db1
          .customStatement('ALTER TABLE mood_entries DROP COLUMN recording_mode');
      await db1.customStatement('PRAGMA user_version = 19');
      await db1.close();

      // ---- 第 3 阶段: 重开 → onUpgrade 走 19→20→21→22 真实 step ----
      final db2 = AppDatabase.forTesting(NativeDatabase(dbFile));

      // user_version 升到 22
      final versionRow = await db2.customSelect('PRAGMA user_version').getSingle();
      expect(versionRow.data.values.first, 22);

      // 5 个新列全部回归
      final medCols = (await db2.customSelect('PRAGMA table_info(medications)').get())
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
      expect(moods.first.influenceFactorsJson, '[]',
          reason: "ADD COLUMN 默认 '[]' 应写回老行",);
      expect(moods.first.recordingMode, isNull);

      await db2.close();
    });
  });

  group('v0.32 round 8 (SP-111-08) — migration guard 覆盖自动比对', () {
    test('每个老版本 v ∈ [1, schemaVersion-1] 都被 onUpgrade guard 覆盖',
        () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final schemaVersion = db.schemaVersion;
      await db.close();

      final src = File('lib/core/data/database/app_database.dart')
          .readAsStringSync();

      // 只解析 onUpgrade block 内的 guard (截取 onUpgrade 到 beforeOpen 之间)
      final upgradeStart = src.indexOf('onUpgrade:');
      final upgradeEnd = src.indexOf('beforeOpen:');
      expect(upgradeStart, greaterThan(0), reason: '找不到 onUpgrade block');
      expect(upgradeEnd, greaterThan(upgradeStart));
      final upgradeBlock = src.substring(upgradeStart, upgradeEnd);

      // 解析 `if (from == N)` / `if (from <= N)` / `if (from < N)`
      final guardRe = RegExp(r'if \(from (==|<=|<) (\d+)\)');
      final guards = <(String, int)>[];
      for (final m in guardRe.allMatches(upgradeBlock)) {
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
        expect(ok, isTrue,
            reason: 'from=$v 没有任何 onUpgrade guard 覆盖 — '
                'schemaVersion $schemaVersion 缺 v→v+1 migration block?',);
      }
    });
  });
}
