// v0.29 round 84 (CBT 思维记录): 3 栏 mode UI 改造
//
// 改自 v0.28 (round 64) — 把 4 维度 MoodScoreChooser 替换为 3/5/7 栏档位切换
// + CbtThreeColumnMode (3 栏) / CbtWizard stub (5/7 栏, Task 6 落地)
//
// 历史:
// - v0.18 round 18: 4 维度评分升级 (mood/energy/sleep/anxiety)
// - v0.23 round 31: 语音录入 + STT graceful degrade
// - v0.24 Sprint #5: 5 子 widget 抽离
// - v0.28 round 64: god-split 收尾 + 子 widget 重命名
// - v0.29 round 84: 4 维度评分移除, 改用 1 维 (mood) + CBT 字段 (3/5/7 栏)
//
// **职责**: 跨 widget 状态 (tags + note + audio + saving) + 协调子 widget +
//            save 流程 + 错误处理 + SegmentedButton 档位切换
// **入口**: MoodRecorderPage.show() (静态方法, 走 Dialog 模态)
//
// emil 设计决策 (v0.29 改造):
// 1. Dialog + Column 替代 AlertDialog — 3 段 (header/body/footer) 适配 SegmentedButton
// 2. SegmentedButton 切档时联动 thoughtRecordLevelProvider (持久化) + cbtDraftProvider
// 3. 4 维度评分 (energy/sleep/anxiety) 移除 — 新设计单 mood 维度 + CBT 字段
// 4. 录音 / 标签 / 文字备注 / 保存按钮保持现有行为
// 5. cbtDraftProvider 状态 dialog 关闭时 reset (下回打开恢复初始 3 栏)
//
// v1.1.0 R114 (Wave D, spec §5.5) ALS 化:
// - body 3 段改 AppleListSection insetGrouped 2 组 (情绪评分组: 5 档 72pt
//   圆形 spring 选中 / 记录内容组: period+影响因素+标签+状态短语+烦恼+note+audio)
// - Dialog 保持 modal (sheet 化留 v1.0, 裁决见 build 注释)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/shared/error_sinks.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/data/feature_flags.dart';
import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/domain/entities/influence_category.dart';
import 'package:chroniccare/features/mood/domain/entities/mood_entry_draft.dart';
import 'package:chroniccare/domain/entities/thought_record_level.dart';
import 'package:chroniccare/domain/logic/worry_thread_library.dart';
import 'package:chroniccare/presentation/widgets/worry_selector_field.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/mood_score_buttons.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/mood_audio_section.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/mood_influence_chips.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/mood_submit_panel.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/mood_tags.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/mood_text_input.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/period_field.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/status_phrase_field.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/cbt_three_column_mode.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/cbt_wizard.dart';

/// 情绪日记 orchestrator page
///
/// v0.29 round 84: 集成 3/5/7 栏 CBT 思维记录
/// - 顶部: SegmentedButton (3 栏 / 5 栏 / 7 栏) 切档
/// - 中间: 3 栏 mode (CbtThreeColumnMode) 或 5/7 栏 (CbtWizard stub, Task 6 落地)
/// - 底部: 标签 + 文字备注 + 录音 + 保存/取消
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
/// v0.29 (round 84): 4 维度评分移除, 改 CBT 思维记录
class MoodRecorderPage extends ConsumerStatefulWidget {
  /// v1.1.0 round 9 (F1 烦恼闭环): 预绑定烦恼主题 id (从时间线"继续倾诉"
  /// 进入时带 query `worry=<id>`; 普通入口 = null)
  final int? initialWorryThreadId;

  const MoodRecorderPage({super.key, this.initialWorryThreadId});

  /// 静态入口 — Dialog 模态
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
  final Set<String> _tags = {};

  // ===== v0.30 R101: 影响因素 =====
  final List<String> _influenceFactors = [];

  // ===== v0.30 R101: 记录模式 (瞬时/日常) =====
  String _recordingMode = 'momentary';

  // ===== 文字备注 =====
  late final TextEditingController _noteController;

  // ===== v1.1.0 round 5d: 状态短语 (预设 chip / 自定义, 可空) =====
  String? _statusPhrase;

  // ===== v1.1.0 round 9 (F1 烦恼闭环): 烦恼绑定 =====
  int? _worryThreadId;
  bool _createNewWorry = false;

  // ===== 保存状态 =====
  bool _saving = false;

  // ===== 录音机 controller =====
  late final MoodRecorderController _recorderController;

  // ===== 提前捕获 notifier (避免 dispose() 里 ref.read 触发 unmounted assert)
  // v0.30 round 91 (P1): Riverpod 3.x 严格要求 dispose 期间不用 ref,
  // 否则 widget test 跟 widget unmount 时崩。InitState 时一次性
  // capture, dispose 时直接调。
  late final CbtDraftNotifier _cbtDraftNotifier;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    // v1.1.0 round 9 (F1): 从时间线"继续倾诉"进入时预绑定烦恼
    _worryThreadId = widget.initialWorryThreadId;
    _recorderController = MoodRecorderController(
      onError: _handleRecorderError,
    );
    _cbtDraftNotifier = ref.read(cbtDraftProvider.notifier);
    // v0.29 round 84 (fix): dialog 打开时从 SP 同步 level
    //
    // 背景: dispose() 会 reset cbtDraftProvider 回 3 栏, 但用户的 5/7 栏偏好持久化在
    // thoughtRecordLevelProvider (SP)。若不同步, 下次打开 SegmentedButton 会显示 3 栏
    // selected, 但 SP 里仍是 5/7 栏 — 偏好被静默丢弃。
    //
    // 用 addPostFrameCallback 而非同步调用: 避免在 initState 期间直接触发 provider
    // 写入 + 避免 build() 期间修改 provider 触发 Riverpod 警告。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final persisted = ref.read(thoughtRecordLevelProvider);
      if (ref.read(cbtDraftProvider).level != persisted) {
        ref.read(cbtDraftProvider.notifier).setLevel(persisted);
      }
    });
  }

  @override
  void dispose() {
    _recorderController.dispose();
    _noteController.dispose();
    // 关闭 dialog 时重置 cbtDraftProvider, 下次打开回到初始 (3 栏)
    // — 但 initState 的 addPostFrameCallback 会从 SP 重新同步 5/7 栏偏好。
    //
    // v0.30 R91 P1 fix: 用 initState 捕获的 notifier 引用 (避免 dispose 期
    // ref.read 触发 unmounted assert), 再用 microtask 延迟到 widget tree
    // finalize 之后 (避免 Riverpod 3.x "modifying provider during build"
    // 警告)。try-catch swallow: 测试 teardown 时 fake_async 会在
    // ProviderScope 拆掉后 flush microtask, 此时 notifier 已 dispose, 静默
    // 吞掉 (reset 是 best-effort, 不是 critical path)。生产路径: 用户点
    // 保存 → Navigator.pop → dispose → 下个微任务 reset (此时 notifier 仍
    // 在, 因为 cbtDraftProvider 非 autoDispose)。下次打开 dialog →
    // initState → addPostFrameCallback 从 SP 同步 5/7 栏偏好。
    Future.microtask(() {
      try {
        _cbtDraftNotifier.reset();
      } catch (e, st) {
        // v0.30 R92: 走 swallowError 集中器, 替代完全静默 (R39 P1-10 模式)
        // notifier 已 dispose (test teardown); 记录 dev 模式看 devtools
        audioErrorSink(
          where: 'mood_recorder_page.dispose_cbtDraft_reset',
          error: e,
          stack: st,
          note: 'cbtDraftNotifier.reset() 在 dispose 后调用, 记录但不阻断',
        );
      }
    });
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
    final cbtState = ref.read(cbtDraftProvider);
    final snap = _recorderController.snapshot.value;
    final hasText = _noteController.text.trim().isNotEmpty;
    final hasAudio = snap.audioPath != null;
    final hasCbtContent = (cbtState.draft.situation?.isNotEmpty ?? false) ||
        (cbtState.draft.automaticThought?.isNotEmpty ?? false);
    if (!hasText && !hasAudio && !hasCbtContent) {
      AppSnackBar.showInfo(
        context,
        AppLocalizations.of(context).moodNoteHint,
      );
      return;
    }
    setState(() => _saving = true);
    // v1.1.0 R113 (BUG 4): catch 块读不到 try 内局部变量 → 提升到 try 外
    // (回滚删除本次新建的烦恼主题)
    var createdThreadId = 0;
    try {
      // cbtState.draft 已有 score + cbt 字段; 合并 tags/note/audio
      // (MoodEntryDraft 无 copyWith, 手动展开 8 个 CBT 字段)
      final d = cbtState.draft;
      // v1.1.0 round 9 (F1 烦恼闭环): 新建烦恼 → 先建主题 (title = 首条
      // note 前 20 字), 再绑到本条记录。生成规则在 domain library。
      // v1.1.0 R113 (BUG 4): 修前创建后 mood add 失败 → 孤儿主题 (无
      // 任何记录引用, 永远躺在"进行中"列表)。修: 记 createdThreadId,
      // catch 里回滚 delete。
      var worryThreadId = _worryThreadId;
      if (_createNewWorry) {
        final note = hasText ? _noteController.text.trim() : null;
        final title = WorryThreadLibrary.generateTitle(note) ??
            AppLocalizations.of(context).worryDefaultTitle;
        final now = DateTime.now();
        createdThreadId = await ref
            .read(worryThreadRepositoryProvider)
            .create(title: title, at: now);
        worryThreadId = createdThreadId;
      }
      await ref.read(moodRepositoryProvider).add(
            draft: MoodEntryDraft(
              score: d.score,
              tags: _tags.toList(),
              note: hasText ? _noteController.text.trim() : null,
              audioPath: snap.audioPath,
              audioTranscript:
                  snap.finalTranscript.isEmpty ? null : snap.finalTranscript,
              audioDurationMs: snap.audioDurationMs,
              situation: d.situation,
              automaticThought: d.automaticThought,
              evidenceFor: d.evidenceFor,
              evidenceAgainst: d.evidenceAgainst,
              alternativeThought: d.alternativeThought,
              reratedScore: d.reratedScore,
              coreBelief: d.coreBelief,
              behaviorResponse: d.behaviorResponse,
              // v0.30 round 91: 心境时段 (morning/noon/evening/night/
              // unspecified), 透传 save → DB → mood_period_aggregator
              period: d.period,
              // v0.30 R101: 影响因素
              influenceFactorsJson: _influenceFactors.isEmpty
                  ? null
                  : InfluenceCodec.encode(_influenceFactors),
              // v0.30 R101: 记录模式
              recordingMode: _recordingMode,
              // v1.1.0 round 5d: 状态短语 (预设或自定义, null = 未选)
              statusPhrase: _statusPhrase,
              // v1.1.0 round 9 (F1 烦恼闭环): 烦恼主题绑定
              worryThreadId: worryThreadId,
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
      // v1.1.0 R113 (BUG 4): 本次新建的烦恼主题回滚删除 — 否则 mood
      // 保存失败后主题孤儿残留 (无记录引用)。best-effort: 回滚失败走
      // swallowError (主题还在列表里, 用户可自行删除, 不阻断错误提示)。
      if (createdThreadId != 0) {
        try {
          await ref.read(worryThreadRepositoryProvider).delete(createdThreadId);
        } catch (e2, st2) {
          swallowError(
            where: 'mood_recorder_page._save.rollbackWorryThread',
            error: e2,
            stack: st2,
            note: '新建烦恼主题回滚失败, 主题留在列表 (用户可手动删)',
          );
        }
      }
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
    final cbtState = ref.watch(cbtDraftProvider);
    final cbtNotifier = ref.read(cbtDraftProvider.notifier);
    final levelNotifier = ref.read(thoughtRecordLevelProvider.notifier);
    final isThreeColumn = cbtState.level == ThoughtRecordLevel.three;

    // v0.27 R72 (P5.4): 整 build 包 RepaintBoundary
    //
    // v1.1.0 R114 (Wave D, spec §5.5): Dialog+Column → AppleListSection
    // insetGrouped 2 组 (情绪评分组 / 记录内容组)。裁决: Dialog 保持 modal
    // (showModalBottomSheet 化留 v1.0 — 现有 6+ 调用方/测试走 showDialog,
    // 改动风险高, apple-design 审计 F-mood 的 sheet 化记为后续项)。
    return RepaintBoundary(
      child: Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusCard),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: AppTokens.edgeInsetsMd,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 顶部: 标题 + 档位切换
                    Text(
                      l10n.moodDialogTitle,
                      style: AppTokens.textStyleLabelStrong(context),
                    ),
                    const SizedBox(height: AppTokens.spacingSm),
                    SegmentedButton<ThoughtRecordLevel>(
                      segments: [
                        ButtonSegment(
                          value: ThoughtRecordLevel.three,
                          label: Text(l10n.moodCbtLevelLabel3),
                        ),
                        ButtonSegment(
                          value: ThoughtRecordLevel.five,
                          label: Text(l10n.moodCbtLevelLabel5),
                        ),
                        ButtonSegment(
                          value: ThoughtRecordLevel.seven,
                          label: Text(l10n.moodCbtLevelLabel7),
                        ),
                      ],
                      selected: {cbtState.level},
                      onSelectionChanged: (selection) {
                        final newLevel = selection.first;
                        // 1. dialog 内部: 切档 + 跳到第一个未填 step
                        cbtNotifier.setLevel(newLevel);
                        // 2. 持久化: 用户下次打开仍用此档
                        levelNotifier.setLevel(newLevel);
                      },
                    ),
                    const SizedBox(height: AppTokens.spacingSm),

                    // v0.30 R101: 记录模式切换 (此刻/今天)
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: 'momentary',
                          label: Text(l10n.moodModeMomentary),
                          icon: const Icon(Icons.access_time, size: 16),
                        ),
                        ButtonSegment(
                          value: 'daily',
                          label: Text(l10n.moodModeDaily),
                          icon: const Icon(Icons.today, size: 16),
                        ),
                      ],
                      selected: {_recordingMode},
                      onSelectionChanged: (selection) {
                        setState(() {
                          _recordingMode = selection.first;
                        });
                      },
                    ),
                    const SizedBox(height: AppTokens.spacingMd),

                    // ===== 情绪评分组 (spec §5.5: 5 档 72pt 圆形 + spring 选中) =====
                    // 仅 3 栏模式 — 5/7 栏 wizard 在 step 2 自管 score。
                    // score 从 CbtThreeColumnMode 移出 (v0.29 后单 mood 维度,
                    // 评分属于 dialog 顶层, 不进模式内容)。
                    if (isThreeColumn) ...[
                      AppleListSection(
                        title: l10n.moodScoreSectionTitle,
                        margin: EdgeInsets.zero,
                        children: [
                          MoodScoreButtons(
                            value: cbtState.draft.score,
                            onChanged: cbtNotifier.updateScore,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTokens.spacingMd),
                    ],

                    // 中间: 模式内容 (3 栏 vs wizard)
                    // v0.30 round 92 (audit-fixes / P0 #11): wizard
                    // 末步 "完成" 按钮调 onSaveRequested → 父 _save 触发
                    // moodRepository.add 把 5/7 栏 CBT 字段落库 (修前 bug:
                    // 直接 pop, 父 _save 没调, 字段丢库)。
                    switch (cbtState.level) {
                      ThoughtRecordLevel.three => const CbtThreeColumnMode(),
                      ThoughtRecordLevel.five ||
                      ThoughtRecordLevel.seven =>
                        CbtWizard(onSaveRequested: _save),
                    },
                    const SizedBox(height: AppTokens.spacingMd),

                    // ===== 记录内容组 (period / 影响因素 / 标签 / 状态短语 /
                    // 烦恼绑定 / note / audio) =====
                    // v1.1.0 R114: Dialog+Column → ALS insetGrouped 分组,
                    // hairline 0.5 分隔各 cell。
                    AppleListSection(
                      title: l10n.moodRecordSectionTitle,
                      margin: EdgeInsets.zero,
                      children: [
                        // v0.30 round 91 (sub-spec 7 日常追踪): 心境时段 dropdown
                        // 5 段 (morning/noon/evening/night/unspecified), 默认
                        // unspecified, 走 cbtDraftProvider 状态, 透传到 save → DB。
                        const PeriodField(),

                        // v0.30 R101: 影响因素标签 (参照 Apple Health State of Mind)
                        MoodInfluenceChips(
                          selected: _influenceFactors,
                          onChanged: (factors) {
                            setState(() {
                              _influenceFactors
                                ..clear()
                                ..addAll(factors);
                            });
                          },
                        ),

                        // 标签
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

                        // v1.1.0 round 5d: 状态短语 (预设 chip 按 score 方向
                        // 优先 + 自定义输入), score 来自上方评分组 (3 栏) 或
                        // wizard step 2 (5/7 栏)。
                        StatusPhraseField(
                          score: cbtState.draft.score,
                          value: _statusPhrase,
                          onChanged: (v) => setState(() => _statusPhrase = v),
                        ),

                        // v1.1.0 round 9 (F1 烦恼闭环): 烦恼绑定选择器
                        // (不关联 / 关联进行中烦恼 / 新建烦恼)
                        WorrySelectorField(
                          initialThreadId: widget.initialWorryThreadId,
                          onChanged: (sel) {
                            setState(() {
                              _worryThreadId = sel.threadId;
                              _createNewWorry = sel.createNew;
                            });
                          },
                        ),

                        MoodTextInput(controller: _noteController),

                        // v0.30 round 93 (阶段 2 audit-fixes): mood audio 录音
                        // 业务闭环不全, 走 [FeatureFlags.ventAudioEnabled] gate,
                        // 默认 false 隐藏。MoodTextInput 文字输入保留 (用户主路径
                        // 不依赖 audio)。MoodTags + PeriodField + CbtThreeColumnMode
                        // 也保留 (核心情绪日记业务)。
                        if (FeatureFlags.ventAudioEnabled)
                          MoodRecorder(controller: _recorderController),
                      ],
                    ),
                    const SizedBox(height: AppTokens.spacingSm),
                    MoodSubmitPanel(
                      saving: _saving,
                      onSave: _save,
                      onCancel: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
