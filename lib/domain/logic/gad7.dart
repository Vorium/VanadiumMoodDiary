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

import 'package:chroniccare/domain/entities/scale_translations.dart';
import 'package:chroniccare/domain/logic/assessment_scale.dart';

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
  String get shortDescription => '过去两周的焦虑倾向筛查';

  @override
  String get instruction => '过去两周内，你有多经常被以下问题困扰？';

  @override
  List<AssessmentItem> get items => gad7Items;

  @override
  Map<int, String> get options => gad7Options;

  @override
  int get totalRange => 21;

  @override
  List<SeverityCutoff> get severityCutoffs => const [
        SeverityCutoff(threshold: 4, rank: 0, label: '几乎没有焦虑', summary: '几乎没有焦虑倾向'),
        SeverityCutoff(threshold: 9, rank: 1, label: '轻度焦虑', summary: '轻度焦虑倾向'),
        SeverityCutoff(threshold: 14, rank: 2, label: '中度焦虑', summary: '中度焦虑倾向'),
        SeverityCutoff(threshold: 21, rank: 3, label: '重度焦虑', summary: '重度焦虑倾向'),
      ];

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
