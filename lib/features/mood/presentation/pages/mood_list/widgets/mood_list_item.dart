// v0.30 round 87 (sub-spec 3 mood 列表页): 单行 mood entry 渲染
//
// 跟 trend_calendar DayDetailCard 复用 MoodVisual + AppTokens
// (sub-spec 1 加的 isCbtRecord / cbtLevel getter 也复用)。
//
// 设计要点:
// - 三段式行: leading(emoji) / 中(timestamp + score + note + CBT badge) / 可点
// - preview 优先 note, fallback 到 automaticThought, 都空才显示 '...'
// - 5/7 栏 entry 在 subtitle 末尾追加 chip 风格 badge,沿用 tintedPrimaryDeep + primaryColor
//   (跟 trend_calendar DayDetailCard 视觉一致)
//
// v0.32 R112 (EM-02/AH-04, spec §5.5): ListTile → PressFeedback + Row
// (home _RowCell 样板)。AppleListSection 容器是 DecoratedBox 非 Material,
// ListTile 在 debug 断言 "ink splashes may be invisible" → 改平铺 cell。
import 'package:flutter/material.dart';
import 'package:chroniccare/core/shared/mood_visual.dart';
import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/features/mood/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/l10n/preset_content_l10n.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';

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

    return PressFeedback(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          children: [
            Text(
              MoodVisual.emojiFor(entry.score),
              style: const TextStyle(fontSize: AppTokens.fontSizeTitle),
            ),
            const SizedBox(width: AppTokens.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(timestamp, style: AppTokens.textStyleCaption(context)),
                  const SizedBox(height: 2),
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
                  // v1.1.0 round 5d: 状态短语 (在标签/CBT badge 行前)
                  // round 7b: 显示层走 ARB 本地化 (存储仍是 canonical zh)
                  if (entry.statusPhrase != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppTokens.spacingXxs),
                      child: Text(
                        '“${localizedStatusPhrase(context, entry.statusPhrase!)}”',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTokens.textStyleMicro(context).copyWith(
                          color: AppTokens.primaryColor(context),
                        ),
                      ),
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
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusChip),
                        ),
                        child: Text(
                          entry.cbtLevel == 7
                              ? l10n.moodCbtChipBadge7
                              : l10n.moodCbtChipBadge5,
                          style: AppTokens.textStyleMicro(context).copyWith(
                            color: AppTokens.primaryColor(context),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTimestamp(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
  }
}
