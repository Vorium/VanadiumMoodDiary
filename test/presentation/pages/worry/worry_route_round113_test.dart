// R113 (BUG 1): /worry/archive 死路由遮蔽 + /worry/:id 不存在的空态
//
// 修前: /worry/:id 先注册 (first-match-wins) → /worry/archive 被吞成
//   id='archive' → int.tryParse ?? 0 → WorryTimelinePage(threadId: 0) 永远转圈,
//   "忆往昔"入口假死。
// 修后: 字面量路由先注册 → WorryArchivePage 正常显示。
//
// 附加回归: 不存在的烦恼 id (已删除 / 非法) → EmptyState + 返回引导,
//   不再无限 CircularProgressIndicator。
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

class _FakeWorryRepo implements WorryThreadRepository {
  @override
  Stream<List<WorryThreadEntity>> watchOpen() => Stream.value(const []);

  @override
  Stream<List<WorryThreadEntity>> watchResolved() => Stream.value(const []);

  @override
  Future<WorryThreadEntity?> getById(int id) async => null;

  @override
  Future<int> create({required String title, required DateTime at}) async => 1;

  @override
  Future<int> resolve(int id, {required DateTime at}) async => 1;

  @override
  Future<int> reopen(int id) async => 1;

  @override
  Future<void> noteRelapse(int id, {required DateTime at}) async {}

  @override
  Future<int> rename(int id, String title) async => 1;

  @override
  Future<int> delete(int id) async => 1;
}

Widget buildRouter(String initialLocation) {
  return ProviderScope(
    overrides: [
      worryThreadRepositoryProvider.overrideWithValue(_FakeWorryRepo()),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: initialLocation,
        routes: AppRoutes.all(),
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
    ),
  );
}

void main() {
  testWidgets('/worry/archive → WorryArchivePage (不被 /worry/:id 遮蔽)',
      (tester) async {
    await tester.pumpWidget(buildRouter('/worry/archive'));
    await tester.pumpAndSettle();

    expect(
      find.byType(WorryArchivePage),
      findsOneWidget,
      reason: '字面量路由应先匹配 — 修前这里会进 WorryTimelinePage(threadId: 0)',
    );
    expect(find.text('忆往昔'), findsOneWidget);
    expect(
      find.byType(WorryTimelinePage),
      findsNothing,
      reason: '修前 bug: /worry/archive 被 /worry/:id 吞掉, timeline 永远转圈',
    );
  });

  testWidgets('/worry/999 (不存在) → 空态 + 返回引导, 非无限转圈', (tester) async {
    await tester.pumpWidget(buildRouter('/worry/999'));
    await tester.pumpAndSettle();

    expect(
      find.text('这个烦恼找不到了，可能已经删除'),
      findsOneWidget,
      reason: 'thread==null 应显示 not-found 空态而非 spinner',
    );
    expect(find.text('返回'), findsOneWidget, reason: '应给返回引导出口');
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
