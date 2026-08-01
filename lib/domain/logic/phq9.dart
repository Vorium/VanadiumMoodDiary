// PHQ-9 患者健康问卷抑郁量表
//
// 数据来源：美国精神医学学会（APA）DSM-IV 推荐筛查工具
// 9 道题，每题 0-3 分，总分 0-27
//
// 严重度切分：
// 0-4   → 几乎没有
// 5-9   → 轻度
// 10-14 → 中度（建议就医）
// 15-19 → 中重度（建议就医）
// 20-27 → 重度（强烈建议就医）
//
// 危机信号：第 9 题（自杀念头）≥ 1 → 弹出危机资源
//
// v0.28 round 65 (spzh P1-A 起步): `Phq9Scale` 加 `translations` 字段 —
// 老 const `phq9Scale` 不传走 `const StaticScaleTranslations()` 中文 fallback,
// 21 case crisis test 不破; 新 caller 传 `AppLocalizationsScaleTranslations`
// 走 ARB 翻译。`displayName` 走 translations.phq9Name()。

import 'package:chroniccare/domain/entities/scale_translations.dart';
import 'package:chroniccare/domain/logic/assessment_scale.dart';

/// 频率选项（0-3）
const Map<int, String> phq9Options = {
  0: '完全不会',
  1: '好几天',
  2: '一半以上的天数',
  3: '几乎每天',
};

enum Phq9Severity {
  minimal, // 0-4
  mild, // 5-9
  moderate, // 10-14
  moderatelySevere, // 15-19
  severe, // 20-27
}

class Phq9Result {
  final int total;
  final Phq9Severity severity;
  final String summary;

  const Phq9Result(this.total, this.severity, this.summary);

  static Phq9Result fromTotal(int total) {
    final cutoff = phq9Scale.severityCutoffs.firstWhere(
      (c) => total <= c.threshold,
      orElse: () => phq9Scale.severityCutoffs.last,
    );
    return Phq9Result(total, Phq9Severity.values[cutoff.rank], cutoff.summary);
  }
}

/// 第 9 题（自杀念头）阳性 → 立即提示
/// 总分 ≥ 10 → 建议就医
/// 总分 ≥ 20 → 强烈建议就医
extension Phq9CriticalConcerns on Phq9Result {
  bool get recommendDoctorVisit => total >= 10;
  bool get urgentDoctorVisit => total >= 20;
}

// ============================================================
// AssessmentScale 实现
// ============================================================

/// PHQ-9 量表（实现 AssessmentScale 接口）
///
/// v0.28 round 65 (spzh P1-A 起步): 加 [translations] 字段 (默认
/// `const StaticScaleTranslations()` 中文 fallback, const 兼容)。
/// displayName 走 translations.phq9Name()。
class Phq9Scale implements AssessmentScale {
  @override
  final ScaleTranslations translations;
  const Phq9Scale({
    this.translations = const StaticScaleTranslations(),
  });

  @override
  String get id => 'phq9';

  @override
  String get displayName => translations.phq9Name();

  @override
  String get shortDescription => '过去两周的抑郁倾向筛查';

  @override
  String get instruction => '过去两周内，你有多经常被以下问题困扰？';

  @override
  List<AssessmentItem> get items => const [
        AssessmentItem(0, '做事时提不起劲或没有兴趣'),
        AssessmentItem(1, '感到心情低落、沮丧或绝望'),
        AssessmentItem(2, '入睡困难、睡不安稳或睡得过多'),
        AssessmentItem(3, '感觉疲倦或没有活力'),
        AssessmentItem(4, '食欲不振或吃太多'),
        AssessmentItem(5, '觉得自己很糟、很失败，或让自己和家人失望'),
        AssessmentItem(6, '对事物专注有困难，例如看报纸或看电视时'),
        AssessmentItem(7, '动作或说话速度缓慢到别人能察觉？\n或正好相反——烦躁或坐立不安'),
        AssessmentItem(8, '有不如死掉或用某种方式伤害自己的念头'),
      ];

  @override
  Map<int, String> get options => phq9Options;

  @override
  int get totalRange => 27;

  @override
  List<SeverityCutoff> get severityCutoffs => const [
        SeverityCutoff(
            threshold: 4, rank: 0, label: '几乎没有抑郁', summary: '几乎没有抑郁倾向',),
        SeverityCutoff(threshold: 9, rank: 1, label: '轻度抑郁', summary: '轻度抑郁倾向'),
        SeverityCutoff(
            threshold: 14, rank: 2, label: '中度抑郁', summary: '中度抑郁倾向',),
        SeverityCutoff(
            threshold: 19, rank: 3, label: '中重度抑郁', summary: '中重度抑郁倾向',),
        SeverityCutoff(
            threshold: 27, rank: 4, label: '重度抑郁', summary: '重度抑郁倾向',),
      ];

  @override
  AssessmentResult computeResult(List<int> scores) {
    final total = scores.fold<int>(0, (a, b) => a + b);
    final r = Phq9Result.fromTotal(total);
    return AssessmentResult(
      total: r.total,
      summary: r.summary,
      recommendDoctorVisit: r.recommendDoctorVisit,
      urgentDoctorVisit: r.urgentDoctorVisit,
    );
  }

  @override
  CrisisSignal? detectCrisis(
    List<int> scores,
    AssessmentResult result, {
    HotlineRegion region = HotlineRegion.cn,
  }) {
    // 第 9 题（index 8）≥ 1 → 自杀念头阳性
    if (scores.length > 8 && scores[8] >= 1) {
      // v0.27 round 63 (P1-5 修复): 海外 region 可能未注册 (e.g. 之后
      // 扩 HotlineRegion 但忘加 crisis_number), `!` 强解会 NPE 崩。
      // 兜底走 cn (mainland 必有), 至少给用户一条可用 hotline。
      //
      // v0.28 round 65 (spzh P1-A 起步): hotlines label 暂保持 const 中文
      // (与 `hotlineByRegion[region]` 完全一致, 21 case test 不破)。
      // translations 字段已就位, R65b 阶段再把 hotlines label 走
      // translations.crisisHotlineLabel(region, index) 翻译 — 需要新加
      // 6 region × N hotline i18n key (本起步版本只加 4 region × 1st hotline)。
      return CrisisSignal(
        title: '我们关心你',
        message: '你提到了想伤害自己的念头。\n请记住：寻求帮助是勇敢的，不是软弱。',
        hotlines: hotlineByRegion[region] ?? hotlineByRegion[HotlineRegion.cn]!,
      );
    }
    return null;
  }
}

/// PHQ-9 单例（注册表用）
///
/// v0.28 round 65: const Phq9Scale() 默认走
/// `const StaticScaleTranslations()` 中文 fallback, 21 case test 不破。
const phq9Scale = Phq9Scale();
