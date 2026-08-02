import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_colors.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/widgets/error_state.dart';
import 'package:chroniccare/presentation/providers/iap_provider.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/widgets/primary_button.dart';
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

          // 2026-07-31 联系人软隐藏: 联系人 section 已挪到**最底部**
          // (有用户反馈"病耻感", 不希望一进设置就看到联系人相关 UI)。
          // 联系人相关业务 (失联通知) 整体已用 [FeatureFlags.emergencyContactEnabled]
          // 暂停,数据模型/repository 全部保留,后续要启用零成本。

          // === 升级到 Pro (IAP, v0.27 round 65 appstore P0-4) ===
          // 仅未购买时显示; 已购后隐藏 (避免反复提示)
          Consumer(
            builder: (context, ref, _) {
              final isPro = ref.watch(iapProProvider);
              if (isPro) {
                // 已购: 走简短提示卡 (绿色 "已是 Pro" 状态)
                return Card(
                  color: AppColors.tintedSuccessSoft(context),
                  child: ListTile(
                    // R69 (CC-9 emil P0 修复): 用 fgOnSuccess 替代裸 success,
                    // 语义化("success 前景色"), 未来 success 改色时 fgOnSuccess 自动跟
                    leading: const Icon(
                      Icons.workspace_premium,
                      color: AppColors.fgOnSuccess,
                    ),
                    title: Text(
                      AppLocalizations.of(context).settingsIapProOwnedTitle,
                      style: const TextStyle(
                        fontSize: AppTokens.fontSizeBody,
                        fontWeight: FontWeight.w600,
                        color: AppColors.fgOnSuccess,
                      ),
                    ),
                    subtitle: Text(
                      AppLocalizations.of(context).settingsIapProOwnedSubtitle,
                      style: const TextStyle(
                        fontSize: AppTokens.fontSizeCaption,
                        color: AppColors.fgOnSuccess,
                      ),
                    ),
                  ),
                );
              }
              // 未购: 展示升级卡片
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.spacingMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          // R69 (CC-9 emil P0 修复): 改 theme-aware 集中器,
                          // dark mode 下 primary 自动反白
                          Icon(
                            Icons.workspace_premium,
                            color: AppColors.primaryColor(context),
                          ),
                          const SizedBox(width: AppTokens.spacingSm),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)
                                  .settingsIapUpgradeTitle,
                              style: TextStyle(
                                fontSize: AppTokens.fontSizeTitle,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimaryColor(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTokens.spacingSm),
                      Text(
                        AppLocalizations.of(context).settingsIapUpgradeSubtitle,
                        style: TextStyle(
                          fontSize: AppTokens.fontSizeBody,
                          color: AppColors.textSecondaryColor(context),
                        ),
                      ),
                      const SizedBox(height: AppTokens.spacingMd),
                      PrimaryButton(
                        onPressed: () async {
                          final buy = ref.read(buyLifetimeProvider);
                          final ok = await buy();
                          if (!context.mounted) return;
                          AppSnackBar.showInfo(
                            context,
                            ok
                                ? AppLocalizations.of(context)
                                    .iapPurchaseSuccess
                                : AppLocalizations.of(context)
                                    .iapPurchaseFailed,
                          );
                        },
                        child: Text(
                          AppLocalizations.of(context).settingsIapUpgradeTitle,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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
            // v0.27 round 77 (R76-N8 修): commonLoadFailed 传 e.toString()
            error: (e, _) => ErrorState(
              title:
                  AppLocalizations.of(context).commonLoadFailed(e.toString()),
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
          // v0.28 R81 (emil design-5): chip 标签 (B 站风格)
          SectionHeader(
            title: AppLocalizations.of(context).settingsAssessment,
            chip: AppLocalizations.of(context).assessmentChipCurrent,
          ),
          const SizedBox(height: AppTokens.spacingSm),
          const AssessmentSection(),

          const SizedBox(height: AppTokens.spacingLg),

          // === 联系人 (2026-07-31 挪到最底部, 病耻感考量) ===
          // 跟其他 section 一样仍可访问, 但不在用户进入设置时第一眼看到。
          // 联系人 section 内的 "添加联系人" 仍会触发 ConsentDialog (PIPL §13),
          // 业务跑 [FeatureFlags.emergencyContactEnabled] gate 后整个失联通信
          // 链路不会发出去。
          SectionHeader(title: AppLocalizations.of(context).settingsContacts),
          const SizedBox(height: AppTokens.spacingSm),
          contactsAsync.when(
            data: (contacts) => ContactsListWidget(contacts: contacts),
            loading: () => const LoadingSkeleton.fullScreen(),
            // v0.27 round 77 (R76-N8 修): commonLoadFailed 传 e.toString()
            error: (e, _) => ErrorState(
              title:
                  AppLocalizations.of(context).commonLoadFailed(e.toString()),
              detail: e.toString(),
              onRetry: () => ref.invalidate(contactsProvider),
            ),
          ),

          const SizedBox(height: AppTokens.spacingMd),
        ],
      ),
    );
  }
}
