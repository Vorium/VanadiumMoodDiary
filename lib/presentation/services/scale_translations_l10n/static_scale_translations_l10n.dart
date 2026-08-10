// v0.27 round 75 (R74 报告 P1-1 修): `AppLocalizationsScaleTranslations` 从
// `lib/domain/entities/scale_translations.dart` 移到 presentation 层。
//
// 原因: domain 层 0 Flutter 0 Drift (4 层架构纯度) — 之前类在 domain
// 但实际依赖 AppLocalizations, 间接 import Flutter, 触发 R74 报告的
// "soft 架构违规" P1-1。
//
// 修法: 类移到 presentation 层, domain 只留 abstract ScaleTranslations + 中文
// fallback StaticScaleTranslations。当前 0 caller 引用 (R65 抽象 + R71 crisis
// i18n 抽走 fallback), 0 回归风险。R76+ 真接 SMS/Email 后, 紧急联系人 + 评估
// 报告 + 失联通知 都需要 l10n, 走 `AppLocalizationsScaleTranslations(l10n)` 包装。
//
// v0.30 round 90 (Task 2): 8 新量表 186 方法 stub, 全部返 `''`。
// Task 6 (i18n 任务) 写 ARB key + 改 `l10n.xxxItem(index)` 委托 — 跟 R78 PHQ-9
// 现有实现同模式 (switch case + l10n.xxxItem0/1/2/...)。当前 stub 故意返空,
// 让 const class 兜底 (displayName / items / options / severityCutoffs.label)
// 仍能显示, 后续 Task 6 全量补 ARB 后这里也同步扩。
//
// v0.30 round 95 (sub-spec 6 task 6b): 拆 785 → 2 文件 (主壳 re-export + 本文件 impl)
// - scale_translations_l10n.dart (主壳, 24 行): abstract 引用 + re-export
//   AppLocalizationsScaleTranslations 走本 static_scale_translations_l10n.dart
// - scale_translations_l10n/static_scale_translations_l10n.dart (本文件, 760 行):
//   AppLocalizationsScaleTranslations 类实现 (10 量表 186 method)
// 跟 R95 sub-spec 4 task 2 拆 scale_translations 模式一致 (abstract 主壳 + static sub-file)
import 'package:chroniccare/domain/entities/scale_translations.dart';
import 'package:chroniccare/domain/logic/assessment_scale.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

/// AppLocalizations 包装 (presentation 层注入, 走 zh / en / zh_Hant)
class AppLocalizationsScaleTranslations implements ScaleTranslations {
  final AppLocalizations l10n;
  const AppLocalizationsScaleTranslations(this.l10n);

  @override
  String phq9Name({String? override}) => override ?? l10n.assessmentScalePhq9;

  @override
  String gad7Name({String? override}) => override ?? l10n.assessmentScaleGad7;

  @override
  String crisisHotlineLabel(
    HotlineRegion region, {
    int index = 0,
    String? override,
  }) {
    if (override != null) return override;
    // v0.27 R77 (spzh P1-A 收尾): 6 region × 2 hotline 全 i18n 化
    // (cn/us/tw 各 2 个, hk/sg/uk 各 1 个)。index 越界走 first.label 兜底。
    // scaleHotlineIntl 保留作 region 缺数据 fallback (e.g. 未来新 region)。
    if (index < 0) return l10n.scaleHotlineIntl;
    switch (region) {
      case HotlineRegion.cn:
        return index == 0 ? l10n.scaleHotlineCn : l10n.scaleHotlineCn2;
      case HotlineRegion.us:
        return index == 0 ? l10n.scaleHotlineUs : l10n.scaleHotlineUs2;
      case HotlineRegion.hk:
        return l10n.scaleHotlineHk;
      case HotlineRegion.tw:
        return index == 0 ? l10n.scaleHotlineTw : l10n.scaleHotlineTw2;
      case HotlineRegion.sg:
        return l10n.scaleHotlineSg;
      case HotlineRegion.uk:
        return l10n.scaleHotlineUk;
    }
  }

  @override
  String crisisTitle({String? override}) => override ?? l10n.scaleCrisisTitle;

  @override
  String crisisMessage({String? override}) =>
      override ?? l10n.scaleCrisisMessage;

  // ============================================================
  // PHQ-9 全文 i18n (v0.27 R78)
  // ============================================================

  @override
  String phq9Item(int index, {String? override}) {
    if (override != null) return override;
    switch (index) {
      case 0:
        return l10n.phq9Item0;
      case 1:
        return l10n.phq9Item1;
      case 2:
        return l10n.phq9Item2;
      case 3:
        return l10n.phq9Item3;
      case 4:
        return l10n.phq9Item4;
      case 5:
        return l10n.phq9Item5;
      case 6:
        return l10n.phq9Item6;
      case 7:
        return l10n.phq9Item7;
      case 8:
        return l10n.phq9Item8;
      default:
        return '';
    }
  }

  @override
  String phq9Option(int score, {String? override}) {
    if (override != null) return override;
    switch (score) {
      case 0:
        return l10n.phq9Option0;
      case 1:
        return l10n.phq9Option1;
      case 2:
        return l10n.phq9Option2;
      case 3:
        return l10n.phq9Option3;
      default:
        return '';
    }
  }

  @override
  String phq9SeverityLabel(int rank, {String? override}) {
    if (override != null) return override;
    switch (rank) {
      case 0:
        return l10n.phq9SeverityLabel0;
      case 1:
        return l10n.phq9SeverityLabel1;
      case 2:
        return l10n.phq9SeverityLabel2;
      case 3:
        return l10n.phq9SeverityLabel3;
      case 4:
        return l10n.phq9SeverityLabel4;
      default:
        return '';
    }
  }

  @override
  String phq9SeveritySummary(int rank, {String? override}) {
    if (override != null) return override;
    switch (rank) {
      case 0:
        return l10n.phq9SeveritySummary0;
      case 1:
        return l10n.phq9SeveritySummary1;
      case 2:
        return l10n.phq9SeveritySummary2;
      case 3:
        return l10n.phq9SeveritySummary3;
      case 4:
        return l10n.phq9SeveritySummary4;
      default:
        return '';
    }
  }

  @override
  String phq9Instruction({String? override}) =>
      override ?? l10n.phq9Instruction;

  @override
  String phq9ShortDescription({String? override}) =>
      override ?? l10n.phq9ShortDescription;

  // ============================================================
  // GAD-7 全文 i18n (v0.27 R78)
  // ============================================================

  @override
  String gad7Item(int index, {String? override}) {
    if (override != null) return override;
    switch (index) {
      case 0:
        return l10n.gad7Item0;
      case 1:
        return l10n.gad7Item1;
      case 2:
        return l10n.gad7Item2;
      case 3:
        return l10n.gad7Item3;
      case 4:
        return l10n.gad7Item4;
      case 5:
        return l10n.gad7Item5;
      case 6:
        return l10n.gad7Item6;
      default:
        return '';
    }
  }

  @override
  String gad7Option(int score, {String? override}) {
    // GAD-7 跟 PHQ-9 共用 4 档频率选项 (R19 决策保留, 文本完全一致)
    return phq9Option(score, override: override);
  }

  @override
  String gad7SeverityLabel(int rank, {String? override}) {
    if (override != null) return override;
    switch (rank) {
      case 0:
        return l10n.gad7SeverityLabel0;
      case 1:
        return l10n.gad7SeverityLabel1;
      case 2:
        return l10n.gad7SeverityLabel2;
      case 3:
        return l10n.gad7SeverityLabel3;
      default:
        return '';
    }
  }

  @override
  String gad7SeveritySummary(int rank, {String? override}) {
    if (override != null) return override;
    switch (rank) {
      case 0:
        return l10n.gad7SeveritySummary0;
      case 1:
        return l10n.gad7SeveritySummary1;
      case 2:
        return l10n.gad7SeveritySummary2;
      case 3:
        return l10n.gad7SeveritySummary3;
      default:
        return '';
    }
  }

  @override
  String gad7Instruction({String? override}) =>
      override ?? l10n.gad7Instruction;

  @override
  String gad7ShortDescription({String? override}) =>
      override ?? l10n.gad7ShortDescription;

  // ============================================================
  // v0.30 round 90 (Task 6): 8 新量表 i18n 委托 l10n.
  // 老 const class displayName / items / options / severityCutoffs 是 const
  // 中文 fallback, 走 AppLocalizationsScaleTranslations 后 l10n 接管 (走
  // zh / en / zh_Hant)。题目全文 留 v1.0 (跟 R78 PHQ-9 一致), 用
  // StaticScaleTranslations.const 内容兜底 — const class items 直接返 const
  // 题目, 不走 ARB 题目全文 (题目 keys 留 v1.0)。
  // ============================================================

  @override
  String isiName({String? override}) => override ?? l10n.isiName;

  @override
  String isiShortDescription({String? override}) =>
      override ?? l10n.isiShortDescription;

  @override
  String isiInstruction({String? override}) => override ?? l10n.isiInstruction;

  @override
  String isiItem(int index, {String? override}) {
    // 题目全文 留 v1.0 (跟 R78 PHQ-9 一致), 返 const 兜底空 — const class
    // items[] 直接显示中文, 不走 ARB
    return override ?? '';
  }

  @override
  String isiOption(int score, {String? override}) {
    if (override != null) return override;
    switch (score) {
      case 0:
        return l10n.isiOption0;
      case 1:
        return l10n.isiOption1;
      case 2:
        return l10n.isiOption2;
      case 3:
        return l10n.isiOption3;
      case 4:
        return l10n.isiOption4;
      default:
        return '';
    }
  }

  @override
  String isiSeverityLabel(int rank, {String? override}) {
    if (override != null) return override;
    switch (rank) {
      case 0:
        return l10n.isiSeverityLabel0;
      case 1:
        return l10n.isiSeverityLabel1;
      case 2:
        return l10n.isiSeverityLabel2;
      case 3:
        return l10n.isiSeverityLabel3;
      default:
        return '';
    }
  }

  @override
  String isiSeveritySummary(int rank, {String? override}) {
    if (override != null) return override;
    switch (rank) {
      case 0:
        return l10n.isiSeveritySummary0;
      case 1:
        return l10n.isiSeveritySummary1;
      case 2:
        return l10n.isiSeveritySummary2;
      case 3:
        return l10n.isiSeveritySummary3;
      default:
        return '';
    }
  }

  @override
  String pssName({String? override}) => override ?? l10n.pssName;

  @override
  String pssShortDescription({String? override}) =>
      override ?? l10n.pssShortDescription;

  @override
  String pssInstruction({String? override}) => override ?? l10n.pssInstruction;

  @override
  String pssItem(int index, {String? override}) {
    // 题目全文 留 v1.0
    return override ?? '';
  }

  @override
  String pssOption(int score, {String? override}) {
    if (override != null) return override;
    switch (score) {
      case 0:
        return l10n.pssOption0;
      case 1:
        return l10n.pssOption1;
      case 2:
        return l10n.pssOption2;
      case 3:
        return l10n.pssOption3;
      case 4:
        return l10n.pssOption4;
      default:
        return '';
    }
  }

  @override
  String pssSeverityLabel(int rank, {String? override}) {
    if (override != null) return override;
    switch (rank) {
      case 0:
        return l10n.pssSeverityLabel0;
      case 1:
        return l10n.pssSeverityLabel1;
      case 2:
        return l10n.pssSeverityLabel2;
      default:
        return '';
    }
  }

  @override
  String pssSeveritySummary(int rank, {String? override}) {
    if (override != null) return override;
    switch (rank) {
      case 0:
        return l10n.pssSeveritySummary0;
      case 1:
        return l10n.pssSeveritySummary1;
      case 2:
        return l10n.pssSeveritySummary2;
      default:
        return '';
    }
  }

  @override
  String whodasName({String? override}) => override ?? l10n.whodasName;

  @override
  String whodasShortDescription({String? override}) =>
      override ?? l10n.whodasShortDescription;

  @override
  String whodasInstruction({String? override}) =>
      override ?? l10n.whodasInstruction;

  @override
  String whodasItem(int index, {String? override}) {
    // 题目全文 留 v1.0
    return override ?? '';
  }

  @override
  String whodasOption(int score, {String? override}) {
    if (override != null) return override;
    switch (score) {
      case 0:
        return l10n.whodasOption0;
      case 1:
        return l10n.whodasOption1;
      case 2:
        return l10n.whodasOption2;
      case 3:
        return l10n.whodasOption3;
      case 4:
        return l10n.whodasOption4;
      default:
        return '';
    }
  }

  @override
  String whodasSeverityLabel(int rank, {String? override}) {
    if (override != null) return override;
    switch (rank) {
      case 0:
        return l10n.whodasSeverityLabel0;
      case 1:
        return l10n.whodasSeverityLabel1;
      case 2:
        return l10n.whodasSeverityLabel2;
      case 3:
        return l10n.whodasSeverityLabel3;
      case 4:
        return l10n.whodasSeverityLabel4;
      default:
        return '';
    }
  }

  @override
  String whodasSeveritySummary(int rank, {String? override}) {
    if (override != null) return override;
    switch (rank) {
      case 0:
        return l10n.whodasSeveritySummary0;
      case 1:
        return l10n.whodasSeveritySummary1;
      case 2:
        return l10n.whodasSeveritySummary2;
      case 3:
        return l10n.whodasSeveritySummary3;
      case 4:
        return l10n.whodasSeveritySummary4;
      default:
        return '';
    }
  }

  @override
  String level2DepressionName({String? override}) =>
      override ?? l10n.level2DepressionName;

  @override
  String level2DepressionShortDescription({String? override}) =>
      override ?? l10n.level2DepressionShortDescription;

  @override
  String level2DepressionInstruction({String? override}) =>
      override ?? l10n.level2DepressionInstruction;

  @override
  String level2DepressionItem(int index, {String? override}) {
    // 题目全文 留 v1.0
    return override ?? '';
  }

  @override
  String level2DepressionOption(int score, {String? override}) {
    if (override != null) return override;
    switch (score) {
      case 0:
        return l10n.level2DepressionOption0;
      case 1:
        return l10n.level2DepressionOption1;
      case 2:
        return l10n.level2DepressionOption2;
      case 3:
        return l10n.level2DepressionOption3;
      default:
        return '';
    }
  }

  @override
  String level2DepressionSeverityLabel(int rank, {String? override}) {
    if (override != null) return override;
    switch (rank) {
      case 0:
        return l10n.level2DepressionSeverityLabel0;
      case 1:
        return l10n.level2DepressionSeverityLabel1;
      case 2:
        return l10n.level2DepressionSeverityLabel2;
      case 3:
        return l10n.level2DepressionSeverityLabel3;
      default:
        return '';
    }
  }

  @override
  String level2DepressionSeveritySummary(int rank, {String? override}) {
    if (override != null) return override;
    switch (rank) {
      case 0:
        return l10n.level2DepressionSeveritySummary0;
      case 1:
        return l10n.level2DepressionSeveritySummary1;
      case 2:
        return l10n.level2DepressionSeveritySummary2;
      case 3:
        return l10n.level2DepressionSeveritySummary3;
      default:
        return '';
    }
  }

  @override
  String level2AnxietyName({String? override}) =>
      override ?? l10n.level2AnxietyName;

  @override
  String level2AnxietyShortDescription({String? override}) =>
      override ?? l10n.level2AnxietyShortDescription;

  @override
  String level2AnxietyInstruction({String? override}) =>
      override ?? l10n.level2AnxietyInstruction;

  @override
  String level2AnxietyItem(int index, {String? override}) {
    // 题目全文 留 v1.0
    return override ?? '';
  }

  @override
  String level2AnxietyOption(int score, {String? override}) {
    if (override != null) return override;
    switch (score) {
      case 0:
        return l10n.level2AnxietyOption0;
      case 1:
        return l10n.level2AnxietyOption1;
      case 2:
        return l10n.level2AnxietyOption2;
      case 3:
        return l10n.level2AnxietyOption3;
      default:
        return '';
    }
  }

  @override
  String level2AnxietySeverityLabel(int rank, {String? override}) {
    if (override != null) return override;
    switch (rank) {
      case 0:
        return l10n.level2AnxietySeverityLabel0;
      case 1:
        return l10n.level2AnxietySeverityLabel1;
      case 2:
        return l10n.level2AnxietySeverityLabel2;
      case 3:
        return l10n.level2AnxietySeverityLabel3;
      default:
        return '';
    }
  }

  @override
  String level2AnxietySeveritySummary(int rank, {String? override}) {
    if (override != null) return override;
    switch (rank) {
      case 0:
        return l10n.level2AnxietySeveritySummary0;
      case 1:
        return l10n.level2AnxietySeveritySummary1;
      case 2:
        return l10n.level2AnxietySeveritySummary2;
      case 3:
        return l10n.level2AnxietySeveritySummary3;
      default:
        return '';
    }
  }

  @override
  String level2ManiaName({String? override}) =>
      override ?? l10n.level2ManiaName;

  @override
  String level2ManiaShortDescription({String? override}) =>
      override ?? l10n.level2ManiaShortDescription;

  @override
  String level2ManiaInstruction({String? override}) =>
      override ?? l10n.level2ManiaInstruction;

  @override
  String level2ManiaItem(int index, {String? override}) {
    // 题目全文 留 v1.0
    return override ?? '';
  }

  @override
  String level2ManiaOption(int score, {String? override}) {
    if (override != null) return override;
    switch (score) {
      case 0:
        return l10n.level2ManiaOption0;
      case 1:
        return l10n.level2ManiaOption1;
      case 2:
        return l10n.level2ManiaOption2;
      case 3:
        return l10n.level2ManiaOption3;
      default:
        return '';
    }
  }

  @override
  String level2ManiaSeverityLabel(int rank, {String? override}) {
    if (override != null) return override;
    switch (rank) {
      case 0:
        return l10n.level2ManiaSeverityLabel0;
      case 1:
        return l10n.level2ManiaSeverityLabel1;
      case 2:
        return l10n.level2ManiaSeverityLabel2;
      case 3:
        return l10n.level2ManiaSeverityLabel3;
      default:
        return '';
    }
  }

  @override
  String level2ManiaSeveritySummary(int rank, {String? override}) {
    if (override != null) return override;
    switch (rank) {
      case 0:
        return l10n.level2ManiaSeveritySummary0;
      case 1:
        return l10n.level2ManiaSeveritySummary1;
      case 2:
        return l10n.level2ManiaSeveritySummary2;
      case 3:
        return l10n.level2ManiaSeveritySummary3;
      default:
        return '';
    }
  }

  @override
  String asrmName({String? override}) => override ?? l10n.asrmName;

  @override
  String asrmShortDescription({String? override}) =>
      override ?? l10n.asrmShortDescription;

  @override
  String asrmInstruction({String? override}) =>
      override ?? l10n.asrmInstruction;

  @override
  String asrmItem(int index, {String? override}) {
    // 题目全文 留 v1.0
    return override ?? '';
  }

  @override
  String asrmOption(int score, {String? override}) {
    if (override != null) return override;
    switch (score) {
      case 0:
        return l10n.asrmOption0;
      case 1:
        return l10n.asrmOption1;
      case 2:
        return l10n.asrmOption2;
      case 3:
        return l10n.asrmOption3;
      case 4:
        return l10n.asrmOption4;
      default:
        return '';
    }
  }

  @override
  String asrmSeverityLabel(int rank, {String? override}) {
    if (override != null) return override;
    switch (rank) {
      case 0:
        return l10n.asrmSeverityLabel0;
      case 1:
        return l10n.asrmSeverityLabel1;
      case 2:
        return l10n.asrmSeverityLabel2;
      case 3:
        return l10n.asrmSeverityLabel3;
      case 4:
        return l10n.asrmSeverityLabel4;
      default:
        return '';
    }
  }

  @override
  String asrmSeveritySummary(int rank, {String? override}) {
    if (override != null) return override;
    switch (rank) {
      case 0:
        return l10n.asrmSeveritySummary0;
      case 1:
        return l10n.asrmSeveritySummary1;
      case 2:
        return l10n.asrmSeveritySummary2;
      case 3:
        return l10n.asrmSeveritySummary3;
      case 4:
        return l10n.asrmSeveritySummary4;
      default:
        return '';
    }
  }

  @override
  String level2PsychosisName({String? override}) =>
      override ?? l10n.level2PsychosisName;

  @override
  String level2PsychosisShortDescription({String? override}) =>
      override ?? l10n.level2PsychosisShortDescription;

  @override
  String level2PsychosisInstruction({String? override}) =>
      override ?? l10n.level2PsychosisInstruction;

  @override
  String level2PsychosisItem(int index, {String? override}) {
    // 题目全文 留 v1.0
    return override ?? '';
  }

  @override
  String level2PsychosisOption(int score, {String? override}) {
    if (override != null) return override;
    switch (score) {
      case 0:
        return l10n.level2PsychosisOption0;
      case 1:
        return l10n.level2PsychosisOption1;
      case 2:
        return l10n.level2PsychosisOption2;
      case 3:
        return l10n.level2PsychosisOption3;
      default:
        return '';
    }
  }

  @override
  String level2PsychosisSeverityLabel(int rank, {String? override}) {
    if (override != null) return override;
    switch (rank) {
      case 0:
        return l10n.level2PsychosisSeverityLabel0;
      case 1:
        return l10n.level2PsychosisSeverityLabel1;
      case 2:
        return l10n.level2PsychosisSeverityLabel2;
      case 3:
        return l10n.level2PsychosisSeverityLabel3;
      default:
        return '';
    }
  }

  @override
  String level2PsychosisSeveritySummary(int rank, {String? override}) {
    if (override != null) return override;
    switch (rank) {
      case 0:
        return l10n.level2PsychosisSeveritySummary0;
      case 1:
        return l10n.level2PsychosisSeveritySummary1;
      case 2:
        return l10n.level2PsychosisSeveritySummary2;
      case 3:
        return l10n.level2PsychosisSeveritySummary3;
      default:
        return '';
    }
  }
}
