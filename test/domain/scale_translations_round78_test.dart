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
//
// v0.32 R112 (AR-17): `AppLocalizationsScaleTranslations` (presentation 810L,
// 0 运行时 caller 死代码) 已删。en/zh 路径锁改直接测 ARB getter
// (AppLocalizationsEn/Zh.phq9Item0 等), 量表名/短描述派发走
// scaleNameL10n 测试 (test/presentation/services/scale_name_l10n_round8_test.dart)。

import 'package:chroniccare/domain/entities/scale_translations.dart';
import 'package:chroniccare/domain/logic/gad7.dart';
import 'package:chroniccare/domain/logic/phq9.dart';
import 'package:chroniccare/l10n/app_localizations_en.dart';
import 'package:chroniccare/l10n/app_localizations_zh.dart';
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

  group('ARB getter (R112 AR-17: en 路径直测 l10n)', () {
    final enL10n = AppLocalizationsEn();

    test('phq9Item 9 题 en 走英文 (≠ 中文 fallback)', () {
      expect(enL10n.phq9Item0, 'Little interest or pleasure in doing things');
      expect(
        enL10n.phq9Item8,
        'Thoughts that you would be better off dead, or of hurting yourself in some way',
      );
    });

    test('phq9Option en 返英文', () {
      expect(enL10n.phq9Option0, 'Not at all');
      expect(enL10n.phq9Option3, 'Nearly every day');
    });

    test('phq9SeverityLabel en 返英文 (clinical 5 档)', () {
      expect(enL10n.phq9SeverityLabel0, 'None');
      expect(enL10n.phq9SeverityLabel1, 'Mild');
      expect(enL10n.phq9SeverityLabel2, 'Moderate');
      expect(enL10n.phq9SeverityLabel3, 'Moderately severe');
      expect(enL10n.phq9SeverityLabel4, 'Severe');
    });

    test('phq9SeveritySummary en 返英文', () {
      expect(enL10n.phq9SeveritySummary2, 'Moderate depression');
    });

    test('phq9Instruction en 返英文', () {
      expect(
        enL10n.phq9Instruction,
        'Over the last 2 weeks, how often have you been bothered by the following problems?',
      );
    });

    test('phq9ShortDescription en 返英文', () {
      expect(
        enL10n.phq9ShortDescription,
        'Depression screening over the last 2 weeks',
      );
    });

    test('gad7Item 7 题 en 返英文 (≠ 中文 fallback)', () {
      expect(enL10n.gad7Item0, 'Feeling nervous, anxious or on edge');
      expect(
        enL10n.gad7Item6,
        'Feeling afraid as if something awful might happen',
      );
    });

    test('gad7SeverityLabel en 4 档返英文', () {
      expect(enL10n.gad7SeverityLabel0, 'None');
      expect(enL10n.gad7SeverityLabel3, 'Severe');
    });

    test('gad7Option en 跟 phq9Option 共享 4 档 (R19 决策)', () {
      expect(enL10n.phq9Option0, 'Not at all');
      expect(enL10n.phq9Option3, 'Nearly every day');
    });
  });

  group('ARB getter (R112 AR-17: zh 路径直测 l10n)', () {
    final zhL10n = AppLocalizationsZh();

    test('phq9Item zh 返中文 (跟 StaticScaleTranslations 等价)', () {
      expect(zhL10n.phq9Item0, '做事时提不起劲或没有兴趣');
      expect(zhL10n.phq9Item8, '有不如死掉或用某种方式伤害自己的念头');
    });

    test('gad7Item zh 返中文', () {
      expect(zhL10n.gad7Item0, '感到紧张、焦虑或急切');
      expect(zhL10n.gad7Item6, '感到似乎将有可怕的事情发生而害怕');
    });

    test('phq9SeverityLabel zh 跟 fallback 等价', () {
      expect(zhL10n.phq9SeverityLabel2, '中度抑郁');
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

    test('Phq9Scale + 自定义 translations (AR-17 本地替身) → items 走英文', () {
      final enScale = Phq9Scale(translations: _EnTranslations(AppLocalizationsEn()));
      expect(enScale.items.length, 9);
      expect(
        enScale.items[0].text,
        'Little interest or pleasure in doing things',
      );
      expect(
        enScale.items[8].text,
        'Thoughts that you would be better off dead, or of hurting yourself in some way',
      );
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

    test('Phq9Scale severityCutoffs 走英文 (en, AR-17 本地替身)', () {
      final enScale = Phq9Scale(
        translations: _EnTranslations(AppLocalizationsEn()),
      );
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

    test('Gad7Scale + 自定义 translations (AR-17 本地替身) → items 走英文', () {
      final enScale = Gad7Scale(
        translations: _EnTranslations(AppLocalizationsEn()),
      );
      expect(enScale.items.length, 7);
      expect(enScale.items[0].text, 'Feeling nervous, anxious or on edge');
      expect(
        enScale.items[6].text,
        'Feeling afraid as if something awful might happen',
      );
    });

    test('Gad7Scale severityCutoffs 4 档 label+summary 走 translations', () {
      const scale = gad7Scale;
      expect(scale.severityCutoffs.length, 4);
      expect(scale.severityCutoffs[0].threshold, 4);
      expect(scale.severityCutoffs[0].label, '几乎没有焦虑');
      expect(scale.severityCutoffs[3].threshold, 21);
      expect(scale.severityCutoffs[3].label, '重度焦虑');
    });

    test('Gad7Scale severityCutoffs 走英文 (en, AR-17 本地替身)', () {
      final enScale = Gad7Scale(
        translations: _EnTranslations(AppLocalizationsEn()),
      );
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

/// v0.32 R112 (AR-17): 本地 en translations 测试替身
///
/// 替代已删除的 `AppLocalizationsScaleTranslations` (presentation 810L 死代码)。
/// 只 override 本文件集成测试用到的 PHQ-9/GAD-7 6 类 method, 走 ARB en getter;
/// 其余 method 走 StaticScaleTranslations 中文 fallback。
class _EnTranslations extends StaticScaleTranslations {
  final AppLocalizationsEn l10n;
  _EnTranslations(this.l10n);

  @override
  String phq9Item(int index, {String? override}) => override ??
      switch (index) {
        0 => l10n.phq9Item0,
        1 => l10n.phq9Item1,
        2 => l10n.phq9Item2,
        3 => l10n.phq9Item3,
        4 => l10n.phq9Item4,
        5 => l10n.phq9Item5,
        6 => l10n.phq9Item6,
        7 => l10n.phq9Item7,
        8 => l10n.phq9Item8,
        _ => '',
      };

  @override
  String phq9Option(int score, {String? override}) => override ??
      switch (score) {
        0 => l10n.phq9Option0,
        1 => l10n.phq9Option1,
        2 => l10n.phq9Option2,
        3 => l10n.phq9Option3,
        _ => '',
      };

  @override
  String phq9SeverityLabel(int rank, {String? override}) => override ??
      switch (rank) {
        0 => l10n.phq9SeverityLabel0,
        1 => l10n.phq9SeverityLabel1,
        2 => l10n.phq9SeverityLabel2,
        3 => l10n.phq9SeverityLabel3,
        4 => l10n.phq9SeverityLabel4,
        _ => '',
      };

  @override
  String gad7Item(int index, {String? override}) => override ??
      switch (index) {
        0 => l10n.gad7Item0,
        1 => l10n.gad7Item1,
        2 => l10n.gad7Item2,
        3 => l10n.gad7Item3,
        4 => l10n.gad7Item4,
        5 => l10n.gad7Item5,
        6 => l10n.gad7Item6,
        _ => '',
      };

  @override
  String gad7SeverityLabel(int rank, {String? override}) => override ??
      switch (rank) {
        0 => l10n.gad7SeverityLabel0,
        1 => l10n.gad7SeverityLabel1,
        2 => l10n.gad7SeverityLabel2,
        3 => l10n.gad7SeverityLabel3,
        _ => '',
      };
}
