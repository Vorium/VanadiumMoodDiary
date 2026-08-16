// 1.1.0 round 9 (论文落地 F3 心理技巧知识库): 心理技巧 l10n 映射测试
//
// 覆盖:
// 1. zh: canonical 中文原样 (title/summary/steps)
// 2. en: 5 条技巧全英文映射
// 3. 未知 id → 原样透传
//
// 策略跟 preset_content_l10n_round7_test.dart 一致: MaterialApp + l10n
// delegates 拿真实 ARB 文案, pump probe Text 拿 BuildContext。

import 'package:chroniccare/domain/logic/psychology_tips_library.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/l10n/preset_content_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<BuildContext> _pumpLocale(WidgetTester tester, Locale locale) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: Text('probe')),
    ),
  );
  return tester.element(find.text('probe'));
}

/// en 期望映射 (跟 app_en.arb 逐条对齐, 防 ARB 漂移)
const Map<String, List<String>> _enExpect = {
  'mindfulBreathing': [
    'Mindful breathing',
    'Anchor yourself in the present by focusing on your breath',
    'Sit somewhere comfortable and gently close your eyes',
    'Breathe in for 4 seconds, feeling the air fill your body',
    'Hold your breath for 2 seconds',
    'Exhale slowly for 6 seconds, relaxing your shoulders and body',
    'Repeat for 3-5 minutes, keeping your attention on your breath',
  ],
  'nameEmotion': [
    'Name the emotion',
    'Naming an emotion reduces its intensity',
    'Pause and notice how your body is reacting',
    'Ask yourself: what emotion am I feeling right now',
    'Describe it in one word, like "irritated", "sad" or "anxious"',
    'Say it or write it down: "I feel…"',
    'Watch how the emotion shifts, without judging it',
  ],
  'cognitiveReframing': [
    'Cognitive reframing',
    'Identify and adjust unhelpful automatic thoughts — pairs well with CBT records',
    'Write down the specific situation that triggered the feeling',
    'Record the automatic thought that came to mind',
    'List the evidence for and against this thought',
    'Write a more balanced, fact-based alternative thought',
    'Practice with a 5-column CBT record in your mood diary',
  ],
  'grounding54321': [
    '5-4-3-2-1 grounding',
    'Use your five senses to return to the present and step back from anxiety',
    'Name 5 things you can see',
    'Notice 4 things you can touch',
    'Listen for 3 sounds you can hear',
    'Notice 2 smells around you',
    'Feel 1 taste in your mouth',
  ],
  'progressiveMuscleRelaxation': [
    'Progressive muscle relaxation',
    'Release physical tension by tensing and relaxing muscle groups',
    'Sit or lie down in a comfortable position',
    'Starting with your toes, tense them tightly for 5 seconds',
    'Release and enjoy the relaxed feeling for about 10 seconds',
    'Move upward: calves, thighs, belly, arms, shoulders',
    'Finish by relaxing your face and scalp for a full-body scan',
  ],
};

void main() {
  const zh = Locale('zh');
  const en = Locale('en');

  group('localizedPsychologyTip', () {
    testWidgets('zh: canonical 中文原样 (全 5 条)', (tester) async {
      final ctx = await _pumpLocale(tester, zh);
      for (final tip in PsychologyTipsLibrary.all) {
        final localized = localizedPsychologyTip(ctx, tip);
        expect(localized.title, tip.title, reason: '${tip.id} zh title');
        expect(localized.summary, tip.summary, reason: '${tip.id} zh summary');
        expect(localized.steps, tip.steps, reason: '${tip.id} zh steps');
      }
    });

    testWidgets('en: 5 条技巧全英文映射 (含每步)', (tester) async {
      final ctx = await _pumpLocale(tester, en);
      for (final tip in PsychologyTipsLibrary.all) {
        final expectList = _enExpect[tip.id]!;
        final localized = localizedPsychologyTip(ctx, tip);
        expect(localized.title, expectList[0], reason: '${tip.id} en title');
        expect(localized.summary, expectList[1],
            reason: '${tip.id} en summary');
        expect(
          localized.steps,
          expectList.sublist(2),
          reason: '${tip.id} en steps',
        );
      }
    });

    testWidgets('未知 id → 原样透传 canonical (zh + en)', (tester) async {
      const fake = PsychologyTip(
        id: 'custom',
        title: '自定义技巧',
        summary: '自定义摘要',
        steps: ['步骤一', '步骤二'],
      );
      final zhCtx = await _pumpLocale(tester, zh);
      final zhLocalized = localizedPsychologyTip(zhCtx, fake);
      expect(zhLocalized.title, '自定义技巧');
      expect(zhLocalized.summary, '自定义摘要');
      expect(zhLocalized.steps, ['步骤一', '步骤二']);

      final enCtx = await _pumpLocale(tester, en);
      final enLocalized = localizedPsychologyTip(enCtx, fake);
      expect(enLocalized.title, '自定义技巧', reason: '未知 id 不透传英文');
    });
  });
}
