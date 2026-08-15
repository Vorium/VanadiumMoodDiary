// v1.1.0 round 5d (Task 14): 记录 dialog 状态短语接入测试
//
// 覆盖 (TDD red→green):
// 1. 选预设短语 ('被治愈了') + 提交 → moodRepository.add 收到 draft.statusPhrase
//    且 fake 构造的 entity.statusPhrase == 所选短语
// 2. 自定义短语输入 + 提交 → statusPhrase == '自定义一句'
//
// 设计要点 (跟 R91 mood_dialog_period_round91 + R92 cbt_wizard_save 同款):
// - 绕开 Dialog 直接挂 MoodRecorderPage 到 Scaffold body (3 栏默认)
// - _FakeMoodAudioService + _FakeMoodRepository (捕获 lastAddedDraft)
// - score 走 cbtDraftProvider.notifier.updateScore(4) → StatusPhraseField
//   重算 positive 组 (被治愈了可见)
// - 保存 gate (hasText/hasAudio/hasCbtContent) 用 updateField(situation:) 通过

import 'package:chroniccare/core/data/services/mood_audio_service.dart';
import 'package:chroniccare/domain/entities/mood_entry_draft.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/repositories/mood_repository.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/mood_recorder_page.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/mood_providers.dart';
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

/// Fake MoodRepository — 捕获 add() 调用
class _FakeMoodRepository implements MoodRepository {
  MoodEntryDraft? lastAddedDraft;
  final List<MoodEntryEntity> _store = [];

  @override
  Future<int> add({required MoodEntryDraft draft}) async {
    lastAddedDraft = draft;
    final id = _store.length + 1;
    _store.add(
      MoodEntryEntity(
        id: id,
        timestamp: draft.at ?? DateTime(2026, 8, 15),
        score: draft.score,
        period: draft.period,
        note: draft.note,
        situation: draft.situation,
        statusPhrase: draft.statusPhrase,
      ),
    );
    return id;
  }

  @override
  Future<int> delete(int id) async {
    _store.removeWhere((e) => e.id == id);
    return id;
  }

  @override
  Stream<List<MoodEntryEntity>> watchAll() =>
      Stream.value(List.unmodifiable(_store));

  @override
  Stream<List<MoodEntryEntity>> watchToday() => Stream.value(const []);

  @override
  Stream<MoodEntryEntity?> watchLatest() =>
      Stream.value(_store.isNotEmpty ? _store.last : null);
}

void main() {
  late SharedPreferences sp;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    sp = await SharedPreferences.getInstance();
  });

  /// 800x2600 模拟手机视口 (3 栏 + period + influence + tags + 状态短语 +
  /// note + audio + save 全可见, 与 R92 的 800x2400 相比多出短语 section)
  void setBigView(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget wrap({required _FakeMoodRepository fakeRepo}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sp),
        moodAudioServiceProvider.overrideWithValue(_FakeMoodAudioService()),
        moodRepositoryProvider.overrideWithValue(fakeRepo),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('zh'),
        home: Scaffold(body: MoodRecorderPage()),
      ),
    );
  }

  testWidgets('选预设短语 → 提交 → repository 收到 draft/entity.statusPhrase',
      (tester) async {
    setBigView(tester);
    final fakeRepo = _FakeMoodRepository();
    await tester.pumpWidget(wrap(fakeRepo: fakeRepo));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MoodRecorderPage)),
    );
    // score → 4: StatusPhraseField 展示 positive 组 ('被治愈了' 可见)
    container.read(cbtDraftProvider.notifier).updateScore(4);
    // 保存 gate: situation 非空 = hasCbtContent
    container
        .read(cbtDraftProvider.notifier)
        .updateField(situation: 'round 5d');
    await tester.pumpAndSettle();

    // 选短语
    await tester.ensureVisible(find.text('被治愈了'));
    await tester.tap(find.text('被治愈了'));
    await tester.pumpAndSettle();

    // 提交
    await tester.ensureVisible(find.text('保存'));
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(
      fakeRepo.lastAddedDraft,
      isNotNull,
      reason: '点保存后 moodRepository.add 应被调',
    );
    expect(
      fakeRepo.lastAddedDraft!.statusPhrase,
      '被治愈了',
      reason: '所选状态短语应透传到 draft',
    );
    expect(
      fakeRepo._store.last.statusPhrase,
      '被治愈了',
      reason: 'entity.statusPhrase == 所选短语',
    );
  });

  testWidgets('自定义短语输入 → 提交 → statusPhrase == 自定义短语',
      (tester) async {
    setBigView(tester);
    final fakeRepo = _FakeMoodRepository();
    await tester.pumpWidget(wrap(fakeRepo: fakeRepo));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MoodRecorderPage)),
    );
    container
        .read(cbtDraftProvider.notifier)
        .updateField(situation: 'round 5d custom');
    await tester.pumpAndSettle();

    // 自定义输入 (StatusPhraseField 的 TextField, hint 与 note 不同)
    final field = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == '或输入一句此刻的心情……',
    );
    expect(field, findsOneWidget);
    await tester.ensureVisible(field);
    await tester.enterText(field, '自定义一句');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('保存'));
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(fakeRepo.lastAddedDraft, isNotNull);
    expect(
      fakeRepo.lastAddedDraft!.statusPhrase,
      '自定义一句',
      reason: '自定义短语应透传到 draft',
    );
    expect(
      fakeRepo._store.last.statusPhrase,
      '自定义一句',
      reason: 'entity.statusPhrase == 自定义短语',
    );
  });
}
