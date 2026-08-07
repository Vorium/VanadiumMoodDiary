# R95 sub-spec "god section 拆 1" plan

> **创建时间**: 2026-08-06
> **作者**: Mavis (orchestrator)
> **基线 spec**: [docs/superpowers/specs/2026-08-06-r95-godpage-section-design.md](../specs/2026-08-06-r95-godpage-section-design.md)
> **基线 R93 task 1**: [docs/superpowers/sdd-logs/round93-audit-fixes/sdd/task-1-report.md](../sdd-logs/round93-audit-fixes/sdd/task-1-report.md)
> **目的**: 拆 `data_management_section.dart` 606 行 god section → 6 sub-tile 文件
> **估时**: 1-2 周 (1 人)
> **估 commit**: 6-9 commit
> **估 tests**: +16 R95 sub-spec 1 tests (6 sub-tile × 1 widget test + 5-10 老 test 适配)

---

## 0. 目标

拆 `data_management_section.dart` 606 行 god section → 主壳 30-50 行 + 6 sub-tile (50-80 行 each), 复用 R93 task 1 拆 medication_calendar god page 模式。

## 1. 步骤 (按 sub-tile 详细到 commit 级)

### 1.1 步骤 1: 建 sub-tile 骨架 (估 0.5d, 1 commit)

**目标**: 建 6 个 sub-tile 骨架文件, 主壳改 props callback 模式

**步骤**:
1. 建 `lib/presentation/pages/settings/widgets/data_management_section/widgets/` 目录
2. 建 6 个 sub-tile 骨架文件:
   - `widgets/export_tile.dart` (空 StatelessWidget, 接受 VoidCallback onExport)
   - `widgets/cbt_pdf_tile.dart` (空 StatelessWidget, 接受 VoidCallback onExport)
   - `widgets/report_tile.dart` (空 StatelessWidget, 接受 VoidCallback onShow)
   - `widgets/history_tile.dart` (空 StatelessWidget, 接受 VoidCallback onShow)
   - `widgets/import_tile.dart` (空 StatelessWidget, 接受 VoidCallback onImport)
   - `widgets/clear_tile.dart` (空 StatelessWidget, 接受 VoidCallback onClear)
3. 改主壳 `data_management_section.dart`:
   - 6 个 ListTile 改用 6 个 sub-tile
   - 6 个方法从 class 移到 build 闭包 (保留 ref + context)
   - 6 个 sub-tile 各传 callback
4. 跑 `flutter analyze` 确认 0 error
5. 跑 `flutter test test/presentation/pages/settings/` 老 test, 记录 baseline fail 数 (估 3-5 个)

**Commit**: `v0.30 round 95 (sub-spec 1 task 1): 拆 data_management_section god section 骨架 (606→6 sub-tile 入口)`

**测试**: 老 test 跑过 (3-5 fail 后续适配)

### 1.2 步骤 2: 抽 export_tile (估 1-2d, 1-2 commit)

**目标**: 抽 `_exportData` (200+ 行, 含 ConsentDialog + audit log + JSON 弹窗) → `export_tile.dart`

**步骤**:
1. 创 `widgets/export_tile.dart` 50-80 行:
   - 接受 `BuildContext context, WidgetRef ref, Future<void> Function() onExport` props
   - 内置 1 个 `AppListTile` (走原 `_exportData` 一样的 icon / title / subtitle / onTap)
2. 移动 `_exportData` 方法到 sub-tile:
   - 业务逻辑 (ConsentDialog / audit log / JSON 弹窗) 全部保留
   - 改用 `widget.context` / `widget.ref` (R93 task 1 模式)
3. 主壳改 `ExportTile(onExport: () async => await _exportData(context, ref))`
4. 跑 `flutter analyze` 确认 0 error
5. 跑 `flutter test` 老 test 适配:
   - `data_management_section_round49_test.dart` 改测试 `ExportTile` 入口
   - 等等
6. 加新 widget test `export_tile_round95_test.dart`:
   - test 1: 渲染 AppListTile (icon / title / subtitle)
   - test 2: onTap 触发 ConsentDialog (mock ConsentDialog)
   - test 3: 同意 → JSON 弹窗 (mock dataExportServiceProvider)
   - test 4: 不同意 → 静默退出
   - test 5: audit log 失败 → swallowError

**Commit**:
- `v0.30 round 95 (sub-spec 1 task 2a): 抽 export_tile (ConsentDialog + audit log + JSON 弹窗 200 行 → sub-tile)`
- `v0.30 round 95 (sub-spec 1 task 2b): export_tile widget test 5 case + 老 test 适配`

**测试**: 5 新 + 估 1-2 老 test 适配

### 1.3 步骤 3: 抽 cbt_pdf_tile (估 1d, 1 commit)

**目标**: 抽 `_exportCbtPdf` (R88 新增, 5/7 栏 CBT PDF 导出) → `cbt_pdf_tile.dart`

**步骤**:
1. 创 `widgets/cbt_pdf_tile.dart` 40-60 行:
   - 接受 `BuildContext context, WidgetRef ref, Future<void> Function() onExport` props
   - 内置 1 个 `AppListTile` (走原 `_exportCbtPdf` 一样的 icon / title / subtitle / onTap)
2. 移动 `_exportCbtPdf` 方法到 sub-tile:
   - 业务逻辑 (date range picker + cbtReratedEntriesProvider + CbtThoughtRecordPdf + Printing.layoutPdf + SnackBar) 全部保留
   - **修复 R19B DateTime.now() race** (入口 `final now = DateTime.now();` 一次, 复用 4 处)
3. 主壳改 `CbtPdfTile(onExport: () async => await _exportCbtPdf(context, ref))`
4. 跑 `flutter analyze` 确认 0 error
5. 跑 `flutter test` 老 test 适配
6. 加新 widget test `cbt_pdf_tile_round95_test.dart`:
   - test 1: 渲染 AppListTile
   - test 2: onTap → date range picker (mock showDateRangePicker)
   - test 3: 选区间 → cbtReratedEntriesProvider 过滤 + CbtThoughtRecordPdf.build (mock)
   - test 4: PDF 生成成功 → Printing.layoutPdf (mock)
   - test 5: 失败 → AppSnackBar.showError

**Commit**: `v0.30 round 95 (sub-spec 1 task 3): 抽 cbt_pdf_tile (R88 CBT PDF 导出 + 修 R19B DateTime race)`

**测试**: 5 新 + 估 1 老 test 适配

### 1.4 步骤 4: 抽 report_tile + history_tile (估 1-2d, 1-2 commit)

**目标**: 抽 `_chooseAndShowReport` + `_showMedicationReport` → `report_tile.dart`, 抽 `_showReportHistory` → `history_tile.dart`

**步骤**:
1. 创 `widgets/report_tile.dart` 40-60 行:
   - 接受 props
   - 移动 `_chooseAndShowReport` + `_showMedicationReport` 方法 (ChooseWindowDialog + medication report dialog + swallowError 写 history)
2. 创 `widgets/history_tile.dart` 30-50 行:
   - 接受 props
   - 移动 `_showReportHistory` 方法 (走 report_history_dialog)
3. 主壳改 2 处
4. 跑 `flutter analyze` 确认 0 error
5. 跑老 test + 加新 widget test:
   - `report_tile_round95_test.dart` 3 case (渲染 / onTap / swallowError)
   - `history_tile_round95_test.dart` 2 case (渲染 / onTap)

**Commit**:
- `v0.30 round 95 (sub-spec 1 task 4a): 抽 report_tile (ChooseWindowDialog + medication report + swallowError)`
- `v0.30 round 95 (sub-spec 1 task 4b): 抽 history_tile + 2 widget test`

**测试**: 5 新 + 估 1-2 老 test 适配

### 1.5 步骤 5: 抽 import_tile (估 1d, 1 commit)

**目标**: 抽 `_showImportDialog` (JSON 导入) → `import_tile.dart`

**步骤**:
1. 创 `widgets/import_tile.dart` 50-80 行:
   - 接受 props
   - 移动 `_showImportDialog` 方法 (JSON 导入 + 风险告知 + 用户确认)
2. 主壳改
3. 跑老 test + 加新 widget test `import_tile_round95_test.dart`:
   - test 1: 渲染
   - test 2: onTap → 风险告知 dialog
   - test 3: 用户确认 → JSON 解析 + DB 导入
   - test 4: 失败 → AppSnackBar

**Commit**: `v0.30 round 95 (sub-spec 1 task 5): 抽 import_tile (JSON 导入 + 风险告知)`

**测试**: 4 新 + 估 1 老 test 适配

### 1.6 步骤 6: 抽 clear_tile (估 1d, 1 commit)

**目标**: 抽 `_showClearAllDataDialog` (清空数据) → `clear_tile.dart`

**步骤**:
1. 创 `widgets/clear_tile.dart` 40-60 行:
   - 接受 props
   - 移动 `_showClearAllDataDialog` 方法 (清空数据 + 二次确认)
2. 主壳改
3. 跑老 test + 加新 widget test `clear_tile_round95_test.dart`:
   - test 1: 渲染 (error color)
   - test 2: onTap → 二次确认 dialog
   - test 3: 确认 → 清空 DB
   - test 4: 取消 → 静默退出

**Commit**: `v0.30 round 95 (sub-spec 1 task 6): 抽 clear_tile (清空数据 + 二次确认)`

**测试**: 4 新 + 估 1 老 test 适配

### 1.7 步骤 7: 跑守门员 + 老 test 全过 + 收尾 (估 0.5d, 1 commit)

**目标**: 验证 16 守门员全绿 + 老 test 全过 + 0 analyzer error

**步骤**:
1. 跑 `flutter analyze` → 0 error
2. 跑 `flutter test` → 估 1652 pass (1636 baseline + 16 R95 sub-spec 1 tests), 0 fail
3. 跑 `dart scripts/check_all.dart` → 全绿 (purity + consistency)
4. 跑 16 python 守门员:
   - `check_arb_keys.py` ✅ (无新 key)
   - `check_changelog.py` ✅ (待补)
   - `check_cross_feature.py` ✅
   - `check_datetime_race.py` ✅ (R19B 修过)
   - `check_datetime_race2.py` ✅
   - `check_drift_namespace.py` ✅
   - `check_fullwidth_punctuation.py` ✅ (warn-only)
   - `check_no_hardcoded_utc.py` ✅
   - `check_no_pua.py` ✅
   - `check_widget_dispose.py` ✅ (R92 已知 1 false positive)
   - `check_orphan_arb_keys.py` ✅ (R56e)
   - `check_legal_consent.py` ✅
   - `check_sms_release_ready.py` ✅ (warn-only)
   - `check_strings_hardcoded.py` ✅
   - `check_zh_hant_consistency.py` ✅
   - `check_16kb_alignment.py` ✅
5. 更新 `docs/CHANGELOG.md` 顶部 [0.30.0] 段加 R95 sub-spec 1 entry
6. 更新 `docs/VERSION_1.0_PLAN.md` R95 task 1 状态 (P0 → ✅)
7. 写 task 1 report `docs/superpowers/sdd-logs/round95-godpage-section/sdd/task-1-report.md`
8. 更新 progress.md (待 sub-spec 1 整体完成后)

**Commit**: `v0.30 round 95 (sub-spec 1 task 7): 跑 17 守门员全绿 + 0 analyzer error + 老 test 全过 + 收尾`

**测试**: 0 新 (验证), 1652 pass 全过

## 2. 风险 + 应对 (详见 spec §5)

| # | 风险 | 步骤对应 | 应对 |
|---|------|----------|------|
| 1 | 6 sub-tile 移动引 5+ 老 test 失败 | 步骤 1, 2-6 | 步骤 1 先跑 baseline, 步骤 2-6 各加老 test 适配 |
| 2 | 主壳 props 持 ref, sub-tile callback race condition | 步骤 2-6 | 复用 R93 task 1 模式 `if (!context.mounted) return;` 守卫 |
| 3 | 业务逻辑拆 6 sub-tile 后测试覆盖要跟上 | 步骤 2-6 | 6 sub-tile 各加 1 widget test (估 23 case total) |
| 4 | _exportCbtPdf DateTime.now() 多次调用 race | 步骤 3 | 步骤 3 入口 `final now = DateTime.now();` 一次, 复用 4 处 |
| 5 | 主壳 22 import 拆 6 sub-tile 后审计 | 步骤 1, 2-6 | 步骤 1 先全部 import 主壳保留, 步骤 2-6 逐 sub-tile 移到 sub-tile 文件 |

## 3. 测试 + 验证

### 3.1 新 widget test (估 23 case)

| Sub-tile | widget test | case 数 |
|----------|------------|----------|
| export_tile | `export_tile_round95_test.dart` | 5 |
| cbt_pdf_tile | `cbt_pdf_tile_round95_test.dart` | 5 |
| report_tile | `report_tile_round95_test.dart` | 3 |
| history_tile | `history_tile_round95_test.dart` | 2 |
| import_tile | `import_tile_round95_test.dart` | 4 |
| clear_tile | `clear_tile_round95_test.dart` | 4 |
| **总** | **6 test 文件** | **23 case** |

注: 估 16 R95 tests, 跟 spec 一致 (23 case 但部分子目录聚合)

### 3.2 老 test 适配 (估 5-10)

R93 task 1 拆 medication_calendar 时, 7 个老 test 适配。本 spec 估 5-10 个:
- `data_management_section_round49_test.dart` (R49 老 test)
- `data_management_section_round56_test.dart` (R56 老 test)
- `data_management_section_round74_test.dart` (R74 cbt_pdf 加时 test)
- 等等

### 3.3 守门员 (17 个全绿)

详见步骤 7。

### 3.4 flutter analyze (0 error)

步骤 1, 2-6, 7 各跑 1 次, 共 7 次。

### 3.5 baseline 估时

```
baseline R93: 1636 pass
+ R95 sub-spec 1 新 test: +16
+ 老 test 适配: 0 (改入口但仍 pass)
= R95 sub-spec 1 完成: 1652 pass
```

## 4. 验收 (详见 spec §6)

### 4.1 行数验收

- 主壳 `data_management_section.dart` **< 80 行** (估 30-50 行)
- 6 sub-tile **各自 < 100 行** (估 50-80 行 each)
- 总行数 (主壳 + 6 sub-tile) **< 500 行** (vs 当前 606 行, 减 17%+)

### 4.2 测试验收

- 老 test 全过 (估 5-10 个老 test 适配)
- 16 新 widget test (6 sub-tile × 估 2-5 case)
- 0 analyzer error
- 守门员全绿
- 1652 pass

### 4.3 业务验收

- PIPL §13 / §17 / §28 保留
- audit log 走 swallowError 集中器
- 6 sub-tile 业务逻辑跟原方法等价
- R88 CBT PDF 导出功能保留

## 5. Commit 计划 (估 6-9 commit)

| # | 步骤 | commit message | 估行数变化 |
|---|------|----------------|------------|
| 1 | 步骤 1 | `v0.30 round 95 (sub-spec 1 task 1): 拆 data_management_section god section 骨架` | 606 → 700 (加骨架) |
| 2 | 步骤 2a | `v0.30 round 95 (sub-spec 1 task 2a): 抽 export_tile` | 700 → 600 (主壳减) |
| 3 | 步骤 2b | `v0.30 round 95 (sub-spec 1 task 2b): export_tile widget test 5 case` | 600 → 650 (加 test) |
| 4 | 步骤 3 | `v0.30 round 95 (sub-spec 1 task 3): 抽 cbt_pdf_tile + 修 R19B DateTime race` | 650 → 600 |
| 5 | 步骤 4a | `v0.30 round 95 (sub-spec 1 task 4a): 抽 report_tile` | 600 → 550 |
| 6 | 步骤 4b | `v0.30 round 95 (sub-spec 1 task 4b): 抽 history_tile + 2 widget test` | 550 → 530 |
| 7 | 步骤 5 | `v0.30 round 95 (sub-spec 1 task 5): 抽 import_tile` | 530 → 500 |
| 8 | 步骤 6 | `v0.30 round 95 (sub-spec 1 task 6): 抽 clear_tile` | 500 → 480 |
| 9 | 步骤 7 | `v0.30 round 95 (sub-spec 1 task 7): 跑 17 守门员全绿 + 0 analyzer error + 收尾` | 480 → 480 (docs only) |

**总 commit**: 6-9 (估 9)

## 6. 引用

- Spec: [docs/superpowers/specs/2026-08-06-r95-godpage-section-design.md](../specs/2026-08-06-r95-godpage-section-design.md)
- R93 task 1 拆 medication_calendar 报告: [docs/superpowers/sdd-logs/round93-audit-fixes/sdd/task-1-report.md](../sdd-logs/round93-audit-fixes/sdd/task-1-report.md)
- R95 增量综合审视报告 00-r95-summary.md §5.1: [docs/audit/2026-08-06/r95-increment/00-r95-summary.md §5.1](../../audit/2026-08-06/r95-increment/00-r95-summary.md#51-data_management_sectiondart-606-行-r95-task-1-必拆)
- R95 增量综合审视报告 06-flutter-spec.md: [docs/audit/2026-08-06/r95-increment/06-flutter-spec.md](../../audit/2026-08-06/r95-increment/06-flutter-spec.md)
- R92 6 视角基线报告: [docs/audit/2026-08-06/00-summary-report.md](../../audit/2026-08-06/00-summary-report.md)
- AGENTS.md 4 层架构约束: [AGENTS.md](../../../../AGENTS.md)
- CHANGELOG: [docs/CHANGELOG.md](../../CHANGELOG.md)

---

**plan 完成时间**: 2026-08-06
**plan 体量**: 11.2KB
**下一步**: 写 task 1 brief → 派 subagent 跑 task 1
