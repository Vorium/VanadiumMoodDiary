// v0.14 (Round 12C) 提醒中心 — 集中查看/管理所有类型的提醒
//
// 之前散落在各处的设置（notification / assessment）整合到一个页面
//
// 四大类提醒：
// 1. 每日打卡提醒（notification_service.scheduleDailyReminder，固定 20:00）
// 2. 用药提醒（notification_service - 每个 medication 的每个 time）
// 3. 续方提醒（medication.refillAt - refillReminderDays）
// 4. 心理评估提醒（AssessmentReminderService）
//
// 1.1.0 round 4: 第 5 类"失联通知"（SafetyWatchService）整摘 —
// 失联通信业务暂停定版。

import 'package:chroniccare/presentation/providers/service_providers.dart';
import 'package:chroniccare/presentation/providers/reminders_hub_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/choice_chip_wrap.dart';
import 'package:chroniccare/presentation/widgets/info_banner.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/reminder_cards.dart';
import 'package:chroniccare/presentation/widgets/primary_button.dart';

/// 提醒中心
class RemindersHubPage extends ConsumerStatefulWidget {
  const RemindersHubPage({super.key});

  @override
  ConsumerState<RemindersHubPage> createState() => _RemindersHubPageState();
}

class _RemindersHubPageState extends ConsumerState<RemindersHubPage> {
  // v0.23 round 41 (spen P3-35): 改用 FutureProvider 替代 setState 模式
  // 之前 4 个 nullable 字段 + initState _load + setState 异步填充
  // 模式落后了。v0.17 round 7 用 calendarWindowProvider FutureProvider
  // 改成 watch remindersHubConfigProvider,异步值自动 rebuild
  @override
  Widget build(BuildContext context) {
    final medsAsync = ref.watch(medicationsProvider);
    final configAsync = ref.watch(remindersHubConfigProvider);
    return PageScaffold(
      title: AppLocalizations.of(context).settingsReminderCenter,
      child: ListView(
        children: [
          const SizedBox(height: AppTokens.spacingMd),

          // 顶部说明
          // v0.27 round 67 (C-2): 用 InfoBanner 集中器
          InfoBanner(
            icon: Icons.notifications_active_outlined,
            text: AppLocalizations.of(context).reminderHubDescription,
          ),

          const SizedBox(height: AppTokens.spacingMd),

          // 1. 每日打卡提醒
          // v0.30 round 95 (sub-spec 2 task 10): 删 /email-preview 路由
          // (失联是 SMS 不是 email, R93 业务暂停后真无用), onAction 改 null
          // 按钮置灰, 业务上线 (EmailServiceEnabled flag 翻 true) 时再恢复。
          // actionLabel 也改空字符串避免 linter 警告 + 跟其他 card 风格一致。
          ReminderCard(
            icon: Icons.check_circle_outline,
            title: AppLocalizations.of(context).reminderHubDailyTitle,
            description: AppLocalizations.of(context).reminderHubDailyDesc,
            statusText: AppLocalizations.of(context).reminderHubDailyStatus,
            statusActive: true,
            actionLabel: '',
            onAction: null,
          ),

          // v0.32 round 13 (R112 EM-02/AH-04): spacingSm -> spacingMd
          // (跟 home AppleListSection 章节间距 16 一致, spec §5.1)
          const SizedBox(height: AppTokens.spacingMd),

          // 2. 用药提醒
          medsAsync.when(
            data: (meds) => MedicationReminderCard(meds: meds),
            loading: () => ReminderCard(
              icon: Icons.medication_outlined,
              title: AppLocalizations.of(context).reminderHubMedicationTitle,
              description: AppLocalizations.of(context).commonLoading,
              statusText: '',
              statusActive: false,
              actionLabel: '',
              onAction: null,
            ),
            error: (e, _) => ReminderCard(
              icon: Icons.medication_outlined,
              title: AppLocalizations.of(context).reminderHubMedicationTitle,
              description:
                  AppLocalizations.of(context).commonLoadFailed(e.toString()),
              statusText: AppLocalizations.of(context).reminderHubStatusError,
              statusActive: false,
              actionLabel: '',
              onAction: null,
            ),
          ),

          const SizedBox(height: AppTokens.spacingMd),

          // 3. 续方提醒
          medsAsync.when(
            data: (meds) => RefillReminderCard(meds: meds),
            loading: () => ReminderCard(
              icon: Icons.shopping_cart_outlined,
              title: AppLocalizations.of(context).reminderHubRefillTitle,
              description: AppLocalizations.of(context).commonLoading,
              statusText: '',
              statusActive: false,
              actionLabel: '',
              onAction: null,
            ),
            error: (e, _) => ReminderCard(
              icon: Icons.shopping_cart_outlined,
              title: AppLocalizations.of(context).reminderHubRefillTitle,
              description:
                  AppLocalizations.of(context).commonLoadFailed(e.toString()),
              statusText: AppLocalizations.of(context).reminderHubStatusError,
              statusActive: false,
              actionLabel: '',
              onAction: null,
            ),
          ),

          const SizedBox(height: AppTokens.spacingMd),

          // 4. 心理评估提醒
          // v0.23 round 41 (spen P3-35): 显式传 configAsync 进 _buildAssessmentCard
          _buildAssessmentCard(context, configAsync),

          const SizedBox(height: AppTokens.spacingMd),
        ],
      ),
    );
  }

  void _showAssessmentSettings(BuildContext context) {
    // v0.23 round 41 (spen P3-35): 显式取一次 configAsync,闭包内不再依赖 build scope
    final configAsync = ref.read(remindersHubConfigProvider);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final c = _configOrFallback(configAsync);
        return _AssessmentReminderSheet(
          initialEnabled: c.assessmentEnabled,
          initialDays: c.assessmentDays,
          onSaved: () => ref.invalidate(remindersHubConfigProvider),
        );
      },
    );
  }

  Widget _buildAssessmentCard(
    BuildContext context,
    AsyncValue<RemindersHubConfig> configAsync,
  ) {
    // v0.23 round 41 (spen P3-35): 用 configAsync 替代本地 nullable 字段
    return AssessmentReminderCard(
      enabled: _configOrFallback(configAsync).assessmentEnabled,
      days: _configOrFallback(configAsync).assessmentDays,
      onConfigure: () => _showAssessmentSettings(context),
    );
  }

  /// configAsync 没加载完时给 fallback 默认值,加载完用真实值
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

/// 评估提醒设置 sheet
class _AssessmentReminderSheet extends ConsumerStatefulWidget {
  final bool initialEnabled;
  final int initialDays;
  final VoidCallback onSaved;
  const _AssessmentReminderSheet({
    required this.initialEnabled,
    required this.initialDays,
    required this.onSaved,
  });

  @override
  ConsumerState<_AssessmentReminderSheet> createState() =>
      _AssessmentReminderSheetState();
}

class _AssessmentReminderSheetState
    extends ConsumerState<_AssessmentReminderSheet> {
  late bool _enabled;
  late int _days;
  bool _busy = false;

  static const _options = [7, 14, 30, 60, 90];

  @override
  void initState() {
    super.initState();
    _enabled = widget.initialEnabled;
    _days = widget.initialDays;
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final service = ref.read(assessmentReminderServiceProvider);
      await service.setEnabled(_enabled);
      if (_enabled) {
        await service.setDays(_days);
      }
      await service.onSettingsChanged();
      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          action: AppLocalizations.of(context).commonSave,
          error: e,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: AppTokens.edgeInsetsMd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              loc.reminderHubAssessmentTitle,
              style: const TextStyle(
                fontSize: AppTokens.fontSizeTitle,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTokens.spacingMd),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(loc.reminderHubEnable),
              subtitle: Text(loc.reminderHubAssessmentSubtitle),
              value: _enabled,
              onChanged: _busy ? null : (v) => setState(() => _enabled = v),
            ),
            if (_enabled) ...[
              const Divider(),
              Text(
                loc.reminderHubInterval,
                style: const TextStyle(
                  fontSize: AppTokens.fontSizeLabel,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppTokens.spacingSm),
              // v0.27 round 67 (C-5): 用 ChoiceChipWrap 集中器
              ChoiceChipWrap<int>(
                options: _options,
                selected: _days,
                labelOf: loc.reminderHubEveryNDays,
                onSelect: (d) => setState(() => _days = d),
                disabled: _busy,
              ),
            ],
            const SizedBox(height: AppTokens.spacingLg),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    variant: PrimaryButtonVariant.secondary,
                    isFullWidth: true,
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    child: Text(loc.commonCancel),
                  ),
                ),
                const SizedBox(width: AppTokens.spacingSm),
                Expanded(
                  child: PrimaryButton(
                    isFullWidth: false,
                    onPressed: _busy ? null : _save,
                    child: Text(loc.commonSave),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
