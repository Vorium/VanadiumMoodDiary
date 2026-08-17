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
import 'package:chroniccare/domain/entities/scale_translations/phq9_translations.dart';
import 'package:chroniccare/domain/entities/scale_translations/pss_translations.dart';

/// 静态中文 fallback (老 caller / 单测 / domain 0 flutter 边界)
class StaticScaleTranslations implements ScaleTranslations {
  const StaticScaleTranslations();

  // v1.1.0 R118 (god class 拆 P2-7): composition 委托 10 个量表到独立 class
  // 阶段 1: PHQ-9 → Phq9Translations (R118 round 1)
  // 阶段 2: GAD-7 → Gad7Translations (R118 round 2)
  // 阶段 3: ISI + PSS → IsiTranslations + PssTranslations (R118 round 3)
  // 阶段 4-5: 拆 WHODAS + 4 个 Level2 + ASRM
  static const _phq9 = Phq9Translations();
  static const _gad7 = Gad7Translations();
  static const _isi = IsiTranslations();
  static const _pss = PssTranslations();

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

  // ---- WHODAS 2.0 (WHO 12 题简化) ----
  static const _whodasItemsZh = [
    '理解并与他人交流',
    '四处走动',
    '自我照顾 (如洗澡、穿衣)',
    '与他人相处',
    '承担家庭 / 工作责任',
    '参与社区活动',
    '集中注意力做事',
    '短距离步行',
    '清洗全身',
    '与陌生人相处',
    '维持朋友关系',
    '完成日常工作任务',
  ];

  static const _whodasOptionsZh = {
    0: '没有',
    1: '轻微',
    2: '中度',
    3: '重度',
    4: '极重度',
  };

  static const _whodasSeverityLabelZh = [
    '无残疾',
    '轻度残疾',
    '中度残疾',
    '重度残疾',
    '极重度残疾',
  ];

  static const _whodasSeveritySummaryZh = [
    '无残疾',
    '轻度残疾',
    '中度残疾, 建议就医评估',
    '重度残疾, 建议就医',
    '极重度残疾, 强烈建议就医',
  ];

  @override
  String whodasName({String? override}) => override ?? 'WHODAS 2.0 残疾评定';

  @override
  String whodasShortDescription({String? override}) =>
      override ?? 'WHO 通用残疾评估 12 题简化版';

  @override
  String whodasInstruction({String? override}) =>
      override ?? '过去 30 天内, 您在以下活动中遇到多大困难?';

  @override
  String whodasItem(int index, {String? override}) {
    if (override != null) return override;
    if (index < 0 || index >= _whodasItemsZh.length) return '';
    return _whodasItemsZh[index];
  }

  @override
  String whodasOption(int score, {String? override}) {
    if (override != null) return override;
    return _whodasOptionsZh[score] ?? '';
  }

  @override
  String whodasSeverityLabel(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _whodasSeverityLabelZh.length) return '';
    return _whodasSeverityLabelZh[rank];
  }

  @override
  String whodasSeveritySummary(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _whodasSeveritySummaryZh.length) return '';
    return _whodasSeveritySummaryZh[rank];
  }

  // ---- DSM-5 Level 2 抑郁严重度 (PROMIS 简化) ----
  static const _level2DepressionItemsZh = [
    '感到心情低落',
    '感到没有希望',
    '感到自己很失败',
    '对任何事都提不起兴趣',
    '感到自己毫无价值',
    '感到内疚或羞耻',
    '感到无助',
    '觉得生活没有意义',
  ];

  static const _level2DepressionOptionsZh = {
    0: '完全没有',
    1: '几天',
    2: '一半以上的天数',
    3: '几乎每天',
  };

  static const _level2DepressionSeverityLabelZh = [
    '无抑郁',
    '轻度抑郁',
    '中度抑郁',
    '重度抑郁',
  ];

  static const _level2DepressionSeveritySummaryZh = [
    '无抑郁倾向',
    '轻度抑郁倾向',
    '中度抑郁, 建议就医',
    '重度抑郁, 强烈建议就医',
  ];

  @override
  String level2DepressionName({String? override}) =>
      override ?? 'DSM-5 Level 2 抑郁严重度';

  @override
  String level2DepressionShortDescription({String? override}) =>
      override ?? '成人抑郁严重度 8 题 (DSM-5 PROMIS 简化版)';

  @override
  String level2DepressionInstruction({String? override}) =>
      override ?? '过去 7 天内, 您有多经常被以下情绪困扰?';

  @override
  String level2DepressionItem(int index, {String? override}) {
    if (override != null) return override;
    if (index < 0 || index >= _level2DepressionItemsZh.length) return '';
    return _level2DepressionItemsZh[index];
  }

  @override
  String level2DepressionOption(int score, {String? override}) {
    if (override != null) return override;
    return _level2DepressionOptionsZh[score] ?? '';
  }

  @override
  String level2DepressionSeverityLabel(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _level2DepressionSeverityLabelZh.length) {
      return '';
    }
    return _level2DepressionSeverityLabelZh[rank];
  }

  @override
  String level2DepressionSeveritySummary(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _level2DepressionSeveritySummaryZh.length) {
      return '';
    }
    return _level2DepressionSeveritySummaryZh[rank];
  }

  // ---- DSM-5 Level 2 焦虑严重度 (PROMIS 简化) ----
  static const _level2AnxietyItemsZh = [
    '感到紧张',
    '感到担心',
    '感到烦躁不安',
    '感到害怕',
    '感到惊慌',
    '感到坐立不安',
    '感到难以放松',
  ];

  static const _level2AnxietyOptionsZh = {
    0: '完全没有',
    1: '几天',
    2: '一半以上的天数',
    3: '几乎每天',
  };

  static const _level2AnxietySeverityLabelZh = [
    '无焦虑',
    '轻度焦虑',
    '中度焦虑',
    '重度焦虑',
  ];

  static const _level2AnxietySeveritySummaryZh = [
    '无焦虑倾向',
    '轻度焦虑倾向',
    '中度焦虑, 建议就医',
    '重度焦虑, 强烈建议就医',
  ];

  @override
  String level2AnxietyName({String? override}) =>
      override ?? 'DSM-5 Level 2 焦虑严重度';

  @override
  String level2AnxietyShortDescription({String? override}) =>
      override ?? '成人焦虑严重度 7 题 (DSM-5 PROMIS 简化版)';

  @override
  String level2AnxietyInstruction({String? override}) =>
      override ?? '过去 7 天内, 您有多经常被以下感受困扰?';

  @override
  String level2AnxietyItem(int index, {String? override}) {
    if (override != null) return override;
    if (index < 0 || index >= _level2AnxietyItemsZh.length) return '';
    return _level2AnxietyItemsZh[index];
  }

  @override
  String level2AnxietyOption(int score, {String? override}) {
    if (override != null) return override;
    return _level2AnxietyOptionsZh[score] ?? '';
  }

  @override
  String level2AnxietySeverityLabel(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _level2AnxietySeverityLabelZh.length) return '';
    return _level2AnxietySeverityLabelZh[rank];
  }

  @override
  String level2AnxietySeveritySummary(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _level2AnxietySeveritySummaryZh.length) return '';
    return _level2AnxietySeveritySummaryZh[rank];
  }

  // ---- DSM-5 Level 2 躁狂严重度 (PROMIS 简化) ----
  static const _level2ManiaItemsZh = [
    '感到精力异常旺盛',
    '思维奔逸',
    '睡眠需求减少但仍感精力充沛',
    '说话比平时多',
    '冲动做决定 (花钱、社交、性行为等)',
  ];

  static const _level2ManiaOptionsZh = {
    0: '完全没有',
    1: '几天',
    2: '一半以上的天数',
    3: '几乎每天',
  };

  static const _level2ManiaSeverityLabelZh = [
    '无躁狂',
    '轻度躁狂',
    '中度躁狂',
    '重度躁狂',
  ];

  static const _level2ManiaSeveritySummaryZh = [
    '无躁狂倾向',
    '轻度躁狂倾向',
    '中度躁狂, 建议就医',
    '重度躁狂, 强烈建议就医',
  ];

  @override
  String level2ManiaName({String? override}) =>
      override ?? 'DSM-5 Level 2 躁狂严重度';

  @override
  String level2ManiaShortDescription({String? override}) =>
      override ?? '成人躁狂严重度 5 题 (DSM-5 PROMIS 简化版)';

  @override
  String level2ManiaInstruction({String? override}) =>
      override ?? '过去 7 天内, 您有多经常体验以下情况?';

  @override
  String level2ManiaItem(int index, {String? override}) {
    if (override != null) return override;
    if (index < 0 || index >= _level2ManiaItemsZh.length) return '';
    return _level2ManiaItemsZh[index];
  }

  @override
  String level2ManiaOption(int score, {String? override}) {
    if (override != null) return override;
    return _level2ManiaOptionsZh[score] ?? '';
  }

  @override
  String level2ManiaSeverityLabel(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _level2ManiaSeverityLabelZh.length) return '';
    return _level2ManiaSeverityLabelZh[rank];
  }

  @override
  String level2ManiaSeveritySummary(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _level2ManiaSeveritySummaryZh.length) return '';
    return _level2ManiaSeveritySummaryZh[rank];
  }

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

  // ---- DSM-5 Level 2 精神病性症状 (PROMIS 简化) ----
  static const _level2PsychosisItemsZh = [
    '听到别人听不到的声音',
    '觉得有人想伤害您',
    '觉得有人在监视您',
    '觉得自己的思维被控制或被广播',
    '看到别人看不到的东西',
    '觉得自己的思维被打断或被插入',
    '觉得周围的事情与自己有关',
    '感到现实不太真实',
  ];

  static const _level2PsychosisOptionsZh = {
    0: '从来没有',
    1: '很少',
    2: '有时',
    3: '经常',
  };

  static const _level2PsychosisSeverityLabelZh = [
    '无症状',
    '轻度',
    '中度',
    '重度',
  ];

  static const _level2PsychosisSeveritySummaryZh = [
    '无精神病性症状',
    '轻度精神病性症状',
    '中度精神病性症状, 建议就医',
    '重度精神病性症状, 强烈建议就医',
  ];

  @override
  String level2PsychosisName({String? override}) =>
      override ?? 'DSM-5 Level 2 精神病性症状';

  @override
  String level2PsychosisShortDescription({String? override}) =>
      override ?? '成人精神病性症状 8 题 (DSM-5 简化版)';

  @override
  String level2PsychosisInstruction({String? override}) =>
      override ?? '过去 7 天内, 您有多经常体验以下情况?';

  @override
  String level2PsychosisItem(int index, {String? override}) {
    if (override != null) return override;
    if (index < 0 || index >= _level2PsychosisItemsZh.length) return '';
    return _level2PsychosisItemsZh[index];
  }

  @override
  String level2PsychosisOption(int score, {String? override}) {
    if (override != null) return override;
    return _level2PsychosisOptionsZh[score] ?? '';
  }

  @override
  String level2PsychosisSeverityLabel(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _level2PsychosisSeverityLabelZh.length) {
      return '';
    }
    return _level2PsychosisSeverityLabelZh[rank];
  }

  @override
  String level2PsychosisSeveritySummary(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _level2PsychosisSeveritySummaryZh.length) {
      return '';
    }
    return _level2PsychosisSeveritySummaryZh[rank];
  }
}
// rule3-whitelist: 171, 175, 198-209, 213-217, 221-225, 229-233, 237, 241, 245, 276-283, 287-290, 294-297, 301-304, 309, 313, 317, 352-358, 362-365, 369-372, 376-379, 384, 388, 392, 423-427, 431-434, 438-441, 445-448, 453, 457, 461, 492-496, 500-504, 508-512, 516-520, 524, 528, 532, 563-570, 574-577, 581-584, 588-591, 596, 600, 604
//   R113 BUG A: 精确行号豁免 (修前文件头 i18n 标记整文件豁免)
//   新增 CJK 字面量需自带 i18n 标记或扩本清单 — 详见 scripts/check_strings_hardcoded.py
