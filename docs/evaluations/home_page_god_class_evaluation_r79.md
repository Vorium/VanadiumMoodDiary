# home_page god class 评估 (v0.28 R79)

> **背景 (R74 报告 P3-1)**:
> home_page.dart 678 行 (R74 631 → R76 678 → R78 估 680), 仍偏 god class.
> R76 → R78 3 轮 0 改善, R74 报告 P3-1 建议抽 3 helper class:
> `HomeDeepLinkHandler` / `HomeCareEngineDispatcher` / `HomeCelebrationController`,
> 减到 ~450 行。
>
> **R79 评估结论**: 跳过真抽, 改写此评估 doc + 撤回 R79 attempt helper。
>
> 抽 helper 评估见下文。

## 1. 现状

`lib/presentation/pages/home/home_page.dart` 678 行含:

| Method | 行数 | 职责 |
|---|---|---|
| `initState` | 16 行 | init _playerCompleteSub |
| `dispose` | 18 行 | cancel timer + cleanup |
| `_handleDeepLink` | 50 行 | 3 路径 (medId / autofire / reason=safety) |
| `_autofireMedicationCheckIn` | 30 行 | 打卡 + 弹庆祝 + GoRouter |
| `_showMedicationHint` | 10 行 | snackbar info |
| `_runSafetyCheck` | 36 行 | safety watch + snackbar |
| `build` | 113 行 | PageScaffold + 8 sub-widget |
| `_onCheckIn` | 32 行 | 打卡成功 + 庆祝 + cancel snooze + 触发 safety + care |
| `_runAfterCheckIn` | 26 行 | 打卡后 safety check |
| `_fireCareEngine` | 76 行 | use case 调 + 4 channel dispatch |
| `_snooze5Min` | 24 行 | 5min 后本地通知 |
| `_celebrationFor` | 7 行 | 5 档庆祝文案 switch |
| `_showCelebrationOverlay` | 49 行 | OverlayEntry + Timer dismiss |

总 method body ~480 行 (678 - 113 build - 16 initState - 18 dispose - 50 misc = 481)。

## 2. R74 P3-1 建议 3 helper class

| Helper | Method | 行数 | 评估 |
|---|---|---|---|
| `HomeDeepLinkHandler` | `_handleDeepLink` + `_autofireMedicationCheckIn` + `_showMedicationHint` | 90 | **可抽** (low risk) |
| `HomeCareEngineDispatcher` | `_runSafetyCheck` + `_runAfterCheckIn` + `_fireCareEngine` + `_snooze5Min` | 162 | **中风险** (跨 _lifecycle 状态机) |
| `HomeCelebrationController` | `_celebrationFor` + `_showCelebrationOverlay` | 56 | **高耦合** (跟 _celebrationOverlayEntry 字段强绑定, 抽完需 lift field up) |

## 3. R79 实际尝试 + 跳过原因

### R79 attempt: 抽 HomeDeepLinkHandler (1 helper)

**R79 wrote**:
- `lib/presentation/pages/home/widgets/home_deep_link_handler.dart` 6.8KB
- 3 method (handleDeepLink / autofireMedicationCheckIn / showMedicationHint)
- 接 ref + context + lifecycle callback + timer callback

**撤回原因**:
1. **lifecycle 状态机跨类**: HomeLifecycleState enum + _lifecycle field 是 State
   内部 state, helper 改需 callback 传 (setLifecycle), 增加 caller 心智 + 4
   个参数。
2. **Timer 跨类**: `_deepLinkRaceTimer` 是 State field, helper 改需 callback
   setDeepLinkRaceTimer 透传 Timer 出去给 caller 管 cancel。
3. **庆祝 overlay 强耦合**: `_autofireMedicationCheckIn` 调 `_showCelebrationOverlay`,
   抽 helper 后这个调用要降级为 snackbar-only (R79 attempt 选这条路,
   但失去原 Haptics.success + 庆祝 overlay 体验)。
4. **集成测缺失**: home_page 0 widget test, R79 同时抽 + 改业务, 改完无 test
   保护, 风险高。

**撤回 action**: helper 文件移到 `scripts/_archive/home_deep_link_handler_r79_attempt.dart`。
评估结论: 真抽需要:
- (a) 同时写 home_page 集成测 5+ case (R80 任务)
- (b) helper 接受 `BuildContext` + `WidgetRef` + `HomeLifecycleState`
  + `ValueChanged<HomeLifecycleState>` + `ValueChanged<Timer>` 共 5 参数
- (c) 抽 `HomeCelebrationController` 时把 `_celebrationOverlayEntry` 字段
  也 lift up 到 State (跟 _showCelebrationOverlay 一起搬)

## 4. R80+ 路线 (Sprint 2 续)

按 R79 评估 + R77 audit 同步:

### R80 (估 4-6h)
1. 写 home_page 集成测 10 case (deep link 4 + care engine 4 + celebration 2)
   - 跟 R78 setup_page 集成测同模式
   - 保护现有 678 行行为
2. 抽 `HomeDeepLinkHandler` (基于 R79 attempt, 调整参数设计)
3. 抽 `HomeCelebrationController` (lift overlay entry field)
4. 跑全测 + commit

### R81+ (估 4-6h)
1. 抽 `HomeCareEngineDispatcher` (跨 lifecycle, 风险最高)
2. 写 home_page care engine 集成测 5 case

### R82+ (估 2-3h)
1. mood_audio_section 拆 3 sub-widget (AudioRecorderControls +
   AudioRecorderPlayer + AudioRecorderSTT)
2. 写 mood_audio_section widget 测 8 case (R77 spec)

### 集成测 backlog (R80+)
- export_orchestrator 集成测 5 case (R77 拆 2 file 后, R39 已加 50+ 单元
  测, 但 export + import **完整链** + vent 加密 round-trip 跨版本升级
  的集成测还没写)
- notification_service facade 集成测 5 case (init 顺序 + ID 范围 +
  showSafetyAlert 3 态)
- vent_compose_page dispose 异步回归测 (R79-1 修后补)
- care_engine integration 5 case (decision/strategy 4 channel)

## 5. 决策记录

| 决策 | 原因 |
|---|---|
| R79 撤回 helper | 1-2h 改完无测保, 风险高于价值 |
| R79 改写评估 doc | 给 R80 抽 helper 完整路线图, 避免重蹈覆辙 |
| helper 进 `_archive/` | 保留 R79 attempt 写过的代码, R80 真抽时可参考 |
| R80 优先写测 | 测保现有行为, 后续抽 helper 风险低 |
| 3 helper class 不合并 | 各自独立, 方便 R80/R81/R82 分 round 拆 |
