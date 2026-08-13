// v0.32 round 8 (R112-09 fix): MedDraft.times 增删触发变更通知
//
// 背景: MedDraft.times 是普通 List<TimeOfDay>, MedCard 的 InputChip
// onDeleted (`med.times.removeAt`) + ActionChip 添加 (`med.times.add`)
// 直接改 list 不触发任何通知 → SetupPageState 不 setState → widget 不重建
// → 用户"删除没反应 / 添加没反应"假 bug。
//
// R112-09 修: MedDraft 加 times 变更通知回调 (attachListener 同款模式),
// 新增 addTime / removeTimeAt 方法 (内部排序 + 触发回调), 接
// SetupPageState._onTextChanged → setState 重建。
//
// 测试 4 case:
// 1. unit: attachListener 后 addTime → callback 触发 + 时间自动排序
// 2. unit: removeTimeAt → callback 触发 + list 变短
// 3. unit: 未 attachListener → add/remove 不抛 (preset addAll 场景兜底)
// 4. widget: MedCard 删除时间 chip → med.times 变空 (onDeleted 接线正确)
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/setup/setup_step_medication.dart';
import 'package:chroniccare/presentation/pages/setup/setup_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MedDraft times 变更通知 (R112-09)', () {
    test('1. attachListener 后 addTime → callback 触发 + 自动排序', () {
      final med = MedDraft();
      var notified = 0;
      med.attachListener(() => notified++);

      med.addTime(const TimeOfDay(hour: 20, minute: 0));
      expect(notified, 1, reason: 'addTime 应触发变更回调');
      med.addTime(const TimeOfDay(hour: 8, minute: 0));
      expect(notified, 2);

      // 自动排序: 8:00 在 20:00 前
      expect(med.times.length, 2);
      expect(
        med.times[0],
        const TimeOfDay(hour: 8, minute: 0),
        reason: 'addTime 内部应排序 (hour*60+minute 升序)',
      );
      expect(med.times[1], const TimeOfDay(hour: 20, minute: 0));
    });

    test('2. removeTimeAt → callback 触发 + list 变短', () {
      final med = MedDraft()
        ..times.add(const TimeOfDay(hour: 8, minute: 0))
        ..times.add(const TimeOfDay(hour: 20, minute: 0));
      var notified = 0;
      med.attachListener(() => notified++);

      med.removeTimeAt(0);
      expect(notified, 1, reason: 'removeTimeAt 应触发变更回调');
      expect(med.times.length, 1);
      expect(med.times.single, const TimeOfDay(hour: 20, minute: 0));
    });

    test('3. 未 attachListener → add/remove 不抛 (preset addAll 场景兜底)', () {
      final med = MedDraft();
      med.times.add(const TimeOfDay(hour: 8, minute: 0));
      med.addTime(const TimeOfDay(hour: 20, minute: 0));
      med.removeTimeAt(0);
      expect(med.times.length, 1, reason: '无 listener 时纯数据操作仍可用');
    });

    testWidgets('4. MedCard 删除时间 chip → med.times 变空 (onDeleted 接线)',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final med = MedDraft()
        ..nameController.text = '舍曲林'
        ..times.add(const TimeOfDay(hour: 8, minute: 0));
      final meds = <MedDraft>[med];

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SetupStepMedication(
              meds: meds,
              saving: false,
              onAddMed: () {},
              onShowPresets: () {},
              onRemoveMed: (_) {},
              onBack: () {},
              onFinish: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1 个时间 chip 渲染 (08:00)
      expect(find.byType(InputChip), findsOneWidget);
      expect(find.text('08:00'), findsOneWidget);

      // 点 InputChip 的删除 icon (chip 内唯一 Icon)
      final deleteIcon = find.descendant(
        of: find.byType(InputChip),
        matching: find.byType(Icon),
      );
      expect(deleteIcon, findsOneWidget);
      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();

      expect(
        med.times,
        isEmpty,
        reason: '删除 chip 应调用 med.removeTimeAt (接线正确, 列表变空)',
      );
    });
  });
}
