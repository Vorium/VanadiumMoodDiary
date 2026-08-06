# Task 4 Report — 联系人入口 + 主页失联 FAB 隐藏

> v0.30 round 93 (audit-fixes) sub-spec 9, task 4
> Worktree: `D:\Batch\chroniccare\.worktrees\feat-audit-fixes-r93\`
> Branch: `feat/audit-fixes-r93`
> Baseline: master 1220c16 (R92 merge) + R93 task 3 done (1662 tests pass)
> 实施日期: 2026-08-06

## Status

**DONE** — 3 commit, 1664 tests pass (+2 R93 task 4), 17 守门员全绿, 主页 homeFabHotline 完全 hidden, 联系人 section 已 task 3 隐藏, setup wizard step 1 保留可填。

## 完成项

- [x] home_fab_toolbar.dart 隐藏 homeFabHotline (emergencyContactEnabled gate)
- [x] homeFabTop 保留 (回到顶端, 不依赖 emergencyContactEnabled)
- [x] TDD 写 `home_fab_toolbar_r93_hide_test.dart` (2 case)
- [x] 修 2 个老 test 适配 R93 隐藏策略 (home_emil_round81 + home_fab_toolbar_round92)
- [x] 联系人入口: settings 联系人 section (task 3 已 hidden) + setup wizard step 1 (保留, 首次设置可填)
- [x] final check (17 守门员 + flutter analyze + flutter test)

## commit

- `b9ff0ba` v0.30 round 93 (ui): 隐藏 home_fab_toolbar 主页失联 hotline FAB (emergencyContactEnabled gate)
- `4d14a72` v0.30 round 93 (test): home_fab_toolbar hidden homeFabHotline widget test (emergencyContactEnabled gate)
- `bcbd55a` v0.30 round 93 (test): 老 test 适配 R93 阶段 2 hidden 策略 (homeFabHotline emergencyContactEnabled gate)

## 文件清单

| 文件 | 操作 | 行数变化 |
|------|------|---------|
| `lib/presentation/pages/home/widgets/home_fab_toolbar.dart` | 改 | 226 → 235 行 (+9) |
| `test/presentation/pages/home/home_fab_toolbar_r93_hide_test.dart` | 新 | 163 行 |
| `test/presentation/home_emil_round81_test.dart` | 改 | 120 → 134 行 (+14) |
| `test/presentation/pages/home/home_fab_toolbar_round92_test.dart` | 改 | 181 → 194 行 (+13) |

## 验证

### flutter test

- **R93 baseline**: 1662 → 1664 pass (+2 R93 task 4, 0 regression)
- **R93 2 case** (新 test 文件):
  - 1) emergencyContactEnabled 默认 false → homeFabHotline hidden (findsNothing), homeFabTop + 日常追踪 + 心情树洞 渲染 (3 FAB 总) ✓
  - 2) emergencyContactEnabled=true (enableForTest) → homeFabHotline 渲染 (findsOneWidget) ✓
- **修 2 老 test**:
  - home_emil_round81: 走 setUp 翻 enableForTest (8 flag 全 true), 3 HomeFabToolbar case + 3 SectionHeader case 全过 ✓
  - home_fab_toolbar_round92: 走 setUp 翻 enableForTest, 2 case 全过 ✓
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

### 1. 主页 homeFabHotline 隐藏,homeFabTop 保留

- homeFabHotline (紧急热线) → 走 emergencyContactEnabled gate, 默认 false hidden
- homeFabTop (回到顶端) → 保留, 不依赖 emergencyContactEnabled (R92 真接 scrollController, 业务无关)
- 4 FAB 工具按钮: 日常追踪 + 心情树洞 + [homeFabHotline hidden] + 回到顶端 = 3 FAB 总
- 展开后用户看到 3 个功能按钮 (R81 减 1, 业务暂停体现)

### 2. 联系人入口 = settings 联系人 section (task 3 已 hidden) + setup wizard step 1 (保留)

- settings 联系人 section: R93 task 3 已 hidden (走 emergencyContactEnabled gate)
- setup wizard step 1 联系人表单: 保留 (首次设置可填, 由 setup_page.dart 内部处理)
- contacts_list_widget.dart L43 push '/contacts/new' 是 dead code (路由没注册) — 后续 R95+ 删

### 3. homeFabHotline 业务含义

- 当前 homeFabHotline push '/crisis-hotline' (R92 改), 5 地区列表 + 800-810-1117 全国
- 这是 **公益危机热线** 入口, 跟失联通知是不同的业务 (一个是"联系公益机构", 一个是"通知自己联系人")
- 但 R93 阶段 2 把整个失联通信业务暂停, 主页"紧急热线"入口也连带 hidden
- 理由: 病耻感 + 失联通信业务暂停, 用户在小米/华为手机上看到"紧急热线"会想到"我是不是被失联了", 影响体验
- 危机热线真接业务时 (1.0), 翻 emergencyContactEnabled=true 立即恢复

### 4. 修 2 老 test 用 enableForTest 模式

- home_emil_round81: 3 HomeFabToolbar case 假设 4 FAB 总渲染, setUp 翻 enableForTest
- home_fab_toolbar_round92: 2 case 同假设, setUp 翻 enableForTest
- enableForTest 翻 8 个全 true, 跟 R67 阶段兼容 (28 个老 test 模式一致)
- 跟 task 3 修 settings_page_round45 + notification_status_card_round20 模式一致

## 后续 (本 task 不做, 留 task 5-7)

- **Task 5**: PHQ-9 / GAD-7 量表隐藏 (assessment_center_page.dart)
- **Task 6**: vent + mood audio 录音隐藏 (vent_compose_page.dart + mood_recorder_page.dart)
- **Task 7**: 3 法律 md + README 红 banner + DEPLOYMENT 阶段 5/6/7 + 删 fastlane 占位截图

## 风险

| 风险 | 缓解 | 状态 |
|------|------|------|
| homeFabHotline 隐藏影响用户紧急联系 | 危机热线 (1.0) 真接业务时翻 emergencyContactEnabled=true 立即恢复 | ✅ |
| 联系人 section hidden 影响 setup 阶段填 | setup wizard step 1 保留, 走 setup_page.dart 独立流程 | ✅ |
| 修 2 老 test 引入新 bug | 修法只动 setUp/tearDown, 业务逻辑 0 改 | ✅ |

## 不在本批做的事 (按 brief)

- ❌ 改 spec / plan / progress.md (R93 主流程维护)
- ❌ 量表 / 录音 hidden (留 task 5-6)
- ❌ 文档 + 删 fastlane 占位 (留 task 7)
- ❌ 删 contacts_list_widget.dart L43 dead code (留 R95+ 清理)
