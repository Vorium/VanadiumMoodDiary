// v0.30 round 91 (sub-spec 7 日常追踪): SleepRepositoryImpl
//
// 4 层架构: data 层, 实现 domain entity 跟 drift row 翻译 (类似 VentRepositoryImpl)。
// 单一职责: watchAll + add + delete, 跟 VentRepositoryImpl 模式一致。

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/domain/entities/sleep_entry.dart';
import 'package:chroniccare/domain/repositories/sleep_repository.dart';
import 'package:drift/drift.dart' show Value;

/// Sleep 仓库的 Drift 实现
///
/// R97-P1-1 (2026-08-07): implements [SleepRepository] domain 接口,
/// 满足 4 层架构"presentation provider 暴露 domain 接口不暴露 impl"约束。
class SleepRepositoryImpl implements SleepRepository {
  final AppDatabase _db;

  SleepRepositoryImpl(this._db);

  /// 监听所有 sleep 条目 (按 date DESC)
  @override
  Stream<List<SleepEntryEntity>> watchAll() {
    return _db.sleepDao.watchAll().map(
          (rows) => rows
              .map(
                (r) => SleepEntryEntity(
                  id: r.id,
                  date: r.date,
                  bedtime: r.bedtime,
                  wakeTime: r.wakeTime,
                  durationMin: r.durationMin,
                  regularityScore: r.regularityScore,
                  note: r.note,
                ),
              )
              .toList(growable: false),
        );
  }

  /// 新增 sleep entry
  ///
  /// [durationMin] 通常由 caller 算 (用 SleepCalculator.durationMin),
  /// 也可 caller 直接传算好的值。
  @override
  Future<int> add({
    required DateTime date,
    required DateTime bedtime,
    required DateTime wakeTime,
    required int durationMin,
    int? regularityScore,
    String? note,
  }) {
    return _db.sleepDao.insert(
      SleepEntriesCompanion.insert(
        date: date,
        bedtime: bedtime,
        wakeTime: wakeTime,
        durationMin: durationMin,
        regularityScore: Value(regularityScore),
        note: Value(note),
      ),
    );
  }

  @override
  Future<int> delete(int id) => _db.sleepDao.delete(id);
}
