import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../utils/json_codec.dart';

/// 打卡仓库
class CheckInRepository {
  final AppDatabase _db;

  CheckInRepository(this._db);

  /// 监听所有打卡记录（按时间倒序）
  Stream<List<CheckIn>> watchAll() => _db.watchAllCheckIns();

  /// 监听所有评估记录（PHQ-9 / GAD-7，按时间正序）
  Stream<List<CheckIn>> watchAssessments() => _db.watchAssessments();

  /// 监听今天的打卡
  Stream<CheckIn?> watchToday() => _db.watchTodayCheckIn();

  /// 打卡（normal 类型）
  Future<int> checkIn({DateTime? at, int? medicationId}) {
    return _db.insertCheckIn(
      CheckInsCompanion.insert(
        timestamp: at ?? DateTime.now(),
        type: 'normal',
        medicationId: Value(medicationId),
      ),
    );
  }

  /// 临时吃药（不影响 streak）
  ///
  /// v0.9：note 改为结构化 JSON `{"name":"...","desc":"..."}`
  /// 解决"布洛芬: 200mg: 头痛"被截断的边界问题（B7 fix）
  Future<int> addTempMedication({
    required String name,
    required String note,
    DateTime? at,
  }) {
    return _db.insertCheckIn(
      CheckInsCompanion.insert(
        timestamp: at ?? DateTime.now(),
        type: 'temp',
        note: Value(
          JsonCodec.buildTempMedNote(name: name, description: note),
        ),
      ),
    );
  }

  /// 保存量表评估（PHQ-9 / GAD-7）
  ///
  /// 复用了 check_ins 表：type='phq9' / 'gad7'，note 存 JSON
  /// 这样做的好处是：
  /// 1. 不需要 schema 迁移
  /// 2. streak 计算已按 type 过滤，不会污染
  /// 3. watchAll() 也能一并拉取
  Future<int> saveAssessment({
    required String scale,
    required List<int> scores,
    required int total,
    DateTime? at,
  }) {
    final note = '{"scale":"$scale","scores":${_encodeScores(scores)},"total":$total}';
    return _db.insertCheckIn(
      CheckInsCompanion.insert(
        timestamp: at ?? DateTime.now(),
        type: scale,
        note: Value(note),
      ),
    );
  }

  /// 编码评分列表为 JSON
  static String _encodeScores(List<int> scores) => '[${scores.join(',')}]';
}
