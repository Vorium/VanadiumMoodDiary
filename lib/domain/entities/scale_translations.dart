// scale_translations.dart — 量表翻译抽象 (v0.28 round 65 spzh P1-A 起步)
//
// 背景 (spzh P1-A):
//   PHQ-9 / GAD-7 量表 16 题 + 9 档严重度 + 6 region 危机电话 label 全部 const
//   硬编中文, en / zh_Hant 用户看中文 label, 海外华人危机电话 region 路由被
//   中文 label 抵消 = 医疗法律责任。
//
// 修法 (起步, **不**完全 16 题 9 档 i18n 化):
//   1) 抽 `ScaleTranslations` abstract class
//   2) 改 `AssessmentScale` 抽象类加 `translations: ScaleTranslations` 字段
//   3) `Phq9Scale` / `Gad7Scale` 注入 ScaleTranslations (老 caller 用
//      `const StaticScaleTranslations()` 走中文 fallback)
//   4) `AppLocalizationsScaleTranslations` 走 `AppLocalizations` 包装
//   5) 6 个 i18n key (复用现有 `assessmentScalePhq9` / `assessmentScaleGad7`,
//      新加 `scaleHotlineCn` / `scaleHotlineUs` / `scaleHotlineHk` / `scaleHotlineIntl`)
//
// 16 题全文 i18n 化留 v1.0 (spzh report P1-A 已记 TODO)。
//
// 现有 21 case crisis test (`phq9_detect_crisis_round60_test.dart` + `phq9_round12_test.dart` +
// `gad7_round16_test.dart`) **不破** — 老 caller 走 `const StaticScaleTranslations()` 返中文
// fallback, hotlines 直接用 `hotlineByRegion[region]` const Map (label 是中文)。
// v0.28 起步版本额外: crisis hotlines 在 detectCrisis 时用 `translations.crisisHotlineLabel(region)`
// 翻译 label, region 不在 i18n key 范围 (tw/sg/uk) 走 intl fallback。
//
// v0.30 round 90 (Task 2): 扩 10 量表 × ~23 method = 186 新方法
// (8 新量表 ISI/PSS/WHODAS/Level2 Depression/Anxiety/Mania/Psychosis/ASRM)。
// R78 模式: 每量表 6 类 (name / shortDescription / instruction / items / options /
// severityLabel+Summary) × 题目/选项/严重度 实际数量。
// 老 PHQ-9 (21) + GAD-7 (17) 方法不动, 老 caller 继续用 `const StaticScaleTranslations()`。
// AppLocalizationsScaleTranslations Task 2 stub 返 `''` 占位, Task 6 补 ARB key 后改
// `l10n.xxxItem(index)` 等。
//
// v0.30 round 95 (sub-spec 4 task 2): 拆 953 → 2 文件
// - scale_translations.dart (本文件, 200 行): abstract class ScaleTranslations interface
// - scale_translations/static_scale_translations.dart (753 行): StaticScaleTranslations
//   实现 (10 量表 50+ method 中文 fallback)
import 'package:chroniccare/domain/logic/assessment_scale.dart';

export 'package:chroniccare/domain/entities/scale_translations/static_scale_translations.dart'
    show StaticScaleTranslations;

/// 量表翻译抽象
///
/// v0.27 R78 (spzh P1-A 跨 round 收尾): 加 PHQ-9 / GAD-7 全文 i18n 方法
/// (R65 起步 TODO 跨 R65/R71/R77 4 round 未动, en / zh_Hant 用户做 PHQ-9 /
/// GAD-7 看到中文题目 + 严重度 + 引导语 = 医疗法律责任)。
///
/// 覆盖:
/// - 2 个量表名 (phq9 / gad7) — R65 已加 `assessmentScalePhq9` / `assessmentScaleGad7`
/// - 6 region 危机电话 label (cn / us / hk / tw / sg / uk × 2) — R77 已加
/// - **R78 新增** PHQ-9: 9 题 + 4 档选项 + 5 严重度 (label + summary) +
///   1 instruction + 1 shortDescription = 21 method
/// - **R78 新增** GAD-7: 7 题 + 4 档选项 + 4 严重度 (label + summary) +
///   1 instruction + 1 shortDescription = 17 method
///
/// 总 50 method (R65+R77 12 + R78 38)。ARB key ≈ 50 × 3 语 = 150 (含 severity
/// label/summary 拆开)。
abstract class ScaleTranslations {
  const ScaleTranslations();

  /// PHQ-9 量表名
  String phq9Name({String? override});

  /// GAD-7 量表名
  String gad7Name({String? override});

  /// 6 region 危机电话 label (cn / us / hk / tw / sg / uk)
  ///
  /// v0.27 R77 (spzh P1-A 收尾): 加 [index] 支持 6 region × 2 hotline (cn/us/tw 各 2 个,
  /// hk/sg/uk 各 1 个, index=1 越界走 fallback first.label)。
  /// tw/sg/uk 之前走 intl fallback, 现在每 region 都有独立 i18n key。
  String crisisHotlineLabel(HotlineRegion region,
      {int index = 0, String? override,});

  /// v0.27 R71 (spzh P1-A 续): 危机弹窗标题 (PHQ-9 Q9 阳性时)
  /// — 之前 detectCrisis 用 const 中文 '我们关心你' 硬编, en / zh_Hant 用户看中文
  String crisisTitle({String? override});

  /// v0.27 R71 (spzh P1-A 续): 危机弹窗正文 (含换行)
  /// — 之前 detectCrisis 用 const 中文 '你提到了想伤害自己的念头...'
  String crisisMessage({String? override});

  // ============================================================
  // PHQ-9 全文 i18n (v0.27 R78)
  // ============================================================

  /// PHQ-9 第 [index] 题题目 (0-8, 9 道题)
  String phq9Item(int index, {String? override});

  /// PHQ-9 频率选项 (0-3, 共 4 档)
  String phq9Option(int score, {String? override});

  /// PHQ-9 严重度 [rank] 的短标签 (0-4, 用于图表/对比)
  String phq9SeverityLabel(int rank, {String? override});

  /// PHQ-9 严重度 [rank] 的完整描述 (用于结果页)
  String phq9SeveritySummary(int rank, {String? override});

  /// PHQ-9 顶部引导语 (答题页 instruction)
  String phq9Instruction({String? override});

  /// PHQ-9 短描述 (设置页副标题)
  String phq9ShortDescription({String? override});

  // ============================================================
  // GAD-7 全文 i18n (v0.27 R78)
  // ============================================================

  /// GAD-7 第 [index] 题题目 (0-6, 7 道题)
  String gad7Item(int index, {String? override});

  /// GAD-7 频率选项 (0-3, 共 4 档, 跟 PHQ-9 一致)
  String gad7Option(int score, {String? override});

  /// GAD-7 严重度 [rank] 的短标签 (0-3, 用于图表/对比)
  String gad7SeverityLabel(int rank, {String? override});

  /// GAD-7 严重度 [rank] 的完整描述 (用于结果页)
  String gad7SeveritySummary(int rank, {String? override});

  /// GAD-7 顶部引导语
  String gad7Instruction({String? override});

  /// GAD-7 短描述
  String gad7ShortDescription({String? override});

  // ============================================================
  // v0.30 round 90 (Task 2): 8 新量表全文 i18n 抽象方法
  // 每量表 6 类 (name / shortDescription / instruction / items / options /
  // severityLabel + severitySummary), 实际题数 / 选项数 / 严重度档数。
  // 老 PHQ-9 (21) + GAD-7 (17) 不动, 这里只加新 8 量表。
  // ============================================================

  // ---- ISI (7 题, 5 档选项, 4 严重度, 23 方法) ----
  String isiName({String? override});
  String isiShortDescription({String? override});
  String isiInstruction({String? override});
  String isiItem(int index, {String? override});
  String isiOption(int score, {String? override});
  String isiSeverityLabel(int rank, {String? override});
  String isiSeveritySummary(int rank, {String? override});

  // ---- PSS (10 题, 5 档选项, 3 严重度, 24 方法) ----
  String pssName({String? override});
  String pssShortDescription({String? override});
  String pssInstruction({String? override});
  String pssItem(int index, {String? override});
  String pssOption(int score, {String? override});
  String pssSeverityLabel(int rank, {String? override});
  String pssSeveritySummary(int rank, {String? override});

  // ---- WHODAS (12 题, 5 档选项, 5 严重度, 30 方法) ----
  String whodasName({String? override});
  String whodasShortDescription({String? override});
  String whodasInstruction({String? override});
  String whodasItem(int index, {String? override});
  String whodasOption(int score, {String? override});
  String whodasSeverityLabel(int rank, {String? override});
  String whodasSeveritySummary(int rank, {String? override});

  // ---- Level 2 Depression (8 题, 4 档选项, 4 严重度, 23 方法) ----
  String level2DepressionName({String? override});
  String level2DepressionShortDescription({String? override});
  String level2DepressionInstruction({String? override});
  String level2DepressionItem(int index, {String? override});
  String level2DepressionOption(int score, {String? override});
  String level2DepressionSeverityLabel(int rank, {String? override});
  String level2DepressionSeveritySummary(int rank, {String? override});

  // ---- Level 2 Anxiety (7 题, 4 档选项, 4 严重度, 22 方法) ----
  String level2AnxietyName({String? override});
  String level2AnxietyShortDescription({String? override});
  String level2AnxietyInstruction({String? override});
  String level2AnxietyItem(int index, {String? override});
  String level2AnxietyOption(int score, {String? override});
  String level2AnxietySeverityLabel(int rank, {String? override});
  String level2AnxietySeveritySummary(int rank, {String? override});

  // ---- Level 2 Mania (5 题, 4 档选项, 4 严重度, 19 方法) ----
  String level2ManiaName({String? override});
  String level2ManiaShortDescription({String? override});
  String level2ManiaInstruction({String? override});
  String level2ManiaItem(int index, {String? override});
  String level2ManiaOption(int score, {String? override});
  String level2ManiaSeverityLabel(int rank, {String? override});
  String level2ManiaSeveritySummary(int rank, {String? override});

  // ---- ASRM (5 题, 5 档选项, 5 严重度, 22 方法) ----
  String asrmName({String? override});
  String asrmShortDescription({String? override});
  String asrmInstruction({String? override});
  String asrmItem(int index, {String? override});
  String asrmOption(int score, {String? override});
  String asrmSeverityLabel(int rank, {String? override});
  String asrmSeveritySummary(int rank, {String? override});

  // ---- Level 2 Psychosis (8 题, 4 档选项, 4 严重度, 23 方法) ----
  String level2PsychosisName({String? override});
  String level2PsychosisShortDescription({String? override});
  String level2PsychosisInstruction({String? override});
  String level2PsychosisItem(int index, {String? override});
  String level2PsychosisOption(int score, {String? override});
  String level2PsychosisSeverityLabel(int rank, {String? override});
  String level2PsychosisSeveritySummary(int rank, {String? override});
}
