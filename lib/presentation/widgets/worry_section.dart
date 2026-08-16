// v1.1.0 论文落地 (F1 烦恼闭环): WorrySection — 情绪列表页的烦恼入口
//
// 情绪列表页搜索栏下方的一个紧凑 section:
// - 进行中的烦恼 (open, chip 可点 → /worry/:id)
// - "忆往昔" 入口 → /worry/archive
// 有数据 (open 或 resolved 任一非空) 才显示, 避免打扰纯情绪用户。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/worry_providers.dart';

class WorrySection extends ConsumerWidget {
  const WorrySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final openAsync = ref.watch(worryOpenProvider);
    final resolvedAsync = ref.watch(worryResolvedProvider);
    // R114 B1-7: 修前 `.value ?? const []` 吞 error — DB 读失败时用户看到
    // "没有烦恼"且无重试入口。修后: error 显示紧凑错误行 + 重试。
    if (openAsync.hasError || resolvedAsync.hasError) {
      final error =
          openAsync.hasError ? openAsync.error! : resolvedAsync.error!;
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.pageMarginH,
          AppTokens.spacingXs,
          AppTokens.pageMarginH,
          0,
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              size: AppTokens.iconSizeInline,
              color: AppTokens.errorColor(context),
            ),
            const SizedBox(width: AppTokens.spacingXs),
            Expanded(
              child: Text(
                l10n.commonLoadFailed(error.toString()),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTokens.textStyleCaption(context).copyWith(
                  color: AppTokens.textSecondaryColor(context),
                ),
              ),
            ),
            const SizedBox(width: AppTokens.spacingXs),
            TextButton(
              onPressed: () {
                ref.invalidate(worryOpenProvider);
                ref.invalidate(worryResolvedProvider);
              },
              child: Text(l10n.commonRetry),
            ),
          ],
        ),
      );
    }
    if (openAsync.isLoading || resolvedAsync.isLoading) {
      // loading → 暂隐藏 (无 flicker, 数据到再显示)
      return const SizedBox.shrink();
    }
    final open = openAsync.value ?? const [];
    final resolved = resolvedAsync.value ?? const [];
    if (open.isEmpty && resolved.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.pageMarginH,
        AppTokens.spacingXs,
        AppTokens.pageMarginH,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.worrySectionTitle,
                style: AppTokens.textStyleCaptionStrong(context),
              ),
              if (open.isNotEmpty)
                Text(
                  l10n.worryOpenCount(open.length),
                  style: AppTokens.textStyleCaption(context).copyWith(
                    color: AppTokens.textSecondaryColor(context),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTokens.spacingXxs),
          Wrap(
            spacing: AppTokens.spacingXs,
            runSpacing: AppTokens.spacingXxs,
            children: [
              for (final t in open)
                ActionChip(
                  avatar: const Icon(Icons.wb_cloudy_outlined, size: 18),
                  label: Text(t.title),
                  tooltip: l10n.worryStatusOpen,
                  onPressed: () => context.push('/worry/${t.id}'),
                ),
              ActionChip(
                avatar: const Text('🎉', style: TextStyle(fontSize: 14)),
                label: Text(l10n.worrySectionArchiveAction),
                onPressed: () => context.push('/worry/archive'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
