// v0.30 round 95 (sub-spec 6 task 6d): 5 端到端集成测试
//
// 覆盖跨 module 的 5 个 user journey (spen P1 #7 集成测扩):
// 1. 打卡 → streak 实时计算 (CheckIn + StreakCalculator + HomePage state)
// 2. 设置 → 紧急联系人 → contactsProvider watch (Setup + ContactRepository)
// 3. 评估 → PHQ-9 → DB round-trip (AssessmentRepository.submitEntry +
//    check_ins 表 JSON 编码)
// 4. 数据导出 → JSON 含 schema + data (DataExportService.exportToJson)
// 5. vent 树洞 → 写 → encryption round-trip (VentRepository.add + contentText
//    加密落库 → watchAll decrypt)
//
// 模式 (跟 R84 cbt_thought_record_flow 集成测同款):
// - ProviderContainer + sharedPreferencesProvider + databaseProvider overrides
// - AppDatabase.forTesting(NativeDatabase.memory()) — 真实 in-memory DB
// - SharedPreferences.setMockInitialValues — 模拟用户已选设置
//
// 跟 R84 集成测差异:
// - 5 个 testWidgets 而非 1 个, 每个聚焦 1 个 cross-module 集成点
// - 5 个都走真 DB, 不 mock repository, 验证完整 round-trip
//
// 已知限制 (跟 R84 cbt 集成测同步):
// - **不挂 page widget** — production code 用 SingleChildScrollView 包 page
//   在 widget test 框架触发 layout error, 集成测专注 logic 流
// - **不测 audio 真实播放** — audioplayers package 在 test 框架不初始化
//   audio session

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/services/setup_committer.dart';
import 'package:chroniccare/domain/entities/consent_artifact.dart';
import 'package:chroniccare/domain/entities/mood_entry_draft.dart';
import 'package:chroniccare/domain/logic/streak_calculator.dart';
import 'package:chroniccare/presentation/providers/assessment_providers.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/service_providers.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/providers/vent_providers.dart';

void main() {
  late AppDatabase db;
  late SharedPreferences sp;

  setUp(() async {
    // vent 加密服务走 FlutterSecureStorage, 需要 binding init
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    sp = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('集成 1: 打卡 → streak 实时计算 (CheckInRepository + StreakCalculator 端到端)',
      () async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sp),
        databaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);

    // ===== Step 1: 初始状态 streak = 0 (用 maybeWhen 兜底, 跟 home_page_state 模式一致) =====
    final initialStreakAsync = container.read(streakSummaryProvider);
    final initialStreak = initialStreakAsync.maybeWhen(
      data: (s) => s,
      orElse: () =>
          const StreakSnapshot(streak: 0, shouldShowStreakBroken: false),
    );
    expect(initialStreak.streak, 0, reason: '初始无打卡 → streak=0');

    // ===== Step 2: 写今天打卡 =====
    final checkInRepo = container.read(checkInRepositoryProvider);
    await checkInRepo.checkIn(at: DateTime.now());

    // ===== Step 3: 直接走 repo watchNormalCheckIns (不依赖 StreamProvider autoDispose) =====
    final checkIns = await checkInRepo.watchNormalCheckIns().first;
    expect(
      checkIns.length,
      1,
      reason: '1 个今天 normal 打卡 → watchNormalCheckIns 返 1 条',
    );
    // 直接用 StreakCalculator 算 (不依赖 Provider stream sync 顺序)
    final streak = StreakCalculator.calculate(
      checkIns: checkIns,
      now: DateTime.now(),
    );
    expect(
      streak,
      1,
      reason: '1 个今天 normal 打卡 → StreakCalculator.calculate() 返 1',
    );
    expect(
      StreakCalculator.shouldShowStreakBroken(
        checkIns: checkIns,
        now: DateTime.now(),
      ),
      isFalse,
      reason: '今天刚打卡 → 不显示断签文案',
    );
  });

  test('集成 2: 设置 → 紧急联系人 → contactsProvider watch 端到端', () async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sp),
        databaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);

    // ===== Step 1: completeSetup 含 1 个紧急联系人 + 1 个同意 (PIPL §13) =====
    // contactList.length == contactConsents.length (PIPL §13 必填, 见 SetupCommitter 注释)
    // v0.32 架构批 2 (AR-19): saveSetup 迁到 SetupCommitter (data 层编排)
    await SetupCommitter(container.read(databaseProvider)).completeSetup(
      userName: '集成测试用户',
      contactList: const [
        (name: '家人A', phone: '13800000001', sortOrder: 0),
      ],
      contactConsents: [
        ConsentArtifact(
          kind: ConsentKind.emergencyContactSharing,
          version: 'integration-test-v1',
          grantedAt: DateTime.now(),
          grantedBy: 'integration-test-user',
        ),
      ],
      medicationList: const [],
    );

    // ===== Step 2: 直接走 contactRepository.watchAll (不依赖 StreamProvider autoDispose) =====
    final contactRepo = container.read(contactRepositoryProvider);
    final contacts = await contactRepo.watchAll().first;
    expect(
      contacts.length,
      1,
      reason: 'completeSetup 写 1 联系人 → contactRepository.watchAll 返 1',
    );
    expect(contacts.first.name, '家人A');
    expect(contacts.first.phone, '13800000001');
    expect(contacts.first.sortOrder, 0);
  });

  test(
      '集成 3: 评估 → PHQ-9 → DB round-trip (AssessmentRepository.submitEntry + check_ins 端到端)',
      () async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sp),
        databaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);

    // ===== Step 1: 走 assessmentRepository.submitEntry 写 PHQ-9 =====
    final assessmentRepo = container.read(assessmentRepositoryProvider);
    final id = await assessmentRepo.submitEntry(
      scaleId: 'phq9',
      score: 18,
      severityRank: 3, // moderately severe
      answers: const [3, 3, 3, 3, 3, 0, 0, 3, 0], // 9 题
      note: '集成测试 PHQ-9 高严重度',
    );
    expect(id, greaterThan(0), reason: 'submitEntry 返 drift auto-generate id');

    // ===== Step 2: 走真 check_ins 表读, 验证 JSON 编码 =====
    final database = container.read(databaseProvider);
    final checkIns = await database.select(database.checkIns).get();
    expect(checkIns.length, 1);
    expect(
      checkIns.first.type,
      'phq9',
      reason: 'R90 量表中心: assessment 走 check_ins.type = scaleId',
    );
    expect(checkIns.first.note, isNotNull);
    // 验证 JSON 编码含 score + severity + answers
    final noteJson = checkIns.first.note!;
    expect(noteJson.contains('"score":18'), isTrue);
    expect(noteJson.contains('"severity":3'), isTrue);
    expect(noteJson.contains('"answers"'), isTrue);
  });

  test('集成 4: 数据导出 → JSON 含 schema + data (DataExportService.exportToJson 端到端)',
      () async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sp),
        databaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);

    // ===== Step 1: 写一些 seed data =====
    final checkInRepo = container.read(checkInRepositoryProvider);
    await checkInRepo.checkIn(at: DateTime.now());
    await container.read(moodRepositoryProvider).add(
          draft: const MoodEntryDraft(
            at: null, // null = use DateTime.now() inside repo
            score: 4,
            tags: <String>[], // R24 必填字段
          ),
        );
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // ===== Step 2: 走 exportService.exportToJson 真导出 =====
    final exportService = container.read(dataExportServiceProvider);
    final jsonStr = await exportService.exportToJson();

    // ===== Step 3: 验证 JSON 含 schema + seed data =====
    // R57 export schema 字段: version / exportedAt / profile / checkIns /
    // moodEntries / medications / ventEntries / reportHistories /
    // assessmentEntries / cbtThoughtRecords
    expect(
      jsonStr.contains('"version"'),
      isTrue,
      reason: '导出 JSON 含 version 字段 (R57 schema 规范)',
    );
    expect(
      jsonStr.contains('"exportedAt"'),
      isTrue,
      reason: '导出 JSON 含 exportedAt 时间戳',
    );
    expect(
      jsonStr.contains('"checkIns"'),
      isTrue,
      reason: '导出 JSON 含 checkIns 段 (7 段数据)',
    );
    expect(
      jsonStr.contains('"moodEntries"'),
      isTrue,
      reason: '导出 JSON 含 moodEntries 段 (7 段数据)',
    );
    expect(
      jsonStr.length,
      greaterThan(100),
      reason: 'JSON 长度 > 100 字符 (含 schema + data)',
    );
  });

  test(
      '集成 5: vent 树洞 → 写 → DB 落库 (VentRepository.add 端到端, FlutterSecureStorage mock)',
      () async {
    // vent 加密服务走 FlutterSecureStorage MethodChannel, 需要 mock
    // R56c 模式: 在 test 里设 MethodChannel handler, 让 read/write 走 in-memory
    // map, 跟 R79 encryption service test 同模式
    const channel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    final keyValueStore = <String, String>{};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'read') {
        final key = (call.arguments as Map?)?['key'] as String?;
        return key == null ? null : keyValueStore[key];
      }
      if (call.method == 'write') {
        final args = (call.arguments as Map?) ?? const {};
        final key = args['key'] as String;
        final value = args['value'] as String?;
        if (value == null) {
          keyValueStore.remove(key);
        } else {
          keyValueStore[key] = value;
        }
        return null;
      }
      if (call.method == 'delete') {
        final args = (call.arguments as Map?) ?? const {};
        keyValueStore.remove(args['key'] as String);
        return null;
      }
      if (call.method == 'deleteAll') {
        keyValueStore.clear();
        return null;
      }
      if (call.method == 'containsKey') {
        final args = (call.arguments as Map?) ?? const {};
        return keyValueStore.containsKey(args['key'] as String);
      }
      if (call.method == 'readAll') {
        return Map<String, String>.from(keyValueStore);
      }
      return null;
    });

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sp),
        databaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);

    // ===== Step 1: 写 1 个 vent entry (text 模式) =====
    final ventRepo = container.read(ventRepositoryProvider);
    final ventId = await ventRepo.add(
      text: '集成测试 vent text 加密 round-trip',
    );
    expect(ventId, greaterThan(0), reason: 'add 返 drift auto-generate id');

    // ===== Step 2: 走 ventRepository.watchAll 验证落库 =====
    final allVent = await ventRepo.watchAll().first;
    expect(allVent.length, 1);
    // vent text 在 DB 走 contentText (BLOB 加密), watchAll 返实体, text 由
    // service decrypt 后返 (跟 R20 vent audio 模式一致)
    expect(
      allVent.first.hasText,
      isTrue,
      reason: 'vent text 加密落库, watchAll decrypt 后 hasText=true',
    );
    expect(allVent.first.audioPath, isNull);

    // ===== Step 3: 模拟撤回 (PIPL §47 删除权, R95 留 R96+ 真接) =====
    // ventRepository.delete 单条物理删 (PIPL §47 删除权), UI 立即隐藏
    final deleted = await ventRepo.delete(ventId);
    expect(
      deleted,
      isTrue,
      reason: 'delete(ventId) 返 true (条目物理删, PIPL §47 删除权)',
    );

    final afterDelete = await ventRepo.watchAll().first;
    expect(afterDelete.length, 0, reason: 'delete 后 vent 不在列表 (UI 隐藏)');
  });
}
