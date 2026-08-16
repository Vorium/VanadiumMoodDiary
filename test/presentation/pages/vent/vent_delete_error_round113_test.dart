// v1.1.0 R113 (BUG 7 + 7b): vent_list_page 滑动删除失败错误处理回归测试
//
// 修前: onDismissed fire-and-forget 裸 await repo.delete —
// delete 抛异常 = unhandled async error + 条目从 UI 消失但 DB 还在。
// R113 BUG 7 修 catch 链 (swallowError + 错误 snackbar + invalidate),
// 但 BUG 7b 残留: invalidate 走 isRefreshing (skipLoadingOnRefresh
// 默认 true) → loading 分支永不渲染 → 已 dismiss 的 Dismissible
// (key 不变) 仍在树 → rebuild 抛 FlutterError "A dismissed Dismissible
// widget is still part of the tree"。
//
// 修法: Dismissible key 带失败计数 (`vent-entry-<id>-<failCount>`),
// 删除失败时计数 +1 → 旧 Dismissible unmount + 新 key remount 回
// "未滑走"状态, 条目立即回到列表。
//
// 全流程: swipe → 确认删除 dialog → delete 抛异常 → 条目重新可见 +
// 无 "dismissed Dismissible" 异常 + 错误 snackbar。
//
// 依赖: ventRepositoryProvider override 为 delete 必抛的 fake
// (vent_list_round18_test 同款 harness)。

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

/// delete 必抛异常的 vent 仓库 — watchAll 始终返回原条目列表
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
      'BUG 7b 全流程 swipe: delete 抛异常 → 无 dismissed-Dismissible '
      '异常 + 条目滑走后重新可见', (tester) async {
    setBigView(tester);
    // confirmDismiss 先 await Haptics.warning() — 平台 channel 在 widget
    // test 中 future 永不完成 → 确认 dialog 永远弹不出。mock platform
    // channel 让 haptics 立即完成 (测试环境标准做法)。
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
            contentText: '今天有点累，先说一下吧',
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('今天有点累，先说一下吧'), findsOneWidget);

    // 真实 swipe (endToStart) → confirmDismiss 弹确认 dialog
    await tester.drag(
      find.byType(Dismissible).first,
      const Offset(-600, 0),
    );
    await tester.pumpAndSettle();

    // 确认删除 dialog: 点"删除"
    final deleteButton = find.widgetWithText(TextButton, '删除');
    expect(deleteButton, findsOneWidget, reason: '确认删除 dialog 必须出现');
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // BUG 7b 修前: invalidate 后 Dismissible (key 不变) 仍在树 → 任何
    // rebuild 抛 FlutterError "A dismissed Dismissible widget is still
    // part of the tree"。修后: key 换 → remount → 条目回来。
    expect(
      tester.takeException(),
      isNull,
      reason: '修前: dismissed Dismissible 仍在树 → FlutterError',
    );
    expect(
      find.text('今天有点累，先说一下吧'),
      findsOneWidget,
      reason: 'delete 失败后条目必须回到列表 (DB 里还在)',
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
