// v0.30 round 91 (sub-spec 7 日常追踪 / Task 4 UI): SleepListWidget widget 测试
//
// 覆盖 (TDD red→green):
// 1. 渲染 list + 添加入口 + 空态
// 2. tap 添加 → SleepEntryDialog 打开 (4 字段: bedtime / wakeTime / regularity / note)
// 3. tap 保存 (默认 23:00→07:00 跨午夜, regularity=null, note=空)
//    → repository.add() 调 1 次 (fake 记录) + dialog 关闭
//
// 测试 setup:
// - 不用真实 in-memory DB (StreamProvider 跟 drift 联动会在 pumpAndSettle
//   时挂起, 跟 R91 cbt_thought_record_flow 集成测同款问题)
// - 改 override sleepRepositoryProvider → _FakeSleepRepository (走 List
//   + StreamController 控制流), 跟 R18 vent_list 测试同款 fake pattern
// - override sleepEntriesProvider (基于 fake repo 的 stream)
// - 验证: list 渲染 + dialog 打开 + 调 add() 1 次
//
// 不验证 showTimePicker UI 交互 (系统 dialog 太复杂), 默认值 23:00→07:00
// 跨午夜已覆盖 R91 sleep 核心 (跨午夜计算)。
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/core/data/repositories/daily_tracking/sleep_repository_impl.dart';
import 'package:chroniccare/domain/entities/sleep_entry.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/sleep_widgets.dart';
import 'package:chroniccare/presentation/providers/daily_tracking_providers.dart';

/// Fake SleepRepository (override 用, 跟 R18 vent_list _FakeVentRepository 同款)
class _FakeSleepRepository implements SleepRepositoryImpl {
  final List<SleepEntryEntity> _entries = [];
  final StreamController<List<SleepEntryEntity>> _ctrl =
      StreamController<List<SleepEntryEntity>>.broadcast();
  int addCallCount = 0;

  @override
  Stream<List<SleepEntryEntity>> watchAll() async* {
    yield List.unmodifiable(_entries);
    yield* _ctrl.stream;
  }

  @override
  Future<int> add({
    required DateTime date,
    required DateTime bedtime,
    required DateTime wakeTime,
    required int durationMin,
    int? regularityScore,
    String? note,
  }) async {
    addCallCount++;
    final newId = _entries.length + 1;
    _entries.add(
      SleepEntryEntity(
        id: newId,
        date: date,
        bedtime: bedtime,
        wakeTime: wakeTime,
        durationMin: durationMin,
        regularityScore: regularityScore,
        note: note,
      ),
    );
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
  late _FakeSleepRepository fakeRepo;

  setUp(() {
    fakeRepo = _FakeSleepRepository();
  });

  tearDown(() async {
    await fakeRepo._ctrl.close();
  });

  Widget wrap() {
    return ProviderScope(
      overrides: [
        sleepRepositoryProvider.overrideWithValue(fakeRepo),
        sleepEntriesProvider.overrideWith(
          (ref) => ref.watch(sleepRepositoryProvider).watchAll(),
        ),
      ],
      child: const MaterialApp(
        // v0.30 R91 Task 7: widget 用 l10n.sleepXxx, 测试需要 locale
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('zh'),
        home: Scaffold(body: SafeArea(child: SleepListWidget())),
      ),
    );
  }

  testWidgets('空态 → tap 添加 → dialog → tap 保存 → repo.add() 调 1 次',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    // 1. 初始: 空态 (EmptyState)
    expect(
      find.text('暂无睡眠记录'),
      findsOneWidget,
      reason: '空 entry 时显示 EmptyState title "暂无睡眠记录"',
    );

    // 2. tap 添加按钮 → 弹 SleepEntryDialog
    await tester.tap(find.text('添加睡眠记录'));
    await tester.pumpAndSettle();

    // 3. 验证 dialog 渲染 (4 字段)
    expect(find.text('入睡时间'), findsOneWidget);
    expect(find.text('起床时间'), findsOneWidget);
    expect(find.text('规律性'), findsOneWidget);
    expect(find.text('备注'), findsOneWidget);
    // 默认 23:00 → 07:00 = 8h = 480 min → durationLabel "8h00min"
    // dialog 显示 "时长: 8h00min" (Text widget 含前缀), 走 textContaining
    expect(
      find.textContaining('8h00min'),
      findsOneWidget,
      reason: '默认 bedtime=23:00 + wakeTime=07:00 跨午夜 → 8h00min',
    );

    // 4. tap 保存 → submit (调 repo.add, 关闭 dialog)
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    // 5. 验证: repo.add() 被调 1 次
    expect(
      fakeRepo.addCallCount,
      1,
      reason: '保存后 SleepRepository.add() 必须被调 1 次',
    );
    // 6. dialog 关闭
    expect(
      find.text('添加睡眠记录'),
      findsOneWidget,
      reason: 'dialog 关闭后 "添加睡眠记录" 按钮重新可见',
    );
  });
}
