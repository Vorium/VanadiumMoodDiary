// v0.31 round 11a (Apple Health redesign · Phase 3 Task 3.3):
// TempMedicationDialog 表单改 AppleListSection + PrimaryButton
//
// 改前: AlertDialog inline Column + 3 个 TextField
// 改后:
// - AppleListSection 包装表单 (iOS 群组列表风格, 圆角 16 容器, hairline 分隔)
// - "取消" 改 PrimaryButton tertiary (TextButton)
// - "保存" 改 PrimaryButton primary (FilledButton, isFullWidth: true)
// - 间距统一 16
//
// 业务逻辑 / 0 改动 (Phase 3 任务约束: 不改业务逻辑).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/l10n/medication_unit_label.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/providers/check_in_notifier.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/error_state.dart';
import 'package:chroniccare/presentation/widgets/primary_button.dart';

/// 临时吃药 dialog
///
/// v0.7：加关联常吃药字段（可选）。点"保存"插入 type='temp' 的 CheckIn。
///
/// **N25 fix**: 之前用 `ValueNotifier<Medication?>` 配 ignore 注释,
/// 改成纯 StatefulWidget + setState 模式，更清晰且无 lint 噪音。
///
/// **WidgetRef fix**: 改为 ConsumerStatefulWidget，不再通过构造参数传 WidgetRef，
/// 避免 WidgetRef 脱离创建它的 widget 作用域。
///
/// **v0.31 round 11a (Apple Health redesign)**: 表单改 AppleListSection 风格,
/// 底部 "取消 / 保存" 改 PrimaryButton (3 variant).
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
      // v0.27 round 77 (R76-N8 修): commonLoadFailed 传 e.toString()
      error: (e, _) => showDialog<void>(
        context: context,
        builder: (_) => ErrorState(
          title: AppLocalizations.of(context).commonLoadFailed(e.toString()),
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
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.tempMedDialogTitle),
      contentPadding: const EdgeInsets.symmetric(vertical: AppTokens.spacingMd),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // v0.31 round 11a: 表单改 AppleListSection 风格
            // (圆角 16 容器 + hairline 分隔, 跟 spec §5.3 medication 一致)
            AppleListSection(
              margin: EdgeInsets.zero,
              children: [
                DropdownButtonFormField<MedicationEntity?>(
                  initialValue: selectedMed,
                  decoration: InputDecoration(
                    labelText: l10n.tempMedLinkLabel,
                    hintText: l10n.tempMedLinkHint,
                    border: InputBorder.none, // AppleListSection 自带容器
                  ),
                  items: [
                    DropdownMenuItem<MedicationEntity?>(
                      value: null,
                      child: Text(l10n.tempMedNoLink),
                    ),
                    for (final m in meds)
                      DropdownMenuItem<MedicationEntity?>(
                        value: m,
                        child: Text(
                          // v0.27 round 61 (P2): 走 dosageUnitLabel 走 ARB i18n
                          // 之前 `m.dosageUnit.id` 返回 'mg'/'片' 字符串, en 用户看 '片' 困惑
                          '${m.name} ${m.dosage}${dosageUnitLabel(context, m.dosageUnit)}',
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => selectedMed = v),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spacingXs),
            AppleListSection(
              margin: EdgeInsets.zero,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.commonMedName,
                    hintText: l10n.tempMedNameHint,
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spacingXs),
            AppleListSection(
              margin: EdgeInsets.zero,
              children: [
                TextField(
                  controller: noteController,
                  decoration: InputDecoration(
                    labelText: l10n.tempMedReasonLabel,
                    hintText: l10n.tempMedReasonHint,
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        // v0.31 round 11a: 改 PrimaryButton 3 variant
        // (Dialog 内 isFullWidth: false, 跟 spec §4.1 一致)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.pageMarginH),
          child: Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  variant: PrimaryButtonVariant.tertiary,
                  isFullWidth: true,
                  onPressed: saving ? null : () => Navigator.pop(context),
                  child: Text(l10n.commonCancel),
                ),
              ),
              const SizedBox(width: AppTokens.spacingSm),
              Expanded(
                child: PrimaryButton(
                  isFullWidth: true,
                  onPressed: saving ? null : _onSave,
                  child: Text(l10n.commonSave),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.spacingXs),
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
      // v0.27 round 59 (emil EMIL-T13): 用 showError 集中器
      AppSnackBar.showError(
        ctx,
        action: l10n.snackbarActionSave,
        error: e,
      );
      setState(() => saving = false);
    }
  }
}
