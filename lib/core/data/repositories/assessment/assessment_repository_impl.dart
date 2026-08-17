/// 评估 Repository 实现 (跨 10 量表统一入口, 走 check_ins 表)
///
/// **R126 续 评估 1 commit 整包 (1.1.0+176)**: 实际定义已迁到
/// `lib/features/assessment/data/repositories/assessment_repository_impl.dart`。
/// 本文件 re-export 保持旧 import path 兼容 (现有用户 0 改动)。
library;

export 'package:chroniccare/features/assessment/data/repositories/assessment_repository_impl.dart';
