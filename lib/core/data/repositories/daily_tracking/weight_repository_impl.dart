// v0.30 round 91 (sub-spec 7 日常追踪): WeightRepositoryImpl

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/domain/entities/weight_entry.dart';
import 'package:drift/drift.dart' show Value;

/// Weight 仓库的 Drift 实现
class WeightRepositoryImpl {
  final AppDatabase _db;

  WeightRepositoryImpl(this._db);

  Stream<List<WeightEntryEntity>> watchAll() {
    return _db.weightDao.watchAll().map(
          (rows) => rows
              .map(
                (r) => WeightEntryEntity(
                  id: r.id,
                  timestamp: r.timestamp,
                  weightKg: r.weightKg,
                  bmi: r.bmi,
                  note: r.note,
                ),
              )
              .toList(growable: false),
        );
  }

  Future<int> add({
    required DateTime timestamp,
    required double weightKg,
    double? bmi,
    String? note,
  }) {
    return _db.weightDao.insert(
      WeightEntriesCompanion.insert(
        timestamp: timestamp,
        weightKg: weightKg,
        bmi: Value(bmi),
        note: Value(note),
      ),
    );
  }

  Future<int> delete(int id) => _db.weightDao.delete(id);
}
