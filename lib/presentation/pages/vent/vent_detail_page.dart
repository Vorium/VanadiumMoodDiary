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

import 'package:chroniccare/domain/entities/vent_entry.dart';
import 'package:chroniccare/core/l10n/strings.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';

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
    super.dispose();
  }

  Future<void> _togglePlay(VentEntryEntity entry) async {
    final path = entry.audioPath;
    if (path == null) return;
    if (_isPlaying) {
      await _player.pause();
      if (mounted) setState(() => _isPlaying = false);
    } else {
      try {
        await _player.play(DeviceFileSource(path));
        if (mounted) setState(() => _isPlaying = true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('播放失败：$e')),
          );
        }
      }
    }
  }

  Future<void> _delete(VentEntryEntity entry) async {
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
      title: '树洞',
      actions: [
        entryAsync.maybeWhen(
          data: (entry) => IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTokens.error),
            tooltip: '删除',
            onPressed: entry == null ? null : () => _delete(entry),
          ),
          orElse: () => const SizedBox.shrink(),
        ),
      ],
      child: entryAsync.when(
        data: (entry) {
          if (entry == null) {
            return const Center(child: Text('找不到了'));
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
                            ? AppTokens.primaryLight
                            : AppTokens.divider,
                        child: Icon(
                          entry.hasAudio
                              ? Icons.mic
                              : Icons.text_snippet_outlined,
                          color: entry.hasAudio
                              ? AppTokens.primary
                              : AppTokens.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTokens.spacingSm),
                    Text(
                      _formatTime(entry.timestamp),
                      style: const TextStyle(
                        fontSize: AppTokens.fontSizeCaption,
                        color: AppTokens.textHint,
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
                      color: AppTokens.background,
                      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                    ),
                    child: Text(
                      entry.contentText!,
                      style: const TextStyle(
                        fontSize: AppTokens.fontSizeBody,
                        height: 1.6,
                      ),
                    ),
                  ),
                if (entry.hasAudio) ...[
                  const SizedBox(height: AppTokens.spacingMd),
                  Container(
                    padding: const EdgeInsets.all(AppTokens.spacingMd),
                    decoration: BoxDecoration(
                      color: AppTokens.primaryLight,
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
                                color: AppTokens.primary,
                                size: 32,
                              ),
                              onPressed: () => _togglePlay(entry),
                            ),
                            const SizedBox(width: AppTokens.spacingXs),
                            // 之前是 Hero('vent-mic-...'),但 source 已统一到
                            // 顶部的 CircleAvatar。这里只保留普通 mic icon (无 Hero)
                            const Icon(
                              Icons.mic,
                              color: AppTokens.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              entry.durationLabel(),
                              style: const TextStyle(
                                fontSize: AppTokens.fontSizeBody,
                                color: AppTokens.primary,
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
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTokens.textHint,
                              ),
                            ),
                            Text(
                              _formatDur(_duration),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTokens.textHint,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppTokens.spacingXl),
                const Text(
                  '🔒 私密 · 只有你能看到',
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeCaption,
                    color: AppTokens.textHint,
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  String _formatDur(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
