// v0.16 round 20 测试
//
// 覆盖 3 件事：
// 1. NotificationStatusCard 在 mobile 平台显示完整 Card
// 2. 三个主按钮存在（测试通知 / 查看已排队 / 国产手机引导）
// 3. pendingCount 三种状态（正常 / 0 / -1）的 UI 显示
import 'package:chroniccare/core/data/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/presentation/pages/settings/widgets/notification_status_card.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';

class _StubNotificationService extends NotificationService {
  int pendingToReturn;
  bool showNowCalled;
  int? showNowId;
  String? showNowTitle;
  String? showNowBody;

  _StubNotificationService({
    this.pendingToReturn = 3,
  }) : showNowCalled = false;

  @override
  Future<void> init() async {}

  @override
  Future<int> get pendingCount async => pendingToReturn;

  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    showNowCalled = true;
    showNowId = id;
    showNowTitle = title;
    showNowBody = body;
  }

  @override
  Future<void> cancelAll() async {}
}

void _setBigView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Widget _wrap(_StubNotificationService service) {
  return ProviderScope(
    overrides: [
      notificationServiceProvider.overrideWithValue(service),
    ],
    child: MaterialApp(
      theme: ThemeData.light(),
      home: const Scaffold(body: NotificationStatusCard()),
    ),
  );
}

void main() {
  testWidgets('mobile 模式显示完整 card（3 个入口）', (tester) async {
    _setBigView(tester);
    final service = _StubNotificationService(pendingToReturn: 5);
    await tester.pumpWidget(_wrap(service));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // 标题
    expect(find.text('通知与提醒'), findsOneWidget);
    // 状态显示
    expect(find.textContaining('已排队 5 条'), findsOneWidget);
    // 三个主按钮
    expect(find.text('测试通知'), findsOneWidget);
    expect(find.text('查看已排队通知'), findsOneWidget);
    // OEM 引导折叠
    expect(find.text('国产手机没收到通知?'), findsOneWidget);
  });

  testWidgets('pendingCount == 0 时提示"提醒可能没设上"', (tester) async {
    _setBigView(tester);
    final service = _StubNotificationService(pendingToReturn: 0);
    await tester.pumpWidget(_wrap(service));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.textContaining('没有待发通知'), findsOneWidget);
    expect(find.textContaining('可能没设上'), findsOneWidget);
  });

  testWidgets('pendingCount == -1 时提示"当前平台不支持查询"', (tester) async {
    _setBigView(tester);
    final service = _StubNotificationService(pendingToReturn: -1);
    await tester.pumpWidget(_wrap(service));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.textContaining('当前平台不支持'), findsOneWidget);
  });

  testWidgets('点"测试通知"按钮 → 调 showNow 推一条', (tester) async {
    _setBigView(tester);
    final service = _StubNotificationService(pendingToReturn: 1);
    await tester.pumpWidget(_wrap(service));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // 点「测试通知」ListTile
    await tester.tap(find.text('测试通知'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(service.showNowCalled, isTrue);
    expect(service.showNowId, 99001); // 测试用 id,不会冲突
    expect(service.showNowTitle, contains('通知自检'));
  });

  testWidgets('点刷新按钮 → 重新读 pendingCount', (tester) async {
    _setBigView(tester);
    final service = _StubNotificationService(pendingToReturn: 2);
    await tester.pumpWidget(_wrap(service));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // 改成 7
    service.pendingToReturn = 7;
    // 找 refresh IconButton
    final refreshBtn = find.byIcon(Icons.refresh);
    expect(refreshBtn, findsOneWidget);
    await tester.tap(refreshBtn);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.textContaining('已排队 7 条'), findsOneWidget);
  });
}
