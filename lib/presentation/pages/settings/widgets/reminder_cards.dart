// v0.22 round 35 (sp-en 重构): 抽 [reminder_cards.dart]
//
// 从 reminders_hub_page.dart (27KB) 拆出 4 个 _XxxReminderCard widget:
// - _ReminderCard (基础 widget)
// - _AssessmentReminderCard
// - _MedicationReminderCard
// - _RefillReminderCard
//
// emil 设计原则 3 "build cohesive experience" — 4 个 widget 都是 'icon + title
// + description + status chip + configure button' 模式, 抽 1 个 base + 3 个
// specific 保持视觉一致。
//
// 拆出后 reminders_hub_page.dart 从 28KB → ~15KB, 拆出的 widget 可独立测。
//
// 1.1.0 round 4f: SafetyReminderCard (失联通知卡) 整摘 — 失联通信业务暂停定版,
// 0 renderer 死代码。reminderHubSafety* ARB key 随之清理。
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';

/// 心理评估提醒卡片
class AssessmentReminderCard extends StatelessWidget {
  final bool? enabled;
  final int? days;
  final VoidCallback onConfigure;
  const AssessmentReminderCard({
    super.key,
    required this.enabled,
    required this.days,
    required this.onConfigure,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLoading = enabled == null;
    final isEnabled = enabled ?? false;
    final d = days ?? 14;
    return ReminderCard(
      icon: Icons.psychology_outlined,
      title: l10n.reminderHubAssessmentTitle,
      description: isLoading
          ? l10n.commonLoading
          : isEnabled
              ? l10n.reminderHubAssessmentDescEnabled(d)
              : l10n.reminderHubAssessmentDescDisabled,
      statusText: isLoading
          ? ''
          : isEnabled
              ? l10n.reminderHubAssessmentStatusEnabled(d)
              : l10n.reminderHubStatusDisabled,
      statusActive: isEnabled,
      actionLabel: l10n.reminderHubConfigure,
      onAction: isLoading ? null : onConfigure,
    );
  }
}

/// 通用提醒卡片 (基础 widget)
class ReminderCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String statusText;
  final bool statusActive;
  final String actionLabel;
  final VoidCallback? onAction;

  const ReminderCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.statusText,
    required this.statusActive,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    // v0.32 round 13 (R112 EM-02/AH-04 视觉债): Card 容器改
    // AppleListSection (iOS insetGrouped 风格, spec §4.5),
    // 内部 icon + title + status chip + description + action 布局原样保留
    return AppleListSection(
      margin: EdgeInsets.zero,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: AppTokens.avatarSizeMd,
              height: AppTokens.avatarSizeMd,
              decoration: BoxDecoration(
                color: statusActive
                    ? AppTokens.primaryLightColor(context)
                    : AppTokens.dividerColor(context),
                borderRadius: BorderRadius.circular(AppTokens.radiusChip),
              ),
              child:
                  Icon(icon, color: AppTokens.primaryColor(context), size: 22),
            ),
            const SizedBox(width: AppTokens.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: AppTokens.fontSizeBody,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (statusText.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.spacingXs,
                            vertical: AppTokens.spacingXxxs,
                          ),
                          decoration: BoxDecoration(
                            color: statusActive
                                ? AppTokens.tintedPrimarySoft(context)
                                : AppTokens.dividerColor(context),
                            borderRadius:
                                BorderRadius.circular(AppTokens.radiusChip),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: AppTokens.fontSizeCaption,
                              color: statusActive
                                  ? AppTokens.primaryColor(context)
                                  : AppTokens.textHintColor(context),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.spacingXxs),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: AppTokens.fontSizeCaption,
                      color: AppTokens.textSecondaryColor(context),
                    ),
                  ),
                  if (onAction != null && actionLabel.isNotEmpty) ...[
                    const SizedBox(height: AppTokens.spacingSm),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: onAction,
                        icon: const Icon(
                          Icons.tune,
                          size: AppTokens.iconSizeInline,
                        ),
                        label: Text(actionLabel),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 用药提醒卡片
class MedicationReminderCard extends StatelessWidget {
  final List<MedicationEntity> meds;
  const MedicationReminderCard({super.key, required this.meds});

  @override
  Widget build(BuildContext context) {
    final activeMeds = meds.where((m) => m.isInUse).toList();
    final totalTimes =
        activeMeds.fold<int>(0, (sum, m) => sum + m.times.length);
    final active = activeMeds.isNotEmpty;

    return ReminderCard(
      icon: Icons.medication_outlined,
      title: AppLocalizations.of(context).reminderHubMedicationTitle,
      description: active
          ? AppLocalizations.of(context)
              .reminderHubMedicationDescActive(activeMeds.length, totalTimes)
          : AppLocalizations.of(context).reminderHubMedicationDescInactive,
      statusText: active
          ? AppLocalizations.of(context)
              .reminderHubMedicationStatusActive(activeMeds.length, totalTimes)
          : AppLocalizations.of(context).reminderHubStatusNotConfigured,
      statusActive: active,
      actionLabel: AppLocalizations.of(context).reminderHubManageMedication,
      onAction: () => context.push('/settings'),
    );
  }
}

/// 续方提醒卡片
class RefillReminderCard extends StatelessWidget {
  final List<MedicationEntity> meds;
  const RefillReminderCard({super.key, required this.meds});

  @override
  Widget build(BuildContext context) {
    final withRefill = meds.where((m) => m.hasRefill && m.isInUse).toList();
    final overdue = withRefill.where((m) => m.isRefillOverdue()).toList();
    final inWindow = withRefill
        .where((m) => m.isInRefillWindow() && !m.isRefillOverdue())
        .toList();
    final active = withRefill.isNotEmpty;

    String description;
    if (!active) {
      description = AppLocalizations.of(context).reminderHubRefillDescNone;
    } else if (overdue.isNotEmpty) {
      description = AppLocalizations.of(context)
          .reminderHubRefillDescOverdue(overdue.length, inWindow.length);
    } else {
      description = AppLocalizations.of(context)
          .reminderHubRefillDescActive(withRefill.length);
    }

    return ReminderCard(
      icon: Icons.shopping_cart_outlined,
      title: AppLocalizations.of(context).reminderHubRefillTitle,
      description: description,
      statusText: active
          ? overdue.isNotEmpty
              ? AppLocalizations.of(context)
                  .reminderHubRefillStatusOverdue(overdue.length)
              : inWindow.isNotEmpty
                  ? AppLocalizations.of(context)
                      .reminderHubRefillStatusInWindow(inWindow.length)
                  : AppLocalizations.of(context)
                      .reminderHubRefillStatusActive(withRefill.length)
          : AppLocalizations.of(context).reminderHubStatusNotConfigured,
      statusActive: active,
      actionLabel: AppLocalizations.of(context).reminderHubManageRefill,
      onAction: () => context.push('/settings/refills'),
    );
  }
}
