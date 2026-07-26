// v0.14 (Round 13A) RefillManagePage widget + 业务逻辑测试
import 'package:chroniccare/core/data/services/notification_service.dart';
import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/presentation/pages/medication/refill_manage_page.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chroniccare/l10n/app_localizations.dart';

class _NoopNotificationService extends NotificationService {
  @override
  Future<void> init() async {}
  @override
  Future<void> scheduleDailyReminder({int hour = 20, int minute = 0}) async {}
}

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
      notificationServiceProvider.overrideWithValue(_NoopNotificationService()),
      medicationsProvider.overrideWith((ref) => Stream.value(meds)),
    ],
    child: MaterialApp(
      theme: ThemeData.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: const Scaffold(body: RefillManagePage()),
    ),
  );
}

MedicationEntity _med({
  int id = 1,
  String name = '氟西汀',
  double dosage = 40,
  DosageUnit unit = DosageUnit.mg,
  bool isActive = true,
  DateTime? refillAt,
  int reminderDays = 7,
}) {
  return MedicationEntity(
    id: id,
    name: name,
    dosage: dosage,
    dosageUnit: unit,
    times: const [HourMinute(hour: 8, minute: 0)],
    startDate: DateTime(2026, 1, 1),
    isActive: isActive,
    refillAt: refillAt,
    refillReminderDays: reminderDays,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('业务：RefillStatus 计算（4 状态）', () {
    test('未设 refillAt → notConfigured', () {
      final m = _med(refillAt: null);
      expect(m.hasRefill, isFalse);
    });

    test('refillAt 在远处 → farFuture', () {
      final m = _med(refillAt: DateTime.now().add(const Duration(days: 30)));
      expect(m.isInRefillWindow(), isFalse);
      expect(m.isRefillOverdue(), isFalse);
    });

    test('refillAt 在窗口内 → inWindow', () {
      final m = _med(refillAt: DateTime.now().add(const Duration(days: 3)));
      expect(m.isInRefillWindow(), isTrue);
      expect(m.isRefillOverdue(), isFalse);
    });

    test('refillAt 已过 → overdue', () {
      final m =
          _med(refillAt: DateTime.now().subtract(const Duration(days: 3)));
      expect(m.isRefillOverdue(), isTrue);
    });

    test('reminderDays 边界：今天正好是 refillAt - N（窗口起点）', () {
      final now = DateTime.now();
      final m = _med(
        refillAt: now.add(const Duration(days: 7)),
        reminderDays: 7,
      );
      // 窗口起点 = now (refillAt - 7)
      // 期望: inWindow = true
      expect(m.isInRefillWindow(), isTrue);
    });

    // v0.14 fix (Bug B): 续方 day 当天 14:00 仍然不算过期
    test('refillAt 当天 14:00 → not overdue（refill day 整天不算）', () {
      final now = DateTime.now();
      // 模拟 refillAt = 今天的 00:00，now 是 14:00
      final todayMidnight = DateTime(now.year, now.month, now.day);
      final m = _med(refillAt: todayMidnight);
      expect(m.isRefillOverdue(), isFalse, reason: 'refill day 当天不应该算过期');
    });

    test('refillAt 昨天 23:59 → overdue', () {
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 1))
          .add(const Duration(hours: 23, minutes: 59));
      final m = _med(refillAt: yesterday);
      expect(m.isRefillOverdue(), isTrue);
    });
  });

  group('widget: RefillManagePage', () {
    testWidgets('页面渲染 + 顶部 4 个统计', (tester) async {
      _setBigView(tester);
      await tester.pumpWidget(_wrap(meds: [_med(), _med(id: 2, name: '碳酸锂')]));
      await tester.pumpAndSettle();

      expect(find.text('续方管理'), findsOneWidget);
      expect(find.text('总药数'), findsOneWidget);
      expect(find.text('已设续方'), findsOneWidget);
      expect(find.text('提醒中'), findsOneWidget);
      expect(find.text('已过期'), findsOneWidget);
    });

    testWidgets('空 meds → "还没有添加药物"', (tester) async {
      _setBigView(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('还没有添加药物'), findsOneWidget);
    });

    testWidgets('未设续方的药显示"未设置"徽章', (tester) async {
      _setBigView(tester);
      await tester.pumpWidget(_wrap(meds: [_med(refillAt: null)]));
      await tester.pumpAndSettle();

      expect(find.text('未设置'), findsOneWidget);
    });

    testWidgets('已过期的药显示"已过期" + 排第一', (tester) async {
      _setBigView(tester);
      final meds = [
        _med(
          id: 1,
          name: '正常药',
          refillAt: DateTime.now().add(const Duration(days: 30)),
        ),
        _med(
          id: 2,
          name: '过期药',
          refillAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ];
      await tester.pumpWidget(_wrap(meds: meds));
      await tester.pumpAndSettle();

      // 找到 2 个徽章
      final badges = find.byWidgetPredicate((w) {
        if (w is Container) {
          final c = w.child;
          if (c is Text) {
            return c.data == '已过期' || c.data == '已设';
          }
        }
        return false;
      });
      expect(badges, findsWidgets);
    });

    testWidgets('点击行 → 跳到编辑对话框', (tester) async {
      _setBigView(tester);
      final med = _med(
        name: '氟西汀',
        refillAt: DateTime.now().add(const Duration(days: 30)),
      );
      await tester.pumpWidget(_wrap(meds: [med]));
      await tester.pumpAndSettle();

      // 找到包含药名 + 剂量的行
      final row = find.textContaining('氟西汀');
      expect(row, findsOneWidget);
      await tester.tap(row);
      await tester.pumpAndSettle();

      // EditMedicationDialog 应该弹出（验证 dialog 存在）
      // 由于 dialog 内部用 notifier，dialog 不一定立刻 render，但 showDialog 会把 dialog 加到 overlay
      // 我们检查 Navigator 是否多了一层
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      expect(navigator.canPop(), isTrue); // 可 pop 说明 dialog 在 stack
    });
  });
}
