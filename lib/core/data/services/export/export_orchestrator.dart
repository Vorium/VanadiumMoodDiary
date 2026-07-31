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

import 'package:drift/drift.dart' show Value;

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/repositories/report_history/report_history_repository_impl.dart';
import 'package:chroniccare/core/data/services/encryption_service.dart';
import 'package:chroniccare/core/data/services/export/export_audio_service.dart';
import 'package:chroniccare/core/data/services/export/export_crypto_service.dart';
import 'package:chroniccare/core/data/services/export/export_schema_service.dart';
import 'package:chroniccare/core/data/services/pii_safe_log.dart';
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
    final profile = await _db.getUserProfile();
    // v0.24 round 48 (sp-en P2-14): 改名为 streamTimeout 去掉下划线
    // (no_leading_underscores_for_local_identifiers lint)
    const streamTimeout = Duration(seconds: 5);
    final contacts = await _db
        .watchContacts()
        .first
        .timeout(streamTimeout, onTimeout: () => const []);
    final medications = await _db
        .watchMedications()
        .first
        .timeout(streamTimeout, onTimeout: () => const []);
    final checkIns = await _db
        .watchAllCheckIns()
        .first
        .timeout(streamTimeout, onTimeout: () => const []);
    final reportHistories = await _reportRepo.getAll();
    final moodEntries = await _db.getAllMoodEntries();
    final ventEntries = await _db
        .watchVentEntries()
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
            },
      'contacts': [
        for (final c in contacts)
          {
            'name': c.name,
            'phone': c.phone,
            'sortOrder': c.sortOrder,
            'isActive': c.isActive,
          },
      ],
      'medications': [
        for (final m in medications)
          {
            'name': m.name,
            'dosage': m.dosage,
            'dosageUnit': m.dosageUnit,
            'timesJson': m.timesJson,
            'startDate': isoUtc(m.startDate),
            'isActive': m.isActive,
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
            'timestamp': isoUtc(m.timestamp),
            'score': m.score,
            // v0.18 4D 情绪: energy / sleep / anxiety (nullable, 老数据为 null)
            if (m.energy != null) 'energy': m.energy,
            if (m.sleep != null) 'sleep': m.sleep,
            if (m.anxiety != null) 'anxiety': m.anxiety,
            'tagsJson': m.tagsJson,
            'note': m.note,
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
            ..._audioService.buildAudioMetadata(
              audioDurationSec: v.audioDurationSec,
              audioSizeBytes: v.audioSizeBytes,
              audioPath: v.audioPath,
            ),
          },
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// 从 JSON 字符串导入数据 (覆盖现有)
  ///
  /// 返回导入条数摘要
  Future<ImportResult> importFromJson(String json) async {
    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      final version = _schemaService.validateVersion(data['version']);
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

      await _db.transaction(() async {
        // 清空旧数据
        await _db.delete(_db.checkIns).go();
        await _db.delete(_db.medications).go();
        await _db.delete(_db.contacts).go();
        // 旧 schema 缺失表安全删除 (v0.23 round 39 P1-10 fix: 走 swallowError
        // 集中器, 不再 catch(_) 完全静默)
        await _schemaService.deleteOldDataSafely(
          _db,
          _db.reportHistories,
          label: 'reportHistories',
        );
        await _schemaService.deleteOldDataSafely(
          _db,
          _db.moodEntries,
          label: 'moodEntries',
        );
        // P0-3: vent_entries 表 (v0.15+ 存在, 不需要 guard, 但仍走安全删除)
        await _schemaService.deleteOldDataSafely(
          _db,
          _db.ventEntries,
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
            await _db.upsertUserProfile(
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
          await _db.insertContact(
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
          await _db.insertMedication(
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
          await _db.insertCheckIn(
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
            await _reportRepo.insert(
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
            await _db.insertMoodEntry(
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
            final encText = await _cryptoService.encryptVentText(text);
            await _db.insertVentEntry(
              VentEntriesCompanion.insert(
                timestamp: ts,
                contentTextEnc: Value(encText),
                // audioPath 永远 null — 旧路径在重装后失效
                audioDurationSec: Value(
                  _audioService.parseAudioDurationSec(m['audioDurationSec']),
                ),
                audioSizeBytes: Value(
                  _audioService.parseAudioSizeBytes(m['audioSizeBytes']),
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
}

/// 导入结果摘要 — v0.26 round 57 (spen P1 #2): 从 facade 移到 orchestrator
///
/// 跟 ImportOrchestrator 紧耦合, 留在本文件更易读。
/// 之前 facade 内引用 Strings 拼 summary, 拆出来后 Strings 属于 l10n 层,
/// 留 facade 拿, 这里只提供 6 个 int 字段 + success/error 标志。
class ImportResult {
  final bool success;
  final String? error;
  final int contactCount;
  final int medicationCount;
  final int checkInCount;
  final int reportHistoryCount;
  final int moodEntryCount;

  /// P0-3: 树洞导入条数 (文字 only, 录音不导入)
  final int ventEntryCount;

  const ImportResult({
    required this.success,
    this.error,
    this.contactCount = 0,
    this.medicationCount = 0,
    this.checkInCount = 0,
    this.reportHistoryCount = 0,
    this.moodEntryCount = 0,
    this.ventEntryCount = 0,
  });

  factory ImportResult.success({
    required int contactCount,
    required int medicationCount,
    required int checkInCount,
    int reportHistoryCount = 0,
    int moodEntryCount = 0,
    int ventEntryCount = 0,
  }) =>
      ImportResult(
        success: true,
        contactCount: contactCount,
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
      Strings.importSummaryContact(contactCount),
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
