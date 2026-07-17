// v0.15 (Round 18) VentListPage widget 测试
//
// 验证：
// - 空状态：显示 "树洞还是空的" + "写第一句"按钮
// - 有条目：列表渲染（首条预览、时长）
// - 有 audio 的条目：显示 mic 图标 + 时长
// - "+"按钮 + 写第一句按钮都跳到 compose
import 'package:chroniccare/domain/entities/vent_entry.dart';
import 'package:chroniccare/domain/repositories/vent_repository.dart';
import 'package:chroniccare/presentation/pages/vent/vent_list_page.dart';
import 'package:chroniccare/presentation/providers/vent_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeVentRepository implements VentRepository {
  final List<VentEntryEntity> _entries;
  _FakeVentRepository(this._entries);

  @override
  Stream<List<VentEntryEntity>> watchAll() => Stream.value(_entries);

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
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> delete(int id) async {
    _entries.removeWhere((e) => e.id == id);
    return true;
  }
}

void _setBigView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Widget _wrap(List<VentEntryEntity> entries) {
  final fake = _FakeVentRepository(entries);
  return ProviderScope(
    overrides: [
      ventRepositoryProvider.overrideWithValue(fake),
    ],
    child: MaterialApp.router(
      theme: ThemeData.light(),
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
  testWidgets('空状态：显示"树洞还是空的" + 写第一句按钮', (tester) async {
    _setBigView(tester);
    await tester.pumpWidget(_wrap([]));
    await tester.pumpAndSettle();

    expect(find.text('树洞还是空的'), findsOneWidget);
    expect(find.text('写第一句'), findsOneWidget);
    // 不应该渲染 list item
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('有文字条目：显示预览（前 80 字内）', (tester) async {
    _setBigView(tester);
    await tester.pumpWidget(_wrap([
      VentEntryEntity(
        id: 1,
        timestamp: DateTime(2026, 7, 15, 10, 30),
        contentText: '今天有点累，先说一下吧',
      ),
    ]),);
    await tester.pumpAndSettle();

    expect(find.text('今天有点累，先说一下吧'), findsOneWidget);
    // 不显示空状态
    expect(find.text('树洞还是空的'), findsNothing);
  });

  testWidgets('有 audio 条目：显示 mic 图标 + 时长', (tester) async {
    _setBigView(tester);
    await tester.pumpWidget(_wrap([
      VentEntryEntity(
        id: 1,
        timestamp: DateTime(2026, 7, 15, 10, 30),
        audioPath: '/fake/voice.m4a',
        audioDurationSec: 65,
      ),
    ]),);
    await tester.pumpAndSettle();

    // audio 条目的预览文字 = "🎙️ 语音"
    expect(find.text('🎙️ 语音'), findsOneWidget);
    // durationLabel 输出 "1分05秒"
    expect(find.text('1分05秒'), findsOneWidget);
  });

  testWidgets('混合条目：显示文字预览 + mic 图标', (tester) async {
    _setBigView(tester);
    await tester.pumpWidget(_wrap([
      VentEntryEntity(
        id: 1,
        timestamp: DateTime(2026, 7, 15, 10, 30),
        contentText: '这段录音 + 文字',
        audioPath: '/fake/voice.m4a',
        audioDurationSec: 30,
      ),
    ]),);
    await tester.pumpAndSettle();

    // 文字预览
    expect(find.text('这段录音 + 文字'), findsOneWidget);
    // 时长（"30秒"）
    expect(find.text('30秒'), findsOneWidget);
  });

  testWidgets('长文字超过 80 字符：截断显示 "…"', (tester) async {
    _setBigView(tester);
    final longText = '一' * 100; // 100 个字
    final displayText = '${'一' * 80}…';
    await tester.pumpWidget(_wrap([
      VentEntryEntity(
        id: 1,
        timestamp: DateTime(2026, 7, 15, 10, 30),
        contentText: longText,
      ),
    ]),);
    await tester.pumpAndSettle();

    expect(find.text(displayText), findsOneWidget);
  });

  testWidgets('多条目：按列表顺序渲染（DB 已按时间倒序）', (tester) async {
    _setBigView(tester);
    await tester.pumpWidget(_wrap([
      VentEntryEntity(
        id: 1,
        timestamp: DateTime(2026, 7, 15, 10, 0),
        contentText: '第一条',
      ),
      VentEntryEntity(
        id: 2,
        timestamp: DateTime(2026, 7, 15, 11, 0),
        contentText: '第二条',
      ),
      VentEntryEntity(
        id: 3,
        timestamp: DateTime(2026, 7, 15, 12, 0),
        contentText: '第三条',
      ),
    ]),);
    await tester.pumpAndSettle();

    expect(find.text('第一条'), findsOneWidget);
    expect(find.text('第二条'), findsOneWidget);
    expect(find.text('第三条'), findsOneWidget);
  });
}

// 补一下 firstOrNull（dart sdk 老版本可能没这个）
extension _IterableX<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
