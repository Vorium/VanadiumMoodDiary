// v0.29 round 84 (CBT 思维记录): 设置页"思维记录档位" radio section
//
// 3 选 1 RadioListTile<ThoughtRecordLevel>:
//   - 3 栏: 入门版, 1-2 分钟可填完
//   - 5 栏: 标准 Beck 思维记录, 含认知重构关键步骤
//   - 7 栏: 深度版, 含核心信念识别和行为应对
//
// 跟 settings/widgets/ 6 个 section widget 同模式 (Card + Consumer 状态绑定),
// 独立 widget 独立测 (见 test/presentation/pages/settings/widgets/cbt_section_round84_test.dart)。
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/thought_record_level.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';

/// v0.29 round 84 (settings): 思维记录档位 radio 入口
///
/// 独立 widget 供 settings_page 直接引用, 跟 RemindersSection / AssessmentSection
/// 等同模式。`Consumer` 内 watch `thoughtRecordLevelProvider` 取当前档位,
/// `setLevel` 立即写 SharedPreferences。
class CbtSection extends ConsumerWidget {
  const CbtSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
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
                l10n.settingsCbtLevel,
                style: AppTokens.textStyleTitle(context),
              ),
            ),
            Text(
              l10n.settingsCbtLevelDescription,
              style: AppTokens.textStyleCaption(context),
            ),
            const SizedBox(height: AppTokens.spacingXxs),
            // R97-P1-13 (2026-08-07): 迁移到 RadioGroup 新 API。
            //
            // Flutter 3.32+ 弃用 RadioListTile.groupValue / RadioListTile.onChanged
            // 单 tile 自管理状态模式, 改用 RadioGroup 祖先 widget 集中管理
            // groupValue + onChanged (满足 APG/ARIA 键盘导航 + 语义属性要求)。
            // 修前 deprecated_member_use info warning 2 处。
            //
            // 语义不变: 3 个 tile 互斥单选, 选中后 fire-and-forget 写 SP。
            RadioGroup<ThoughtRecordLevel>(
              groupValue: level,
              onChanged: (newVal) {
                if (newVal != null) {
                  // fire-and-forget: SP 写入异步, 不阻塞 UI
                  unawaited(notifier.setLevel(newVal));
                }
              },
              child: Column(
                children: [
                  for (final lv in ThoughtRecordLevel.values)
                    RadioListTile<ThoughtRecordLevel>(
                      title: Text('${lv.columnCount} 栏'),
                      subtitle: Text(_descriptionFor(lv, l10n)),
                      value: lv,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _descriptionFor(ThoughtRecordLevel lv, AppLocalizations l10n) {
    switch (lv) {
      case ThoughtRecordLevel.three:
        return l10n.settingsCbtLevel3Desc;
      case ThoughtRecordLevel.five:
        return l10n.settingsCbtLevel5Desc;
      case ThoughtRecordLevel.seven:
        return l10n.settingsCbtLevel7Desc;
    }
  }
}
