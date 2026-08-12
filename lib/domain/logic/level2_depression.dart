// DSM-5 Level 2 抑郁严重程度量表 (成人)
//
// 数据来源: APA 公开 PROMIS Emotional Distress - Depression 简化版
// (代表 5-9 题原 PROMIS bank, 8 题覆盖核心症状)
//
// 题数: 8
// 选项: 0-3 (完全没有 / 几天 / 一半以上天数 / 几乎每天, 共 4 档)
// 总分: 0-24
//
// 严重度切分 (4 档):
// 0-5  → 无抑郁
// 6-10 → 轻度
// 11-15 → 中度 (建议就医)
// 16-24 → 重度 (强烈建议就医)
//
// v0.30 round 90 (Task 1): 6 公开新增量表之一
// R60 AssessmentScale interface 复用, 题目硬编中文 (Task 6 走 ARB 翻译)
//
// 危机信号: 不触发 (公开量表, 走 PHQ-9 第 9 题)

import 'package:chroniccare/domain/entities/scale_translations.dart';
import 'package:chroniccare/domain/logic/assessment_scale.dart';

/// DSM-5 Level 2 抑郁严重程度量表 (成人) 实现
class Level2DepressionScale implements AssessmentScale {
  @override
  final ScaleTranslations translations;
  const Level2DepressionScale({
    this.translations = const StaticScaleTranslations(),
  });

  @override
  String get id => 'level2_depression';

  @override
  String get displayName => 'DSM-5 Level 2 抑郁严重度';

  @override
  String get shortDescription => '成人抑郁严重度 8 题 (DSM-5 PROMIS 简化版)';

  @override
  String get instruction => '过去 7 天内, 您有多经常被以下情绪困扰?';

  @override
  List<AssessmentItem> get items => const [
        AssessmentItem(0, '感到心情低落'),
        AssessmentItem(1, '感到没有希望'),
        AssessmentItem(2, '感到自己很失败'),
        AssessmentItem(3, '对任何事都提不起兴趣'),
        AssessmentItem(4, '感到自己毫无价值'),
        AssessmentItem(5, '感到内疚或羞耻'),
        AssessmentItem(6, '感到无助'),
        AssessmentItem(7, '觉得生活没有意义'),
      ];

  @override
  Map<int, String> get options => const {
        0: '完全没有',
        1: '几天',
        2: '一半以上的天数',
        3: '几乎每天',
      };

  @override
  int get totalRange => 24;

  @override
  List<SeverityCutoff> get severityCutoffs => const [
        SeverityCutoff(
          threshold: 5,
          rank: 0,
          label: '无抑郁',  // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
          summary: '无抑郁倾向',
        ),
        SeverityCutoff(
          threshold: 10,
          rank: 1,
          label: '轻度抑郁',  // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
          summary: '轻度抑郁倾向',
        ),
        SeverityCutoff(
          threshold: 15,
          rank: 2,
          label: '中度抑郁',  // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
          summary: '中度抑郁, 建议就医',
        ),
        SeverityCutoff(
          threshold: 24,
          rank: 3,
          label: '重度抑郁',  // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
          summary: '重度抑郁, 强烈建议就医',
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

/// Level 2 抑郁单例 (Task 2 注册表用)
const level2DepressionScale = Level2DepressionScale();
