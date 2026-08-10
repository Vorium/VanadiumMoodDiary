// v0.15 (Round 18) 树洞详情页
//
// 单条 tree hole 完整内容：文字 + 音频播放器
// 路径参数：id（int）
//
// 删除按钮在右上角

import 'package:chroniccare/presentation/providers/vent_providers.dart';
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/domain/entities/vent_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/empty_state.dart';
import 'package:chroniccare/presentation/widgets/error_state.dart';
import 'package:chroniccare/presentation/widgets/feedback.dart';
import 'package:chroniccare/presentation/widgets/press_feedback_icon_button.dart';

class VentDetailPage extends ConsumerStatefulWidget {
  final int id;
  const VentDetailPage({super.key, required this.id});

  @override
  ConsumerState<VentDetailPage> createState() => _VentDetailPageState();
}

class _VentDetailPageState extends ConsumerState<VentDetailPage> {
  final _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<void>? _completeSub;

  @override
  void initState() {
    super.initState();
    _durationSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _positionSub = _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _completeSub = _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _completeSub?.cancel();
    _player.dispose();
    // P0-2: 清理临时解密文件(以防用户离开页面时还在播)
    // v0.30 R108 revisit (P0-018): 之前 `try { deleteTempFile(...) }` 是
    // fire-and-forget — return Future 但不 await, dispose() 立即返回,
    // 调用方 (Flutter framework) 已经 dispose widget 树, 后续 async 路径
    // 抛的 NoSuchMethodError / setState 错误**全吞**到 swallowError,用户
    // 树洞明文 PII 文件残留 (设备 root 可读 = PIPL §28 漏洞)。
    // 修: 用 unawaited(...) 显式标记, + .catchError 收口异常, 跟项目其他
    // fire-and-forget Future (audio recorder stop / mood audio cleanup)
    // 1:1 模式。
    if (_tempDecryptedPath != null) {
      final tempPath = _tempDecryptedPath!;
      _tempDecryptedPath = null;
      unawaited(
        ref
            .read(ventAudioStorageProvider)
            .deleteTempFile(tempPath)
            .catchError((Object e, StackTrace st) {
          // v0.22 round 30 (sp-en P1-3): 走 swallowError (app teardown 期间)
          swallowError(
            where: 'vent_detail_page.dispose',
            error: e,
            stack: st,
          );
        }),
      );
    }
    super.dispose();
  }

  /// P0-2: 当前播放用的临时解密文件，页面离开时清
  String? _tempDecryptedPath;

  Future<void> _togglePlay(VentEntryEntity entry) async {
    final path = entry.audioPath;
    if (path == null) return;
    if (_isPlaying) {
      await _player.pause();
      // 不删 temp(pause 后 resume 还要用)
      if (mounted) setState(() => _isPlaying = false);
    } else {
      try {
        // P0-2: path 是 .m4a.enc 加密文件 → 先 decryptToTemp → audioplayer 播
        final storage = ref.read(ventAudioStorageProvider);
        // 如果已有 temp (从 pause 恢复),直接复用
        _tempDecryptedPath ??= await storage.decryptToTemp(path);
        await _player.play(DeviceFileSource(_tempDecryptedPath!));
        if (context.mounted) setState(() => _isPlaying = true);
      } catch (e) {
        // v0.22 round 28 (spen-bug-02): 失败时清 temp file 避免堆积
        if (_tempDecryptedPath != null) {
          try {
            await ref
                .read(ventAudioStorageProvider)
                .deleteTempFile(_tempDecryptedPath!);
          } catch (e, st) {
            // v0.22 round 30 (sp-en P1-3): 走 swallowError
            swallowError(
              where: 'vent_detail_page._togglePlay.failCleanup',
              error: e,
              stack: st,
            );
          }
          _tempDecryptedPath = null;
        }
        if (!mounted) return;
        if (!context.mounted) return;
        final l10n = AppLocalizations.of(context);
        AppSnackBar.showError(
          context,
          action: l10n.snackbarActionPlay,
          error: e,
        );
      }
    }
  }

  /// R97-P1-4 (2026-08-07): UGC 举报/反馈入口。
  ///
  /// 背景：App Store Guideline 1.2.1 要求包含 UGC 的 App 必须提供
  /// 举报机制。虽然本 App 的树洞内容仅本地存储、不会跨用户可见，
  /// 但仍需提供"反馈/举报 App 本身内容"的入口以满足审核。
  ///
  /// 这里弹一个 dialog 说明本地存储机制，并提供跳转到「法律与隐私」
  /// 页面联系开发者的入口（该页面已存在，包含开发者邮箱等联系方式）。
  Future<void> _showReportDialog() async {
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.ventReportDialogTitle),
        content: Text(l10n.ventReportDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l10n.ventReportDialogClose),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.push('/settings/legal');
            },
            child: Text(l10n.ventReportDialogAction),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(VentEntryEntity entry) async {
    // v0.21 Round 22 (P1-14 修复): 删除前重触感警示
    final l10n = AppLocalizations.of(context);
    await Haptics.warning();
    if (!mounted) return;
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
    if ((ok ?? false) && mounted) {
      // 停播放
      try {
        await _player.stop();
      } catch (e, st) {
        // player.stop 失败不影响删除流程(可能已经停止),dev 模式可见
        swallowError(
          where: 'vent_detail_page._confirmDelete',
          error: e,
          stack: st,
          note: 'player.stop failed, continuing to delete entry',
        );
      }
      // 删
      await ref.read(ventRepositoryProvider).delete(entry.id);
      if (mounted) context.pop();
    }
  }

  String _formatTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final entryAsync = ref.watch(ventEntryByIdProvider(widget.id));
    return PageScaffold(
      title: AppLocalizations.of(context).ventDetailTitle,
      actions: [
        // R97-P1-4 (2026-08-07): UGC 举报/反馈按钮(App Store 1.2.1)
        // 永远可用，跟 entry 是否存在无关（举报的是 App 本身的内容机制）
        PressFeedbackIconButton(
          icon: Icons.flag_outlined,
          tooltip: AppLocalizations.of(context).ventReportTooltip,
          onPressed: _showReportDialog,
        ),
        entryAsync.maybeWhen(
          data: (entry) => PressFeedbackIconButton(
            icon: Icons.delete_outline,
            color: AppTokens.errorColor(context),
            tooltip: AppLocalizations.of(context).commonDelete,
            onPressed: entry == null ? null : () => _delete(entry),
          ),
          orElse: () => const SizedBox.shrink(),
        ),
      ],
      child: entryAsync.when(
        data: (entry) {
          if (entry == null) {
            // v0.25 round 56d (spen P0 #15 cleanup): 改用 EmptyState 统一风格
            // (跟 vent_list / assessment_history / medication_calendar 等 5+ 处一致)
            return EmptyState(
              icon: Icons.search_off,
              title: AppLocalizations.of(context).ventDetailNotFound,
            );
          }
          return SingleChildScrollView(
            padding: AppTokens.edgeInsetsMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // v0.17 round 2 (A4 emil 动效): 顶部接收列表页 Hero
                // — 头像从列表卡片"飞"过来。tag 必须跟 source 一致。
                Row(
                  children: [
                    Hero(
                      tag: 'vent-avatar-${entry.id}',
                      child: CircleAvatar(
                        backgroundColor: entry.hasAudio
                            ? AppTokens.primaryLightColor(context)
                            : AppTokens.dividerColor(context),
                        child: Icon(
                          entry.hasAudio
                              ? Icons.mic
                              : Icons.text_snippet_outlined,
                          color: entry.hasAudio
                              ? AppTokens.primaryColor(context)
                              : AppTokens.textSecondaryColor(context),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTokens.spacingSm),
                    Text(
                      _formatTime(entry.timestamp),
                      style: AppTokens.textStyleCaptionHint(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.spacingMd),
                if (entry.hasText)
                  Container(
                    width: double.infinity,
                    padding: AppTokens.edgeInsetsMd,
                    decoration: BoxDecoration(
                      color: AppTokens.surfaceColor(context),
                      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                    ),
                    child: Text(
                      entry.contentText!,
                      style: const TextStyle(
                        fontSize: AppTokens.fontSizeBody,
                        height: AppTokens.lineHeightRelaxed,
                      ),
                    ),
                  ),
                if (entry.hasAudio) ...[
                  const SizedBox(height: AppTokens.spacingMd),
                  Container(
                    padding: AppTokens.edgeInsetsMd,
                    decoration: BoxDecoration(
                      color: AppTokens.primaryLightColor(context),
                      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // v0.27 round 62 (P1-15 修复): 改用 PressFeedbackIconButton 集中器
                            PressFeedbackIconButton(
                              icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: AppTokens.primaryColor(context),
                              size: 32,
                              onPressed: () => _togglePlay(entry),
                              tooltip: _isPlaying
                                  ? AppLocalizations.of(context)
                                      .ventAudioPauseTooltip
                                  : AppLocalizations.of(context)
                                      .ventAudioPlayTooltip,
                            ),
                            const SizedBox(width: AppTokens.spacingXs),
                            // 之前是 Hero('vent-mic-...'),但 source 已统一到
                            // 顶部的 CircleAvatar。这里只保留普通 mic icon (无 Hero)
                            Icon(
                              Icons.mic,
                              color: AppTokens.primaryColor(context),
                              size: AppTokens.iconSizeInline,
                            ),
                            const SizedBox(width: AppTokens.spacingChipGap),
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
                              style: TextStyle(
                                fontSize: AppTokens.fontSizeBody,
                                color: AppTokens.primaryColor(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTokens.spacingXs),
                        Slider(
                          value: _position.inMilliseconds.toDouble(),
                          min: 0,
                          max: _duration.inMilliseconds > 0
                              ? _duration.inMilliseconds.toDouble()
                              : 1,
                          onChanged: _duration.inMilliseconds > 0
                              ? (v) {
                                  _player
                                      .seek(Duration(milliseconds: v.toInt()));
                                }
                              : null,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDur(_position),
                              style: TextStyle(
                                fontSize: AppTokens.fontSizeLabelSm,
                                color: AppTokens.textHintColor(context),
                              ),
                            ),
                            Text(
                              _formatDur(_duration),
                              style: TextStyle(
                                fontSize: AppTokens.fontSizeLabelSm,
                                color: AppTokens.textHintColor(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppTokens.spacingXl),
                Text(
                  AppLocalizations.of(context).ventDetailPrivacy,
                  style: AppTokens.textStyleCaptionHint(context),
                ),
              ],
            ),
          );
        },
        loading: () => const LoadingSkeleton.fullScreen(),
        // v0.22 round 29 (emil-44): 改用 ErrorState 集中器
        // v0.27 round 77 (R76-N8 修): commonLoadFailed 传 e.toString()
        error: (e, _) => ErrorState(
          title: AppLocalizations.of(context).commonLoadFailed(e.toString()),
          detail: e.toString(),
          onRetry: () => ref.invalidate(ventEntryByIdProvider(widget.id)),
        ),
      ),
    );
  }

  String _formatDur(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
