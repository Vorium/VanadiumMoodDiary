// 6 张 daily tracking 表段导入 — R114 Wave B2 (B2-7, 02-code F-02)
//
// 从 import_entities.dart 拆出 (R113 wave 5 预留的 seam — 私有
// _importDailyTracking 升为公共函数独立文件), import_entities 保留
// medications / checkIns / reportHistories / moodEntries / worryThreads。
//
// PURE MOVE: 函数体逐行不变。medIdMap / moodIdMap 两个 old→new 映射由
// importEntities 传入, 在本函数内只读 (treatment.linkedMedicationId /
// stress.linkedMoodEntryId 重映射)。
//
// 6 表 (DB schema 22, R91):
//   sleepEntries / socialRhythmEntries / stressEvents /
//   treatmentEntries / weightEntries / anxietyAgitationEntries
//
// v0.32 round 8 (R112 E6 fix): 之前完全缺这 6 段 → 换机整块静默丢失。
// 字段校验走既有 validate 模式, 老 v4 文件无这些 key → 空列表, 天然兼容。
//
// 兜底测试: data_export_v5_daily_tracking_round8 / export_import_pipeline_round99
// / import_daily_tracking_round114 (直接调用本函数)。

import 'package:drift/drift.dart' show Value;

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/services/export/export_schema_service.dart';

/// 子任务 3b/4: 6 张 daily tracking 表 (R91)
///
/// [medIdMap] (medications old→new) 供 treatment.linkedMedicationId 重映射;
/// [moodIdMap] (mood old→new) 供 stress.linkedMoodEntryId 重映射。
/// 引用不在 export (对应段缺失/被过滤) → null, 不导入孤儿 FK。
Future<void> importDailyTracking(
  AppDatabase db,
  Map<String, dynamic> data,
  Map<int, int> medIdMap,
  Map<int, int> moodIdMap,
) async {
  // sleep_entries (1 天 1 条)
  for (final s in (data['sleepEntries'] as List? ?? [])) {
    if (s is! Map) continue;
    final m = s;
    final date = ExportSchemaService.validateDate(m['date']);
    final bedtime = ExportSchemaService.validateDate(m['bedtime']);
    final wakeTime = ExportSchemaService.validateDate(m['wakeTime']);
    if (date == null || bedtime == null || wakeTime == null) continue;
    await db.sleepDao.insert(
      SleepEntriesCompanion.insert(
        date: date,
        bedtime: bedtime,
        wakeTime: wakeTime,
        durationMin: ExportSchemaService.validateIntOr(
          m['durationMin'],
          0,
          min: 0,
          max: 1440,
        ),
        regularityScore: Value(
          ExportSchemaService.validateInt(
            m['regularityScore'],
            null,
            min: 1,
            max: 5,
          ),
        ),
        note: Value(
          ExportSchemaService.validateString(
            m['note'],
            'sleep.note',
            maxLen: 10000,
          ),
        ),
      ),
    );
  }

  // social_rhythm_entries (1 天 1 条)
  for (final s in (data['socialRhythmEntries'] as List? ?? [])) {
    if (s is! Map) continue;
    final m = s;
    final date = ExportSchemaService.validateDate(m['date']);
    final wakeTime = ExportSchemaService.validateDate(m['wakeTime']);
    final firstMealTime = ExportSchemaService.validateDate(m['firstMealTime']);
    final lastMealTime = ExportSchemaService.validateDate(m['lastMealTime']);
    if (date == null ||
        wakeTime == null ||
        firstMealTime == null ||
        lastMealTime == null) {
      continue;
    }
    await db.socialRhythmDao.insert(
      SocialRhythmEntriesCompanion.insert(
        date: date,
        wakeTime: wakeTime,
        firstMealTime: firstMealTime,
        lastMealTime: lastMealTime,
        socialMin: Value(
          ExportSchemaService.validateIntOr(
            m['socialMin'],
            0,
            min: 0,
            max: 1440,
          ),
        ),
        workMin: Value(
          ExportSchemaService.validateIntOr(
            m['workMin'],
            0,
            min: 0,
            max: 1440,
          ),
        ),
        exerciseMin: Value(
          ExportSchemaService.validateIntOr(
            m['exerciseMin'],
            0,
            min: 0,
            max: 1440,
          ),
        ),
      ),
    );
  }

  // stress_events (1 次事件 1 条)
  for (final s in (data['stressEvents'] as List? ?? [])) {
    if (s is! Map) continue;
    final m = s;
    final ts = ExportSchemaService.validateDate(m['timestamp']);
    final eventType = ExportSchemaService.validateString(
      m['eventType'],
      'stress.eventType',
      maxLen: 20,
    );
    if (ts == null || eventType == null) continue;
    final oldMoodId = ExportSchemaService.validateInt(
      m['linkedMoodEntryId'],
      null,
    );
    await db.stressEventDao.insert(
      StressEventsCompanion.insert(
        timestamp: ts,
        eventType: eventType,
        intensity: ExportSchemaService.validateIntOr(
          m['intensity'],
          3,
          min: 1,
          max: 5,
        ),
        note: Value(
          ExportSchemaService.validateString(
            m['note'],
            'stress.note',
            maxLen: 10000,
          ),
        ),
        // E3 同款重映射: 引用的 mood 不在 export → null, 不导入孤儿 FK
        linkedMoodEntryId: Value(
          oldMoodId == null ? null : moodIdMap[oldMoodId],
        ),
      ),
    );
  }

  // treatment_entries (1 次治疗 1 条)
  for (final t in (data['treatmentEntries'] as List? ?? [])) {
    if (t is! Map) continue;
    final m = t;
    final ts = ExportSchemaService.validateDate(m['timestamp']);
    final treatmentType = ExportSchemaService.validateString(
      m['treatmentType'],
      'treatment.type',
      maxLen: 20,
    );
    final description = ExportSchemaService.validateString(
      m['description'],
      'treatment.desc',
      maxLen: 10000,
    );
    if (ts == null || treatmentType == null || description == null) {
      continue;
    }
    final oldMedId = ExportSchemaService.validateInt(
      m['linkedMedicationId'],
      null,
    );
    await db.treatmentDao.insert(
      TreatmentEntriesCompanion.insert(
        timestamp: ts,
        treatmentType: treatmentType,
        description: description,
        linkedMedicationId: Value(
          oldMedId == null ? null : medIdMap[oldMedId],
        ),
        // snapshot 缓存原样保留 (换机后 medication rename 不会漂移历史)
        linkedMedicationName: Value(
          ExportSchemaService.validateString(
            m['linkedMedicationName'],
            'treatment.medName',
            maxLen: 50,
          ),
        ),
        note: Value(
          ExportSchemaService.validateString(
            m['note'],
            'treatment.note',
            maxLen: 10000,
          ),
        ),
      ),
    );
  }

  // weight_entries (1 天可多次)
  for (final w in (data['weightEntries'] as List? ?? [])) {
    if (w is! Map) continue;
    final m = w;
    final ts = ExportSchemaService.validateDate(m['timestamp']);
    final weightKg = ExportSchemaService.validateDouble(m['weightKg']);
    if (ts == null || weightKg == null) continue;
    await db.weightDao.insert(
      WeightEntriesCompanion.insert(
        timestamp: ts,
        weightKg: weightKg,
        bmi: Value(ExportSchemaService.validateDouble(m['bmi'])),
        note: Value(
          ExportSchemaService.validateString(
            m['note'],
            'weight.note',
            maxLen: 10000,
          ),
        ),
      ),
    );
  }

  // anxiety_agitation_entries (1 个时间点 1 条)
  for (final a in (data['anxietyAgitationEntries'] as List? ?? [])) {
    if (a is! Map) continue;
    final m = a;
    final ts = ExportSchemaService.validateDate(m['timestamp']);
    final anxietyScore = ExportSchemaService.validateInt(
      m['anxietyScore'],
      null,
      min: 1,
      max: 5,
    );
    final agitationScore = ExportSchemaService.validateInt(
      m['agitationScore'],
      null,
      min: 1,
      max: 5,
    );
    if (ts == null || anxietyScore == null || agitationScore == null) {
      continue;
    }
    await db.anxietyAgitationDao.insert(
      AnxietyAgitationEntriesCompanion.insert(
        timestamp: ts,
        anxietyScore: anxietyScore,
        agitationScore: agitationScore,
        note: Value(
          ExportSchemaService.validateString(
            m['note'],
            'anxiety.note',
            maxLen: 10000,
          ),
        ),
      ),
    );
  }
}
