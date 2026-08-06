// v0.14 (Round 13C) 用药日历 — 医生视角的依从性热力图
//
// 布局（v0.30 round 93 拆 god page 之后）：
// - 顶部说明 InfoBanner
// - 时间窗口 SegmentedButton (7/30/90)
// - 日历网格 (CalendarGrid sub-widget)
// - 颜色图例 (Legend sub-widget, Step 1.4)
//
// 之前 v0.14-0.29 都在本页 inline 446 行, 拆 3 sub-widget 后缩到 < 250 行
// (CalendarGrid ~280 行, DayDetail ~150 行, Legend ~60 行, page < 250 行)
//
// v0.17 round 7 (B1+B2): _days setState 状态提到 calendarWindowProvider
// v0.21 (P0-6 fix): watch dayChangeTickProvider 让跨 midnight 时本页自动 rebuild
// v0.30 round 93 (audit-fixes task 1): 拆 god page → CalendarGrid + DayDetail + Legend

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
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

class MedicationCalendarPage extends ConsumerWidget {
  const MedicationCalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      ),
    );
  }
}
