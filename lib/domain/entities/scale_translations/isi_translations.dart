import 'package:chroniccare/domain/entities/scale_translations/_scale_translations_interfaces.dart';
// v1.1.0 R118 (god class 拆 P2-7 阶段 3): ISI 中文 fallback 独立 class
//
// 改前: static_scale_translations.dart 9 量表 inline
// 改后: 独立 class + 主壳 composition
//
// v1.0+ i18n canonical fallback (走 l10n, 显示层 l10n 优先)

/// ISI (Insomnia Severity Index, Morin 1993, 失眠严重指数 7 题) 中文 fallback
///
/// R118 P2-7 阶段 3: 原 [StaticScaleTranslations] ISI 段 70L
///   (4 const + 7 method) 1:1 抽到本 class, 主壳用 instance 委托 method。
///
/// **v1.0+ i18n canonical fallback** — R107 R113 已加 i18n l10n,
/// 本 class 是 ARB key 缺失时的 fallback, 显示层优先走 l10n。
// rule3-whitelist: 24-87
class IsiTranslations implements IsiTranslationsInterface {
  const IsiTranslations();

  static const _itemsZh = <String>[
    '入睡困难程度',
    '维持睡眠困难程度 (夜间醒来)',
    '早醒问题程度',
    '对当前睡眠模式的满意度',
    '睡眠问题对日常功能的影响程度',
    '睡眠问题在他人眼中明显的程度',
    '对当前睡眠问题的担忧 / 痛苦程度',
  ];

  static const _optionsZh = <int, String>{
    0: '无',
    1: '轻度',
    2: '中度',
    3: '重度',
    4: '极重度',
  };

  static const _severityLabelZh = <String>[
    '无失眠',
    '阈下失眠',
    '中度失眠',
    '重度失眠',
  ];

  static const _severitySummaryZh = <String>[
    '无临床失眠',
    '亚临床失眠, 建议关注',
    '中度失眠, 建议就医',
    '重度失眠, 强烈建议就医',
  ];

  // === 7 method (主壳委托调用) ===

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
    if (index < 0 || index >= _itemsZh.length) return '';
    return _itemsZh[index];
  }

  @override
  String isiOption(int score, {String? override}) {
    if (override != null) return override;
    return _optionsZh[score] ?? '';
  }

  @override
  String isiSeverityLabel(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _severityLabelZh.length) return '';
    return _severityLabelZh[rank];
  }

  @override
  String isiSeveritySummary(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _severitySummaryZh.length) return '';
    return _severitySummaryZh[rank];
  }
}
