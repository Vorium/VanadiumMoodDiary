// v1.1.0+159 R121 P1-2 (frame-thinking god class split): 从 vent_list_page.dart
// 抽出 _EntryList + _EntryListState (164L) → 独立 widget 文件。
//
// 跟 widgets/vent_entry_cell.dart (R121 P1-2 抽 _EntryCell) 配套, 完成
// vent_list_page 684L → 240L 主壳 + 232L vent_entry_cell + 164L vent_entry_list
// 续拆 2/3 (frame-thinking 拆 3 file 计划)。
//
// 公开 VentEntryList / VentEntryListState 命名, 跟项目 widget 集中器
// 模式一致 (VentEntryCell / VentHintHelper R121 P1-2 已公开化)。
import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/vent_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/vent_providers.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/feedback.dart';
import 'package:chroniccare/presentation/widgets/swipe_delete_background.dart';
import 'package:chroniccare/presentation/widgets/animations/animations.dart';
import 'package:chroniccare/presentation/widgets/lazy_apple_list_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/presentation/pages/vent/widgets/vent_entry_cell.dart';

/// 树洞条目列表 (LazyAppleListSection + Dismissible 左滑删除 + stagger fade-in)
class VentEntryList extends ConsumerStatefulWidget {
  final List<VentEntryEntity> entries;
  const VentEntryList({super.key, required this.entries});

  @override
  ConsumerState<VentEntryList> createState() => _VentEntryListState();
}

class _VentEntryListState extends ConsumerState<VentEntryList> {
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
                        where: 'vent_entry_list.onDismissed.undo',
                        error: e,
                        stack: st,
                        note: 'vent restore failed — 原内容已删, 无法恢复',
                      );
                    }
                  },
                );
              } catch (e, st) {
                swallowError(
                  where: 'vent_entry_list.onDismissed',
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
