import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/widgets/error_state.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/widgets/section_header.dart';
import 'package:chroniccare/presentation/pages/contact/contacts_list_widget.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/medications_list_widget.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/notification_status_card.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/reminders_section.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/legal_section.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/data_management_section.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/assessment_section.dart';

/// 设置页
///
/// v0.23 P1 refactor: 从 713 行瘦身到 ~80 行。
/// 6 个 section widgets 已提取到 settings/widgets/:
///   - RemindersSection (提醒中心 + 续方管理)
///   - LegalSection (法律与隐私)
///   - DataManagementSection (导出/报告/历史/导入/清空)
///   - AssessmentSection (评估历史/周期提醒/量表列表/邮件预览/关于)
///   - NotificationStatusCard (通知自检, 原已存在)
///   - ContactsListWidget / MedicationsListWidget (联系人/药物, 原已存在)
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsProvider);
    final medsAsync = ref.watch(medicationsProvider);

    return PageScaffold(
      title: AppLocalizations.of(context).settingsTitle,
      child: ListView(
        children: [
          const SizedBox(height: AppTokens.spacingMd),

          // === 联系人 ===
          SectionHeader(title: AppLocalizations.of(context).settingsContacts),
          const SizedBox(height: AppTokens.spacingSm),
          contactsAsync.when(
            data: (contacts) => ContactsListWidget(contacts: contacts),
            loading: () => const LoadingSkeleton.fullScreen(),
            error: (e, _) => ErrorState(
              title: AppLocalizations.of(context).commonLoadFailed(''),
              detail: e.toString(),
              onRetry: () => ref.invalidate(contactsProvider),
            ),
          ),

          const SizedBox(height: AppTokens.spacingLg),

          // === 药物 ===
          SectionHeader(
            title: AppLocalizations.of(context).settingsMedication,
          ),
          const SizedBox(height: AppTokens.spacingSm),
          medsAsync.when(
            data: (meds) => MedicationsListWidget(meds: meds),
            loading: () => const LoadingSkeleton.fullScreen(),
            error: (e, _) => ErrorState(
              title: AppLocalizations.of(context).commonLoadFailed(''),
              detail: e.toString(),
              onRetry: () => ref.invalidate(medicationsProvider),
            ),
          ),

          const SizedBox(height: AppTokens.spacingLg),

          // === 数据管理 ===
          SectionHeader(
            title: AppLocalizations.of(context).settingsDataManagement,
          ),
          const SizedBox(height: AppTokens.spacingSm),
          const DataManagementSection(),

          const SizedBox(height: AppTokens.spacingLg),

          // === 法律与隐私 ===
          SectionHeader(
            title: AppLocalizations.of(context).settingsLegalAndPrivacy,
          ),
          const SizedBox(height: AppTokens.spacingSm),
          const LegalSection(),

          const SizedBox(height: AppTokens.spacingLg),

          // === 提醒 ===
          SectionHeader(title: AppLocalizations.of(context).settingsReminders),
          const SizedBox(height: AppTokens.spacingSm),
          const RemindersSection(),

          const SizedBox(height: AppTokens.spacingLg),

          // 通知自检卡
          const NotificationStatusCard(),

          const SizedBox(height: AppTokens.spacingLg),

          // === 心理评估 + 邮件预览 + 关于 ===
          SectionHeader(
            title: AppLocalizations.of(context).settingsAssessment,
          ),
          const SizedBox(height: AppTokens.spacingSm),
          const AssessmentSection(),

          const SizedBox(height: AppTokens.spacingMd),
        ],
      ),
    );
  }
}
