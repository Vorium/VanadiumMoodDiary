// v1.1.0+174 R126 (R110 feature-first 阶段 2 step 3) — weight impl
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/features/daily_tracking/data/mappers/weight_mapper.dart';
import 'package:chroniccare/features/daily_tracking/domain/entities/weight_entry.dart';
import 'package:chroniccare/features/daily_tracking/domain/repositories/weight_repository.dart';
import 'package:drift/drift.dart' show Value;

class WeightRepositoryImpl implements WeightRepository {
  final AppDatabase _db;

  WeightRepositoryImpl(this._db);

  @override
  Stream<List<WeightEntryEntity>> watchAll() {
    return _db.weightDao.watchAll().map(
          (rows) => rows.map(weightRowToEntity).toList(growable: false),
        );
  }

  @override
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

  @override
  Future<int> delete(int id) => _db.weightDao.delete(id);
}
