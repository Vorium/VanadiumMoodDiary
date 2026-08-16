// 1.1.0 round 5b (emotion-first refactor · Task 12): VentHeroCard 树洞卡
//
// 首页双主卡之一: 最新倾诉 1 行预览 + 写心事入口 (tap 整卡进 /vent)。
//
// 数据: ventEntriesProvider (StreamProvider.autoDispose, vent_providers.dart)
// 时间倒序, entries.first = 最新一条。
//
// R114 BUG 5 (PIPL §47): 加 ventSealedProvider gate — 修前预览直读
// ventEntriesProvider 不查封存状态, 用户撤回树洞同意选"加密封存"后
// 首页仍泄漏最新倾诉文字 (vent_list_page 有 gate, home 没有)。
// sealed=true → 不显示任何内容预览 + 隐藏"写心事"入口 (跟
// vent_list_page 封存态 FAB 隐藏同语义)。
//
// 隐私边界: 只展示最新 1 条 contentText 1 行截断预览, 不接任何分析 /
// 通知 / 关怀模块。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/shared/formatters.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/vent_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/legal_consent_provider.dart';
import 'package:chroniccare/presentation/providers/vent_providers.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';

/// 树洞卡 — 最新倾诉 1 行预览 + 写心事入口
class VentHeroCard extends ConsumerWidget {
  const VentHeroCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // R114 BUG 5 (PIPL §47): 封存状态优先 — sealed=true 不读条目预览
    // (vent_list_page.dart:61 同款 gate; maybeWhen orElse=false 是
    // fail-open 但 loading 期不渲染 preview 由 _preview(sealed) 保证)
    final sealed = ref.watch(ventSealedProvider).maybeWhen(
          data: (s) => s,
          orElse: () => false,
        );
    final entries = ref.watch(ventEntriesProvider).maybeWhen(
          data: (list) => list,
          orElse: () => const <VentEntryEntity>[],
        );
    final latest = sealed || entries.isEmpty ? null : entries.first;
    return AppleListSection(
      title: l10n.homeVentHeroTitle,
      margin: EdgeInsets.zero,
      children: [
        // v1.1.0 round 11 (R115+ polish): padding 12/14 → 18, 加大 hero 卡视觉权重
        // 跟 MoodHeroCard 一起从「次要卡」升格为「双主卡」(emotion-first)。
        InkWell(
          onTap: () => context.push('/vent'),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 28pt 圆角方块 icon, iOS systemPurple (#AF52DE)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFAF52DE),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(
                    sealed ? Icons.lock_outline : Icons.forum_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _preview(l10n, latest, sealed: sealed),
                      if (!sealed && latest != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          Formatters.time(latest.timestamp),
                          style: AppTokens.textStyleCaption(context).copyWith(
                            color: AppTokens.textHintColor(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!sealed) ...[
                  const SizedBox(width: 8),
                  PressFeedback(
                    child: FilledButton(
                      onPressed: () => context.push('/vent/compose'),
                      child: Text(l10n.homeVentHeroWrite),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 预览内容:
  /// - 封存 → 封存占位文案 (无任何内容泄漏, PIPL §47)
  /// - 无条目 → 空态文案
  /// - 有文字 → 文字截断预览
  /// - 仅语音 → ventVoiceLabel (与 vent_list_page 同款判定, P0-3 修复)
  Widget _preview(
    AppLocalizations l10n,
    VentEntryEntity? latest, {
    bool sealed = false,
  }) {
    if (sealed) return Text(l10n.ventSealedTitle);
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
