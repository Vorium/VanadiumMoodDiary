// v0.24 (Round 45): settings_page widget 单测
//
// 之前 v0.22 round 30 P1-38 标的"settings 整片 0 widget 测"残留 2 周。
// v0.24 round 45 (Sprint #6 中段 3 page 0 widget 测补齐之二) 补 3 个 case:
//
// 1. contacts error → 渲染 ErrorState (loading + error 状态切换)
// 2. contacts data 空 + meds data 空 → 6 section widget 全部渲染
// 3. contacts data 1 → ContactsListWidget 渲染 + name 显示
//
// 测试 setup:
// - MaterialApp + AppLocalizations.localizationsDelegates
// - ProviderScope overrides mock Stream<List> provider
// - 测 contacts/meds 状态切换, 不测 6 个 section widget 内部逻辑 (各自有测)
//
// v0.24 Sprint #5 (mood_dialog 拆解) 后 settings_page 99 行只剩 section 拼接,
// 每个 section 在 settings/widgets/ 独立测, 测 main page 容器逻辑 ROI 最高
import 'package:chroniccare/domain/entities/contact_entity.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/contact/contacts_list_widget.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/medications_list_widget.dart';
import 'package:chroniccare/presentation/pages/settings/settings_page.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/assessment_section.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/data_management_section.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/legal_section.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/notification_status_card.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/reminders_section.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // helper: 构造测试 widget
  Widget buildSettingsPage({
    List<ContactEntity> contacts = const [],
    List<MedicationEntity> meds = const [],
    bool contactsError = false,
  }) {
    return ProviderScope(
      overrides: [
        contactsProvider.overrideWith((ref) {
          if (contactsError) {
            return Stream.error(Exception('test error'));
          }
          return Stream.value(contacts);
        }),
        medicationsProvider.overrideWith((ref) => Stream.value(meds)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: const SettingsPage(),
      ),
    );
  }

  testWidgets('contacts error → 显示 ErrorState', (tester) async {
    await tester.pumpWidget(buildSettingsPage(contactsError: true));
    await tester.pumpAndSettle();

    // ErrorState 集中器显示 (v0.22 round 29 emil-44)
    expect(find.byType(ErrorState), findsOneWidget);
  });

  testWidgets('contacts + meds 都空 → 6 个 section widget 全部渲染',
      (tester) async {
    await tester.pumpWidget(buildSettingsPage());
    await tester.pumpAndSettle();

    // ListView 内 section 默认只渲染 viewport 内, 用 scrollUntilVisible
    // 把每个 section scroll 出来验证渲染
    await tester.scrollUntilVisible(
        find.byType(DataManagementSection), 100);
    expect(find.byType(DataManagementSection), findsOneWidget);

    await tester.scrollUntilVisible(find.byType(LegalSection), 100);
    expect(find.byType(LegalSection), findsOneWidget);

    await tester.scrollUntilVisible(find.byType(RemindersSection), 100);
    expect(find.byType(RemindersSection), findsOneWidget);

    await tester.scrollUntilVisible(
        find.byType(NotificationStatusCard), 100);
    expect(find.byType(NotificationStatusCard), findsOneWidget);

    await tester.scrollUntilVisible(find.byType(AssessmentSection), 100);
    expect(find.byType(AssessmentSection), findsOneWidget);
  });

  testWidgets('contacts data 1 → ContactsListWidget 渲染 + name 显示',
      (tester) async {
    const contact = ContactEntity(
      id: 1,
      name: '张三',
      phone: '13800000001',
      sortOrder: 0,
      isActive: true,
    );
    await tester.pumpWidget(buildSettingsPage(contacts: [contact]));
    await tester.pumpAndSettle();

    // contacts 1 → ContactsListWidget 渲染 + name 显示
    expect(find.byType(ContactsListWidget), findsOneWidget);
    expect(find.text('张三'), findsOneWidget);

    // meds 0 → MedicationsListWidget 渲染 (EmptyState 模式)
    expect(find.byType(MedicationsListWidget), findsOneWidget);
  });
}
