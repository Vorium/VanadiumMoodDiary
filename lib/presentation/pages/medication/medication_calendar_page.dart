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
// v0.31 round 11a (Apple Health redesign · Phase 3 Task 3.3):
//   - 章节改 ALL CAPS SectionHeader (跟 spec §4.6 一致)
//   - 日历 grid 章节用 AppleListSection 风格 (iOS 群组列表容器)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/core/shared/formatters.dart';
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/medication_calendar_day_detail.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/medication_calendar_grid.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/medication_calendar_legend.dart';
import 'package:chroniccare/presentation/providers/calendar_window_provider.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/providers/check_in_notifier.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/app_semantics.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/error_state.dart';
import 'package:chroniccare/presentation/widgets/info_banner.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';
import 'package:chroniccare/presentation/widgets/primary_button.dart';
import 'package:chroniccare/presentation/widgets/section_header.dart';

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

          // 顶部说明 (保留, 不用 AppleListSection 包装因为是单行说明)
          // v0.27 round 67 (C-2): 走 InfoBanner 集中器
          InfoBanner(
            icon: Icons.medication_outlined,
            text: AppLocalizations.of(context).medsCalendarHeatmapDesc,
          ),

          const SizedBox(height: AppTokens.spacingMd),

          // v0.31 round 11a: 时间窗口章节 — 走 SectionHeader ALL CAPS
          // + AppleListSection 风格容器 (spec §4.6 + §4.5)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppTokens.pageMarginH),
            child: SectionHeader(
              title: AppLocalizations.of(context).medsCalendarWindowTitle,
            ),
          ),
          const SizedBox(height: AppTokens.spacingXxs),

          AppleListSection(
            margin:
                const EdgeInsets.symmetric(horizontal: AppTokens.pageMarginH),
            children: [
              // v0.22 round 29 (emil-34): Semantics 描述时间窗口
              // (TalkBack 读"时间窗口 7/30/90 天，当前 30" 让用户知道是单选)
              AppSemantics.container(
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
            ],
          ),

          const SizedBox(height: AppTokens.spacingMd),

          // v0.31 round 11a: 日历 grid 章节 — SectionHeader ALL CAPS
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppTokens.pageMarginH),
            child: SectionHeader(
              title: AppLocalizations.of(context).medsCalendarTitle,
            ),
          ),
          const SizedBox(height: AppTokens.spacingXxs),

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
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.pageMarginH,
              ),
              child: MedicationCalendarDayDetail(
                date: _selectedDate!,
                checkIns: checkInsAsync.value ?? const <CheckInEntity>[],
                meds: medsAsync.value ?? const <MedicationEntity>[],
                onAddLog: _onAddLog,
              ),
            ),

          // v0.30 round 93: 拆 Legend sub-widget (Step 1.4)
          // v0.31 round 11a: Legend 章节用 SectionHeader ALL CAPS
          const SizedBox(height: AppTokens.spacingMd),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppTokens.pageMarginH),
            child: SectionHeader(
              title: AppLocalizations.of(context).medsCalendarLegendTitle,
            ),
          ),
          const SizedBox(height: AppTokens.spacingXxs),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTokens.pageMarginH),
            child: MedicationCalendarLegend(),
          ),
          const SizedBox(height: AppTokens.spacingLg),
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
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.pageMarginH),
      child: MedicationCalendarGrid(
        meds: meds,
        checkIns: checkIns,
        days: days,
        selectedDate: _selectedDate,
        onCellTap: _onCellTap,
      ),
    );
  }

  /// v0.32 round 8 (R111 R111-03 fix): 补打卡真实现
  ///
  /// 之前 _onAddLogStub 只弹 "补打卡功能接入中" SnackBar (B2-09 残留)。
  /// RecordCheckInUseCase.call 已有 `at` 参数, 只差 UI 接入。流程:
  /// 选药 dialog → CheckInNotifier.checkIn(medicationId, at: date)
  /// → 成功 SnackBar (AppSnackBar) + invalidate providers。
  Future<void> _onAddLog(DateTime date) async {
    final l10n = AppLocalizations.of(context);
    final meds =
        ref.read(medicationsProvider).value ?? const <MedicationEntity>[];
    MedicationEntity? selected = meds.isNotEmpty ? meds.first : null;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final l = AppLocalizations.of(ctx);
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(l.medsCalendarDayDetailAddLog),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (meds.isNotEmpty)
                    DropdownButtonFormField<MedicationEntity?>(
                      initialValue: selected,
                      decoration: InputDecoration(
                        labelText: l.commonMedName,
                        border: InputBorder.none,
                      ),
                      items: [
                        DropdownMenuItem<MedicationEntity?>(
                          value: null,
                          child: Text(l.tempMedNoLink),
                        ),
                        for (final m in meds)
                          DropdownMenuItem<MedicationEntity?>(
                            value: m,
                            child: Text(m.name),
                          ),
                      ],
                      onChanged: (v) => setLocal(() => selected = v),
                    ),
                  const SizedBox(height: AppTokens.spacingSm),
                  Text(
                    Formatters.date(date),
                    textAlign: TextAlign.center,
                    style: AppTokens.textStyleLabel(context),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l.commonCancel),
                ),
                PrimaryButton(
                  isFullWidth: false,
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l.medCalendarBackfillConfirm),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(checkInNotifierProvider.notifier)
          .checkIn(medicationId: selected?.id, at: date);
      if (!mounted) return;
      AppSnackBar.showInfo(
        context,
        l10n.medCalendarBackfillSuccess(
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        ),
      );
      ref.invalidate(allCheckInsProvider);
      ref.invalidate(streakSummaryProvider);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, action: l10n.snackbarActionSave, error: e);
    }
  }
}
