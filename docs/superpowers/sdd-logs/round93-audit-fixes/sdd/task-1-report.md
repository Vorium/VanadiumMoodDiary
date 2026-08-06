# Task 1 Report — 拆 medication_calendar god page

> v0.30 round 93 (audit-fixes) sub-spec 9, task 1
> Worktree: `D:\Batch\chroniccare\.worktrees\feat-audit-fixes-r93\`
> Branch: `feat/audit-fixes-r93`
> Baseline: master 1220c16 (R92 merge) + R93 worktree bootstrap OK
> 实施日期: 2026-08-06

## Status

**DONE** — 6 commit, 1646 tests pass (+10 R93), 17 守门员全绿, medication_calendar_page.dart 446→209 行 (< 250)。

## 完成项

- [x] snapshot test baseline (4 测试: 列表态 / 日历态 / 日历态 + 打卡 / times=[])
- [x] 拆 CalendarGrid sub-widget (317 行, props: meds + checkIns + days + selectedDate + onCellTap)
- [x] 拆 DayDetail sub-widget (144 行, props: date + checkIns + meds + onAddLog)
- [x] 拆 Legend sub-widget (96 行, 4 色块 + l10n)
- [x] cell tap 详情 (ConsumerStatefulWidget + _selectedDate state + onCellTap)
- [x] final check (17 守门员 + flutter analyze + flutter test)

## commit

- `f3712d0` v0.30 round 93 (test): medication_calendar 3 状态 snapshot test (拆前 baseline)
- `3a8d333` v0.30 round 93 (refactor): medication_calendar_page 拆 CalendarGrid sub-widget (446→217 行)
- `6955324` v0.30 round 93 (refactor): medication_calendar_page 拆 DayDetail sub-widget
- `fdcba20` v0.30 round 93 (refactor): medication_calendar_page 拆 Legend sub-widget (155 行)
- `b639ac7` v0.30 round 93 (ui): medication_calendar cell tap → day detail 详情

## 文件清单

| 文件 | 行数 | 角色 |
|------|------|------|
| `lib/presentation/pages/medication/medication_calendar_page.dart` | 209 | 父 page (state + 布局, 拆前 446) |
| `lib/presentation/pages/medication/widgets/medication_calendar_grid.dart` | 317 | 30/7/90 天热力图 + 颜色 + EmptyState |
| `lib/presentation/pages/medication/widgets/medication_calendar_day_detail.dart` | 144 | 单日详情 (日期 + log list + 补打卡 button) |
| `lib/presentation/pages/medication/widgets/medication_calendar_legend.dart` | 96 | 4 色块 (漏服 / <50% / <100% / 100%) |
| `test/presentation/pages/medication/medication_calendar_split_round93_test.dart` | 387 | 10 R93 测试 (4 baseline + 4 DayDetail + 1 Legend + 1 cell tap 集成) |
| `lib/l10n/app_zh.arb` + `app_en.arb` + `app_zh_Hant.arb` | +25 行 / lang | 8 新 ARB key (DayDetail 5 + Legend 3) × 3 lang |

## 验证

### flutter test

- **R93 baseline**: 1636 → 1646 pass (+10 R93, 0 regression)
- **R93 10 测试**:
  - 1) 列表态: 空药物 → "还没有在用药物" EmptyState
  - 2) 日历态: 1 药 + 30 天无打卡 → 漏服 / 100% 图例 + 时间窗口
  - 3) 日历态: 1 药 + 1 打卡 → 网格 + 药名 + 时间窗口
  - 日历态: times=[] → "未设置服用时间" EmptyState
  - DayDetail 单日有打卡 → 日期头部 + 打卡 list + 药名
  - DayDetail 单日无打卡 → EmptyState + 补打卡 button
  - DayDetail onAddLog 回调 → 点 button 触发
  - DayDetail onAddLog=null → 不显示 button
  - Legend 渲染 4 色块 + 4 标签
  - cell tap 集成: 点 today cell → DayDetail 显示 today 08:30 log
- **R13C 8 测试**: 全过 (medication_calendar_round13c_test.dart, 无 regression)

### flutter analyze

- 0 error / 0 warning
- 19 info-level (pre-existing in master, 无新增)

### 17 守门员

| 守门员 | 结果 |
|--------|------|
| check_arb_keys.py | ✅ zh_Hant synchronized with zh (1054 keys) |
| check_changelog.py | ✅ pubspec=0.30.0+85 |
| check_cross_feature.py | ✅ 103 files, 0 violations |
| check_datetime_race.py | ✅ 0 race |
| check_datetime_race2.py | ✅ 0 race |
| check_drift_namespace.py | ✅ 13 @DataClassName, 0 duplicates |
| check_fullwidth_punctuation.py | ⚠️ 131 violations (warn-only, pre-existing) |
| check_legal_consent.py | ✅ 无 TODO |
| check_no_hardcoded_utc.py | ✅ 0 硬编码 |
| check_no_pua.py | ✅ 0 PUA |
| check_widget_dispose.py | ⚠️ 1 pre-existing (HomeFabToolbar, 不可见式, 人工 review) |
| check_orphan_arb_keys.py | ✅ 1054 zh, 0 orphan, en 1054, zh_Hant 1054 |
| check_sms_release_ready.py | ✅ AliyunSmsProvider 一致 |
| check_strings_hardcoded.py | ✅ 32 处 R57 override 配对 |
| check_zh_hant_consistency.py | ✅ 1054 keys, 100% 一致 |
| check_16kb_alignment.py | ✅ done |
| dart check_all.dart | ✅ 4 层纯度 + 语义一致 |

### 行数

- `medication_calendar_page.dart`: **446 → 209** (< 250, 满足 brief)
- 3 sub-widget: 317 + 144 + 96 = 557 行 (拆前 inline ~ 270 行)
- 净增: 287 行 (注释 + sub-widget 文档 + props boilerplate)

## 关键决策

### 1. CalendarGrid 接受预过滤数据 (R92 模式)

- **不**接受 raw Provider, 接受 props (meds + checkIns + days)
- 父 page 走 StreamProvider → data → sub-widget
- 避免 sub-widget 读全局 state (R92 props callback 一致)

### 2. DayDetail "补打卡" 暂 stub

- `_onAddLogStub(date)` 当前只显示 SnackBar "补打卡功能接入中 (YYYY-MM-DD)"
- 完整实现待 R93 task 4 (schema) / task 5 (Repository 扩展 `at` 参数)
- 不影响 cell tap → DayDetail 显示的核心功能 (task 1.5 主目标)

### 3. selectedDate 用 page state (非 navigation)

- brief 提到 "Navigator.push + MaterialPageRoute 或 Provider state 切换"
- 选 Provider state 切换 (in-page state): 简单, 不用 back stack, 用户体验更顺
- ConsumerStatefulWidget + `DateTime? _selectedDate` state
- Cell tap → `setState(_selectedDate = day)` → DayDetail 出现在 grid 下方

### 4. 8 新 ARB key × 3 lang

- DayDetail: `medsCalendarDayDetailTitle` (param) / `Empty` / `AddLog` / `AddLogHint` / `LogItem` (param)
- Legend: `medsCalendarLegendPartial` / `Almost` / `Full` (替代原 hardcoded `< 50%` / `< 100%` / `100%`)
- 3 lang 同步: zh / en / zh_Hant (R57 守门员强制)
- 走 gen-l10n 重生 AppLocalizations (无 schema 改动, 仅 ARB keys)

## 复用 widget (跟 R91 R92 一致, 不重写)

- `PageScaffold` — page root
- `SectionHeader` — DayDetail 头部
- `AppListTile` — DayDetail log list
- `EmptyState` — DayDetail 无打卡 + CalendarGrid 无药
- `PrimaryButton` — DayDetail 补打卡 button
- `PressFeedback` — CalendarGrid cell (scale 反馈)
- `InfoBanner` — page 顶部说明
- `LoadingSkeleton` — 加载态
- `ErrorState` — 错误态
- `Formatters.date / .time` — DayDetail 时间格式

## 风险

| 风险 | 缓解 | 状态 |
|------|------|------|
| 拆完 UI 不一致 | snapshot test (4 baseline + 4 DayDetail + 1 Legend + 1 集成) | ✅ 0 视觉回归 |
| 30 处中文 l10n 漏改 | 3 lang 同步 + check_strings_hardcoded + check_orphan_arb_keys | ✅ 0 漏改, 0 orphan |
| cell tap 跨 navigation | in-page state (无 navigation) | ✅ 0 路由变更 |
| sub-widget 数据访问错位 | props callback 模式 (父 page 持 data, sub-widget 纯渲染) | ✅ 与 R92 pattern 一致 |

## 遗留 / 后续

- `_onAddLogStub` 待 R93 task 4 + task 5 接入 (RecordCheckInUseCase 扩 `at` 参数)
- 暂未支持 "选药" 弹窗 (DayDetail 当前直接 stub, 未来需 add MedPickerDialog)
- pre-existing 2 守门员 warning (fullwidth_punctuation + widget_dispose) 与本任务无关, 不在本批 fix 范围

## 不在本批做的事 (按 brief)

- ❌ 改 spec / plan / brief / progress.md (R93 主流程维护)
- ❌ 在 master 工作区做 (本任务在 worktree `feat/audit-fixes-r93`)
- ❌ 跑 `flutter pub get` (worktree bootstrap OK)
- ❌ 跑 build_runner schema 改动 (本任务无 schema 改动, 仅 ARB 触发 gen-l10n)
- ❌ 重写 R60 R90 R91 已有 widget (复用, 0 重写)
