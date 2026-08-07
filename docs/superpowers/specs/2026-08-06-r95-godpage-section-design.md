# R95 sub-spec "god section 拆 1" spec

> **创建时间**: 2026-08-06
> **作者**: Mavis (orchestrator)
> **目的**: 拆 `data_management_section.dart` 606 行 god section → 6 sub-tile 文件
> **基线**: v0.30.0+85 (R93 已完成)
> **优先级**: P0 必做, R95 阶段 1 第 1 task
> **参考**: R93 task 1 拆 medication_calendar god page 642→209 行 模式 + R95 增量综合审视报告 00-r95-summary.md §5.1

---

## 0. 目标

- **拆 `data_management_section.dart` 606 行 god section → 6 sub-tile 文件**
- **复用 R93 task 1 模式** (medication_calendar 642→209 行, 6 commit + 10 tests)
- **主壳 props 持 ref / context, sub-tile 接受 props + callback, 不读全局**
- **复用 `app_list_tile.dart` 公共组件** (R75 引入)
- **保持原 import 风格** (PIPL §13 单独同意 / audit log / swallowError 集中器 / AppSnackBar)

## 1. 背景

### 1.1 为什么拆

- R92 6 视角基线报告标 "3 个 600+ 行 god page 必拆" (assessment / medication_calendar / data_management_section)
- R93 task 1 已拆 medication_calendar 642→209 行 (6 commit + 10 tests, 模式建立)
- R93 后实测 6 个 600+ 行文件, `data_management_section.dart` 606 行是其中之一
- 用户在原始指令明确指定 "拆 data_management_section 606 行 god section 留 R95+"
- R95 增量综合审视报告 00-r95-summary.md §5.1 详细分析 (6 入口 / 22 import / 8 provider)

### 1.2 现状结构 (R93 后实测)

- **22 import** (settings / providers / services / widgets / l10n / domain / theme)
- 1 个 `DataManagementSection extends ConsumerWidget` build:
  - 1 `Card` > `Column` 6 children
  - 6 `AppListTile` (export / cbt_pdf / med_report / report_history / import / clear)
- 6 个方法:
  - `_exportData` (200+ 行, 含 ConsentDialog + audit log + JSON 弹窗 + PIPL §17 告知)
  - `_exportCbtPdf` (R88 新增, 5/7 栏 CBT PDF 导出, 走 date range picker + Printing.layoutPdf)
  - `_chooseAndShowReport` (medication report dialog, 走 ChooseWindowDialog)
  - `_showMedicationReport` (R83 写 history 失败的 swallowError 模式)
  - `_showReportHistory` (history dialog)
  - `_showImportDialog` (JSON 导入)
  - `_showClearAllDataDialog` (清空数据 dialog)

### 1.3 拆解后结构 (目标)

```
lib/presentation/pages/settings/widgets/data_management_section.dart  (主壳 30-50 行)
└── widgets/
    ├── export_tile.dart           (50-80 行, 走 ConsentDialog + audit log + JSON 弹窗)
    ├── cbt_pdf_tile.dart          (40-60 行, 走 date range picker + CbtThoughtRecordPdf.build)
    ├── report_tile.dart           (40-60 行, 走 ChooseWindowDialog + medication report)
    ├── history_tile.dart          (30-50 行, 走 history dialog)
    ├── import_tile.dart           (50-80 行, 走 JSON 导入)
    └── clear_tile.dart            (40-60 行, 走清空数据 dialog)
```

## 2. 范围

### 2.1 拆 6 sub-tile (P0 必修)

| # | Sub-tile | 来源方法 | 估行数 | 业务复杂度 |
|---|----------|----------|--------|------------|
| 1 | `widgets/export_tile.dart` | `_exportData` | 50-80 | XL (ConsentDialog + audit log + JSON 弹窗 + PIPL §17) |
| 2 | `widgets/cbt_pdf_tile.dart` | `_exportCbtPdf` | 40-60 | M (date range picker + CbtThoughtRecordPdf + Printing.layoutPdf) |
| 3 | `widgets/report_tile.dart` | `_chooseAndShowReport` + `_showMedicationReport` | 40-60 | M (ChooseWindowDialog + medication report dialog + swallowError 写 history) |
| 4 | `widgets/history_tile.dart` | `_showReportHistory` | 30-50 | S (走 report_history_dialog) |
| 5 | `widgets/import_tile.dart` | `_showImportDialog` | 50-80 | L (JSON 导入 + 风险告知 + 用户确认) |
| 6 | `widgets/clear_tile.dart` | `_showClearAllDataDialog` | 40-60 | M (清空数据 dialog + 二次确认) |

### 2.2 主壳

- `data_management_section.dart` (主壳 30-50 行, 6 `AppListTile` 拼装, props 持 ref / context, callback 模式)

## 3. 不在范围 (R95+ 其他 task 配)

- ❌ **不动 `home_page.dart` 679 行** (R95 sub-spec 3 拆, task 5)
- ❌ **不动 `trend_calendar.dart` 642 行** (R95 sub-spec 3 拆, task 6)
- ❌ **不动 `mood_audio_section.dart` 553 行** (R95 sub-spec 3 拆, task 7)
- ❌ **不动 `scale_translations.dart` 784 + l10n 708** (R95 sub-spec 3 拆, task 2)
- ❌ **不动 224 TextStyle / 208 EdgeInsets 集中器化** (R95 sub-spec 2, task 3-4)
- ❌ **不动 30+ 硬编码中文 → 走 ARB** (R95 sub-spec 2, task 9)
- ❌ **不动 10 处 catch (_) 静默吞错** (R95 sub-spec 2, task 8)
- ❌ **不动其他 4 个半成品 widget 清理** (R95 sub-spec 2, task 10)

## 4. 设计

### 4.1 复用 R93 task 1 模式 (medication_calendar 642→209)

**R93 task 1 拆解模式**:
- 抽 `widgets/{sub}_widget.dart` 子目录 (跟 `medication/widgets/` 一致)
- 主壳 props 持 ref / context, sub-widget 接受 props + callback, **不读全局**
- 复用 `app_list_tile.dart` 公共组件
- 6 commit + 10 tests, 估 1-2 周

**本 spec 复用同一模式**:
- 抽 `widgets/{sub}_tile.dart` (6 sub-tile)
- 主壳 props 持 ref / context, sub-tile 接受 callback
- 复用 `app_list_tile.dart`

### 4.2 props callback 模式 (避免 R95 P1 风险)

**错误模式 (god section 当前)**:
```dart
// 主壳持 ref + context, 直接读 provider
final consent = await ConsentDialog.show(context, kind: ConsentKind.dataExport, ...);
final service = ref.read(dataExportServiceProvider);
final json = await service.exportToJson();
```

**正确模式 (R95 sub-tile)**:
```dart
// 主壳 props 持 ref + context
class DataManagementSection extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(child: Column(children: [
      ExportTile(onExport: () => _exportData(context, ref)),
      CbtPdfTile(onExport: () => _exportCbtPdf(context, ref)),
      ...
    ]));
  }
}

// sub-tile 接受 callback
class ExportTile extends StatelessWidget {
  final VoidCallback onExport;
  Widget build(BuildContext context) {
    return AppListTile(
      title: Text(AppLocalizations.of(context).settingsExportData),
      onTap: onExport,
    );
  }
}
```

### 4.3 复用既有组件

- `app_list_tile.dart` (R75 引入, 主壳 6 ListTile 用)
- `app_snack_bar.dart` (showInfo / showError, 6 sub-tile 错误提示)
- `swallow_error.dart` (R17 模式, audit log 失败时)
- `consent_dialog.dart` (PIPL §13 单独同意, export_tile 用)
- `app_tokens.dart` (颜色 / 字体 / 间距 / 圆角 / 阴影)

### 4.4 业务逻辑保留

- **PIPL §13 单独同意** (export_tile 走 ConsentDialog)
- **PIPL §17 告知** (JSON 弹窗加明文风险 + 责任划界 + checkbox 强制勾选)
- **audit log** (LegalConsentStore.recordDataExportConsent, 失败走 swallowError)
- **PIPL §28 vent 录音不导出** (Container 提示)
- **swallowError 集中器** (audit log 失败)
- **AppSnackBar 集中器** (成功/失败提示)
- **CbtThoughtRecordPdf** (R88 新增, cbt_pdf_tile 用)

## 5. 风险

### 5.1 已知风险

| # | 风险 | 概率 | 影响 | 应对 |
|---|------|------|------|------|
| 1 | 6 sub-tile 移动可能引 5+ 老 test 失败 (test 直接调 _exportData / _exportCbtPdf 等) | 中 | 中 | 老 test 改调用 sub-tile 入口, 加新 widget test |
| 2 | 主壳 props 持 ref, sub-tile 接受 callback, 可能有 race condition (context.mounted 跨 async gap) | 中 | 中 | 复用 R93 task 1 模式 `if (!context.mounted) return;` 守卫 |
| 3 | 业务逻辑 (ConsentDialog / audit log / JSON 弹窗) 拆 6 sub-tile 后测试覆盖要跟上 | 高 | 中 | 6 sub-tile 各加 1 widget test + 1 老 test 适配 |
| 4 | _exportCbtPdf 内 DateTime.now() 多次调用 race (R19B 已知问题) | 低 | 中 | 入口 `final now = DateTime.now();` 一次, 复用 |
| 5 | 主壳 22 import 拆 6 sub-tile 后, 部分 import 仍需主壳保留 (ConsentKind / AppTokens) | 低 | 低 | 仔细审计 import 分布 |

### 5.2 老 test 适配 (R93 task 1 模式)

R93 task 1 拆 medication_calendar 时, 7 个老 test 适配:
- `medication_calendar_grid_round82_test.dart` 改测试入口
- `medication_calendar_page_round66_test.dart` 改 props
- 等等

本 spec 估计:
- `data_management_section_round49_test.dart` 改测试入口
- `data_management_section_round56_test.dart` 改 props
- `data_management_section_round74_test.dart` 改 cbt_pdf 入口
- 等等

## 6. 验收

### 6.1 行数验收

- 主壳 `data_management_section.dart` **< 80 行** (估 30-50 行)
- 6 sub-tile **各自 < 100 行**
- 总行数 (主壳 + 6 sub-tile) **< 500 行** (vs 当前 606 行, 减 17%+)

### 6.2 测试验收

- 老 test 全过 (估 5-10 个老 test 适配)
- 6 新 widget test (每个 sub-tile 1 个)
- 0 analyzer error
- 守门员全绿 (16 .py + 1 .dart)
- 估算: 1636 → 1652 pass (+16 R95 sub-spec 1 tests)

### 6.3 业务验收

- PIPL §13 / §17 / §28 保留
- audit log 走 swallowError 集中器
- 6 sub-tile 业务逻辑跟原方法等价
- R88 CBT PDF 导出功能保留

## 7. 不在范围 (重复强调)

本 spec 只拆 `data_management_section.dart`, 不动:
- home_page.dart / trend_calendar.dart / mood_audio_section.dart (留 R95 sub-spec 3)
- scale_translations.dart + l10n (留 R95 sub-spec 3)
- 224 TextStyle / 208 EdgeInsets 集中器化 (留 R95 sub-spec 2)
- 30+ 硬编码中文 (留 R95 sub-spec 2)
- 10 处 catch (_) 静默吞错 (留 R95 sub-spec 2)
- 4 个半成品 widget 清理 (留 R95 sub-spec 2)
- 业务真接 (IAP / 阿里云 SMS / 5 厂商 push / Email / PHQ-9 i18n, 留 R95 sub-spec 4)
- 法务过审 (留 R95 sub-spec 4)

## 8. 引用

- R93 task 1 拆 medication_calendar 报告: [docs/superpowers/sdd-logs/round93-audit-fixes/sdd/task-1-report.md](../sdd-logs/round93-audit-fixes/sdd/task-1-report.md)
- R95 增量综合审视报告 00-r95-summary.md §5.1: [docs/audit/2026-08-06/r95-increment/00-r95-summary.md §5.1](../../audit/2026-08-06/r95-increment/00-r95-summary.md#51-data_management_sectiondart-606-行-r95-task-1-必拆)
- AGENTS.md 4 层架构约束: [AGENTS.md](../../../../AGENTS.md)
- R92 6 视角基线报告: [docs/audit/2026-08-06/00-summary-report.md](../../audit/2026-08-06/00-summary-report.md)

---

**spec 完成时间**: 2026-08-06
**spec 体量**: 5.2KB
**下一步**: 写 plan (15-25KB, 详细到每 sub-tile 步骤) → 写 task 1 brief → 派 subagent 跑
