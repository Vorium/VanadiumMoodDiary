// v0.14 (Round 13C) 单个药物行 — ListTile + Dismissible + 3 IconButton
//
// v0.24 (Round 45) 从 medications_list_widget.dart 抽到独立文件
// (god class 拆解样板 · 跟 mood_score_form 同模式: presentation-only 抽出)
//
// 状态全由 parent 透传 (Set 引用, 不复制), 自己只管渲染。
// Dismissible 通过 enableSwipe 参数控制 (active 药启用, stopped 药不启用)。

import 'package:flutter/material.dart';

import 'package:chroniccare/core/shared/formatters.dart';
import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/features/medication/domain/entities/medication_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/chip_badge.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/widgets/press_feedback_icon_button.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';
import 'package:chroniccare/presentation/widgets/swipe_delete_background.dart';

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

  /// R114 BUG 6 (R113 BUG 7b 同款): 删除失败计数 — swipe 删除失败时
  /// parent 计数 +1 → Dismissible key 变 → 已 dismiss 的旧 Dismissible
  /// unmount, 新 key remount 回"未滑走"状态 (条目回到列表)。
  /// 修前 key 固定 `medication-<id>` → 删除失败 rebuild 必抛
  /// "A dismissed Dismissible widget is still part of the tree"。
  final int deleteFailCount;

  /// v0.32 round 14 (R112 F1 遗留): ListTile contentPadding 透传 —
  /// 放进 AppleListSection 时传 EdgeInsets.zero (cell padding 16/12
  /// 由容器提供, 避免 ListTile 自带 16 横向 double padding)
  final EdgeInsetsGeometry? contentPadding;

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
    this.deleteFailCount = 0,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final refillText = _refillSubtitle(med, context);
    final isStopped = !med.isActive;
    // v0.26 round 57 (emil C-12): 走 AppListTile.standard 集中器
    // 替代 inline ListTile (Dismissible 包裹, 不影响 ListTile 本身)
    final tile = AppListTile.standard(
      contentPadding: contentPadding,
      leading: Icon(
        isStopped ? Icons.medication : Icons.medication_outlined,
        color: isStopped
            ? AppTokens.textHintColor(context)
            : AppTokens.primaryColor(context),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              med.name,
              // 注: 不走 textStyleBody 集中器, 因为原 inline TextStyle
              // 没 fontSize, 走 ListTile.title 默认 (16/w400) 视觉一致
              // 故意保留 TextStyle 透传给 ListTile 内嵌标题
              style: TextStyle(
                decoration: isStopped ? TextDecoration.lineThrough : null,
                color: isStopped ? AppTokens.textHintColor(context) : null,
              ),
            ),
          ),
          if (isStopped) ...[
            const SizedBox(width: AppTokens.spacingChipGap),
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
            const SizedBox(height: AppTokens.spacingXxxs),
            Row(
              children: [
                Icon(
                  // v0.14 fix: 跟文字同源（entity.isInRefillWindow），
                  // 旧用 raw isBefore 会和 refillTextColor 不同步
                  med.isInRefillWindow() || med.isRefillOverdue()
                      ? Icons.warning_amber_outlined
                      : Icons.event_outlined,
                  size: AppTokens.iconSizeSmall,
                  color: refillTextColor(med, context),
                ),
                const SizedBox(width: AppTokens.spacingXxs),
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
            // v0.27 R70 (重构 B-1): 走 LoadingSpinner 集中器替代 inline
            // CircularProgressIndicator (统一 strokeWidth / 默认 size 24)
            const LoadingSpinner(size: 18)
          else ...[
            // 编辑按钮（v0.13 Round 9）
            // v0.26 round 57 (emil B-11): 走 PressFeedbackIconButton 集中器
            PressFeedbackIconButton(
              icon: Icons.edit_outlined,
              tooltip: AppLocalizations.of(context).commonEdit,
              onPressed: onEdit,
              color: AppTokens.primaryColor(context),
            ),
            if (!isStopped)
              PressFeedbackIconButton(
                icon: Icons.event_available_outlined,
                tooltip: AppLocalizations.of(context).medsActionRefill,
                onPressed: onEditRefill,
                color: AppTokens.primaryColor(context),
              ),
          ],
          if (!isDeleting && !isEditing && !isEditingRefill)
            // v0.26 round 57 (emil B-11): 走 PressFeedbackIconButton 集中器
            PressFeedbackIconButton(
              icon: Icons.delete_outline,
              tooltip: AppLocalizations.of(context).commonDelete,
              onPressed: onDelete,
              color: AppTokens.errorColor(context),
            ),
        ],
      ),
    );

    if (!enableSwipe) return tile;

    // v0.21 Round 23 (P1-26): swipe-to-dismiss 左滑删除
    return Dismissible(
      // R114 BUG 6: key 带失败计数 (vent_list_page.dart:311 同款修法)
      key: ValueKey('medication-${med.id}-$deleteFailCount'),
      direction: DismissDirection.endToStart,
      background: const SwipeDeleteBackground(),
      // IconButton 路径已走 onDelete (含 confirm);
      // swipe 路径走 onSwipeDelete (无 dialog, Undo 兜底)
      onDismissed: (_) => onSwipeDelete(med),
      child: tile,
    );
  }

  /// v0.14 fix: 用 entity 的"按天判断"方法，refill day 整天都算 in window
  static Color refillTextColor(MedicationEntity med, BuildContext context) {
    if (med.refillAt == null) return AppTokens.textHintColor(context);
    if (med.isRefillOverdue()) return AppTokens.errorColor(context);
    if (med.isInRefillWindow()) return AppTokens.warningColor(context);
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
