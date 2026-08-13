// v0.32 R110 round 7b-2: mood_audio_recorder_widget (589L god class) 补 0-test
//
// 覆盖 (全部走 serviceFactory fake, 完全不碰 record/speech_to_text 平台
// channel + 真实文件 IO):
// 1. idle 态: 显示"录音"按钮 + STT 不可用提示 + 无播放/重录按钮
// 2. 点录音 → 变"取消"按钮 + 计时器 0:00 + STT 可用时显示"正在聆听"
// 3. 录音中收 STT partial → 实时转写文本显示
// 4. 停止录音 → 已录 0:05 + snapshot 上抛 (audioPath/时长/transcript) +
//    播放/重录按钮出现
// 5. 重录 → snapshot 清空回 empty + 回到 idle
// 6. initialize() 返回 false → STT 不可用提示 (macro 分离: 未录音时)
//
// 注: 播放路径 (decryptToTemp + AudioPlayer) 依赖 platform channel +
// 真实文件, 已由 vent/mood audio service 层单测覆盖, 此处不测。

import 'dart:async';

import 'package:chroniccare/core/data/services/mood_audio_service.dart';
import 'package:chroniccare/core/data/services/mood_audio_storage.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/mood_audio_recorder_widget.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/mood_audio_types.dart';
import 'package:chroniccare/presentation/providers/mood_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 全内存 fake — 无真实录音, 手动驱动状态
class _FakeMoodAudioService implements MoodAudioService {
  bool sttAvailable = true;
  int _tickCount = 0;
  Duration recordingElapsed = Duration.zero;
  final _transcriptController = StreamController<String>.broadcast();

  final List<String> log = [];
  Timer? _tickTimer;

  @override
  Future<bool> initialize() async => sttAvailable;

  @override
  bool get isRecording => _recording;
  bool _recording = false;

  @override
  bool get isSttListening => false;

  @override
  Stream<String> get sttTranscriptStream => _transcriptController.stream;

  @override
  Future<void> startRecording({
    required void Function(Duration elapsed) onTick,
    required void Function() onMaxReached,
  }) async {
    log.add('start');
    _recording = true;
    _tickCount = 0;
    _tickTimer?.cancel();
    // 模拟 2 次 tick (100ms/次)
    _tickTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!_recording) {
        t.cancel();
        return;
      }
      _tickCount++;
      recordingElapsed = Duration(milliseconds: _tickCount * 100);
      onTick(recordingElapsed);
      if (_tickCount >= 2) t.cancel();
    });
  }

  @override
  Future<MoodAudioResult?> stopRecording() async {
    log.add('stop');
    _recording = false;
    _tickTimer?.cancel();
    return const MoodAudioResult(
      plainPath: '/tmp/fake.m4a',
      durationMs: 5000,
    );
  }

  @override
  Future<void> cancelRecording() async {
    log.add('cancel');
    _recording = false;
    _tickTimer?.cancel();
  }

  @override
  Future<void> stopStt() async {}

  @override
  Future<void> dispose() async {
    log.add('dispose');
  }
}

/// EncryptedAudioStorage 子类 — 覆盖文件 IO, 全内存
class _FakeMoodAudioStorage extends MoodAudioStorage {
  @override
  Future<String> newAudioPath() async => '/fake/rec.m4a.enc';

  @override
  Future<void> encryptAndWrite({
    required String plainPath,
    required String encryptedPath,
  }) async {}

  @override
  Future<bool> deleteAudio(String path) async => true;
}

Widget _wrap(_FakeMoodAudioService service,
    {MoodRecorderController? controller}) {
  final ctrl =
      controller ?? MoodRecorderController(serviceFactory: () => service);
  addTearDown(ctrl.dispose);
  return ProviderScope(
    overrides: [
      moodAudioServiceProvider.overrideWithValue(service),
      moodAudioStorageProvider.overrideWithValue(_FakeMoodAudioStorage()),
    ],
    child: MaterialApp(
      theme: ThemeData.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 800,
          child: MoodRecorder(controller: ctrl),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('1) idle 态: 录音按钮 + STT 可用无提示', (tester) async {
    await tester.pumpWidget(_wrap(_FakeMoodAudioService()..sttAvailable = true));
    await tester.pumpAndSettle();

    expect(find.text('录语音'), findsOneWidget);
    expect(find.text('该设备暂不支持语音转文字'), findsNothing);
    expect(find.byIcon(Icons.play_arrow), findsNothing);
    expect(find.byIcon(Icons.refresh), findsNothing);
  });

  testWidgets('2) STT 不可用 → 录音前显示提示', (tester) async {
    await tester.pumpWidget(_wrap(_FakeMoodAudioService()..sttAvailable = false));
    await tester.pumpAndSettle();

    expect(find.text('该设备暂不支持语音转文字'), findsOneWidget);
  });

  testWidgets('3) 点录音 → 取消按钮 + STT 聆听标记 + 计时器', (tester) async {
    await tester.pumpWidget(_wrap(_FakeMoodAudioService()..sttAvailable = true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('录语音'));
    // 录音中 _RecordingTimer (100ms 周期) 持续重建 → 不能 pumpAndSettle
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('取消'), findsOneWidget);
    expect(find.text('识别中……'), findsOneWidget);
    expect(find.text('0:00'), findsOneWidget);

    // 收尾: 停止录音, 避免 widget 周期 timer 悬挂
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
  });

  testWidgets('4) 录音中 STT partial → 实时转写', (tester) async {
    final service = _FakeMoodAudioService();
    await tester.pumpWidget(_wrap(service));
    await tester.pumpAndSettle();

    await tester.tap(find.text('录语音'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    service._transcriptController.add('今天心情好多了');
    await tester.pump();

    expect(find.text('今天心情好多了'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
  });

  testWidgets('5) 停止录音 → 已录时长 + snapshot 上抛 + 播放/重录出现',
      (tester) async {
    final service = _FakeMoodAudioService();
    final controller = MoodRecorderController(serviceFactory: () => service);
    await tester.pumpWidget(_wrap(service, controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('录语音'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(find.text('已录 0:05'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);

    final snap = controller.snapshot.value;
    expect(snap.audioPath, '/fake/rec.m4a.enc');
    expect(snap.audioDurationMs, 5000);
  });

  testWidgets('6) 重录 → snapshot 清空 + 回 idle', (tester) async {
    final service = _FakeMoodAudioService();
    final controller = MoodRecorderController(serviceFactory: () => service);
    await tester.pumpWidget(_wrap(service, controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('录语音'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();

    expect(controller.snapshot.value.audioPath, isNull);
    expect(find.byIcon(Icons.play_arrow), findsNothing);
    expect(find.text('录语音'), findsOneWidget);
  });
}
