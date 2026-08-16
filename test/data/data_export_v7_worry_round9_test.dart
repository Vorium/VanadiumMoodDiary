// v1.1.0 round 9 (F1 烦恼闭环): export JSON schema v6 → v7 — worryThreads 段
//
// - 导出: worryThreads 段 (title/createdAt/status/resolvedAt) +
//   moodEntries +worryThreadId (原 id)
// - 导入: worryThreads 段重建 (old→new id 映射) + mood.worryThreadId 重映射
// - 老 v6 文件 (无 worryThreads 段) → mood.worryThreadId 降级 null
import 'dart:convert';
import 'dart:typed_data';

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/services/data_export_service.dart';
import 'package:chroniccare/core/data/services/encryption_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DataExportService svc;
  late EncryptionService enc;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    enc = EncryptionService();
    enc.setKeyForTest(Uint8List.fromList(List<int>.filled(32, 0x42)));
    svc = DataExportService(db, null, enc);
  });

  tearDown(() async {
    await db.close();
  });

  Map<String, dynamic> parseJson(String json) =>
      jsonDecode(json) as Map<String, dynamic>;

  test('1. export 含 worryThreads 段 + mood.worryThreadId', () async {
    final threadId = await db.worryDao.insert(
      title: '工作压力',
      createdAt: DateTime.utc(2026, 8, 15, 9),
    );
    await db.moodDao.insert(
      MoodEntriesCompanion.insert(
        timestamp: DateTime.utc(2026, 8, 15, 10),
        score: 3,
        note: const Value('方案又被打回'),
        worryThreadId: Value(threadId),
      ),
    );
    final json = parseJson(await svc.exportToJson());
    expect(json['version'], 7);

    final worries = json['worryThreads'] as List;
    expect(worries.length, 1);
    expect((worries[0] as Map)['title'], '工作压力');
    expect((worries[0] as Map)['status'], 'open');

    final mood = (json['moodEntries'] as List)[0] as Map;
    expect(mood['worryThreadId'], threadId);
  });

  test('2. v7 import → worryThreads 重建 + mood.worryThreadId 重映射 (old→new)',
      () async {
    final json = jsonEncode({
      'version': 7,
      'exportedAt': '2026-08-16T00:00:00.000Z',
      'profile': null,
      'medications': <Map<String, dynamic>>[],
      'checkIns': <Map<String, dynamic>>[],
      'reportHistories': <Map<String, dynamic>>[],
      'moodEntries': [
        {
          'id': 999,
          'timestamp': '2026-08-15T10:00:00.000Z',
          'score': 3,
          'worryThreadId': 42, // 引用下面 worryThreads 的原 id
        },
      ],
      'worryThreads': [
        {
          'id': 42,
          'title': '工作压力',
          'createdAt': '2026-08-15T09:00:00.000Z',
          'status': 'open',
        },
      ],
      'ventEntries': <Map<String, dynamic>>[],
    });
    final result = await svc.importFromJson(json);
    expect(result.success, isTrue, reason: result.error);
    expect(result.moodEntryCount, 1);

    final worries = await db.worryDao.getAll();
    expect(worries.length, 1);
    expect(worries.first.title, '工作压力');
    expect(worries.first.status, 'open');
    final newId = worries.first.id;

    final moods = await db.moodDao.getAll();
    expect(moods.length, 1);
    expect(
      moods.first.worryThreadId,
      newId,
      reason: 'import 后 mood.worryThreadId 应重映射到新 id (非 42)',
    );
  });

  test('3. 闭环烦恼导出 + 导入 → resolvedAt 保留', () async {
    final threadId = await db.worryDao.insert(
      title: '失眠',
      createdAt: DateTime.utc(2026, 8, 1, 9),
    );
    await db.worryDao.resolve(
      threadId,
      resolvedAt: DateTime.utc(2026, 8, 10, 20),
    );
    final json = parseJson(await svc.exportToJson());
    final worries = json['worryThreads'] as List;
    expect((worries[0] as Map)['status'], 'resolved');
    expect((worries[0] as Map)['resolvedAt'], '2026-08-10T20:00:00.000Z');

    final importJson = jsonEncode({
      'version': 7,
      'exportedAt': '2026-08-16T00:00:00.000Z',
      'profile': null,
      'medications': <Map<String, dynamic>>[],
      'checkIns': <Map<String, dynamic>>[],
      'reportHistories': <Map<String, dynamic>>[],
      'moodEntries': <Map<String, dynamic>>[],
      'worryThreads': worries,
      'ventEntries': <Map<String, dynamic>>[],
    });
    final result = await svc.importFromJson(importJson);
    expect(result.success, isTrue, reason: result.error);

    final resolved = await db.worryDao.watchResolved().first;
    expect(resolved.length, 1);
    expect(
      resolved.first.resolvedAt!.toUtc(),
      DateTime.utc(2026, 8, 10, 20),
      reason: 'resolvedAt 保留 (时区归一化到 UTC 比较)',
    );
  });

  test('4. 老 v6 文件 (无 worryThreads 段) → 降级: mood.worryThreadId = null',
      () async {
    final json = jsonEncode({
      'version': 6,
      'exportedAt': '2026-08-15T00:00:00.000Z',
      'profile': null,
      'medications': <Map<String, dynamic>>[],
      'checkIns': <Map<String, dynamic>>[],
      'reportHistories': <Map<String, dynamic>>[],
      'moodEntries': [
        {
          'id': 999,
          'timestamp': '2026-08-15T10:00:00.000Z',
          'score': 3,
          // v6 无 worryThreadId key
        },
      ],
      'ventEntries': <Map<String, dynamic>>[],
    });
    final result = await svc.importFromJson(json);
    expect(result.success, isTrue, reason: result.error);

    final moods = await db.moodDao.getAll();
    expect(moods.length, 1);
    expect(
      moods.first.worryThreadId,
      isNull,
      reason: 'v6 无 worryThreads 段 → 引用不在 export → null (不建孤儿 FK)',
    );
  });
}
