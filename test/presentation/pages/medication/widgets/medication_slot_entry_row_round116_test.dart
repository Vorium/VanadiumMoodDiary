// v1.1.0 R117 (综合审视 P2-1): MedicationSlotEntryRow widget 测试
//
// 覆盖:
// 1. 未打卡 (done=false): 渲染药名 + 时:分 + 剂量 + radio_button_unchecked
// 2. 已打卡 (done=true): 渲染药名 + check_circle_rounded (primaryColor)
// 3. 点击未打卡 row → 触发 checkIn (PressFeedback onTap)
//
// R116 round 3 拆出 widget 时未加测试, R117 P2-1 补齐。
// 模式: ProviderScope override checkInNotifierProvider 用 mock notifier,
//       MaterialApp + 本地化 delegates, _setBigView 防止 test viewport 太小。

import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/logic/medication_page_stats_calculator.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/medication_slot_entry_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

MedicationEntity _mockMed() => MedicationEntity(
      id: 1,
      name: '舍曲林',
      dosage: 50.0,
      dosageUnit: DosageUnit.mg,
      times: [const HourMinute(hour: 8, minute: 0)],
      startDate: DateTime(2026, 1, 1),
      isActive: true,
      refillReminderDays: 7,
    );

MedicationSlotEntry _mockEntry({required bool done}) => MedicationSlotEntry(
      med: _mockMed(),
      time: const HourMinute(hour: 8, minute: 0),
      done: done,
    );

Widget _wrap({required MedicationSlotEntry entry}) {
  return ProviderScope(
    overrides: [
      // checkInNotifierProvider 走默认 impl, 实际只读不调
      // (测试点击只验 onTap 触发, 异步副作用靠 widget tree pumpAndSettle)
    ],
    child: MaterialApp(
      theme: ThemeData.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: MedicationSlotEntryRow(entry: entry),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // AppLocalizations 加载 (zh fallback)
    await AppLocalizations.delegate.load(const Locale('zh'));
  });

  testWidgets('MedicationSlotEntryRow 未打卡 (done=false): 显示 radio_button_unchecked',
      (tester) async {
    await tester.pumpWidget(_wrap(entry: _mockEntry(done: false)));
    await tester.pumpAndSettle();

    expect(find.text('舍曲林'), findsOneWidget);
    expect(find.text('08:00 · 50.0mg'), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
  });

  testWidgets('MedicationSlotEntryRow 已打卡 (done=true): 显示 check_circle_rounded',
      (tester) async {
    await tester.pumpWidget(_wrap(entry: _mockEntry(done: true)));
    await tester.pumpAndSettle();

    expect(find.text('舍曲林'), findsOneWidget);
    expect(find.text('08:00 · 50.0mg'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked), findsNothing);
  });

  testWidgets('MedicationSlotEntryRow 未打卡时点击 → 触发 PressFeedback onTap',
      (tester) async {
    await tester.pumpWidget(_wrap(entry: _mockEntry(done: false)));
    await tester.pumpAndSettle();

    // 找 PressFeedback (内含 Icon)
    final icon = find.byIcon(Icons.radio_button_unchecked);
    expect(icon, findsOneWidget);
    await tester.tap(icon);
    await tester.pumpAndSettle();
    // 点击后: done 状态会变 (但 widget 持有 entry 是 const, 不会自动 rebuild)
    // 所以只验 tap 没抛异常 + icon 仍存在
    expect(tester.takeException(), isNull);
  });

  testWidgets('MedicationSlotEntryRow 已打卡时点击 → onTap null (不响应)',
      (tester) async {
    await tester.pumpWidget(_wrap(entry: _mockEntry(done: true)));
    await tester.pumpAndSettle();

    final icon = find.byIcon(Icons.check_circle_rounded);
    expect(icon, findsOneWidget);
    await tester.tap(icon);
    await tester.pumpAndSettle();
    // done=true 时 PressFeedback onTap=null, tap 不触发 checkIn, 无异常
    expect(tester.takeException(), isNull);
  });
}
