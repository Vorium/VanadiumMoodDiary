# Task 3 Report — 设置页 4 section 隐藏

> v0.30 round 93 (audit-fixes) sub-spec 9, task 3
> Worktree: `D:\Batch\chroniccare\.worktrees\feat-audit-fixes-r93\`
> Branch: `feat/audit-fixes-r93`
> Baseline: master 1220c16 (R92 merge) + R93 task 2 done (1657 tests pass)
> 实施日期: 2026-08-06

## Status

**DONE** — 4 commit, 1662 tests pass (+5 R93 task 3), 17 守门员全绿, 设置页 4 section 全 hidden (iapEnabled/emergencyContactEnabled/fiveVendorPushEnabled/emailServiceEnabled gate)。

## 完成项

- [x] settings_page.dart 隐藏 IAP 商业卡 (iapEnabled gate)
- [x] settings_page.dart 隐藏联系人 section (emergencyContactEnabled gate)
- [x] notification_status_card.dart 隐藏 OEM 引导 (fiveVendorPushEnabled gate)
- [x] assessment_section.dart 隐藏邮件预览 (emailServiceEnabled gate)
- [x] TDD 写 `settings_page_r93_hide_test.dart` (5 case)
- [x] 修 2 个老 test 适配 R93 隐藏策略 (notification_status_card_round20 + settings_page_round45)
- [x] final check (17 守门员 + flutter analyze + flutter test)

## commit

- `dd0fb30` v0.30 round 93 (ui): settings_page 隐藏 IAP 商业卡 + 联系人 section (iapEnabled/emergencyContactEnabled gate)
- `c360ee8` v0.30 round 93 (ui): 隐藏 notification_status OEM 引导 + assessment 邮件预览 (fiveVendorPushEnabled/emailServiceEnabled gate)
- `c8ff846` v0.30 round 93 (test): settings_page 4 section hidden widget test (iap/emergency/fiveVendorPush/emailService)
- `8d31d8c` v0.30 round 93 (test): 老 test 适配 R93 阶段 2 hidden 策略 (notification_status OEM + settings_page 联系人)

## 文件清单

| 文件 | 操作 | 行数变化 |
|------|------|---------|
| `lib/presentation/pages/settings/settings_page.dart` | 改 | 242 → 263 行 (+21) |
| `lib/presentation/pages/settings/widgets/notification_status_card.dart` | 改 | 401 → 410 行 (+9) |
| `lib/presentation/pages/settings/widgets/assessment_section.dart` | 改 | 124 → 134 行 (+10) |
| `test/presentation/pages/settings/settings_page_r93_hide_test.dart` | 新 | 129 行 |
| `test/presentation/notification_status_card_round20_test.dart` | 改 | 142 → 152 行 (+10) |
| `test/presentation/pages/settings/settings_page_round45_test.dart` | 改 | 145 → 153 行 (+8) |

## 验证

### flutter test

- **R93 baseline**: 1657 → 1662 pass (+5 R93 task 3, 0 regression)
- **R93 5 case** (新 test 文件):
  - 1) 4 flag 默认 false → 4 section 全 hidden (findsNothing × 4) ✓
  - 2) iapEnabled=true → IAP 商业卡渲染 (workspace_premium icon) ✓
  - 3) emergencyContactEnabled=true (enableForTest) → ContactsListWidget 渲染 ✓
  - 4) emailServiceEnabled=true → 邮件预览 Card 渲染 ("预览停药通知邮件") ✓
  - 5) fiveVendorPushEnabled=true → OEM 引导 ExpansionTile 渲染 ("国产手机没收到通知？") ✓
- **修 2 老 test**:
  - notification_status_card_round20 (5 case): 走 setUp 翻 fiveVendorPushEnabled=true, 全过 ✓
  - settings_page_round45 "contacts data 1" (1 case): 走 enableForTest 翻 emergencyContactEnabled=true, 全过 ✓
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

### 1. 4 section 跨 3 文件,统一 FeatureFlag gate 模式

- IAP 商业卡 + 联系人 section 在 `settings_page.dart` (2 处)
- 5 厂商 OEM 引导在 `notification_status_card.dart` (1 处)
- 邮件预览在 `assessment_section.dart` (1 处)
- 全部走 `if (FeatureFlags.xxxEnabled) ... else SizedBox.shrink()` 模式
- spread operator `[...]` 用于多 widget block 条件渲染

### 2. "5 厂商 push section" 实际未建,隐藏的是 OEM 引导

- 当前代码里没独立的"5 厂商 push 自检" section (feature_flags 注释提到但 UI 还没建)
- "5 厂商自检" = NotificationStatusCard 内 OEM 引导 ExpansionTile (_OemBackgroundHint)
- 业务语义:OEM 引导是给小米/华为等国产 ROM 用户解释"通知收不到"用的文字清单
- 跟 5 厂商 push SDK 接入不是同一业务, 但跟国产 ROM 通知链路相关, R93 阶段 2 跟随策略一并 hidden
- 后续真接 5 厂商 push SDK 时, OEM 引导可考虑重新放回 (跟 SDK 集成文档对应)

### 3. 修 2 个老 test 适配 hidden 策略 (R93 副作用)

- notification_status_card_round20: 老 test 假设 OEM 引导总是渲染, 加 setUp 翻 fiveVendorPushEnabled=true
- settings_page_round45: 老 test "contacts data 1" 假设联系人总是渲染, 用 enableForTest 翻 8 个全 true
- 不动老 test 的逻辑结构, 只在 setUp/tearDown 加 FeatureFlag 翻起/恢复
- 跟 R92 修 28 个老 test 的模式一致 (R67 阶段 FeatureFlags 推广)

### 4. 联系人 section 设置页入口 hidden, setup step 1 保留

- 联系人 section 隐藏 (settings 入口), 但 setup wizard step 1 仍可填 (首次设置流程独立 gate)
- 跟 R66 阶段策略一致: 数据模型/repository 全部保留, 业务暂停零成本
- 后续真接业务后, 改 FeatureFlags.emergencyContactEnabled=true 立即恢复

## 后续 (本 task 不做, 留 task 4-7)

- **Task 4**: 联系人入口 + 主页失联 FAB 隐藏 (contacts_list_page.dart + home_fab_toolbar.dart)
- **Task 5**: PHQ-9 / GAD-7 量表隐藏 (assessment_center_page.dart)
- **Task 6**: vent + mood audio 录音隐藏 (vent_compose_page.dart + mood_recorder_page.dart)
- **Task 7**: 3 法律 md + README 红 banner + DEPLOYMENT 阶段 5/6/7 + 删 fastlane 占位截图

## 风险

| 风险 | 缓解 | 状态 |
|------|------|------|
| 4 section hidden 误伤现有用户 | 4 flag 全 const false, 编译期锁定, 真接后改源码翻 true | ✅ |
| OEM 引导隐藏后用户收不到通知 | 主屏"测试通知"自检卡保留 (NotificationStatusCard 4 个入口只 hidden 第 4 个) | ✅ |
| 联系人 section hidden 误伤 setup step 1 | setup wizard 独立 gate 控制, 首次设置仍可填 | ✅ |
| 修 2 老 test 引入新 bug | 修法只动 setUp/tearDown, 业务逻辑 0 改 | ✅ |

## 不在本批做的事 (按 brief)

- ❌ 改 spec / plan / progress.md (R93 主流程维护)
- ❌ 联系人入口 + 主页失联 FAB 隐藏 (留 task 4)
- ❌ 量表 / 录音 hidden (留 task 5-6)
- ❌ 文档 + 删 fastlane 占位 (留 task 7)
