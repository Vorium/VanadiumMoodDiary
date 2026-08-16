// v1.1.0 R114 (BUG 8): home deep link 提示显示药名而非裸数据库 id
//
// 修前: showMedicationHint 直接 `homeMedHint(medId)` → 用户看到
// "💊 准备打卡药物 #5" 裸 id (autofire 路径已从 provider 解析药名,
// showHint 路径漏)。ARB key homeMedHint 参数从 int id 改 String name
// (3 语)。
//
// 修法: 从 medicationsProvider 缓存查名, 查不到 fallback
// homeAutofireFallbackName (通用名), 不再泄漏内部 id。
//
// 覆盖:
// 1. 药名可查 → snackbar 显示药名 (不含 "#42")
// 2. 药名不可查 (provider 空) → fallback 通用名 (不含 "#42")
import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/home/controllers/home_deep_link_handler.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

MedicationEntity _med({int id = 42, String name = '舍曲林'}) {
  return MedicationEntity(
    id: id,
    name: name,
    dosage: 50,
    dosageUnit: DosageUnit.mg,
    times: const [HourMinute(hour: 8, minute: 0)],
    startDate: DateTime(2026, 1, 1),
    isActive: true,
    refillAt: null,
    refillReminderDays: 7,
  );
}

Widget wrap(List<MedicationEntity> meds) {
  return ProviderScope(
    overrides: [
      medicationsProvider.overrideWith(
        (ref) => Stream.value(meds),
      ),
    ],
    child: MaterialApp(
      theme: ThemeData.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Scaffold(
        body: Consumer(
          builder: (context, ref, _) {
            // 生产环境 home_page 会 watch medicationsProvider (缓存保活,
            // handler 读 .value 依赖此前提)。测试 harness 对齐生产行为。
            ref.watch(medicationsProvider);
            final handler = HomeDeepLinkHandler(ref);
            return Builder(
              builder: (ctx) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () => handler.showMedicationHint(42, ctx),
                    child: const Text('trigger-hint'),
                  ),
                );
              },
            );
          },
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('R114 BUG 8: 药名可查 → snackbar 显示药名 (无裸 id)', (tester) async {
    await tester.pumpWidget(wrap([_med()]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('trigger-hint'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));

    expect(
      find.textContaining('舍曲林'),
      findsOneWidget,
      reason: '提示应显示药名',
    );
    expect(
      find.textContaining('#42'),
      findsNothing,
      reason: '修前显示裸数据库 id "#42" (R114 BUG 8)',
    );

    // 排空 info snackbar 2s 计时器, 避免 test 结束 pending timer
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('R114 BUG 8: 药名不可查 → fallback 通用名 (无裸 id)', (tester) async {
    await tester.pumpWidget(wrap(const []));
    await tester.pumpAndSettle();

    await tester.tap(find.text('trigger-hint'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));

    expect(
      find.textContaining('该药'),
      findsOneWidget,
      reason: 'provider 查不到药名应 fallback homeAutofireFallbackName',
    );
    expect(
      find.textContaining('#42'),
      findsNothing,
      reason: 'fallback 也不应泄漏裸 id',
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
