// 数据导出/导入编排 — v0.26 round 57 (spen P1 #2 god class 拆分续)
//
// **职责**: DataExportService 内部 import / export 编排 + JSON 字段拼装
//
// **拆分前**: data_export_service.dart 539 行, facade 含 exportToJson / importFromJson
// 全部实现 (~280 行), 跟 DataExportService 1 facade 类 + 1 ImportResult class 混在一起.
//
// **拆分后**:
// - `DataExportService` (facade, ~120 行): 1 facade + 4 sub-service 委托 + 1 helper (_isoUtc)
// - `ExportOrchestrator` (本文件, ~340 行): importData / exportData 编排 + JSON map 拼装
// - 3 sub-service (export_crypto / export_audio / export_schema) 不动
//
// **架构延续**: 跟 R57 safety_watch / R58 medication_report / R59 app_router / R60 medication_repository
// 同款"渐进 facade 模式" — facade 留 5 类编排入口, 复杂业务下沉 orchestrator。
//
// **测试兼容**: facade 公开 API 跟拆分前一致 (exportToJson / importFromJson / 构造签名),
// 50+ 现有 test 不用改。

import 'dart:convert';

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/repositories/report_history/report_history_repository_impl.dart';
import 'package:chroniccare/core/data/services/encryption_service.dart';
import 'package:chroniccare/core/data/services/export/export_audio_service.dart';
import 'package:chroniccare/core/data/services/export/export_crypto_service.dart';
import 'package:chroniccare/core/data/services/export/export_import_pipeline.dart';
import 'package:chroniccare/core/data/services/export/export_schema_service.dart';
import 'package:chroniccare/core/l10n/strings.dart';
import 'package:chroniccare/domain/repositories/report_history_repository.dart';

/// v0.21 (P0-3 fix): 导出时统一 `toUtc()` 让 ISO 字符串带 'Z' 后缀。
///
/// **bug 现象**: 之前用 `DateTime.now().toIso8601String()` 输出
/// `2026-07-20T04:15:55.123` (**不带**时区后缀)。Dart `DateTime.parse()`
/// 对无后缀字符串**按 local 解析**。用户在北京导出 (UTC+8), 飞机到纽约
/// (UTC-5) 再导入 → 同一个字符串 "04:15:55" 在两个时区都被当 local 解析
/// → 跨时区打卡记录"瞬移" 12 小时。
///
/// **修法**: 导出统一 `.toUtc().toIso8601String()` 输出
/// `2026-07-19T20:15:55.123Z` (带 'Z'), `DateTime.parse()` 自动按 UTC 解析
/// 存进 drift → drift 转回 local 时按目标时区正确显示。
///
/// 9 处调用全部走这个 helper, 避免漏改 + 未来加新字段直接用。
String isoUtc(DateTime d) => d.toUtc().toIso8601String();

/// v0.26 round 57: 导出/导入业务编排
///
/// facade (`DataExportService`) 把 importData / exportData 委托给本 class,
/// 自身只剩"协调 4 sub-service" 一行 import。
class ExportOrchestrator {
  final AppDatabase _db;
  final ReportHistoryRepository _reportRepo;
  final ExportCryptoService _cryptoService;
  final ExportAudioService _audioService;
  final ExportSchemaService _schemaService;

  /// v0.27 round 77 (R76-N8 修): 公开 5 个依赖 getter, 让
  /// `export_import_pipeline.dart` 的 `runImportFromJson` 顶层函数能
  /// 访问, 不打破 private 封装。
  AppDatabase get db => _db;
  ReportHistoryRepository get reportRepo => _reportRepo;
  ExportCryptoService get cryptoService => _cryptoService;
  ExportAudioService get audioService => _audioService;
  ExportSchemaService get schemaService => _schemaService;

  /// 构造注入, 默认值跟 facade 一致。
  ///
  /// 公开供 facade / 测 test 注入, 默认走单例 (跟 `DataExportService()` 行为一致)。
  ExportOrchestrator({
    required AppDatabase db,
    required ExportCryptoService cryptoService,
    required ExportAudioService audioService,
    required ExportSchemaService schemaService,
    ReportHistoryRepository? reportRepo,
  })  : _db = db,
        _reportRepo = reportRepo ?? ReportHistoryRepositoryImpl(db),
        _cryptoService = cryptoService,
        _audioService = audioService,
        _schemaService = schemaService;

  /// 工厂 — 跟 facade 旧构造签名兼容 (3 参数位置可选)
  ///
  /// 现有 50+ test 调用 `DataExportService(db, [reportRepo, ventTextEncryption])`,
  /// facade 内部转成本 orchestrator, test 不用改。
  factory ExportOrchestrator.legacy({
    required AppDatabase db,
    ReportHistoryRepository? reportRepo,
    EncryptionService? ventTextEncryption,
  }) {
    return ExportOrchestrator(
      db: db,
      cryptoService: ExportCryptoService(ventTextEncryption),
      audioService: const ExportAudioService(),
      schemaService: const ExportSchemaService(),
      reportRepo: reportRepo,
    );
  }

  /// 导出所有数据为 JSON 字符串
  ///
  /// **编排**: 拉所有 DB (5s timeout 防 drift stream hang) → 拼 JSON map
  /// (委托 3 sub-service) → JsonEncoder.withIndent
  Future<String> exportToJson({DateTime? now}) async {
    final profile = await _db.userProfileDao.get();
    // v0.24 round 48 (sp-en P2-14): 改名为 streamTimeout 去掉下划线
    // (no_leading_underscores_for_local_identifiers lint)
    const streamTimeout = Duration(seconds: 5);
    final medications = await _db.medicationDao
        // v0.32 round 8 (R112 E8 fix): watchActive → watchAllIncludingInactive。
        // 之前软停药 (isActive=false) 整行不导出 → 换机后药名从历史消失
        // (报告 / 趋势 / treatment join 全断)。E3 medIdMap 重映射自然覆盖
        // inactive 药, 无孤儿 FK 风险。
        .watchAllIncludingInactive()
        .first
        .timeout(streamTimeout, onTimeout: () => const []);
    final checkIns = await _db.checkInDao
        .watchAll()
        .first
        .timeout(streamTimeout, onTimeout: () => const []);
    final reportHistories = await _reportRepo.getAll();
    final moodEntries = await _db.moodDao.getAll();
    final ventEntries = await _db.ventDao
        .watchAll()
        .first
        .timeout(streamTimeout, onTimeout: () => const []);
    // v1.1.0 round 9 (F1 烦恼闭环): 烦恼主题导出
    final worryThreads = await _db.worryDao.getAll();

    // v0.32 round 8 (R112 E6 fix): 6 张 daily tracking 表 (R91, DB schema 22)。
    // 之前 export/import 完全缺这 6 段 → 换机整块静默丢失。
    final sleepEntries = await _db.sleepDao
        .watchAll()
        .first
        .timeout(streamTimeout, onTimeout: () => const []);
    final socialRhythmEntries = await _db.socialRhythmDao
        .watchAll()
        .first
        .timeout(streamTimeout, onTimeout: () => const []);
    final stressEvents = await _db.stressEventDao
        .watchAll()
        .first
        .timeout(streamTimeout, onTimeout: () => const []);
    final treatmentEntries = await _db.treatmentDao
        .watchAll()
        .first
        .timeout(streamTimeout, onTimeout: () => const []);
    final weightEntries = await _db.weightDao
        .watchAll()
        .first
        .timeout(streamTimeout, onTimeout: () => const []);
    final anxietyAgitationEntries = await _db.anxietyAgitationDao
        .watchAll()
        .first
        .timeout(streamTimeout, onTimeout: () => const []);

    final data = {
      'version': ExportSchemaService.currentVersion,
      'exportedAt': isoUtc(now ?? DateTime.now()),
      'profile': profile == null
          ? null
          : {
              'userName': profile.userName,
              'checkInCycleHours': profile.checkInCycleHours,
              'firstLaunchAt': isoUtc(profile.firstLaunchAt),
              // P0-10: 顺便带上 lastCheckInAt, 导入后立即可见
              if (profile.lastCheckInAt != null)
                'lastCheckInAt': isoUtc(profile.lastCheckInAt!),
              // v0.32 round 8 (R112 E7 fix): PIPL §14 同意留痕 4 字段
              // (R63 加, R68 gate 只挡 setup 路径, 导出/导入直接绕过 → 换机
              // 留痕断裂)。v5 起导出, 老 v4 文件无这 4 字段, import 时
              // 优雅降级 null。
              if (profile.userAgreementVersion != null)
                'userAgreementVersion': profile.userAgreementVersion,
              if (profile.privacyPolicyVersion != null)
                'privacyPolicyVersion': profile.privacyPolicyVersion,
              if (profile.sensitiveDataConsentAt != null)
                'sensitiveDataConsentAt':
                    isoUtc(profile.sensitiveDataConsentAt!),
              if (profile.consentRevokedAt != null)
                'consentRevokedAt': isoUtc(profile.consentRevokedAt!),
            },
      'medications': [
        for (final m in medications)
          {
            // v0.32 round 8 (R111 E3 fix): 导出原 id, import 时建
            // old→new id 映射, checkIn.medicationId 重映射 (修孤儿 FK)
            'id': m.id,
            'name': m.name,
            'dosage': m.dosage,
            'dosageUnit': m.dosageUnit,
            'timesJson': m.timesJson,
            'startDate': isoUtc(m.startDate),
            // v0.32 round 8 (R112 E8 fix): endDate 补导出 — 软停药历史
            // 的停药日期换机不丢 (import 侧 v5 已有 endDate 反序列化)。
            if (m.endDate != null) 'endDate': isoUtc(m.endDate!),
            'isActive': m.isActive,
            // v0.32 round 8 (R111 E1 fix): 续方/剂型/颜色/备注 5 字段
            // (R101 加了 3 个, R12 加了 2 个, 全部漏 export → 换机静默丢失)
            if (m.refillAt != null) 'refillAt': isoUtc(m.refillAt!),
            'refillReminderDays': m.refillReminderDays,
            'form': m.form,
            'colorIndex': m.colorIndex,
            if (m.notes != null) 'notes': m.notes,
          },
      ],
      'checkIns': [
        for (final c in checkIns)
          {
            'timestamp': isoUtc(c.timestamp),
            'type': c.type,
            'medicationId': c.medicationId,
            'note': c.note,
          },
      ],
      'reportHistories': [
        for (final h in reportHistories)
          {
            'windowDays': h.windowDays,
            'generatedAt': isoUtc(h.generatedAt),
            'userName': h.userName,
            'reportText': h.reportText,
          },
      ],
      'moodEntries': [
        for (final m in moodEntries)
          {
            // v0.32 round 8 (R112 E6 fix): 导出原 id, import 时建
            // old→new id 映射, stressEvents.linkedMoodEntryId 重映射
            // (跟 E3 checkIn.medicationId 同款修孤儿 FK)。
            'id': m.id,
            'timestamp': isoUtc(m.timestamp),
            'score': m.score,
            // v0.18 4D 情绪: energy / sleep / anxiety (nullable, 老数据为 null)
            if (m.energy != null) 'energy': m.energy,
            if (m.sleep != null) 'sleep': m.sleep,
            if (m.anxiety != null) 'anxiety': m.anxiety,
            'tagsJson': m.tagsJson,
            'note': m.note,
            // v0.30 round 88 (P0 fix): R84 加 8 CBT 字段时漏了 toMap, 用户导出
            // → 删 DB → 导入 = silent data loss。R88 修。8 字段全 nullable, 老数据
            // (R84 前) 全部 null, 5 栏 / 7 栏 / 单纯 score 都兼容。
            if (m.situation != null) 'situation': m.situation,
            if (m.automaticThought != null)
              'automaticThought': m.automaticThought,
            if (m.evidenceFor != null) 'evidenceFor': m.evidenceFor,
            if (m.evidenceAgainst != null) 'evidenceAgainst': m.evidenceAgainst,
            if (m.alternativeThought != null)
              'alternativeThought': m.alternativeThought,
            if (m.reratedScore != null) 'reratedScore': m.reratedScore,
            if (m.coreBelief != null) 'coreBelief': m.coreBelief,
            if (m.behaviorResponse != null)
              'behaviorResponse': m.behaviorResponse,
            // v0.32 round 8 (R111 E1 fix): 语音转录 / 时长 + period /
            // influenceFactors / recordingMode (R31/R91/R101 加, 全部漏 export
            // → 换机静默丢失)。audioPath 不导出 — vent 先例: stale 路径跨
            // 设备不可用, 只保文字转录 + 元数据。
            if (m.audioTranscript != null) 'audioTranscript': m.audioTranscript,
            if (m.audioDurationMs != null) 'audioDurationMs': m.audioDurationMs,
            if (m.period != null) 'period': m.period,
            // influenceFactorsJson 非 nullable (DB 默认 '[]')
            'influenceFactorsJson': m.influenceFactorsJson,
            if (m.recordingMode != null) 'recordingMode': m.recordingMode,
            // v1.1.0: 状态短语 (预设或自定义)
            if (m.statusPhrase != null) 'statusPhrase': m.statusPhrase,
            // v1.1.0 round 9 (F1 烦恼闭环): 关联烦恼主题 id
            if (m.worryThreadId != null) 'worryThreadId': m.worryThreadId,
          },
      ],
      // v1.1.0 round 9 (F1 烦恼闭环): 烦恼主题段 (moodEntries.worryThreadId
      // 引用的原 id, import 时建 old→new 映射重映射)
      'worryThreads': [
        for (final w in worryThreads)
          {
            'id': w.id,
            'title': w.title,
            'createdAt': isoUtc(w.createdAt),
            'status': w.status,
            if (w.resolvedAt != null) 'resolvedAt': isoUtc(w.resolvedAt!),
          },
      ],
      'ventEntries': [
        // P0-3: 导出文字 + 元数据 (duration / size), **不**导出 audioPath。
        // v0.21 Round 22: contentTextEnc 字段加密后, 导出时 decrypt 给用户明文
        // (跨设备恢复需要明文)。导入时再 encrypt 写回。
        for (final v in ventEntries)
          {
            'timestamp': isoUtc(v.timestamp),
            'contentText':
                await _cryptoService.decryptVentText(v.contentTextEnc),
            'tagsJson': v.tagsJson,
            ..._audioService.buildAudioMetadata(
              audioDurationSec: v.audioDurationSec,
              audioSizeBytes: v.audioSizeBytes,
              audioPath: v.audioPath,
            ),
          },
      ],
      // v0.32 round 8 (R112 E6 fix): 6 张 daily tracking 表 (R91)。全字段
      // 导出, 外键 (stress.linkedMoodEntryId / treatment.linkedMedicationId)
      // 导出原 id, import 时走 old→new 映射 (跟 E3 同款)。
      'sleepEntries': [
        for (final s in sleepEntries)
          {
            'date': isoUtc(s.date),
            'bedtime': isoUtc(s.bedtime),
            'wakeTime': isoUtc(s.wakeTime),
            'durationMin': s.durationMin,
            if (s.regularityScore != null) 'regularityScore': s.regularityScore,
            if (s.note != null) 'note': s.note,
          },
      ],
      'socialRhythmEntries': [
        for (final s in socialRhythmEntries)
          {
            'date': isoUtc(s.date),
            'wakeTime': isoUtc(s.wakeTime),
            'firstMealTime': isoUtc(s.firstMealTime),
            'lastMealTime': isoUtc(s.lastMealTime),
            'socialMin': s.socialMin,
            'workMin': s.workMin,
            'exerciseMin': s.exerciseMin,
          },
      ],
      'stressEvents': [
        for (final s in stressEvents)
          {
            'timestamp': isoUtc(s.timestamp),
            'eventType': s.eventType,
            'intensity': s.intensity,
            if (s.note != null) 'note': s.note,
            if (s.linkedMoodEntryId != null)
              'linkedMoodEntryId': s.linkedMoodEntryId,
          },
      ],
      'treatmentEntries': [
        for (final t in treatmentEntries)
          {
            'timestamp': isoUtc(t.timestamp),
            'treatmentType': t.treatmentType,
            'description': t.description,
            if (t.linkedMedicationId != null)
              'linkedMedicationId': t.linkedMedicationId,
            if (t.linkedMedicationName != null)
              'linkedMedicationName': t.linkedMedicationName,
            if (t.note != null) 'note': t.note,
          },
      ],
      'weightEntries': [
        for (final w in weightEntries)
          {
            'timestamp': isoUtc(w.timestamp),
            'weightKg': w.weightKg,
            if (w.bmi != null) 'bmi': w.bmi,
            if (w.note != null) 'note': w.note,
          },
      ],
      'anxietyAgitationEntries': [
        for (final a in anxietyAgitationEntries)
          {
            'timestamp': isoUtc(a.timestamp),
            'anxietyScore': a.anxietyScore,
            'agitationScore': a.agitationScore,
            if (a.note != null) 'note': a.note,
          },
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// 从 JSON 字符串导入数据 (覆盖现有)
  ///
  /// **v0.27 round 77 (R76-N8 修)**: 委托 [runImportFromJson] (定义在
  /// `export_import_pipeline.dart`), 本文件只保留 facade. 整 method 310 行
  /// 拆出后 ExportOrchestrator 从 21.5KB → 12KB, 仍跟 facade + 50+ test 兼容
  /// (公开签名 `importFromJson(String)` 不变)。
  ///
  /// 返回导入条数摘要 [ImportResult]
  Future<ImportResult> importFromJson(String json) =>
      runImportFromJson(this, json);
}

/// 导入结果摘要 — v0.26 round 57 (spen P1 #2): 从 facade 移到 orchestrator
///
/// 跟 ImportOrchestrator 紧耦合, 留在本文件更易读。
/// 之前 facade 内引用 Strings 拼 summary, 拆出来后 Strings 属于 l10n 层,
/// 留 facade 拿, 这里只提供 5 个 int 字段 (v1.1.0 round 3 删 contactCount)
/// + success/error 标志。
class ImportResult {
  final bool success;
  final String? error;
  final int medicationCount;
  final int checkInCount;
  final int reportHistoryCount;
  final int moodEntryCount;

  /// P0-3: 树洞导入条数 (文字 only, 录音不导入)
  final int ventEntryCount;

  const ImportResult({
    required this.success,
    this.error,
    this.medicationCount = 0,
    this.checkInCount = 0,
    this.reportHistoryCount = 0,
    this.moodEntryCount = 0,
    this.ventEntryCount = 0,
  });

  factory ImportResult.success({
    required int medicationCount,
    required int checkInCount,
    int reportHistoryCount = 0,
    int moodEntryCount = 0,
    int ventEntryCount = 0,
  }) =>
      ImportResult(
        success: true,
        medicationCount: medicationCount,
        checkInCount: checkInCount,
        reportHistoryCount: reportHistoryCount,
        moodEntryCount: moodEntryCount,
        ventEntryCount: ventEntryCount,
      );

  factory ImportResult.failure(String error) =>
      ImportResult(success: false, error: error);

  /// 一句话摘要 (i18n 走 Strings helper, 跟 v0.24 sprint #5c 同步)
  ///
  /// 留本类而不是 facade extension, 是因为 Dart extension 需要 caller 显式
  /// import 才能访问, 老调用方 `result.summary` 不愿改 import, 直接放 class
  /// 内最稳。Strings 是 core/l10n 层, data 层允许 import (跟 medication_notifier
  /// / refill_notifier 用法一致)。
  String get summary {
    final parts = <String>[
      Strings.importSummaryMedication(medicationCount),
      Strings.importSummaryCheckIn(checkInCount),
    ];
    if (reportHistoryCount > 0) {
      parts.add(Strings.importSummaryReport(reportHistoryCount));
    }
    if (moodEntryCount > 0) {
      parts.add(Strings.importSummaryMood(moodEntryCount));
    }
    if (ventEntryCount > 0) {
      parts.add(Strings.importSummaryVent(ventEntryCount));
    }
    return parts.join(' / ');
  }
}
