// v1.1.0 round 3 (Task 6): export JSON schema v5 → v6 — 导出侧
//
// 情绪优先重构 (docs/superpowers/specs/2026-08-15-emotion-first-refactor-design.md):
// - export 不再写 contacts 段 (表 Task 9 才删, 本 task 只摘除 export/import 引用)
// - moodEntries +statusPhrase (Task 5 列, DB schema 23)
// - ventEntries +tagsJson (Task 5 列, DB schema 23)
//
// 本文件 5 case: RED 阶段全 fail (version 5≠6 / contacts key 存在 /
// statusPhrase/tagsJson 缺 / summary 含联系人), GREEN 后全过。
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

  Future<Uint8List> encText(String s) async =>
      enc.encrypt(Uint8List.fromList(utf8.encode(s)));

  Map<String, dynamic> parseJson(String json) =>
      jsonDecode(json) as Map<String, dynamic>;

  test('1. version = 6', () async {
    final json = parseJson(await svc.exportToJson());
    expect(json['version'], 6);
  });

  test('2. 导出不含 contacts key (DB 有 contacts 也不导出)', () async {
    await db.contactDao.insert(
      ContactsCompanion.insert(
        name: '妈妈',
        phone: '13800138001',
      ),
    );
    final json = parseJson(await svc.exportToJson());
    expect(json.containsKey('contacts'), isFalse);
  });

  test('3. mood entry statusPhrase 导出', () async {
    await db.moodDao.insert(
      MoodEntriesCompanion.insert(
        timestamp: DateTime.utc(2026, 7, 1, 21, 0),
        score: 4,
        statusPhrase: const Value('被治愈了'),
      ),
    );
    final json = parseJson(await svc.exportToJson());
    final m = (json['moodEntries'] as List)[0] as Map<String, dynamic>;
    expect(m['statusPhrase'], '被治愈了');
  });

  test('4. vent entry tagsJson 导出', () async {
    await db.ventDao.insert(
      VentEntriesCompanion.insert(
        timestamp: DateTime.utc(2026, 7, 1, 22, 0),
        contentTextEnc: Value(await encText('今天很累')),
        tagsJson: const Value('["家庭"]'),
      ),
    );
    final json = parseJson(await svc.exportToJson());
    final v = (json['ventEntries'] as List)[0] as Map<String, dynamic>;
    expect(v['tagsJson'], '["家庭"]');
  });

  test('5. import 摘要不含 "联系人" (contactCount 已删)', () async {
    await db.moodDao.insert(
      MoodEntriesCompanion.insert(
        timestamp: DateTime.utc(2026, 7, 1, 21, 0),
        score: 4,
        statusPhrase: const Value('被治愈了'),
      ),
    );
    final exported = await svc.exportToJson();
    final result = await svc.importFromJson(exported);
    expect(result.success, isTrue, reason: result.error);
    expect(result.summary, isNot(contains('联系人')));
  });
}
