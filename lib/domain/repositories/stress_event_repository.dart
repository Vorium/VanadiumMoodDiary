// v1.1.0+172 R126 (R110 feature-first 阶段 2) — 旧路径 re-export
//
// R126 阶段 2 step 1 样板: 旧路径 lib/domain/repositories/stress_event_repository.dart
// 保留为 re-export, 现有用户仍能 import。R126 阶段 2 step 2+ 批量删旧路径。

export 'package:chroniccare/features/daily_tracking/domain/repositories/stress_event_repository.dart'
    show StressEventRepository;
