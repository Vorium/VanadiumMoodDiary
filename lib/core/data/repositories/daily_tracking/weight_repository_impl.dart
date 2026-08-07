// v0.30 round 91 (sub-spec 7 日常追踪): WeightRepositoryImpl

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/domain/entities/weight_entry.dart';
import 'package:chroniccare/domain/repositories/weight_repository.dart';
import 'package:drift/drift.dart' show Value;

/// Weight 仓库的 Drift 实现
///
/// R97-P1-1 (2026-08-07): implements [WeightRepository] domain 接口
/// (跟 sleep_repository_impl.dart 同模式, 详见该文件注释)。
class WeightRepositoryImpl implements WeightRepository {
  final AppDatabase _db;

  WeightRepositoryImpl(this._db);

  @override
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
