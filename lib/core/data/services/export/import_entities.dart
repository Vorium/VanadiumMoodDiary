// 实体簇导入 — v1.1.0 R113 wave 5 (gdc P1-7 god class 拆分)
//
// 从 export_import_pipeline.dart 抽出 (R77/R112-ARCH-03 的 4 子任务之一
// _importEntities), 按 R113 gdc 审计建议按实体簇拆 3 文件之一:
//   - import_entities.dart (本文件): medications / checkIns / reportHistories /
//     moodEntries / worryThreads
//   - import_daily_tracking.dart: 6 张 daily tracking 表 (R91)
//     — R114 Wave B2 (B2-7) 从本文件拆出的独立 seam
//   - import_profile.dart: user profile (全局单条)
//   - import_vent.dart: vent entries
//   - import_shared.dart: ImportResultBuilder 共享聚合器
//
// PURE MOVE: 函数体逐行不变 (medIdMap / moodIdMap / worryIdMap 三个
// old→new 映射仍在本文件内闭环), 仅 6 张 daily tracking 表段整体下沉
// 到 import_daily_tracking.dart (R112 审计建议的第 5 子函数, 行为不变)。
// 兜底测试: data_export_v7_worry_round9 / data_export_v5_round8 /
// data_export_v5_daily_tracking_round8 / export_import_pipeline_round99 等。

import 'package:drift/drift.dart' show Value;

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/services/export/export_schema_service.dart';
import 'package:chroniccare/core/data/services/export/import_daily_tracking.dart';
import 'package:chroniccare/core/data/services/export/import_shared.dart';
import 'package:chroniccare/domain/repositories/report_history_repository.dart';

/// 子任务 3/4: medications / checkIns / reportHistories /
/// moodEntries / worryThreads (+ 委托 importDailyTracking 6 表)
///
/// medIdMap (medications old→new) 供 checkIns.medicationId 和
/// treatment.linkedMedicationId 重映射; moodIdMap (mood old→new) 供
/// stress.linkedMoodEntryId 重映射 — 两个映射在本函数内闭环, 不跨子任务。
Future<void> importEntities(
  AppDatabase db,
  ReportHistoryRepository reportRepo,
  Map<String, dynamic> data,
  int version,
  ImportResultBuilder counts,
) async {
  // medications
  //
  // v0.32 round 8 (R111 E3 fix): 建 old→new id 映射, 供 checkIns 段
  // 的 medicationId 重映射。老 v4 文件无 'id' → 无映射 → 老文件
  // checkIn.medicationId 导入后为 null (旧 id 跨设备无意义, 且是孤儿 FK)。
  final medIdMap = <int, int>{};
  // v0.32 round 8 (R112 E6 fix): mood old→new id 映射, 供 stressEvents
  // 段 linkedMoodEntryId 重映射 (跟 medIdMap 同款修孤儿 FK)。
  final moodIdMap = <int, int>{};
  // v1.1.0 round 9 (F1 烦恼闭环): worry old→new id 映射, 供 moodEntries 段
  // worryThreadId 重映射 (跟 medIdMap 同款; 老 v6 文件无 worryThreads 段
  // → mood.worryThreadId 无映射 → 导入后 null)
  final worryIdMap = <int, int>{};
  for (final w in (data['worryThreads'] as List? ?? [])) {
    if (w is! Map) continue;
    final title = ExportSchemaService.validateString(
      w['title'],
      'worry.title',
      maxLen: 100,
    );
    final createdAt = ExportSchemaService.validateDate(w['createdAt']);
    final status = ExportSchemaService.validateString(
      w['status'],
      'worry.status',
      maxLen: 20,
    );
    if (title == null || createdAt == null) continue;
    final newWorryId = await db.worryDao.insert(
      title: title,
      createdAt: createdAt,
    );
    if (status == 'resolved') {
      final resolvedAt = ExportSchemaService.validateDate(w['resolvedAt']);
      await db.worryDao.resolve(
        newWorryId,
        resolvedAt: resolvedAt ?? createdAt,
      );
    }
    final oldId = w['id'];
    if (oldId is int) worryIdMap[oldId] = newWorryId;
  }
  for (final med in (data['medications'] as List? ?? [])) {
    if (med is! Map) continue;
    final m = med;
    final name = ExportSchemaService.validateString(
      m['name'],
      'med.name',
      maxLen: 50,
    );
    final unit = ExportSchemaService.validateString(
      m['dosageUnit'],
      'med.unit',
      maxLen: 10,
    );
    final dosage = ExportSchemaService.validateDouble(m['dosage']);
    final start = ExportSchemaService.validateDate(m['startDate']);
    if (name == null || unit == null || dosage == null || start == null) {
      continue;
    }
    final newMedId = await db.medicationDao.insert(
      MedicationsCompanion.insert(
        name: name,
        dosage: dosage,
        dosageUnit: unit,
        timesJson: Value(
          ExportSchemaService.validateString(
                m['timesJson'],
                'med.timesJson',
                maxLen: 1000,
              ) ??
              '[]',
        ),
        startDate: start,
        endDate: Value(ExportSchemaService.validateDate(m['endDate'])),
        // v0.32 round 8 (R112-05 fix): 跟 contact isActive 同款脏数据容错。
        isActive: Value(m['isActive'] is bool ? m['isActive'] as bool : true),
        // v0.32 round 8 (R111 E1 fix): 续方 / 剂型 / 颜色 / 备注
        refillAt: Value(
          ExportSchemaService.validateDate(m['refillAt']),
        ),
        // v1.1.0 R113 (BUG 1): <1 显式 clamp 到 1 — validateIntOr 保持
        // min:0 接脏数据 (不整条丢弃), 再 clamp 防止 0 天进 DB 后让
        // computeRefillFireTime 拿 <1 (旧行为抛 ArgumentError → 全部
        // 续方提醒静默 abort)。clamp 而非回退 default 7: 保留用户
        // "续方当天提醒"意图。
        refillReminderDays: Value(
          () {
            final days = ExportSchemaService.validateIntOr(
              m['refillReminderDays'],
              7,
              min: 0,
              max: 90,
            );
            return days < 1 ? 1 : days;
          }(),
        ),
        form: Value(
          ExportSchemaService.validateString(
                m['form'],
                'med.form',
                maxLen: 20,
              ) ??
              'tablet',
        ),
        colorIndex: Value(
          ExportSchemaService.validateIntOr(
            m['colorIndex'],
            0,
            min: 0,
            max: 5,
          ),
        ),
        notes: Value(
          ExportSchemaService.validateString(
            m['notes'],
            'med.notes',
            maxLen: 1000,
          ),
        ),
      ),
    );
    final oldMedId = ExportSchemaService.validateInt(m['id'], null);
    if (oldMedId != null) {
      medIdMap[oldMedId] = newMedId;
    }
    counts.medicationCount++;
  }

  // checkIns
  for (final c in (data['checkIns'] as List? ?? [])) {
    if (c is! Map) continue;
    final m = c;
    final ts = ExportSchemaService.validateDate(m['timestamp']);
    final type = ExportSchemaService.validateString(
      m['type'],
      'checkIn.type',
      maxLen: 20,
    );
    if (ts == null || type == null) continue;
    // v0.32 round 8 (R111 E3 fix): medicationId 走 old→new 映射。
    // 引用的 med 不在 export (被删/inactive 被过滤) → null,
    // 不再导入孤儿 FK。
    final oldMedId = ExportSchemaService.validateInt(
      m['medicationId'],
      null,
    );
    await db.checkInDao.insert(
      CheckInsCompanion.insert(
        timestamp: ts,
        type: type,
        medicationId: Value(
          oldMedId == null ? null : medIdMap[oldMedId],
        ),
        note: Value(
          ExportSchemaService.validateString(
            m['note'],
            'checkIn.note',
            maxLen: 10000,
          ),
        ),
      ),
    );
    counts.checkInCount++;
  }

  // reportHistories (v2 才有, v1 没有这段也兼容)
  if (version >= 2) {
    for (final h in (data['reportHistories'] as List? ?? [])) {
      if (h is! Map) continue;
      final m = h;
      final days = ExportSchemaService.validateInt(
        m['windowDays'],
        null,
        min: 1,
        max: 365,
      );
      final at = ExportSchemaService.validateDate(m['generatedAt']);
      final userName = ExportSchemaService.validateString(
            m['userName'],
            'report.userName',
            maxLen: 50,
          ) ??
          '';
      final text = ExportSchemaService.validateString(
        m['reportText'],
        'report.text',
        maxLen: 100000,
      );
      if (days == null || at == null || text == null) continue;
      await reportRepo.insert(
        windowDays: days,
        generatedAt: at,
        userName: userName,
        reportText: text,
      );
      counts.reportHistoryCount++;
    }

    for (final me in (data['moodEntries'] as List? ?? [])) {
      if (me is! Map) continue;
      final m = me;
      final ts = ExportSchemaService.validateDate(m['timestamp']);
      final score = ExportSchemaService.validateIntOr(
        m['score'],
        3,
        min: 1,
        max: 5,
      );
      if (ts == null) continue;
      final tags = ExportSchemaService.validateString(
            m['tagsJson'],
            'mood.tags',
            maxLen: 5000,
          ) ??
          '[]';
      final newMoodId = await db.moodDao.insert(
        MoodEntriesCompanion.insert(
          timestamp: ts,
          score: score,
          // v0.18 4D 情绪: 老导出文件 (v1-3) 无这些字段时为 null
          energy: Value(
            ExportSchemaService.validateInt(
              m['energy'],
              null,
              min: 1,
              max: 5,
            ),
          ),
          sleep: Value(
            ExportSchemaService.validateInt(
              m['sleep'],
              null,
              min: 1,
              max: 5,
            ),
          ),
          anxiety: Value(
            ExportSchemaService.validateInt(
              m['anxiety'],
              null,
              min: 1,
              max: 5,
            ),
          ),
          tagsJson: Value(tags),
          note: Value(
            ExportSchemaService.validateString(
              m['note'],
              'mood.note',
              maxLen: 10000,
            ),
          ),
          // v0.30 round 88 (P0 fix): R84 加 8 CBT 字段时漏了 import 反序列化,
          // 用户导出 → 删 DB → 导入 = silent data loss。R88 修。8 字段全
          // nullable, 老数据 (R84 前) 全部 null = 单 score 模式。
          situation: Value(
            ExportSchemaService.validateString(
              m['situation'],
              'mood.situation',
              maxLen: 10000,
            ),
          ),
          automaticThought: Value(
            ExportSchemaService.validateString(
              m['automaticThought'],
              'mood.automaticThought',
              maxLen: 10000,
            ),
          ),
          evidenceFor: Value(
            ExportSchemaService.validateString(
              m['evidenceFor'],
              'mood.evidenceFor',
              maxLen: 10000,
            ),
          ),
          evidenceAgainst: Value(
            ExportSchemaService.validateString(
              m['evidenceAgainst'],
              'mood.evidenceAgainst',
              maxLen: 10000,
            ),
          ),
          alternativeThought: Value(
            ExportSchemaService.validateString(
              m['alternativeThought'],
              'mood.alternativeThought',
              maxLen: 10000,
            ),
          ),
          reratedScore: Value(
            ExportSchemaService.validateInt(
              m['reratedScore'],
              null,
              min: 1,
              max: 5,
            ),
          ),
          coreBelief: Value(
            ExportSchemaService.validateString(
              m['coreBelief'],
              'mood.coreBelief',
              maxLen: 10000,
            ),
          ),
          behaviorResponse: Value(
            ExportSchemaService.validateString(
              m['behaviorResponse'],
              'mood.behaviorResponse',
              maxLen: 10000,
            ),
          ),
          // v0.32 round 8 (R111 E1 fix): 语音转录 / 时长 + period /
          // influenceFactors / recordingMode。audioPath 不导入 (vent
          // 先例: stale 路径跨设备不可用)。
          audioTranscript: Value(
            ExportSchemaService.validateString(
              m['audioTranscript'],
              'mood.audioTranscript',
              maxLen: 100000,
            ),
          ),
          audioDurationMs: Value(
            ExportSchemaService.validateInt(
              m['audioDurationMs'],
              null,
              min: 0,
            ),
          ),
          period: Value(
            ExportSchemaService.validateString(
              m['period'],
              'mood.period',
              maxLen: 20,
            ),
          ),
          influenceFactorsJson: Value(
            ExportSchemaService.validateString(
                  m['influenceFactorsJson'],
                  'mood.influenceFactors',
                  maxLen: 5000,
                ) ??
                '[]',
          ),
          recordingMode: Value(
            ExportSchemaService.validateString(
              m['recordingMode'],
              'mood.recordingMode',
              maxLen: 20,
            ),
          ),
          statusPhrase: Value(
            ExportSchemaService.validateString(
              m['statusPhrase'],
              'mood.statusPhrase',
              maxLen: 100,
            ),
          ),
          // v1.1.0 round 9 (F1 烦恼闭环): worryThreadId 重映射 (old→new)。
          // 引用不在 export (worryThreads 段缺失) → null, 不导入孤儿 FK。
          worryThreadId: Value(
            () {
              final v = m['worryThreadId'];
              if (v is! int) return null;
              return worryIdMap[v];
            }(),
          ),
        ),
      );
      // v0.32 round 8 (R112 E6 fix): 记录 old→new id 映射 (老 v4 文件
      // 无 'id' → 无映射 → stress.linkedMoodEntryId 导入后为 null)。
      final oldMoodId = ExportSchemaService.validateInt(m['id'], null);
      if (oldMoodId != null) {
        moodIdMap[oldMoodId] = newMoodId;
      }
      counts.moodEntryCount++;
    }
  }

  await importDailyTracking(db, data, medIdMap, moodIdMap);
}
