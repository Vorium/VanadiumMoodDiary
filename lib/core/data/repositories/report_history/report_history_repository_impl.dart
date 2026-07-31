// v0.16 (Round 19) ReportHistoryRepositoryImpl — data 层 Drift 实现
//
// 对应 domain/entities/report_history_entity.dart
// UI 只用 ReportHistoryEntity，不直接碰 Drift row

import 'package:chroniccare/domain/entities/report_history_entity.dart';
import 'package:chroniccare/domain/repositories/report_history_repository.dart';
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/mappers/report_history_mapper.dart';
import 'package:drift/drift.dart' show Value;

class ReportHistoryRepositoryImpl implements ReportHistoryRepository {
  final AppDatabase _db;
  ReportHistoryRepositoryImpl(this._db);

  @override
  Stream<List<ReportHistoryEntity>> watchAll() {
    return _db.reportDao.watchAll().map(
          (rows) => rows.map((r) => r.toEntity()).toList(growable: false),
        );
  }

  @override
  Future<List<ReportHistoryEntity>> getAll() async {
    final rows = await _db.reportDao.getAll();
    return rows.map((r) => r.toEntity()).toList(growable: false);
  }

  @override
  Future<int> delete(int id) => _db.reportDao.delete(id);

  @override
  Future<int> clearAll() => _db.reportDao.clearAll();

  @override
  Future<int> insert({
    required int windowDays,
    required DateTime generatedAt,
    // v0.21 Round 23 (P1-24): userName 改 nullable
    String? userName,
    required String reportText,
  }) {
    return _db.reportDao.insert(
      ReportHistoriesCompanion.insert(
        windowDays: windowDays,
        generatedAt: generatedAt,
        userName: Value(userName),
        reportText: reportText,
      ),
    );
  }
}
