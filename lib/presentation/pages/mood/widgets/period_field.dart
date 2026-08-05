// v0.30 round 91 (sub-spec 7 日常追踪 / Task 2): PeriodField
//
// mood_dialog 加的 1 个 dropdown — 5 段 (morning / noon / evening / night /
// unspecified), 4 段聚合 + 老 entry 兼容 (null = unspecified 桶)。
//
// 设计要点 (跟 R84 CbtSectionField / R87 MoodListFilterBar 同款):
// - ConsumerWidget — period 状态走 cbtDraftProvider (跟 score 同一份 state)
// - 走 l10n.moodDialogPeriodLabel + moodPeriodXxx (5 段)
// - 默认 'unspecified' (老 entry 兼容; draft.period = null 也归这桶)
// - onChanged → notifier.updateField(period: v) (跟 score 透传 save → DB)
// - ChoiceChip 不用 (ActionChip 风格更轻 + 跟 R87 filter bar 一致),
//   后续 v0.31+ 要换可改
// - 含 fill 5 段都列出来 (老 entry 兼容 — 用户可显式改 unspecified 桶)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/logic/mood_period_aggregator.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';

/// mood_dialog 的心境时段 dropdown
///
/// 5 段 (morning / noon / evening / night / unspecified), 走 l10n。
/// 状态从 cbtDraftProvider 读, 改动通过 onChanged 回调 → notifier.updateField。
class PeriodField extends ConsumerWidget {
  const PeriodField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(cbtDraftProvider);
    final notifier = ref.read(cbtDraftProvider.notifier);

    // 当前值: 跟 score 模式一致, draft.period == null 当 'unspecified' 桶
    final current = state.draft.period ?? MoodPeriod.unspecified;

    return Row(
      children: [
        Text(
          l10n.moodDialogPeriodLabel,
          style: AppTokens.textStyleLabel(context),
        ),
        const SizedBox(width: AppTokens.spacingSm),
        Expanded(
          child: DropdownButton<String>(
            value: current,
            isExpanded: true,
            isDense: true,
            underline: const SizedBox.shrink(),
            onChanged: (v) {
              if (v != null) notifier.updateField(period: v);
            },
            items: [
              for (final p in MoodPeriod.all)
                DropdownMenuItem(
                  value: p,
                  child: Text(_labelFor(l10n, p)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _labelFor(AppLocalizations l10n, String period) {
    switch (period) {
      case MoodPeriod.morning:
        return l10n.moodPeriodMorning;
      case MoodPeriod.noon:
        return l10n.moodPeriodNoon;
      case MoodPeriod.evening:
        return l10n.moodPeriodEvening;
      case MoodPeriod.night:
        return l10n.moodPeriodNight;
      case MoodPeriod.unspecified:
        return l10n.moodPeriodUnspecified;
    }
    return period;
  }
}
