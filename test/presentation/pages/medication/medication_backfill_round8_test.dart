// v0.32 round 8 (R111 R111-03 fix): 补打卡 SnackBar-only stub → 真实现
//
// 背景: medication_calendar_page `_onAddLogStub` (R93 task 1.5) 只弹
// "补打卡功能接入中" SnackBar (B2-09 残留)。RecordCheckInUseCase.call 已有
// `at` 参数, 只差 UI 接入。R111-03 修: 补打卡 button → 选药 dialog →
// checkIn(medicationId, at: date) → 成功 SnackBar + provider 刷新。
//
// 覆盖:
// 1. 点补打卡 → dialog 打开 (药名下拉 + 确认/取消)
// 2. 确认 → CheckInNotifier.checkIn 被调 (medicationId + at=选中日期)
// 3. 确认 → 成功 SnackBar (走 AppSnackBar) + 不再出现 stub 文案
import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/medication/medication_calendar_page.dart';
import 'package:chroniccare/presentation/providers/check_in_notifier.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCheckInNotifier extends CheckInNotifier {
  int callCount = 0;
  int? lastMedicationId;
  DateTime? lastAt;

  @override
  Future<void> checkIn({int? medicationId, DateTime? at}) async {
    callCount++;
    lastMedicationId = medicationId;
    lastAt = at;
  }
}

void _setBigView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 1500);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

MedicationEntity _med({int id = 1, String name = '氟西汀'}) {
  return MedicationEntity(
    id: id,
    name: name,
    dosage: 40,
    dosageUnit: DosageUnit.mg,
    times: const [HourMinute(hour: 8, minute: 0)],
    startDate: DateTime(2026, 1, 1),
    isActive: true,
    refillReminderDays: 7,
  );
}

void main() {
  group('v0.32 round 8 (R111-03) — 补打卡真实现', () {
    testWidgets('1. 点补打卡 → dialog 打开 (选药下拉 + 确认/取消)', (tester) async {
      _setBigView(tester);
      final fake = _FakeCheckInNotifier();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            medicationsProvider.overrideWith((ref) => Stream.value([_med()])),
            allCheckInsProvider.overrideWith((ref) => Stream.value(const [])),
            checkInNotifierProvider.overrideWith(() => fake),
          ],
          child: MaterialApp(
            theme: ThemeData.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),
            home: const Scaffold(body: MedicationCalendarPage()),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 点 "今天" cell → DayDetail
      final allPressFeedbacks = find.byType(PressFeedback);
      await tester.tap(allPressFeedbacks.at(30));
      await tester.pumpAndSettle();

      // 点补打卡 → dialog 打开
      await tester.tap(find.text('补打卡'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('确认补打卡'), findsOneWidget);
      expect(fake.callCount, 0, reason: '确认前不应写 DB');
    });

    testWidgets('2. 确认 → checkIn(medicationId, at=选中日期) + 成功 SnackBar',
        (tester) async {
      _setBigView(tester);
      final fake = _FakeCheckInNotifier();
      final today = DateTime.now();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            medicationsProvider.overrideWith((ref) => Stream.value([_med()])),
            allCheckInsProvider.overrideWith((ref) => Stream.value(const [])),
            checkInNotifierProvider.overrideWith(() => fake),
          ],
          child: MaterialApp(
            theme: ThemeData.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),
            home: const Scaffold(body: MedicationCalendarPage()),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final allPressFeedbacks = find.byType(PressFeedback);
      await tester.tap(allPressFeedbacks.at(30));
      await tester.pumpAndSettle();
      await tester.tap(find.text('补打卡'));
      await tester.pumpAndSettle();

      // 确认 (dialog 内 PrimaryButton)
      await tester.tap(find.text('确认补打卡'));
      await tester.pumpAndSettle();

      expect(fake.callCount, 1, reason: '确认后应写 1 次打卡');
      expect(fake.lastMedicationId, 1, reason: '默认选第 1 个药');
      expect(fake.lastAt, isNotNull);
      expect(
        fake.lastAt!.year == today.year &&
            fake.lastAt!.month == today.month &&
            fake.lastAt!.day == today.day,
        isTrue,
        reason: '补打卡 at 应是选中日期 (今天)',
      );

      // 成功 SnackBar (不再是 stub 文案)
      expect(find.textContaining('补打卡功能接入中'), findsNothing);
      expect(find.textContaining('已补打卡'), findsOneWidget);
    });

    testWidgets('3. 取消 → 0 写 DB, dialog 关闭', (tester) async {
      _setBigView(tester);
      final fake = _FakeCheckInNotifier();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            medicationsProvider.overrideWith((ref) => Stream.value([_med()])),
            allCheckInsProvider.overrideWith((ref) => Stream.value(const [])),
            checkInNotifierProvider.overrideWith(() => fake),
          ],
          child: MaterialApp(
            theme: ThemeData.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),
            home: const Scaffold(body: MedicationCalendarPage()),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final allPressFeedbacks = find.byType(PressFeedback);
      await tester.tap(allPressFeedbacks.at(30));
      await tester.pumpAndSettle();
      await tester.tap(find.text('补打卡'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      expect(fake.callCount, 0, reason: '取消不应写 DB');
      expect(find.byType(Dialog), findsNothing);
    });
  });
}
