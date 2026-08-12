// Altman 自评躁狂量表 (ASRM)
//
// 数据来源: Altman et al. (1997) - The Altman Self-Rating Mania Scale
// 5 题, 每题评估过去 1 周内症状, 0-4 共 5 档
//
// 题数: 5
// 选项: 0-4 (完全没有 / 轻微 / 中度 / 明显 / 严重, 共 5 档)
// 总分: 0-20
//
// 严重度切分 (5 档, Altman 1997):
// 0     → 无症状
// 1-5   → 轻度
// 6-10  → 中度 (建议就医)
// 11-15 → 重度
// 16-20 → 极重度 (强烈建议就医)
//
// v0.30 round 90 (Task 1): 6 公开新增量表之一
// R60 AssessmentScale interface 复用, 题目硬编中文 (Task 6 走 ARB 翻译)
//
// 危机信号: 不触发 (公开量表, 走 PHQ-9 第 9 题)

import 'package:chroniccare/domain/entities/scale_translations.dart';
import 'package:chroniccare/domain/logic/assessment_scale.dart';

/// ASRM (Altman 自评躁狂量表) 实现
class AsrmScale implements AssessmentScale {
  @override
  final ScaleTranslations translations;
  const AsrmScale({
    this.translations = const StaticScaleTranslations(),
  });

  @override
  String get id => 'asrm';

  @override
  String get displayName => 'ASRM 自评躁狂量表';

  @override
  String get shortDescription => 'Altman 1997 自评躁狂量表 (5 题)';

  @override
  String get instruction => '过去 1 周内, 您有 (或感觉到) 以下情况的程度?';

  @override
  List<AssessmentItem> get items => const [
        AssessmentItem(0, '心情比平时更好, 或感到兴奋 (elevated mood)'),
        AssessmentItem(1, '自信增加, 或感到自己很重要'),
        AssessmentItem(2, '睡眠需求减少, 仍感精力充沛'),
        AssessmentItem(3, '话比平时多, 或说话速度加快'),
        AssessmentItem(4, '思维奔逸, 想法快速跳跃'),
      ];

  @override
  Map<int, String> get options => const {
        0: '完全没有',
        1: '轻微',
        2: '中度',
        3: '明显',
        4: '严重',
      };

  @override
  int get totalRange => 20;

  @override
  List<SeverityCutoff> get severityCutoffs => const [
        SeverityCutoff(
          threshold: 0,
          rank: 0,
          label: '无症状',  // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
          summary: '无症状',
        ),
        SeverityCutoff(
          threshold: 5,
          rank: 1,
          label: '轻度',  // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
          summary: '轻度躁狂倾向',
        ),
        SeverityCutoff(
          threshold: 10,
          rank: 2,
          label: '中度',  // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
          summary: '中度躁狂, 建议就医',
        ),
        SeverityCutoff(
          threshold: 15,
          rank: 3,
          label: '重度',  // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
          summary: '重度躁狂, 建议就医',
        ),
        SeverityCutoff(
          threshold: 20,
          rank: 4,
          label: '极重度',  // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
          summary: '极重度躁狂, 强烈建议就医',
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

/// ASRM 单例 (Task 2 注册表用)
const asrmScale = AsrmScale();
