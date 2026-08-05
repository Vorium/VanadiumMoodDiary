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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/anxiety_agitation_entry.dart';
import 'package:chroniccare/presentation/providers/daily_tracking_providers.dart';
import 'package:chroniccare/presentation/widgets/empty_state.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';

/// 焦虑急躁记录列表 (监听 anxietyAgitationEntriesProvider stream)
class AnxietyAgitationListWidget extends ConsumerWidget {
  const AnxietyAgitationListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(anxietyAgitationEntriesProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppTokens.spacingSm),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('添加评估'),
              onPressed: () => AnxietyAgitationEntryDialog.show(context),
            ),
          ),
        ),
        Expanded(
          child: entriesAsync.when(
            loading: () => const LoadingSkeleton.fullScreen(),
            error: (e, st) => Center(child: Text('加载失败: $e')),
            data: (entries) => entries.isEmpty
                ? const EmptyState(
                    icon: Icons.psychology_outlined,
                    title: '暂无焦虑急躁记录',
                    subtitle: '快速评估当前状态, 帮医生判断情绪变化',
                  )
                : ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, i) =>
                        _AnxietyAgitationEntryTile(entry: entries[i]),
                  ),
          ),
        ),
      ],
    );
  }
}

/// 单条 anxiety_agitation tile
class _AnxietyAgitationEntryTile extends StatelessWidget {
  const _AnxietyAgitationEntryTile({required this.entry});
  final AnxietyAgitationEntryEntity entry;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingSm,
        vertical: AppTokens.spacingXxs,
      ),
      child: ListTile(
        leading: Icon(Icons.psychology, color: AppTokens.primaryColor(context)),
        title: Text('焦虑 ${entry.anxietyScore} · 急躁 ${entry.agitationScore}',
            style: AppTokens.textStyleLabelStrong(context),),
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
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加焦虑急躁评估'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 焦虑分数 1-5 (1=严重 5=平静)
            Row(
              children: [
                Icon(Icons.psychology_outlined,
                    color: AppTokens.primaryColor(context),),
                const SizedBox(width: AppTokens.spacingXs),
                const Text('焦虑分数'),
                const SizedBox(width: AppTokens.spacingSm),
                const Text('1=严重 5=平静',
                    style: TextStyle(fontSize: AppTokens.fontSizeCaption),),
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
                const Text('急躁分数'),
                const SizedBox(width: AppTokens.spacingSm),
                const Text('1=平静 5=极急',
                    style: TextStyle(fontSize: AppTokens.fontSizeCaption),),
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
              decoration: const InputDecoration(
                labelText: '备注',
                border: OutlineInputBorder(),
                hintText: '可选',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed:
              (_saving || _anxietyScore == null || _agitationScore == null)
                  ? null
                  : _save,
          child: const Text('保存'),
        ),
      ],
    );
  }
}
