// ISI 失眠严重指数 (Insomnia Severity Index)
//
// 数据来源: Morin et al. (1993) - Insomnia Severity Index
// 7 题, 评估过去 2 周睡眠问题, 0-4 共 5 档
//
// 题数: 7
// 选项: 0-4 (无 / 轻度 / 中度 / 重度 / 极重度, 共 5 档)
// 总分: 0-28
//
// 严重度切分 (4 档, Morin 1993):
// 0-7   → 无临床失眠
// 8-14  → 阈下失眠 (亚临床)
// 15-21 → 中度失眠 (建议就医)
// 22-28 → 重度失眠 (强烈建议就医)
//
// v0.30 round 90 (Task 1): R60 已有 const 补全, Task 2 注册
// R60 AssessmentScale interface 复用, 题目硬编中文 (Task 6 走 ARB 翻译)
//
// 危机信号: 不触发 (公开量表, 走 PHQ-9 第 9 题)

import 'package:chroniccare/domain/entities/scale_translations.dart';
import 'package:chroniccare/domain/logic/assessment_scale.dart';

/// ISI (失眠严重指数) 实现
class IsiScale implements AssessmentScale {
  @override
  final ScaleTranslations translations;
  const IsiScale({
    this.translations = const StaticScaleTranslations(),
  });

  @override
  String get id => 'isi';

  // v0.32 round 8 (R111 E4/R111-02 fix): 走 translations (跟 phq9 一致),
  // 老 const 单例走 StaticScaleTranslations 中文 fallback 1:1, 0 行为变化;
  // presentation 传 AppLocalizationsScaleTranslations 时 en 用户不再看中文
  @override
  String get displayName => translations.isiName();

  @override
  String get shortDescription => translations.isiShortDescription();

  @override
  String get instruction => translations.isiInstruction();

  @override
  List<AssessmentItem> get items => const [
        AssessmentItem(0, '入睡困难程度'),
        AssessmentItem(1, '维持睡眠困难程度 (夜间醒来)'),
        AssessmentItem(2, '早醒问题程度'),
        AssessmentItem(3, '对当前睡眠模式的满意度'),
        AssessmentItem(4, '睡眠问题对日常功能的影响程度'),
        AssessmentItem(5, '睡眠问题在他人眼中明显的程度'),
        AssessmentItem(6, '对当前睡眠问题的担忧 / 痛苦程度'),
      ];

  @override
  Map<int, String> get options => const {
        0: '无',
        1: '轻度',
        2: '中度',
        3: '重度',
        4: '极重度',
      };

  @override
  int get totalRange => 28;

  @override
  List<SeverityCutoff> get severityCutoffs => const [
        SeverityCutoff(
          threshold: 7,
          rank: 0,
          label: '无失眠',  // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
          summary: '无临床失眠',
        ),
        SeverityCutoff(
          threshold: 14,
          rank: 1,
          label: '阈下失眠',  // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
          summary: '亚临床失眠, 建议关注',
        ),
        SeverityCutoff(
          threshold: 21,
          rank: 2,
          label: '中度失眠',  // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
          summary: '中度失眠, 建议就医',
        ),
        SeverityCutoff(
          threshold: 28,
          rank: 3,
          label: '重度失眠',  // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
          summary: '重度失眠, 强烈建议就医',
        ),
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

/// ISI 单例 (Task 2 注册表用)
const isiScale = IsiScale();
