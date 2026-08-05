// v0.29 round 84 (CBT thought record) — mood_entries drift round-trip 测试
//
// 验证 8 个 CBT 字段在 drift DB (in-memory) 中能完整 insert → 读出 → toEntity
// 流转,无字段丢失。
//
// 不依赖 flutter_test 的 widget,只用 flutter_test 的 test framework + drift
// NativeDatabase.memory()。
//
// 注意: domain 4 层架构下 MoodEntryDraft 不依赖 drift,toCompanion 走
// MoodEntryEntity 端。所以 round-trip 测试先用 draft 拼 entity,再走 entity→
// companion→insert。

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/entities/mood_entry_draft.dart';
import 'package:chroniccare/core/data/database/mappers/mood/mood_entry_mapper.dart';
import 'package:chroniccare/core/data/repositories/mood/mood_repository_impl.dart';
import 'package:chroniccare/core/shared/json_codec.dart';

/// 模拟 MoodRepositoryImpl.add() 的内部逻辑(draft → entity → companion),
/// 让测试独立于 repository impl。
MoodEntriesCompanion _draftToCompanion(MoodEntryDraft draft, {int id = 0}) {
  final entity = MoodEntryEntity(
    id: id,
    timestamp: draft.at ?? DateTime(2026, 8, 4),
    score: draft.score,
    energy: draft.energy,
    sleep: draft.sleep,
    anxiety: draft.anxiety,
    tagsJson: JsonCodec.encodeStringList(draft.tags),
    note: draft.note,
    audioPath: draft.audioPath,
    audioTranscript: draft.audioTranscript,
    audioDurationMs: draft.audioDurationMs,
    situation: draft.situation,
    automaticThought: draft.automaticThought,
    evidenceFor: draft.evidenceFor,
    evidenceAgainst: draft.evidenceAgainst,
    alternativeThought: draft.alternativeThought,
    reratedScore: draft.reratedScore,
    coreBelief: draft.coreBelief,
    behaviorResponse: draft.behaviorResponse,
  );
  return entity.toCompanion();
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  test('CBT 5 栏字段 round-trip 全部保留', () async {
    const draft = MoodEntryDraft(
      score: 4, tags: ['焦虑'],
      situation: '开会迟到', automaticThought: '大家觉得我不靠谱',
      evidenceFor: '上次也迟到', evidenceAgainst: '过去一年只迟到一次',
      alternativeThought: '偶尔一次正常', reratedScore: 3,
    );
    final id = await db.moodDao.insert(_draftToCompanion(draft));
    final all = await db.moodDao.getAll();
    final saved = all.firstWhere((e) => e.id == id);
    expect(saved.situation, '开会迟到');
    expect(saved.automaticThought, '大家觉得我不靠谱');
    expect(saved.evidenceFor, '上次也迟到');
    expect(saved.evidenceAgainst, '过去一年只迟到一次');
    expect(saved.alternativeThought, '偶尔一次正常');
    expect(saved.reratedScore, 3);
    final entity = saved.toEntity();
    expect(entity.cbtLevel, 5);
    expect(entity.scoreShift, -1.0);
  });

  test('7 栏字段 round-trip', () async {
    const draft = MoodEntryDraft(
      score: 2, tags: [],
      situation: 'x', automaticThought: 'y', evidenceFor: 'a',
      evidenceAgainst: 'b', alternativeThought: 'c', reratedScore: 4,
      coreBelief: '我不够好', behaviorResponse: '深呼吸',
    );
    final id = await db.moodDao.insert(_draftToCompanion(draft));
    final saved = (await db.moodDao.getAll()).firstWhere((e) => e.id == id);
    expect(saved.coreBelief, '我不够好');
    expect(saved.behaviorResponse, '深呼吸');
    expect(saved.toEntity().cbtLevel, 7);
  });

  test('老 3 栏数据 (CBT 字段全 null) round-trip', () async {
    const draft = MoodEntryDraft(score: 3, tags: ['普通'], note: '今天还行');
    final id = await db.moodDao.insert(_draftToCompanion(draft));
    final saved = (await db.moodDao.getAll()).firstWhere((e) => e.id == id);
    // 8 个 CBT 字段全 null (v0.29 R84 老数据升级后默认状态)
    expect(saved.situation, isNull);
    expect(saved.automaticThought, isNull);
    expect(saved.evidenceFor, isNull);
    expect(saved.evidenceAgainst, isNull);
    expect(saved.alternativeThought, isNull);
    expect(saved.reratedScore, isNull);
    expect(saved.coreBelief, isNull);
    expect(saved.behaviorResponse, isNull);
    expect(saved.toEntity().isCbtRecord, isFalse);
    expect(saved.toEntity().cbtLevel, isNull);
  });

  // v0.29 round 84 (fix) — 防止 moodRepository.add() 漏传 CBT 字段的回归测试
  test('moodRepository.add 透传 8 个 CBT 字段到 DB (P0 fix)', () async {
    final repo = MoodRepositoryImpl(db);
    const draft = MoodEntryDraft(
      score: 4, tags: ['焦虑'],
      situation: '开会迟到', automaticThought: '大家觉得我不可靠',
      evidenceFor: '上次也迟到', evidenceAgainst: '过去一年只迟到一次',
      alternativeThought: '偶尔一次正常', reratedScore: 3,
      coreBelief: '我不够好', behaviorResponse: '深呼吸',
    );
    final id = await repo.add(draft: draft);
    final saved = (await db.moodDao.getAll()).firstWhere((e) => e.id == id);
    expect(saved.situation, '开会迟到');
    expect(saved.automaticThought, '大家觉得我不可靠');
    expect(saved.evidenceFor, '上次也迟到');
    expect(saved.evidenceAgainst, '过去一年只迟到一次');
    expect(saved.alternativeThought, '偶尔一次正常');
    expect(saved.reratedScore, 3);
    expect(saved.coreBelief, '我不够好');
    expect(saved.behaviorResponse, '深呼吸');
  });

  test('moodRepository.add 老调用 (CBT 字段全 null) 仍 OK', () async {
    final repo = MoodRepositoryImpl(db);
    const draft = MoodEntryDraft(score: 3, tags: [], note: '普通');
    final id = await repo.add(draft: draft);
    final saved = (await db.moodDao.getAll()).firstWhere((e) => e.id == id);
    expect(saved.situation, isNull);
    expect(saved.automaticThought, isNull);
    expect(saved.coreBelief, isNull);
    expect(saved.behaviorResponse, isNull);
    expect(saved.reratedScore, isNull);
    expect(saved.note, '普通');
  });
}
