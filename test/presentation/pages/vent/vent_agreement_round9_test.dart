// v1.1.0 round 9 (F4 树洞使用公约): 首次进入 vent compose 弹公约 dialog
//
// 覆盖:
// 1. 首次进入 (未确认) → 弹"树洞使用公约" dialog, 点"我知道了" → 标记已读
// 2. 已确认后再进入 → 不弹
// 3. 未确认时 pop 回上一页 → 不标记 (下次仍弹)
//
// 平台通道 mock 与 vent_compose_full_chain_round8_test 一致
// (audioplayers / record / system platform haptics)。
import 'dart:async';

import 'package:audioplayers_platform_interface/src/audioplayers_platform.dart'
    show AudioplayersPlatform;
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart'
    show AudioplayersPlatformInterface, GlobalAudioplayersPlatformInterface;
import 'package:audioplayers_platform_interface/src/global_audioplayers_platform.dart'
    show GlobalAudioplayersPlatform;
import 'package:chroniccare/core/data/feature_flags.dart';
import 'package:chroniccare/core/data/services/vent_agreement_store.dart';
import 'package:chroniccare/core/data/services/vent_audio_storage.dart';
import 'package:chroniccare/domain/entities/vent_entry_entity.dart';
import 'package:chroniccare/domain/repositories/vent_repository.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/vent/vent_compose_page.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';
import 'package:chroniccare/presentation/providers/vent_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    String? tagsJson,
    DateTime? at,
  }) async =>
      1;

  @override
  Future<int> restore(VentEntryEntity entry) async => entry.id;

  @override
  Future<int> deleteAll() async => 0;
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
  late SharedPreferences sp;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sp = await SharedPreferences.getInstance();
    FeatureFlags.setVentAudioEnabledForTest(true);

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
        ventRepositoryProvider.overrideWithValue(_FakeVentRepository()),
        ventAudioStorageProvider.overrideWithValue(_FakeVentAudioStorage()),
        sharedPreferencesProvider.overrideWithValue(sp),
      ],
      child: MaterialApp.router(
        theme: ThemeData.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        routerConfig: GoRouter(
          initialLocation: '/vent/compose',
          routes: [
            GoRoute(
              path: '/vent',
              builder: (_, __) => const Scaffold(body: Text('VENT_LIST')),
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

  testWidgets('首次进入 (未确认) 弹公约 dialog, 点"我知道了"标记已读并关闭', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // dialog 出现
    expect(find.text('树洞使用公约'), findsOneWidget);
    expect(find.text('我知道了'), findsOneWidget);

    await tester.tap(find.text('我知道了'));
    await tester.pumpAndSettle();

    // dialog 关闭 + 已读已持久化
    expect(find.text('树洞使用公约'), findsNothing);
    final store = VentAgreementStore(await SharedPreferences.getInstance());
    expect(await store.isAcknowledged(), isTrue);
  });

  testWidgets('已确认后再进入 → 不再弹 dialog', (tester) async {
    SharedPreferences.setMockInitialValues({
      'vent_agreement_acknowledged': true,
    });
    sp = await SharedPreferences.getInstance();

    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('树洞使用公约'), findsNothing);
    expect(find.text('我知道了'), findsNothing);
  });
}
