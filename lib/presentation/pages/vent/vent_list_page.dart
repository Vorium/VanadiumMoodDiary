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

import 'package:chroniccare/domain/entities/vent_entry.dart';
import 'package:chroniccare/core/l10n/strings.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/animations/animations.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';

class VentListPage extends ConsumerWidget {
  const VentListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(ventEntriesProvider);
    return PageScaffold(
      title: '我的树洞',
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: '写一条',
          onPressed: () => context.push('/vent/compose'),
        ),
      ],
      child: entriesAsync.when(
        data: (entries) {
          if (entries.isEmpty) return const _EmptyState();
          return _EntryList(entries: entries);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingXl),
        // v0.17 round 14 (P1-1): 抽 FadeIn widget,代替内联
        // TweenAnimationBuilder + Opacity + Transform.scale 三层嵌套。
        // rare 频度 (用户第一次进树洞 / 删完所有) → withScale: true 弹一下
        child: FadeIn(
          withScale: true,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.forest_outlined,
                size: 80,
                color: AppTokens.textHint,
              ),
              const SizedBox(height: AppTokens.spacingMd),
              const Text(
                '树洞还是空的',
                style: TextStyle(
                  fontSize: AppTokens.fontSizeTitle,
                  fontWeight: FontWeight.w600,
                  color: AppTokens.textPrimary,
                ),
              ),
              const SizedBox(height: AppTokens.spacingSm),
              const Text(
                '想说什么就说出来。文字、语音都可以。\n这些话只有你自己能看到。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTokens.fontSizeBody,
                  color: AppTokens.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppTokens.spacingLg),
              ElevatedButton.icon(
                onPressed: () => context.push('/vent/compose'),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('写第一句'),
              ),
            ],
          ),
        ),
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
      itemBuilder: (_, i) => _EntryCard(entry: entries[i]),
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
        : '🎙️ 语音';

    return Card(
      child: ListTile(
        leading: Hero(
          // v0.17 round 2 (A4 emil 动效): 列表 → 详情时头像
          // "飞"过去。emil 决策:occasional 频度(用户偶尔看历史回听) → 可加
          // Hero 过渡。tag 必须 unique per entry,无论有没有 audio 都包
          // (详情页同步有对应 Hero 接收)
          tag: 'vent-avatar-${entry.id}',
          child: CircleAvatar(
            backgroundColor:
                entry.hasAudio ? AppTokens.primaryLight : AppTokens.divider,
            child: Icon(
              entry.hasAudio ? Icons.mic : Icons.text_snippet_outlined,
              color: entry.hasAudio ? AppTokens.primary : AppTokens.textSecondary,
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
                _formatTime(entry.timestamp),
                style: const TextStyle(
                  fontSize: AppTokens.fontSizeCaption,
                  color: AppTokens.textHint,
                ),
              ),
              if (entry.hasAudio) ...[
                const SizedBox(width: AppTokens.spacingSm),
                const Icon(
                  Icons.access_time,
                  size: 12,
                  color: AppTokens.textHint,
                ),
                const SizedBox(width: 2),
                Text(
                  entry.durationLabel(),
                  style: const TextStyle(
                    fontSize: AppTokens.fontSizeCaption,
                    color: AppTokens.textHint,
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTokens.textHint),
        onTap: () => context.push('/vent/detail/${entry.id}'),
        onLongPress: () => _confirmDelete(context, entry),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, VentEntryEntity entry,) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除这条？'),
        content: const Text('删了就没了。文字和录音都会一起删。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(Strings.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTokens.error),
            child: const Text('删除'),
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

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dtDay = DateTime(dt.year, dt.month, dt.day);
    if (dtDay == today) {
      return '今天 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (dtDay == today.subtract(const Duration(days: 1))) {
      return '昨天 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
