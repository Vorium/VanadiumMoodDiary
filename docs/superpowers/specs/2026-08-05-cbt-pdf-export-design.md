# CBT 字段导出 PDF + 修 silent data loss Sub-spec 4

| 项目 | 内容 |
|---|---|
| 状态 | design |
| 日期 | 2026-08-05 |
| 范围 | sub-spec 4 / 5 |
| 依赖 | sub-spec 1+2+3 merged (v0.30 R84+85+86+87) |

## 背景

两个相关问题:

### 问题 1: Silent data loss in data_export (CRITICAL, R84 P0 同类)
`lib/core/data/services/export/export_orchestrator.dart:178-189` moodEntries 序列化时**没导出 8 个 CBT 字段**（situation / automaticThought / evidenceFor / evidenceAgainst / alternativeThought / reratedScore / coreBelief / behaviorResponse）。

这是 R84 加 8 字段时**没同步 data_export**导致的, 跟 R84 P0 `moodRepository.add` 漏传字段同类问题。

用户导出 JSON 备份 → 删除原 DB → 从备份恢复 → **所有 CBT 数据丢失**。

### 问题 2: 没有 CBT 思维记录 PDF 导出
现有 `MedicationReportPdf` 导出用药报告, 但没"导出 5/7 栏 CBT 思维记录"功能。用户在精神科复诊时常需要带 PDF 给医生看, 当前只能手抄。

## Goals

- **P0**: 修 silent data loss — moodEntries toMap 加 8 CBT 字段
- **P0**: 配套 import 反序列化 (导入) 也支持 8 CBT 字段
- **P1**: 新加 `CbtThoughtRecordPdf` 类 — 导出 5/7 栏 mood entries 进 PDF
- **P1**: settings page data_management_section 加 "导出 CBT 思维记录" 按钮
- **P2**: i18n ~10 keys (zh / en / zh_Hant)
- **P2**: round-trip 测试 (导出 → 导入 → 字段全保留)

## Non-Goals

- ❌ 加密 PDF (现有 MedicationReportPdf 不加密, 跟)
- ❌ PDF 多语言 (i18n 只用 zh, en 留 v0.31)
- ❌ 邮件发送 PDF (走现有 email 逻辑, 不重复)
- ❌ PDF 美化 (UI/UX polish, v0.31+)
- ❌ 旧 data_export 备份格式升级 (现有 v2 schema, 加字段仍兼容)

## 范围

1. **修 silent data loss** (R84 P0 类似): export_orchestrator.dart moodEntries toMap 加 8 CBT 字段
2. **修 import 反序列化**: export_import_pipeline.dart 跟 JSON map 写入 MoodEntriesCompanion 也加 8 字段
3. **CBT PDF 导出类**: 新加 `lib/core/data/services/cbt_thought_record_pdf.dart` (参考 MedicationReportPdf 模式, ~150 行 facade + 1 layout 文件)
4. **设置入口**: `lib/presentation/pages/settings/widgets/data_management_section.dart` 加 1 个 "导出 CBT 思维记录 PDF" 按钮
5. **i18n**: 10 keys (zh / en / zh_Hant)
6. **测试**: data_export round-trip test (含 8 CBT 字段) + PDF 单元 test

## 数据模型

无 schema 改动 (8 CBT 字段已在 R84 加进 mood_entries)。

新加 1 个 service:
- `CbtThoughtRecordPdf` (lib/core/data/services/cbt_thought_record_pdf.dart)

```dart
class CbtThoughtRecordPdf {
  /// 输入: 5/7 栏 mood entries (cbtLevel >= 5), 输出: Uint8List (PDF 二进制)
  Future<Uint8List> build({
    required List<MoodEntryEntity> entries,
    required DateTimeRange? dateRange,  // 可选 filter
  });
}
```

## UI 设计 (settings 入口)

```
Data Management section (现有)
├─ 导出全部数据 (JSON 备份, 现有)
├─ 导入数据 (现有)
└─ 导出 CBT 思维记录 PDF (新)  ← 点了走 showDateRangePicker → 调 CbtThoughtRecordPdf.build()
```

## 状态管理

无新 provider (settings 入口是 stateless, PDF build 是 one-shot)

## 错误处理

- 无 5/7 栏 entry → SnackBar "还没有 5/7 栏 CBT 数据" (跟 R85 ReratedScoreChart 空态同)
- 日期范围无 entry → 同
- PDF 生成失败 → catch + SnackBar "导出失败, 请重试"

## 测试

- **data round-trip** (P0): 1 case (5 栏 entry 导出 JSON → 删除 → 导入 → 字段全保留)
- **PDF 单元** (P1): 2 case (5 栏 entry 渲染 / 7 栏 entry 渲染 + 1 empty entry 空 PDF)
- **i18n 守门**: 4 脚本 (P2)

## 风险与回滚

- **silent data loss 修复**: 加 8 字段 toMap 是 +8 行, 风险低, 但**老备份恢复时 8 字段会是 null** (因为老备份没这 8 字段). 这是可接受的 (老备份 = 老数据).
- **PDF package 版本**: pubspec 锁 `pdf: ^3.11.1` + `printing: ^5.13.4`, 跟 MedicationReportPdf 同版本, 兼容 OK.

## ARB key 列表

```
cbtExportPdfButton       "导出 CBT 思维记录 PDF"
cbtExportPdfDialogTitle  "选择日期范围"
cbtExportPdfEmpty        "还没有 5/7 栏 CBT 数据可导出"
cbtExportPdfSuccess      "已导出 {count} 条 CBT 思维记录到 PDF"
cbtExportPdfFailed       "导出失败, 请重试"
cbtExportPdfSection1     "情境"
cbtExportPdfSection2     "自动思维"
cbtExportPdfSection3     "证据 (支持 / 反对)"
cbtExportPdfSection4     "替代思维 + 重新评分"
cbtExportPdfSection5     "核心信念 + 行为应对"
```

## 实施步骤 (high level)

1. **Task 1**: 修 silent data loss (export_orchestrator + export_import_pipeline)
2. **Task 2**: CbtThoughtRecordPdf 服务 + 1 个 layout helper
3. **Task 3**: settings 入口 button
4. **Task 4**: i18n + final review
5. **Task 5 (optional)**: PDF 单元 test (如果 task 2 包含就不单独)
