// v0.30 round 91 (sub-spec 7 日常追踪 / Task 4 UI): SocialRhythmListWidget widget 测试
//
// 覆盖 (TDD red→green):
// 1. 渲染 list + 添加入口 + 空态
// 2. tap 添加 → SocialRhythmEntryDialog 打开 (6 字段: 3 TimeOfDay + 3 number)
// 3. tap 保存 (默认 07:00 / 12:00 / 19:00 + 0 / 0 / 0) → repo.add() 调 1 次
//
// 测试 setup: 跟 sleep_widgets_round91 同款 fake repo pattern
// (避免 StreamProvider 跟 drift 联动在 pumpAndSettle 时挂起)
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/core/data/repositories/daily_tracking/social_rhythm_repository_impl.dart';
import 'package:chroniccare/domain/entities/social_rhythm_entry.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/social_rhythm_widgets.dart';
import 'package:chroniccare/presentation/providers/daily_tracking_providers.dart';

class _FakeSocialRhythmRepository implements SocialRhythmRepositoryImpl {
  final List<SocialRhythmEntryEntity> _entries = [];
  final StreamController<List<SocialRhythmEntryEntity>> _ctrl =
      StreamController<List<SocialRhythmEntryEntity>>.broadcast();
  int addCallCount = 0;

  @override
  Stream<List<SocialRhythmEntryEntity>> watchAll() async* {
    yield List.unmodifiable(_entries);
    yield* _ctrl.stream;
  }

  @override
  Future<int> add({
    required DateTime date,
    required DateTime wakeTime,
    required DateTime firstMealTime,
    required DateTime lastMealTime,
    int socialMin = 0,
    int workMin = 0,
    int exerciseMin = 0,
  }) async {
    addCallCount++;
    final newId = _entries.length + 1;
    _entries.add(SocialRhythmEntryEntity(
      id: newId,
      date: date,
      wakeTime: wakeTime,
      firstMealTime: firstMealTime,
      lastMealTime: lastMealTime,
      socialMin: socialMin,
      workMin: workMin,
      exerciseMin: exerciseMin,
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
  late _FakeSocialRhythmRepository fakeRepo;

  setUp(() {
    fakeRepo = _FakeSocialRhythmRepository();
  });

  tearDown(() async {
    await fakeRepo._ctrl.close();
  });

  Widget wrap() {
    return ProviderScope(
      overrides: [
        socialRhythmRepositoryProvider.overrideWithValue(fakeRepo),
        socialRhythmEntriesProvider.overrideWith(
            (ref) => ref.watch(socialRhythmRepositoryProvider).watchAll(),),
      ],
      child: const MaterialApp(
        home: Scaffold(body: SafeArea(child: SocialRhythmListWidget())),
      ),
    );
  }

  testWidgets('空态 → tap 添加 → dialog → tap 保存 → repo.add() 调 1 次',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    // 1. 空态
    expect(find.text('暂无社会节律记录'), findsOneWidget,
        reason: '空 entry 时显示 EmptyState title',);

    // 2. tap 添加
    await tester.tap(find.text('添加社会节律'));
    await tester.pumpAndSettle();

    // 3. 验证 dialog 6 字段渲染
    expect(find.text('起床时间'), findsOneWidget);
    expect(find.text('第一餐时间'), findsOneWidget);
    expect(find.text('最后一餐时间'), findsOneWidget);
    expect(find.text('社交时长 (分钟)'), findsOneWidget);
    expect(find.text('工作时长 (分钟)'), findsOneWidget);
    expect(find.text('运动时长 (分钟)'), findsOneWidget);

    // 4. tap 保存 (defaults: 07:00 / 12:00 / 19:00 + 0 / 0 / 0)
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    // 5. 验证: repo.add() 调 1 次 + dialog 关闭
    expect(fakeRepo.addCallCount, 1,
        reason: 'SocialRhythmRepository.add() 必须被调 1 次',);
    expect(find.text('添加社会节律'), findsOneWidget,
        reason: 'dialog 关闭后 "添加社会节律" 按钮重新可见',);
  });
}
