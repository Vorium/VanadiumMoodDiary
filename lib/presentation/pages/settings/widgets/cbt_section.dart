// v0.29 round 84 (CBT 思维记录): 设置页"思维记录档位" radio section
//
// 3 选 1 RadioListTile<ThoughtRecordLevel>:
//   - 3 栏: 入门版, 1-2 分钟可填完
//   - 5 栏: 标准 Beck 思维记录, 含认知重构关键步骤
//   - 7 栏: 深度版, 含核心信念识别和行为应对
//
// 跟 settings/widgets/ 6 个 section widget 同模式 (Card + Consumer 状态绑定),
// 独立 widget 独立测 (见 test/presentation/pages/settings/widgets/cbt_section_round84_test.dart)。
//
// v0.29 round 84 (Task 9 留 TODO): 当前标题 / 副标题 / 3 栏描述用硬编码中文字符串,
// 后续 Task 9 加 ARB key `settingsCbtLevel*` 后改 AppLocalizations。
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/thought_record_level.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';

/// v0.29 round 84 (settings): 思维记录档位 radio 入口
///
/// 独立 widget 供 settings_page 直接引用, 跟 RemindersSection / AssessmentSection
/// 等同模式。`Consumer` 内 watch `thoughtRecordLevelProvider` 取当前档位,
/// `setLevel` 立即写 SharedPreferences。
class CbtSection extends ConsumerWidget {
  const CbtSection({super.key});

  // ===== v0.29 round 84 (Task 9 TODO) 硬编码中文字符串 =====
  // 当前 key 还没加 ARB, 暂用 inline 字符串避免编译失败。Task 9 统一加:
  //   - settingsCbtLevelTitle      → "思维记录档位"
  //   - settingsCbtLevelSubtitle   → "选择每次记录情绪时使用的思维记录模板"
  //   - settingsCbtLevelThreeDesc  → "入门版, 1-2 分钟可填完"
  //   - settingsCbtLevelFiveDesc   → "标准 Beck 思维记录, 含认知重构关键步骤"
  //   - settingsCbtLevelSevenDesc  → "深度版, 含核心信念识别和行为应对"
  static const _title = '思维记录档位';
  static const _subtitle = '选择每次记录情绪时使用的思维记录模板';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(thoughtRecordLevelProvider);
    final notifier = ref.read(thoughtRecordLevelProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacingMd,
          vertical: AppTokens.spacingSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: AppTokens.spacingXxs,
                bottom: AppTokens.spacingXxs,
              ),
              child: Text(
                _title,
                style: AppTokens.textStyleTitle(context),
              ),
            ),
            Text(
              _subtitle,
              style: AppTokens.textStyleCaption(context),
            ),
            const SizedBox(height: AppTokens.spacingXxs),
            for (final lv in ThoughtRecordLevel.values)
              RadioListTile<ThoughtRecordLevel>(
                title: Text('${lv.columnCount} 栏'),
                subtitle: Text(_descriptionFor(lv)),
                value: lv,
                // 关键: groupValue 决定哪个 radio 显示 selected
                groupValue: level,
                onChanged: (newVal) {
                  if (newVal != null) {
                    // fire-and-forget: SP 写入异步, 不阻塞 UI
                    unawaited(notifier.setLevel(newVal));
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  static String _descriptionFor(ThoughtRecordLevel lv) {
    switch (lv) {
      case ThoughtRecordLevel.three:
        return '入门版, 1-2 分钟可填完';
      case ThoughtRecordLevel.five:
        return '标准 Beck 思维记录, 含认知重构关键步骤';
      case ThoughtRecordLevel.seven:
        return '深度版, 含核心信念识别和行为应对';
    }
  }
}
