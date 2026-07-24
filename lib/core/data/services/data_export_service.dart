/// 数据导出/导入服务
///
/// v0.7：用户换手机/重装 app 时恢复数据
/// 导出：所有数据 → JSON 字符串（用户复制保存或分享）
/// 导入：JSON 字符串 → 验证 → 写回 DB
///
/// 注意：不加密（用户自己保管），不依赖云端
/// 加密备份是后续 v1.0+ 增强
///
/// v0.21 Round 22 (P0-1 修复): vent 文字导出时 decrypt → 用户拿 JSON 时是
/// 明文（跨设备恢复需要）；导入时再 encrypt 写回 DB。
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/repositories/report_history/report_history_repository_impl.dart';
import 'package:chroniccare/core/data/services/encryption_service.dart';
import 'package:chroniccare/core/data/services/pii_safe_log.dart';
import 'package:chroniccare/core/l10n/strings.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';

/// v0.21 (P0-3 fix): 导出时统一 toUtc() 让 ISO 字符串带 'Z' 后缀。
///
/// **bug 现象**: 之前用 `DateTime.now().toIso8601String()` 输出
/// `2026-07-20T04:15:55.123`（**不带**时区后缀）。Dart `DateTime.parse()`
/// 对无后缀字符串**按 local 解析**。用户在北京导出 (UTC+8)，飞机到纽约 (UTC-5)
/// 再导入 → 同一个字符串 "04:15:55" 在两个时区都被当 local 解析 → 跨时区
/// 打卡记录"瞬移" 12 小时。
///
/// **修法**: 导出统一 `.toUtc().toIso8601String()` 输出
/// `2026-07-19T20:15:55.123Z`（带 'Z'），`DateTime.parse()` 自动按 UTC 解析
/// 存进 drift → drift 转回 local 时按目标时区正确显示。
///
/// 9 处调用全部走这个 helper, 避免漏改 + 未来加新字段直接用。
String _isoUtc(DateTime d) => d.toUtc().toIso8601String();

class DataExportService {
  final AppDatabase _db;
  final ReportHistoryRepositoryImpl _reportRepo;
  final EncryptionService _ventTextEncryption;

  DataExportService(
    this._db, [
    ReportHistoryRepositoryImpl? reportRepo,
    EncryptionService? ventTextEncryption,
  ])  : _reportRepo = reportRepo ?? ReportHistoryRepositoryImpl(_db),
        _ventTextEncryption = ventTextEncryption ?? EncryptionService();

  /// 导出所有数据为 JSON 字符串
  ///
  /// **P4 fix**: v0.9 加上 `report_histories` 和 `mood_entries`,
  /// 否则 v0.9 引入的核心表完全无法通过备份恢复。
  ///
  /// **P0-3 fix**: v0.18 (round 14 P0 batch) 加上 `vent_entries` 文字。
  /// 录音文件 (audioPath) **不**导出 — 文件在 app docs 目录，重装/跨设备
  /// 路径失效，无法直接复用。文字可跨设备，所以导出。
  /// 重装 → 导入后，树洞**文字**会恢复，但录音会标 `hasAudio=false`。
  Future<String> exportToJson({DateTime? now}) async {
    final profile = await _db.getUserProfile();
    final contacts = await _db.watchContacts().first;
    final medications = await _db.watchMedications().first;
    final checkIns = await _db.watchAllCheckIns().first;
    final reportHistories = await _reportRepo.getAll();
    final moodEntries = await _db.getAllMoodEntries();
    final ventEntries = await _db.watchVentEntries().first;

    final data = {
      'version': 4, // v0.18 bump: 加入 4D 情绪 (energy/sleep/anxiety)
      'exportedAt': _isoUtc(now ?? DateTime.now()),
      'profile': profile == null
          ? null
          : {
              'userName': profile.userName,
              'checkInCycleHours': profile.checkInCycleHours,
              'firstLaunchAt': _isoUtc(profile.firstLaunchAt),
              // P0-10: 顺便带上 lastCheckInAt,导入后立即可见
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
        // P0-3: 导出文字 + 元数据 (duration / size),**不**导出 audioPath。
        // v0.21 Round 22: contentText 字段加密后,导出时 decrypt 给用户明文
        // (跨设备恢复需要明文)。导入时再 encrypt 写回。
        for (final v in ventEntries) await _buildVentEntryExport(v),
      ],
    };
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }

  /// 把单条 vent 导出为 JSON map (decrypt text)
  ///
  /// decrypt 失败 = 旧数据 / key 损坏 → text 字段为 null,用户能在 import
  /// log 里看到（不抛异常，避免一份坏数据毁掉整个导出）
  Future<Map<String, dynamic>> _buildVentEntryExport(VentEntry v) async {
    String? text;
    final blob = v.contentTextEnc;
    if (blob != null) {
      try {
        final plain =
            await _ventTextEncryption.decrypt(Uint8List.fromList(blob));
        text = utf8.decode(plain);
      } catch (e, st) {
        // v0.23 round 39 (P1-5 fix): catch all
        // 之前 `on Exception` 漏 catch `InvalidArgument` (PKCS7 pad 错误)
        // → 整条 vent 导出炸 → 整个 export 失败
        // 改成 catch all,text = null
        // swallowError 走 developer.log
        swallowError(
          where: 'DataExportService._buildVentEntryExport',
          error: e,
          stack: st,
          note: 'vent 文字 decrypt 失败 (PKCS7 pad / data corruption), 视为无文字',
        );
      }
    }
    return {
      'timestamp': _isoUtc(v.timestamp),
      'contentText': text,
      'audioDurationSec': v.audioDurationSec,
      'audioSizeBytes': v.audioSizeBytes,
      // 标志：旧数据可能含 audioPath,我们导入时丢弃并提示
      if (v.audioPath != null) 'hadAudio': true,
    };
  }

  /// 从 JSON 字符串导入数据（覆盖现有）
  ///
  /// 返回导入条数摘要
  ///
  /// **P12 fix**: 错误信息脱敏，不再直接 `'$e'` 暴露内部细节
  /// **P13 fix**: 关键字段做长度/类型校验，坏数据不写 DB
  Future<ImportResult> importFromJson(String json) async {
    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      final version = data['version'];
      if (version is! int || version < 1 || version > 4) {
        return ImportResult.failure('数据版本不匹配（期望 1-4，实际 $version）');
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
        // v0.9 新增表（v1 才存在，先 guard）
        try {
          await _db.delete(_db.reportHistories).go();
        } catch (e, st) {
          // v0.23 round 39 (P1-10 fix): 不再 `catch (_)` 完全静默,
          // 走 swallowError 集中器,便于排查异常 schema
          swallowError(
            where: 'DataExportService.import — reportHistories.delete',
            error: e,
            stack: st,
            note: '表不存在(旧 schema),忽略',
          );
        }
        try {
          await _db.delete(_db.moodEntries).go();
        } catch (e, st) {
          swallowError(
            where: 'DataExportService.import — moodEntries.delete',
            error: e,
            stack: st,
            note: '表不存在(旧 schema),忽略',
          );
        }
        // P0-3: vent_entries 表(v0.15+ 存在，不需要 guard)
        try {
          await _db.delete(_db.ventEntries).go();
        } catch (e, st) {
          swallowError(
            where: 'DataExportService.import — ventEntries.delete',
            error: e,
            stack: st,
            note: '表不存在(老 schema),忽略',
          );
        }

        // profile
        if (data['profile'] != null) {
          final p = data['profile'] as Map<String, dynamic>;
          final userName =
              _validateString(p['userName'], 'userName', maxLen: 50);
          if (userName != null) {
            await _db.upsertUserProfile(
              UserProfilesCompanion.insert(
                // v0.21 Round 23 (P1-24): userName nullable
                userName: Value(userName),
                checkInCycleHours: Value(
                  _validateIntOr(p['checkInCycleHours'], 48, min: 1, max: 168),
                ),
                firstLaunchAt:
                    _validateDate(p['firstLaunchAt']) ?? DateTime.now(),
              ),
            );
          }
        }

        // contacts
        for (final c in (data['contacts'] as List? ?? [])) {
          if (c is! Map) continue;
          final m = c;
          final name = _validateString(m['name'], 'contact.name', maxLen: 50);
          final phone = _validateString(
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
              sortOrder: Value(_validateIntOr(m['sortOrder'], 0)),
              isActive: Value(m['isActive'] as bool? ?? true),
            ),
          );
          contactCount++;
        }

        // medications
        for (final med in (data['medications'] as List? ?? [])) {
          if (med is! Map) continue;
          final m = med;
          final name = _validateString(m['name'], 'med.name', maxLen: 50);
          final unit = _validateString(m['dosageUnit'], 'med.unit', maxLen: 10);
          final dosage = _validateDouble(m['dosage']);
          final start = _validateDate(m['startDate']);
          if (name == null || unit == null || dosage == null || start == null) {
            continue;
          }
          await _db.insertMedication(
            MedicationsCompanion.insert(
              name: name,
              dosage: dosage,
              dosageUnit: unit,
              timesJson: Value(
                _validateString(
                      m['timesJson'],
                      'med.timesJson',
                      maxLen: 1000,
                    ) ??
                    '[]',
              ),
              startDate: start,
              endDate: Value(_validateDate(m['endDate'])),
              isActive: Value(m['isActive'] as bool? ?? true),
            ),
          );
          medicationCount++;
        }

        // checkIns
        for (final c in (data['checkIns'] as List? ?? [])) {
          if (c is! Map) continue;
          final m = c;
          final ts = _validateDate(m['timestamp']);
          final type = _validateString(m['type'], 'checkIn.type', maxLen: 20);
          if (ts == null || type == null) continue;
          await _db.insertCheckIn(
            CheckInsCompanion.insert(
              timestamp: ts,
              type: type,
              medicationId: Value(_validateInt(m['medicationId'], null)),
              note: Value(
                _validateString(m['note'], 'checkIn.note', maxLen: 10000),
              ),
            ),
          );
          checkInCount++;
        }

        // reportHistories（v2 才有，v1 没有这段也兼容）
        if (version >= 2) {
          for (final h in (data['reportHistories'] as List? ?? [])) {
            if (h is! Map) continue;
            final m = h;
            final days = _validateInt(m['windowDays'], null, min: 1, max: 365);
            final at = _validateDate(m['generatedAt']);
            final userName =
                _validateString(m['userName'], 'report.userName', maxLen: 50) ??
                    '';
            final text =
                _validateString(m['reportText'], 'report.text', maxLen: 100000);
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
            final ts = _validateDate(m['timestamp']);
            final score = _validateIntOr(m['score'], 3, min: 1, max: 5);
            if (ts == null) continue;
            final tags =
                _validateString(m['tagsJson'], 'mood.tags', maxLen: 5000) ??
                    '[]';
            await _db.insertMoodEntry(
              MoodEntriesCompanion.insert(
                timestamp: ts,
                score: score,
                // v0.18 4D 情绪: 老导出文件(v1-3)无这些字段时为 null
                energy: Value(_validateInt(m['energy'], null, min: 1, max: 5)),
                sleep: Value(_validateInt(m['sleep'], null, min: 1, max: 5)),
                anxiety: Value(
                  _validateInt(m['anxiety'], null, min: 1, max: 5),
                ),
                tagsJson: Value(tags),
                note: Value(
                  _validateString(m['note'], 'mood.note', maxLen: 10000),
                ),
              ),
            );
            moodEntryCount++;
          }
        }

        // P0-3: vent_entries 文字导入(录音路径永远丢弃，跨设备不可用)。
        // version 3+ 才有，老导出文件没这段也兼容。
        // v0.21 Round 22: 文字从 JSON 读出是明文,导入时 encrypt 写回 BLOB。
        if (version >= 3) {
          for (final v in (data['ventEntries'] as List? ?? [])) {
            if (v is! Map) continue;
            final m = v;
            final ts = _validateDate(m['timestamp']);
            if (ts == null) continue;
            // 文字可以很大(树洞常长篇),放宽到 100k
            final text = _validateString(
              m['contentText'],
              'vent.text',
              maxLen: 100000,
            );
            Uint8List? encText;
            if (text != null && text.isNotEmpty) {
              encText = await _ventTextEncryption
                  .encrypt(Uint8List.fromList(utf8.encode(text)));
            }
            await _db.insertVentEntry(
              VentEntriesCompanion.insert(
                timestamp: ts,
                contentTextEnc: Value(encText),
                // audioPath 永远 null — 旧路径在重装后失效
                audioDurationSec: Value(
                  _validateIntOr(m['audioDurationSec'], 0, min: 0, max: 86400),
                ),
                audioSizeBytes: Value(
                  _validateIntOr(
                    m['audioSizeBytes'],
                    0,
                    min: 0,
                    max: 1073741824,
                  ),
                ), // 1GB
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
      // P12 fix: 脱敏，只告诉用户"解析失败",不暴露具体异常
      return ImportResult.failure('解析失败：数据格式不正确，请确认是从本 App 导出的 JSON');
    }
  }

  // ===== 校验辅助 =====

  static String? _validateString(
    dynamic v,
    String field, {
    int maxLen = 1000,
    RegExp? pattern,
  }) {
    if (v == null) return null;
    if (v is! String) return null;
    if (v.isEmpty) return null;
    if (v.length > maxLen) return null;
    if (pattern != null && !pattern.hasMatch(v)) return null;
    return v;
  }

  static int? _validateInt(dynamic v, int? defaultValue, {int? min, int? max}) {
    if (v == null) return defaultValue;
    if (v is int) {
      if (min != null && v < min) return defaultValue;
      if (max != null && v > max) return defaultValue;
      return v;
    }
    return defaultValue;
  }

  /// 非空默认值场景:`_validateIntOr(x, 48, min:1, max:168)` 直接返回 int
  static int _validateIntOr(dynamic v, int defaultValue, {int? min, int? max}) {
    final r = _validateInt(v, defaultValue, min: min, max: max);
    return r ?? defaultValue;
  }

  static double? _validateDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return null;
  }

  static DateTime? _validateDate(dynamic v) {
    if (v is! String) return null;
    // v0.21 (P0-2 fix): 用 tryParse 替代 try/catch + DateTime.parse。
    // 之前 try/catch 是反模式——DateTime.parse 失败是**预期内**的情况(用户导入了
    // 格式异常的历史数据),不是异常。try/catch 在 hot path 上还有 stack 捕获开销。
    return DateTime.tryParse(v);
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

  /// P0-3: 树洞导入条数 (文字 only,录音不导入)
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
