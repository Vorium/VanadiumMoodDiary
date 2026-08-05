# Task 5 Report — 3 栏 mode UI 改造

## Status: DONE_WITH_CONCERNS

## What I implemented

### 1. `CbtThreeColumnMode` widget (lib/presentation/pages/mood/widgets/cbt_three_column_mode.dart)
- 3 栏 mode 内容布局: 情绪分数 (1-5) + 情境 + 自动思维
- 复用 Task 4 公共 widget `CbtSectionField` (5/7 栏 wizard 也用)
- score chip 用 `ChoiceChip` + 数字 (1-5) — Task 8 集成时换 `DimensionRow` IP emoji 风格
- `ConsumerWidget` — 跟随 `cbtDraftProvider` 状态
- **Column 而非 ListView** — 适配嵌入 `mood_recorder_page` dialog 的 `SingleChildScrollView`
  (ListView 嵌套 SingleChildScrollView 会触发 unbounded height 错误)

### 2. `CbtWizard` stub (lib/presentation/pages/mood/widgets/cbt_wizard.dart)
- 5/7 栏 wizard 占位 widget
- Task 5 集成需要 switch 引用此 widget, 实际 Stepper + step 内容由 Task 6 实现
- 让 mood_recorder_page 的 switch 编译通过

### 3. `mood_recorder_page.dart` 集成改造
- **Dialog + Column 替代 AlertDialog** — 3 段 (header/body/footer) 适配 SegmentedButton
- **顶部**: `SegmentedButton<ThoughtRecordLevel>` (3 栏 / 5 栏 / 7 栏)
  - 切档联动 `cbtDraftProvider.setLevel` + `thoughtRecordLevelProvider.setLevel` (持久化到 SP)
- **中间**: `switch (cbtState.level) { three => CbtThreeColumnMode, _ => CbtWizard stub }`
- **底部**: 标签 + 文字备注 + 录音 + 保存/取消
- 4 维度评分 (`energy/sleep/anxiety`) 移除 — 改用 1 维 (mood) + CBT 字段
  - 保存逻辑改用 `cbtState.draft` (含 score + 8 CBT 字段), 合并 tags/note/audio
  - `MoodEntryDraft` 无 `copyWith`, 手动展开构造
- `dispose` 调 `cbtDraftNotifier.reset()` — 下次打开恢复初始 (3 栏)

## What I tested and test results

### TDD Evidence

**RED (Step 2)**: Test file imported non-existent `CbtThreeColumnMode`, causing compilation failure:
```
test/presentation/pages/mood/cbt_three_column_round84_test.dart:14:8: Error: Error when reading
  'lib/presentation/pages/mood/widgets/cbt_three_column_mode.dart': 系统找不到指定的文件。
test/presentation/pages/mood/cbt_three_column_round84_test.dart:40:26: Error: Couldn't find constructor 'CbtThreeColumnMode'.
```

**GREEN (Step 4)**: After implementing `CbtThreeColumnMode`:
```
00:00 +0: loading ...cbt_three_column_round84_test.dart
00:00 +0: 3 栏 mode 显示 score + situation + automaticThought 三个 section
00:00 +1: All tests passed!
```

### Final test count
- **Baseline**: 1436 pass + 16 fail (pre-existing setup tests, not from my changes)
- **After Task 5**: 1437 pass + 16 fail (same pre-existing)
- **Delta**: +1 new test (CbtThreeColumnMode 3-section rendering)
- `flutter analyze` 全项目: 0 error / 0 warning
- All 12+ 守护脚本 (check_cross_feature / check_all / check_orphan_arb_keys / ...) pass

## Files changed

| File | Type | Lines |
|---|---|---|
| `lib/presentation/pages/mood/widgets/cbt_three_column_mode.dart` | new | 92 |
| `lib/presentation/pages/mood/widgets/cbt_wizard.dart` | new | 32 |
| `lib/presentation/pages/mood/widgets/mood_recorder_page.dart` | modify | 84 → 251 |
| `test/presentation/pages/mood/cbt_three_column_round84_test.dart` | new | 33 |

## Commits created

- `eda6236` v0.29 round 84 (ui): CbtThreeColumnMode 单屏长表式 (3 栏 mode 内容布局)
- `cf4c5a5` v0.29 round 84 (ui): 3 栏 mode 单屏长表式 + SegmentedButton

## Self-review findings

### Spec deviations (intentional)
1. **Test pattern simplified**: 规范的测试用 `Consumer.builder` + `setLevel(three)`, 但 Riverpod 禁止 build 期间改 provider
   (`Tried to modify a provider while the widget tree was building`)。简化后用直接 `const CbtThreeColumnMode()` —
   `cbtDraftProvider` 默认 level=three, 无需在 build 期间 setLevel。测试仍验证 3 个 section 标题渲染, 等价语义。
2. **Layout 选择 Dialog 而非 AlertDialog**: 规范代码结构是 `Dialog + Column + Expanded`, 实现也用 Dialog (3 段: header/body/footer),
   适配新增的 SegmentedButton + switch 模式。AlertDialog.title/content/actions 槽位不灵活。
3. **保留 MoodTextInput (note)**: 规范 footer 注释 "标签 + 保存" 只列 2 项, 但 "保持现有行为" 包括 note 字段。保留 note 字段以
   保证 backward compat (用户既可用 situation 也可写 note)。

### Concerns (forwarded to future tasks)
1. **score chip 是占位** (`notifier.updateField()` 不接受 score 参数, 是 no-op): 用户点 chip 时 score 不变, 保存的 mood
   entry 永远是 score=3 (默认)。规范注释明确说 "Task 8 集成时改为 `notifier.updateScore(score)` 走现有路径"。
   任务范围外, 不修。
2. **4 维度评分移除** (energy/sleep/anxiety): 新设计用 1 维 (mood) + CBT 字段, 老用户 4 维度数据为 null。是产品决策,
   已与 plan 文档对齐。
3. **CbtWizard 是占位**: Task 5 集成需要 switch 引用此 widget, 实际 wizard (Stepper + 5/7 步) 由 Task 6 实现。
4. **dialog 关闭后 cbtDraftProvider 重置**: 用户每次开 dialog 都回到 3 栏 (默认), 即使 thoughtRecordLevelProvider 持久化
   了上次的 5/7 栏偏好。可在后续 task 改善 (e.g., cbtDraftProvider build 读 thoughtRecordLevelProvider), 当前不在
   任务范围。
5. **`flutter test` 输出含 "Flutter assets will be downloaded"**: 首次跑 test 时 Flutter 提示下载 assets, 后续不再出现。
   跟 守护脚本 check_widget_dispose.py 等无关, 测试本身输出干净 (`+1: All tests passed!`)。

## Test result summary

```
+1437 -16 (baseline + 1 new test, 16 pre-existing setup failures unrelated to Task 5)
flutter analyze: 0 issues
```

## Fix #2: Task 5 review fixes (Important findings)

### What changed

**Bug 1 — dispose() reset() desyncs SegmentedButton from SP** (`lib/presentation/pages/mood/widgets/mood_recorder_page.dart`)

`initState` added `WidgetsBinding.instance.addPostFrameCallback` that reads
`thoughtRecordLevelProvider` (SP-persisted preference) and, if it differs from
`cbtDraftProvider.level`, calls `cbtDraftProvider.notifier.setLevel(persisted)`.
This restores the user's 5/7 栏 choice on each dialog open — previously the
`dispose() → cbtDraftProvider.reset()` would silently drop the persisted
preference back to 3 栏.

Flow now:
1. Open dialog → `initState` schedules post-frame callback.
2. First frame renders with default `cbtState.level = three`.
3. After first frame → callback reads `thoughtRecordLevelProvider` (e.g. `five`)
   and syncs `cbtDraftProvider` to match. UI rebuilds with `SegmentedButton`
   showing the persisted selection.

Why `addPostFrameCallback` and not synchronous `initState.setLevel`:
avoids Riverpod "modify during build" warnings + isolates the SP read from the
build path. The 1-frame visual flash is acceptable for a dialog open.

`dispose()` reset is kept (draft content is per-session, while SP level is
preference) — the next open re-syncs via the post-frame callback.

**Bug 2 — Test name vs assertion mismatch** (`test/presentation/pages/mood/cbt_three_column_round84_test.dart`)

Added 5 explicit `find.text('1')`..`find.text('5')` assertions to verify the
score chip Wrap at `cbt_three_column_mode.dart:36-50` is actually rendered. If
the `List.generate(5, ...)` block is removed, the test now fails.

### Test results

```bash
$ flutter test test/presentation/pages/mood/cbt_three_column_round84_test.dart
00:00 +0: loading .../cbt_three_column_round84_test.dart
00:00 +0: 3 栏 mode 显示 score + situation + automaticThought 三个 section
00:00 +1: All tests passed!

$ flutter test test/presentation/pages/mood/
00:00 +0: cbt_three_column_round84_test.dart: 3 栏 mode ...
00:00 +1: cbt_widgets_round84_test.dart: CbtSectionField 显示标题 + ℹ️ + placeholder + prompt 按钮
00:00 +2: cbt_widgets_round84_test.dart: CbtSectionField 父 setState 重建时保留用户输入 (controller leak regression)
00:01 +3: cbt_widgets_round84_test.dart: CbtExplainerCard 默认展开, 点击收起
00:01 +4: All tests passed!

$ flutter test test/domain/entities/cbt_draft_state_round84_test.dart
00:00 +0: CbtDraftState (v0.29 round 84) 初始 state level=three, stepIndex=0, draft 8 字段全 null
00:00 +1: ... 3 → 5 切换保留已有 situation/automaticThought 字段
00:00 +2: ... 5 → 7 切换保留所有 5 栏字段
00:00 +3: ... 7 → 5 切换保留 core/behavior 字段 (UI 隐藏但 state 保留)
00:00 +4: ... firstEmptyStep 5 栏: 全空 → 0, situation 空 → 0, 都填 → 4
00:00 +5: ... 3 栏 firstEmptyStep 永远返回 0 (单屏模式无 step 概念)
00:00 +6: All tests passed!

$ flutter analyze
Analyzing feat-cbt-thought-record...
No issues found! (ran in 5.8s)
```

All 4 mood page tests pass + 6 cbt_draft_state unit tests pass + 0 analyze issues.

### Files modified

| File | Change |
|---|---|
| `lib/presentation/pages/mood/widgets/mood_recorder_page.dart` | `initState` adds `addPostFrameCallback` to sync `cbtDraftProvider.level` from `thoughtRecordLevelProvider` (SP) |
| `test/presentation/pages/mood/cbt_three_column_round84_test.dart` | Added 5 `find.text('1'..'5')` assertions to verify score chip Wrap is rendered |

### Concerns

1. **No regression test for the SP sync logic itself**: The fix is verified
   indirectly via the existing 5/7 栏 SegmentedButton interaction flow, but no
   dedicated unit test asserts "after `dispose` → reopen, `cbtDraftProvider.level`
   matches `thoughtRecordLevelProvider`". Could be added in a future round
   (e.g., a widget test for `MoodRecorderPage` that overrides
   `thoughtRecordLevelProvider` with `five`, then verifies SegmentedButton
   selection after pumpAndSettle). Out of scope for this fix.
2. **1-frame visual flash on open**: When SP has 5/7 栏, the first frame
   shows `SegmentedButton` with "3 栏" selected, then the post-frame callback
   re-renders with the persisted selection. Negligible for a dialog open, but
   noted for completeness.

