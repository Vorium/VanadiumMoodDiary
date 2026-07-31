// v0.14 (Round 12A) CheckInRepositoryImpl — data 层 Drift 实现
//
// 实现 domain/repositories/check_in_repository.dart 的 abstract 接口。
// 所有读路径都 .toEntity() 转 entity，UI 看到的是 entity 不是 Drift row。

import 'dart:convert' show jsonEncode;

import 'package:drift/drift.dart' show Value;

import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/repositories/check_in_repository.dart';
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/mappers/check_in/check_in_mapper.dart';
import 'package:chroniccare/core/shared/json_codec.dart';

/// v0.27 round 63 (P1-6 修复): 抽 _resolveTimestamp 顶层 helper
///
/// 之前 3 处 `at ?? DateTime.now()` 重复 pattern (checkIn / addTempMedication /
/// saveAssessment)。caller 不传 timestamp 时调, 跨 midnight 同一函数多次调
/// `DateTime.now()` 理论会拿到不同秒 (R19B DateTime race 纪律)。
/// 抽 helper 强制 1 次取, 防止未来 caller 复用 pattern 时再写错。
DateTime _resolveTimestamp(DateTime? at) => at ?? DateTime.now();

/// CheckIn 仓库的 Drift 实现
class CheckInRepositoryImpl implements CheckInRepository {
  final AppDatabase _db;

  CheckInRepositoryImpl(this._db);

  @override
  Stream<List<CheckInEntity>> watchAll() {
    return _db.checkInDao.watchAll().map(
          (rows) => rows.map((r) => r.toEntity()).toList(growable: false),
        );
  }

  @override
  Stream<List<CheckInEntity>> watchAssessments() {
    return _db.checkInDao.watchAssessments().map(
          (rows) => rows.map((r) => r.toEntity()).toList(growable: false),
        );
  }

  @override
  Stream<CheckInEntity?> watchToday() {
    return _db.checkInDao.watchToday().map((row) => row?.toEntity());
  }

  @override
  Stream<List<CheckInEntity>> watchNormalCheckIns() {
    return _db.checkInDao.watchNormal().map(
          (rows) => rows.map((r) => r.toEntity()).toList(growable: false),
        );
  }

  @override
  Future<CheckInEntity?> getLatestNormalCheckIn() async {
    final row = await _db.checkInDao.getLatestNormal();
    return row?.toEntity();
  }

  @override
  Future<DateTime?> getLatestAssessmentTimestamp() {
    return _db.checkInDao.getLatestAssessmentTimestamp();
  }

  @override
  Future<int> checkIn({DateTime? at, int? medicationId}) {
    return _db.checkInDao.insert(
      CheckInsCompanion.insert(
        timestamp: _resolveTimestamp(at),
        type: CheckInType.normal.wire,
        medicationId: Value(medicationId),
      ),
    );
  }

  @override
  Future<int> addTempMedication({
    required String name,
    required String note,
    DateTime? at,
  }) {
    return _db.checkInDao.insert(
      CheckInsCompanion.insert(
        timestamp: _resolveTimestamp(at),
        type: CheckInType.temp.wire,
        note: Value(
          JsonCodec.buildTempMedNote(name: name, description: note),
        ),
      ),
    );
  }

  @override
  Future<int> saveAssessment({
    required String scale,
    required List<int> scores,
    required int total,
    DateTime? at,
  }) {
    final note = jsonEncode({
      'scale': scale,
      'scores': scores,
      'total': total,
    });
    return _db.checkInDao.insert(
      CheckInsCompanion.insert(
        timestamp: _resolveTimestamp(at),
        type: scale, // 'phq9' / 'gad7' (wire 与 id 同名)
        note: Value(note),
      ),
    );
  }
}
