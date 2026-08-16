// v0.14 (Round 13C) 用药日历入口 + 药物列表渲染
//
// v0.24 (Round 45) 从 medications_list_widget.dart 抽到独立文件
// (god class 拆解样板 · 跟 mood_score_form 同模式: presentation-only 抽出)
//
// 全 StatelessWidget, 状态由 parent 透传 (3 Set 引用)。
// 渲染:
// 1. 用药日历入口 (v0.14 round 13C, v0.32 round 14 ALS 化)
// 2. active list: MedicationRow × N (Dismissible swipe 启用)
//    或 active empty state (MedicationEmptyState.noActive)
// 3. stopped list (可选): MedicationRow × N (Dismissible 关闭)
//
// v0.32 round 14 (R112 F1 遗留): 2 处 Card + AppListTile.carded → 3 处
// AppleListSection (iOS insetGrouped 白块 + hairline 0.5 + 0 阴影,
// spec §4.5), 对齐已 ALS 化的 settings 宿主 (profile_group)。

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/medication_empty_state.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/medication_row.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';

/// 药物列表渲染 (header card + active list + stopped list)
///
/// presentation-only, 业务流程全在 parent (medications_list_widget state class)。
class MedicationListView extends StatelessWidget {
  final List<MedicationEntity> meds;

  /// 3 个状态 Set (引用 parent state, 不复制)
  final Set<int> deleting;
  final Set<int> editing;
  final Set<int> editingRefill;

  /// R114 BUG 6: swipe 删除失败计数 (medId → 次数, 换 Dismissible key 用)
  final Map<int, int> deleteFailCounts;

  /// 4 个业务流程回调 (parent handler)
  final Future<void> Function(int id) onDelete;
  final Future<void> Function(MedicationEntity med) onEdit;
  final Future<void> Function(MedicationEntity med) onEditRefill;
  final Future<void> Function(MedicationEntity med) onSwipeDelete;

  const MedicationListView({
    super.key,
    required this.meds,
    required this.deleting,
    required this.editing,
    required this.editingRefill,
    required this.deleteFailCounts,
    required this.onDelete,
    required this.onEdit,
    required this.onEditRefill,
    required this.onSwipeDelete,
  });

  @override
  Widget build(BuildContext context) {
    final activeMeds = meds.where((m) => m.isActive).toList(growable: false);
    final stoppedMeds = meds.where((m) => !m.isActive).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // v0.14 (Round 13C) 用药日历入口
        if (activeMeds.isNotEmpty) _buildCalendarEntry(context),
        // 在用列表 (或空态)
        if (activeMeds.isEmpty)
          const MedicationEmptyState(kind: MedicationEmptyKind.noActive)
        else
          _buildActiveList(context, activeMeds),
        // 已停药列表（v0.13 Round 9）
        if (stoppedMeds.isNotEmpty) ...[
          const SizedBox(height: AppTokens.spacingSm),
          _buildStoppedHeader(context),
          const SizedBox(height: AppTokens.spacingXs),
          _buildStoppedList(context, stoppedMeds),
        ],
      ],
    );
  }

  Widget _buildCalendarEntry(BuildContext context) {
    // v0.32 round 14 (R112 F1 遗留): AppListTile.carded (Card) →
    // AppleListSection (iOS insetGrouped 白块 + 0 阴影, spec §4.5),
    // 与 settings 宿主 (profile_group) 已 ALS 化的方言对齐
    return AppleListSection(
      margin: EdgeInsets.zero,
      children: [
        AppListTile.standard(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            Icons.calendar_view_month,
            color: AppTokens.primaryColor(context),
          ),
          title: Text(AppLocalizations.of(context).medsCalendarTitle),
          subtitle: Text(AppLocalizations.of(context).medsCalendarSubtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/medication/calendar'),
        ),
      ],
    );
  }

  Widget _buildActiveList(
    BuildContext context,
    List<MedicationEntity> activeMeds,
  ) {
    // v0.32 round 14 (R112 F1 遗留): Card + 手写 Divider → AppleListSection
    // (hairline 0.5 由容器自动串联, cell padding 16/12 由容器提供)
    return AppleListSection(
      margin: EdgeInsets.zero,
      children: [
        for (final med in activeMeds)
          MedicationRow(
            med: med,
            isDeleting: deleting.contains(med.id),
            isEditing: editing.contains(med.id),
            isEditingRefill: editingRefill.contains(med.id),
            onDelete: () => onDelete(med.id),
            onEdit: () => onEdit(med),
            onEditRefill: () => onEditRefill(med),
            onSwipeDelete: onSwipeDelete,
            enableSwipe: true,
            deleteFailCount: deleteFailCounts[med.id] ?? 0,
            contentPadding: EdgeInsets.zero,
          ),
      ],
    );
  }

  Widget _buildStoppedHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: AppTokens.spacingXs),
      child: Text(
        AppLocalizations.of(context).medsListStoppedSection,
        style: TextStyle(
          fontSize: AppTokens.fontSizeCaption,
          color: AppTokens.textHintColor(context),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStoppedList(
    BuildContext context,
    List<MedicationEntity> stoppedMeds,
  ) {
    // v0.32 round 14 (R112 F1 遗留): Card + 手写 Divider → AppleListSection
    return AppleListSection(
      margin: EdgeInsets.zero,
      children: [
        for (final med in stoppedMeds)
          MedicationRow(
            med: med,
            isDeleting: deleting.contains(med.id),
            isEditing: editing.contains(med.id),
            isEditingRefill: false, // 停药不显示续方按钮
            onDelete: () => onDelete(med.id),
            onEdit: () => onEdit(med),
            onEditRefill: () {}, // 停药不调
            onSwipeDelete: onSwipeDelete,
            enableSwipe: false, // 停药不启用 swipe
            deleteFailCount: deleteFailCounts[med.id] ?? 0,
            contentPadding: EdgeInsets.zero,
          ),
      ],
    );
  }
}
