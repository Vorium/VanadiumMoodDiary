# mood_dialog god class 拆解设计

> **Sprint**: v0.24 Sprint #5
> **基线**: v0.24 round 45 / commit `cf61948` (HEAD)
> **Skill 视角**: emilkowalski (设计工程师 · 状态机拆解 · 组件边界 · 决策命名化)
> **目标文件**: `lib/presentation/pages/mood/mood_dialog.dart` (706 行, 1 个 state class 装 4 状态机)
> **参考样板**: `settings_page` 681 → 96 行 (6 widget + 1 orchestrator)

---

## 1. 现状诊断 (emil 视角)

### 1.1 数字说话

| 指标 | 值 | emil 评估 |
|---|---|---|
| 总行数 | **706** | 远超 god class 阈值 (500+) |
| `_MoodDialogContentState` 字段 | **15** 个 (4 评分 + 1 tag Set + 1 controller + 8 录音) | 1 个 state class 装 4 个独立状态机 |
| StreamSubscription | **2** 个 (`_playerCompleteSub` + `_sttSub`) | 资源生命周期互相耦合 |
| 业务职责 | **6 类**: 4 维度评分 / 标签 / 文字 / 录音状态机 / STT 流 / 临时文件清理 | 违反 SRP (Single Responsibility) |
| 公开 widget | 1 (`_MoodDialogContent`) + 1 内部 (`_MoodAudioSection`) | 后者仅封装 UI, 状态机仍在 parent |

### 1.2 emil "decisions should be nameable" 检查

`mood_dialog.dart` 当前 6 类状态**没有一处有清晰命名**:
- 4 维度评分 (`_score/_energy/_sleep/_anxiety`) — 4 个变量名相同模式
- 录音机 (`_isRecording/_audioPath/_audioDurationMs/_liveTranscript/_finalTranscript/_isPlaying/_sttAvailable/_sttFailed/_tempDecryptedPath`) — 9 个相关字段全平铺
- 临时文件 + AudioPlayer + StreamSubscription 跟 4 维度评分共享同一个 state — **emil 视角: "decisions that can't be named are usually wrong"**

### 1.3 当前 god class 的 4 类决策混在一起

1. **数据收集决策** (mood/energy/sleep/anxiety/tags/note) — pure data, 无副作用
2. **录音资源决策** (AudioPlayer/Recorder/STT) — 有副作用, 需要 dispose 链
3. **生命周期决策** (initialize/dispose/cancelRecording) — 资源管理
4. **UI 编排决策** (AlertDialog 容器 / actions 按钮) — presentation only

---

## 2. 拆解方案 (emil 决策)

### 2.1 拆分原则 (5 条)

1. **5 个子 widget, 1 个 orchestrator**: 跟 settings_page 6 widget + 1 page 同模式
2. **MoodRecorder 自管录音机**: idle/recording/recorded/playing 状态机**完整下沉**, 不上抛
3. **orchestrator 只持跨 widget 状态**: 4 维度评分 + tag Set + 文字 (不持录音机)
4. **回调统一 ValueChanged / VoidCallback**: 不用 Riverpod (单 dialog scope, 不需要全局)
5. **保留所有 P0/P1 修复**: snackbar 移到 pop 前 / AudioPlayer dispose 顺序 / EncryptedAudioStorage cleanup / swallowError 模式

### 2.2 目标文件树

```
lib/presentation/pages/mood/
├── mood_dialog.dart              (~150 行 — Dialog 容器 + orchestrator 状态)
└── widgets/                      (新目录)
    ├── mood_score_form.dart      (~100 行 — 4 维度评分)
    ├── mood_tags.dart            (~50 行 — 标签多选)
    ├── mood_text_note.dart       (~40 行 — 文字备注)
    ├── mood_recorder.dart        (~200 行 — 录音机 + STT 自管状态机)
    └── mood_dialog_actions.dart  (~30 行 — 取消/保存按钮)
```

**总行数**: 706 → 150 + 100 + 50 + 40 + 200 + 30 = **570 行** (分解后总和, 不算 orchestrator 减负)
**实际效果**: 每个文件 ≤ 200 行, 单一职责, 可独立测试

### 2.3 数据流 (orchestrator → 子 widget)

```
MoodDialog.show() [static]
  └── _MoodDialogContent [ConsumerStatefulWidget]
        ├── state: _score/_energy/_sleep/_anxiety (int × 4)
        │         _tags (Set<String>)
        │         _noteController (TextEditingController)
        │         _saving (bool)
        │         _recorderController (MoodRecorderController)
        └── build:
              ├── Column:
              │   ├── MoodScoreForm(value×4, onChanged×4)
              │   ├── MoodTags(selected: _tags, onToggle: ...)
              │   ├── MoodTextNote(controller: _noteController)
              │   └── MoodRecorder(controller: _recorderController)
              └── actions: MoodDialogActions(
                    saving: _saving,
                    onSave: _save,
                    onCancel: _cancel,
                  )
```

### 2.4 5 个子 widget 接口 (emil "decisions should be nameable")

#### `MoodScoreForm` (~100 行)

```dart
class MoodScoreForm extends StatelessWidget {
  final int score, energy, sleep, anxiety;          // 4 维度当前值
  final ValueChanged<int> onScoreChanged, onEnergyChanged,
                          onSleepChanged, onAnxietyChanged;

  /// 4 个 DimensionRow 顺序排列, 单文件 100 行
}
```

**责任**: 4 维度评分 UI。无状态, 全 callback 透传。复用现 `DimensionRow` widget (v0.23 round 44 抽出, 已有 PressFeedback + AppSemantics 集中器)。

#### `MoodTags` (~50 行)

```dart
class MoodTags extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;  // 通知 parent add/remove
}
```

**责任**: 6 个预设标签的 `FilterChip` 多选。无状态, 标签文本从 l10n 拿。

#### `MoodTextNote` (~40 行)

```dart
class MoodTextNote extends StatelessWidget {
  final TextEditingController controller;
}
```

**责任**: 文字备注 TextField。无状态, controller 透传 (parent 负责 dispose)。

#### `MoodRecorder` (~200 行)

```dart
/// 录音机 — 自管 idle/recording/recorded/playing 状态机
class MoodRecorder extends StatefulWidget {
  final MoodRecorderController controller;
  const MoodRecorder({super.key, required this.controller});
}

class _MoodRecorderState extends State<MoodRecorder> {
  // 内部状态: isRecording / audioPath / audioDurationMs / liveTranscript /
  //          finalTranscript / isPlaying / sttAvailable / sttFailed
  // 内部资源: AudioPlayer / 2 StreamSubscription / tempDecryptedPath
  // 不上抛 — parent 调 controller.snapshot() 拿当前快照
}

class MoodRecorderController {
  final _state = ValueNotifier<MoodRecorderSnapshot>(...);
  ValueListenable<MoodRecorderSnapshot> get snapshot;
  Future<void> toggleRecord();
  Future<void> togglePlay();
  Future<void> reRecord();
  Future<void> dispose();
}

class MoodRecorderSnapshot {
  final String? audioPath;
  final int? audioDurationMs;
  final String? finalTranscript;
  // ... 用于 save 时收集
}
```

**责任**: 录音 + STT 状态机 + 临时文件清理 + AudioPlayer 生命周期。**所有副作用内部消化**, parent 只通过 `controller.snapshot` 拿最终数据 + `controller.toggleXxx` 触发动作。

**emil 决策**: 用 `ValueNotifier + ValueListenable` 而非 `setState` 上抛, 状态在 child 内部流转, orchestrator 只在 save 时拉快照。

#### `MoodDialogActions` (~30 行)

```dart
class MoodDialogActions extends StatelessWidget {
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onCancel;
}
```

**责任**: 取消 / 保存按钮 + saving spinner (复用 `LoadingTextButton`)。

### 2.5 orchestrator (`mood_dialog.dart` ~150 行)

```dart
class MoodDialog {
  static Future<void> show(BuildContext, WidgetRef) { ... }
}

class _MoodDialogContent extends ConsumerStatefulWidget { ... }

class _MoodDialogContentState extends ConsumerState<_MoodDialogContent> {
  // ===== 跨 widget 状态 =====
  int _score = 3, _energy = 3, _sleep = 3, _anxiety = 3;
  final _tags = <String>{};
  late final _noteController = TextEditingController();
  bool _saving = false;
  late final _recorderController = MoodRecorderController();

  // ===== 保存流程 =====
  Future<void> _save() async {
    final hasText = _noteController.text.trim().isNotEmpty;
    final snap = _recorderController.snapshot.value;
    final hasAudio = snap.audioPath != null;
    if (!hasText && !hasAudio) { /* snackbar hint */ return; }
    if (_saving) return;
    setState(() => _saving = true);
    final savedAudioPath = snap.audioPath;
    try {
      await ref.read(moodRepositoryProvider).add(
        score: _score, tags: _tags.toList(), note: hasText ? ... : null,
        energy: _energy, sleep: _sleep, anxiety: _anxiety,
        audioPath: savedAudioPath,
        audioTranscript: snap.finalTranscript,
        audioDurationMs: snap.audioDurationMs,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.info(context, l10n.moodAudioSavedWithPlay),
      );
      Navigator.pop(context);
    } catch (e) { ... }
  }

  @override
  void dispose() {
    _recorderController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(l10n.moodDialogTitle),
      content: SingleChildScrollView(child: Column(...)),
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
```

---

## 3. 关键设计决策 (emil 决策框架)

### 3.1 决策 1: MoodRecorder 状态机如何独立?

| 候选 | 优劣 |
|---|---|
| **A. ValueNotifier + ValueListenable** ✅ | parent 不订阅变化流, 只在 save 时拉快照, 99% 状态机在 child 内部 |
| B. Riverpod StateNotifier | 过度工程, dialog 不需要全局 |
| C. callback 上抛 (旧模式) | parent 状态膨胀, 拆解失败 |

**决策**: A。`MoodRecorderController` 暴露 `snapshot` (ValueListenable) + `toggleRecord/togglePlay/reRecord` (方法) + `dispose` (清理)。

### 3.2 决策 2: `_MoodAudioSection` 去留?

**决策**: **删除 `_MoodAudioSection`, 整体下沉到 `MoodRecorder`**。
- 当前 230 行 widget (含注释) 已经在封装录音 UI
- 拆解后 200 行 MoodRecorder 是其**演进** (内部消化状态机)
- 不需要中间层

### 3.3 决策 3: maxReached 状态是否上抛?

**当前**: parent 计算 `audioDurationMs >= 180000` 传 `maxReached` flag 给 `_MoodAudioSection`。
**决策**: **下沉到 MoodRecorder 内部**。`MoodRecorderSnapshot.maxReached` 由 recorder 内部 tick 100ms 时计算, parent 不感知。

### 3.4 决策 4: l10n 调用位置?

**emil "decisions should be nameable" 原则**: l10n 文本应靠近使用点 (靠近显示位置)。
**决策**:
- 子 widget 内部直接调 `AppLocalizations.of(context).moodXxx`
- orchestrator 调 l10n 仅用于 `moodDialogTitle` (dialog title) + `moodNoteHint` (保存时 hint) + `moodAudioSavedWithPlay` (保存后 snackbar)

### 3.5 决策 5: 临时文件清理谁负责?

**当前**: parent dispose 时清 (脆弱, 跨 widget)
**决策**: **MoodRecorder 内部消化**。
- 录音停止时 → 加密 + 删明文 (MoodRecorder 内部)
- 播放完成时 → 删 temp (MoodRecorder 内部)
- parent dispose → `controller.dispose()` 触发 MoodRecorder dispose → 全部清理

---

## 4. 验证策略

### 4.1 静态验证

```bash
flutter analyze     # 0 error (48 info-level 已有, 不回归)
flutter test        # 876 cases pass (不回归)
dart scripts/check_all.dart  # 4 层架构 0 violation
```

### 4.2 测试覆盖

| 文件 | 行数 | 测试目标 |
|---|---|---|
| `mood_dialog.dart` (orchestrator) | ~150 | 4 维度评分 + 标签 + 文字 + save 流程 |
| `widgets/mood_score_form.dart` | ~100 | 4 维度评分回调触发 |
| `widgets/mood_tags.dart` | ~50 | tag toggle 行为 |
| `widgets/mood_text_note.dart` | ~40 | controller 透传 |
| `widgets/mood_recorder.dart` | ~200 | 状态机 + STT + temp cleanup (现有 round31 test 覆盖 service 契约) |
| `widgets/mood_dialog_actions.dart` | ~30 | saving 态 spinner + 按钮 onTap |

**新 test**: `test/presentation/mood_dialog_split_round45_test.dart`
- 验证 5 个子 widget 都能 mount
- 验证 save 流程 (无 text 无 audio → hint)
- 验证 MoodRecorder snapshot 行为 (idle/recording/recorded)
- 验证 orchestrator dispose 链 (recorder + noteController)

### 4.3 行为不变性 (P0/P1 不回归)

| P0/P1 修复 | 保留位置 |
|---|---|
| snackbar 移到 pop 前 | `_save()` in orchestrator |
| AudioPlayer dispose 顺序 (`stop` → `dispose`) | `MoodRecorder.dispose()` |
| EncryptedAudioStorage temp cleanup | `MoodRecorder.dispose()` |
| `_playerCompleteSub` 显式 cancel | `MoodRecorder.dispose()` |
| `_sttSub` 显式 cancel | `MoodRecorder.dispose()` |
| `swallowError` 模式 (4 处 dispose) | `MoodRecorder.dispose()` (合并) |
| `_isRecording` 时 cancel recording on dispose | `MoodRecorder.dispose()` |
| STT failed graceful degrade (`_sttFailed`) | `MoodRecorder` 内部状态 |
| 60s STT partial hint | `MoodRecorder` UI (录音中显示) |

---

## 5. 工作量估算

| 步骤 | 工作量 |
|---|---|
| Step 1: 5 个子 widget 抽出 | 🟠 4-6 小时 |
| Step 2: MoodRecorderController + Snapshot 抽象 | 🟠 2 小时 |
| Step 3: orchestrator 重新组装 | 🟢 1 小时 |
| Step 4: 写 split test | 🟡 1-2 小时 |
| Step 5: 全量验证 | 🟢 30 分钟 |
| **合计** | **🟠 1-2 天** (8-12 小时) |

---

## 6. 风险评估

| 风险 | 概率 | 缓解 |
|---|---|---|
| 现有 widget test 失效 | 🟢 低 | round31 test 只测 service 契约, 不碰 widget |
| 状态机迁移 bug (dispose 顺序) | 🟡 中 | 显式保留所有 P0 修复 + dispose 链测试 |
| MoodRecorderController API 不够灵活 | 🟢 低 | snapshot + 3 method 简单清晰 |
| 子 widget 重建频率过高 (录音中每 100ms) | 🟡 中 | ValueNotifier 只在 snapshot 字段变化时通知, 录音 UI 局部 rebuild |

---

## 7. 不在本次 scope

- ❌ notification_service 拆 4 orchestrator (P0 god class 候选 #2)
- ❌ data_export_service 拆 3-4 子 service (P3 god class 候选)
- ❌ 其他 8 个 god class (assessment_history / trend_charts / vent_compose / ...)
- ❌ token 化 14 处 `withValues(alpha:)` 散落
- ❌ 4 处 hardcode duration / 4 处 hardcode icon size
- ❌ ScaffoldMessenger 集中化 56% → 95%
- ❌ AppListTile 全量替换 13+ ListTile

**本次只动 `mood_dialog.dart` + 新增 5 个子 widget**。

---

## 8. 参考样板: settings_page 拆解成功关键

| 关键 | 体现 |
|---|---|
| 1 page = 1 orchestrator | 96 行, 仅 Scaffold + ListView + 6 SectionHeader |
| 1 section = 1 widget (50-450 行) | 6 widget, 各管自己职责 |
| 跨 widget 状态不上抛 | data 是从 provider 拿 (ConsumerWidget) |
| 不引入新架构 | 仅用 Riverpod 现有能力 |

**mood_dialog 拆解关键 (跟 settings_page 同)**:
- 1 dialog = 1 orchestrator (~150 行, AlertDialog 容器)
- 5 个子 widget 各管自己职责
- 跨 widget 状态 (4 维度 + tag + text) 留在 orchestrator (dialog scope, 简单值)
- 录音机状态机下沉到 MoodRecorder (内部消化, 99% 副作用不外泄)
- 不引入 Riverpod StateNotifier (单 dialog, ValueNotifier 足够)
