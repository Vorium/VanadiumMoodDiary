// v0.13 (Round 9) 药物编辑 dialog
//
// 复用 setup_page 的"药物卡片"字段：name / dosage / unit / times，
// 但保存路径不同：调 MedicationRepository.update。
// 同时加"停药 / 恢复"开关（isActive 软停，保留历史）。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/shared/domain_value.dart';
import 'package:chroniccare/core/shared/formatters.dart';
import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/widgets/loading_text_button.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';
import 'package:chroniccare/presentation/providers/data_providers.dart';

/// 弹出编辑 dialog，返回 true 表示有保存成功，false/null = 取消
Future<bool?> showEditMedicationDialog(
  BuildContext context,
  MedicationEntity med,
) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _EditMedicationDialog(med: med),
  );
}

class _EditMedicationDialog extends ConsumerStatefulWidget {
  final MedicationEntity med;
  const _EditMedicationDialog({required this.med});

  @override
  ConsumerState<_EditMedicationDialog> createState() =>
      _EditMedicationDialogState();
}

class _EditMedicationDialogState extends ConsumerState<_EditMedicationDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late String _dosageUnit;
  late List<TimeOfDay> _times;
  late bool _isActive;
  bool _saving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final m = widget.med;
    _nameController = TextEditingController(text: m.name);
    _dosageController = TextEditingController(
      text: m.dosage == m.dosage.toInt()
          ? m.dosage.toInt().toString()
          : m.dosage.toString(),
    );
    _dosageUnit = m.dosageUnit;
    _times = m.times
        .map((hm) => TimeOfDay(hour: hm.hour, minute: hm.minute))
        .toList();
    _isActive = m.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  /// 表单验证，返回 null = 通过
  String? _validate(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_nameController.text.trim().isEmpty) {
      return l10n.editMedValidationNameRequired;
    }
    final dosage = double.tryParse(_dosageController.text.trim());
    if (dosage == null || dosage <= 0) {
      return l10n.editMedValidationDosageInvalid;
    }
    if (_dosageUnit != DosageUnit.mg.id && _dosageUnit != DosageUnit.tablet.id) {
      return l10n.editMedValidationUnitInvalid;
    }
    return null;
  }

  Future<void> _save() async {
    final err = _validate(context);
    if (err != null) {
      setState(() => _errorText = err);
      return;
    }
    if (_saving) return;
    setState(() {
      _saving = true;
      _errorText = null;
    });

    // v0.21 (P0-1 fix): 之前用 double.parse,虽然 _validate 已 tryParse 校验过,
    // 但这是不规范模式——若未来有人改 _validate 漏校验,会直接崩。
    // 改 tryParse + 二次校验(防御性),失败时回滚 _saving 状态。
    final dosage = double.tryParse(_dosageController.text.trim());
    if (dosage == null || dosage <= 0) {
      setState(() {
        _saving = false;
        _errorText =
            AppLocalizations.of(context).editMedValidationDosageInvalid;
      });
      return;
    }
    final original = widget.med;
    final isActiveChanged = _isActive != original.isActive;

    // 构造更新后的 Medication
    // 1) 基础字段（UI 用 TimeOfDay，保存时转 HourMinute）
    var updated = original.copyWith(
      name: _nameController.text.trim(),
      dosage: dosage,
      dosageUnit: _dosageUnit,
      times: _times
          .map((t) => HourMinute(hour: t.hour, minute: t.minute))
          .toList(),
      isActive: _isActive,
    );
    // 2) isActive 变化时同步 endDate（停药/恢复的语义）
    if (isActiveChanged) {
      updated = _isActive
          ? updated.copyWith(endDate: const DomainValue<DateTime?>(null)) // 恢复
          : updated.copyWith(
              endDate: DomainValue<DateTime?>(DateTime.now()),
            ); // 停药
    }

    try {
      await ref.read(medicationRepositoryProvider).update(updated);
      // 改完重排该药的所有相关推送
      final notif = ref.read(notificationServiceProvider);
      // v0.23 (P0-2 H1 fix): invalidate + read 同步 race 拿到 stale meds
      // → rescheduleMedicationReminders 用旧 ID 公式, 通知时间错位
      // 修: refresh(provider.future) 强制等 stream 重新 emit, 直接用返回的新值
      final meds = await ref.refresh(medicationsProvider.future);
      // v0.18 (P2-P0-2): notification_service 改接受 entity, 删 mapper 调用
      // medication reminders: 整个重排（停药会自然被 reschedule 排除）
      await notif.rescheduleMedicationReminders(meds);
      // refill reminders: 整个重排
      await notif.rescheduleRefillReminders(meds);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _errorText = AppLocalizations.of(context)
              .editMedSaveFailed(e.toString().split('\n').first);
        });
      }
    }
  }

  Future<void> _pickTime() async {
    final initial =
        _times.isNotEmpty ? _times.last : const TimeOfDay(hour: 8, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null && mounted) {
      setState(() {
        _times.add(picked);
        _times.sort(
          (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.med;
    return AlertDialog(
      title: Text(AppLocalizations.of(context).editMedDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 状态卡：active / stopped
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.spacingSm,
                vertical: AppTokens.spacingXs,
              ),
              decoration: BoxDecoration(
                color: _isActive
                    ? AppTokens.primaryLightColor(context)
                    : AppTokens.tintedWarningSoft(context),
                borderRadius: BorderRadius.circular(AppTokens.radiusChip),
              ),
              child: Row(
                children: [
                  Icon(
                    _isActive ? Icons.check_circle_outline : Icons.pause_circle,
                    size: 16,
                    color: _isActive ? AppTokens.primary : AppTokens.warning,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isActive
                        ? AppLocalizations.of(context).editMedStatusActive
                        : AppLocalizations.of(context).editMedStatusStopped,
                    style: TextStyle(
                      fontSize: AppTokens.fontSizeCaption,
                      color: _isActive ? AppTokens.primary : AppTokens.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (m.endDate != null && !_isActive) ...[
                    const Spacer(),
                    Text(
                      AppLocalizations.of(context)
                          .editMedStoppedDate(Formatters.date(m.endDate!)),
                      style: TextStyle(
                        fontSize: AppTokens.fontSizeCaption,
                        color: AppTokens.textHintColor(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppTokens.spacingSm),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).commonMedName,
                // P0-5 fix: 改中性文案，避免《广告法》第 16 条 +
                // 《医疗广告管理办法》风险。
                hintText: AppLocalizations.of(context).editMedNameHint,
              ),
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() => _errorText = null);
                }
              },
            ),
            const SizedBox(height: AppTokens.spacingSm),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _dosageController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText:
                          AppLocalizations.of(context).editMedDosageLabel,
                      hintText: '40',
                    ),
                    onChanged: (_) {
                      if (_errorText != null) {
                        setState(() => _errorText = null);
                      }
                    },
                  ),
                ),
                const SizedBox(width: AppTokens.spacingSm),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _dosageUnit,
                    decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context).editMedUnitLabel,),
                    items: [
                      DropdownMenuItem<String>(
                          value: DosageUnit.mg.id,
                          child: const Text('mg'),
                      ),
                      DropdownMenuItem<String>(
                          value: DosageUnit.tablet.id,
                          child: Text(
                              AppLocalizations.of(context).commonDoseUnit,),),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _dosageUnit = v);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spacingSm),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AppLocalizations.of(context).editMedTimeSectionLabel,
                style: TextStyle(
                  fontSize: AppTokens.fontSizeLabel,
                  color: AppTokens.textSecondaryColor(context),
                ),
              ),
            ),
            const SizedBox(height: AppTokens.spacingXs),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < _times.length; i++)
                  PressFeedback(
                    child: InputChip(
                      label: Text(_formatTime(_times[i])),
                      onDeleted: () {
                        setState(() => _times.removeAt(i));
                      },
                    ),
                  ),
                PressFeedback(
                  child: ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: Text(AppLocalizations.of(context).editMedAddTime),
                    onPressed: _saving ? null : _pickTime,
                  ),
                ),
              ],
            ),
            if (_times.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppTokens.spacingXxs),
                child: Text(
                  AppLocalizations.of(context).editMedNoTimeHint,
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeCaption,
                    color: AppTokens.textHintColor(context),
                  ),
                ),
              ),
            const SizedBox(height: AppTokens.spacingSm),
            // 停药/恢复 开关
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                _isActive
                    ? AppLocalizations.of(context).editMedStopAction
                    : AppLocalizations.of(context).editMedResumeAction,
                style: TextStyle(
                  fontSize: AppTokens.fontSizeBody,
                  color: _isActive ? AppTokens.warning : AppTokens.primary,
                ),
              ),
              subtitle: Text(
                _isActive
                    ? AppLocalizations.of(context).editMedStopHint
                    : AppLocalizations.of(context).editMedResumeHint,
                style: TextStyle(
                  fontSize: AppTokens.fontSizeCaption,
                  color: AppTokens.textHintColor(context),
                ),
              ),
              value: _isActive,
              onChanged: _saving
                  ? null
                  : (v) {
                      setState(() => _isActive = v);
                    },
            ),
            if (_errorText != null) ...[
              const SizedBox(height: AppTokens.spacingXs),
              Text(
                _errorText!,
                style: const TextStyle(
                  color: AppTokens.error,
                  fontSize: AppTokens.fontSizeLabel,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: Text(AppLocalizations.of(context).commonCancel),
        ),
        // v0.24 round 43 (emil P1-01 H-03): 改用 LoadingTextButton
        // 替代内联 ElevatedButton + CircularProgressIndicator
        LoadingTextButton(
          label: AppLocalizations.of(context).commonSave,
          isLoading: _saving,
          onPressed: _save,
        ),
      ],
    );
  }

  static String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
