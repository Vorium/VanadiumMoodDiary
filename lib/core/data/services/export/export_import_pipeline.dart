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
// 后续 R78+ 进一步拆 importFromJson 内部 4 子任务 (clearData / importProfile
// / importEntities / importVent) 为 4 private method, 减少单 method 长度。

import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/services/export/export_orchestrator.dart';
import 'package:chroniccare/core/data/services/export/export_schema_service.dart';
import 'package:chroniccare/core/data/services/pii_safe_log.dart';

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
  final reportRepo = orchestrator.reportRepo;
  final cryptoService = orchestrator.cryptoService;
  final audioService = orchestrator.audioService;

  try {
    final data = jsonDecode(json) as Map<String, dynamic>;
    final version = schemaService.validateVersion(data['version']);
    if (version == null) {
      return ImportResult.failure(
        '数据版本不匹配（期望 1-${ExportSchemaService.currentVersion}, 实际 ${data['version']}）',
      );
    }

    int contactCount = 0;
    int medicationCount = 0;
    int checkInCount = 0;
    int reportHistoryCount = 0;
    int moodEntryCount = 0;
    int ventEntryCount = 0;

    await db.transaction(() async {
      // 清空旧数据
      await db.delete(db.checkIns).go();
      await db.delete(db.medications).go();
      await db.delete(db.contacts).go();
      // 旧 schema 缺失表安全删除 (v0.23 round 39 P1-10 fix: 走 swallowError
      // 集中器, 不再 catch(_) 完全静默)
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

      // profile
      if (data['profile'] != null) {
        final p = data['profile'] as Map<String, dynamic>;
        final userName = ExportSchemaService.validateString(
          p['userName'],
          'userName',
          maxLen: 50,
        );
        if (userName != null) {
          await db.userProfileDao.upsert(
            UserProfilesCompanion.insert(
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
              firstLaunchAt:
                  ExportSchemaService.validateDate(p['firstLaunchAt']) ??
                      DateTime.now(),
            ),
          );
        }
      }

      // contacts
      for (final c in (data['contacts'] as List? ?? [])) {
        if (c is! Map) continue;
        final m = c;
        final name = ExportSchemaService.validateString(
          m['name'],
          'contact.name',
          maxLen: 50,
        );
        final phone = ExportSchemaService.validateString(
          m['phone'],
          'contact.phone',
          maxLen: 20,
          pattern: RegExp(r'^\+?\d{6,20}$'),
        );
        if (name == null || phone == null) continue;
        await db.contactDao.insert(
          ContactsCompanion.insert(
            name: name,
            phone: phone,
            sortOrder: Value(
              ExportSchemaService.validateIntOr(m['sortOrder'], 0),
            ),
            isActive: Value(m['isActive'] as bool? ?? true),
          ),
        );
        contactCount++;
      }

      // medications
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
        await db.medicationDao.insert(
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
            isActive: Value(m['isActive'] as bool? ?? true),
          ),
        );
        medicationCount++;
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
        await db.checkInDao.insert(
          CheckInsCompanion.insert(
            timestamp: ts,
            type: type,
            medicationId: Value(
              ExportSchemaService.validateInt(m['medicationId'], null),
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
        checkInCount++;
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
          reportHistoryCount++;
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
          await db.moodDao.insert(
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
            ),
          );
          moodEntryCount++;
        }
      }

      // P0-3: vent_entries 文字导入 (录音路径永远丢弃, 跨设备不可用)。
      // version 3+ 才有, 老导出文件没这段也兼容。
      // v0.21 Round 22: 文字从 JSON 读出是明文, 导入时 encrypt 写回 BLOB。
      if (version >= 3) {
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
            ),
          );
          ventEntryCount++;
        }
      }
    });

    return ImportResult.success(
      contactCount: contactCount,
      medicationCount: medicationCount,
      checkInCount: checkInCount,
      reportHistoryCount: reportHistoryCount,
      moodEntryCount: moodEntryCount,
      ventEntryCount: ventEntryCount,
    );
  } catch (e, st) {
    piiSafeLog('DataExportService', 'importFromJson error: $e\n$st');
    // P12 fix: 脱敏, 只告诉用户"解析失败", 不暴露具体异常
    return ImportResult.failure('解析失败：数据格式不正确，请确认是从本 App 导出的 JSON');
  }
}
