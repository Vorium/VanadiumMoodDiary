// 规则 3 标记: 量表中文 fallback — v1.0+ i18n (R51b backlog, 显示层走 l10n)
// DSM-5 Level 2 躁狂严重程度量表 (成人)
//
// 数据来源: APA 公开 PROMIS Mania 简化版
// (代表 5-9 题原 PROMIS bank, 5 题覆盖核心症状)
//
// 题数: 5
// 选项: 0-3 (完全没有 / 几天 / 一半以上天数 / 几乎每天, 共 4 档)
// 总分: 0-15
//
// 严重度切分 (4 档):
// 0-3  → 无躁狂
// 4-7  → 轻度
// 8-10 → 中度 (建议就医)
// 11-15 → 重度 (强烈建议就医)
//
// v0.30 round 90 (Task 1): 6 公开新增量表之一
// R60 AssessmentScale interface 复用, 题目硬编中文 (Task 6 走 ARB 翻译)
//
// 危机信号: 不触发 (公开量表, 走 PHQ-9 第 9 题)

import 'package:chroniccare/domain/entities/scale_translations.dart';
import 'package:chroniccare/domain/logic/assessment_scale.dart';

/// DSM-5 Level 2 躁狂严重程度量表 (成人) 实现
class Level2ManiaScale implements AssessmentScale {
  @override
  final ScaleTranslations translations;
  const Level2ManiaScale({
    this.translations = const StaticScaleTranslations(),
  });

  @override
  String get id => 'level2_mania';

  // v0.32 round 8 (R111 E4/R111-02 fix): 走 translations (跟 phq9 一致)
  @override
  String get displayName => translations.level2ManiaName();

  @override
  String get shortDescription => translations.level2ManiaShortDescription();

  @override
  String get instruction => translations.level2ManiaInstruction();

  @override
  List<AssessmentItem> get items => const [
        AssessmentItem(0, '感到精力异常旺盛'),
        AssessmentItem(1, '思维奔逸'),
        AssessmentItem(2, '睡眠需求减少但仍感精力充沛'),
        AssessmentItem(3, '说话比平时多'),
        AssessmentItem(4, '冲动做决定 (花钱、社交、性行为等)'),
      ];

  @override
  Map<int, String> get options => const {
        0: '完全没有',
        1: '几天',
        2: '一半以上的天数',
        3: '几乎每天',
      };

  @override
  int get totalRange => 15;

  @override
  List<SeverityCutoff> get severityCutoffs => const [
        SeverityCutoff(
          threshold: 3,
          rank: 0,
          label: '无躁狂', // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
          summary: '无躁狂倾向',
        ),
        SeverityCutoff(
          threshold: 7,
          rank: 1,
          label: '轻度躁狂', // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
          summary: '轻度躁狂倾向',
        ),
        SeverityCutoff(
          threshold: 10,
          rank: 2,
          label: '中度躁狂', // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
          summary: '中度躁狂, 建议就医',
        ),
        SeverityCutoff(
          threshold: 15,
          rank: 3,
          label: '重度躁狂', // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
          summary: '重度躁狂, 强烈建议就医',
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

/// Level 2 躁狂单例 (Task 2 注册表用)
const level2ManiaScale = Level2ManiaScale();
// rule3-whitelist: 48-52, 57-60
//   R113 BUG A: 精确行号豁免 (修前文件头 i18n 标记整文件豁免)
//   新增 CJK 字面量需自带 i18n 标记或扩本清单 — 详见 scripts/check_strings_hardcoded.py
