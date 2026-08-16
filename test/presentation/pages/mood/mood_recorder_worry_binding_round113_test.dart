// v1.1.0 R113 (F1 烦恼闭环 audit gaps 3+4): 预绑定 SUCCESS 路径 + /mood/create?worry=<id> 路由
//
// 覆盖:
// 1. SUCCESS 路径: MoodRecorderPage(initialWorryThreadId: 42) 预绑定保存 —
//    moodRepository.add 捕获的 draft.worryThreadId == 42 且
//    worryThreadRepository.create 不被调用 (预绑定不得重复建主题)。
//    (mood_recorder_orphan_worry_round113_test 只覆盖 create-new 的失败回滚路径)
// 2. 路由绑定: 实路由 AppRoutes.all() initialLocation '/mood/create?worry=7' →
//    MoodRecorderPage 出现且 selector 显示绑定 thread title (query 解析实锤)。
//
// 依赖 (跟 mood_recorder_orphan_worry_round113_test 同款):
// - 绕开 Dialog 直接挂 MoodRecorderPage 到 Scaffold body
// - sharedPreferencesProvider (thoughtRecordLevelProvider) +
//   moodAudioServiceProvider (MoodRecorder, ventAudioEnabled=true) override
// - 保存 gate 走 cbtDraftProvider.updateField(situation:) (hasCbtContent)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chroniccare/core/data/services/mood_audio_service.dart';
import 'package:chroniccare/core/routing/app_routes.dart';
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

/// 捕获 add() draft 的 MoodRepository
class _CaptureMoodRepository implements MoodRepository {
  MoodEntryDraft? capturedDraft;
  int addCalls = 0;

  @override
  Future<int> add({required MoodEntryDraft draft}) async {
    addCalls++;
    capturedDraft = draft;
    return 1;
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

/// 记录 create 调用的 WorryThreadRepository (预绑定路径不应调 create)
class _FakeWorryThreadRepository implements WorryThreadRepository {
  int createCalls = 0;
  final List<WorryThreadEntity> open;

  _FakeWorryThreadRepository({this.open = const []});

  @override
  Stream<List<WorryThreadEntity>> watchOpen() =>
      Stream.value(List.unmodifiable(open));

  @override
  Stream<List<WorryThreadEntity>> watchResolved() => Stream.value(const []);

  @override
  Future<WorryThreadEntity?> getById(int id) async =>
      open.where((t) => t.id == id).firstOrNull;

  @override
  Future<int> create({required String title, required DateTime at}) async {
    createCalls++;
    return 99;
  }

  @override
  Future<int> resolve(int id, {required DateTime at}) async => id;

  @override
  Future<int> reopen(int id) async => id;

  @override
  Future<int> rename(int id, String title) async => id;

  @override
  Future<int> delete(int id) async => id;
}

WorryThreadEntity _open(int id, String title) => WorryThreadEntity(
      id: id,
      title: title,
      createdAt: DateTime(2026, 8, 15, 9),
      status: WorryStatus.open,
    );

void main() {
  late SharedPreferences sp;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    sp = await SharedPreferences.getInstance();
  });

  void setBigView(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  testWidgets('预绑定 SUCCESS: draft.worryThreadId == 42 且不重复 create',
      (tester) async {
    setBigView(tester);
    final moodRepo = _CaptureMoodRepository();
    final worryRepo = _FakeWorryThreadRepository(open: [_open(42, '考试焦虑')]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sp),
        moodAudioServiceProvider.overrideWithValue(_FakeMoodAudioService()),
        moodRepositoryProvider.overrideWithValue(moodRepo),
        worryThreadRepositoryProvider.overrideWithValue(worryRepo),
        worryOpenProvider.overrideWith((ref) => Stream.value(worryRepo.open)),
        worryResolvedProvider.overrideWith((ref) => Stream.value(const [])),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        const MoodRecorderPage(initialWorryThreadId: 42),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // 绑定可见: selector label 显示已绑定烦恼 title
    expect(find.text('考试焦虑'), findsOneWidget,
        reason: '预绑定后 selector 应显示 thread 42 的 title');

    // 保存 gate: situation 非空 = hasCbtContent (orphan 测试同款)
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MoodRecorderPage)),
    );
    container
        .read(cbtDraftProvider.notifier)
        .updateField(situation: 'round 113 binding');
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('保存'));
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(moodRepo.addCalls, 1, reason: '保存必调 moodRepository.add');
    expect(moodRepo.capturedDraft, isNotNull);
    expect(moodRepo.capturedDraft!.worryThreadId, 42,
        reason: '预绑定 SUCCESS 路径: draft 必须带上 initialWorryThreadId');
    expect(worryRepo.createCalls, 0,
        reason: '预绑定 (非 create-new) 不得调 worryThreadRepository.create — '
            '否则重复建主题');
    expect(find.byType(MoodRecorderPage), findsNothing,
        reason: '保存成功后页面应 pop 关闭 (生产路径 = 模态页)');
    expect(find.text('情绪已保存'), findsOneWidget, reason: '保存成功 snackbar');
    expect(tester.takeException(), isNull);

    // 排空 snackbar 计时器
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('路由 /mood/create?worry=7 → MoodRecorderPage 预绑定显示 title',
      (tester) async {
    setBigView(tester);
    final moodRepo = _CaptureMoodRepository();
    final worryRepo = _FakeWorryThreadRepository(open: [_open(7, '考试焦虑')]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sp),
        moodAudioServiceProvider.overrideWithValue(_FakeMoodAudioService()),
        moodRepositoryProvider.overrideWithValue(moodRepo),
        worryThreadRepositoryProvider.overrideWithValue(worryRepo),
        worryOpenProvider.overrideWith((ref) => Stream.value(worryRepo.open)),
        worryResolvedProvider.overrideWith((ref) => Stream.value(const [])),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/mood/create?worry=7',
          routes: AppRoutes.all(),
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(MoodRecorderPage), findsOneWidget,
        reason: '/mood/create 路由应渲染 MoodRecorderPage');
    expect(find.text('考试焦虑'), findsOneWidget,
        reason: 'query worry=7 解析为 initialWorryThreadId → selector 显示 '
            'thread 7 title (绑定链路: 路由 → 页面 → selector → 显示)');
    expect(tester.takeException(), isNull);
  });
}
