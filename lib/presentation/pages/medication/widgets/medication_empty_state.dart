// v0.24 (Round 45) medications_list god class 拆解
//
// 抽 MedicationEmptyState 集中器 — 复用 2 种空态:
// 1. 全空 (meds.isEmpty): "还没有添加药物" + 添加按钮
// 2. 无 active (activeMeds.isEmpty): "暂未在用药物" + 提示 + 添加按钮
//
// 替代原 medications_list_widget.dart 2 处 inline EmptyState 调用。
// 跟 mood_dialog 拆 mood_score_form 模式一致 (单一职责 + 集中器)。

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/empty_state.dart';

/// 空态类型
enum MedicationEmptyKind {
  /// 全空: 用户还没添加任何药物
  noMeds,

  /// 无 active: 有药物但全部已停
  noActive,
}

/// 药物列表空态
///
/// 跟 `EmptyState` 集中器 (lib/presentation/widgets/empty_state.dart) 配合使用,
/// 内部根据 [kind] 选不同 icon / title / subtitle, 统一走 l10n。
class MedicationEmptyState extends StatelessWidget {
  final MedicationEmptyKind kind;
  const MedicationEmptyState({super.key, required this.kind});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (kind) {
      case MedicationEmptyKind.noMeds:
        return EmptyState(
          icon: Icons.medication_outlined,
          title: l10n.medsListEmpty,
          actionLabel: l10n.medsListAddAction,
          onAction: () => GoRouter.of(context).push('/medication/add'),
        );
      case MedicationEmptyKind.noActive:
        return EmptyState(
          icon: Icons.check_circle_outline,
          title: l10n.medsListNoActive,
          subtitle: l10n.medsListNoActiveHint,
          actionLabel: l10n.medsListAddAction,
          onAction: () => GoRouter.of(context).push('/medication/add'),
        );
    }
  }
}
