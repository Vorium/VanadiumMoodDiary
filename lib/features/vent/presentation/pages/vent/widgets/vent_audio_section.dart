// v0.24 round 46 (emil B-13 god class 续拆): vent_compose 抽 3 子 widget
//
// 3 态 (idle / recording / recorded) PageTransitionSwitcher 平滑切换
// mic 位置 crossfade 给用户"我刚按下"的位置感 (emil spatial consistency)
//
// 高内聚：只关心录音按钮 / 播放按钮 / 重录按钮的 UI 切换
// 低耦合：orchestrator 调 (isRecording, audioPath, audioDurationSec, isPlaying) + 3 个 callback
//
// v0.32 R112 round 8h: 录音中加 暂停/继续 控制 —
// - 修前录音态渲染 _buildIdleButton 且 `onPressed: isRecording ? null : ...`
//   = 录音中停止按钮被禁用 (v0.24 起 bug), 用户只能等 3min 自动停, 且
//   无任何暂停能力 (用户报"树洞录音不能暂停")
// - 修后 recording/paused 渲染 _buildRecordingRow:
//   [暂停/继续] [实时时长 mm:ss, 暂停冻结] [停止]
import 'package:flutter/material.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/presentation/widgets/press_feedback_icon_button.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/animations/page_transition_switcher.dart';

enum _AudioState { idle, recording, recorded }

class VentAudioSection extends StatelessWidget {
  final bool isRecording;
  final bool isPaused;
  final Duration recordingElapsed;
  final String? audioPath;
  final int? audioDurationSec;
  final bool isPlaying;
  final VoidCallback onToggleRecord;
  final VoidCallback onTogglePause;
  final VoidCallback onTogglePlay;
  final VoidCallback onReRecord;

  const VentAudioSection({
    super.key,
    required this.isRecording,
    required this.isPaused,
    required this.recordingElapsed,
    required this.audioPath,
    required this.audioDurationSec,
    required this.isPlaying,
    required this.onToggleRecord,
    required this.onTogglePause,
    required this.onTogglePlay,
    required this.onReRecord,
  });

  @override
  Widget build(BuildContext context) {
    final state = audioPath == null
        ? (isRecording || isPaused ? _AudioState.recording : _AudioState.idle)
        : _AudioState.recorded;
    return PageTransitionSwitcher(
      switchKey: state,
      child: switch (state) {
        _AudioState.idle => _buildIdleButton(context),
        _AudioState.recording => _buildRecordingRow(context),
        _AudioState.recorded => _buildRecordedRow(context),
      },
    );
  }

  Widget _buildIdleButton(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: onToggleRecord,
        icon: Icon(
          Icons.mic,
          color: AppTokens.primaryColor(context),
          size: 28,
        ),
        label: Text(
          AppLocalizations.of(context).ventRecordIdle,
          style: TextStyle(
            fontSize: AppTokens.fontSizeBody,
            color: AppTokens.primaryColor(context),
          ),
        ),
      ),
    );
  }

  // v0.32 R112 round 8h: 录音中行 — [暂停/继续] [时长] [停止]
  // 修前此处渲染 _buildIdleButton 且录音中 onPressed=null (停止按钮禁用)
  Widget _buildRecordingRow(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: AppTokens.edgeInsetsSm,
      decoration: BoxDecoration(
        color: AppTokens.primaryLightColor(context),
        borderRadius: BorderRadius.circular(AppTokens.radiusChip),
      ),
      child: Row(
        children: [
          // 暂停 / 继续切换
          PressFeedbackIconButton(
            icon: isPaused ? Icons.play_arrow : Icons.pause,
            color: AppTokens.primaryColor(context),
            onPressed: onTogglePause,
            tooltip: isPaused
                ? l10n.audioRecordResumeTooltip
                : l10n.audioRecordPauseTooltip,
          ),
          Icon(
            Icons.mic,
            color: AppTokens.primaryColor(context),
            size: AppTokens.iconSizeInline,
          ),
          const SizedBox(width: AppTokens.spacingChipGap),
          // v0.32 R112 round 8i: 大字号/窄屏防溢出 — 时长 FittedBox 缩放
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _formatDuration(recordingElapsed),
                style: TextStyle(
                  fontSize: AppTokens.fontSizeBody,
                  color: AppTokens.primaryColor(context),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          const Spacer(),
          // 停止 (录音中可点 — 修前禁用 bug)
          PressFeedbackIconButton(
            icon: Icons.stop,
            color: AppTokens.errorColor(context),
            onPressed: onToggleRecord,
            tooltip: l10n.audioRecordStopTooltip,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordedRow(BuildContext context) {
    // 有录音：显示播放 / 重录
    return Container(
      padding: AppTokens.edgeInsetsSm,
      decoration: BoxDecoration(
        color: AppTokens.primaryLightColor(context),
        borderRadius: BorderRadius.circular(AppTokens.radiusChip),
      ),
      child: Row(
        children: [
          // v0.27 round 62 (P1-15 修复): 改用 PressFeedbackIconButton 集中器
          PressFeedbackIconButton(
            icon: isPlaying ? Icons.stop : Icons.play_arrow,
            color: AppTokens.primaryColor(context),
            onPressed: onTogglePlay,
            tooltip: isPlaying
                ? AppLocalizations.of(context).ventAudioPauseTooltip
                : AppLocalizations.of(context).ventAudioPlayTooltip,
          ),
          Icon(
            Icons.mic,
            color: AppTokens.primaryColor(context),
            size: AppTokens.iconSizeInline,
          ),
          const SizedBox(width: AppTokens.spacingChipGap),
          // v0.32 R112 round 8i: 大字号/窄屏防溢出
          Flexible(
            child: Text(
              audioDurationSec != null
                  ? _formatSec(context, audioDurationSec!)
                  : AppLocalizations.of(context).ventAudioLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: AppTokens.fontSizeBody,
                color: AppTokens.primaryColor(context),
              ),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onReRecord,
            child: Text(AppLocalizations.of(context).ventRerecord),
          ),
        ],
      ),
    );
  }

  String _formatSec(BuildContext context, int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
