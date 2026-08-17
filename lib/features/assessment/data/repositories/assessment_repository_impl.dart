// v0.30 round 90 (sub-spec 6 量表中心): AssessmentRepository
//
// 跨 10 量表统一入口 (PHQ-9 / GAD-7 / ISI / PSS / WHODAS /
// Level 2 抑郁/焦虑/躁狂/精神病 / ASRM)。不开新表 — 走 check_ins 表
// type='<scaleId>' + note 字段 JSON 编码 (user 选 keep 兼容)。
//
// 4 层架构: data 层, 实现 domain 层 logic/scale_registry 的工具
// (scaleById / isScaleAvailable) 校验 + 写库。

import 'dart:convert';

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/domain/logic/scale_registry.dart';
import 'package:chroniccare/features/assessment/data/daos/assessment_dao.dart';
import 'package:chroniccare/features/assessment/domain/entities/assessment_entry.dart';
import 'package:drift/drift.dart' show Value;

class AssessmentRepository {
  final AppDatabase _db;
  final AssessmentDao _dao;

  AssessmentRepository(this._db, this._dao);

  /// 监听所有 10 量表 entry (跨 type 聚合)
  Stream<List<AssessmentEntry>> watchAll() => _dao.watchAllAssessmentEntries();

  /// 拿某量表最新 entry
  Future<AssessmentEntry?> getLatest(String scaleId) =>
      _dao.getLatestEntryByType(scaleId);

  /// 统计每量表提交次数 (排除 unavailable)
  Future<Map<String, int>> countByScale() => _dao.countByType();

  /// 某量表历史 (按 scale_id filter, 跨量表详情页 / 趋势图用)
  Stream<List<AssessmentEntry>> watchByScale(String scaleId) =>
      _dao.watchEntriesByScaleId(scaleId);

  /// 提交一份新 entry (写 check_ins 表 type='`scaleId`' + note=jsonEncode)
  ///
  /// 校验顺序 (重要 — unavailable 必须先查):
  /// 1. 如果 scaleId 在 `unavailableScaleIds` (NSESSS / CRDPSS) →
  ///    抛 [StateError] (已知但未开放, 法务审核中)
  /// 2. 否则如果 scaleById == null → 抛 [ArgumentError] (完全未知)
  /// 3. 否则通过, 写 check_ins
  ///
  /// 顺序重要: NSESSS / CRDPSS 不在 `allScales()` 也不在 `scaleById`
  /// 命中范围 — 跟"完全未知"互斥。unavailable 优先 (更具体的错误信息)。
  Future<int> submitEntry({
    required String scaleId,
    required int score,
    required int severityRank,
    required List<int> answers,
    String? note,
  }) async {
    if (unavailableScaleIds.contains(scaleId)) {
      throw StateError('Scale not available: $scaleId');
    }
    if (scaleById(scaleId) == null) {
      throw ArgumentError('Unknown scale: $scaleId');
    }

    final json = jsonEncode({
      'score': score,
      'severity': severityRank,
      'answers': answers,
      if (note != null) 'note': note,
    });

    return _db.into(_db.checkIns).insert(
          CheckInsCompanion.insert(
            timestamp: DateTime.now(),
            type: scaleId,
            note: Value(json),
          ),
        );
  }
}
