// 心理评估量表抽象接口
//
// 让 PHQ-9 / GAD-7 / 未来扩展的量表共用同一套渲染 + 提交逻辑。
//
// 设计目标：
// 1. 新增量表只写一份数据 + 一个 AssessmentScale 实现
// 2. 评估页（AssessmentRunner）只认 AssessmentScale，不关心具体量表
// 3. 评估结果写库时复用 check_ins 表（type=scaleId）
//
// v0.28 round 65 (spzh P1-A 起步): `AssessmentScale` abstract 加
// `translations: ScaleTranslations` 字段 — 起步只覆盖 phq9 / gad7
// 名称 + 6 region 危机电话 label (16 题全文留 v1.0)。老 caller 用
// `const StaticScaleTranslations()` 走中文 fallback, const 兼容
// (e.g. `const phq9Scale = Phq9Scale()` 仍可编译)。

import 'package:chroniccare/domain/entities/scale_translations.dart';

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

  /// i18n 翻译注入 (v0.28 round 65 spzh P1-A 起步)
  ///
  /// 老 caller 不传 (e.g. `const phq9Scale = Phq9Scale()`) 走 const
  /// `StaticScaleTranslations()` 中文 fallback — 0 测试 break。
  /// 新 caller 传 `AppLocalizationsScaleTranslations(l10n)` 走 ARB。
  ScaleTranslations get translations;

  /// 显示名（"PHQ-9 抑郁筛查" / "PHQ-9 Depression Screening"）
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
  ///
  /// v0.25 round 51 (spzh P0 #3): [region] 决定 hotlines 路由。
  /// 之前 PHQ-9 hardcode 中国大陆 2 个电话,海外用户做评估时看到中国电话
  /// 打不通 = 医疗法律责任。海外用户应看到 region=us/hk/tw/sg/uk 的
  /// 当地危机电话(Lifeline 988 / 撒玛利亚 2389 2222 / 生命线 1995 等)。
  /// [region] 默认 cn 保持旧行为兼容(已在 v0.24 之前 release 的用户)。
  ///
  /// v0.28 round 65 (spzh P1-A 起步): `hotlines` label 走 [translations]
  /// 翻译 (en/zh_Hant 走 ARB, zh fallback 走 `hotlineByRegion` const Map)。
  /// 老 const phq9Scale (无显式 translations) → 中文 fallback, 21 case test 不破。
  CrisisSignal? detectCrisis(
    List<int> scores,
    AssessmentResult result, {
    HotlineRegion region = HotlineRegion.cn,
  }) =>
      null;
}

/// v0.25 round 51 (spzh P0 #3): 危机电话 region 路由
///
/// 精神心理评估的危机资源必须按用户所在地/语言区显示对应电话。
/// 之前 PHQ-9 hardcode 中国 2 个电话,海外华人/外籍用户看到中国电话
/// 打不通 = 用户自杀时救命电话失效 = 法律责任。
///
/// region 跟 PhoneRegion (cn/hk/mo/tw/intl) 不同 — 这里更细 (5 国 + 1 国际)
/// 覆盖英语 / 粤语 / 闽南语 / 韩语等。
enum HotlineRegion {
  /// 中国大陆 (默认)
  cn,

  /// 美国 / 加拿大 (988 Lifeline 英文 + 西班牙文)
  us,

  /// 中国香港 (撒玛利亚防止自杀会)
  hk,

  /// 中国台湾 (生命线 1995 + 安心专线 1925)
  tw,

  /// 新加坡 (Samaritans of Singapore)
  sg,

  /// 英国 / 爱尔兰 (Samaritans 116 123)
  uk,
}

/// v0.25 round 51: 6 个 region 的危机电话数据
///
/// 命名按 region 升序(国际通用排序)。label 中文为 fallback (与 strings.dart
/// 一致的 domain 0 flutter 逃生口模式) — 未来 R51b 在 presentation 层
/// wrapper 走 l10n。
///
/// 电话来源:
/// - cn: 全国24小时心理援助热线 + 北京心理危机研究与干预中心
/// - us: 988 Suicide & Crisis Lifeline + Crisis Text Line (text HOME to 741741)
/// - hk: 撒玛利亚防止自杀会 (24h 多语言)
/// - tw: 生命线 + 安心专线 (1925 心理咨商)
/// - sg: Samaritans of Singapore (24h)
/// - uk: Samaritans UK & ROI (24h 免费)
const Map<HotlineRegion, List<({String label, String number})>>
    hotlineByRegion = {
  HotlineRegion.cn: [
    (
      label: '全国24小时心理援助热线', // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
      number: '400-161-9995'
    ),
    (
      label: '北京心理危机研究与干预中心', // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
      number: '010-82951332'
    ),
  ],
  HotlineRegion.us: [
    (label: '988 Suicide & Crisis Lifeline (US)', number: '988'),
    (label: 'Crisis Text Line (text HOME)', number: '741741'),
  ],
  HotlineRegion.hk: [
    (
      label:
          '撒玛利亚防止自杀会 (24h 多语言)', // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
      number: '2389 2222'
    ),
  ],
  HotlineRegion.tw: [
    (
      label: '生命线 (24h)', // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
      number: '1995'
    ),
    (
      label: '安心专线 (心理咨商)', // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
      number: '1925'
    ),
  ],
  HotlineRegion.sg: [
    (label: 'Samaritans of Singapore (24h)', number: '1800-221-4444'),
  ],
  HotlineRegion.uk: [
    (
      label:
          'Samaritans UK & ROI (24h 免费)', // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
      number: '116 123'
    ),
  ],
};
