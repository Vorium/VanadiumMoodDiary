// v0.32 R112 (E-01): vent_compose dispose 链 unmount 后 ref.read 泄漏修复测试
//
// **背景 (审计 09-line-by-line-presentation.md E-01)**:
// Riverpod 3.4.2 `ref.read` 在 widget unmount 后无条件抛 StateError (非
// assert, release 也抛)。vent_compose_page.dispose → unawaited(
// asyncDisposeAudio(...)) → mixin 第 6 步 cleanupTempFile 在 unmount 后才
// 跑 `ref.read(ventAudioStorageProvider)` → StateError 被 swallowError 吞 →
// 播放后离开页面 temp 解密明文文件永不删除 (PIPL §28, R108 P0-018 同款)。
// vent_detail_page 在 round 7b-5 (B1-11) 已用"字段缓存 storage"修, 本文件漏修。
//
// **修法 (B1-11 同款)**: initState 把 VentAudioStorage 捕获进 State 字段,
// cleanupTempFile 只用字段不碰 ref。事件回调 (stopRecordingImpl 等) 内的
// ref.read 合法不动。
//
// 覆盖:
// 1. 录音中 unmount → dispose 链跑完 (record channel 收到 stop + dispose,
//    即 mixin 链不被 unmount 后的 ref.read / root-zone cancel future 卡死)
// 2. 源码 lock-in: cleanupTempFile 体不出现 ref.read
// 3. 源码 lock-in: initState 捕获 ventAudioStorageProvider 进字段
//
// 注: 播放 → temp 清理路径走同一个 AudioLifecycleMixin.asyncDisposeAudio
// 第 6 步, 运行时行为已由 mood_audio_recorder_round7b_test.dart 测试 8
// 覆盖 (vent_audio_section 的"停止录音"按钮 v0.24 起在录音中为 disabled,
// UI 上到不了播放态 — 不在本文件所有权范围, 见 fix report concerns)。
//
// 依赖:
// - audioplayers channel (`xyz.luan/audioplayers`) 必须 mock (create/dispose)
// - record channel (`com.llfbandit.record/messages`) 必须 mock (hasPermission/
//   create/start/stop/dispose)
// - ventRepositoryProvider / ventAudioStorageProvider 全部 override 为内存 fake

import 'dart:io';

import 'package:audioplayers_platform_interface/src/audioplayers_platform.dart'
    show AudioplayersPlatform;
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart'
    show AudioplayersPlatformInterface, GlobalAudioplayersPlatformInterface;
import 'package:audioplayers_platform_interface/src/global_audioplayers_platform.dart'
    show GlobalAudioplayersPlatform;
import 'package:chroniccare/core/data/feature_flags.dart';
import 'package:chroniccare/core/data/services/vent_audio_storage.dart';
import 'package:chroniccare/domain/entities/vent_entry_entity.dart';
import 'package:chroniccare/domain/repositories/vent_repository.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/vent/vent_compose_page.dart';
import 'package:chroniccare/presentation/providers/vent_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeVentRepository implements VentRepository {
  @override
  Stream<List<VentEntryEntity>> watchAll() => Stream.value(const []);

  @override
  Future<VentEntryEntity?> getById(int id) async => null;

  @override
  Future<bool> delete(int id) async => true;

  @override
  Future<int> add({
    String? text,
    String? audioPath,
    int? audioDurationSec,
    int? audioSizeBytes,
    DateTime? at,
  }) async =>
      1;

  @override
  Future<int> restore(VentEntryEntity entry) async => 1;

  @override
  Future<int> deleteAll() async => 1;
}

class _FakeVentAudioStorage extends VentAudioStorage {
  @override
  Future<String> newTempRecordPath() async => '/tmp/vent_record_1.m4a';

  @override
  Future<String> newAudioPath() async => '/tmp/vent_1.m4a.enc';

  @override
  Future<void> encryptAndWrite({
    required String plainPath,
    required String encryptedPath,
  }) async {}
}

void main() {
  late List<String> recordCalls;
  late List<String> audioCalls;

  setUp(() {
    // vent audio 录音业务必须打开 (prod 默认 true, 显式设置防 prod 翻转)
    FeatureFlags.setVentAudioEnabledForTest(true);
    recordCalls = [];
    audioCalls = [];
    // audioplayers 的 GlobalAudioScope + platform 是进程级单例, _initCompleter
    // 跨 testWidgets 残留 → 每个测试重置 platform (vent_detail 同款)。
    AudioplayersPlatformInterface.instance = AudioplayersPlatform();
    GlobalAudioplayersPlatformInterface.instance = GlobalAudioplayersPlatform();
    final messenger =
        TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger;
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
        audioCalls.add(call.method);
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
    // record 5.x channel: hasPermission / create / start / stop / dispose
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.llfbandit.record/messages'),
      (call) async {
        recordCalls.add(call.method);
        if (call.method == 'create') {
          final recorderId = (call.arguments as Map)['recorderId'] as String;
          messenger.setMockMethodCallHandler(
            MethodChannel('com.llfbandit.record/events/$recorderId'),
            (call) async {
              return null;
            },
          );
          return null;
        }
        if (call.method == 'hasPermission') return true;
        if (call.method == 'stop') return '/tmp/plain_vent.m4a';
        return null;
      },
    );
    // HapticFeedback.vibrate 在无 handler 时挂起 (vent_detail 同款)
    messenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
  });

  tearDown(FeatureFlags.resetForTest);

  testWidgets('1) 录音中 unmount → dispose 链跑完 (record stop + dispose)',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ventRepositoryProvider.overrideWithValue(_FakeVentRepository()),
          ventAudioStorageProvider.overrideWithValue(_FakeVentAudioStorage()),
        ],
        child: MaterialApp(
          theme: ThemeData.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: const VentComposePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 录音
    await tester.tap(find.text('按一下开始录音'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    // v0.32 R112 round 8h: 录音态 UI 改为 [暂停][时长][停止] 行
    // (修前是 "正在录音……点停止" 且停止按钮被禁用)
    expect(find.byIcon(Icons.pause), findsOneWidget);
    expect(find.byIcon(Icons.stop), findsOneWidget);

    // 录音中 unmount → mixin.asyncDisposeAudio:
    // 修前: 链在 await recorder.dispose() 卡死 (record 包 dispose 内部
    // _stateStreamSubscription.cancel() 的 root zone future 永不 resolve),
    // 后续 player.dispose / temp 清理全不跑 → native handle 每次进/出页面
    // 泄漏。修后: recorder.dispose 走 fire-and-forget, 链跑完第 5 步
    // player.stop (audioplayers channel 'stop')。
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(recordCalls, contains('stop'));
    expect(audioCalls, contains('stop'));
  });

  group('E-01 dispose 期 ref.read lock-in (R112)', () {
    late String source;

    setUpAll(() {
      source = File(
        'lib/presentation/pages/vent/vent_compose_page.dart',
      ).readAsStringSync();
    });

    test('cleanupTempFile 体不出现 ref.read', () {
      final start = source.indexOf('Future<void> cleanupTempFile()');
      expect(start, isNot(-1), reason: '方法必须存在');
      final end = source.indexOf('// ===== vent 特有 helper');
      expect(end, isNot(-1), reason: '方法边界注释必须存在');
      final body = source.substring(start, end);
      expect(
        body.contains('ref.read'),
        isFalse,
        reason: 'cleanupTempFile 在 mixin.asyncDisposeAudio 第 6 步 (unmount 后) '
            '被调, ref.read 抛 StateError 被吞 → temp 明文永不删 (PIPL §28)',
      );
    });

    test('initState 把 ventAudioStorageProvider 捕获进 State 字段', () {
      // B1-11 同款字段缓存: dispose 链只能走字段 (ref.read 只在 initState/
      // build/事件回调合法)
      expect(
        source.contains('ref.read(ventAudioStorageProvider)'),
        isTrue,
        reason: 'initState 必须 ref.read(ventAudioStorageProvider) 捕获进字段',
      );
      expect(
        source.contains('VentAudioStorage? _storage'),
        isTrue,
        reason: '必须有 VentAudioStorage 类型 State 字段承接 initState 捕获',
      );
    });
  });
}
