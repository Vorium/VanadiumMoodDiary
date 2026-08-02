// 量表翻译抽象 (v0.28 round 65 spzh P1-A 起步)
//
// 背景 (spzh P1-A):
//   PHQ-9 / GAD-7 量表 16 题 + 9 档严重度 + 6 region 危机电话 label 全部 const
//   硬编中文, en / zh_Hant 用户看中文 label, 海外华人危机电话 region 路由被
//   中文 label 抵消 = 医疗法律责任。
//
// 修法 (起步, **不**完全 16 题 9 档 i18n 化):
//   1) 抽 `ScaleTranslations` abstract class
//   2) 改 `AssessmentScale` 抽象类加 `translations: ScaleTranslations` 字段
//   3) `Phq9Scale` / `Gad7Scale` 注入 ScaleTranslations (老 caller 用
//      `const StaticScaleTranslations()` 走中文 fallback)
//   4) `AppLocalizationsScaleTranslations` 走 `AppLocalizations` 包装
//   5) 6 个 i18n key (复用现有 `assessmentScalePhq9` / `assessmentScaleGad7`,
//      新加 `scaleHotlineCn` / `scaleHotlineUs` / `scaleHotlineHk` / `scaleHotlineIntl`)
//
// 16 题全文 i18n 化留 v1.0 (spzh report P1-A 已记 TODO)。
//
// 现有 21 case crisis test (`phq9_detect_crisis_round60_test.dart` + `phq9_round12_test.dart` +
// `gad7_round16_test.dart`) **不破** — 老 caller 走 `const StaticScaleTranslations()` 返中文
// fallback, hotlines 直接用 `hotlineByRegion[region]` const Map (label 是中文)。
// v0.28 起步版本额外: crisis hotlines 在 detectCrisis 时用 `translations.crisisHotlineLabel(region)`
// 翻译 label, region 不在 i18n key 范围 (tw/sg/uk) 走 intl fallback。

import 'package:chroniccare/domain/logic/assessment_scale.dart';

/// 量表翻译抽象
///
/// v0.27 R78 (spzh P1-A 跨 round 收尾): 加 PHQ-9 / GAD-7 全文 i18n 方法
/// (R65 起步 TODO 跨 R65/R71/R77 4 round 未动, en / zh_Hant 用户做 PHQ-9 /
/// GAD-7 看到中文题目 + 严重度 + 引导语 = 医疗法律责任)。
///
/// 覆盖:
/// - 2 个量表名 (phq9 / gad7) — R65 已加 `assessmentScalePhq9` / `assessmentScaleGad7`
/// - 6 region 危机电话 label (cn / us / hk / tw / sg / uk × 2) — R77 已加
/// - **R78 新增** PHQ-9: 9 题 + 4 档选项 + 5 严重度 (label + summary) +
///   1 instruction + 1 shortDescription = 21 method
/// - **R78 新增** GAD-7: 7 题 + 4 档选项 + 4 严重度 (label + summary) +
///   1 instruction + 1 shortDescription = 17 method
///
/// 总 50 method (R65+R77 12 + R78 38)。ARB key ≈ 50 × 3 语 = 150 (含 severity
/// label/summary 拆开)。
abstract class ScaleTranslations {
  const ScaleTranslations();

  /// PHQ-9 量表名
  String phq9Name({String? override});

  /// GAD-7 量表名
  String gad7Name({String? override});

  /// 6 region 危机电话 label (cn / us / hk / tw / sg / uk)
  ///
  /// v0.27 R77 (spzh P1-A 收尾): 加 [index] 支持 6 region × 2 hotline (cn/us/tw 各 2 个,
  /// hk/sg/uk 各 1 个, index=1 越界走 fallback first.label)。
  /// tw/sg/uk 之前走 intl fallback, 现在每 region 都有独立 i18n key。
  String crisisHotlineLabel(HotlineRegion region,
      {int index = 0, String? override,});

  /// v0.27 R71 (spzh P1-A 续): 危机弹窗标题 (PHQ-9 Q9 阳性时)
  /// — 之前 detectCrisis 用 const 中文 '我们关心你' 硬编, en / zh_Hant 用户看中文
  String crisisTitle({String? override});

  /// v0.27 R71 (spzh P1-A 续): 危机弹窗正文 (含换行)
  /// — 之前 detectCrisis 用 const 中文 '你提到了想伤害自己的念头...'
  String crisisMessage({String? override});

  // ============================================================
  // PHQ-9 全文 i18n (v0.27 R78)
  // ============================================================

  /// PHQ-9 第 [index] 题题目 (0-8, 9 道题)
  String phq9Item(int index, {String? override});

  /// PHQ-9 频率选项 (0-3, 共 4 档)
  String phq9Option(int score, {String? override});

  /// PHQ-9 严重度 [rank] 的短标签 (0-4, 用于图表/对比)
  String phq9SeverityLabel(int rank, {String? override});

  /// PHQ-9 严重度 [rank] 的完整描述 (用于结果页)
  String phq9SeveritySummary(int rank, {String? override});

  /// PHQ-9 顶部引导语 (答题页 instruction)
  String phq9Instruction({String? override});

  /// PHQ-9 短描述 (设置页副标题)
  String phq9ShortDescription({String? override});

  // ============================================================
  // GAD-7 全文 i18n (v0.27 R78)
  // ============================================================

  /// GAD-7 第 [index] 题题目 (0-6, 7 道题)
  String gad7Item(int index, {String? override});

  /// GAD-7 频率选项 (0-3, 共 4 档, 跟 PHQ-9 一致)
  String gad7Option(int score, {String? override});

  /// GAD-7 严重度 [rank] 的短标签 (0-3, 用于图表/对比)
  String gad7SeverityLabel(int rank, {String? override});

  /// GAD-7 严重度 [rank] 的完整描述 (用于结果页)
  String gad7SeveritySummary(int rank, {String? override});

  /// GAD-7 顶部引导语
  String gad7Instruction({String? override});

  /// GAD-7 短描述
  String gad7ShortDescription({String? override});
}

/// 静态中文 fallback (老 caller / 单测 / domain 0 flutter 边界)
class StaticScaleTranslations implements ScaleTranslations {
  const StaticScaleTranslations();

  @override
  String phq9Name({String? override}) => override ?? 'PHQ-9 抑郁筛查';

  @override
  String gad7Name({String? override}) => override ?? 'GAD-7 焦虑筛查';

  @override
  String crisisHotlineLabel(HotlineRegion region,
      {int index = 0, String? override,}) {
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
}

// v0.27 round 75 (R74 报告 P1-1 修): `AppLocalizationsScaleTranslations` 类
// 之前在本文件 (domain/)，import Flutter (软违规 4 层架构纯度)。
// 修法: 本类移到 presentation 层 `lib/presentation/services/scale_translations_l10n.dart`。
// domain 现在 0 Flutter import, 4 层架构纯度恢复。
// 当前 0 caller 引用 (R65 抽象 + R71 crisis i18n 抽 走 StaticScaleTranslations 中文 fallback),
// 移走 0 回归风险。
