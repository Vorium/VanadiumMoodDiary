// v0.32 round 8 (R112 E6 fix): export v5 补 6 张 daily tracking 表
//
// 背景 (R112 审计发现, docs/audit/2026-08-13-r112-multi-lens/):
// - E6 (P0, ~1d): export v5 仍完全缺 6 张 daily tracking 表 (R91 功能,
//   DB schema 22) — sleep_entries / social_rhythm_entries / stress_events /
//   treatment_entries / weight_entries / anxiety_agitation_entries。
//   R111 E1 只对 medications/mood/contacts 逐字段对照, 漏了整表对照。
//   用户换机/重装后这 6 块数据整块静默丢失, import 也不 clear 这 6 表
//   (残留旧设备数据)。
//
// 修法: export 加 6 段 + import 加 6 段 (先 clear 再插入)。外键跟 E3
// checkIn.medicationId 同款重映射:
// - treatment.linkedMedicationId → medIdMap (E3 已有)
// - stress.linkedMoodEntryId → moodIdMap (mood export 加 'id', 本批新)
//
// 本文件 6 case: RED 阶段全 fail, GREEN 后全过。
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

  test(
      '1. sleep_entries round-trip (date/bedtime/wakeTime/durationMin/'
      'regularityScore/note)', () async {
    await db.sleepDao.insert(
      SleepEntriesCompanion.insert(
        date: DateTime.utc(2026, 8, 10),
        bedtime: DateTime.utc(2026, 8, 10, 23, 30),
        wakeTime: DateTime.utc(2026, 8, 11, 7, 10),
        durationMin: 460,
        regularityScore: const Value(4),
        note: const Value('睡得不错'),
      ),
    );
    final json = parseJson(await svc.exportToJson());
    final list = json['sleepEntries'] as List;
    expect(list.length, 1);
    final s = list[0] as Map<String, dynamic>;
    expect(s['date'], '2026-08-10T00:00:00.000Z');
    expect(s['bedtime'], '2026-08-10T23:30:00.000Z');
    expect(s['wakeTime'], '2026-08-11T07:10:00.000Z');
    expect(s['durationMin'], 460);
    expect(s['regularityScore'], 4);
    expect(s['note'], '睡得不错');

    final exported = await svc.exportToJson();
    await db.delete(db.sleepEntries).go();
    final result = await svc.importFromJson(exported);
    expect(result.success, isTrue, reason: result.error);
    final rows = await db.sleepDao.watchAll().first;
    expect(rows.length, 1);
    final r = rows.first;
    expect(r.date, DateTime.utc(2026, 8, 10).toLocal());
    expect(r.bedtime, DateTime.utc(2026, 8, 10, 23, 30).toLocal());
    expect(r.wakeTime, DateTime.utc(2026, 8, 11, 7, 10).toLocal());
    expect(r.durationMin, 460);
    expect(r.regularityScore, 4);
    expect(r.note, '睡得不错');
  });

  test('2. social_rhythm_entries round-trip (3 餐 + 3 时长)', () async {
    await db.socialRhythmDao.insert(
      SocialRhythmEntriesCompanion.insert(
        date: DateTime.utc(2026, 8, 10),
        wakeTime: DateTime.utc(2026, 8, 10, 7, 30),
        firstMealTime: DateTime.utc(2026, 8, 10, 8, 0),
        lastMealTime: DateTime.utc(2026, 8, 10, 19, 0),
        socialMin: const Value(120),
        workMin: const Value(480),
        exerciseMin: const Value(30),
      ),
    );
    final json = parseJson(await svc.exportToJson());
    final list = json['socialRhythmEntries'] as List;
    expect(list.length, 1);
    final s = list[0] as Map<String, dynamic>;
    expect(s['date'], '2026-08-10T00:00:00.000Z');
    expect(s['wakeTime'], '2026-08-10T07:30:00.000Z');
    expect(s['firstMealTime'], '2026-08-10T08:00:00.000Z');
    expect(s['lastMealTime'], '2026-08-10T19:00:00.000Z');
    expect(s['socialMin'], 120);
    expect(s['workMin'], 480);
    expect(s['exerciseMin'], 30);

    final exported = await svc.exportToJson();
    await db.delete(db.socialRhythmEntries).go();
    final result = await svc.importFromJson(exported);
    expect(result.success, isTrue, reason: result.error);
    final rows = await db.socialRhythmDao.watchAll().first;
    expect(rows.length, 1);
    final r = rows.first;
    expect(r.date, DateTime.utc(2026, 8, 10).toLocal());
    expect(r.wakeTime, DateTime.utc(2026, 8, 10, 7, 30).toLocal());
    expect(r.firstMealTime, DateTime.utc(2026, 8, 10, 8, 0).toLocal());
    expect(r.lastMealTime, DateTime.utc(2026, 8, 10, 19, 0).toLocal());
    expect(r.socialMin, 120);
    expect(r.workMin, 480);
    expect(r.exerciseMin, 30);
  });

  test('3. stress_events round-trip + linkedMoodEntryId 重映射 (非孤儿 FK)',
      () async {
    final moodId = await db.moodDao.insert(
      MoodEntriesCompanion.insert(
        timestamp: DateTime.utc(2026, 7, 1, 21, 0),
        score: 3,
      ),
    );
    await db.stressEventDao.insert(
      StressEventsCompanion.insert(
        timestamp: DateTime.utc(2026, 7, 1, 22, 0),
        eventType: 'work',
        intensity: 4,
        note: const Value('加班到深夜'),
        linkedMoodEntryId: Value(moodId),
      ),
    );
    final json = parseJson(await svc.exportToJson());
    final list = json['stressEvents'] as List;
    expect(list.length, 1);
    final s = list[0] as Map<String, dynamic>;
    expect(s['timestamp'], '2026-07-01T22:00:00.000Z');
    expect(s['eventType'], 'work');
    expect(s['intensity'], 4);
    expect(s['note'], '加班到深夜');
    expect(s['linkedMoodEntryId'], moodId);
    // mood 也要导出 id 供重映射
    expect(((json['moodEntries'] as List)[0] as Map)['id'], moodId);

    final exported = await svc.exportToJson();
    await db.delete(db.stressEvents).go();
    await db.delete(db.moodEntries).go();
    final result = await svc.importFromJson(exported);
    expect(result.success, isTrue, reason: result.error);
    final moods = await db.moodDao.getAll();
    expect(moods.length, 1);
    final rows = await db.stressEventDao.watchAll().first;
    expect(rows.length, 1);
    final r = rows.first;
    expect(r.timestamp, DateTime.utc(2026, 7, 1, 22, 0).toLocal());
    expect(r.eventType, 'work');
    expect(r.intensity, 4);
    expect(r.note, '加班到深夜');
    expect(r.linkedMoodEntryId, moods.first.id);
  });

  test('4. treatment_entries round-trip + linkedMedicationId 重映射', () async {
    final medId = await db.medicationDao.insert(
      MedicationsCompanion.insert(
        name: '舍曲林',
        dosage: 50.0,
        dosageUnit: 'mg',
        startDate: DateTime.utc(2026, 6, 1),
      ),
    );
    await db.treatmentDao.insert(
      TreatmentEntriesCompanion.insert(
        timestamp: DateTime.utc(2026, 7, 2, 9, 0),
        treatmentType: 'consultation',
        description: '心理咨询',
        linkedMedicationId: Value(medId),
        linkedMedicationName: const Value('舍曲林'),
        note: const Value('感觉不错'),
      ),
    );
    final json = parseJson(await svc.exportToJson());
    final list = json['treatmentEntries'] as List;
    expect(list.length, 1);
    final t = list[0] as Map<String, dynamic>;
    expect(t['timestamp'], '2026-07-02T09:00:00.000Z');
    expect(t['treatmentType'], 'consultation');
    expect(t['description'], '心理咨询');
    expect(t['linkedMedicationId'], medId);
    expect(t['linkedMedicationName'], '舍曲林');
    expect(t['note'], '感觉不错');

    final exported = await svc.exportToJson();
    await db.delete(db.treatmentEntries).go();
    await db.delete(db.medications).go();
    final result = await svc.importFromJson(exported);
    expect(result.success, isTrue, reason: result.error);
    final meds = await db.medicationDao.watchAllIncludingInactive().first;
    expect(meds.length, 1);
    final rows = await db.treatmentDao.watchAll().first;
    expect(rows.length, 1);
    final r = rows.first;
    expect(r.timestamp, DateTime.utc(2026, 7, 2, 9, 0).toLocal());
    expect(r.treatmentType, 'consultation');
    expect(r.description, '心理咨询');
    expect(r.linkedMedicationId, meds.first.id);
    expect(r.linkedMedicationName, '舍曲林');
    expect(r.note, '感觉不错');
  });

  test('5. weight_entries round-trip (weightKg/bmi/note)', () async {
    await db.weightDao.insert(
      WeightEntriesCompanion.insert(
        timestamp: DateTime.utc(2026, 7, 3, 8, 0),
        weightKg: 65.5,
        bmi: const Value(22.3),
        note: const Value('早上空腹'),
      ),
    );
    final json = parseJson(await svc.exportToJson());
    final list = json['weightEntries'] as List;
    expect(list.length, 1);
    final w = list[0] as Map<String, dynamic>;
    expect(w['timestamp'], '2026-07-03T08:00:00.000Z');
    expect(w['weightKg'], 65.5);
    expect(w['bmi'], closeTo(22.3, 0.001));
    expect(w['note'], '早上空腹');

    final exported = await svc.exportToJson();
    await db.delete(db.weightEntries).go();
    final result = await svc.importFromJson(exported);
    expect(result.success, isTrue, reason: result.error);
    final rows = await db.weightDao.watchAll().first;
    expect(rows.length, 1);
    final r = rows.first;
    expect(r.timestamp, DateTime.utc(2026, 7, 3, 8, 0).toLocal());
    expect(r.weightKg, closeTo(65.5, 0.001));
    expect(r.bmi, closeTo(22.3, 0.001));
    expect(r.note, '早上空腹');
  });

  test('6. anxiety_agitation_entries round-trip (anxiety/agitation/note)',
      () async {
    await db.anxietyAgitationDao.insert(
      AnxietyAgitationEntriesCompanion.insert(
        timestamp: DateTime.utc(2026, 7, 4, 10, 0),
        anxietyScore: 4,
        agitationScore: 2,
        note: const Value('有点急'),
      ),
    );
    final json = parseJson(await svc.exportToJson());
    final list = json['anxietyAgitationEntries'] as List;
    expect(list.length, 1);
    final a = list[0] as Map<String, dynamic>;
    expect(a['timestamp'], '2026-07-04T10:00:00.000Z');
    expect(a['anxietyScore'], 4);
    expect(a['agitationScore'], 2);
    expect(a['note'], '有点急');

    final exported = await svc.exportToJson();
    await db.delete(db.anxietyAgitationEntries).go();
    final result = await svc.importFromJson(exported);
    expect(result.success, isTrue, reason: result.error);
    final rows = await db.anxietyAgitationDao.watchAll().first;
    expect(rows.length, 1);
    final r = rows.first;
    expect(r.timestamp, DateTime.utc(2026, 7, 4, 10, 0).toLocal());
    expect(r.anxietyScore, 4);
    expect(r.agitationScore, 2);
    expect(r.note, '有点急');
  });
}
