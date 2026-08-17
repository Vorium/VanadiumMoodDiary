// v1.1.0+172 R126 (R110 feature-first 阶段 2) — stress_event impl
// (R125 阶段 1 样板, R126 阶段 2 step 1 扩第 2 子表)
//
// 跟 R125 anxiety_agitation_repository_impl 模式一致:
// - row→entity 翻译走新 mapper (stressEventRowToEntity)
// - watchAll / add / delete 3 method, 跟 R125 样板同模式
// - add 走 StressEventsCompanion.insert

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/features/daily_tracking/data/mappers/stress_event_mapper.dart';
import 'package:chroniccare/features/daily_tracking/domain/entities/stress_event.dart';
import 'package:chroniccare/features/daily_tracking/domain/repositories/stress_event_repository.dart';
import 'package:drift/drift.dart' show Value;

/// StressEvent 仓库的 Drift 实现 (R126 阶段 2 step 1 迁移)
class StressEventRepositoryImpl implements StressEventRepository {
  final AppDatabase _db;

  StressEventRepositoryImpl(this._db);

  @override
  Stream<List<StressEventEntity>> watchAll() {
    return _db.stressEventDao.watchAll().map(
          (rows) => rows.map(stressEventRowToEntity).toList(growable: false),
        );
  }

  @override
  Future<int> add({
    required DateTime timestamp,
    required String eventType,
    required int intensity,
    String? note,
    int? linkedMoodEntryId,
  }) {
    return _db.stressEventDao.insert(
      StressEventsCompanion.insert(
        timestamp: timestamp,
        eventType: eventType,
        intensity: intensity,
        note: Value(note),
        linkedMoodEntryId: Value(linkedMoodEntryId),
      ),
    );
  }

  @override
  Future<int> delete(int id) => _db.stressEventDao.delete(id);
}
