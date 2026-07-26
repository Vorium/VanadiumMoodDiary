// v0.14 (Round 13C) 单个药物行 — ListTile + Dismissible + 3 IconButton
//
// v0.24 (Round 45) 从 medications_list_widget.dart 抽到独立文件
// (god class 拆解样板 · 跟 mood_score_form 同模式: presentation-only 抽出)
//
// 状态全由 parent 透传 (Set 引用, 不复制), 自己只管渲染。
// Dismissible 通过 enableSwipe 参数控制 (active 药启用, stopped 药不启用)。

import 'package:flutter/material.dart';

import 'package:chroniccare/core/shared/formatters.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/chip_badge.dart';

/// 单个药物行 (含 Dismissible swipe-to-dismiss + 3 IconButton)
class MedicationRow extends StatelessWidget {
  final MedicationEntity med;
  final bool isDeleting;
  final bool isEditing;
  final bool isEditingRefill;

  /// 显式 IconButton 删除 (含 confirm dialog, 走 parent handler)
  final VoidCallback onDelete;

  /// 显式 IconButton 编辑 (走 parent handler, 弹 EditMedicationDialog)
  final VoidCallback onEdit;

  /// 显式 IconButton 续方 (走 parent handler, 弹 date picker + RefillDaysDialog)
  final VoidCallback onEditRefill;

  /// Dismissible swipe-to-dismiss 删除 (无 dialog, Undo snackbar 兜底)
  final Future<void> Function(MedicationEntity) onSwipeDelete;

  /// false = stopped 药不启用 swipe (IconButton 路径已覆盖)
  final bool enableSwipe;

  const MedicationRow({
    super.key,
    required this.med,
    required this.isDeleting,
    required this.isEditing,
    required this.isEditingRefill,
    required this.onDelete,
    required this.onEdit,
    required this.onEditRefill,
    required this.onSwipeDelete,
    this.enableSwipe = true,
  });

  @override
  Widget build(BuildContext context) {
    final refillText = _refillSubtitle(med, context);
    final isStopped = !med.isActive;
    final tile = ListTile(
      leading: Icon(
        isStopped ? Icons.medication : Icons.medication_outlined,
        color: isStopped ? AppTokens.textHintColor(context) : AppTokens.primary,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              med.name,
              style: TextStyle(
                decoration: isStopped ? TextDecoration.lineThrough : null,
                color: isStopped ? AppTokens.textHintColor(context) : null,
              ),
            ),
          ),
          if (isStopped) ...[
            const SizedBox(width: 6),
            // v0.24 round 43 (emil P1-01 H-05): 改用 ChipBadge 集中器
            // 替代内联 Container + BoxDecoration + Text
            ChipBadge(
              label: AppLocalizations.of(context).medsListStoppedSection,
              tone: ChipBadgeTone.warning,
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_medSubtitle(med)),
          if (refillText != null && !isStopped) ...[
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
                  color: refillTextColor(med, context),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    refillText,
                    style: TextStyle(
                      fontSize: AppTokens.fontSizeCaption,
                      color: refillTextColor(med, context),
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
              tooltip: AppLocalizations.of(context).commonEdit,
              onPressed: onEdit,
            ),
            if (!isStopped)
              IconButton(
                icon: const Icon(
                  Icons.event_available_outlined,
                  color: AppTokens.primary,
                ),
                tooltip: AppLocalizations.of(context).medsActionRefill,
                onPressed: onEditRefill,
              ),
          ],
          if (!isDeleting && !isEditing && !isEditingRefill)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTokens.error),
              tooltip: AppLocalizations.of(context).commonDelete,
              onPressed: onDelete,
            ),
        ],
      ),
    );

    if (!enableSwipe) return tile;

    // v0.21 Round 23 (P1-26): swipe-to-dismiss 左滑删除
    return Dismissible(
      key: ValueKey('medication-${med.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingLg),
        color: AppTokens.error,
        child: Icon(
          Icons.delete_outline,
          // v0.22 round 30 (emil P2-6): 走 fgOnError
          color: AppTokens.fgOnError(context),
        ),
      ),
      // IconButton 路径已走 onDelete (含 confirm);
      // swipe 路径走 onSwipeDelete (无 dialog, Undo 兜底)
      onDismissed: (_) => onSwipeDelete(med),
      child: tile,
    );
  }

  /// v0.14 fix: 用 entity 的"按天判断"方法，refill day 整天都算 in window
  static Color refillTextColor(MedicationEntity med, BuildContext context) {
    if (med.refillAt == null) return AppTokens.textHintColor(context);
    if (med.isRefillOverdue()) return AppTokens.error;
    if (med.isInRefillWindow()) return AppTokens.warning;
    return AppTokens.textSecondaryColor(context);
  }

  String? _refillSubtitle(MedicationEntity med, BuildContext context) {
    if (med.refillAt == null) {
      return null;
    }
    final now = DateTime.now();
    final days = _daysUntilRefill(med, now);
    final l10n = AppLocalizations.of(context);
    if (med.isRefillOverdue(now)) {
      return l10n.medsRefillOverdue(-days, med.refillReminderDays);
    }
    return l10n.medsRefillUpcoming(
      Formatters.date(med.refillAt!),
      days,
      med.refillReminderDays,
    );
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
        .map(
          (t) =>
              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
        )
        .join(' / ');
    return '$dosage · $timesStr';
  }
}
