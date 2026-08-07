// v0.30 round 91 (sub-spec 7 日常追踪): TreatmentRepositoryImpl
//
// linkedMedicationName 是写时 snapshot 缓存, 避免 medication rename 后
// 历史 treatment 显示错名 (R55 R60 模式)。
//
// v0.30 round 91 Task 3 升级:
// - watchAll() 改走 treatmentDao.watchAllTreatmentEntries() (leftOuterJoin
//   medications, cache 优先 + join 兜底)
// - 加 submitEntry() 方法: 写时 snapshot medication.name (避免 medication
//   rename 影响历史)

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/domain/entities/treatment_entry.dart';
import 'package:chroniccare/domain/repositories/treatment_repository.dart';
import 'package:drift/drift.dart' show Value;

/// Treatment 仓库的 Drift 实现
///
/// R97-P1-1 (2026-08-07): implements [TreatmentRepository] domain 接口
/// (跟 sleep_repository_impl.dart 同模式, 详见该文件注释)。
class TreatmentRepositoryImpl implements TreatmentRepository {
  final AppDatabase _db;

  TreatmentRepositoryImpl(this._db);

  /// 监听所有 treatment (按 timestamp DESC 倒序, join medications)
  ///
  /// v0.30 round 91 Task 3: 改用 dao.watchAllTreatmentEntries() (leftOuterJoin)
  /// - linkedMedicationId IS NULL → entity.linkedMedicationName = null
  /// - linkedMedicationId 指向 medications.id → entity.linkedMedicationName =
  ///   cache (写时 snapshot) ?? medications.name
  /// - medication rename 不影响 cache, 历史显示原名
  @override
  Stream<List<TreatmentEntryEntity>> watchAll() {
    return _db.treatmentDao.watchAllTreatmentEntries().map(
          (rows) => rows
              .map(
                (r) => TreatmentEntryEntity(
                  id: r.id,
                  timestamp: r.timestamp,
                  treatmentType: r.treatmentType,
                  description: r.description,
                  linkedMedicationId: r.linkedMedicationId,
                  linkedMedicationName: r.linkedMedicationName,
                  note: r.note,
                ),
              )
              .toList(growable: false),
        );
  }

  /// 添加 treatment (完整字段, 显式传 timestamp + name)
  ///
  /// 历史 API, 保留兼容: caller 必须自己传 linkedMedicationName
  /// (e.g. UI 已知 medication 显示名)。新 caller 改用 submitEntry。
  @override
  Future<int> add({
    required DateTime timestamp,
    required String treatmentType,
    required String description,
    int? linkedMedicationId,
    String? linkedMedicationName,
    String? note,
  }) {
    return _db.treatmentDao.insert(
      TreatmentEntriesCompanion.insert(
        timestamp: timestamp,
        treatmentType: treatmentType,
        description: description,
        linkedMedicationId: Value(linkedMedicationId),
        linkedMedicationName: Value(linkedMedicationName),
        note: Value(note),
      ),
    );
  }

  /// 提交 treatment (写时 snapshot medication name)
  ///
  /// v0.30 round 91 Task 3 新增: 简化 API + 自动 snapshot。
  /// - 不需要传 timestamp (用 DateTime.now())
  /// - 不需要传 linkedMedicationName (自动从 medications 表查 + 写时 snapshot)
  /// - linkedMedicationId 传 null = 不关联 medication
  /// - linkedMedicationId 指向不存在的 medication (孤儿 FK, R60 模式不报错)
  ///   → name = null, 仍写入 (R60 FK 不强制)
  ///
  /// 写时 snapshot 意义: 后续 medication.name 被改, 历史 treatment 仍显示
  /// 当时的 name (joined 读 + cache 优先逻辑保证)。
  @override
  Future<int> submitEntry({
    required String treatmentType,
    required String description,
    int? linkedMedicationId,
    String? note,
  }) async {
    // 写时 snapshot medication name (避免后续 medication rename 影响 history)
    String? linkedMedicationName;
    if (linkedMedicationId != null) {
      final med = await (_db.select(_db.medications)
            ..where((m) => m.id.equals(linkedMedicationId)))
          .getSingleOrNull();
      // R60 模式: FK 不强制, 找不到时 name=null (孤儿 FK 仍写入, UI 显示 "无关联")
      linkedMedicationName = med?.name;
    }

    return _db.treatmentDao.insert(
      TreatmentEntriesCompanion.insert(
        timestamp: DateTime.now(),
        treatmentType: treatmentType,
        description: description,
        linkedMedicationId: Value(linkedMedicationId),
        linkedMedicationName: Value(linkedMedicationName),
        note: Value(note),
      ),
    );
  }

  @override
  Future<int> delete(int id) => _db.treatmentDao.delete(id);
}
