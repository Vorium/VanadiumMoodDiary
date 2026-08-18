// v1.1.0 round 12n (R121 P1-2 god class split): 从 vent_list_page.dart 684L
// 抽出 _EntryCell (208L) + _VentHintHelper (24L) → 232L 独立 widget 文件。
//
// R120 综合审视 frame-thinking 独家 P1 推荐:
//   vent_list_page 是 emotion-first 主路径用户最频繁触碰的 god class
//   (684L, 主页 stagger 8→3 入口 + 用户每天 1-3 次进树洞), 拆 3 file 后
//   主壳 < 350L, 符合 flutter-spec 守门阈值。
//
// 抽 1 of 3: VentEntryCell (208L) + VentHintHelper (24L) 抽完
// 剩 _EntryList (~180L) 待 R121 续抽
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare/features/vent/domain/entities/vent_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/providers/vent_providers.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/feedback.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// v0.32 R112 (EM-02/AH-04, spec §5.6): _EntryCard → _EntryCell
///
/// 树洞列表单条 cell — 头像 (audio/text) + 摘要预览 (前 80 字) + 相对时间 + 录音时长 + chevron
/// + onTap (详情) + onLongPress (删除)
class VentEntryCell extends ConsumerWidget {
  final VentEntryEntity entry;
  const VentEntryCell({super.key, required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wave 7 (Task B, R113): "今天／昨天"相对时间基准改 watch(todayProvider)
    // (修前 _formatTime 内 DateTime.now(), 跨 midnight 标签 stale 到次日)。
    final now = ref.watch(todayProvider);
    final preview = entry.hasText
        ? (entry.contentText!.length > 80
            ? '${entry.contentText!.substring(0, 80)}…'
            : entry.contentText!)
        : AppLocalizations.of(context).ventVoiceLabel;

    // v0.24 round 48 (emil P1-8): 加 PressFeedback 跟其他 list 行体感一致
    // 之前 Card(child: ListTile) 无 scale 反馈,只有 InkWell ripple
    // 树洞列表 tens/day 频度(情绪低谷时频繁查看历史) 体感应跟 settings 列表一致
    //
    // v0.24 round 48 (emil P2-8) 决策: 保留 `PressFeedback + 行` 不用 AppListTile
    // 因为需要 onLongPress (长按删除) + Hero 过渡, AppListTile 无这 2 API。
    //
    // v0.32 R112 (spec §5.6): Card 去掉 + ListTile → Row (home _RowCell
    // 样板)。AppleListSection 容器是 DecoratedBox 非 Material, ListTile
    // debug 断言 "ink splashes may be invisible" → 平铺 cell。
    return PressFeedback(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push('/vent/detail/${entry.id}'),
        onLongPress: () => _confirmDelete(context, ref, entry),
        child: Row(
          children: [
            Hero(
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
            const SizedBox(width: AppTokens.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTokens.textStyleBody(context),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppTokens.spacingXxs),
                    child: Row(
                      children: [
                        Text(
                          _formatTime(context, entry.timestamp, now),
                          style: AppTokens.textStyleCaption(context).copyWith(
                            color: AppTokens.textHintColor(context),
                          ),
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
                              getSeconds: (s) => AppLocalizations.of(context)
                                  .ventDurationSeconds(s),
                              getMinutes: (m) => AppLocalizations.of(context)
                                  .ventDurationMinutes(m),
                              getMinutesSeconds: (m, s) =>
                                  AppLocalizations.of(context)
                                      .ventDurationMinutesSeconds(m, s),
                            ),
                            style: AppTokens.textStyleCaption(context).copyWith(
                              color: AppTokens.textHintColor(context),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTokens.spacingXs),
            Icon(
              Icons.chevron_right,
              color: AppTokens.textHintColor(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    VentEntryEntity entry,
  ) async {
    // v0.32 round 8 (R112-10): 长按删除跟 swipe 路径对齐 —
    // 1) Haptics.warning 警示 (修前长按无触感, swipe confirmDismiss 有)
    await Haptics.warning();
    if (!context.mounted) return;
    // R112-10: repo 在 async gap 前捕获 — ref 不跨 unmount 使用
    // (Riverpod 3 element unmount 后 ref.read 抛 StateError)
    final repo = ref.read(ventRepositoryProvider);
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
      // R114 BUG 7 (R113 BUG 7 只修 swipe 路径): 长按删除裸 await
      // 无 catch — delete 抛异常 = unhandled async error + 无用户反馈
      // + 条目留存。修: try/catch + swallowError + 错误 snackbar +
      // ok==false 时 invalidate 刷新 (与 onDismissed 路径对齐)。
      try {
        final deleted = await repo.delete(entry.id);
        if (!context.mounted) return;
        if (!deleted) {
          // 行已不存在 (并发删除) — 刷新列表对齐 UI
          ref.invalidate(ventEntriesProvider);
          return;
        }
        // 2) Undo snackbar (修前长按删完无撤销入口, swipe onDismissed 有)
        AppSnackBar.undo(
          context,
          message: AppLocalizations.of(context).ventEntryDeleted,
          onUndo: () async {
            try {
              await repo.restore(entry);
            } catch (e, st) {
              // undo 失败不该再弹 snackbar 链 — 走 swallow
              swallowError(
                where: 'vent_entry_cell._confirmDelete.undo',
                error: e,
                stack: st,
                note: 'vent restore failed — 原内容已删, 无法恢复',
              );
            }
          },
        );
      } catch (e, st) {
        swallowError(
          where: 'vent_entry_cell._confirmDelete',
          error: e,
          stack: st,
          note: 'vent 长按删除失败 — snackbar 已提示用户',
        );
        if (context.mounted) {
          AppSnackBar.showError(
            context,
            action: AppLocalizations.of(context).commonDelete,
            error: e,
          );
          // 条目仍留在 DB → 重新拉流对齐 UI
          ref.invalidate(ventEntriesProvider);
        }
      }
    }
  }

  String _formatTime(BuildContext context, DateTime dt, DateTime now) {
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
class VentHintHelper {
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
    if (prefs.getBool(_kSwipeHintShownKey) ?? false) return;
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    AppSnackBar.showInfo(context, l10n.ventSwipeHint);
    await prefs.setBool(_kSwipeHintShownKey, true);
  }
}
