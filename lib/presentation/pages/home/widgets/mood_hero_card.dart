// 1.1.0 round 5b (emotion-first refactor · Task 12): MoodHeroCard 情绪大卡
//
// 首页双主卡之一: 最新心情状态短语 (statusPhrase, 无则 4 维迷你分退化) +
// 上次记录时间 + 记录/回顾 2 入口。
//
// 数据: latestMoodProvider (moodRepositoryProvider.watchLatest() 的
// StreamProvider 包装, 跟 TodaySummaryCard 同一数据源)。
//
// 设计:
// - AppleListSection("今日心情") 包装 (跟 home 其他 section 一致, margin zero)
// - 空数据: ListTile + 记录 button (homeMoodHeroNoData)
// - 有数据: 状态短语 headline + 时间 caption + 记录/回顾 buttons
// - 时间格式化走 core/shared/formatters.dart Formatters.time (项目统一
//   helper, 不直接 import intl DateFormat)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/shared/formatters.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/l10n/preset_content_l10n.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/mood_recorder_page.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';

/// 情绪大卡 — 最新状态短语 + 4 维迷你分退化 + 记录/回顾入口
class MoodHeroCard extends ConsumerWidget {
  const MoodHeroCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final latestAsync = ref.watch(latestMoodProvider);
    return latestAsync.maybeWhen(
      data: (entry) => entry == null
          ? _empty(context, ref, l10n)
          : _loaded(context, ref, l10n, entry),
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _empty(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    return AppleListSection(
      title: l10n.homeMoodHeroTitle,
      margin: EdgeInsets.zero,
      children: [
        // v1.1.0 round 11 (R115+ polish): padding 16 → 18, 加大 hero 卡视觉权重
        // 跟 VentHeroCard 一起从「次要卡」升格为「双主卡」(emotion-first)。
        Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const Icon(
                Icons.sentiment_satisfied_outlined,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.homeMoodHeroNoData,
                  style: AppTokens.textStyleBody(context),
                ),
              ),
              PressFeedback(
                child: FilledButton(
                  onPressed: () => MoodRecorderPage.show(context, ref),
                  child: Text(l10n.homeMoodHeroRecord),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _loaded(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    MoodEntryEntity entry,
  ) {
    final phrase = entry.statusPhrase == null
        ? null
        : localizedStatusPhrase(context, entry.statusPhrase!);
    final summary = phrase ?? _dimensionSummary(l10n, entry);
    return AppleListSection(
      title: l10n.homeMoodHeroTitle,
      margin: EdgeInsets.zero,
      children: [
        Padding(
          // v1.1.0 round 11 (R115+ polish): padding 16 → 18, headline 字号 → 24
          // 升格为「双主卡」, 跟 VentHeroCard 视觉对齐。
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                summary,
                // R115+ polish: 24px 突出大字号, 跟 VentHeroCard 一致
                style: AppTokens.textStyleHeadline(context).copyWith(
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: AppTokens.spacingXxs),
              Text(
                l10n.homeMoodHeroLastRecorded(Formatters.time(entry.timestamp)),
                style: AppTokens.textStyleCaption(context),
              ),
              const SizedBox(height: AppTokens.spacingXs),
              Row(
                children: [
                  // R114 Wave B2 (B2-9, emil F4): 主页双主卡入口按钮补
                  // scale 0.97 反馈 (修前只有 M3 ripple, 跟 CheckInButton
                  // "被听见"标准不一致)
                  PressFeedback(
                    child: FilledButton(
                      onPressed: () => MoodRecorderPage.show(context, ref),
                      child: Text(l10n.homeMoodHeroRecord),
                    ),
                  ),
                  const SizedBox(width: AppTokens.spacingSm),
                  PressFeedback(
                    child: TextButton(
                      onPressed: () => context.push('/mood-review'),
                      child: Text(l10n.homeMoodHeroReview),
                    ),
                  ),
                  // round 7c: /mood-list 死路由入口补齐 (P2 gatekeeper blind spot)
                  const SizedBox(width: AppTokens.spacingSm),
                  PressFeedback(
                    child: TextButton(
                      onPressed: () => context.push('/mood-list'),
                      child: Text(l10n.homeMoodHeroViewAll),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 无短语退化: '情绪 4 · 精力 3 · 睡眠 3 · 焦虑 3' 样式, 用 mood_score_chooser
  /// 里现有 4 维 label (l10n.moodDimensionMood 等), null 维度跳过
  String _dimensionSummary(AppLocalizations l10n, MoodEntryEntity e) {
    final parts = <String>[
      '${l10n.moodDimensionMood} ${e.score}',
      if (e.energy != null) '${l10n.moodDimensionEnergy} ${e.energy}',
      if (e.sleep != null) '${l10n.moodDimensionSleep} ${e.sleep}',
      if (e.anxiety != null) '${l10n.moodDimensionAnxiety} ${e.anxiety}',
    ];
    return parts.join(' · ');
  }
}
