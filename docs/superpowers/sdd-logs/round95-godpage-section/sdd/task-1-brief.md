# R95 sub-spec 1 task 1 brief

> **任务**: 拆 `data_management_section.dart` 606 行 god section → 6 sub-tile 文件
> **基线**: v0.30.0+85 (R93 完成, 1672 pass, 17 守门员全绿)
> **基线 spec**: [docs/superpowers/specs/2026-08-06-r95-godpage-section-design.md](../../../specs/2026-08-06-r95-godpage-section-design.md)
> **基线 plan**: [docs/superpowers/plans/2026-08-06-r95-godpage-section.md](../../../plans/2026-08-06-r95-godpage-section.md)
> **基线 R93 task 1**: [docs/superpowers/sdd-logs/round93-audit-fixes/sdd/task-1-report.md](../../round93-audit-fixes/sdd/task-1-report.md) (拆 medication_calendar god page 642→209, 6 commit + 10 tests 模式建立)
> **估时**: 60-90 分钟 (1 subagent, 6-9 commit)

---

## 拆解目标

```
lib/presentation/pages/settings/widgets/data_management_section.dart  (主壳 < 80 行, 估 30-50)
└── widgets/
    ├── export_tile.dart           (50-80 行, ConsentDialog + audit log + JSON 弹窗)
    ├── cbt_pdf_tile.dart          (40-60 行, R88 CBT PDF 导出 + 修 R19B DateTime race)
    ├── report_tile.dart           (40-60 行, ChooseWindowDialog + medication report)
    ├── history_tile.dart          (30-50 行, history dialog)
    ├── import_tile.dart           (50-80 行, JSON 导入 + 风险告知)
    └── clear_tile.dart            (40-60 行, 清空数据 + 二次确认)
```

总行数: **< 500** (vs 当前 606, -17%)

## 关键约束

- **props callback 模式** (主壳持 ref + context, sub-tile 接受 callback, 不读全局)
- 复用 `app_list_tile.dart` 公共组件
- 走 `widgets/{sub}_tile.dart` 子目录 (跟 `medication/widgets/` 一致)
- 保留 PIPL §13 单独同意 / PIPL §17 告知 / PIPL §28 vent 录音不导出
- 保留 audit log 走 swallowError 集中器
- **修 R19B DateTime.now() race** (`final now = DateTime.now();` 入口一次, 复用 4 处, 步骤 3 必做)
- 老 test 适配 (估 5-10 个)
- 6 sub-tile 各加 1 widget test (估 23 case total)
- 0 analyzer error
- 17 守门员全绿 (16 .py + 1 .dart)
- 估 1652 pass (1636 baseline + 16 R95 sub-spec 1 tests)

## 6-9 commit 计划 (按 plan 步骤)

1. **步骤 1**: 拆骨架 (建 6 sub-tile 骨架 + 主壳改 props callback)
2. **步骤 2a**: 抽 export_tile (200+ 行 → sub-tile)
3. **步骤 2b**: export_tile widget test 5 case + 老 test 适配
4. **步骤 3**: 抽 cbt_pdf_tile (R88 CBT PDF 导出 + 修 R19B DateTime race)
5. **步骤 4a**: 抽 report_tile (ChooseWindowDialog + medication report + swallowError)
6. **步骤 4b**: 抽 history_tile + 2 widget test
7. **步骤 5**: 抽 import_tile (JSON 导入 + 风险告知)
8. **步骤 6**: 抽 clear_tile (清空数据 + 二次确认)
9. **步骤 7**: 跑 17 守门员全绿 + 0 analyzer error + 老 test 全过 + 收尾

## 任务清单 (按步骤)

### 步骤 1: 拆骨架
- 建 `widgets/` 子目录
- 创 6 个 sub-tile 骨架 (空 StatelessWidget, 接受 VoidCallback onExport)
- 改主壳 6 个 ListTile 改用 sub-tile
- 跑 `flutter analyze` 0 error + 老 test baseline

### 步骤 2: 抽 export_tile
- 移动 `_exportData` (200+ 行) → `widgets/export_tile.dart` 50-80 行
- 业务逻辑 (ConsentDialog / audit log / JSON 弹窗) 全部保留
- 加 5 widget test + 老 test 适配

### 步骤 3: 抽 cbt_pdf_tile
- 移动 `_exportCbtPdf` (R88) → `widgets/cbt_pdf_tile.dart` 40-60 行
- 业务逻辑 (date range picker + cbtReratedEntriesProvider + CbtThoughtRecordPdf + Printing.layoutPdf + SnackBar) 全部保留
- **修 R19B DateTime.now() race** (入口 `final now = DateTime.now();` 一次, 复用 4 处)
- 加 5 widget test

### 步骤 4: 抽 report_tile + history_tile
- 移动 `_chooseAndShowReport` + `_showMedicationReport` → `widgets/report_tile.dart` 40-60 行
- 移动 `_showReportHistory` → `widgets/history_tile.dart` 30-50 行
- 加 5 widget test (3 + 2)

### 步骤 5: 抽 import_tile
- 移动 `_showImportDialog` → `widgets/import_tile.dart` 50-80 行
- 加 4 widget test

### 步骤 6: 抽 clear_tile
- 移动 `_showClearAllDataDialog` → `widgets/clear_tile.dart` 40-60 行
- 加 4 widget test

### 步骤 7: 收尾
- 跑 `flutter analyze` 0 error
- 跑 `flutter test` 估 1652 pass
- 跑 `dart scripts/check_all.dart` 全绿
- 跑 16 .py 守门员全绿
- 更新 `docs/CHANGELOG.md` 顶部 [0.30.0] 段加 R95 sub-spec 1 entry
- 更新 `docs/VERSION_1.0_PLAN.md` R95 task 1 状态 (P0 → ✅)
- 写 task 1 report `docs/superpowers/sdd-logs/round95-godpage-section/sdd/task-1-report.md`

## 报告输出

写到: `D:\Batch\chroniccare\docs\superpowers\sdd-logs\round95-godpage-section\sdd\task-1-report.md`

报告内容 (1-2KB):
- 实际 commit 数
- 实际行数变化 (主壳 / 6 sub-tile)
- 实际 test 数 (老 test 适配 + 新 test)
- 跑过 17 守门员结果
- 0 analyzer error
- 风险应对 (如有)
- 下一步 (R95 sub-spec 2 task 8-10)

## 时间预算

60-90 分钟 (1 subagent 跑全量)

## 引用

- Spec: [docs/superpowers/specs/2026-08-06-r95-godpage-section-design.md](../../../specs/2026-08-06-r95-godpage-section-design.md)
- Plan: [docs/superpowers/plans/2026-08-06-r95-godpage-section.md](../../../plans/2026-08-06-r95-godpage-section.md)
- R93 task 1 拆 medication_calendar 报告: [docs/superpowers/sdd-logs/round93-audit-fixes/sdd/task-1-report.md](../../round93-audit-fixes/sdd/task-1-report.md)
- R95 增量综合审视报告: [docs/audit/2026-08-06/r95-increment/00-r95-summary.md](../../audit/2026-08-06/r95-increment/00-r95-summary.md) §5.1
- AGENTS.md: [AGENTS.md](../../../../AGENTS.md)
- CHANGELOG: [docs/CHANGELOG.md](../../CHANGELOG.md)
- VERSION_1.0_PLAN: [docs/VERSION_1.0_PLAN.md](../../VERSION_1.0_PLAN.md)

---

**brief 完成时间**: 2026-08-06
**brief 体量**: 3.2KB
**下一步**: 派 1 subagent 跑 task 1 (6-9 commit, 估 60-90 分钟)
