// 趋势页（v0.7 新增，v0.8 加量表折线图，v0.9 加情绪折线图，
//        v0.12 / Round 6 加 list ↔ calendar 切换 + mood 入日历，
//        v0.13 / Round 10 展开"选中日详情"）
// - 顶部：当前连续天数 / 最长连续 / 总打卡 / 总天数
// - list 视图：30 天热力图 + 6 个月柱状图 + 心理评估 + 情绪历史
// - calendar 视图：当月 7×6 日历 + 选中日详情（所有事件列表）
//
// v0.19 (P1-15): 拆分为 trend_summary / trend_charts / trend_calendar / trend_utils
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/logic/assessment_record.dart';
import 'package:chroniccare/domain/logic/trend_calculator.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/providers/data_providers.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/pages/trend/trend_summary.dart';
import 'package:chroniccare/presentation/pages/trend/trend_charts.dart';
import 'package:chroniccare/presentation/pages/trend/trend_calendar.dart';

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

    return PageScaffold(
      title: '我的趋势',
      child: checkInsAsync.when(
        data: (List<CheckInEntity> checkIns) {
          final moodEntries = moodAsync.maybeWhen(
            data: (m) => m,
            orElse: () => <MoodEntryEntity>[],
          );
          return _buildBody(context, checkIns, moodEntries);
        },
        loading: () => const LoadingSkeleton.fullScreen(),
        error: (Object e, _) => Center(
            child: Text(
                AppLocalizations.of(context).commonLoadFailed(e.toString()),),),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<CheckInEntity> checkIns,
    List<MoodEntryEntity> moodEntries,
  ) {
    final summary = TrendCalculator.streakSummary(checkIns: checkIns);

    return SingleChildScrollView(
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
          if (_view == _TrendView.list)
            _buildListView(context, checkIns)
          else
            _buildCalendarView(context, checkIns, moodEntries),
          const SizedBox(height: AppTokens.spacingXl),
        ],
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
        Text(
          '最近 30 天',
          style: TextStyle(
            fontSize: AppTokens.fontSizeLabel,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppTokens.spacingSm),
        HeatmapGrid(daily: daily),
        const SizedBox(height: AppTokens.spacingLg),
        Text(
          '最近 6 个月',
          style: TextStyle(
            fontSize: AppTokens.fontSizeLabel,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppTokens.spacingSm),
        MonthlyChart(monthly: monthly),
        const SizedBox(height: AppTokens.spacingLg),
        Text(
          '心理评估历史',
          style: TextStyle(
            fontSize: AppTokens.fontSizeLabel,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
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
                height: 200,
                child: LoadingSkeleton.fullScreen(),
              ),
              error: (e, _) => Text(
                  AppLocalizations.of(context).commonLoadFailed(e.toString()),),
            );
          },
        ),
        const SizedBox(height: AppTokens.spacingLg),
        Text(
          '情绪日记历史',
          style: TextStyle(
            fontSize: AppTokens.fontSizeLabel,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppTokens.spacingSm),
        Consumer(
          builder: (context, ref, _) {
            final async = ref.watch(allMoodProvider);
            return async.when(
              data: (entries) => MoodHistoryChart(entries: entries),
              loading: () => const SizedBox(
                height: 200,
                child: LoadingSkeleton.fullScreen(),
              ),
              error: (e, _) => Text(
                  AppLocalizations.of(context).commonLoadFailed(e.toString()),),
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
    return SegmentedButton<_TrendView>(
      segments: const [
        ButtonSegment(
          value: _TrendView.list,
          label: Text('列表'),
          icon: Icon(Icons.view_list, size: 18),
        ),
        ButtonSegment(
          value: _TrendView.calendar,
          label: Text('日历'),
          icon: Icon(Icons.calendar_month, size: 18),
        ),
      ],
      selected: {current},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
    );
  }
}
