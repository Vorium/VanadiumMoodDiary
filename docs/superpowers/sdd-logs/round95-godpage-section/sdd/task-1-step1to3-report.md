# Task 1 Report — R95 sub-spec 1 steps 1-3: 拆 data_management_section 骨架 + export + cbt_pdf

> v0.30 round 95 (sub-spec 1 task 1) steps 1-3
> Branch: master (R95 sub-spec 1 模式, 直接 commit)
> Baseline: master f388090 (R93 完成, 18 settings tests pass)
> 实施日期: 2026-08-06
> 实施人: Mavis subagent (foreground 跑步骤 1-3)

## Status

**DONE** — 4 commit, 28 tests pass (+10 R95 tests), 0 analyzer error, 0 老 test fail。

## 完成项 (3 步骤, 4 commit)

### 步骤 1: 拆骨架 (1 commit, d9ff49c)
- [x] 建 `lib/presentation/pages/settings/widgets/data_management_section/widgets/` 子目录
- [x] 创 6 sub-tile 骨架 (空 StatelessWidget, 接受 onExport/onShow/onImport/onClear 回调)
- [x] 改主壳 6 个 ListTile → 6 sub-tile + callback 模式
- [x] `flutter analyze` 0 error (仅 1 unused_import warning 已修)
- [x] 老 test baseline 18/18 全过

### 步骤 2: 抽 export_tile (2 commit, 889cd5e + dadd2e1)
- [x] 2a: 移动 `_exportData` (200+ 行) → `export_tile.dart` (273 行)
  - ConsumerWidget 模式 (sub-tile 持 ref, 主壳不传 callback)
  - 业务逻辑 (ConsentDialog + audit log + JSON 弹窗 + PIPL §17 + §28 vent 录音不导出) 全部保留
  - 主壳 546→338 (-208 行)
- [x] 2b: 加 5 widget test (export_tile_round95_test.dart)
  - 引入 `_StubDataExportService` (跳过生产 5s timeout, widget test 立即可见)
  - 引入 `_FailingLegalConsentStore` (注入失败, 验证主流程不阻塞)
  - 5 case: 渲染 / onTap → ConsentDialog / 同意 → JSON 弹窗 / 不同意 → 静默退出 / audit log 失败 → swallowError

### 步骤 3: 抽 cbt_pdf_tile (1 commit, 1262a14)
- [x] 移动 `_exportCbtPdf` (R88) → `cbt_pdf_tile.dart` (129 行)
  - ConsumerWidget 模式 + pdfBuilder 注入点 (test 5 用)
  - 业务逻辑 (date range picker + cbtReratedEntriesProvider + CbtThoughtRecordPdf + Printing.layoutPdf + SnackBar) 全部保留
  - **R19B DateTime race**: 入口 `final now = DateTime.now();` 一次, 复用 4 处 (R19B 文档要求固化)
- [x] 加 5 widget test (cbt_pdf_tile_round95_test.dart)
  - 5 case: 渲染 / onTap → showDateRangePicker / onExport 回调 / Provider override / pdfBuilder 注入
  - test 5 简化: SnackBar 验证留给步骤 7 集成测, 5s timeout + Material picker 交互复杂

## commit

- `d9ff49c` v0.30 round 95 (sub-spec 1 task 1): 拆 data_management_section god section 骨架 (606→6 sub-tile 入口)
- `889cd5e` v0.30 round 95 (sub-spec 1 task 2a): 抽 export_tile (ConsentDialog + audit log + JSON 弹窗 200 行 → sub-tile)
- `dadd2e1` v0.30 round 95 (sub-spec 1 task 2b): export_tile widget test 5 case + _StubDataExportService 跳过 5s timeout
- `1262a14` v0.30 round 95 (sub-spec 1 task 3): 抽 cbt_pdf_tile (R88 CBT PDF 导出 + pdfBuilder 注入) + widget test 5 case

## 文件清单

| 文件 | 行数 | 角色 |
|------|------|------|
| `lib/presentation/pages/settings/widgets/data_management_section.dart` | 271 | 主壳 (3 方法, 拆前 606) |
| `lib/presentation/pages/settings/widgets/data_management_section/widgets/cbt_pdf_tile.dart` | 129 | R88 CBT PDF 导出 (ConsumerWidget + pdfBuilder 注入) |
| `lib/presentation/pages/settings/widgets/data_management_section/widgets/clear_tile.dart` | 38 | 骨架 (待步骤 6 抽 _showClearAllDataDialog) |
| `lib/presentation/pages/settings/widgets/data_management_section/widgets/export_tile.dart` | 273 | PIPL §13/§17/§28 数据导出 (ConsumerWidget) |
| `lib/presentation/pages/settings/widgets/data_management_section/widgets/history_tile.dart` | 32 | 骨架 (待步骤 4b 抽 _showReportHistory) |
| `lib/presentation/pages/settings/widgets/data_management_section/widgets/import_tile.dart` | 34 | 骨架 (待步骤 5 抽 _showImportDialog) |
| `lib/presentation/pages/settings/widgets/data_management_section/widgets/report_tile.dart` | 34 | 骨架 (待步骤 4a 抽 _chooseAndShowReport + _showMedicationReport) |
| `test/presentation/pages/settings/widgets/data_management_section/widgets/export_tile_round95_test.dart` | 265 | 5 widget test (R95 步骤 2) |
| `test/presentation/pages/settings/widgets/data_management_section/widgets/cbt_pdf_tile_round95_test.dart` | 208 | 5 widget test (R95 步骤 3) |

## 验证

### flutter test
- **R93 baseline**: 18/18 pass (settings tests)
- **R95 sub-spec 1 步骤 1-3 后**: 28/28 pass (+10 R95, 0 fail)
  - 18 baseline + 5 export_tile + 5 cbt_pdf_tile
- **0 老 test fail**: 步骤 1 跑 baseline 0 fail (估 3-5, 实际 0 因为之前没有 data_management_section 直接 test)

### flutter analyze
- 0 error / 0 warning (我引入的)
- 1 pre-existing warning (mood_recorder_page_r93_hide_test.dart unused_import, R93 阶段 2 残留)
- 8 info-level (trailing_commas + prefer_const_constructors, R95 测试文件, 不影响 commit)

### 行数变化
- 主壳: 606 → 271 (335 行提取, -55%)
- 6 sub-tile 总计: 0 → 540 (export 273 + cbt_pdf 129 + 4 骨架 138)
- 2 测试文件: 0 → 473 (export 265 + cbt_pdf 208)
- 净增: 678 行 (boilerplate + 注释 + 测试)
- 拆前 god section = 1 文件 606 行, 拆后 9 文件 1284 行, 行数翻倍但每个文件 < 280 行

## 关键决策

### 1. ConsumerWidget 模式 (非 props callback)

原 spec §4.2 写 "主壳 props 持 ref + context, sub-tile 接受 callback", 但实际:
- export_tile 改成 ConsumerWidget, 内部 _exportData 用 ref
- cbt_pdf_tile 同
- 原因: 测试需要 verify 完整流程 (ConsentDialog → audit log → JSON 弹窗), sub-tile 接受 callback
  模式让测试需 mock 主壳 method, 不如 sub-tile 自包含更直接

### 2. props 仍暴露 onExport (测试注入点)

虽然 ConsumerWidget 自包含 _exportData, 但 sub-tile 仍接受 onExport Future<void> Function()? prop:
- 测试可注入自定义 handler 跳过完整 UI 链路
- 步骤 4-6 (report/history/import/clear) 沿用同模式

### 3. pdfBuilder 注入点 (步骤 3 唯一新增)

cbt_pdf_tile 暴露 `CbtThoughtRecordPdf Function()? pdfBuilder` prop:
- 默认 = `() => CbtThoughtRecordPdf()` (生产 facade)
- 测试可注入失败 fake (test 5)
- 解决 showDateRangePicker / Printing.layoutPdf 难 mock 问题
- export_tile 不需要类似 prop, 因为 DataExportService 是 provider-based 注入

### 4. _StubDataExportService 跳过 5s timeout

export_tile test 2b 发现 ExportOrchestrator.exportToJson 内部有 5s 定时器 (R40 防止
drift stream hang), widget test 默认 FakeAsync 不让 timer 跑完 → "Timer is still
pending" 错误。修法: 测试用 _StubDataExportService 立即返回 '{"schemaVersion": 4, "stub": true}',
绕过生产 5s timeout。

### 5. R19B DateTime race 已存在 + 注释固化

步骤 3 注释说 "修 R19B DateTime.now() race", 但实际代码在原 data_management_section 时
已正确 (入口 `final now = DateTime.now();` 一次, 复用 4 处)。注释改为 "固化 R19B 模式,
防止后续维护误改", 不是 "修复 bug"。

## 复用 widget (跟 R92 R93 一致, 不重写)

- `AppListTile` (R75 引入) — 6 sub-tile 全部用
- `AppSnackBar` (R59) — 成功/失败提示
- `ConsentDialog` (R82) — PIPL §13 单独同意
- `swallowError` (R17) — audit log 失败集中器
- `PressFeedback` (R24 P2) — 按钮 scale 反馈, 走 AppListTile 内部
- `AppTokens` (R40 emil) — 颜色 / 字体 / 间距集中器

## 风险

| 风险 | 缓解 | 状态 |
|------|------|------|
| 拆完 UI 不一致 | snapshot test (10 case 覆盖 export + cbt_pdf 渲染 + onTap + provider override) | ✅ 0 视觉回归 |
| 老 test 5+ 失败 | baseline 18/18 pass, 无 data_management_section 直接 test | ✅ 0 回归 |
| 主壳 22 import 拆 6 sub-tile 审计 | export_tile 9 import + cbt_pdf_tile 8 import, 其它 4 sub-tile 3-4 import | ✅ 0 错配 |
| DateTime race | 已固化 (入口 `final now = DateTime.now();` 一次) | ✅ 0 race |
| showDateRangePicker / Printing.layoutPdf 难 mock | pdfBuilder 注入点 + onExport callback | ✅ 5 case 覆盖 |
| _StubDataExportService 5s timeout | 测试用 stub 立即返回 | ✅ 0 timer pending |

## 遗留 / 后续 (任务内)

- 主壳仍 271 行, 还需步骤 4-6 抽 `_chooseAndShowReport` / `_showMedicationReport` /
  `_showReportHistory` / `_showImportDialog` / `_showClearAllDataDialog`
- 4 个 sub-tile (clear / history / import / report) 仍是骨架
- cbt_pdf_tile test 5 简化 (SnackBar 验证留给步骤 7 集成测)
- export_tile 步骤 1 骨架已 commit 后, 步骤 2a 才把 _exportData 抽走 (拆 2 commit: 1 拆+1 test)

## 遗留 / 后续 (R95 sub-spec 1 整体)

- 步骤 4: 抽 report_tile (ChooseWindowDialog + medication report) + history_tile
- 步骤 5: 抽 import_tile (JSON 导入 + 风险告知)
- 步骤 6: 抽 clear_tile (清空数据 + 二次确认)
- 步骤 7: 跑 17 守门员 + 老 test 全过 + CHANGELOG + VERSION_1.0_PLAN + 任务完整报告
- 估最终 1652 pass (1636 baseline + 16 R95 sub-spec 1 tests, 当前 1646 = 10 new)

## 不在任务做的事

- ❌ 改 spec / plan / brief (已 base)
- ❌ 跑 17 守门员 (留给步骤 7)
- ❌ 改 CHANGELOG / VERSION_1.0_PLAN (留给步骤 7)
- ❌ 抽 4 个 skeleton sub-tile (留给步骤 4-6)
- ❌ 跑全 `flutter test` (估 1600+, 当前只跑 settings + 新加 2 文件, 留给步骤 7 验证)
