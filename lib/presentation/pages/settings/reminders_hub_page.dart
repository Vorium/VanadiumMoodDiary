// v0.14 (Round 12C) 提醒中心 �?集中查看/管理所有类型的提醒
//
// 之前散落在各处的设置（notification / assessment / safety watch）整合到一个页�?
//
// 五大类提醒：
// 1. 每日打卡提醒（notification_service.scheduleDailyReminder，固�?20:00�?
// 2. 用药提醒（notification_service - 每个 medication 的每�?time�?
// 3. 续方提醒（medication.refillAt - refillReminderDays�?
// 4. 心理评估提醒（AssessmentReminderService�?
// 5. 失联通知（SafetyWatchService - 死了�?撸了么）

import 'package:chroniccare/presentation/providers/service_providers.dart';
import 'package:chroniccare/presentation/providers/reminders_hub_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
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
  // 之前 4 �?nullable 字段 + initState _load + setState 异步填�?
  // 模式落后�?v0.17 round 7 �?calendarWindowProvider FutureProvider
  // 改成 watch remindersHubConfigProvider,异步值自�?rebuild
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
          // v0.27 round 67 (C-2): �?InfoBanner 集中�?
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

          const SizedBox(height: AppTokens.spacingSm),

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

          const SizedBox(height: AppTokens.spacingSm),

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

          const SizedBox(height: AppTokens.spacingSm),

          // 4. 心理评估提醒
          // v0.23 round 41 (spen P3-35): 显式�?configAsync �?_buildAssessmentCard
          _buildAssessmentCard(context, configAsync),

          const SizedBox(height: AppTokens.spacingSm),

          // 5. 失联通知
          _buildSafetyCard(context, configAsync),

          const SizedBox(height: AppTokens.spacingMd),
        ],
      ),
    );
  }

  void _showAssessmentSettings(BuildContext context) {
    // v0.23 round 41 (spen P3-35): 显式取一�?configAsync,闭包内不再依�?build scope
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

  void _showSafetySettings(BuildContext context) {
    final configAsync = ref.read(remindersHubConfigProvider);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final c = _configOrFallback(configAsync);
        return _SafetyReminderSheet(
          initialEnabled: c.safetyEnabled,
          initialThreshold: c.safetyThreshold,
          onSaved: () => ref.invalidate(remindersHubConfigProvider),
        );
      },
    );
  }

  Widget _buildAssessmentCard(
    BuildContext context,
    AsyncValue<RemindersHubConfig> configAsync,
  ) {
    // v0.23 round 41 (spen P3-35): �?configAsync 替代本地 nullable 字段
    return AssessmentReminderCard(
      enabled: _configOrFallback(configAsync).assessmentEnabled,
      days: _configOrFallback(configAsync).assessmentDays,
      onConfigure: () => _showAssessmentSettings(context),
    );
  }

  Widget _buildSafetyCard(
    BuildContext context,
    AsyncValue<RemindersHubConfig> configAsync,
  ) {
    return SafetyReminderCard(
      enabled: _configOrFallback(configAsync).safetyEnabled,
      threshold: _configOrFallback(configAsync).safetyThreshold,
      // P0-1 fix: 检测当�?SMS provider,如果�?mock 状态显�?banner
      isMockSms: ref.watch(smsProviderNameProvider) == 'mock',
      onConfigure: () => _showSafetySettings(context),
    );
  }

  /// configAsync 没加载完时给 fallback 默认�?加载完用真实�?
  ///
  /// v0.23 round 41 (spen P3-35): 替代之前 4 �?nullable 字段 + setState
  RemindersHubConfig _configOrFallback(AsyncValue<RemindersHubConfig> async) {
    return async.maybeWhen(
      data: (c) => c,
      orElse: () => const RemindersHubConfig(
        assessmentEnabled: false,
        assessmentDays: 14,
        safetyEnabled: false,
        safetyThreshold: 2,
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
              // v0.27 round 67 (C-5): �?ChoiceChipWrap 集中�?
              ChoiceChipWrap<int>(
                options: _options,
                selected: _days,
                labelOf: (d) => loc.reminderHubEveryNDays(d),
                onSelect: (d) => setState(() => _days = d),
                disabled: _busy,
              ),
            ],
            const SizedBox(height: AppTokens.spacingLg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
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

/// 失联通知设置 sheet
class _SafetyReminderSheet extends ConsumerStatefulWidget {
  final bool initialEnabled;
  final int initialThreshold;
  final VoidCallback onSaved;
  const _SafetyReminderSheet({
    required this.initialEnabled,
    required this.initialThreshold,
    required this.onSaved,
  });

  @override
  ConsumerState<_SafetyReminderSheet> createState() =>
      _SafetyReminderSheetState();
}

class _SafetyReminderSheetState extends ConsumerState<_SafetyReminderSheet> {
  late bool _enabled;
  late int _threshold;
  bool _busy = false;

  static const _options = [1, 2, 3, 5, 7, 14];

  @override
  void initState() {
    super.initState();
    _enabled = widget.initialEnabled;
    _threshold = widget.initialThreshold;
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      // v0.27 round 61 (P1-12 拆分收尾): 改走 safetyConfigServiceProvider
      // 直接�?SharedPreferences, 不再�?safetyWatchServiceProvider facade�?
      final config = ref.read(safetyConfigServiceProvider);
      await config.setEnabled(_enabled);
      if (_enabled) {
        await config.setThresholdDays(_threshold);
      }
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
              loc.reminderHubSafetyTitle,
              style: const TextStyle(
                fontSize: AppTokens.fontSizeTitle,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTokens.spacingSm),
            Text(
              loc.reminderHubSafetyDescription,
              style: TextStyle(
                fontSize: AppTokens.fontSizeCaption,
                color: AppTokens.textSecondaryColor(context),
              ),
            ),
            const SizedBox(height: AppTokens.spacingMd),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(loc.reminderHubEnable),
              value: _enabled,
              onChanged: _busy ? null : (v) => setState(() => _enabled = v),
            ),
            if (_enabled) ...[
              const Divider(),
              Text(
                loc.reminderHubTriggerThreshold,
                style: const TextStyle(
                  fontSize: AppTokens.fontSizeLabel,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppTokens.spacingSm),
              // v0.27 round 67 (C-5): �?ChoiceChipWrap 集中�?
              ChoiceChipWrap<int>(
                options: _options,
                selected: _threshold,
                labelOf: (d) => loc.reminderHubNDays(d),
                onSelect: (d) => setState(() => _threshold = d),
                disabled: _busy,
              ),
            ],
            const SizedBox(height: AppTokens.spacingLg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
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
