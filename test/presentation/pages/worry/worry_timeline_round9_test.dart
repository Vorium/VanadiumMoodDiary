// v1.1.0 round 9 (F1 烦恼闭环) — WorryTimelinePage / WorrySection / WorrySelectorField widget 测试
//
// 覆盖:
// 1. 时间线页渲染 title + 状态 + 记录列表
// 2. 空记录 → EmptyWorryState
// 3. WorrySection (mood list 入口): 有 open 烦恼 → 显示 chip, 无 → 隐藏
// 4. 点击"不再烦恼啦" → repo.resolve 被调用 + snackbar
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/entities/worry_thread_entity.dart';
import 'package:chroniccare/domain/repositories/worry_thread_repository.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/worry/worry_timeline_page.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/worry_providers.dart';
import 'package:chroniccare/presentation/widgets/worry_section.dart';

class _FakeWorryRepo implements WorryThreadRepository {
  final List<WorryThreadEntity> store = [];
  final List<WorryThreadEntity> resolvedStore = [];
  final List<MoodEntryEntity> entries = [];
  final List<String> log = [];

  _FakeWorryRepo() {
    store.add(WorryThreadEntity(
      id: 1,
      title: '工作压力',
      createdAt: DateTime(2026, 8, 15, 9),
      status: WorryStatus.open,
    ));
  }

  @override
  Stream<List<WorryThreadEntity>> watchOpen() =>
      Stream.value(List.unmodifiable(store));

  @override
  Stream<List<WorryThreadEntity>> watchResolved() =>
      Stream.value(List.unmodifiable(resolvedStore));

  @override
  Future<WorryThreadEntity?> getById(int id) async =>
      [...store, ...resolvedStore].where((t) => t.id == id).firstOrNull;

  @override
  Future<int> create({required String title, required DateTime at}) async {
    store.add(WorryThreadEntity(
      id: store.length + 1,
      title: title,
      createdAt: at,
      status: WorryStatus.open,
    ));
    return store.last.id;
  }

  @override
  Future<int> resolve(int id, {required DateTime at}) async {
    log.add('resolve:$id');
    final t = store.where((x) => x.id == id).firstOrNull;
    if (t != null) {
      store.remove(t);
      resolvedStore.add(t.copyWith(
        status: WorryStatus.resolved,
        resolvedAt: at,
      ));
    }
    return 1;
  }

  @override
  Future<int> reopen(int id) async {
    log.add('reopen:$id');
    return 1;
  }
  @override
  Future<void> noteRelapse(int id, {required DateTime at}) async {}

  @override
  Future<int> rename(int id, String title) async {
    log.add('rename:$id');
    return 1;
  }

  @override
  Future<int> delete(int id) async {
    log.add('delete:$id');
    store.removeWhere((t) => t.id == id);
    return 1;
  }
}

void main() {
  testWidgets('时间线页渲染 title + open 状态 + 记录', (tester) async {
    final repo = _FakeWorryRepo();
    repo.entries.add(MoodEntryEntity(
      id: 1,
      timestamp: DateTime(2026, 8, 15, 10),
      score: 3,
      note: '方案又被打回',
    ));

    await tester.pumpWidget(ProviderScope(
      overrides: [
        worryThreadRepositoryProvider.overrideWithValue(repo),
        worryEntriesProvider
            .overrideWith((ref, id) => Stream.value(repo.entries)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: const WorryTimelinePage(threadId: 1),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('工作压力'), findsOneWidget);
    expect(find.text('进行中'), findsOneWidget);
    expect(find.text('方案又被打回'), findsOneWidget);
    expect(find.text('继续倾诉'), findsOneWidget);
    expect(find.text('不再烦恼啦'), findsOneWidget);
  });

  testWidgets('空记录 → EmptyWorryState 文案', (tester) async {
    final repo = _FakeWorryRepo();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        worryThreadRepositoryProvider.overrideWithValue(repo),
        worryEntriesProvider.overrideWith((ref, id) => Stream.value(const [])),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: const WorryTimelinePage(threadId: 1),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('这个烦恼还没有记录，从「继续倾诉」开始吧'), findsOneWidget);
  });
  testWidgets('点击"不再烦恼啦" → resolve + 确认 dialog + snackbar', (tester) async {
    final repo = _FakeWorryRepo();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        worryThreadRepositoryProvider.overrideWithValue(repo),
        worryEntriesProvider.overrideWith((ref, id) => Stream.value(const [])),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: const WorryTimelinePage(threadId: 1),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('不再烦恼啦'));
    await tester.pumpAndSettle();
    // 确认 dialog
    expect(find.text('放下这个烦恼？'), findsOneWidget);
    await tester.tap(find.text('放下啦'));
    await tester.pumpAndSettle();

    expect(repo.log, contains('resolve:1'));
    expect(find.text('🎉 恭喜，你放下了一个烦恼'), findsOneWidget);
  });

  testWidgets('WorrySection: 有 open 烦恼 → 显示 chip', (tester) async {
    Widget build(
        List<WorryThreadEntity> open, List<WorryThreadEntity> resolved) {
      return ProviderScope(
        overrides: [
          worryThreadRepositoryProvider.overrideWithValue(_FakeWorryRepo()),
          worryOpenProvider.overrideWith((ref) => Stream.value(open)),
          worryResolvedProvider.overrideWith((ref) => Stream.value(resolved)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: const Scaffold(body: WorrySection()),
        ),
      );
    }

    await tester.pumpWidget(build(
      [
        WorryThreadEntity(
          id: 1,
          title: '工作压力',
          createdAt: DateTime(2026, 8, 15),
          status: WorryStatus.open,
        ),
      ],
      const [],
    ));
    await tester.pumpAndSettle();
    expect(find.text('烦恼心事'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, '工作压力'), findsOneWidget);
  });

  testWidgets('WorrySection: 无烦恼 → 隐藏', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        worryOpenProvider.overrideWith((ref) => Stream.value(const [])),
        worryResolvedProvider.overrideWith((ref) => Stream.value(const [])),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: const Scaffold(body: WorrySection()),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('烦恼心事'), findsNothing);
  });
}
