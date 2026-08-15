// 1.1.0 round 5c: vent list 标签筛选 widget 测试
//
// 覆盖:
// 1. 初始渲染: 全部条目 + 筛选 chips (全部/家庭/工作), 全部默认选中
// 2. tap '家庭' → 列表只剩带 家庭 的条目
// 3. tap '工作' → 列表只剩带 工作 的条目
// 4. tap '全部' → 恢复全部条目
// 5. 条目无任何标签 → 不渲染筛选 row
// 6. 筛选后列表为空 (stream re-emit 移除带标签条目) → ventTagFilterEmpty 空态
//
// 全内存 fake repo (broadcast stream 支持 re-emit) + SharedPreferences mock
// (swipe hint key 置已看过, 避免 snackbar 噪音)。

import 'dart:async';

import 'package:chroniccare/domain/entities/vent_entry_entity.dart';
import 'package:chroniccare/domain/repositories/vent_repository.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/vent/vent_list_page.dart';
import 'package:chroniccare/presentation/providers/vent_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeVentRepository implements VentRepository {
  final List<VentEntryEntity> _entries;
  late final StreamController<List<VentEntryEntity>> _controller;

  _FakeVentRepository(this._entries) {
    _controller = StreamController<List<VentEntryEntity>>.broadcast(
      onListen: () => _controller.add(List.unmodifiable(_entries)),
    );
  }

  void emit(List<VentEntryEntity> entries) {
    _entries
      ..clear()
      ..addAll(entries);
    _controller.add(List.unmodifiable(_entries));
  }

  @override
  Stream<List<VentEntryEntity>> watchAll() => _controller.stream;

  @override
  Future<VentEntryEntity?> getById(int id) async =>
      _entries.where((e) => e.id == id).cast<VentEntryEntity?>().firstOrNull;

  @override
  Future<int> add({
    String? text,
    String? audioPath,
    int? audioDurationSec,
    int? audioSizeBytes,
    DateTime? at,
    String? tagsJson,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> delete(int id) async => true;

  @override
  Future<int> restore(VentEntryEntity entry) async => 1;

  @override
  Future<int> deleteAll() async => 0;
}

VentEntryEntity _entry({
  required int id,
  required String text,
  String tagsJson = '[]',
}) {
  return VentEntryEntity(
    id: id,
    timestamp: DateTime(2026, 7, 15, 10 + id, 30),
    contentText: text,
    tagsJson: tagsJson,
  );
}

List<VentEntryEntity> _taggedEntries() => [
      _entry(id: 1, text: '今天很累', tagsJson: '["家庭"]'),
      _entry(id: 2, text: '又被老板骂了', tagsJson: '["家庭","工作"]'),
      _entry(id: 3, text: '论文写不完', tagsJson: '["工作"]'),
    ];

void _setBigView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Widget _wrap(_FakeVentRepository repo) {
  return ProviderScope(
    overrides: [
      ventRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp.router(
      theme: ThemeData.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      routerConfig: GoRouter(
        initialLocation: '/vent',
        routes: [
          GoRoute(
            path: '/vent',
            builder: (_, __) => const VentListPage(),
          ),
          GoRoute(
            path: '/vent/compose',
            builder: (_, __) => const Scaffold(body: Text('COMPOSE')),
          ),
          GoRoute(
            path: '/vent/detail/:id',
            builder: (_, state) => Scaffold(
              body: Text('DETAIL ${state.pathParameters['id']}'),
            ),
          ),
        ],
      ),
    ),
  );
}

void main() {
  setUp(() {
    // swipe hint 已看过 → 不弹 snackbar (避免遮挡 + pumpAndSettle 噪音)
    SharedPreferences.setMockInitialValues({
      'vent_swipe_hint_shown_v1': true,
    });
  });

  testWidgets('1) 初始: 3 条全部显示 + 筛选 chips (全部/家庭/工作)', (tester) async {
    _setBigView(tester);
    await tester.pumpWidget(_wrap(_FakeVentRepository(_taggedEntries())));
    await tester.pumpAndSettle();

    expect(find.text('今天很累'), findsOneWidget);
    expect(find.text('又被老板骂了'), findsOneWidget);
    expect(find.text('论文写不完'), findsOneWidget);

    // 筛选 row: 全部 + 家庭 + 工作 (全部默认选中)
    final allChip = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, '全部'),
    );
    expect(allChip.selected, isTrue);
    expect(find.widgetWithText(FilterChip, '家庭'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, '工作'), findsOneWidget);
  });

  testWidgets("2) tap '家庭' → 只剩 2 条带家庭的条目", (tester) async {
    _setBigView(tester);
    await tester.pumpWidget(_wrap(_FakeVentRepository(_taggedEntries())));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, '家庭'));
    await tester.pumpAndSettle();

    expect(find.text('今天很累'), findsOneWidget);
    expect(find.text('又被老板骂了'), findsOneWidget);
    expect(find.text('论文写不完'), findsNothing);
  });

  testWidgets("3) tap '工作' → 只剩 2 条带工作的条目", (tester) async {
    _setBigView(tester);
    await tester.pumpWidget(_wrap(_FakeVentRepository(_taggedEntries())));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, '工作'));
    await tester.pumpAndSettle();

    expect(find.text('又被老板骂了'), findsOneWidget);
    expect(find.text('论文写不完'), findsOneWidget);
    expect(find.text('今天很累'), findsNothing);
  });

  testWidgets("4) tap '全部' → 恢复 3 条", (tester) async {
    _setBigView(tester);
    await tester.pumpWidget(_wrap(_FakeVentRepository(_taggedEntries())));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, '家庭'));
    await tester.pumpAndSettle();
    expect(find.text('论文写不完'), findsNothing);

    await tester.tap(find.widgetWithText(FilterChip, '全部'));
    await tester.pumpAndSettle();

    expect(find.text('今天很累'), findsOneWidget);
    expect(find.text('又被老板骂了'), findsOneWidget);
    expect(find.text('论文写不完'), findsOneWidget);
  });

  testWidgets('5) 条目无任何标签 → 不渲染筛选 row', (tester) async {
    _setBigView(tester);
    await tester.pumpWidget(
      _wrap(
        _FakeVentRepository([
          _entry(id: 1, text: '没有标签的一条'),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('没有标签的一条'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, '全部'), findsNothing);
  });

  testWidgets('6) 筛选后 stream re-emit 变空 → ventTagFilterEmpty 空态', (tester) async {
    _setBigView(tester);
    final repo = _FakeVentRepository(_taggedEntries());
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, '家庭'));
    await tester.pumpAndSettle();
    expect(find.text('今天很累'), findsOneWidget);

    // 带 家庭 的条目全部消失 → 筛选结果为空
    repo.emit([_entry(id: 3, text: '论文写不完', tagsJson: '["工作"]')]);
    await tester.pumpAndSettle();

    expect(find.text('论文写不完'), findsNothing);
    expect(find.text('没有带这个标签的树洞'), findsOneWidget);
  });
}
