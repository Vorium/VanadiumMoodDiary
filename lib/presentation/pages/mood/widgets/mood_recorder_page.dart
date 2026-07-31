// v0.28 (round 64 MoodRecorder god-split): 顶层 page 从 mood_dialog.dart 抽出
//
// 历史:
// - v0.18 round 18: 4 维度评分升级 (mood/energy/sleep/anxiety)
// - v0.23 round 31: 语音录入 + STT graceful degrade
// - v0.24 Sprint #5: 5 子 widget 抽离 (mood_recorder / mood_score_form /
//   mood_tags / mood_text_note / mood_dialog_actions)
// - v0.28 round 64: god-split 收尾 — _MoodDialogContent 抽出到独立 file,
//   子 widget 重命名 (audio_section / score_chooser / text_input / submit_panel)
//
// **职责**: 跨 widget 状态 (4 维度 + tag Set + 文字 controller + saving) +
//            协调 5 子 widget 组装 + save 流程 + 错误处理
// **入口**: MoodRecorderPage.show() (静态方法, 走 AlertDialog 薄壳保持外部行为不变)
//
// emil 设计决策:
// 1. orchestrator 只持**跨 widget 状态**, 录音机状态机**完整下沉**到 MoodAudioSection
// 2. parent 通过 MoodRecorderController.snapshot 拉最终数据
// 3. 错误处理走 onError callback — MoodAudioSection 不知道 l10n
// 4. 保留所有 P0 修复: snackbar 移到 pop 前 / dispose 链 / service 清理
// 5. 频度: tens/day, 跨 widget 状态不上抛 Riverpod, 单 dialog scope
//
// 已知限制 (跟 emil P2-2.21 任务描述差距):
// - 任务说"组装 5 个子 widget", 实际组装 4 个: audio_section / score_chooser /
//   text_input + tags (MoodTags 独立) + submit_panel。
//   mood_avatar_picker 在本项目**根本不存在**, 不发明 (违反"不"改外部行为)。
// - 错误处理在 _save() 内部 (l10n snackbar), 不在 submit_panel 子 widget,
//   跟 R24 抽离原则一致 (decisions should be nameable)。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/mood_entry_draft.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/mood_audio_section.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/mood_score_chooser.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/mood_submit_panel.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/mood_tags.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/mood_text_input.dart';

/// 情绪日记 orchestrator page
///
/// 4 维度评分 (mood/energy/sleep/anxiety) + 预设标签 + 文字备注 + 录音 + 保存/取消。
///
/// v0.18 round 18 (P1-15) 升级 4 维度:
/// - 情绪 (mood): 1-5 分 (主轴, 必填)
/// - 精力 (energy): 1-5 分
/// - 睡眠 (sleep): 1-5 分
/// - 焦虑 (anxiety): 1-5 分 (反向:1=严重 5=平静)
///
/// v0.23 (Round 31) 语音录入:
/// - 加录音按钮 (与文字备注并存, 互不影响)
/// - STT 失败 graceful degrade
/// - 保存后 snackbar 带 "回放" action
///
/// v0.28 (round 64): god-split 收尾, 5 子 widget 重命名
class MoodRecorderPage extends ConsumerStatefulWidget {
  const MoodRecorderPage({super.key});

  /// 静态入口 — 保持外部行为 (AlertDialog 模态) 不变
  static Future<void> show(BuildContext context, WidgetRef ref) {
    return showDialog<void>(
      context: context,
      builder: (_) => const MoodRecorderPage(),
    );
  }

  @override
  ConsumerState<MoodRecorderPage> createState() => _MoodRecorderPageState();
}

class _MoodRecorderPageState extends ConsumerState<MoodRecorderPage> {
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

  /// MoodAudioSection 错误回调 — 翻译成 l10n snackbar
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
        AppLocalizations.of(context).moodNoteHint,
      );
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
        AppLocalizations.of(context).moodAudioSavedWithPlay,
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackBar.showError(
        context,
        action: AppLocalizations.of(context).snackbarActionSave,
        error: e,
      );
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
            MoodScoreChooser(
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
            MoodTextInput(controller: _noteController),
            const SizedBox(height: AppTokens.spacingSm),
            // v0.23 (Round 31) 语音录入区 — v0.28 (round 64) 重命名为 MoodAudioSection
            MoodRecorder(controller: _recorderController),
          ],
        ),
      ),
      actions: [
        MoodSubmitPanel(
          saving: _saving,
          onSave: _save,
          onCancel: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
