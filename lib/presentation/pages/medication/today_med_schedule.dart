// v0.14 (Round 17) 今日服药计划
//
// 主页小卡：列出今天每种在用药物的服用时间点，
// 并标出已打卡 / 未打卡的进度。
//
// v0.31 round 11a (Apple Health redesign · Phase 3 Task 3.3):
// 改 AppleListSection 风格 — iOS 群组列表 (insetGrouped) 替代原 Card + Padding。
//
// 数据：medicationsProvider (active meds) + allCheckInsProvider (today's check-ins)
//
// 匹配规则（v0.14 简单版）：medId 相等 + 当天有 normal 打卡 → 全天视为已打卡。
// 故意不做"time ± N 分钟"的精确匹配：用户可能一次打了多药，
// 或做"补卡"覆盖整天。太严格会漏报，留 v1.0 引入"补卡"功能后再精细化。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/core/theme/app_typography.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';

/// 一行时间点：[已打卡 ✓] 药名 08:00
class _ScheduleEntry {
  final MedicationEntity med;
  final HourMinute time;
  final bool done;
  const _ScheduleEntry({
    required this.med,
    required this.time,
    required this.done,
  });
}

class TodayMedSchedule extends ConsumerWidget {
  const TodayMedSchedule({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync = ref.watch(medicationsProvider);
    final checkInsAsync = ref.watch(allCheckInsProvider);
    // R97-P1-2: watch todayProvider 让 widget 跨 midnight 自动 rebuild,
    // 不再在 build 内直接调 DateTime.now() (避免 stale + 方便测试 override)。
    final today = ref.watch(todayProvider);
    return medsAsync.when(
      data: (meds) {
        final entries = _buildEntries(meds, checkInsAsync.value, today);
        if (entries.isEmpty) return const SizedBox.shrink();
        final done = entries.where((e) => e.done).length;
        final l10n = AppLocalizations.of(context);

        // v0.31 round 11a (Apple Health redesign):
        // 改 AppleListSection 风格 — iOS 群组列表, 圆角 16 容器, hairline 分隔
        // (替代原 Card + Padding 模式, 跟 spec §4.5 一致).
        return AppleListSection(
          title: l10n.medsTodaySchedule, // "今日服药" / "Today's Schedule"
          margin: EdgeInsets.zero, // 主页 caller 自管 padding
          children: [
            // 列表头: 进度数字 (AppleListSection 内部已用 ALL CAPS title,
            // 这里是 cell 内的 progress 数字)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTokens.spacingXs),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    color: AppTokens.primaryColor(context),
                    size: 20,
                  ),
                  const SizedBox(width: AppTokens.spacingXs),
                  // v0.31 R7a (StatCard ultralight): 进度数字走 ultralight
                  Text(
                    '$done / ${entries.length}',
                    style: AppTypography.textStyleMetricMd(context).copyWith(
                      // (跟 spec §4.3 StatCard default variant 字号一致)
                      color: done == entries.length
                          ? AppTokens.primaryColor(context)
                          : AppTokens.textHintColor(context),
                    ),
                  ),
                ],
              ),
            ),
            // 列表 cell: 每条 entry 1 行 (药名 + 时间 + 状态)
            for (final e in entries) _ScheduleEntryCell(entry: e),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// 把所有 active meds × times 展平，再标记已打卡
  ///
  /// 匹配规则（v0.14 简单版）：medId 匹配 + 当天有 normal 打卡
  /// 不做时间±N 分钟的精确匹配 — 用户的打卡可能是"补卡"或一次打了多药，
  /// 太严格的匹配会漏报。v1.0+ 引入"补卡"功能后再精细化。
  static List<_ScheduleEntry> _buildEntries(
    List<MedicationEntity> meds,
    List<CheckInEntity>? checkIns,
    DateTime now,
  ) {
    final activeMeds =
        meds.where((m) => m.isInUse && m.times.isNotEmpty).toList();
    if (activeMeds.isEmpty) return const [];

    // 收集今天已打卡的 medId（去重）
    final todayMedIds = <int>{};
    if (checkIns != null) {
      for (final c in checkIns) {
        if (!c.isNormal) continue;
        if (_isSameDay(c.timestamp, now)) {
          if (c.medicationId != null) todayMedIds.add(c.medicationId!);
        }
      }
    }

    final entries = <_ScheduleEntry>[];
    for (final m in activeMeds) {
      for (final t in m.times) {
        entries.add(
          _ScheduleEntry(
            med: m,
            time: t,
            done: todayMedIds.contains(m.id),
          ),
        );
      }
    }
    // 按时间排序
    entries.sort((a, b) {
      final c = a.time.hour.compareTo(b.time.hour);
      return c != 0 ? c : a.time.minute.compareTo(b.time.minute);
    });
    return entries;
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// v0.31 round 11a (Apple Health redesign): 1 行 entry cell
///
/// 视觉 (iOS list cell 标准 44pt):
/// - 左侧: 药名 (body w500) + 时间 (caption hint, 12pt → 13pt 后 caption 字号)
/// - 右侧: 状态 icon (check_circle / access_time, metric 色)
class _ScheduleEntryCell extends StatelessWidget {
  final _ScheduleEntry entry;
  const _ScheduleEntryCell({required this.entry});

  @override
  Widget build(BuildContext context) {
    final e = entry;
    return PressFeedback(
      // v0.31 R11a: 点击跳转 medication 主页 (跟原 InkWell 行为一致)
      onTap: () => context.push('/medication'),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  e.med.name,
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeBody,
                    fontWeight: FontWeight.w500,
                    color: AppTokens.textPrimaryColor(context),
                  ),
                ),
                const SizedBox(height: 2),
                // v0.31 R11a: 时间单独显示, 跟原 _TimeChip 拆开 (Apple List
                // 风格不重复 chip 容器, 改纯文字 + hint 色)
                Text(
                  '${_pad(e.time.hour)}:${_pad(e.time.minute)}',
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeCaption,
                    fontWeight: FontWeight.w500,
                    color: AppTokens.textSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),
          // 右侧状态 icon
          Icon(
            e.done
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            size: 22,
            color: e.done
                ? AppTokens.primaryColor(context)
                : AppTokens.textHintColor(context),
          ),
        ],
      ),
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
