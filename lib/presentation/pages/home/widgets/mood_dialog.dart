import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/mood_visual.dart';
import '../../../../l10n/strings.dart';
import '../../../../theme/app_tokens.dart';
import '../../../providers/core_providers.dart';

/// 情绪日记 dialog
///
/// - 选 1-5 分（必填）
/// - 选预设标签（多选）：焦虑/抑郁/平静/失眠/烦躁/能量低
/// - 自由备注（可选）
class MoodDialog {
  MoodDialog._();

  static Future<void> show(BuildContext context, WidgetRef ref) {
    final noteController = TextEditingController();
    int selectedScore = 3;
    final selectedTags = <String>{};
    const presetTags = ['焦虑', '抑郁', '平静', '失眠', '烦躁', '能量低'];
    bool saving = false;

    return showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('今天情绪如何？'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1-5 分选择
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (int s = 1; s <= 5; s++)
                      GestureDetector(
                        onTap: () => setLocal(() => selectedScore = s),
                        child: Column(
                          children: [
                            Text(
                              MoodVisual.emojiFor(s),
                              style: TextStyle(
                                fontSize: 32,
                                color:
                                    s == selectedScore ? null : Colors.black26,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              MoodVisual.labelFor(s),
                              style: TextStyle(
                                fontSize: 12,
                                color: s == selectedScore
                                    ? Theme.of(ctx).colorScheme.primary
                                    : Theme.of(ctx)
                                        .colorScheme
                                        .onSurfaceVariant,
                                fontWeight: s == selectedScore
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
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
              child: const Text(Strings.commonCancel),
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
                            );
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('保存失败：$e')),
                          );
                          setLocal(() => saving = false);
                        }
                      }
                    },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text(Strings.commonSave),
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
