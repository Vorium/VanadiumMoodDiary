// v0.30 round 91 (sub-spec 7 日常追踪): TreatmentDao
//
// 跟 R53a 抽 DAO 模式一致 — 不用 @DriftAccessor (避免 build_runner 重建),
// 用 _db.select(_db.treatmentEntries) 访问 table。drift 生成的 getter 在
// _$AppDatabase 里。
//
// v0.30 round 91 Task 3: 加 watchAllTreatmentEntries (leftOuterJoin medications)
// 实现 treatment ↔ medication 跨表 join 渲染, 配合 R55 medication 表
// (schemaVersion 14+ 已有, R91 不动)。FK 不强制 (R60 模式: 应用层维护),
// unlinked treatment (linkedMedicationId = null) 也走 leftOuterJoin 返。

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:drift/drift.dart';

class TreatmentDao {
  final AppDatabase _db;
  TreatmentDao(this._db);

  /// 监听所有治疗记录 (按 timestamp DESC 倒序, 不 join)
  ///
  /// 历史行为, R91 Task 3 之前用。R91 Task 3 之后, 需要 medication name 的
  /// caller 改用 `watchAllTreatmentEntries` (有 join)。
  Stream<List<TreatmentEntry>> watchAll() {
    return (_db.select(_db.treatmentEntries)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// 监听所有 treatment_entries, leftOuterJoin medications 取 name
  ///
  /// v0.30 round 91 Task 3: 治疗记录联动 medication
  /// - linkedMedicationId IS NULL → 走 leftOuterJoin, medication 侧 null,
  ///   entity.linkedMedicationName = null (unlinked treatment 仍返, 不漏)
  /// - linkedMedicationId 指向 medications.id → join 取 medications.name
  /// - cache (`t.linkedMedicationName`) 优先于 join: 历史 migration / medication
  ///   rename 时 cache 写时 snapshot 保持, join 不会覆盖
  ///
  /// 排序: timestamp DESC (跟 watchAll 一致)
  Stream<List<TreatmentEntry>> watchAllTreatmentEntries() {
    final query = _db.select(_db.treatmentEntries)
      ..orderBy([
        (t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
      ]);
    final joined = query.join([
      leftOuterJoin(
        _db.medications,
        _db.medications.id.equalsExp(_db.treatmentEntries.linkedMedicationId),
      ),
    ]);
    return joined
        .watch()
        .map((rows) => rows.map(_rowToEntry).toList(growable: false));
  }

  /// join 后 row → TreatmentEntry (drift data class)
  ///
  /// 字段映射规则:
  /// - 基础字段: 直接从 `row.readTable(_db.treatmentEntries)` 读
  /// - linkedMedicationName: cache 优先, fallback 到 join 读 medications.name
  ///   (老 entry cache=null 时仍能从 join 读, history migration 安全)
  TreatmentEntry _rowToEntry(TypedResult row) {
    final t = row.readTable(_db.treatmentEntries);
    final m = row.readTableOrNull(_db.medications);
    return TreatmentEntry(
      id: t.id,
      timestamp: t.timestamp,
      treatmentType: t.treatmentType,
      description: t.description,
      linkedMedicationId: t.linkedMedicationId,
      linkedMedicationName: t.linkedMedicationName ?? m?.name,
      note: t.note,
    );
  }

  Future<int> insert(TreatmentEntriesCompanion entry) =>
      _db.into(_db.treatmentEntries).insert(entry);

  Future<int> delete(int id) =>
      (_db.delete(_db.treatmentEntries)..where((t) => t.id.equals(id))).go();
}
