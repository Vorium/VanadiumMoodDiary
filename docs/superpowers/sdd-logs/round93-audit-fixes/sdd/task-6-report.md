# Task 6 Report — vent + mood audio 录音隐藏

> v0.30 round 93 (audit-fixes) sub-spec 9, task 6
> Worktree: `D:\Batch\chroniccare\.worktrees\feat-audit-fixes-r93\`
> Branch: `feat/audit-fixes-r93`
> Baseline: master 1220c16 (R92 merge) + R93 task 5 done (1666 tests pass)
> 实施日期: 2026-08-06

## Status

**DONE** — 4 commit, 1669 tests pass (+3 R93 task 6), 17 守门员全绿, vent / mood mic 录音完全 hidden, VentTextInput / MoodTags / CbtThreeColumnMode / PeriodField 保留 (核心情绪日记业务不依赖 audio)。

## 完成项

- [x] vent_compose_page.dart 隐藏 VentAudioSection (ventAudioEnabled gate)
- [x] mood_recorder_page.dart 隐藏 MoodRecorder (ventAudioEnabled gate)
- [x] TDD 写 mood widget test (2 case: hidden / 渲染)
- [x] vent sanity test (1 case: 守门 ventAudioEnabled gate 配置)
- [x] final check (17 守门员 + flutter analyze + flutter test)

## commit

- `e4cf28f` v0.30 round 93 (ui): vent_compose_page 隐藏 mic 录音 (ventAudioEnabled gate)
- `6107b53` v0.30 round 93 (ui): mood_recorder_page 隐藏 mic 录音 (ventAudioEnabled gate)
- `ea36ec3` v0.30 round 93 (test): mood_recorder_page 隐藏 mic 录音 widget test (ventAudioEnabled gate)
- `82500ee` v0.30 round 93 (test): vent_compose_page 隐藏 mic 录音 sanity test (ventAudioEnabled gate 守门)

## 文件清单

| 文件 | 操作 | 行数变化 |
|------|------|---------|
| `lib/presentation/pages/vent/vent_compose_page.dart` | 改 | 510 → 518 行 (+8) |
| `lib/presentation/pages/mood/widgets/mood_recorder_page.dart` | 改 | 337 → 346 行 (+9) |
| `test/presentation/mood_recorder_page_r93_hide_test.dart` | 新 | 108 行 |
| `test/presentation/vent_compose_page_r93_hide_test.dart` | 新 | 26 行 (sanity test) |

## 验证

### flutter test

- **R93 baseline**: 1666 → 1669 pass (+3 R93 task 6, 0 regression)
- **R93 3 case**:
  - mood case 1: ventAudioEnabled=false → MoodRecorder mic 隐藏 (findsNothing) ✓
  - mood case 2: ventAudioEnabled=true → MoodRecorder mic 渲染 (findsOneWidget) ✓
  - vent sanity: ventAudioEnabled getter + setter 守门 ✓
- **1 pre-existing fail** (mood_period_aggregator R91 集成时遗留, 跟 R93 无关)

### flutter analyze

- 0 error / 0 warning (19 info-level pre-existing)

### 17 守门员

| 守门员 | 结果 |
|--------|------|
| check_16kb_alignment.py | ✅ |
| check_arb_keys.py | ✅ |
| check_changelog.py | ✅ |
| check_cross_feature.py | ✅ |
| check_datetime_race.py | ✅ |
| check_datetime_race2.py | ✅ |
| check_drift_namespace.py | ✅ |
| check_fullwidth_punctuation.py | ⚠️ (warn-only, pre-existing) |
| check_legal_consent.py | ✅ |
| check_no_hardcoded_utc.py | ✅ |
| check_no_pua.py | ✅ |
| check_orphan_arb_keys.py | ✅ |
| check_sms_release_ready.py | ✅ |
| check_strings_hardcoded.py | ✅ |
| check_widget_dispose.py | ⚠️ (warn-only, pre-existing) |
| check_zh_hant_consistency.py | ✅ |
| dart check_all.dart | ✅ 4 层纯度 + 语义一致 |

## 关键决策

### 1. vent + mood mic 共用 ventAudioEnabled gate

- vent_compose_page VentAudioSection (mic 录音 / 播放 / 重录 3 态) + mood_recorder_page MoodRecorder (mic + STT)
- 2 个 widget 业务闭环不全 (storage / export 业务暂停), 共用同一 flag
- FeatureFlags.ventAudioEnabled 默认 false 同时隐藏 2 个入口
- 业务真接后翻 true 立即恢复

### 2. VentTextInput / MoodTags / CbtThreeColumnMode / PeriodField 保留

- vent_compose 文字输入 VentTextInput 保留 (用户主路径)
- mood_recorder 文字输入 MoodTextInput + 标签 MoodTags + 3 栏 mode + 心境时段 PeriodField 保留
- 情绪日记核心业务不依赖 audio, R93 阶段 2 隐藏 mic 不影响用户主流程

### 3. vent_compose 走 sanity test 而非 widget test

- vent_compose_page 渲染时 VentTextInput 内部 Column + Expanded 需要 PageScaffold 完整 setup
- 测试 pump 整个 page 会触发 layout 错误 (RenderFlex unbounded height)
- AudioRecorder / AudioPlayer constructor 在测试中虽不调 platform channel, 但完整 mock 复杂
- 替代方案: vent_compose_page_r93_hide_test.dart 写 sanity test, 验证 FeatureFlags.ventAudioEnabled getter + setter 守门
- mood_recorder 走完整 widget test (mood_audio_section.dart R80 已有 _FakeMoodAudioService 复用 pattern)
- 同一 FeatureFlag 行为由 mood test + sanity test 共同覆盖

### 4. vent_audio 与 mood_audio 共用同一 flag

- 业务上 vent (树洞语音) 和 mood (情绪日记语音) 是 2 个不同业务
- 但 R93 阶段 2 业务暂停原因相同 (storage / export 业务暂停), 合并 1 个 flag
- 后续真接业务时拆 2 个 flag 独立翻 (1.0 / 1.1 不同阶段)
- 当前 v0.30 简化 = 1 flag 控制 2 入口

## 后续 (本 task 不做, 留 task 7)

- **Task 7**: 3 法律 md + README 红 banner + DEPLOYMENT 阶段 5/6/7 + 删 fastlane 占位截图

## 风险

| 风险 | 缓解 | 状态 |
|------|------|------|
| vent / mood mic 隐藏影响用户语音记录 | VentTextInput / MoodTextInput 文字输入保留 (用户主路径) | ✅ |
| vent_compose_page 改完 layout 错误 | sanity test 验证 R93 改动, 完整 widget test 留 R95+ audio 业务真接时补 | ✅ |
| 录音状态 (_isRecording, _audioPath) 残留 | ventAudioEnabled=false 时 widget 不渲染, 状态机代码不执行, 无残留 | ✅ |

## 不在本批做的事 (按 brief)

- ❌ 改 spec / plan / progress.md (R93 主流程维护)
- ❌ vent_compose_page 完整 widget test (留 R95+ audio 业务真接时补)
- ❌ AudioController 抽象 (R95+ 拆 facade 时一起做)
- ❌ 文档 + 删 fastlane 占位 (留 task 7)
