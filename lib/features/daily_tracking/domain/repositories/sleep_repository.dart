// v1.1.0+173 R126 (R110 feature-first 阶段 2 step 2) — sleep abstract
// (R125 样板模式 + R126 step 1 stress_event abstract 同模式)
//
// 4 层架构: domain 0 flutter 0 drift, 跟 R110 阶段 1/2 设计一致。

import 'package:chroniccare/features/daily_tracking/domain/entities/sleep_entry.dart';

/// 睡眠仓库 (domain 接口, R126 阶段 2 step 2 迁移)
abstract class SleepRepository {
  Stream<List<SleepEntryEntity>> watchAll();

  Future<int> add({
    required DateTime date,
    required DateTime bedtime,
    required DateTime wakeTime,
    required int durationMin,
    int? regularityScore,
    String? note,
  });

  Future<int> delete(int id);
}
