// v0.24 (Round 45) medications_list god class 拆解 — 子 widget 挂载测试
//
// 验证 4 个新子 widget 都能在 ProviderScope + MaterialApp 内 mount,
// 公开 API 签名不变 (MedicationsListWidget({required meds})).
//
// 不测业务流程 (业务流程 974 个 test 已覆盖),
// 仅测 mount + 子 widget 路由通.

import 'package:chroniccare/core/data/services/notification_service.dart';
import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_draft.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/repositories/medication_repository.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/medication_empty_state.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/medication_list_view.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/medication_row.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/medications_list_widget.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/refill_days_dialog.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoopNotificationService extends NotificationService {
  @override
  Future<void> init() async {}
}

class _StubMedicationRepository implements MedicationRepository {
  @override
  Future<int> delete(int id) async => 1;
  @override
  Future<int> add(MedicationDraft draft) async {
    return 1;
  }

  @override
  Future<bool> update(MedicationEntity medication) async => true;
  @override
  Future<bool> setActive({
    required int medicationId,
    required bool isActive,
  }) async =>
      true;
  @override
  Future<bool> updateRefill({
    required int medicationId,
    required DateTime? refillAt,
    int? reminderDays,
  }) async =>
      true;
  @override
  Stream<List<MedicationEntity>> watchAll() => Stream.value([]);
  @override
  Stream<List<MedicationEntity>> watchAllIncludingInactive() =>
      Stream.value([]);
}

MedicationEntity _med({
  int id = 1,
  String name = '氟西汀',
  bool isActive = true,
  DateTime? refillAt,
  int reminderDays = 7,
}) {
  return MedicationEntity(
    id: id,
    name: name,
    dosage: 40,
    dosageUnit: DosageUnit.mg,
    times: const [HourMinute(hour: 8, minute: 0)],
    startDate: DateTime(2026, 1, 1),
    isActive: isActive,
    refillAt: refillAt,
    refillReminderDays: reminderDays,
  );
}

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      notificationServiceProvider.overrideWithValue(_NoopNotificationService()),
      medicationRepositoryProvider
          .overrideWithValue(_StubMedicationRepository()),
      medicationsProvider
          .overrideWith((ref) => Stream.value(<MedicationEntity>[])),
    ],
    child: MaterialApp(
      theme: ThemeData.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('god class 拆解 — 子 widget 挂载', () {
    testWidgets('MedicationEmptyState (noMeds) mount + 显示 l10n',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const MedicationEmptyState(kind: MedicationEmptyKind.noMeds)),
      );
      await tester.pumpAndSettle();

      expect(find.text('还没添加常吃药'), findsOneWidget);
      expect(find.text('添加药物'), findsOneWidget);
    });

    testWidgets('MedicationEmptyState (noActive) mount + 显示 l10n',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const MedicationEmptyState(kind: MedicationEmptyKind.noActive)),
      );
      await tester.pumpAndSettle();

      expect(find.text('没有在用的药'), findsOneWidget);
    });

    testWidgets('MedicationRow mount + 显示药名 + 剂量 + 时间', (tester) async {
      await tester.pumpWidget(
        _wrap(
          MedicationRow(
            med: _med(name: '氟西汀'),
            isDeleting: false,
            isEditing: false,
            isEditingRefill: false,
            onDelete: () {},
            onEdit: () {},
            onEditRefill: () {},
            onSwipeDelete: (m) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('氟西汀'), findsOneWidget);
      expect(find.textContaining('40'), findsOneWidget);
    });

    testWidgets('MedicationRow (stopped) 显示 stopped 徽章 + 删除线', (tester) async {
      await tester.pumpWidget(
        _wrap(
          MedicationRow(
            med: _med(name: '碳酸锂', isActive: false),
            isDeleting: false,
            isEditing: false,
            isEditingRefill: false,
            onDelete: () {},
            onEdit: () {},
            onEditRefill: () {},
            onSwipeDelete: (m) async {},
            enableSwipe: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('碳酸锂'), findsOneWidget);
      expect(find.text('已停药'), findsOneWidget);
    });

    testWidgets('MedicationListView mount + empty state (无 active)',
        (tester) async {
      final stoppedMed = _med(name: '已停药', isActive: false);
      await tester.pumpWidget(
        _wrap(
          MedicationListView(
            meds: [stoppedMed],
            deleting: const {},
            editing: const {},
            editingRefill: const {},
            onDelete: (id) async {},
            onEdit: (med) async {},
            onEditRefill: (med) async {},
            onSwipeDelete: (med) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 无 active → 走 noActive 空态 + stopped 列表
      expect(find.text('没有在用的药'), findsOneWidget);
      // "已停药" 出现 1+ 次 (section header + chip badge), 用 findsWidgets
      expect(find.text('已停药'), findsWidgets);
      // v0.32 round 14 (R112 F1 遗留): stopped 列表 Card → AppleListSection
      expect(find.byType(AppleListSection), findsOneWidget);
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('MedicationListView (active meds) 显示日历入口 + 列表', (tester) async {
      await tester.pumpWidget(
        _wrap(
          MedicationListView(
            meds: [_med(name: '氟西汀')],
            deleting: const {},
            editing: const {},
            editingRefill: const {},
            onDelete: (id) async {},
            onEdit: (med) async {},
            onEditRefill: (med) async {},
            onSwipeDelete: (med) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 用药日历入口 (v0.14 round 13C)
      expect(find.text('用药日历'), findsOneWidget);
      expect(find.text('氟西汀'), findsOneWidget);
      // v0.32 round 14 (R112 F1 遗留): 日历入口 + active 列表
      // 2 处 Card → AppleListSection (hairline 由容器自动串联)
      expect(find.byType(AppleListSection), findsNWidgets(2));
      expect(find.byType(Card), findsNothing);
    });

    testWidgets(
        'MedicationsListWidget (meds=[]) → 走 MedicationEmptyState.noMeds',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const MedicationsListWidget(meds: [])),
      );
      await tester.pumpAndSettle();

      expect(find.text('还没添加常吃药'), findsOneWidget);
    });

    testWidgets('MedicationsListWidget (meds=[1]) 公开 API 签名不变 → mount OK',
        (tester) async {
      await tester.pumpWidget(
        _wrap(MedicationsListWidget(meds: [_med()])),
      );
      await tester.pumpAndSettle();

      expect(find.text('氟西汀'), findsOneWidget);
      // v0.32 round 14 (R112 F1 遗留): 日历入口 + active 列表 2 ALS, 0 Card
      expect(find.byType(AppleListSection), findsNWidgets(2));
      expect(find.byType(Card), findsNothing);
    });
  });

  group('RefillDaysDialog', () {
    testWidgets('mount + 显示 5 个 radio 选项', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: const Scaffold(
            body: RefillDaysDialog(initial: 7),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('提前几天提醒？'), findsOneWidget);
      // 5 个 radio 标题
      expect(find.text('3 天'), findsOneWidget);
      expect(find.text('5 天'), findsOneWidget);
      expect(find.text('7 天'), findsOneWidget);
      expect(find.text('14 天'), findsOneWidget);
      expect(find.text('30 天'), findsOneWidget);
    });

    testWidgets('initial=10 (不在 _options) → 默认选 7', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: const Scaffold(
            body: RefillDaysDialog(initial: 10),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 找 RadioGroup widget, 检查 groupValue
      final radioGroup = tester.widget<RadioGroup<int>>(
        find.byType(RadioGroup<int>),
      );
      expect(radioGroup.groupValue, 7, reason: 'initial=10 不在 _options, 回落到 7');
    });
  });
}
