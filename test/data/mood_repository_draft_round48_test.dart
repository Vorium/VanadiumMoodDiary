// v0.24 round 48 (sp-en P1-14): MoodEntryDraft 参数对象行为锁定
//
// 之前 MoodRepository.add() 有 10 个 named 参数, 改 add({required MoodEntryDraft
// draft}) 后必须锁 10 字段全部正确映射到 drift MoodEntriesCompanion +
// watchAll() 拿回 entity 字段全部正确。
//
// 覆盖:
// 1. 必填 (score / tags) 映射
// 2. note / at / 4 维字段 (energy / sleep / anxiety) 映射
// 3. 语音 3 字段 (audioPath / audioTranscript / audioDurationMs) 映射
// 4. at null → repository 用 DateTime.now() (跟旧 add() 行为一致)
// 5. tags 空列表 → tagsJson = '[]'
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/repositories/mood/mood_repository_impl.dart';
import 'package:chroniccare/domain/entities/mood_entry_draft.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late MoodRepositoryImpl repo;
  final fixedTime = DateTime(2026, 7, 17, 14, 30);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = MoodRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('add(draft: MoodEntryDraft) (v0.24 round 48 sp-en P1-14)', () {
    test('必填 score + tags → DB 写入正确 (P1-14 GREEN-1)', () async {
      final id = await repo.add(
        draft: const MoodEntryDraft(score: 4, tags: ['平静']),
      );
      final entry = await (db.select(db.moodEntries)..where((t) => t.id.equals(id)))
          .getSingle();
      expect(entry.score, 4);
      expect(entry.tagsJson, '["平静"]');
    });

    test('note 字段映射', () async {
      final id = await repo.add(
        draft: const MoodEntryDraft(
          score: 3,
          tags: [],
          note: '今天有点累',
        ),
      );
      final entry = await (db.select(db.moodEntries)..where((t) => t.id.equals(id)))
          .getSingle();
      expect(entry.note, '今天有点累');
    });

    test('at 字段映射 — 显式传时间', () async {
      final id = await repo.add(
        draft: MoodEntryDraft(
          score: 3,
          tags: const [],
          at: fixedTime,
        ),
      );
      final entry = await (db.select(db.moodEntries)..where((t) => t.id.equals(id)))
          .getSingle();
      expect(entry.timestamp, fixedTime);
    });

    test('at null → repository 自动用 DateTime.now()', () async {
      final before = DateTime.now();
      final id = await repo.add(
        draft: const MoodEntryDraft(score: 3, tags: []),
      );
      final after = DateTime.now();
      final entry = await (db.select(db.moodEntries)..where((t) => t.id.equals(id)))
          .getSingle();
      // entry.timestamp 应该在 before..after 之间
      expect(entry.timestamp.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(entry.timestamp.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('4 维字段 (energy / sleep / anxiety) 全部映射 (P1-14 GREEN-2)', () async {
      final id = await repo.add(
        draft: const MoodEntryDraft(
          score: 3,
          tags: [],
          energy: 2,
          sleep: 4,
          anxiety: 5,
        ),
      );
      final entry = await (db.select(db.moodEntries)..where((t) => t.id.equals(id)))
          .getSingle();
      expect(entry.energy, 2);
      expect(entry.sleep, 4);
      expect(entry.anxiety, 5);
    });

    test('4 维字段 null → DB 存 null (单 score 模式兼容)', () async {
      final id = await repo.add(
        draft: const MoodEntryDraft(score: 3, tags: []),
      );
      final entry = await (db.select(db.moodEntries)..where((t) => t.id.equals(id)))
          .getSingle();
      expect(entry.energy, isNull);
      expect(entry.sleep, isNull);
      expect(entry.anxiety, isNull);
    });

    test('语音 3 字段全部映射 (P1-14 GREEN-3)', () async {
      final id = await repo.add(
        draft: const MoodEntryDraft(
          score: 4,
          tags: [],
          audioPath: '/docs/mood_audio/m1.m4a.enc',
          audioTranscript: '心情不错',
          audioDurationMs: 8000,
        ),
      );
      final entry = await (db.select(db.moodEntries)..where((t) => t.id.equals(id)))
          .getSingle();
      expect(entry.audioPath, '/docs/mood_audio/m1.m4a.enc');
      expect(entry.audioTranscript, '心情不错');
      expect(entry.audioDurationMs, 8000);
    });

    test('tags 空列表 → tagsJson = "[]" (JsonCodec.encodeStringList)', () async {
      final id = await repo.add(
        draft: const MoodEntryDraft(score: 3, tags: []),
      );
      final entry = await (db.select(db.moodEntries)..where((t) => t.id.equals(id)))
          .getSingle();
      expect(entry.tagsJson, '[]');
    });

    test('多个 tags → tagsJson JSON 数组 (P1-14 GREEN-4)', () async {
      final id = await repo.add(
        draft: const MoodEntryDraft(
          score: 3,
          tags: ['焦虑', '失眠'],
        ),
      );
      final entry = await (db.select(db.moodEntries)..where((t) => t.id.equals(id)))
          .getSingle();
      expect(entry.tagsJson, '["焦虑","失眠"]');
    });

    test('watchAll() 拿回的 entity 字段全对应 draft', () async {
      await repo.add(
        draft: MoodEntryDraft(
          score: 5,
          tags: const ['开心'],
          note: '周末',
          at: fixedTime,
          energy: 5,
          sleep: 5,
          anxiety: 5,
          audioPath: '/x.m4a.enc',
          audioTranscript: 'good',
          audioDurationMs: 3000,
        ),
      );
      final all = await repo.watchAll().first;
      expect(all.length, 1);
      final e = all.first;
      expect(e.score, 5);
      expect(e.tags, ['开心']);
      expect(e.note, '周末');
      expect(e.timestamp, fixedTime);
      expect(e.energy, 5);
      expect(e.sleep, 5);
      expect(e.anxiety, 5);
      expect(e.audioPath, '/x.m4a.enc');
      expect(e.audioTranscript, 'good');
      expect(e.audioDurationMs, 3000);
    });
  });
}
