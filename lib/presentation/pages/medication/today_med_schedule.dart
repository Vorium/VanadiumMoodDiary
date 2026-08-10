// v0.14 (Round 17) 今日服药计划
//
// 主页小卡：列出今天每种在用药物的服用时间点，
// 并标出已打卡 / 未打卡的进度。
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
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';

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
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push('/medication'),
            child: Padding(
              padding: AppTokens.edgeInsetsMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        color: AppTokens.primaryColor(context),
                        size: 20,
                      ),
                      const SizedBox(width: AppTokens.spacingXs),
                      Text(
                        AppLocalizations.of(context).medsTodaySchedule,
                        style: const TextStyle(
                          fontSize: AppTokens.fontSizeBody,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$done / ${entries.length}',
                        style: TextStyle(
                          fontSize: AppTokens.fontSizeCaption,
                          color: done == entries.length
                              ? AppTokens.primaryColor(context)
                              : AppTokens.textHintColor(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.spacingSm),
                  Wrap(
                    // v0.27 R72 (emil E-P2-4): 走 AppTokens.spacingXs 集中器替代 inline 8
                    spacing: AppTokens.spacingXs,
                    runSpacing: AppTokens.spacingXs,
                    children: [
                      for (final e in entries) _TimeChip(entry: e),
                    ],
                  ),
                ],
              ),
            ),
          ),
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

class _TimeChip extends StatelessWidget {
  final _ScheduleEntry entry;
  const _TimeChip({required this.entry});

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final color = e.done
        ? AppTokens.primaryColor(context)
        : AppTokens.textSecondaryColor(context);
    final bg = e.done
        ? AppTokens.tintedPrimarySoft(context)
        : AppTokens.dividerColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingChipGap,
        vertical: AppTokens.spacingChipGap,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTokens.radiusChip),
        border: e.done
            ? null
            : Border.all(color: AppTokens.borderColor(context), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (e.done)
            Padding(
              padding: const EdgeInsets.only(right: AppTokens.spacingXxs),
              child: Icon(
                Icons.check_circle,
                color: AppTokens.primaryColor(context),
                size: AppTokens.iconSizeSmall,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: AppTokens.spacingXxs),
              child: Icon(
                Icons.access_time,
                color: AppTokens.textHintColor(context),
                size: AppTokens.iconSizeSmall,
              ),
            ),
          Text(
            '${_pad(e.time.hour)}:${_pad(e.time.minute)}',
            style: TextStyle(
              fontSize: AppTokens.fontSizeBodySm,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: AppTokens.spacingChipGap),
          Text(
            e.med.name,
            style: TextStyle(
              fontSize: AppTokens.fontSizeCaptionSm,
              color: e.done
                  ? AppTokens.textPrimaryColor(context)
                  : AppTokens.textSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
