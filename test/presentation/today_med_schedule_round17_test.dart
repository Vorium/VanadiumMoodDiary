// v0.14 (Round 17) TodayMedSchedule widget 测试
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/presentation/pages/home/widgets/today_med_schedule.dart';
import 'package:chroniccare/presentation/providers/data_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

MedicationEntity _med({
  int id = 1,
  String name = '氟西汀',
  List<TimeOfDay> times = const [TimeOfDay(hour: 8, minute: 0)],
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
  required int? medicationId,
  DateTime? at,
}) {
  return CheckInEntity(
    id: (at ?? DateTime.now()).millisecondsSinceEpoch,
    timestamp: at ?? DateTime.now(),
    type: CheckInType.normal,
    medicationId: medicationId,
  );
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
      home: const Scaffold(body: TodayMedSchedule()),
    ),
  );
}

void _setBigView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1500);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  testWidgets('空 meds → 不显示', (tester) async {
    _setBigView(tester);
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.text('今日服药计划'), findsNothing);
  });

  testWidgets('只有 1 种药 × 1 个时间点 → 显示 0/1', (tester) async {
    _setBigView(tester);
    final meds = [_med(name: '氟西汀', times: const [TimeOfDay(hour: 8, minute: 0)])];
    await tester.pumpWidget(_wrap(meds: meds));
    await tester.pumpAndSettle();

    expect(find.text('今日服药计划'), findsOneWidget);
    expect(find.text('0 / 1'), findsOneWidget);
    expect(find.text('氟西汀'), findsOneWidget);
    expect(find.text('08:00'), findsOneWidget);
  });

  testWidgets('已打卡 → 显示 1/1 + 勾', (tester) async {
    _setBigView(tester);
    final meds = [_med(id: 1, name: '氟西汀')];
    final checkIns = [_checkIn(medicationId: 1)];
    await tester.pumpWidget(_wrap(meds: meds, checkIns: checkIns));
    await tester.pumpAndSettle();

    expect(find.text('1 / 1'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('多药多时间点 → 按时间排序', (tester) async {
    _setBigView(tester);
    final meds = [
      _med(id: 1, name: '氟西汀', times: const [TimeOfDay(hour: 20, minute: 0)]),
      _med(id: 2, name: '碳酸锂', times: const [TimeOfDay(hour: 8, minute: 0)]),
    ];
    await tester.pumpWidget(_wrap(meds: meds));
    await tester.pumpAndSettle();

    // 没打卡 → 0 / 2
    expect(find.text('0 / 2'), findsOneWidget);
    // 应按时间顺序：08:00 碳酸锂 在前
    final textWidgets = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList();
    final liIdx = textWidgets.indexOf('08:00');
    final fluIdx = textWidgets.indexOf('20:00');
    expect(liIdx, isNonNegative);
    expect(fluIdx, isNonNegative);
    expect(liIdx, lessThan(fluIdx), reason: '08:00 应该在 20:00 之前');
  });

  testWidgets('停药 / 无时间的药不显示', (tester) async {
    _setBigView(tester);
    final meds = [
      _med(id: 1, name: '已停', isActive: false),
      _med(id: 2, name: '无时间', times: const []),
    ];
    await tester.pumpWidget(_wrap(meds: meds));
    await tester.pumpAndSettle();

    expect(find.text('今日服药计划'), findsNothing);
  });

  testWidgets('昨天的打卡不算', (tester) async {
    _setBigView(tester);
    final meds = [_med(id: 1, name: '氟西汀')];
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final checkIns = [_checkIn(medicationId: 1, at: yesterday)];
    await tester.pumpWidget(_wrap(meds: meds, checkIns: checkIns));
    await tester.pumpAndSettle();

    expect(find.text('0 / 1'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });
}
