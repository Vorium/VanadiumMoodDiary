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
//
// v0.32 R112 (E-01): dispose 期 ref.read 泄漏链修复测试。
// Riverpod 3.4.2 `ref.read` 在 widget unmount 后无条件抛 StateError
// (非 assert), 被 dispose 链的 swallowError 吞掉 → MoodAudioService
// native 句柄泄漏 + 播放后明文 temp 文件永不删 (PIPL §28)。
// 修法 = B1-11 同款字段缓存 (initState 捕获 service/storage 进 State 字段,
// dispose 链只用字段不碰 ref)。新增:
// 7. 录音中 unmount → fake service 收到 cancel + dispose (链必须跑完)
// 8. 播放中 unmount → temp 解密文件被删 (cleanupTempFile 必须跑完)
// 9. 源码 lock-in: _disposeResources / cleanupTempFile 体不出现 ref.read

import 'dart:async';
import 'dart:io';

import 'package:audioplayers_platform_interface/src/audioplayers_platform.dart'
    show AudioplayersPlatform;
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart'
    show AudioplayersPlatformInterface, GlobalAudioplayersPlatformInterface;
import 'package:audioplayers_platform_interface/src/global_audioplayers_platform.dart'
    show GlobalAudioplayersPlatform;
import 'package:chroniccare/core/data/services/mood_audio_service.dart';
import 'package:chroniccare/core/data/services/mood_audio_storage.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/mood_audio_recorder_widget.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/mood_audio_types.dart';
import 'package:chroniccare/presentation/providers/mood_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 全内存 fake — 无真实录音, 手动驱动状态
class _FakeMoodAudioService implements MoodAudioService {
  bool sttAvailable = true;
  int _tickCount = 0;
  @override
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
  @override
  Future<void> pauseRecording() async {}

  @override
  Future<void> resumeRecording() async {}

  @override
  bool get isPaused => false;

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
    await _transcriptController.close();
  }
}

/// EncryptedAudioStorage 子类 — 覆盖文件 IO, 全内存
class _FakeMoodAudioStorage extends MoodAudioStorage {
  final List<String> deletedTempFiles = [];

  @override
  Future<String> newAudioPath() async => '/fake/rec.m4a.enc';

  @override
  Future<void> encryptAndWrite({
    required String plainPath,
    required String encryptedPath,
  }) async {}

  @override
  Future<bool> deleteAudio(String path) async => true;

  @override
  Future<String> decryptToTemp(String encryptedPath) async =>
      '/fake/decrypt.m4a';

  @override
  Future<void> deleteTempFile(String tempPath) async {
    deletedTempFiles.add(tempPath);
  }
}

Widget _wrap(
  _FakeMoodAudioService service, {
  MoodRecorderController? controller,
  MoodAudioStorage? storage,
}) {
  final ctrl =
      controller ?? MoodRecorderController(serviceFactory: () => service);
  addTearDown(ctrl.dispose);
  return ProviderScope(
    overrides: [
      moodAudioServiceProvider.overrideWithValue(service),
      moodAudioStorageProvider
          .overrideWithValue(storage ?? _FakeMoodAudioStorage()),
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
  setUp(() {
    // audioplayers 的 GlobalAudioScope + platform 是进程级单例, _initCompleter
    // 跨 testWidgets 残留 → 第 2 个测试的 AudioPlayer._create() 挂在
    // ensureInitialized (await 幽灵 completer)。每个测试重置 platform,
    // 保证 _lastGlobal != _platform → 每次都重新 init。
    // (跟 vent_detail_page_round7b_test.dart setUp 同款)
    AudioplayersPlatformInterface.instance = AudioplayersPlatform();
    GlobalAudioplayersPlatformInterface.instance = GlobalAudioplayersPlatform();
    final messenger =
        TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger;
    // audioplayers 6.x 三件套 (缺一会挂/抛): 每个 playerId 独立 sink,
    // 避免多 player 时 eventSink 被最后一个 listen 覆盖。
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (call) async {
        return null;
      },
    );
    final Map<String, MockStreamHandlerEventSink> sinks = {};
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async {
        if (call.method == 'create') {
          final playerId = (call.arguments as Map)['playerId'] as String;
          messenger.setMockStreamHandler(
            EventChannel('xyz.luan/audioplayers/events/$playerId'),
            MockStreamHandler.inline(
              onListen: (arguments, events) {
                sinks[playerId] = events;
              },
              onCancel: (_) {
                sinks.remove(playerId);
              },
            ),
          );
          return 'test-player';
        }
        if (call.method == 'setSourceUrl') {
          final playerId = (call.arguments as Map)['playerId'] as String;
          Future<void>.delayed(Duration.zero, () {
            sinks[playerId]
                ?.success({'event': 'audio.onPrepared', 'value': true});
          });
        }
        return null;
      },
    );
  });

  testWidgets('1) idle 态: 录音按钮 + STT 可用无提示', (tester) async {
    await tester
        .pumpWidget(_wrap(_FakeMoodAudioService()..sttAvailable = true));
    await tester.pumpAndSettle();

    expect(find.text('录语音'), findsOneWidget);
    expect(find.text('该设备暂不支持语音转文字'), findsNothing);
    expect(find.byIcon(Icons.play_arrow), findsNothing);
    expect(find.byIcon(Icons.refresh), findsNothing);
  });

  testWidgets('2) STT 不可用 → 录音前显示提示', (tester) async {
    await tester
        .pumpWidget(_wrap(_FakeMoodAudioService()..sttAvailable = false));
    await tester.pumpAndSettle();

    expect(find.text('该设备暂不支持语音转文字'), findsOneWidget);
  });

  testWidgets('3) 点录音 → 取消按钮 + STT 聆听标记 + 计时器', (tester) async {
    await tester
        .pumpWidget(_wrap(_FakeMoodAudioService()..sttAvailable = true));
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

  testWidgets('5) 停止录音 → 已录时长 + snapshot 上抛 + 播放/重录出现', (tester) async {
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

  testWidgets('7) 录音中 unmount → dispose 链跑完 (service cancel + dispose)',
      (tester) async {
    // E-01: 不带 serviceFactory — 强制走 provider, 复现 dispose 期 ref.read
    // (修前: _service getter 在 unmount 后 ref.read 抛 StateError 被吞,
    // cancelRecording / dispose 永不执行 → 链中断)。
    final service = _FakeMoodAudioService();
    await tester.pumpWidget(
      _wrap(service, controller: MoodRecorderController()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('录语音'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    // unmount: dispose 链在 widget 已卸载后才跑
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    expect(service.log, contains('cancel'));
    expect(service.log, contains('dispose'));
  });

  testWidgets('8) 播放中 unmount → temp 解密文件被删 (cleanupTempFile 跑完)',
      (tester) async {
    // E-01: 修前 cleanupTempFile 在 unmount 后 ref.read(moodAudioStorageProvider)
    // 抛 StateError 被吞 → deleteTempFile 永不执行 → 明文 temp 残留 (PIPL §28)。
    final service = _FakeMoodAudioService();
    final storage = _FakeMoodAudioStorage();
    await tester.pumpWidget(_wrap(service, storage: storage));
    await tester.pumpAndSettle();

    // 录音 + 停止 (fake, 无真实 IO)
    await tester.tap(find.text('录语音'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);

    // 播放 → decryptToTemp 设置 tempDecryptedPath
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byIcon(Icons.pause), findsOneWidget);

    // 播放中 unmount → mixin asyncDisposeAudio 第 6 步 cleanupTempFile
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(storage.deletedTempFiles, ['/fake/decrypt.m4a']);
  });

  group('E-01 dispose 期 ref.read lock-in (R112)', () {
    late String source;

    setUpAll(() {
      source = File(
        'lib/features/mood/presentation/pages/mood/widgets/mood_audio_recorder_widget.dart',
      ).readAsStringSync();
    });

    test('_disposeResources 体不出现 ref.read', () {
      final start = source.indexOf('Future<void> _disposeResources()');
      expect(start, isNot(-1), reason: '方法必须存在');
      final end = source.indexOf('// ===== AudioLifecycleMixin 4 抽象方法');
      expect(end, isNot(-1), reason: '方法边界注释必须存在');
      final body = source.substring(start, end);
      expect(
        body.contains('ref.read'),
        isFalse,
        reason: '_disposeResources 是 dispose 链主体, unmount 后 ref.read '
            '抛 StateError 被 swallowError 吞 → service 释放永不执行',
      );
    });

    test('cleanupTempFile 体不出现 ref.read', () {
      final start = source.indexOf('Future<void> cleanupTempFile()');
      expect(start, isNot(-1), reason: '方法必须存在');
      final end = source.indexOf('// ===== 公开方法');
      expect(end, isNot(-1), reason: '方法边界注释必须存在');
      final body = source.substring(start, end);
      expect(
        body.contains('ref.read'),
        isFalse,
        reason: 'cleanupTempFile 在 asyncDisposeAudio 第 6 步 (unmount 后) 被调, '
            'ref.read 抛 StateError → temp 明文永不删 (PIPL §28)',
      );
    });
  });
}
