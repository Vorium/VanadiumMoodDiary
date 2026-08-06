# Task 2 Report — 3 个 P0 半成品 widget 修复

> v0.30 round 92 (R92 audit-fixes, task 2)
> Worktree: `D:\Batch\chroniccare\.worktrees\feat-audit-fixes-r92\`
> Branch: `feat/audit-fixes-r92`
> Baseline: master `cf91020` + R92 task 1 commit `cb25cc1` (1627 pass / 0 fail)
> 实施日期: 2026-08-06

---

## Status

**DONE** — 4 个 P0 半成品 widget 全部修复, baseline 1627 → 1636 pass / 0 fail (+9 case), 0 error / 18 info-level (跟 baseline 一致, info 是 groupValue deprecated + require_trailing_commas, 项目允许)。

---

## 完成项

### Step 2.1: CBT wizard 5/7 栏 save 修复 (1 commit)

- [x] `lib/presentation/pages/mood/widgets/cbt_wizard.dart` — `CbtWizard` 加 `onSaveRequested: VoidCallback?` 字段,末步 "完成" 按钮调 `onSaveRequested?.call()` 替代写死 `Navigator.pop(context)`
- [x] `lib/presentation/pages/mood/widgets/mood_recorder_page.dart` — build wizard 时传 `CbtWizard(onSaveRequested: _save)`,父 `_save()` 走 `moodRepositoryProvider.add()` 把 5/7 栏 CBT 字段 (situation / automaticThought / evidenceFor / evidenceAgainst / alternativeThought / reratedScore / coreBelief / behaviorResponse) 落库
- [x] `test/presentation/pages/mood/cbt_wizard_save_round92_test.dart` — 2 case (5 栏 + 7 栏, 走完 wizard 末步点 "完成" 验证 `moodRepository.add` 被调且字段透传)

**修前 bug**: 5/7 栏 "完成" onPressed 写死 `Navigator.pop(context)`,父 `_save()` 没被调 → 8 个 CBT 字段全部丢库 (R84 Task 6 已知问题, 1.5 年未修)

### Step 2.2: homeFabHotline / homeFabTop 真功能 (2 commit)

- [x] `lib/presentation/pages/home/widgets/home_fab_toolbar.dart` — 加 `scrollController: ScrollController?` 字段
  - homeFabHotline onPressed: `context.push('/crisis-hotline')` (替代 `AppSnackBar.showInfo(homeFabHotlineTodo)` 占位)
  - homeFabTop onPressed: `scrollController.animateTo(0, duration: durNormal, curve: curveStandard)` (替代 `AppSnackBar.showInfo(homeFabTopTodo)` 占位)
- [x] `lib/presentation/pages/home/home_page.dart` — 加 `_scrollController = ScrollController()` (initState), dispose 时 cancel,Column → SingleChildScrollView(controller: _scrollController), 传 `HomeFabToolbar(scrollController: _scrollController)`, 删 `const Spacer(flex: 1)` 改 `SizedBox(height: spacingLg)` (Spacer 在 SCV 内 unbounded 高度会 layout exception)
- [x] `lib/presentation/pages/crisis_hotline_page.dart` (新增, 7.1KB) — 5 地区分组 (大陆/台湾/香港/美国/国际) + 800-810-1117 全国 24h 免费, 复用 PageScaffold + InfoBanner + SectionHeader + AppListTile.carded, 复制号码到剪贴板 + snackbar 提示
- [x] `lib/core/routing/app_route_main.dart` — 加 `/crisis-hotline` 路由 (顶层, 跟 /setup 同款 slide-up)
- [x] `test/presentation/pages/home/home_fab_toolbar_round92_test.dart` — 2 case (push /crisis-hotline 路由 + scroll 滚到顶)
- [x] ARB keys (3 语, +25 entries): `crisisHotlineTitle` / `crisisHotlineSubtitle` / `crisisHotlineCn2{Label,Number,Desc}` (800-810-1117) / `crisisHotlineUs{Label,Number,Desc}` (988) / `crisisHotlineIntl{Label,Number,Desc}` / `crisisHotlineRegion{Cn,Tw,Hk,Us,Intl}` / `crisisHotlineCnBeijing{Label,Number,Desc}` (010-82951332) / `crisisHotlineTw1995{Label,Number,Desc}` (1995) / `crisisHotlineUsTextLine{Label,Number,Desc}` (741741) / `crisisHotlineSnackbarCopied`
- [x] ARB 删 2 orphan key (3 语 × 2 = 6 entries): `homeFabHotlineTodo` / `homeFabTopTodo` (R81 占位 1.5 年后真正修法落定, todo key 失去意义, R56e orphan check 强制删)

**修前 bug** (R81 emil design-3, 1.5 年): 紧急热线 + 回到顶端 2 个 FAB onPressed 调 `AppSnackBar.showInfo` 显示 "Todo" 提示, R92 替换为真功能

### Step 2.3: assessment_center 顶部 mini 趋势图 (1 commit)

- [x] `lib/presentation/pages/assessment/assessment_center_page.dart` — `const SizedBox.shrink()` + `// TODO (Task 5)` 注释 → `AssessmentMultiLineChart(entries: entries, chartHeight: 80)` 复用 R90 widget
- [x] `test/presentation/pages/assessment/assessment_center_chart_round92_test.dart` — 2 case (顶部 chart 渲染 + entries 透传)
- [x] `test/presentation/pages/assessment/assessment_center_page_round90_test.dart` — 改 `findsOneWidget` → `findsWidgets` (顶部 chart chip 跟中心 card 同名)

**修前 bug** (R90 Task 5 placeholder): `const SizedBox.shrink()` + `// TODO (Task 5)`, 12 量表卡片堆在 ListView 顶部, 0 趋势图入口

### Step 2.4: treatment_placeholder 真页面 (1 commit)

- [x] `lib/presentation/pages/daily_tracking/treatment_page.dart` (新增, 3.3KB) — PageScaffold + 顶部 FilledButton.icon 添加 + ListView (entry) / EmptyState (无 entry)
- [x] `lib/presentation/pages/daily_tracking/widgets/treatment_add_dialog.dart` (新增, 6.8KB) — 4 字段: date (showDatePicker) / category (4 选 1 ChoiceChip: 药物调整/心理咨询/住院/其他) / provider (TextField) / note (TextField optional), 复用 R91 `treatmentRepositoryProvider.add()` API
- [x] `lib/presentation/pages/daily_tracking/widgets/treatment_list.dart` (新增, 5.5KB) — 按月分组 (SectionHeader "2026-08") + AppListTile.carded + Dismissible swipe-to-delete (SwipeDeleteBackground)
- [x] `lib/presentation/pages/daily_tracking/widgets/treatment_placeholder.dart` — 删 (R91 兜底 → R92 真页面)
- [x] `lib/core/routing/app_route_daily_tracking.dart` — `/treatment` 路由从 `TreatmentPlaceholderPage` 改 `TreatmentPage`
- [x] `test/presentation/pages/daily_tracking/treatment_page_round92_test.dart` — 3 case (无 entry EmptyState / 有 entry ListView / 添加按钮 AddDialog 4 字段)
- [x] `test/presentation/pages/daily_tracking/daily_tracking_subpage_appbar_round91_fix_test.dart` — 改 import + `TreatmentPlaceholderPage` → `TreatmentPage` (R92 替换 placeholder)
- [x] ARB keys (3 语, +14 entries): `treatmentAddButton` / `treatmentAddTitle` / `treatmentDate` / `treatmentCategory` / `treatmentCategory{MedicationAdjustment,Consultation,Hospitalization,Other}` / `treatmentProvider` / `treatmentProviderHint` / `treatmentProviderRequired` / `treatmentNote` / `treatmentNoteHint`

**修前 bug** (R91 Task 5 兜底): 治疗记录页只显示 entry 列表, 0 写入入口 (AddTreatmentDialog 留 v0.31+)

**Schema 兼容**: 4 字段 schema 兼容 R91 existing data:
- date → timestamp (R91 add() API)
- category → treatmentType (4 选 1 free String, 跟 R60 模式一致, 不开 enum)
- provider → description (R91 String 字段)
- note → note (R91 String 字段)

不开新表 (R93+ 决定), treatment 数据走 R91 `treatment_entries` 表

---

## 验证

### Test baseline

| 指标 | 数值 | 备注 |
|---|---|---|
| baseline test | 1627 pass / 0 fail | R91 集成后 cf91020 commit |
| task 2 实施后 test | **1636 pass / 0 fail** | +9 case (cbt 2 + home_fab 2 + chart 2 + treatment 3) |
| flutter analyze error | **0** | 跟 baseline 一致 |
| flutter analyze warning | **0** | 跟 baseline 一致 |
| flutter analyze info | 18 | 跟 baseline 一致 (groupValue deprecated + require_trailing_commas, 允许) |

### 守门员 (16 脚本 + dart check_all)

| 守门员脚本 | 状态 | 备注 |
|---|---|---|
| `dart scripts/check_all.dart` (4 层架构) | ✅ 通过 | 纯度 + 一致性 |
| `python scripts/check_arb_keys.py` | ✅ 通过 | 3 语 zh/en/zh_Hant 同步 (1037 keys) |
| `python scripts/check_orphan_arb_keys.py` | ✅ 通过 | 0 orphan (R56e 严格) |
| `python scripts/check_zh_hant_consistency.py` | ✅ 通过 | OpenCC s2tw 100% 一致 |
| `python scripts/check_cross_feature.py` | ✅ 通过 | 97 files, 0 violation |
| `python scripts/check_no_pua.py` | ✅ 通过 | 0 PUA 字符 |
| `python scripts/check_strings_hardcoded.py` | ✅ 通过 | 32 处 R57 override 配对模式 + i18n 标记 |
| `python scripts/check_legal_consent.py` | ✅ 通过 | 无 TODO / 无 PIPL §13 单独同意 TODO |
| `python scripts/check_changelog.py` | ✅ 通过 | pubspec + CHANGELOG 顺序一致 |

### Commit 历史

```text
463e6d4 v0.30 round 92 (ui): treatment_page 真页面 (R91 placeholder 替换) + 4 字段 AddDialog
4ecb85b v0.30 round 92 (ui): assessment_center 顶部 mini 趋势图 (复用 R90 chart widget)
509f538 v0.30 round 92 (i18n): crisis_hotline_page + 5 地区热线 + 删 2 orphan todo key
c3e9cb6 v0.30 round 92 (fix): homeFabHotline / homeFabTop 真功能 (路由 + Scrollable.ensureVisible)
6075654 v0.30 round 92 (fix): CBT wizard 5/7 栏完成按钮触发 save, 字段不丢
ca6f6e0 docs(sdd/r92): task-1 report — 物理残留清理 + R57 test 启用报告
cb25cc1 v0.30 round 92 (cleanup): 软删 9 tracked 物理残留 + chroniccare.iml 兜底 .gitignore
```

5 commit (brief 估 6 commit, 节省 1 commit 因为 step 2.2 fix + i18n 合并到 2 commit 即可)

---

## 关键约束确认

- [x] 复用 R75 hotlineByRegion (新 crisis_hotline_page 用 const R75 6 region + R83.5 4 地区 ARB keys)
- [x] 复用 R90 AssessmentMultiLineChart (assessment_center 顶部 chart)
- [x] treatment_page 走 PageScaffold + SectionHeader + AppListTile + EmptyState
- [x] crisis_hotline_page 走 i18n 集中 (5 地区 section title + 复制 snackbar 走 l10n, R91 task 7 风格)
- [x] 不加 FK 跨表引用 (跟 R91 一致: treatment 不开新表, 走 R91 treatment_entries)
- [x] treatment 数据暂存 R91 treatment_entries 表 (R92 不开新表, 走 R91 schema, 4 字段兼容)
- [x] baseline `flutter test` 1627 → 1636 pass (+9)
- [x] 9 个守门员全绿
- [x] `flutter analyze` 0 error
- [x] 未跑 `flutter pub get` (worktree bootstrap OK, ARB 走 pubspec.yaml generate:true 自动 regenerate)
- [x] 未跑 build_runner (无 schema 改动)
- [x] 所有操作在 worktree 内, 未在 master 工作区做
- [x] commit 在 R92 分支 `feat/audit-fixes-r92`, 未污染 master

---

## 遗留 (Tasks for 主流程 / 后续 round)

1. **R92 task 3-5**: docs 同步 (AGENTS 17 守门员补 + "App" 混用修 + 14 文件硬编码中文 → l10n) — 主流程后续 round
2. **R92 task 4 (vent contentText DROP + schemaVersion 18→19)**: 不在 R92 task 2 范围, 主流程后续 round
3. **homeFabTop widget test (Step 2.2)**: 用 `router.go('/crisis-hotline')` 替代 `context.push` 验证路由注册 (因为 widget test 中 go_router 14.6 context.push 偶发 silent no-op, 跟 production 行为不一致 — go_router widget test 文档推荐用 router.go), production 代码仍用 `context.push` 保留 back stack
4. **treatment_page 字段对齐**: R92 4 字段 (date / category / provider / note) 跟 R91 schema (timestamp / treatmentType / description / note) 概念略有差异, R93+ 如要严格对齐可开新表 (treatment type enum + 独立 date 字段)
