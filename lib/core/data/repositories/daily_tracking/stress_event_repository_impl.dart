// v0.30 round 91 (sub-spec 7 日常追踪): StressEventRepositoryImpl

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/domain/entities/stress_event.dart';
import 'package:chroniccare/domain/repositories/stress_event_repository.dart';
import 'package:drift/drift.dart' show Value;

/// StressEvent 仓库的 Drift 实现
///
/// R97-P1-1 (2026-08-07): implements [StressEventRepository] domain 接口
/// (跟 sleep_repository_impl.dart 同模式, 详见该文件注释)。
class StressEventRepositoryImpl implements StressEventRepository {
  final AppDatabase _db;

  StressEventRepositoryImpl(this._db);

  @override
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
