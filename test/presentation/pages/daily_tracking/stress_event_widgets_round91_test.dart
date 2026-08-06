// v0.30 round 91 (sub-spec 7 日常追踪 / Task 4 UI): StressEventListWidget widget 测试
//
// 覆盖 (TDD red→green):
// 1. 渲染 list + 添加入口 + 空态
// 2. tap 添加 → StressEventEntryDialog 打开 (3 字段: eventType / intensity / note)
// 3. tap intensity "3" chip → tap 保存 → repo.add() 调 1 次
//
// 测试 setup: 跟 sleep_widgets_round91 同款 fake repo pattern
// (避免 StreamProvider 跟 drift 联动在 pumpAndSettle 时挂起)
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/core/data/repositories/daily_tracking/stress_event_repository_impl.dart';
import 'package:chroniccare/domain/entities/stress_event.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/stress_event_widgets.dart';
import 'package:chroniccare/presentation/providers/daily_tracking_providers.dart';

class _FakeStressEventRepository implements StressEventRepositoryImpl {
  final List<StressEventEntity> _entries = [];
  final StreamController<List<StressEventEntity>> _ctrl =
      StreamController<List<StressEventEntity>>.broadcast();
  int addCallCount = 0;

  @override
  Stream<List<StressEventEntity>> watchAll() async* {
    yield List.unmodifiable(_entries);
    yield* _ctrl.stream;
  }

  @override
  Future<int> add({
    required DateTime timestamp,
    required String eventType,
    required int intensity,
    String? note,
    int? linkedMoodEntryId,
  }) async {
    addCallCount++;
    final newId = _entries.length + 1;
    _entries.add(StressEventEntity(
      id: newId,
      timestamp: timestamp,
      eventType: eventType,
      intensity: intensity,
      note: note,
      linkedMoodEntryId: linkedMoodEntryId,
    ),);
    _ctrl.add(List.unmodifiable(_entries));
    return newId;
  }

  @override
  Future<int> delete(int id) async {
    _entries.removeWhere((e) => e.id == id);
    _ctrl.add(List.unmodifiable(_entries));
    return 1;
  }
}

void main() {
  late _FakeStressEventRepository fakeRepo;

  setUp(() {
    fakeRepo = _FakeStressEventRepository();
  });

  tearDown(() async {
    await fakeRepo._ctrl.close();
  });

  Widget wrap() {
    return ProviderScope(
      overrides: [
        stressEventRepositoryProvider.overrideWithValue(fakeRepo),
        stressEventEntriesProvider.overrideWith(
            (ref) => ref.watch(stressEventRepositoryProvider).watchAll(),),
      ],
      child: const MaterialApp(
        // v0.30 R91 Task 7: widget 用 l10n.stressEventXxx, 测试需要 locale
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('zh'),
        home: Scaffold(body: SafeArea(child: StressEventListWidget())),
      ),
    );
  }

  testWidgets(
      '空态 → tap 添加 → dialog → 选 intensity 3 → tap 保存 → repo.add() 调 1 次',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    // 1. 空态
    expect(find.text('暂无应激源记录'), findsOneWidget,
        reason: '空 entry 时显示 EmptyState title',);

    // 2. tap 添加
    await tester.tap(find.text('添加应激源'));
    await tester.pumpAndSettle();

    // 3. 验证 dialog 3 字段渲染
    expect(find.text('事件类型'), findsOneWidget);
    expect(find.text('强度'), findsOneWidget);
    expect(find.text('备注'), findsOneWidget);

    // 4. tap intensity "3" ChoiceChip (1-5 档评分)
    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();

    // 5. tap 保存
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    // 6. 验证: repo.add() 调 1 次 + dialog 关闭
    expect(fakeRepo.addCallCount, 1,
        reason: 'StressEventRepository.add() 必须被调 1 次',);
    expect(find.text('添加应激源'), findsOneWidget,
        reason: 'dialog 关闭后 "添加应激源" 按钮重新可见',);
  });
}
