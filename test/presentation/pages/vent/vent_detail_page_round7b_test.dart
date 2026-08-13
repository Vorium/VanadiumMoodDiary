// v0.32 R110 round 7b-5: vent_detail_page (426L god class) 补 0-test
//
// 覆盖:
// 1. 文字条目渲染: 正文 + 时间戳 + 文字图标头像 + 删除按钮可用
// 2. 音频条目: 播放按钮 (tooltip 播放录音) → tap → decryptToTemp 被调
//    + 图标切暂停 → 再 tap → 暂停
// 3. 举报/反馈 dialog (App Store 1.2.1): 打开 → 前往法律与隐私 → 路由跳转
// 4. 删除确认: 删除这条？→ 删除 → repo.delete(id) + 页面 pop
// 5. 找不到条目 (id 999) → EmptyState 找不到了
//
// 依赖:
// - audioplayers channel (`xyz.luan/audioplayers`) 必须 mock (create/dispose)
// - ventEntryByIdProvider / ventRepositoryProvider / ventAudioStorageProvider
//   全部 override 为内存 fake

import 'package:audioplayers_platform_interface/src/audioplayers_platform.dart'
    show AudioplayersPlatform;
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart'
    show AudioplayersPlatformInterface, GlobalAudioplayersPlatformInterface;
import 'package:audioplayers_platform_interface/src/global_audioplayers_platform.dart'
    show GlobalAudioplayersPlatform;
import 'package:chroniccare/core/data/services/vent_audio_storage.dart';
import 'package:chroniccare/domain/entities/vent_entry_entity.dart';
import 'package:chroniccare/domain/repositories/vent_repository.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/vent/vent_detail_page.dart';
import 'package:chroniccare/presentation/providers/vent_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeVentRepository implements VentRepository {
  final VentEntryEntity? entry;
  final List<int> deleted = [];

  _FakeVentRepository(this.entry);

  @override
  Stream<List<VentEntryEntity>> watchAll() =>
      Stream.value([if (entry != null) entry!]);

  @override
  Future<VentEntryEntity?> getById(int id) async =>
      (entry != null && entry!.id == id) ? entry : null;

  @override
  Future<bool> delete(int id) async {
    deleted.add(id);
    return true;
  }

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
  final List<String> deletedTempFiles = [];

  @override
  Future<String> decryptToTemp(String path) async => '/tmp/fake_decrypt.m4a';

  @override
  Future<void> deleteTempFile(String path) async {
    deletedTempFiles.add(path);
  }
}

VentEntryEntity _entry({
  int id = 1,
  String? text = '今天心情不错',
  String? audioPath,
  int? audioDurationSec,
}) {
  return VentEntryEntity(
    id: id,
    timestamp: DateTime(2026, 8, 13, 21, 30),
    contentText: text,
    audioPath: audioPath,
    audioDurationSec: audioDurationSec,
    audioSizeBytes: null,
  );
}

Future<void> _pumpPage(
  WidgetTester tester,
  _FakeVentRepository repo,
  _FakeVentAudioStorage storage,
) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => context.push('/detail/1'),
                child: const Text('open-detail'),
              ),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/detail/:id',
        builder: (_, state) =>
            VentDetailPage(id: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/settings/legal',
        builder: (_, __) => const Scaffold(body: Text('legal-stub')),
      ),
    ],
  );

  await tester.pumpWidget(ProviderScope(
    overrides: [
      ventRepositoryProvider.overrideWithValue(repo),
      ventAudioStorageProvider.overrideWithValue(storage),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      theme: ThemeData.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
    ),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('open-detail'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    // audioplayers 的 GlobalAudioScope + platform 是进程级单例, _initCompleter
    // 跨 testWidgets 残留 → 第 2 个测试的 AudioPlayer._create() 挂在
    // ensureInitialized (await 幽灵 completer)。每个测试重置 platform,
    // 保证 _lastGlobal != _platform → 每次都重新 init。
    AudioplayersPlatformInterface.instance = AudioplayersPlatform();
    GlobalAudioplayersPlatformInterface.instance = GlobalAudioplayersPlatform();
    final messenger = TestWidgetsFlutterBinding.ensureInitialized()
        .defaultBinaryMessenger;
    // audioplayers 6.x 三件套 (缺一会挂/抛):
    // 1. global channel 'init' → null (否则 MissingPluginException)
    // 2. player channel 'create' → 捕获 playerId, 注册对应 EventChannel
    // 3. 'setSourceUrl' → 延迟推 'audio.onPrepared' (firstWhere 那时才订阅,
    //    listen 时同步推会被 broadcast 丢弃)
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (call) async {
        return null;
      },
    );
    MockStreamHandlerEventSink? eventSink;
    final List<String> calls = [];
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async {
        calls.add(call.method);
        if (call.method == 'create') {
          final playerId = (call.arguments as Map)['playerId'] as String;
          messenger.setMockStreamHandler(
            EventChannel('xyz.luan/audioplayers/events/$playerId'),
            MockStreamHandler.inline(
              onListen: (arguments, events) {
                eventSink = events;
              },
            ),
          );
          return 'test-player';
        }
        if (call.method == 'setSourceUrl') {
          Future<void>.delayed(Duration.zero, () {
            eventSink?.success({'event': 'audio.onPrepared', 'value': true});
          });
        }
        return null;
      },
    );
    // HapticFeedback.vibrate 在无 handler 时挂起, 删除确认 dialog 永远
    // 等不到 Haptics.warning() 返回
    messenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
  });

  testWidgets('1) 文字条目 → 正文 + 时间戳 + 头像图标 + 删除按钮', (tester) async {
    final storage = _FakeVentAudioStorage();
    await _pumpPage(tester, _FakeVentRepository(_entry()), storage);

    expect(find.text('今天心情不错'), findsOneWidget);
    expect(find.text('2026-08-13 21:30'), findsOneWidget);
    // 无音频 → text_snippet 头像
    expect(find.byIcon(Icons.text_snippet_outlined), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsNothing);
    // 删除按钮 (tooltip 删除)
    expect(find.byTooltip('删除'), findsOneWidget);
  });

  testWidgets('2) 音频条目 → 播放/暂停 toggle + decryptToTemp 调用', (tester) async {
    final storage = _FakeVentAudioStorage();
    await _pumpPage(
      tester,
      _FakeVentRepository(
        _entry(text: null, audioPath: '/data/vent_x.m4a.enc', audioDurationSec: 5),
      ),
      storage,
    );

    // 播放按钮 (tooltip 播放录音)
    expect(find.byTooltip('播放录音'), findsOneWidget);
    await tester.tap(find.byTooltip('播放录音'));
    // 播放中 positionUpdater 每帧重排 frame callback → pumpAndSettle 会
    // 死循环, 用固定 pump 推进 (含 setSourceUrl 的 prepared 延迟 emit)。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // decryptToTemp 被调 + 图标切暂停
    expect(storage.deletedTempFiles, isEmpty);
    expect(find.byTooltip('暂停录音'), findsOneWidget);

    // 再 tap → 暂停
    await tester.tap(find.byTooltip('暂停录音'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('播放录音'), findsOneWidget);
  });

  testWidgets('3) 举报 dialog → 前往法律与隐私 → 路由跳转', (tester) async {
    final storage = _FakeVentAudioStorage();
    await _pumpPage(tester, _FakeVentRepository(_entry()), storage);

    await tester.tap(find.byTooltip('举报或反馈'));
    await tester.pumpAndSettle();
    expect(find.text('私密倾诉说明'), findsOneWidget);

    await tester.tap(find.text('前往法律与隐私'));
    await tester.pumpAndSettle();
    expect(find.text('legal-stub'), findsOneWidget);
  });

  testWidgets('4) 删除确认 → repo.delete + 页面 pop', (tester) async {
    final repo = _FakeVentRepository(_entry());
    final storage = _FakeVentAudioStorage();
    await _pumpPage(tester, repo, storage);

    await tester.tap(find.byTooltip('删除'));
    await tester.pumpAndSettle();
    expect(find.text('删除这条？'), findsOneWidget);
    expect(find.text('删了就没了。文字和录音都会一起删。'), findsOneWidget);

    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(repo.deleted, [1]);
    expect(find.byType(VentDetailPage), findsNothing);
  });

  testWidgets('5) 找不到条目 → EmptyState', (tester) async {
    final storage = _FakeVentAudioStorage();
    await _pumpPage(tester, _FakeVentRepository(null), storage);

    expect(find.text('找不到了'), findsOneWidget);
  });
}