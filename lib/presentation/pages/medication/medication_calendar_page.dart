// v0.14 (Round 13C) 用药日历 — 医生视角的依从性热力图
//
// 布局（v0.30 round 93 拆 god page 之后）：
// - 顶部说明 InfoBanner
// - 时间窗口 SegmentedButton (7/30/90)
// - 日历网格 (CalendarGrid sub-widget) — 点 cell 选中
// - 单日详情 (DayDetail sub-widget) — 选中后显示在 grid 下方
// - 颜色图例 (Legend sub-widget)
//
// 之前 v0.14-0.29 都在本页 inline 446 行, 拆 3 sub-widget + cell tap 后
// 缩到 < 250 行
//
// v0.17 round 7 (B1+B2): _days setState 状态提到 calendarWindowProvider
// v0.21 (P0-6 fix): watch dayChangeTickProvider 让跨 midnight 时本页自动 rebuild
// v0.30 round 93 (audit-fixes task 1):
//   - 拆 god page → CalendarGrid + DayDetail + Legend
//   - 加 cell tap → 选中 date → 显示 DayDetail (新行为)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/medication_calendar_day_detail.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/medication_calendar_grid.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/medication_calendar_legend.dart';
import 'package:chroniccare/presentation/providers/calendar_window_provider.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/app_semantics.dart';
import 'package:chroniccare/presentation/widgets/error_state.dart';
import 'package:chroniccare/presentation/widgets/info_banner.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';

class MedicationCalendarPage extends ConsumerStatefulWidget {
  const MedicationCalendarPage({super.key});

  @override
  ConsumerState<MedicationCalendarPage> createState() =>
      _MedicationCalendarPageState();
}

class _MedicationCalendarPageState
    extends ConsumerState<MedicationCalendarPage> {
  /// v0.30 round 93 (task 1.5): 用户点 cell 选中的日期
  ///
  /// null = 没选中, DayDetail 不显示。
  /// 父 widget (本页) 持 state, 传给 sub-widget (CalendarGrid onCellTap,
  /// DayDetail date)。
  DateTime? _selectedDate;

  void _onCellTap(DateTime day) {
    setState(() {
      _selectedDate = day;
    });
  }

  @override
  Widget build(BuildContext context) {
    // v0.17 round 7 (B1+B2): 状态从 setState 提到 Notifier
    final days = ref.watch(calendarWindowProvider);
    final medsAsync = ref.watch(medicationsProvider);
    final checkInsAsync = ref.watch(allCheckInsProvider);
    // v0.21 (P0-6 fix): watch dayChangeTickProvider 让跨 midnight 时本页自动 rebuild
    ref.watch(dayChangeTickProvider);
    return PageScaffold(
      title: AppLocalizations.of(context).medsCalendarTitle,
      child: ListView(
        children: [
          const SizedBox(height: AppTokens.spacingMd),

          // 顶部说明
          // v0.27 round 67 (C-2): 走 InfoBanner 集中器
          InfoBanner(
            icon: Icons.medication_outlined,
            text: AppLocalizations.of(context).medsCalendarHeatmapDesc,
          ),

          const SizedBox(height: AppTokens.spacingSm),

          // 时间窗口选择
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppTokens.spacingMd),
            // v0.22 round 29 (emil-34): Semantics 描述时间窗口
            // (TalkBack 读"时间窗口 7/30/90 天，当前 30" 让用户知道是单选)
            child: AppSemantics.container(
              label: AppLocalizations.of(context)
                  .medicationTimeWindowSemantics(days),
              // v0.26 round 57 (emil EMIL-INC-06): 走 PressFeedback 集中器
              // 替代裸 SegmentedButton (无 :active scale 反馈)
              child: PressFeedback(
                child: SegmentedButton<int>(
                  segments: [
                    ButtonSegment(
                      value: 7,
                      label: Text(
                        AppLocalizations.of(context).medsCalendarWindow7,
                      ),
                    ),
                    ButtonSegment(
                      value: 30,
                      label: Text(
                        AppLocalizations.of(context).medsCalendarWindow30,
                      ),
                    ),
                    ButtonSegment(
                      value: 90,
                      label: Text(
                        AppLocalizations.of(context).medsCalendarWindow90,
                      ),
                    ),
                  ],
                  selected: {days},
                  // v0.22 round 29 (emil-49): 跟 trend_page.dart:252 一致 showSelectedIcon: false
                  // (避免 list/calendar 切换时 check 图标跳动)
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => ref
                      .read(calendarWindowProvider.notifier)
                      .setDays(s.first),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppTokens.spacingMd),

          // v0.30 round 93: 拆 CalendarGrid sub-widget
          // 父 widget 传 data, sub-widget 渲染 (R92 props callback 模式)
          medsAsync.when(
            data: (meds) => checkInsAsync.when(
              data: (checkIns) => _buildGridWithData(
                meds: meds,
                checkIns: checkIns,
                days: days,
              ),
              loading: () => const LoadingSkeleton.fullScreen(),
              error: (e, _) => ErrorState(
                title: AppLocalizations.of(context)
                    .medsCalendarLoadCheckinFailed(''),
                detail: e.toString(),
                onRetry: () => ref.invalidate(allCheckInsProvider),
              ),
            ),
            loading: () => const LoadingSkeleton.fullScreen(),
            error: (e, _) => ErrorState(
              title: AppLocalizations.of(context).medsCalendarLoadMedFailed(''),
              detail: e.toString(),
              onRetry: () => ref.invalidate(medicationsProvider),
            ),
          ),

          const SizedBox(height: AppTokens.spacingMd),

          // v0.30 round 93 (task 1.5): 选中后显示 DayDetail
          // 父 widget 持 _selectedDate state, 传 date + checkIns + meds
          // DayDetail 只渲染, 不读全局 (R92 props callback 模式)
          if (_selectedDate != null && medsAsync.hasValue)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppTokens.spacingMd),
              child: MedicationCalendarDayDetail(
                date: _selectedDate!,
                checkIns: checkInsAsync.value ?? const <CheckInEntity>[],
                meds: medsAsync.value ?? const <MedicationEntity>[],
                onAddLog: _onAddLogStub,
              ),
            ),

          // v0.30 round 93: 拆 Legend sub-widget (Step 1.4)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTokens.spacingMd),
            child: MedicationCalendarLegend(),
          ),
        ],
      ),
    );
  }

  /// 包装层: 同步取 data, 传给 sub-widget
  Widget _buildGridWithData({
    required List<MedicationEntity> meds,
    required List<CheckInEntity> checkIns,
    required int days,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingMd),
      child: MedicationCalendarGrid(
        meds: meds,
        checkIns: checkIns,
        days: days,
        selectedDate: _selectedDate,
        onCellTap: _onCellTap,
      ),
    );
  }

  /// v0.30 round 93 (task 1.5): 补打卡 stub
  ///
  /// 完整实现待 R93 task 4 (schema) / task 5 (Repository 扩展) 接入
  /// RecordCheckInUseCase 的 `at` 参数。当前只显示 SnackBar 提示。
  /// 不影响 cell tap → DayDetail 显示的核心功能 (task 1.5 主目标)。
  void _onAddLogStub(DateTime date) {
    // 显式使用 ref / context 避免 lint 警告
    ref.invalidate(allCheckInsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '补打卡功能接入中 (${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')})',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
