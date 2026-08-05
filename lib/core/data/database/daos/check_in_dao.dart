// v0.25 round 53a: CheckInDao 抽离 (app_database.dart god class 拆分)
//
// 之前 app_database.dart 559 行含 30 query method + 2 transaction,
// god class 标签。R53a 抽 7 个 DAO + app_database 改成 1 行委托,
// caller 暂时不动 (兼容 facade 模式)。
//
// 修法: 纯 wrapper, 接受 AppDatabase 实例 + 暴露 query method。
// DAO 不用 @DriftAccessor (避免 dart run build_runner 重建), 用
// _db.select(_db.checkIns) 访问 table — drift 生成的 getter 在
// _$AppDatabase 里。

import 'package:drift/drift.dart';

import 'package:chroniccare/core/data/database/app_database.dart';

class CheckInDao {
  final AppDatabase _db;
  CheckInDao(this._db);

  /// 监听所有打卡（按时间倒序）
  Stream<List<CheckIn>> watchAll() {
    return (_db.select(_db.checkIns)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// 监听所有评估记录 (跨 10 量表 type IN), 按时间正序 (折线图用)
  ///
  /// v0.30 round 90 (sub-spec 6 量表中心): 扩 10 scale_id —
  /// PHQ-9 / GAD-7 / ISI / PSS (R60 已有 + 补全) +
  /// WHODAS / Level 2 Dep/Anx/Mania/Psychosis / ASRM (R90 新)。
  /// NSESSS / CRDPSS 是 unavailable (走 `unavailableScaleIds` 黑名单), 不在 IN 列表。
  Stream<List<CheckIn>> watchAssessments() {
    return (_db.select(_db.checkIns)
          ..where(
            (t) => t.type.isIn(
              const [
                'phq9',
                'gad7',
                'isi',
                'pss',
                'whodas',
                'level2_depression',
                'level2_anxiety',
                'level2_mania',
                'asrm',
                'level2_psychosis',
              ],
            ),
          )
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  /// 监听今天的打卡 (跨 midnight 单次 DateTime.now())
  Stream<CheckIn?> watchToday() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (_db.select(_db.checkIns)
          ..where(
            (t) =>
                t.timestamp.isBiggerOrEqualValue(startOfDay) &
                t.timestamp.isSmallerThanValue(endOfDay),
          )
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .watchSingleOrNull();
  }

  /// 监听"正常"打卡 (排除评估/临时), 按时间倒序
  Stream<List<CheckIn>> watchNormal() {
    return (_db.select(_db.checkIns)
          ..where((t) => t.type.equals('normal'))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// 获取最近一次"正常"打卡 (单次)
  Future<CheckIn?> getLatestNormal() {
    return (_db.select(_db.checkIns)
          ..where((t) => t.type.equals('normal'))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  /// 获取最近一次评估时间戳 (单次)
  Future<DateTime?> getLatestAssessmentTimestamp() async {
    final r = await (_db.select(_db.checkIns)
          ..where((t) => t.type.equals('phq9') | t.type.equals('gad7'))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();
    return r?.timestamp;
  }

  /// 插入打卡
  Future<int> insert(CheckInsCompanion entry) =>
      _db.into(_db.checkIns).insert(entry);
}
