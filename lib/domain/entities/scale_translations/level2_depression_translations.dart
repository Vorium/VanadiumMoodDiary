// v1.1.0 R118 (god class 拆 P2-7 阶段 5): Level2 Depression 中文 fallback
//
// 改前: static_scale_translations.dart 6 量表 inline (PHQ-9/GAD-7/ISI/PSS/WHODAS 已抽)
// 改后: 独立 class + 主壳 composition
//
// v1.0+ i18n canonical fallback (走 l10n, 显示层 l10n 优先)

/// DSM-5 Level 2 抑郁严重度 (PROMIS 简化, 8 题) 中文 fallback
///
/// R118 P2-7 阶段 5: 原 [StaticScaleTranslations] Level2 Depression 段 75L
///   (4 const + 7 method) 1:1 抽到本 class, 主壳用 instance 委托 method。
///
/// **v1.0+ i18n canonical fallback** — R107 R113 已加 i18n l10n,
/// 本 class 是 ARB key 缺失时的 fallback, 显示层优先走 l10n。
// rule3-whitelist: 24-91
class Level2DepressionTranslations {
  const Level2DepressionTranslations();

  static const _itemsZh = <String>[
    '感到心情低落',
    '感到没有希望',
    '感到自己很失败',
    '对任何事都提不起兴趣',
    '感到自己毫无价值',
    '感到内疚或羞耻',
    '感到无助',
    '觉得生活没有意义',
  ];

  static const _optionsZh = <int, String>{
    0: '完全没有',
    1: '几天',
    2: '一半以上的天数',
    3: '几乎每天',
  };

  static const _severityLabelZh = <String>[
    '无抑郁',
    '轻度抑郁',
    '中度抑郁',
    '重度抑郁',
  ];

  static const _severitySummaryZh = <String>[
    '无抑郁倾向',
    '轻度抑郁倾向',
    '中度抑郁, 建议就医',
    '重度抑郁, 强烈建议就医',
  ];

  // === 7 method (主壳委托调用) ===

  String level2DepressionName({String? override}) =>
      override ?? 'DSM-5 Level 2 抑郁严重度';

  String level2DepressionShortDescription({String? override}) =>
      override ?? '成人抑郁严重度 8 题 (DSM-5 PROMIS 简化版)';

  String level2DepressionInstruction({String? override}) =>
      override ?? '过去 7 天内, 您有多经常被以下情绪困扰?';

  String level2DepressionItem(int index, {String? override}) {
    if (override != null) return override;
    if (index < 0 || index >= _itemsZh.length) return '';
    return _itemsZh[index];
  }

  String level2DepressionOption(int score, {String? override}) {
    if (override != null) return override;
    return _optionsZh[score] ?? '';
  }

  String level2DepressionSeverityLabel(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _severityLabelZh.length) return '';
    return _severityLabelZh[rank];
  }

  String level2DepressionSeveritySummary(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _severitySummaryZh.length) return '';
    return _severitySummaryZh[rank];
  }
}
