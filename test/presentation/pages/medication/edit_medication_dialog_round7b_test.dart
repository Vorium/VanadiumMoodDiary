// v0.32 R110 round 7b-4: edit_medication_dialog (413L god class) 补 0-test
//
// 覆盖:
// 1. 打开 dialog → 预填字段 (药名/剂量/单位/时间 chips) + "服药中" 状态
// 2. 原样保存 → repo.update 收到相同值 + dialog pop true
// 3. 校验: 清空药名 → "请填写药名"; 剂量 0 → "剂量必须是大于 0 的数字"
// 4. 停药 (switch off) → 保存 → isActive=false + endDate 非空
// 5. 恢复 (已停药 med, switch on) → 保存 → isActive=true + endDate null
// 6. 取消 → pop false + update 未调用
// 7. 删除时间 chip → 保存 → times 少一个
//
// 注: 保存后重排走 delegate → plugin, 需 mock 通知 channel
// (见 setUp, 跟 add_medication_page_round7b_test 同款)。

import 'package:chroniccare/core/data/services/notification_service.dart';
import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_draft.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/repositories/medication_repository.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/edit_medication_dialog.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoopNotificationService extends NotificationService {
  @override
  Future<void> init() async {}
  @override
  Future<void> scheduleDailyReminder({int hour = 20, int minute = 0}) async {}
}

class _RecordingMedicationRepository implements MedicationRepository {
  final List<MedicationEntity> updates = [];
  MedicationEntity current;

  _RecordingMedicationRepository(this.current);

  @override
  Future<bool> update(MedicationEntity medication) async {
    updates.add(medication);
    current = medication;
    return true;
  }

  @override
  Stream<List<MedicationEntity>> watchAll() => Stream.value([current]);
  @override
  Stream<List<MedicationEntity>> watchAllIncludingInactive() =>
      Stream.value([current]);
  @override
  Future<int> add(MedicationDraft draft) async => 1;
  @override
  Future<int> delete(int id) async => 1;
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
}

MedicationEntity _med({
  int id = 1,
  String name = '氟西汀',
  double dosage = 20,
  DosageUnit unit = DosageUnit.mg,
  List<HourMinute> times = const [HourMinute(hour: 8, minute: 0)],
  bool isActive = true,
  DateTime? endDate,
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
    endDate: endDate,
  );
}

Future<void> _openDialog(WidgetTester tester, _RecordingMedicationRepository repo) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      medicationRepositoryProvider.overrideWithValue(repo),
      notificationServiceProvider.overrideWithValue(_NoopNotificationService()),
      medicationsProvider.overrideWith((ref) => repo.watchAll()),
    ],
    child: MaterialApp(
      theme: ThemeData.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showEditMedicationDialog(context, repo.current),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (call) async => switch (call.method) {
        'pendingNotificationRequests' => <Map<String, Object?>>[],
        _ => null,
      },
    );
  });

  testWidgets('1) 打开 dialog → 预填字段 + 服药中状态', (tester) async {
    final repo = _RecordingMedicationRepository(
      _med(times: const [
        HourMinute(hour: 8, minute: 0),
        HourMinute(hour: 20, minute: 0),
      ]),
    );
    await _openDialog(tester, repo);

    expect(find.text('编辑药物'), findsOneWidget);
    expect(find.text('氟西汀'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('20:00'), findsOneWidget);
    expect(find.text('正在使用'), findsOneWidget);
  });

  testWidgets('2) 原样保存 → update 收到相同值 + pop true', (tester) async {
    final repo = _RecordingMedicationRepository(_med());
    await _openDialog(tester, repo);

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(repo.updates, hasLength(1));
    final updated = repo.updates.single;
    expect(updated.name, '氟西汀');
    expect(updated.dosage, 20);
    expect(updated.dosageUnit, DosageUnit.mg);
    expect(updated.times, [const HourMinute(hour: 8, minute: 0)]);
    expect(updated.isActive, isTrue);
    // dialog 已关闭
    expect(find.text('编辑药物'), findsNothing);
  });

  testWidgets('3a) 空药名 → 校验错误, 不保存', (tester) async {
    final repo = _RecordingMedicationRepository(_med());
    await _openDialog(tester, repo);

    await tester.enterText(find.widgetWithText(TextField, '氟西汀'), '');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('请填写药名'), findsOneWidget);
    expect(repo.updates, isEmpty);
    expect(find.text('编辑药物'), findsOneWidget);
  });

  testWidgets('3b) 剂量 0 → 校验错误', (tester) async {
    final repo = _RecordingMedicationRepository(_med());
    await _openDialog(tester, repo);

    // 剂量输入框 (数字键盘)
    await tester.enterText(
      find.widgetWithText(TextField, '20'),
      '0',
    );
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('剂量必须是大于 0 的数字'), findsOneWidget);
    expect(repo.updates, isEmpty);
  });

  testWidgets('4) 停药 (switch off) → isActive=false + endDate 非空',
      (tester) async {
    final repo = _RecordingMedicationRepository(_med());
    await _openDialog(tester, repo);

    // 停药 switch (SwitchListTile)
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(find.text('已停药'), findsOneWidget);

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final updated = repo.updates.single;
    expect(updated.isActive, isFalse);
    expect(updated.endDate, isNotNull);
  });

  testWidgets('5) 恢复 (switch on, 已停药 med) → isActive=true + endDate null',
      (tester) async {
    final repo = _RecordingMedicationRepository(
      _med(isActive: false, endDate: DateTime(2026, 7, 1)),
    );
    await _openDialog(tester, repo);

    expect(find.text('已停药'), findsOneWidget);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(find.text('正在使用'), findsOneWidget);

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final updated = repo.updates.single;
    expect(updated.isActive, isTrue);
    expect(updated.endDate, isNull);
  });

  testWidgets('6) 取消 → pop false + update 未调用', (tester) async {
    final repo = _RecordingMedicationRepository(_med());
    await _openDialog(tester, repo);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(find.text('编辑药物'), findsNothing);
    expect(repo.updates, isEmpty);
  });

  testWidgets('7) 删除时间 chip → 保存 → times 少一个', (tester) async {
    final repo = _RecordingMedicationRepository(
      _med(times: const [
        HourMinute(hour: 8, minute: 0),
        HourMinute(hour: 20, minute: 0),
      ]),
    );
    await _openDialog(tester, repo);

    // 删除 20:00 chip (InputChip delete icon)
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(InputChip, '20:00'),
        matching: find.byIcon(Icons.clear),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('20:00'), findsNothing);

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final updated = repo.updates.single;
    expect(updated.times, [const HourMinute(hour: 8, minute: 0)]);
  });
}