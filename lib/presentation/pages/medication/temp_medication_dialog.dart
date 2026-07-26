import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/providers/check_in_notifier.dart';
import 'package:chroniccare/presentation/providers/data_providers.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/error_state.dart';
import 'package:chroniccare/presentation/widgets/loading_text_button.dart';

/// 临时吃药 dialog
///
/// v0.7：加关联常吃药字段（可选）。点"保存"插入 type='temp' 的 CheckIn。
///
/// **N25 fix**: 之前用 `ValueNotifier<Medication?>` 配 ignore 注释,
/// 改成纯 StatefulWidget + setState 模式，更清晰且无 lint 噪音。
///
/// **WidgetRef fix**: 改为 ConsumerStatefulWidget，不再通过构造参数传 WidgetRef，
/// 避免 WidgetRef 脱离创建它的 widget 作用域。
class TempMedicationDialog extends ConsumerStatefulWidget {
  const TempMedicationDialog({super.key});

  @override
  ConsumerState<TempMedicationDialog> createState() =>
      _TempMedicationDialogState();

  /// 入口：读 meds provider,转给 ConsumerStatefulWidget
  static Future<void> show(BuildContext context, WidgetRef ref) {
    final medsAsync = ref.read(medicationsProvider);
    return medsAsync.when(
      data: (meds) => showDialog<void>(
        context: context,
        builder: (_) => const TempMedicationDialog(),
      ),
      loading: () => showDialog<void>(
        context: context,
        builder: (_) => const LoadingSkeleton.fullScreen(),
      ),
      error: (e, _) => showDialog<void>(
        context: context,
        builder: (_) => ErrorState(
          title: AppLocalizations.of(context).commonLoadFailed(''),
          detail: e.toString(),
        ),
      ),
    );
  }
}

class _TempMedicationDialogState extends ConsumerState<TempMedicationDialog> {
  late final TextEditingController nameController;
  late final TextEditingController noteController;
  MedicationEntity? selectedMed;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    noteController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // v0.17 round 3: Riverpod 3.x 改名为 .value（之前 .valueOrNull）
    final meds = (ref.read(medicationsProvider).value) ?? <MedicationEntity>[];
    return AlertDialog(
      title: Text(AppLocalizations.of(context).tempMedDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<MedicationEntity?>(
            initialValue: selectedMed,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).tempMedLinkLabel,
              hintText: AppLocalizations.of(context).tempMedLinkHint,
            ),
            items: [
              DropdownMenuItem<MedicationEntity?>(
                value: null,
                child: Text(AppLocalizations.of(context).tempMedNoLink),
              ),
              for (final m in meds)
                DropdownMenuItem<MedicationEntity?>(
                  value: m,
                  child: Text(
                    '${m.name} ${m.dosage}${m.dosageUnit.id}',
                  ),
                ),
            ],
            onChanged: (v) => setState(() => selectedMed = v),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).commonMedName,
              hintText: AppLocalizations.of(context).tempMedNameHint,
            ),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          TextField(
            controller: noteController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).tempMedReasonLabel,
              hintText: AppLocalizations.of(context).tempMedReasonHint,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context).commonCancel),
        ),
        LoadingTextButton(
          label: AppLocalizations.of(context).commonSave,
          isLoading: saving,
          onPressed: saving ? null : _onSave,
        ),
      ],
    );
  }

  Future<void> _onSave() async {
    if (nameController.text.trim().isEmpty) return;
    setState(() => saving = true);
    final med = selectedMed;
    final name = nameController.text.trim();
    final note = noteController.text.trim();
    final ctx = context;
    try {
      await ref.read(checkInNotifierProvider.notifier).addTempMedication(
            name: name,
            note: med == null ? note : '【${med.name}】$note',
          );
      if (ctx.mounted) Navigator.pop(ctx);
    } catch (e) {
      if (!ctx.mounted) return;
      final l10n = AppLocalizations.of(ctx);
      ScaffoldMessenger.of(ctx).showSnackBar(
        AppSnackBar.error(ctx,
            action: l10n.snackbarActionSave,
            error: e,),
      );
      setState(() => saving = false);
    }
  }
}
