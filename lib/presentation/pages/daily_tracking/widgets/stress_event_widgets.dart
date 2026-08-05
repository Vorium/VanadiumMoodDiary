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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/stress_event.dart';
import 'package:chroniccare/presentation/providers/daily_tracking_providers.dart';
import 'package:chroniccare/presentation/widgets/empty_state.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';

/// 5 档事件类型 (跟 spec 一致)
const _kEventTypes = <(String, String)>[
  ('work', '工作'),
  ('relationship', '人际关系'),
  ('health', '健康'),
  ('financial', '经济'),
  ('other', '其他'),
];

/// 应激源记录列表 (监听 stressEventEntriesProvider stream)
class StressEventListWidget extends ConsumerWidget {
  const StressEventListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(stressEventEntriesProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppTokens.spacingSm),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('添加应激源'),
              onPressed: () => StressEventEntryDialog.show(context),
            ),
          ),
        ),
        Expanded(
          child: entriesAsync.when(
            loading: () => const LoadingSkeleton.fullScreen(),
            error: (e, st) => Center(child: Text('加载失败: $e')),
            data: (entries) => entries.isEmpty
                ? const EmptyState(
                    icon: Icons.bolt_outlined,
                    title: '暂无应激源记录',
                    subtitle: '记录生活中的压力事件, 帮医生判断触发因素',
                  )
                : ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, i) =>
                        _StressEventEntryTile(entry: entries[i]),
                  ),
          ),
        ),
      ],
    );
  }
}

/// 单条 stress_event tile
class _StressEventEntryTile extends StatelessWidget {
  const _StressEventEntryTile({required this.entry});
  final StressEventEntity entry;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingSm,
        vertical: AppTokens.spacingXxs,
      ),
      child: ListTile(
        leading: Icon(Icons.bolt, color: AppTokens.warningColor(context)),
        title: Text('${_eventLabel(entry.eventType)} · 强度 ${entry.intensity}/5',
            style: AppTokens.textStyleLabelStrong(context),),
        subtitle: entry.note != null ? Text(entry.note!) : null,
      ),
    );
  }

  /// 事件类型 → 中文 label
  static String _eventLabel(String eventType) {
    for (final e in _kEventTypes) {
      if (e.$1 == eventType) return e.$2;
    }
    return eventType;
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
  String _eventType = _kEventTypes.first.$1; // 默认 'work'
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
      title: const Text('添加应激源'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // eventType dropdown
            DropdownButtonFormField<String>(
              initialValue: _eventType,
              decoration: const InputDecoration(
                labelText: '事件类型',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final e in _kEventTypes)
                  DropdownMenuItem(value: e.$1, child: Text(e.$2)),
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
                const Text('强度'),
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
          onPressed: (_saving || _intensity == null) ? null : _save,
          child: const Text('保存'),
        ),
      ],
    );
  }
}
