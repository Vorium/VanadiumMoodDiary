// v1.1.0 R118 (god class 拆 P2-7 阶段 2): GAD-7 中文 fallback 独立 class
//
// 改前: static_scale_translations.dart 747L 1 个 class 9 量表 inline (PHQ-9 已抽)
// 改后: 9 独立 class + 主壳 composition (持 9 instance, method 委托)
//
// v1.0+ i18n canonical fallback (走 l10n, 显示层 l10n 优先)
// R108 §六 候选 拆解 (frame-thinking 评估)。

import 'package:chroniccare/domain/entities/scale_translations/phq9_translations.dart';
import 'package:chroniccare/domain/entities/scale_translations/_scale_translations_interfaces.dart';

/// GAD-7 (Generalized Anxiety Disorder-7 焦虑筛查 7 题) 中文 fallback
///
/// R118 P2-7 阶段 2: 原 [StaticScaleTranslations] GAD-7 段 60L
///   (3 const + 7 method, gad7Option 委托 phq9Option 共享 4 档频率选项)
///   1:1 抽到本 class, 主壳用 instance 委托 method (composition 模式)。
///
/// **v1.0+ i18n canonical fallback** — R107 R113 已加 i18n l10n,
/// 本 class 是 ARB key 缺失时的 fallback, 显示层优先走 l10n。
// rule3-whitelist: 28-66
class Gad7Translations implements Gad7TranslationsInterface {
  const Gad7Translations();

  // === 中文 fallback data (跟 const gad7Scale 同步, 改一处必同步) ===

  static const _itemsZh = <String>[
    '感到紧张、焦虑或急切',
    '不能停止或控制担忧',
    '对各种事情担忧过多',
    '难以放松',
    '心情烦躁以至坐不住',
    '变得容易烦恼或急躁',
    '感到似乎将有可怕的事情发生而害怕',
  ];

  static const _severityLabelZh = <String>[
    '几乎没有焦虑',
    '轻度焦虑',
    '中度焦虑',
    '重度焦虑',
  ];

  static const _severitySummaryZh = <String>[
    '几乎没有焦虑倾向',
    '轻度焦虑倾向',
    '中度焦虑倾向',
    '重度焦虑倾向',
  ];

  // === 7 method (主壳委托调用, 不带 @override) ===

  @override
  String gad7Name({String? override}) => override ?? 'GAD-7 焦虑筛查';

  @override
  String gad7ShortDescription({String? override}) =>
      override ?? '过去两周的焦虑倾向筛查';

  @override
  String gad7Instruction({String? override}) =>
      override ?? '过去两周内，你有多经常被以下问题困扰？';

  @override
  String gad7Item(int index, {String? override}) {
    if (override != null) return override;
    if (index < 0 || index >= _itemsZh.length) return '';
    return _itemsZh[index];
  }

  // GAD-7 跟 PHQ-9 共享同一套 4 档频率选项 (R19 决策保留)
  // 委托 Phq9Translations.phq9Option (R118 P2-7 阶段 2 跨 class 委托)
  @override
  String gad7Option(int score, {String? override}) {
    // 注意: 这里走 Phq9Translations 静态 + instance, 不直接读 Phq9Translations
    // const data (避免循环依赖: phq9 → gad7 委托 → phq9)
    return const Phq9Translations().phq9Option(score, override: override);
  }

  @override
  String gad7SeverityLabel(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _severityLabelZh.length) return '';
    return _severityLabelZh[rank];
  }

  @override
  String gad7SeveritySummary(int rank, {String? override}) {
    if (override != null) return override;
    if (rank < 0 || rank >= _severitySummaryZh.length) return '';
    return _severitySummaryZh[rank];
  }
}
