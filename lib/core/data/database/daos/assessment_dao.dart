// v0.30 round 90 (sub-spec 6 量表中心): 跨 10 量表 聚合 DAO
//
// 不开新表, 走 check_ins.type = '<scale_id>' + note 字段 JSON 编码
// (user 选 keep 兼容, schemaVersion 不变)。DAO 层返回 AssessmentEntry
// domain entity, 隐藏 check_ins 原始 row。
//
// 模式: 跟 R53a 抽 DAO 模式一致 — 不用 @DriftAccessor (避免
// dart run build_runner 重建), 用 _db.select(_db.checkIns) 访问 table。
// drift 生成的 getter 在 _$AppDatabase 里。

import 'dart:convert';

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/daos/check_in_dao.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare/domain/entities/assessment_entry.dart';
import 'package:chroniccare/domain/logic/scale_registry.dart';
import 'package:drift/drift.dart';

class AssessmentDao {
  final AppDatabase _db;
  final CheckInDao _checkInDao;

  AssessmentDao(this._db, this._checkInDao);

  /// 监听所有 10 量表的 entry (跨 type), 解析 note JSON
  Stream<List<AssessmentEntry>> watchAllAssessmentEntries() {
    return _checkInDao.watchAssessments().map((rows) {
      return rows.map(_rowToEntry).toList(growable: false);
    });
  }

  /// 拿某量表最新 entry
  ///
  /// 排序: timestamp DESC, id DESC (id 作 tie-breaker, 同秒插入时返回最新插入)
  /// 原因: DateTime 精度跟 SQLite 存储精度一致, 同 1 秒内连续 insert 可能
  /// 撞 timestamp, drift 的 OrderingTerm 在同值时返回顺序未定义。
  /// id 是 autoIncrement, 一定单调, 作 tie-breaker 可靠。
  Future<AssessmentEntry?> getLatestEntryByType(String scaleId) async {
    final row = await (_db.select(_db.checkIns)
          ..where((t) => t.type.equals(scaleId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    return _rowToEntry(row);
  }

  /// 统计每量表提交次数
  ///
  /// 排除 unavailableScaleIds (NSESSS / CRDPSS) — 这些量表不在 watchAssessments
  /// 跨 type IN 列表里, 但历史数据可能存在。count 跟 UI 中心化入口对齐, 灰卡
  /// 量表不算提交数。
  Future<Map<String, int>> countByType() async {
    final rows = await _db.select(_db.checkIns).get();
    final map = <String, int>{};
    for (final r in rows) {
      if (unavailableScaleIds.contains(r.type)) continue;
      map[r.type] = (map[r.type] ?? 0) + 1;
    }
    return map;
  }

  /// 某量表历史 (按 scale_id filter)
  Stream<List<AssessmentEntry>> watchEntriesByScaleId(String scaleId) {
    return (_db.select(_db.checkIns)
          ..where((t) => t.type.equals(scaleId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.asc),
          ]))
        .watch()
        .map((rows) => rows.map(_rowToEntry).toList(growable: false));
  }

  /// 解析 check_ins row → AssessmentEntry
  ///
  /// 3 个分支:
  /// 1. note == null/empty → 老空数据, score=0, answers=[]
  /// 2. note 是合法 JSON → 解析 score / severity / answers, 提取可选 note 字段
  /// 3. note 不是 JSON (R60 老格式 free text) → 兜底, note 保留原文, score=0
  ///
  /// v0.30 round 91 (fix): 分支 2 接受 BOTH R90 + R60 keys, R90 优先, R60 兜底。
  /// - R90 格式: `{"score":N, "severity":N, "answers":[...], "note":...}`
  /// - R60 格式: `{"scale":"phq9", "scores":[...], "total":N}` (老 saveAssessment)
  /// 老用户升级到 R90 + 用 R90 reader 解老 note 时, score=0 / answers=空
  /// → 中心化入口页 + 折线图看不见数据。修法: 字段级 R60 兜底。
  AssessmentEntry _rowToEntry(CheckIn row) {
    final rawNote = row.note;
    if (rawNote == null || rawNote.isEmpty) {
      return AssessmentEntry(
        id: row.id,
        timestamp: row.timestamp,
        scaleId: row.type,
        score: 0,
        severityRank: 0,
        answers: const [],
        note: null,
      );
    }
    try {
      final decoded = jsonDecode(rawNote);
      if (decoded is Map<String, dynamic>) {
        // R90 优先: score / severity / answers
        // R60 兜底: total / (severity 没存, R60 老 entry 无 rank 概念) / scores
        final score =
            (decoded['score'] as int?) ?? (decoded['total'] as int?) ?? 0;
        final severityRank = (decoded['severity'] as int?) ?? 0;
        final answers = ((decoded['answers'] as List?) ??
                (decoded['scores'] as List?) ??
                const [])
            .whereType<int>()
            .toList(growable: false);
        return AssessmentEntry(
          id: row.id,
          timestamp: row.timestamp,
          scaleId: row.type,
          score: score,
          severityRank: severityRank,
          answers: answers,
          note: decoded['note'] as String?,
        );
      }
      // JSON 解析成功但不是 Map (e.g. JSON 数组) → 兜底
      return AssessmentEntry(
        id: row.id,
        timestamp: row.timestamp,
        scaleId: row.type,
        score: 0,
        severityRank: 0,
        answers: const [],
        note: rawNote,
      );
    } catch (e, st) {
      // 老格式 free text 兜底 (R60 之前 phq9/gad7 老 entry note 是 "用户备注: ...")
      // v0.30 R92: 走 swallowError 集中器, 替代完全静默 (R39 P1-10 模式)
      swallowError(
        where: 'assessment_dao._rowToEntry_parse',
        error: e,
        stack: st,
        note: 'assessmentId=${row.id} type=${row.type} rawNote=$rawNote 解析失败, 走老格式 free text 兜底',
      );
      return AssessmentEntry(
        id: row.id,
        timestamp: row.timestamp,
        scaleId: row.type,
        score: 0,
        severityRank: 0,
        answers: const [],
        note: rawNote,
      );
    }
  }
}
