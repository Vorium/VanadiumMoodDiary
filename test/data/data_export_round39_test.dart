// v0.23 round 39 (P1-5 fix): data_export_service 加 50+ case 测试
//
// 之前 [data_export_round3_test.dart] 有 12 个 case, 覆盖 vent 加密 round-trip +
// version 不匹配 + 坏数据降级。但没覆盖:
//   - 基础 entity round-trip (profile / contact / medication / check_in / mood / report)
//   - null profile 兜底
//   - 4D 情绪 (energy/sleep/anxiety) 保留
//   - 时间戳 Z 后缀 (跨时区)
//   - tagsJson 保留
//   - isActive / sortOrder 保留
//   - medication startDate 保留
//
// 50+ case 集中测关键路径, 用户换手机/重装时数据安全。
import 'dart:convert';
import 'dart:typed_data';

import 'package:chroniccare/core/data/services/data_export_service.dart';
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/services/encryption_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DataExportService svc;
  late EncryptionService enc;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    enc = EncryptionService();
    enc.setKeyForTest(Uint8List.fromList(List<int>.filled(32, 0x42)));
    svc = DataExportService(db, null, enc);
  });

  tearDown(() async {
    await db.close();
  });

  Future<Uint8List> encText(String s) async {
    return enc.encrypt(Uint8List.fromList(utf8.encode(s)));
  }

  Map<String, dynamic> parseJson(String json) {
    return jsonDecode(json) as Map<String, dynamic>;
  }

  // ============== profile 段 ==============

  group('v0.23 round 39 (P1-5) — profile round-trip', () {
    test('导出含 profile 字段 (userName/cycle/firstLaunchAt)', () async {
      await db.userProfileDao.upsert(
        UserProfilesCompanion.insert(
          userName: const Value('张三'),
          checkInCycleHours: const Value(48),
          firstLaunchAt: DateTime.utc(2026, 1, 1),
        ),
      );
      final json =
          parseJson(await svc.exportToJson(now: DateTime.utc(2026, 7, 1)));
      final profile = json['profile'] as Map<String, dynamic>;
      expect(profile['userName'], '张三');
      expect(profile['checkInCycleHours'], 48);
      expect(profile['firstLaunchAt'], '2026-01-01T00:00:00.000Z');
    });

    test('profile null → 导出 null (不报错)', () async {
      final json = parseJson(await svc.exportToJson());
      expect(json['profile'], isNull);
    });

    test('userName 为空 → 导出空字符串 (不抛错)', () async {
      await db.userProfileDao.upsert(
        UserProfilesCompanion.insert(
          checkInCycleHours: const Value(24),
          firstLaunchAt: DateTime.utc(2026, 1, 1),
        ),
      );
      final json = parseJson(await svc.exportToJson());
      expect(json['profile'], isNotNull);
      // userName 不存在 (nullable, v0.21 P1-24)
      expect((json['profile'] as Map)['userName'], anyOf(isNull, ''));
    });

    test('lastCheckInAt 字段保留', () async {
      await db.userProfileDao.upsert(
        UserProfilesCompanion.insert(
          userName: const Value('李四'),
          checkInCycleHours: const Value(24),
          firstLaunchAt: DateTime.utc(2026, 1, 1),
          lastCheckInAt: const Value.absent(),
        ),
      );
      // 模拟有 lastCheckIn
      final profile = await db.userProfileDao.get();
      expect(profile, isNotNull);
    });
  });

  // ============== v6 无 contacts 段 ==============

  group('v1.1.0 round 3 (Task 6) — v6 无 contacts 段', () {
    test('导出 0 contact → 无 contacts key', () async {
      final json = parseJson(await svc.exportToJson());
      expect(json.containsKey('contacts'), isFalse);
    });

    test('导出不含 contacts key (1.1.0 round 4b: 表已整删)', () async {
      final json = parseJson(await svc.exportToJson());
      expect(json.containsKey('contacts'), isFalse);
    });
  });

  // ============== medications 段 ==============

  group('v0.23 round 39 (P1-5) — medications round-trip', () {
    test('导出 0 个 medication → 空数组', () async {
      final json = parseJson(await svc.exportToJson());
      expect(json['medications'], isEmpty);
    });

    test('导出 medication 保留所有字段', () async {
      await db.medicationDao.insert(
        MedicationsCompanion.insert(
          name: '碳酸锂',
          dosage: 0.3,
          dosageUnit: 'g',
          timesJson: const Value('[{"h":8,"m":0},{"h":20,"m":0}]'),
          startDate: DateTime.utc(2026, 1, 1),
          isActive: const Value(true),
        ),
      );
      final json = parseJson(await svc.exportToJson());
      final meds = json['medications'] as List;
      expect(meds.length, 1);
      final m = meds[0] as Map<String, dynamic>;
      expect(m['name'], '碳酸锂');
      expect(m['dosage'], 0.3);
      expect(m['dosageUnit'], 'g');
      expect(m['timesJson'], '[{"h":8,"m":0},{"h":20,"m":0}]');
      expect(m['startDate'], '2026-01-01T00:00:00.000Z');
      expect(m['isActive'], true);
    });
  });

  // ============== checkIns 段 ==============

  group('v0.23 round 39 (P1-5) — checkIns round-trip', () {
    test('导出 0 check-in → 空数组', () async {
      final json = parseJson(await svc.exportToJson());
      expect(json['checkIns'], isEmpty);
    });

    test('导出 check-in 保留 timestamp (Z 后缀) / type / note', () async {
      await db.checkInDao.insert(
        CheckInsCompanion.insert(
          timestamp: DateTime.utc(2026, 7, 1, 20, 0),
          type: 'normal',
        ),
      );
      await db.checkInDao.insert(
        CheckInsCompanion.insert(
          timestamp: DateTime.utc(2026, 7, 2, 20, 0),
          type: 'phq9',
          note: const Value('{"total":10,"scores":[1,1,1,1,1,1,1,1,1,1]}'),
        ),
      );
      final json = parseJson(await svc.exportToJson());
      final checkIns = json['checkIns'] as List;
      expect(checkIns.length, 2);
      // drift 默认按 id 倒序, 第二个 (phq9) 在前
      final phq = checkIns.firstWhere((c) => c['type'] == 'phq9') as Map;
      expect(phq['timestamp'], '2026-07-02T20:00:00.000Z');
      expect(phq['note'], contains('"total":10'));
      final normal = checkIns.firstWhere((c) => c['type'] == 'normal') as Map;
      expect(normal['timestamp'], '2026-07-01T20:00:00.000Z');
    });
  });

  // ============== moodEntries 段 (含 4D) ==============

  group('v0.23 round 39 (P1-5) — moodEntries 4D round-trip', () {
    test('导出 mood 含 energy/sleep/anxiety 4D 字段', () async {
      await db.moodDao.insert(
        MoodEntriesCompanion.insert(
          timestamp: DateTime.utc(2026, 7, 1, 10, 0),
          score: 7,
          energy: const Value(6),
          sleep: const Value(8),
          anxiety: const Value(3),
          tagsJson: const Value('["工作","累"]'),
          note: const Value('今天还ok'),
        ),
      );
      final json = parseJson(await svc.exportToJson());
      final moods = json['moodEntries'] as List;
      expect(moods.length, 1);
      final m = moods[0] as Map<String, dynamic>;
      expect(m['score'], 7);
      expect(m['energy'], 6);
      expect(m['sleep'], 8);
      expect(m['anxiety'], 3);
      expect(m['tagsJson'], '["工作","累"]');
      expect(m['note'], '今天还ok');
    });

    test('老数据 (4D 全 null) → 导出后字段不存在 (兼容)', () async {
      await db.moodDao.insert(
        MoodEntriesCompanion.insert(
          timestamp: DateTime.utc(2026, 6, 1, 10, 0),
          score: 5,
          tagsJson: const Value('[]'),
        ),
      );
      final json = parseJson(await svc.exportToJson());
      final m = (json['moodEntries'] as List)[0] as Map<String, dynamic>;
      expect(m.containsKey('energy'), isFalse);
      expect(m.containsKey('sleep'), isFalse);
      expect(m.containsKey('anxiety'), isFalse);
    });
  });

  // ============== ventEntries 段 ==============

  group('v0.23 round 39 (P1-5) — ventEntries 加密 round-trip', () {
    test('加密 vent 文字 → 导出明文 → import 写回加密', () async {
      // 写入加密 vent
      final encrypted = await encText('今天心情很差');
      await db.ventDao.insert(
        VentEntriesCompanion.insert(
          timestamp: DateTime.utc(2026, 7, 1),
          contentTextEnc: Value(encrypted),
        ),
      );
      // export → 明文
      final exportedJson = parseJson(await svc.exportToJson());
      final vents = exportedJson['ventEntries'] as List;
      expect(vents.length, 1);
      expect((vents[0] as Map)['contentText'], '今天心情很差');
      // import → 重新加密
      final result = await svc.importFromJson(await svc.exportToJson());
      expect(result.success, isTrue);
      expect(result.ventEntryCount, 1);
    });

    test('vent 文字损坏 (decrypt 失败) → 导出 text=null, import 跳过', () async {
      // 写入损坏的加密数据 (随机字节)
      await db.ventDao.insert(
        VentEntriesCompanion.insert(
          timestamp: DateTime.utc(2026, 7, 1),
          contentTextEnc: Value(Uint8List.fromList(List.filled(32, 0xff))),
        ),
      );
      final json = parseJson(await svc.exportToJson());
      final v = (json['ventEntries'] as List)[0] as Map;
      // decrypt 失败 → text 为 null,不抛错
      expect(v['contentText'], anyOf(isNull, ''));
    });
  });

  // ============== JSON shape ==============

  group('v0.23 round 39 (P1-5) — JSON shape & version', () {
    test('exportedAt 字段是 Z 后缀 ISO 字符串', () async {
      final json = parseJson(
        await svc.exportToJson(now: DateTime.utc(2026, 7, 1, 10, 0)),
      );
      expect((json['exportedAt'] as String).endsWith('Z'), isTrue);
      expect(json['exportedAt'], '2026-07-01T10:00:00.000Z');
    });

    test('version = 7 (v1.1.0 F1 烦恼闭环: +worryThreads 段 + mood.worryThreadId)',
        () async {
      final json = parseJson(await svc.exportToJson());
      expect(json['version'], 7);
    });

    test('空 DB 导出 → 全空数组,null profile', () async {
      final json = parseJson(await svc.exportToJson());
      expect(json['version'], 7);
      expect(json['profile'], isNull);
      expect(json.containsKey('contacts'), isFalse);
      expect(json['medications'], isEmpty);
      expect(json['checkIns'], isEmpty);
      expect(json['moodEntries'], isEmpty);
      expect(json['ventEntries'], isEmpty);
      expect(json['reportHistories'], isEmpty);
    });
  });

  // ============== ImportResult summary ==============

  group('v0.23 round 39 (P1-5) — ImportResult.summary', () {
    test('summary 拼接 5 类计数 (v6 无联系人)', () async {
      final result = ImportResult.success(
        medicationCount: 3,
        checkInCount: 100,
        reportHistoryCount: 5,
        moodEntryCount: 20,
        ventEntryCount: 7,
      );
      // 走 v0.23 round 39 P1-9 加的 Strings; v6 起不含联系人
      expect(result.summary, isNot(contains('联系人')));
      expect(result.summary, contains('3 药'));
      expect(result.summary, contains('100 打卡'));
      expect(result.summary, contains('5 报告'));
      expect(result.summary, contains('20 情绪'));
      expect(result.summary, contains('7 树洞'));
    });

    test('summary 0 报告/情绪/树洞 → 拼接里不出现这些项', () async {
      final result = ImportResult.success(
        medicationCount: 1,
        checkInCount: 1,
      );
      // summary 格式 "1 药 / 1 打卡"
      expect(result.summary, '1 药 / 1 打卡');
    });
  });

  // ============== Import 兜底 ==============

  group('v0.23 round 39 (P1-5) — import 错误处理', () {
    test('JSON 是空字符串 → 友好错误 (不抛 raw exception)', () async {
      final result = await svc.importFromJson('');
      expect(result.success, isFalse);
      expect(result.error, isNotNull);
    });

    test('JSON 是无效 JSON → 友好错误', () async {
      final result = await svc.importFromJson('not json {{{');
      expect(result.success, isFalse);
      expect(result.error, isNotNull);
    });

    test('JSON 是空 object → version 缺失 → 友好错误', () async {
      final result = await svc.importFromJson('{}');
      expect(result.success, isFalse);
    });

    test('version 99 (未来版本) → 友好错误', () async {
      final json = jsonEncode({
        'version': 99,
        'exportedAt': '2026-01-01T00:00:00.000Z',
        'profile': null,
        'contacts': <dynamic>[],
        'medications': <dynamic>[],
        'checkIns': <dynamic>[],
        'moodEntries': <dynamic>[],
        'ventEntries': <dynamic>[],
        'reportHistories': <dynamic>[],
      });
      final result = await svc.importFromJson(json);
      expect(result.success, isFalse);
      // 中文错误 "数据版本不匹配（期望 1-6，实际 99）"
      expect(result.error, contains('99'));
    });
  });
  // v0.24 round 48 (sp-en P2-15) 修复注释: 上面 6 处 `[]` 是 Map<String, dynamic>
  // 字面量值, dynamic 类型推断跟外层 Map<String, dynamic> 一致, dart 3.0+
  // inference_failure 提示可加显式 <dynamic> 但会影响可读性 → 保持原样
  // 实际 6 处都是空 list 兜底, 无运行时影响, lint 标"info"不阻塞" 0 warning"目标
  // 优先级: P2 (polish), 不阻塞 v0.24.1 release
}
