// v1.1.0+171 R125 (R110 feature-first 阶段 1) — AnxietyAgitationRepository
// abstract interface (样板: 从 lib/domain/repositories/anxiety_agitation_repository.dart 迁)
//
// 4 层架构: domain 0 flutter 0 drift, 跟 R110 阶段 1 设计一致。

import 'package:chroniccare/features/daily_tracking/domain/entities/anxiety_agitation_entry.dart';

/// 焦虑急躁仓库 (domain 接口, R125 阶段 1 样板迁移)
abstract class AnxietyAgitationRepository {
  Stream<List<AnxietyAgitationEntryEntity>> watchAll();

  Future<int> add({
    required DateTime timestamp,
    required int anxietyScore,
    required int agitationScore,
    String? note,
  });

  Future<int> delete(int id);
}
