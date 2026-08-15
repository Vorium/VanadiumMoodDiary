// v0.28 round 99 (DeepSeek v0.28+65 P3 #27): export_import_pipeline 零独立测试
//
// 背景:
// - export_import_pipeline.dart (R77 抽出, 360 行) 是 import 流程核心,
//   但 50+ 现有 test 都走 DataExportService.importFromJson facade, 没直接测
//   顶层函数 `Future<ImportResult> runImportFromJson(orch, json)`。
// - facade 跟 pipeline 1:1 委托 (line 101-102: `=> _orchestrator.importFromJson(json)`,
//   内部 `runImportFromJson(this, json)`), 50+ test 间接覆盖 happy path,
//   但 failure path + 边界 (wrong version / malformed JSON / 空 JSON /
//   vent 损坏) 没专门覆盖。
//
// 修法: 11 case 集中测关键路径:
// 1. happy path: export → import → counts 一致 + DB 实际有数据
// 2. import 清空旧 + 写新: 插 A → import B → DB 只有 B
// 3. 二次 import 覆盖 (PIPL §47 删除权场景)
// 4. wrong version (5) → failure 含"数据版本不匹配"
// 5. version 缺省 / null → failure
// 6. malformed JSON 字符串 → failure 含"解析失败"
// 7. 空字符串 JSON → failure
// 8. version=0 → failure
// 9. 空 JSON `{}` → failure (version 缺省)
// 10. vent 加密 round-trip: export 明文 → import 重新加密 → DB 查到密文,
//     decrypt 验一致
import 'dart:convert';
import 'dart:typed_data';

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/services/encryption_service.dart';
import 'package:chroniccare/core/data/services/export/export_audio_service.dart';
import 'package:chroniccare/core/data/services/export/export_crypto_service.dart';
import 'package:chroniccare/core/data/services/export/export_orchestrator.dart';
import 'package:chroniccare/core/data/services/export/export_import_pipeline.dart';
import 'package:chroniccare/core/data/services/export/export_schema_service.dart';
import 'package:chroniccare/core/data/services/data_export_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DataExportService svc;
  late EncryptionService enc;
  late ExportOrchestrator orch;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    enc = EncryptionService();
    enc.setKeyForTest(Uint8List.fromList(List<int>.filled(32, 0x42)));
    svc = DataExportService(db, null, enc);
    // 顶层函数 runImportFromJson(orch, json) 走 orchestrator 公开 getter,
    // 直接构造 ExportOrchestrator 跟 svc 共享 db + enc
    orch = ExportOrchestrator(
      db: db,
      cryptoService: ExportCryptoService(enc),
      audioService: const ExportAudioService(),
      schemaService: const ExportSchemaService(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<Uint8List> encText(String s) async =>
      enc.encrypt(Uint8List.fromList(utf8.encode(s)));

  Map<String, dynamic> parseJson(String json) =>
      jsonDecode(json) as Map<String, dynamic>;

  // ============== happy path ==============

  group('R99 #27 happy path — 完整 round-trip', () {
    test('1. export → import (空 DB) → success + 0 counts', () async {
      final exported = await svc.exportToJson();
      final result = await runImportFromJson(orch, exported);
      expect(result.success, isTrue);
      expect(result.medicationCount, 0);
      expect(result.checkInCount, 0);
      expect(result.reportHistoryCount, 0);
      expect(result.moodEntryCount, 0);
      expect(result.ventEntryCount, 0);
    });

    test('2. export + import 全 6 段数据 → counts 全对 + DB 查到', () async {
      // 准备数据
      await db.userProfileDao.upsert(
        UserProfilesCompanion.insert(
          userName: const Value('王五'),
          checkInCycleHours: const Value(48),
          firstLaunchAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await db.medicationDao.insert(
        MedicationsCompanion.insert(
          name: '舍曲林',
          dosage: 50.0, // required double, not Value<double>
          dosageUnit: 'mg', // required String, not Value<String>
          timesJson: const Value('["08:00"]'),
          startDate: DateTime.utc(2026, 6, 1),
        ),
      );
      await db.checkInDao.insert(
        CheckInsCompanion.insert(
          timestamp: DateTime.utc(2026, 7, 1, 8, 5),
          type: 'normal',
        ),
      );
      final moodId = await db.moodDao.insert(
        MoodEntriesCompanion.insert(
          timestamp: DateTime.utc(2026, 7, 1, 21, 0),
          score: 4,
          energy: const Value(3),
          sleep: const Value(4),
          anxiety: const Value(2),
          tagsJson: const Value('["ok"]'),
          note: const Value('还好'),
        ),
      );
      await db.reportDao.insert(
        ReportHistoriesCompanion.insert(
          windowDays: 7,
          generatedAt: DateTime.utc(2026, 7, 1),
          userName: const Value('王五'),
          reportText: '依从率 90%',
        ),
      );
      await db.ventDao.insert(
        VentEntriesCompanion.insert(
          timestamp: DateTime.utc(2026, 7, 1, 22, 0),
          contentTextEnc: Value(await encText('今天很累')),
        ),
      );

      // export
      final exported = await svc.exportToJson();
      final parsed = parseJson(exported);
      expect(parsed['version'], ExportSchemaService.currentVersion);

      // 清空 DB 再 import 同一份
      await db.delete(db.checkIns).go();
      await db.delete(db.medications).go();
      await db.moodDao.delete(moodId);

      // import
      final result = await runImportFromJson(orch, exported);
      expect(result.success, isTrue);
      expect(result.medicationCount, 1);
      expect(result.checkInCount, 1);
      expect(result.moodEntryCount, 1);
      expect(result.reportHistoryCount, 1);
      expect(result.ventEntryCount, 1);

      // DB 实际有数据
      final profile = await db.userProfileDao.get();
      expect(profile?.userName, '王五');
      final meds = await db.medicationDao.watchActive().first;
      expect(meds.length, 1);
      expect(meds.first.name, '舍曲林');
    });
  });

  // ============== 覆盖语义 ==============

  group('R99 #27 import 覆盖语义 (P0)', () {
    test('3. import 会清空旧 med 但不清 contacts (v6 刻意行为)', () async {
      // 旧: 1 个 contact + 1 个 med
      await db.contactDao.insert(
        ContactsCompanion.insert(
          name: '旧联系人',
          phone: '13800000000',
        ),
      );
      await db.medicationDao.insert(
        MedicationsCompanion.insert(
          name: '旧药',
          dosage: 10.0,
          dosageUnit: 'mg',
          startDate: DateTime.utc(2026, 6, 1),
        ),
      );
      expect((await db.medicationDao.watchActive().first).length, 1);

      // import: 0 med
      final json = jsonEncode({
        'version': ExportSchemaService.currentVersion,
        'exportedAt': '2026-07-01T00:00:00.000Z',
        'profile': null,
        'medications': <Map<String, dynamic>>[],
        'checkIns': <Map<String, dynamic>>[],
        'reportHistories': <Map<String, dynamic>>[],
        'moodEntries': <Map<String, dynamic>>[],
        'ventEntries': <Map<String, dynamic>>[],
      });
      final result = await runImportFromJson(orch, json);
      expect(result.success, isTrue);
      expect(result.medicationCount, 0);
      // 旧 med 被清空
      expect(await db.medicationDao.watchActive().first, isEmpty);
      // contacts 表 Task 9 才删, v6 导入器刻意不清它
      expect((await db.contactDao.watchActive().first).first.name, '旧联系人');
    });

    test('4. 二次 import 第二次 JSON 覆盖第一次 (PIPL §47 删除权场景)', () async {
      final json1 = jsonEncode({
        'version': ExportSchemaService.currentVersion,
        'exportedAt': '2026-07-01T00:00:00.000Z',
        'profile': null,
        'medications': [
          {
            'name': 'A',
            'dosage': 10.0,
            'dosageUnit': 'mg',
            'startDate': '2026-06-01T00:00:00.000Z',
          },
        ],
        'checkIns': <Map<String, dynamic>>[],
        'reportHistories': <Map<String, dynamic>>[],
        'moodEntries': <Map<String, dynamic>>[],
        'ventEntries': <Map<String, dynamic>>[],
      });
      final json2 = jsonEncode({
        'version': ExportSchemaService.currentVersion,
        'exportedAt': '2026-07-02T00:00:00.000Z',
        'profile': null,
        'medications': [
          {
            'name': 'B',
            'dosage': 10.0,
            'dosageUnit': 'mg',
            'startDate': '2026-06-01T00:00:00.000Z',
          },
        ],
        'checkIns': <Map<String, dynamic>>[],
        'reportHistories': <Map<String, dynamic>>[],
        'moodEntries': <Map<String, dynamic>>[],
        'ventEntries': <Map<String, dynamic>>[],
      });
      final r1 = await runImportFromJson(orch, json1);
      expect(r1.success, isTrue);
      expect((await db.medicationDao.watchActive().first).first.name, 'A');

      final r2 = await runImportFromJson(orch, json2);
      expect(r2.success, isTrue);
      // A 被清,只剩 B
      final meds = await db.medicationDao.watchActive().first;
      expect(meds.length, 1);
      expect(meds.first.name, 'B');
    });
  });

  // ============== failure path ==============

  group('R99 #27 failure path (P0-3 三态)', () {
    test('6. wrong version (7 > current 6) → failure 含"数据版本不匹配"', () async {
      final json = jsonEncode({
        'version': 7, // 超过 currentVersion 6
      });
      final result = await runImportFromJson(orch, json);
      expect(result.success, isFalse);
      expect(result.error, contains('数据版本不匹配'));
    });

    test('6. version 缺省 / null → failure', () async {
      // version 字段缺失,validateVersion(null) 应返 null → failure
      final json = jsonEncode({});
      final result = await runImportFromJson(orch, json);
      expect(result.success, isFalse);
      expect(result.error, contains('数据版本不匹配'));
    });

    test('7. malformed JSON 字符串 → failure 含"解析失败"', () async {
      final result = await runImportFromJson(orch, 'not json at all {{');
      expect(result.success, isFalse);
      expect(result.error, contains('解析失败'));
    });

    test('8. 空字符串 JSON → failure 含"解析失败"', () async {
      final result = await runImportFromJson(orch, '');
      expect(result.success, isFalse);
      expect(result.error, contains('解析失败'));
    });

    test('9. version=0 (低于 1) → failure', () async {
      final json = jsonEncode({
        'version': 0,
      });
      final result = await runImportFromJson(orch, json);
      expect(result.success, isFalse);
      expect(result.error, contains('数据版本不匹配'));
    });

    test('10. 空 JSON `{}` → failure (version 缺省)', () async {
      final result = await runImportFromJson(orch, '{}');
      expect(result.success, isFalse);
      expect(result.error, contains('数据版本不匹配'));
    });
  });

  // ============== 字段 round-trip ==============

  group('R99 #27 字段 round-trip (7 段)', () {
    test(
        '11. vent 加密 round-trip: export 明文 → import 重新加密 → '
        'DB 查到密文, decrypt 验一致', () async {
      // 源: 加密 vent 文字写入 DB
      const original = '今天心情很差,需要倾诉';
      final encrypted = await encText(original);
      await db.ventDao.insert(
        VentEntriesCompanion.insert(
          timestamp: DateTime.utc(2026, 7, 1, 22, 0),
          contentTextEnc: Value(encrypted),
        ),
      );

      // export → 拿到明文
      final exported = await svc.exportToJson();
      final parsed = parseJson(exported);
      final vents = parsed['ventEntries'] as List;
      expect(vents.length, 1);
      expect((vents.first as Map)['contentText'], original);

      // 清空 + import → 重新加密
      await db.delete(db.ventEntries).go();
      final result = await runImportFromJson(orch, exported);
      expect(result.success, isTrue);
      expect(result.ventEntryCount, 1);

      // DB 查到的是密文
      final imported = await db.ventDao.watchAll().first;
      expect(imported.length, 1);
      final stored = imported.first.contentTextEnc;
      expect(stored, isNotNull);
      expect(stored, isNot(equals(encrypted))); // 重新加密应不同 IV
      // decrypt 验一致
      final decrypted = await enc.decrypt(stored!);
      expect(utf8.decode(decrypted), original);
    });
  });
}
