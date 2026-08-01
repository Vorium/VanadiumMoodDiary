// v0.13 (Round 7) 评估周期提醒设置 UI
//
// - 顶部一个开关：开启/关闭整个评估提醒
// - 下方一个下拉/选择行：提醒间隔（7/14/30/60/90 天）
// - 关闭时整体灰显
// - 改完即生效（onSettingsChanged）
import 'package:chroniccare/presentation/providers/service_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/data/services/assessment_reminder_service.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/primary_button.dart';

class AssessmentReminderSection extends ConsumerStatefulWidget {
  const AssessmentReminderSection({super.key});

  @override
  ConsumerState<AssessmentReminderSection> createState() =>
      _AssessmentReminderSectionState();
}

class _AssessmentReminderSectionState
    extends ConsumerState<AssessmentReminderSection> {
  bool? _enabled;
  int? _days;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = ref.read(assessmentReminderServiceProvider);
    final enabled = await service.isEnabled();
    final days = await service.getDays();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _days = days;
    });
  }

  Future<void> _toggle(bool v) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final service = ref.read(assessmentReminderServiceProvider);
      await service.setEnabled(v);
      await service.onSettingsChanged();
      if (!mounted) return;
      setState(() => _enabled = v);
      if (v && mounted) {
        // v0.27 round 59 (emil EMIL-T13): 用 showInfo 集中器 (1 行)
        AppSnackBar.showInfo(
          context,
          AppLocalizations.of(context).assessmentReminderEnabled(_days ?? 14),
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          action: AppLocalizations.of(context).commonSetup,
          error: e,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changeDays() async {
    if (_busy) return;
    final current = _days ?? AssessmentReminderService.defaultDays;
    final picked = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => _AssessmentDaysSheet(initial: current),
    );
    if (picked == null) return;
    setState(() => _busy = true);
    try {
      final service = ref.read(assessmentReminderServiceProvider);
      await service.setDays(picked);
      await service.onSettingsChanged();
      if (!mounted) return;
      setState(() => _days = picked);
      if (mounted) {
        // v0.27 round 59 (emil EMIL-T13): 用 showInfo 集中器
        AppSnackBar.showInfo(
          context,
          AppLocalizations.of(context).assessmentReminderChanged(picked),
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          action: AppLocalizations.of(context).commonSetup,
          error: e,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_enabled == null || _days == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppTokens.spacingMd),
          child: SizedBox(
            height: AppTokens.spacingXl,
            child: LoadingSkeleton.fullScreen(),
          ),
        ),
      );
    }
    final enabled = _enabled!;
    final days = _days!;
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: Icon(Icons.event_repeat,
                color: AppTokens.primaryColor(context),),
            title:
                Text(AppLocalizations.of(context).reminderHubAssessmentTitle),
            subtitle: Text(
              enabled
                  ? AppLocalizations.of(context)
                      .assessmentReminderSubtitleEnabled(days)
                  : AppLocalizations.of(context)
                      .reminderHubAssessmentDescDisabled,
              style: TextStyle(
                color: enabled
                    ? Theme.of(context).colorScheme.onSurface
                    : AppTokens.textHintColor(context),
              ),
            ),
            value: enabled,
            onChanged: _busy ? null : _toggle,
          ),
          if (enabled) ...[
            const Divider(height: 1),
            AppListTile(
              leading:
                  Icon(Icons.schedule, color: AppTokens.primaryColor(context)),
              title: Text(AppLocalizations.of(context).reminderHubInterval),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context).reminderHubNDays(days),
                    style: const TextStyle(
                      fontSize: AppTokens.fontSizeBody,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: AppTokens.spacingXs),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: _busy ? null : _changeDays,
            ),
          ],
          if (enabled) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppTokens.spacingMd),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: AppTokens.iconSizeInline,
                    color: AppTokens.textSecondaryColor(context),
                  ),
                  const SizedBox(width: AppTokens.spacingXs),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).assessmentReminderHelpText,
                      style: TextStyle(
                        fontSize: AppTokens.fontSizeCaption,
                        color: AppTokens.textSecondaryColor(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 提醒间隔 bottom sheet
class _AssessmentDaysSheet extends StatefulWidget {
  final int initial;
  const _AssessmentDaysSheet({required this.initial});
  @override
  State<_AssessmentDaysSheet> createState() => _AssessmentDaysSheetState();
}

class _AssessmentDaysSheetState extends State<_AssessmentDaysSheet> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  static const _days = [7, 14, 30, 60, 90];

  String _hintForDays(AppLocalizations l10n, int days) {
    return switch (days) {
      7 => l10n.assessmentReminderHintAcute,
      14 => l10n.assessmentReminderHintCommon,
      30 => l10n.assessmentReminderHintStable,
      60 => l10n.assessmentReminderHintMaintenance,
      90 => l10n.assessmentReminderHintLongTerm,
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTokens.spacingMd),
            child: Text(
              l10n.reminderHubInterval,
              style: const TextStyle(
                fontSize: AppTokens.fontSizeTitle,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Flutter 3.32+: 用 RadioGroup 包裹代替每个 RadioListTile 单独传 groupValue/onChanged
          RadioGroup<int>(
            groupValue: _selected,
            onChanged: (v) {
              if (v != null) setState(() => _selected = v);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final d in _days)
                  RadioListTile<int>(
                    value: d,
                    title: Text(l10n.reminderHubEveryNDays(d)),
                    subtitle: Text(_hintForDays(l10n, d)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          Padding(
            padding: const EdgeInsets.all(AppTokens.spacingMd),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.commonCancel),
                  ),
                ),
                const SizedBox(width: AppTokens.spacingSm),
                Expanded(
                  child: PrimaryButton(
                    isFullWidth: false,
                    onPressed: () => Navigator.pop(context, _selected),
                    child: Text(l10n.commonConfirmOk),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
