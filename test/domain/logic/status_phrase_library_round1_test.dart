// test/domain/logic/status_phrase_library_round1_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/domain/logic/status_phrase_library.dart';

void main() {
  group('StatusPhraseLibrary', () {
    test('4 组短语非空且不重复', () {
      for (final group in [
        StatusPhraseLibrary.low,
        StatusPhraseLibrary.tired,
        StatusPhraseLibrary.calm,
        StatusPhraseLibrary.positive,
      ]) {
        expect(group.length, greaterThanOrEqualTo(4));
        expect(group.toSet().length, group.length);
        for (final p in group) {
          expect(p.trim().isEmpty, isFalse);
        }
      }
    });

    test('all = 4 组拼接', () {
      expect(StatusPhraseLibrary.all, [
        ...StatusPhraseLibrary.low,
        ...StatusPhraseLibrary.tired,
        ...StatusPhraseLibrary.calm,
        ...StatusPhraseLibrary.positive,
      ]);
    });

    test('phrasesForScore 分组规则', () {
      expect(StatusPhraseLibrary.phrasesForScore(1),
          [...StatusPhraseLibrary.low, ...StatusPhraseLibrary.tired]);
      expect(StatusPhraseLibrary.phrasesForScore(2),
          [...StatusPhraseLibrary.low, ...StatusPhraseLibrary.tired]);
      expect(StatusPhraseLibrary.phrasesForScore(3),
          StatusPhraseLibrary.calm);
      expect(StatusPhraseLibrary.phrasesForScore(4),
          StatusPhraseLibrary.positive);
      expect(StatusPhraseLibrary.phrasesForScore(5),
          StatusPhraseLibrary.positive);
    });
  });
}
