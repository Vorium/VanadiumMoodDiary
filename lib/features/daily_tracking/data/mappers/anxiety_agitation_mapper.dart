// v1.1.0+171 R125 (R110 feature-first 阶段 1) — AnxietyAgitation row ↔ entity 翻译
//
// R110 阶段 1 新增 mapper (现有 daily_tracking 子表无独立 mapper, 走 inline
// 翻译在 repository_impl 内)。R110 阶段 2+ 抽 mapper 是 best practice
// (跟 R119 mood_entry_mapper / R120 vent_mapper 模式对齐)。
//
// row (drift 生成 AnxietyAgitationEntry) ↔ entity (domain AnxietyAgitationEntryEntity) 翻译。

import 'package:chroniccare/features/daily_tracking/domain/entities/anxiety_agitation_entry.dart';
import 'package:drift/drift.dart' show Value;

/// AnxietyAgitation row → entity 翻译 (R125 阶段 1 新增)
AnxietyAgitationEntryEntity anxietyAgitationRowToEntity(dynamic row) {
  // row 是 drift 生成 AnxietyAgitationEntry data class, 字段跟 entity 对齐
  return AnxietyAgitationEntryEntity(
    id: row.id as int,
    timestamp: row.timestamp as DateTime,
    anxietyScore: row.anxietyScore as int,
    agitationScore: row.agitationScore as int,
    note: row.note as String?,
  );
}

/// entity → companion (insert / update 用) 翻译 (R125 阶段 1 新增)
Value<dynamic> anxietyAgitationEntityToCompanion(AnxietyAgitationEntryEntity entity) {
  // R110 阶段 1 简化: 现阶段只暴露 row→entity, 写操作走原 repository_impl
  // (R110 阶段 2 抽 mapper 时再加 entity→companion)
  throw UnimplementedError(
    'R125 阶段 1: anxietyAgitationEntityToCompanion 暂未实现, 写操作走原 repository_impl',
  );
}
