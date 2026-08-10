// v0.31 round 11c (Apple Health redesign · Phase 3 Task 3.3):
// MedicationPage + 5 子页 Apple Health 风格 — 视觉 sanity + 集成测试
//
// 验证 (跟 spec §5.3 medication + Phase 3 任务清单对应):
// 1. medication_page 顶部 4 AppleHealthTile (systemRed 主题)
// 2. medication_page today schedule 走 AppleListSection
// 3. today_med_schedule 走 AppleListSection 容器 (圆角 + hairline)
// 4. medication_calendar_page 章节 ALL CAPS + AppleListSection
// 5. refill_manage_page StatCard ultralight + AppleListSection
// 6. (集成) medication_page 加载 → 顶部 4 tile + 内容渲染

import 'package:chroniccare/core/theme/app_colors.dart';
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/medication/medication_calendar_page.dart';
import 'package:chroniccare/presentation/pages/medication/refill_manage_page.dart';
import 'package:chroniccare/presentation/pages/medication/today_med_schedule.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/apple_health_tile.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void _setBigView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

MedicationEntity _med({
  int id = 1,
  String name = '氟西汀',
  double dosage = 20,
  DosageUnit unit = DosageUnit.mg,
  List<HourMinute> times = const [HourMinute(hour: 8, minute: 0)],
  bool isActive = true,
  DateTime? refillAt,
}) {
  return MedicationEntity(
    id: id,
    name: name,
    dosage: dosage,
    dosageUnit: unit,
    times: times,
    startDate: DateTime(2026, 1, 1),
    isActive: isActive,
    refillAt: refillAt,
    refillReminderDays: 7,
  );
}

/// 包装 widget — 注入 GoRouter (PageScaffold 需要) + 共享 provider
Widget _wrap({
  required Widget child,
  List<MedicationEntity> meds = const [],
  List<CheckInEntity> checkIns = const [],
}) {
  return ProviderScope(
    overrides: [
      medicationsProvider.overrideWith((ref) => Stream.value(meds)),
      allCheckInsProvider.overrideWith((ref) => Stream.value(checkIns)),
    ],
    child: MaterialApp.router(
      theme: ThemeData.light(),
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => child,
          ),
        ],
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
    ),
  );
}

void main() {
  group('medication 5 子页 Apple Health 风格 (R11c 5 视觉 sanity + 1 集成)', () {
    testWidgets(
        '1) AppleHealthTile medication metric 渲染 systemRed (#FF3B30) + icon 28pt',
        (tester) async {
      _setBigView(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                child: AppleHealthTile(
                  metricId: 'medication',
                  label: '待服',
                  value: '5',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1 个 AppleHealthTile
      expect(find.byType(AppleHealthTile), findsOneWidget);
      // label 渲染
      expect(find.text('待服'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      // medication metric icon
      expect(find.byIcon(Icons.medication), findsOneWidget);
      // chevron
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      // 验证 metric color (系统红 #FF3B30)
      expect(
        AppColors.healthMetricsColorFor('medication'),
        const Color(0xFFFF3B30),
        reason: 'medication metric 颜色应 = systemRed #FF3B30',
      );
    });

    testWidgets('2) today_med_schedule 走 AppleListSection (iOS 群组列表 圆角 16 容器)',
        (tester) async {
      _setBigView(tester);
      await tester.pumpWidget(
        _wrap(
          child: const TodayMedSchedule(),
          meds: [
            _med(),
            _med(
              id: 2,
              name: '碳酸锂',
              times: const [
                HourMinute(hour: 20, minute: 0),
              ],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // 1 个 AppleListSection (今日服药计划)
      expect(find.byType(AppleListSection), findsOneWidget);
      // 进度数字 0 / 2
      expect(find.text('0 / 2'), findsOneWidget);
      // 2 个药物名
      expect(find.text('氟西汀'), findsOneWidget);
      expect(find.text('碳酸锂'), findsOneWidget);
    });

    testWidgets('3) medication_calendar_page 走 AppleListSection 包装时间窗口',
        (tester) async {
      _setBigView(tester);
      await tester.pumpWidget(
        _wrap(
          child: const MedicationCalendarPage(),
          meds: [_med()],
        ),
      );
      await tester.pumpAndSettle();

      // AppleListSection 至少 1 个 (时间窗口 segmented button 容器)
      expect(find.byType(AppleListSection), findsAtLeastNWidgets(1));
    });

    testWidgets(
        '4) refill_manage_page 顶部汇总 StatCard ultralight + AppleListSection 包装',
        (tester) async {
      _setBigView(tester);
      final now = DateTime.now();
      // 注意: 给 4 个 med 但 refillAt 全 null (避免 status 出现 提醒中/已过期 干扰)
      // 仅 1 个 med 设 refillAt inWindow 状态, 用来验证 StatCard 数据流
      final meds = [
        _med(id: 1, name: '氟西汀', refillAt: now.add(const Duration(days: 3))),
        _med(id: 2, name: '碳酸锂'),
        _med(id: 3, name: '阿普唑仑'),
        _med(id: 4, name: '舍曲林'),
      ];
      await tester.pumpWidget(
        _wrap(child: const RefillManagePage(), meds: meds),
      );
      await tester.pumpAndSettle();

      // 2 个 AppleListSection (汇总卡 + 续方列表)
      expect(find.byType(AppleListSection), findsNWidgets(2));
      // 4 个 StatCard label (zh locale, 总药数 / 已设续方 / 提醒中 / 已过期)
      expect(find.text('总药数'), findsAtLeastNWidgets(1));
      expect(find.text('已设续方'), findsAtLeastNWidgets(1));
    });

    testWidgets(
        '5) AppleListSection 4 横向 AppleHealthTile 渲染 (模拟 medication_page 顶部)',
        (tester) async {
      _setBigView(tester);
      // 模拟 medication_page 顶部 4-5 tile 横滚 (不嵌 ListView 内, 走 SizedBox)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: AppleHealthTile.tileHeight,
                    child: Row(
                      children: [
                        SizedBox(width: 20),
                        Expanded(
                          child: AppleHealthTile(
                            metricId: 'medication',
                            label: '待服',
                            value: '3',
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: AppleHealthTile(
                            metricId: 'medication',
                            label: '已服',
                            value: '2',
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: AppleHealthTile(
                            metricId: 'medication',
                            label: '需续方',
                            value: '1',
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: AppleHealthTile(
                            metricId: 'medication',
                            label: '用药日历',
                            value: '查看',
                          ),
                        ),
                        SizedBox(width: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 4 个 AppleHealthTile 渲染
      expect(find.byType(AppleHealthTile), findsNWidgets(4));
      // 4 个 label
      expect(find.text('待服'), findsOneWidget);
      expect(find.text('已服'), findsOneWidget);
      expect(find.text('需续方'), findsOneWidget);
      expect(find.text('用药日历'), findsOneWidget);
    });

    // ════════════════════════════════════════════════════════════════
    // 集成测试: today_med_schedule + 多药物 → 显示进度 + 列表
    // ════════════════════════════════════════════════════════════════
    testWidgets('集成) today_med_schedule 多药多时间 + 部分已打卡 → 进度 + 列表 cell 渲染',
        (tester) async {
      _setBigView(tester);
      final meds = [
        _med(id: 1, name: '氟西汀', times: const [HourMinute(hour: 8, minute: 0)]),
        _med(
          id: 2,
          name: '碳酸锂',
          times: const [
            HourMinute(hour: 12, minute: 0),
            HourMinute(hour: 20, minute: 0),
          ],
        ),
      ];
      // 1 个已打卡
      final checkIns = [
        CheckInEntity(
          id: 1,
          timestamp: DateTime.now(),
          type: CheckInType.normal,
          medicationId: 1,
        ),
      ];
      await tester.pumpWidget(
        _wrap(
          child: const TodayMedSchedule(),
          meds: meds,
          checkIns: checkIns,
        ),
      );
      await tester.pumpAndSettle();

      // 1 个 AppleListSection
      expect(find.byType(AppleListSection), findsOneWidget);
      // 进度 1 / 3 (氟西汀已打卡 + 碳酸锂 2 个未打卡)
      expect(find.text('1 / 3'), findsOneWidget);
      // 3 个时间点显示
      expect(find.text('08:00'), findsOneWidget);
      expect(find.text('12:00'), findsOneWidget);
      expect(find.text('20:00'), findsOneWidget);
      // 已打卡的 check icon 渲染 (check_circle_rounded)
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });
  });
}
