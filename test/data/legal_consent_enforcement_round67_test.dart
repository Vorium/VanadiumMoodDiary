// v0.27 round 67 (Sprint 1 上架前 P0, spzh C-P0-6):
// 撤回同意业务层生效验证
//
// 背景: R67 修复前, `legalConsentWithdrawnProvider` 只被 legal_page 自身读,
// 业务层 (VentRepositoryImpl / trend_page) 0 拦截 → PIPL §14
// 严重违反 (spzh 视角 P0-6 标记)。R67 修复后:
// - VentRepositoryImpl.add() / restore() 入口检查 ConsentKind.vent 撤回状态
//   → 撤回时 throw VentConsentWithdrawnError
// - trend_page build() 顶部检查 ConsentKind.analytics 撤回状态
//   → 撤回时渲染 EmptyState 占位
//
// 1.1.0 round 4b (emotion-first refactor): FireCareStrategyUseCase (关怀
// use case) 随 CareEngine 整摘, A-3.2 组删除。剩余 2 case 覆盖 2 个
// entry point (vent repo + trend page), 验证 R67 修复实际生效。
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/repositories/vent/vent_repository_impl.dart';
import 'package:chroniccare/core/data/services/encryption_service.dart';
import 'package:chroniccare/core/shared/consent_gate.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/trend/trend_page.dart';
import 'package:chroniccare/presentation/providers/legal_consent_provider.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/empty_state.dart';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 测试用 fake ConsentGate (返固定值)
class _FakeConsentGate implements ConsentGate {
  final bool ventWithdrawn;
  _FakeConsentGate({this.ventWithdrawn = false});

  @override
  Future<bool> isWithdrawn(ConsentKind kind) async {
    if (kind == ConsentKind.vent) return ventWithdrawn;
    return false;
  }
}

Widget _buildTrendPage({required bool analyticsWithdrawn}) {
  return ProviderScope(
    overrides: [
      allCheckInsProvider.overrideWith((ref) => Stream.value(const [])),
      allMoodProvider.overrideWith((ref) => Stream.value(const [])),
      assessmentsProvider.overrideWith((ref) => Stream.value(const [])),
      legalConsentWithdrawnProvider(ConsentKind.analytics)
          .overrideWith((ref) => Stream.value(analyticsWithdrawn)),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('zh'),
      home: TrendPage(),
    ),
  );
}

void main() {
  group('A-3.1 VentRepositoryImpl.add 撤回 vent 同意 → throw', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      // EncryptionService 默认走 flutter_secure_storage platform channel, 测试环境
      // 不可用。用 setKeyForTest 注入固定 32 字节 key, 绕过 platform channel。
      EncryptionService().setKeyForTest(
        Uint8List.fromList(List.generate(32, (i) => i)),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('gate.ventWithdrawn=false → add 成功', () async {
      final repo = VentRepositoryImpl(
        db,
        null, // audioStorage
        null, // encryption
        _FakeConsentGate(ventWithdrawn: false),
      );
      final id = await repo.add(text: '今天心情不错');
      expect(id, greaterThan(0), reason: '未撤回同意时 add 应正常返回 id');
    });

    test('gate.ventWithdrawn=true → add 抛 VentConsentWithdrawnError', () async {
      final repo = VentRepositoryImpl(
        db,
        null,
        null,
        _FakeConsentGate(ventWithdrawn: true),
      );
      expect(
        () => repo.add(text: '今天心情不错'),
        throwsA(isA<VentConsentWithdrawnError>()),
        reason: '撤回 vent 同意时 add 必须拒绝, 抛 VentConsentWithdrawnError',
      );
    });

    test('gate.ventWithdrawn=true → restore (Dismissible Undo) 也拒绝', () async {
      // restore() 内部调 add(), 所以同一 gate 应生效
      final repo = VentRepositoryImpl(
        db,
        null,
        null,
        _FakeConsentGate(ventWithdrawn: false),
      );
      // 先 add 一条
      final id = await repo.add(text: '原条目');
      final entity = await repo.getById(id);
      expect(entity, isNotNull);

      // 撤回后 restore
      final repoWithdrawn = VentRepositoryImpl(
        db,
        null,
        null,
        _FakeConsentGate(ventWithdrawn: true),
      );
      expect(
        () => repoWithdrawn.restore(entity!),
        throwsA(isA<VentConsentWithdrawnError>()),
        reason: '撤回后 Undo 也应拒绝 (避免用户感觉已撤回却能恢复)',
      );
    });

    test('VentConsentWithdrawnError.message 默认 = "已撤回树洞同意" 文案', () {
      final err = VentConsentWithdrawnError();
      expect(err.message, contains('已撤回'));
    });
  });

  // A-3.2 (1.1.0 round 4b): FireCareStrategyUseCase 组随 CareEngine 整摘删除。

  group('A-3.3 trend_page 撤回 analytics 同意 → EmptyState', () {
    testWidgets('analytics 未撤回 → 不显示 EmptyState', (tester) async {
      await tester.pumpWidget(_buildTrendPage(analyticsWithdrawn: false));
      await tester.pumpAndSettle();
      expect(find.byType(TrendPage), findsOneWidget);
      expect(
        find.byType(EmptyState),
        findsNothing,
        reason: '未撤回时不显示 EmptyState',
      );
    });

    testWidgets('analytics 撤回 → 渲染 EmptyState 占位', (tester) async {
      await tester.pumpWidget(_buildTrendPage(analyticsWithdrawn: true));
      await tester.pumpAndSettle();
      expect(
        find.byType(EmptyState),
        findsOneWidget,
        reason: '撤回 analytics 同意时, 趋势页应渲染 EmptyState 占位',
      );
    });
  });
}
