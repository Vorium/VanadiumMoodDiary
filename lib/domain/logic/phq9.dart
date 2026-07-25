/// PHQ-9 患者健康问卷抑郁量表
///
/// 数据来源：美国精神医学学会（APA）DSM-IV 推荐筛查工具
/// 9 道题，每题 0-3 分，总分 0-27
///
/// 严重度切分：
/// 0-4   → 几乎没有
/// 5-9   → 轻度
/// 10-14 → 中度（建议就医）
/// 15-19 → 中重度（建议就医）
/// 20-27 → 重度（强烈建议就医）
///
/// 危机信号：第 9 题（自杀念头）≥ 1 → 弹出危机资源
library;

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
    if (total <= 4) {
      return Phq9Result(total, Phq9Severity.minimal, '几乎没有抑郁倾向');
    }
    if (total <= 9) {
      return Phq9Result(total, Phq9Severity.mild, '轻度抑郁倾向');
    }
    if (total <= 14) {
      return Phq9Result(total, Phq9Severity.moderate, '中度抑郁倾向');
    }
    if (total <= 19) {
      return Phq9Result(total, Phq9Severity.moderatelySevere, '中重度抑郁倾向');
    }
    return Phq9Result(total, Phq9Severity.severe, '重度抑郁倾向');
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
class Phq9Scale implements AssessmentScale {
  const Phq9Scale();

  @override
  String get id => 'phq9';

  @override
  String get displayName => 'PHQ-9 抑郁筛查';

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
  CrisisSignal? detectCrisis(List<int> scores, AssessmentResult result) {
    // 第 9 题（index 8）≥ 1 → 自杀念头阳性
    if (scores.length > 8 && scores[8] >= 1) {
      return const CrisisSignal(
        title: '我们关心你',
        message: '你提到了想伤害自己的念头。\n请记住：寻求帮助是勇敢的，不是软弱。',
        hotlines: [
          (label: '全国24小时心理援助热线', number: '400-161-9995'),
          (label: '北京心理危机研究与干预中心', number: '010-82951332'),
        ],
      );
    }
    return null;
  }
}

/// PHQ-9 单例（注册表用）
const phq9Scale = Phq9Scale();
