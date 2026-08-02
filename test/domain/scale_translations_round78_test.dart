// v0.27 R78 (spzh P1-A 跨 round 收尾): PHQ-9 / GAD-7 全文 i18n 测试
//
// 覆盖 (R65 起步 TODO 跨 4 round 收尾, en / zh_Hant 用户看英文 / 繁体):
// - PHQ-9 9 题题目走 translations.phq9Item(0..8)
// - PHQ-9 4 档频率选项走 translations.phq9Option(0..3)
// - PHQ-9 5 档严重度 (label + summary) 走 translations
// - PHQ-9 instruction + shortDescription 走 translations
// - GAD-7 7 题 + 4 档严重度 + instruction + shortDescription 同款
// - 21 case phq9_detect_crisis + 13 case gad7 走 const StaticScaleTranslations
//   返中文, 不破 (R78 验证)

import 'package:chroniccare/domain/entities/scale_translations.dart';
import 'package:chroniccare/domain/logic/gad7.dart';
import 'package:chroniccare/domain/logic/phq9.dart';
import 'package:chroniccare/l10n/app_localizations_en.dart';
import 'package:chroniccare/l10n/app_localizations_zh.dart';
import 'package:chroniccare/presentation/services/scale_translations_l10n.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StaticScaleTranslations (R78: PHQ-9/GAD-7 中文 fallback)', () {
    const t = StaticScaleTranslations();

    test('phq9Item 9 题全部返中文', () {
      expect(t.phq9Item(0), '做事时提不起劲或没有兴趣');
      expect(t.phq9Item(1), '感到心情低落、沮丧或绝望');
      expect(t.phq9Item(2), '入睡困难、睡不安稳或睡得过多');
      expect(t.phq9Item(3), '感觉疲倦或没有活力');
      expect(t.phq9Item(4), '食欲不振或吃太多');
      expect(t.phq9Item(5), '觉得自己很糟、很失败，或让自己和家人失望');
      expect(t.phq9Item(6), '对事物专注有困难，例如看报纸或看电视时');
      expect(t.phq9Item(7), '动作或说话速度缓慢到别人能察觉？\n或正好相反——烦躁或坐立不安');
      expect(t.phq9Item(8), '有不如死掉或用某种方式伤害自己的念头');
    });

    test('phq9Option 4 档频率选项返中文', () {
      expect(t.phq9Option(0), '完全不会');
      expect(t.phq9Option(1), '好几天');
      expect(t.phq9Option(2), '一半以上的天数');
      expect(t.phq9Option(3), '几乎每天');
    });

    test('phq9SeverityLabel 5 档返中文', () {
      expect(t.phq9SeverityLabel(0), '几乎没有抑郁');
      expect(t.phq9SeverityLabel(1), '轻度抑郁');
      expect(t.phq9SeverityLabel(2), '中度抑郁');
      expect(t.phq9SeverityLabel(3), '中重度抑郁');
      expect(t.phq9SeverityLabel(4), '重度抑郁');
    });

    test('phq9SeveritySummary 5 档返中文', () {
      expect(t.phq9SeveritySummary(0), '几乎没有抑郁倾向');
      expect(t.phq9SeveritySummary(1), '轻度抑郁倾向');
      expect(t.phq9SeveritySummary(2), '中度抑郁倾向');
      expect(t.phq9SeveritySummary(3), '中重度抑郁倾向');
      expect(t.phq9SeveritySummary(4), '重度抑郁倾向');
    });

    test('phq9Instruction + phq9ShortDescription 返中文', () {
      expect(t.phq9Instruction(), '过去两周内，你有多经常被以下问题困扰？');
      expect(t.phq9ShortDescription(), '过去两周的抑郁倾向筛查');
    });

    test('gad7Item 7 题全部返中文', () {
      expect(t.gad7Item(0), '感到紧张、焦虑或急切');
      expect(t.gad7Item(1), '不能停止或控制担忧');
      expect(t.gad7Item(2), '对各种事情担忧过多');
      expect(t.gad7Item(3), '难以放松');
      expect(t.gad7Item(4), '心情烦躁以至坐不住');
      expect(t.gad7Item(5), '变得容易烦恼或急躁');
      expect(t.gad7Item(6), '感到似乎将有可怕的事情发生而害怕');
    });

    test('gad7Option 跟 PHQ-9 共享 4 档', () {
      expect(t.gad7Option(0), '完全不会');
      expect(t.gad7Option(1), '好几天');
      expect(t.gad7Option(2), '一半以上的天数');
      expect(t.gad7Option(3), '几乎每天');
    });

    test('gad7SeverityLabel + Summary 4 档返中文', () {
      expect(t.gad7SeverityLabel(0), '几乎没有焦虑');
      expect(t.gad7SeverityLabel(1), '轻度焦虑');
      expect(t.gad7SeverityLabel(2), '中度焦虑');
      expect(t.gad7SeverityLabel(3), '重度焦虑');
      expect(t.gad7SeveritySummary(0), '几乎没有焦虑倾向');
      expect(t.gad7SeveritySummary(3), '重度焦虑倾向');
    });

    test('gad7Instruction + gad7ShortDescription 返中文', () {
      expect(t.gad7Instruction(), '过去两周内，你有多经常被以下问题困扰？');
      expect(t.gad7ShortDescription(), '过去两周的焦虑倾向筛查');
    });

    test('越界 index 返空字符串 (跟 R77 hotline 越界行为一致)', () {
      expect(t.phq9Item(99), '');
      expect(t.phq9Item(-1), '');
      expect(t.phq9Option(99), '');
      expect(t.phq9SeverityLabel(99), '');
      expect(t.gad7Item(99), '');
      expect(t.gad7SeverityLabel(99), '');
    });

    test('override 优先', () {
      expect(t.phq9Item(0, override: 'Custom'), 'Custom');
      expect(t.gad7Item(3, override: 'Custom GAD'), 'Custom GAD');
      expect(t.phq9SeverityLabel(2, override: 'My level'), 'My level');
    });
  });

  group('AppLocalizationsScaleTranslations (R78: en 路径)', () {
    final enL10n = AppLocalizationsEn();
    final t = AppLocalizationsScaleTranslations(enL10n);

    test('phq9Item 9 题 en 走英文 (≠ 中文 fallback)', () {
      expect(t.phq9Item(0), 'Little interest or pleasure in doing things');
      expect(t.phq9Item(8),
          'Thoughts that you would be better off dead, or of hurting yourself in some way',);
    });

    test('phq9Option en 返英文', () {
      expect(t.phq9Option(0), 'Not at all');
      expect(t.phq9Option(3), 'Nearly every day');
    });

    test('phq9SeverityLabel en 返英文 (clinical 5 档)', () {
      expect(t.phq9SeverityLabel(0), 'None');
      expect(t.phq9SeverityLabel(1), 'Mild');
      expect(t.phq9SeverityLabel(2), 'Moderate');
      expect(t.phq9SeverityLabel(3), 'Moderately severe');
      expect(t.phq9SeverityLabel(4), 'Severe');
    });

    test('phq9SeveritySummary en 返英文', () {
      expect(t.phq9SeveritySummary(2), 'Moderate depression');
    });

    test('phq9Instruction en 返英文', () {
      expect(t.phq9Instruction(),
          'Over the last 2 weeks, how often have you been bothered by the following problems?',);
    });

    test('phq9ShortDescription en 返英文', () {
      expect(t.phq9ShortDescription(),
          'Depression screening over the last 2 weeks',);
    });

    test('gad7Item 7 题 en 返英文 (≠ 中文 fallback)', () {
      expect(t.gad7Item(0), 'Feeling nervous, anxious or on edge');
      expect(
          t.gad7Item(6), 'Feeling afraid as if something awful might happen',);
    });

    test('gad7SeverityLabel en 4 档返英文', () {
      expect(t.gad7SeverityLabel(0), 'None');
      expect(t.gad7SeverityLabel(3), 'Severe');
    });

    test('gad7Option en 跟 phq9Option 共享 4 档 (R19 决策)', () {
      expect(t.gad7Option(0), 'Not at all');
      expect(t.gad7Option(3), 'Nearly every day');
    });
  });

  group('AppLocalizationsScaleTranslations (R78: zh 路径)', () {
    final zhL10n = AppLocalizationsZh();
    final t = AppLocalizationsScaleTranslations(zhL10n);

    test('phq9Item zh 返中文 (跟 StaticScaleTranslations 等价)', () {
      expect(t.phq9Item(0), '做事时提不起劲或没有兴趣');
      expect(t.phq9Item(8), '有不如死掉或用某种方式伤害自己的念头');
    });

    test('gad7Item zh 返中文', () {
      expect(t.gad7Item(0), '感到紧张、焦虑或急切');
      expect(t.gad7Item(6), '感到似乎将有可怕的事情发生而害怕');
    });

    test('phq9SeverityLabel zh 跟 fallback 等价', () {
      expect(t.phq9SeverityLabel(2), '中度抑郁');
    });
  });

  group('Phq9Scale.items 走 translations (R78 集成)', () {
    test('const phq9Scale (走 StaticScaleTranslations) 返中文 items', () {
      // 21 case phq9_detect_crisis + R12 test 走这条路径, 验证 R78 不破
      const scale = phq9Scale;
      expect(scale.items.length, 9);
      expect(scale.items[0].text, '做事时提不起劲或没有兴趣');
      expect(scale.items[8].text, '有不如死掉或用某种方式伤害自己的念头');
    });

    test('Phq9Scale + AppLocalizationsEn → items 走英文', () {
      final enScale = Phq9Scale(
          translations:
              AppLocalizationsScaleTranslations(AppLocalizationsEn()),);
      expect(enScale.items.length, 9);
      expect(
          enScale.items[0].text, 'Little interest or pleasure in doing things',);
      expect(enScale.items[8].text,
          'Thoughts that you would be better off dead, or of hurting yourself in some way',);
    });

    test('Phq9Scale options 走 translations.phq9Option(0..3)', () {
      const scale = phq9Scale;
      expect(scale.options[0], '完全不会');
      expect(scale.options[3], '几乎每天');
    });

    test('Phq9Scale severityCutoffs 5 档 label+summary 走 translations', () {
      const scale = phq9Scale;
      expect(scale.severityCutoffs.length, 5);
      expect(scale.severityCutoffs[0].threshold, 4);
      expect(scale.severityCutoffs[0].label, '几乎没有抑郁');
      expect(scale.severityCutoffs[0].summary, '几乎没有抑郁倾向');
      expect(scale.severityCutoffs[2].label, '中度抑郁');
      expect(scale.severityCutoffs[4].threshold, 27);
    });

    test('Phq9Scale severityCutoffs 走英文 (en)', () {
      final enScale = Phq9Scale(
          translations:
              AppLocalizationsScaleTranslations(AppLocalizationsEn()),);
      expect(enScale.severityCutoffs[0].label, 'None');
      expect(enScale.severityCutoffs[2].label, 'Moderate');
      expect(enScale.severityCutoffs[4].label, 'Severe');
    });

    test('Phq9Scale shortDescription + instruction 走 translations', () {
      const scale = phq9Scale;
      expect(scale.shortDescription, '过去两周的抑郁倾向筛查');
      expect(scale.instruction, '过去两周内，你有多经常被以下问题困扰？');
    });
  });

  group('Gad7Scale.items 走 translations (R78 集成)', () {
    test('const gad7Scale (走 StaticScaleTranslations) 返中文 items', () {
      const scale = gad7Scale;
      expect(scale.items.length, 7);
      expect(scale.items[0].text, '感到紧张、焦虑或急切');
      expect(scale.items[6].text, '感到似乎将有可怕的事情发生而害怕');
    });

    test('Gad7Scale + AppLocalizationsEn → items 走英文', () {
      final enScale = Gad7Scale(
          translations:
              AppLocalizationsScaleTranslations(AppLocalizationsEn()),);
      expect(enScale.items.length, 7);
      expect(enScale.items[0].text, 'Feeling nervous, anxious or on edge');
      expect(enScale.items[6].text,
          'Feeling afraid as if something awful might happen',);
    });

    test('Gad7Scale severityCutoffs 4 档 label+summary 走 translations', () {
      const scale = gad7Scale;
      expect(scale.severityCutoffs.length, 4);
      expect(scale.severityCutoffs[0].threshold, 4);
      expect(scale.severityCutoffs[0].label, '几乎没有焦虑');
      expect(scale.severityCutoffs[3].threshold, 21);
      expect(scale.severityCutoffs[3].label, '重度焦虑');
    });

    test('Gad7Scale severityCutoffs 走英文 (en)', () {
      final enScale = Gad7Scale(
          translations:
              AppLocalizationsScaleTranslations(AppLocalizationsEn()),);
      expect(enScale.severityCutoffs[0].label, 'None');
      expect(enScale.severityCutoffs[3].label, 'Severe');
    });

    test('Gad7Scale options 走 translations.gad7Option', () {
      const scale = gad7Scale;
      expect(scale.options[0], '完全不会');
      expect(scale.options[3], '几乎每天');
    });
  });
}
