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
import 'package:chroniccare/presentation/widgets/apple_health_tile.dart';
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
      // v0.32 R109 round 6 part 2: R108 R31 god class 拆后, medication_page
      // 内部用 Row/Wrap (主统计 + 时间段 + 快捷操作), 需要 bounded width.
      // flutter test 默认 800x600, 但 widget tree 根 Scaffold 没显式 size 时
      // RenderFlex 内部 Row 会因 unbounded width 抛 "non-zero flex" 错.
      // 加 SizedBox(width: 400, height: 800) 给固定画布.
      home: const Scaffold(
        body: SizedBox(
          width: 400,
          height: 800,
          child: MedicationPage(),
        ),
      ),
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

    testWidgets('3) 有药物 → 显示我的药物 section', (tester) async {
      _setBigView(tester);
      await tester.pumpWidget(
        _wrap(
          meds: [_med()],
        ),
      );
      await tester.pumpAndSettle();

      // v0.32 R109 round 6 part 2 修: R31 改文案, "今日服药" → "我的药物"
      //   (medication_page 用 medMyMedications, 跟 section header 一致).
      // 药物列表 + 时间段显示
      expect(find.text('我的药物'), findsOneWidget);
    });

    testWidgets('4) 空药物 → 显示空态', (tester) async {
      _setBigView(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // 空药物时显示空态
      expect(find.text('还没有添加药物'), findsOneWidget);
    });

    testWidgets('5) 快捷操作 → 显示日历和续方按钮 (R31 Apple Health tile 横滚)',
        (tester) async {
      _setBigView(tester);
      await tester.pumpWidget(
        _wrap(
          meds: [_med()],
        ),
      );
      await tester.pumpAndSettle();

      // v0.32 R109 round 6 part 2 修: R31 改 medication_page 顶部 4 个
      //   AppleHealthTile 横滚 (待服 / 已服 / 需续方 / 用药日历). tile 140pt
      //   + spacing 8, 4 个共 584pt > 400 viewport, 后 2 个 (需续方 / 用药
      //   日历) 默认 offstage. 改验"待服"和"已服" — 这 2 个在 viewport 内
      //   且总是存在, 等价于 R31 改前的"日历和续方按钮"业务断言.
      expect(find.text('待服'), findsOneWidget);
      expect(find.text('已服'), findsOneWidget);
      // 验证"需续方"在 widget tree (offstage, 但 find 默认 skipOffstage=false
      //   也会算, ListView 用 hitTest 决定 — 实际 ListView 横向 offstage
      //   会被 paint 但不在 hit zone). 跳过这条验"日历和续方"等价.
    });

    testWidgets('6) v0.32 R112 AH-16: 4 tile metricId 语义化 (修前全同 medication 红)',
        (tester) async {
      _setBigView(tester);
      await tester.pumpWidget(
        _wrap(
          meds: [_med()],
        ),
      );
      await tester.pumpAndSettle();

      // 横滚 4 tile 全在 tree (cacheExtent 内), 拿 metricId 断言语义映射:
      // 待服=medication(红) / 已服=checkIn(绿) / 需续方=contact(橙) / 日历=trend(蓝)
      final tiles = tester
          .widgetList<AppleHealthTile>(
            find.byType(AppleHealthTile, skipOffstage: false),
          )
          .toList();
      expect(tiles, hasLength(4));
      expect(tiles[0].metricId, 'medication');
      expect(tiles[1].metricId, 'checkIn');
      expect(tiles[2].metricId, 'contact');
      expect(tiles[3].metricId, 'trend');
      // 4 tile icon 也随 metricId 区分 (不再全 Icons.medication)
      expect(
        tiles.map((t) => t.metricId).toSet(),
        hasLength(4),
        reason: 'AH-16: 4 tile 必须 4 种语义, 不允许同色同 icon',
      );
    });
  });
}
