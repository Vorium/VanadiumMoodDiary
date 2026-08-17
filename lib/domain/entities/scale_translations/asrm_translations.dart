// v1.1.0 R118 (god class 拆 P2-7 阶段 7): ASRM 中文 fallback
//
// 改前: static_scale_translations.dart 9 量表 inline
// 改后: 独立 class + 主壳 composition
//
// v1.0+ i18n canonical fallback (走 l10n, 显示层 l10n 优先)

/// ASRM (Altman Self-Rating Mania Scale, 1997, 自评躁狂量表 5 题) 中文 fallback
///
/// R118 P2-7 阶段 7: 原 [StaticScaleTranslations] ASRM 段 70L
///   (4 const + 7 method) 1:1 抽到本 class, 主壳用 instance 委托 method。
///
/// **v1.0+ i18n canonical fallback** — R107 R113 已加 i18n l10n,
/// 本 class 是 ARB key 缺失时的 fallback, 显示层优先走 l10n。
// rule3-whitelist: 24-90
class AsrmTranslations {
  const AsrmTranslations();

  static const _itemsZh = <String>[
    '心情比平时更好, 或感到兴奋 (elevated mood)',
    '自信增加, 或感到自己很重要',
    '睡眠需求减少, 仍感精力充沛',
    '话比平时多, 或说话速度加快',
    '思维奔逸, 想法快速跳跃',
  ];

  static const _optionsZh = <int, String>{
    0: '完全没有',
    1: '轻微',
    2: '中度',
    3: '明显',
    4: '严重',
  };

  static const _severityLabelZh = <String>[
    '无症状',
    '轻度',
    '中度',
    '重度',
    '极重度',
  ];

  static const _severitySummaryZh = <String>[
    '无症状',
    '轻度躁狂倾向',
    '中度躁狂, 建议就医',
    '重度躁狂, 建议就医',
    '极重度躁狂, 强烈建议就医',
  ];

  // === 7 method (主壳委托调用) ===

  String asrmName({String? override}) => override ?? 'ASRM 自评躁狂量表';

  String asrmShortDescription({String? override}) =>
      override ?? 'Altman 1997 自评躁狂量表 (5 题)';

  String asrmInstruction({String? override}) =>
      override ?? '过去 1 周内, 您有 (或感觉到) 以下情况的程度?';

  String asrmItem(int index, {String? override}) {
    if (override != null) return override;
    if (index < 0 || index >= _itemsZh.length) return '';
    return _itemsZh[index];
  }

  String asrmOption(int score, {String? override}) {
    if (override != null) return override;
    return _optionsZh[score] ?? '';
  }

  String asrmSeverityLabel(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _severityLabelZh.length) return '';
    return _severityLabelZh[rank];
  }

  String asrmSeveritySummary(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _severitySummaryZh.length) return '';
    return _severitySummaryZh[rank];
  }
}
