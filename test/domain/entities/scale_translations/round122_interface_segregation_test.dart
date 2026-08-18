// v1.1.0+168 R122 P2-3 (R121 P1-3 step 3 续) — 10 量表 sub-interface
// (Interface Segregation Principle) 拆分验证
//
// Goal: 10 量表 class implements 各自 sub-interface, caller 可直接用
// sub-interface 跳过 70 委派链 (老 caller 走 StaticScaleTranslations 仍工作)。
//
// 验证 4 类:
//
//   1. _scale_translations_interfaces.dart 存在 + 10 sub-interface 全列
//   2. 10 量表 class `implements` 各自 sub-interface (代码检查)
//   3. 10 量表 class 7 method 全部 @override 注解 (sub-interface 满足)
//   4. sub-interface public API 跟主壳 StaticScaleTranslations 输出完全一致
//      (caller 跳过 70 委派链可行)
//
// Functional correctness: R118 round118_direct_test.dart 42 case + 主壳
// round 8 test 验证委派链一致性, 本 test 验证 sub-interface 独立可用性。

import 'dart:io';

import 'package:chroniccare/domain/entities/scale_translations.dart';
import 'package:chroniccare/domain/entities/scale_translations/_scale_translations_interfaces.dart';
import 'package:chroniccare/domain/entities/scale_translations/gad7_translations.dart';
import 'package:chroniccare/domain/entities/scale_translations/isi_translations.dart';
import 'package:chroniccare/domain/entities/scale_translations/level2_depression_translations.dart';
import 'package:chroniccare/domain/entities/scale_translations/phq9_translations.dart';
import 'package:chroniccare/domain/entities/scale_translations/whodas_translations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const interfacesPath =
      'lib/domain/entities/scale_translations/_scale_translations_interfaces.dart';

  group('R122 P2-3 — 10 sub-interface 拆分 (Interface Segregation)', () {
    test('sub-interface 文件存在', () {
      expect(File(interfacesPath).existsSync(), isTrue,
          reason: '应新建 _scale_translations_interfaces.dart 集中 10 sub-interface');
    });

    test('10 sub-interface 全列 (Phq9..Asrm × 10)', () {
      final content = File(interfacesPath).readAsStringSync();
      for (final name in [
        'Phq9TranslationsInterface',
        'Gad7TranslationsInterface',
        'IsiTranslationsInterface',
        'PssTranslationsInterface',
        'WhodasTranslationsInterface',
        'Level2DepressionTranslationsInterface',
        'Level2AnxietyTranslationsInterface',
        'Level2ManiaTranslationsInterface',
        'Level2PsychosisTranslationsInterface',
        'AsrmTranslationsInterface',
      ]) {
        expect(content.contains('abstract class $name'), isTrue,
            reason: 'sub-interface $name 应在 $interfacesPath 声明');
      }
    });

    test('10 量表 class implements 各自 sub-interface', () {
      // 验证每个量表文件含 `implements XxxTranslationsInterface`
      final pairs = [
        ('phq9_translations.dart', 'Phq9TranslationsInterface'),
        ('gad7_translations.dart', 'Gad7TranslationsInterface'),
        ('isi_translations.dart', 'IsiTranslationsInterface'),
        ('pss_translations.dart', 'PssTranslationsInterface'),
        ('whodas_translations.dart', 'WhodasTranslationsInterface'),
        ('level2_depression_translations.dart', 'Level2DepressionTranslationsInterface'),
        ('level2_anxiety_translations.dart', 'Level2AnxietyTranslationsInterface'),
        ('level2_mania_translations.dart', 'Level2ManiaTranslationsInterface'),
        ('level2_psychosis_translations.dart', 'Level2PsychosisTranslationsInterface'),
        ('asrm_translations.dart', 'AsrmTranslationsInterface'),
      ];
      for (final (filename, interface) in pairs) {
        final path = 'lib/domain/entities/scale_translations/$filename';
        final content = File(path).readAsStringSync();
        expect(
          content.contains('implements $interface'),
          isTrue,
          reason: '$filename 应 implements $interface (R122 P2-3 interface segregation)',
        );
      }
    });

    test('10 量表 7 method 全部 @override 注解 (sub-interface 满足)', () {
      // 验证每个量表 7 method (Name/ShortDescription/Instruction/Item/Option/
      // SeverityLabel/SeveritySummary) 全部带 @override
      final methodPrefixes = [
        'phq9',
        'gad7',
        'isi',
        'pss',
        'whodas',
        'level2Depression',
        'level2Anxiety',
        'level2Mania',
        'level2Psychosis',
        'asrm',
      ];
      final suffixes = [
        'Name',
        'ShortDescription',
        'Instruction',
        'Item',
        'Option',
        'SeverityLabel',
        'SeveritySummary',
      ];
      for (final prefix in methodPrefixes) {
        // 文件名 (snake_case, level2_depression 拆分有下划线)
        final filename = prefix == 'phq9'
            ? 'phq9_translations.dart'
            : prefix == 'gad7'
                ? 'gad7_translations.dart'
                : '${prefix.replaceAllMapped(RegExp(r'([A-Z])'), (m) => '_${m[0]!.toLowerCase()}')}_translations.dart';
        final path = 'lib/domain/entities/scale_translations/$filename';
        final content = File(path).readAsStringSync();
        for (final suffix in suffixes) {
          final methodName = '$prefix$suffix';
          // 找 @override 行 + method 名行
          final lines = content.split('\n');
          var foundOverride = false;
          for (var i = 0; i < lines.length - 1; i++) {
            if (lines[i].trim() == '@override' &&
                lines[i + 1].contains(methodName)) {
              foundOverride = true;
              break;
            }
          }
          expect(
            foundOverride,
            isTrue,
            reason: '$filename 应有 @override + $methodName method',
          );
        }
      }
    });
  });

  group('R122 P2-3 — sub-interface 跟主壳输出一致 (caller 可跳过 70 委派)', () {
    // 验证: 通过 sub-interface 调用的输出 == 通过主壳 StaticScaleTranslations 调用
    // 1 行断言即可证明 caller 可绕过主壳。

    test('PHQ-9: sub-interface vs 主壳 输出一致', () {
      const sub = Phq9Translations();
      const main = StaticScaleTranslations();
      // 7 method
      expect(sub.phq9Name(), main.phq9Name());
      expect(sub.phq9ShortDescription(), main.phq9ShortDescription());
      expect(sub.phq9Instruction(), main.phq9Instruction());
      expect(sub.phq9Item(0), main.phq9Item(0));
      expect(sub.phq9Option(0), main.phq9Option(0));
      expect(sub.phq9SeverityLabel(0), main.phq9SeverityLabel(0));
      expect(sub.phq9SeveritySummary(0), main.phq9SeveritySummary(0));
    });

    test('GAD-7: sub-interface vs 主壳 输出一致 (含 4 档频率选项共享)', () {
      const sub = Gad7Translations();
      const main = StaticScaleTranslations();
      expect(sub.gad7Name(), main.gad7Name());
      expect(sub.gad7ShortDescription(), main.gad7ShortDescription());
      expect(sub.gad7Instruction(), main.gad7Instruction());
      expect(sub.gad7Item(0), main.gad7Item(0));
      expect(sub.gad7Option(0), main.gad7Option(0));
      expect(sub.gad7SeverityLabel(0), main.gad7SeverityLabel(0));
      expect(sub.gad7SeveritySummary(0), main.gad7SeveritySummary(0));
    });

    test('ISI: sub-interface vs 主壳 输出一致', () {
      const sub = IsiTranslations();
      const main = StaticScaleTranslations();
      expect(sub.isiName(), main.isiName());
      expect(sub.isiItem(0), main.isiItem(0));
      expect(sub.isiOption(0), main.isiOption(0));
    });

    test('WHODAS: sub-interface vs 主壳 输出一致', () {
      const sub = WhodasTranslations();
      const main = StaticScaleTranslations();
      expect(sub.whodasName(), main.whodasName());
      expect(sub.whodasItem(0), main.whodasItem(0));
    });

    test('Level2 Depression: sub-interface vs 主壳 输出一致', () {
      const sub = Level2DepressionTranslations();
      const main = StaticScaleTranslations();
      expect(sub.level2DepressionName(), main.level2DepressionName());
      expect(sub.level2DepressionItem(0), main.level2DepressionItem(0));
    });

    test('sub-interface 边界: 越界 → "" (跟主壳一致)', () {
      const phq9 = Phq9Translations();
      expect(phq9.phq9Item(999), '', reason: '越界应返空字符串');
      expect(phq9.phq9Item(-1), '', reason: '负 index 应返空字符串');
      expect(phq9.phq9SeverityLabel(999), '', reason: '越界 rank 应返空字符串');
    });

    test('sub-interface 类型可独立使用 (caller 跳过 70 委派)', () {
      // 验证: Phq9TranslationsInterface 类型可作为类型签名 (caller 写
      // `Phq9TranslationsInterface phq9 = Phq9Translations();`)
      const Phq9TranslationsInterface phq9 = Phq9Translations();
      expect(phq9.phq9Name(), 'PHQ-9 情绪自测');
      expect(phq9.phq9Item(0), isNotEmpty);
    });
  });
}
