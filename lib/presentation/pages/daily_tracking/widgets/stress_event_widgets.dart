// v0.30 round 91 (sub-spec 7 日常追踪 / Task 4 UI): StressEventListWidget + StressEventEntryDialog
//
// 4 层架构: presentation/pages/daily_tracking/widgets/, 0 跨 feature import。
// 复用 R88 mood_dialog 风格。
//
// 应激源记录 (R91 3 字段):
// - eventType dropdown ('work' / 'relationship' / 'health' / 'financial' / 'other')
//   默认 'work', 5 档 enum (跟 brief 一致)
// - intensity 5 档评分 (1-5, required)
// - note 可选备注
//
// 跟 R60 R90 一致: eventType 是 String 自由 (不用 enum, 应用层 validation)。
//
// v0.30 R91 Task 7: i18n — 替换 hardcoded 中文 placeholder + eventType 中文
// 走 l10n.stressEventTypeXxx
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/stress_event.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/daily_tracking_widgets.dart';
import 'package:chroniccare/presentation/providers/daily_tracking_providers.dart';
import 'package:chroniccare/presentation/widgets/empty_state.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';

/// 5 档事件类型 id (跟 spec 一致, 走 l10n 拿中文 label)
const _kEventTypeIds = <String>[
  'work',
  'relationship',
  'health',
  'financial',
  'other',
];

/// 事件类型 → l10n 中文 label
String _eventTypeLabel(BuildContext context, String eventType) {
  final l10n = AppLocalizations.of(context);
  switch (eventType) {
    case 'work':
      return l10n.stressEventTypeWork;
    case 'relationship':
      return l10n.stressEventTypeRelationship;
    case 'health':
      return l10n.stressEventTypeHealth;
    case 'financial':
      return l10n.stressEventTypeFinancial;
    case 'other':
      return l10n.stressEventTypeOther;
  }
  return eventType;
}

/// 应激源记录列表 (监听 stressEventEntriesProvider stream)
///
/// v0.30 R91 Fix Round 1 (I-2): AppBar title 走 l10n.stressEventName,
/// 跟 R87 MoodListPage pattern 一致. 路由 file 不再包 PageScaffold wrapper.
class StressEventListWidget extends ConsumerWidget {
  const StressEventListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final entriesAsync = ref.watch(stressEventEntriesProvider);

    return PageScaffold(
      title: l10n.stressEventName,
      child: Column(
        children: [
          Padding(
            padding: AppTokens.edgeInsetsSm,
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                icon: const Icon(Icons.add),
                label: Text(l10n.stressEventAddButton),
                onPressed: () => StressEventEntryDialog.show(context),
              ),
            ),
          ),
          Expanded(
            child: entriesAsync.when(
              loading: () => const LoadingSkeleton.fullScreen(),
              error: (e, st) =>
                  Center(child: Text(l10n.commonLoadFailed(e.toString()))),
              data: (entries) => entries.isEmpty
                  ? EmptyState(
                      icon: Icons.bolt_outlined,
                      title: l10n.stressEventNoData,
                      subtitle: l10n.stressEventHint,
                    )
                  : ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, i) =>
                          _StressEventEntryTile(entry: entries[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 单条 stress_event tile
class _StressEventEntryTile extends StatelessWidget {
  const _StressEventEntryTile({required this.entry});
  final StressEventEntity entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingSm,
        vertical: AppTokens.spacingXxs,
      ),
      child: ListTile(
        leading: Icon(Icons.bolt, color: AppTokens.warningColor(context)),
        title: Text(
          '${_eventTypeLabel(context, entry.eventType)} · ${l10n.stressIntensityScore(entry.intensity)}',
          style: AppTokens.textStyleLabelStrong(context),
        ),
        subtitle: entry.note != null ? Text(entry.note!) : null,
      ),
    );
  }
}

/// StressEventEntryDialog — 3 字段 (eventType / intensity / note)
class StressEventEntryDialog extends ConsumerStatefulWidget {
  const StressEventEntryDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const StressEventEntryDialog(),
    );
  }

  @override
  ConsumerState<StressEventEntryDialog> createState() =>
      _StressEventEntryDialogState();
}

class _StressEventEntryDialogState
    extends ConsumerState<StressEventEntryDialog> {
  String _eventType = _kEventTypeIds.first; // 默认 'work'
  int? _intensity; // 1-5 required, null = 未选 (按钮 disabled)
  final _noteController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final intensity = _intensity;
    if (intensity == null) return; // intensity required
    setState(() => _saving = true);
    try {
      await ref.read(stressEventRepositoryProvider).add(
            timestamp: DateTime.now(),
            eventType: _eventType,
            intensity: intensity,
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
      title: Text(l10n.stressEventAddButton),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // eventType dropdown
            DropdownButtonFormField<String>(
              initialValue: _eventType,
              decoration: InputDecoration(
                labelText: l10n.stressEventEventType,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final id in _kEventTypeIds)
                  DropdownMenuItem(
                    value: id,
                    child: Text(_eventTypeLabel(context, id)),
                  ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _eventType = v);
              },
            ),
            const SizedBox(height: AppTokens.spacingMd),
            // intensity 5 档
            Row(
              children: [
                Icon(Icons.flash_on, color: AppTokens.warningColor(context)),
                const SizedBox(width: AppTokens.spacingXs),
                Text(l10n.stressEventIntensity),
              ],
            ),
            const SizedBox(height: AppTokens.spacingXxs),
            Wrap(
              spacing: AppTokens.spacingXs,
              children: [
                for (var i = 1; i <= 5; i++)
                  ChoiceChip(
                    label: Text('$i'),
                    selected: _intensity == i,
                    onSelected: (_) {
                      setState(() => _intensity = i);
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
          onPressed: (_saving || _intensity == null) ? null : _save,
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}
