import 'package:chroniccare/domain/entities/scale_translations/_scale_translations_interfaces.dart';
// v1.1.0 R118 (god class 拆 P2-7 阶段 6): Level2 Mania 中文 fallback
//
// 改前: static_scale_translations.dart 4 量表 inline
// 改后: 独立 class + 主壳 composition
//
// v1.0+ i18n canonical fallback (走 l10n, 显示层 l10n 优先)

/// DSM-5 Level 2 躁狂严重度 (PROMIS 简化, 5 题) 中文 fallback
///
/// R118 P2-7 阶段 6: 原 [StaticScaleTranslations] Level2 Mania 段 68L
///   (4 const + 7 method) 1:1 抽到本 class, 主壳用 instance 委托 method。
///
/// **v1.0+ i18n canonical fallback** — R107 R113 已加 i18n l10n,
/// 本 class 是 ARB key 缺失时的 fallback, 显示层优先走 l10n。
// rule3-whitelist: 24-86
class Level2ManiaTranslations implements Level2ManiaTranslationsInterface {
  const Level2ManiaTranslations();

  static const _itemsZh = <String>[
    '感到精力异常旺盛',
    '思维奔逸',
    '睡眠需求减少但仍感精力充沛',
    '说话比平时多',
    '冲动做决定 (花钱、社交、性行为等)',
  ];

  static const _optionsZh = <int, String>{
    0: '完全没有',
    1: '几天',
    2: '一半以上的天数',
    3: '几乎每天',
  };

  static const _severityLabelZh = <String>[
    '无躁狂',
    '轻度躁狂',
    '中度躁狂',
    '重度躁狂',
  ];

  static const _severitySummaryZh = <String>[
    '无躁狂倾向',
    '轻度躁狂倾向',
    '中度躁狂, 建议就医',
    '重度躁狂, 强烈建议就医',
  ];

  // === 7 method (主壳委托调用) ===

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
    if (index < 0 || index >= _itemsZh.length) return '';
    return _itemsZh[index];
  }

  @override
  String level2ManiaOption(int score, {String? override}) {
    if (override != null) return override;
    return _optionsZh[score] ?? '';
  }

  @override
  String level2ManiaSeverityLabel(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _severityLabelZh.length) return '';
    return _severityLabelZh[rank];
  }

  @override
  String level2ManiaSeveritySummary(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _severitySummaryZh.length) return '';
    return _severitySummaryZh[rank];
  }
}
