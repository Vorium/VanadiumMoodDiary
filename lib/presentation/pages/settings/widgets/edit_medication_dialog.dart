// v0.13 (Round 9) 药物编辑 dialog
//
// 复用 setup_page 的"药物卡片"字段：name / dosage / unit / times，
// 但保存路径不同：调 MedicationRepository.update。
// 同时加"停药 / 恢复"开关（isActive 软停，保留历史）。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/database/medication_mapper.dart';
import '../../../../shared/domain_value.dart';
import '../../../../shared/formatters.dart';
import '../../../../domain/entities/hour_minute.dart';
import '../../../../domain/entities/medication_entity.dart';
import '../../../../theme/app_tokens.dart';
import '../../../providers/core_providers.dart';

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

class _EditMedicationDialogState
    extends ConsumerState<_EditMedicationDialog> {
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
  String? _validate() {
    if (_nameController.text.trim().isEmpty) return '请填写药名';
    final dosage = double.tryParse(_dosageController.text.trim());
    if (dosage == null || dosage <= 0) return '剂量必须是大于 0 的数字';
    if (_dosageUnit != 'mg' && _dosageUnit != '片') {
      return '单位必须是 mg 或 片';
    }
    return null;
  }

  Future<void> _save() async {
    final err = _validate();
    if (err != null) {
      setState(() => _errorText = err);
      return;
    }
    if (_saving) return;
    setState(() {
      _saving = true;
      _errorText = null;
    });

    final dosage = double.parse(_dosageController.text.trim());
    final original = widget.med;
    final isActiveChanged = _isActive != original.isActive;

    // 构造更新后的 Medication
    // 1) 基础字段（UI 用 TimeOfDay，保存时转 HourMinute）
    var updated = original.copyWith(
      name: _nameController.text.trim(),
      dosage: dosage,
      dosageUnit: _dosageUnit,
      times: _times.map((t) => HourMinute(hour: t.hour, minute: t.minute)).toList(),
      isActive: _isActive,
    );
    // 2) isActive 变化时同步 endDate（停药/恢复的语义）
    if (isActiveChanged) {
      updated = _isActive
          ? updated.copyWith(endDate: const DomainValue<DateTime?>(null)) // 恢复
          : updated.copyWith(endDate: DomainValue<DateTime?>(DateTime.now())); // 停药
    }

    try {
      await ref.read(medicationRepositoryProvider).update(updated);
      // 改完重排该药的所有相关推送
      final notif = ref.read(notificationServiceProvider);
      final meds = await ref.read(medicationRepositoryProvider).watchAll().first;
      // v0.13 (Round 11): 4 层架构 — entity → Drift row 转换
      final driftRows = meds.map((e) => e.toDriftRow()).toList();
      // medication reminders: 整个重排（停药会自然被 reschedule 排除）
      await notif.rescheduleMedicationReminders(driftRows);
      // refill reminders: 整个重排
      await notif.rescheduleRefillReminders(driftRows);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _errorText = '保存失败：${e.toString().split('\n').first}';
        });
      }
    }
  }

  Future<void> _pickTime() async {
    final initial = _times.isNotEmpty
        ? _times.last
        : const TimeOfDay(hour: 8, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        _times.add(picked);
        _times.sort((a, b) =>
            (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.med;
    return AlertDialog(
      title: const Text('编辑药物'),
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
                    ? AppTokens.primaryLight
                    : AppTokens.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTokens.radiusChip),
              ),
              child: Row(
                children: [
                  Icon(
                    _isActive ? Icons.check_circle_outline : Icons.pause_circle,
                    size: 16,
                    color:
                        _isActive ? AppTokens.primary : AppTokens.warning,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isActive ? '正在使用' : '已停药',
                    style: TextStyle(
                      fontSize: AppTokens.fontSizeCaption,
                      color: _isActive
                          ? AppTokens.primary
                          : AppTokens.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (m.endDate != null && !_isActive) ...[
                    const Spacer(),
                    Text(
                      '${Formatters.date(m.endDate!)} 停药',
                      style: const TextStyle(
                        fontSize: AppTokens.fontSizeCaption,
                        color: AppTokens.textHint,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppTokens.spacingSm),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '药名',
                hintText: '氟西汀 / 奥氮平',
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
                    decoration: const InputDecoration(
                      labelText: '剂量',
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
                    decoration: const InputDecoration(labelText: '单位'),
                    items: const [
                      DropdownMenuItem(value: 'mg', child: Text('mg')),
                      DropdownMenuItem(value: '片', child: Text('片')),
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
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '吃药时间（点 + 加）',
                style: TextStyle(
                  fontSize: AppTokens.fontSizeLabel,
                  color: AppTokens.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: AppTokens.spacingXs),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < _times.length; i++)
                  InputChip(
                    label: Text(_formatTime(_times[i])),
                    onDeleted: () {
                      setState(() => _times.removeAt(i));
                    },
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('加时间'),
                  onPressed: _saving ? null : _pickTime,
                ),
              ],
            ),
            if (_times.isEmpty)
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
            const SizedBox(height: AppTokens.spacingSm),
            // 停药/恢复 开关
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                _isActive ? '停用此药' : '重新启用',
                style: TextStyle(
                  fontSize: AppTokens.fontSizeBody,
                  color: _isActive ? AppTokens.warning : AppTokens.primary,
                ),
              ),
              subtitle: Text(
                _isActive
                    ? '软停：保留所有打卡历史，不再推送提醒'
                    : '恢复：清空停药日期，恢复每日提醒',
                style: const TextStyle(
                  fontSize: AppTokens.fontSizeCaption,
                  color: AppTokens.textHint,
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
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('保存'),
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
