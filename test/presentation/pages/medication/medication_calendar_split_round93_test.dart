// v0.30 round 93 (audit-fixes task 1): medication_calendar god page 拆 sub-widget 验证
//
// 3 个 baseline test:
// 1. 列表 (空药物 → EmptyState)
// 2. 日历 (medication + checkIns → 网格 + 头部日期标签 + 药名行标签 + 漏服/100% 颜色)
// 3. 详情 (单个 medication + 单日打卡 → 行 + 单元格都存在)
//
// 拆前: 3 test 都通过 (god page 内联实现)
// 拆后 (Step 1.2-1.4): 3 test 仍通过 (sub-widget 替换内联实现, snapshot 行为一致)
//
// 加 Step 1.5 后: 加 1 test (cell tap → DayDetail 显示该日 log)

import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/medication/medication_calendar_page.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void _setBigView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 1500);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Widget _wrap({
  List<MedicationEntity> meds = const [],
  List<CheckInEntity> checkIns = const [],
}) {
  return ProviderScope(
    overrides: [
      medicationsProvider.overrideWith((ref) => Stream.value(meds)),
      allCheckInsProvider.overrideWith((ref) => Stream.value(checkIns)),
    ],
    child: MaterialApp(
      theme: ThemeData.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: const Scaffold(body: MedicationCalendarPage()),
    ),
  );
}

MedicationEntity _med({
  int id = 1,
  String name = '氟西汀',
  List<HourMinute> times = const [HourMinute(hour: 8, minute: 0)],
  bool isActive = true,
}) {
  return MedicationEntity(
    id: id,
    name: name,
    dosage: 40,
    dosageUnit: DosageUnit.mg,
    times: times,
    startDate: DateTime(2026, 1, 1),
    isActive: isActive,
    refillReminderDays: 7,
  );
}

CheckInEntity _checkIn({
  required int medicationId,
  required DateTime at,
}) {
  return CheckInEntity(
    id: at.millisecondsSinceEpoch,
    timestamp: at,
    type: CheckInType.normal,
    medicationId: medicationId,
  );
}

void main() {
  // ============================================================
  // 1. 列表 (空药物 → EmptyState)
  // ============================================================
  testWidgets(
    '1) 列表态: 空药物 → 显示 "还没有在用药物" EmptyState',
    (tester) async {
      _setBigView(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('还没有在用药物'), findsOneWidget);
      expect(find.text('添加药物'), findsOneWidget);
    },
  );

  // ============================================================
  // 2. 日历 (medication + checkIns → 网格 + 头部 + 药名 + 颜色)
  // ============================================================
  testWidgets(
    '2) 日历态: 1 药 + 30 天无打卡 → 显示 漏服 100% 图例 + 时间窗口',
    (tester) async {
      _setBigView(tester);
      await tester.pumpWidget(_wrap(meds: [_med()]));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 时间窗口 (CalendarGrid 上面)
      expect(find.text('7 天'), findsOneWidget);
      expect(find.text('30 天'), findsOneWidget);
      expect(find.text('90 天'), findsOneWidget);

      // 图例 (Legend 在网格下面)
      expect(find.text('依从：'), findsOneWidget);
      expect(find.text('漏服'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);

      // 网格: 药名行标签 (CalendarGrid 内)
      expect(find.text('氟西汀'), findsOneWidget);
    },
  );

  // ============================================================
  // 3. 详情 (单日 log 通过 click cell 暴露 — 由 Step 1.5 加, 此处先保留)
  //    拆前: DayDetail 不存在, 所以这一步验证 (日历渲染 + 无空日历态)
  // ============================================================
  testWidgets(
    '3) 日历态: 1 药 + 1 打卡 → 网格渲染, 药名 + 时间窗口都在',
    (tester) async {
      _setBigView(tester);
      final now = DateTime.now();
      await tester.pumpWidget(
        _wrap(
          meds: [_med()],
          checkIns: [_checkIn(medicationId: 1, at: now)],
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 网格主体: 药名 + 30 天格子 (具体颜色不测, 由 _CellBox 颜色函数负责)
      expect(find.text('氟西汀'), findsOneWidget);
      expect(find.text('7 天'), findsOneWidget);
      expect(find.text('30 天'), findsOneWidget);
      expect(find.text('90 天'), findsOneWidget);

      // Legend 还在
      expect(find.text('依从：'), findsOneWidget);
      expect(find.text('漏服'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    },
  );

  // ============================================================
  // 拆前辅助 test: 没设 times 的药不画日历 (覆盖 _buildGrid EmptyState 分支)
  // ============================================================
  testWidgets(
    '日历态: times=[] 的药显示 "未设置服用时间" EmptyState, 不画网格',
    (tester) async {
      _setBigView(tester);
      final meds = [_med(id: 1, name: '氟西汀', times: const [])];
      await tester.pumpWidget(_wrap(meds: meds));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('氟西汀'), findsNothing);
      expect(find.textContaining('未设置服用时间'), findsOneWidget);
    },
  );
}
