// trend_day_detail_card.dart — 趋势页日历选中日详情卡片
//
// v0.30 round 95 (sub-spec 4 task 6): 从 trend_calendar.dart 抽出
//
// 职责: 显示选中日详情 (date header + mood range + check-in chip + events
// list + CBT 摘要), 含 R84 CBT 5/7 栏摘要展开功能。
//
// 跟原 DayDetailCard 1:1 行为不变, 仅移到独立文件 + 抽 cbt widgets
// 内部方法 (private 改成 top-level private _cbtFieldRow, 因类内 private
// 跨类访问受限)。
import 'package:flutter/material.dart';

import 'package:chroniccare/core/shared/mood_visual.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/logic/day_detail.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/trend/widgets/trend_event_row.dart';
import 'package:chroniccare/presentation/services/scale_name_l10n.dart';
import 'package:chroniccare/presentation/widgets/mood_label.dart';

/// 选中日详情卡片
///
/// v0.29 round 84: 改成 public `DayDetailCard` (去掉 underscore),
/// 让 test/presentation/pages/trend/cbt_calendar_badge_round84_test.dart
/// 能直接 import 测 CBT 摘要显示。
class DayDetailCard extends StatelessWidget {
  final DateTime date;
  final List<CheckInEntity> allCheckIns;
  final List<MoodEntryEntity> moodEntries;
  final List<MedicationEntity> medications;
  const DayDetailCard({
    super.key,
    required this.date,
    required this.allCheckIns,
    required this.moodEntries,
    required this.medications,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // v0.28 round 65 (spzh P2-H 修复): DayDetailCalculator.fromData
    // v0.27 round 77 (R76-N11 修): 改用 6 个 closure 注入 i18n, 跟
    // l10n 解耦 (l10n 通过 closure 闭包传入, day_detail.dart 不再 import l10n)。
    final detail = DayDetailCalculator.fromData(
      date: date,
      checkIns: allCheckIns,
      moodEntries: moodEntries,
      medications: medications,
      checkInLabel: (medName) => l10n.dayDetailCheckInWith(medName ?? ''),
      dailyLabel: () => l10n.dayDetailDailyCheckIn,
      tempLabel: (medName) => l10n.dayDetailTempWith(medName ?? ''),
      tempDefaultLabel: () => l10n.dayDetailTempMed,
      phq9Name: () => l10n.dayDetailPhq9,
      gad7Name: () => l10n.dayDetailGad7,
      // R114 BUG 4: 全量表名按 id 派发 (8 个 R90 新量表修前显示裸 id)
      scaleName: (id) => scaleNameL10n(id, l10n),
      // R114 BUG 4: 情绪标签 + 总分后缀走 l10n (修前 en locale 看中文)
      moodLabel: (score) => moodLabel(l10n, score),
      totalScoreLabel: l10n.dayDetailTotalScore,
    );
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return Card(
      child: Padding(
        padding: AppTokens.edgeInsetsMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  dateStr,
                  // v0.27 R77: textStyleLabel (textPrimary) → textSecondary + w500
                  style: AppTokens.textStyleLabel(context).copyWith(
                    color: AppTokens.textSecondaryColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: AppTokens.spacingSm),
                if (detail.hasNormalCheckIn)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.spacingChipGap,
                      vertical: AppTokens.spacingXxxs,
                    ),
                    decoration: BoxDecoration(
                      // v0.22 round 29 (emil-01~12): 改用 tintedPrimaryDeep 集中器
                      color: AppTokens.tintedPrimaryDeep(context),
                      borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                    ),
                    child: Text(
                      l10n.trendCheckedIn,
                      // v0.27 R77: textStyleMicro (textSecondary) → primary + w500
                      // v0.22 round 29 (emil-16): emil 报告原文用 11, 实际是 10 微小字
                      // 改用 fontSizeMicro token
                      style: AppTokens.textStyleMicro(context).copyWith(
                        color: AppTokens.primaryColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.spacingChipGap,
                      vertical: AppTokens.spacingXxxs,
                    ),
                    decoration: BoxDecoration(
                      color: AppTokens.dividerColor(context),
                      borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                    ),
                    child: Text(
                      l10n.trendNotCheckedIn,
                      style: AppTokens.textStyleMicro(context).copyWith(
                        color: AppTokens.textHintColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const Spacer(),
                if (detail.events.isNotEmpty)
                  Text(
                    l10n.trendEventCount(detail.events.length),
                    // v0.27 R77: caption + textHint (比 caption 的 textSecondary 弱)
                    style: AppTokens.textStyleCaption(context)
                        .copyWith(color: AppTokens.textHintColor(context)),
                  ),
              ],
            ),
            if (detail.bestMoodScore != null &&
                detail.worstMoodScore != null) ...[
              const SizedBox(height: AppTokens.spacingXs),
              Row(
                children: [
                  Icon(
                    Icons.mood_outlined,
                    size: AppTokens.iconSizeSmall,
                    color: AppTokens.textSecondaryColor(context),
                  ),
                  const SizedBox(width: AppTokens.spacingXxxs),
                  Text(
                    detail.bestMoodScore == detail.worstMoodScore
                        ? l10n.trendMoodEntriesSame(
                            detail.totalMoodEntries,
                            MoodVisual.emojiFor(detail.bestMoodScore!),
                          )
                        : l10n.trendMoodEntriesRange(
                            detail.totalMoodEntries,
                            MoodVisual.emojiFor(detail.worstMoodScore!),
                            MoodVisual.emojiFor(detail.bestMoodScore!),
                          ),
                    // v0.27 R77: 直接用 textStyleCaption (textSecondary)
                    style: AppTokens.textStyleCaption(context),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppTokens.spacingSm),
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: AppTokens.spacingSm),
            if (detail.events.isEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppTokens.spacingSm),
                child: Row(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 20,
                      color: AppTokens.textSecondaryColor(context),
                    ),
                    const SizedBox(width: AppTokens.spacingXs),
                    Text(
                      l10n.trendNoRecords,
                      // v0.27 R77: textStyleBody (textPrimary) → textHint
                      style: AppTokens.textStyleBody(context)
                          .copyWith(color: AppTokens.textHintColor(context)),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  for (int i = 0; i < detail.events.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, thickness: 0.5, indent: 32),
                    EventRow(event: detail.events[i]),
                    // v0.29 round 84 (CBT 思维记录): 在 mood event 行下展开 CBT 摘要
                    if (detail.events[i].kind == DayEventKind.mood)
                      ..._cbtWidgetsFor(detail.events[i], context),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  // v0.29 round 84 (CBT 思维记录): 给定 mood event, 返回 CBT 摘要 widget 列表
  // (空 list = 不是 mood event 或无 CBT 字段)。
  // v0.30 round 95 (sub-spec 4 task 6): 仍是 private 实例 method, 但内部走
  // top-level _cbtFieldRow (因 class 内 private 跨引用需要).
  List<Widget> _cbtWidgetsFor(DayEvent event, BuildContext context) {
    if (event.kind != DayEventKind.mood) return const [];
    // 通过 timestamp 匹配对应的 MoodEntryEntity
    MoodEntryEntity? entry;
    for (final e in moodEntries) {
      if (e.timestamp == event.time) {
        entry = e;
        break;
      }
    }
    if (entry == null || !entry.isCbtRecord) return const [];

    final l10n = AppLocalizations.of(context);

    // badge 缩进 = 跟 EventRow 的文本列对齐 (time col + icon + spacing)
    const badgeIndent = AppTokens.eventTimeColWidth +
        AppTokens.iconSizeInline +
        AppTokens.spacingXs;
    // 各字段行缩进 = badge indent + badge 宽度之后,跟 EventRow 文本列对齐即可
    const fieldIndent = badgeIndent;

    final badgeLabel =
        entry.cbtLevel == 7 ? l10n.moodCbtChipBadge7 : l10n.moodCbtChipBadge5;

    return [
      Padding(
        padding: const EdgeInsets.only(
          left: badgeIndent,
          top: AppTokens.spacingXxxs,
          bottom: AppTokens.spacingXxxs,
        ),
        child: Wrap(
          spacing: AppTokens.spacingXxs,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.spacingChipGap,
                vertical: AppTokens.spacingXxxs,
              ),
              decoration: BoxDecoration(
                color: AppTokens.tintedPrimaryDeep(context),
                borderRadius: BorderRadius.circular(AppTokens.radiusChip),
              ),
              child: Text(
                badgeLabel,
                style: AppTokens.textStyleMicro(context).copyWith(
                  color: AppTokens.primaryColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
      if (entry.situation != null)
        _cbtFieldRow(
          context,
          l10n.moodCbtSectionSituation,
          entry.situation!,
          indent: fieldIndent,
        ),
      if (entry.automaticThought != null)
        _cbtFieldRow(
          context,
          l10n.moodCbtSectionAutomaticThought,
          entry.automaticThought!,
          indent: fieldIndent,
        ),
      if (entry.evidenceFor != null)
        _cbtFieldRow(
          context,
          l10n.moodCbtSectionEvidenceFor,
          entry.evidenceFor!,
          indent: fieldIndent,
        ),
      if (entry.evidenceAgainst != null)
        _cbtFieldRow(
          context,
          l10n.moodCbtSectionEvidenceAgainst,
          entry.evidenceAgainst!,
          indent: fieldIndent,
        ),
      if (entry.alternativeThought != null)
        _cbtFieldRow(
          context,
          l10n.moodCbtSectionAlternative,
          entry.alternativeThought!,
          indent: fieldIndent,
        ),
      if (entry.reratedScore != null)
        _cbtFieldRow(
          context,
          l10n.moodCbtSectionRerated,
          l10n.moodCbtReratedComparison(entry.reratedScore!, entry.score),
          indent: fieldIndent,
        ),
      if (entry.coreBelief != null)
        _cbtFieldRow(
          context,
          l10n.moodCbtSectionCoreBelief,
          entry.coreBelief!,
          indent: fieldIndent,
        ),
      if (entry.behaviorResponse != null)
        _cbtFieldRow(
          context,
          l10n.moodCbtSectionBehavior,
          entry.behaviorResponse!,
          indent: fieldIndent,
        ),
    ];
  }
}

/// v0.29 round 84: CBT 单字段行 (label: value), caption 字号 + secondary 色
/// v0.30 round 95 (sub-spec 4 task 6): 提到 top-level (原 instance method),
/// 因 Dart private 仅限同一 .dart 文件访问, 现在跨文件需要 public 或 top-level.
Widget _cbtFieldRow(
  BuildContext context,
  String label,
  String value, {
  required double indent,
}) {
  return Padding(
    padding: EdgeInsets.only(
      left: indent,
      bottom: AppTokens.spacingXxxs,
    ),
    child: Text(
      '$label: $value',
      style: TextStyle(
        fontSize: AppTokens.fontSizeCaption,
        color: AppTokens.textSecondaryColor(context),
      ),
    ),
  );
}
