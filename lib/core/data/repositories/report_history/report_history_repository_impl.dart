// v0.16 (Round 19) ReportHistoryRepositoryImpl — data 层 Drift 实现
//
// 对应 domain/entities/report_history_entity.dart
// UI 只用 ReportHistoryEntity，不直接碰 Drift row

import 'package:chroniccare/domain/entities/report_history_entity.dart';
import 'package:chroniccare/domain/repositories/report_history_repository.dart';
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/mappers/report_history_mapper.dart';

class ReportHistoryRepositoryImpl implements ReportHistoryRepository {
  final AppDatabase _db;
  ReportHistoryRepositoryImpl(this._db);

  @override
  Stream<List<ReportHistoryEntity>> watchAll() {
    return _db.watchReportHistories().map(
          (rows) => rows.map(reportHistoryFromRow).toList(growable: false),
        );
  }

  @override
  Future<List<ReportHistoryEntity>> getAll() async {
    final rows = await _db.getAllReportHistories();
    return rows.map(reportHistoryFromRow).toList(growable: false);
  }

  @override
  Future<int> delete(int id) => _db.deleteReportHistory(id);

  @override
  Future<int> clearAll() => _db.clearAllReportHistories();

  @override
  Future<int> insert({
    required int windowDays,
    required DateTime generatedAt,
    required String userName,
    required String reportText,
  }) {
    return _db.insertReportHistory(
      ReportHistoriesCompanion.insert(
        windowDays: windowDays,
        generatedAt: generatedAt,
        userName: userName,
        reportText: reportText,
      ),
    );
  }
}
