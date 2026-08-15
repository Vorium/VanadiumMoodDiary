// 规则 3 标记: 量表中文 fallback — v1.0+ i18n (R51b backlog, 显示层走 l10n)
// GAD-7 广泛性焦虑量表
//
// 数据来源：Spitzer et al. (2006) 7-item Generalized Anxiety Disorder Scale
// 7 道题，每题 0-3 分，总分 0-21
//
// 严重度切分：
// 0-4   → 几乎没有
// 5-9   → 轻度
// 10-14 → 中度（建议就医）
// 15-21 → 重度（强烈建议就医）
//
// v0.28 round 65 (spzh P1-A 起步): `Gad7Scale` 加 `translations` 字段 —
// 老 const `gad7Scale` 不传走 `const StaticScaleTranslations()` 中文 fallback,
// 13 case test (`gad7_round16_test.dart`) 不破; 新 caller 传
// `AppLocalizationsScaleTranslations` 走 ARB 翻译。
// `displayName` 走 translations.gad7Name()。
//
// v0.27 R78 (spzh P1-A 跨 round 收尾): items / options / severityCutoffs /
// shortDescription / instruction 全走 translations.gad7Item(N) / .gad7Option(score) /
// .gad7SeverityLabel(rank) / .gad7SeveritySummary(rank) / .gad7ShortDescription() /
// .gad7Instruction()。13 case gad7_round16_test 走 const StaticScaleTranslations
// 返中文, 不破。

import 'package:chroniccare/domain/entities/scale_translations.dart';
import 'package:chroniccare/domain/logic/assessment_scale.dart';

/// 7 道题 (v0.27 R78: 仍保留 const list 作为 `StaticScaleTranslations.gad7Item`
/// fallback source, 但 `Gad7Scale.items` getter 改走 `translations.gad7Item(i)`)
const List<AssessmentItem> gad7Items = [
  AssessmentItem(0, '感到紧张、焦虑或急切'),
  AssessmentItem(1, '不能停止或控制担忧'),
  AssessmentItem(2, '对各种事情担忧过多'),
  AssessmentItem(3, '难以放松'),
  AssessmentItem(4, '心情烦躁以至坐不住'),
  AssessmentItem(5, '变得容易烦恼或急躁'),
  AssessmentItem(6, '感到似乎将有可怕的事情发生而害怕'),
];

/// 频率选项（0-3）—— 与 PHQ-9 一致
const Map<int, String> gad7Options = {
  0: '完全不会',
  1: '好几天',
  2: '一半以上的天数',
  3: '几乎每天',
};

/// GAD-7 量表实现
///
/// v0.28 round 65 (spzh P1-A 起步): 加 [translations] 字段 (默认
/// `const StaticScaleTranslations()` 中文 fallback, const 兼容)。
/// displayName 走 translations.gad7Name()。
class Gad7Scale implements AssessmentScale {
  @override
  final ScaleTranslations translations;
  const Gad7Scale({
    this.translations = const StaticScaleTranslations(),
  });

  @override
  String get id => 'gad7';

  @override
  String get displayName => translations.gad7Name();

  @override
  // v0.27 R78: 走 translations.gad7ShortDescription
  String get shortDescription => translations.gad7ShortDescription();

  @override
  // v0.27 R78: 走 translations.gad7Instruction
  String get instruction => translations.gad7Instruction();

  @override
  // v0.27 R78: items 走 translations.gad7Item(0..6)
  List<AssessmentItem> get items => List<AssessmentItem>.generate(
        7,
        (i) => AssessmentItem(i, translations.gad7Item(i)),
      );

  @override
  // v0.27 R78: 4 档频率选项走 translations.gad7Option(score)
  // (跟 PHQ-9 共用同一套 4 档, 但走 gad7Option 方法)
  Map<int, String> get options => {
        0: translations.gad7Option(0),
        1: translations.gad7Option(1),
        2: translations.gad7Option(2),
        3: translations.gad7Option(3),
      };

  @override
  int get totalRange => 21;

  @override
  // v0.27 R78: 4 档严重度走 translations
  List<SeverityCutoff> get severityCutoffs => List<SeverityCutoff>.generate(
        4,
        (rank) => SeverityCutoff(
          threshold: _gad7CutoffThresholds[rank],
          rank: rank,
          label: translations.gad7SeverityLabel(rank),
          summary: translations.gad7SeveritySummary(rank),
        ),
      );

  /// v0.27 R78: 4 档严重度 threshold
  static const _gad7CutoffThresholds = [4, 9, 14, 21];

  @override
  AssessmentResult computeResult(List<int> scores) {
    final total = scores.fold<int>(0, (a, b) => a + b);
    final cutoff = severityCutoffs.firstWhere(
      (c) => total <= c.threshold,
      orElse: () => severityCutoffs.last,
    );
    return AssessmentResult(
      total: total,
      summary: cutoff.summary,
      recommendDoctorVisit: cutoff.rank >= 2,
      urgentDoctorVisit: cutoff.rank >= 3,
    );
  }

  @override
  CrisisSignal? detectCrisis(
    List<int> scores,
    AssessmentResult result, {
    HotlineRegion region = HotlineRegion.cn,
  }) =>
      null;
}

/// GAD-7 单例（注册表用）
const gad7Scale = Gad7Scale();
