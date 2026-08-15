// 1.1.0 round 7b (P1 i18n): preset_content_l10n.dart helper 测试
//
// 覆盖:
// 1. 8 个树洞预设标签 zh (canonical 原样) / en (英文) 映射
// 2. 自定义标签透传 (zh + en 都原样返回)
// 3. 17 条状态短语 zh / en 映射 (按 StatusPhraseLibrary 组顺序)
// 4. 自定义短语透传
// 5. 5 个 tier → 鼓励文案 (zh / en)
// 6. widget 测试: en locale 下 VentTagPicker chip 显示英文 (存储仍传 canonical)
//
// 测试策略: MaterialApp + l10n delegates 拿真实 ARB 文案 (不 mock),
// helper 需要 BuildContext → pump probe Text 拿 element。

import 'package:chroniccare/domain/logic/mood_review_aggregator.dart';
import 'package:chroniccare/domain/logic/status_phrase_library.dart';
import 'package:chroniccare/domain/logic/vent_tag_library.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/l10n/preset_content_l10n.dart';
import 'package:chroniccare/presentation/pages/vent/widgets/vent_tag_picker.dart';
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

void main() {
  const zh = Locale('zh');
  const en = Locale('en');

  const enTags = [
    'Family',
    'Work',
    'Study',
    'Relationship',
    'Friends',
    'Health',
    'Mood',
    'Other',
  ];

  const enPhrases = [
    // low
    'A little sad',
    'Feeling really down',
    'Feel like crying',
    'No energy',
    // tired
    'Tired but calm',
    'So tired',
    'Drained',
    'Just want to lie down',
    // calm
    'Calm',
    'At ease',
    'Mellow',
    'Nothing special',
    // positive
    'Feeling healed',
    'Feeling good',
    'Full of energy',
    'Hopeful',
    'Very happy',
  ];

  group('localizedVentTag (8 预设)', () {
    testWidgets('zh: canonical 中文原样', (tester) async {
      final ctx = await _pumpLocale(tester, zh);
      for (var i = 0; i < VentTagLibrary.presetTags.length; i++) {
        final tag = VentTagLibrary.presetTags[i];
        expect(
          localizedVentTag(ctx, tag),
          tag,
          reason: 'zh locale 下 $tag 应走 ARB (值 = canonical)',
        );
      }
    });

    testWidgets('en: 英文映射', (tester) async {
      final ctx = await _pumpLocale(tester, en);
      for (var i = 0; i < VentTagLibrary.presetTags.length; i++) {
        expect(
          localizedVentTag(ctx, VentTagLibrary.presetTags[i]),
          enTags[i],
          reason: 'en locale 下 ${VentTagLibrary.presetTags[i]} 应显示英文',
        );
      }
    });

    testWidgets('自定义标签透传 (zh + en)', (tester) async {
      final zhCtx = await _pumpLocale(tester, zh);
      expect(localizedVentTag(zhCtx, '考研压力'), '考研压力');
      final enCtx = await _pumpLocale(tester, en);
      expect(localizedVentTag(enCtx, '考研压力'), '考研压力');
    });
  });

  group('localizedStatusPhrase (17 预设)', () {
    testWidgets('zh: canonical 中文原样 (全 17 条)', (tester) async {
      final ctx = await _pumpLocale(tester, zh);
      for (final phrase in StatusPhraseLibrary.all) {
        expect(
          localizedStatusPhrase(ctx, phrase),
          phrase,
          reason: 'zh locale 下 $phrase 应走 ARB (值 = canonical)',
        );
      }
    });

    testWidgets('en: 英文映射 (全 17 条)', (tester) async {
      final ctx = await _pumpLocale(tester, en);
      for (var i = 0; i < StatusPhraseLibrary.all.length; i++) {
        expect(
          localizedStatusPhrase(ctx, StatusPhraseLibrary.all[i]),
          enPhrases[i],
          reason: 'en locale 下 ${StatusPhraseLibrary.all[i]} 应显示英文',
        );
      }
    });

    testWidgets('自定义短语透传 (zh + en)', (tester) async {
      final zhCtx = await _pumpLocale(tester, zh);
      expect(localizedStatusPhrase(zhCtx, '自定义一句'), '自定义一句');
      final enCtx = await _pumpLocale(tester, en);
      expect(localizedStatusPhrase(enCtx, '自定义一句'), '自定义一句');
    });
  });

  group('localizedEncouragement (5 tier)', () {
    const zhTexts = {
      MoodReviewEncouragementTier.empty: '这周还没记录心情，从现在开始吧',
      MoodReviewEncouragementTier.low: '最近有些辛苦，记得照顾自己',
      MoodReviewEncouragementTier.mid: '情绪有起伏，倾诉会好受些',
      MoodReviewEncouragementTier.high: '状态不错，继续保持',
      MoodReviewEncouragementTier.noAvg: '继续记录，慢慢了解自己的情绪',
    };
    const enTexts = {
      MoodReviewEncouragementTier.empty:
          "Haven't recorded your mood this week — start now",
      MoodReviewEncouragementTier.low:
          "It's been a rough time — take care of yourself",
      MoodReviewEncouragementTier.mid:
          'Moods have been up and down — venting may help',
      MoodReviewEncouragementTier.high: "You're doing well — keep it up",
      MoodReviewEncouragementTier.noAvg:
          'Keep logging to better understand your emotions',
    };

    testWidgets('zh: 5 tier 全映射', (tester) async {
      final ctx = await _pumpLocale(tester, zh);
      for (final e in MoodReviewEncouragementTier.values) {
        expect(localizedEncouragement(ctx, e), zhTexts[e]);
      }
    });

    testWidgets('en: 5 tier 全映射', (tester) async {
      final ctx = await _pumpLocale(tester, en);
      for (final e in MoodReviewEncouragementTier.values) {
        expect(localizedEncouragement(ctx, e), enTexts[e]);
      }
    });

    test('tier enum 恰 5 值 (empty/low/mid/high/noAvg)', () {
      expect(
        MoodReviewEncouragementTier.values.map((e) => e.name).toList(),
        ['empty', 'low', 'mid', 'high', 'noAvg'],
      );
    });
  });

  group('VentTagPicker en locale widget', () {
    testWidgets('en: chip 显示英文, onChanged 仍传 canonical 中文', (tester) async {
      Set<String>? received;
      await tester.pumpWidget(
        MaterialApp(
          locale: en,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: VentTagPicker(
              selected: const {},
              onChanged: (next) => received = next,
            ),
          ),
        ),
      );

      for (final label in enTags) {
        expect(find.text(label), findsOneWidget, reason: 'en chip 应显示 $label');
      }
      expect(find.text('家庭'), findsNothing, reason: 'en locale 不应显示中文预设');

      await tester.tap(find.text('Family'));
      await tester.pump();
      expect(received, {'家庭'}, reason: 'onChanged 仍传 canonical (存储兼容)');
    });
  });
}
