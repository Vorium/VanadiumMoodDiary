// 规则 3 标记: 量表中文 fallback — v1.0+ i18n (R51b backlog, 显示层走 l10n)
// DSM-5 Level 2 焦虑严重程度量表 (成人)
//
// 数据来源: APA 公开 PROMIS Anxiety 简化版
// (代表 5-9 题原 PROMIS bank, 7 题覆盖核心症状)
//
// 题数: 7
// 选项: 0-3 (完全没有 / 几天 / 一半以上天数 / 几乎每天, 共 4 档)
// 总分: 0-21
//
// 严重度切分 (4 档):
// 0-4  → 无焦虑
// 5-9  → 轻度
// 10-14 → 中度 (建议就医)
// 15-21 → 重度 (强烈建议就医)
//
// v0.30 round 90 (Task 1): 6 公开新增量表之一
// R60 AssessmentScale interface 复用, 题目硬编中文 (Task 6 走 ARB 翻译)
//
// 危机信号: 不触发 (公开量表, 走 PHQ-9 第 9 题)

import 'package:chroniccare/domain/entities/scale_translations.dart';
import 'package:chroniccare/domain/logic/assessment_scale.dart';

/// DSM-5 Level 2 焦虑严重程度量表 (成人) 实现
class Level2AnxietyScale implements AssessmentScale {
  @override
  final ScaleTranslations translations;
  const Level2AnxietyScale({
    this.translations = const StaticScaleTranslations(),
  });

  @override
  String get id => 'level2_anxiety';

  // v0.32 round 8 (R111 E4/R111-02 fix): 走 translations (跟 phq9 一致)
  @override
  String get displayName => translations.level2AnxietyName();

  @override
  String get shortDescription => translations.level2AnxietyShortDescription();

  @override
  String get instruction => translations.level2AnxietyInstruction();

  @override
  List<AssessmentItem> get items => const [
        AssessmentItem(0, '感到紧张'),
        AssessmentItem(1, '感到担心'),
        AssessmentItem(2, '感到烦躁不安'),
        AssessmentItem(3, '感到害怕'),
        AssessmentItem(4, '感到惊慌'),
        AssessmentItem(5, '感到坐立不安'),
        AssessmentItem(6, '感到难以放松'),
      ];

  @override
  Map<int, String> get options => const {
        0: '完全没有',
        1: '几天',
        2: '一半以上的天数',
        3: '几乎每天',
      };

  @override
  int get totalRange => 21;

  @override
  List<SeverityCutoff> get severityCutoffs => const [
        SeverityCutoff(
          threshold: 4,
          rank: 0,
          label: '无焦虑',  // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
          summary: '无焦虑倾向',
        ),
        SeverityCutoff(
          threshold: 9,
          rank: 1,
          label: '轻度焦虑',  // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
          summary: '轻度焦虑倾向',
        ),
        SeverityCutoff(
          threshold: 14,
          rank: 2,
          label: '中度焦虑',  // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
          summary: '中度焦虑, 建议就医',
        ),
        SeverityCutoff(
          threshold: 21,
          rank: 3,
          label: '重度焦虑',  // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
          summary: '重度焦虑, 强烈建议就医',
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

/// Level 2 焦虑单例 (Task 2 注册表用)
const level2AnxietyScale = Level2AnxietyScale();
