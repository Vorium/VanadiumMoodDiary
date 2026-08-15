// v0.32 round 8 (R111 E1/E2/E3 fix): export JSON schema v4 → v5
//
// 背景 (R111 审计发现, docs/audit/2026-08-13-r111-multi-lens/):
// - E1 (P1, ≤1d): export JSON schema v4 落后 DB schema 22 — medications 漏
//   refillAt / refillReminderDays / form / colorIndex / notes 5 字段,
//   moodEntries 漏 audioTranscript / audioDurationMs / period /
//   influenceFactorsJson / recordingMode 5 字段 + audioPath。用户换机/重装后
//   静默丢失。
// - E2 (P1, ≤2h): contacts consent 4 字段 (consentAt / kind / by / version,
//   R63 加, PIPL §13 留痕) 不导出。R68 gate 只挡 add() 路径, 导入直接绕过
//   → 留痕断裂。
// - E3 (P2, ≤1d): checkIn.medicationId 导入不重映射 → 孤儿 FK。
//
// 修法: 一次 v5 schema 升级 (export/import 双向补字段 + consent 4 字段 +
// checkIn FK 重映射)。audioPath 沿用 vent 先例 (stale 路径跨设备不可用,
// 不导出不导入, 只保文字转录 + 时长元数据)。
// 本文件 7 case: RED 阶段全 fail, GREEN 后全过。
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

  group('v0.32 round 8 (R111 E1) — medication v5 字段 round-trip', () {
    test('1. 导出含 5 个新增字段 (refillAt/refillReminderDays/form/colorIndex/notes)',
        () async {
      await db.medicationDao.insert(
        MedicationsCompanion.insert(
          name: '文拉法辛',
          dosage: 75.0,
          dosageUnit: 'mg',
          timesJson: const Value('[{"h":8,"m":0}]'),
          startDate: DateTime.utc(2026, 6, 1),
          refillAt: Value(DateTime.utc(2026, 8, 20)),
          refillReminderDays: const Value(3),
          form: const Value('capsule'),
          colorIndex: const Value(2),
          notes: const Value('饭后服用'),
        ),
      );
      final json = parseJson(await svc.exportToJson());
      final m = (json['medications'] as List)[0] as Map<String, dynamic>;
      expect(m['refillAt'], '2026-08-20T00:00:00.000Z');
      expect(m['refillReminderDays'], 3);
      expect(m['form'], 'capsule');
      expect(m['colorIndex'], 2);
      expect(m['notes'], '饭后服用');
    });

    test('2. import 后 5 字段全部保留 (换机不丢)', () async {
      await db.medicationDao.insert(
        MedicationsCompanion.insert(
          name: '文拉法辛',
          dosage: 75.0,
          dosageUnit: 'mg',
          startDate: DateTime.utc(2026, 6, 1),
          refillAt: Value(DateTime.utc(2026, 8, 20)),
          refillReminderDays: const Value(3),
          form: const Value('capsule'),
          colorIndex: const Value(2),
          notes: const Value('饭后服用'),
        ),
      );
      final exported = await svc.exportToJson();
      await db.delete(db.medications).go();
      final result = await svc.importFromJson(exported);
      expect(result.success, isTrue);
      expect(result.medicationCount, 1);
      final meds = await db.medicationDao.watchActive().first;
      expect(meds.length, 1);
      final m = meds.first;
      expect(m.refillAt, DateTime.utc(2026, 8, 20).toLocal());
      expect(m.refillReminderDays, 3);
      expect(m.form, 'capsule');
      expect(m.colorIndex, 2);
      expect(m.notes, '饭后服用');
    });
  });

  group('v0.32 round 8 (R111 E1) — mood v5 字段 round-trip', () {
    test('3. 导出含 5 个新字段, 不含 audioPath (vent 先例: stale 路径)', () async {
      await db.moodDao.insert(
        MoodEntriesCompanion.insert(
          timestamp: DateTime.utc(2026, 7, 1, 21, 0),
          score: 4,
          audioTranscript: const Value('今天心情不错'),
          audioDurationMs: const Value(65000),
          period: const Value('evening'),
          influenceFactorsJson: const Value('["work","family"]'),
          recordingMode: const Value('momentary'),
        ),
      );
      final json = parseJson(await svc.exportToJson());
      final m = (json['moodEntries'] as List)[0] as Map<String, dynamic>;
      expect(m['audioTranscript'], '今天心情不错');
      expect(m['audioDurationMs'], 65000);
      expect(m['period'], 'evening');
      expect(m['influenceFactorsJson'], '["work","family"]');
      expect(m['recordingMode'], 'momentary');
      expect(m.containsKey('audioPath'), isFalse);
    });

    test('4. import 后 5 字段保留, audioPath 为 null', () async {
      await db.moodDao.insert(
        MoodEntriesCompanion.insert(
          timestamp: DateTime.utc(2026, 7, 1, 21, 0),
          score: 4,
          audioTranscript: const Value('今天心情不错'),
          audioDurationMs: const Value(65000),
          period: const Value('evening'),
          influenceFactorsJson: const Value('["work","family"]'),
          recordingMode: const Value('momentary'),
        ),
      );
      final exported = await svc.exportToJson();
      await db.delete(db.moodEntries).go();
      final result = await svc.importFromJson(exported);
      expect(result.success, isTrue);
      expect(result.moodEntryCount, 1);
      final moods = await db.moodDao.getAll();
      expect(moods.length, 1);
      final m = moods.first;
      expect(m.audioTranscript, '今天心情不错');
      expect(m.audioDurationMs, 65000);
      expect(m.period, 'evening');
      expect(m.influenceFactorsJson, '["work","family"]');
      expect(m.recordingMode, 'momentary');
      expect(m.audioPath, isNull);
    });
  });

  group(
      'v1.1.0 round 3 (Task 6) — v6 无 contacts 段 (原 E2 contact round-trip 改造)',
      () {
    test('5. 导出不再含 contacts key (1.1.0 round 4b: 表已整删)', () async {
      final json = parseJson(await svc.exportToJson());
      expect(json.containsKey('contacts'), isFalse);

      final exported = await svc.exportToJson();
      final result = await svc.importFromJson(exported);
      expect(result.success, isTrue, reason: result.error);
      // v6 + round 4b: 导入器不引用 contacts (表已整删, 无清/写可言)
    });
  });

  group('v0.32 round 8 (R111 E3) — checkIn.medicationId 重映射', () {
    test('6. import 后 checkIn.medicationId 指向新插入的 med id (非孤儿 FK)', () async {
      final medId = await db.medicationDao.insert(
        MedicationsCompanion.insert(
          name: '舍曲林',
          dosage: 50.0,
          dosageUnit: 'mg',
          startDate: DateTime.utc(2026, 6, 1),
        ),
      );
      await db.checkInDao.insert(
        CheckInsCompanion.insert(
          timestamp: DateTime.utc(2026, 7, 1, 8, 5),
          type: 'normal',
          medicationId: Value(medId),
        ),
      );
      final exported = await svc.exportToJson();
      await db.delete(db.checkIns).go();
      await db.delete(db.medications).go();
      final result = await svc.importFromJson(exported);
      expect(result.success, isTrue);
      final meds = await db.medicationDao.watchActive().first;
      final checkIns = await db.checkInDao.watchAll().first;
      expect(meds.length, 1);
      expect(checkIns.length, 1);
      expect(checkIns.first.medicationId, meds.first.id);
    });

    test('7. checkIn 引用 inactive 药 → E8 起 inactive 也导出, import 后 FK 重映射到新 id',
        () async {
      final medId = await db.medicationDao.insert(
        MedicationsCompanion.insert(
          name: '已停用药',
          dosage: 10.0,
          dosageUnit: 'mg',
          startDate: DateTime.utc(2026, 6, 1),
          isActive: const Value(false),
        ),
      );
      await db.checkInDao.insert(
        CheckInsCompanion.insert(
          timestamp: DateTime.utc(2026, 7, 1, 8, 5),
          type: 'normal',
          medicationId: Value(medId),
        ),
      );
      final exported = await svc.exportToJson();
      await db.delete(db.checkIns).go();
      await db.delete(db.medications).go();
      final result = await svc.importFromJson(exported);
      expect(result.success, isTrue);
      // v0.32 round 8 (R112 E8 fix): 软停药也导出, 不再被 watchActive 过滤
      final meds = await db.medicationDao.watchAllIncludingInactive().first;
      expect(meds.length, 1);
      expect(meds.first.isActive, isFalse);
      final checkIns = await db.checkInDao.watchAll().first;
      expect(checkIns.length, 1);
      expect(checkIns.first.medicationId, meds.first.id);
    });
  });

  group('v0.32 round 8 (R112 E8) — 软停药整行导出不丢', () {
    test('8. inactive 药 round-trip: isActive=false + endDate 全字段保留', () async {
      await db.medicationDao.insert(
        MedicationsCompanion.insert(
          name: '奥氮平',
          dosage: 5.0,
          dosageUnit: 'mg',
          startDate: DateTime.utc(2026, 5, 1),
          endDate: Value(DateTime.utc(2026, 7, 31)),
          isActive: const Value(false),
          notes: const Value('已停'),
        ),
      );
      final json = parseJson(await svc.exportToJson());
      final meds = json['medications'] as List;
      expect(meds.length, 1);
      expect((meds[0] as Map)['name'], '奥氮平');
      expect((meds[0] as Map)['isActive'], isFalse);
      expect((meds[0] as Map)['endDate'], '2026-07-31T00:00:00.000Z');

      final exported = await svc.exportToJson();
      await db.delete(db.medications).go();
      final result = await svc.importFromJson(exported);
      expect(result.success, isTrue);
      final restored = await db.medicationDao.watchAllIncludingInactive().first;
      expect(restored.length, 1);
      expect(restored.first.name, '奥氮平');
      expect(restored.first.isActive, isFalse);
      expect(restored.first.endDate, DateTime.utc(2026, 7, 31).toLocal());
      expect(restored.first.notes, '已停');
    });
  });

  group('v0.32 round 8 (R112 E7) — profile PIPL §14 同意留痕 round-trip', () {
    test('9. 导出含 4 字段, import 后保留 (换机留痕不断)', () async {
      await db.userProfileDao.upsert(
        UserProfilesCompanion.insert(
          userName: const Value('测试'),
          checkInCycleHours: const Value(48),
          firstLaunchAt: DateTime.utc(2026, 8, 1),
          userAgreementVersion: const Value('v0.32-2026-08'),
          privacyPolicyVersion: const Value('v0.32-2026-08'),
          sensitiveDataConsentAt: Value(DateTime.utc(2026, 8, 1, 10, 0)),
          consentRevokedAt: Value(DateTime.utc(2026, 8, 5, 9, 0)),
        ),
      );
      final json = parseJson(await svc.exportToJson());
      final p = json['profile'] as Map<String, dynamic>;
      expect(p['userAgreementVersion'], 'v0.32-2026-08');
      expect(p['privacyPolicyVersion'], 'v0.32-2026-08');
      expect(p['sensitiveDataConsentAt'], '2026-08-01T10:00:00.000Z');
      expect(p['consentRevokedAt'], '2026-08-05T09:00:00.000Z');

      final exported = await svc.exportToJson();
      // import 全量替换: 先确认 DB 里 4 字段有旧值, import 后必须变成
      // 文件里的值 (write() 显式 SET, 非 upsert 忽略 null)。
      final result = await svc.importFromJson(exported);
      expect(result.success, isTrue);
      final restored = await db.userProfileDao.get();
      expect(restored!.userAgreementVersion, 'v0.32-2026-08');
      expect(restored.privacyPolicyVersion, 'v0.32-2026-08');
      expect(
        restored.sensitiveDataConsentAt,
        DateTime.utc(2026, 8, 1, 10, 0).toLocal(),
      );
      expect(
        restored.consentRevokedAt,
        DateTime.utc(2026, 8, 5, 9, 0).toLocal(),
      );
    });

    test('10. 老 v4 文件无 consent 4 字段 → 导入后 null (优雅降级)', () async {
      await db.userProfileDao.upsert(
        UserProfilesCompanion.insert(
          userName: const Value('测试'),
          checkInCycleHours: const Value(48),
          firstLaunchAt: DateTime.utc(2026, 8, 1),
          userAgreementVersion: const Value('v0.32-2026-08'),
          sensitiveDataConsentAt: Value(DateTime.utc(2026, 8, 1, 10, 0)),
        ),
      );
      final legacyJson = jsonEncode({
        'version': 5,
        'exportedAt': '2026-08-13T00:00:00.000Z',
        'profile': {
          'userName': '测试',
          'checkInCycleHours': 48,
          'firstLaunchAt': '2026-08-01T00:00:00.000Z',
        },
      });
      final result = await svc.importFromJson(legacyJson);
      expect(result.success, isTrue, reason: result.error);
      final p = await db.userProfileDao.get();
      expect(p!.userAgreementVersion, isNull);
      expect(p.privacyPolicyVersion, isNull);
      expect(p.sensitiveDataConsentAt, isNull);
      expect(p.consentRevokedAt, isNull);
    });
  });

  group('v0.32 round 8 (R112-05) — isActive 脏数据容错 (不崩导入)', () {
    test('11. v4 脏数据 isActive (int 1 / string "true") → 降级为 true', () async {
      final dirtyJson = jsonEncode({
        'version': 5,
        'exportedAt': '2026-08-13T00:00:00.000Z',
        'profile': {
          'userName': '测试',
          'checkInCycleHours': 48,
          'firstLaunchAt': '2026-08-01T00:00:00.000Z',
        },
        'contacts': [
          {'name': '姐', 'phone': '13800138003', 'sortOrder': 0, 'isActive': 1},
        ],
        'medications': [
          {
            'name': '药',
            'dosage': 1.0,
            'dosageUnit': 'mg',
            'timesJson': '[]',
            'startDate': '2026-08-01T00:00:00.000Z',
            'isActive': 'true',
          },
        ],
      });
      final result = await svc.importFromJson(dirtyJson);
      expect(result.success, isTrue, reason: result.error);
      // v6 + round 4b: fixture 的 contacts key 被忽略 (表已整删, 不再导入)
      final meds = await db.medicationDao.watchActive().first;
      expect(meds.length, 1);
      expect(meds.first.isActive, isTrue);
    });
  });

  group('v0.32 round 8 (R112-06) — lastCheckInAt 导入', () {
    test('12. 已导出 lastCheckInAt, import 后恢复 (P0-10 注释意图补完)', () async {
      await db.userProfileDao.upsert(
        UserProfilesCompanion.insert(
          userName: const Value('测试'),
          checkInCycleHours: const Value(48),
          firstLaunchAt: DateTime.utc(2026, 8, 1),
          lastCheckInAt: Value(DateTime.utc(2026, 8, 12, 20, 30)),
        ),
      );
      final json = parseJson(await svc.exportToJson());
      final p = json['profile'] as Map<String, dynamic>;
      expect(p['lastCheckInAt'], '2026-08-12T20:30:00.000Z');

      final exported = await svc.exportToJson();
      // import 全量替换 (write()): 若 import 不读 lastCheckInAt 会显式
      // SET NULL, 断言必挂 — 真正验证 P0-10 意图。
      final result = await svc.importFromJson(exported);
      expect(result.success, isTrue);
      final restored = await db.userProfileDao.get();
      expect(
        restored!.lastCheckInAt,
        DateTime.utc(2026, 8, 12, 20, 30).toLocal(),
      );
    });
  });
}
