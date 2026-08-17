// v1.1.0 R118 (god class 拆 P2-7 阶段 3): PSS 中文 fallback 独立 class
//
// 改前: static_scale_translations.dart 9 量表 inline
// 改后: 独立 class + 主壳 composition
//
// v1.0+ i18n canonical fallback (走 l10n, 显示层 l10n 优先)

/// PSS (Perceived Stress Scale, Cohen 1983, 压力量表 10 题含 4 反向) 中文 fallback
///
/// R118 P2-7 阶段 3: 原 [StaticScaleTranslations] PSS 段 70L
///   (4 const + 7 method) 1:1 抽到本 class, 主壳用 instance 委托 method。
///
/// **v1.0+ i18n canonical fallback** — R107 R113 已加 i18n l10n,
/// 本 class 是 ARB key 缺失时的 fallback, 显示层优先走 l10n。
// rule3-whitelist: 24-87
class PssTranslations {
  const PssTranslations();

  static const _itemsZh = <String>[
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

  static const _optionsZh = <int, String>{
    0: '从未',
    1: '几乎不',
    2: '有时',
    3: '经常',
    4: '总是',
  };

  static const _severityLabelZh = <String>[
    '低压力',
    '中度压力',
    '高压力',
  ];

  static const _severitySummaryZh = <String>[
    '低压力',
    '中度压力',
    '高压力, 建议关注和寻求支持',
  ];

  // === 7 method (主壳委托调用) ===

  String pssName({String? override}) => override ?? 'PSS 压力量表';

  String pssShortDescription({String? override}) =>
      override ?? 'Cohen 1983 压力量表 (10 题, 含 4 题反向)';

  String pssInstruction({String? override}) =>
      override ?? '过去 1 个月里, 您有多经常有下列感受?';

  String pssItem(int index, {String? override}) {
    if (override != null) return override;
    if (index < 0 || index >= _itemsZh.length) return '';
    return _itemsZh[index];
  }

  String pssOption(int score, {String? override}) {
    if (override != null) return override;
    return _optionsZh[score] ?? '';
  }

  String pssSeverityLabel(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _severityLabelZh.length) return '';
    return _severityLabelZh[rank];
  }

  String pssSeveritySummary(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _severitySummaryZh.length) return '';
    return _severitySummaryZh[rank];
  }
}
