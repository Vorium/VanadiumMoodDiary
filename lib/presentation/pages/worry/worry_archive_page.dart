// v1.1.0 论文落地 (F1 烦恼闭环): WorryArchivePage (忆往昔)
//
// 已闭环的烦恼收藏页 — 每条显示放下时间 + 🎉 庆祝 (还原论文"烦恼闭环后
// 回顾成就"的正向激励), 点击进入时间线可"又烦恼了"重新打开。
//
// AppleListSection 风格, 空状态用爱心文案。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/shared/formatters.dart';
import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/worry_providers.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';

class WorryArchivePage extends ConsumerWidget {
  const WorryArchivePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final resolved = ref.watch(worryResolvedProvider).value ?? const [];
    return PageScaffold(
      title: l10n.worryArchiveTitle,
      child: resolved.isEmpty
          ? _empty(l10n, context)
          : ListView(
              padding: const EdgeInsets.only(
                left: AppTokens.pageMarginH,
                right: AppTokens.pageMarginH,
                top: AppTokens.spacingSm,
                bottom: AppTokens.spacingLg,
              ),
              children: [
                AppleListSection(
                  title: l10n.worryArchiveCount(resolved.length),
                  margin: EdgeInsets.zero,
                  children: [
                    for (final t in resolved)
                      Material(
                        type: MaterialType.transparency,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading:
                              const Text('🎉', style: TextStyle(fontSize: 24)),
                          title: Text(
                            t.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            Formatters.dateTime(t.resolvedAt ?? t.createdAt),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/worry/${t.id}'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _empty(AppLocalizations l10n, BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🕊️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: AppTokens.spacingSm),
            Text(
              l10n.worryArchiveEmpty,
              textAlign: TextAlign.center,
              style: AppTokens.textStyleBody(context).copyWith(
                color: AppTokens.textSecondaryColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
