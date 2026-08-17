// v1.1.0 round 12j (R119 P1-1 god class split): regression-protection test
// for the `app_database.dart` ↔ `app_database_migrations.dart` split.
//
// Goal: if anyone re-merges the onUpgrade body back into `app_database.dart`
// (undoing the god-class split) or removes the `part` directive, this test
// fails. The split is a soft architectural choice (file size + readability),
// not a functional one — so the test asserts structural properties:
//
//   1. Both files exist on disk
//   2. `app_database.dart` declares the `part` directive for the migrations file
//   3. `app_database.dart` `onUpgrade:` body is a 1-line delegation (not inline)
//   4. `app_database_migrations.dart` contains all 24 `if (from ...)` guards
//   5. `app_database.dart` main shell is under 200L (god-class size guard)
//
// The functional correctness of the migrations themselves is exercised by
// `test/data/database_migration_dryrun_round8_test.dart` (v3/v5/v19
// real-database upgrade dry-runs + the source-parsing guard coverage test).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('R119 P1-1 — app_database god class split', () {
    const mainPath = 'lib/core/data/database/app_database.dart';
    const partPath = 'lib/core/data/database/app_database_migrations.dart';

    test('main file + migrations part file both exist on disk', () {
      expect(File(mainPath).existsSync(), isTrue, reason: mainPath);
      expect(File(partPath).existsSync(), isTrue, reason: partPath);
    });

    test('main file declares part directive for the migrations file', () {
      final main = File(mainPath).readAsStringSync();
      expect(
        main,
        contains("part 'app_database_migrations.dart';"),
        reason: 'app_database.dart 必须 part 引用 migrations',
      );
    });

    test('main file onUpgrade body is a 1-line delegation, not inline', () {
      final main = File(mainPath).readAsStringSync();
      // 截取 onUpgrade: 到 beforeOpen: 之间
      final upgradeStart = main.indexOf('onUpgrade:');
      final upgradeEnd = main.indexOf('beforeOpen:');
      expect(upgradeStart, greaterThan(0));
      expect(upgradeEnd, greaterThan(upgradeStart));
      final block = main.substring(upgradeStart, upgradeEnd);

      // 必须有 _runAppDatabaseMigrations 委托调用
      expect(
        block,
        contains('_runAppDatabaseMigrations'),
        reason: 'onUpgrade 必须委托到 part 文件的 _runAppDatabaseMigrations',
      );

      // 不能内联 24 个 `if (from ...)` guard (那是 god class 状态)
      final inlineGuards = RegExp(r'if \(from (==|<=|<) \d+\)').allMatches(block);
      expect(
        inlineGuards,
        isEmpty,
        reason: 'onUpgrade 块不应内联 guard — 应在 part 文件',
      );
    });

    test('part file contains all 24 version guards', () {
      final part = File(partPath).readAsStringSync();
      final guards = RegExp(r'if \(from (==|<=|<) (\d+)\)').allMatches(part);

      // 24 个 version (1 to 24) 必须每个都至少被 1 个 guard 覆盖
      // — 等价于 database_migration_dryrun_round8_test.dart 的覆盖测试
      // 但只解析 part 文件 (R119 前 main 文件 564L 包含全部 guard)
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
          reason: 'version $v 没有任何 onUpgrade guard 覆盖',
        );
      }
    });

    test('main file shell stays under 200L (god-class size guard)', () {
      final lines = File(mainPath).readAsLinesSync().length;
      expect(
        lines,
        lessThan(200),
        reason:
            'app_database.dart 主壳应保持精简 (R119 P1-1 拆后 139L), '
            '回归到 500+L 表示 migration 体被回填',
      );
    });
  });
}
