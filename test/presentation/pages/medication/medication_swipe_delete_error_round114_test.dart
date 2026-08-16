// v1.1.0 R114 (BUG 6): medication_row swipe 删除失败错误处理回归测试
//
// 修前 (R113 BUG 7b 同款漏修): Dismissible key 固定
// `medication-<id>` 无失败计数 — swipe 删除失败时 catch 只弹 snackbar,
// Dismissible 已 dismiss 但仍留在树 (widget.meds 未变) → 下次 rebuild
// 抛 FlutterError "A dismissed Dismissible widget is still part of the
// tree"。R113 修了 vent_list / treatment, 漏 medication_row。
//
// 修法: key 带失败计数 (`medication-<id>-<failCount>`), catch 里计数 +1
// → 旧 Dismissible unmount + 新 key remount 回"未滑走"状态, 条目立即
// 回到列表 (DB 里还在) + swallowError + invalidate medicationsProvider。
//
// 全流程: swipe → (无 confirmDismiss, 直接 onDismissed) → delete 抛异常
// → 条目重新可见 + 无 "dismissed Dismissible" 异常 + 错误 snackbar。
//
// 依赖: medicationRepositoryProvider override 为 delete 必抛的 fake;
// notificationServiceProvider 用真实 NotificationService + 全 mock
// plugin channel (cancelRefillReminder/cancelSnoozeForMedication 走
// channel, setup_page_state_round112 同款 harness)。

import 'package:chroniccare/core/data/services/notification_service.dart';
import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_draft.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/repositories/medication_repository.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/medications_list_widget.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// delete 必抛异常的 medication 仓库 — watchAll 始终返回原条目
class _ThrowingMedicationRepository implements MedicationRepository {
  final List<MedicationEntity> entries;
  _ThrowingMedicationRepository(this.entries);

  @override
  Stream<List<MedicationEntity>> watchAll() => Stream.value(entries);

  @override
  Stream<List<MedicationEntity>> watchAllIncludingInactive() =>
      Stream.value(entries);

  @override
  Future<int> add(MedicationDraft draft) async => 1;

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
  Future<int> delete(int id) async {
    throw Exception('db delete failed');
  }
}

const _pluginChannel =
    MethodChannel('dexterous.com/flutter/local_notifications');
const _tzChannel = MethodChannel('flutter_timezone');

void main() {
  void setBigView(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget wrap(List<MedicationEntity> meds) {
    return ProviderScope(
      overrides: [
        notificationServiceProvider.overrideWithValue(
          NotificationService(),
        ),
        medicationRepositoryProvider.overrideWithValue(
          _ThrowingMedicationRepository(meds),
        ),
        medicationsProvider.overrideWith(
          (ref) => Stream.value(meds),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(body: MedicationsListWidget(meds: meds)),
      ),
    );
  }

  testWidgets(
      'R114 BUG 6: swipe 删除抛异常 → 无 dismissed-Dismissible 异常 '
      '+ 条目回到列表 + 错误 snackbar', (tester) async {
    setBigView(tester);
    SharedPreferences.setMockInitialValues({});
    // Haptics.warning() 平台 channel mock (swipe onDismissed 前先触感)
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });
    // flutter_local_notifications + timezone channel mock —
    // _swipeDeleteMedication 先走 delegate.cancelRefillReminder /
    // cancelSnoozeForMedication (内部 init 走 channel)
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pluginChannel, (call) async {
      if (call.method == 'initialize' ||
          call.method == 'requestPermissions' ||
          call.method == 'requestNotificationsPermission') {
        return true;
      }
      return null;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_tzChannel, (call) async => 'Asia/Shanghai');
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_pluginChannel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_tzChannel, null);
    });

    final med = MedicationEntity(
      id: 1,
      name: '舍曲林',
      dosage: 50,
      dosageUnit: DosageUnit.mg,
      times: const [HourMinute(hour: 8, minute: 0)],
      startDate: DateTime(2026, 1, 1),
      isActive: true,
      refillAt: null,
      refillReminderDays: 7,
    );
    await tester.pumpWidget(wrap([med]));
    await tester.pumpAndSettle();
    expect(find.text('舍曲林'), findsOneWidget);

    // 真实 swipe (endToStart) → 无 confirmDismiss → 直接 onDismissed
    await tester.drag(
      find.byType(Dismissible).first,
      const Offset(-600, 0),
    );
    await tester.pumpAndSettle();

    // R114 BUG 6 修前: catch 只弹 snackbar, Dismissible (key 不变) 仍在树
    // → rebuild 抛 FlutterError "A dismissed Dismissible widget is still
    // part of the tree"。修后: key 换 → remount → 条目回来。
    expect(
      tester.takeException(),
      isNull,
      reason: '修前: dismissed Dismissible 仍在树 → FlutterError',
    );
    expect(
      find.text('舍曲林'),
      findsOneWidget,
      reason: 'delete 失败后条目必须回到列表 (DB 里还在)',
    );
    expect(
      find.textContaining('删除失败'),
      findsOneWidget,
      reason: '错误 snackbar (commonDelete 模板)',
    );

    // 排空错误 snackbar 4s 计时器, 避免 test 结束 pending timer
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
