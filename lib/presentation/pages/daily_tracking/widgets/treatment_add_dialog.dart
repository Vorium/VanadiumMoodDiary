// v0.30 round 92 (audit-fixes / P0 #15): AddTreatmentDialog
//
// 治疗记录添加 dialog (4 字段: date / category / provider / note):
// - date: ListTile + showDatePicker (默认 DateTime.now())
// - category: 4 选 1 ChoiceChip (medication_adjustment / consultation /
//   hospitalization / other), R91 schema 是 free String treatmentType,
//   这里硬 4 选 1 跟 R91 existing data 兼容 (R60 模式, 不开 enum)
// - provider: TextField String (R91 description 字段, 显示 "心理医生" /
//   "医院" / "诊所" 名称)
// - note: TextField String optional
//
// 复用 R91 treatmentRepositoryProvider.add() API (write timestamp +
// treatmentType + description + linkedMedicationId + linkedMedicationName + note),
// linkedMedicationId/name 留 null (R92 不开 medication picker, 留 v0.31+)。
//
// 4 层架构: presentation/pages/daily_tracking/widgets/, 0 跨 feature import。
// 复用 R91 sleep_widgets.dart SleepEntryDialog 风格: AlertDialog + ListTile +
// ChoiceChip + TextField + 取消/保存。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/daily_tracking_providers.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';

/// 治疗记录添加 dialog (R92 4 字段)
class AddTreatmentDialog extends ConsumerStatefulWidget {
  const AddTreatmentDialog({super.key});

  /// 静态入口 — Dialog 模态 (R88 mood_dialog 风格)
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const AddTreatmentDialog(),
    );
  }

  @override
  ConsumerState<AddTreatmentDialog> createState() => _AddTreatmentDialogState();
}

class _AddTreatmentDialogState extends ConsumerState<AddTreatmentDialog> {
  // 默认: 今天
  DateTime _date = DateTime.now();
  // 默认: 心理咨询 (R92 设计: 用户最常用)
  String _category = 'consultation';
  final _providerController = TextEditingController();
  final _noteController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _providerController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// 4 类 category 列表 (跟 R91 existing treatmentType 字符串兼容)
  static const _categoryValues = [
    'medication_adjustment',
    'consultation',
    'hospitalization',
    'other',
  ];

  String _categoryLabel(String value, AppLocalizations l10n) {
    switch (value) {
      case 'medication_adjustment':
        return l10n.treatmentCategoryMedicationAdjustment;
      case 'consultation':
        return l10n.treatmentCategoryConsultation;
      case 'hospitalization':
        return l10n.treatmentCategoryHospitalization;
      case 'other':
        return l10n.treatmentCategoryOther;
    }
    return value;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context);
    final provider = _providerController.text.trim();
    if (provider.isEmpty) {
      AppSnackBar.showInfo(context, l10n.treatmentProviderRequired);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(treatmentRepositoryProvider).add(
            timestamp: _date,
            treatmentType: _category,
            description: provider,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackBar.showError(
        context,
        action: l10n.snackbarActionSave,
        error: e,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.treatmentAddTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. 日期
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(l10n.treatmentDate),
              subtitle: Text(DateFormat('yyyy-MM-dd').format(_date)),
              onTap: _pickDate,
            ),
            const SizedBox(height: AppTokens.spacingSm),
            // 2. 类别 (4 选 1)
            Text(
              l10n.treatmentCategory,
              style: AppTokens.textStyleLabelStrong(context),
            ),
            const SizedBox(height: AppTokens.spacingXs),
            Wrap(
              spacing: AppTokens.spacingSm,
              runSpacing: AppTokens.spacingXxs,
              children: [
                for (final value in _categoryValues)
                  ChoiceChip(
                    label: Text(_categoryLabel(value, l10n)),
                    selected: _category == value,
                    onSelected: (selected) {
                      if (selected) setState(() => _category = value);
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppTokens.spacingMd),
            // 3. provider (description)
            TextField(
              controller: _providerController,
              decoration: InputDecoration(
                labelText: l10n.treatmentProvider,
                hintText: l10n.treatmentProviderHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppTokens.spacingMd),
            // 4. note
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: l10n.treatmentNote,
                hintText: l10n.treatmentNoteHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}
