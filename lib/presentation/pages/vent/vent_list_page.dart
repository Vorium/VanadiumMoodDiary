// v0.15 (Round 18) 树洞列表页
//
// 全屏页面：用户的所有树洞条目，按时间倒序
// 顶部右上角有"+"按钮跳到撰写页
// 单条点开 → 详情（听 audio / 看文字 / 删除）
//
// 隐私边界：
// - 列表显示摘要（前 80 字 / 录音时长）
// - 详情页才显示完整内容
// - 长按 / 滑动可单条删除
library;

import 'package:chroniccare/presentation/providers/vent_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/domain/entities/vent_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/widgets/animations/animations.dart';
import 'package:chroniccare/presentation/widgets/empty_state.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';

class VentListPage extends ConsumerWidget {
  const VentListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(ventEntriesProvider);
    final l10n = AppLocalizations.of(context);
    return PageScaffold(
      title: l10n.ventListTitle,
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: l10n.ventListWriteTooltip,
          onPressed: () => context.push('/vent/compose'),
        ),
      ],
      child: entriesAsync.when(
        data: (entries) {
          if (entries.isEmpty) return const _VentEmptyState();
          return _EntryList(entries: entries);
        },
        loading: () => const LoadingSkeleton.fullScreen(),
        error: (e, _) => Center(
            child: Text(
                AppLocalizations.of(context).commonLoadFailed(e.toString()),),),
      ),
    );
  }
}

/// v0.21 Round 22 (P0-11 修复): 改用统一 EmptyState + FadeIn(withScale)
/// 保留 emil "rare 频度 + 弹一下" 的 delight 动画 (P1-1)
class _VentEmptyState extends StatelessWidget {
  const _VentEmptyState();
  @override
  Widget build(BuildContext context) {
    return FadeIn(
      withScale: true,
      child: EmptyState(
        icon: Icons.forest_outlined,
        title: AppLocalizations.of(context).ventEmptyTitle,
        subtitle: AppLocalizations.of(context).ventEmptySubtitle,
        actionLabel: AppLocalizations.of(context).ventEmptyAction,
        onAction: () => context.push('/vent/compose'),
      ),
    );
  }
}

class _EntryList extends ConsumerWidget {
  final List<VentEntryEntity> entries;
  const _EntryList({required this.entries});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppTokens.spacingSm),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTokens.spacingXs),
      // v0.17 round 14 (P2-6): staggered fade-in for vent entries
      // 用户录完一条回到列表时，新条目 + 历史条目一起 fade in,
      // 视觉上"列表刚加载"的感觉更明显。
      // delay cap 400ms: 超过 10 条的列表只 stagger 前 10 条,
      // 避免后加载的长条等太久。
      itemBuilder: (_, i) => FadeIn(
        delay: Duration(milliseconds: (i * 40).clamp(0, 400)),
        child: _EntryCard(entry: entries[i]),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final VentEntryEntity entry;
  const _EntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final preview = entry.hasText
        ? (entry.contentText!.length > 80
            ? '${entry.contentText!.substring(0, 80)}…'
            : entry.contentText!)
        : AppLocalizations.of(context).ventVoiceLabel;

    return Card(
      child: ListTile(
        leading: Hero(
          // v0.17 round 2 (A4 emil 动效): 列表 → 详情时头像
          // "飞"过去。emil 决策:occasional 频度(用户偶尔看历史回听) → 可加
          // Hero 过渡。tag 必须 unique per entry,无论有没有 audio 都包
          // (详情页同步有对应 Hero 接收)
          tag: 'vent-avatar-${entry.id}',
          child: CircleAvatar(
            backgroundColor: entry.hasAudio
                ? AppTokens.primaryLightColor(context)
                : AppTokens.dividerColor(context),
            child: Icon(
              entry.hasAudio ? Icons.mic : Icons.text_snippet_outlined,
              color: entry.hasAudio
                  ? AppTokens.primary
                  : AppTokens.textSecondaryColor(context),
              size: 20,
            ),
          ),
        ),
        title: Text(
          preview,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: AppTokens.fontSizeBody),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(
                _formatTime(context, entry.timestamp),
                style: TextStyle(
                  fontSize: AppTokens.fontSizeCaption,
                  color: AppTokens.textHintColor(context),
                ),
              ),
              if (entry.hasAudio) ...[
                const SizedBox(width: AppTokens.spacingSm),
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: AppTokens.textHintColor(context),
                ),
                const SizedBox(width: 2),
                Text(
                  entry.durationLabel(),
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeCaption,
                    color: AppTokens.textHintColor(context),
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing:
            Icon(Icons.chevron_right, color: AppTokens.textHintColor(context)),
        onTap: () => context.push('/vent/detail/${entry.id}'),
        onLongPress: () => _confirmDelete(context, entry),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    VentEntryEntity entry,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).commonConfirmDelete),
        content: Text(AppLocalizations.of(context).commonVentDeleteWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context).commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTokens.error),
            child: Text(AppLocalizations.of(context).commonDelete),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final repo =
          ProviderScope.containerOf(context).read(ventRepositoryProvider);
      await repo.delete(entry.id);
    }
  }

  String _formatTime(BuildContext context, DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dtDay = DateTime(dt.year, dt.month, dt.day);
    if (dtDay == today) {
      return '${AppLocalizations.of(context).ventToday} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (dtDay == today.subtract(const Duration(days: 1))) {
      return '${AppLocalizations.of(context).ventYesterday} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
