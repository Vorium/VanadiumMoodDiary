// v0.14 (Round 12A) CheckInRepositoryImpl — data 层 Drift 实现
//
// 实现 domain/repositories/check_in_repository.dart 的 abstract 接口。
// 所有读路径都 .toEntity() 转 entity，UI 看到的是 entity 不是 Drift row。
library;

import 'package:drift/drift.dart' show Value;

import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/repositories/check_in_repository.dart';
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/mappers/check_in/check_in_mapper.dart';
import 'package:chroniccare/core/shared/json_codec.dart';

/// CheckIn 仓库的 Drift 实现
class CheckInRepositoryImpl implements CheckInRepository {
  final AppDatabase _db;

  CheckInRepositoryImpl(this._db);

  @override
  Stream<List<CheckInEntity>> watchAll() {
    return _db.watchAllCheckIns().map(
          (rows) => rows.map((r) => r.toEntity()).toList(growable: false),
        );
  }

  @override
  Stream<List<CheckInEntity>> watchAssessments() {
    return _db.watchAssessments().map(
          (rows) => rows.map((r) => r.toEntity()).toList(growable: false),
        );
  }

  @override
  Stream<CheckInEntity?> watchToday() {
    return _db.watchTodayCheckIn().map((row) => row?.toEntity());
  }

  @override
  Stream<List<CheckInEntity>> watchNormalCheckIns() {
    return _db.watchNormalCheckIns().map(
          (rows) => rows.map((r) => r.toEntity()).toList(growable: false),
        );
  }

  @override
  Future<CheckInEntity?> getLatestNormalCheckIn() async {
    final row = await _db.getLatestNormalCheckIn();
    return row?.toEntity();
  }

  @override
  Future<DateTime?> getLatestAssessmentTimestamp() {
    return _db.getLatestAssessmentTimestamp();
  }

  @override
  Future<int> checkIn({DateTime? at, int? medicationId}) {
    return _db.insertCheckIn(
      CheckInsCompanion.insert(
        timestamp: at ?? DateTime.now(),
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
    return _db.insertCheckIn(
      CheckInsCompanion.insert(
        timestamp: at ?? DateTime.now(),
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
    final note =
        '{"scale":"$scale","scores":${_encodeScores(scores)},"total":$total}';
    return _db.insertCheckIn(
      CheckInsCompanion.insert(
        timestamp: at ?? DateTime.now(),
        type: scale, // 'phq9' / 'gad7' (wire 与 id 同名)
        note: Value(note),
      ),
    );
  }

  /// 编码评分列表为 JSON
  static String _encodeScores(List<int> scores) => '[${scores.join(',')}]';
}
