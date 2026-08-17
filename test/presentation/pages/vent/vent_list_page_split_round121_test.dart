// v1.1.0+158 R121 P1-2 (frame-thinking god class split): regression-protection
// test for `vent_list_page.dart` 684L → 424L 主壳 + 232L `vent_entry_cell.dart`
// 抽出。
//
// Goal: if anyone re-merges `_EntryCell` or `_VentHintHelper` back into
// `vent_list_page.dart` (undoing the god-class split), this test fails.
// The split is a soft architectural choice (file size + readability), not
// a functional one — so the test asserts structural properties:
//
//   1. Both files exist on disk
//   2. `vent_list_page.dart` 主壳 < 500L (god-class size guard, R121 target 424L)
//   3. `vent_entry_cell.dart` exists with `VentEntryCell` public widget
//   4. `VentHintHelper` exists (was `_VentHintHelper`)
//   5. `vent_list_page.dart` no longer contains `_EntryCell` / `_VentHintHelper`
//   6. 公开 widget 提供 `super.key` 构造 (use_key_in_widget_constructors)
//
// The functional correctness of vent list rendering + 树洞 list 行为
// is exercised by `test/presentation/pages/mood_list/mood_trend_day_change_round113_test.dart`
// (5 处 build 不再 DateTime.now() 跨 midnight lock-in) + integration tests
// under `test/data/` and `test/presentation/`.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('R121 P1-2 — vent_list_page god class split', () {
    const mainPath = 'lib/features/vent/presentation/pages/vent/vent_list_page.dart';
    const cellPath =
        'lib/features/vent/presentation/pages/vent/widgets/vent_entry_cell.dart';
    const listPath =
        'lib/features/vent/presentation/pages/vent/widgets/vent_entry_list.dart';

    test('main + entry cell + entry list 文件三存在', () {
      expect(File(mainPath).existsSync(), isTrue, reason: mainPath);
      expect(File(cellPath).existsSync(), isTrue, reason: cellPath);
      expect(File(listPath).existsSync(), isTrue, reason: listPath);
    });

    test('主壳 < 350L (R121 P1-2 续拆 2/3 后 ~255L, god-class size guard)', () {
      final lines = File(mainPath).readAsLinesSync().length;
      expect(
        lines,
        lessThan(350),
        reason:
            'vent_list_page.dart 主壳应保持精简 (R121 P1-2 续拆后 255L), '
            '回归到 684+L 表示 _EntryCell / _VentHintHelper / _EntryList 被回填',
      );
    });

    test('VentEntryCell public widget 在 entry cell 文件', () {
      final cell = File(cellPath).readAsStringSync();
      expect(cell, contains('class VentEntryCell extends ConsumerWidget'),
          reason: '_EntryCell → VentEntryCell 公开化');
      expect(cell, contains('super.key'),
          reason: '公开 widget 必须有 super.key 构造');
    });

    test('VentEntryList public widget 在 entry list 文件', () {
      final list = File(listPath).readAsStringSync();
      expect(list, contains('class VentEntryList extends ConsumerStatefulWidget'),
          reason: '_EntryList → VentEntryList 公开化');
      expect(list, contains('super.key'),
          reason: '公开 widget 必须有 super.key 构造');
    });

    test('VentHintHelper public static class 在 entry cell 文件', () {
      final cell = File(cellPath).readAsStringSync();
      expect(cell, contains('class VentHintHelper'),
          reason: '_VentHintHelper → VentHintHelper 公开化');
      expect(cell, contains('showSwipeHintIfFirstTime'),
          reason: '保留原 showSwipeHintIfFirstTime static method');
    });

    test('主壳不再含 _EntryCell / _VentHintHelper / _EntryList / _EntryListState', () {
      final main = File(mainPath).readAsStringSync();
      expect(main, isNot(contains('class _EntryCell')),
          reason: '主壳不应再有 _EntryCell class 定义');
      expect(main, isNot(contains('class _VentHintHelper')),
          reason: '主壳不应再有 _VentHintHelper class 定义');
      expect(main, isNot(contains('class _EntryList')),
          reason: '主壳不应再有 _EntryList class 定义');
      expect(main, isNot(contains('class _EntryListState')),
          reason: '主壳不应再有 _EntryListState class 定义');
      // call site 应已切到公开 widget
      expect(main, contains('VentEntryList'),
          reason: '主壳调 VentEntryList (公开 widget)');
      expect(main, contains('VentHintHelper.showSwipeHintIfFirstTime'),
          reason: '主壳调 VentHintHelper.showSwipeHintIfFirstTime (公开 helper)');
    });
  });
}
