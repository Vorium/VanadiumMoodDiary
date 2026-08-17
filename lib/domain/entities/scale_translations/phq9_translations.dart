// v1.1.0 R118 (god class 拆 P2-7 阶段 1): PHQ-9 中文 fallback 独立 class
//
// 改前: static_scale_translations.dart 785L 1 个 class 10 量表 inline
// 改后: 10 独立 class + 主壳 composition (持 10 instance, method 委托)
//
// v1.0+ i18n canonical fallback (走 l10n, 显示层 l10n 优先)
// R108 §六 候选 拆解 (frame-thinking 评估)。

/// PHQ-9 (Patient Health Questionnaire-9 抑郁筛查 9 题) 中文 fallback
///
/// R118 P2-7 阶段 1: 原 [StaticScaleTranslations] PHQ-9 段 73L
///   (4 const + 7 method) 1:1 抽到本 class, 主壳用 instance 委托 method
///   (composition 模式, R118 试 mixin 失败后 fallback 方案)。
///
/// **v1.0+ i18n canonical fallback** — R107 R113 已加 i18n l10n,
/// 本 class 是 ARB key 缺失时的 fallback, 显示层优先走 l10n。
///
/// 注意: 本 class **不 implements ScaleTranslations** — 只放 PHQ-9 相关
/// const + method, 不实现其他 9 个量表 (留给 Gad7Translations /
/// IsiTranslations / ... 各自实现)。R118 阶段 2-5 拆其他 9 个量表。
class Phq9Translations {
  const Phq9Translations();

  // === 中文 fallback data (跟 const phq9Scale 同步, 改一处必同步) ===
  // canonical fallback (R118 P2-7 阶段 1 抽 PHQ-9 段, v1.0+ i18n) ===
  // rule3-whitelist: 25-93
  static const _itemsZh = <String>[
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

  static const _optionsZh = <int, String>{
    0: '完全不会',
    1: '好几天',
    2: '一半以上的天数',
    3: '几乎每天',
  };

  static const _severityLabelZh = <String>[
    '几乎没有抑郁',
    '轻度抑郁',
    '中度抑郁',
    '中重度抑郁',
    '重度抑郁',
  ];

  static const _severitySummaryZh = <String>[
    '几乎没有抑郁倾向',
    '轻度抑郁倾向',
    '中度抑郁倾向',
    '中重度抑郁倾向',
    '重度抑郁倾向',
  ];

  // === 7 method (主壳委托调用, 不带 @override) ===

  String phq9Name({String? override}) => override ?? 'PHQ-9 抑郁筛查';

  String phq9ShortDescription({String? override}) =>
      override ?? '过去两周的抑郁倾向筛查';

  String phq9Instruction({String? override}) =>
      override ?? '过去两周内，你有多经常被以下问题困扰？';

  String phq9Item(int index, {String? override}) {
    if (override != null) return override;
    if (index < 0 || index >= _itemsZh.length) return '';
    return _itemsZh[index];
  }

  String phq9Option(int score, {String? override}) {
    if (override != null) return override;
    return _optionsZh[score] ?? '';
  }

  String phq9SeverityLabel(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _severityLabelZh.length) return '';
    return _severityLabelZh[rank];
  }

  String phq9SeveritySummary(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _severitySummaryZh.length) return '';
    return _severitySummaryZh[rank];
  }
}
