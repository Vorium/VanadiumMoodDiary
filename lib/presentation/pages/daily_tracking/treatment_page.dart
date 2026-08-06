// v0.30 round 92 (audit-fixes / P0 #15): treatment_page 真页面
//
// 背景:
// - R91 Task 3 加了 treatment_entries 表 + TreatmentRepositoryImpl +
//   submitEntry() (写时 snapshot medication name)
// - R91 Task 5 整合入口页 "治疗" 卡片 → 跳 /treatment 路由
// - R91 兜底: treatment_placeholder.dart 显示 R91 "治疗 entry 显示 (写入功能
//   v0.31+ 跟 medication picker 整合)" 占位, 0 写入入口
//
// R92 修法:
// - 删 treatment_placeholder.dart, 新建 treatment_page.dart (含 list + FAB
//   + AddTreatmentDialog, 4 字段: date / category / provider / note)
// - 复用 R91 treatmentEntriesProvider (StreamProvider.autoDispose) +
//   treatmentRepositoryProvider.add() API
// - 4 字段 schema 兼容 R91: date→timestamp (default now), category→treatmentType
//   (4 选 1 free String: medication_adjustment / consultation /
//   hospitalization / other), provider→description (String), note→note (String)
// - 复用 PageScaffold + EmptyState + AppListTile (跟 R91 sleep_widgets 风格一致)
//
// 4 层架构: presentation/pages/daily_tracking/, 0 跨 feature import。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/treatment_add_dialog.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/treatment_list.dart';
import 'package:chroniccare/presentation/providers/daily_tracking_providers.dart';
import 'package:chroniccare/presentation/widgets/empty_state.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';

/// 治疗记录页 (R91 兜底 placeholder → R92 真页面)
class TreatmentPage extends ConsumerWidget {
  const TreatmentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final entriesAsync = ref.watch(treatmentEntriesProvider);

    return PageScaffold(
      title: l10n.treatmentName,
      child: Column(
        children: [
          // 顶部添加按钮 (R91 sleep_widgets 风格 — 不用 FAB, list 页面通常
          // FAB 被 Card 占用, 走 FilledButton.icon 在右上角)
          Padding(
            padding: AppTokens.edgeInsetsXs,
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                icon: const Icon(Icons.add),
                label: Text(l10n.treatmentAddButton),
                onPressed: () => AddTreatmentDialog.show(context),
              ),
            ),
          ),
          Expanded(
            child: entriesAsync.when(
              loading: () => const LoadingSkeleton.fullScreen(),
              error: (e, st) => Center(child: Text(l10n.commonLoadFailed(e.toString()))),
              data: (entries) => entries.isEmpty
                  ? EmptyState(
                      icon: Icons.medical_services_outlined,
                      title: l10n.treatmentNoData,
                      subtitle: l10n.treatmentHint,
                    )
                  : TreatmentList(entries: entries),
            ),
          ),
        ],
      ),
    );
  }
}
