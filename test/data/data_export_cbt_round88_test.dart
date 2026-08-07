// v0.30 round 88 (P0): data_export moodEntries CBT 字段 round-trip 回归测试
//
// 背景: R84 加 8 个 CBT 字段 (situation / automaticThought / evidenceFor /
//   evidenceAgainst / alternativeThought / reratedScore / coreBelief /
//   behaviorResponse) 到 mood_entries 表 + 7 栏 UI 完整流程, **但漏了**
//   export_orchestrator toMap 和 export_import_pipeline MoodEntriesCompanion
//   写这 8 字段。导致用户:
//   1. 旧版本 (R84 之前) 用户已记 CBT 数据 → 升 R84 之后 export JSON
//      → JSON 不含 8 字段
//   2. 删 DB → 导入 JSON → 8 字段全丢 (silent data loss)
//
// P0 同类 bug 历史: R84 P0 漏 vent audio, R85 修; 这是 P0 第二发。
//
// TDD red → green:
// - red:  round-trip 后 expect 8 字段全保留 → fail (字段为 null)
// - green: 修 toMap + MoodEntriesCompanion 写 8 字段 → pass

import 'dart:convert';
import 'dart:typed_data';

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/services/data_export_service.dart';
import 'package:chroniccare/core/data/services/encryption_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DataExportService svc;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // v0.21 Round 22 (P0-1): vent 文字字段级加密, 注入固定 32-byte key。
    // 32-byte 全 0x42 跟 data_export_round3_test.dart 一致。
    final enc = EncryptionService();
    enc.setKeyForTest(Uint8List.fromList(List<int>.filled(32, 0x42)));
    svc = DataExportService(db, null, enc);
  });

  tearDown(() async {
    await db.close();
  });

  test('P0 fix (R88): 5 栏 mood entry 导出 → 删 DB → 导入, 8 CBT 字段全保留 (round-trip)',
      () async {
    // 1. 插入 1 条 5 栏 CBT mood entry
    await db.moodDao.insert(
      MoodEntriesCompanion.insert(
        timestamp: DateTime.utc(2026, 8, 5, 10, 0, 0),
        score: 4,
        tagsJson: const Value('["焦虑"]'),
        situation: const Value('开会被点名'),
        automaticThought: const Value('大家觉得我很差'),
        evidenceFor: const Value('这次回答得不好'),
        evidenceAgainst: const Value('过去一年只被点名一次'),
        alternativeThought: const Value('偶尔一次很正常'),
        reratedScore: const Value(3),
      ),
    );

    // 2. 导出 → JSON 字符串 → map (验证 JSON 含 8 字段)
    final exportJson = await svc.exportToJson();
    final exportMap = jsonDecode(exportJson) as Map<String, dynamic>;
    final moodList = exportMap['moodEntries'] as List;
    expect(moodList, hasLength(1));
    final exported = moodList.first as Map<String, dynamic>;
    expect(exported['situation'], '开会被点名');
    expect(exported['automaticThought'], '大家觉得我很差');
    expect(exported['evidenceFor'], '这次回答得不好');
    expect(exported['evidenceAgainst'], '过去一年只被点名一次');
    expect(exported['alternativeThought'], '偶尔一次很正常');
    expect(exported['reratedScore'], 3);
    expect(exported['coreBelief'], isNull);
    expect(exported['behaviorResponse'], isNull);

    // 3. 删 DB (模拟 "卸载重装")
    await db.delete(db.moodEntries).go();
    expect(await db.moodDao.getAll(), isEmpty);

    // 4. 重新导入
    final result = await svc.importFromJson(exportJson);
    expect(result.success, true, reason: 'import 应该成功');
    expect(result.moodEntryCount, 1);

    // 5. 校验 8 字段全保留
    final restored = (await db.moodDao.getAll()).first;
    expect(restored.situation, '开会被点名');
    expect(restored.automaticThought, '大家觉得我很差');
    expect(restored.evidenceFor, '这次回答得不好');
    expect(restored.evidenceAgainst, '过去一年只被点名一次');
    expect(restored.alternativeThought, '偶尔一次很正常');
    expect(restored.reratedScore, 3);
    expect(restored.coreBelief, isNull);
    expect(restored.behaviorResponse, isNull);
    // 已知字段也要保留
    expect(
      restored.timestamp.toUtc().toIso8601String(),
      '2026-08-05T10:00:00.000Z',
    );
    expect(restored.score, 4);
    expect(restored.tagsJson, '["焦虑"]');
  });

  test(
      'P0 fix (R88): 7 栏 mood entry (含 coreBelief + behaviorResponse) round-trip',
      () async {
    await db.moodDao.insert(
      MoodEntriesCompanion.insert(
        timestamp: DateTime.utc(2026, 8, 5, 12, 0, 0),
        score: 2,
        situation: const Value('项目延期'),
        automaticThought: const Value('我永远做不好'),
        evidenceFor: const Value('这次又延期'),
        evidenceAgainst: const Value('上季度按时交付'),
        alternativeThought: const Value('这次是特殊原因'),
        reratedScore: const Value(4),
        coreBelief: const Value('我不够好'),
        behaviorResponse: const Value('明天跟 PM 复盘原因'),
      ),
    );

    final exportJson = await svc.exportToJson();
    final exportMap = jsonDecode(exportJson) as Map<String, dynamic>;
    final moodList = exportMap['moodEntries'] as List;
    final exported = moodList.first as Map<String, dynamic>;
    // 7 栏独有字段必须导出
    expect(exported['coreBelief'], '我不够好');
    expect(exported['behaviorResponse'], '明天跟 PM 复盘原因');

    // 删 → 导入
    await db.delete(db.moodEntries).go();
    final result = await svc.importFromJson(exportJson);
    expect(result.moodEntryCount, 1);

    final restored = (await db.moodDao.getAll()).first;
    expect(restored.situation, '项目延期');
    expect(restored.automaticThought, '我永远做不好');
    expect(restored.evidenceFor, '这次又延期');
    expect(restored.evidenceAgainst, '上季度按时交付');
    expect(restored.alternativeThought, '这次是特殊原因');
    expect(restored.reratedScore, 4);
    expect(restored.coreBelief, '我不够好');
    expect(restored.behaviorResponse, '明天跟 PM 复盘原因');
  });
}
