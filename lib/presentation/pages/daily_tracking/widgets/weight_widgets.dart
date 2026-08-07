// v0.30 round 91 (sub-spec 7 日常追踪 / Task 4 UI): WeightListWidget + WeightEntryDialog
//
// 4 层架构: presentation/pages/daily_tracking/widgets/, 0 跨 feature import。
// 复用 R88 mood_dialog 风格。
//
// 体重记录 (R91 3 字段):
// - weightKg TextField (1 decimal, 30-200 kg range, required)
// - BMI 自动算 (读 userProfileProvider.heightCm, 找不到时 bmi = null)
//   R91 brief: "找不到时 bmi = null (跟 R55 user_profile 兼容)"
// - note 可选备注
//
// 跟 BmiCalculator 复用: calculator 接受 heightCm 参数 (应用层传),
// 0 依赖 profile (跟 R91 BMI calculator 1:1)。
//
// v0.30 R91 Task 7: i18n — 替换 hardcoded 中文 placeholder 走 l10n
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/weight_entry.dart';
import 'package:chroniccare/domain/logic/bmi_calculator.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/daily_tracking_providers.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/empty_state.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';

/// 体重记录列表 (监听 weightEntriesProvider stream)
///
/// v0.30 R91 Fix Round 1 (I-2): AppBar title 走 l10n.weightName,
/// 跟 R87 MoodListPage pattern 一致. 路由 file 不再包 PageScaffold wrapper.
class WeightListWidget extends ConsumerWidget {
  const WeightListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final entriesAsync = ref.watch(weightEntriesProvider);

    return PageScaffold(
      title: l10n.weightName,
      child: Column(
        children: [
          Padding(
            padding: AppTokens.edgeInsetsSm,
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                icon: const Icon(Icons.add),
                label: Text(l10n.weightAddButton),
                onPressed: () => WeightEntryDialog.show(context),
              ),
            ),
          ),
          Expanded(
            child: entriesAsync.when(
              loading: () => const LoadingSkeleton.fullScreen(),
              error: (e, st) => Center(child: Text(l10n.commonLoadFailed(e.toString()))),
              data: (entries) => entries.isEmpty
                  ? EmptyState(
                      icon: Icons.monitor_weight_outlined,
                      title: l10n.weightNoData,
                      subtitle: l10n.weightHint,
                    )
                  : ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, i) =>
                          _WeightEntryTile(entry: entries[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 单条 weight tile
class _WeightEntryTile extends StatelessWidget {
  const _WeightEntryTile({required this.entry});
  final WeightEntryEntity entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bmiLabel = entry.bmi != null
        ? ' · ${l10n.weightBmi(entry.bmi!.toStringAsFixed(1))}'
        : ' · ${l10n.weightNoBmi}';
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingSm,
        vertical: AppTokens.spacingXxs,
      ),
      child: ListTile(
        leading:
            Icon(Icons.monitor_weight, color: AppTokens.primaryColor(context)),
        title: Text(
          '${l10n.weightWeight(entry.weightKg.toStringAsFixed(1))}$bmiLabel',
          style: AppTokens.textStyleLabelStrong(context),
        ),
        subtitle: entry.note != null ? Text(entry.note!) : null,
      ),
    );
  }
}

/// WeightEntryDialog — 3 字段 (weightKg / bmi 自动 / note)
class WeightEntryDialog extends ConsumerStatefulWidget {
  const WeightEntryDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const WeightEntryDialog(),
    );
  }

  @override
  ConsumerState<WeightEntryDialog> createState() => _WeightEntryDialogState();
}

class _WeightEntryDialogState extends ConsumerState<WeightEntryDialog> {
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// 读 userProfileEntity 的 heightCm (R91 暂未存, 走 userProfileProvider).
  ///
  /// R91 brief: "profile.height 读取 — 读 userProfileProvider.heightCm, 找不到时 bmi = null"
  /// 当前 userProfileEntity 没有 heightCm 字段, 永远返 null (后续 v0.31+ setup 加身高).
  double? _getHeightCm() {
    final profileAsync = ref.read(userProfileProvider);
    final profile = profileAsync.value;
    // R91: UserProfileEntity 暂无 heightCm 字段, 后续 v0.31+ 加
    // 这里走 dynamic getter 容错 (字段不存在时返 null)
    if (profile == null) return null;
    try {
      // 尝试读 heightCm (字段可能不存在 → throw)
      return (profile as dynamic).heightCm as double?;
    } catch (e, st) {
      // v0.30 R92: 走 swallowError 集中器, 替代完全静默 (R39 P1-10 模式)
      // 老 UserProfile (R27 前) 没有 heightCm 字段, 视为 null (兜底)
      swallowError(
        where: 'weight_widgets._readHeightCm',
        error: e,
        stack: st,
        note: 'UserProfile.heightCm 字段读取失败, 走 null 兜底',
      );
      return null;
    }
  }

  /// 计算 BMI (实时跟 dialog 同步)
  double? get _bmi {
    final weightStr = _weightController.text.trim();
    if (weightStr.isEmpty) return null;
    final weight = double.tryParse(weightStr);
    if (weight == null) return null;
    return BmiCalculator.compute(weightKg: weight, heightCm: _getHeightCm());
  }

  Future<void> _save() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context);
    final weightStr = _weightController.text.trim();
    if (weightStr.isEmpty) return;
    final weight = double.tryParse(weightStr);
    if (weight == null) return;
    if (weight < 30 || weight > 200) return; // 边界保护
    setState(() => _saving = true);
    try {
      await ref.read(weightRepositoryProvider).add(
            timestamp: DateTime.now(),
            weightKg: weight,
            bmi: BmiCalculator.compute(
              weightKg: weight,
              heightCm: _getHeightCm(),
            ),
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.editMedSaveFailed(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.weightAddButton),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _weightController,
              decoration: InputDecoration(
                // R100 (P1#9): 走 ARB, 替代 hardcoded 中文
                labelText: l10n.weightKgLabel,
                border: const OutlineInputBorder(),
                hintText: l10n.weightKgHint,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}), // BMI 实时更新
            ),
            const SizedBox(height: AppTokens.spacingSm),
            // BMI 实时显示 (read-only)
            Row(
              children: [
                Icon(Icons.calculate, color: AppTokens.textHintColor(context)),
                const SizedBox(width: AppTokens.spacingXs),
                Text(
                  'BMI: ${_bmi?.toStringAsFixed(1) ?? l10n.weightBmiNeedHeight}',
                  style: AppTokens.textStyleLabelMedium(context),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spacingSm),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                // v0.30 R95 sub-spec 7 task 55: 走 ARB 集中器, 替代 hardcoded 中文
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
          onPressed: _saving ? null : _save,
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}
