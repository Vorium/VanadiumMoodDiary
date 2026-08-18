// v0.30 round 91 (sub-spec 7 日常追踪 / Task 4 UI): AnxietyAgitationListWidget + AnxietyAgitationEntryDialog
//
// 4 层架构: presentation/pages/daily_tracking/widgets/, 0 跨 feature import。
// 复用 R88 mood_dialog 风格。
//
// 焦虑急躁快速评估 (R91 3 字段):
// - anxietyScore 5 档 (1=严重 / 5=平静, 反向计分, required)
// - agitationScore 5 档 (1=平静 / 5=极度急躁, required)
// - note 可选备注
//
// 跟 brief 一致: 2 score required, note optional。
//
// v0.30 R91 Task 7: i18n — 替换 hardcoded 中文 placeholder 走 l10n
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/domain/entities/anxiety_agitation_entry.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/daily_tracking_widgets.dart';
import 'package:chroniccare/presentation/providers/daily_tracking_providers.dart';
import 'package:chroniccare/presentation/widgets/empty_state.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/widgets/error_state.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';

/// 焦虑急躁记录列表 (监听 anxietyAgitationEntriesProvider stream)
///
/// v0.30 R91 Fix Round 1 (I-2): AppBar title 走 l10n.anxietyAgitationName,
/// 跟 R87 MoodListPage pattern 一致. 路由 file 不再包 PageScaffold wrapper.
class AnxietyAgitationListWidget extends ConsumerWidget {
  const AnxietyAgitationListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final entriesAsync = ref.watch(anxietyAgitationEntriesProvider);

    return PageScaffold(
      title: l10n.anxietyAgitationName,
      child: Column(
        children: [
          Padding(
            padding: AppTokens.edgeInsetsSm,
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                icon: const Icon(Icons.add),
                label: Text(l10n.anxietyAgitationAddButton),
                onPressed: () => AnxietyAgitationEntryDialog.show(context),
              ),
            ),
          ),
          Expanded(
            child: entriesAsync.when(
              loading: () => const LoadingSkeleton.fullScreen(),
              error: (e, st) => ErrorState(
                title: l10n.commonLoadFailed(e.toString()),
              ),
              data: (entries) => entries.isEmpty
                  ? EmptyState(
                      icon: Icons.psychology_outlined,
                      title: l10n.anxietyAgitationNoData,
                      subtitle: l10n.anxietyAgitationHint,
                    )
                  : ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, i) =>
                          _AnxietyAgitationEntryTile(entry: entries[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 单条 anxiety_agitation tile
class _AnxietyAgitationEntryTile extends StatelessWidget {
  const _AnxietyAgitationEntryTile({required this.entry});
  final AnxietyAgitationEntryEntity entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingSm,
        vertical: AppTokens.spacingXxs,
      ),
      child: ListTile(
        leading: Icon(Icons.psychology, color: AppTokens.primaryColor(context)),
        title: Text(
          '${l10n.anxietyAgitationAnxietyScore(entry.anxietyScore)} · ${l10n.anxietyAgitationAgitationScore(entry.agitationScore)}',
          style: AppTokens.textStyleLabelStrong(context),
        ),
        subtitle: entry.note != null ? Text(entry.note!) : null,
      ),
    );
  }
}

/// AnxietyAgitationEntryDialog — 3 字段 (anxietyScore / agitationScore / note)
class AnxietyAgitationEntryDialog extends ConsumerStatefulWidget {
  const AnxietyAgitationEntryDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const AnxietyAgitationEntryDialog(),
    );
  }

  @override
  ConsumerState<AnxietyAgitationEntryDialog> createState() =>
      _AnxietyAgitationEntryDialogState();
}

class _AnxietyAgitationEntryDialogState
    extends ConsumerState<AnxietyAgitationEntryDialog> {
  int? _anxietyScore; // 1-5 required
  int? _agitationScore; // 1-5 required
  final _noteController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final anxiety = _anxietyScore;
    final agitation = _agitationScore;
    if (anxiety == null || agitation == null) return; // both required
    setState(() => _saving = true);
    try {
      await ref.read(anxietyAgitationRepositoryProvider).add(
            timestamp: DateTime.now(),
            anxietyScore: anxiety,
            agitationScore: agitation,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          );
      if (!mounted) return;
      DailyTrackingNav.safePop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      DailyTrackingSnackBar.showSaveError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.anxietyAgitationAddButton),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 焦虑分数 1-5 (1=严重 5=平静)
            Row(
              children: [
                Icon(
                  Icons.psychology_outlined,
                  color: AppTokens.primaryColor(context),
                ),
                const SizedBox(width: AppTokens.spacingXs),
                Text(l10n.anxietyAgitationAnxietyLabel),
                const SizedBox(width: AppTokens.spacingSm),
                Text(
                  l10n.anxietyAgitationAnxietyScaleHint,
                  style: const TextStyle(fontSize: AppTokens.fontSizeCaption),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spacingXxs),
            Wrap(
              spacing: AppTokens.spacingXs,
              children: [
                for (var i = 1; i <= 5; i++)
                  ChoiceChip(
                    label: Text('$i'),
                    selected: _anxietyScore == i,
                    onSelected: (_) {
                      setState(() => _anxietyScore = i);
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppTokens.spacingMd),
            // 急躁分数 1-5 (1=平静 5=极度急躁)
            Row(
              children: [
                Icon(Icons.flash_on, color: AppTokens.warningColor(context)),
                const SizedBox(width: AppTokens.spacingXs),
                Text(l10n.anxietyAgitationAgitationLabel),
                const SizedBox(width: AppTokens.spacingSm),
                Text(
                  l10n.anxietyAgitationAgitationScaleHint,
                  style: const TextStyle(fontSize: AppTokens.fontSizeCaption),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spacingXxs),
            Wrap(
              spacing: AppTokens.spacingXs,
              children: [
                for (var i = 1; i <= 5; i++)
                  ChoiceChip(
                    label: Text('$i'),
                    selected: _agitationScore == i,
                    onSelected: (_) {
                      setState(() => _agitationScore = i);
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppTokens.spacingSm),
            // note
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                // R100 (P1#9): 走 ARB 集中器 (复用 dailyTrackingNote*)
                labelText: l10n.dailyTrackingNoteLabel,
                border: const OutlineInputBorder(),
                hintText: l10n.dailyTrackingNoteHint,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed:
              (_saving || _anxietyScore == null || _agitationScore == null)
                  ? null
                  : _save,
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}
