// v1.1.0+173 R126 (R110 feature-first 阶段 2 step 2) — 旧路径 re-export
//
// R126 阶段 2 step 2 样板: 旧路径 lib/domain/repositories/sleep_repository.dart
// 保留为 re-export, 现有用户仍能 import。R126 阶段 2 step 3+ 批量删旧路径。

export 'package:chroniccare/features/daily_tracking/domain/repositories/sleep_repository.dart'
    show SleepRepository;
