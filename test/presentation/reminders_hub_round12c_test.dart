// v0.14 (Round 12C) RemindersHubPage widget 测试
//
// 验证 5 个提醒卡片的渲染 + 状态显示
import 'package:chroniccare/core/data/services/notification_service.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/settings/reminders_hub_page.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';

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

Widget _wrap({
  List<MedicationEntity> meds = const [],
}) {
  return ProviderScope(
    overrides: [
      notificationServiceProvider.overrideWithValue(_NoopNotificationService()),
      medicationsProvider.overrideWith((ref) => Stream.value(meds)),
    ],
    child: MaterialApp(
      theme: ThemeData.light(),
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: RemindersHubPage()),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('reminders hub 渲染 5 个核心卡片标题', (tester) async {
    _setBigView(tester);
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('每日打卡提醒'), findsOneWidget);
    expect(find.text('用药提醒'), findsOneWidget);
    expect(find.text('续方提醒'), findsOneWidget);
    expect(find.text('周期评估提醒'), findsOneWidget);
    expect(find.text('失联通知（安全开关）'), findsOneWidget);
  });

  testWidgets('顶部 banner 提示集中管理', (tester) async {
    _setBigView(tester);
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(
      find.textContaining('集中管理所有提醒'),
      findsOneWidget,
    );
  });

  testWidgets('默认未启用时显示"未启用"/"未配置"', (tester) async {
    _setBigView(tester);
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 评估 + 安全开关 = 2 个 "未启用"
    expect(find.text('未启用'), findsNWidgets(2));
    // 用药 + 续方 = 2 个 "未配置"
    expect(find.text('未配置'), findsNWidgets(2));
  });

  testWidgets('5 个 action button 出现', (tester) async {
    _setBigView(tester);
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('查看通知预览'), findsOneWidget);
    expect(find.text('管理用药'), findsOneWidget);
    expect(find.text('管理续方'), findsOneWidget);
    expect(find.text('配置'), findsNWidgets(2));
  });

  testWidgets('用药提醒卡有正确描述（无药物时）', (tester) async {
    _setBigView(tester);
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(
      find.text('还没有在用药物 · 添加后会自动启用'),
      findsOneWidget,
    );
  });

  testWidgets('有在用药物时显示 "X 种 / Y 时间点"', (tester) async {
    _setBigView(tester);
    final meds = [
      MedicationEntity(
        id: 1,
        name: '氟西汀',
        dosage: 40,
        dosageUnit: DosageUnit.mg,
        times: const [
          HourMinute(hour: 8, minute: 0),
          HourMinute(hour: 20, minute: 0),
        ],
        startDate: DateTime(2026, 1, 1),
        isActive: true,
        refillReminderDays: 7,
      ),
      MedicationEntity(
        id: 2,
        name: '碳酸锂',
        dosage: 300,
        dosageUnit: DosageUnit.mg,
        times: const [HourMinute(hour: 12, minute: 0)],
        startDate: DateTime(2026, 1, 1),
        isActive: true,
        refillReminderDays: 7,
      ),
    ];
    await tester.pumpWidget(_wrap(meds: meds));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(
      find.text('已启用 · 2 种 ／ 3 时间点'),
      findsOneWidget,
    );
    expect(
      find.textContaining('共 2 种在用药物'),
      findsOneWidget,
    );
  });

  testWidgets('5 个 card 都用 Card 容器', (tester) async {
    _setBigView(tester);
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.byType(Card), findsNWidgets(5));
  });
}
