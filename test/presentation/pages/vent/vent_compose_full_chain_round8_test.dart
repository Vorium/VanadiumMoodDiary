// v0.32 round 8 (R111-08): vent compose 全链路 widget test
//
// R111 审计: vent compose 全链路 0 widget test (只有 dispose / lock-in 级)。
// 补 1 个全链路: 打开 compose → 输入文字 → 提交 → 列表出现新条目。
//
// 全内存 fake: ventRepository (broadcast stream) + ventAudioStorage,
// 平台通道 mock 跟 vent_compose_dispose_ref_leak_round112_test 一致
// (audioplayers / record / system platform haptics)。
//
// 路径: GoRouter '/vent' (VentListPage) + '/vent/compose' (VentComposePage),
// 空列表 → EmptyState "写第一句" → compose → 输入 → "放进树洞" → 回列表
// → 新条目预览可见 (repo.add 被调 + watchAll re-emit)。

import 'dart:async';

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
import 'package:chroniccare/presentation/pages/vent/vent_list_page.dart';
import 'package:chroniccare/presentation/providers/vent_providers.dart';
import 'package:chroniccare/presentation/widgets/loading_text_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeVentRepository implements VentRepository {
  final List<VentEntryEntity> _entries = [];
  late final StreamController<List<VentEntryEntity>> _controller;

  _FakeVentRepository() {
    // onListen 立即 emit 当前状态 — 否则 broadcast 无初始值, StreamProvider
    // 一直 loading → LoadingSkeleton 无限动画 → pumpAndSettle 超时
    _controller = StreamController<List<VentEntryEntity>>.broadcast(
      onListen: () => _controller.add(List.unmodifiable(_entries)),
    );
  }

  List<VentEntryEntity> get entries => List.unmodifiable(_entries);

  @override
  Stream<List<VentEntryEntity>> watchAll() => _controller.stream;

  @override
  Future<VentEntryEntity?> getById(int id) async =>
      _entries.where((e) => e.id == id).cast<VentEntryEntity?>().firstOrNull;

  @override
  Future<int> add({
    String? text,
    String? audioPath,
    int? audioDurationSec,
    int? audioSizeBytes,
    String? tagsJson,
    DateTime? at,
  }) async {
    final id = _entries.length + 1;
    _entries.add(
      VentEntryEntity(
        id: id,
        timestamp: at ?? DateTime.now(),
        contentText: text,
        audioPath: audioPath,
        audioDurationSec: audioDurationSec,
        audioSizeBytes: audioSizeBytes,
        tagsJson: tagsJson ?? '[]',
      ),
    );
    _controller.add(List.unmodifiable(_entries));
    return id;
  }

  @override
  Future<bool> delete(int id) async {
    _entries.removeWhere((e) => e.id == id);
    _controller.add(List.unmodifiable(_entries));
    return true;
  }

  @override
  Future<int> restore(VentEntryEntity entry) async {
    _entries.add(entry);
    _controller.add(List.unmodifiable(_entries));
    return entry.id;
  }

  @override
  Future<int> deleteAll() async {
    final count = _entries.length;
    _entries.clear();
    _controller.add(List.unmodifiable(_entries));
    return count;
  }
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
  late _FakeVentRepository repo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FeatureFlags.setVentAudioEnabledForTest(true);
    repo = _FakeVentRepository();

    // audioplayers 进程级单例跨 test 残留 → 每个测试重置 platform
    AudioplayersPlatformInterface.instance = AudioplayersPlatform();
    GlobalAudioplayersPlatformInterface.instance = GlobalAudioplayersPlatform();
    final messenger =
        TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (call) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async {
        if (call.method == 'create') {
          final playerId = (call.arguments as Map)['playerId'] as String;
          messenger.setMockStreamHandler(
            EventChannel('xyz.luan/audioplayers/events/$playerId'),
            MockStreamHandler.inline(
              onListen: (arguments, events) {},
              onCancel: (_) {},
            ),
          );
          return 'test-player';
        }
        return null;
      },
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.llfbandit.record/messages'),
      (call) async {
        if (call.method == 'hasPermission') return true;
        return null;
      },
    );
    messenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
  });

  tearDown(FeatureFlags.resetForTest);

  Widget app() {
    return ProviderScope(
      overrides: [
        ventRepositoryProvider.overrideWithValue(repo),
        ventAudioStorageProvider.overrideWithValue(_FakeVentAudioStorage()),
      ],
      child: MaterialApp.router(
        theme: ThemeData.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        routerConfig: GoRouter(
          initialLocation: '/vent',
          routes: [
            GoRoute(
              path: '/vent',
              builder: (_, __) => const VentListPage(),
            ),
            GoRoute(
              path: '/vent/compose',
              builder: (_, __) => const VentComposePage(),
            ),
          ],
        ),
      ),
    );
  }

  // v0.32 R112 round 8h: 录音暂停/继续 (用户报"树洞录音不能暂停")
  testWidgets('录音 → 暂停 (时长冻结) → 继续 → 停止', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // 1. 进 compose
    await tester.tap(find.text('写第一句'));
    await tester.pumpAndSettle();

    // 2. 点 mic 开始录音
    await tester.tap(find.text('按一下开始录音'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // recording 行: pause icon + stop icon 都在, 且 stop 不再是禁用
    expect(find.byIcon(Icons.pause), findsOneWidget);
    expect(find.byIcon(Icons.stop), findsOneWidget);

    // 3. 暂停 → play_arrow 出现, 时长冻结
    await tester.tap(find.byIcon(Icons.pause));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    final frozen = tester
        .widget<Text>(
          find.textContaining(RegExp(r'^\d{2}:\d{2}$')),
        )
        .data;
    await tester.pump(const Duration(seconds: 2));
    final stillFrozen = tester
        .widget<Text>(
          find.textContaining(RegExp(r'^\d{2}:\d{2}$')),
        )
        .data;
    expect(stillFrozen, frozen, reason: '暂停期间时长冻结');

    // 4. 继续 → pause icon 回来
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.pause), findsOneWidget);

    // 5. 停止 (recorder.stop mock 返 null → 回 idle, mic 按钮再现)
    await tester.tap(find.byIcon(Icons.stop));
    await tester.pumpAndSettle();
    expect(find.text('按一下开始录音'), findsOneWidget);
  });

  testWidgets('全链路: 空列表 → 写第一句 → 输入文字 → 放进树洞 → 列表出现新条目',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // 1. 空列表 → EmptyState
    expect(find.text('树洞还是空的'), findsOneWidget);
    expect(find.text('写第一句'), findsOneWidget);

    // 2. 打开 compose
    await tester.tap(find.text('写第一句'));
    await tester.pumpAndSettle();
    expect(find.byType(VentComposePage), findsOneWidget);

    // 3. 输入文字 (1.1.0 round 5c: 页面现在有 2 个 TextField — 文字输入
    // + 标签自定义输入; 文字输入是树里第一个)
    await tester.enterText(
      find.byType(TextField).first,
      '今天有点累，但撑过来了',
    );
    await tester.pump();

    // 4. 提交 → pop 回列表 (title + 保存按钮同文案, 按 LoadingTextButton 定位)
    await tester.tap(
      find.widgetWithText(LoadingTextButton, '放进树洞'),
    );
    await tester.pumpAndSettle();

    // 5. 列表出现新条目 (repo.add 已调 + watchAll re-emit)
    expect(find.byType(VentListPage), findsOneWidget);
    expect(find.text('树洞还是空的'), findsNothing);
    expect(find.text('今天有点累，但撑过来了'), findsOneWidget);
    expect(repo.entries.single.contentText, '今天有点累，但撑过来了');
  });
}
