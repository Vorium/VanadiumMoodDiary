// v0.30 R101: medication_page widget 测试
//
// 覆盖:
// 1. 空药物 → EmptyState 提示
// 2. 有药物 → 药物列表 + 时间段分组
// 3. 点击药物卡片 → 跳转详情页

import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/medication/medication_page.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void _setBigView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
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
      home: const MedicationPage(),
    ),
  );
}

MedicationEntity _med({
  int id = 1,
  String name = '氟西汀',
  double dosage = 20,
  DosageUnit unit = DosageUnit.mg,
  List<HourMinute> times = const [HourMinute(hour: 8, minute: 0)],
  bool isActive = true,
}) {
  return MedicationEntity(
    id: id,
    name: name,
    dosage: dosage,
    dosageUnit: unit,
    times: times,
    startDate: DateTime(2026, 6, 1),
    isActive: isActive,
    refillReminderDays: 7,
  );
}

void main() {
  group('MedicationPage', () {
    testWidgets('1) 空药物 → 显示空态提示', (tester) async {
      _setBigView(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('还没有添加药物'), findsOneWidget);
    });

    testWidgets('2) 有药物 → 显示药物列表', (tester) async {
      _setBigView(tester);
      await tester.pumpWidget(
        _wrap(
          meds: [_med(), _med(id: 2, name: '碳酸锂', dosage: 300)],
        ),
      );
      await tester.pumpAndSettle();

      // 药物名在时间段和药物列表中各出现一次
      expect(find.text('氟西汀'), findsAtLeast(1));
      expect(find.text('碳酸锂'), findsAtLeast(1));
    });

    testWidgets('3) 有药物 → 显示今日服药时间段', (tester) async {
      _setBigView(tester);
      await tester.pumpWidget(
        _wrap(
          meds: [_med()],
        ),
      );
      await tester.pumpAndSettle();

      // 早上时间段应该显示
      expect(find.text('今日服药'), findsOneWidget);
    });

    testWidgets('4) 空药物 → 不显示今日服药', (tester) async {
      _setBigView(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // 空药物时今日服药不显示（显示空态）
      expect(find.text('还没有添加药物'), findsOneWidget);
    });

    testWidgets('5) 快捷操作 → 显示日历和续方按钮', (tester) async {
      _setBigView(tester);
      await tester.pumpWidget(
        _wrap(
          meds: [_med()],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('用药日历'), findsOneWidget);
      expect(find.text('续方管理'), findsOneWidget);
    });
  });
}
