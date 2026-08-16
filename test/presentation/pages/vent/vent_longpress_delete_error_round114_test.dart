// v1.1.0 R114 (BUG 7): vent_list_page 长按删除失败错误处理回归测试
//
// 修前 (R113 BUG 7 只修了 swipe 路径): `_confirmDelete` 里
// `await repo.delete(entry.id)` 裸 await — delete 抛异常 = unhandled
// async error + 无用户反馈 + 条目留存; onUndo 的 restore 也无 catch。
//
// 修法 (与 swipe onDismissed 路径对齐): try/catch + swallowError +
// 错误 snackbar + ok==false 时 invalidate 刷新 + undo restore 包 catch。
//
// 全流程: 长按条目 → 确认删除 dialog → delete 抛异常 → 条目仍可见 +
// 无 unhandled exception + 错误 snackbar。
import 'package:chroniccare/domain/entities/vent_entry_entity.dart';
import 'package:chroniccare/domain/repositories/vent_repository.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/vent/vent_list_page.dart';
import 'package:chroniccare/presentation/providers/vent_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// delete 必抛异常的 vent 仓库 (vent_delete_error_round113 同款)
class _ThrowingVentRepository implements VentRepository {
  final List<VentEntryEntity> entries;
  _ThrowingVentRepository(this.entries);

  @override
  Stream<List<VentEntryEntity>> watchAll() => Stream.value(entries);

  @override
  Future<VentEntryEntity?> getById(int id) async => null;

  @override
  Future<int> add({
    String? text,
    String? audioPath,
    int? audioDurationSec,
    int? audioSizeBytes,
    String? tagsJson,
    DateTime? at,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> delete(int id) async {
    throw Exception('db delete failed');
  }

  @override
  Future<int> restore(VentEntryEntity entry) async => entry.id;

  @override
  Future<int> deleteAll() async => 0;
}

void main() {
  void setBigView(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget wrap(VentRepository repo) {
    return ProviderScope(
      overrides: [
        ventRepositoryProvider.overrideWithValue(repo),
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
              builder: (_, __) => const Scaffold(body: Text('COMPOSE')),
            ),
            GoRoute(
              path: '/vent/detail/:id',
              builder: (_, state) => Scaffold(
                body: Text('DETAIL ${state.pathParameters['id']}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  testWidgets(
      'R114 BUG 7: 长按删除抛异常 → 无 unhandled exception '
      '+ 条目仍可见 + 错误 snackbar', (tester) async {
    setBigView(tester);
    SharedPreferences.setMockInitialValues({});
    // Haptics.warning() 平台 channel mock (长按删除前先触感)
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });
    await tester.pumpWidget(
      wrap(
        _ThrowingVentRepository([
          VentEntryEntity(
            id: 1,
            timestamp: DateTime(2026, 7, 15, 10, 30),
            contentText: '长按删除失败也要留住我',
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('长按删除失败也要留住我'), findsOneWidget);

    // 长按 → 确认删除 dialog
    await tester.longPress(find.text('长按删除失败也要留住我'));
    await tester.pumpAndSettle();

    final deleteButton = find.widgetWithText(TextButton, '删除');
    expect(deleteButton, findsOneWidget, reason: '确认删除 dialog 必须出现');
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    expect(
      tester.takeException(),
      isNull,
      reason: '修前: delete 裸 await 异常 = unhandled async error',
    );
    expect(
      find.text('长按删除失败也要留住我'),
      findsOneWidget,
      reason: 'delete 失败后条目必须仍在列表 (DB 里还在)',
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
