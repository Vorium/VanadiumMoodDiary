// v0.12 (Round 6) 常吃药列表（可编辑、可设置续方、可停药、可删除）
// v0.13 (Round 9) 编辑 + 软停药：edit 按钮 + 停药/恢复开关
// v0.14 (Round 13C) 用药日历入口
// v0.21 (Round 22) 改用统一 EmptyState (P0-11 修复)
// v0.21 (Round 23) swipe-to-dismiss (P1-26)
// v0.22 (Round 30) AppSnackBar 集中化 (sp-zh P1-16) + fgOnError token (emil P2-6)
// v0.24 (Round 45) god class 拆解 (Sprint #5d) —
//   抽 MedicationListView / MedicationRow / MedicationEmptyState / RefillDaysDialog 4 子 widget
//   本文件保留: 3 Set 状态 + 4 handler (业务流程) + delegate build
// v0.32 (Round 14) R112 F1 遗留: 渲染子组件 (MedicationListView) Card →
//   AppleListSection (iOS insetGrouped, spec §4.5), 对齐已 ALS 化的
//   settings 宿主 (profile_group)。本文件业务逻辑 0 改。
//
// 公开 API: MedicationsListWidget({required List<MedicationEntity> meds})
// 调用方: medication_page.dart 等, 公开签名不变 (零改动)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/shared/formatters.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare/features/medication/domain/entities/medication_draft.dart';
import 'package:chroniccare/features/medication/domain/entities/medication_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/edit_medication_dialog.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/medication_empty_state.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/medication_list_view.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/refill_days_dialog.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/feedback.dart';

/// 常吃药列表（可编辑、可设置续方、可停药、可删除）
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

  /// R114 BUG 6 (R113 BUG 7b 同款): swipe 删除失败计数 — 删除失败时
  /// 计数 +1 → 已 dismiss 的旧 Dismissible 换 key unmount, 新 key
  /// remount 回"未滑走"状态, 条目立即回到列表 (DB 里还在)。修前 key
  /// 固定 → 删除失败 rebuild 必抛 "A dismissed Dismissible widget is
  /// still part of the tree"。
  final Map<int, int> _deleteFailCounts = {};

  @override
  Widget build(BuildContext context) {
    if (widget.meds.isEmpty) {
      return const MedicationEmptyState(kind: MedicationEmptyKind.noMeds);
    }
    return MedicationListView(
      meds: widget.meds,
      deleting: _deleting,
      editing: _editing,
      editingRefill: _editingRefill,
      deleteFailCounts: _deleteFailCounts,
      onDelete: _deleteMedication,
      onEdit: _editMedication,
      onEditRefill: _editRefill,
      onSwipeDelete: _swipeDeleteMedication,
    );
  }

  Future<void> _editMedication(MedicationEntity med) async {
    if (_editing.contains(med.id)) return;
    setState(() => _editing.add(med.id));
    try {
      final result = await showEditMedicationDialog(context, med);
      if (!mounted) return;
      if (result ?? false) {
        // v0.27 round 59 (emil EMIL-T13): 用 showInfo 集中器
        AppSnackBar.showInfo(
          context,
          med.isActive
              ? AppLocalizations.of(context).medsSnackUpdated
              : AppLocalizations.of(context).medsSnackUpdatedSoftStop,
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
      await notif.delegate.cancelRefillReminder(id);
      await notif.delegate.cancelSnoozeForMedication(id);
      await ref.read(medicationRepositoryProvider).delete(id);
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          action: AppLocalizations.of(context).commonDelete,
          error: e,
        );
      }
    } finally {
      if (mounted) setState(() => _deleting.remove(id));
    }
  }

  /// v0.21 Round 23 (P1-26): swipe-to-dismiss 触发
  ///
  /// 与 IconButton 删除共享底层逻辑,但跳过 explicit dialog
  /// (Dismissible 的 swipe gesture 本身已表达删除意图,
  /// Undo snackbar 给反悔窗口)。
  ///
  /// R114 BUG 6: catch 补 swallowError + 失败计数换 key + invalidate
  /// (vent_list_page R113 BUG 7b 同款修法 — 修前 catch 只弹 snackbar,
  /// Dismissible 已 dismiss 仍留在树 → 下次 rebuild 抛 FlutterError)。
  Future<void> _swipeDeleteMedication(MedicationEntity med) async {
    if (_deleting.contains(med.id)) return;
    setState(() => _deleting.add(med.id));
    await Haptics.warning();
    try {
      final notif = ref.read(notificationServiceProvider);
      await notif.delegate.cancelRefillReminder(med.id);
      await notif.delegate.cancelSnoozeForMedication(med.id);
      await ref.read(medicationRepositoryProvider).delete(med.id);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      AppSnackBar.undo(
        context,
        message: l10n.medicationDeleted,
        onUndo: () async {
          // 简化: 重新插入(保留 name/dosage/unit/times/startDate/refill)
          // id 会变, 时间戳为 now
          // v0.25 R60: 用 MedicationDraft value object 替代 9 字段 named 参数
          await ref.read(medicationRepositoryProvider).add(
                MedicationDraft(
                  name: med.name,
                  dosage: med.dosage,
                  dosageUnit: med.dosageUnit,
                  times: med.times,
                  refillAt: med.refillAt,
                  refillReminderDays: med.refillReminderDays,
                  startDate: med.startDate,
                  endDate: med.endDate,
                  isActive: med.isActive,
                ),
              );
        },
      );
    } catch (e, st) {
      // R114 BUG 6: 先换 key 卸载已 dismiss 的 Dismissible, 让条目
      // 回到列表 (setState 同步触发 rebuild)
      swallowError(
        where: 'medications_list_widget._swipeDeleteMedication',
        error: e,
        stack: st,
        note: 'medication swipe delete failed — snackbar 已提示用户',
      );
      if (mounted) {
        setState(() {
          _deleteFailCounts[med.id] = (_deleteFailCounts[med.id] ?? 0) + 1;
        });
        AppSnackBar.showError(
          context,
          action: AppLocalizations.of(context).commonDelete,
          error: e,
        );
        // 条目仍留在 DB → 重新拉流让它回到列表
        ref.invalidate(medicationsProvider);
      }
    } finally {
      if (mounted) setState(() => _deleting.remove(med.id));
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
        helpText: AppLocalizations.of(context).medsRefillPickDate,
        cancelText: AppLocalizations.of(context).commonCancel,
        confirmText: AppLocalizations.of(context).commonConfirmOk,
      );
      if (picked == null) return;
      if (!mounted) return;

      // 选提前天数（默认 7）
      final days = await showDialog<int>(
        context: context,
        builder: (ctx) => RefillDaysDialog(initial: med.refillReminderDays),
      );
      if (days == null) return;

      await ref.read(medicationRepositoryProvider).updateRefill(
            medicationId: med.id,
            refillAt: picked,
            reminderDays: days,
          );

      // v0.23 (P0-3 H2 fix): await updateRefill 写完 DB, 但 stream 还在 broadcast
      // 旧值, ref.read 拿 stale list → rescheduleRefillReminders 用旧 refillAt
      // 修: refresh(provider.future) 等 stream 重新 emit, 直接用返回的新值
      final meds = await ref.refresh(medicationsProvider.future);
      // v0.18 (P2-P0-2): notification_service 改接受 entity, 删 mapper 调用
      await ref
          .read(notificationServiceProvider)
          .delegate
          .rescheduleRefillReminders(meds);

      if (!mounted) return;
      // v0.27 round 59 (emil EMIL-T13): 用 showInfo 集中器
      AppSnackBar.showInfo(
        context,
        AppLocalizations.of(context)
            .medsRefillSet(Formatters.date(picked), days),
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          action: AppLocalizations.of(context).commonSetup,
          error: e,
        );
      }
    } finally {
      if (mounted) setState(() => _editingRefill.remove(med.id));
    }
  }
}
