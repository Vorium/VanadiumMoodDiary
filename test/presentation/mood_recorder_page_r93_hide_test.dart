// v0.30 round 93 (test): mood_recorder_page 的 FeatureFlags.ventAudioEnabled gate
//
// R93 阶段 2: "所有需要真接的内容先隐藏" 策略
// R105: R104 起启用语音录制, ventAudioEnabled prod 默认改 true → MoodRecorder 默认渲染。
// 保留 setVentAudioEnabledForTest(false) 验证 gate 仍有效 (业务暂停时可隐藏)。
// MoodTextInput / MoodTags / CbtThreeColumnMode / PeriodField 保留。
//
// 2 case:
//   - case 1: ventAudioEnabled 默认 true → MoodRecorder 渲染
//   - case 2: ventAudioEnabled=false (override) → MoodRecorder 不渲染
//
// 测试模式: ProviderScope + MaterialApp 渲染 MoodRecorderPage (走静态 show() 方法)
// + cbtDraftProvider override (避免 initState 走 addPostFrameCallback 同步 SP)
import 'package:chroniccare/core/data/feature_flags.dart';
import 'package:chroniccare/core/data/services/mood_audio_service.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/mood_audio_section.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/mood_recorder_page.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';
import 'package:chroniccare/presentation/providers/mood_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 假 MoodAudioService — 测 mood_recorder 渲染时 recorder
/// widget 不会真调 platform channel
class _FakeMoodAudioService implements MoodAudioService {
  @override
  Future<bool> initialize() async => true;
  @override
  bool get isRecording => false;
  @override
  bool get isSttListening => false;
  @override
  Duration get recordingElapsed => Duration.zero;
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
  Stream<String> get sttTranscriptStream => const Stream.empty();
  @override
  Future<void> stopStt() async {}
  @override
  Future<void> dispose() async {}
}

void main() {
  late SharedPreferences mockSp;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    mockSp = await SharedPreferences.getInstance();
    FeatureFlags.resetForTest();
  });

  tearDown(FeatureFlags.resetForTest);

  Widget wrap() {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(mockSp),
        // cbtDraftProvider 走默认 (3 栏), initState addPostFrameCallback 同步
        // SP 后 cbtDraft.level = 3
        moodAudioServiceProvider.overrideWithValue(_FakeMoodAudioService()),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('zh'),
        home: Scaffold(body: MoodRecorderPage()),
      ),
    );
  }

  testWidgets(
      'R105 case 1: ventAudioEnabled 默认 true → MoodRecorder mic widget 渲染',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    // MoodRecorder widget (mic 录音 + 状态机) 渲染 (R104 启用语音录制)
    expect(
      find.byType(MoodRecorder),
      findsOneWidget,
      reason: 'R105: ventAudioEnabled 默认 true 时 MoodRecorder mic 可见',
    );
  });

  testWidgets('R93 case 2: ventAudioEnabled=false → MoodRecorder mic widget 隐藏',
      (tester) async {
    // ventAudioEnabled 有 setVentAudioEnabledForTest setter (R93 阶段 2 新增)
    FeatureFlags.setVentAudioEnabledForTest(false);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    // MoodRecorder widget 不渲染 (gate 仍有效, 业务暂停时可隐藏)
    expect(
      find.byType(MoodRecorder),
      findsNothing,
      reason: 'R93: ventAudioEnabled=false 时 MoodRecorder mic 隐藏',
    );
  });
}
