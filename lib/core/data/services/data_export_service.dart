/// 数据导出/导入服务 (facade) — v0.24 Sprint #5c (emil god class 拆解)
///
/// **基线**: v0.24 round 45, 582 行 → ~250 行 (1 facade + 3 sub-service)
///
/// **职责 (拆分后)**:
/// - **facade** (本文件): importData / exportData 编排 + ImportResult class + _isoUtc helper
/// - **ExportCryptoService** (export_crypto_service.dart): vent text encrypt/decrypt 副作用封装
/// - **ExportAudioService** (export_audio_service.dart): vent audio metadata 序列化 + 校验
/// - **ExportSchemaService** (export_schema_service.dart): JSON schema version + 6 字段校验 + 旧表删除
///
/// **来源历史**:
/// - v0.7: 用户换手机/重装 app 时恢复数据 (不加密, 不依赖云端)
/// - v0.21 Round 22 (P0-3): vent 文字导出时 decrypt → 给明文 (跨设备恢复需要); 导入时再 encrypt
/// - v0.22 round 30 (P0): JSON schema version 1-4 兼容 (不破坏老用户数据)
/// - v0.22 round 32 (spzh 合规): vent 二次确认 (presentation 层不动, 数据层无感)
/// - v0.23 round 39 (P1-5): 加 50+ case test (data_export_round39_test.dart)
/// - v0.23 round 39 (P1-10): catch(_) → swallowError 集中器
/// - v0.23 round 40 (P2): exportToJson 5s timeout 防 drift stream hang
/// - v0.24 round 45: god class 拆 3 sub-service (本文件, **Sprint #5c**)
///
/// **隐私边界**:
/// - vent 文字: export 时 decrypt → 明文, import 时 encrypt → blob (PIPL §28)
/// - vent audio: **不导出文件** (跨设备路径失效), 只导 metadata 引用
/// - 二次确认: presentation 层 (data_management_section) 决定, service 不感知
///
/// **JSON schema version**:
/// - v1: 基础 (profile / contacts / medications / checkIns)
/// - v2: + reportHistories + moodEntries (v0.9)
/// - v3: + ventEntries 文字 (v0.15)
/// - v4 (current): 4D 情绪 energy/sleep/anxiety (v0.18)
library;

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
String _isoUtc(DateTime d) => d.toUtc().toIso8601String();

class DataExportService {
  final AppDatabase _db;
  final ReportHistoryRepository _reportRepo;
  final ExportCryptoService _cryptoService;
  final ExportAudioService _audioService;
  final ExportSchemaService _schemaService;

  /// 构造注入 (DI 模式, 跟 mood_dialog `MoodRecorderController` 同思路)
  ///
  /// **构造签名向后兼容** (Sprint #5c 不破): 保留 v0.23 round 39 时
  /// `DataExportService(db, [reportRepo, ventTextEncryption])` 3 参数位置签名,
  /// 内部把 `ventTextEncryption` 转发到 `ExportCryptoService(ventTextEncryption)`。
  /// 现有 50+ test 不用改, 跟 round 39 P1-5 加 test 时的签名一致。
  ///
  /// - `reportRepo`: ReportHistoryRepository, 默认 new ReportHistoryRepositoryImpl(_db)
  /// - `ventTextEncryption`: EncryptionService, 默认走单例 (跟 `EncryptionService()` 一致)
  DataExportService(
    this._db, [
    ReportHistoryRepository? reportRepo,
    EncryptionService? ventTextEncryption,
  ])  : _reportRepo = reportRepo ?? ReportHistoryRepositoryImpl(_db),
        _cryptoService = ExportCryptoService(ventTextEncryption),
        _audioService = const ExportAudioService(),
        _schemaService = const ExportSchemaService();

  /// 导出所有数据为 JSON 字符串
  ///
  /// **编排**: 拉所有 DB (5s timeout 防 drift stream hang) → 拼 JSON map
  /// (委托 3 sub-service) → JsonEncoder.withIndent
  ///
  /// **P4 fix**: v0.9 加上 `reportHistories` 和 `moodEntries`,
  /// 否则 v0.9 引入的核心表完全无法通过备份恢复。
  ///
  /// **P0-3 fix**: v0.18 (round 14 P0 batch) 加上 `ventEntries` 文字。
  /// 录音文件 (audioPath) **不**导出 — 文件在 app docs 目录, 重装/跨设备
  /// 路径失效, 无法直接复用。文字可跨设备, 所以导出。
  /// 重装 → 导入后, 树洞**文字**会恢复, 但录音会标 `hadAudio=true` 但点播放无效。
  ///
  /// **v0.23 round 40 (P2)**: 加 5s timeout 防 drift stream hang 导致导出阻塞
  Future<String> exportToJson({DateTime? now}) async {
    final profile = await _db.getUserProfile();
    const _streamTimeout = Duration(seconds: 5);
    final contacts = await _db
        .watchContacts()
        .first
        .timeout(_streamTimeout, onTimeout: () => const []);
    final medications = await _db
        .watchMedications()
        .first
        .timeout(_streamTimeout, onTimeout: () => const []);
    final checkIns = await _db
        .watchAllCheckIns()
        .first
        .timeout(_streamTimeout, onTimeout: () => const []);
    final reportHistories = await _reportRepo.getAll();
    final moodEntries = await _db.getAllMoodEntries();
    final ventEntries = await _db
        .watchVentEntries()
        .first
        .timeout(_streamTimeout, onTimeout: () => const []);

    final data = {
      'version': ExportSchemaService.currentVersion,
      'exportedAt': _isoUtc(now ?? DateTime.now()),
      'profile': profile == null
          ? null
          : {
              'userName': profile.userName,
              'checkInCycleHours': profile.checkInCycleHours,
              'firstLaunchAt': _isoUtc(profile.firstLaunchAt),
              // P0-10: 顺便带上 lastCheckInAt, 导入后立即可见
              if (profile.lastCheckInAt != null)
                'lastCheckInAt': _isoUtc(profile.lastCheckInAt!),
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
            'startDate': _isoUtc(m.startDate),
            'isActive': m.isActive,
          },
      ],
      'checkIns': [
        for (final c in checkIns)
          {
            'timestamp': _isoUtc(c.timestamp),
            'type': c.type,
            'medicationId': c.medicationId,
            'note': c.note,
          },
      ],
      'reportHistories': [
        for (final h in reportHistories)
          {
            'windowDays': h.windowDays,
            'generatedAt': _isoUtc(h.generatedAt),
            'userName': h.userName,
            'reportText': h.reportText,
          },
      ],
      'moodEntries': [
        for (final m in moodEntries)
          {
            'timestamp': _isoUtc(m.timestamp),
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
            'timestamp': _isoUtc(v.timestamp),
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
  ///
  /// **编排**: jsonDecode → version 校验 (委托) → 6 类 entity 校验插入
  /// (委托 6 个 `validate*` 静态 helper) → 拼 ImportResult
  ///
  /// **P12 fix**: 错误信息脱敏, 不再直接 `'$e'` 暴露内部细节
  /// **P13 fix**: 关键字段做长度/类型校验, 坏数据不写 DB
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

  /// 一句话摘要
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
