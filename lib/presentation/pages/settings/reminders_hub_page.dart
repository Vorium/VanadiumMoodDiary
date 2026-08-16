// v1.1.0 R116 (god class 拆): 提醒中心主壳
//
// 历史:
// - v0.14 (Round 12C) 提醒中心: 4 大类提醒 (打卡/用药/续方/评估) + 失联 (R4 摘)
// - v0.23 (Round 41 spen P3-35): 改用 FutureProvider 替代 setState 模式
// - v1.1.0 R116: 312L god class → 主壳 + 4 reminder card 走 widgets/
//   - 本文件: 主壳 PageScaffold + ListView 4 card 拼装 + 评估 sheet 唤起
//   - lib/presentation/pages/settings/widgets/reminder_cards.dart:
//     ReminderCard / MedicationReminderCard / RefillReminderCard /
//     AssessmentReminderCard (R95 既有拆分, 维持)
//   - lib/presentation/pages/settings/widgets/assessment_reminder_sheet.dart
//     (R116 新拆): AssessmentReminderSheet BottomSheet (stateful widget)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/assessment_reminder_sheet.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/reminder_cards.dart';
import 'package:chroniccare/presentation/providers/reminders_hub_provider.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/info_banner.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';

/// 提醒中心
///
/// v1.1.0 R116 god class 拆: 主壳 0 业务方法, 仅 PageScaffold + ListView
/// 4 card 拼装 + AssessmentReminderSheet 唤起。所有 widget 都已抽到
/// widgets/ (reminder_cards.dart 既有 + assessment_reminder_sheet.dart 新)。
class RemindersHubPage extends ConsumerStatefulWidget {
  const RemindersHubPage({super.key});

  @override
  ConsumerState<RemindersHubPage> createState() => _RemindersHubPageState();
}

class _RemindersHubPageState extends ConsumerState<RemindersHubPage> {
  @override
  Widget build(BuildContext context) {
    final medsAsync = ref.watch(medicationsProvider);
    final configAsync = ref.watch(remindersHubConfigProvider);
    return PageScaffold(
      title: AppLocalizations.of(context).settingsReminderCenter,
      child: ListView(
        children: [
          const SizedBox(height: AppTokens.spacingMd),

          // 顶部说明 — v0.27 round 67 (C-2): InfoBanner 集中器
          InfoBanner(
            icon: Icons.notifications_active_outlined,
            text: AppLocalizations.of(context).reminderHubDescription,
          ),

          const SizedBox(height: AppTokens.spacingMd),

          // 1. 每日打卡提醒 (R95 拆: ReminderCard 走 reminder_cards.dart)
          ReminderCard(
            icon: Icons.check_circle_outline,
            title: AppLocalizations.of(context).reminderHubDailyTitle,
            description: AppLocalizations.of(context).reminderHubDailyDesc,
            statusText: AppLocalizations.of(context).reminderHubDailyStatus,
            statusActive: true,
            actionLabel: '',
            onAction: null,
          ),

          const SizedBox(height: AppTokens.spacingMd),

          // 2. 用药提醒
          _medicationReminderSection(context, medsAsync),

          const SizedBox(height: AppTokens.spacingMd),

          // 3. 续方提醒
          _refillReminderSection(context, medsAsync),

          const SizedBox(height: AppTokens.spacingMd),

          // 4. 心理评估提醒
          _assessmentReminderSection(context, configAsync),

          const SizedBox(height: AppTokens.spacingMd),
        ],
      ),
    );
  }

  /// 2. 用药提醒段 (loading/error/data 3 态)
  Widget _medicationReminderSection(
    BuildContext context,
    AsyncValue<List<MedicationEntity>> medsAsync,
  ) {
    final loc = AppLocalizations.of(context);
    return medsAsync.when(
      data: (meds) => MedicationReminderCard(meds: meds),
      loading: () => _placeholderCard(
        context,
        icon: Icons.medication_outlined,
        title: loc.reminderHubMedicationTitle,
        description: loc.commonLoading,
      ),
      error: (e, _) => _errorCard(
        context,
        icon: Icons.medication_outlined,
        title: loc.reminderHubMedicationTitle,
        error: e,
      ),
    );
  }

  /// 3. 续方提醒段
  Widget _refillReminderSection(
    BuildContext context,
    AsyncValue<List<MedicationEntity>> medsAsync,
  ) {
    final loc = AppLocalizations.of(context);
    return medsAsync.when(
      data: (meds) => RefillReminderCard(meds: meds),
      loading: () => _placeholderCard(
        context,
        icon: Icons.shopping_cart_outlined,
        title: loc.reminderHubRefillTitle,
        description: loc.commonLoading,
      ),
      error: (e, _) => _errorCard(
        context,
        icon: Icons.shopping_cart_outlined,
        title: loc.reminderHubRefillTitle,
        error: e,
      ),
    );
  }

  /// 4. 心理评估提醒段
  Widget _assessmentReminderSection(
    BuildContext context,
    AsyncValue<RemindersHubConfig> configAsync,
  ) {
    return AssessmentReminderCard(
      enabled: _configOrFallback(configAsync).assessmentEnabled,
      days: _configOrFallback(configAsync).assessmentDays,
      onConfigure: () => _showAssessmentSettings(context),
    );
  }

  /// 占位 card (loading 态)
  Widget _placeholderCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return ReminderCard(
      icon: icon,
      title: title,
      description: description,
      statusText: '',
      statusActive: false,
      actionLabel: '',
      onAction: null,
    );
  }

  /// 错误 card (error 态)
  Widget _errorCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Object error,
  }) {
    final loc = AppLocalizations.of(context);
    return ReminderCard(
      icon: icon,
      title: title,
      description: loc.commonLoadFailed(error.toString()),
      statusText: loc.reminderHubStatusError,
      statusActive: false,
      actionLabel: '',
      onAction: null,
    );
  }

  void _showAssessmentSettings(BuildContext context) {
    // v0.23 round 41 (spen P3-35): 显式取一次 configAsync, 闭包内不再依赖 build scope
    final configAsync = ref.read(remindersHubConfigProvider);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final c = _configOrFallback(configAsync);
        return AssessmentReminderSheet(
          initialEnabled: c.assessmentEnabled,
          initialDays: c.assessmentDays,
          onSaved: () => ref.invalidate(remindersHubConfigProvider),
        );
      },
    );
  }

  /// configAsync 没加载完时给 fallback 默认值, 加载完用真实值
  ///
  /// v0.23 round 41 (spen P3-35): 替代之前 4 个 nullable 字段 + setState
  RemindersHubConfig _configOrFallback(AsyncValue<RemindersHubConfig> async) {
    return async.maybeWhen(
      data: (c) => c,
      orElse: () => const RemindersHubConfig(
        assessmentEnabled: false,
        assessmentDays: 14,
      ),
    );
  }
}
