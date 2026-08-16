// v1.1.0 R113 (BUG 7 + 7b): treatment_list 滑动删除失败错误处理回归测试
//
// 修前: onDismissed fire-and-forget 裸调用 `repo.delete(entry.id)` —
// delete 抛异常 = unhandled async error (widget test 直接 fail) + 条目
// 从 UI 消失但 DB 还在 (无任何恢复路径)。
// 修后: try/catch + swallowError + 错误 snackbar + invalidate
// treatmentEntriesProvider 重新拉流。
//
// BUG 7b (R113 后半): "invalidate 恢复条目" 这一半在实际用户路径上
// 不生效:
//   1. Riverpod 3.4.2 `AsyncValue.when` 对 invalidate 走 isRefreshing 分支
//      (skipLoadingOnRefresh 默认 true) → loading 分支永不渲染 →
//      Dismissible 元素 (key treatment-<id> 不变) 从不卸载;
//   2. 已 dismiss 的 Dismissible 在 resize 动画完成后被任何 rebuild 触发
//      FlutterError "A dismissed Dismissible widget is still part of the
//      tree" (debug 构建崩溃; release 断言剥离 = 条目静默不可见, 直到
//      离开页面重进)。
// 修法: Dismissible key 带失败计数 (`treatment-<id>-<failCount>`),
// 删除失败时计数 +1 → 旧 Dismissible unmount + 新 key remount 回
// "未滑走"状态, 条目立即回到列表。
//
// 因此本文件:
// - 行为测试 A 走直接调 onDismissed (不经过 swipe 的 dismiss 状态) —
//   覆盖修后 catch 处理链: 无 unhandled error + 错误 snackbar + 条目仍在;
// - 行为测试 B 走全流程真实 swipe — 锁 BUG 7b: 无 "dismissed Dismissible"
//   FlutterError + 条目滑走后重新可见 (tester.takeException() 必须 null);
// - 源码 lock-in 锁 catch 结构 (try/catch + swallowError + snackbar +
//   invalidate), 修前代码 (裸 delete) 必 fail。
//
// 依赖: treatmentRepositoryProvider override 为抛异常 fake;
// treatmentEntriesProvider 由其自动派生。

import 'dart:io';

import 'package:chroniccare/domain/entities/treatment_entry.dart';
import 'package:chroniccare/domain/repositories/treatment_repository.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/treatment_page.dart';
import 'package:chroniccare/presentation/providers/daily_tracking_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// delete 必抛异常的治疗仓库 — watchAll 始终返回原条目列表
class _ThrowingTreatmentRepository implements TreatmentRepository {
  final List<TreatmentEntryEntity> entries;

  _ThrowingTreatmentRepository(this.entries);

  @override
  Stream<List<TreatmentEntryEntity>> watchAll() => Stream.fromFuture(
        Future<List<TreatmentEntryEntity>>.delayed(
          const Duration(milliseconds: 500),
          () => List.unmodifiable(entries),
        ),
      );

  @override
  Future<int> delete(int id) async {
    throw Exception('db delete failed');
  }

  @override
  Future<int> add({
    required DateTime timestamp,
    required String treatmentType,
    required String description,
    int? linkedMedicationId,
    String? linkedMedicationName,
    String? note,
  }) async =>
      1;

  @override
  Future<int> submitEntry({
    required String treatmentType,
    required String description,
    int? linkedMedicationId,
    String? note,
  }) async =>
      1;
}

void main() {
  /// 800x2000 模拟手机视口 (跟 treatment_page_round92 同款)
  void setBigView(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget wrap(TreatmentRepository repo) {
    return ProviderScope(
      overrides: [
        treatmentRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        routerConfig: GoRouter(
          initialLocation: '/treatment',
          routes: [
            GoRoute(
              path: '/treatment',
              builder: (context, state) => const TreatmentPage(),
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
    final entry = TreatmentEntryEntity(
      id: 1,
      timestamp: DateTime(2026, 8, 1),
      treatmentType: 'consultation',
      description: '心理医生 (王医生)',
      note: '聊得不错',
    );
    await tester.pumpWidget(wrap(_ThrowingTreatmentRepository([entry])));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.textContaining('心理咨询'), findsOneWidget);

    // 真实 swipe (endToStart) → Dismissible 真正进入 dismissed 状态
    await tester.drag(
      find.byType(Dismissible).first,
      const Offset(-600, 0),
    );
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
      find.textContaining('心理咨询'),
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

  testWidgets('delete 抛异常 → 错误 snackbar + 条目仍在 + 无 unhandled error',
      (tester) async {
    setBigView(tester);
    final entry = TreatmentEntryEntity(
      id: 1,
      timestamp: DateTime(2026, 8, 1),
      treatmentType: 'consultation',
      description: '心理医生 (王医生)',
      note: '聊得不错',
    );
    await tester.pumpWidget(wrap(_ThrowingTreatmentRepository([entry])));
    // 初始 load: fake watchAll 500ms 定时 emit (模拟 drift 异步流) → 数据渲染
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.textContaining('心理咨询'), findsOneWidget);

    // 直接调 onDismissed (绕过 swipe 的 dismiss 状态 — 全流程 swipe 会触发
    // BUG 7b 的 Dismissible FlutterError, 见文件头) → catch 链: swallowError
    // + 错误 snackbar + invalidate (条目仍非 dismissed → 重发射后可见)
    final dismissible = tester.widget<Dismissible>(
      find.byType(Dismissible).first,
    );
    dismissible.onDismissed!(DismissDirection.endToStart);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    // 修前: delete 裸调用 → unhandled async error (widget test fail)
    expect(
      find.textContaining('删除失败'),
      findsOneWidget,
      reason: 'delete 抛异常应显示错误 snackbar (commonDelete 模板)',
    );
    expect(
      find.textContaining('心理咨询'),
      findsOneWidget,
      reason: '条目仍在 DB (fake watchAll 仍返回) → 非 dismissed 状态下重发射可见',
    );
    expect(
      tester.takeException(),
      isNull,
      reason: '修前 fire-and-forget delete 抛异常 = unhandled async error',
    );

    // 排空错误 snackbar 4s 计时器, 避免 test 结束 pending timer
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  test('onDismissed catch 结构源码 lock-in (修前裸 delete 必 fail)', () {
    final source = File(
      'lib/presentation/pages/daily_tracking/widgets/treatment_list.dart',
    ).readAsStringSync();
    final start = source.indexOf('onDismissed: (_) async {');
    expect(start, isNot(-1), reason: 'onDismissed 必须是 async 闭包');
    final end = source.indexOf('child: AppListTile.carded(', start);
    expect(end, isNot(-1), reason: '闭包边界必须存在');
    final body = source.substring(start, end);
    expect(body.contains('try {'), isTrue, reason: 'delete 必须在 try 内');
    expect(body.contains('await repo.delete(entry.id)'), isTrue);
    expect(body.contains('swallowError('), isTrue, reason: '必须走 swallowError');
    expect(
      body.contains('AppSnackBar.showError'),
      isTrue,
      reason: '必须弹错误 snackbar 提示用户',
    );
    expect(
      body.contains('ref.invalidate(treatmentEntriesProvider)'),
      isTrue,
      reason: '必须 invalidate 重拉流',
    );
  });
}
