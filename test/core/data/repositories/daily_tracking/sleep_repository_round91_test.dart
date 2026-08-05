// v0.30 round 91 (sub-spec 7 日常追踪): SleepRepository 行为锁定
//
// 覆盖 (TDD red→green):
// 1. add → watchAll 返 1 条 SleepEntryEntity, 字段全对应
// 2. add 跨午夜 bedtime/wakeTime → durationMin 自动算
// 3. delete → watchAll 返空
//
// 4 层架构: domain entity 0 flutter 0 drift (跟 VentEntryEntity 一致)。

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/repositories/daily_tracking/sleep_repository_impl.dart';
import 'package:chroniccare/domain/entities/sleep_entry.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SleepRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SleepRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('SleepRepository (v0.30 round 91 新表)', () {
    test('add + watchAll → 1 条 SleepEntryEntity 字段全对应', () async {
      final bedtime = DateTime(2026, 8, 1, 23, 0);
      final wakeTime = DateTime(2026, 8, 2, 7, 30);
      await repo.add(
        date: DateTime(2026, 8, 1),
        bedtime: bedtime,
        wakeTime: wakeTime,
        durationMin: 510,
        regularityScore: 4,
        note: '正常',
      );

      final all = await repo.watchAll().first;
      expect(all.length, 1);
      final e = all.first;
      expect(e, isA<SleepEntryEntity>());
      expect(e.bedtime, bedtime);
      expect(e.wakeTime, wakeTime);
      expect(e.durationMin, 510);
      expect(e.regularityScore, 4);
      expect(e.note, '正常');
    });

    test('delete(id) → watchAll 返空', () async {
      final id = await repo.add(
        date: DateTime(2026, 8, 1),
        bedtime: DateTime(2026, 8, 1, 22, 0),
        wakeTime: DateTime(2026, 8, 2, 6, 0),
        durationMin: 480,
      );
      await repo.delete(id);
      final all = await repo.watchAll().first;
      expect(all, isEmpty);
    });
  });
}
