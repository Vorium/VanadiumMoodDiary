// 规则 3 标记: 量表中文 fallback — v1.0+ i18n (R51b backlog, 显示层走 l10n)
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
//
// v0.27 R78 (spzh P1-A 跨 round 收尾): items / options / severityCutoffs /
// shortDescription / instruction 全走 translations.phq9Item(N) / .phq9Option(score) /
// .phq9SeverityLabel(rank) / .phq9SeveritySummary(rank) / .phq9ShortDescription() /
// .phq9Instruction()。21 case phq9_detect_crisis_round60_test 走 const
// StaticScaleTranslations 返中文, 不破。

import 'package:chroniccare/domain/entities/scale_translations.dart';
import 'package:chroniccare/domain/logic/assessment_scale.dart';

/// 频率选项（0-3）
///
/// v0.27 R78: 仍保留 const Map 作为 `StaticScaleTranslations.phq9Option` fallback
/// (跟 R65 起步版本同款), 但 `Phq9Scale.options` getter 改走
/// `translations.phq9Option(score)`。
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

  // R97-P1-12 (2026-08-07): static factory → factory constructor
  // (Effective Dart: prefer_constructors_over_static_methods)
  // 调用方 Phq9Result.fromTotal(x) 语法不变, 但更符合 Dart 惯例
  factory Phq9Result.fromTotal(int total) {
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
  // v0.27 R78: 走 translations.phq9ShortDescription (中文 fallback 由
  // StaticScaleTranslations 兜底, 跟原 hardcode '过去两周的抑郁倾向筛查' 等价)
  String get shortDescription => translations.phq9ShortDescription();

  @override
  // v0.27 R78: 走 translations.phq9Instruction
  String get instruction => translations.phq9Instruction();

  @override
  // v0.27 R78: items 走 translations.phq9Item(0..8),
  // 9 道题全部走 ARB, en/zh_Hant 用户看英文/繁体题 (而非中文)
  List<AssessmentItem> get items => List<AssessmentItem>.generate(
        9,
        (i) => AssessmentItem(i, translations.phq9Item(i)),
      );

  @override
  // v0.27 R78: 4 档频率选项走 translations.phq9Option(score)
  Map<int, String> get options => {
        0: translations.phq9Option(0),
        1: translations.phq9Option(1),
        2: translations.phq9Option(2),
        3: translations.phq9Option(3),
      };

  @override
  int get totalRange => 27;

  @override
  // v0.27 R78: 5 档严重度 (label + summary) 走 translations,
  // 跟原 hardcode 1:1 一致, 但支持 en/zh_Hant
  List<SeverityCutoff> get severityCutoffs => List<SeverityCutoff>.generate(
        5,
        (rank) => SeverityCutoff(
          threshold: _phq9CutoffThresholds[rank],
          rank: rank,
          label: translations.phq9SeverityLabel(rank),
          summary: translations.phq9SeveritySummary(rank),
        ),
      );

  /// v0.27 R78: 5 档严重度 threshold (跟原 hardcode 一致)
  static const _phq9CutoffThresholds = [4, 9, 14, 19, 27];

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
      // v0.27 R77 (spzh P1-A 收尾): hotlines label 走 translations.crisisHotlineLabel
      // (region, index), 6 region × 2 hotline 全 i18n 化 (cn/us/tw 各 2 个)。
      // 老 const phq9Scale 走 StaticScaleTranslations 中文 fallback, 21 case test 不破。
      final baseList =
          hotlineByRegion[region] ?? hotlineByRegion[HotlineRegion.cn]!;
      // v0.27 R77: hotlines label 走 translations (en/zh_Hant 不再是中文)
      return CrisisSignal(
        // v0.27 R71 (spzh P1-A 续): 走 translations.crisisTitle() + crisisMessage()
        // 之前 hardcode 中文, en / zh_Hant 用户看中文 (医疗法律责任)
        title: translations.crisisTitle(),
        message: translations.crisisMessage(),
        hotlines: [
          for (var i = 0; i < baseList.length; i++)
            (
              label: translations.crisisHotlineLabel(region, index: i),
              number: baseList[i].number,
            ),
        ],
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
// rule3-whitelist: 36-39
//   R113 BUG A: 精确行号豁免 (修前文件头 i18n 标记整文件豁免)
//   新增 CJK 字面量需自带 i18n 标记或扩本清单 — 详见 scripts/check_strings_hardcoded.py
