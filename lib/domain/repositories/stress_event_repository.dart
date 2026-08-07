// v0.30 round 91 (sub-spec 7 日常追踪): StressEventRepository — domain 层 abstract
//
// R97-P1-1 (2026-08-07): 新增 abstract interface, 修复 4 层架构违规
// (跟 sleep_repository.dart 同模式, 详见该文件注释)。
import 'package:chroniccare/domain/entities/stress_event.dart';

/// 应激源仓库 (domain 接口)
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
