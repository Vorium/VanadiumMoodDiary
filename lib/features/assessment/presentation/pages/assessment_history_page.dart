// v0.14 (Round 13B) 心理评估历史完整页面
//
// 独立页面：列出所有 PHQ-9 / GAD-7 评估 + 折线图 + 与上次对比
// 入口：home_page 心理评估图标（之前直接跳 phq9 答题）
// 入口：settings → "心理评估" section
// 入口：trend_page 评估历史小节（点击查看全部）
//
// 数据流：assessmentsProvider → AssessmentRecord.tryFromEntity → UI
//
// v0.24 round 46 (emil B-11 god class 续拆): 从 624 行瘦身到 ~80 行 orchestrator
// 4 个 section widgets 已提取到 assessment/widgets/:
//   - AssessmentSummaryStrip (顶部汇总条)
//   - AssessmentChartCard (折线图，每个量表一张)
//   - AssessmentHistoryList (完整历史 + diff)
//   - AssessmentSeverityStyle + 4 helpers (严重度配色, 多个 widget 共用)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/features/assessment/domain/logic/assessment_record.dart';
import 'package:chroniccare/presentation/widgets/empty_state.dart';
import 'package:chroniccare/presentation/widgets/error_state.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/pages/assessment/widgets/assessment_summary_strip.dart';
import 'package:chroniccare/presentation/pages/assessment/widgets/assessment_chart_card.dart';
import 'package:chroniccare/presentation/pages/assessment/widgets/assessment_history_list.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

class AssessmentHistoryPage extends ConsumerWidget {
  const AssessmentHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(assessmentsProvider);
    return PageScaffold(
      title: AppLocalizations.of(context).settingsAssessmentHistory,
      child: async.when(
        data: (all) {
          final records = all
              .map(AssessmentRecord.tryFromEntity)
              .whereType<AssessmentRecord>()
              .toList();
          if (records.isEmpty) {
            return _AssessmentHistoryEmptyState();
          }
          return _buildBody(context, ref, records);
        },
        loading: () => const LoadingSkeleton.fullScreen(),
        // v0.22 round 29 (emil-44): 改用 ErrorState 集中器, 加 retry 入口
        // v0.27 round 77 (R76-N8 修): commonLoadFailed 传 e.toString() 走
        // l10n 模板, 跟 detail 一致
        error: (e, _) => ErrorState(
          title: AppLocalizations.of(context).commonLoadFailed(e.toString()),
          detail: e.toString(),
          onRetry: () => ref.invalidate(assessmentsProvider),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    List<AssessmentRecord> records,
  ) {
    // 按时间倒序
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // 分组：phq9 / gad7
    final phq9 = records.where((r) => r.scaleId == 'phq9').toList();
    final gad7 = records.where((r) => r.scaleId == 'gad7').toList();

    // v0.21 Round 23 (P1-27): 下拉刷新 — emil 决策: occasional 频度
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(assessmentsProvider);
        await Future<void>.delayed(
          const Duration(milliseconds: AppTokens.refreshMinVisibleMs),
        );
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: AppTokens.spacingMd),
          // 顶部汇总
          AssessmentSummaryStrip(records: records),
          const SizedBox(height: AppTokens.spacingMd),
          // 折线图（每个量表一张）
          if (phq9.isNotEmpty) ...[
            AssessmentChartCard(scaleId: 'phq9', records: phq9),
            const SizedBox(height: AppTokens.spacingSm),
          ],
          if (gad7.isNotEmpty) ...[
            AssessmentChartCard(scaleId: 'gad7', records: gad7),
            const SizedBox(height: AppTokens.spacingSm),
          ],
          // 完整列表
          AssessmentHistoryList(records: records),
          const SizedBox(height: AppTokens.spacingLg),
        ],
      ),
    );
  }
}

/// v0.21 Round 22 (P0-11 修复): 改用统一 EmptyState
class _AssessmentHistoryEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.psychology_outlined,
      title: AppLocalizations.of(context).assessmentHistoryEmpty,
      subtitle: AppLocalizations.of(context).assessmentHistoryEmptyHint,
      actionLabel: AppLocalizations.of(context).assessmentHistoryStartFirst,
      onAction: () => context.push('/assessment/phq9'),
    );
  }
}
