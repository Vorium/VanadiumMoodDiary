// v0.30 round 91 (sub-spec 7 日常追踪 / Task 2): mood_dialog period 字段 行为锁定
//
// 覆盖 (TDD red→green):
// 1. 渲染: MoodRecorderPage 挂载后, period dropdown (label "时段") 可见
// 2. 提交: cbtDraftProvider 写 period='morning' + 填 situation → 点保存
//          → moodRepository.add 收到 draft.period == 'morning'
//
// 设计要点 (跟 R80 mood_recorder_round80 + R84 cbt_thought_record 同款):
// - 绕开 Dialog (production layout 在 widget test 触发 Expanded 错误, 见
//   cbt_thought_record_flow_round84 header) — 直接挂 MoodRecorderPage 到
//   Scaffold body, 3 栏 mode 默认, 无 wizard Expanded, 可在测试中布局
// - 覆写 ProviderScope: sharedPreferencesProvider (thoughtRecordLevelProvider 用)
//   + moodAudioServiceProvider (FakeMoodAudioService, R31 模式) +
//   moodRepositoryProvider (FakeMoodRepository 捕获 add() 调用)
// - 测试 2 走 state 模拟: notifier.updateField(period: 'morning', situation: 'x')
//   (跟 dropdown 的 onChanged 行为一致, 比测 menu item 简单)
// - 保存按钮靠 hasCbtContent 判断 (situation 非空即通过)
import 'dart:async';

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

/// Fake MoodAudioService — 跟 R80 mood_recorder_round80 同款
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

/// Fake MoodRepository — 捕获 add() 调用, 给 test 2 验 entry.period
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
  Stream<MoodEntryEntity?> watchLatest() => Stream.value(
      _store.isNotEmpty ? _store.last : null,);
}

void main() {
  late SharedPreferences sp;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    sp = await SharedPreferences.getInstance();
  });

  /// 800x2000 模拟手机视口, MoodRecorderPage 全内容 (3 栏 + period + tags + audio + save) 可见
  void setBigView(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2000);
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

  testWidgets('mood_dialog 渲染 period dropdown (label "时段" + 默认 "未指定")',
      (tester) async {
    setBigView(tester);
    await tester.pumpWidget(wrap(fakeRepo: _FakeMoodRepository()));
    await tester.pumpAndSettle();

    // period label 可见 (moodDialogPeriodLabel = "时段")
    expect(find.text('时段'), findsOneWidget);
    // dropdown 默认值 "未指定" (moodPeriodUnspecified) 可见
    expect(find.text('未指定'), findsOneWidget);
  });

  testWidgets('选 period morning → 提交后 entry.period == "morning"',
      (tester) async {
    setBigView(tester);
    final fakeRepo = _FakeMoodRepository();
    await tester.pumpWidget(wrap(fakeRepo: fakeRepo));
    await tester.pumpAndSettle();

    // 拿 ProviderContainer, 走 cbtDraftProvider 模拟 dropdown onChanged
    // (PeriodField.onChanged(period: 'morning') → notifier.updateField)
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MoodRecorderPage)),
    );
    container.read(cbtDraftProvider.notifier).updateField(
          period: 'morning',
          situation: 'morning test',
        );
    await tester.pumpAndSettle();

    // 点保存按钮 (l10n.commonSave = "保存")
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    // 验 moodRepository.add 收到 period='morning'
    expect(
      fakeRepo.lastAddedDraft,
      isNotNull,
      reason: '点保存后 MoodRepository.add 应被调',
    );
    expect(
      fakeRepo.lastAddedDraft!.period,
      'morning',
      reason: 'cbtDraftProvider 写 period → save 时透传给 repository',
    );
  });
}
