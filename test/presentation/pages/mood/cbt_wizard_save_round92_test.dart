// v0.30 round 92 (audit-fixes / P0 #11): CBT wizard 5/7 栏 "完成" 按钮触发父 save
//
// 覆盖 (TDD red→green):
// 1. 5 栏走完 5 步, 点 "完成" 按钮 → moodRepository.add 被调 (字段不丢)
// 2. 7 栏走完 7 步, 点 "完成" 按钮 → moodRepository.add 被调 (字段不丢)
//
// 设计要点:
// - 复用 R91 mood_dialog_period_round91_test 模式:
//   _FakeMoodRepository + _FakeMoodAudioService + ProviderScope override
// - 不走 PeriodField / tags / audio 等 UI 控件 (复杂); 直接走
//   cbtDraftProvider.notifier 模拟用户输入 (跟 R91 test 2 一致)
// - MoodRecorderPage 5/7 栏渲染时, wizard 完整显示 step, MoodRecorderPage
//   太长 → 测试视图调到 800x2400 保证所有 step 可见
// - bug 现状: 5/7 栏 wizard "完成" onPressed = Navigator.pop() → 字段丢失;
//   修法: wizard onSaveRequested callback, 父 _save() 走 repository.add

import 'package:chroniccare/core/data/services/mood_audio_service.dart';
import 'package:chroniccare/domain/entities/mood_entry_draft.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/repositories/mood_repository.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/mood_recorder_page.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/mood_providers.dart';
import 'package:chroniccare/domain/entities/thought_record_level.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fake MoodAudioService — 跟 R91 mood_dialog_period_round91_test 同款
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
        timestamp: draft.at ?? DateTime(2026, 8, 5),
        score: draft.score,
        period: draft.period,
        note: draft.note,
        situation: draft.situation,
        automaticThought: draft.automaticThought,
        evidenceFor: draft.evidenceFor,
        evidenceAgainst: draft.evidenceAgainst,
        alternativeThought: draft.alternativeThought,
        reratedScore: draft.reratedScore,
        coreBelief: draft.coreBelief,
        behaviorResponse: draft.behaviorResponse,
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
  Stream<List<MoodEntryEntity>> watchToday() => const Stream.empty();
}

void main() {
  late SharedPreferences sp;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    sp = await SharedPreferences.getInstance();
  });

  /// 800x2400 模拟手机视口, MoodRecorderPage 全内容 (5 栏 wizard 5 step +
  /// period + tags + audio + save) 可见。MoodRecorderPage 内部 SingleChildScrollView
  /// 滚动, 不需要担心溢出。
  void setBigView(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2400);
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

  /// 走完 5 栏 wizard 所有 step + 填字段
  void fillFiveColumnFields(WidgetTester tester, ProviderContainer container) {
    // 切到 5 栏 mode (setLevel 会跳到第一个未填 step)
    container.read(cbtDraftProvider.notifier).setLevel(ThoughtRecordLevel.five);
    // step 0 情境
    container
        .read(cbtDraftProvider.notifier)
        .updateField(situation: '今天开会迟到了');
    container.read(cbtDraftProvider.notifier).setStep(1);
    // step 1 自动思维
    container
        .read(cbtDraftProvider.notifier)
        .updateField(automaticThought: '同事会觉得我不靠谱');
    container.read(cbtDraftProvider.notifier).setStep(2);
    // step 2 score + 证据 (score 1-5, evidenceFor/Against 字符串)
    container.read(cbtDraftProvider.notifier).updateScore(2);
    container
        .read(cbtDraftProvider.notifier)
        .updateField(evidenceFor: '确实迟到了 10 分钟');
    container
        .read(cbtDraftProvider.notifier)
        .updateField(evidenceAgainst: '其他同事偶尔也迟到');
    container.read(cbtDraftProvider.notifier).setStep(3);
    // step 3 替代思维 + 重新评分
    container
        .read(cbtDraftProvider.notifier)
        .updateField(alternativeThought: '一次迟到不能说明所有问题');
    container
        .read(cbtDraftProvider.notifier)
        .updateField(reratedScore: 4);
    // 跳到 step 4 (5 栏确认页, lastStep = "完成" 按钮)
    container.read(cbtDraftProvider.notifier).setStep(4);
  }

  /// 走完 7 栏 wizard 所有 step + 填字段
  void fillSevenColumnFields(
      WidgetTester tester, ProviderContainer container,) {
    container.read(cbtDraftProvider.notifier).setLevel(ThoughtRecordLevel.seven);
    container
        .read(cbtDraftProvider.notifier)
        .updateField(situation: '今天开会迟到了');
    container.read(cbtDraftProvider.notifier).setStep(1);
    container
        .read(cbtDraftProvider.notifier)
        .updateField(automaticThought: '同事会觉得我不靠谱');
    container.read(cbtDraftProvider.notifier).setStep(2);
    container.read(cbtDraftProvider.notifier).updateScore(2);
    container
        .read(cbtDraftProvider.notifier)
        .updateField(evidenceFor: '确实迟到了 10 分钟');
    container
        .read(cbtDraftProvider.notifier)
        .updateField(evidenceAgainst: '其他同事偶尔也迟到');
    container.read(cbtDraftProvider.notifier).setStep(3);
    container
        .read(cbtDraftProvider.notifier)
        .updateField(alternativeThought: '一次迟到不能说明所有问题');
    container
        .read(cbtDraftProvider.notifier)
        .updateField(reratedScore: 4);
    container.read(cbtDraftProvider.notifier).setStep(4);
    // step 4 = 7 栏核心信念
    container
        .read(cbtDraftProvider.notifier)
        .updateField(coreBelief: '我应该完美');
    container.read(cbtDraftProvider.notifier).setStep(5);
    // step 5 = 7 栏行为应对
    container
        .read(cbtDraftProvider.notifier)
        .updateField(behaviorResponse: '下次提前 5 分钟准备');
    // 跳到 step 6 (7 栏确认页, lastStep = "完成" 按钮)
    container.read(cbtDraftProvider.notifier).setStep(6);
  }

  testWidgets(
      '5 栏 wizard 走完 5 步 → 点 "完成" 按钮 → moodRepository.add 被调 (字段不丢)',
      (tester) async {
    setBigView(tester);
    final fakeRepo = _FakeMoodRepository();
    await tester.pumpWidget(wrap(fakeRepo: fakeRepo));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MoodRecorderPage)),
    );
    fillFiveColumnFields(tester, container);
    await tester.pumpAndSettle();

    // 验现在在 step 4 (5 栏最后一步, 确认页)
    expect(container.read(cbtDraftProvider).stepIndex, 4);
    expect(container.read(cbtDraftProvider).level, ThoughtRecordLevel.five);

    // 点 "完成" 按钮 (l10n.moodCbtComplete = "完成")
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();

    // 验 moodRepository.add 被调, 字段不丢
    expect(fakeRepo.lastAddedDraft, isNotNull,
        reason: '5 栏 "完成" 按钮应触发父 save → moodRepository.add',);
    expect(fakeRepo.lastAddedDraft!.situation, '今天开会迟到了',
        reason: '5 栏 situation 字段应透传',);
    expect(fakeRepo.lastAddedDraft!.automaticThought, '同事会觉得我不靠谱',
        reason: '5 栏 automaticThought 字段应透传',);
    expect(fakeRepo.lastAddedDraft!.evidenceFor, '确实迟到了 10 分钟',
        reason: '5 栏 evidenceFor 字段应透传',);
    expect(fakeRepo.lastAddedDraft!.evidenceAgainst, '其他同事偶尔也迟到',
        reason: '5 栏 evidenceAgainst 字段应透传',);
    expect(fakeRepo.lastAddedDraft!.alternativeThought, '一次迟到不能说明所有问题',
        reason: '5 栏 alternativeThought 字段应透传',);
    expect(fakeRepo.lastAddedDraft!.reratedScore, 4,
        reason: '5 栏 reratedScore 字段应透传',);
    expect(fakeRepo.lastAddedDraft!.coreBelief, isNull,
        reason: '5 栏 coreBelief 应为 null (5 栏不包含)',);
  });

  testWidgets(
      '7 栏 wizard 走完 7 步 → 点 "完成" 按钮 → moodRepository.add 被调 (字段不丢)',
      (tester) async {
    setBigView(tester);
    final fakeRepo = _FakeMoodRepository();
    await tester.pumpWidget(wrap(fakeRepo: fakeRepo));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MoodRecorderPage)),
    );
    fillSevenColumnFields(tester, container);
    await tester.pumpAndSettle();

    // 验现在在 step 6 (7 栏最后一步, 确认页)
    expect(container.read(cbtDraftProvider).stepIndex, 6);
    expect(container.read(cbtDraftProvider).level, ThoughtRecordLevel.seven);

    // 点 "完成" 按钮
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();

    // 验 moodRepository.add 被调, 7 栏独有字段 (coreBelief / behaviorResponse) 透传
    expect(fakeRepo.lastAddedDraft, isNotNull,
        reason: '7 栏 "完成" 按钮应触发父 save → moodRepository.add',);
    expect(fakeRepo.lastAddedDraft!.situation, '今天开会迟到了');
    expect(fakeRepo.lastAddedDraft!.coreBelief, '我应该完美',
        reason: '7 栏 coreBelief 字段应透传',);
    expect(fakeRepo.lastAddedDraft!.behaviorResponse, '下次提前 5 分钟准备',
        reason: '7 栏 behaviorResponse 字段应透传',);
  });
}
