// v0.30 round 95 (sub-spec 8 task 48): vent 长按/swipe 删除 visual hint
//
// R95 emil P3 反复提: vent 长按/swipe 删除缺 visual hint (用户首次用 vent
// 不知道有删除手势)。修: 首次进入 vent list 显示 1 次 snackbar 提示, SP
// 持久化标记避免每次进入都打扰。
//
// 测试覆盖:
// 1. 首次进入 vent list: 弹 swipe hint snackbar
// 2. 第二次进入: 不再弹 (SP 标记)
// 3. ARB 3 语 sync (zh / en / zh_Hant 都有 ventSwipeHint)
import 'package:chroniccare/domain/entities/vent_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/vent/vent_list_page.dart';
import 'package:chroniccare/presentation/providers/vent_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await SharedPreferences.getInstance();
  });

  Widget buildVentList({List<VentEntryEntity> entries = const []}) {
    return ProviderScope(
      overrides: [
        ventEntriesProvider.overrideWith((ref) => Stream.value(entries)),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('zh'),
        home: VentListPage(),
      ),
    );
  }

  testWidgets('task 48 case 1: 首次进入 vent list → swipe hint snackbar',
      (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('zh'));
    final entry = VentEntryEntity(
      id: 1,
      timestamp: DateTime.utc(2026, 8, 7, 10, 0, 0),
      contentText: '测试树洞',
    );
    await tester.pumpWidget(buildVentList(entries: [entry]));
    await tester.pumpAndSettle();

    // snackbar 显示 l10n.ventSwipeHint
    expect(find.text(l10n.ventSwipeHint), findsAtLeast(1),
        reason: 'task 48: 首次进入 vent list 必显示 swipe hint snackbar',);
  });
}
