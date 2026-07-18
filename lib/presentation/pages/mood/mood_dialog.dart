import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';

/// 情绪日记 dialog
///
/// v0.18 round 18 (P1-15) 升级 4 维度：
/// - 情绪 (mood): 1-5 分 (主轴, 必填)
/// - 精力 (energy): 1-5 分 (1=很低 5=充沛)
/// - 睡眠 (sleep): 1-5 分 (1=很差 5=很好)
/// - 焦虑 (anxiety): 1-5 分 (反向:1=严重 5=平静)
/// + 预设标签 (多选) + 自由备注
class MoodDialog {
  MoodDialog._();

  static Future<void> show(BuildContext context, WidgetRef ref) {
    final noteController = TextEditingController();
    int selectedScore = 3;
    int selectedEnergy = 3;
    int selectedSleep = 3;
    int selectedAnxiety = 3;
    final selectedTags = <String>{};
    const presetTags = ['焦虑', '抑郁', '平静', '失眠', '烦躁', '能量低'];
    bool saving = false;

    return showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('今天怎么样？'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DimensionRow(
                  label: '情绪',
                  hint: '1=很差 5=很好',
                  value: selectedScore,
                  onChanged: (v) => setLocal(() => selectedScore = v),
                ),
                const SizedBox(height: AppTokens.spacingSm),
                _DimensionRow(
                  label: '精力',
                  hint: '1=很低 5=充沛',
                  value: selectedEnergy,
                  onChanged: (v) => setLocal(() => selectedEnergy = v),
                ),
                const SizedBox(height: AppTokens.spacingSm),
                _DimensionRow(
                  label: '睡眠',
                  hint: '1=很差 5=很好',
                  value: selectedSleep,
                  onChanged: (v) => setLocal(() => selectedSleep = v),
                ),
                const SizedBox(height: AppTokens.spacingSm),
                _DimensionRow(
                  label: '焦虑',
                  hint: '1=严重 5=平静',
                  value: selectedAnxiety,
                  onChanged: (v) => setLocal(() => selectedAnxiety = v),
                ),
                const SizedBox(height: AppTokens.spacingMd),
                const Divider(height: 1),
                const SizedBox(height: AppTokens.spacingSm),
                // 预设标签
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final tag in presetTags)
                      FilterChip(
                        label: Text(tag),
                        selected: selectedTags.contains(tag),
                        onSelected: (sel) {
                          setLocal(() {
                            if (sel) {
                              selectedTags.add(tag);
                            } else {
                              selectedTags.remove(tag);
                            }
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppTokens.spacingSm),
                // 自由备注
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: '备注（可选）',
                    hintText: '今天发生什么？',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context).commonCancel),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      setLocal(() => saving = true);
                      try {
                        await ref.read(moodRepositoryProvider).add(
                              score: selectedScore,
                              tags: selectedTags.toList(),
                              note: noteController.text.trim().isEmpty
                                  ? null
                                  : noteController.text.trim(),
                              energy: selectedEnergy,
                              sleep: selectedSleep,
                              anxiety: selectedAnxiety,
                            );
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            AppSnackBar.error(context, action: '保存', error: e),
                          );
                          setLocal(() => saving = false);
                        }
                      }
                    },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(AppLocalizations.of(context).commonSave),
                  if (saving)
                    const IgnorePointer(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      noteController.dispose();
    });
  }
}

/// 4 维度评分行: label + 1-5 评分按钮
class _DimensionRow extends StatelessWidget {
  final String label;
  final String hint;
  final int value;
  final ValueChanged<int> onChanged;

  const _DimensionRow({
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: AppTokens.fontSizeBody,
                fontWeight: FontWeight.w600,
                color: AppTokens.textPrimaryColor(context),
              ),
            ),
            Text(
              hint,
              style: TextStyle(
                fontSize: AppTokens.fontSizeCaption,
                color: AppTokens.textHintColor(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.spacingXs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (int s = 1; s <= 5; s++)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onChanged(s),
                  borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$s',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: s == value
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: s == value
                                ? Theme.of(context).colorScheme.primary
                                : AppTokens.textHintColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
