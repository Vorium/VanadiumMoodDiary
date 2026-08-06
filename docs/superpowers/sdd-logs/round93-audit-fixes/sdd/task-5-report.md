# Task 5 Report — PHQ-9 / GAD-7 量表隐藏

> v0.30 round 93 (audit-fixes) sub-spec 9, task 5
> Worktree: `D:\Batch\chroniccare\.worktrees\feat-audit-fixes-r93\`
> Branch: `feat/audit-fixes-r93`
> Baseline: master 1220c16 (R92 merge) + R93 task 4 done (1664 tests pass)
> 实施日期: 2026-08-06

## Status

**DONE** — 1 commit, 1666 tests pass (+2 R93 task 5), 17 守门员全绿, PHQ-9 / GAD-7 量表完全 hidden, 保留 8 量表 (ISI / PSS / WHODAS / Level2-* 4 / ASRM)。

## 完成项

- [x] assessment_center_page.dart 隐藏 PHQ-9 / GAD-7 (phqGad7I18nEnabled gate)
- [x] chart 顶部 chip 列表也走同一份 filtered scales (避免 stale chip)
- [x] TDD 写 `assessment_center_page_r93_hide_test.dart` (2 case)
- [x] 修 1 个老 test 适配 R93 策略 (assessment_center_page_round90: setUp 翻 phqGad7I18nEnabled=true)
- [x] final check (17 守门员 + flutter analyze + flutter test)

## commit

- `44783e3` v0.30 round 93 (ui): 隐藏 PHQ-9 / GAD-7 量表 (phqGad7I18nEnabled gate, 8 开放保留)

## 文件清单

| 文件 | 操作 | 行数变化 |
|------|------|---------|
| `lib/presentation/pages/assessment/assessment_center_page.dart` | 改 | 105 → 113 行 (+8) |
| `test/presentation/pages/assessment/assessment_center_page_r93_hide_test.dart` | 新 | 87 行 |
| `test/presentation/pages/assessment/assessment_center_page_round90_test.dart` | 改 | 130 → 144 行 (+14) |

## 验证

### flutter test

- **R93 baseline**: 1664 → 1666 pass (+2 R93 task 5, 0 regression)
- **R93 2 case** (新 test 文件):
  - 1) phqGad7I18nEnabled 默认 false → 8 开放 + 2 unavailable = 10 Card, PHQ-9 / GAD-7 隐藏 (findsNothing) ✓
  - 2) phqGad7I18nEnabled=true → 10 开放 + 2 unavailable = 12 Card, PHQ-9 / GAD-7 渲染 (findsWidgets) ✓
- **修 1 老 test**:
  - assessment_center_page_round90: 4 case 走 setUp 翻 phqGad7I18nEnabled=true, 4 case 全过 ✓
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

### 1. 隐藏 PHQ-9 / GAD-7,保留 8 量表

- 当前 10 开放量表: phq9, gad7, isi, pss, whodas, level2_depression, level2_anxiety, level2_mania, asrm, level2_psychosis
- R93 隐藏 phq9 + gad7,保留 8 (isi / pss / whodas / level2_* 4 / asrm)
- 走 [FeatureFlags.phqGad7I18nEnabled] gate,默认 false hidden
- 2 unavailable 量表 (nsesss, crdpss) 仍渲染 (跟 FeatureFlag 无关)

### 2. chart 顶部 chip 列表也走同一份 filtered scales

- assessment_center_page 顶部 AssessmentMultiLineChart 有 chip 列表 (10 量表 toggle)
- chart 默认走 `AssessmentColorPalette.allScaleIds` (10 开放)
- R93 改后 grid 8+2 但 chart chip 仍 10 → PHQ-9 chip 单独渲染 (跟 hidden 状态不一致)
- 修法: AssessmentMultiLineChart 加 `scaleIds: scales.map((s) => s.id).toList()` 参数
- chart 跟 grid 走同一份 filtered scales,hidden 时 chip 也消失

### 3. 修 1 老 test 用 setPhqGad7I18nEnabledForTest

- assessment_center_page_round90 假设 10 开放 + 2 unavailable = 12 Card
- 加 setUp 翻 `FeatureFlags.setPhqGad7I18nEnabledForTest(true)` 让 4 case 不破
- tearDown resetForTest 恢复 prod 默认 (跟 task 3/4 修老 test 模式一致)

### 4. PHQ-9 / GAD-7 业务含义

- 16 题 + 严重度 + 危机电话完整 i18n 走完 ARB 时 (R65b 阶段开启)
- 现状: zh 全量翻译 OK,en / zh_Hant 翻译不完整 (题目 + 严重度 + 危机电话)
- 法律责任: en / zh_Hant 用户看到的题目如果 fallback 英文,会引发医疗合规问题 (题目严肃性 + 严重度判断)
- R93 阶段 2 隐藏是临时保护,翻译完善后翻 phqGad7I18nEnabled=true 立即恢复

## 后续 (本 task 不做, 留 task 6-7)

- **Task 6**: vent + mood audio 录音隐藏 (vent_compose_page.dart + mood_recorder_page.dart)
- **Task 7**: 3 法律 md + README 红 banner + DEPLOYMENT 阶段 5/6/7 + 删 fastlane 占位截图

## 风险

| 风险 | 缓解 | 状态 |
|------|------|------|
| PHQ-9 / GAD-7 隐藏影响用户抑郁/焦虑筛查 | 8 量表保留,临床覆盖 (失眠 / 压力 / 残疾 / 躁狂 / 精神病性 等) | ✅ |
| chart chip 跟 grid 不一致 | chart 走同一份 filtered scales | ✅ |
| 修 1 老 test 引入新 bug | 修法只动 setUp/tearDown, 业务逻辑 0 改 | ✅ |

## 不在本批做的事 (按 brief)

- ❌ 改 spec / plan / progress.md (R93 主流程维护)
- ❌ vent / mood audio 录音 hidden (留 task 6)
- ❌ 文档 + 删 fastlane 占位 (留 task 7)
- ❌ 翻译完善 PHQ-9 / GAD-7 en / zh_Hant (留 R95+ 长期)
