// v1.1.0 R113 (BUG 5): vent_detail _togglePlay catch 用 _storage 字段回归测试
//
// 修前: catch 块 `await ref.read(ventAudioStorageProvider).deleteTempFile(...)`
// — async gap (decryptToTemp / play await) 里 widget 可能已 unmount, Riverpod 3
// ref.read 无条件抛 StateError → 被嵌套 catch 吞 → temp 解密明文文件永不删除
// (设备 root 可读 = PIPL §28 漏洞)。跟 dispose 段 B1-11 同款 bug。
//
// 修后: 播放开始时把 storage 缓存进 State 字段 `_storage`, catch 只用字段
// (ref.read 只在事件回调里合法)。跟 vent_compose_dispose_ref_leak_round112
// 的 B1-11 字段缓存模式 1:1。
//
// 覆盖:
// 1. 行为: unmount 后播放失败 → storage.deleteTempFile 仍被调 (无 StateError)
// 2. 源码 lock-in: _togglePlay catch 块不出现 ref.read, 必须用 _storage 字段
//
// 依赖: audioplayers channel mock (跟 vent_detail_page_round7b_test 同款),
// ventRepositoryProvider / ventAudioStorageProvider override 内存 fake。

import 'dart:async';
import 'dart:io';

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
  final VentEntryEntity entry;

  _FakeVentRepository(this.entry);

  @override
  Stream<List<VentEntryEntity>> watchAll() => Stream.value([entry]);

  @override
  Future<VentEntryEntity?> getById(int id) async =>
      (entry.id == id) ? entry : null;

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
  Future<int> restore(VentEntryEntity entry) async => 1;

  @override
  Future<int> deleteAll() async => 1;
}

class _FakeVentAudioStorage extends VentAudioStorage {
  final List<String> deletedTempFiles = [];
  int decryptCalls = 0;
  Completer<String>? decryptGate;

  @override
  Future<String> decryptToTemp(String path) {
    decryptCalls++;
    final gate = decryptGate;
    if (gate != null) return gate.future;
    return Future.value('/tmp/fake_decrypt.m4a');
  }

  @override
  Future<void> deleteTempFile(String path) async {
    deletedTempFiles.add(path);
  }
}

VentEntryEntity _entry() {
  return VentEntryEntity(
    id: 1,
    timestamp: DateTime(2026, 8, 13, 21, 30),
    contentText: null,
    audioPath: '/data/vent_x.m4a.enc',
    audioDurationSec: 5,
    audioSizeBytes: null,
  );
}

Future<void> _pumpDetail(
  WidgetTester tester,
  _FakeVentRepository repo,
  _FakeVentAudioStorage storage,
) async {
  final router = GoRouter(
    initialLocation: '/detail/1',
    routes: [
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
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    // audioplayers 的 GlobalAudioScope + platform 是进程级单例 (round7b 同款)
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
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async {
        if (call.method == 'create') {
          final playerId = (call.arguments as Map)['playerId'] as String;
          // 注册 event channel 防 MissingPluginException (round7b 同款),
          // 本文件不测成功播放路径 → 不推 prepared 事件
          messenger.setMockStreamHandler(
            EventChannel('xyz.luan/audioplayers/events/$playerId'),
            MockStreamHandler.inline(onListen: (arguments, events) {}),
          );
          return 'test-player';
        }
        return null;
      },
    );
    // HapticFeedback / SystemChannels 挂起防护 (round7b 同款)
    messenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
  });

  testWidgets(
      '1) unmount 后播放失败 → catch 用 _storage 删 temp (修前 ref.read 抛 StateError)',
      (tester) async {
    final storage = _FakeVentAudioStorage()..decryptGate = Completer<String>();
    await _pumpDetail(tester, _FakeVentRepository(_entry()), storage);

    expect(find.byTooltip('播放录音'), findsOneWidget);
    await tester.tap(find.byTooltip('播放录音'));
    await tester.pump();
    // decryptToTemp 挂起 → async gap
    expect(storage.decryptCalls, 1);

    // decrypt 未完成 (temp 路径还没写进 State) → unmount 页面
    // (dispose 里 _tempDecryptedPath == null → 不抢在 catch 前清理)
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump(const Duration(milliseconds: 20));

    // 完成 decrypt → play 链在 unmount 后继续: player 已 dispose →
    // prepared 流已关闭 → orElse 抛 'Stream closed before it got prepared'
    // → catch → 走 _storage 字段删 temp
    storage.decryptGate!.complete('/tmp/dec.m4a');
    storage.decryptGate = null;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      storage.deletedTempFiles,
      ['/tmp/dec.m4a'],
      reason: '修前 ref.read(ventAudioStorageProvider) 在 unmount 后抛 '
          'StateError 被嵌套 catch 吞 → temp 明文永不删 (PIPL §28)',
    );
    expect(tester.takeException(), isNull);
  });

  group('BUG 5 源码 lock-in', () {
    late String source;

    setUpAll(() {
      source = File(
        'lib/features/vent/presentation/pages/vent/vent_detail_page.dart',
      ).readAsStringSync();
    });

    test('_togglePlay catch 块不出现 ref.read (必须走 _storage 字段)', () {
      final start = source.indexOf('Future<void> _togglePlay');
      expect(start, isNot(-1), reason: '方法必须存在');
      final catchStart = source.indexOf('catch (e) {', start);
      expect(catchStart, isNot(-1), reason: 'catch 块必须存在');
      final end = source.indexOf('/// R97-P1-4', catchStart);
      expect(end, isNot(-1), reason: '方法边界注释必须存在');
      final body = source.substring(catchStart, end);
      // doc 注释描述旧 bug 时引用了 `ref.read(ventAudioStorageProvider)`,
      // 只检查代码行 (去注释)
      final codeOnly = body
          .split('\n')
          .where((l) => !l.trimLeft().startsWith('//'))
          .join('\n');
      expect(
        codeOnly.contains('ref.read'),
        isFalse,
        reason: 'catch 在 unmount 后跑, ref.read 抛 StateError 被吞 → '
            'temp 明文永不删 (PIPL §28)',
      );
      expect(
        codeOnly.contains('_storage'),
        isTrue,
        reason: 'catch 必须用 State 字段缓存的 storage',
      );
    });
  });
}
