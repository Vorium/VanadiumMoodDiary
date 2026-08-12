// PSS 压力量表 (Perceived Stress Scale)
//
// 数据来源: Cohen, S. (1983) - Perceived Stress Scale, 10 题版本 (PSS-10)
// 评估过去 1 个月生活事件感知压力
//
// 题数: 10
// 选项: 0-4 (从未 / 几乎不 / 有时 / 经常 / 总是, 共 5 档)
// 总分: 0-40 (含 4 题反向计分)
//
// 反向计分 (Cohen 1983): 1-indexed 4, 5, 7, 8 题 = 0-indexed 3, 4, 6, 7
// 反向公式: adjusted = 4 - raw
//
// 严重度切分 (Cohen 1983, 3 档):
// 0-13  → 低压力
// 14-26 → 中度压力
// 27-40 → 高压力 (建议就医)
//
// v0.30 round 90 (Task 1): R60 已有 const 补全 (4 题反向计分), Task 2 注册
// R60 AssessmentScale interface 复用, 题目硬编中文 (Task 6 走 ARB 翻译)
//
// 危机信号: 不触发 (公开量表, 走 PHQ-9 第 9 题)

import 'package:chroniccare/domain/entities/scale_translations.dart';
import 'package:chroniccare/domain/logic/assessment_scale.dart';

/// PSS (压力量表) 实现
class PssScale implements AssessmentScale {
  @override
  final ScaleTranslations translations;
  const PssScale({
    this.translations = const StaticScaleTranslations(),
  });

  @override
  String get id => 'pss';

  @override
  String get displayName => 'PSS 压力量表';

  @override
  String get shortDescription => 'Cohen 1983 压力量表 (10 题, 含 4 题反向)';

  @override
  String get instruction => '过去 1 个月里, 您有多经常有下列感受?';

  @override
  List<AssessmentItem> get items => const [
        // 1-3: 负向 (kept as-is)
        AssessmentItem(0, '因为意外发生的事情而感到心烦意乱'),
        AssessmentItem(1, '感到无法控制生活中重要的事情'),
        AssessmentItem(2, '感到紧张和有压力'),
        // 4-5: 正向 (reverse)
        AssessmentItem(3, '自信能处理好个人问题 (反向)'),
        AssessmentItem(4, '感到事情在按您期望的方向发展 (反向)'),
        // 6: 负向
        AssessmentItem(5, '发现自己无法应对必须完成的事情'),
        // 7-8: 正向 (reverse)
        AssessmentItem(6, '能控制生活中的烦人事 (反向)'),
        AssessmentItem(7, '感到自己能掌控一切 (反向)'),
        // 9-10: 负向
        AssessmentItem(8, '因为无法控制的事情而恼火'),
        AssessmentItem(9, '感到困难堆积得无法克服'),
      ];

  @override
  Map<int, String> get options => const {
        0: '从未',
        1: '几乎不',
        2: '有时',
        3: '经常',
        4: '总是',
      };

  @override
  int get totalRange => 40;

  /// v0.30 round 90 (Task 1): PSS 4 题反向计分 (0-indexed 3, 4, 6, 7)
  static const _reversedIndices = {3, 4, 6, 7};

  @override
  List<SeverityCutoff> get severityCutoffs => const [
        SeverityCutoff(
          threshold: 13,
          rank: 0,
          label: '低压力',  // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
          summary: '低压力',
        ),
        SeverityCutoff(
          threshold: 26,
          rank: 1,
          label: '中度压力',  // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
          summary: '中度压力',
        ),
        SeverityCutoff(
          threshold: 40,
          rank: 2,
          label: '高压力',  // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
          summary: '高压力, 建议关注和寻求支持',
        ),
      ];

  @override
  AssessmentResult computeResult(List<int> scores) {
    // v0.30 round 90 (Task 1): 4 题反向计分 (Cohen 1983)
    // 正向题 1-indexed 4, 5, 7, 8 = 0-indexed 3, 4, 6, 7
    // 反向公式: adjusted = 4 - raw
    var total = 0;
    for (var i = 0; i < scores.length; i++) {
      final raw = scores[i];
      final adjusted = _reversedIndices.contains(i) ? 4 - raw : raw;
      total += adjusted;
    }
    final cutoff = severityCutoffs.firstWhere(
      (c) => total <= c.threshold,
      orElse: () => severityCutoffs.last,
    );
    return AssessmentResult(
      total: total,
      summary: cutoff.summary,
      recommendDoctorVisit: cutoff.rank >= 2,
      urgentDoctorVisit: false, // PSS 无"极重"档, 不触发 urgent
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

/// PSS 单例 (Task 2 注册表用)
const pssScale = PssScale();
