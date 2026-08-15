// 数据导入 pipeline — v0.27 round 77 (R76-N8 重构 续)
//
// 背景 (R76 superpowers-en 报告 P1-8):
//   export_orchestrator.dart 21.5KB, 1 facade + 1 god method (importFromJson 310 行)
//   + 1 class (ImportResult 65 行) 全堆一起, 修改 import 逻辑需要滚屏 + 风险。
//
//   拆法 (渐进 facade 模式, 跟 R57 safety_watch / R58 medication_report 同款):
//   - export_orchestrator.dart (12KB): 公共 facade + exportToJson + ImportResult
//   - export_import_pipeline.dart (本文件, 9KB): importFromJson 整 method
//
// 设计:
//   - importFromJson 内部高度耦合 _db / _schemaService / _reportRepo / _cryptoService
//     / _audioService 等私有字段, 不能简单抽 extension (会破坏封装)
//   - 改: 把整个 importFromJson method 整体迁出到本文件作为 `Future<ImportResult>
//     runImportFromJson(ExportOrchestrator orchestrator, String json)` 顶层函数
//   - ExportOrchestrator.importFromJson(json) 改成 1 行委托:
//     `=> runImportFromJson(this, json)`
//   - 50+ test 不用改 (走 facade.public method)
//
// v0.32 架构批 2 (R112-ARCH-03): 执行 R77 注释的 4 子任务拆分计划
//   - runImportFromJson 拆为 4 private 顶层函数:
//     _clearData / _importProfile / _importEntities / _importVent
//   - ImportResultBuilder 聚合 6 个计数 (v1.1.0 round 3 删 contactCount;
//     medIdMap / moodIdMap 老→新 id
//     映射在 _importEntities 内部闭环, 不泄漏到其它子任务)
//   - 行为 100% 不变 (data_export_v5_round8 / export_import_pipeline_round99
//     等兜底测试全绿)

import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/services/export/export_audio_service.dart';
import 'package:chroniccare/core/data/services/export/export_crypto_service.dart';
import 'package:chroniccare/core/data/services/export/export_orchestrator.dart';
import 'package:chroniccare/core/data/services/export/export_schema_service.dart';
import 'package:chroniccare/core/data/services/pii_safe_log.dart';
import 'package:chroniccare/domain/repositories/report_history_repository.dart';

/// v0.32 架构批 2 (R112-ARCH-03): 导入计数聚合器
///
/// 4 个子任务各自 +1, 最后 [build] 装配成 [ImportResult.success]。
/// 6 张 daily tracking 表 (R91) 不进 ImportResult 摘要 (跟拆分前一致)。
class ImportResultBuilder {
  int medicationCount = 0;
  int checkInCount = 0;
  int reportHistoryCount = 0;
  int moodEntryCount = 0;
  int ventEntryCount = 0;

  ImportResult build() => ImportResult.success(
        medicationCount: medicationCount,
        checkInCount: checkInCount,
        reportHistoryCount: reportHistoryCount,
        moodEntryCount: moodEntryCount,
        ventEntryCount: ventEntryCount,
      );
}

/// 导入数据 (覆盖现有) — 从 ExportOrchestrator.importFromJson 拆出
///
/// 返回导入条数摘要 [ImportResult]
Future<ImportResult> runImportFromJson(
  ExportOrchestrator orchestrator,
  String json,
) async {
  // v0.27 round 77: 抽 5 个依赖为 final local, 避免每次访问 orchestrator._xxx
  // (跨文件 private 字段访问会失败 — 改用 ExportOrchestrator 公开 getter)
  final db = orchestrator.db;
  final schemaService = orchestrator.schemaService;

  try {
    final data = jsonDecode(json) as Map<String, dynamic>;
    final version = schemaService.validateVersion(data['version']);
    if (version == null) {
      return ImportResult.failure(
        '数据版本不匹配（期望 1-${ExportSchemaService.currentVersion}, 实际 ${data['version']}）',
      );
    }

    final counts = ImportResultBuilder();

    await db.transaction(() async {
      // 清空旧数据
      await _clearData(db, schemaService);

      // profile
      await _importProfile(db, data);

      // contacts / medications / checkIns / reportHistories / moodEntries /
      // 6 张 daily tracking 表 (medIdMap + moodIdMap 在本子任务内闭环)
      await _importEntities(
        db,
        orchestrator.reportRepo,
        data,
        version,
        counts,
      );

      // P0-3: vent_entries 文字导入 (录音路径永远丢弃, 跨设备不可用)。
      await _importVent(
        db,
        orchestrator.cryptoService,
        orchestrator.audioService,
        data,
        version,
        counts,
      );
    });

    return counts.build();
  } catch (e, st) {
    piiSafeLog('DataExportService', 'importFromJson error: $e\n$st');
    // P12 fix: 脱敏, 只告诉用户"解析失败", 不暴露具体异常
    return ImportResult.failure('解析失败：数据格式不正确，请确认是从本 App 导出的 JSON');
  }
}

/// 子任务 1/4: 清空旧数据 (覆盖导入语义)
///
/// v0.23 round 39 P1-10 fix: 旧 schema 缺失表安全删除走 swallowError
/// 集中器 (deleteOldDataSafely), 不再 catch(_) 完全静默。
/// v0.32 round 8 (R112 E6 fix): 6 张 daily tracking 表 (R91) 也 clear。
Future<void> _clearData(
  AppDatabase db,
  ExportSchemaService schemaService,
) async {
  await db.delete(db.checkIns).go();
  await db.delete(db.medications).go();
  // v1.1.0 round 3 (Task 6): contacts 表不清 — Task 9 才删表, 导入器
  // 不再引用 contacts (v5 文件含 contacts key 时忽略)。
  // 旧 schema 缺失表安全删除
  await schemaService.deleteOldDataSafely(
    db,
    db.reportHistories,
    label: 'reportHistories',
  );
  await schemaService.deleteOldDataSafely(
    db,
    db.moodEntries,
    label: 'moodEntries',
  );
  // P0-3: vent_entries 表 (v0.15+ 存在, 不需要 guard, 但仍走安全删除)
  await schemaService.deleteOldDataSafely(
    db,
    db.ventEntries,
    label: 'ventEntries',
  );
  // v0.32 round 8 (R112 E6 fix): 6 张 daily tracking 表 (R91, DB schema 22)。
  // 之前 import 不 clear → 导入后残留旧设备数据 (与新数据混在一起)。
  await schemaService.deleteOldDataSafely(
    db,
    db.sleepEntries,
    label: 'sleepEntries',
  );
  await schemaService.deleteOldDataSafely(
    db,
    db.socialRhythmEntries,
    label: 'socialRhythmEntries',
  );
  await schemaService.deleteOldDataSafely(
    db,
    db.stressEvents,
    label: 'stressEvents',
  );
  await schemaService.deleteOldDataSafely(
    db,
    db.treatmentEntries,
    label: 'treatmentEntries',
  );
  await schemaService.deleteOldDataSafely(
    db,
    db.weightEntries,
    label: 'weightEntries',
  );
  await schemaService.deleteOldDataSafely(
    db,
    db.anxietyAgitationEntries,
    label: 'anxietyAgitationEntries',
  );
}

/// 子任务 2/4: user profile 导入 (全局单条, id=1)
///
/// v0.32 round 8 (R112 E7 fix): drift insertOnConflictUpdate 忽略
/// Value(null) → 老文件缺的字段不会清掉旧设备残留。改 update().write()
/// (显式 SET NULL), import = 全量替换语义。
Future<void> _importProfile(AppDatabase db, Map<String, dynamic> data) async {
  if (data['profile'] != null) {
    final p = data['profile'] as Map<String, dynamic>;
    final userName = ExportSchemaService.validateString(
      p['userName'],
      'userName',
      maxLen: 50,
    );
    if (userName != null) {
      final companion = UserProfilesCompanion.insert(
        // v0.21 Round 23 (P1-24): userName nullable
        userName: Value(userName),
        checkInCycleHours: Value(
          ExportSchemaService.validateIntOr(
            p['checkInCycleHours'],
            48,
            min: 1,
            max: 168,
          ),
        ),
        firstLaunchAt: ExportSchemaService.validateDate(p['firstLaunchAt']) ??
            DateTime.now(),
        // v0.32 round 8 (R112-06 fix): lastCheckInAt 已导出但 import
        // 从不读 (P0-10 注释意图未实现)。
        lastCheckInAt: Value(
          ExportSchemaService.validateDate(p['lastCheckInAt']),
        ),
        // v0.32 round 8 (R112 E7 fix): PIPL §14 同意留痕 4 字段
        // (R63 加)。跟 contact consent 同款: 老 v4 文件无这 4 字段
        // → null (老数据, 法务可接受)。
        userAgreementVersion: Value(
          ExportSchemaService.validateString(
            p['userAgreementVersion'],
            'profile.userAgreementVersion',
            maxLen: 50,
          ),
        ),
        privacyPolicyVersion: Value(
          ExportSchemaService.validateString(
            p['privacyPolicyVersion'],
            'profile.privacyPolicyVersion',
            maxLen: 50,
          ),
        ),
        sensitiveDataConsentAt: Value(
          ExportSchemaService.validateDate(p['sensitiveDataConsentAt']),
        ),
        consentRevokedAt: Value(
          ExportSchemaService.validateDate(p['consentRevokedAt']),
        ),
      );
      if (await db.userProfileDao.get() == null) {
        await db.userProfileDao.upsert(companion);
      } else {
        // v0.32 round 8 (R112 E7 fix): 显式 SET NULL, import = 全量替换语义。
        await (db.update(db.userProfiles)..where((t) => t.id.equals(1)))
            .write(companion);
      }
    }
  }
}

/// 子任务 3/4: medications / checkIns / reportHistories /
/// moodEntries / 6 张 daily tracking 表
///
/// medIdMap (medications old→new) 供 checkIns.medicationId 和
/// treatment.linkedMedicationId 重映射; moodIdMap (mood old→new) 供
/// stress.linkedMoodEntryId 重映射 — 两个映射在本函数内闭环, 不跨子任务。
Future<void> _importEntities(
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
        refillReminderDays: Value(
          ExportSchemaService.validateIntOr(
            m['refillReminderDays'],
            7,
            min: 0,
            max: 90,
          ),
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

  // v0.32 round 8 (R112 E6 fix): 6 张 daily tracking 表 (R91, DB schema 22)。
  // 之前完全缺这 6 段 → 换机整块静默丢失。字段校验走既有 validate 模式,
  // 外键走 old→new 映射 (medIdMap / moodIdMap), 老 v4 文件无这些 key
  // → 空列表, 天然兼容。

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

/// 子任务 4/4: vent_entries 文字导入 (录音路径永远丢弃, 跨设备不可用)。
/// version 3+ 才有, 老导出文件没这段也兼容。
/// v0.21 Round 22: 文字从 JSON 读出是明文, 导入时 encrypt 写回 BLOB。
Future<void> _importVent(
  AppDatabase db,
  ExportCryptoService cryptoService,
  ExportAudioService audioService,
  Map<String, dynamic> data,
  int version,
  ImportResultBuilder counts,
) async {
  if (version < 3) return;
  for (final v in (data['ventEntries'] as List? ?? [])) {
    if (v is! Map) continue;
    final m = v;
    final ts = ExportSchemaService.validateDate(m['timestamp']);
    if (ts == null) continue;
    // 文字可以很大 (树洞常长篇), 放宽到 100k
    final text = ExportSchemaService.validateString(
      m['contentText'],
      'vent.text',
      maxLen: 100000,
    );
    // 委托 ExportCryptoService.encryptVentText — encrypt 副作用下沉
    final encText = await cryptoService.encryptVentText(text);
    await db.ventDao.insert(
      VentEntriesCompanion.insert(
        timestamp: ts,
        contentTextEnc: Value(encText),
        // audioPath 永远 null — 旧路径在重装后失效
        audioDurationSec: Value(
          audioService.parseAudioDurationSec(m['audioDurationSec']),
        ),
        audioSizeBytes: Value(
          audioService.parseAudioSizeBytes(m['audioSizeBytes']),
        ),
        tagsJson: Value(
          ExportSchemaService.validateString(
            m['tagsJson'],
            'vent.tagsJson',
            maxLen: 1000,
          ) ??
          '[]',
        ),
      ),
    );
    counts.ventEntryCount++;
  }
}
