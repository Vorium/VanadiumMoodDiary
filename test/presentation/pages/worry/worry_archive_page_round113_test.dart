// v1.1.0 R113 (F1 烦恼闭环 audit gap 1): WorryArchivePage (忆往昔) widget 测试
//
// 覆盖:
// 1. 渲染 resolved threads (title + 🎉 + 计数 header)
// 2. 空状态文案 (worryArchiveEmpty)
// 3. 点击 resolved thread → context.push('/worry/:id') 进入 WorryTimelinePage
//    (实路由 AppRoutes.all() — 防 /worry/archive 被 /worry/:id 遮蔽回归)
// 4. 时间线页 resolved 状态 → "又烦恼了" → repository.reopen(id) + snackbar
//
// 依赖: worryResolvedProvider / worryOpenProvider 从 worryThreadRepositoryProvider
// 派生 (fake repo watchResolved/watchOpen); worryEntriesProvider 直接 override。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/routing/app_routes.dart';
import 'package:chroniccare/domain/entities/worry_thread_entity.dart';
import 'package:chroniccare/domain/repositories/worry_thread_repository.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/worry/worry_archive_page.dart';
import 'package:chroniccare/presentation/pages/worry/worry_timeline_page.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/worry_providers.dart';

/// 记录调用 + 可配置 resolved 列表的 WorryThreadRepository
class _FakeWorryRepo implements WorryThreadRepository {
  final List<WorryThreadEntity> resolved = [];
  final List<WorryThreadEntity> open = [];
  final List<String> log = [];

  @override
  Stream<List<WorryThreadEntity>> watchOpen() =>
      Stream.value(List.unmodifiable(open));

  @override
  Stream<List<WorryThreadEntity>> watchResolved() =>
      Stream.value(List.unmodifiable(resolved));

  @override
  Future<WorryThreadEntity?> getById(int id) async =>
      [...open, ...resolved].where((t) => t.id == id).firstOrNull;

  @override
  Future<int> create({required String title, required DateTime at}) async => 0;

  @override
  Future<int> resolve(int id, {required DateTime at}) async => 0;

  @override
  Future<int> reopen(int id) async {
    log.add('reopen:$id');
    return 1;
  }

  @override
  Future<int> rename(int id, String title) async => 0;

  @override
  Future<int> delete(int id) async => 0;
}

Widget _archiveApp({List<WorryThreadEntity>? resolved}) {
  return ProviderScope(
    overrides: [
      worryResolvedProvider
          .overrideWith((ref) => Stream.value(resolved ?? const [])),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: const WorryArchivePage(),
    ),
  );
}

Widget _routerApp(_FakeWorryRepo repo) {
  return ProviderScope(
    overrides: [
      worryThreadRepositoryProvider.overrideWithValue(repo),
      worryEntriesProvider.overrideWith((ref, id) => Stream.value(const [])),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/worry/archive',
        routes: AppRoutes.all(),
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
    ),
  );
}

WorryThreadEntity _resolved(int id, String title) => WorryThreadEntity(
      id: id,
      title: title,
      createdAt: DateTime(2026, 8, 10, 9),
      status: WorryStatus.resolved,
      resolvedAt: DateTime(2026, 8, 15, 20),
    );

void main() {
  testWidgets('渲染 resolved threads: title + 🎉 + 计数 header', (tester) async {
    await tester.pumpWidget(_archiveApp(resolved: [
      _resolved(1, '工作压力'),
      _resolved(2, '考试焦虑'),
    ]));
    await tester.pumpAndSettle();

    expect(find.byType(WorryArchivePage), findsOneWidget);
    expect(find.text('忆往昔'), findsOneWidget);
    expect(find.text('已放下 2 个烦恼'), findsOneWidget,
        reason: 'worryArchiveCount(2) 计数 header');
    expect(find.text('工作压力'), findsOneWidget);
    expect(find.text('考试焦虑'), findsOneWidget);
    expect(find.text('🎉'), findsNWidgets(2),
        reason: '每条 resolved thread 一个 🎉');
  });

  testWidgets('空状态: worryArchiveEmpty 文案', (tester) async {
    await tester.pumpWidget(_archiveApp(resolved: const []));
    await tester.pumpAndSettle();

    expect(find.text('还没有放下过的烦恼。把心情记成烦恼时间线，成长会被珍藏。'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('点击 resolved thread → 导航到 WorryTimelinePage (实路由)',
      (tester) async {
    final repo = _FakeWorryRepo()..resolved.add(_resolved(5, '工作压力'));
    await tester.pumpWidget(_routerApp(repo));
    await tester.pumpAndSettle();

    expect(find.byType(WorryArchivePage), findsOneWidget,
        reason: '/worry/archive 必须先匹配字面量路由 (BUG 1 回归)');
    await tester.tap(find.text('工作压力'));
    await tester.pumpAndSettle();

    expect(find.byType(WorryTimelinePage), findsOneWidget,
        reason: '点击应 push /worry/5 时间线');
    expect(find.text('又烦恼了'), findsOneWidget,
        reason: 'resolved thread 时间线显示 reopen 主动作');
  });

  testWidgets('时间线 resolved → 点"又烦恼了" → repository.reopen(5) + snackbar',
      (tester) async {
    final repo = _FakeWorryRepo()..resolved.add(_resolved(5, '工作压力'));
    await tester.pumpWidget(_routerApp(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('工作压力'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('又烦恼了'));
    await tester.pumpAndSettle();

    expect(repo.log, ['reopen:5'],
        reason: 'reopen 动作必调 repository.reopen(threadId)');
    expect(find.text('已重新打开，需要的时候随时来倾诉'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // 排空 snackbar 4s 计时器
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
