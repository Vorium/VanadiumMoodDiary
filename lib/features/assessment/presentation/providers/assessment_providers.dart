// v0.30 round 90 (sub-spec 6 量表中心): 中心化 providers
//
// 提供 10 量表 (来自 scale_registry) + 各量表最新 entry 聚合 stream
// 给 assessment_center_page 用。
//
// 4 层架构: presentation/providers/ 跨 feature 共享, 0 跨 page/ 引用。

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/data/repositories/assessment/assessment_repository_impl.dart';
import 'package:chroniccare/features/assessment/domain/entities/assessment_entry.dart';
import 'package:chroniccare/features/assessment/domain/logic/assessment_scale.dart';
import 'package:chroniccare/domain/logic/scale_registry.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';

/// 跨 10 量表 聚合 Repository
///
/// 跟 core_providers.dart 的 7 个 repo 同模式, 但单独放 assessment_providers
/// 因为 assessment center 是 R90 新加的 sub-spec, 不污染 core_providers 的
/// repo 注册表 (R90 后该文件已经 6 repo, R91+ 可能加 contact / mood PDF 等)。
final assessmentRepositoryProvider = Provider<AssessmentRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return AssessmentRepository(db, db.assessmentDao);
});

/// 10 量表 list (PHQ-9 → Level 2 Psychosis, scale_registry.allScales())
///
/// Provider 暴露让 future 测试可 override (虽然目前是 const),
/// 跟 presentation/pages/assessment/widgets/assessment_history_list.dart
/// 直接用 `allScales()` 函数风格保持一致也行, 但统一 provider 入口更整洁。
final allScalesProvider = Provider<List<AssessmentScale>>((ref) => allScales());

/// 监听所有 entry (10 量表聚合)
/// R100 (N-3): 加 autoDispose — 仅 assessment 页面 watch, 离开后释放。
final allAssessmentEntriesProvider =
    StreamProvider.autoDispose<List<AssessmentEntry>>(
  (ref) {
    final repo = ref.watch(assessmentRepositoryProvider);
    return repo.watchAll();
  },
);

/// 某量表最新 entry (中心化卡片显示用)
///
/// Future-based, 走 AsyncValue.guard 包装成 AsyncValue
final latestEntryByScaleProvider =
    FutureProvider.family<AssessmentEntry?, String>((ref, scaleId) async {
  final repo = ref.watch(assessmentRepositoryProvider);
  return repo.getLatest(scaleId);
});

/// 量表是否对用户开放
final scaleAvailableProvider = Provider.family<bool, String>(
  (ref, scaleId) => isScaleAvailable(scaleId),
);
