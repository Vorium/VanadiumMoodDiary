// 规则 3 标记: 内部 note 中文 (非用户可见), 豁免 i18n 扫描
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

  @override
  // v0.27 round 60 (审计 M9 修复): `==` 加上 scores element-based 比较
  //
  // 修复前 bug: `==` 只比较 scaleId / timestamp / total, 忽略 scores。
  // 后果: 两个 AssessmentRecord 的 scaleId + timestamp + total 相同但
  // scores 不同 → `==` 判 true → Set / Map round-trip 漏去重
  // (e.g. `Set<AssessmentRecord>` 去重依赖 `==`)。
  //
  // 修复方法: 比较 scores 长度 + element-based 比较。
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssessmentRecord &&
          other.scaleId == scaleId &&
          other.timestamp == timestamp &&
          other.total == total &&
          _listEquals(other.scores, scores);

  @override
  // v0.27 round 60 (审计 M9 修复): `hashCode` 加上 scores element-based hash
  //
  // `Object.hashAll(List<T>)` 走 element-based 哈希, 不是 identity-based。
  // Dart 3.12.2 验证: 6/6 contract test pass。
  // 必须保持 `==` 和 `hashCode` 都基于 element-based, 否则 Set / Map
  // 不一致 → 同样的对象在不同容器里算不同 key。
  int get hashCode =>
      Object.hash(scaleId, timestamp, total, Object.hashAll(scores));

  /// Element-based 列表相等 (长度相同 + 各 index 元素相同)。
  ///
  /// 不走 `List.equals` 库函数: 保持零依赖, 纯 Dart 内置。
  static bool _listEquals(List<int> a, List<int> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

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
      // R114 BUG 3: 双 key 兼容 — R90 量表中心 submitEntry 写
      // 'score'/'answers', 老路径 (round 12 之前) 写 'total'/'scores'。
      // 修前只读 'total' → 经量表中心提交的所有评估在历史/对比/趋势
      // 总分恒 0、scores 恒空 (R113 #9 未闭环实锤; DAO 已双读, 只漏
      // domain 这个解析器)。
      final total = (json['total'] as int?) ?? (json['score'] as int?) ?? 0;
      final rawScores = (json['scores'] as List<dynamic>?) ??
          (json['answers'] as List<dynamic>?) ??
          const [];
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
// rule3-whitelist: 106
//   R113 BUG A: 精确行号豁免 (修前文件头 i18n 标记整文件豁免)
//   新增 CJK 字面量需自带 i18n 标记或扩本清单 — 详见 scripts/check_strings_hardcoded.py
