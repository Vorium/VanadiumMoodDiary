// v0.30 round 92 (audit-fixes / P0 #15): treatment_placeholder 真页面
//
// 覆盖 (TDD red→green):
// 1. TreatmentPage 渲染: ListView (有 entry) 或 EmptyState (无 entry)
// 2. 点添加按钮 → AddTreatmentDialog 弹出
// 3. 填 4 字段 (date / category / provider / note) → save →
//    treatmentEntriesProvider 加 1 条 + dialog pop
//
// 修前 (R91 Task 5 兜底): treatment_placeholder.dart 显示 R91 兜底
// "R91 兜底: 治疗 entry 显示 (写入功能 v0.31+ 跟 medication picker 整合)"
// 文案 + ListView Card 渲染, 但 0 写入入口 (AddTreatmentDialog 留 v0.31+)。
// 用户在 /treatment 只能看, 不能加。
//
// R92 修法:
// - 删 treatment_placeholder.dart, 新增 treatment_page.dart (含 list + FAB +
//   AddTreatmentDialog, 4 字段)
// - 复用 R91 treatmentEntriesProvider (StreamProvider.autoDispose) +
//   treatmentRepositoryProvider.add() API
// - 4 字段 schema 兼容 R91: date→timestamp (R91 default now),
//   category→treatmentType (4 选 1 free String), provider→description (String),
//   note→note (String)
// - 复用 PageScaffold + SectionHeader + AppListTile + EmptyState

import 'package:chroniccare/domain/entities/treatment_entry.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/treatment_page.dart';
import 'package:chroniccare/presentation/providers/daily_tracking_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  /// 800x2000 模拟手机视口, TreatmentPage + ListView + FAB 可见
  void setBigView(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  /// helper: pump page + override treatmentEntriesProvider
  Widget wrap({required List<TreatmentEntryEntity> entries}) {
    return ProviderScope(
      overrides: [
        treatmentEntriesProvider.overrideWith((ref) => Stream.value(entries)),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        routerConfig: GoRouter(
          initialLocation: '/treatment',
          routes: [
            GoRoute(
              path: '/treatment',
              builder: (context, state) => const TreatmentPage(),
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('TreatmentPage 渲染: 无 entry → EmptyState (R91 hint)',
      (tester) async {
    setBigView(tester);
    await tester.pumpWidget(wrap(entries: const []));
    await tester.pumpAndSettle();

    // EmptyState 显示 (R91 existing treatmentNoData / treatmentHint)
    expect(
      find.text('暂无治疗记录'),
      findsOneWidget,
      reason: 'R91 treatmentNoData 文案应可见',
    );
    expect(
      find.textContaining('治疗条目'),
      findsOneWidget,
      reason: 'R91 treatmentHint 副文案应可见',
    );
  });

  testWidgets('TreatmentPage 渲染: 有 entry → ListView 显示', (tester) async {
    setBigView(tester);
    final entry = TreatmentEntryEntity(
      id: 1,
      timestamp: DateTime(2026, 8, 1),
      treatmentType: 'consultation',
      description: '心理医生 (王医生)',
      note: '聊得不错',
    );
    await tester.pumpWidget(wrap(entries: [entry]));
    await tester.pumpAndSettle();

    // 列表有 1 条 entry (R92 format: "category · description" + subtitle)
    expect(
      find.textContaining('心理咨询'),
      findsOneWidget,
      reason: 'entry category (treatmentType) 透传显示',
    );
    expect(
      find.textContaining('心理医生 (王医生)'),
      findsOneWidget,
      reason: 'entry description (provider) 透传显示',
    );
    expect(
      find.textContaining('聊得不错'),
      findsOneWidget,
      reason: 'entry note 透传显示',
    );
  });

  testWidgets('TreatmentPage 顶部添加按钮 + AddTreatmentDialog 弹出', (tester) async {
    setBigView(tester);
    await tester.pumpWidget(wrap(entries: const []));
    await tester.pumpAndSettle();

    // 点 "添加" 按钮
    await tester.tap(find.text('添加'));
    await tester.pumpAndSettle();

    // AddTreatmentDialog 弹出 (4 字段 visible)
    expect(
      find.text('添加治疗记录'),
      findsOneWidget,
      reason: 'AddTreatmentDialog title 可见',
    );
    expect(
      find.text('日期'),
      findsOneWidget,
      reason: 'date field 可见',
    );
    expect(
      find.text('类别'),
      findsOneWidget,
      reason: 'category field 可见',
    );
    expect(
      find.text('医疗机构 / 医生'),
      findsOneWidget,
      reason: 'provider field 可见',
    );
    expect(
      find.text('备注'),
      findsOneWidget,
      reason: 'note field 可见',
    );
  });
}
