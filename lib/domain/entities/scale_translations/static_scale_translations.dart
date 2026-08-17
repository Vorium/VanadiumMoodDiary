// 规则 3 标记: 量表中文 fallback — v1.0+ i18n (R51b backlog, 显示层走 l10n)
// static_scale_translations.dart — 静态中文 fallback 实现
//
// v0.30 round 95 (sub-spec 4 task 2): 从 scale_translations.dart 抽出
//
// 职责: [StaticScaleTranslations] 类 — 实现 [ScaleTranslations] 接口, 走
// const 中文 fallback (8 老量表 PHQ-9 / GAD-7 + 8 新量表 ISI / PSS / WHODAS
// / Level2 Depression / Anxiety / Mania / Psychosis / ASRM = 10 量表 50+ method)
//
// 拆出原因: 原 scale_translations.dart 953 行, abstract class (198 行) +
// StaticScaleTranslations (752 行) 混一起。拆出后:
// - scale_translations.dart (主壳): 198 行 (abstract interface + import re-export)
// - scale_translations/static_scale_translations.dart (本文件): 752 行
//   (StaticScaleTranslations 完整实现)
//
// 公共 API:
// - [ScaleTranslations] (在 scale_translations.dart 公开) — abstract interface
// - [StaticScaleTranslations] (本文件, 在主壳 re-export) — const 中文 fallback
//   实现, 保持向后兼容老 caller (e.g. const StaticScaleTranslations() 走中文
//   fallback, 21 case crisis test 不破, R65/R78/R90 老 caller 0 改动)
//
// 4 层架构纯度: 本文件 import domain/logic/assessment_scale.dart (同 domain 层),
// 0 flutter / 0 drift / 0 data / 0 presentation, check_all.dart 守门员 0 violation。
import 'package:chroniccare/domain/logic/assessment_scale.dart';
import 'package:chroniccare/domain/entities/scale_translations.dart';
import 'package:chroniccare/domain/entities/scale_translations/gad7_translations.dart';
import 'package:chroniccare/domain/entities/scale_translations/isi_translations.dart';
import 'package:chroniccare/domain/entities/scale_translations/level2_anxiety_translations.dart';
import 'package:chroniccare/domain/entities/scale_translations/level2_depression_translations.dart';
import 'package:chroniccare/domain/entities/scale_translations/level2_mania_translations.dart';
import 'package:chroniccare/domain/entities/scale_translations/level2_psychosis_translations.dart';
import 'package:chroniccare/domain/entities/scale_translations/phq9_translations.dart';
import 'package:chroniccare/domain/entities/scale_translations/pss_translations.dart';
import 'package:chroniccare/domain/entities/scale_translations/whodas_translations.dart';

/// 静态中文 fallback (老 caller / 单测 / domain 0 flutter 边界)
class StaticScaleTranslations implements ScaleTranslations {
  const StaticScaleTranslations();

  // v1.1.0 R118 (god class 拆 P2-7): composition 委托 10 个量表到独立 class
  // 阶段 1: PHQ-9 → Phq9Translations (R118 round 1)
  // 阶段 2: GAD-7 → Gad7Translations (R118 round 2)
  // 阶段 3: ISI + PSS → IsiTranslations + PssTranslations (R118 round 3)
  // 阶段 4: WHODAS → WhodasTranslations (R118 round 4)
  // 阶段 5: Level2 Depression + Anxiety (R118 round 5)
  // 阶段 6: Level2 Mania + Psychosis (R118 round 6)
  // 阶段 7: ASRM
  static const _phq9 = Phq9Translations();
  static const _gad7 = Gad7Translations();
  static const _isi = IsiTranslations();
  static const _pss = PssTranslations();
  static const _whodas = WhodasTranslations();
  static const _level2Depression = Level2DepressionTranslations();
  static const _level2Anxiety = Level2AnxietyTranslations();
  static const _level2Mania = Level2ManiaTranslations();
  static const _level2Psychosis = Level2PsychosisTranslations();

  // === PHQ-9 7 method 委托 (R118 P2-7 阶段 1) ===
  @override
  String phq9Name({String? override}) => _phq9.phq9Name(override: override);

  @override
  String phq9ShortDescription({String? override}) =>
      _phq9.phq9ShortDescription(override: override);

  @override
  String phq9Instruction({String? override}) =>
      _phq9.phq9Instruction(override: override);

  @override
  String phq9Item(int index, {String? override}) =>
      _phq9.phq9Item(index, override: override);

  @override
  String phq9Option(int score, {String? override}) =>
      _phq9.phq9Option(score, override: override);

  @override
  String phq9SeverityLabel(int rank, {String? override}) =>
      _phq9.phq9SeverityLabel(rank, override: override);

  @override
  String phq9SeveritySummary(int rank, {String? override}) =>
      _phq9.phq9SeveritySummary(rank, override: override);

  // === GAD-7 7 method 委托 (R118 P2-7 阶段 2) ===
  @override
  String gad7Name({String? override}) => _gad7.gad7Name(override: override);

  @override
  String gad7ShortDescription({String? override}) =>
      _gad7.gad7ShortDescription(override: override);

  @override
  String gad7Instruction({String? override}) =>
      _gad7.gad7Instruction(override: override);

  @override
  String gad7Item(int index, {String? override}) =>
      _gad7.gad7Item(index, override: override);

  @override
  String gad7Option(int score, {String? override}) =>
      _gad7.gad7Option(score, override: override);

  @override
  String gad7SeverityLabel(int rank, {String? override}) =>
      _gad7.gad7SeverityLabel(rank, override: override);

  @override
  String gad7SeveritySummary(int rank, {String? override}) =>
      _gad7.gad7SeveritySummary(rank, override: override);

  // === ISI 7 method 委托 (R118 P2-7 阶段 3) ===
  @override
  String isiName({String? override}) => _isi.isiName(override: override);

  @override
  String isiShortDescription({String? override}) =>
      _isi.isiShortDescription(override: override);

  @override
  String isiInstruction({String? override}) =>
      _isi.isiInstruction(override: override);

  @override
  String isiItem(int index, {String? override}) =>
      _isi.isiItem(index, override: override);

  @override
  String isiOption(int score, {String? override}) =>
      _isi.isiOption(score, override: override);

  @override
  String isiSeverityLabel(int rank, {String? override}) =>
      _isi.isiSeverityLabel(rank, override: override);

  @override
  String isiSeveritySummary(int rank, {String? override}) =>
      _isi.isiSeveritySummary(rank, override: override);

  // === PSS 7 method 委托 (R118 P2-7 阶段 3) ===
  @override
  String pssName({String? override}) => _pss.pssName(override: override);

  @override
  String pssShortDescription({String? override}) =>
      _pss.pssShortDescription(override: override);

  @override
  String pssInstruction({String? override}) =>
      _pss.pssInstruction(override: override);

  @override
  String pssItem(int index, {String? override}) =>
      _pss.pssItem(index, override: override);

  @override
  String pssOption(int score, {String? override}) =>
      _pss.pssOption(score, override: override);

  @override
  String pssSeverityLabel(int rank, {String? override}) =>
      _pss.pssSeverityLabel(rank, override: override);

  @override
  String pssSeveritySummary(int rank, {String? override}) =>
      _pss.pssSeveritySummary(rank, override: override);

  // === WHODAS 7 method 委托 (R118 P2-7 阶段 4) ===
  @override
  String whodasName({String? override}) => _whodas.whodasName(override: override);

  @override
  String whodasShortDescription({String? override}) =>
      _whodas.whodasShortDescription(override: override);

  @override
  String whodasInstruction({String? override}) =>
      _whodas.whodasInstruction(override: override);

  @override
  String whodasItem(int index, {String? override}) =>
      _whodas.whodasItem(index, override: override);

  @override
  String whodasOption(int score, {String? override}) =>
      _whodas.whodasOption(score, override: override);

  @override
  String whodasSeverityLabel(int rank, {String? override}) =>
      _whodas.whodasSeverityLabel(rank, override: override);

  @override
  String whodasSeveritySummary(int rank, {String? override}) =>
      _whodas.whodasSeveritySummary(rank, override: override);

  // === Level2 Depression 7 method 委托 (R118 P2-7 阶段 5) ===
  @override
  String level2DepressionName({String? override}) =>
      _level2Depression.level2DepressionName(override: override);

  @override
  String level2DepressionShortDescription({String? override}) =>
      _level2Depression.level2DepressionShortDescription(override: override);

  @override
  String level2DepressionInstruction({String? override}) =>
      _level2Depression.level2DepressionInstruction(override: override);

  @override
  String level2DepressionItem(int index, {String? override}) =>
      _level2Depression.level2DepressionItem(index, override: override);

  @override
  String level2DepressionOption(int score, {String? override}) =>
      _level2Depression.level2DepressionOption(score, override: override);

  @override
  String level2DepressionSeverityLabel(int rank, {String? override}) =>
      _level2Depression.level2DepressionSeverityLabel(rank, override: override);

  @override
  String level2DepressionSeveritySummary(int rank, {String? override}) =>
      _level2Depression.level2DepressionSeveritySummary(rank, override: override);

  // === Level2 Anxiety 7 method 委托 (R118 P2-7 阶段 5) ===
  @override
  String level2AnxietyName({String? override}) =>
      _level2Anxiety.level2AnxietyName(override: override);

  @override
  String level2AnxietyShortDescription({String? override}) =>
      _level2Anxiety.level2AnxietyShortDescription(override: override);

  @override
  String level2AnxietyInstruction({String? override}) =>
      _level2Anxiety.level2AnxietyInstruction(override: override);

  @override
  String level2AnxietyItem(int index, {String? override}) =>
      _level2Anxiety.level2AnxietyItem(index, override: override);

  @override
  String level2AnxietyOption(int score, {String? override}) =>
      _level2Anxiety.level2AnxietyOption(score, override: override);

  @override
  String level2AnxietySeverityLabel(int rank, {String? override}) =>
      _level2Anxiety.level2AnxietySeverityLabel(rank, override: override);

  @override
  String level2AnxietySeveritySummary(int rank, {String? override}) =>
      _level2Anxiety.level2AnxietySeveritySummary(rank, override: override);

  // === Level2 Mania 7 method 委托 (R118 P2-7 阶段 6) ===
  @override
  String level2ManiaName({String? override}) =>
      _level2Mania.level2ManiaName(override: override);

  @override
  String level2ManiaShortDescription({String? override}) =>
      _level2Mania.level2ManiaShortDescription(override: override);

  @override
  String level2ManiaInstruction({String? override}) =>
      _level2Mania.level2ManiaInstruction(override: override);

  @override
  String level2ManiaItem(int index, {String? override}) =>
      _level2Mania.level2ManiaItem(index, override: override);

  @override
  String level2ManiaOption(int score, {String? override}) =>
      _level2Mania.level2ManiaOption(score, override: override);

  @override
  String level2ManiaSeverityLabel(int rank, {String? override}) =>
      _level2Mania.level2ManiaSeverityLabel(rank, override: override);

  @override
  String level2ManiaSeveritySummary(int rank, {String? override}) =>
      _level2Mania.level2ManiaSeveritySummary(rank, override: override);

  // === Level2 Psychosis 7 method 委托 (R118 P2-7 阶段 6) ===
  @override
  String level2PsychosisName({String? override}) =>
      _level2Psychosis.level2PsychosisName(override: override);

  @override
  String level2PsychosisShortDescription({String? override}) =>
      _level2Psychosis.level2PsychosisShortDescription(override: override);

  @override
  String level2PsychosisInstruction({String? override}) =>
      _level2Psychosis.level2PsychosisInstruction(override: override);

  @override
  String level2PsychosisItem(int index, {String? override}) =>
      _level2Psychosis.level2PsychosisItem(index, override: override);

  @override
  String level2PsychosisOption(int score, {String? override}) =>
      _level2Psychosis.level2PsychosisOption(score, override: override);

  @override
  String level2PsychosisSeverityLabel(int rank, {String? override}) =>
      _level2Psychosis.level2PsychosisSeverityLabel(rank, override: override);

  @override
  String level2PsychosisSeveritySummary(int rank, {String? override}) =>
      _level2Psychosis.level2PsychosisSeveritySummary(rank, override: override);

  @override
  String crisisHotlineLabel(
    HotlineRegion region, {
    int index = 0,
    String? override,
  }) {
    if (override != null) return override;
    final list = hotlineByRegion[region];
    if (list == null || list.isEmpty) return region.name;
    if (index < list.length) return list[index].label;
    return list.first.label;
  }

  @override
  String crisisTitle({String? override}) => override ?? '我们关心你';

  @override
  String crisisMessage({String? override}) =>
      override ?? '你提到了想伤害自己的念头。\n请记住：寻求帮助是勇敢的，不是软弱。';

  // ============================================================
  // PHQ-9 段抽到 phq9_translations.dart (R118 P2-7 阶段 1)
  // 主壳持 const _phq9 instance, 7 method 委托 (见上)
  // ============================================================

  // ============================================================
  // GAD-7 段抽到 gad7_translations.dart (R118 P2-7 阶段 2)
  // 主壳持 const _gad7 instance, 7 method 委托 (见上)
  // ============================================================

  // ============================================================
  // v0.30 round 90 (Task 2): 8 新量表中文 fallback
  // 内容 1:1 跟各自 const class displayName / shortDescription / instruction /
  // items / options / severityCutoffs.label+summary 一致 (Task 6 走 ARB)。
  // 跟 const class 同步: 重构量表题目 / 严重度档名时, 这里同步改。
  // ============================================================

  // ---- ISI + PSS 段抽到 isi_translations.dart + pss_translations.dart (R118 P2-7 阶段 3) ----

  // ---- WHODAS 段抽到 whodas_translations.dart (R118 P2-7 阶段 4) ----

  // ---- Level2 Depression + Anxiety 段抽到 level2_depression_translations.dart
  //      + level2_anxiety_translations.dart (R118 P2-7 阶段 5) ----


  // ---- ASRM (Altman 1997) ----
  static const _asrmItemsZh = [
    '心情比平时更好, 或感到兴奋 (elevated mood)',
    '自信增加, 或感到自己很重要',
    '睡眠需求减少, 仍感精力充沛',
    '话比平时多, 或说话速度加快',
    '思维奔逸, 想法快速跳跃',
  ];

  static const _asrmOptionsZh = {
    0: '完全没有',
    1: '轻微',
    2: '中度',
    3: '明显',
    4: '严重',
  };

  static const _asrmSeverityLabelZh = [
    '无症状',
    '轻度',
    '中度',
    '重度',
    '极重度',
  ];

  static const _asrmSeveritySummaryZh = [
    '无症状',
    '轻度躁狂倾向',
    '中度躁狂, 建议就医',
    '重度躁狂, 建议就医',
    '极重度躁狂, 强烈建议就医',
  ];

  @override
  String asrmName({String? override}) => override ?? 'ASRM 自评躁狂量表';

  @override
  String asrmShortDescription({String? override}) =>
      override ?? 'Altman 1997 自评躁狂量表 (5 题)';

  @override
  String asrmInstruction({String? override}) =>
      override ?? '过去 1 周内, 您有 (或感觉到) 以下情况的程度?';

  @override
  String asrmItem(int index, {String? override}) {
    if (override != null) return override;
    if (index < 0 || index >= _asrmItemsZh.length) return '';
    return _asrmItemsZh[index];
  }

  @override
  String asrmOption(int score, {String? override}) {
    if (override != null) return override;
    return _asrmOptionsZh[score] ?? '';
  }

  @override
  String asrmSeverityLabel(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _asrmSeverityLabelZh.length) return '';
    return _asrmSeverityLabelZh[rank];
  }

  @override
  String asrmSeveritySummary(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _asrmSeveritySummaryZh.length) return '';
    return _asrmSeveritySummaryZh[rank];
  }
}
// rule3-whitelist: 328, 332, 361-365, 369-373, 377-381, 385-389, 393, 397, 401
//   R113 BUG A: 精确行号豁免 (修前文件头 i18n 标记整文件豁免)
//   新增 CJK 字面量需自带 i18n 标记或扩本清单 — 详见 scripts/check_strings_hardcoded.py
