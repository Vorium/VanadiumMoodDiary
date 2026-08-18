// v1.1.0 R113 (BUG 4): 新建烦恼 + mood 保存失败 → 孤儿主题回滚回归测试
//
// 修前: _save 先 worryThreadRepository.create 再 moodRepository.add —
// mood 保存失败时新主题已入库却无任何记录引用, 永远躺在"进行中"列表
// (孤儿主题, 无 UI 入口可删绑定)。
// 修后: 记 createdThreadId, catch 里 best-effort delete 回滚 (回滚失败走
// swallowError 不阻断错误提示)。
//
// 覆盖:
// 1. 选"新建烦恼" + 保存 → mood add 抛 → create 调 1 次 + delete(createdId)
//    调 1 次 (回滚)
// 2. 无 unhandled error + 错误 snackbar ('保存失败：…')
//
// 依赖 (跟 mood_recorder_status_phrase_round5_test 同款):
// - 绕开 Dialog 直接挂 MoodRecorderPage 到 Scaffold body
// - _FakeMoodAudioService + moodRepositoryProvider (add 抛) +
//   worryThreadRepositoryProvider (记录 create/delete 调用) override
// - 保存 gate 走 cbtDraftProvider.updateField(situation:) (hasCbtContent)
// - 烦恼选择器 UI 流程: tap '没有关联烦恼' → bottom sheet → tap '新建烦恼'

import 'package:chroniccare/core/data/services/mood_audio_service.dart';
import 'package:chroniccare/domain/entities/mood_entry_draft.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/entities/worry_thread_entity.dart';
import 'package:chroniccare/domain/repositories/mood_repository.dart';
import 'package:chroniccare/domain/repositories/worry_thread_repository.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/mood_recorder_page.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/mood_providers.dart';
import 'package:chroniccare/presentation/providers/worry_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fake MoodAudioService — 跟 R91 mood_dialog_period_round91 同款
class _FakeMoodAudioService implements MoodAudioService {
  @override
  Future<bool> initialize() async => false;
  @override
  bool get isRecording => false;
  @override
  bool get isSttListening => false;
  @override
  Duration get recordingElapsed => Duration.zero;
  @override
  Stream<String> get sttTranscriptStream => const Stream.empty();
  @override
  Future<void> startRecording({
    required void Function(Duration elapsed) onTick,
    required void Function() onMaxReached,
  }) async {}
  @override
  Future<void> pauseRecording() async {}
  @override
  Future<void> resumeRecording() async {}
  @override
  bool get isPaused => false;
  @override
  Future<MoodAudioResult?> stopRecording() async => null;
  @override
  Future<void> cancelRecording() async {}
  @override
  Future<void> stopStt() async {}
  @override
  Future<void> dispose() async {}
}

/// add 必抛的 MoodRepository — 触发保存失败路径
class _ThrowingMoodRepository implements MoodRepository {
  int addCalls = 0;

  @override
  Future<int> add({required MoodEntryDraft draft}) async {
    addCalls++;
    throw Exception('db write failed');
  }

  @override
  Future<int> delete(int id) async => id;

  @override
  Stream<List<MoodEntryEntity>> watchAll() => Stream.value(const []);

  @override
  Stream<List<MoodEntryEntity>> watchToday() => Stream.value(const []);

  @override
  Stream<List<MoodEntryEntity>> watchByThread(int threadId) =>
      Stream.value(const []);

  @override
  Stream<MoodEntryEntity?> watchLatest() => Stream.value(null);
}

/// 记录 create/delete 调用的 WorryThreadRepository
class _FakeWorryThreadRepository implements WorryThreadRepository {
  int createCalls = 0;
  final List<int> deleted = [];

  @override
  Stream<List<WorryThreadEntity>> watchOpen() => Stream.value(const []);

  @override
  Stream<List<WorryThreadEntity>> watchResolved() => Stream.value(const []);

  @override
  Future<WorryThreadEntity?> getById(int id) async => null;

  @override
  Future<int> create({required String title, required DateTime at}) async {
    createCalls++;
    return 42;
  }

  @override
  Future<int> resolve(int id, {required DateTime at}) async => id;

  @override
  Future<int> reopen(int id) async => id;

  @override
  Future<int> rename(int id, String title) async => id;

  @override
  Future<int> delete(int id) async {
    deleted.add(id);
    return id;
  }
  @override
  Future<void> noteRelapse(int id, {required DateTime at}) async {}
}

void main() {
  late SharedPreferences sp;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    sp = await SharedPreferences.getInstance();
  });

  /// 800x2600 模拟手机视口 (round5 同款 + 烦恼选择器 section)
  void setBigView(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget wrap({
    required _ThrowingMoodRepository moodRepo,
    required _FakeWorryThreadRepository worryRepo,
  }) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sp),
        moodAudioServiceProvider.overrideWithValue(_FakeMoodAudioService()),
        moodRepositoryProvider.overrideWithValue(moodRepo),
        worryThreadRepositoryProvider.overrideWithValue(worryRepo),
        worryOpenProvider.overrideWith((ref) => Stream.value(const [])),
        worryResolvedProvider.overrideWith((ref) => Stream.value(const [])),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('zh'),
        home: Scaffold(body: MoodRecorderPage()),
      ),
    );
  }

  testWidgets('新建烦恼 + mood 保存失败 → create 1 次 + delete(42) 回滚 1 次',
      (tester) async {
    setBigView(tester);
    final moodRepo = _ThrowingMoodRepository();
    final worryRepo = _FakeWorryThreadRepository();
    await tester.pumpWidget(wrap(moodRepo: moodRepo, worryRepo: worryRepo));
    await tester.pumpAndSettle();

    // 保存 gate: situation 非空 = hasCbtContent (round5 同款)
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MoodRecorderPage)),
    );
    container
        .read(cbtDraftProvider.notifier)
        .updateField(situation: 'round 113');
    await tester.pumpAndSettle();

    // 烦恼选择器: 打开 bottom sheet → 选"新建烦恼"
    await tester.ensureVisible(find.text('没有关联烦恼'));
    await tester.tap(find.text('没有关联烦恼'));
    await tester.pumpAndSettle();
    expect(find.text('关联烦恼'), findsOneWidget);
    await tester.tap(find.text('新建烦恼'));
    await tester.pumpAndSettle();
    // 选择后 field label 变成"新建烦恼"
    expect(find.text('新建烦恼'), findsOneWidget);

    // 保存 → create(42) → mood add 抛 → 回滚 delete(42)
    await tester.ensureVisible(find.text('保存'));
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(moodRepo.addCalls, 1, reason: '保存必调 moodRepository.add');
    expect(worryRepo.createCalls, 1, reason: '新建烦恼必调 create 1 次');
    expect(
      worryRepo.deleted,
      [42],
      reason: 'mood 保存失败必回滚删除本次新建主题; '
          '修前 0 delete → 孤儿主题残留"进行中"列表',
    );
    expect(
      find.textContaining('保存失败'),
      findsOneWidget,
      reason: '保存失败应显示错误 snackbar (snackbarActionSave 模板)',
    );
    expect(tester.takeException(), isNull);

    // 排空错误 snackbar 4s 计时器
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
