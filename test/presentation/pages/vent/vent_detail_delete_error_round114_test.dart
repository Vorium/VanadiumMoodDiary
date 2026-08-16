// v1.1.0 R114 (BUG 7): vent_detail_page 删除失败错误处理回归测试
//
// 修前 (R113 BUG 7 只修列表页): `_delete` 中
// `await ref.read(ventRepositoryProvider).delete(entry.id)` 裸 await —
// delete 抛异常 = unhandled async error + 页面停留无提示。
//
// 修法: repo 在 async gap 前捕获 + try/catch + swallowError + 错误
// snackbar (页面停留); ok==false (行已不存在) → invalidate 详情流走
// EmptyState。
//
// 全流程: 详情页删除按钮 → 确认 dialog → delete 抛异常 → 页面停留
// (无 unhandled exception) + 错误 snackbar。
//
// 依赖: audioplayers channel 全 mock (vent_detail_page_round7b 同款
// harness), ventRepositoryProvider override 为 delete 必抛的 fake。
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

class _ThrowingDeleteVentRepository implements VentRepository {
  final VentEntryEntity? entry;
  _ThrowingDeleteVentRepository(this.entry);

  @override
  Stream<List<VentEntryEntity>> watchAll() =>
      Stream.value([if (entry != null) entry!]);

  @override
  Future<VentEntryEntity?> getById(int id) async =>
      (entry != null && entry!.id == id) ? entry : null;

  @override
  Future<bool> delete(int id) async {
    throw Exception('db delete failed');
  }

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
  Future<int> restore(VentEntryEntity entry) async => 1;

  @override
  Future<int> deleteAll() async => 1;
}

class _FakeVentAudioStorage extends VentAudioStorage {
  @override
  Future<String> decryptToTemp(String path) async => '/tmp/fake_decrypt.m4a';

  @override
  Future<void> deleteTempFile(String path) async {}
}

void main() {
  setUp(() {
    // audioplayers 进程级单例跨 testWidgets 残留 → 每测试重置 platform
    // (vent_detail_page_round7b 同款)
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
            MockStreamHandler.inline(onListen: (arguments, events) {}),
          );
          return 'test-player';
        }
        return null;
      },
    );
    // HapticFeedback.vibrate 挂起修复
    messenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
  });

  testWidgets(
      'R114 BUG 7: 详情页删除抛异常 → 页面停留 (无 unhandled exception) '
      '+ 错误 snackbar', (tester) async {
    final entry = VentEntryEntity(
      id: 1,
      timestamp: DateTime(2026, 8, 13, 21, 30),
      contentText: '这条删不掉也要显示',
    );
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
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ventRepositoryProvider
              .overrideWithValue(_ThrowingDeleteVentRepository(entry)),
          ventAudioStorageProvider.overrideWithValue(_FakeVentAudioStorage()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: ThemeData.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open-detail'));
    await tester.pumpAndSettle();
    expect(find.text('这条删不掉也要显示'), findsOneWidget);

    await tester.tap(find.byTooltip('删除'));
    await tester.pumpAndSettle();
    expect(find.text('删除这条？'), findsOneWidget);
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      tester.takeException(),
      isNull,
      reason: '修前: delete 裸 await 异常 = unhandled async error',
    );
    expect(
      find.byType(VentDetailPage),
      findsOneWidget,
      reason: '删除失败应停留详情页 (不给用户"已删"假象)',
    );
    expect(
      find.textContaining('删除失败'),
      findsOneWidget,
      reason: '错误 snackbar (commonDelete 模板)',
    );

    // 排空错误 snackbar 4s 计时器, 避免 test 结束 pending timer
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
