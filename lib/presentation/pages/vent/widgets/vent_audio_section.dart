// v0.24 round 46 (emil B-13 god class 续拆): vent_compose 抽 3 子 widget
//
// 3 态 (idle / recording / recorded) PageTransitionSwitcher 平滑切换
// mic 位置 crossfade 给用户"我刚按下"的位置感 (emil spatial consistency)
//
// 高内聚：只关心录音按钮 / 播放按钮 / 重录按钮的 UI 切换
// 低耦合：orchestrator 调 (isRecording, audioPath, audioDurationSec, isPlaying) + 3 个 callback
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/press_feedback_icon_button.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/animations/page_transition_switcher.dart';

enum _AudioState { idle, recording, recorded }

class VentAudioSection extends StatelessWidget {
  final bool isRecording;
  final String? audioPath;
  final int? audioDurationSec;
  final bool isPlaying;
  final VoidCallback onToggleRecord;
  final VoidCallback onTogglePlay;
  final VoidCallback onReRecord;

  const VentAudioSection({
    super.key,
    required this.isRecording,
    required this.audioPath,
    required this.audioDurationSec,
    required this.isPlaying,
    required this.onToggleRecord,
    required this.onTogglePlay,
    required this.onReRecord,
  });

  @override
  Widget build(BuildContext context) {
    final state = audioPath == null
        ? (isRecording ? _AudioState.recording : _AudioState.idle)
        : _AudioState.recorded;
    return PageTransitionSwitcher(
      switchKey: state,
      child: switch (state) {
        _AudioState.idle => _buildIdleButton(context),
        _AudioState.recording => _buildIdleButton(context),
        _AudioState.recorded => _buildRecordedRow(context),
      },
    );
  }

  Widget _buildIdleButton(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: isRecording ? null : onToggleRecord,
        icon: Icon(
          isRecording ? Icons.stop_circle : Icons.mic,
          color: isRecording
              ? AppTokens.errorColor(context)
              : AppTokens.primaryColor(context),
          size: 28,
        ),
        label: Text(
          isRecording
              ? AppLocalizations.of(context).ventRecordActive
              : AppLocalizations.of(context).ventRecordIdle,
          style: TextStyle(
            fontSize: AppTokens.fontSizeBody,
            color: isRecording
                ? AppTokens.errorColor(context)
                : AppTokens.primaryColor(context),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordedRow(BuildContext context) {
    // 有录音：显示播放 / 重录
    return Container(
      padding: const EdgeInsets.all(AppTokens.spacingSm),
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
          Icon(Icons.mic,
              color: AppTokens.primaryColor(context),
              size: AppTokens.iconSizeInline,),
          const SizedBox(width: AppTokens.spacingChipGap),
          Text(
            audioDurationSec != null
                ? _formatSec(context, audioDurationSec!)
                : AppLocalizations.of(context).ventAudioLabel,
            style: TextStyle(
              fontSize: AppTokens.fontSizeBody,
              color: AppTokens.primaryColor(context),
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
}
