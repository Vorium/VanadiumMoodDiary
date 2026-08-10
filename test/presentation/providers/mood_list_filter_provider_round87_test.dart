// v0.30 round 87 (sub-spec 3 mood 列表页): filter + search + sort 单元测试
//
// 4 个 case:
// 1. 默认无 filter: 5 条全部, 时间倒序
// 2. search "难" 过滤 → 1 条 (id=2)
// 3. cbtLevel=5 filter → 1 条 (id=3)
// 4. sort score asc → 5 条 score 1, 2, 3, 4, 5
//
// 测试通过 `moodEntriesProvider.overrideWith` 直接注入 sync list,
// 跳过 allMoodProvider (StreamProvider), 走 provider 纯过滤逻辑。

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/presentation/providers/cbt_rerated_entries_provider.dart';
import 'package:chroniccare/presentation/providers/mood_list_filter_provider.dart';

void main() {
  // 5 条 mood entries: 3 栏 + 5 栏 + 7 栏 混合
  // id=1: 3 栏 (note='开心')
  // id=2: 3 栏 (note='难受')
  // id=3: 5 栏 (note='一般', situation/automaticThought/.../reratedScore 非空)
  // id=4: 3 栏 (note='OK')
  // id=5: 7 栏 (note='差', 含 coreBelief + behaviorResponse)
  List<MoodEntryEntity> makeEntries() => [
        MoodEntryEntity(
          id: 1,
          timestamp: DateTime(2026, 8, 5),
          score: 5,
          note: '开心',
        ),
        MoodEntryEntity(
          id: 2,
          timestamp: DateTime(2026, 8, 4),
          score: 2,
          note: '难受',
        ),
        MoodEntryEntity(
          id: 3,
          timestamp: DateTime(2026, 8, 3),
          score: 3,
          note: '一般',
          situation: 's',
          automaticThought: 'at',
          evidenceFor: 'ef',
          evidenceAgainst: 'ea',
          alternativeThought: 'alt',
          reratedScore: 4, // cbtLevel = 5
        ),
        MoodEntryEntity(
          id: 4,
          timestamp: DateTime(2026, 8, 2),
          score: 4,
          note: 'OK',
        ),
        MoodEntryEntity(
          id: 5,
          timestamp: DateTime(2026, 8, 1),
          score: 1,
          note: '差',
          situation: 's',
          automaticThought: 'at',
          evidenceFor: 'ef',
          evidenceAgainst: 'ea',
          alternativeThought: 'alt',
          reratedScore: 3,
          coreBelief: 'cb',
          behaviorResponse: 'br', // cbtLevel = 7
        ),
      ];

  group('filteredMoodEntriesProvider (v0.30 round 87)', () {
    test('默认无 filter: 5 条全部, 时间倒序', () {
      final container = ProviderContainer(
        overrides: [
          moodEntriesProvider.overrideWith((ref) => makeEntries()),
        ],
      );
      addTearDown(container.dispose);
      final result = container.read(filteredMoodEntriesProvider);
      expect(result.length, 5);
      expect(result[0].id, 1); // 最新在前面
      expect(result[4].id, 5); // 最旧在最后
    });

    test('search "难" 过滤 → 1 条 (id=2)', () {
      final container = ProviderContainer(
        overrides: [
          moodEntriesProvider.overrideWith((ref) => makeEntries()),
        ],
      );
      addTearDown(container.dispose);
      // 设置 search query
      container.read(moodListFilterProvider.notifier).setSearchQuery('难');
      final result = container.read(filteredMoodEntriesProvider);
      expect(result.length, 1);
      expect(result.first.id, 2);
    });

    test('cbtLevel=5 filter → 1 条 (id=3)', () {
      final container = ProviderContainer(
        overrides: [
          moodEntriesProvider.overrideWith((ref) => makeEntries()),
        ],
      );
      addTearDown(container.dispose);
      container.read(moodListFilterProvider.notifier).setCbtLevel(5);
      final result = container.read(filteredMoodEntriesProvider);
      expect(result.length, 1);
      expect(result.first.id, 3);
    });

    test('sort score asc → 5 条 score 1, 2, 3, 4, 5', () {
      final container = ProviderContainer(
        overrides: [
          moodEntriesProvider.overrideWith((ref) => makeEntries()),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(moodListFilterProvider.notifier)
          .setSort(MoodListSort.scoreAsc);
      final result = container.read(filteredMoodEntriesProvider);
      expect(result.length, 5);
      expect(result[0].score, 1);
      expect(result[1].score, 2);
      expect(result[2].score, 3);
      expect(result[3].score, 4);
      expect(result[4].score, 5);
    });
  });
}
