// v1.1.0 论文落地 (F1 烦恼闭环): WorrySelectorField — 情绪记录页的烦恼绑定
//
// 记录心情时可选:
// - 关联到一个进行中的烦恼 (open thread)
// - 新建一个烦恼 (保存时按首条 note 前 20 字自动命名)
// - 不关联 (默认)
//
// 状态通过 [onChanged] 上抛给 MoodRecorderPage (保存时构造 draft)。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/worry_thread_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/worry_providers.dart';

/// 保存时需要的烦恼绑定信息
class WorrySelection {
  /// 已选中的进行中烦恼 id (null = 未选现有烦恼)
  final int? threadId;

  /// true = 保存时新建烦恼 (title 由 note 生成)
  final bool createNew;

  const WorrySelection({this.threadId, this.createNew = false});

  bool get isNone => !createNew && threadId == null;
}

class WorrySelectorField extends ConsumerStatefulWidget {
  final int? initialThreadId;
  final ValueChanged<WorrySelection> onChanged;

  const WorrySelectorField({
    super.key,
    this.initialThreadId,
    required this.onChanged,
  });

  @override
  ConsumerState<WorrySelectorField> createState() => _WorrySelectorFieldState();
}

class _WorrySelectorFieldState extends ConsumerState<WorrySelectorField> {
  WorrySelection _selection = const WorrySelection();

  @override
  void initState() {
    super.initState();
    if (widget.initialThreadId != null) {
      _selection = WorrySelection(threadId: widget.initialThreadId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final openAsync = ref.watch(worryOpenProvider);
    // R114 B1-7: 修前 `.value ?? const []` 吞 error — DB 读失败时选择器
    // 显示"不关联"误导用户。修后: error 显示错误提示, 不可点。
    if (openAsync.hasError) {
      return Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 20,
            color: AppTokens.errorColor(context),
          ),
          const SizedBox(width: AppTokens.spacingXs),
          Expanded(
            child: Text(
              l10n.commonLoadFailed(openAsync.error.toString()),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTokens.textStyleCaption(context).copyWith(
                color: AppTokens.textSecondaryColor(context),
              ),
            ),
          ),
        ],
      );
    }
    final open = openAsync.value ?? const [];
    // P3-CLEAN-12: initialThreadId 指向失效 thread (已闭环 / 不存在) 时,
    // label 显示"不关联"但 _selection.threadId 仍绑定 → 显示与保存不一致。
    // open 数据到位后检测, 降级为 none 并上抛 onChanged 让 draft 同步。
    // (hasValue 守卫: 加载中 open 为空时不能误清初始绑定)
    if (_selection.threadId != null &&
        !_selection.createNew &&
        openAsync.hasValue &&
        !open.any((t) => t.id == _selection.threadId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selection = const WorrySelection());
        widget.onChanged(_selection);
      });
    }
    final selected = open.where((t) => t.id == _selection.threadId).firstOrNull;

    final label = _selection.createNew
        ? l10n.worryNewOption
        : selected != null
            ? selected.title
            : l10n.worryNoWorry;

    return InkWell(
      onTap: () => _showPicker(l10n, open),
      borderRadius: BorderRadius.circular(AppTokens.radiusInput),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.spacingXxs),
        child: Row(
          children: [
            Icon(
              _selection.isNone ? Icons.wb_cloudy_outlined : Icons.link,
              size: 20,
              color: _selection.isNone
                  ? AppTokens.textSecondaryColor(context)
                  : AppTokens.primaryColor(context),
            ),
            const SizedBox(width: AppTokens.spacingXs),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTokens.textStyleBody(context).copyWith(
                  color: _selection.isNone
                      ? AppTokens.textSecondaryColor(context)
                      : null,
                ),
              ),
            ),
            const Icon(Icons.expand_more, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _showPicker(
    AppLocalizations l10n,
    List<WorryThreadEntity> open,
  ) async {
    final result = await showModalBottomSheet<_PickerResult>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTokens.spacingSm),
              child: Text(
                l10n.worryFieldLabel,
                style: AppTokens.textStyleTitle(context),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.link_off),
              title: Text(l10n.worryNoWorry),
              onTap: () => Navigator.pop(sheetCtx, const _PickerResult.none()),
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: Text(l10n.worryNewOption),
              subtitle: Text(l10n.worryFieldHint),
              onTap: () =>
                  Navigator.pop(sheetCtx, const _PickerResult.createNew()),
            ),
            const Divider(height: 1),
            if (open.isNotEmpty)
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final t in open)
                      ListTile(
                        leading: const Icon(Icons.wb_cloudy_outlined),
                        title: Text(t.title),
                        onTap: () =>
                            Navigator.pop(sheetCtx, _PickerResult.thread(t.id)),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _selection = result.toSelection();
    });
    widget.onChanged(_selection);
  }
}

/// bottom sheet 返回值 → [WorrySelection]
class _PickerResult {
  final int? threadId;
  final bool createNew;
  const _PickerResult.none()
      : threadId = null,
        createNew = false;
  const _PickerResult.createNew()
      : threadId = null,
        createNew = true;
  const _PickerResult.thread(int id)
      : threadId = id,
        createNew = false;

  WorrySelection toSelection() =>
      WorrySelection(threadId: threadId, createNew: createNew);
}
