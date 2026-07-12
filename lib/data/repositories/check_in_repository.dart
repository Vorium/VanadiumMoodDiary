import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// 打卡仓库
class CheckInRepository {
  final AppDatabase _db;

  CheckInRepository(this._db);

  /// 监听所有打卡记录（按时间倒序）
  Stream<List<CheckIn>> watchAll() => _db.watchAllCheckIns();

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
  Future<int> addTempMedication({
    required String name,
    required String note,
    DateTime? at,
  }) {
    return _db.insertCheckIn(
      CheckInsCompanion.insert(
        timestamp: at ?? DateTime.now(),
        type: 'temp',
        note: Value('$name: $note'),
      ),
    );
  }
}
