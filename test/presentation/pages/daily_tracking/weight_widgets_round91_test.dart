// v0.30 round 91 (sub-spec 7 日常追踪 / Task 4 UI): WeightListWidget widget 测试
//
// 覆盖 (TDD red→green):
// 1. 渲染 list + 添加入口 + 空态
// 2. tap 添加 → WeightEntryDialog 打开 (3 字段: weightKg / bmi 自动 / note)
// 3. 输入 "60" → tap 保存 → repo.add() 调 1 次
//
// 测试 setup: 跟 sleep_widgets_round91 同款 fake repo pattern
// BMI 读 profile.height (R91 brief "找不到时 bmi=null"), 跟 R55 user_profile 兼容
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/core/data/repositories/daily_tracking/weight_repository_impl.dart';
import 'package:chroniccare/domain/entities/weight_entry.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/weight_widgets.dart';
import 'package:chroniccare/presentation/providers/daily_tracking_providers.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';

class _FakeWeightRepository implements WeightRepositoryImpl {
  final List<WeightEntryEntity> _entries = [];
  final StreamController<List<WeightEntryEntity>> _ctrl =
      StreamController<List<WeightEntryEntity>>.broadcast();
  int addCallCount = 0;

  @override
  Stream<List<WeightEntryEntity>> watchAll() async* {
    yield List.unmodifiable(_entries);
    yield* _ctrl.stream;
  }

  @override
  Future<int> add({
    required DateTime timestamp,
    required double weightKg,
    double? bmi,
    String? note,
  }) async {
    addCallCount++;
    final newId = _entries.length + 1;
    _entries.add(WeightEntryEntity(
      id: newId,
      timestamp: timestamp,
      weightKg: weightKg,
      bmi: bmi,
      note: note,
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
  late _FakeWeightRepository fakeRepo;

  setUp(() {
    fakeRepo = _FakeWeightRepository();
  });

  tearDown(() async {
    await fakeRepo._ctrl.close();
  });

  Widget wrap() {
    return ProviderScope(
      overrides: [
        weightRepositoryProvider.overrideWithValue(fakeRepo),
        weightEntriesProvider.overrideWith(
            (ref) => ref.watch(weightRepositoryProvider).watchAll(),),
        // userProfileProvider override: null (R91 user_profile 暂没 heightCm 字段)
        userProfileProvider.overrideWith((ref) => Stream.value(null)),
      ],
      child: const MaterialApp(
        home: Scaffold(body: SafeArea(child: WeightListWidget())),
      ),
    );
  }

  testWidgets('空态 → tap 添加 → dialog → 输入 60 → tap 保存 → repo.add() 调 1 次',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    // 1. 空态
    expect(find.text('暂无体重记录'), findsOneWidget,
        reason: '空 entry 时显示 EmptyState title',);

    // 2. tap 添加
    await tester.tap(find.text('添加体重记录'));
    await tester.pumpAndSettle();

    // 3. 验证 dialog 字段渲染
    expect(find.text('体重 (kg)'), findsOneWidget);
    expect(find.text('备注'), findsOneWidget);
    // BMI 字段 (auto-computed, profile.height 缺失 → "暂无 (需 profile.height)")
    expect(find.textContaining('BMI'), findsOneWidget,
        reason: 'dialog 显示 BMI 行 (含 "BMI" prefix)',);

    // 4. 输入体重 60
    await tester.enterText(find.byType(TextField).first, '60');
    await tester.pumpAndSettle();

    // 5. tap 保存
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    // 6. 验证: repo.add() 调 1 次 + dialog 关闭
    expect(fakeRepo.addCallCount, 1, reason: 'WeightRepository.add() 必须被调 1 次');
    expect(find.text('添加体重记录'), findsOneWidget,
        reason: 'dialog 关闭后 "添加体重记录" 按钮重新可见',);
  });
}
