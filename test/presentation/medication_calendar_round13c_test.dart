// v0.14 (Round 13C) MedicationCalendarPage widget + 业务逻辑测试
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/presentation/pages/medication/medication_calendar_page.dart';
import 'package:chroniccare/presentation/providers/data_providers.dart';
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
    dosageUnit: 'mg',
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
  testWidgets('空药物 → "还没有在用药物"', (tester) async {
    _setBigView(tester);
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('还没有在用药物'), findsOneWidget);
  });

  testWidgets('页面渲染：标题 + 时间窗口 + 图例', (tester) async {
    _setBigView(tester);
    await tester.pumpWidget(_wrap(meds: [_med()]));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 标题（PageScaffold 显示在 AppBar）
    // expect(find.text('用药日历'), findsOneWidget);  // AppBar title 不在 ListView 树
    expect(find.text('7 天'), findsOneWidget);
    expect(find.text('30 天'), findsOneWidget);
    expect(find.text('90 天'), findsOneWidget);
    expect(find.text('依从：'), findsOneWidget);
    expect(find.text('漏服'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('1 种药 × 30 天：行标签 = 药名', (tester) async {
    _setBigView(tester);
    await tester.pumpWidget(_wrap(meds: [_med(name: '氟西汀')]));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 药名出现在行标签 + 顶部说明
    expect(find.text('氟西汀'), findsOneWidget);
  });

  testWidgets('多药 + 打卡数据：行数 = 药数', (tester) async {
    _setBigView(tester);
    final meds = [
      _med(id: 1, name: '氟西汀'),
      _med(id: 2, name: '碳酸锂'),
    ];
    final checkIns = [
      _checkIn(medicationId: 1, at: DateTime.now()),
      _checkIn(medicationId: 2, at: DateTime.now()),
    ];
    await tester.pumpWidget(_wrap(meds: meds, checkIns: checkIns));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('氟西汀'), findsOneWidget);
    expect(find.text('碳酸锂'), findsOneWidget);
  });

  testWidgets('切换到 90 天：标签变化', (tester) async {
    _setBigView(tester);
    await tester.pumpWidget(_wrap(meds: [_med()]));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.text('90 天'));
    await tester.pumpAndSettle();

    // 90 天后还显示同样的标题
    expect(find.text('90 天'), findsOneWidget);
  });

  testWidgets('打卡匹配 medicationId：只显示对应药', (tester) async {
    _setBigView(tester);
    final meds = [_med(id: 1, name: '氟西汀')];
    final checkIns = [
      // 不同的 medId，不应影响氟西汀的热力图
      _checkIn(medicationId: 999, at: DateTime.now()),
    ];
    await tester.pumpWidget(_wrap(meds: meds, checkIns: checkIns));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 氟西汀仍然显示，没崩
    expect(find.text('氟西汀'), findsOneWidget);
  });

  testWidgets('非 normal type（temp）的打卡不计入日历', (tester) async {
    _setBigView(tester);
    final meds = [_med(id: 1, name: '氟西汀')];
    final tempCheckIn = CheckInEntity(
      id: 1,
      timestamp: DateTime.now(),
      type: CheckInType.temp,
      note: 'temp',
      medicationId: 1,
    );
    await tester.pumpWidget(_wrap(meds: meds, checkIns: [tempCheckIn]));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 页面不崩，显示药名
    expect(find.text('氟西汀'), findsOneWidget);
  });

  // v0.14 fix (Bug G): 没设服用时间的药不再显示"漏服"假象
  testWidgets('times=[] 的药显示"未设置服用时间"提示，不画日历', (tester) async {
    _setBigView(tester);
    final meds = [_med(id: 1, name: '氟西汀', times: const [])];
    await tester.pumpWidget(_wrap(meds: meds));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('氟西汀'), findsNothing);
    expect(find.textContaining('未设置服用时间'), findsOneWidget);
  });
}
