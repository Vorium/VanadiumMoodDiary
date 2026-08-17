// v1.1.0 R118 (god class 拆 P2-7 完整闭环验证): 10 个 translation class 直接单元测试
//
// 改前: static_scale_translations_round8_test.dart 测 8 个新量表 (走主壳委托)
// 改后: 加 round 118 直接测 10 个独立 class
//   1. 边界 (越界 → '' / override 优先)
//   2. 主壳委托 = 直调新 class (10 量表 70 method 一致性)
//   3. 跨 class 共享 (GAD-7 走 PHQ-9 4 档频率选项, R19 决策保留)
//
// R118 7 阶段抽 10 量表到独立 class, 0 单元 test 是回归风险。
// 主壳 StaticScaleTranslations round 8 test 验证 8 新量表 8 case 一致性,
//  走主壳委托间接测新 class。本批补直测 10 class + 边界。

import 'package:chroniccare/domain/entities/scale_translations.dart';
import 'package:chroniccare/domain/entities/scale_translations/asrm_translations.dart';
import 'package:chroniccare/domain/entities/scale_translations/gad7_translations.dart';
import 'package:chroniccare/domain/entities/scale_translations/isi_translations.dart';
import 'package:chroniccare/domain/entities/scale_translations/level2_anxiety_translations.dart';
import 'package:chroniccare/domain/entities/scale_translations/level2_depression_translations.dart';
import 'package:chroniccare/domain/entities/scale_translations/level2_mania_translations.dart';
import 'package:chroniccare/domain/entities/scale_translations/level2_psychosis_translations.dart';
import 'package:chroniccare/domain/entities/scale_translations/phq9_translations.dart';
import 'package:chroniccare/domain/entities/scale_translations/pss_translations.dart';
import 'package:chroniccare/domain/entities/scale_translations/whodas_translations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {});

  group('R118 P2-7 — 边界 (越界 → \'\' / override 优先)', () {
    test('Phq9Translations.phq9Item(-1) → ""', () {
      expect(const Phq9Translations().phq9Item(-1), '');
    });
    test('Phq9Translations.phq9Item(999) → ""', () {
      expect(const Phq9Translations().phq9Item(999), '');
    });
    test('Phq9Translations.phq9Name(override: "test") → "test"', () {
      expect(const Phq9Translations().phq9Name(override: 'test'), 'test');
    });
    test('Phq9Translations.phq9Option(99) → ""', () {
      expect(const Phq9Translations().phq9Option(99), '');
    });
    test('Phq9Translations.phq9SeverityLabel(999) → ""', () {
      expect(const Phq9Translations().phq9SeverityLabel(999), '');
    });
    test('Phq9Translations.phq9SeveritySummary(999) → ""', () {
      expect(const Phq9Translations().phq9SeveritySummary(999), '');
    });

    test('Gad7Translations.gad7Item(-1) → ""', () {
      expect(const Gad7Translations().gad7Item(-1), '');
    });
    test('Gad7Translations.gad7Name(override: "test") → "test"', () {
      expect(const Gad7Translations().gad7Name(override: 'test'), 'test');
    });
    test('Gad7Translations.gad7Option(99) → "" (走 Phq9 共享)', () {
      expect(const Gad7Translations().gad7Option(99), '');
    });

    test('IsiTranslations.isiItem(-1) → ""', () {
      expect(const IsiTranslations().isiItem(-1), '');
    });
    test('IsiTranslations.isiOption(99) → ""', () {
      expect(const IsiTranslations().isiOption(99), '');
    });

    test('PssTranslations.pssItem(-1) → ""', () {
      expect(const PssTranslations().pssItem(-1), '');
    });
    test('PssTranslations.pssOption(99) → ""', () {
      expect(const PssTranslations().pssOption(99), '');
    });

    test('WhodasTranslations.whodasItem(-1) → ""', () {
      expect(const WhodasTranslations().whodasItem(-1), '');
    });
    test('WhodasTranslations.whodasOption(99) → ""', () {
      expect(const WhodasTranslations().whodasOption(99), '');
    });

    test('AsrmTranslations.asrmItem(-1) → ""', () {
      expect(const AsrmTranslations().asrmItem(-1), '');
    });
    test('Level2DepressionTranslations.level2DepressionItem(-1) → ""', () {
      expect(const Level2DepressionTranslations().level2DepressionItem(-1), '');
    });
    test('Level2AnxietyTranslations.level2AnxietyItem(-1) → ""', () {
      expect(const Level2AnxietyTranslations().level2AnxietyItem(-1), '');
    });
    test('Level2ManiaTranslations.level2ManiaItem(-1) → ""', () {
      expect(const Level2ManiaTranslations().level2ManiaItem(-1), '');
    });
    test('Level2PsychosisTranslations.level2PsychosisItem(-1) → ""', () {
      expect(const Level2PsychosisTranslations().level2PsychosisItem(-1), '');
    });
  });

  group('R118 P2-7 — 主壳委托 == 直调 (10 量表 70 method 验证)', () {
    // 验证 composition 模式: 主壳 method 委托给新 class, 结果应一致。
    // 这是 R118 P2-7 拆分的关键不变量: 拆分不改行为。
    const main = StaticScaleTranslations();
    const phq9 = Phq9Translations();
    const gad7 = Gad7Translations();
    const isi = IsiTranslations();
    const pss = PssTranslations();
    const whodas = WhodasTranslations();
    const asrm = AsrmTranslations();
    const l2d = Level2DepressionTranslations();
    const l2a = Level2AnxietyTranslations();
    const l2m = Level2ManiaTranslations();
    const l2p = Level2PsychosisTranslations();

    test('PHQ-9 7 method 主壳委托 == 直调', () {
      expect(main.phq9Name(), phq9.phq9Name());
      expect(main.phq9ShortDescription(), phq9.phq9ShortDescription());
      expect(main.phq9Instruction(), phq9.phq9Instruction());
      expect(main.phq9Item(0), phq9.phq9Item(0));
      expect(main.phq9Option(1), phq9.phq9Option(1));
      expect(main.phq9SeverityLabel(0), phq9.phq9SeverityLabel(0));
      expect(main.phq9SeveritySummary(0), phq9.phq9SeveritySummary(0));
    });

    test('GAD-7 7 method 主壳委托 == 直调', () {
      expect(main.gad7Name(), gad7.gad7Name());
      expect(main.gad7ShortDescription(), gad7.gad7ShortDescription());
      expect(main.gad7Instruction(), gad7.gad7Instruction());
      expect(main.gad7Item(0), gad7.gad7Item(0));
      expect(main.gad7Option(1), gad7.gad7Option(1));
      expect(main.gad7SeverityLabel(0), gad7.gad7SeverityLabel(0));
      expect(main.gad7SeveritySummary(0), gad7.gad7SeveritySummary(0));
    });

    test('ISI 7 method 主壳委托 == 直调', () {
      expect(main.isiName(), isi.isiName());
      expect(main.isiShortDescription(), isi.isiShortDescription());
      expect(main.isiInstruction(), isi.isiInstruction());
      expect(main.isiItem(0), isi.isiItem(0));
      expect(main.isiOption(2), isi.isiOption(2));
      expect(main.isiSeverityLabel(0), isi.isiSeverityLabel(0));
      expect(main.isiSeveritySummary(0), isi.isiSeveritySummary(0));
    });

    test('PSS 7 method 主壳委托 == 直调', () {
      expect(main.pssName(), pss.pssName());
      expect(main.pssShortDescription(), pss.pssShortDescription());
      expect(main.pssInstruction(), pss.pssInstruction());
      expect(main.pssItem(0), pss.pssItem(0));
      expect(main.pssOption(2), pss.pssOption(2));
      expect(main.pssSeverityLabel(0), pss.pssSeverityLabel(0));
      expect(main.pssSeveritySummary(0), pss.pssSeveritySummary(0));
    });

    test('WHODAS 7 method 主壳委托 == 直调', () {
      expect(main.whodasName(), whodas.whodasName());
      expect(main.whodasShortDescription(),
          whodas.whodasShortDescription());
      expect(main.whodasInstruction(), whodas.whodasInstruction());
      expect(main.whodasItem(0), whodas.whodasItem(0));
      expect(main.whodasOption(2), whodas.whodasOption(2));
      expect(main.whodasSeverityLabel(0), whodas.whodasSeverityLabel(0));
      expect(main.whodasSeveritySummary(0), whodas.whodasSeveritySummary(0));
    });

    test('ASRM 7 method 主壳委托 == 直调', () {
      expect(main.asrmName(), asrm.asrmName());
      expect(main.asrmShortDescription(), asrm.asrmShortDescription());
      expect(main.asrmInstruction(), asrm.asrmInstruction());
      expect(main.asrmItem(0), asrm.asrmItem(0));
      expect(main.asrmOption(2), asrm.asrmOption(2));
      expect(main.asrmSeverityLabel(0), asrm.asrmSeverityLabel(0));
      expect(main.asrmSeveritySummary(0), asrm.asrmSeveritySummary(0));
    });

    test('Level2 Depression 7 method 主壳委托 == 直调', () {
      expect(main.level2DepressionName(), l2d.level2DepressionName());
      expect(main.level2DepressionShortDescription(),
          l2d.level2DepressionShortDescription());
      expect(main.level2DepressionInstruction(),
          l2d.level2DepressionInstruction());
      expect(main.level2DepressionItem(0), l2d.level2DepressionItem(0));
      expect(main.level2DepressionOption(1), l2d.level2DepressionOption(1));
      expect(main.level2DepressionSeverityLabel(0),
          l2d.level2DepressionSeverityLabel(0));
      expect(main.level2DepressionSeveritySummary(0),
          l2d.level2DepressionSeveritySummary(0));
    });

    test('Level2 Anxiety 7 method 主壳委托 == 直调', () {
      expect(main.level2AnxietyName(), l2a.level2AnxietyName());
      expect(main.level2AnxietyShortDescription(),
          l2a.level2AnxietyShortDescription());
      expect(main.level2AnxietyInstruction(), l2a.level2AnxietyInstruction());
      expect(main.level2AnxietyItem(0), l2a.level2AnxietyItem(0));
      expect(main.level2AnxietyOption(1), l2a.level2AnxietyOption(1));
      expect(main.level2AnxietySeverityLabel(0),
          l2a.level2AnxietySeverityLabel(0));
      expect(main.level2AnxietySeveritySummary(0),
          l2a.level2AnxietySeveritySummary(0));
    });

    test('Level2 Mania 7 method 主壳委托 == 直调', () {
      expect(main.level2ManiaName(), l2m.level2ManiaName());
      expect(main.level2ManiaShortDescription(),
          l2m.level2ManiaShortDescription());
      expect(main.level2ManiaInstruction(), l2m.level2ManiaInstruction());
      expect(main.level2ManiaItem(0), l2m.level2ManiaItem(0));
      expect(main.level2ManiaOption(1), l2m.level2ManiaOption(1));
      expect(main.level2ManiaSeverityLabel(0),
          l2m.level2ManiaSeverityLabel(0));
      expect(main.level2ManiaSeveritySummary(0),
          l2m.level2ManiaSeveritySummary(0));
    });

    test('Level2 Psychosis 7 method 主壳委托 == 直调', () {
      expect(main.level2PsychosisName(), l2p.level2PsychosisName());
      expect(main.level2PsychosisShortDescription(),
          l2p.level2PsychosisShortDescription());
      expect(main.level2PsychosisInstruction(),
          l2p.level2PsychosisInstruction());
      expect(main.level2PsychosisItem(0), l2p.level2PsychosisItem(0));
      expect(main.level2PsychosisOption(1), l2p.level2PsychosisOption(1));
      expect(main.level2PsychosisSeverityLabel(0),
          l2p.level2PsychosisSeverityLabel(0));
      expect(main.level2PsychosisSeveritySummary(0),
          l2p.level2PsychosisSeveritySummary(0));
    });
  });

  group('R118 P2-7 — 跨 class 共享 (GAD-7 走 PHQ-9 4 档频率选项)', () {
    test('Gad7Translations.gad7Option(0..3) == Phq9Translations.phq9Option(0..3)',
        () {
      const gad7 = Gad7Translations();
      const phq9 = Phq9Translations();
      for (final score in [0, 1, 2, 3]) {
        expect(gad7.gad7Option(score), phq9.phq9Option(score),
            reason: 'GAD-7 跟 PHQ-9 共享 4 档频率选项 (R19 决策保留)');
      }
    });

    test('Gad7Translations.gad7Option(4+) → "" (跟 PHQ-9 一致)', () {
      // PHQ-9 optionsZh 只有 0..3, 4+ 应该返回 ''
      const gad7 = Gad7Translations();
      const phq9 = Phq9Translations();
      for (final score in [4, 5, 99]) {
        expect(gad7.gad7Option(score), phq9.phq9Option(score),
            reason: '越界 score 应该一致返回 ""');
      }
    });
  });

  group('R118 P2-7 — name/shortDescription/instruction 真实输出非空', () {
    // 验证每个 class 的 7 method 都有非空 fallback (无 stub, 跟 R111 SP-111-04 模式一致)
    test('PHQ-9', () {
      const t = Phq9Translations();
      expect(t.phq9Name(), isNotEmpty);
      expect(t.phq9ShortDescription(), isNotEmpty);
      expect(t.phq9Instruction(), isNotEmpty);
    });
    test('GAD-7', () {
      const t = Gad7Translations();
      expect(t.gad7Name(), isNotEmpty);
      expect(t.gad7ShortDescription(), isNotEmpty);
      expect(t.gad7Instruction(), isNotEmpty);
    });
    test('ISI', () {
      const t = IsiTranslations();
      expect(t.isiName(), isNotEmpty);
      expect(t.isiShortDescription(), isNotEmpty);
      expect(t.isiInstruction(), isNotEmpty);
    });
    test('PSS', () {
      const t = PssTranslations();
      expect(t.pssName(), isNotEmpty);
      expect(t.pssShortDescription(), isNotEmpty);
      expect(t.pssInstruction(), isNotEmpty);
    });
    test('WHODAS', () {
      const t = WhodasTranslations();
      expect(t.whodasName(), isNotEmpty);
      expect(t.whodasShortDescription(), isNotEmpty);
      expect(t.whodasInstruction(), isNotEmpty);
    });
    test('ASRM', () {
      const t = AsrmTranslations();
      expect(t.asrmName(), isNotEmpty);
      expect(t.asrmShortDescription(), isNotEmpty);
      expect(t.asrmInstruction(), isNotEmpty);
    });
    test('Level2 Depression', () {
      const t = Level2DepressionTranslations();
      expect(t.level2DepressionName(), isNotEmpty);
      expect(t.level2DepressionShortDescription(), isNotEmpty);
      expect(t.level2DepressionInstruction(), isNotEmpty);
    });
    test('Level2 Anxiety', () {
      const t = Level2AnxietyTranslations();
      expect(t.level2AnxietyName(), isNotEmpty);
      expect(t.level2AnxietyShortDescription(), isNotEmpty);
      expect(t.level2AnxietyInstruction(), isNotEmpty);
    });
    test('Level2 Mania', () {
      const t = Level2ManiaTranslations();
      expect(t.level2ManiaName(), isNotEmpty);
      expect(t.level2ManiaShortDescription(), isNotEmpty);
      expect(t.level2ManiaInstruction(), isNotEmpty);
    });
    test('Level2 Psychosis', () {
      const t = Level2PsychosisTranslations();
      expect(t.level2PsychosisName(), isNotEmpty);
      expect(t.level2PsychosisShortDescription(), isNotEmpty);
      expect(t.level2PsychosisInstruction(), isNotEmpty);
    });
  });
}
