// v0.30 round 95 (sub-spec 8 task 17): 用户档案 group
//
// 用户档案 / 提醒 / 数据 / 法律 4 group 之一。包含原 5 个 section / 卡:
//   - IAP Pro 卡 (FeatureFlags.iapEnabled gate)
//   - 药物 section (medsAsync.when 渲染 MedicationsListWidget)
//   - 通知自检卡 (NotificationStatusCard)
//   - 心理评估 section (AssessmentSection)
//   - 联系人 section (FeatureFlags.emergencyContactEnabled gate)
//
// 业务封装:
// - IAP 商业卡: 已购绿色 Pro / 未购 升级提示 (v0.27 R65 appstore P0-4)
// - Medication 列表: 走 medsAsync.when (data / loading / error 3 态)
// - NotificationStatusCard: 5 厂商 OEM 引导 + 测试通知
// - AssessmentSection: 评估历史 / 周期提醒 / 量表列表 / 关于 / 免责声明
// - Contact 列表: 走 contactsAsync.when, 失联通知业务暂停期 hidden
//
// 模式 (R95 task 1 ConsumerWidget 模式 + onXxx callback 注入点):
// - ConsumerWidget 自包含, 走 ref 自带 provider
// - 接受 onIapBuyTap / onMedRetry / onContactRetry 可选 callback (测试注入)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/data/feature_flags.dart';
import 'package:chroniccare/core/theme/app_colors.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/contact/contacts_list_widget.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/medications_list_widget.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/assessment_section.dart';
import 'package:chroniccare/presentation/providers/iap_provider.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/error_state.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/widgets/primary_button.dart';
import 'package:chroniccare/presentation/widgets/section_header.dart';

/// 用户档案 group — IAP + 药物 + 通知自检 + 心理评估 + 联系人
///
/// v0.30 round 95 (sub-spec 8 task 17): 4 group 之一, 包原 5 个 section / 卡。
///
/// 5 section 都已存在, 本 group 仅做拼装 + SectionHeader, 不重复业务逻辑。
class ProfileGroup extends ConsumerWidget {
  const ProfileGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final contactsAsync = ref.watch(contactsProvider);
    final medsAsync = ref.watch(medicationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // v0.30 R101: 用户头像/健康档案入口 (参照 Apple Health Profile)
        _UserProfileCard(l10n: l10n),

        const SizedBox(height: AppTokens.spacingMd),

        // === 升级到 Pro (IAP, v0.27 round 65 appstore P0-4) ===
        // 仅未购买时显示; 已购后隐藏 (避免反复提示)
        // v0.30 round 93 (阶段 2 audit-fixes): 整个 IAP 商业卡走
        // [FeatureFlags.iapEnabled] gate, 业务真接 App Store Connect productId 前
        // 完全 hidden (避 Apple 2.1 拒 — "未提供其他购买方式")。
        //
        // v0.32 round 13 (R112 EM-02/AH-04 视觉债): Card 改 AppleListSection
        if (FeatureFlags.iapEnabled) ...[
          Consumer(
            builder: (context, ref, _) {
              final isPro = ref.watch(iapProProvider);
              if (isPro) {
                // 已购: 走简短提示卡 (绿色 "已是 Pro" 状态)
                return AppleListSection(
                  margin: EdgeInsets.zero,
                  children: [
                    // v0.32 round 13: 透明 Material 包 ListTile, 防
                    // Flutter debug assert (ListTile 在 AppleListSection
                    // 白色 DecoratedBox 容器内 ink 不可见)
                    Material(
                      type: MaterialType.transparency,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.tintedSuccessSoft(context),
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusChip),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.workspace_premium,
                            color: AppColors.fgOnSuccess,
                          ),
                          title: Text(
                            l10n.settingsIapProOwnedTitle,
                            style: const TextStyle(
                              fontSize: AppTokens.fontSizeBody,
                              fontWeight: FontWeight.w600,
                              color: AppColors.fgOnSuccess,
                            ),
                          ),
                          subtitle: Text(
                            l10n.settingsIapProOwnedSubtitle,
                            style: const TextStyle(
                              fontSize: AppTokens.fontSizeCaption,
                              color: AppColors.fgOnSuccess,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              // 未购: 展示升级卡片
              return AppleListSection(
                margin: EdgeInsets.zero,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.workspace_premium,
                            color: AppColors.primaryColor(context),
                          ),
                          const SizedBox(width: AppTokens.spacingSm),
                          Expanded(
                            child: Text(
                              l10n.settingsIapUpgradeTitle,
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
                        l10n.settingsIapUpgradeSubtitle,
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
                                ? l10n.iapPurchaseSuccess
                                : l10n.iapPurchaseFailed,
                          );
                        },
                        child: Text(l10n.settingsIapUpgradeTitle),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppTokens.spacingMd),
        ] else
          const SizedBox.shrink(),

        // === 药物 ===
        // 注: MedicationsListWidget 内部 Card 属 medication feature
        // (跨 feature 不动), 本 section 保留 SectionHeader + 原 list,
        // 待 medication feature 自转 ALS 后无缝接入。
        SectionHeader(title: l10n.settingsMedication),
        const SizedBox(height: AppTokens.spacingSm),
        medsAsync.when(
          data: (meds) => MedicationsListWidget(meds: meds),
          loading: () => const LoadingSkeleton.fullScreen(),
          error: (e, _) => ErrorState(
            title: l10n.commonLoadFailed(e.toString()),
            detail: e.toString(),
            onRetry: () => ref.invalidate(medicationsProvider),
          ),
        ),
        const SizedBox(height: AppTokens.spacingMd),

        // === 心理评估 + 邮件预览 + 关于 ===
        // v0.28 R81 (emil design-5): chip 标签 (B 站风格)
        SectionHeader(
          title: l10n.settingsAssessment,
          chip: l10n.assessmentChipCurrent,
        ),
        const SizedBox(height: AppTokens.spacingSm),
        const AssessmentSection(),
        const SizedBox(height: AppTokens.spacingMd),

        // === 联系人 (2026-07-31 挪到最底部, 病耻感考量) ===
        // v0.30 round 93 (阶段 2 audit-fixes): 整个联系人 section
        // 走 [FeatureFlags.emergencyContactEnabled] gate, 失联通信业务暂停期间
        // 完全 hidden (setup step 1 仍可填, 由 setup wizard 独立 gate 控制)。
        if (FeatureFlags.emergencyContactEnabled) ...[
          SectionHeader(title: l10n.settingsContacts),
          const SizedBox(height: AppTokens.spacingSm),
          contactsAsync.when(
            data: (contacts) => ContactsListWidget(contacts: contacts),
            loading: () => const LoadingSkeleton.fullScreen(),
            error: (e, _) => ErrorState(
              title: l10n.commonLoadFailed(e.toString()),
              detail: e.toString(),
              onRetry: () => ref.invalidate(contactsProvider),
            ),
          ),
        ] else
          const SizedBox.shrink(),
      ],
    );
  }
}

/// 用户头像/健康档案入口卡 (参照 Apple Health Profile)
///
/// v0.32 round 13 (R112 EM-02/AH-04 视觉债): Card 改 AppleListSection
class _UserProfileCard extends StatelessWidget {
  const _UserProfileCard({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return AppleListSection(
      margin: EdgeInsets.zero,
      children: [
        Row(
          children: [
            // 头像
            CircleAvatar(
              radius: 28,
              backgroundColor:
                  AppTokens.primaryColor(context).withValues(alpha: 0.1),
              child: Icon(
                Icons.person,
                size: 32,
                color: AppTokens.primaryColor(context),
              ),
            ),
            const SizedBox(width: AppTokens.spacingMd),
            // 用户名 + 描述
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.settingsProfileTitle,
                    style: const TextStyle(
                      fontSize: AppTokens.fontSizeBody,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.settingsProfileSubtitle,
                    style: TextStyle(
                      fontSize: AppTokens.fontSizeCaption,
                      color: AppTokens.textHintColor(context),
                    ),
                  ),
                ],
              ),
            ),
            // v0.32 round 8 (R111 EM-17 fix): 删 chevron — 本卡是静态展示
            // (无 profile 路由可跳), chevron 假 affordance 误导可点
          ],
        ),
      ],
    );
  }
}
