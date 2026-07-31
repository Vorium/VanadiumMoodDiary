// 量表注册表
//
// 集中管理所有可用量表。新增量表 → 加一个 import + 一行。

import 'package:chroniccare/domain/logic/assessment_scale.dart';
import 'package:chroniccare/domain/logic/gad7.dart';
import 'package:chroniccare/domain/logic/phq9.dart';

/// 列出所有可用量表（顺序固定：PHQ-9 先，GAD-7 后）
List<AssessmentScale> allScales() => const [phq9Scale, gad7Scale];

/// 根据 id 查量表，未知 id 返回 null
AssessmentScale? scaleById(String id) {
  for (final s in allScales()) {
    if (s.id == id) return s;
  }
  return null;
}
