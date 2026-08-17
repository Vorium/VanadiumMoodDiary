// v1.1.0+172 R126 (R110 feature-first 阶段 2) — stress_event abstract
// (R125 阶段 1 样板, R126 阶段 2 step 1 扩第 2 子表)
//
// 4 层架构: domain 0 flutter 0 drift, 跟 R110 阶段 1/2 设计一致。

import 'package:chroniccare/features/daily_tracking/domain/entities/stress_event.dart';

/// 生活事件/应激源仓库 (domain 接口, R126 阶段 2 step 1 迁移)
abstract class StressEventRepository {
  Stream<List<StressEventEntity>> watchAll();

  Future<int> add({
    required DateTime timestamp,
    required String eventType,
    required int intensity,
    String? note,
    int? linkedMoodEntryId,
  });

  Future<int> delete(int id);
}
