// v0.30 round 85 (CBT 重评效果图): provider 单元测试
//
// 3 个 case:
// 1. 3 栏 entries (cbtLevel null) 过滤掉, 只返回 5/7 栏
// 2. 7 栏 entries (coreBelief/behaviorResponse 非空) 也返回
// 3. 空 list 返回空
//
// 测试通过 `moodEntriesProvider.overrideWith` 直接注入 sync list,
// 跳过 allMoodProvider (StreamProvider), 走 provider 纯过滤逻辑。

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/presentation/providers/cbt_rerated_entries_provider.dart';

void main() {
  group('cbtReratedEntriesProvider (v0.30 round 85)', () {
    test('过滤 3 栏 entries (cbtLevel null), 只返回 5/7 栏', () {
      final container = ProviderContainer(
        overrides: [
          moodEntriesProvider.overrideWith((ref) => [
            MoodEntryEntity(
              id: 1,
              timestamp: DateTime(2026, 8, 1),
              score: 3,
              note: '3-栏',
            ),
            MoodEntryEntity(
              id: 2,
              timestamp: DateTime(2026, 8, 2),
              score: 4,
              situation: 's',
              automaticThought: 'at',
              evidenceFor: 'ef',
              evidenceAgainst: 'ea',
              alternativeThought: 'alt',
              reratedScore: 3,
            ),
          ],),
        ],
      );
      addTearDown(container.dispose);
      final result = container.read(cbtReratedEntriesProvider);
      expect(result.length, 1);
      expect(result[0].id, 2);
    });

    test('7 栏 entries 也返回', () {
      final container = ProviderContainer(
        overrides: [
          moodEntriesProvider.overrideWith((ref) => [
            MoodEntryEntity(
              id: 1,
              timestamp: DateTime(2026, 8, 1),
              score: 2,
              situation: 's',
              automaticThought: 'at',
              evidenceFor: 'ef',
              evidenceAgainst: 'ea',
              alternativeThought: 'alt',
              reratedScore: 4,
              coreBelief: 'cb',
              behaviorResponse: 'br',
            ),
          ],),
        ],
      );
      addTearDown(container.dispose);
      final result = container.read(cbtReratedEntriesProvider);
      expect(result.length, 1);
      expect(result.first.id, 1);
    });

    test('空 list 返回空', () {
      final container = ProviderContainer(
        overrides: [
          moodEntriesProvider.overrideWith((ref) => <MoodEntryEntity>[]),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(cbtReratedEntriesProvider), isEmpty);
    });
  });
}
