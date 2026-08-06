// v0.30 round 91 (sub-spec 7 日常追踪): StressEventRepositoryImpl

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/domain/entities/stress_event.dart';
import 'package:drift/drift.dart' show Value;

/// StressEvent 仓库的 Drift 实现
class StressEventRepositoryImpl {
  final AppDatabase _db;

  StressEventRepositoryImpl(this._db);

  Stream<List<StressEventEntity>> watchAll() {
    return _db.stressEventDao.watchAll().map(
          (rows) => rows
              .map(
                (r) => StressEventEntity(
                  id: r.id,
                  timestamp: r.timestamp,
                  eventType: r.eventType,
                  intensity: r.intensity,
                  note: r.note,
                  linkedMoodEntryId: r.linkedMoodEntryId,
                ),
              )
              .toList(growable: false),
        );
  }

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

  Future<int> delete(int id) => _db.stressEventDao.delete(id);
}
