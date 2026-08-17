// v1.1.0+161 R121 P1-3 (emil dimension god class split): regression-protection
// test for `app_database_migrations.dart` 480L → 60L 薄壳 + 4 sub-part
// (v1-v5 / v6-v12 / v13-v18 / v19-v24)。
//
// Goal: if anyone re-merges 4 sub-part 的 if guard 块回主 part 文件 (undoing
// the split), this test fails. The split is a soft architectural choice
// (file size + readability), not a functional one — so the test asserts
// structural properties:
//
//   1. 5 文件全存在 (主 + 4 sub-part)
//   2. 主 part 文件 < 150L (R121 拆后 60L, god-class size guard 防回填)
//   3. 4 sub-part 各自 < 200L (god-class size guard)
//   4. 主 part 文件不再含 `if (from <op> N)` 守卫 (全外移)
//   5. 4 sub-part 跨 24 version guard 全部覆盖 (跟 round119 split test 互补)
//   6. 4 sub-part 含特定版本的 known guard pattern (v1-v5 含 from==1,
//      v6-v12 含 from<=8 加密 backfill, v13-v18 含 from<=16 CBT 8 列,
//      v19-v24 含 from<19 DROP contentText)
//
// The functional correctness of the actual migration is exercised by
// `test/data/database_migration_dryrun_round8_test.dart` (v3/v5/v19 真实
// dry-run + 24 version guard 覆盖) + `test/core/data/database/app_database_split_round119_test.dart`
// (part 文件结构)。

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('R121 P1-3 — app_database_migrations 拆 4 sub-part', () {
    const mainPath = 'lib/core/data/database/app_database_migrations.dart';
    const v1v5Path =
        'lib/core/data/database/app_database_migrations_v1_v5.dart';
    const v6v12Path =
        'lib/core/data/database/app_database_migrations_v6_v12.dart';
    const v13v18Path =
        'lib/core/data/database/app_database_migrations_v13_v18.dart';
    const v19v24Path =
        'lib/core/data/database/app_database_migrations_v19_v24.dart';

    test('5 文件全存在 (主 + 4 sub-part)', () {
      expect(File(mainPath).existsSync(), isTrue, reason: mainPath);
      expect(File(v1v5Path).existsSync(), isTrue, reason: v1v5Path);
      expect(File(v6v12Path).existsSync(), isTrue, reason: v6v12Path);
      expect(File(v13v18Path).existsSync(), isTrue, reason: v13v18Path);
      expect(File(v19v24Path).existsSync(), isTrue, reason: v19v24Path);
    });

    test('主 part 文件 < 150L (R121 拆后 60L, god-class size guard)', () {
      final lines = File(mainPath).readAsLinesSync().length;
      expect(
        lines,
        lessThan(150),
        reason:
            'app_database_migrations.dart 主 orchestrator 应保持精简 (R121 拆后 60L), '
            '回归到 480+L 表示 4 sub-part 的 if guard 块被回填',
      );
    });

    test('4 sub-part 各自 < 200L (god-class size guard)', () {
      for (final path in [v1v5Path, v6v12Path, v13v18Path, v19v24Path]) {
        final lines = File(path).readAsLinesSync().length;
        expect(
          lines,
          lessThan(200),
          reason: '$path 拆后应 < 200L, 实际 ${lines}L',
        );
      }
    });

    test('主 part 文件不再含 `if (from ...)` 守卫 (全外移到 4 sub-part)', () {
      final main = File(mainPath).readAsStringSync();
      final guards = RegExp(r'if \(from (==|<=|<) (\d+)\)').allMatches(main);
      expect(
        guards,
        isEmpty,
        reason: '主 orchestrator 不应再有 if (from ...) 守卫, 24 guard 全外移到 4 sub-part',
      );
    });

    test('4 sub-part 跨 24 version guard 全部覆盖', () {
      final allSrc = [
        v1v5Path,
        v6v12Path,
        v13v18Path,
        v19v24Path,
      ].map((p) => File(p).readAsStringSync()).join('\n');
      final guards =
          RegExp(r'if \(from (==|<=|<) (\d+)\)').allMatches(allSrc);

      final covered = <int>{};
      for (final m in guards) {
        final op = m.group(1)!;
        final n = int.parse(m.group(2)!);
        for (var v = 1; v < 24; v++) {
          final hit = switch (op) {
            '==' => v == n,
            '<=' => v <= n,
            '<' => v < n,
            _ => false,
          };
          if (hit) covered.add(v);
        }
      }
      for (var v = 1; v < 24; v++) {
        expect(
          covered.contains(v),
          isTrue,
          reason: 'version $v 没有任何 onUpgrade guard 覆盖 (4 sub-part 应覆盖)',
        );
      }
    });

    test('4 sub-part 各自含特定版本的 known guard pattern', () {
      // v1-v5: 含 from == 1 (v1→v2 dosage / dosageUnit 唯一 = 等于 guard)
      final v1v5 = File(v1v5Path).readAsStringSync();
      expect(v1v5.contains('if (from == 1)'), isTrue,
          reason: 'v1-v5 sub-part 应含 from==1 (v1→v2 dosage 等于 guard)');
      expect(v1v5.contains('_runAppDatabaseMigrationsV1ToV5'), isTrue,
          reason: 'v1-v5 sub-part 应定义 _runAppDatabaseMigrationsV1ToV5 函数');

      // v6-v12: 含 from <= 8 加密 backfill 块
      final v6v12 = File(v6v12Path).readAsStringSync();
      expect(v6v12.contains('if (from <= 8)'), isTrue,
          reason: 'v6-v12 sub-part 应含 from<=8 (v8→v9 vent 加密 backfill)');
      expect(v6v12.contains('app_database.v8v9_vent_encrypt_fail'),
          isTrue,
          reason: 'v6-v12 应保留 v8v9 加密失败 swallowError where tag');
      expect(v6v12.contains('_runAppDatabaseMigrationsV6ToV12'), isTrue,
          reason: 'v6-v12 sub-part 应定义 _runAppDatabaseMigrationsV6ToV12 函数');

      // v13-v18: 含 from <= 16 (8 CBT 列)
      final v13v18 = File(v13v18Path).readAsStringSync();
      expect(v13v18.contains('if (from <= 16)'), isTrue,
          reason: 'v13-v18 sub-part 应含 from<=16 (v15→v17 mood +8 CBT 列)');
      expect(v13v18.contains('moodEntries.situation'), isTrue,
          reason: 'v13-v18 应含 8 CBT 列首列 situation');
      expect(v13v18.contains('_runAppDatabaseMigrationsV13ToV18'), isTrue,
          reason: 'v13-v18 sub-part 应定义 _runAppDatabaseMigrationsV13ToV18 函数');

      // v19-v24: 含 from < 19 DROP content_text + from < 23 contacts 整摘
      final v19v24 = File(v19v24Path).readAsStringSync();
      expect(v19v24.contains('if (from < 19)'), isTrue,
          reason: 'v19-v24 sub-part 应含 from<19 (v18→v19 DROP content_text)');
      expect(v19v24.contains("m.deleteTable('contacts')"), isTrue,
          reason: 'v19-v24 应含 1.1.0 round 4b contacts 整摘');
      expect(v19v24.contains('if (from < 24)'), isTrue,
          reason: 'v19-v24 应含 from<24 (v23→v24 worry 闭环)');
      expect(v19v24.contains('_runAppDatabaseMigrationsV19ToV24'), isTrue,
          reason: 'v19-v24 sub-part 应定义 _runAppDatabaseMigrationsV19ToV24 函数');
    });
  });
}
