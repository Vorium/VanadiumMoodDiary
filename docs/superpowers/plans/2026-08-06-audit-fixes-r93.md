# 6 视角审计修复 (R93 阶段 2) — Implementation Plan v2

> v0.30 round 93 (sub-spec 9) — 阶段 2
> Spec: `docs/superpowers/specs/2026-08-06-audit-fixes-r93-design.md` (v1, 15KB)
> Plan author: Mavis (R84-R92 SDD 流程延续)
> Plan v1 date: 2026-08-06 (拆 god page 主线)
> **Plan v2 date: 2026-08-06** (策略调整: 隐藏未真接业务为主, 拆 god page 留 R95+)
> v2 范围变化: 8-9 task → 7 task, 25-35 commit → 12-18 commit, 估 1-2 周 → 3-5 天

## v1 → v2 策略调整 (用户最新指令: "所有需要真接的内容先隐藏")

| 维度 | v1 (拆 god page) | v2 (隐藏业务) | 理由 |
|------|------------------|----------------|------|
| 策略 | 拆 medication_calendar 642 行 + data_management 606 行 god page | 不拆, 改隐藏未真接业务入口 | R93-94 都是纯代码改动, 不动架构, 避免引入新 bug |
| 范围 | 20 项 M 难度 (拆 + UI/UX + 业务 + 文档) | 7 task 集中: FeatureFlags 加 4 新 + UI 隐藏 4 section + 量表隐藏 + 录音隐藏 + 文档一致 + 删占位 | 拆 god page 涉及 1000+ 行 sub-widget 移动, 风险大; 隐藏业务 1 个 FeatureFlag + UI hidden 即可, 风险低 |
| 业务 | 主页信息架构重排 + AudioController 抽象 + 启动 health check + trend narrative + quick mood confirm | 全部跳过 | 业务加固不解决 R92 阶段 1 暴露的 P0 blocker (PIPL §17 / Apple 2.1 拒) |
| 文档 | 30 处硬编码中文 l10n + DEPLOYMENT 阶段 5/6/7 + progress.md 整理 | 3 法律 md 一致性 + README 红 banner + DEPLOYMENT 阶段 5/6/7 + 删 fastlane 占位截图 33+9 张 | R92 已修 31 处, 剩 30 处属装饰, R95+ 批量做; 删 fastlane 占位 67 字节 png 立即生效 (Apple 拒审点) |

## Goal

按 6 视角审计 (总 410KB) 暴露的 **P0 上架 blocker (Apple 2.1 / PIPL §17 / emil 商业卡 / OEM push 业务暂停)** ,把所有**未真接业务**的入口用 FeatureFlag 守护 + UI 完全 hidden (SizeBox.shrink), 7 task, 3-5 天, 12-18 commit, baseline 1646 → 1660+ tests pass。

## Architecture (跟 R92 一致)

- 4 层架构 + 5 子层 umbrella, 不动
- TDD 风格, 红 → 绿 → commit
- 1 task 1-3 commit, 跟项目自定 `<version> round <N> (xxx): <title>` 风格
- baseline 1646 pass / 1 pre-existing fail (mood_period_aggregator 跟 R93 无关, 留 R95+)
- master commit: 1220c16 (R92 merge 后)
- worktree: `.worktrees/feat-audit-fixes-r93/`

## Global Constraints

- Flutter 3.41.9 / Dart 3.12.2 / Riverpod 3.3.2 / Drift 2.20.3 (SQLCipher) / go_router 14.6
- 4 层架构 (`domain/` 0 flutter 0 drift 0 data)
- 17 守门员脚本 (R92 已补 check_16kb_alignment 17 个)
- 跨 feature import 守门 (`check_cross_feature.py`)
- ARB key 同步 (3 语 zh / en / zh_Hant, 4 i18n 守门员)
- 中文 commit 风格
- **FeatureFlag 命名**: `_prodXxxEnabled = const false` (R66 + R72 模式, 编译期不可改)
- **hidden 而非 disabled**: UI 入口完全 `const SizedBox.shrink()`, 业务真接后翻 true

## File Structure (估)

### 新增 (~5 文件)
- `test/core/data/feature_flags_round93_test.dart` (5-8 case, 11 项 flag 守门)
- `docs/superpowers/sdd-logs/round93-audit-fixes/sdd/task-{2,3,4,5,6,7}-{brief,report}.md`
- (task 7) `assets/legal/sensitive_data_consent.md` (R93 业务暂停说明新增节)
- (task 7) `assets/legal/privacy_policy.md` (R93 业务暂停说明新增节)
- (task 7) `assets/legal/user_agreement.md` (R93 业务暂停说明新增节)

### 修改 (~10 文件)
- `lib/core/data/feature_flags.dart` (4 flag → 11 flag, 加 4 新 + 改 bootReceiver)
- `lib/presentation/pages/settings/settings_page.dart` (隐藏 IAP 商业卡 / 失联通知 / 5 厂商 push / EmailService 邮件 4 section)
- `lib/presentation/pages/settings/widgets/notification_status_card.dart` (隐藏 5 厂商 push section)
- `lib/presentation/pages/contact/contacts_list_page.dart` (隐藏入口, 仅 setup 可填)
- `lib/presentation/pages/home/widgets/home_fab_toolbar.dart` (隐藏 homeFabHotline)
- `lib/presentation/pages/assessment/assessment_center_page.dart` (隐藏 PHQ-9 / GAD-7 入口)
- `lib/presentation/pages/vent/vent_compose_page.dart` (隐藏 mic 录音 icon)
- `lib/presentation/pages/mood/widgets/mood_recorder_page.dart` (隐藏 mic 录音 icon)
- `README.md` (加红 banner: "R93 阶段 2 — 7 项未真接业务已隐藏")
- `docs/DEPLOYMENT.md` (阶段 5/6/7 补全)
- `assets/legal/{privacy_policy,sensitive_data_consent,user_agreement}.md` (业务暂停说明)

### 删除
- `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/screenshots/*.png` (33+9+9=51 张 67 字节占位, Apple 拒审点)

## Tasks (7 task, 3-5 天, 估 12-18 commit)

### Task 1: 拆 medication_calendar god page (5 commit, 2-3d) — _DONE (1646 pass)_

> v1 主线, 跟 v2 一起跑 (保持 v1 task 1 收益)

- [x] snapshot test baseline
- [x] 拆 CalendarGrid
- [x] 拆 DayDetail
- [x] 拆 Legend
- [x] cell tap 详情
- [x] final check (commit 22df332)

### Task 2: FeatureFlags 11 项硬 false + 1 项改 true→false (2-3 commit, 0.5d) — _pending_

> P0 blocker: 7 个真接业务没接, 业务不能默认开

#### Step 2.1: 改 `feature_flags.dart` L40 `_prodBootReceiverEnabled = true` → `false`

- 理由: BootReceiver 完善前 (R55 阶段), 设备重启后 WorkManager 触发可能 crash (R92 阶段 1 hidden)
- 1 commit

#### Step 2.2: 加 4 个新 FeatureFlag

- `_prodAliyunSmsEnabled = false` — 阿里云 SMS 真接前
- `_prodEmailServiceEnabled = false` — EmailService 真接 SendGrid 前
- `_prodFiveVendorPushEnabled = false` — 5 厂商 push SDK 接入前 (米/华/OPP/vivo/魅族)
- `_prodVentAudioEnabled = false` — vent audio 录音业务闭环不全
- 11 项 `_prodXxxEnabled = const false` (8 个改 false, 加原有 3 个 false)
- 1 commit

#### Step 2.3 (TDD): 写 `test/core/data/feature_flags_round93_test.dart`

- 8 case: 4 旧 flag + 4 新 flag 各自默认值 false
- 1 case: enableForTest 翻 8 个全 true
- 1 case: resetForTest 恢复 prod
- 1 commit

### Task 3: 设置页 4 section 隐藏 (2-3 commit, 0.5-1d) — _pending_

> Apple 2.1 + PIPL §17 上架 blocker

#### Step 3.1: 隐藏 IAP 商业卡 + 失联通知 section

- 改 `settings_page.dart`:
  - "立即买断" 商业卡 → `if (FeatureFlags.iapEnabled) ... else SizedBox.shrink()`
  - "失联通知" section → `if (FeatureFlags.emergencyContactEnabled) ... else SizedBox.shrink()`
- 1 commit

#### Step 3.2: 隐藏 5 厂商 push section + EmailService 邮件

- 改 `settings_page.dart`:
  - "厂商推送" section → `if (FeatureFlags.fiveVendorPushEnabled) ... else SizedBox.shrink()`
- 改 `notification_status_card.dart`:
  - "5 厂商自检" → `if (FeatureFlags.fiveVendorPushEnabled) ... else SizedBox.shrink()`
- 改 `settings_page.dart` 邮件 export section:
  - "邮件导出" → `if (FeatureFlags.emailServiceEnabled) ... else SizedBox.shrink()`
- 1 commit

#### Step 3.3 (TDD): 写 4 widget test

- 4 case: 4 section 隐藏后 render 验证 (用 `find.byType(SizedBox).evaluate()` 数 SizedBox 数)
- 1 commit

### Task 4: 联系人入口 + 主页失联 FAB 隐藏 (1-2 commit, 0.5d) — _pending_

> 病耻感 + 失联通信业务暂停 (R66 一致)

#### Step 4.1: 联系人设置入口隐藏

- 改 `contacts_list_page.dart`:
  - settings 路由跳联系人 → `if (FeatureFlags.emergencyContactEnabled) ... else SizedBox.shrink()`
  - setup step 1 保留 (首次设置可填)
- 1 commit

#### Step 4.2: 主页失联 FAB 隐藏 (homeFabHotline)

- 改 `home_fab_toolbar.dart`:
  - `_buildHotlineFab()` → `if (FeatureFlags.emergencyContactEnabled) ... else SizedBox.shrink()`
  - homeFabTop 保留 (Scrollable.ensureVisible)
- 1 commit

#### Step 4.3 (TDD): 写 2 widget test

- 2 case: 入口隐藏后 find 返回 0
- 1 commit

### Task 5: PHQ-9 / GAD-7 量表隐藏 (1 commit, 0.5d) — _pending_

> en / zh_Hant 法律责任 + 翻译不完整

#### Step 5.1: 8 量表 → 6 显 (ISI / PSS / WHODAS / Level2-* / ASRM)

- 改 `assessment_center_page.dart`:
  - PHQ-9 + GAD-7 入口 → `if (FeatureFlags.phqGad7I18nEnabled) ... else SizedBox.shrink()`
  - 6 量表保留 (R65b 阶段)
- 1 commit + test (1 case)

### Task 6: vent + mood audio 录音隐藏 (1-2 commit, 0.5d) — _pending_

> vent 录音业务闭环不全 (storage / export 业务暂停)

#### Step 6.1: vent 录音 icon 隐藏

- 改 `vent_compose_page.dart`:
  - mic 录音 button → `if (FeatureFlags.ventAudioEnabled) ... else SizedBox.shrink()`
  - 文字输入保留
- 1 commit

#### Step 6.2: mood 录音 icon 隐藏

- 改 `mood_recorder_page.dart`:
  - mic 录音 button → `if (FeatureFlags.ventAudioEnabled) ... else SizedBox.shrink()`
  - emoji 选 mood 保留
- 1 commit

#### Step 6.3 (TDD): 写 2 widget test

- 2 case: mic 隐藏后 find 返回 0
- 1 commit

### Task 7: 文档 + 删 fastlane 占位 (3-4 commit, 0.5-1d) — _pending_

> 文档一致性 + Apple 拒审点清理

#### Step 7.1: 3 法律 md 业务暂停说明 (3 commit)

- 改 `assets/legal/privacy_policy.md`:
  - 加 "v0.30 业务暂停" section: 7 项未真接业务
- 改 `assets/legal/sensitive_data_consent.md`:
  - 加同样 section
- 改 `assets/legal/user_agreement.md`:
  - 加同样 section
- 1 commit (3 文件)

#### Step 7.2: README 红 banner + DEPLOYMENT 阶段 5/6/7 (1 commit)

- 改 `README.md`:
  - 顶部加红 banner: "R93 阶段 2 — 7 项未真接业务已隐藏"
- 改 `docs/DEPLOYMENT.md`:
  - 阶段 5: Apple 完整 metadata 模板 (截图 / AppIcon / 描述 / 关键词)
  - 阶段 6: 5 项上架前手动 checklist (红色 banner)
  - 阶段 7: 部署 + 上线监控
- 1 commit

#### Step 7.3: 删 fastlane 占位截图 (1 commit)

- 删 `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/screenshots/*.png` (33+9+9=51 张 67 字节占位)
- 验证: `git status` 看到 51 文件 deleted
- 1 commit

#### Step 7.4 (TDD): 写 doc consistency test (1 commit)

- 1 case: 3 法律 md 都有 "v0.30 业务暂停" section 字符串
- 1 case: README 含 "R93 阶段 2" 字符串
- 1 case: DEPLOYMENT.md 阶段 5/6/7 节都有

### Final review + merge (1-2 commit) — _pending_

- Whole-branch review (1 subagent, 跨 R93 整 branch)
- 1-2 fix subagent per remaining Critical/Important
- merge master (R93 → master, --no-ff)
- cleanup worktree (R93 + R93 branch)
- Save SDD workspace → `docs/superpowers/sdd-logs/round93-audit-fixes/sdd/`
- update `docs/CHANGELOG.md` [0.30.0] 增 R93 entry

## Pre-existing baseline (跑前必记)

- master commit: 1220c16 (R92 merge 后)
- R93 task 1 done: baseline 1636 → 1646 pass (+10 R93)
- 1 pre-existing fail (mood_period_aggregator 跟 R93 无关, 留 R95+)
- 17 守门员全绿 (2 WARN: fullwidth / widget_dispose, 已知)
- worktree: `.worktrees/feat-audit-fixes-r93/` (已建, pub get OK)

## 验收标准 (按 spec §8)

- `flutter analyze` 0 error / 0 warning
- `flutter test` baseline 1646 → ≥1660 pass
- 17 守门员脚本全绿
- `grep -rn 'catch (_) {' lib/` → 0
- `grep -rn 'TODO (Task' lib/` → 0
- `lib/core/data/feature_flags.dart` 11 项 `_prodXxxEnabled = const false`
- 设置页 4 section hidden (IAP/失联/5 厂商/EmailService)
- 量表入口 hidden (PHQ-9/GAD-7)
- vent + mood 录音 hidden
- README 红 banner 存在
- DEPLOYMENT.md 阶段 5/6/7 都有
- 3 法律 md "v0.30 业务暂停" section 都有
- `git status` fastlane 51 占位 png 全部 deleted

## 风险与缓解 (按 spec §7)

| # | 风险 | 缓解 |
|---|------|------|
| 1 | FeatureFlag 改 false 误伤现有 test | task 2.3 TDD 8 case 验证 + 17 守门员全绿 |
| 2 | UI hidden 引入新 widget tree layout bug | widget test + Visual regression (snapshot) |
| 3 | 量表入口隐藏影响 6 量表 list 布局 | 6 量表 widget 已有, 列表渲染测试 |
| 4 | 录音 icon 隐藏影响 vent / mood 主流程 | text / emoji input 保留, 录音仅 1 button 删 |
| 5 | 3 法律 md 加 section 后需 3 lang 一致 (zh/en/zh_Hant) | 守门员 check_arb_keys / check_zh_hant_consistency |
| 6 | 删 fastlane png 误删正式截图 | `67 字节占位` 特征 grep 验证, 设计师正式截图不在 fastlane/metadata 下 |
| 7 | worktree .gitignore 状态不同步 | merge 前跑 baseline test |

## 一句话总结 (v2)

按 6 视角审计 (总 410KB) 暴露的 **7 项未真接业务 P0 blocker**, 全部 FeatureFlag 守护 + UI hidden, 7 task, 3-5 天, 12-18 commit, baseline 1646 → 1660+ tests pass。
