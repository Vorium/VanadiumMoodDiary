import 'dart:convert';
import 'dart:typed_data';

import 'package:chroniccare/core/data/services/data_export_service.dart';
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/mappers/vent/vent_mapper.dart';
import 'package:chroniccare/core/data/services/encryption_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// 第三轮审查 fix: data_export_service 加 report_histories + mood_entries,
/// 加上字段校验
///
/// v0.21 Round 22 (P0-1): vent 文字字段级加密。
/// 测试环境 FlutterSecureStorage 不可用 → 注入固定 32-byte key 走 in-memory。
void main() {
  late AppDatabase db;
  late DataExportService svc;
  late EncryptionService enc;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    enc = EncryptionService();
    // 32-byte 固定 key,测试环境不走 SecureStorage
    enc.setKeyForTest(Uint8List.fromList(List<int>.filled(32, 0x42)));
    svc = DataExportService(db, null, enc);
  });

  tearDown(() async {
    await db.close();
  });

  /// 单元测试用:把明文用注入的 key 加密成 Uint8List,写入 contentTextEnc 字段
  Future<Uint8List> encText(String s) async {
    return enc.encrypt(Uint8List.fromList(utf8.encode(s)));
  }

  test('P4 fix: 导出包含 reportHistories + moodEntries', () async {
    // 准备数据
    await db.insertReportHistory(
      ReportHistoriesCompanion.insert(
        windowDays: 14,
        generatedAt: DateTime(2026, 7, 13, 12, 0),
        userName: '小明',
        reportText: '测试报告内容',
      ),
    );
    await db.insertMoodEntry(
      MoodEntriesCompanion.insert(
        timestamp: DateTime(2026, 7, 13, 10, 0),
        score: 4,
        tagsJson: const Value('["好","平静"]'),
        note: const Value('今天心情不错'),
      ),
    );

    final json = await svc.exportToJson();
    expect(json, contains('"reportHistories"'));
    expect(json, contains('"moodEntries"'));
    expect(json, contains('测试报告内容'));
    expect(json, contains('今天心情不错'));
  });

  test('P4 fix: 导入 v2 JSON → reportHistories + moodEntries 也被恢复', () async {
    final json = '''
{
  "version": 2,
  "exportedAt": "2026-07-13T12:00:00.000Z",
  "profile": null,
  "contacts": [],
  "medications": [],
  "checkIns": [],
  "reportHistories": [
    {
      "windowDays": 14,
      "generatedAt": "2026-07-10T12:00:00.000Z",
      "userName": "导入测试",
      "reportText": "导入的报告内容"
    }
  ],
  "moodEntries": [
    {
      "timestamp": "2026-07-12T10:00:00.000Z",
      "score": 3,
      "tagsJson": "[]",
      "note": null
    }
  ]
}
''';
    final result = await svc.importFromJson(json);
    expect(result.success, true);
    expect(result.reportHistoryCount, 1);
    expect(result.moodEntryCount, 1);

    final reports = await db.getAllReportHistories();
    expect(reports.length, 1);
    expect(reports.first.reportText, '导入的报告内容');

    final moods = await db.getAllMoodEntries();
    expect(moods.length, 1);
    expect(moods.first.score, 3);
  });

  test('P12 fix: 错误信息脱敏,不再泄露内部异常', () async {
    final result = await svc.importFromJson('not json {{{');
    expect(result.success, false);
    expect(result.error, contains('解析失败'));
    // 不应该包含 "FormatException" / "Unexpected character" 这类内部细节
    expect(result.error, isNot(contains('FormatException')));
    expect(result.error, isNot(contains('Unexpected')));
  });

  test('P13 fix: 坏数据不写 DB,只跳过', () async {
    final json = '''
{
  "version": 2,
  "exportedAt": "2026-07-13T12:00:00.000Z",
  "profile": null,
  "contacts": [
    {"name": "有效", "phone": "13800138000", "sortOrder": 0, "isActive": true},
    {"name": "无效phone", "phone": "abc", "sortOrder": 0, "isActive": true}
  ],
  "medications": [
    {"name": "", "dosage": 40, "dosageUnit": "mg", "timesJson": "[]", "startDate": "2026-01-01T00:00:00.000Z", "isActive": true}
  ],
  "checkIns": [],
  "reportHistories": [],
  "moodEntries": [
    {"timestamp": "not-a-date", "score": 4}
  ]
}
''';
    final result = await svc.importFromJson(json);
    expect(result.success, true);
    expect(result.contactCount, 1); // 只有一个有效
    expect(result.medicationCount, 0); // name 空被跳
    expect(result.moodEntryCount, 0); // timestamp 坏被跳
  });

  test('version 不匹配 → 友好错误', () async {
    final result = await svc.importFromJson('{"version": 99, "contacts":[]}');
    expect(result.success, false);
    expect(result.error, contains('版本'));
  });

  // ===== P0-3: vent_entries 导出/导入 (round 14 P0 batch) =====

  test('P0-3: 导出包含 ventEntries 文字,不导出 audioPath', () async {
    await db.insertVentEntry(
      VentEntriesCompanion.insert(
        timestamp: DateTime(2026, 7, 13, 22, 0),
        contentTextEnc: Value(await encText('今天好累')),
        audioPath: const Value('/fake/path/vent_xxx.m4a'),
        audioDurationSec: const Value(45),
        audioSizeBytes: const Value(234567),
      ),
    );

    final json = await svc.exportToJson();
    expect(json, contains('"ventEntries"'));
    expect(json, contains('今天好累'));
    // audioPath 永远不进 export(跨设备不可用)
    expect(json, isNot(contains('/fake/path/vent_xxx.m4a')));
    // 但 hadAudio 标志会带
    expect(json, contains('"hadAudio": true'));
    // version bump 到 4 (v0.18 4D 情绪: energy/sleep/anxiety)
    expect(json, contains('"version": 4'));
  });

  test('P0-3: 纯文字 vent 条目正常导出', () async {
    await db.insertVentEntry(
      VentEntriesCompanion.insert(
        timestamp: DateTime(2026, 7, 13, 22, 0),
        contentTextEnc: Value(await encText('想哭')),
      ),
    );

    final json = await svc.exportToJson();
    final data = jsonDecode(json) as Map<String, dynamic>;
    final vents = data['ventEntries'] as List;
    expect(vents, hasLength(1));
    final v = vents.first as Map<String, dynamic>;
    expect(v['contentText'], '想哭');
    expect(
      v.containsKey('hadAudio'),
      false,
      reason: '纯文字条目不应有 hadAudio 标志',
    );
  });

  test('P0-3: 导入 v3 ventEntries 文字 + 录音元数据,丢弃 audioPath', () async {
    final json = '''
{
  "version": 3,
  "exportedAt": "2026-07-13T12:00:00.000Z",
  "profile": null,
  "contacts": [],
  "medications": [],
  "checkIns": [],
  "reportHistories": [],
  "moodEntries": [],
  "ventEntries": [
    {
      "timestamp": "2026-07-12T22:00:00.000Z",
      "contentText": "导入的树洞文字",
      "audioDurationSec": 60,
      "audioSizeBytes": 300000,
      "hadAudio": true
    },
    {
      "timestamp": "2026-07-13T22:00:00.000Z",
      "contentText": "第二条",
      "audioDurationSec": 0,
      "audioSizeBytes": 0
    }
  ]
}
''';
    final result = await svc.importFromJson(json);
    expect(result.success, true);
    expect(result.ventEntryCount, 2);

    // v0.21 Round 22 (P0-1): vent 文字字段级加密,需经 mapper.toEntity() decrypt
    // 拿到 entity.contentText (明文),不能直接读 Drift row 的 contentText (旧字段)。
    final rows = await db.watchVentEntries().first;
    final entries = await Future.wait(rows.map((r) => r.toEntity()));
    expect(entries, hasLength(2));
    // watchVentEntries 按 timestamp DESC 排,2026-07-13 在前
    expect(entries.first.contentText, '第二条');
    expect(entries.last.contentText, '导入的树洞文字');
    expect(
      entries.last.audioPath,
      isNull,
      reason: '导入时 audioPath 必须始终是 null(跨设备失效)',
    );
    expect(entries.last.audioDurationSec, 60);
  });

  test('P0-3: 导入 v2 (没 ventEntries 段) 也能成功,只是 ventCount = 0', () async {
    final json = '''
{
  "version": 2,
  "exportedAt": "2026-07-13T12:00:00.000Z",
  "profile": null,
  "contacts": [],
  "medications": [],
  "checkIns": [],
  "reportHistories": [],
  "moodEntries": []
}
''';
    final result = await svc.importFromJson(json);
    expect(result.success, true);
    expect(result.ventEntryCount, 0);
  });

  test('P0-3: 导入 v3 但 ventEntries 是空数组 → ventCount = 0', () async {
    final json = '''
{
  "version": 3,
  "exportedAt": "2026-07-13T12:00:00.000Z",
  "profile": null,
  "contacts": [],
  "medications": [],
  "checkIns": [],
  "reportHistories": [],
  "moodEntries": [],
  "ventEntries": []
}
''';
    final result = await svc.importFromJson(json);
    expect(result.success, true);
    expect(result.ventEntryCount, 0);
  });

  test('P0-3: 导入时坏 vent 数据 (timestamp 无效) 跳过,不抛错', () async {
    final json = '''
{
  "version": 3,
  "exportedAt": "2026-07-13T12:00:00.000Z",
  "profile": null,
  "contacts": [],
  "medications": [],
  "checkIns": [],
  "reportHistories": [],
  "moodEntries": [],
  "ventEntries": [
    {"timestamp": "not-a-date", "contentText": "应该被跳过"},
    {"timestamp": "2026-07-12T22:00:00.000Z", "contentText": "有效"}
  ]
}
''';
    final result = await svc.importFromJson(json);
    expect(result.success, true);
    expect(result.ventEntryCount, 1);
  });

  test('P0-3: 导入 v3 → 再导出, 文字保留 (round-trip)', () async {
    await db.insertVentEntry(
      VentEntriesCompanion.insert(
        timestamp: DateTime(2026, 7, 13, 22, 0),
        contentTextEnc: Value(await encText('今天好累')),
      ),
    );

    final export1 = await svc.exportToJson();
    // 清空 (新数据库)
    await db.delete(db.ventEntries).go();
    expect((await db.watchVentEntries().first), isEmpty);

    // 重新导入
    final result = await svc.importFromJson(export1);
    expect(result.ventEntryCount, 1);

    // 二次导出, 文字保留
    final export2 = await svc.exportToJson();
    expect(export2, contains('今天好累'));
  });
}
