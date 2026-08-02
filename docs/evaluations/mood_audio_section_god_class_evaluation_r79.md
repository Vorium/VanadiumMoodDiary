# mood_audio_section god class 评估 (v0.28 R79)

> **背景 (R76 报告)**:
> `lib/presentation/pages/mood/widgets/mood_audio_section.dart` 591 行 (R76
> 估 591, 实际 R79 量 591), 升为新最大 god class 候选 (R74 报告 R64 拆
> mood_dialog 1204 → 实际 R64 已拆, 误判)。
>
> R76 建议拆 3 sub-widget, R77 → R78 → R79 0 改善, R79 评估 + 留 R80+ 拆。

## 1. 现状

`mood_audio_section.dart` 591 行, 主 widget `MoodRecorder` (ConsumerStateful):

| 元素 | 行范围 | 行数 | 职责 |
|---|---|---|---|
| `MoodRecorderSnapshot` (immutable) | 42-62 | 20 | 状态快照 (录音 / 播放 / 资源) |
| `MoodRecorderController` | 63-92 | 29 | 资源初始化 + dispose 编排 |
| `MoodRecorder extends ConsumerStatefulWidget` | 94-102 | 8 | widget 壳 |
| `_MoodRecorderState` | 103-585 | 482 | 完整 state + build |
| └─ `initState` | 126-135 | 10 | 初始化 |
| └─ `_initializeStt` | 137-143 | 6 | 初始化 STT |
| └─ `dispose` | 144-171 | 27 | cancel + dispose |
| └─ `_disposeResources` | 173-224 | 51 | 资源释放顺序 |
| └─ `_toggleRecord` | 226-232 | 6 | toggle 入口 |
| └─ `_startRecording` | 234-265 | 31 | 开始录音 |
| └─ `_stopRecording` | 267-328 | 61 | 停止录音 + 加密 |
| └─ `_reRecord` | 330-354 | 24 | 重录 |
| └─ `_togglePlay` | 356-405 | 49 | toggle 播放 |
| └─ `build` | 407-585 | 178 | UI 渲染 |

总 method body 约 350 行 (482 - 178 build - 36 initState/dispose - 其他)。

## 2. R76 建议拆 3 sub-widget

| Sub-widget | Method | 估行数 | 评估 |
|---|---|---|---|
| `AudioRecorderControls` | `_toggleRecord` + `_startRecording` + `_stopRecording` + `_reRecord` + record button UI | ~180 | **可抽** (state-bound 但职责清晰) |
| `AudioRecorderPlayer` | `_togglePlay` + play button + progress UI | ~80 | **可抽** (low risk) |
| `AudioRecorderSTT` | `_initializeStt` + STT result display | ~50 | **可抽** (跟 speech_to_text plugin 解耦) |

抽完 MoodRecorder 主 widget 减到 ~270 行 (State 含 _disposeResources 资源链 51 行留主), 仍 1 个 widget, 但职责清晰, 后续易测。

## 3. R79 跳过真拆原因

1. **业务编排 + 资源链耦合**: `_disposeResources` (51 行) 是录音停止 +
   加密 + 资源释放完整链, 跟 `_startRecording` (31 行) 共享 recorder 实例
   + temp file path, 抽 sub-widget 需把 recorder 实例和 temp path 状态
   lift up 到父 State, 改动较大 (1-2h)。
2. **加密链路**: mood_dialog 加密 / 解密 / temp file 清理跨 3 个 method
   (`_stopRecording` 写加密 + `_reRecord` 删旧 + `_disposeResources` 收尾),
   抽完跨 widget boundary 容易出错。
3. **集成测缺失**: 0 widget test (R74 报), 跟 home_page 同样问题 —
   改完无测保。
4. **R76 报告 P3-5 标"中等风险, 估 2-3h"**, R79 留作 R80+ 配集成测一起做。

## 4. R80+ 路线

### R80 (估 3-4h)
1. 写 mood_audio_section widget 测 8 case (R77 spec 已列):
   - idle / recording / recorded 3 状态转换
   - STT graceful degrade (无 STT 支持时 fallback)
   - dispose 资源清理链 (跟 R79-1 vent_compose 异步 dispose 同模式验证)
   - temp file 加密 round-trip
   - reRecord 重置
   - maxReached 3min 上限
   - onPlayerComplete
2. 抽 `AudioRecorderPlayer` (最低风险, 80 行 sub-widget, 跟主 widget 通过 callback 通信)
3. 跑测 + commit

### R81 (估 2-3h)
1. 抽 `AudioRecorderControls` (180 行, 跨 _startRecording + _stopRecording
   资源状态, 中风险)
2. 跑测 + commit

### R82 (估 1-2h)
1. 抽 `AudioRecorderSTT` (50 行, 解耦 speech_to_text plugin)
2. 跑测 + commit

## 5. 决策记录

| 决策 | 原因 |
|---|---|
| R79 写评估 doc | 跟 home_page 评估同步, 给 R80+ 完整路线 |
| R80 优先 Player (low risk) | 80 行 sub-widget, 测保护下风险低 |
| R81 再 Controls (medium risk) | 跨资源状态, 跟测一起保 |
| R82 最后 STT (low risk) | 解耦 plugin, 留最后 |
| 资源链 (51 行) 留主 widget | `_disposeResources` 跨多 method 共享, 留主 widget 减少 bug |
