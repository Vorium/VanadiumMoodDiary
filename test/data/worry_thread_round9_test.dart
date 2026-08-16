// v1.1.0 round 9 (F1 烦恼闭环) — worry_threads 表 DAO + repo round-trip 测试
//
// data 层 round-trip:
// - WorryDao: insert / watchOpen / watchResolved / resolve / reopen / rename / getAll
// - 烦恼时间线聚合: mood.worryThreadId 关联查询 (watchByThread)
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;

import 'package:chroniccare/core/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => db.close());

  test('insert → watchOpen 出现, watchResolved 空', () async {
    final id = await db.worryDao.insert(
      title: '工作压力',
      createdAt: DateTime(2026, 8, 15, 9),
    );
    final open = await db.worryDao.watchOpen().first;
    expect(open.length, 1);
    expect(open.first.id, id);
    expect(open.first.title, '工作压力');
    expect(open.first.status, 'open');
    expect(await db.worryDao.watchResolved().first, isEmpty);
  });

  test('resolve → 移入 watchResolved + resolvedAt 记录, open 消失', () async {
    final id = await db.worryDao.insert(
      title: '失眠',
      createdAt: DateTime(2026, 8, 15, 9),
    );
    await db.worryDao.resolve(id, resolvedAt: DateTime(2026, 8, 16, 20));

    final open = await db.worryDao.watchOpen().first;
    final resolved = await db.worryDao.watchResolved().first;
    expect(open, isEmpty);
    expect(resolved.length, 1);
    expect(resolved.first.status, 'resolved');
    expect(resolved.first.resolvedAt, DateTime(2026, 8, 16, 20));
  });

  test('reopen → 回到 open, resolvedAt 清空', () async {
    final id = await db.worryDao.insert(
      title: '旧烦恼',
      createdAt: DateTime(2026, 8, 15),
    );
    await db.worryDao.resolve(id, resolvedAt: DateTime(2026, 8, 16));
    await db.worryDao.reopen(id);

    final open = await db.worryDao.watchOpen().first;
    expect(open.single.id, id);
    expect(open.single.resolvedAt, isNull);
    expect(await db.worryDao.watchResolved().first, isEmpty);
  });

  test('rename → title 更新', () async {
    final id = await db.worryDao.insert(
      title: '旧标题',
      createdAt: DateTime(2026, 8, 15),
    );
    await db.worryDao.rename(id, '新标题');
    final open = await db.worryDao.watchOpen().first;
    expect(open.single.title, '新标题');
  });

  test('getAll → 全量 (导出用), 含 resolved', () async {
    final a = await db.worryDao.insert(
      title: 'A',
      createdAt: DateTime(2026, 8, 15),
    );
    final b = await db.worryDao.insert(
      title: 'B',
      createdAt: DateTime(2026, 8, 16),
    );
    await db.worryDao.resolve(b, resolvedAt: DateTime(2026, 8, 17));
    final all = await db.worryDao.getAll();
    expect(all.length, 2);
    expect(all.map((w) => w.id), containsAll([a, b]));
  });

  test('watchByThread: mood 绑定烦恼 → 该主题下聚合出记录', () async {
    final threadId = await db.worryDao.insert(
      title: '关系问题',
      createdAt: DateTime(2026, 8, 15, 9),
    );
    await db.moodDao.insert(
      MoodEntriesCompanion.insert(
        timestamp: DateTime(2026, 8, 15, 10),
        score: 3,
        note: const Value('又吵架了'),
        worryThreadId: Value(threadId),
      ),
    );
    await db.moodDao.insert(
      MoodEntriesCompanion.insert(
        timestamp: DateTime(2026, 8, 15, 11),
        score: 2,
        note: const Value('很伤心'),
        worryThreadId: Value(threadId),
      ),
    );
    // 未绑定的记录不应出现
    await db.moodDao.insert(
      MoodEntriesCompanion.insert(
        timestamp: DateTime(2026, 8, 15, 12),
        score: 4,
        note: const Value('今天不错'),
      ),
    );

    final entries = await db.moodDao.watchByThread(threadId).first;
    expect(entries.length, 2);
    expect(entries.map((e) => e.note), containsAll(['又吵架了', '很伤心']));
    // 时间正序
    expect(
      entries[0].timestamp.isBefore(entries[1].timestamp),
      isTrue,
      reason: 'watchByThread 应按时间正序',
    );
  });

  test('watchByThread: 未绑定 (null) 记录不出现在任何主题', () async {
    final threadId = await db.worryDao.insert(
      title: 'X',
      createdAt: DateTime(2026, 8, 15),
    );
    await db.moodDao.insert(
      MoodEntriesCompanion.insert(
        timestamp: DateTime(2026, 8, 15, 10),
        score: 4,
      ),
    );
    expect(await db.moodDao.watchByThread(threadId).first, isEmpty);
  });
}
