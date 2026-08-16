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

/// 静态中文 fallback (老 caller / 单测 / domain 0 flutter 边界)
class StaticScaleTranslations implements ScaleTranslations {
  const StaticScaleTranslations();

  @override
  String phq9Name({String? override}) => override ?? 'PHQ-9 抑郁筛查';

  @override
  String gad7Name({String? override}) => override ?? 'GAD-7 焦虑筛查';

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
  // PHQ-9 中文 fallback (跟原 hardcode 1:1 一致)
  // ============================================================

  static const _phq9ItemsZh = [
    '做事时提不起劲或没有兴趣',
    '感到心情低落、沮丧或绝望',
    '入睡困难、睡不安稳或睡得过多',
    '感觉疲倦或没有活力',
    '食欲不振或吃太多',
    '觉得自己很糟、很失败，或让自己和家人失望',
    '对事物专注有困难，例如看报纸或看电视时',
    '动作或说话速度缓慢到别人能察觉？\n或正好相反——烦躁或坐立不安',
    '有不如死掉或用某种方式伤害自己的念头',
  ];

  static const _phq9OptionsZh = {
    0: '完全不会',
    1: '好几天',
    2: '一半以上的天数',
    3: '几乎每天',
  };

  static const _phq9SeverityLabelZh = [
    '几乎没有抑郁',
    '轻度抑郁',
    '中度抑郁',
    '中重度抑郁',
    '重度抑郁',
  ];

  static const _phq9SeveritySummaryZh = [
    '几乎没有抑郁倾向',
    '轻度抑郁倾向',
    '中度抑郁倾向',
    '中重度抑郁倾向',
    '重度抑郁倾向',
  ];

  @override
  String phq9Item(int index, {String? override}) {
    if (override != null) return override;
    if (index < 0 || index >= _phq9ItemsZh.length) return '';
    return _phq9ItemsZh[index];
  }

  @override
  String phq9Option(int score, {String? override}) {
    if (override != null) return override;
    return _phq9OptionsZh[score] ?? '';
  }

  @override
  String phq9SeverityLabel(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _phq9SeverityLabelZh.length) return '';
    return _phq9SeverityLabelZh[rank];
  }

  @override
  String phq9SeveritySummary(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _phq9SeveritySummaryZh.length) return '';
    return _phq9SeveritySummaryZh[rank];
  }

  @override
  String phq9Instruction({String? override}) =>
      override ?? '过去两周内，你有多经常被以下问题困扰？';

  @override
  String phq9ShortDescription({String? override}) => override ?? '过去两周的抑郁倾向筛查';

  // ============================================================
  // GAD-7 中文 fallback
  // ============================================================

  static const _gad7ItemsZh = [
    '感到紧张、焦虑或急切',
    '不能停止或控制担忧',
    '对各种事情担忧过多',
    '难以放松',
    '心情烦躁以至坐不住',
    '变得容易烦恼或急躁',
    '感到似乎将有可怕的事情发生而害怕',
  ];

  static const _gad7SeverityLabelZh = [
    '几乎没有焦虑',
    '轻度焦虑',
    '中度焦虑',
    '重度焦虑',
  ];

  static const _gad7SeveritySummaryZh = [
    '几乎没有焦虑倾向',
    '轻度焦虑倾向',
    '中度焦虑倾向',
    '重度焦虑倾向',
  ];

  @override
  String gad7Item(int index, {String? override}) {
    if (override != null) return override;
    if (index < 0 || index >= _gad7ItemsZh.length) return '';
    return _gad7ItemsZh[index];
  }

  @override
  String gad7Option(int score, {String? override}) {
    // GAD-7 跟 PHQ-9 共享同一套 4 档频率选项 (R19 决策保留)
    return phq9Option(score, override: override);
  }

  @override
  String gad7SeverityLabel(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _gad7SeverityLabelZh.length) return '';
    return _gad7SeverityLabelZh[rank];
  }

  @override
  String gad7SeveritySummary(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _gad7SeveritySummaryZh.length) return '';
    return _gad7SeveritySummaryZh[rank];
  }

  @override
  String gad7Instruction({String? override}) =>
      override ?? '过去两周内，你有多经常被以下问题困扰？';

  @override
  String gad7ShortDescription({String? override}) => override ?? '过去两周的焦虑倾向筛查';

  // ============================================================
  // v0.30 round 90 (Task 2): 8 新量表中文 fallback
  // 内容 1:1 跟各自 const class displayName / shortDescription / instruction /
  // items / options / severityCutoffs.label+summary 一致 (Task 6 走 ARB)。
  // 跟 const class 同步: 重构量表题目 / 严重度档名时, 这里同步改。
  // ============================================================

  // ---- ISI (Morin 1993) ----
  static const _isiItemsZh = [
    '入睡困难程度',
    '维持睡眠困难程度 (夜间醒来)',
    '早醒问题程度',
    '对当前睡眠模式的满意度',
    '睡眠问题对日常功能的影响程度',
    '睡眠问题在他人眼中明显的程度',
    '对当前睡眠问题的担忧 / 痛苦程度',
  ];

  static const _isiOptionsZh = {
    0: '无',
    1: '轻度',
    2: '中度',
    3: '重度',
    4: '极重度',
  };

  static const _isiSeverityLabelZh = [
    '无失眠',
    '阈下失眠',
    '中度失眠',
    '重度失眠',
  ];

  static const _isiSeveritySummaryZh = [
    '无临床失眠',
    '亚临床失眠, 建议关注',
    '中度失眠, 建议就医',
    '重度失眠, 强烈建议就医',
  ];

  @override
  String isiName({String? override}) => override ?? 'ISI 失眠严重指数';

  @override
  String isiShortDescription({String? override}) =>
      override ?? 'Morin 1993 失眠严重指数 7 题';

  @override
  String isiInstruction({String? override}) =>
      override ?? '过去 2 周内, 您的睡眠问题有多严重?';

  @override
  String isiItem(int index, {String? override}) {
    if (override != null) return override;
    if (index < 0 || index >= _isiItemsZh.length) return '';
    return _isiItemsZh[index];
  }

  @override
  String isiOption(int score, {String? override}) {
    if (override != null) return override;
    return _isiOptionsZh[score] ?? '';
  }

  @override
  String isiSeverityLabel(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _isiSeverityLabelZh.length) return '';
    return _isiSeverityLabelZh[rank];
  }

  @override
  String isiSeveritySummary(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _isiSeveritySummaryZh.length) return '';
    return _isiSeveritySummaryZh[rank];
  }

  // ---- PSS (Cohen 1983) ----
  static const _pssItemsZh = [
    '因为意外发生的事情而感到心烦意乱',
    '感到无法控制生活中重要的事情',
    '感到紧张和有压力',
    '自信能处理好个人问题 (反向)',
    '感到事情在按您期望的方向发展 (反向)',
    '发现自己无法应对必须完成的事情',
    '能控制生活中的烦人事 (反向)',
    '感到自己能掌控一切 (反向)',
    '因为无法控制的事情而恼火',
    '感到困难堆积得无法克服',
  ];

  static const _pssOptionsZh = {
    0: '从未',
    1: '几乎不',
    2: '有时',
    3: '经常',
    4: '总是',
  };

  static const _pssSeverityLabelZh = [
    '低压力',
    '中度压力',
    '高压力',
  ];

  static const _pssSeveritySummaryZh = [
    '低压力',
    '中度压力',
    '高压力, 建议关注和寻求支持',
  ];

  @override
  String pssName({String? override}) => override ?? 'PSS 压力量表';

  @override
  String pssShortDescription({String? override}) =>
      override ?? 'Cohen 1983 压力量表 (10 题, 含 4 题反向)';

  @override
  String pssInstruction({String? override}) =>
      override ?? '过去 1 个月里, 您有多经常有下列感受?';

  @override
  String pssItem(int index, {String? override}) {
    if (override != null) return override;
    if (index < 0 || index >= _pssItemsZh.length) return '';
    return _pssItemsZh[index];
  }

  @override
  String pssOption(int score, {String? override}) {
    if (override != null) return override;
    return _pssOptionsZh[score] ?? '';
  }

  @override
  String pssSeverityLabel(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _pssSeverityLabelZh.length) return '';
    return _pssSeverityLabelZh[rank];
  }

  @override
  String pssSeveritySummary(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _pssSeveritySummaryZh.length) return '';
    return _pssSeveritySummaryZh[rank];
  }

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
// rule3-whitelist: 32, 35, 51, 55, 62-70, 74-77, 81-85, 89-93, 125, 128, 135-141, 145-148, 152-155, 187, 190, 201-207, 211-215, 219-222, 226-229, 233, 237, 241, 272-281, 285-289, 293-295, 299-301, 305, 309, 313, 344-355, 359-363, 367-371, 375-379, 383, 387, 391, 422-429, 433-436, 440-443, 447-450, 455, 459, 463, 498-504, 508-511, 515-518, 522-525, 530, 534, 538, 569-573, 577-580, 584-587, 591-594, 599, 603, 607, 638-642, 646-650, 654-658, 662-666, 670, 674, 678, 709-716, 720-723, 727-730, 734-737, 742, 746, 750
//   R113 BUG A: 精确行号豁免 (修前文件头 i18n 标记整文件豁免)
//   新增 CJK 字面量需自带 i18n 标记或扩本清单 — 详见 scripts/check_strings_hardcoded.py
