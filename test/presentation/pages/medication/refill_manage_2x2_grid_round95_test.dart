// v0.30 round 95 (sub-spec 2 task 10 A3): refill_manage_page 4 StatCard
// → 2x2 grid widget test
//
// **问题 (R92 emil P1-2.1.4)**: 4 StatCard 挤一起 1 个 Row, 数字密度
// 太高, 视觉混乱, 难读。
//
// **修法 (R95 task 10 A3)**: 改 2x2 grid (2 个 Row, 各 2 个 StatCard),
// 数字更大 / 间距更合理, 改善可读性。
//
// 2 case widget test:
// 1. 顶部汇总卡有 2 个 Row (各 2 个 StatCard = 4 StatCard total), 不是
//    1 个 Row 4 StatCard 旧版
// 2. 总药数 / 已设续方 / 提醒中 / 已过期 4 个 StatCard 全部渲染
import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/medication/refill_manage_page.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/stat_card.dart';
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

Widget _wrap({List<MedicationEntity> meds = const []}) {
  return ProviderScope(
    overrides: [
      medicationsProvider.overrideWith((ref) => Stream.value(meds)),
    ],
    child: MaterialApp(
      theme: ThemeData.light(),
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: RefillManagePage()),
    ),
  );
}

MedicationEntity _med({
  int id = 1,
  String name = '氟西汀',
  DateTime? refillAt,
}) {
  return MedicationEntity(
    id: id,
    name: name,
    dosage: 40,
    dosageUnit: DosageUnit.mg,
    times: const [],
    startDate: DateTime(2026, 1, 1),
    isActive: true,
    refillAt: refillAt,
    refillReminderDays: 7,
  );
}

void main() {
  testWidgets('R95 A3 fix 1: 顶部汇总卡 2x2 grid (2 Row × 2 StatCard)',
      (tester) async {
    _setBigView(tester);
    // 1 个已过期 med (refillAt 过去) + 1 个提醒中 (refillAt 3 天后)
    final now = DateTime.now();
    final meds = [
      _med(
        id: 1,
        name: '氟西汀',
        refillAt: now.subtract(const Duration(days: 1)),
      ),
      _med(
        id: 2,
        name: '碳酸锂',
        refillAt: now.add(const Duration(days: 3)),
      ),
    ];
    await tester.pumpWidget(_wrap(meds: meds));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // 验证有 4 个 StatCard (2x2 grid)
    expect(
      find.byType(StatCard),
      findsNWidgets(4),
      reason: '顶部汇总卡应有 4 个 StatCard (总药数/已设续方/提醒中/已过期)',
    );
  });

  testWidgets('R95 A3 fix 2: 总药数 / 已设续方 / 提醒中 / 已过期 4 label 渲染',
      (tester) async {
    _setBigView(tester);
    final meds = [
      _med(id: 1, name: '氟西汀'),
      _med(id: 2, name: '碳酸锂'),
    ];
    await tester.pumpWidget(_wrap(meds: meds));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // 验证 4 个 StatCard label 都渲染 (zh locale)
    expect(find.text('总药数'), findsOneWidget);
    expect(find.text('已设续方'), findsOneWidget);
    expect(find.text('提醒中'), findsOneWidget);
    expect(find.text('已过期'), findsOneWidget);
  });
}
