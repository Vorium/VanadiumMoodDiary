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

import 'dart:async';

import 'package:drift/drift.dart';

import 'package:chroniccare/core/data/database/app_database.dart';

class CheckInDao {
  final AppDatabase _db;

  /// R114 B1-4: 可注入 clock / midnightDelay — 生产用 DateTime.now +
  /// 下一个 00:00:05, 测试注入假时钟 + 短 delay 快进跨日。
  final DateTime Function() _clock;
  final Duration Function(DateTime) _midnightDelay;

  CheckInDao(
    this._db, {
    DateTime Function()? clock,
    Duration Function(DateTime)? midnightDelay,
  })  : _clock = clock ?? DateTime.now,
        _midnightDelay = midnightDelay ?? _nextMidnightDelay;

  /// 距离下一个 00:00:05 的时长
  ///
  /// 跟 app.dart [nextMidnightRefresh] 同款语义 (5s buffer 防 00:00 边界
  /// race); 跨月/跨年由 DateTime(y, m, day + 1) 自动进位。
  static Duration _nextMidnightDelay(DateTime now) {
    final nextDay = DateTime(now.year, now.month, now.day + 1);
    return nextDay.difference(now) + const Duration(seconds: 5);
  }

  /// R114 B1-4: 跨日窗口流模板
  ///
  /// 每次"今天"变化时取消旧查询订阅, 按新窗口重新查询再订阅 —
  /// 到下一个 00:00:05 再切一次 (App 跨 midnight 长开时窗口不再冻结)。
  ///
  /// 注: 不用 `Stream.asyncExpand` 接 drift watch — 实测 asyncExpand 对
  /// 永不 complete 的 drift watch 流只拉第一个外层事件就停 (外层 generator
  /// 不再被请求), 窗口永远切不动; 显式 cancel + 重订阅可靠 (drift 按
  /// (sql, boundVariables) 缓存同 key 流, 重订阅直接推 _lastData)。
  Stream<T> _watchWindowed<T>(Stream<T> Function(DateTime start) query) {
    final controller = StreamController<T>();
    StreamSubscription<T>? current;
    Timer? timer;

    void resubscribe() {
      final now = _clock();
      final start = DateTime(now.year, now.month, now.day);
      unawaited(current?.cancel());
      current = query(start).listen(
        controller.add,
        onError: controller.addError,
      );
      timer?.cancel();
      timer = Timer(_midnightDelay(now), resubscribe);
    }

    controller.onListen = resubscribe;
    controller.onCancel = () async {
      timer?.cancel();
      await current?.cancel();
      await controller.close();
    };
    return controller.stream;
  }

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
  ///
  /// R114 B1-4: 修前流创建时一次性捕获 now — App 跨 00:00 长开时窗口永远
  /// 停在昨天。修后: 走 [_watchWindowed] 每个跨日 tick 重算窗口 + 重查。
  Stream<CheckIn?> watchToday() {
    return _watchWindowed((startOfDay) {
      final endOfDay = startOfDay.add(const Duration(days: 1));
      return (_db.select(_db.checkIns)
            ..where(
              (t) =>
                  t.timestamp.isBiggerOrEqualValue(startOfDay) &
                  t.timestamp.isSmallerThanValue(endOfDay),
            )
            ..orderBy([
              (t) => OrderingTerm(
                    expression: t.timestamp,
                    mode: OrderingMode.desc,
                  ),
            ])
            ..limit(1))
          .watchSingleOrNull();
    });
  }

  /// 监听今天所有打卡（用于首页概览卡统计今日药物进度）
  ///
  /// R114 B1-4: 同 [watchToday] — 跨日窗口流驱动重查, 窗口不再冻结。
  Stream<List<CheckIn>> watchTodayAll() {
    return _watchWindowed((startOfDay) {
      final endOfDay = startOfDay.add(const Duration(days: 1));
      return (_db.select(_db.checkIns)
            ..where(
              (t) =>
                  t.timestamp.isBiggerOrEqualValue(startOfDay) &
                  t.timestamp.isSmallerThanValue(endOfDay),
            )
            ..orderBy([
              (t) => OrderingTerm(
                    expression: t.timestamp,
                    mode: OrderingMode.desc,
                  ),
            ]))
          .watch();
    });
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
  ///
  /// v0.30 round 91 (fix): 跨 10 量表 (跟 `watchAssessments` 对齐) —
  /// 之前 hardcode phq9|gad7, 只用新量表的用户的评估提醒周期永远不启动。
  /// NSESSS / CRDPSS 是 unavailable, 不在 IN 列表, 跟 `watchAssessments` 行为一致。
  Future<DateTime?> getLatestAssessmentTimestamp() async {
    final r = await (_db.select(_db.checkIns)
          ..where(
            (t) => t.type.isIn(const [
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
            ]),
          )
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
