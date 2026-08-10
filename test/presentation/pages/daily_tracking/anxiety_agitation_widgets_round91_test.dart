// v0.30 round 91 (sub-spec 7 日常追踪 / Task 4 UI): AnxietyAgitationListWidget widget 测试
//
// 覆盖 (TDD red→green):
// 1. 渲染 list + 添加入口 + 空态
// 2. tap 添加 → AnxietyAgitationEntryDialog 打开 (3 字段: anxiety / agitation / note)
// 3. tap "3" for anxiety + "3" for agitation → tap 保存 → repo.add() 调 1 次
//
// 测试 setup: 跟 sleep_widgets_round91 同款 fake repo pattern
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/core/data/repositories/daily_tracking/anxiety_agitation_repository_impl.dart';
import 'package:chroniccare/domain/entities/anxiety_agitation_entry.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/anxiety_agitation_widgets.dart';
import 'package:chroniccare/presentation/providers/daily_tracking_providers.dart';

class _FakeAnxietyAgitationRepository
    implements AnxietyAgitationRepositoryImpl {
  final List<AnxietyAgitationEntryEntity> _entries = [];
  final StreamController<List<AnxietyAgitationEntryEntity>> _ctrl =
      StreamController<List<AnxietyAgitationEntryEntity>>.broadcast();
  int addCallCount = 0;

  @override
  Stream<List<AnxietyAgitationEntryEntity>> watchAll() async* {
    yield List.unmodifiable(_entries);
    yield* _ctrl.stream;
  }

  @override
  Future<int> add({
    required DateTime timestamp,
    required int anxietyScore,
    required int agitationScore,
    String? note,
  }) async {
    addCallCount++;
    final newId = _entries.length + 1;
    _entries.add(
      AnxietyAgitationEntryEntity(
        id: newId,
        timestamp: timestamp,
        anxietyScore: anxietyScore,
        agitationScore: agitationScore,
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
  late _FakeAnxietyAgitationRepository fakeRepo;

  setUp(() {
    fakeRepo = _FakeAnxietyAgitationRepository();
  });

  tearDown(() async {
    await fakeRepo._ctrl.close();
  });

  Widget wrap() {
    return ProviderScope(
      overrides: [
        anxietyAgitationRepositoryProvider.overrideWithValue(fakeRepo),
        anxietyAgitationEntriesProvider.overrideWith(
          (ref) => ref.watch(anxietyAgitationRepositoryProvider).watchAll(),
        ),
      ],
      child: const MaterialApp(
        // v0.30 R91 Task 7: widget 用 l10n.anxietyAgitationXxx, 测试需要 locale
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('zh'),
        home: Scaffold(body: SafeArea(child: AnxietyAgitationListWidget())),
      ),
    );
  }

  testWidgets(
      '空态 → tap 添加 → dialog → 选 焦虑 3 + 急躁 3 → tap 保存 → repo.add() 调 1 次',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    // 1. 空态
    expect(
      find.text('暂无焦虑急躁记录'),
      findsOneWidget,
      reason: '空 entry 时显示 EmptyState title',
    );

    // 2. tap 添加
    await tester.tap(find.text('添加评估'));
    await tester.pumpAndSettle();

    // 3. 验证 dialog 字段渲染
    expect(find.text('焦虑分数'), findsOneWidget);
    expect(find.text('急躁分数'), findsOneWidget);
    expect(find.text('备注'), findsOneWidget);

    // 4. tap "3" for 焦虑 (1-5 档评分 ChoiceChip)
    //    tap "3" for 急躁 (1-5 档评分 ChoiceChip)
    // 5 档 chip 全部 "1" "2" "3" "4" "5" 标签, dialog 2 个 section 各 5 chip
    // → find 第一个 "3" 落在焦虑段, find 最后一个 "3" 落在急躁段
    final threeChips = find.text('3');
    expect(
      threeChips,
      findsNWidgets(2),
      reason: '2 个 section (焦虑 + 急躁) 各 5 chip, "3" 出现 2 次',
    );

    await tester.tap(threeChips.first); // 焦虑分数 = 3
    await tester.pumpAndSettle();
    await tester.tap(threeChips.last); // 急躁分数 = 3
    await tester.pumpAndSettle();

    // 5. tap 保存
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    // 6. 验证: repo.add() 调 1 次 + dialog 关闭
    expect(
      fakeRepo.addCallCount,
      1,
      reason: 'AnxietyAgitationRepository.add() 必须被调 1 次',
    );
    expect(
      find.text('添加评估'),
      findsOneWidget,
      reason: 'dialog 关闭后 "添加评估" 按钮重新可见',
    );
  });
}
