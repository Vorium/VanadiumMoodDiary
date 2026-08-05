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

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/assessment_entry.dart';
import 'package:chroniccare/domain/logic/assessment_scale.dart';
import 'package:chroniccare/domain/logic/scale_registry.dart';
import 'package:chroniccare/presentation/pages/assessment/widgets/assessment_center_card.dart';
import 'package:chroniccare/presentation/pages/assessment/widgets/assessment_unavailable_card.dart';
import 'package:chroniccare/presentation/providers/assessment_providers.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';

/// 中心化入口页 — 12 量表卡片 grid
///
/// 复用 R60 AssessmentScale 抽象 + Task 1-3 const scale class + scale_registry.
/// 不开新表, 走 check_ins 表 type=`[scale_id]` 跨量表聚合.
///
/// v0.30 R90: 8 ARB keys 占位 (assessmentCenterTitle/LastScore/LastTime/
/// NoData/StartButton/MultiLineTitle/NotAvailable/ComingSoon), Task 6 一次性
/// 换 200+ l10n key. 本 task 中文 placeholder 即可.
class AssessmentCenterPage extends ConsumerWidget {
  const AssessmentCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scales = ref.watch(allScalesProvider);
    final entriesAsync = ref.watch(allAssessmentEntriesProvider);
    final unavailableIds = unavailableScaleIds;

    return PageScaffold(
      // Task 6 换 l10n.assessmentCenterTitle
      title: '量表中心',
      child: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('加载失败: $e')),
        data: (entries) => _buildGrid(context, entries, scales, unavailableIds),
      ),
    );
  }

  /// 12 张卡片 grid (10 开放 + 2 unavailable)
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
      padding: const EdgeInsets.all(AppTokens.spacingMd),
      children: [
        // TODO (Task 5): 顶部 mini 趋势图
        // _buildMiniChart(context, entries),
        const SizedBox(height: AppTokens.spacingMd),

        // 10 开放量表 + 2 unavailable
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
