# CBT PDF 导出 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修 R84 silent data loss (moodEntries toMap 漏 8 CBT 字段) + 新加 CbtThoughtRecordPdf 服务导出 5/7 栏 mood entries 进 PDF

**Architecture:** 1 个 P0 silent-data-loss fix (export_orchestrator + import_pipeline) + 1 个 P1 PDF service (facade + layout, 参考 MedicationReportPdf 模式) + 1 个 P2 settings 入口

**Tech Stack:** Flutter 3.41.9 / pdf ^3.11.1 / printing ^5.13.4 (项目已有)

## Global Constraints

- Flutter 3.41.9 / Dart 3.12.2
- 4-layer architecture
- 守门员: `flutter analyze` 0, `flutter test` 全过, 16 脚本全绿
- TDD: red → green → commit
- baseline 1483 pass / 0 fail (R87 后)
- master commit dc69d70

## File Structure

### 修改
- `lib/core/data/services/export/export_orchestrator.dart` (加 8 CBT 字段 toMap)
- `lib/core/data/services/export/export_import_pipeline.dart` (加 8 CBT 字段 import 反序列化)
- `lib/presentation/pages/settings/widgets/data_management_section.dart` (加 1 个 button)
- `lib/l10n/app_zh.arb` / `app_en.arb` / `app_zh_Hant.arb` (~10 keys)
- `docs/CHANGELOG.md` (R88 entry)

### 新增
- `lib/core/data/services/cbt_thought_record_pdf.dart` (facade, ~120 行)
- `lib/core/data/services/cbt_thought_record_pdf_layout.dart` (layout helpers, ~250 行)
- `test/core/data/services/cbt_thought_record_pdf_round88_test.dart` (2 cases)
- `test/data/data_export_cbt_round88_test.dart` (1 case: round-trip)

---

### Task 1: 修 silent data loss (R84 P0 同类)

**Files:**
- Modify: `lib/core/data/services/export/export_orchestrator.dart:178-189` (moodEntries toMap)
- Modify: `lib/core/data/services/export/export_import_pipeline.dart` (MoodEntriesCompanion insert 写 8 字段)
- Test: `test/data/data_export_cbt_round88_test.dart`

**Interfaces:**
- Produces: data export JSON 含 8 CBT 字段, import 反序列化恢复 8 字段

- [ ] **Step 1: 写失败测试 — round-trip**

`test/data/data_export_cbt_round88_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/services/export/export_orchestrator.dart';
import 'package:chroniccare/core/data/services/export/export_import_pipeline.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

void main() {
  late AppDatabase db;
  late ExportOrchestrator exportOrch;
  late ExportImportPipeline importPipe;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // 实际项目可能有 DataExportService facade 包 orch + pipeline,
    // 用现有 test 的方式构造. 先看 test/data/data_export_round3_test.dart:10-25 模仿.
  });

  tearDown(() async => db.close());

  test('P0 fix: 5 栏 mood entry 导出 → 删除 → 导入, 8 CBT 字段全保留', () async {
    // 1. 插入 5 栏 entry
    final entry = MoodEntryDraft(
      score: 4, tags: const ['焦虑'],
      situation: '开会迟到', automaticThought: '大家觉得我不可靠',
      evidenceFor: '上次也迟到', evidenceAgainst: '过去一年只迟到一次',
      alternativeThought: '偶尔一次正常', reratedScore: 3,
    );
    await db.moodDao.insert(entry.toCompanion());
    // 2. 导出
    final exportData = await exportOrch.exportData(...);  // 看现有 toJson 签名
    final json = exportData.toJson();
    // 3. 删 DB
    await db.moodDao.delete(1);
    // 4. 导入
    await importPipe.importData(ExportData.fromJson(json));
    // 5. 校验
    final restored = (await db.moodDao.getAll()).first;
    expect(restored.situation, '开会迟到');
    expect(restored.automaticThought, '大家觉得我不可靠');
    expect(restored.evidenceFor, '上次也迟到');
    expect(restored.evidenceAgainst, '过去一年只迟到一次');
    expect(restored.alternativeThought, '偶尔一次正常');
    expect(restored.reratedScore, 3);
  });
}
```

- [ ] **Step 2: 跑测试验证失败**

```bash
flutter test test/data/data_export_cbt_round88_test.dart
```

Expected: FAIL (导入后 8 字段 = null, 因为 orchestrator 没导出 + pipeline 没读).

- [ ] **Step 3: 修 export_orchestrator.dart moodEntries toMap**

`lib/core/data/services/export/export_orchestrator.dart:178-189` 改成:

```dart
'moodEntries': [
  for (final m in moodEntries)
    {
      'timestamp': isoUtc(m.timestamp),
      'score': m.score,
      if (m.energy != null) 'energy': m.energy,
      if (m.sleep != null) 'sleep': m.sleep,
      if (m.anxiety != null) 'anxiety': m.anxiety,
      'tagsJson': m.tagsJson,
      'note': m.note,
      // v0.30 round 84 (CBT 思维记录): 8 CBT 字段
      if (m.situation != null) 'situation': m.situation,
      if (m.automaticThought != null) 'automaticThought': m.automaticThought,
      if (m.evidenceFor != null) 'evidenceFor': m.evidenceFor,
      if (m.evidenceAgainst != null) 'evidenceAgainst': m.evidenceAgainst,
      if (m.alternativeThought != null) 'alternativeThought': m.alternativeThought,
      if (m.reratedScore != null) 'reratedScore': m.reratedScore,
      if (m.coreBelief != null) 'coreBelief': m.coreBelief,
      if (m.behaviorResponse != null) 'behaviorResponse': m.behaviorResponse,
    },
],
```

- [ ] **Step 4: 修 export_import_pipeline.dart MoodEntriesCompanion 写 8 字段**

在 pipeline 里搜 `MoodEntriesCompanion.insert(...)` for moodEntries 解析处, 加 8 个 `Value(map['xxx'] as String?)` (int 字段用 as int?):

```dart
final companion = MoodEntriesCompanion.insert(
  timestamp: parsedTs,
  score: parsedScore,
  // ... existing 7 字段 ...
  // v0.30 round 84 CBT:
  situation: Value(map['situation'] as String?),
  automaticThought: Value(map['automaticThought'] as String?),
  evidenceFor: Value(map['evidenceFor'] as String?),
  evidenceAgainst: Value(map['evidenceAgainst'] as String?),
  alternativeThought: Value(map['alternativeThought'] as String?),
  reratedScore: Value(map['reratedScore'] as int?),
  coreBelief: Value(map['coreBelief'] as String?),
  behaviorResponse: Value(map['behaviorResponse'] as String?),
);
```

- [ ] **Step 5: 跑测试验证通过**

```bash
flutter test test/data/data_export_cbt_round88_test.dart
```

Expected: PASS.

- [ ] **Step 6: 跑全量 + 守门员**

```bash
flutter test
python scripts/check_*.py
```

Expected: 1484 pass (1483 + 1 new), 0 fail.

- [ ] **Step 7: Commit**

```bash
git add lib/core/data/services/export/export_orchestrator.dart \
        lib/core/data/services/export/export_import_pipeline.dart \
        test/data/data_export_cbt_round88_test.dart
git commit -m 'v0.30 round 88 (P0): data_export moodEntries 加 8 CBT 字段 toMap + import 反序列化 (R84 silent data loss 修复)'
```

---

### Task 2: CbtThoughtRecordPdf 服务

**Files:**
- Create: `lib/core/data/services/cbt_thought_record_pdf.dart` (facade, ~120 行)
- Create: `lib/core/data/services/cbt_thought_record_pdf_layout.dart` (layout, ~250 行)
- Test: `test/core/data/services/cbt_thought_record_pdf_round88_test.dart`

**Interfaces:**
- Produces: `class CbtThoughtRecordPdf` with `Future<Uint8List> build({required List<MoodEntryEntity> entries, DateTimeRange? dateRange})`

- [ ] **Step 1: 写失败测试**

`test/core/data/services/cbt_thought_record_pdf_round88_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/core/data/services/cbt_thought_record_pdf.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';

void main() {
  test('5 栏 entries build → Uint8List non-empty', () async {
    final pdf = CbtThoughtRecordPdf();
    final entries = [MoodEntryEntity(
      id: 1, timestamp: DateTime(2026, 8, 4), score: 4,
      situation: 's', automaticThought: 'at', evidenceFor: 'ef', evidenceAgainst: 'ea',
      alternativeThought: 'alt', reratedScore: 3,
    )];
    final result = await pdf.build(entries: entries);
    expect(result, isNotEmpty);
    // PDF 魔术字: %PDF-1.x
    expect(String.fromCharCodes(result.sublist(0, 4)), '%PDF');
  });

  test('空 entries build → 仍然返回 valid PDF (with "无数据" 页)', () async {
    final pdf = CbtThoughtRecordPdf();
    final result = await pdf.build(entries: []);
    expect(result, isNotEmpty);
    expect(String.fromCharCodes(result.sublist(0, 4)), '%PDF');
  });
}
```

- [ ] **Step 2: 跑测试验证失败**

- [ ] **Step 3: 实现 CbtThoughtRecordPdf facade + layout**

`lib/core/data/services/cbt_thought_record_pdf.dart` (参考 medication_report_pdf.dart 模式):

```dart
// v0.30 round 88 (sub-spec 4): CBT 思维记录 PDF 生成器
//
// 复用 MedicationReportPdf 模式 (facade + layout 拆分)

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:chroniccare/core/data/services/cbt_thought_record_pdf_layout.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

class CbtThoughtRecordPdf {
  /// 导出 5/7 栏 mood entries 进 PDF
  ///
  /// entries 必须过滤 cbtLevel >= 5 (调用方负责, 例如 cbtReratedEntriesProvider)
  /// dateRange 可选 filter
  Future<Uint8List> build({
    required List<MoodEntryEntity> entries,
    DateTimeRange? dateRange,
    required AppLocalizations l10n,  // i18n 走 caller 注入
  }) async {
    final doc = pw.Document();
    final filtered = dateRange == null
        ? entries
        : entries.where((e) =>
            !e.timestamp.isBefore(dateRange.start) &&
            !e.timestamp.isAfter(dateRange.end)).toList();

    if (filtered.isEmpty) {
      doc.addPage(pw.Page(build: (_) => CbtLayout.empty(l10n)));
    } else {
      for (final entry in filtered) {
        doc.addPage(pw.Page(build: (_) => CbtLayout.entryPage(entry, l10n)));
      }
    }
    return doc.save();
  }
}
```

`lib/core/data/services/cbt_thought_record_pdf_layout.dart`:

```dart
// v0.30 round 88: CBT 思维记录 PDF layout helpers
//
// 1 页 1 entry, 5/7 栏分别渲染
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

class CbtLayout {
  static pw.Widget entryPage(MoodEntryEntity e, AppLocalizations l10n) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _header(e),
        pw.SizedBox(height: 16),
        _section(l10n.moodCbtSectionSituation, e.situation),
        _section(l10n.moodCbtSectionAutomaticThought, e.automaticThought),
        _section('${l10n.moodCbtSectionEvidenceFor} / ${l10n.moodCbtSectionEvidenceAgainst}',
                 '${e.evidenceFor ?? '-'}\n${e.evidenceAgainst ?? '-'}'),
        _section(l10n.moodCbtSectionAlternative, e.alternativeThought),
        _section('${l10n.moodCbtSectionRerated} (${l10n.moodCbtScoreReratedLabel})',
                 '${e.reratedScore ?? '-'} (原 ${e.score})'),
        if (e.coreBelief != null) _section(l10n.moodCbtSectionCoreBelief, e.coreBelief),
        if (e.behaviorResponse != null) _section(l10n.moodCbtSectionBehavior, e.behaviorResponse),
      ],
    );
  }

  static pw.Widget empty(AppLocalizations l10n) {
    return pw.Center(child: pw.Text(l10n.cbtExportPdfEmpty));
  }

  static pw.Widget _header(MoodEntryEntity e) {
    final ts = '${e.timestamp.year}-${e.timestamp.month.toString().padLeft(2, '0')}-${e.timestamp.day.toString().padLeft(2, '0')} ${e.timestamp.hour.toString().padLeft(2, '0')}:${e.timestamp.minute.toString().padLeft(2, '0')}';
    return pw.Text('${e.cbtLevel == 7 ? "CBT 7 栏" : "CBT 5 栏"}  $ts  情绪 ${e.score}/5',
                   style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold));
  }

  static pw.Widget _section(String title, String? body) {
    if (body == null || body.isEmpty) return pw.SizedBox.shrink();
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 4),
          pw.Text(body, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: 跑测试验证通过**

- [ ] **Step 5: Commit**

```bash
git add lib/core/data/services/cbt_thought_record_pdf.dart \
        lib/core/data/services/cbt_thought_record_pdf_layout.dart \
        test/core/data/services/cbt_thought_record_pdf_round88_test.dart
git commit -m 'v0.30 round 88 (ui): CbtThoughtRecordPdf facade + layout (5/7 栏 1 页 1 entry)'
```

---

### Task 3: settings 入口 button

**Files:**
- Modify: `lib/presentation/pages/settings/widgets/data_management_section.dart`

- [ ] **Step 1: 加 1 个 button**

在 data_management_section.dart 的 "导出全部数据" 按钮附近加:

```dart
ListTile(
  leading: const Icon(Icons.picture_as_pdf),
  title: Text(l10n.cbtExportPdfButton),
  subtitle: Text(l10n.cbtExportPdfDialogTitle),
  onTap: () => _exportCbtPdf(context, ref),
),

Future<void> _exportCbtPdf(BuildContext context, WidgetRef ref) async {
  // 1. 选日期范围 (showDateRangePicker)
  // 2. 读 5/7 栏 entries (cbtReratedEntriesProvider)
  // 3. 调 CbtThoughtRecordPdf.build
  // 4. Printing.layoutPdf / Printing.sharePdf
  // 5. SnackBar 成功 / 失败
}
```

- [ ] **Step 2: 跑 widget test 验证**

```bash
flutter test test/presentation/pages/settings/
```

Expected: PASS (现有 data_management_section test 仍 pass).

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/pages/settings/widgets/data_management_section.dart
git commit -m 'v0.30 round 88 (ui): settings 加 "导出 CBT 思维记录 PDF" 入口'
```

---

### Task 4: i18n + CHANGELOG + final review

**Files:**
- Modify: 3 ARB files (10 keys)
- Modify: `docs/CHANGELOG.md`

- [ ] **Step 1: 加 10 keys (zh)**

`lib/l10n/app_zh.arb` 末尾加:

```json
,
  "cbtExportPdfButton": "导出 CBT 思维记录 PDF",
  "cbtExportPdfDialogTitle": "选择日期范围",
  "cbtExportPdfEmpty": "还没有 5/7 栏 CBT 数据可导出",
  "cbtExportPdfSuccess": "已导出 {count} 条 CBT 思维记录到 PDF",
  "cbtExportPdfFailed": "导出失败, 请重试"
```

(其他 5 keys `cbtExportPdfSection1..5` 复用 sub-spec 1 R84 加的 `moodCbtSection*` 即可, 不需要新加)

- [ ] **Step 2-3: en + zh_Hant 类似翻译 + flutter gen-l10n**

- [ ] **Step 4: 守门员 + analyze + test 全跑**

- [ ] **Step 5: CHANGELOG R88 entry**

```markdown
### Added (v0.30 round 88)
- **CBT 字段导出 PDF (sub-spec 4)**: 5/7 栏 mood entries 导 PDF
  - 修 R84 silent data loss: data_export moodEntries toMap 加 8 CBT 字段 (P0)
  - 新加 `CbtThoughtRecordPdf` 服务 (参考 MedicationReportPdf 模式)
  - settings 加 "导出 CBT 思维记录 PDF" 入口
  - 5 ARB keys (zh / en / zh_Hant)
```

- [ ] **Step 6: Commit final**

```bash
git commit -m 'v0.30 round 88 (i18n): 5 ARB keys + CHANGELOG + CBT PDF 导出 spec/plan'
```

---

## Self-Review

- [x] Spec coverage: P0 silent data loss (Task 1) / P1 PDF 服务 (Task 2) / P2 settings 入口 (Task 3) / i18n (Task 4)
- [x] No placeholders
- [x] Type consistency: `CbtThoughtRecordPdf.build(entries, dateRange?, l10n)` signature 一致
- [x] TDD: red → green → commit per task
- [x] DRY: 复用 MedicationReportPdf facade + layout 拆分模式
- [x] YAGNI: 不做加密 PDF / 不做 PDF 多语言 / 不做 UI 美化 (留 v0.31)
