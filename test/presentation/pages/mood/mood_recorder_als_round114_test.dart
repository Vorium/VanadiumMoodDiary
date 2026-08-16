// v1.1.0 R114 (Wave D, spec §5.5): mood recorder ALS 化测试
//
// 覆盖 (apple-design F-mood 闭环):
// 1. 72pt 圆形按钮渲染 — MoodScoreButtons 5 个圆形 72x72 (AnimatedContainer
//    width==height==72), 宽视口不收缩
// 2. spring 选中态 — 点第 4 档 → 该档 Transform.scale 进行中 (≠1.0),
//    pumpAndSettle 后收敛 1.0, cbtDraftProvider.score 更新
// 3. reduce-motion 归零 — disableAnimations=true 时点第 5 档, 单帧 pump
//    后 scale 立即 == 1.0 (无 spring 弹跳)
// 4. ALS section — MoodRecorderPage 内 2 个 AppleListSection (情绪评分组
//    + 记录内容组), 标题走 ARB key
//
// 模式: 跟 R91 mood_dialog_period_round91 / R5 status_phrase 同款 —
// ProviderScope overrides + MaterialApp + 大视口 + 绕开 Dialog 直挂
// MoodRecorderPage 到 Scaffold body。
import 'package:chroniccare/core/data/services/mood_audio_service.dart';
import 'package:chroniccare/domain/entities/mood_entry_draft.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/repositories/mood_repository.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/mood_recorder_page.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/mood_providers.dart';
import 'package:chroniccare/presentation/providers/worry_providers.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/mood_score_buttons.dart';
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

/// Fake MoodRepository — 不被本测试直接调, 仅满足 override 链
class _FakeMoodRepository implements MoodRepository {
  @override
  Future<int> add({required MoodEntryDraft draft}) async => 1;
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

  Widget wrap({bool disableAnimations = false}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sp),
        moodAudioServiceProvider.overrideWithValue(_FakeMoodAudioService()),
        moodRepositoryProvider.overrideWithValue(_FakeMoodRepository()),
        // v1.1.0 round 9 (F1): MoodRecorderPage 内嵌 WorrySelectorField
        worryOpenProvider.overrideWith((ref) => Stream.value(const [])),
        worryResolvedProvider.overrideWith((ref) => Stream.value(const [])),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(disableAnimations: disableAnimations),
            child: const MoodRecorderPage(),
          ),
        ),
      ),
    );
  }

  /// 72pt 圆形: MoodScoreButtons 下 5 个 AnimatedContainer (圆形面)
  ///
  /// AnimatedContainer 不暴露 width/height getter (走 constraints.tightFor),
  /// 用 constraints 判尺寸。
  Finder circleOf(double size) => find.descendant(
        of: find.byType(MoodScoreButtons),
        matching: find.byWidgetPredicate(
          (w) =>
              w is AnimatedContainer &&
              w.constraints ==
                  BoxConstraints.tightFor(width: size, height: size),
        ),
      );

  /// 某档圆形按钮当前 spring scale (Transform.scale matrix m00 = X 轴 scale)
  ///
  /// 不能用 getMaxScaleOnAxis: Transform.scale 矩阵 z 轴恒 1.0,
  /// max() 会把 <1.0 的进行中 scale 掩盖成 1.0。
  double scaleOf(WidgetTester tester, int score) {
    final t = tester.widget<Transform>(
      find.byKey(ValueKey('mood-score-scale-$score')),
    );
    return t.transform.storage[0];
  }

  testWidgets('1) 72pt 圆形按钮渲染 — 5 个 72x72 圆形 + 5 档 emoji + ALS 2 组',
      (tester) async {
    setBigView(tester);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.byType(MoodScoreButtons), findsOneWidget);
    expect(circleOf(72), findsNWidgets(5), reason: '宽视口 5 个圆形全 72pt');
    for (final emoji in ['😢', '😟', '😐', '🙂', '😄']) {
      expect(
        find.descendant(
          of: find.byType(MoodScoreButtons),
          matching: find.text(emoji),
        ),
        findsOneWidget,
        reason: '5 档标准人脸 emoji 各一个',
      );
    }

    // ALS 2 组 (情绪评分组 / 记录内容组) + ARB title
    expect(find.byType(AppleListSection), findsNWidgets(2));
    expect(find.text('情绪评分'), findsOneWidget);
    expect(find.text('记录内容'), findsOneWidget);
  });

  testWidgets('2) spring 选中态 — 点第 4 档 scale 进行中 → settle 1.0 + score 更新',
      (tester) async {
    setBigView(tester);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    // 初始 (score=3) 所有按钮都停在终态 scale 1.0
    expect(scaleOf(tester, 4), 1.0);

    await tester.tap(
      find.descendant(
        of: find.byType(MoodScoreButtons),
        matching: find.text('🙂'),
      ),
    );
    // spring 起步后 50ms: 值在 0→1 途中, scale = 0.92 + 0.08t ≠ 1.0
    await tester.pump(const Duration(milliseconds: 50));
    final midFlight = scaleOf(tester, 4);
    expect(
      midFlight,
      isNot(1.0),
      reason: 'Spring.standard 进行中 scale 应偏离终态 (实测 $midFlight)',
    );

    await tester.pumpAndSettle();
    // SpringSimulation isDone 容差内残留极轻过冲 (~1.000005), 用 closeTo
    expect(scaleOf(tester, 4), closeTo(1.0, 0.01), reason: 'spring 收敛回 1.0');

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MoodRecorderPage)),
    );
    expect(
      container.read(cbtDraftProvider).draft.score,
      4,
      reason: '点第 4 档 → updateScore(4) 落 cbtDraftProvider',
    );
  });

  testWidgets('3) reduce-motion 归零 — disableAnimations 时选中直跳 1.0 无弹跳',
      (tester) async {
    setBigView(tester);
    await tester.pumpWidget(wrap(disableAnimations: true));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(MoodScoreButtons),
        matching: find.text('😄'),
      ),
    );
    // 单帧 pump (无 spring 时间): scale 必须已 == 1.0 (didUpdateWidget
    // 检测 reduce-motion 直跳终态, 不播 SpringSimulation)
    await tester.pump();
    expect(
      scaleOf(tester, 5),
      1.0,
      reason: 'reduce-motion 下选中态 0 弹跳, scale 立即终态',
    );
    await tester.pumpAndSettle();
  });

  testWidgets('4) 窄视口收缩 — 5 个圆形按比例收缩 ≥48pt 触达下限', (tester) async {
    // 窄屏 (250 逻辑宽) 直挂 MoodScoreButtons: (250-48)/5 = 40.4 < 48
    // → clamp 到 48pt 下限 (≥ Apple HIG 44), 不溢出
    tester.view.physicalSize = const Size(250, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: Scaffold(
            body: MoodScoreButtons(
              value: 3,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MoodScoreButtons), findsOneWidget);
    expect(
      circleOf(48),
      findsNWidgets(5),
      reason: '250pt 宽装不下 5×72 → 收缩到 48pt 下限 (≥ Apple HIG 44)',
    );
    expect(tester.takeException(), isNull, reason: '无 layout overflow');
  });
}
