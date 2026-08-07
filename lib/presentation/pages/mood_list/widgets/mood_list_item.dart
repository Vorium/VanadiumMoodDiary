// v0.30 round 87 (sub-spec 3 mood 列表页): 单行 mood entry 渲染
//
// 跟 trend_calendar DayDetailCard 复用 MoodVisual + AppTokens
// (sub-spec 1 加的 isCbtRecord / cbtLevel getter 也复用)。
//
// 设计要点:
// - ListTile 标准三段: leading(emoji) / title(timestamp) / subtitle(score + note + CBT badge)
// - preview 优先 note, fallback 到 automaticThought, 都空才显示 '...'
// - 5/7 栏 entry 在 subtitle 末尾追加 chip 风格 badge,沿用 tintedPrimaryDeep + primaryColor
//   (跟 trend_calendar DayDetailCard 视觉一致)
import 'package:flutter/material.dart';
import 'package:chroniccare/core/shared/mood_visual.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

class MoodListItem extends StatelessWidget {
  final MoodEntryEntity entry;
  final VoidCallback? onTap;
  const MoodListItem({super.key, required this.entry, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final timestamp = _formatTimestamp(entry.timestamp);
    final preview = entry.note?.isNotEmpty ?? false
        ? entry.note!
        : entry.automaticThought?.isNotEmpty ?? false
              ? entry.automaticThought!
              : '...';

    return ListTile(
      onTap: onTap,
      leading: Text(
        MoodVisual.emojiFor(entry.score),
        style: const TextStyle(fontSize: AppTokens.fontSizeTitle),
      ),
      title: Text(timestamp, style: AppTokens.textStyleCaption(context)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${entry.score}/5'),
              const SizedBox(width: AppTokens.spacingXs),
              Expanded(
                child: Text(
                  preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (entry.isCbtRecord)
            Padding(
              padding: const EdgeInsets.only(top: AppTokens.spacingXxs),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppTokens.tintedPrimaryDeep(context),
                  borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                ),
                child: Text(
                  entry.cbtLevel == 7 ? l10n.moodCbtChipBadge7 : l10n.moodCbtChipBadge5,
                  style: AppTokens.textStyleMicro(context).copyWith(
                    color: AppTokens.primaryColor(context),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _formatTimestamp(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
  }
}
