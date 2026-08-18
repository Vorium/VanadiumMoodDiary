// v1.1.0 论文落地 (F1 烦恼闭环): WorryTimelinePage
//
// 烦恼时间线 — 一个烦恼主题下的全部记录 + 3 个闭环动作:
// - 继续倾诉 (open): 打开记录心情页, 预绑定本烦恼
// - 不再烦恼啦 (open): 闭环 → 忆往昔 (确认 dialog)
// - 又烦恼了 (resolved): 重新打开
// - 重命名: title 可编辑 (首条 note 前 20 字自动生成, 可改)
//
// AppleListSection 风格 (v0.31), 跟 mood list / tips 页一致。
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

  /// 3 个动作按钮 (2 行: 主动作 + 次动作)
  Widget _actions(AppLocalizations l10n, WorryThreadEntity thread) {
    final mainAction =
        thread.isResolved ? l10n.worryReopenAction : l10n.worryContinueAction;
    final secondaryAction = thread.isResolved ? null : l10n.worryResolveAction;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.pageMarginH,
        vertical: AppTokens.spacingSm,
      ),
      child: Row(
        children: [
          Expanded(
            // R114 Wave B2 (B2-9, emil F4): 包 PressFeedback (mode 2)
            child: PressFeedback(
              child: FilledButton(
                onPressed: thread.isResolved ? () => _reopen(l10n) : _continue,
                child: Text(mainAction),
              ),
            ),
          ),
          if (secondaryAction != null) ...[
            const SizedBox(width: AppTokens.spacingSm),
            Expanded(
              child: PressFeedback(
                child: OutlinedButton(
                  onPressed: () => _resolve(l10n),
                  child: Text(secondaryAction),
                ),
              ),
            ),
          ],
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
