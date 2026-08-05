// v0.30 round 91 (sub-spec 7 日常追踪 / Task 4 UI): SleepListWidget + SleepEntryDialog
//
// 4 层架构: presentation/pages/daily_tracking/widgets/, 0 跨 feature import。
// 复用 R88 mood_dialog 风格 (AlertDialog + ListTile + ChoiceChip + TextField + 保存/取消)。
//
// 睡眠记录 (R91 4 字段, 跨午夜):
// - bedtime TimeOfDay picker (默认 23:00)
// - wakeTime TimeOfDay picker (默认 07:00)
// - durationMin 自动算 (跨午夜: 23:00 → 07:00 = 480min = 8h00min)
// - regularityScore 1-5 (5 档评分 ChoiceChip, nullable = 未评分)
// - note 可选备注 (TextField)
//
// 复用 R60 R90 calculator 模式:
// - SleepCalculator.durationMin(bedtime, wakeTime) 算跨午夜时长
// - 跟 daily_tracking_providers.sleepRepositoryProvider.add() 写库
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/sleep_entry.dart';
import 'package:chroniccare/domain/logic/sleep_calculator.dart';
import 'package:chroniccare/presentation/providers/daily_tracking_providers.dart';
import 'package:chroniccare/presentation/widgets/empty_state.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';

/// 睡眠记录列表 (监听 sleepEntriesProvider stream)
///
/// R88 mood_dialog 风格 + R60 list 模式:
/// - 空 → EmptyState (添加按钮, 跳 SleepEntryDialog)
/// - 非空 → ListView (Card + ListTile) + 顶部"添加"按钮
/// - 加 FAB "添加" 跟 R87 mood_list 一致
class SleepListWidget extends ConsumerWidget {
  const SleepListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(sleepEntriesProvider);

    return Column(
      children: [
        // 顶部添加按钮 (R88 mood_dialog 风格, 不走 FAB — list 页面通常 FAB 被 Card 占用)
        Padding(
          padding: const EdgeInsets.all(AppTokens.spacingSm),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('添加睡眠记录'),
              onPressed: () => SleepEntryDialog.show(context),
            ),
          ),
        ),
        // 列表主体
        Expanded(
          child: entriesAsync.when(
            loading: () => const LoadingSkeleton.fullScreen(),
            error: (e, st) => Center(child: Text('加载失败: $e')),
            data: (entries) => entries.isEmpty
                ? const EmptyState(
                    icon: Icons.bedtime_outlined,
                    title: '暂无睡眠记录',
                    subtitle: '点击右上角添加你的第一条睡眠记录',
                  )
                : ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, i) =>
                        _SleepEntryTile(entry: entries[i]),
                  ),
          ),
        ),
      ],
    );
  }
}

/// 单条 sleep entry tile
class _SleepEntryTile extends StatelessWidget {
  const _SleepEntryTile({required this.entry});
  final SleepEntryEntity entry;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingSm,
        vertical: AppTokens.spacingXxs,
      ),
      child: ListTile(
        leading: Icon(Icons.bedtime, color: AppTokens.primaryColor(context)),
        title: Text(entry.durationLabel,
            style: AppTokens.textStyleLabelStrong(context),),
        subtitle: Text(
          '入睡 ${_fmt(entry.bedtime)} · 起床 ${_fmt(entry.wakeTime)}'
          '${entry.hasRegularityScore ? ' · 规律 ${entry.regularityScore}/5' : ''}'
          '${entry.note != null ? ' · ${entry.note}' : ''}',
        ),
      ),
    );
  }

  static String _fmt(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

/// SleepEntryDialog — 4 字段 (bedtime / wakeTime / regularity / note)
///
/// R88 mood_dialog 风格: AlertDialog + ListTile (time picker) + ChoiceChip row
/// (regularity 5 档) + TextField (note) + 取消/保存。
///
/// 默认值: bedtime=23:00, wakeTime=07:00 (跨午夜 8h, 跟一般用户作息一致)。
/// 跨午夜由 SleepCalculator.durationMin() 处理 (R91 brief 明确)。
class SleepEntryDialog extends ConsumerStatefulWidget {
  const SleepEntryDialog({super.key});

  /// 静态入口 — Dialog 模态
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const SleepEntryDialog(),
    );
  }

  @override
  ConsumerState<SleepEntryDialog> createState() => _SleepEntryDialogState();
}

class _SleepEntryDialogState extends ConsumerState<SleepEntryDialog> {
  // 默认 23:00 入睡, 07:00 起床 (跨午夜 8h)
  TimeOfDay _bedtime = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  int? _regularityScore; // 1-5, null = 未评分
  final _noteController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  /// 自动算 durationMin (跨午夜支持)
  int get _durationMin {
    final now = DateTime.now();
    final bedtime =
        DateTime(now.year, now.month, now.day, _bedtime.hour, _bedtime.minute);
    // 跨午夜: wakeTime hour < bedtime hour → +1 day
    final wakeTime = _wakeTime.hour >= _bedtime.hour
        ? DateTime(
            now.year, now.month, now.day, _wakeTime.hour, _wakeTime.minute,)
        : DateTime(
            now.year, now.month, now.day + 1, _wakeTime.hour, _wakeTime.minute,);
    return SleepCalculator.durationMin(bedtime, wakeTime);
  }

  String get _durationLabel {
    final min = _durationMin;
    final h = min ~/ 60;
    final m = min % 60;
    return '${h}h${m.toString().padLeft(2, '0')}min';
  }

  Future<void> _pickBedtime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _bedtime,
    );
    if (picked != null) setState(() => _bedtime = picked);
  }

  Future<void> _pickWakeTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _wakeTime,
    );
    if (picked != null) setState(() => _wakeTime = picked);
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final bedtime = DateTime(
          now.year, now.month, now.day, _bedtime.hour, _bedtime.minute,);
      final wakeTime = _wakeTime.hour >= _bedtime.hour
          ? DateTime(
              now.year, now.month, now.day, _wakeTime.hour, _wakeTime.minute,)
          : DateTime(now.year, now.month, now.day + 1, _wakeTime.hour,
              _wakeTime.minute,);
      await ref.read(sleepRepositoryProvider).add(
            date: DateTime(now.year, now.month, now.day),
            bedtime: bedtime,
            wakeTime: wakeTime,
            durationMin: SleepCalculator.durationMin(bedtime, wakeTime),
            regularityScore: _regularityScore,
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
      title: const Text('添加睡眠记录'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 入睡时间
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.nights_stay_outlined),
              title: const Text('入睡时间'),
              trailing: Text(_fmtTime(_bedtime)),
              onTap: _pickBedtime,
            ),
            // 起床时间
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.wb_sunny_outlined),
              title: const Text('起床时间'),
              trailing: Text(_fmtTime(_wakeTime)),
              onTap: _pickWakeTime,
            ),
            // durationLabel (自动算, 不可编辑)
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: AppTokens.spacingSm),
              child: Row(
                children: [
                  Icon(Icons.timelapse,
                      color: AppTokens.textHintColor(context),),
                  const SizedBox(width: AppTokens.spacingXs),
                  Text('时长: $_durationLabel',
                      style: AppTokens.textStyleLabelMedium(context),),
                ],
              ),
            ),
            // regularity 5 档评分
            const SizedBox(height: AppTokens.spacingSm),
            Row(
              children: [
                Icon(Icons.repeat, color: AppTokens.textHintColor(context)),
                const SizedBox(width: AppTokens.spacingXs),
                const Text('规律性'),
              ],
            ),
            const SizedBox(height: AppTokens.spacingXxs),
            Wrap(
              spacing: AppTokens.spacingXs,
              children: [
                for (var i = 1; i <= 5; i++)
                  ChoiceChip(
                    label: Text('$i'),
                    selected: _regularityScore == i,
                    onSelected: (_) {
                      setState(() {
                        _regularityScore = _regularityScore == i ? null : i;
                      });
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
          onPressed: _saving ? null : _save,
          child: const Text('保存'),
        ),
      ],
    );
  }
}
