// v0.23 (Round 31) mood_repository 3 个 audio 字段 DB round-trip
//
// 测试 add() 加 audioPath / audioTranscript / audioDurationMs,
// watchAll() / watchToday() 拿回来的 entity 包含 3 字段。
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/repositories/mood/mood_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late MoodRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = MoodRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('add() 加 audio 字段 (v0.23 Round 31)', () {
    test('纯文字模式 — audio 3 字段全 null (向后兼容)', () async {
      final id = await repo.add(score: 3, tags: const ['焦虑']);
      final entry = await (db.select(db.moodEntries)..where((t) => t.id.equals(id)))
          .getSingle();
      expect(entry.audioPath, isNull);
      expect(entry.audioTranscript, isNull);
      expect(entry.audioDurationMs, isNull);
    });

    test('完整 audio 字段 round-trip', () async {
      final id = await repo.add(
        score: 4,
        tags: const ['平静'],
        audioPath: '/docs/mood_audio/mood_12345.m4a.enc',
        audioTranscript: '今天心情不错',
        audioDurationMs: 12500,
      );
      final entry = await (db.select(db.moodEntries)..where((t) => t.id.equals(id)))
          .getSingle();
      expect(entry.audioPath, '/docs/mood_audio/mood_12345.m4a.enc');
      expect(entry.audioTranscript, '今天心情不错');
      expect(entry.audioDurationMs, 12500);
    });

    test('只传 audioPath 不传 transcript — transcript 仍 null', () async {
      // 真实场景: STT 失败 → audio 录音保存但 transcript = null
      final id = await repo.add(
        score: 2,
        tags: const ['抑郁'],
        audioPath: '/a.m4a.enc',
      );
      final entry = await (db.select(db.moodEntries)..where((t) => t.id.equals(id)))
          .getSingle();
      expect(entry.audioPath, '/a.m4a.enc');
      expect(entry.audioTranscript, isNull);
      expect(entry.audioDurationMs, isNull);
    });

    test('3min 录音 — durationMs = 180000', () async {
      final id = await repo.add(
        score: 3,
        tags: const [],
        audioPath: '/a.m4a.enc',
        audioTranscript: '识别 60s',
        audioDurationMs: 180000,
      );
      final entry = await (db.select(db.moodEntries)..where((t) => t.id.equals(id)))
          .getSingle();
      expect(entry.audioDurationMs, 180000);
    });
  });

  group('watchAll() 包含 audio 字段 (v0.23 Round 31)', () {
    test('空表 — 返回空 list', () async {
      final all = await repo.watchAll().first;
      expect(all, isEmpty);
    });

    test('混合 纯文字 / 录音 2 条 — entity 字段全部带过来', () async {
      await repo.add(score: 3, tags: const ['焦虑']);
      await repo.add(
        score: 4,
        tags: const ['平静'],
        audioPath: '/b.m4a.enc',
        audioTranscript: 'good day',
        audioDurationMs: 8000,
      );
      final all = await repo.watchAll().first;
      expect(all.length, 2);
      final withAudio = all.firstWhere((e) => e.hasAudio);
      expect(withAudio.audioPath, '/b.m4a.enc');
      expect(withAudio.audioTranscript, 'good day');
      expect(withAudio.audioDurationMs, 8000);
      final textOnly = all.firstWhere((e) => !e.hasAudio);
      expect(textOnly.audioPath, isNull);
    });
  });
}
