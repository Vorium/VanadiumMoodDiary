// v1.1.0+168 R122 P2-3 (R121 P1-3 step 3 续) — 10 量表 sub-interface 拆分
// (Interface Segregation Principle, R19 决策保留)
//
// 拆解动机 (R121 P1-3 step 3 评估 → R122 P2-3 闭环):
// - R118 P2-7 抽 10 量表独立 class, 主壳持 10 const instance, 70 method
//   1:1 委托 — 是 composition 模式, 不是 interface inheritance
// - R121 P1-3 step 3 评估时算 "10 × 70 = 700 method stub 远超 70 委派",
//   结论: defer 到 pub workspace 规模
// - R122 P2-3 重新评估: 1 个 70-method ScaleTranslations interface 是
//   interface segregation violation — 任何 1 个量表 class implements
//   都必须实现全部 70 method, 真实需求只是自己那 7 method
// - 修法: 拆 10 sub-interface × 7 method, 每个量表 implements 各自
//   sub-interface (10 × 7 = 70 stub, 跟 70 委派同档, 但 caller 可绕过
//   主壳直接用 sub-interface 拿单量表翻译)
//
// 收益 (跟 R121 P1-3 step 3 评估对比):
// - 70 委派保留 (StaticScaleTranslations 仍 1 行委派, 老 caller 0 改动)
// - 10 sub-interface 公开: caller 只关心 PHQ-9 / GAD-7 等单量表时
//   直接 `Phq9Translations().phq9Item(0)`, 跳过 70 委派链
// - 真正"消除 70 委派" = 让 70 委派成为可选 (caller 可绕过), 不是删
//   主壳 method (会破 21 case crisis test 老 caller)
//
// 单文件 10 sub-interface 集中器 (R118 P2-7 10 量表 1 文件集中模式延续):
// 避免 10 sub 文件 overhead (10 个 ~10L 文件 vs 1 个 80L 文件, 跨 7 method ×
// 10 量表 = 70 stub 集中易找, 跟 R118 P2-7 static_scale_translations.dart
// 70 method 集中器对齐)
//
// 4 层架构纯度: 本文件 0 flutter / 0 drift / 0 data / 0 presentation,
// check_all.dart 守门员 0 violation。10 sub-interface 签名纯抽象, 不依赖
// domain/logic/assessment_scale.dart (sub-interface 只描述"翻译什么",
// 不依赖"翻译对象类型" — 跟 ScaleTranslations 大 interface 用 HotlineRegion
// enum 不同)。

/// PHQ-9 (Patient Health Questionnaire-9 抑郁筛查 9 题) 翻译 sub-interface
abstract class Phq9TranslationsInterface {
  String phq9Name({String? override});
  String phq9ShortDescription({String? override});
  String phq9Instruction({String? override});
  String phq9Item(int index, {String? override});
  String phq9Option(int score, {String? override});
  String phq9SeverityLabel(int rank, {String? override});
  String phq9SeveritySummary(int rank, {String? override});
}

/// GAD-7 (Generalized Anxiety Disorder-7 焦虑筛查 7 题) 翻译 sub-interface
abstract class Gad7TranslationsInterface {
  String gad7Name({String? override});
  String gad7ShortDescription({String? override});
  String gad7Instruction({String? override});
  String gad7Item(int index, {String? override});
  String gad7Option(int score, {String? override});
  String gad7SeverityLabel(int rank, {String? override});
  String gad7SeveritySummary(int rank, {String? override});
}

/// ISI (Insomnia Severity Index 失眠严重指数 7 题) 翻译 sub-interface
abstract class IsiTranslationsInterface {
  String isiName({String? override});
  String isiShortDescription({String? override});
  String isiInstruction({String? override});
  String isiItem(int index, {String? override});
  String isiOption(int score, {String? override});
  String isiSeverityLabel(int rank, {String? override});
  String isiSeveritySummary(int rank, {String? override});
}

/// PSS (Perceived Stress Scale 知觉压力量表 10 题) 翻译 sub-interface
abstract class PssTranslationsInterface {
  String pssName({String? override});
  String pssShortDescription({String? override});
  String pssInstruction({String? override});
  String pssItem(int index, {String? override});
  String pssOption(int score, {String? override});
  String pssSeverityLabel(int rank, {String? override});
  String pssSeveritySummary(int rank, {String? override});
}

/// WHODAS 2.0 (WHO Disability Assessment Schedule 12 题) 翻译 sub-interface
abstract class WhodasTranslationsInterface {
  String whodasName({String? override});
  String whodasShortDescription({String? override});
  String whodasInstruction({String? override});
  String whodasItem(int index, {String? override});
  String whodasOption(int score, {String? override});
  String whodasSeverityLabel(int rank, {String? override});
  String whodasSeveritySummary(int rank, {String? override});
}

/// Level 2 Depression (DSM-5 Level 2 抑郁 8 题) 翻译 sub-interface
abstract class Level2DepressionTranslationsInterface {
  String level2DepressionName({String? override});
  String level2DepressionShortDescription({String? override});
  String level2DepressionInstruction({String? override});
  String level2DepressionItem(int index, {String? override});
  String level2DepressionOption(int score, {String? override});
  String level2DepressionSeverityLabel(int rank, {String? override});
  String level2DepressionSeveritySummary(int rank, {String? override});
}

/// Level 2 Anxiety (DSM-5 Level 2 焦虑 7 题) 翻译 sub-interface
abstract class Level2AnxietyTranslationsInterface {
  String level2AnxietyName({String? override});
  String level2AnxietyShortDescription({String? override});
  String level2AnxietyInstruction({String? override});
  String level2AnxietyItem(int index, {String? override});
  String level2AnxietyOption(int score, {String? override});
  String level2AnxietySeverityLabel(int rank, {String? override});
  String level2AnxietySeveritySummary(int rank, {String? override});
}

/// Level 2 Mania (DSM-5 Level 2 躁狂 6 题) 翻译 sub-interface
abstract class Level2ManiaTranslationsInterface {
  String level2ManiaName({String? override});
  String level2ManiaShortDescription({String? override});
  String level2ManiaInstruction({String? override});
  String level2ManiaItem(int index, {String? override});
  String level2ManiaOption(int score, {String? override});
  String level2ManiaSeverityLabel(int rank, {String? override});
  String level2ManiaSeveritySummary(int rank, {String? override});
}

/// Level 2 Psychosis (DSM-5 Level 2 精神病性 8 题) 翻译 sub-interface
abstract class Level2PsychosisTranslationsInterface {
  String level2PsychosisName({String? override});
  String level2PsychosisShortDescription({String? override});
  String level2PsychosisInstruction({String? override});
  String level2PsychosisItem(int index, {String? override});
  String level2PsychosisOption(int score, {String? override});
  String level2PsychosisSeverityLabel(int rank, {String? override});
  String level2PsychosisSeveritySummary(int rank, {String? override});
}

/// ASRM (Altman Self-Rating Mania Scale 5 题) 翻译 sub-interface
abstract class AsrmTranslationsInterface {
  String asrmName({String? override});
  String asrmShortDescription({String? override});
  String asrmInstruction({String? override});
  String asrmItem(int index, {String? override});
  String asrmOption(int score, {String? override});
  String asrmSeverityLabel(int rank, {String? override});
  String asrmSeveritySummary(int rank, {String? override});
}
