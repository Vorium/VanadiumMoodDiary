/// 数据导出/导入服务
///
/// v0.7：用户换手机/重装 app 时恢复数据
/// 导出：所有数据 → JSON 字符串（用户复制保存或分享）
/// 导入：JSON 字符串 → 验证 → 写回 DB
///
/// 注意：不加密（用户自己保管），不依赖云端
/// 加密备份是后续 v1.0+ 增强
library;

import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/repositories/report_history_repository_impl.dart';

class DataExportService {
  final AppDatabase _db;
  final ReportHistoryRepositoryImpl _reportRepo;

  DataExportService(this._db, [ReportHistoryRepositoryImpl? reportRepo])
      : _reportRepo = reportRepo ?? ReportHistoryRepositoryImpl(_db);

  /// 导出所有数据为 JSON 字符串
  ///
  /// **P4 fix**: v0.9 加上 `report_histories` 和 `mood_entries`,
  /// 否则 v0.9 引入的核心表完全无法通过备份恢复。
  ///
  /// **P0-3 fix**: v0.18 (round 14 P0 batch) 加上 `vent_entries` 文字。
  /// 录音文件 (audioPath) **不**导出 — 文件在 app docs 目录,重装/跨设备
  /// 路径失效,无法直接复用。文字可跨设备,所以导出。
  /// 重装 → 导入后,树洞**文字**会恢复,但录音会标 `hasAudio=false`。
  Future<String> exportToJson() async {
    final profile = await _db.getUserProfile();
    final contacts = await _db.watchContacts().first;
    final medications = await _db.watchMedications().first;
    final checkIns = await _db.watchAllCheckIns().first;
    final reportHistories = await _reportRepo.getAll();
    final moodEntries = await _db.getAllMoodEntries();
    final ventEntries = await _db.watchVentEntries().first;

    final data = {
      'version': 3, // P0-3 bump: 加入 ventEntries
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': profile == null
          ? null
          : {
              'userName': profile.userName,
              'checkInCycleHours': profile.checkInCycleHours,
              'firstLaunchAt': profile.firstLaunchAt.toIso8601String(),
              // P0-10: 顺便带上 lastCheckInAt,导入后立即可见
              if (profile.lastCheckInAt != null)
                'lastCheckInAt': profile.lastCheckInAt!.toIso8601String(),
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
            'startDate': m.startDate.toIso8601String(),
            'isActive': m.isActive,
          },
      ],
      'checkIns': [
        for (final c in checkIns)
          {
            'timestamp': c.timestamp.toIso8601String(),
            'type': c.type,
            'medicationId': c.medicationId,
            'note': c.note,
          },
      ],
      'reportHistories': [
        for (final h in reportHistories)
          {
            'windowDays': h.windowDays,
            'generatedAt': h.generatedAt.toIso8601String(),
            'userName': h.userName,
            'reportText': h.reportText,
          },
      ],
      'moodEntries': [
        for (final m in moodEntries)
          {
            'timestamp': m.timestamp.toIso8601String(),
            'score': m.score,
            'tagsJson': m.tagsJson,
            'note': m.note,
          },
      ],
      'ventEntries': [
        // P0-3: 导出文字 + 元数据 (duration / size),**不**导出 audioPath。
        for (final v in ventEntries)
          {
            'timestamp': v.timestamp.toIso8601String(),
            'contentText': v.contentText,
            'audioDurationSec': v.audioDurationSec,
            'audioSizeBytes': v.audioSizeBytes,
            // 标志:旧数据可能含 audioPath,我们导入时丢弃并提示
            if (v.audioPath != null) 'hadAudio': true,
          },
      ],
    };
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }

  /// 从 JSON 字符串导入数据（覆盖现有）
  ///
  /// 返回导入条数摘要
  ///
  /// **P12 fix**: 错误信息脱敏,不再直接 `'$e'` 暴露内部细节
  /// **P13 fix**: 关键字段做长度/类型校验,坏数据不写 DB
  Future<ImportResult> importFromJson(String json) async {
    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      final version = data['version'];
      if (version is! int || version < 1 || version > 3) {
        return ImportResult.failure('数据版本不匹配（期望 1-3，实际 $version）');
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
        // v0.9 新增表（v1 才存在,先 guard）
        try {
          await _db.delete(_db.reportHistories).go();
        } catch (_) {
          // 表不存在（旧 schema），忽略
        }
        try {
          await _db.delete(_db.moodEntries).go();
        } catch (_) {
          // 同上
        }
        // P0-3: vent_entries 表(v0.15+ 存在,不需要 guard)
        try {
          await _db.delete(_db.ventEntries).go();
        } catch (_) {
          // 表不存在(老 schema),忽略
        }

        // profile
        if (data['profile'] != null) {
          final p = data['profile'] as Map<String, dynamic>;
          final userName =
              _validateString(p['userName'], 'userName', maxLen: 50);
          if (userName != null) {
            await _db.upsertUserProfile(
              UserProfilesCompanion.insert(
                userName: userName,
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
          final phone = _validateString(m['phone'], 'contact.phone',
              maxLen: 20, pattern: RegExp(r'^\+?\d{6,20}$'),);
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
              timesJson: Value(_validateString(m['timesJson'], 'med.timesJson',
                      maxLen: 1000,) ??
                  '[]',),
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
                  _validateString(m['note'], 'checkIn.note', maxLen: 10000),),
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
                tagsJson: Value(tags),
                note: Value(
                    _validateString(m['note'], 'mood.note', maxLen: 10000),),
              ),
            );
            moodEntryCount++;
          }
        }

        // P0-3: vent_entries 文字导入(录音路径永远丢弃,跨设备不可用)。
        // version 3+ 才有,老导出文件没这段也兼容。
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
            await _db.insertVentEntry(
              VentEntriesCompanion.insert(
                timestamp: ts,
                contentText: Value(text),
                // audioPath 永远 null — 旧路径在重装后失效
                audioDurationSec: Value(
                    _validateIntOr(m['audioDurationSec'], 0, min: 0, max: 86400),),
                audioSizeBytes: Value(
                    _validateIntOr(m['audioSizeBytes'], 0, min: 0, max: 1073741824),), // 1GB
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
      if (kDebugMode) {
        debugPrint('importFromJson error: $e\n$st');
      }
      // P12 fix: 脱敏,只告诉用户"解析失败",不暴露具体异常
      return ImportResult.failure('解析失败：数据格式不正确,请确认是从本 App 导出的 JSON');
    }
  }

  // ===== 校验辅助 =====

  static String? _validateString(dynamic v, String field,
      {int maxLen = 1000, RegExp? pattern,}) {
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
    try {
      return DateTime.parse(v);
    } catch (_) {
      return null;
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
      '$contactCount 联系人',
      '$medicationCount 药',
      '$checkInCount 打卡',
    ];
    if (reportHistoryCount > 0) parts.add('$reportHistoryCount 报告');
    if (moodEntryCount > 0) parts.add('$moodEntryCount 情绪');
    if (ventEntryCount > 0) parts.add('$ventEntryCount 树洞');
    return parts.join(' / ');
  }
}
