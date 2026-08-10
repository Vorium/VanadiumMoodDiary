// v0.30 R101: 情绪详情页 — 展示完整 mood entry 信息
//
// 点击列表条目 → 完整 CBT 内容 + 影响因素 + 录音播放 + 编辑/删除

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/shared/mood_visual.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';

class MoodDetailPage extends ConsumerWidget {
  const MoodDetailPage({super.key, required this.entry});
  final MoodEntryEntity entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return PageScaffold(
      title: l10n.moodDetailTitle,
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: l10n.moodDeleteTooltip,
          onPressed: () => _confirmDelete(context, ref),
        ),
      ],
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 顶部: emoji + 评分 + 时间
          Card(
            child: Padding(
              padding: AppTokens.edgeInsetsLg,
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: Text(
                      MoodVisual.emojiFor(entry.score),
                      style: const TextStyle(fontSize: 48),
                    ),
                  ),
                  const SizedBox(width: AppTokens.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.score}/5',
                          style: TextStyle(
                            fontSize: AppTokens.fontSizeTitle,
                            fontWeight: FontWeight.w700,
                            color: Color(MoodVisual.colorArgbFor(entry.score)),
                          ),
                        ),
                        Text(
                          _formatDateTime(entry.timestamp),
                          style: TextStyle(
                            fontSize: AppTokens.fontSizeCaption,
                            color: AppTokens.textHintColor(context),
                          ),
                        ),
                        if (entry.period != null)
                          Text(
                            _periodLabel(entry.period!, l10n),
                            style: TextStyle(
                              fontSize: AppTokens.fontSizeCaption,
                              color: AppTokens.textSecondaryColor(context),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppTokens.spacingSm),

          // 情绪状态标签
          if (entry.tags.isNotEmpty) ...[
            Text(
              l10n.moodDetailMoodState,
              style: const TextStyle(
                fontSize: AppTokens.fontSizeBody,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTokens.spacingXxs),
            Wrap(
              spacing: AppTokens.spacingXs,
              runSpacing: AppTokens.spacingXxs,
              children: entry.tags
                  .map(
                    (tag) => Chip(
                      label: Text(tag),
                      backgroundColor: AppTokens.primaryColor(context)
                          .withValues(alpha: 0.1),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppTokens.spacingSm),
          ],

          // 影响因素
          if (entry.hasInfluenceFactors) ...[
            Text(
              l10n.moodDetailFactors,
              style: const TextStyle(
                fontSize: AppTokens.fontSizeBody,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTokens.spacingXxs),
            Wrap(
              spacing: AppTokens.spacingXs,
              runSpacing: AppTokens.spacingXxs,
              children: entry.influenceFactors
                  .map(
                    (f) => Chip(
                      label: Text(f),
                      backgroundColor: AppTokens.tintedPrimarySoft(context),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppTokens.spacingSm),
          ],

          // CBT 思维记录
          if (entry.isCbtRecord) ...[
            Text(
              l10n.moodDetailCbtRecord,
              style: const TextStyle(
                fontSize: AppTokens.fontSizeBody,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTokens.spacingXxs),
            Card(
              child: Padding(
                padding: AppTokens.edgeInsetsMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entry.situation != null)
                      _CbtField(
                          label: l10n.moodCbtSituation,
                          value: entry.situation!,),
                    if (entry.automaticThought != null)
                      _CbtField(
                        label: l10n.moodCbtAutoThought,
                        value: entry.automaticThought!,
                      ),
                    if (entry.evidenceFor != null)
                      _CbtField(
                        label: l10n.moodCbtEvidenceFor,
                        value: entry.evidenceFor!,
                      ),
                    if (entry.evidenceAgainst != null)
                      _CbtField(
                        label: l10n.moodCbtEvidenceAgainst,
                        value: entry.evidenceAgainst!,
                      ),
                    if (entry.alternativeThought != null)
                      _CbtField(
                        label: l10n.moodCbtAltThought,
                        value: entry.alternativeThought!,
                      ),
                    if (entry.reratedScore != null)
                      _CbtField(
                        label: l10n.moodCbtRerated,
                        value: '${entry.reratedScore}/5',
                      ),
                    if (entry.coreBelief != null)
                      _CbtField(
                        label: l10n.moodCbtCoreBelief,
                        value: entry.coreBelief!,
                      ),
                    if (entry.behaviorResponse != null)
                      _CbtField(
                        label: l10n.moodCbtBehavior,
                        value: entry.behaviorResponse!,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTokens.spacingSm),
          ],

          // 文字备注
          if (entry.note != null && entry.note!.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: AppTokens.edgeInsetsMd,
                child: Text(
                  entry.note!,
                  style: const TextStyle(fontSize: AppTokens.fontSizeBody),
                ),
              ),
            ),
            const SizedBox(height: AppTokens.spacingSm),
          ],

          // 录音信息
          if (entry.hasAudio) ...[
            Card(
              child: ListTile(
                leading:
                    Icon(Icons.mic, color: AppTokens.primaryColor(context)),
                title: Text(l10n.moodRecordingLabel(_formatDuration(entry.audioDurationMs))),
                subtitle: entry.audioTranscript != null
                    ? Text(
                        entry.audioTranscript!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.moodDeleteTooltip),
        content: Text(l10n.moodDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(moodRepositoryProvider).delete(entry.id);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                AppSnackBar.showInfo(context, l10n.moodDeleted);
                context.pop();
              }
            },
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _periodLabel(String period, AppLocalizations l10n) {
    switch (period) {
      case 'morning':
        return l10n.moodPeriodMorning;
      case 'noon':
      case 'afternoon':
        return l10n.moodPeriodAfternoon;
      case 'evening':
        return l10n.moodPeriodEvening;
      case 'night':
        return l10n.moodPeriodNight;
      default:
        return '';
    }
  }

  String _formatDuration(int? ms) {
    if (ms == null) return '';
    final seconds = (ms / 1000).round();
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}

class _CbtField extends StatelessWidget {
  const _CbtField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.spacingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppTokens.fontSizeCaption,
              fontWeight: FontWeight.w600,
              color: AppTokens.textSecondaryColor(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: AppTokens.fontSizeBody),
          ),
        ],
      ),
    );
  }
}
