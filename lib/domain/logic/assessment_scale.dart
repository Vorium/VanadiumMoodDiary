/// 心理评估量表抽象接口
///
/// 让 PHQ-9 / GAD-7 / 未来扩展的量表共用同一套渲染 + 提交逻辑。
///
/// 设计目标：
/// 1. 新增量表只写一份数据 + 一个 AssessmentScale 实现
/// 2. 评估页（AssessmentRunner）只认 AssessmentScale，不关心具体量表
/// 3. 评估结果写库时复用 check_ins 表（type=scaleId）
library;

/// 量表单道题
class AssessmentItem {
  final int index; // 0-based
  final String text;

  const AssessmentItem(this.index, this.text);
}

/// 量表结果（提交后展示给用户）
class AssessmentResult {
  final int total;
  final String summary;
  final bool recommendDoctorVisit;
  final bool urgentDoctorVisit;

  const AssessmentResult({
    required this.total,
    required this.summary,
    required this.recommendDoctorVisit,
    required this.urgentDoctorVisit,
  });
}

/// 危机信号（自杀念头 / 极端情况）
///
/// 量表可选择性地在结果之外额外触发一次"关心你"对话框
class CrisisSignal {
  final String title;
  final String message;
  final List<({String label, String number})> hotlines;

  const CrisisSignal({
    required this.title,
    required this.message,
    required this.hotlines,
  });
}

/// 严重度切分点
///
/// [threshold] 该档的上界（含），如 PHQ-9 的 4 表示 total <= 4 为该档。
/// [rank] 严重度等级（越大越严重）。
/// [label] 短标签（图表/对比用），如 "轻度抑郁"。
/// [summary] 完整描述（结果页用），如 "轻度抑郁倾向"。
class SeverityCutoff {
  final int threshold;
  final int rank;
  final String label;
  final String summary;

  const SeverityCutoff({
    required this.threshold,
    required this.rank,
    required this.label,
    required this.summary,
  });
}

/// 量表抽象
abstract class AssessmentScale {
  /// 唯一 id（写入 check_ins.type）
  String get id;

  /// 显示名（"PHQ-9 抑郁筛查"）
  String get displayName;

  /// 短描述（设置页副标题用）
  String get shortDescription;

  /// 顶部引导语（"过去两周内..."）
  String get instruction;

  /// 题项
  List<AssessmentItem> get items;

  /// 频率选项：score → 中文标签
  Map<int, String> get options;

  /// 总分上限（显示用，"总分（0-27）"）
  int get totalRange;

  /// 严重度切分点（单一数据源）
  ///
  /// 按 threshold 升序排列。最后一个 entry 的 threshold 应为理论最大值
  /// （如 PHQ-9 的 27），作为"以上所有"的兜底。
  ///
  /// 用于：
  /// - `computeResult()` 映射 total → summary + flags
  /// - `AssessmentComparisonCalculator.severityRankFor()` 映射 total → rank
  List<SeverityCutoff> get severityCutoffs;

  /// 根据 raw scores 计算结果
  AssessmentResult computeResult(List<int> scores);

  /// 危机检测：返回 null = 无危机；非 null = 弹出危机对话框
  ///
  /// 注意：PHQ-9 的第 9 题是"自杀念头"，GAD-7 不涉及——所以默认 null
  CrisisSignal? detectCrisis(List<int> scores, AssessmentResult result) => null;
}
