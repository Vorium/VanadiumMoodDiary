// v0.32 round 8 (R112-07 fix): /medication/detail/:id 脏 URL id 不崩
//
// 背景: app_route_medication.dart:91 `int.parse(state.pathParameters['id']!)`
// — 恶意/脏 URL /medication/detail/abc 抛 FormatException → GoRouter catch
// 不到直接崩 app (跟 v0.16 round 19C vent 路由同款 bug)。
//
// 修: `int.tryParse(...) ?? 0` (跟 app_route_vent.dart:38 同款模式),
// id=0 → MedicationDetailPage 已有 medNotFound 分支 ("药物未找到")。
//
// 测试 2 case (走 AppRouteMedication.shellRoutes() 真实 route builder):
// 1. /medication/detail/abc → 不崩, 渲染 medNotFound 文案
// 2. /medication/detail/42 → int 正常解析, MedicationDetailPage 渲染
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/routing/app_route_medication.dart';
import 'package:chroniccare/presentation/pages/medication/medication_detail_page.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  Future<GoRouter> pumpDetail(WidgetTester tester, String location) async {
    final detailRoute = AppRouteMedication.shellRoutes().firstWhere(
      (r) => r is GoRoute && r.path == '/medication/detail/:id',
    ) as GoRoute;
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: '/medication/detail/:id',
          pageBuilder: detailRoute.pageBuilder,
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allMedicationsProvider
              .overrideWith((ref) => Stream.value(const <MedicationEntity>[])),
          allCheckInsProvider.overrideWith((ref) => Stream.value(const [])),
          todayProvider.overrideWithValue(DateTime(2026, 8, 13)),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  group('medication detail route param 安全解析 (R112-07)', () {
    testWidgets('1. /medication/detail/abc → 不崩 + medNotFound 文案',
        (tester) async {
      await pumpDetail(tester, '/medication/detail/abc');

      expect(find.byType(MedicationDetailPage), findsOneWidget);
      expect(
        find.text('药物未找到'),
        findsOneWidget,
        reason: '脏 id tryParse 失败 → fallback 0 → medNotFound 分支',
      );
    });

    testWidgets('2. /medication/detail/42 → MedicationDetailPage 渲染 (id 解析正常)',
        (tester) async {
      await pumpDetail(tester, '/medication/detail/42');

      expect(find.byType(MedicationDetailPage), findsOneWidget);
      expect(
        find.text('药物未找到'),
        findsOneWidget,
        reason: 'id=42 解析成功但列表空 → medNotFound (无 provider 崩)',
      );
    });
  });
}
