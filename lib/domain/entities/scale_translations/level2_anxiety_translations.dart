import 'package:chroniccare/domain/entities/scale_translations/_scale_translations_interfaces.dart';
// v1.1.0 R118 (god class 拆 P2-7 阶段 5): Level2 Anxiety 中文 fallback
//
// 改前: static_scale_translations.dart 6 量表 inline
// 改后: 独立 class + 主壳 composition
//
// v1.0+ i18n canonical fallback (走 l10n, 显示层 l10n 优先)

/// DSM-5 Level 2 焦虑严重度 (PROMIS 简化, 7 题) 中文 fallback
///
/// R118 P2-7 阶段 5: 原 [StaticScaleTranslations] Level2 Anxiety 段 70L
///   (4 const + 7 method) 1:1 抽到本 class, 主壳用 instance 委托 method。
///
/// **v1.0+ i18n canonical fallback** — R107 R113 已加 i18n l10n,
/// 本 class 是 ARB key 缺失时的 fallback, 显示层优先走 l10n。
// rule3-whitelist: 24-88
class Level2AnxietyTranslations implements Level2AnxietyTranslationsInterface {
  const Level2AnxietyTranslations();

  static const _itemsZh = <String>[
    '感到紧张',
    '感到担心',
    '感到烦躁不安',
    '感到害怕',
    '感到惊慌',
    '感到坐立不安',
    '感到难以放松',
  ];

  static const _optionsZh = <int, String>{
    0: '完全没有',
    1: '几天',
    2: '一半以上的天数',
    3: '几乎每天',
  };

  static const _severityLabelZh = <String>[
    '无焦虑',
    '轻度焦虑',
    '中度焦虑',
    '重度焦虑',
  ];

  static const _severitySummaryZh = <String>[
    '无焦虑倾向',
    '轻度焦虑倾向',
    '中度焦虑, 建议就医',
    '重度焦虑, 强烈建议就医',
  ];

  // === 7 method (主壳委托调用) ===

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
    if (index < 0 || index >= _itemsZh.length) return '';
    return _itemsZh[index];
  }

  @override
  String level2AnxietyOption(int score, {String? override}) {
    if (override != null) return override;
    return _optionsZh[score] ?? '';
  }

  @override
  String level2AnxietySeverityLabel(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _severityLabelZh.length) return '';
    return _severityLabelZh[rank];
  }

  @override
  String level2AnxietySeveritySummary(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _severitySummaryZh.length) return '';
    return _severitySummaryZh[rank];
  }
}
