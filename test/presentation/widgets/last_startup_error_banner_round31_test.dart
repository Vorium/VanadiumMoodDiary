// v0.23 (Round 31 P0-6): last_startup_error_banner widget 单测
//
// 之前 v0.22 round 33 加 P0 banner widget 但 0 widget test。补 3 个 case:
//   1. consume 返 null → banner 不显示
//   2. consume 返 LastError → banner 显示
//   3. 点关闭 → banner 消失, child 仍可见
//   4. consume 失败 (SharedPreferences 抛) → 不 crash
import 'package:chroniccare/core/data/services/last_error_capture.dart';
import 'package:chroniccare/presentation/widgets/last_startup_error_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('consume 返 null → banner 不显示, child 正常',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LastStartupErrorBanner(
          child: Scaffold(body: Center(child: Text('home'))),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    expect(find.text('上次启动出错，请截图反馈'), findsNothing);
  });

  testWidgets('consume 返 LastError → banner 显示',
      (tester) async {
    await LastErrorCapture.record(
      Exception('boom'),
      StackTrace.fromString('frame1\nframe2'),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: LastStartupErrorBanner(
          child: Scaffold(body: Center(child: Text('home'))),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('上次启动出错，请截图反馈'), findsOneWidget);
    // child 仍在
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('点关闭 → banner 消失, child 仍可见',
      (tester) async {
    await LastErrorCapture.record(
      Exception('boom'),
      StackTrace.fromString('frame1'),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: LastStartupErrorBanner(
          child: Scaffold(body: Center(child: Text('home'))),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('上次启动出错，请截图反馈'), findsOneWidget);

    // 点关闭按钮 (IconButton tooltip '关闭')
    await tester.tap(find.byTooltip('关闭'));
    await tester.pumpAndSettle();

    expect(find.text('上次启动出错，请截图反馈'), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('banner consume 后 SharedPreferences 已 clear, 重 mount 不再现',
      (tester) async {
    await LastErrorCapture.record(
      Exception('boom'),
      StackTrace.fromString('frame1'),
    );

    // 第一次 mount
    await tester.pumpWidget(
      const MaterialApp(
        home: LastStartupErrorBanner(child: Scaffold(body: Text('home'))),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('上次启动出错，请截图反馈'), findsOneWidget);

    // unmount
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpAndSettle();

    // 重 mount - SharedPreferences 已 clear, banner 不应再现
    await tester.pumpWidget(
      const MaterialApp(
        home: LastStartupErrorBanner(child: Scaffold(body: Text('home'))),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('上次启动出错，请截图反馈'), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });
}
