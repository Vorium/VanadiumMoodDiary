import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/data/database/mappers/medication/medication_mapper.dart';
import 'package:chroniccare/core/shared/formatters.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/edit_medication_dialog.dart';

/// 常吃药列表（可编辑、可设置续方、可停药、可删除）
///
/// v0.12 (Round 6) 续方提醒：每个药显示"续方日期 + 提前提醒天数"
/// v0.13 (Round 9) 编辑 + 软停药：edit 按钮 + 停药/恢复开关
class MedicationsListWidget extends ConsumerStatefulWidget {
  final List<MedicationEntity> meds;
  const MedicationsListWidget({super.key, required this.meds});

  @override
  ConsumerState<MedicationsListWidget> createState() =>
      _MedicationsListWidgetState();
}

class _MedicationsListWidgetState extends ConsumerState<MedicationsListWidget> {
  final Set<int> _deleting = {};
  final Set<int> _editingRefill = {};
  final Set<int> _editing = {};

  @override
  Widget build(BuildContext context) {
    final activeMeds =
        widget.meds.where((m) => m.isActive).toList(growable: false);
    final stoppedMeds =
        widget.meds.where((m) => !m.isActive).toList(growable: false);

    if (widget.meds.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppTokens.spacingMd),
          child: Text('还没添加常吃药', style: TextStyle(color: AppTokens.textHint)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // v0.14 (Round 13C) 用药日历入口
        if (activeMeds.isNotEmpty)
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_view_month,
                  color: AppTokens.primary,),
              title: const Text('用药日历'),
              subtitle: const Text('医生视角依从性热力图 · 7/30/90 天'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/medication/calendar'),
            ),
          ),
        // 在用列表
        if (activeMeds.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(AppTokens.spacingMd),
              child: Text(
                '没有在用的药',
                style: TextStyle(color: AppTokens.textHint),
              ),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (int i = 0; i < activeMeds.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _MedicationRow(
                    med: activeMeds[i],
                    isDeleting: _deleting.contains(activeMeds[i].id),
                    isEditing: _editing.contains(activeMeds[i].id),
                    isEditingRefill: _editingRefill.contains(activeMeds[i].id),
                    onDelete: () => _deleteMedication(activeMeds[i].id),
                    onEdit: () => _editMedication(activeMeds[i]),
                    onEditRefill: () => _editRefill(activeMeds[i]),
                  ),
                ],
              ],
            ),
          ),
        // 已停药列表（v0.13 Round 9）
        if (stoppedMeds.isNotEmpty) ...[
          const SizedBox(height: AppTokens.spacingSm),
          const Padding(
            padding: EdgeInsets.only(left: 4, top: AppTokens.spacingXs),
            child: Text(
              '已停药',
              style: TextStyle(
                fontSize: AppTokens.fontSizeCaption,
                color: AppTokens.textHint,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spacingXs),
          Card(
            child: Column(
              children: [
                for (int i = 0; i < stoppedMeds.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _MedicationRow(
                    med: stoppedMeds[i],
                    isDeleting: _deleting.contains(stoppedMeds[i].id),
                    isEditing: _editing.contains(stoppedMeds[i].id),
                    isEditingRefill: false, // 停药不显示续方按钮
                    onDelete: () => _deleteMedication(stoppedMeds[i].id),
                    onEdit: () => _editMedication(stoppedMeds[i]),
                    onEditRefill: () {}, // 停药不调
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _editMedication(MedicationEntity med) async {
    if (_editing.contains(med.id)) return;
    setState(() => _editing.add(med.id));
    try {
      final result = await showEditMedicationDialog(context, med);
      if (!mounted) return;
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              med.isActive ? '已更新' : '已更新 · 软停',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _editing.remove(med.id));
    }
  }

  Future<void> _deleteMedication(int id) async {
    if (_deleting.contains(id)) return;
    setState(() => _deleting.add(id));
    try {
      // 取消该药的所有相关推送
      final notif = ref.read(notificationServiceProvider);
      await notif.cancelRefillReminder(id);
      await notif.cancelSnoozeForMedication(id);
      await ref.read(medicationRepositoryProvider).delete(id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting.remove(id));
    }
  }

  /// 编辑续方设置：弹 dialog 选日期 + 提前天数
  Future<void> _editRefill(MedicationEntity med) async {
    if (_editingRefill.contains(med.id)) return;
    setState(() => _editingRefill.add(med.id));
    try {
      // v0.16 round 19 fix: 之前 3 次 DateTime.now() 跨 midnight 时 initialDate/firstDate/lastDate 可能不一致
      // 统一在 await 之前算一次 now, 避免理论上 midnight 边界 race
      final now = DateTime.now();
      final initialDate = med.refillAt ?? now.add(const Duration(days: 30));
      final picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: now.subtract(const Duration(days: 7)),
        lastDate: now.add(const Duration(days: 365)),
        helpText: '选择续方日期',
        cancelText: '取消',
        confirmText: '确定',
      );
      if (picked == null) return;
      if (!mounted) return;

      // 选提前天数（默认 7）
      final days = await showDialog<int>(
        context: context,
        builder: (ctx) => _RefillDaysDialog(initial: med.refillReminderDays),
      );
      if (days == null) return;

      await ref.read(medicationRepositoryProvider).updateRefill(
            medicationId: med.id,
            refillAt: picked,
            reminderDays: days,
          );

      // 重排续方提醒
      final meds =
          await ref.read(medicationRepositoryProvider).watchAll().first;
      // v0.13 (Round 11): 4 层架构 — entity → Drift row 转换
      final driftRows = meds.map((e) => e.toDriftRow()).toList();
      await ref
          .read(notificationServiceProvider)
          .rescheduleRefillReminders(driftRows);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已设置：${Formatters.date(picked)} 续方，提前 $days 天提醒'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('设置失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _editingRefill.remove(med.id));
    }
  }
}

/// 单个药的行（ListTile 复杂时拆出来）
class _MedicationRow extends StatelessWidget {
  final MedicationEntity med;
  final bool isDeleting;
  final bool isEditing;
  final bool isEditingRefill;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onEditRefill;
  const _MedicationRow({
    required this.med,
    required this.isDeleting,
    required this.isEditing,
    required this.isEditingRefill,
    required this.onDelete,
    required this.onEdit,
    required this.onEditRefill,
  });

  @override
  Widget build(BuildContext context) {
    final refillText = _refillSubtitle(med);
    final isStopped = !med.isActive;
    return ListTile(
      leading: Icon(
        isStopped ? Icons.medication_outlined : Icons.medication_outlined,
        color: isStopped ? AppTokens.textHint : AppTokens.primary,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              med.name,
              style: TextStyle(
                decoration: isStopped ? TextDecoration.lineThrough : null,
                color: isStopped ? AppTokens.textHint : null,
              ),
            ),
          ),
          if (isStopped) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppTokens.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTokens.radiusChip),
              ),
              child: const Text(
                '已停药',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTokens.warning,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_medSubtitle(med)),
          if (refillText != null && isStopped == false) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  // v0.14 fix: 跟文字同源（entity.isInRefillWindow），
                  // 旧用 raw isBefore 会和 refillTextColor 不同步
                  med.isInRefillWindow() || med.isRefillOverdue()
                      ? Icons.warning_amber_outlined
                      : Icons.event_outlined,
                  size: 14,
                  color: refillTextColor(med),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    refillText,
                    style: TextStyle(
                      fontSize: AppTokens.fontSizeCaption,
                      color: refillTextColor(med),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      isThreeLine: refillText != null && !isStopped,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isEditing || isEditingRefill || isDeleting)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            // 编辑按钮（v0.13 Round 9）
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTokens.primary),
              tooltip: '编辑',
              onPressed: onEdit,
            ),
            if (!isStopped)
              IconButton(
                icon: const Icon(Icons.event_available_outlined,
                    color: AppTokens.primary,),
                tooltip: '设置续方',
                onPressed: onEditRefill,
              ),
          ],
          if (!isDeleting && !isEditing && !isEditingRefill)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTokens.error),
              tooltip: '删除',
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }

  static Color refillTextColor(MedicationEntity med) {
    if (med.refillAt == null) return AppTokens.textHint;
    // v0.14 fix: 用 entity 的"按天判断"方法，refill day 整天都算 in window
    if (med.isRefillOverdue()) return AppTokens.error;
    if (med.isInRefillWindow()) return AppTokens.warning;
    return AppTokens.textSecondary;
  }

  String? _refillSubtitle(MedicationEntity med) {
    if (med.refillAt == null) {
      return null; // 没设过续方日期 = 不显示这行
    }
    final now = DateTime.now();
    final days = _daysUntilRefill(med, now);
    if (med.isRefillOverdue(now)) {
      return '已过期 ${-days} 天 · 提前 ${med.refillReminderDays} 天提醒';
    }
    return '续方：${Formatters.date(med.refillAt!)} '
        '($days 天后) · 提前 ${med.refillReminderDays} 天提醒';
  }

  /// 按"天"计算 refill 距今多少天（负数=已过期）
  static int _daysUntilRefill(MedicationEntity med, DateTime now) {
    if (med.refillAt == null) return 0;
    final today = DateTime(now.year, now.month, now.day);
    final refillDay = DateTime(
      med.refillAt!.year,
      med.refillAt!.month,
      med.refillAt!.day,
    );
    return refillDay.difference(today).inDays;
  }

  String _medSubtitle(MedicationEntity med) {
    final dosage = Formatters.dosage(med.dosage, med.dosageUnit);
    final times = med.times;
    if (times.isEmpty) return dosage;
    final timesStr = times
        .map((t) =>
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',)
        .join(' / ');
    return '$dosage · $timesStr';
  }
}

/// 续方提前天数选择 dialog
class _RefillDaysDialog extends StatefulWidget {
  final int initial;
  const _RefillDaysDialog({required this.initial});
  @override
  State<_RefillDaysDialog> createState() => _RefillDaysDialogState();
}

class _RefillDaysDialogState extends State<_RefillDaysDialog> {
  late int _selected;
  static const _options = [3, 5, 7, 14, 30];

  @override
  void initState() {
    super.initState();
    _selected = _options.contains(widget.initial) ? widget.initial : 7;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('提前几天提醒？'),
      content: RadioGroup<int>(
        groupValue: _selected,
        onChanged: (v) {
          if (v != null) setState(() => _selected = v);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final d in _options)
              RadioListTile<int>(
                value: d,
                title: Text('$d 天'),
                subtitle: Text(_hintFor(d)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('确定'),
        ),
      ],
    );
  }

  String _hintFor(int d) {
    switch (d) {
      case 3:
        return '最后冲刺期';
      case 5:
        return '比较紧';
      case 7:
        return '推荐（默认）';
      case 14:
        return '两周时间挂号';
      case 30:
        return '一个月周期';
      default:
        return '';
    }
  }
}
