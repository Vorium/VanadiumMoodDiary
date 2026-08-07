// v0.30 round 91 (sub-spec 7 日常追踪): TreatmentRepository — domain 层 abstract
//
// R97-P1-1 (2026-08-07): 新增 abstract interface, 修复 4 层架构违规
// (跟 sleep_repository.dart 同模式, 详见该文件注释)。
//
// linkedMedicationName 是写时 snapshot 缓存, 避免 medication rename 后
// 历史 treatment 显示错名 (R55 R60 模式)。
import 'package:chroniccare/domain/entities/treatment_entry.dart';

/// 治疗仓库 (domain 接口)
abstract class TreatmentRepository {
  /// 监听所有 treatment (按 timestamp DESC 倒序, join medications)
  Stream<List<TreatmentEntryEntity>> watchAll();

  /// 添加 treatment (完整字段, 显式传 timestamp + name)
  ///
  /// 历史 API, 保留兼容: caller 必须自己传 linkedMedicationName
  /// (e.g. UI 已知 medication 显示名)。新 caller 改用 submitEntry。
  Future<int> add({
    required DateTime timestamp,
    required String treatmentType,
    required String description,
    int? linkedMedicationId,
    String? linkedMedicationName,
    String? note,
  });

  /// 提交 treatment (写时 snapshot medication name)
  ///
  /// v0.30 round 91 Task 3 新增: 简化 API + 自动 snapshot。
  /// - 不需要传 timestamp (用 DateTime.now())
  /// - 不需要传 linkedMedicationName (自动从 medications 表查 + 写时 snapshot)
  /// - linkedMedicationId 传 null = 不关联 medication
  /// - linkedMedicationId 指向不存在的 medication (孤儿 FK, R60 模式不报错)
  ///   → name = null, 仍写入 (R60 FK 不强制)
  Future<int> submitEntry({
    required String treatmentType,
    required String description,
    int? linkedMedicationId,
    String? note,
  });

  Future<int> delete(int id);
}
