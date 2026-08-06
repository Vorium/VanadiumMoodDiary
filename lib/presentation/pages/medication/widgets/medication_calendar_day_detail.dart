// v0.30 round 93 (audit-fixes task 1.3): MedicationCalendarDayDetail
// 拆 medication_calendar_page.dart god page 第 2 步
// - 单日详情 widget: 日期头部 + 打卡 list + 补打 button
// - 接受 props: date, checkIns, meds (用于查 med 名字), onAddLog
// - 复用 AppListTile / EmptyState / SectionHeader
// - 跟 R92 模式一致: 父 widget 传 data, sub-widget 只渲染
//
// 之前没有"单日详情"概念 (cell 不可点击), Step 1.5 加 onCellTap 集成
//
// R93 task 1.3 只拆 widget, 不在 page 接 onCellTap (Step 1.5 才接)

import 'package:flutter/material.dart';

import 'package:chroniccare/core/shared/formatters.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';
import 'package:chroniccare/presentation/widgets/empty_state.dart';
import 'package:chroniccare/presentation/widgets/primary_button.dart';
import 'package:chroniccare/presentation/widgets/section_header.dart';

/// 用药日历单日详情 widget
///
/// 显示选中日期的:
/// - 日期头部 (SectionHeader: "2026-08-06 的打卡")
/// - 打卡 list (AppListTile, 每行: 时间 · 药名)
/// - 补打卡 button (PrimaryButton, onAddLog callback)
///
/// 父 widget 负责:
/// - 监听 cell tap, 选 date 后 rebuild
/// - 处理 onAddLog 实际写 DB (checkInRepositoryProvider.checkIn)
///
/// 本 widget 不读全局 state (R92 props callback 模式)
class MedicationCalendarDayDetail extends StatelessWidget {
  const MedicationCalendarDayDetail({
    super.key,
    required this.date,
    required this.checkIns,
    required this.meds,
    this.onAddLog,
  });

  /// 选中的日期 (00:00:00 形式, 父 widget 已 normalize)
  final DateTime date;

  /// 所有打卡 (父 widget 已传完整 list, 本 widget 内部按 date 过滤)
  final List<CheckInEntity> checkIns;

  /// 所有药物 (用于通过 medId 查药名, 父 widget 传完整 list)
  final List<MedicationEntity> meds;

  /// "补打卡" 按钮回调 (null = 不显示按钮, 只读 view)
  ///
  /// 签名: 父 widget 知道 date 但不知道选什么药,
  /// 本 callback 触发后父 widget 弹 dialog 选药 → 写 DB。
  final void Function(DateTime date)? onAddLog;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // 过滤该日的 normal 打卡 (排除 temp / assessment)
    final dayLogs = checkIns
        .where((c) => c.isNormal && _isSameDay(c.timestamp, date))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final medNameById = <int, String>{
      for (final m in meds) m.id: m.name,
    };

    return Card(
      child: Padding(
        padding: AppTokens.edgeInsetsMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              title: l10n.medsCalendarDayDetailTitle(Formatters.date(date)),
              leading: Icon(
                Icons.event_outlined,
                size: AppTokens.iconSizeInline,
                color: AppTokens.primaryColor(context),
              ),
            ),
            const SizedBox(height: AppTokens.spacingSm),
            if (dayLogs.isEmpty)
              EmptyState(
                icon: Icons.check_circle_outline,
                title: l10n.medsCalendarDayDetailEmpty,
              )
            else
              ..._buildLogTiles(context, dayLogs, medNameById, l10n),
            if (onAddLog != null) ...[
              const SizedBox(height: AppTokens.spacingMd),
              PrimaryButton(
                isFullWidth: true,
                onPressed: () => onAddLog!(date),
                child: Text(l10n.medsCalendarDayDetailAddLog),
              ),
              const SizedBox(height: AppTokens.spacingXxs),
              Text(
                l10n.medsCalendarDayDetailAddLogHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTokens.fontSizeCaption,
                  color: AppTokens.textHintColor(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLogTiles(
    BuildContext context,
    List<CheckInEntity> logs,
    Map<int, String> medNameById,
    AppLocalizations l10n,
  ) {
    return [
      for (final log in logs)
        AppListTile.standard(
          leading: Icon(
            Icons.check_circle,
            color: AppTokens.primaryColor(context),
            size: AppTokens.iconSizeInline,
          ),
          title: Text(
            l10n.medsCalendarDayDetailLogItem(
              Formatters.time(log.timestamp),
              log.medicationId != null
                  ? (medNameById[log.medicationId!] ?? '?')
                  : '?',
            ),
          ),
        ),
    ];
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
