// 趋势页（v0.7 新增，v0.8 加量表折线图，v0.9 加情绪折线图，
//        v0.12 / Round 6 加 list ↔ calendar 切换 + mood 入日历，
//        v0.13 / Round 10 展开"选中日详情"）
// - 顶部：当前连续天数 / 最长连续 / 总打卡 / 总天数
// - list 视图：30 天热力图 + 6 个月柱状图 + 心理评估 + 情绪历史
// - calendar 视图：当月 7×6 日历 + 选中日详情（所有事件列表）
//
// v0.19 (P1-15): 拆分为 trend_summary / trend_charts / trend_calendar / trend_utils
//
// v0.27 round 67 (Sprint 1 上架前 P0, spzh C-P0-6):
// PIPL §14 撤回 analytics 同意 → 趋势页显示"已撤回"占位 + 引导去重新同意。
// 不删数据 (用户可重新同意后恢复), 但页面渲染屏蔽。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/logic/assessment_record.dart';
import 'package:chroniccare/domain/logic/trend_calculator.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:chroniccare/presentation/providers/legal_consent_provider.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/animations/page_transition_switcher.dart';
import 'package:chroniccare/presentation/widgets/empty_state.dart';
import 'package:chroniccare/presentation/widgets/error_state.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';
import 'package:chroniccare/presentation/widgets/section_header.dart';
import 'package:chroniccare/presentation/pages/trend/trend_summary.dart';
import 'package:chroniccare/presentation/pages/trend/trend_calendar.dart';
import 'package:chroniccare/presentation/pages/trend/widgets/trend_heatmap_grid.dart';
import 'package:chroniccare/presentation/pages/trend/widgets/trend_monthly_chart.dart';
import 'package:chroniccare/presentation/pages/trend/widgets/trend_assessment_chart.dart';
import 'package:chroniccare/presentation/pages/trend/widgets/trend_mood_chart.dart';

/// v0.12 (Round 6) 视图模式
enum _TrendView { list, calendar }

class TrendPage extends ConsumerStatefulWidget {
  const TrendPage({super.key});

  @override
  ConsumerState<TrendPage> createState() => _TrendPageState();
}

class _TrendPageState extends ConsumerState<TrendPage> {
  _TrendView _view = _TrendView.list;
  DateTime _calendarMonth = _initialCalendarMonth();

  static DateTime _initialCalendarMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final checkInsAsync = ref.watch(allCheckInsProvider);
    final moodAsync = ref.watch(allMoodProvider);
    // v0.27 round 67 (Sprint 1, spzh C-P0-6): 撤回 analytics 同意 → 趋势页屏蔽
    final analyticsWithdrawn =
        ref.watch(legalConsentWithdrawnProvider(ConsentKind.analytics)).value;

    return PageScaffold(
      title: AppLocalizations.of(context).trendTitle,
      child: analyticsWithdrawn == true
          ? _buildWithdrawnState(context)
          : checkInsAsync.when(
              data: (List<CheckInEntity> checkIns) {
                final moodEntries = moodAsync.maybeWhen(
                  data: (m) => m,
                  orElse: () => <MoodEntryEntity>[],
                );
                return _buildBody(context, checkIns, moodEntries);
              },
              loading: () => const LoadingSkeleton.fullScreen(),
              error: (Object e, _) => ErrorState(
                title: AppLocalizations.of(context).commonLoadFailed(''),
                detail: e.toString(),
                onRetry: () => ref.invalidate(allCheckInsProvider),
              ),
            ),
    );
  }

  /// v0.27 round 67: 撤回 analytics 同意后的占位页
  ///
  /// 不删数据 (用户可重新开启), 但趋势页渲染屏蔽, 引导去"设置 → 法律与隐私"
  /// 重新同意 [ConsentKind.analytics] 即可恢复。
  Widget _buildWithdrawnState(BuildContext context) {
    return EmptyState(
      icon: Icons.analytics_outlined,
      title: AppLocalizations.of(context).trendWithdrawnTitle,
      subtitle: AppLocalizations.of(context).trendWithdrawnSubtitle,
      actionLabel: AppLocalizations.of(context).trendWithdrawnAction,
      onAction: () {
        // 用 go_router 推 legal_page (push 不 pop, 用户改完可 pop 回来)
        // 路径参考 lib/core/routing/app_route_medication.dart
        context.push('/settings/legal');
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<CheckInEntity> checkIns,
    List<MoodEntryEntity> moodEntries,
  ) {
    final summary = TrendCalculator.streakSummary(checkIns: checkIns);

    // v0.21 Round 23 (P1-27): 下拉刷新 — emil 决策: occasional 频度
    // (用户偶尔回头看历史) → 标准,RefreshIndicator 即可。
    // invalidate provider 让 Stream 重新订阅 → 最新数据自动渲染。
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allCheckInsProvider);
        ref.invalidate(allMoodProvider);
        // 给个最小可见时长,不然一闪而过体验差
        await Future<void>.delayed(
            const Duration(milliseconds: AppTokens.refreshMinVisibleMs),);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppTokens.spacingMd),
            SummaryCard(summary: summary),
            const SizedBox(height: AppTokens.spacingMd),
            _ViewToggle(
              current: _view,
              onChanged: (v) => setState(() => _view = v),
            ),
            const SizedBox(height: AppTokens.spacingMd),
            // v0.24 round 43 (emil P1-01 H-04 / D-08):
            // list ↔ calendar 切换 100ms fade (occasional 频度, emil rare 可加 delight)
            PageTransitionSwitcher(
              switchKey: _view,
              child: _view == _TrendView.list
                  ? _buildListView(context, checkIns)
                  : _buildCalendarView(context, checkIns, moodEntries),
            ),
            const SizedBox(height: AppTokens.spacingXl),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(BuildContext context, List<CheckInEntity> checkIns) {
    final daily = TrendCalculator.dailyBreakdown(checkIns: checkIns, days: 30);
    final monthly =
        TrendCalculator.monthlyBreakdown(checkIns: checkIns, months: 6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // v0.23 round 40 (emil F4 fix): 4 处 inline section header 改用 SectionHeader
        SectionHeader(title: AppLocalizations.of(context).trendLast30Days),
        const SizedBox(height: AppTokens.spacingSm),
        HeatmapGrid(daily: daily),
        const SizedBox(height: AppTokens.spacingLg),
        SectionHeader(title: AppLocalizations.of(context).trendLast6Months),
        const SizedBox(height: AppTokens.spacingSm),
        MonthlyChart(monthly: monthly),
        const SizedBox(height: AppTokens.spacingLg),
        SectionHeader(
            title: AppLocalizations.of(context).trendAssessmentHistory,),
        const SizedBox(height: AppTokens.spacingSm),
        Consumer(
          builder: (context, ref, _) {
            final async = ref.watch(assessmentsProvider);
            return async.when(
              data: (raw) {
                final records = raw
                    .map(AssessmentRecord.tryFromEntity)
                    .whereType<AssessmentRecord>()
                    .toList();
                return AssessmentHistoryChart(records: records);
              },
              loading: () => const SizedBox(
                // v0.26 round 57 (emil C-10): 走 chartPlaceholderHeight 集中器
                // 替代 inline height: 200 magic
                height: AppTokens.chartPlaceholderHeight,
                child: LoadingSkeleton.fullScreen(),
              ),
              error: (e, _) => SizedBox(
                // v0.26 round 57 (emil C-10): 走 chartPlaceholderHeight 集中器
                // 替代 inline height: 200 magic
                height: AppTokens.chartPlaceholderHeight,
                child: ErrorState(
                  title: AppLocalizations.of(context).commonLoadFailed(''),
                  detail: e.toString(),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppTokens.spacingLg),
        SectionHeader(title: AppLocalizations.of(context).trendMoodHistory),
        const SizedBox(height: AppTokens.spacingSm),
        Consumer(
          builder: (context, ref, _) {
            final async = ref.watch(allMoodProvider);
            return async.when(
              data: (entries) => MoodHistoryChart(entries: entries),
              loading: () => const SizedBox(
                // v0.26 round 57 (emil C-10): 走 chartPlaceholderHeight 集中器
                // 替代 inline height: 200 magic
                height: AppTokens.chartPlaceholderHeight,
                child: LoadingSkeleton.fullScreen(),
              ),
              error: (e, _) => SizedBox(
                // v0.26 round 57 (emil C-10): 走 chartPlaceholderHeight 集中器
                // 替代 inline height: 200 magic
                height: AppTokens.chartPlaceholderHeight,
                child: ErrorState(
                  title: AppLocalizations.of(context).commonLoadFailed(''),
                  detail: e.toString(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCalendarView(
    BuildContext context,
    List<CheckInEntity> checkIns,
    List<MoodEntryEntity> moodEntries,
  ) {
    final cm = TrendCalculator.monthlyCalendar(
      month: _calendarMonth,
      checkIns: checkIns,
      moodEntries: moodEntries,
    );
    final allMedications = ref.watch(allMedicationsProvider).maybeWhen(
          data: (m) => m,
          orElse: () => const <MedicationEntity>[],
        );
    return CalendarView(
      calendar: cm,
      allCheckIns: checkIns,
      moodEntries: moodEntries,
      medications: allMedications,
      onPrevMonth: () {
        setState(() {
          _calendarMonth = TrendCalculator.shiftMonth(_calendarMonth, -1);
        });
      },
      onNextMonth: () {
        setState(() {
          _calendarMonth = TrendCalculator.shiftMonth(_calendarMonth, 1);
        });
      },
    );
  }
}

/// 视图切换 SegmentedButton（list ↔ calendar）
class _ViewToggle extends StatelessWidget {
  final _TrendView current;
  final ValueChanged<_TrendView> onChanged;
  const _ViewToggle({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // v0.27 round 62 (P1-16 修复): 走 PressFeedback 集中器
    // (emil "频度: occasional (切视图)")。替代裸 SegmentedButton, 加 :active scale 反馈。
    return PressFeedback(
      child: SegmentedButton<_TrendView>(
        segments: [
          ButtonSegment(
            value: _TrendView.list,
            label: Text(AppLocalizations.of(context).trendViewList),
            icon: const Icon(Icons.view_list, size: AppTokens.iconSizeInline),
          ),
          ButtonSegment(
            value: _TrendView.calendar,
            label: Text(AppLocalizations.of(context).trendViewCalendar),
            icon: const Icon(Icons.calendar_month,
                size: AppTokens.iconSizeInline,),
          ),
        ],
        selected: {current},
        onSelectionChanged: (s) => onChanged(s.first),
        showSelectedIcon: false,
      ),
    );
  }
}
