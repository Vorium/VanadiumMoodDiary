// v0.30 round 90 (sub-spec 6 量表中心): 中心化入口页
//
// 路径: `/assessment-center`
// 12 卡片 grid (10 开放 + 2 TODO 标 unavailable)
// 顶部: 12 量表叠加 mini 趋势图 (Task 5 实施)
//
// 4 层架构: presentation/pages/assessment/, 0 跨 page 引用,
// 只用 presentation/providers/ + core/ + domain/ + 同 page widget.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/data/feature_flags.dart';
import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/features/assessment/domain/entities/assessment_entry.dart';
import 'package:chroniccare/features/assessment/domain/logic/assessment_scale.dart';
import 'package:chroniccare/domain/logic/scale_registry.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/assessment/widgets/assessment_center_card.dart';
import 'package:chroniccare/presentation/pages/assessment/widgets/assessment_unavailable_card.dart';
import 'package:chroniccare/presentation/providers/assessment_providers.dart';
import 'package:chroniccare/presentation/widgets/charts/assessment_multi_line_chart.dart';
import 'package:chroniccare/presentation/widgets/error_state.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';

/// 中心化入口页 — 12 量表卡片 grid
///
/// 复用 R60 AssessmentScale 抽象 + Task 1-3 const scale class + scale_registry.
/// 不开新表, 走 check_ins 表 type=`[scale_id]` 跨量表聚合.
///
/// v0.30 R90 Task 6: title 走 l10n.assessmentCenterTitle.
///
/// v0.30 round 93 (阶段 2 audit-fixes): PHQ-9 / GAD-7 16 题 i18n 不完整
/// (en / zh_Hant 法律责任 + 翻译), 走 [FeatureFlags.phqGad7I18nEnabled]
/// gate, 默认 false 隐藏。保留 8 量表 (ISI / PSS / WHODAS / Level2-* 4 /
/// ASRM)。
class AssessmentCenterPage extends ConsumerWidget {
  const AssessmentCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // v0.30 round 93: PHQ-9 / GAD-7 走 [FeatureFlags.phqGad7I18nEnabled] gate,
    // false 时从 scales 列表过滤掉 (8 量表 → 6 显, 实际 10 → 8)。
    final allScalesList = ref.watch(allScalesProvider);
    final scales = FeatureFlags.phqGad7I18nEnabled
        ? allScalesList
        : allScalesList.where((s) => s.id != 'phq9' && s.id != 'gad7').toList();
    final entriesAsync = ref.watch(allAssessmentEntriesProvider);
    const unavailableIds = unavailableScaleIds;

    return PageScaffold(
      title: l10n.assessmentCenterTitle,
      child: entriesAsync.when(
        // v0.32 round 8 (R111 EM-15 fix): LoadingSpinner + ErrorState 集中器
        loading: () => const Center(child: LoadingSpinner()),
        error: (e, st) =>
            ErrorState(title: l10n.commonLoadFailed(e.toString())),
        data: (entries) => _buildGrid(context, entries, scales, unavailableIds),
      ),
    );
  }

  /// 12 张卡片 grid (10 开放 + 2 unavailable, R93 阶段 2 后变 8 + 2 = 10)
  Widget _buildGrid(
    BuildContext context,
    List<AssessmentEntry> entries,
    List<AssessmentScale> scales,
    List<String> unavailableIds,
  ) {
    // 按 scaleId 索引最新 entry (centered card 显示用)
    final latestByScaleId = <String, AssessmentEntry>{};
    for (final e in entries) {
      latestByScaleId[e.scaleId] = e;
    }

    return ListView(
      padding: AppTokens.edgeInsetsMd,
      children: [
        // v0.30 round 92 (audit-fixes / P0 #14): 顶部 mini 趋势图
        // 复用 R90 AssessmentMultiLineChart widget (sub-spec 6 Task 4 实施),
        // 80dp 高 mini 版 (跟 AppTokens.chartPlaceholderHeight 集中器同值)。
        // 修前 (R90 Task 5 placeholder): `const SizedBox.shrink()` +
        // `// TODO (Task 5)` 注释, 12 量表卡片堆在 ListView 顶部, 0 趋势图
        // 入口。R92 真做: 复用 R90 widget, 走 allAssessmentEntriesProvider
        // entries (page build 已 watch), 12 量表叠加 30 天。
        AssessmentMultiLineChart(
          entries: entries,
          // v0.30 round 93 (阶段 2 audit-fixes): chart 顶部 chip 列表走
          // 跟 grid 同一份 filtered scales (PHQ-9 / GAD-7 hidden 时 chip 也隐藏)。
          scaleIds: scales.map((s) => s.id).toList(),
          chartHeight: 80,
        ),
        const SizedBox(height: AppTokens.spacingMd),

        // v0.30 round 93 (阶段 2 audit-fixes): 开放量表数从 10 → 8
        // (PHQ-9 / GAD-7 隐藏, 走 [FeatureFlags.phqGad7I18nEnabled] gate)
        // + 2 unavailable = 总 10 卡片 (原 12)。
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppTokens.spacingSm,
            mainAxisSpacing: AppTokens.spacingSm,
            childAspectRatio: 1.1,
          ),
          itemCount: scales.length + unavailableIds.length,
          itemBuilder: (context, i) {
            if (i < scales.length) {
              final scale = scales[i];
              return AssessmentCenterCard(
                scale: scale,
                latestEntry: latestByScaleId[scale.id],
              );
            }
            final id = unavailableIds[i - scales.length];
            return AssessmentUnavailableCard(scaleId: id);
          },
        ),
      ],
    );
  }
}
