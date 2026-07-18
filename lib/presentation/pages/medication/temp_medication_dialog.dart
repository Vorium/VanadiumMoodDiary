import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/providers/check_in_notifier.dart';
import 'package:chroniccare/presentation/providers/data_providers.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';

/// 临时吃药 dialog
///
/// v0.7：加关联常吃药字段（可选）。点"保存"插入 type='temp' 的 CheckIn。
///
/// **N25 fix**: 之前用 `ValueNotifier<Medication?>` 配 ignore 注释,
/// 改成纯 StatefulWidget + setState 模式，更清晰且无 lint 噪音。
class TempMedicationDialog extends StatefulWidget {
  final WidgetRef ref;
  const TempMedicationDialog({super.key, required this.ref});

  @override
  State<TempMedicationDialog> createState() => _TempMedicationDialogState();

  /// 入口：读 meds provider,转给 StatefulWidget
  static Future<void> show(BuildContext context, WidgetRef ref) {
    final medsAsync = ref.read(medicationsProvider);
    return medsAsync.when(
      data: (meds) => showDialog<void>(
        context: context,
        builder: (_) => TempMedicationDialog(ref: ref),
      ),
      loading: () => showDialog<void>(
        context: context,
        builder: (_) => LoadingSkeleton.fullScreen(),
      ),
      error: (e, _) => showDialog<void>(
        context: context,
        builder: (_) => Center(child: Text(AppLocalizations.of(context).commonLoadFailed(e.toString()))),
      ),
    );
  }
}

class _TempMedicationDialogState extends State<TempMedicationDialog> {
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
    final meds =
        (widget.ref.read(medicationsProvider).value) ?? <MedicationEntity>[];
    return AlertDialog(
      title: const Text('添加临时吃药'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<MedicationEntity?>(
            initialValue: selectedMed,
            decoration: const InputDecoration(
              labelText: '关联到常吃药（可选）',
              hintText: '不选 = 临时事件',
            ),
            items: [
              const DropdownMenuItem<MedicationEntity?>(
                value: null,
                child: Text('不关联'),
              ),
              for (final m in meds)
                DropdownMenuItem<MedicationEntity?>(
                  value: m,
                  child: Text(
                    '${m.name} ${m.dosage}${m.dosageUnit}',
                  ),
                ),
            ],
            onChanged: (v) => setState(() => selectedMed = v),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: '药名',
              hintText: '如：布洛芬',
            ),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          TextField(
            controller: noteController,
            decoration: const InputDecoration(
              labelText: '原因',
              hintText: '如：感冒',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context).commonCancel),
        ),
        ElevatedButton(
          onPressed: saving ? null : _onSave,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(AppLocalizations.of(context).commonSave),
              if (saving)
                const IgnorePointer(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
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
    final ref = widget.ref;
    try {
      await ref.read(checkInNotifierProvider.notifier).addTempMedication(
            name: name,
            note: med == null ? note : '【${med.name}】$note',
          );
      if (ctx.mounted) Navigator.pop(ctx);
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          AppSnackBar.error(ctx, action: '保存', error: e),
        );
        setState(() => saving = false);
      }
    }
  }
}
