/// 评估记录模型
///
/// 把 CheckInEntity 里 type ∈ {phq9, gad7} 的 note JSON 解析为强类型 record，
/// 方便趋势页折线图使用。
library;

import 'dart:convert';

import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare/domain/entities/check_in_entity.dart';

class AssessmentRecord {
  /// 量表 id（'phq9' / 'gad7'）
  final String scaleId;

  /// 提交时间
  final DateTime timestamp;

  /// 总分
  final int total;

  /// 各题分数（按 0-based 顺序）
  final List<int> scores;

  const AssessmentRecord({
    required this.scaleId,
    required this.timestamp,
    required this.total,
    required this.scores,
  });

  /// 从 CheckInEntity 反序列化
  ///
  /// 失败返回 null：
  /// - type 不是 phq9 / gad7
  /// - note 为空 / JSON 解析失败
  static AssessmentRecord? tryFromEntity(CheckInEntity c) {
    if (!c.isAssessment) return null;
    final note = c.note;
    if (note == null || note.isEmpty) return null;
    try {
      final json = jsonDecode(note) as Map<String, dynamic>;
      final total = json['total'] as int? ?? 0;
      final rawScores = json['scores'] as List<dynamic>? ?? const [];
      final scores = rawScores.map((e) => (e as num).toInt()).toList();
      return AssessmentRecord(
        scaleId: c.type.wire,
        timestamp: c.timestamp,
        total: total,
        scores: scores,
      );
    } catch (e, st) {
      // v0.23 round 39 (P1-10 fix): 不再 `catch (_)` 完全静默,
      // 走 swallowError 集中器,release 模式不打印,debug 模式打 developer.log
      swallowError(
        where: 'AssessmentRecord.tryParse',
        error: e,
        stack: st,
        note: 'note JSON 解析失败: 返回 null',
      );
      return null;
    }
  }
}
