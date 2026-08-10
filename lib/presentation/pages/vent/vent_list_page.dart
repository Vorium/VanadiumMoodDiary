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

import 'dart:async';

import 'package:chroniccare/presentation/providers/legal_consent_provider.dart';
import 'package:chroniccare/presentation/providers/vent_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chroniccare/domain/entities/vent_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/feedback.dart';
import 'package:chroniccare/presentation/widgets/swipe_delete_background.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/widgets/press_feedback_icon_button.dart';
import 'package:chroniccare/presentation/widgets/animations/animations.dart';
import 'package:chroniccare/presentation/widgets/empty_state.dart';
import 'package:chroniccare/presentation/widgets/error_state.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';

class VentListPage extends ConsumerWidget {
  const VentListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      child: sealedAsync.maybeWhen(
        // v0.28 R82.5: 封存占位 — 优先级最高, 覆盖 loading / data / error
        // 不在 loading/error 走 LoadingSkeleton (持续动画会让 widget test
        // pumpAndSettle timeout), 直接 fallback 走 _buildContent
        // (entriesAsync 自己的 loading 已经有占位)
        data: (sealed) => sealed
            ? const _VentSealedState()
            : _buildContent(context, ref, entriesAsync),
        loading: () => _buildContent(context, ref, entriesAsync),
        error: (_, __) => _buildContent(context, ref, entriesAsync),
        orElse: () => _buildContent(context, ref, entriesAsync),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<VentEntryEntity>> entriesAsync,
  ) {
    return entriesAsync.when(
      data: (entries) {
        if (entries.isEmpty) return const _VentEmptyState();
        // v0.30 R95 sub-spec 8 task 48: 首次进入 vent list 显示 1 次 swipe/long-press
        // visual hint snackbar (emil P3 反复提 — 视觉提示用户有删除手势)
        // 用 SharedPreferences 持久化标记 _ventSwipeHintShown, 后续进入不再显示
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _VentHintHelper.showSwipeHintIfFirstTime(context);
        });
        // v0.21 Round 23 (P1-27): 下拉刷新
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(ventEntriesProvider);
            await Future<void>.delayed(
              const Duration(milliseconds: AppTokens.refreshMinVisibleMs),
            );
          },
          child: _EntryList(entries: entries),
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

class _EntryList extends ConsumerWidget {
  final List<VentEntryEntity> entries;
  const _EntryList({required this.entries});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // v0.21 Round 23 (P1-26): swipe-to-dismiss 左滑删除
    // emil 决策: tens/day(情绪低谷时多条查看历史) → 微弱 + 实操价值高
    // (不必进详情 → 点删除 → 确认 → 退出)。P1-14 已接 Haptics.warning。
    return ListView.separated(
      padding: AppTokens.edgeInsetsSm,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTokens.spacingXs),
      // v0.17 round 14 (P2-6): staggered fade-in for vent entries
      // 用户录完一条回到列表时，新条目 + 历史条目一起 fade in,
      // 视觉上"列表刚加载"的感觉更明显。
      // delay cap 400ms: 超过 10 条的列表只 stagger 前 10 条,
      // 避免后加载的长条等太久。
      itemBuilder: (_, i) {
        final entry = entries[i];
        return FadeIn(
          delay: Duration(
            milliseconds:
                (i * AppTokens.staggerStepMs).clamp(0, AppTokens.staggerCapMs),
          ),
          child: Dismissible(
            key: ValueKey('vent-entry-${entry.id}'),
            direction: DismissDirection.endToStart,
            background: const SwipeDeleteBackground(rounded: true),
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
              final deleted = entry;
              await ref.read(ventRepositoryProvider).delete(deleted.id);
              if (!context.mounted) return;
              final l10n = AppLocalizations.of(context);
              AppSnackBar.undo(
                context,
                message: l10n.ventEntryDeleted,
                onUndo: () async {
                  // Undo: 重新插入(保留原 id + 时间)
                  await ref.read(ventRepositoryProvider).restore(deleted);
                },
              );
            },
            child: _EntryCard(entry: entry),
          ),
        );
      },
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

    // v0.24 round 48 (emil P1-8): 加 PressFeedback 跟其他 list 行体感一致
    // 之前 Card(child: ListTile) 无 scale 反馈,只有 InkWell ripple
    // 树洞列表 tens/day 频度(情绪低谷时频繁查看历史) 体感应跟 settings 列表一致
    //
    // v0.24 round 48 (emil P2-8) 决策: 保留 `PressFeedback + Card + ListTile` 不用 AppListTile.carded
    // 因为 _EntryCard 需要 onLongPress (长按删除) + Hero 过渡
    // AppListTile 当前不支持这 2 个参数, 强行用要扩 API → 价值低
    // emil 决策: 1 处用 + 缺 2 个关键 API = 不抽, 注释说明 deliberate
    return PressFeedback(
      child: Card(
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
                    ? AppTokens.primaryColor(context)
                    : AppTokens.textSecondaryColor(context),
                size: AppTokens.iconSize,
              ),
            ),
          ),
          title: Text(
            preview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTokens.textStyleBody(context),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: AppTokens.spacingXxs),
            child: Row(
              children: [
                Text(
                  _formatTime(context, entry.timestamp),
                  style: AppTokens.textStyleCaption(context)
                      .copyWith(color: AppTokens.textHintColor(context)),
                ),
                if (entry.hasAudio) ...[
                  const SizedBox(width: AppTokens.spacingSm),
                  Icon(
                    Icons.access_time,
                    size: AppTokens.iconSizeMicro,
                    color: AppTokens.textHintColor(context),
                  ),
                  const SizedBox(width: AppTokens.spacingXxs),
                  Text(
                    // v0.28 round 65 (spzh P2-I): durationLabel 走 i18n
                    entry.durationLabelL10n(
                      getSeconds: (s) =>
                          AppLocalizations.of(context).ventDurationSeconds(s),
                      getMinutes: (m) =>
                          AppLocalizations.of(context).ventDurationMinutes(m),
                      getMinutesSeconds: (m, s) => AppLocalizations.of(context)
                          .ventDurationMinutesSeconds(m, s),
                    ),
                    style: AppTokens.textStyleCaption(context)
                        .copyWith(color: AppTokens.textHintColor(context)),
                  ),
                ],
              ],
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: AppTokens.textHintColor(context),
          ),
          onTap: () => context.push('/vent/detail/${entry.id}'),
          onLongPress: () => _confirmDelete(context, entry),
        ),
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
            style: TextButton.styleFrom(
              foregroundColor: AppTokens.errorColor(context),
            ),
            child: Text(AppLocalizations.of(context).commonDelete),
          ),
        ],
      ),
    );
    if ((ok ?? false) && context.mounted) {
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

/// v0.30 R95 (sub-spec 8 task 48): vent list 首次 swipe/long-press visual hint
///
/// emil P3 反复提: vent 长按/swipe 删除缺 visual hint (用户首次用 vent 不知
/// 道有删除手势)。修: 首次进入 vent list 显示 1 次 snackbar 提示, SharedPreferences
/// 持久化标记避免每次进入都打扰。
///
/// 模式 (跟 project_notification_status_card 风格一致):
/// - async fire-and-forget (snackbar 不阻塞 list render)
/// - SP 持久化 key 跟其它"已看过"标记 (R42 添加, R56c 续)
/// - snackbar 用 AppSnackBar.showInfo 集中器
class _VentHintHelper {
  static const _kSwipeHintShownKey = 'vent_swipe_hint_shown_v1';

  /// 首次进入 vent list 显示 swipe/long-press 提示
  ///
  /// 流程:
  /// 1. 读 SP _kSwipeHintShownKey
  /// 2. true → 已显示过, 跳过
  /// 3. false → 弹 snackbar 提示 + 写 SP
  ///
  /// mounted guard: 弹 snackbar 前检查 BuildContext (避免 postFrameCallback
  /// 跨页面 lifecycle 撞 defunct context, R17 round 14 防御模式)
  static Future<void> showSwipeHintIfFirstTime(BuildContext context) async {
    if (context.mounted == false) return;
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool(_kSwipeHintShownKey) ?? false;
    if (shown) return;
    if (context.mounted == false) return;
    final l10n = AppLocalizations.of(context);
    AppSnackBar.showInfo(context, l10n.ventSwipeHint);
    // fire-and-forget 写 SP
    unawaited(prefs.setBool(_kSwipeHintShownKey, true));
  }
}
