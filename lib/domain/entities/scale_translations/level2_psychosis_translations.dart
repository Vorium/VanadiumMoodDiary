import 'package:chroniccare/domain/entities/scale_translations/_scale_translations_interfaces.dart';
// v1.1.0 R118 (god class 拆 P2-7 阶段 6): Level2 Psychosis 中文 fallback
//
// 改前: static_scale_translations.dart 4 量表 inline
// 改后: 独立 class + 主壳 composition
//
// v1.0+ i18n canonical fallback (走 l10n, 显示层 l10n 优先)

/// DSM-5 Level 2 精神病性症状 (PROMIS 简化, 8 题) 中文 fallback
///
/// R118 P2-7 阶段 6: 原 [StaticScaleTranslations] Level2 Psychosis 段 74L
///   (4 const + 7 method) 1:1 抽到本 class, 主壳用 instance 委托 method。
///
/// **v1.0+ i18n canonical fallback** — R107 R113 已加 i18n l10n,
/// 本 class 是 ARB key 缺失时的 fallback, 显示层优先走 l10n。
// rule3-whitelist: 24-92
class Level2PsychosisTranslations implements Level2PsychosisTranslationsInterface {
  const Level2PsychosisTranslations();

  static const _itemsZh = <String>[
    '听到别人听不到的声音',
    '觉得有人想伤害您',
    '觉得有人在监视您',
    '觉得自己的思维被控制或被广播',
    '看到别人看不到的东西',
    '觉得自己的思维被打断或被插入',
    '觉得周围的事情与自己有关',
    '感到现实不太真实',
  ];

  static const _optionsZh = <int, String>{
    0: '从来没有',
    1: '很少',
    2: '有时',
    3: '经常',
  };

  static const _severityLabelZh = <String>[
    '无症状',
    '轻度',
    '中度',
    '重度',
  ];

  static const _severitySummaryZh = <String>[
    '无精神病性症状',
    '轻度精神病性症状',
    '中度精神病性症状, 建议就医',
    '重度精神病性症状, 强烈建议就医',
  ];

  // === 7 method (主壳委托调用) ===

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
    if (index < 0 || index >= _itemsZh.length) return '';
    return _itemsZh[index];
  }

  @override
  String level2PsychosisOption(int score, {String? override}) {
    if (override != null) return override;
    return _optionsZh[score] ?? '';
  }

  @override
  String level2PsychosisSeverityLabel(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _severityLabelZh.length) {
      return '';
    }
    return _severityLabelZh[rank];
  }

  @override
  String level2PsychosisSeveritySummary(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _severitySummaryZh.length) {
      return '';
    }
    return _severitySummaryZh[rank];
  }
}
