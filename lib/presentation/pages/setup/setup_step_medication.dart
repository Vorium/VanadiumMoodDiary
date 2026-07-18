// setup_step_medication.dart — 首次设置 Step 2: 药物列表
//
// 从 setup_page.dart 拆分，v0.19 (Q2)
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/setup/setup_widgets.dart';

/// Step 2: 药物列表
///
/// 用户添加/编辑常吃药物 + 时间。
/// 药物列表（_meds）由父级管理。
class SetupStepMedication extends StatelessWidget {
  final List<MedDraft> meds;
  final bool saving;
  final VoidCallback onAddMed;
  final VoidCallback onShowPresets;
  final ValueChanged<int> onRemoveMed;
  final VoidCallback onBack;
  final VoidCallback onFinish;

  const SetupStepMedication({
    super.key,
    required this.meds,
    required this.saving,
    required this.onAddMed,
    required this.onShowPresets,
    required this.onRemoveMed,
    required this.onBack,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      key: const ValueKey(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppTokens.spacingXl),
          const Text(
            '你常吃什么药？',
            style: TextStyle(
              fontSize: AppTokens.fontSizeTitle,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          const Text(
            '（可加多个药，每个药配自己的时间和剂量；跳过不影响打卡）',
            style: TextStyle(
              fontSize: AppTokens.fontSizeBody,
              color: AppTokens.textSecondary,
            ),
          ),
          const SizedBox(height: AppTokens.spacingXl),
          for (int i = 0; i < meds.length; i++) ...[
            MedCard(
              index: i,
              med: meds[i],
              onRemove: () => onRemoveMed(i),
            ),
            const SizedBox(height: AppTokens.spacingMd),
          ],
          if (meds.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppTokens.spacingMd),
              decoration: BoxDecoration(
                color: AppTokens.primaryLight,
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                border: Border.all(color: AppTokens.border),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTokens.textSecondary,
                    size: 20,
                  ),
                  SizedBox(width: AppTokens.spacingXs),
                  Expanded(
                    child: Text(
                      '还没添加药物。可以跳过——打卡不需要药物信息。',
                      style: TextStyle(
                        color: AppTokens.textSecondary,
                        fontSize: AppTokens.fontSizeLabel,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox.shrink(),
          const SizedBox(height: AppTokens.spacingMd),
          OutlinedButton.icon(
            onPressed: onAddMed,
            icon: const Icon(Icons.add),
            label: const Text('+ 添加药物'),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          TextButton.icon(
            onPressed: onShowPresets,
            icon: const Icon(Icons.auto_awesome_outlined, size: 18),
            label: const Text('📋 载入预置方案（4 种常见模式）'),
          ),
          const SizedBox(height: AppTokens.spacingXl),
          Row(
            children: [
              TextButton(
                onPressed: saving ? null : onBack,
                child: const Text('← 上一步'),
              ),
              const Spacer(),
              SizedBox(
                width: 110,
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: saving ? null : onFinish,
                      child: Text(l10n.setupNext),
                    ),
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
          ),
        ],
      ),
    );
  }
}

/// 单个药物卡片（从 setup_page._buildMedCard 提取）
class MedCard extends StatelessWidget {
  final int index;
  final MedDraft med;
  final VoidCallback onRemove;

  const MedCard({
    super.key,
    required this.index,
    required this.med,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  '药物 ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: AppTokens.fontSizeBody,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppTokens.error,
                  ),
                  tooltip: '删除这个药',
                  onPressed: onRemove,
                ),
              ],
            ),
            TextField(
              controller: med.nameController,
              decoration: InputDecoration(
                labelText: l10n.commonMedName,
                hintText: '请输入药盒上的名称（选填）',
              ),
            ),
            const SizedBox(height: AppTokens.spacingMd),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: med.dosageController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: '剂量',
                      hintText: '40',
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.spacingSm),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: med.dosageUnit,
                    decoration: const InputDecoration(labelText: '单位'),
                    items: [
                      const DropdownMenuItem(value: 'mg', child: Text('mg')),
                      DropdownMenuItem(
                        value: '片',
                        child: Text(l10n.commonDoseUnit),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        med.dosageUnit = v;
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spacingMd),
            const Text(
              '吃药时间（点 + 加）',
              style: TextStyle(
                fontSize: AppTokens.fontSizeLabel,
                color: AppTokens.textSecondary,
              ),
            ),
            const SizedBox(height: AppTokens.spacingXs),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int tIdx = 0; tIdx < med.times.length; tIdx++)
                  InputChip(
                    label: Text(_formatTime(med.times[tIdx])),
                    onDeleted: () => med.times.removeAt(tIdx),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('加时间'),
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: med.times.isNotEmpty
                          ? med.times.last
                          : const TimeOfDay(hour: 8, minute: 0),
                    );
                    if (picked != null && context.mounted) {
                      med.times.add(picked);
                      med.times.sort(
                        (a, b) => (a.hour * 60 + a.minute)
                            .compareTo(b.hour * 60 + b.minute),
                      );
                    }
                  },
                ),
              ],
            ),
            if (med.times.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  '（不设置时间 = 不调度提醒，仅记录）',
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeCaption,
                    color: AppTokens.textHint,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
