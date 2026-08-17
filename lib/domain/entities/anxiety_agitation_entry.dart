// v1.1.0+171 R125 (R110 feature-first 阶段 1) — 旧路径 re-export
//
// R110 阶段 1 样板: 旧路径 lib/domain/entities/anxiety_agitation_entry.dart
// 保留为 re-export, 现有用户 (repository_impl 等) 仍能 import, 避免大批
// 改动。R110 阶段 2 批量删旧路径。

export 'package:chroniccare/features/daily_tracking/domain/entities/anxiety_agitation_entry.dart'
    show AnxietyAgitationEntryEntity;
