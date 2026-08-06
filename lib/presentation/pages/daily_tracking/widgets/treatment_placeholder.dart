// v0.30 round 91 (sub-spec 7 日常追踪 / Task 5 整合入口): 治疗记录页 placeholder
//
// 背景:
// - Task 3 加了 treatment_entries 表 + TreatmentRepositoryImpl + DAO join
//   medication 联动, 写了 unit test
// - Task 4 5 子功能 UI 没包含 treatment (只做 sleep/social_rhythm/stress/
//   weight/anxiety, treatment 跟 medication 联动留给 v0.31+)
// - Task 5 整合入口页"治疗"卡片需要 tap 跳的目标 route
//
// 兜底 (brief 允许): 临时 placeholder 列表页, 复用 treatmentEntriesProvider
// 显示现有 entry 列表 + 显示 medication 联动 (linkedMedicationName), 不含
// entry dialog。TreatmentEntryDialog 留 v0.31+ (跟 medication picker 整合)。
//
// 4 层架构: presentation/pages/daily_tracking/widgets/, 0 跨 feature import。
//
// v0.30 R91 Task 7: i18n — 替换 hardcoded 中文 placeholder 走 l10n
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/daily_tracking_providers.dart';
import 'package:chroniccare/presentation/widgets/empty_state.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';

/// v0.30 R91 Task 5 兜底: 治疗记录页 placeholder
///
/// 显示现有 treatment entry 列表 (R91 brief 兜底, Task 4 没做 treatment
/// widget, Task 5 加最小可用 list page 防止 整合页 /treatment 路由 404)。
/// 写入 (entry dialog) 留 v0.31+ (跟 medication picker 整合)。
class TreatmentPlaceholderPage extends ConsumerWidget {
  const TreatmentPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final entriesAsync = ref.watch(treatmentEntriesProvider);

    return Column(
      children: [
        // 顶部说明 (placeholder 标记, v0.31+ 删)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTokens.spacingSm),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Text(
            'R91 兜底: 治疗 entry 显示 (写入功能 v0.31+ 跟 medication picker 整合)',
            style: AppTokens.textStyleCaption(context),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: entriesAsync.when(
            loading: () => const LoadingSkeleton.fullScreen(),
            error: (e, st) => Center(child: Text('加载失败: $e')),
            data: (entries) => entries.isEmpty
                ? EmptyState(
                    icon: Icons.medical_services_outlined,
                    title: l10n.treatmentNoData,
                    subtitle: l10n.treatmentHint,
                  )
                : ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, i) {
                      final e = entries[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppTokens.spacingSm,
                          vertical: AppTokens.spacingXxs,
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.medical_services,
                            color: AppTokens.primaryColor(context),
                          ),
                          title: Text(
                            l10n.treatmentLast(e.treatmentType, e.description),
                            style: AppTokens.textStyleLabelStrong(context),
                          ),
                          subtitle: Text(
                            '关联用药: ${e.linkedMedicationDisplay}',
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
