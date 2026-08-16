// 量表注册表 — 集中管理所有可用量表
//
// v0.30 round 90 (sub-spec 6 量表中心): 扩 10 量表
// (PHQ-9 / GAD-7 R60 已有 + 6 公开新 + ISI / PSS R60 补全 = 10)。
//
// R117 综合审视 P2-6 (2026-08-17, emotion-first 定版后): 原 TODO
//   "v0.31+ 决定, user 选 hybrid" → **永久 unavailable** 决策:
//   - NSESSS (NCS Pearson 收费量表): emotion-first 0 商业, 永久关闭
//   - CRDPSS (内部自定义量表): 跟 1.1.0 round 4b 删"用户定义"业务一致, 永久关闭
// 守门员: check_no_network_io / check_release_no_network / check_legal_consent
//   (R57 PIPL §13 删 1.1.0 round 4b) 维持 emotion-first 0 商业 + 0 外联定版。
//
// 中心化的好处:
// - 新增量表 → 加一个 import + 一行
// - Task 3 watchAssessments 跨 type IN 走 `allScales().map((s) => s.id)`
// - Task 4 中心化入口页 10 卡片 (10 开放 + 2 unavailable) 走 `allScales()` + unavailableScaleIds
// - Task 5 多线趋势图 各量表 totalRange 走 `scaleById(id).totalRange`
// - Task 6 i18n ScaleTranslations 抽象 走 `scaleById(id).translations.xxx`
//
// 4 层架构: domain/logic/ 0 flutter 0 drift 0 data, 纯 Dart 业务。

import 'package:chroniccare/domain/logic/assessment_scale.dart';
import 'package:chroniccare/domain/logic/asrm.dart';
import 'package:chroniccare/domain/logic/gad7.dart';
import 'package:chroniccare/domain/logic/isi.dart';
import 'package:chroniccare/domain/logic/level2_anxiety.dart';
import 'package:chroniccare/domain/logic/level2_depression.dart';
import 'package:chroniccare/domain/logic/level2_mania.dart';
import 'package:chroniccare/domain/logic/level2_psychosis.dart';
import 'package:chroniccare/domain/logic/phq9.dart';
import 'package:chroniccare/domain/logic/pss.dart';
import 'package:chroniccare/domain/logic/whodas.dart';

/// 列出所有可用量表 (顺序固定: PHQ-9 先, 临床优先)
List<AssessmentScale> allScales() => const [
      phq9Scale, // 1. PHQ-9 抑郁筛查
      gad7Scale, // 2. GAD-7 焦虑筛查
      isiScale, // 3. ISI 失眠严重指数
      pssScale, // 4. PSS 压力量表
      whodasScale, // 5. WHODAS 2.0 残疾评定
      level2DepressionScale, // 6. DSM-5 Level 2 抑郁严重度
      level2AnxietyScale, // 7. DSM-5 Level 2 焦虑严重度
      level2ManiaScale, // 8. DSM-5 Level 2 躁狂严重度
      asrmScale, // 9. ASRM 自评躁狂量表
      level2PsychosisScale, // 10. DSM-5 Level 2 精神病性症状
    ];

/// 未开放量表 (标 unavailable, UI 灰卡 + 锁 icon)
///
/// R117 P2-6 定版:
/// - nsesss (NSESSS, NCS Pearson 收费): emotion-first 0 商业, 永久关闭
/// - crdpss (CRDPSS, 用户定义): 跟 1.1.0 round 4b 删"用户定义"业务一致, 永久关闭
const List<String> unavailableScaleIds = ['nsesss', 'crdpss'];

/// 量表是否对当前用户开放
bool isScaleAvailable(String id) => !unavailableScaleIds.contains(id);

/// 根据 id 查量表, 未知 id 返回 null
AssessmentScale? scaleById(String id) {
  for (final s in allScales()) {
    if (s.id == id) return s;
  }
  return null;
}
