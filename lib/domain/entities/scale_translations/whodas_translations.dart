// v1.1.0 R118 (god class 拆 P2-7 阶段 4): WHODAS 中文 fallback 独立 class
//
// 改前: static_scale_translations.dart 8 量表 inline (PHQ-9/GAD-7/ISI/PSS 已抽)
// 改后: 独立 class + 主壳 composition
//
// v1.0+ i18n canonical fallback (走 l10n, 显示层 l10n 优先)

/// WHODAS 2.0 (WHO 通用残疾评估 12 题简化版) 中文 fallback
///
/// R118 P2-7 阶段 4: 原 [StaticScaleTranslations] WHODAS 段 76L
///   (4 const + 7 method) 1:1 抽到本 class, 主壳用 instance 委托 method。
///
/// **v1.0+ i18n canonical fallback** — R107 R113 已加 i18n l10n,
/// 本 class 是 ARB key 缺失时的 fallback, 显示层优先走 l10n。
// rule3-whitelist: 24-92
class WhodasTranslations {
  const WhodasTranslations();

  static const _itemsZh = <String>[
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

  static const _optionsZh = <int, String>{
    0: '没有',
    1: '轻微',
    2: '中度',
    3: '重度',
    4: '极重度',
  };

  static const _severityLabelZh = <String>[
    '无残疾',
    '轻度残疾',
    '中度残疾',
    '重度残疾',
    '极重度残疾',
  ];

  static const _severitySummaryZh = <String>[
    '无残疾',
    '轻度残疾',
    '中度残疾, 建议就医评估',
    '重度残疾, 建议就医',
    '极重度残疾, 强烈建议就医',
  ];

  // === 7 method (主壳委托调用) ===

  String whodasName({String? override}) => override ?? 'WHODAS 2.0 残疾评定';

  String whodasShortDescription({String? override}) =>
      override ?? 'WHO 通用残疾评估 12 题简化版';

  String whodasInstruction({String? override}) =>
      override ?? '过去 30 天内, 您在以下活动中遇到多大困难?';

  String whodasItem(int index, {String? override}) {
    if (override != null) return override;
    if (index < 0 || index >= _itemsZh.length) return '';
    return _itemsZh[index];
  }

  String whodasOption(int score, {String? override}) {
    if (override != null) return override;
    return _optionsZh[score] ?? '';
  }

  String whodasSeverityLabel(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _severityLabelZh.length) return '';
    return _severityLabelZh[rank];
  }

  String whodasSeveritySummary(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _severitySummaryZh.length) return '';
    return _severitySummaryZh[rank];
  }
}
