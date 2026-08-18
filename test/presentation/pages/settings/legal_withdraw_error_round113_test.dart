// v1.1.0 R113 (BUG 8 + 8b): legal_page withdraw 失败错误处理 + vent 撤回
// 3 选 1 dialog 选项可点回归测试
//
// 修前: `await store.withdraw(kind)` 在 try 外 — SP 写失败 = unhandled
// async error (widget test 直接 fail), 用户无任何提示、无法重试。
// 修后: try/catch + swallowError + 错误 snackbar, 失败不置 withdrawn
// (toggle 保持关, 用户可重试), 成功路径回读 store.withdrawnAt(kind)
// (不再用页面二次 DateTime.now() 记时间)。
//
// BUG 8b (R113 后半): vent 撤回 3 选 1 dialog 的 _WithdrawOption 是裸 Row
// — 无 onTap/InkWell/GestureDetector (R82.5 引入即存在), "立即删除" /
// "加密封存"两个选项点不了, 用户只能点"取消"。修: InkWell 包裹 +
// choice 字段, tap = pop(choice) 传回 _toggle。
//
// 覆盖:
// 1. 行为 (analytics toggle): withdraw 抛异常 → 无 unhandled error +
//    错误 snackbar ('重试删除失败：…') + toggle 值保持 false + 可重试
// 2. 行为 (BUG 8b): vent toggle → 3 选 1 dialog → 点"立即删除" →
//    dialog 关闭 + store.withdraw 被调 + withdrawn 状态置位
//    (store 成功路径)
// 3. 源码 lock-in (vent 路径): store.withdraw 在 try 内 + catch 弹错误
//    snackbar — vent 路径 UI 前置 3 选 1 dialog 的选项行当前无 tap 处理
//    (untappable, 见报告), 行为层用同构的 analytics 路径覆盖, vent
//    路径用 lock-in 锁修复不退化。
//
// 依赖: legalConsentStoreProvider override 为 fake store
// (extends ConsentPreferenceStore, export_tile_round95 同款模式);
// BUG 8b 行为测试额外 override ventRepositoryProvider (deleteAll 路径)。

import 'dart:io';

import 'package:chroniccare/core/data/services/consent_preference_store.dart';
import 'package:chroniccare/domain/entities/vent_entry_entity.dart';
import 'package:chroniccare/domain/repositories/vent_repository.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/settings/legal_page.dart';
import 'package:chroniccare/presentation/providers/legal_consent_provider.dart';
import 'package:chroniccare/presentation/providers/vent_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// withdraw 必抛的 fake store (读状态正常, 写必失败)
class _FakeFailingConsentStore extends ConsentPreferenceStore {
  _FakeFailingConsentStore(super.mockPrefs);

  int withdrawCalls = 0;

  @override
  Future<bool> isWithdrawn(ConsentKind kind) async => false;

  @override
  Future<DateTime?> withdrawnAt(ConsentKind kind) async => null;

  @override
  Future<bool> isSealed(ConsentKind kind) async => false;

  @override
  Future<DateTime?> sealedAt(ConsentKind kind) async => null;

  @override
  Future<void> withdraw(ConsentKind kind) async {
    withdrawCalls++;
    throw Exception('prefs write failed');
  }
}

/// withdraw 成功的 fake store (BUG 8b 行为测试: 验证选项 tap → 状态置位)
class _FakeSuccessConsentStore extends ConsentPreferenceStore {
  _FakeSuccessConsentStore(super.mockPrefs);

  final Set<ConsentKind> withdrawnKinds = {};

  @override
  Future<bool> isWithdrawn(ConsentKind kind) async =>
      withdrawnKinds.contains(kind);

  @override
  Future<DateTime?> withdrawnAt(ConsentKind kind) async =>
      withdrawnKinds.contains(kind) ? DateTime(2026, 8, 16, 10, 0) : null;

  @override
  Future<bool> isSealed(ConsentKind kind) async => false;

  @override
  Future<DateTime?> sealedAt(ConsentKind kind) async => null;

  @override
  Future<void> withdraw(ConsentKind kind) async {
    withdrawnKinds.add(kind);
  }
}

/// deleteAll 成功返回 0 的 vent 仓库 (BUG 8b 行为测试: 立即删除路径)
class _FakeVentRepo implements VentRepository {
  @override
  Stream<List<VentEntryEntity>> watchAll() => Stream.value(const []);

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
  }) async =>
      0;

  @override
  Future<bool> delete(int id) async => true;

  @override
  Future<int> restore(VentEntryEntity entry) async => entry.id;

  @override
  Future<int> deleteAll() async => 0;
}

void main() {
  late SharedPreferences sp;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    sp = await SharedPreferences.getInstance();
  });

  testWidgets(
      '1) analytics 撤回同意失败 → 错误 snackbar + toggle 保持关 + 无 unhandled error',
      (tester) async {
    final store = _FakeFailingConsentStore(sp);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          legalConsentStoreProvider.overrideWithValue(store),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('zh'),
          home: LegalPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 2 个 toggle: vent / analytics — analytics 是第 2 个 Switch
    final analyticsSwitch = find.byType(Switch).at(1);
    expect(tester.widget<Switch>(analyticsSwitch).value, isFalse);

    await tester.tap(analyticsSwitch);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('重试删除失败'),
      findsOneWidget,
      reason: 'withdraw 抛异常应显示错误 snackbar (legalVentDeleteRetry 模板)',
    );
    expect(
      tester.widget<Switch>(find.byType(Switch).at(1)).value,
      isFalse,
      reason: '失败不置 withdrawn — toggle 保持关, 用户可重试',
    );
    expect(store.withdrawCalls, 1);
    expect(
      tester.takeException(),
      isNull,
      reason: '修前 store.withdraw 在 try 外 → unhandled async error',
    );

    // 排空错误 snackbar 4s 计时器
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets(
      '2) BUG 8b: vent 撤回 3 选 1 dialog 点"立即删除" → dialog 关闭 + '
      'withdraw 被调 + withdrawn 置位', (tester) async {
    final store = _FakeSuccessConsentStore(sp);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          legalConsentStoreProvider.overrideWithValue(store),
          ventRepositoryProvider.overrideWithValue(_FakeVentRepo()),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('zh'),
          home: LegalPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // vent 是第 1 个 Switch
    final ventSwitch = find.byType(Switch).at(0);
    expect(tester.widget<Switch>(ventSwitch).value, isFalse);

    await tester.tap(ventSwitch);
    await tester.pumpAndSettle();

    // 3 选 1 dialog: title + 2 个选项 + 取消
    expect(find.text('撤回树洞同意'), findsOneWidget);
    expect(find.text('立即删除'), findsOneWidget);
    expect(find.text('加密封存'), findsOneWidget);

    // BUG 8b 修前: 选项是裸 Row, tap 无效果 (dialog 不关, withdraw 不调)
    await tester.tap(find.text('立即删除'));
    await tester.pumpAndSettle();

    expect(
      find.text('立即删除'),
      findsNothing,
      reason: '点选项后 dialog 必须 pop 关闭',
    );
    expect(
      store.withdrawnKinds.contains(ConsentKind.vent),
      isTrue,
      reason: '选"立即删除" → _toggle 必须调 store.withdraw(vent)',
    );
    expect(
      tester.widget<Switch>(find.byType(Switch).at(0)).value,
      isTrue,
      reason: 'withdraw 成功后 vent toggle 置位 withdrawn',
    );
    expect(tester.takeException(), isNull);

    // 排空 info snackbar 2s 计时器
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  test('3) vent 撤回路径源码 lock-in: withdraw 在 try 内 + 失败 snackbar', () {
    final source = File(
      'lib/features/settings/presentation/pages/settings/legal_page.dart',
    ).readAsStringSync();
    final start = source.indexOf('// 2 个选择都标 withdrawn=true');
    expect(start, isNot(-1), reason: 'vent withdraw 段注释必须存在');
    final end = source.indexOf('// analytics 走原路径', start);
    expect(end, isNot(-1), reason: '段边界注释必须存在');
    final body = source.substring(start, end);
    final tryIdx = body.indexOf('try {');
    // 带分号的代码调用行 (doc 注释里的 `store.withdraw(kind)` 不带分号, 排除)
    final withdrawIdx = body.indexOf('await store.withdraw(kind);');
    expect(tryIdx, isNot(-1), reason: 'vent 路径必须有 try 块');
    expect(withdrawIdx, isNot(-1), reason: 'withdraw 调用必须存在');
    expect(
      tryIdx,
      lessThan(withdrawIdx),
      reason: '修前 withdraw 在 try 外 → unhandled async error',
    );
    expect(
      body.contains('AppSnackBar.showError'),
      isTrue,
      reason: 'catch 必须弹错误 snackbar 提示用户重试',
    );
    expect(
      body.contains('store.withdrawnAt(kind)'),
      isTrue,
      reason: '成功路径必须回读持久化撤回时间 (不二次 DateTime.now)',
    );
  });
}
