// v0.15 (Round 18) 树洞详情页
//
// 单条 tree hole 完整内容：文字 + 音频播放器
// 路径参数：id（int）
//
// 删除按钮在右上角
library;

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
import 'package:chroniccare/presentation/widgets/error_state.dart';
import 'package:chroniccare/presentation/widgets/feedback.dart';

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
    if (_tempDecryptedPath != null) {
      try {
        ref.read(ventAudioStorageProvider).deleteTempFile(_tempDecryptedPath!);
      } catch (e, st) {
        // v0.22 round 30 (sp-en P1-3): 走 swallowError (app teardown 期间)
        swallowError(where: 'vent_detail_page.dispose', error: e, stack: st);
      }
      _tempDecryptedPath = null;
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
        AppSnackBar.showError(context,
              action: l10n.snackbarActionPlay,
              error: e);
      }
    }
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
            style: TextButton.styleFrom(foregroundColor: AppTokens.errorColor(context)),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
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
        entryAsync.maybeWhen(
          data: (entry) => IconButton(
            icon:Icon(Icons.delete_outline, color: AppTokens.errorColor(context)),
            tooltip: AppLocalizations.of(context).commonDelete,
            onPressed: entry == null ? null : () => _delete(entry),
          ),
          orElse: () => const SizedBox.shrink(),
        ),
      ],
      child: entryAsync.when(
        data: (entry) {
          if (entry == null) {
            return Center(
                child: Text(AppLocalizations.of(context).ventDetailNotFound),);
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTokens.spacingMd),
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
                      style: TextStyle(
                        fontSize: AppTokens.fontSizeCaption,
                        color: AppTokens.textHintColor(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.spacingMd),
                if (entry.hasText)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTokens.spacingMd),
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
                    padding: const EdgeInsets.all(AppTokens.spacingMd),
                    decoration: BoxDecoration(
                      color: AppTokens.primaryLightColor(context),
                      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                color: AppTokens.primaryColor(context),
                                size: 32,
                              ),
                              onPressed: () => _togglePlay(entry),
                            ),
                            const SizedBox(width: AppTokens.spacingXs),
                            // 之前是 Hero('vent-mic-...'),但 source 已统一到
                            // 顶部的 CircleAvatar。这里只保留普通 mic icon (无 Hero)
                            Icon(
                              Icons.mic,
                              color: AppTokens.primaryColor(context),
                              size: AppTokens.iconSizeInline,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              entry.durationLabel(),
                              style:TextStyle(
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
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeCaption,
                    color: AppTokens.textHintColor(context),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const LoadingSkeleton.fullScreen(),
        // v0.22 round 29 (emil-44): 改用 ErrorState 集中器
        error: (e, _) => ErrorState(
          title: AppLocalizations.of(context).commonLoadFailed(''),
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
