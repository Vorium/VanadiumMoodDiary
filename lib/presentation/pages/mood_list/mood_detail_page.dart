// v0.30 R101: 情绪详情页 — 展示完整 mood entry 信息
//
// 点击列表条目 → 完整 CBT 内容 + 影响因素 + 录音播放 + 编辑/删除

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/shared/mood_visual.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/core/theme/app_colors.dart';
import 'package:chroniccare/domain/entities/influence_category.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/services/influence_factor_l10n.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/widgets/press_feedback_icon_button.dart';

class MoodDetailPage extends ConsumerWidget {
  const MoodDetailPage({super.key, this.entry, this.entryId})
      : assert(entry != null || entryId != null, 'entry 与 entryId 至少传一个');

  /// 直接传入的 entry (widget 测试 / 潜在老调用场景)
  final MoodEntryEntity? entry;

  /// v0.32 R112-02: 路由 /mood/detail/:id 传的 id, 从 allMoodProvider 反查
  final int? entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (entry != null) return _content(context, ref, entry!);
    return ref.watch(allMoodProvider).when(
          data: (entries) {
            MoodEntryEntity? found;
            for (final e in entries) {
              if (e.id == entryId) {
                found = e;
                break;
              }
            }
            if (found == null) {
              return PageScaffold(
                title: l10n.moodDetailTitle,
                child: Center(
                  child: Text(
                    l10n.moodEntryNotFound,
                    style: TextStyle(
                      fontSize: AppTokens.fontSizeBody,
                      color: AppTokens.textHintColor(context),
                    ),
                  ),
                ),
              );
            }
            return _content(context, ref, found);
          },
          loading: () => PageScaffold(
            title: l10n.moodDetailTitle,
            child: const Center(child: LoadingSpinner()),
          ),
          error: (e, _) => PageScaffold(
            title: l10n.moodDetailTitle,
            child: Center(child: Text('$e')),
          ),
        );
  }

  Widget _content(BuildContext context, WidgetRef ref, MoodEntryEntity entry) {
    final l10n = AppLocalizations.of(context);

    return PageScaffold(
      title: l10n.moodDetailTitle,
      actions: [
        // v0.31.1 round 8 (emil P0-C + R108 P1-001 漏修): 改用
        // PressFeedbackIconButton 集中器。
        PressFeedbackIconButton(
          icon: Icons.delete_outline,
          tooltip: l10n.moodDeleteTooltip,
          onPressed: () => _confirmDelete(context, ref, entry),
        ),
      ],
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ═══ 顶部: emoji + 评分 + 时间 (Card → AppleListSection, R112 EM-02) ═══
            AppleListSection(
              margin: EdgeInsets.zero,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTokens.spacingSm,
                  ),
                  child: Row(
                    children: [
                      ExcludeSemantics(
                        child: Text(
                          MoodVisual.emojiFor(entry.score),
                          // EM-08: 装饰性 emoji 大字号 (48), 无对应 token
                          // 档位, deliberate 保留 (emoji 渲染有 size cap)
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
                                // v0.32 round 8 (R111 EM-06 fix): 大数字改
                                // ultralight w200 (Apple Health 指标风格)
                                fontWeight: AppTokens.fontWeightUltralight,
                                color: AppColors.moodScoreColor(entry.score),
                              ),
                            ),
                            // v1.1.0 round 5d: 状态短语 — score 下的显著行
                            if (entry.statusPhrase != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: AppTokens.spacingXxs,
                                ),
                                child: Text(
                                  '“${entry.statusPhrase}”',
                                  style: TextStyle(
                                    fontSize: AppTokens.fontSizeBody,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.moodScoreColor(
                                      entry.score,
                                    ),
                                  ),
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
              ],
            ),

            // 情绪状态标签
            if (entry.tags.isNotEmpty) ...[
              const SizedBox(height: AppTokens.spacingSm),
              AppleListSection(
                title: l10n.moodDetailMoodState,
                margin: EdgeInsets.zero,
                children: [
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
                ],
              ),
            ],

            // 影响因素
            if (entry.hasInfluenceFactors) ...[
              const SizedBox(height: AppTokens.spacingSm),
              AppleListSection(
                title: l10n.moodDetailFactors,
                margin: EdgeInsets.zero,
                children: [
                  Wrap(
                    spacing: AppTokens.spacingXs,
                    runSpacing: AppTokens.spacingXxs,
                    children: entry.influenceFactors
                        .map(
                          (f) => Chip(
                            // v0.32 R112-03: 旧中文数据反查 key + ARB 派发
                            label: Text(
                              influenceFactorL10nLabel(
                                l10n,
                                influenceFactorNormalizeKey(f),
                              ),
                            ),
                            backgroundColor:
                                AppTokens.tintedPrimarySoft(context),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ],

            // CBT 思维记录 (Card → AppleListSection)
            if (entry.isCbtRecord) ...[
              const SizedBox(height: AppTokens.spacingSm),
              AppleListSection(
                title: l10n.moodDetailCbtRecord,
                margin: EdgeInsets.zero,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTokens.spacingXxs,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (entry.situation != null)
                          _CbtField(
                            label: l10n.moodCbtSituation,
                            value: entry.situation!,
                          ),
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
                ],
              ),
            ],

            // 文字备注 (Card → AppleListSection)
            if (entry.note != null && entry.note!.isNotEmpty) ...[
              const SizedBox(height: AppTokens.spacingSm),
              AppleListSection(
                margin: EdgeInsets.zero,
                children: [
                  Text(
                    entry.note!,
                    style: const TextStyle(fontSize: AppTokens.fontSizeBody),
                  ),
                ],
              ),
            ],

            // 录音信息 (Card → AppleListSection)
            if (entry.hasAudio) ...[
              const SizedBox(height: AppTokens.spacingSm),
              AppleListSection(
                margin: EdgeInsets.zero,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.mic,
                        color: AppTokens.primaryColor(context),
                      ),
                      const SizedBox(width: AppTokens.spacingSm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.moodRecordingLabel(
                                _formatDuration(entry.audioDurationMs),
                              ),
                            ),
                            if (entry.audioTranscript != null)
                              Text(
                                entry.audioTranscript!,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppTokens.spacingLg),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    MoodEntryEntity entry,
  ) {
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
