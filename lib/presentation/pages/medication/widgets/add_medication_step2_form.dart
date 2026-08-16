// v0.32 R112 (AR-20 god class 批2b): 抽 add_medication_page Step 2 表单
//
// 改前: `add_medication_page.dart` 573L, `_buildStep2` (line 301-436)
//   inline builder 混在 page state 里 (form + validation + submit 3 职责)。
// 改后: 抽无状态 widget, 值 + 回调注入, state 留在 page。跟 R109 round 4
//   抽 MedicationConfirmRow 同款子 widget 抽模式。
//
// 4 层架构: presentation/widgets 公开 widget, 0 state 值注入。UI 行为
// 1:1 不动 (AppleListSection "用药时间" + 剂量/单位 + 时间 chips +
// TimePicker 弹窗仍在 widget 内)。

import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/add_medication_form_shared.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';

/// Step 2: 剂量 + 时间 (AppleListSection "用药时间")
///
/// R112 AR-20 批2b: 原 `_buildStep2` 1:1 迁移。
/// 时间列表增删改走回调 (TimePicker 仍在 widget 内弹)。
class AddMedicationStep2Form extends StatelessWidget {
  const AddMedicationStep2Form({
    super.key,
    required this.dosageController,
    required this.dosageUnit,
    required this.onDosageUnitChanged,
    required this.times,
    required this.onTimeChanged,
    required this.onTimeDeleted,
    required this.onTimeAdded,
  });

  /// 剂量输入 controller (page state 持有)
  final TextEditingController dosageController;

  /// 剂量单位
  final DosageUnit dosageUnit;

  /// 剂量单位切换回调
  final ValueChanged<DosageUnit> onDosageUnitChanged;

  /// 服药时间列表 (page state 持有)
  final List<TimeOfDay> times;

  /// 时间修改回调 (index, 新时间)
  final void Function(int index, TimeOfDay time) onTimeChanged;

  /// 时间删除回调 (index)
  final ValueChanged<int> onTimeDeleted;

  /// 时间添加回调 (新时间)
  final ValueChanged<TimeOfDay> onTimeAdded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.spacingMd),
      children: [
        MedicationStepTitle(text: l10n.medAddStep2Title),
        const SizedBox(height: AppTokens.spacingMd),

        // "用药时间" AppleListSection
        AppleListSection(
          title: l10n.medAddTime,
          children: [
            // 剂量 + 单位
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppTokens.spacingXxs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.medAddDosageLabel,
                    style: AppTokens.textStyleCaptionHint(context),
                  ),
                  const SizedBox(height: AppTokens.spacingXxs),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: dosageController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTokens.spacingSm),
                      Expanded(
                        child: DropdownButtonFormField<DosageUnit>(
                          initialValue: dosageUnit,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                          items: DosageUnit.values
                              .map(
                                (u) => DropdownMenuItem(
                                  value: u,
                                  child: Text(u.id),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) onDosageUnitChanged(v);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 时间列表
            Padding(
              padding: const EdgeInsets.only(top: AppTokens.spacingXs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.medAddTimeLabel,
                    style: AppTokens.textStyleCaptionHint(context),
                  ),
                  const SizedBox(height: AppTokens.spacingXs),
                  Wrap(
                    spacing: AppTokens.spacingSm,
                    runSpacing: AppTokens.spacingSm,
                    children: [
                      ...times.asMap().entries.map((e) {
                        final i = e.key;
                        final t = e.value;
                        return InputChip(
                          avatar: const Icon(Icons.access_time, size: 18),
                          label: Text(
                            HourMinute(
                              hour: t.hour,
                              minute: t.minute,
                            ).toTimeString(),
                            // EM-08: InputChip 时间标签 16 (chip 内紧凑
                            // 字号, 无对应 token 档位), deliberate 保留
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: t,
                            );
                            if (picked != null) {
                              onTimeChanged(i, picked);
                            }
                          },
                          onDeleted:
                              times.length > 1 ? () => onTimeDeleted(i) : null,
                        );
                      }),
                      // 添加时间按钮
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 18),
                        label: Text(l10n.medAddTimeAdd),
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(
                              hour: 20,
                              minute: 0,
                            ),
                          );
                          if (picked != null) {
                            onTimeAdded(picked);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
