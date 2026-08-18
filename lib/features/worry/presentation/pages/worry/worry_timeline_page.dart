// v1.1.0 论文落地 (F1 烦恼闭环): WorryTimelinePage
//
// 烦恼时间线 — 一个烦恼主题下的全部记录 + 3 个闭环动作:
// - 继续倾诉 (open): 打开记录心情页, 预绑定本烦恼
// - 不再烦恼啦 (open): 闭环 → 忆往昔 (确认 dialog)
// - 又烦恼了 (resolved): 重新打开
// - 重命名: title 可编辑 (首条 note 前 20 字自动生成, 可改)
//
// AppleListSection 风格 (v0.31), 跟 mood list / tips 页一致。
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/shared/formatters.dart';
import 'package:chroniccare/core/shared/mood_visual.dart';
import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/entities/worry_thread_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/worry_providers.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';
import 'package:chroniccare/presentation/widgets/press_feedback_icon_button.dart';

class WorryTimelinePage extends ConsumerStatefulWidget {
  final int threadId;
  const WorryTimelinePage({super.key, required this.threadId});

  @override
  ConsumerState<WorryTimelinePage> createState() => _WorryTimelinePageState();
}

class _WorryTimelinePageState extends ConsumerState<WorryTimelinePage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final open = ref.watch(worryOpenProvider).value ?? const [];
    final resolved = ref.watch(worryResolvedProvider).value ?? const [];
    final thread = [...open, ...resolved]
        .where((t) => t.id == widget.threadId)
        .firstOrNull;

    if (thread == null) {
      // R113 (BUG 1): 找不到烦恼 (已删除 / 非法 id) → 空态 + 返回引导,
      // 不再无限 CircularProgressIndicator (修前 /worry/archive 被
      // /worry/:id 遮蔽时 threadId=0 永远转圈)。
      return PageScaffold(
        title: l10n.worryTimelineTitle,
        child: EmptyWorryState(
          l10n: l10n,
          message: l10n.worryThreadNotFound,
          actionLabel: l10n.commonBack,
          onAction: () => context.pop(),
        ),
      );
    }

    final entries = ref.watch(worryEntriesProvider(widget.threadId));

    return PageScaffold(
      title: l10n.worryTimelineTitle,
      actions: [
        PressFeedbackIconButton(
          onPressed: () => _rename(l10n, thread),
          tooltip: l10n.worryRenameAction,
          icon: Icons.edit_outlined,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(l10n, thread),
          _actions(l10n, thread),
          Expanded(
            child: entries.when(
              data: (list) => _entries(l10n, list),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(AppLocalizations l10n, WorryThreadEntity thread) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.pageMarginH,
        AppTokens.spacingSm,
        AppTokens.pageMarginH,
        AppTokens.spacingXs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            thread.title,
            style: AppTokens.textStyleTitle(context),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppTokens.spacingXxs),
          Text(
            thread.isResolved ? l10n.worryStatusResolved : l10n.worryStatusOpen,
            style: AppTokens.textStyleCaption(context).copyWith(
              color: thread.isResolved
                  ? AppTokens.success
                  : AppTokens.textSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  /// 3 个闭环动作按钮 (论文 3 §5.3 R128e 优化):
///   1. 继续倾诉该烦恼 (主动作, FilledButton)
///   2. 我又烦恼了 (R128e 新增, "复发"语义, 区别于 resolved 状态的"又烦恼了")
///   3. 不再烦恼啦 (次动作, OutlinedButton, 走忆往昔)
  Widget _actions(AppLocalizations l10n, WorryThreadEntity thread) {
    if (thread.isResolved) {
      // 已闭环状态: 只显示"又烦恼了"重新打开
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.pageMarginH,
          vertical: AppTokens.spacingSm,
        ),
        child: Row(
          children: [
            Expanded(
              child: PressFeedback(
                child: FilledButton(
                  onPressed: () => _reopen(l10n),
                  child: Text(l10n.worryReopenAction),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 进行中状态: 3 个动作 (2 行布局)
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.pageMarginH,
        vertical: AppTokens.spacingSm,
      ),
      child: Column(
        children: [
          // Row 1: 主动作 (继续倾诉)
          Row(
            children: [
              Expanded(
                child: PressFeedback(
                  child: FilledButton(
                    onPressed: _continue,
                    child: Text(l10n.worryContinueAction),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spacingXs),
          // Row 2: 复发 + 闭环 (两个次动作)
          Row(
            children: [
              Expanded(
                child: PressFeedback(
                  child: TextButton(
                    onPressed: () => _relapse(l10n),
                    child: Text(l10n.worryRelapseAction),
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.spacingSm),
              Expanded(
                child: PressFeedback(
                  child: OutlinedButton(
                    onPressed: () => _resolve(l10n),
                    child: Text(l10n.worryResolveAction),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _entries(AppLocalizations l10n, List<MoodEntryEntity> entries) {
    if (entries.isEmpty) {
      return EmptyWorryState(l10n: l10n, message: l10n.worryTimelineEmpty);
    }
    return ListView(
      padding: const EdgeInsets.only(
        left: AppTokens.pageMarginH,
        right: AppTokens.pageMarginH,
        bottom: AppTokens.spacingLg,
      ),
      children: [
        AppleListSection(
          title: l10n.worryEntryCount(entries.length),
          margin: EdgeInsets.zero,
          children: [
            for (final e in entries)
              Material(
                type: MaterialType.transparency,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text(
                    MoodVisual.emojiFor(e.score),
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(
                    e.note ?? e.tags.join('、'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(Formatters.dateTime(e.timestamp)),
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _continue() {
    // R104 路由: /mood/create?worry=<id> — 记录心情并绑定本烦恼
    context.push('/mood/create?worry=${widget.threadId}');
  }

  /// R128e gdc audit 优化 (论文 3 §5.3 "我又烦恼了"):
  /// 跟 _continue 同样开 MoodRecorderPage 但走"复发"语义
  /// (用户承认这个烦恼的强度回升, 跟新烦恼区别).
  Future<void> _relapse(AppLocalizations l10n) async {
    // 复用现有 mood_entries.worryThreadId 关联机制
    // (用户保存新记录会自动延伸 timeline), 避免新增 schema 列
    unawaited(
      ref
          .read(worryThreadRepositoryProvider)
          .noteRelapse(widget.threadId, at: DateTime.now()),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.worryReopenDone)),
    );
    context.push('/mood/create?worry=${widget.threadId}');
  }

  Future<void> _resolve(AppLocalizations l10n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.worryResolveConfirmTitle),
        content: Text(l10n.worryResolveConfirmBody),
        actions: [
          // R114 Wave B2 (B2-9, emil F4): dialog 按钮补 PressFeedback
          PressFeedback(
            child: TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text(l10n.commonCancel),
            ),
          ),
          PressFeedback(
            child: TextButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: Text(l10n.worryResolveConfirmOk),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref
        .read(worryThreadRepositoryProvider)
        .resolve(widget.threadId, at: DateTime.now());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.worryResolveDone)),
    );
  }

  Future<void> _reopen(AppLocalizations l10n) async {
    await ref.read(worryThreadRepositoryProvider).reopen(widget.threadId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.worryReopenDone)),
    );
  }

  Future<void> _rename(AppLocalizations l10n, WorryThreadEntity thread) async {
    final controller = TextEditingController(text: thread.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.worryRenameTitle),
        content: TextField(
          controller: controller,
          maxLength: 30,
          autofocus: true,
          decoration: const InputDecoration(hintText: ''),
        ),
        actions: [
          PressFeedback(
            child: TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(l10n.commonCancel),
            ),
          ),
          PressFeedback(
            child: TextButton(
              onPressed: () {
                final t = controller.text.trim();
                Navigator.pop(dialogCtx, t.isEmpty ? null : t);
              },
              child: Text(l10n.worryRenameAction),
            ),
          ),
        ],
      ),
    );
    if (newTitle == null || !mounted) return;
    await ref
        .read(worryThreadRepositoryProvider)
        .rename(widget.threadId, newTitle);
  }
}

/// 空状态 (无记录 / 无已放下烦恼 / 烦恼不存在 共用)
class EmptyWorryState extends StatelessWidget {
  final AppLocalizations l10n;
  final String message;

  /// R113 (BUG 1): 可选返回引导按钮 (烦恼不存在时给用户出口)
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyWorryState({
    super.key,
    required this.l10n,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.self_improvement, size: 48),
            const SizedBox(height: AppTokens.spacingSm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTokens.textStyleBody(context).copyWith(
                color: AppTokens.textSecondaryColor(context),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppTokens.spacingMd),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
