// v0.32 round 8 (R112-08 emil + R112-06 emil): mood_label 直接测试 +
// MoodQuickButton 参数化拼接测试
//
// 背景:
// - R111 EM-21 修 en locale 情绪标签显示中文后, mood_label.dart (5 档
//   switch) 一直 0 直接测试 (只有 scale_strings lock-in 顺带扫 ARB)
// - R112-06 moodTodayLabelWithValue 参数化后, MoodQuickButton 拼接行为
//   需要回归锁 (修前 '${moodTodayLabel}${moodLabel(...)}' 硬拼)
//
// 验证:
// 1. moodLabel 5 档 → zh / en 正确标签
// 2. 越界分数 (0 / 6) → fallback moodLabel3 (一般 / Fair)
// 3. MoodQuickButton 今日已记录 → "今日情绪：好" (参数化 key, 无双标签)
// 4. MoodQuickButton 今日未记录 → "记一下情绪 ✏️"

import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/repositories/mood_repository.dart';
import 'package:chroniccare/domain/entities/mood_entry_draft.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/widgets/mood_label.dart';
import 'package:chroniccare/presentation/widgets/mood_quick_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMoodRepository implements MoodRepository {
  final List<MoodEntryEntity> today;
  _FakeMoodRepository(this.today);

  @override
  Stream<List<MoodEntryEntity>> watchAll() => Stream.value(today);

  @override
  Stream<List<MoodEntryEntity>> watchToday() => Stream.value(today);

  @override
  Stream<MoodEntryEntity?> watchLatest() async* {
    yield today.isEmpty ? null : today.first;
  }

  @override
  Future<int> add({required MoodEntryDraft draft}) async =>
      throw UnimplementedError();

  @override
  Future<int> delete(int id) async => throw UnimplementedError();
}

AppLocalizations _l10n(String locale) => lookupAppLocalizations(Locale(locale));

void main() {
  group('mood_label (R112-08 emil)', () {
    test('zh 5 档标签 1:1 映射', () {
      final l10n = _l10n('zh');
      expect(moodLabel(l10n, 1), '很差');
      expect(moodLabel(l10n, 2), '差');
      expect(moodLabel(l10n, 3), '一般');
      expect(moodLabel(l10n, 4), '好');
      expect(moodLabel(l10n, 5), '很好');
    });

    test('en 5 档标签 1:1 映射 (R111 EM-21 回归)', () {
      final l10n = _l10n('en');
      expect(moodLabel(l10n, 1), 'Very bad');
      expect(moodLabel(l10n, 2), 'Bad');
      expect(moodLabel(l10n, 3), 'Fair');
      expect(moodLabel(l10n, 4), 'Good');
      expect(moodLabel(l10n, 5), 'Very good');
    });

    test('越界分数 fallback moodLabel3 (0 / 6 / -1)', () {
      final l10n = _l10n('zh');
      expect(moodLabel(l10n, 0), '一般');
      expect(moodLabel(l10n, 6), '一般');
      expect(moodLabel(l10n, -1), '一般');
    });
  });

  group('MoodQuickButton (R112-06 emil)', () {
    Widget wrap(List<MoodEntryEntity> today, {String locale = 'zh'}) {
      return ProviderScope(
        overrides: [
          moodRepositoryProvider.overrideWithValue(_FakeMoodRepository(today)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale(locale),
          home: Scaffold(
            body: Center(child: MoodQuickButton(onTap: () {})),
          ),
        ),
      );
    }

    MoodEntryEntity entry(int id, int score) => MoodEntryEntity(
          id: id,
          timestamp: DateTime(2026, 8, 14, 9, 30),
          score: score,
          energy: null,
          sleep: null,
          anxiety: null,
          tagsJson: '[]',
          note: null,
          audioPath: null,
          audioTranscript: null,
          audioDurationMs: null,
        );

    testWidgets('今日已记录 → moodTodayLabelWithValue 参数化拼接', (tester) async {
      await tester.pumpWidget(wrap([entry(1, 4)]));
      await tester.pumpAndSettle();

      expect(find.text('今日情绪：好'), findsOneWidget);
      // 修前硬拼 bug: '今日情绪：' + '好' 会拆成 2 个 Text 才拼对,
      // 参数化后单 Text 内完整串
      expect(find.text('今日情绪：'), findsNothing);
    });

    testWidgets('今日未记录 → moodRecordButton', (tester) async {
      await tester.pumpWidget(wrap(const []));
      await tester.pumpAndSettle();

      expect(find.text('记一下情绪 ✏️'), findsOneWidget);
    });

    testWidgets('en locale 已记录 → "Mood: Good" (无尾随空格漂移)', (tester) async {
      await tester.pumpWidget(wrap([entry(1, 4)], locale: 'en'));
      await tester.pumpAndSettle();

      expect(find.text('Mood: Good'), findsOneWidget);
    });
  });
}
