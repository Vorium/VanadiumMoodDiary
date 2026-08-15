// v0.14 (Round 12C) RemindersHubPage widget 测试
//
// 验证 4 个提醒卡片的渲染 + 状态显示
//
// 1.1.0 round 4 (emotion-first refactor): 失联通知卡整摘, 5 卡 → 4 卡。
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
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';

class _NoopNotificationService extends NotificationService {
  @override
  Future<void> init() async {}
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

  testWidgets('reminders hub 渲染 4 个核心卡片标题', (tester) async {
    _setBigView(tester);
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('每日打卡提醒'), findsOneWidget);
    expect(find.text('用药提醒'), findsOneWidget);
    expect(find.text('续方提醒'), findsOneWidget);
    expect(find.text('周期评估提醒'), findsOneWidget);
    expect(find.text('失联通知（安全开关）'), findsNothing);
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

    // round 4: 失联卡摘, 只剩评估 1 个 "未启用"
    expect(find.text('未启用'), findsNWidgets(1));
    // 用药 + 续方 = 2 个 "未配置"
    expect(find.text('未配置'), findsNWidgets(2));
  });

  testWidgets('4 个 action button 出现 (R95 task 10 删了"查看通知预览")', (tester) async {
    _setBigView(tester);
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // v0.30 round 95 (sub-spec 2 task 10): 删 /email-preview 路由,
    // "查看通知预览" 按钮不再渲染 (actionLabel 改空字符串 + onAction: null)。
    expect(find.text('查看通知预览'), findsNothing);
    expect(find.text('管理用药'), findsOneWidget);
    expect(find.text('管理续方'), findsOneWidget);
    // round 4: 失联卡摘, "配置" 只剩评估 1 个
    expect(find.text('配置'), findsNWidgets(1));
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

  testWidgets('4 个 card 都用 AppleListSection 容器', (tester) async {
    // v0.32 round 13 (R112 EM-02/AH-04 视觉债): ReminderCard 容器
    // Card → AppleListSection (iOS insetGrouped 风格, spec §4.5),
    // 结构断言同步改
    _setBigView(tester);
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // round 4: 失联卡摘, 4 卡 → 4 AppleListSection
    expect(find.byType(AppleListSection), findsNWidgets(4));
    expect(find.byType(Card), findsNothing);
  });
}
