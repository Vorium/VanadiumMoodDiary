# 6 视角审计修复 (R93 阶段 2) — Implementation Plan

> v0.30 round 93 (sub-spec 9) — 阶段 2
> Spec: `docs/superpowers/specs/2026-08-06-audit-fixes-r93-design.md` (14696 bytes)
> Plan author: Mavis (R84-R92 SDD 流程延续)
> Plan date: 2026-08-06

## Goal

按 6 视角审计 (总 410KB) 合并的 **20 项 P0 阶段 2 M 难度修复**, 5-7 task, 1-2 周, 估 25-35 commit, baseline 1636 → 1670+ tests pass。

## Architecture (跟 R92 一致)

- 4 层架构 + 5 子层 umbrella, 不动
- TDD 风格, 红 → 绿 → commit
- 1 task 1-2 commit, 跟项目自定 `<version> round <N> (xxx): <title>` 风格
- baseline 1636 pass / 1 pre-existing (mood_period_aggregator 跟 R93 无关, 期望 R93 修或留 R95+)
- master commit: 1220c16 (R92 merge 后)
- worktree: `.worktrees/feat-audit-fixes-r93/`

## Global Constraints

- Flutter 3.41.9 / Dart 3.12.2 / Riverpod 3.3.2 / Drift 2.20.3 (SQLCipher) / go_router 14.6
- 4 层架构 (`domain/` 0 flutter 0 drift 0 data)
- 17 守门员脚本 (R92 已补 check_16kb_alignment 17 个, AGENTS.md 已 16→17)
- 跨 feature import 守门 (`check_cross_feature.py`)
- ARB key 同步 (3 语 zh / en / zh_Hant, 4 i18n 守门员)
- 中文 commit 风格

## File Structure (估)

### 新增 (~20 文件)
- `lib/presentation/pages/medication/widgets/medication_calendar_grid.dart` (180 行)
- `lib/presentation/pages/medication/widgets/medication_calendar_day_detail.dart` (150 行)
- `lib/presentation/pages/medication/widgets/medication_calendar_legend.dart` (60 行)
- `lib/presentation/pages/settings/widgets/data_management_export.dart` (180 行)
- `lib/presentation/pages/settings/widgets/data_management_reports.dart` (160 行)
- `lib/presentation/pages/settings/widgets/data_management_destroy.dart` (160 行)
- `lib/presentation/providers/export_providers.dart` (新, 4 provider)
- `lib/presentation/widgets/audio_controller.dart` (interface, 100 行)
- `lib/presentation/widgets/audio_recorder_widget.dart` (150 行, 共享)
- `lib/presentation/widgets/audio_player_widget.dart` (120 行, 共享)
- `test/core/data/services/safety_watch_service_round93_test.dart` (5 case)
- `test/core/data/services/email_service_round93_test.dart` (5 case)
- `test/presentation/pages/medication/medication_calendar_split_round93_test.dart` (snapshot)
- `test/presentation/pages/settings/data_management_split_round93_test.dart` (snapshot)
- `test/presentation/pages/settings/settings_page_redesign_round93_test.dart` (4 group)
- `test/presentation/pages/home/home_page_redesign_round93_test.dart` (5 widget)
- `test/presentation/widgets/audio_controller_round93_test.dart` (5 case)
- + task-1/2/3/4/5/6/7 brief + report

### 修改 (~25 文件)
- `lib/presentation/pages/medication/medication_calendar_page.dart` (642 → ~250 行)
- `lib/presentation/pages/settings/widgets/data_management_section.dart` (606 → ~200 行)
- `lib/presentation/pages/settings/settings_page.dart` (8 section → 4 group)
- `lib/presentation/pages/home/home_page.dart` (8 widget → 5 widget)
- `lib/main.dart` (加 _bootstrapHealthCheck 步骤 7)
- `lib/core/data/services/data_export_service.dart` (删 facade)
- 多文件: vent_compose / vent_detail / mood_recorder (用 AudioController)
- 多文件: 14 文件 30 处硬编码中文 → l10n (R92 已修 31, 剩 30)
- `docs/DEPLOYMENT.md` (阶段 5/6/7 补全)
- `lib/presentation/pages/contact/contacts_list_widget.dart` (5 步 → 3 步)

### 删除
- `lib/core/data/services/data_export_service.dart` (facade 删)

## Tasks (5-7 task, 1-2 周, 估 25-35 commit)

### Task 1: 拆 medication_calendar god page (5 commit, 2-3d)

#### Step 1.1 (TDD): 写 snapshot test baseline
- 写 `test/presentation/pages/medication/medication_calendar_split_round93_test.dart`
  - 3 状态: 列表 / 日历 / 详情
  - snapshot 验证拆前 baseline
- 跑绿 (旧 god page 渲染快照)

#### Step 1.2: 拆 CalendarGrid sub-widget
- 新增 `lib/presentation/pages/medication/widgets/medication_calendar_grid.dart` (~180 行)
  - 30 天热力图 + 颜色 + 单元格
  - 接受 props: medicationLogs (Map<DateTime, List<MedicationLog>>) + onCellTap
- 改 `medication_calendar_page.dart` 引用 CalendarGrid
- 跑绿 (snapshot 一致)
- 1 commit

#### Step 1.3: 拆 DayDetail sub-widget
- 新增 `lib/presentation/pages/medication/widgets/medication_calendar_day_detail.dart` (~150 行)
  - 单日详情 (med log list + 补打 dialog)
  - 接受 props: date + logs + onAddLog
- 改 `medication_calendar_page.dart` 引用 DayDetail
- 跑绿
- 1 commit

#### Step 1.4: 拆 Legend sub-widget
- 新增 `lib/presentation/pages/medication/widgets/medication_calendar_legend.dart` (~60 行)
  - 颜色图例 (服药 / 漏服 / 缺药)
  - 接受 props: locale
- 改 `medication_calendar_page.dart` 引用 Legend
- 跑绿
- 1 commit

#### Step 1.5: 加 tap 详情 (R93 task 8)
- 改 `medication_calendar_page.dart` 的 CalendarGrid onCellTap → 跳 DayDetail
- 复用 R92 task 3 跑出的 day detail pattern
- 跑绿
- 1 commit

#### Step 1.6: final check
- `wc -l medication_calendar_page.dart` < 250 行
- `flutter test test/...medication_calendar_split_round93_test.dart` 3 状态 pass
- 17 守门员全绿
- 1 commit (report + 守门)

### Task 2: 拆 data_management_section god section (4 commit, 2d)

#### Step 2.1 (TDD): 写 snapshot test baseline
- 写 `test/presentation/pages/settings/data_management_split_round93_test.dart`
  - 3 子功能: 导出 / 报告 / 销毁
  - snapshot baseline
- 跑绿

#### Step 2.2: 拆 ExportSubSection
- 新增 `lib/presentation/pages/settings/widgets/data_management_export.dart` (~180 行)
  - 6 行 → 1 Card: 导出 JSON (consent + 风险文字 + 复制)
- 改 `data_management_section.dart` 引用 ExportSubSection
- 1 commit

#### Step 2.3: 拆 ReportsSubSection
- 新增 `lib/presentation/pages/settings/widgets/data_management_reports.dart` (~160 行)
  - 3 行 → 1 Card: CBT PDF / 用药报告 / 历史
- 改引用
- 1 commit

#### Step 2.4: 拆 DestroySubSection
- 新增 `lib/presentation/pages/settings/widgets/data_management_destroy.dart` (~160 行)
  - 1 行 → 1 Card: 清空所有数据 (destructive red)
- 改引用
- 1 commit

#### Step 2.5: final check
- `wc -l data_management_section.dart` < 200 行
- snapshot pass
- 1 commit (report + 守门)

### Task 3: 设置页 4 group 重构 (3 commit, 1d)

#### Step 3.1 (TDD): 写 test
- 写 `test/presentation/pages/settings/settings_page_redesign_round93_test.dart`
  - 4 group 都有 visible header
  - 8 section 拆到 7 (评估挪到 /assessment 路由, 不放设置)
- 跑绿 (旧版)

#### Step 3.2: 4 group 重构
- 改 `settings_page.dart`:
  - 8 section → 4 group (用户档案 / 提醒 / 数据 / 法律) + 评估 路由跳
  - 用 `groupValue` deprecated, 改 RadioGroup (R93 analyzer warning 修)
- 跑绿
- 1 commit

#### Step 3.3: final check
- 跑 `check_widget_dispose` 守门员
- 跑 `check_strings_hardcoded` (设置页 14 处硬编码中文 l10n 化)
- 1 commit (report + 守门 + analyzer warning 修)

### Task 4: data_export_service facade 删 + 4 sub provider 化 (3 commit, 1d)

#### Step 4.1: 4 sub 改 provider 化
- 删 `lib/core/data/services/data_export_service.dart` (110 行 facade)
- 4 sub (`export_orchestrator.dart` + `export_pipeline.dart` + `export_schema_service.dart` + `export_import_pipeline.dart`) 各自加 `Provider` 暴露
- 新增 `lib/presentation/providers/export_providers.dart` 集中 4 provider
- 改 6-8 个 import 路径
- 跑绿
- 1 commit

#### Step 4.2: EmailService mock test
- 写 `test/core/data/services/email_service_round93_test.dart` (5 case)
  - mock 真接路径 / isProductionReady 守门 / 4 字段齐全
  - 跟 SMS round57 模式一致
- 跑绿
- 1 commit

#### Step 4.3: final check
- 跑 `check_all.dart` (4 层架构纯度)
- 1 commit (report + 守门)

### Task 5: 主页信息架构重排 + UI/UX 修复 (5 commit, 1-2d)

#### Step 5.1 (TDD): 写 test
- 写 `test/presentation/pages/home/home_page_redesign_round93_test.dart`
  - 5 widget 都有 (hero 缩 60dp / 居中打卡 88dp / today med 折叠 / secondary 折叠 / footer 缩 40dp)
- 跑绿 (旧版)

#### Step 5.2: 主页 8 widget → 5 widget 重排
- 改 `home_page.dart`:
  - HomeHeroIllustration 缩 60dp + 渐变 alpha 0.15+ (R93 task 6)
  - 删除 Spacer(1)
  - 打卡按钮 88dp 高 + 居中 (primary action dominant)
  - TodayMedSchedule + SecondaryActionRow 折叠 (drawer)
  - HomeFooter 缩 40dp
- 1 commit

#### Step 5.3: 主页 3 icon button 加 tooltip
- 改 `home_page.dart` HeaderAction (趋势 / 评估 / 设置)
- 加 `Tooltip` widget (R93 task 12)
- 1 commit

#### Step 5.4: trend_4_StatCard 改 narrative
- 改 `lib/presentation/pages/trend/trend_summary.dart`:
  - 4 个 StatCard (连续天数 / 最长 / 总打卡 / 总天数) → 1 narrative ("连续 5 天, 总 23 天")
  - 复用 R90 AssessmentSparkline 模式
- 1 commit

#### Step 5.5: quick_mood_carousel 1 tap 加 confirm
- 改 `quick_mood_carousel.dart`:
  - 1 tap 写 mood → 0 confirm bug fix
  - 加 snackbar / haptic 反馈
- 1 commit

### Task 6: 业务加固 (5 commit, 1-2d)

#### Step 6.1: 启动加 _bootstrapHealthCheck
- 改 `lib/main.dart`:
  - 6 步 (load dotenv / migrate / init notification / validate release / migrateIfNeeded / runApp) 后加 7 步
  - `_bootstrapHealthCheck` 跑 LastErrorCapture.lastError 检查
  - `runZonedGuarded` 启动
- 1 commit

#### Step 6.2: safety_watch_service unit test (DST/跨年)
- 写 `test/core/data/services/safety_watch_service_round93_test.dart` (5 case)
  - DST 跨年 (春季 / 秋季) / 24h 边界 / 跨月 / 跨时区
  - 用 `tz.local` 不用 `DateTime` (R40 fix 模式)
- 1 commit

#### Step 6.3: AudioController 抽象 + vent + mood 共享
- 新增 `lib/presentation/widgets/audio_controller.dart` (interface, 100 行)
  - `AudioController` interface (play / pause / stop / recordStart / recordStop / position stream)
- 新增 `audio_recorder_widget.dart` (150 行) + `audio_player_widget.dart` (120 行) 共享
- 改 vent_compose / vent_detail / mood_recorder 用 AudioController
- 减少 ~200 行重复代码
- 1 commit

#### Step 6.4: vent 长按/swipe 加 tooltip
- 改 `vent_list_page.dart`:
  - 加 1 次性 Tooltip 提示气泡 ("左滑删除" / "长按删除")
  - SharedPreferences 标记已显示
- 1 commit

#### Step 6.5: 紧急联系人 5 步 → 3 步
- 改 `contacts_list_widget.dart`:
  - 5 步 (点 + → 填名字+手机 → ConsentDialog → 添加 → snackbar) → 3 步 (点 + → 表单 + consent 内联 → 保存)
  - ConsentDialog 嵌入表单
- 1 commit

### Task 7: 文档 + i18n (3 commit, 0.5d)

#### Step 7.1: 14 文件 30 处硬编码中文 → l10n (剩 30 处)
- grep `Text\(\s*['"][\u4e00-\u9fff]`
- 改 30 处用 AppLocalizations.of(context).xxxKey
- 跑 4 i18n 守门员
- 1 commit

#### Step 7.2: DEPLOYMENT.md 阶段 5/6/7 补全
- 改 `docs/DEPLOYMENT.md`:
  - 阶段 5: Apple 完整 metadata 模板 (截图 / AppIcon / 描述 / 关键词)
  - 阶段 6: 5 项上架前手动 checklist (红色 banner)
  - 阶段 7: 部署 + 上线监控
- 1 commit

#### Step 7.3: progress.md 跨 R70+ 整理
- 改 `docs/`:
  - CI/CD 决策 (R62 R72 keystore)
  - 部署决策 (R67 Sprint 1 撤回真生效)
  - CHANGELOG 链接
- 1 commit

### Final review + merge (1-2 commit)

- Whole-branch review (1 subagent, 跨 R93 整 branch)
- 1-2 fix subagent per remaining Critical/Important
- merge master (R93 → master, --no-ff)
- cleanup worktree (R93 + R93 branch)
- Save SDD workspace → `docs/superpowers/sdd-logs/round93-audit-fixes/sdd/`
- update `docs/CHANGELOG.md` [0.30.0] 增 R93 entry

## Pre-existing baseline (跑前必记)

- master commit: 1220c16 (R92 merge 后)
- baseline 1636 pass / 1 pre-existing fail (mood_period_aggregator 跟 R93 无关, 留 R95+)
- 17 守门员全绿 (2 WARN: fullwidth / widget_dispose, 已知)
- worktree: `.worktrees/feat-audit-fixes-r93/` (已建, pub get OK)

## 验收标准 (按 spec §8)

- `flutter analyze` 0 error / 0 warning
- `flutter test` baseline 1636 → ≥1670 pass
- 17 守门员脚本全绿
- `grep -rn 'catch (_) {' lib/` → 0
- `grep -rn 'TODO (Task' lib/` → 0
- `grep -rn '硬编码中文' lib/` → 0
- `wc -l lib/presentation/pages/medication/medication_calendar_page.dart` < 250
- `wc -l lib/presentation/pages/settings/widgets/data_management_section.dart` < 200
- `wc -l lib/presentation/pages/settings/settings_page.dart` 4 group 分类
- `lib/core/data/services/data_export_service.dart` 已删

## 风险与缓解 (按 spec §7)

| # | 风险 | 缓解 |
|---|------|------|
| 1 | 拆 2 个 600+ 行 god page 引入新 bug | snapshot test 验证 (R92 模式) + props callback 模式 |
| 2 | 主页信息架构重排破坏现有用户习惯 | FeatureFlag `homeRedesignEnabled` 控制 |
| 3 | AudioController 抽象 vent + mood 不兼容 | 抽 interface + 4 widget 各自 adapter |
| 4 | safety_watch_service unit test 跨 DST 边界不准确 | 用 `tz.local` 不用 `DateTime` (R40 fix 模式) |
| 5 | 30 处硬编码中文 l10n 后 ARB key 数量破 1100 | 跑 `check_arb_keys.py` 守门, key 数量不限 |
| 6 | worktree .gitignore 状态不同步 | merge 前跑 baseline test |

## 一句话总结

按 6 视角审计 (总 410KB) 合并的 **20 项 P0 阶段 2 M 难度修复**, 5-7 task, 1-2 周, 估 25-35 commit, baseline 1636 → 1670+ tests pass。
