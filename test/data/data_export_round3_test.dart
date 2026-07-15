import 'package:chroniccare/data/services/data_export_service.dart';
import 'package:chroniccare/data/database/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// 第三轮审查 fix: data_export_service 加 report_histories + mood_entries,
/// 加上字段校验
void main() {
  late AppDatabase db;
  late DataExportService svc;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    svc = DataExportService(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('P4 fix: 导出包含 reportHistories + moodEntries', () async {
    // 准备数据
    await db.insertReportHistory(ReportHistoriesCompanion.insert(
      windowDays: 14,
      generatedAt: DateTime(2026, 7, 13, 12, 0),
      userName: '小明',
      reportText: '测试报告内容',
    ));
    await db.insertMoodEntry(MoodEntriesCompanion.insert(
      timestamp: DateTime(2026, 7, 13, 10, 0),
      score: 4,
      tagsJson: const Value('["好","平静"]'),
      note: const Value('今天心情不错'),
    ));

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
}
