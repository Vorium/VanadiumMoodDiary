// v1.1.0 R116 (god class 拆): 情绪趋势页主壳
//
// 历史:
// - v0.30 R101: 3 tab (趋势/分数分布/CBT 重评) + 4 档时间范围
// - v1.1.0 R113 (BUG 9): 无数据日 nullSpot
// - v1.1.0 R114 (B2-5): Semantics 摘要
// - v1.1.0 R116: 653L god class → 拆 4 文件
//   - lib/domain/logic/mood_trend_calculator.dart (纯函数 + enum)
//   - lib/presentation/pages/mood_list/widgets/mood_trend_line_chart.dart (折线图)
//   - lib/presentation/pages/mood_list/widgets/mood_distribution_chart.dart (分布图)
//   - lib/presentation/pages/mood_list/widgets/mood_cbt_chart.dart (CBT 重评图)
//   - 本文件: 主壳 (TabController + 3 tab 拼装)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/logic/mood_trend_calculator.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/mood_list/widgets/mood_cbt_chart.dart';
import 'package:chroniccare/presentation/pages/mood_list/widgets/mood_distribution_chart.dart';
import 'package:chroniccare/presentation/pages/mood_list/widgets/mood_trend_line_chart.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';

class MoodTrendPage extends ConsumerStatefulWidget {
  const MoodTrendPage({super.key});

  @override
  ConsumerState<MoodTrendPage> createState() => _MoodTrendPageState();
}

class _MoodTrendPageState extends ConsumerState<MoodTrendPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  MoodTrendTimeRange _timeRange = MoodTrendTimeRange.week;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final moodsAsync = ref.watch(allMoodProvider);

    return PageScaffold(
      title: l10n.moodTrendTitle,
      appBarBottom: TabBar(
        controller: _tabController,
        tabs: [
          Tab(text: l10n.moodTrendWeek),
          Tab(text: l10n.moodTrendDistribution),
          const Tab(text: 'CBT'),
        ],
      ),
      child: moodsAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Text(
                l10n.moodTrendNoData,
                style: TextStyle(
                  fontSize: AppTokens.fontSizeBody,
                  color: AppTokens.textHintColor(context),
                ),
              ),
            );
          }
          return TabBarView(
            controller: _tabController,
            children: [
              MoodTrendTab(
                entries: entries,
                timeRange: _timeRange,
                onTimeRangeChanged: (r) => setState(() => _timeRange = r),
              ),
              MoodDistributionChart(
                entries: entries,
                title: l10n.moodTrendDistTitle,
              ),
              MoodCbtEffectChart(
                entries: entries,
                title: l10n.moodTrendCbtTitle,
                hint: l10n.moodTrendCbtHint,
                emptyText: l10n.moodTrendCbtEmpty,
              ),
            ],
          );
        },
        loading: () => const Center(child: LoadingSpinner()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
