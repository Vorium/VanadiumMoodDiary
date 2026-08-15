// v1.1.0 round 3 (Task 6): export JSON schema v5 → v6 — 导入侧
//
// 情绪优先重构:
// - 导入器接受 v1-v6 文件; v5 文件含 contacts key 时忽略 (不清 contacts 表 —
//   表 Task 9 才删, 本 task 刻意行为)
// - moodEntries +statusPhrase 反序列化
// - ventEntries +tagsJson 反序列化 (缺省 '[]')
//
// 本文件 4 case: case 1/2 在 RED 阶段 fail (statusPhrase/tagsJson 丢 +
// contacts 被导入), case 3/4 验证老文件优雅降级 (RED 阶段已过, 防回退)。
import 'dart:convert';
import 'dart:typed_data';

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/services/data_export_service.dart';
import 'package:chroniccare/core/data/services/encryption_service.dart';
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

  test('1. v6 JSON (mood statusPhrase / vent tagsJson) → import → DB 还原',
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
          'timestamp': '2026-07-01T21:00:00.000Z',
          'score': 4,
          'statusPhrase': '被治愈了',
        },
      ],
      'ventEntries': [
        {
          'timestamp': '2026-07-01T22:00:00.000Z',
          'contentText': '今天很累',
          'tagsJson': '["家庭"]',
        },
      ],
    });
    final result = await svc.importFromJson(json);
    expect(result.success, isTrue, reason: result.error);
    expect(result.moodEntryCount, 1);
    expect(result.ventEntryCount, 1);
    expect(result.summary, isNot(contains('联系人')));

    final moods = await db.moodDao.getAll();
    expect(moods.length, 1);
    expect(moods.first.statusPhrase, '被治愈了');

    final vents = await db.ventDao.watchAll().first;
    expect(vents.length, 1);
    expect(vents.first.tagsJson, '["家庭"]');
  });

  test('2. v5 文件含 contacts key → import 成功, contacts 忽略, 其他表照常', () async {
    final v5Json = jsonEncode({
      'version': 5,
      'exportedAt': '2026-08-13T00:00:00.000Z',
      'profile': null,
      'contacts': [
        {
          'name': '姐',
          'phone': '13800138003',
          'sortOrder': 0,
          'isActive': true,
        },
      ],
      'medications': [
        {
          'name': '舍曲林',
          'dosage': 50.0,
          'dosageUnit': 'mg',
          'timesJson': '["08:00"]',
          'startDate': '2026-06-01T00:00:00.000Z',
        },
      ],
      'checkIns': <Map<String, dynamic>>[],
      'reportHistories': <Map<String, dynamic>>[],
      'moodEntries': <Map<String, dynamic>>[],
      'ventEntries': <Map<String, dynamic>>[],
    });
    final result = await svc.importFromJson(v5Json);
    expect(result.success, isTrue, reason: result.error);
    expect(result.medicationCount, 1);
    final meds = await db.medicationDao.watchActive().first;
    expect(meds.length, 1);
    expect(meds.first.name, '舍曲林');
    // v5 contacts 段被忽略 (1.1.0 round 4b: contacts 表已整删, 不导入)
    expect(result.summary, isNot(contains('联系人')));
  });

  test('3. 老 v4 风格 mood 无 statusPhrase → 导入后 null (优雅降级)', () async {
    final v4Json = jsonEncode({
      'version': 4,
      'exportedAt': '2026-07-01T00:00:00.000Z',
      'profile': null,
      'medications': <Map<String, dynamic>>[],
      'checkIns': <Map<String, dynamic>>[],
      'moodEntries': [
        {'timestamp': '2026-07-01T21:00:00.000Z', 'score': 4},
      ],
    });
    final result = await svc.importFromJson(v4Json);
    expect(result.success, isTrue, reason: result.error);
    final moods = await db.moodDao.getAll();
    expect(moods.length, 1);
    expect(moods.first.statusPhrase, isNull);
  });

  test('4. 老 v3 风格 vent 无 tagsJson → 导入后 "[]" (优雅降级)', () async {
    final v3Json = jsonEncode({
      'version': 3,
      'exportedAt': '2026-07-01T00:00:00.000Z',
      'profile': null,
      'medications': <Map<String, dynamic>>[],
      'checkIns': <Map<String, dynamic>>[],
      'ventEntries': [
        {
          'timestamp': '2026-07-01T22:00:00.000Z',
          'contentText': '今天很累',
        },
      ],
    });
    final result = await svc.importFromJson(v3Json);
    expect(result.success, isTrue, reason: result.error);
    final vents = await db.ventDao.watchAll().first;
    expect(vents.length, 1);
    expect(vents.first.tagsJson, '[]');
  });
}
