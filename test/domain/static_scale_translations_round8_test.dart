// v0.32 round 8 (R111 SP-111-04 fix): static_scale_translations 8 新量表 0 直接断言
//
// 背景: round78 只断言 PHQ-9 / GAD-7 经 translations 的中文, domain 层 8 新
// 量表 (ISI / PSS / WHODAS / Level2 抑郁 / 焦虑 / 躁狂 / 精神病性 / ASRM) 的
// 中文 items / options / severity 从没被直接断言 (最大 0-test 块)。
//
// 断言策略: 不重复抄题面, 而是"一致性断言" — 每个量表 const class 的
// items / options / severityCutoffs 必须跟 StaticScaleTranslations 的
// xxxItem / xxxOption / xxxSeverityLabel / xxxSeveritySummary 1:1 一致
// (非空, 无 '' stub)。改任一处的题面/严重度档名, 另一处不同步 → 测试红,
// 防 2026 年"重构量表题目 / 严重度档名时忘记同步翻译"。
//
// 另覆盖: 越界 → '' / override 参数优先 / name/shortDescription/instruction
// 非空 (无 stub)。
import 'package:chroniccare/domain/entities/scale_translations.dart';
import 'package:chroniccare/domain/logic/assessment_scale.dart';
import 'package:chroniccare/domain/logic/asrm.dart';
import 'package:chroniccare/domain/logic/isi.dart';
import 'package:chroniccare/domain/logic/level2_anxiety.dart';
import 'package:chroniccare/domain/logic/level2_depression.dart';
import 'package:chroniccare/domain/logic/level2_mania.dart';
import 'package:chroniccare/domain/logic/level2_psychosis.dart';
import 'package:chroniccare/domain/logic/pss.dart';
import 'package:chroniccare/domain/logic/whodas.dart';
import 'package:flutter_test/flutter_test.dart';

const t = StaticScaleTranslations();

void main() {
  group('v0.32 round 8 (SP-111-04) — 8 新量表 translations 一致性', () {
    const scales = <AssessmentScale>[
      IsiScale(),
      PssScale(),
      WhodasScale(),
      Level2DepressionScale(),
      Level2AnxietyScale(),
      Level2ManiaScale(),
      Level2PsychosisScale(),
      AsrmScale(),
    ];

    for (final scale in scales) {
      final id = scale.id;
      test('$id — items 与 const class 1:1 (非空, 无 stub)', () {
        for (final item in scale.items) {
          final translated = switch (id) {
            'isi' => t.isiItem(item.index),
            'pss' => t.pssItem(item.index),
            'whodas' => t.whodasItem(item.index),
            'level2_depression' => t.level2DepressionItem(item.index),
            'level2_anxiety' => t.level2AnxietyItem(item.index),
            'level2_mania' => t.level2ManiaItem(item.index),
            'level2_psychosis' => t.level2PsychosisItem(item.index),
            'asrm' => t.asrmItem(item.index),
            _ => fail('unknown scale $id'),
          };
          expect(translated, item.text,
              reason: '$id item ${item.index} 翻译与 const class 不一致',);
          expect(translated, isNotEmpty,
              reason: '$id item ${item.index} 是空 stub',);
        }
      });

      test('$id — options 与 const class 1:1', () {
        scale.options.forEach((score, text) {
          final translated = switch (id) {
            'isi' => t.isiOption(score),
            'pss' => t.pssOption(score),
            'whodas' => t.whodasOption(score),
            'level2_depression' => t.level2DepressionOption(score),
            'level2_anxiety' => t.level2AnxietyOption(score),
            'level2_mania' => t.level2ManiaOption(score),
            'level2_psychosis' => t.level2PsychosisOption(score),
            'asrm' => t.asrmOption(score),
            _ => fail('unknown scale $id'),
          };
          expect(translated, text,
              reason: '$id option $score 翻译与 const class 不一致',);
        });
      });

      test('$id — severity label / summary 与 cutoffs 1:1', () {
        for (final cutoff in scale.severityCutoffs) {
          final label = switch (id) {
            'isi' => t.isiSeverityLabel(cutoff.rank),
            'pss' => t.pssSeverityLabel(cutoff.rank),
            'whodas' => t.whodasSeverityLabel(cutoff.rank),
            'level2_depression' => t.level2DepressionSeverityLabel(cutoff.rank),
            'level2_anxiety' => t.level2AnxietySeverityLabel(cutoff.rank),
            'level2_mania' => t.level2ManiaSeverityLabel(cutoff.rank),
            'level2_psychosis' => t.level2PsychosisSeverityLabel(cutoff.rank),
            'asrm' => t.asrmSeverityLabel(cutoff.rank),
            _ => fail('unknown scale $id'),
          };
          final summary = switch (id) {
            'isi' => t.isiSeveritySummary(cutoff.rank),
            'pss' => t.pssSeveritySummary(cutoff.rank),
            'whodas' => t.whodasSeveritySummary(cutoff.rank),
            'level2_depression' =>
              t.level2DepressionSeveritySummary(cutoff.rank),
            'level2_anxiety' => t.level2AnxietySeveritySummary(cutoff.rank),
            'level2_mania' => t.level2ManiaSeveritySummary(cutoff.rank),
            'level2_psychosis' => t.level2PsychosisSeveritySummary(cutoff.rank),
            'asrm' => t.asrmSeveritySummary(cutoff.rank),
            _ => fail('unknown scale $id'),
          };
          expect(label, cutoff.label,
              reason: '$id rank ${cutoff.rank} label 不一致',);
          expect(summary, cutoff.summary,
              reason: '$id rank ${cutoff.rank} summary 不一致',);
          expect(label, isNotEmpty, reason: '$id rank ${cutoff.rank} label 空');
          expect(summary, isNotEmpty,
              reason: '$id rank ${cutoff.rank} summary 空',);
        }
      });

      test('$id — name / shortDescription / instruction 非空', () {
        final (name, desc, instr) = switch (id) {
          'isi' => (t.isiName(), t.isiShortDescription(), t.isiInstruction()),
          'pss' => (t.pssName(), t.pssShortDescription(), t.pssInstruction()),
          'whodas' => (
              t.whodasName(),
              t.whodasShortDescription(),
              t.whodasInstruction()
            ),
          'level2_depression' => (
              t.level2DepressionName(),
              t.level2DepressionShortDescription(),
              t.level2DepressionInstruction()
            ),
          'level2_anxiety' => (
              t.level2AnxietyName(),
              t.level2AnxietyShortDescription(),
              t.level2AnxietyInstruction()
            ),
          'level2_mania' => (
              t.level2ManiaName(),
              t.level2ManiaShortDescription(),
              t.level2ManiaInstruction()
            ),
          'level2_psychosis' => (
              t.level2PsychosisName(),
              t.level2PsychosisShortDescription(),
              t.level2PsychosisInstruction()
            ),
          'asrm' => (t.asrmName(), t.asrmShortDescription(), t.asrmInstruction()),
          _ => fail('unknown scale $id'),
        };
        expect(name, isNotEmpty, reason: '$id name 空');
        expect(desc, isNotEmpty, reason: '$id shortDescription 空');
        expect(instr, isNotEmpty, reason: '$id instruction 空');
      });
    }
  });

  group('v0.32 round 8 (SP-111-04) — 边界 + override', () {
    test('越界 item → \'\'', () {
      expect(t.isiItem(-1), '');
      expect(t.isiItem(7), '');
      expect(t.pssItem(10), '');
      expect(t.asrmItem(99), '');
      expect(t.level2PsychosisItem(-5), '');
    });

    test('option 不存在 → \'\'', () {
      expect(t.isiOption(5), '');
      expect(t.whodasOption(99), '');
      expect(t.level2ManiaOption(-1), '');
    });

    test('severity 越界 → \'\'', () {
      expect(t.pssSeverityLabel(3), '');
      expect(t.asrmSeveritySummary(-1), '');
      expect(t.level2DepressionSeverityLabel(99), '');
    });

    test('override 参数优先 (R57 契约)', () {
      expect(t.isiItem(0, override: '自定义题面'), '自定义题面');
      expect(t.pssName(override: '英文名'), '英文名');
      expect(t.asrmSeverityLabel(0, override: 'override'), 'override');
    });
  });
}
