// v0.24 Sprint #5 (emil god class 拆解): mood_dialog orchestrator
//
// **拆解后 (706 → ~150 行 orchestrator)**:
// - 4 维度评分 → widgets/mood_score_form.dart (~100 行)
// - 标签多选 → widgets/mood_tags.dart (~50 行)
// - 文字备注 → widgets/mood_text_note.dart (~40 行)
// - 录音 + STT 状态机 → widgets/mood_recorder.dart (~200 行, 内部消化)
// - 取消/保存按钮 → widgets/mood_dialog_actions.dart (~30 行)
//
// **emil 设计决策**:
// 1. orchestrator 只持**跨 widget 状态** (4 维度 + tag Set + 文字 controller + saving)
// 2. 录音机状态机**完整下沉**到 MoodRecorder — parent 通过 MoodRecorderController.snapshot
//    拉最终数据, 通过 toggleRecord/togglePlay/reRecord 触发动作
// 3. 错误处理走 onError callback — MoodRecorder 不知道 l10n, parent 决定 snackbar 文案
// 4. 保留所有 P0 修复:
//    - snackbar 移到 pop 前 (save 成功先 snackbar 再 Navigator.pop)
//    - dispose 链 (recorder controller + noteController)
//    - service / player / temp file cleanup 全部在 MoodRecorder.dispose() 内
// 5. 频度: tens/day 频度, 跨 widget 状态不上抛, 单 dialog scope
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/mood_entry_draft.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/mood_dialog_actions.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/mood_recorder.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/mood_score_form.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/mood_tags.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/mood_text_note.dart';

/// 情绪日记 dialog
///
/// v0.18 round 18 (P1-15) 升级 4 维度:
/// - 情绪 (mood): 1-5 分 (主轴, 必填)
/// - 精力 (energy): 1-5 分
/// - 睡眠 (sleep): 1-5 分
/// - 焦虑 (anxiety): 1-5 分 (反向:1=严重 5=平静)
/// + 预设标签 (多选) + 自由备注
///
/// v0.23 (Round 31) 语音录入:
/// - 加录音按钮 (与文字备注并存, 互不影响)
/// - STT 失败 graceful degrade
/// - 保存后 snackbar 带 "回放" action
///
/// v0.24 Sprint #5 (emil): 5 子 widget 抽离, orchestrator 持跨 widget 状态
class MoodDialog {
  MoodDialog._();

  static Future<void> show(BuildContext context, WidgetRef ref) {
    return showDialog<void>(
      context: context,
      builder: (_) => const _MoodDialogContent(),
    );
  }
}

class _MoodDialogContent extends ConsumerStatefulWidget {
  const _MoodDialogContent();

  @override
  ConsumerState<_MoodDialogContent> createState() => _MoodDialogContentState();
}

class _MoodDialogContentState extends ConsumerState<_MoodDialogContent> {
  // ===== 跨 widget 状态 =====
  int _score = 3;
  int _energy = 3;
  int _sleep = 3;
  int _anxiety = 3;
  final Set<String> _tags = {};

  // ===== 文字备注 =====
  late final TextEditingController _noteController;

  // ===== 保存状态 =====
  bool _saving = false;

  // ===== 录音机 controller =====
  late final MoodRecorderController _recorderController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _recorderController = MoodRecorderController(
      onError: _handleRecorderError,
    );
  }

  @override
  void dispose() {
    _recorderController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// MoodRecorder 错误回调 — 翻译成 l10n snackbar
  void _handleRecorderError(Object error, MoodRecorderErrorKind kind) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final actionText = switch (kind) {
      MoodRecorderErrorKind.start => l10n.moodAudioErrorStart,
      MoodRecorderErrorKind.stop => l10n.moodAudioErrorStop,
      MoodRecorderErrorKind.encrypt => l10n.moodAudioErrorEncrypt,
      MoodRecorderErrorKind.play => l10n.moodAudioErrorPlay,
    };
    AppSnackBar.showError(context, action: actionText, error: error);
  }

  // ===== 保存 =====
  Future<void> _save() async {
    if (_saving) return;
    final hasText = _noteController.text.trim().isNotEmpty;
    final snap = _recorderController.snapshot.value;
    final hasAudio = snap.audioPath != null;
    if (!hasText && !hasAudio) {
      AppSnackBar.showInfo(
          context,
          AppLocalizations.of(context).moodNoteHint,);
      return;
    }
    setState(() => _saving = true);
    try {
      // v0.24 round 48 (sp-en P1-14): add() 10 参 → MoodEntryDraft 参数对象
      await ref.read(moodRepositoryProvider).add(
            draft: MoodEntryDraft(
              score: _score,
              tags: _tags.toList(),
              note: hasText ? _noteController.text.trim() : null,
              energy: _energy,
              sleep: _sleep,
              anxiety: _anxiety,
              audioPath: snap.audioPath,
              audioTranscript: snap.finalTranscript.isEmpty
                  ? null
                  : snap.finalTranscript,
              audioDurationMs: snap.audioDurationMs,
            ),
          );
      if (!mounted) return;
      // 先展示 snackbar，再 pop — pop 后 context 可能已失效
      AppSnackBar.showInfo(
          context,
          AppLocalizations.of(context).moodAudioSavedWithPlay,);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackBar.showError(
          context,
          action: AppLocalizations.of(context).snackbarActionSave,
          error: e,);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.moodDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MoodScoreForm(
              score: _score,
              energy: _energy,
              sleep: _sleep,
              anxiety: _anxiety,
              onScoreChanged: (v) => setState(() => _score = v),
              onEnergyChanged: (v) => setState(() => _energy = v),
              onSleepChanged: (v) => setState(() => _sleep = v),
              onAnxietyChanged: (v) => setState(() => _anxiety = v),
            ),
            const SizedBox(height: AppTokens.spacingMd),
            const Divider(height: 1),
            const SizedBox(height: AppTokens.spacingSm),
            MoodTags(
              selected: _tags,
              onToggle: (tag) {
                setState(() {
                  if (_tags.contains(tag)) {
                    _tags.remove(tag);
                  } else {
                    _tags.add(tag);
                  }
                });
              },
            ),
            const SizedBox(height: AppTokens.spacingSm),
            MoodTextNote(controller: _noteController),
            const SizedBox(height: AppTokens.spacingSm),
            // v0.23 (Round 31) 语音录入区 — v0.24 (Sprint #5) 抽到 MoodRecorder
            MoodRecorder(controller: _recorderController),
          ],
        ),
      ),
      actions: [
        MoodDialogActions(
          saving: _saving,
          onSave: _save,
          onCancel: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
