// R114 Wave B2: import_entities 拆分 — importDailyTracking 独立 seam (B2-7)
//
// 02-code F-02: import_entities.dart 664L 真 god class, R113 wave 5 预留的
// 拆分 seam (_importDailyTracking 私有函数) 正式拆到独立文件
// import_daily_tracking.dart (6 张 daily tracking 表段), import_entities
// 保留 medications / checkIns / reportHistories / moodEntries / worryThreads。
//
// PURE MOVE: 行为不变 (round-trip 测试兜底), 本测试直接调用新公共函数
// 验证 6 表段导入 + old→new FK 重映射 (medIdMap / moodIdMap)。

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/services/export/import_daily_tracking.dart';
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

  test('importDailyTracking: 6 表段导入 + medIdMap/moodIdMap 重映射', () async {
    final newMedId = await db.medicationDao.insert(
      MedicationsCompanion.insert(
        name: '药',
        dosage: 1,
        dosageUnit: 'mg',
        timesJson: const Value('[]'),
        startDate: DateTime.utc(2026, 1, 1),
      ),
    );
    final newMoodId = await db.moodDao.insert(
      MoodEntriesCompanion.insert(
        timestamp: DateTime.utc(2026, 8, 1, 9),
        score: 3,
      ),
    );

    await importDailyTracking(
      db,
      {
        'sleepEntries': [
          {
            'date': '2026-08-10T00:00:00.000Z',
            'bedtime': '2026-08-10T23:00:00.000Z',
            'wakeTime': '2026-08-11T07:00:00.000Z',
            'durationMin': 480,
            'regularityScore': 4,
            'note': 'sleep-note',
          },
        ],
        'socialRhythmEntries': [
          {
            'date': '2026-08-10T00:00:00.000Z',
            'wakeTime': '2026-08-10T08:00:00.000Z',
            'firstMealTime': '2026-08-10T08:30:00.000Z',
            'lastMealTime': '2026-08-10T19:00:00.000Z',
            'socialMin': 60,
            'workMin': 300,
            'exerciseMin': 20,
          },
        ],
        'stressEvents': [
          {
            'timestamp': '2026-08-10T12:00:00.000Z',
            'eventType': 'work',
            'intensity': 4,
            'note': 'stress-note',
            'linkedMoodEntryId': 999, // 老 mood id → newMoodId
          },
        ],
        'treatmentEntries': [
          {
            'timestamp': '2026-08-10T12:00:00.000Z',
            'treatmentType': 'drug',
            'description': '服药',
            'linkedMedicationId': 777, // 老 med id → newMedId
            'linkedMedicationName': '药',
            'note': 'treatment-note',
          },
        ],
        'weightEntries': [
          {
            'timestamp': '2026-08-10T08:00:00.000Z',
            'weightKg': 65.5,
            'bmi': 22.1,
            'note': 'weight-note',
          },
        ],
        'anxietyAgitationEntries': [
          {
            'timestamp': '2026-08-10T18:00:00.000Z',
            'anxietyScore': 3,
            'agitationScore': 2,
            'note': 'anxiety-note',
          },
        ],
      },
      {777: newMedId},
      {999: newMoodId},
    );

    final sleeps = await db.sleepDao.watchAll().first;
    expect(sleeps.length, 1);
    expect(sleeps.first.durationMin, 480);
    expect(sleeps.first.regularityScore, 4);

    final socials = await db.socialRhythmDao.watchAll().first;
    expect(socials.length, 1);
    expect(socials.first.socialMin, 60);

    final stresses = await db.stressEventDao.watchAll().first;
    expect(stresses.length, 1);
    expect(
      stresses.first.linkedMoodEntryId,
      newMoodId,
      reason: 'stress.linkedMoodEntryId 应重映射 old→new',
    );

    final treatments = await db.treatmentDao.watchAll().first;
    expect(treatments.length, 1);
    expect(
      treatments.first.linkedMedicationId,
      newMedId,
      reason: 'treatment.linkedMedicationId 应重映射 old→new',
    );

    final weights = await db.weightDao.watchAll().first;
    expect(weights.length, 1);
    expect(weights.first.weightKg, 65.5);

    final anxieties = await db.anxietyAgitationDao.watchAll().first;
    expect(anxieties.length, 1);
    expect(anxieties.first.anxietyScore, 3);
  });

  test('importDailyTracking: 老文件 (无 6 段) → 空列表, 0 行 (天然兼容)', () async {
    await importDailyTracking(db, const {}, const {}, const {});

    expect(await db.sleepDao.watchAll().first, isEmpty);
    expect(await db.socialRhythmDao.watchAll().first, isEmpty);
    expect(await db.stressEventDao.watchAll().first, isEmpty);
    expect(await db.treatmentDao.watchAll().first, isEmpty);
    expect(await db.weightDao.watchAll().first, isEmpty);
    expect(await db.anxietyAgitationDao.watchAll().first, isEmpty);
  });
}
