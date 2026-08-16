// 规则 3 标记: 量表中文 fallback — v1.0+ i18n (R51b backlog, 显示层走 l10n)
// WHODAS 2.0 (12 题简化版) 量表
//
// 数据来源: WHO 官方 36 题简化版, 覆盖 6 domain
// (cognition / mobility / self-care / getting-along / life-activities / participation)
//
// 题数: 12 (每 domain 2 题)
// 选项: 0-4 (没有 / 轻微 / 中度 / 重度 / 极重度, 共 5 档)
// 总分: 0-48
//
// 严重度切分 (WHO 标准, 5 档):
// 0-4   → 无残疾
// 5-9   → 轻度残疾
// 10-15 → 中度残疾 (建议就医)
// 16-24 → 重度残疾 (建议就医)
// 25-48 → 极重度残疾 (强烈建议就医)
//
// v0.30 round 90 (Task 1): 6 公开新增量表之一
// R60 AssessmentScale interface 复用, 题目硬编中文 (Task 6 走 ARB 翻译)
//
// 危机信号: 不触发 (公开量表, 走 PHQ-9 第 9 题)

import 'package:chroniccare/domain/entities/scale_translations.dart';
import 'package:chroniccare/domain/logic/assessment_scale.dart';

/// WHODAS 2.0 (12 题简化版) 量表实现
class WhodasScale implements AssessmentScale {
  @override
  final ScaleTranslations translations;
  const WhodasScale({
    this.translations = const StaticScaleTranslations(),
  });

  @override
  String get id => 'whodas';

  // v0.32 round 8 (R111 E4/R111-02 fix): 走 translations (跟 phq9 一致)
  @override
  String get displayName => translations.whodasName();

  @override
  String get shortDescription => translations.whodasShortDescription();

  @override
  String get instruction => translations.whodasInstruction();

  @override
  List<AssessmentItem> get items => const [
        AssessmentItem(0, '理解并与他人交流'),
        AssessmentItem(1, '四处走动'),
        AssessmentItem(2, '自我照顾 (如洗澡、穿衣)'),
        AssessmentItem(3, '与他人相处'),
        AssessmentItem(4, '承担家庭 / 工作责任'),
        AssessmentItem(5, '参与社区活动'),
        AssessmentItem(6, '集中注意力做事'),
        AssessmentItem(7, '短距离步行'),
        AssessmentItem(8, '清洗全身'),
        AssessmentItem(9, '与陌生人相处'),
        AssessmentItem(10, '维持朋友关系'),
        AssessmentItem(11, '完成日常工作任务'),
      ];

  @override
  Map<int, String> get options => const {
        0: '没有',
        1: '轻微',
        2: '中度',
        3: '重度',
        4: '极重度',
      };

  @override
  int get totalRange => 48;

  @override
  List<SeverityCutoff> get severityCutoffs => const [
        SeverityCutoff(
          threshold: 4,
          rank: 0,
          label: '无残疾', // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
          summary: '无残疾',
        ),
        SeverityCutoff(
          threshold: 9,
          rank: 1,
          label: '轻度残疾', // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
          summary: '轻度残疾',
        ),
        SeverityCutoff(
          threshold: 15,
          rank: 2,
          label: '中度残疾', // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
          summary: '中度残疾, 建议就医评估',
        ),
        SeverityCutoff(
          threshold: 24,
          rank: 3,
          label: '重度残疾', // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
          summary: '重度残疾, 建议就医',
        ),
        SeverityCutoff(
          threshold: 48,
          rank: 4,
          label: '极重度残疾', // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
          summary: '极重度残疾, 强烈建议就医',
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
      urgentDoctorVisit: cutoff.rank >= 4,
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

/// WHODAS 2.0 单例 (Task 2 注册表用)
const whodasScale = WhodasScale();
// rule3-whitelist: 49-60, 65-69
//   R113 BUG A: 精确行号豁免 (修前文件头 i18n 标记整文件豁免)
//   新增 CJK 字面量需自带 i18n 标记或扩本清单 — 详见 scripts/check_strings_hardcoded.py
