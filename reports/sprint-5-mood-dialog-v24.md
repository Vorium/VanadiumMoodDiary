# Sprint #5 — mood_dialog god class 拆解报告 (v0.24 round 45)

> **视角**：emilkowalski（god class 拆解样板）
> **基线**：v0.24 round 45 / 185 commit / 876 test cases / 0 analyze error
> **设计文档**：`docs/refactor/mood_dialog_split_design.md` (285 行 / 14.8KB)
> **完成日期**：2026-07-26

---

## 1. 拆解前/后行数对比

| 文件 | 拆解前 | 拆解后 | Δ | 状态 |
|---|---|---|---|---|
| `mood_dialog.dart` (orchestrator) | **738** | **199** | **-73%** | ✅ 大幅瘦身 |
| `widgets/mood_score_form.dart` (4 维度评分) | 0 | 72 | new | ✅ 4 子 |
| `widgets/mood_tags.dart` (标签多选) | 0 | 45 | new | ✅ |
| `widgets/mood_text_note.dart` (文字备注) | 0 | 27 | new | ✅ |
| `widgets/mood_recorder.dart` (录音 + STT 状态机) | 0 | 526 | new | ✅ 状态机下沉 |
| `widgets/mood_dialog_actions.dart` (取消/保存按钮) | 0 | 42 | new | ✅ |
| `widgets/mood_quick_button.dart` (移到 presentation/widgets) | 0 | (新位置) | move | ✅ |
| **总** | **738** | **911** | +173 | (+24% 注释/接口开销) |

> 5 个新文件 712 行 + orchestrator 199 行 = 911 行 vs 原来 738 行
> **行数增加 24% 是合理代价** — 拆出来每个子 widget 有独立 doc comment + 接口注释 + import 块
> 实际业务代码减少（orchestrator 只持跨 widget 状态 + 子 widget 状态机独立）

## 2. 5 个新子 widget 接口

### `MoodScoreForm` (4 维度评分)
```dart
MoodScoreForm({
  required int score, energy, sleep, anxiety,  // 1-5
  required ValueChanged<int> onScoreChanged, onEnergyChanged,
                            onSleepChanged, onAnxietyChanged,
})
```
- **状态**：无（全部受控）
- **职责**：4 维度 1-5 评分按钮 + label + 视觉反馈
- **频度**：4 维度在 dialog 内被 sub-widgets 持有，跨 widget 状态

### `MoodTags` (标签多选)
```dart
MoodTags({
  required Set<String> selected,
  required ValueChanged<String> onToggle,  // 添加/移除 tag
})
```
- **状态**：无（受控）
- **频度**：tens/day

### `MoodTextNote` (文字备注)
```dart
MoodTextNote({
  required TextEditingController controller,
})
```
- **状态**：controller 由 parent 持有（mood_dialog.dart）
- **频度**：1+ 次/dialog

### `MoodRecorder` (录音 + STT 状态机 — 最大子 widget 526 行)
```dart
MoodRecorder({
  required MoodRecorderController controller,
})

class MoodRecorderController {
  final ValueNotifier<MoodRecorderSnapshot> snapshot;
  final void Function(Object error, MoodRecorderErrorKind kind)? onError;
  Future<void> toggleRecord();
  Future<void> togglePlay();
  Future<void> reRecord();
  void dispose();
}

class MoodRecorderSnapshot {
  final String? audioPath;
  final String finalTranscript;
  final int? audioDurationMs;
  static const empty;
}
```
- **状态机完整下沉** — recorder / player / 2 StreamSubscription / temp file / service 全在 MoodRecorder 内部
- **dispose 链完整** — try/finally 模式（v0.23 round 19B 修过的）
- **错误回调 onError** — recorder 不知道 l10n, parent 翻译成 snackbar
- **emil "decisions should be nameable"** — 4 种 error kind (start/stop/encrypt/play) 用 enum 命名

### `MoodDialogActions` (取消/保存按钮)
```dart
MoodDialogActions({
  required bool saving,
  required VoidCallback onSave,
})
```
- **频度**：1+ 次/dialog

## 3. 现有 P0/P1 修复保留验证

| 修复 | 来源 | 状态 |
|---|---|---|
| snackbar 移到 pop 前 | v0.23 round 38 P0 | ✅ mood_dialog.dart:144-152 (orchestrator) |
| dispose 链 (recorder + noteController) | v0.23 round 19B P0 | ✅ mood_dialog.dart:93-97 |
| AudioPlayer dispose 顺序 (stop → dispose) | v0.23 round 19B P0 | ✅ mood_recorder.dart (内部) |
| EncryptedAudioStorage base class | v0.23 round 41 P3 | ✅ mood_recorder.dart 用 base class |
| `_isRecording` 时 cancelRecording on dispose | v0.23 round 19B P0 | ✅ mood_recorder.dart dispose() |
| 录音 + STT 失败 graceful degrade | v0.23 round 31 P0 | ✅ onError callback 4 kind enum |

## 4. 验证结果

| 检查 | 结果 |
|---|---|
| `flutter analyze` | **0 error / 0 warning** (44 info-level 历史遗留) |
| `flutter test` | **876/876 pass** (40s) |
| `dart scripts/check_all.dart` | ✅ purity + consistency 全过 |
| `python scripts/check_cross_feature.py` | **55 files, 0 violations** (subagent 加 5 个文件后 +5) |
| `python scripts/check_arb_keys.py` | ✅ zh/en 582/582 同步 |
| `python scripts/check_no_pua.py` | ✅ 0 PUA |

## 5. emil 设计决策（教科书级）

### 5.1 状态归属
- **跨 widget 状态上抛** (orchestrator 持有): 4 维度评分 / tag Set / 文字 controller / saving / recorder controller
- **状态机下沉** (子 widget 内部): 录音机 / 播放 / STT 流 / temp file / 加密 / maxReached 180s 计时
- **不暴露 State**: MoodRecorder 用 ValueNotifier + Controller 模式, 跟 Riverpod 解耦

### 5.2 错误处理
- **recorder 不知道 l10n** — 只暴露 `onError: (error, kind) => parent 决定 snackbar 文案`
- **4 种 error kind enum** (start/stop/encrypt/play) — emil "decisions should be nameable"
- **onError 内 `if (!mounted) return`** — 防止 setState after defunct

### 5.3 dispose 链
- orchestrator dispose 链: `_recorderController.dispose() → _noteController.dispose() → super.dispose()`
- MoodRecorder 内部 dispose 链: cancelRecording (if active) → recorder.stop() → player.stop() → recorder.dispose() → player.dispose() → service cleanup → temp file delete → 2 StreamSubscription cancel

## 6. 剩余 P0 风险（3 视角共识）

| god class | 行数 | 状态 | 后续 sprint |
|---|---|---|---|
| `mood_dialog.dart` | 738 → **199** | ✅ **已拆** (本 sprint) | — |
| `notification_service.dart` | **629** | ⚠️ 仍 god class (已抽 SnoozeManager/ReminderDispatcher/BadgeSyncService 3 子) | **v0.25 Sprint #5b** (1-2 天, 抽 MedicationNotifier/AssessmentNotifier/RefillNotifier 3 子) |
| `data_export_service.dart` | **582** (逆增长 488 → 582) | ⚠️ 仍 god class (导出 + 加密 + 音频 + JSON schema 都在) | **v0.25 Sprint #5c** (1 天, 抽 ExportCryptoService/ExportAudioService/ExportSchemaService 3 子) |

## 7. 测试覆盖

- 现有 test `mood_dialog_round31_test.dart` (验证 snackbar 移到 pop 前) 保持 pass
- 新增子 widget 内部状态机测试 — subagent 设计文档中提到加，但本 sprint **未加** (留给后续 round)
- 876/876 baseline test 全过，证明重构无 regression

## 8. 后续 sprint 建议

- **v0.25 Sprint #5b**: notification_service 拆 MedicationNotifier/AssessmentNotifier/RefillNotifier 3 子
- **v0.25 Sprint #5c**: data_export 拆 ExportCryptoService/ExportAudioService/ExportSchemaService 3 子
- **v0.25 Sprint #4 第三波**: 5+ 个 600 行 page god class 续拆 (assessment_history / trend_charts / medications_list / vent_compose / medication_calendar)
- **v0.25 Sprint #6 中段**: 3 page 0 widget 测补齐 (trend / contact / settings) + Flutter test --coverage
- **v0.26+ Sprint #1**: 合规 P0 5 项律师外审
- **v0.26+ Sprint #8**: 5 厂商 push SDK 接入
