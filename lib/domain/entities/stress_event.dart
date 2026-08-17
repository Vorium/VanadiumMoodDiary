// v1.1.0+172 R126 (R110 feature-first 阶段 2) — 旧路径 re-export
//
// R126 阶段 2 step 1 样板: 旧路径 lib/domain/entities/stress_event.dart
// 保留为 re-export, 现有用户 (repository_impl 等) 仍能 import, 避免大批
// 改动。R126 阶段 2 step 2+ 批量删旧路径。

export 'package:chroniccare/features/daily_tracking/domain/entities/stress_event.dart'
    show StressEventEntity;
