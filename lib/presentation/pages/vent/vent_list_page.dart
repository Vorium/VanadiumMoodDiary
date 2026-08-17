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

import 'package:chroniccare/presentation/providers/legal_consent_provider.dart';
import 'package:chroniccare/presentation/providers/vent_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/shared/json_codec.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare/core/theme/app_colors.dart';
import 'package:chroniccare/domain/entities/vent_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/l10n/preset_content_l10n.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/pages/vent/widgets/vent_entry_cell.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/feedback.dart';
import 'package:chroniccare/presentation/widgets/swipe_delete_background.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/widgets/press_feedback_icon_button.dart';
import 'package:chroniccare/presentation/widgets/animations/animations.dart';
import 'package:chroniccare/presentation/widgets/empty_state.dart';
import 'package:chroniccare/presentation/widgets/error_state.dart';
import 'package:chroniccare/presentation/widgets/lazy_apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';

/// v1.1.0 round 5c: ConsumerWidget → ConsumerStatefulWidget
/// (加 `_filterTag` 标签筛选 state, 客户端过滤)。
class VentListPage extends ConsumerStatefulWidget {
  const VentListPage({super.key});

  @override
  ConsumerState<VentListPage> createState() => _VentListPageState();
}

class _VentListPageState extends ConsumerState<VentListPage> {
  /// 1.1.0 round 5c: 当前筛选标签 (null = 全部)
  String? _filterTag;

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(ventEntriesProvider);
    // v0.28 R82.5: 检测 vent 加密封存状态 (法务 Q7b 必改, PIPL §47)
    // sealed=true → 不读 DB, 显示"已加密封存"占位 (数据物理上还在,
    // 用户撤回 vent 同意时选了"加密封存"而非"立即删除", 重新同意后
    // 数据会重新可见)
    final sealedAsync = ref.watch(ventSealedProvider);
    final l10n = AppLocalizations.of(context);
    return PageScaffold(
      title: l10n.ventListTitle,
      actions: [
        // v0.23 round 41 (emil P3-32): 改用 PressFeedbackIconButton 集中器
        // 之前 v0.23 round 40 inline `PressFeedback(child: IconButton(...))`,
        // emil "cohesion" — 抽集中器避免 2+ 处重复
        PressFeedbackIconButton(
          icon: Icons.add,
          tooltip: l10n.ventListWriteTooltip,
          onPressed: () => context.push('/vent/compose'),
        ),
      ],
      // v0.32 R112 (AH-15, spec §5.6): FAB 添加 (systemPurple, 参考
      // medication systemRed FAB 模式)。封存态 / 空列表不显示
      // (EmptyState 自带 "写第一句" action, 避免重复入口)。
      floatingActionButton: _buildVentFab(context, sealedAsync, entriesAsync),
      child: sealedAsync.maybeWhen(
        // v0.28 R82.5: 封存占位 — 优先级最高, 覆盖 loading / data / error
        // 不在 loading/error 走 LoadingSkeleton (持续动画会让 widget test
        // pumpAndSettle timeout), 直接 fallback 走 _buildContent
        // (entriesAsync 自己的 loading 已经有占位)
        data: (sealed) => sealed
            ? const _VentSealedState()
            : _buildContent(context, entriesAsync),
        loading: () => _buildContent(context, entriesAsync),
        error: (_, __) => _buildContent(context, entriesAsync),
        orElse: () => _buildContent(context, entriesAsync),
      ),
    );
  }

  /// v0.32 R112 (AH-15): systemPurple FAB (跟 medication systemRed FAB 同模式)
  ///
  /// 显示条件: 未封存 + 已有条目 (空态走 EmptyState action, 封存态无入口)。
  Widget? _buildVentFab(
    BuildContext context,
    AsyncValue<bool> sealedAsync,
    AsyncValue<List<VentEntryEntity>> entriesAsync,
  ) {
    final isSealed = sealedAsync.maybeWhen(data: (s) => s, orElse: () => false);
    final hasEntries =
        entriesAsync.maybeWhen(data: (e) => e.isNotEmpty, orElse: () => false);
    if (isSealed || !hasEntries) return null;
    return FloatingActionButton(
      backgroundColor: AppColors.healthMetricsColorFor('vent'), // systemPurple
      foregroundColor: AppColors.fgOnPrimary(context),
      onPressed: () => context.push('/vent/compose'),
      child: const Icon(Icons.add_rounded),
    );
  }

  /// 1.1.0 round 5c: 从 entries 收集去重标签 (按出现顺序)
  List<String> _distinctTags(List<VentEntryEntity> entries) {
    final tags = <String>{};
    for (final e in entries) {
      tags.addAll(JsonCodec.decodeStringList(e.tagsJson));
    }
    return tags.toList(growable: false);
  }

  Widget _buildContent(
    BuildContext context,
    AsyncValue<List<VentEntryEntity>> entriesAsync,
  ) {
    return entriesAsync.when(
      data: (entries) {
        if (entries.isEmpty) return const _VentEmptyState();
        // 1.1.0 round 5c: 标签筛选 chips + 客户端过滤
        final distinctTags = _distinctTags(entries);
        final filter = _filterTag;
        final filtered = filter == null
            ? entries
            : entries
                .where(
                  (e) =>
                      JsonCodec.decodeStringList(e.tagsJson).contains(filter),
                )
                .toList(growable: false);
        // v0.30 R95 sub-spec 8 task 48: 首次进入 vent list 显示 1 次 swipe/long-press
        // visual hint snackbar (emil P3 反复提 — 视觉提示用户有删除手势)
        // 用 SharedPreferences 持久化标记 _ventSwipeHintShown, 后续进入不再显示
        if (filtered.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            VentHintHelper.showSwipeHintIfFirstTime(context);
          });
        }
        // v0.21 Round 23 (P1-27): 下拉刷新
        return Column(
          children: [
            // 1.1.0 round 5c: 筛选行 — 有条目带标签时才显示;
            // 筛选激活后即使标签已消失也保留 (含"全部"兜底, 避免卡死空态)
            if (distinctTags.isNotEmpty || filter != null)
              _buildTagFilterBar(context, distinctTags),
            Expanded(
              child: filtered.isEmpty
                  ? EmptyState(
                      icon: Icons.filter_alt_off_outlined,
                      title: AppLocalizations.of(context).ventTagFilterEmpty,
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(ventEntriesProvider);
                        await Future<void>.delayed(
                          const Duration(
                            milliseconds: AppTokens.refreshMinVisibleMs,
                          ),
                        );
                      },
                      child: _EntryList(entries: filtered),
                    ),
            ),
          ],
        );
      },
      loading: () => const LoadingSkeleton.fullScreen(),
      // v0.22 round 29 (emil-44): 改用 ErrorState 集中器
      // v0.27 round 77 (R76-N8 修): commonLoadFailed 传 e.toString()
      error: (e, _) => ErrorState(
        title: AppLocalizations.of(context).commonLoadFailed(e.toString()),
        detail: e.toString(),
        onRetry: () => ref.invalidate(ventEntriesProvider),
      ),
    );
  }

  /// 1.1.0 round 5c: 顶部横向滚动的筛选 chips ('全部' + 去重标签)
  Widget _buildTagFilterBar(BuildContext context, List<String> tags) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingMd,
        vertical: AppTokens.spacingXs,
      ),
      child: Row(
        children: [
          FilterChip(
            label: Text(l10n.ventTagFilterAll),
            selected: _filterTag == null,
            onSelected: (_) => setState(() => _filterTag = null),
          ),
          for (final tag in tags) ...[
            const SizedBox(width: AppTokens.spacingXs),
            FilterChip(
              label: Text(localizedVentTag(context, tag)),
              selected: _filterTag == tag,
              onSelected: (_) => setState(() => _filterTag = tag),
            ),
          ],
        ],
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

/// v0.28 R82.5 (法务 Q7b 必改): vent 加密封存占位
///
/// 用户在 legal_page 撤回 vent 同意时, 选了"加密封存" (而非"立即删除") →
/// 数据物理上还在 DB, 但 UI 隐藏。重新同意后 (legal_page toggle 重新开启)
/// 数据会重新可见。
///
/// 设计: rare 频度(撤回 vent 同意是低频操作) + 严肃场景(emil "delight 不滥用")
/// → 用 EmptyState 集中器, 不加额外动画。锁图标 + "重新同意恢复数据"提示。
class _VentSealedState extends ConsumerWidget {
  const _VentSealedState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Icons.lock_outline,
      title: l10n.ventSealedTitle,
      subtitle: l10n.ventSealedSubtitle,
      actionLabel: l10n.ventSealedAction,
      onAction: () => context.push('/settings/legal'),
    );
  }
}

class _EntryList extends ConsumerStatefulWidget {
  final List<VentEntryEntity> entries;
  const _EntryList({required this.entries});

  @override
  ConsumerState<_EntryList> createState() => _EntryListState();
}

class _EntryListState extends ConsumerState<_EntryList> {
  // v1.1.0 R113 (BUG 7b): 删除失败时给该条目的 Dismissible 换 key —
  // 已 dismiss 的 Dismissible 必须卸载 (换 key = unmount + remount),
  // 否则条目从 UI 消失且 rebuild 必抛 FlutterError。invalidate 走
  // isRefreshing (skipLoadingOnRefresh 默认 true) 永远不会让 loading
  // 分支卸载旧 Dismissible。
  final Map<int, int> _deleteFailCounts = {};

  @override
  Widget build(BuildContext context) {
    // v0.21 Round 23 (P1-26): swipe-to-dismiss 左滑删除
    // emil 决策: tens/day(情绪低谷时多条查看历史) → 微弱 + 实操价值高
    // (不必进详情 → 点删除 → 确认 → 退出)。P1-14 已接 Haptics.warning。
    //
    // v0.32 R112 (EM-02/AH-04, spec §5.6): Card + ListView.separated →
    // AppleListSection (iOS 群组列表)。
    // R114 B1-1: 懒加载恢复 — 修前 `ListView(children: [AppleListSection
    // (children: [for ...])])` 全量构建 (年积累 1000+ 条每条叠 FadeIn +
    // Dismissible)。改 LazyAppleListSection (sliver 化, 只建 viewport 内
    // cell), AppleListSection 外观保留; stagger delay cap 400ms 只作用于
    // 已构建的前 N 条 (首屏), 后续滚动进来的条目 delay 按 i 计算同样被 cap。
    return LazyAppleListSection(
      physics: const AlwaysScrollableScrollPhysics(),
      scrollPadding: const EdgeInsets.only(
        top: AppTokens.spacingXs,
        bottom: AppTokens.spacingLg,
      ),
      itemCount: widget.entries.length,
      itemBuilder: (context, i) {
        // v0.17 round 14 (P2-6): staggered fade-in for vent entries
        // 用户录完一条回到列表时，新条目 + 历史条目一起 fade in,
        // 视觉上"列表刚加载"的感觉更明显。
        // delay cap 400ms: 超过 10 条的列表只 stagger 前 10 条,
        // 避免后加载的长条等太久。
        return FadeIn(
          // R114 Wave B2 (B2-8, emil F2): 显式 durFast 200ms — 修前
          // 默认 durSlow 400ms 落在 tens/day 列表路径, 每次进树洞"慢半拍"
          duration: AppTokens.durFast,
          delay: Duration(
            milliseconds:
                (i * AppTokens.staggerStepMs).clamp(0, AppTokens.staggerCapMs),
          ),
          child: Dismissible(
            // v1.1.0 R113 (BUG 7b): key 带失败计数 — 删除失败时
            // 计数 +1 → 已 dismiss 的旧 Dismissible unmount, 新 key
            // remount 回"未滑走"状态, 条目立即回到列表 (DB 里还在)。
            key: ValueKey(
              'vent-entry-${widget.entries[i].id}-'
              '${_deleteFailCounts[widget.entries[i].id] ?? 0}',
            ),
            direction: DismissDirection.endToStart,
            background: const SwipeDeleteBackground(),
            confirmDismiss: (_) async {
              // 触感警示 + 二次确认: 情绪低谷误删不可逆
              await Haptics.warning();
              if (!context.mounted) return false;
              final l10n = AppLocalizations.of(context);
              final ok = await showDialog<bool>(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  title: Text(l10n.commonConfirmDelete),
                  content: Text(l10n.commonVentDeleteWarning),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx, false),
                      child: Text(l10n.commonCancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx, true),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTokens.errorColor(context),
                      ),
                      child: Text(l10n.commonDelete),
                    ),
                  ],
                ),
              );
              return ok ?? false;
            },
            onDismissed: (_) async {
              // 二次确认已通过 → 真正删 + Undo snackbar
              // v1.1.0 R113 (BUG 7): 修前 fire-and-forget 裸 await —
              // delete 抛异常 = unhandled async error, 且条目从 UI
              // 消失但 DB 还在 (静默"幽灵"直到下次进列表)。修:
              // try/catch + swallowError + 失败时错误 snackbar +
              // invalidate 列表让条目回来。repo 在 async gap 前
              // 捕获 (R112-10 模式, ref 不跨 unmount 使用)。
              final deleted = widget.entries[i];
              final repo = ref.read(ventRepositoryProvider);
              try {
                final ok = await repo.delete(deleted.id);
                if (!context.mounted) return;
                if (!ok) {
                  // 行已不存在 (并发删除) — 刷新列表对齐 UI
                  // BUG 7b: 同样换 key, 让已 dismiss 的 Dismissible
                  // 卸载, 条目随 refresh 回来
                  if (mounted) {
                    setState(() {
                      _deleteFailCounts[deleted.id] =
                          (_deleteFailCounts[deleted.id] ?? 0) + 1;
                    });
                  }
                  ref.invalidate(ventEntriesProvider);
                  return;
                }
                final l10n = AppLocalizations.of(context);
                AppSnackBar.undo(
                  context,
                  message: l10n.ventEntryDeleted,
                  onUndo: () async {
                    try {
                      await repo.restore(deleted);
                    } catch (e, st) {
                      // undo 失败不该再弹 snackbar 链 — 走 swallow
                      swallowError(
                        where: 'vent_list_page.onDismissed.undo',
                        error: e,
                        stack: st,
                        note: 'vent restore failed — 原内容已删, 无法恢复',
                      );
                    }
                  },
                );
              } catch (e, st) {
                swallowError(
                  where: 'vent_list_page.onDismissed',
                  error: e,
                  stack: st,
                  note: 'vent delete failed — snackbar 已提示用户',
                );
                // BUG 7b: 先换 key 卸载已 dismiss 的 Dismissible,
                // 让条目回到列表 (setState 同步触发 rebuild)
                if (mounted) {
                  setState(() {
                    _deleteFailCounts[deleted.id] =
                        (_deleteFailCounts[deleted.id] ?? 0) + 1;
                  });
                }
                if (context.mounted) {
                  AppSnackBar.showError(
                    context,
                    action: AppLocalizations.of(context).commonDelete,
                    error: e,
                  );
                  // 条目仍留在 DB → 重新拉流让它回到列表
                  ref.invalidate(ventEntriesProvider);
                }
              }
            },
            child: VentEntryCell(entry: widget.entries[i]),
          ),
        );
      },
    );
  }
}
