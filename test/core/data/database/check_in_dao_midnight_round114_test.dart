// R114 B1-4: watchToday/watchTodayAll 跨 midnight 窗口冻结 (DAO 根源)
// (2026-08-16 标准审计 · 10-bottom-core-data 发现 6)
//
// 修前: watchToday() / watchTodayAll() 在流创建时一次性捕获 DateTime.now()
// 边界 — App 跨 00:00 长开, stream 不重建 → "今天"窗口永远停在昨天。
// R113 wave 7 只修了 presentation 5 处 (todayProvider), DAO 层 stale 根源还在。
//
// 修后: DAO 构造时注入 clock + midnightDelay (默认 DateTime.now + 下一个
// 00:00:05), 流内每次跨日重新计算窗口并重新查询。
//
// TDD: 老代码在 fakeNow 跨日后不产生新 emit → `emitted.last` 停在昨天 →
// expect 失败; 新代码跨日 tick 后重查 → 窗口更新 → pass。
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/daos/check_in_dao.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('R114 B1-4: watchToday 跨 midnight 窗口更新', () {
    test('watchTodayAll: 跨日 tick 后查询窗口从昨天切到今天', () async {
      var fakeNow = DateTime(2026, 8, 16, 23, 30);
      final dao = CheckInDao(
        db,
        clock: () => fakeNow,
        midnightDelay: (_) => const Duration(milliseconds: 10),
      );
      await db.into(db.checkIns).insert(
            CheckInsCompanion.insert(
              timestamp: DateTime(2026, 8, 16, 10, 0),
              type: 'normal',
            ),
          );
      await db.into(db.checkIns).insert(
            CheckInsCompanion.insert(
              timestamp: DateTime(2026, 8, 17, 1, 0),
              type: 'normal',
            ),
          );

      final emitted = <List<CheckIn>>[];
      final sub = dao.watchTodayAll().listen(emitted.add);
      // 等首个 emit (初始窗口 = 8/16)
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(emitted, isNotEmpty);
      expect(emitted.last.map((c) => c.timestamp.hour), [10]);

      // 跨日: clock 前进到 8/17, 下一个 midnight tick 后窗口应切换
      fakeNow = DateTime(2026, 8, 17, 0, 1);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(emitted.last.map((c) => c.timestamp.hour), [1]);

      await sub.cancel();
    });

    test('watchToday: 昨天没有今天有 → 跨日后 emit 今天的 entry', () async {
      var fakeNow = DateTime(2026, 8, 16, 23, 30);
      final dao = CheckInDao(
        db,
        clock: () => fakeNow,
        midnightDelay: (_) => const Duration(milliseconds: 10),
      );
      await db.into(db.checkIns).insert(
            CheckInsCompanion.insert(
              timestamp: DateTime(2026, 8, 17, 1, 0),
              type: 'normal',
            ),
          );

      final emitted = <CheckIn?>[];
      final sub = dao.watchToday().listen(emitted.add);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(emitted.last, isNull, reason: '8/16 没有打卡 → null');

      fakeNow = DateTime(2026, 8, 17, 0, 1);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(emitted.last, isNotNull, reason: '跨日后 8/17 的打卡应出现');
      expect(emitted.last!.timestamp.hour, 1);

      await sub.cancel();
    });

    test('跨日后窗口不再包含昨天的 entry (窗口是滑动不是累积)', () async {
      var fakeNow = DateTime(2026, 8, 16, 23, 30);
      final dao = CheckInDao(
        db,
        clock: () => fakeNow,
        midnightDelay: (_) => const Duration(milliseconds: 10),
      );
      await db.into(db.checkIns).insert(
            CheckInsCompanion.insert(
              timestamp: DateTime(2026, 8, 16, 10, 0),
              type: 'normal',
              note: const Value('yesterday-entry'),
            ),
          );

      final emitted = <List<CheckIn>>[];
      final sub = dao.watchTodayAll().listen(emitted.add);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(emitted.last.map((c) => c.note), ['yesterday-entry']);

      fakeNow = DateTime(2026, 8, 17, 0, 1);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(emitted.last, isEmpty, reason: '8/17 无打卡 → 空, 不含昨天');

      await sub.cancel();
    });
  });
}
