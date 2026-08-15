// 1.1.0 round 5b (emotion-first refactor · Task 12): VentHeroCard 树洞卡
//
// 首页双主卡之一: 最新倾诉 1 行预览 + 写心事入口 (tap 整卡进 /vent)。
//
// 数据: ventEntriesProvider (StreamProvider.autoDispose, vent_providers.dart)
// 时间倒序, entries.first = 最新一条。
//
// 隐私边界: 只展示最新 1 条 contentText 1 行截断预览, 不接任何分析 /
// 通知 / 关怀模块。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/domain/entities/vent_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/vent_providers.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';

/// 树洞卡 — 最新倾诉 1 行预览 + 写心事入口
class VentHeroCard extends ConsumerWidget {
  const VentHeroCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final entries = ref.watch(ventEntriesProvider).maybeWhen(
          data: (list) => list,
          orElse: () => const <VentEntryEntity>[],
        );
    final latest = entries.isEmpty ? null : entries.first;
    return AppleListSection(
      title: l10n.homeVentHeroTitle,
      margin: EdgeInsets.zero,
      children: [
        ListTile(
          leading: const Icon(Icons.forum_outlined),
          title: _preview(l10n, latest),
          trailing: FilledButton.tonal(
            onPressed: () => context.push('/vent/compose'),
            child: Text(l10n.homeVentHeroWrite),
          ),
          onTap: () => context.push('/vent'),
        ),
      ],
    );
  }

  /// 最新条目的 1 行预览:
  /// - 无条目 → 空态文案
  /// - 有文字 → 文字截断预览
  /// - 仅语音 → ventVoiceLabel (与 vent_list_page 同款判定, P0-3 修复)
  Widget _preview(AppLocalizations l10n, VentEntryEntity? latest) {
    if (latest == null) return Text(l10n.homeVentHeroNoData);
    if (latest.hasText) {
      return Text(
        latest.contentText!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    if (latest.hasAudio) return Text(l10n.ventVoiceLabel);
    return Text(l10n.homeVentHeroNoData);
  }
}
