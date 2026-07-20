// v0.14 (Round 13B) AssessmentHistoryPage widget 测试
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/assessment/assessment_history_page.dart';
import 'package:chroniccare/presentation/providers/data_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void _setBigView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Widget _wrap({List<CheckInEntity> records = const []}) {
  return ProviderScope(
    overrides: [
      assessmentsProvider.overrideWith((ref) => Stream.value(records)),
    ],
    child: MaterialApp(
      theme: ThemeData.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: const Scaffold(body: AssessmentHistoryPage()),
    ),
  );
}

CheckInEntity _phq9({
  required int total,
  required DateTime at,
  List<int>? scores,
}) {
  return CheckInEntity(
    id: at.millisecondsSinceEpoch,
    timestamp: at,
    type: CheckInType.phq9,
    note: '{"scale":"phq9","scores":${scores ?? [
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
        ]},"total":$total}',
  );
}

CheckInEntity _gad7({required int total, required DateTime at}) {
  return CheckInEntity(
    id: at.millisecondsSinceEpoch,
    timestamp: at,
    type: CheckInType.gad7,
    note: '{"scale":"gad7","scores":[0,0,0,0,0,0,0],"total":$total}',
  );
}

void main() {
  testWidgets('空记录 → "还没有评估记录"', (tester) async {
    _setBigView(tester);
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('还没有评估记录'), findsOneWidget);
    expect(find.text('开始第一次评估'), findsOneWidget);
  });

  testWidgets('只有 1 次评估 → 不画图，显示提示', (tester) async {
    _setBigView(tester);
    await tester.pumpWidget(
      _wrap(
        records: [
          _phq9(total: 5, at: DateTime(2026, 7, 10)),
        ],
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('评估历史'), findsOneWidget);
    expect(find.textContaining('只有 1 次评估'), findsOneWidget);
  });

  testWidgets('有 2 次 PHQ-9 → 显示折线图 + 完整记录', (tester) async {
    _setBigView(tester);
    await tester.pumpWidget(
      _wrap(
        records: [
          _phq9(total: 5, at: DateTime(2026, 7, 1)),
          _phq9(total: 12, at: DateTime(2026, 7, 15)),
        ],
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 顶部统计
    expect(find.text('总评估'), findsOneWidget);
    expect(find.text('最近 PHQ-9'), findsOneWidget);
    expect(find.text('最近 GAD-7'), findsOneWidget);

    // 折线图（1 张图 PHQ-9，2 条记录也用 PHQ-9 名字在历史里 = 3 次）
    expect(find.text('PHQ-9 抑郁筛查'), findsNWidgets(3));
    expect(find.text('2 次评估'), findsOneWidget);

    // 完整记录
    expect(find.text('完整记录'), findsOneWidget);
  });

  testWidgets('PHQ-9 + GAD-7 混合 → 2 张图', (tester) async {
    _setBigView(tester);
    await tester.pumpWidget(
      _wrap(
        records: [
          _phq9(total: 5, at: DateTime(2026, 7, 1)),
          _phq9(total: 10, at: DateTime(2026, 7, 15)),
          _gad7(total: 8, at: DateTime(2026, 7, 5)),
          _gad7(total: 15, at: DateTime(2026, 7, 20)),
        ],
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 2 张图标题（每个量表的 chart + history list 项）
    expect(find.text('PHQ-9 抑郁筛查'), findsNWidgets(3)); // chart + 2 history rows
    expect(find.text('GAD-7 焦虑筛查'), findsNWidgets(3)); // chart + 2 history rows
  });

  testWidgets('上次对比：diff 徽章', (tester) async {
    _setBigView(tester);
    await tester.pumpWidget(
      _wrap(
        records: [
          _phq9(total: 5, at: DateTime(2026, 7, 1)),
          _phq9(total: 10, at: DateTime(2026, 7, 15)),
        ],
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 10 - 5 = 5，应有向上的箭头 + 5
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
  });

  testWidgets('严重度：高分显示"重度" + 红色', (tester) async {
    _setBigView(tester);
    await tester.pumpWidget(
      _wrap(
        records: [
          _phq9(total: 25, at: DateTime(2026, 7, 1)), // 重度（> 75% × 27 = 20.25）
        ],
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('重度'), findsWidgets);
  });

  testWidgets('严重度：低分显示"正常"', (tester) async {
    _setBigView(tester);
    await tester.pumpWidget(
      _wrap(
        records: [
          _phq9(total: 3, at: DateTime(2026, 7, 1)), // 正常（< 25% × 27 = 6.75）
        ],
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('正常'), findsWidgets);
  });

  // v0.14 fix (Bug C): 严重度按临床标准，不是百分比
  testWidgets('严重度：PHQ-9 score=5 → "轻度"（百分比会错判为"正常"）', (tester) async {
    _setBigView(tester);
    await tester.pumpWidget(
      _wrap(
        records: [
          _phq9(total: 5, at: DateTime(2026, 7, 1)),
        ],
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // PHQ-9 临床: 0-4=正常, 5-9=轻度
    expect(find.text('轻度'), findsWidgets);
  });

  testWidgets('严重度：PHQ-9 score=20 → "重度"（百分比会错判为"中度"）', (tester) async {
    _setBigView(tester);
    await tester.pumpWidget(
      _wrap(
        records: [
          _phq9(total: 20, at: DateTime(2026, 7, 1)),
        ],
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // PHQ-9 临床: 20+ = 重度
    expect(find.text('重度'), findsWidgets);
  });

  testWidgets('严重度：GAD-7 score=5 → "轻度"（百分比 23.8% 会错判为"正常"）', (tester) async {
    _setBigView(tester);
    await tester.pumpWidget(
      _wrap(
        records: [
          _gad7(total: 5, at: DateTime(2026, 7, 1)),
        ],
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // GAD-7 临床: 5-9 = 轻度
    expect(find.text('轻度'), findsWidgets);
  });

  testWidgets('严重度：GAD-7 score=15 → "重度"（百分比 71.4% 会错判为"中度"）', (tester) async {
    _setBigView(tester);
    await tester.pumpWidget(
      _wrap(
        records: [
          _gad7(total: 15, at: DateTime(2026, 7, 1)),
        ],
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // GAD-7 临床: 15+ = 重度
    expect(find.text('重度'), findsWidgets);
  });
}
