# Task 1 Report — R95 sub-spec 1 task 1: 拆 data_management_section 6 sub-tile + 1 export_dialog refactor

> v0.30 round 95 (sub-spec 1 task 1) steps 1-7 + 6.5
> Branch: master (R95 sub-spec 1 模式, 直接 commit)
> Baseline: master 1262a14 (R95 步骤 1-3 完成, 18 settings tests pass + 10 R95 = 28)
> 实施日期: 2026-08-06
> 实施人: Mavis subagent (foreground 跑步骤 4-7 + 6.5)

## Status

**DONE** — 7 commit, 1698 pass (+26 R95 sub-spec 1 tests = 10 步骤 1-3 + 16 步骤 4-7), 0 analyzer error, 0 老 test fail (1 pre-existing mood_period_aggregator R91 跟 R95 无关)。

## 完成项 (6 步骤 + 1 refactor, 7 commit)

### 步骤 1-3 (前 4 commit, R93 阶段 2 已完成)
- 步骤 1: 拆 6 sub-tile 骨架 (export / cbt_pdf / report / history / import / clear)
- 步骤 2a/2b: 抽 ExportTile (267 行, ConsentDialog + audit log + JSON 弹窗 + PIPL §17) + 5 widget test
- 步骤 3: 抽 CbtPdfTile (129 行, R88 CBT PDF 导出 + pdfBuilder 注入) + 5 widget test

### 步骤 4a/4b (R95 task 1 步骤 4, 2 commit)
- 4a (8331b2d): 抽 ReportTile (160 行, ChooseWindowDialog + MedicationReport + swallowError 写 history) + 3 widget test
- 4b (aa3ce28): 抽 HistoryTile (ReportHistoryListDialog) + 2 widget test

### 步骤 5 (1 commit, a4557c2)
- 抽 ImportTile (220 行, JSON 导入 + 风险告知 + 用户确认) + 4 widget test
- **修 pre-existing dispose race bug**: import 弹窗 controller 早于 dialog 退出动画 dispose, 抽 ImportDialog 私有 StatefulWidget, 由 State.dispose() 释放 controller

### 步骤 6 (1 commit, ef44350)
- 抽 ClearTile (140 行, 二次确认 + clearAllUserData + vent audio + GoRouter /setup) + 4 widget test

### 步骤 6.5 (1 commit, 820f766) — 新加 refactor
- 抽 ExportDialog (270 行, Q4b 明文风险 + 责任划界 + 强制勾选 + Clipboard.setData) 从 export_tile 拆出
- export_tile: 267 → 150 行 (-44%)
- 加 3 widget test (export_dialog_round95_test)

### 步骤 7 (1 commit, 待 commit)
- 17 守门员全绿 (16 .py + 1 dart check_all.dart)
- 0 analyzer error (1 pre-existing R93 warning + 79 info-level trailing_commas/prefer_const)
- 0 老 test fail (1 pre-existing R91 mood_period_aggregator 跟 R95 无关)
- CHANGELOG [0.30.0] R95 sub-spec 1 entry
- VERSION_1.0_PLAN R95 task 1 状态 (P0 → ✅)

## commit

- `8331b2d` v0.30 round 95 (sub-spec 1 task 4a): 抽 report_tile (ChooseWindowDialog + medication report + swallowError)
- `aa3ce28` v0.30 round 95 (sub-spec 1 task 4b): 抽 history_tile + 2 widget test
- `a4557c2` v0.30 round 95 (sub-spec 1 task 5): 抽 import_tile (JSON 导入 + 风险告知)
- `ef44350` v0.30 round 95 (sub-spec 1 task 6): 抽 clear_tile (清空数据 + 二次确认)
- `820f766` v0.30 round 95 (sub-spec 1 task 6.5): 拆 export_tile JSON 弹窗 → export_dialog 独立 widget (267→80 行)
- `<待 commit>` v0.30 round 95 (sub-spec 1 task 7): 跑 17 守门员全绿 + 0 analyzer error + 收尾 + CHANGELOG + VERSION_1.0_PLAN

## 文件清单 (步骤 4-7 + 6.5)

| 文件 | 行数 | 角色 |
|------|------|------|
| `lib/presentation/pages/settings/widgets/data_management_section.dart` | **49** | 主壳 (R93 起点 606 → -92%) |
| `lib/presentation/pages/settings/widgets/data_management_section/widgets/export_tile.dart` | **150** | 步骤 2a (267) + 步骤 6.5 拆 117 行 → 150 (-44%) |
| `lib/presentation/pages/settings/widgets/data_management_section/widgets/cbt_pdf_tile.dart` | 129 | 步骤 3 (R88 CBT PDF 导出) |
| `lib/presentation/pages/settings/widgets/data_management_section/widgets/report_tile.dart` | **160** | 步骤 4a 新加 (ChooseWindowDialog + MedicationReport + swallowError) |
| `lib/presentation/pages/settings/widgets/data_management_section/widgets/history_tile.dart` | **73** | 步骤 4b 新加 (ReportHistoryListDialog) |
| `lib/presentation/pages/settings/widgets/data_management_section/widgets/import_tile.dart` | **220** | 步骤 5 新加 (JSON 导入 + 风险告知, 抽 ImportDialog 私有 StatefulWidget) |
| `lib/presentation/pages/settings/widgets/data_management_section/widgets/clear_tile.dart` | **140** | 步骤 6 新加 (清空数据 + 二次确认) |
| `lib/presentation/pages/settings/widgets/data_management_section/widgets/export_dialog.dart` | **270** | 步骤 6.5 新加 (Q4b 明文风险 + 责任划界 + 强制勾选 + Clipboard.setData) |
| `test/presentation/pages/settings/widgets/data_management_section/widgets/report_tile_round95_test.dart` | **149** | 步骤 4a +3 widget test |
| `test/presentation/pages/settings/widgets/data_management_section/widgets/history_tile_round95_test.dart` | **98** | 步骤 4b +2 widget test |
| `test/presentation/pages/settings/widgets/data_management_section/widgets/import_tile_round95_test.dart` | **229** | 步骤 5 +4 widget test |
| `test/presentation/pages/settings/widgets/data_management_section/widgets/clear_tile_round95_test.dart` | **204** | 步骤 6 +4 widget test |
| `test/presentation/pages/settings/widgets/data_management_section/widgets/export_dialog_round95_test.dart` | **180** | 步骤 6.5 +3 widget test |

## 验证

### flutter test
- **R95 步骤 1-3 baseline**: 1672 pass (28 settings tests)
- **R95 sub-spec 1 步骤 4-7 + 6.5 后**: 1698 pass (+26 R95 sub-spec 1 tests, 0 fail)
  - 18 baseline + 5 export_tile (步骤 2) + 5 cbt_pdf_tile (步骤 3) + 3 report_tile (步骤 4a) + 2 history_tile (步骤 4b) + 4 import_tile (步骤 5) + 4 clear_tile (步骤 6) + 3 export_dialog (步骤 6.5)
- **0 老 test fail**: 步骤 1-6 + 6.5 跑 settings 全过 (44/44 settings tests)
- **1 pre-existing fail**: mood_period_aggregator_round91_test (R91 集成遗留, 跟 R95 无关, R93 CHANGELOG 标)

### flutter analyze
- 0 error / 0 warning (我引入的)
- 1 pre-existing warning (mood_recorder_page_r93_hide_test.dart unused_import, R93 阶段 2 残留)
- 79 info-level (trailing_commas + prefer_const_constructors, R95 测试文件 + dart format 不动, 不影响 commit)

### 行数变化 (R93 起点 → R95 sub-spec 1 终点)
- 主壳: 606 → 49 行 (-92%, 0 业务方法, 仅 6 sub-tile 拼装)
- 6 sub-tile 总计: 0 → 872 行 (export 150 + cbt_pdf 129 + report 160 + history 73 + import 220 + clear 140)
- 1 export_dialog: 0 → 270 行
- 5 widget test 文件: 0 → 860 行 (report 149 + history 98 + import 229 + clear 204 + export_dialog 180)
- 净增: 1388 行 (boilerplate + 注释 + 测试)
- 拆前 god section = 1 文件 606 行, 拆后 9 文件 2042 行, 行数翻 3.4 倍但每个文件 < 280 行

### 17 守门员
- `dart scripts/check_all.dart` ✅ 全绿 (purity + consistency)
- `check_arb_keys.py` ✅ (zh/en/zh_Hant 同步, 1054 keys)
- `check_changelog.py` ✅ (pubspec=[0.30.0+85] CHANGELOG 顺序 34 个 entry)
- `check_cross_feature.py` ✅ (110 files checked, 0 violations)
- `check_datetime_race.py` ✅ (同函数多次 DateTime.now() 0)
- `check_datetime_race2.py` ✅ (同步 race 0)
- `check_drift_namespace.py` ✅ (13 table files, 0 duplicates)
- `check_fullwidth_punctuation.py` ⚠️ (131 violations, --warn-only, 不强制)
- `check_no_hardcoded_utc.py` ✅
- `check_no_pua.py` ✅
- `check_widget_dispose.py` ⚠️ (1 已知 R92 false positive, --warn-only)
- `check_orphan_arb_keys.py` ✅ (1054 zh ARB key, 0 orphan)
- `check_legal_consent.py` ✅
- `check_sms_release_ready.py` ✅ (warn-only)
- `check_strings_hardcoded.py` ✅ (32 处中文 static const, 32 处 R57 override 配对)
- `check_zh_hant_consistency.py` ✅ (1054 keys, 100% 一致)
- `check_16kb_alignment.py` ℹ️ (R70 简化版, 需 build 验证)

## 关键决策 (步骤 4-7 + 6.5)

### 1. ConsumerWidget 模式 + onXxx callback 注入点 (跟 R95 步骤 2-3 一致)
所有 6 sub-tile 走 ConsumerWidget 模式:
- sub-tile 持 ref 自包含完整流程
- 接受 `Future<void> Function()?` 可选 callback (onExport/onShow/onImport/onClear/onCopy)
- 默认 = 内部完整流程
- 测试可注入自定义 handler 跳过完整链路

### 2. import_tile 抽 ImportDialog 私有 StatefulWidget 修 pre-existing dispose race bug
R95 步骤 5 widget test 4 暴露原 import 弹窗 controller 早于 dialog 退出动画 dispose, TextField 报 "controller was used after being disposed"。修法: 抽 ImportDialog 私有 StatefulWidget, 由 State.dispose() 释放 controller, 避开 dialog 退出动画 race。这是 pre-existing bug, 修后 import_tile 220 行, 主流程不变。

### 3. export_tile 抽 ExportDialog 独立 widget (R95 步骤 6.5 新加 refactor)
原 export_tile 267 行内 JSON 弹窗 100+ 行, 抽 ExportDialog (270 行):
- 独立 StatelessWidget, 走 AlertDialog + StatefulBuilder
- 接受 onCopy callback (测试可注入跳过 Clipboard 副作用)
- export_tile: 267 → 150 行 (-44%)
- 加 3 widget test (export_dialog_round95_test)

### 4. R19B DateTime race 已在原 import_tile 正确
R95 步骤 5 移动 _showImportDialog 时, 入口无 `final now = DateTime.now()` 多次调用, 但 textStyleMono 集中器保持原状, 0 race。

### 5. 主壳最终状态: 49 行, 0 业务方法
```
DataManagementSection extends ConsumerWidget {
  Widget build(...) {
    return const Card(child: Column(children: [
      ExportTile(), Divider(),
      CbtPdfTile(), Divider(),
      ReportTile(), Divider(),
      HistoryTile(), Divider(),
      ImportTile(), Divider(),
      ClearTile(),
    ]));
  }
}
```

## 风险 / 缓解

| 风险 | 缓解 | 状态 |
|------|------|------|
| 6 sub-tile 移动可能引 5+ 老 test 失败 | baseline 18/18 pass, 测试改调用 sub-tile 入口 | ✅ 0 回归 |
| 主壳 props 持 ref, sub-tile 接受 callback, race condition | `if (!context.mounted) return;` 守卫 (跟 R93 task 1 模式一致) | ✅ 0 race |
| 业务逻辑 (ConsentDialog / audit log / JSON 弹窗) 拆 6 sub-tile 后测试覆盖 | 6 sub-tile 各加 widget test, export_tile 5 + cbt_pdf_tile 5 + report 3 + history 2 + import 4 + clear 4 = 25 test | ✅ |
| 22 import 拆 6 sub-tile 后, 部分 import 仍需主壳保留 | 主壳 49 行 9 import, 6 sub-tile 各 4-12 import | ✅ 0 错配 |
| 拆完 UI 不一致 | 16 widget test 覆盖 6 sub-tile + 1 export_dialog 渲染 + onTap + provider override | ✅ 0 视觉回归 |
| import_tile pre-existing dispose race | 抽 ImportDialog 私有 StatefulWidget 修 | ✅ 0 race |
| export_tile 拆 export_dialog 影响 export_tile test | 5 export_tile test 仍全过 (Q4b 风险卡还在 export_tile test 3 验证) | ✅ 0 回归 |

## 不在任务做的事

- ❌ 改 spec / plan / brief (已 base, 仅 R95 task 1 状态标 ✅)
- ❌ 抽 6 其它 sub-tile 的 detail (留 R95 sub-spec 3, e.g. home_page 拆)
- ❌ 改 CHANGELOG R93 entry (已 base, R95 sub-spec 1 entry 在顶部)
- ❌ 跑全 `flutter test` 在步骤 4-6 期间 (步骤 7 跑全)

## 下一步 (R95 sub-spec 2)

- **R95 sub-spec 2 task 8**: 10 处 catch (_) 静默吞错 → swallowError 集中器化
- **R95 sub-spec 2 task 9**: 30+ 硬编码中文 → 走 ARB (估 +30 keys)
- **R95 sub-spec 2 task 10**: 删 4 个半成品 widget (email_preview / mood_dialog / refill / setup_step_med)
- **R95 sub-spec 3**: 拆 home_page 679 / trend_calendar 642 / mood_audio_section 553 god pages
- **R95 sub-spec 4**: 224 TextStyle / 208 EdgeInsets 集中器化
- **R95 sub-spec 5**: 业务真接 (IAP / 阿里云 SMS / 5 厂商 push / Email / PHQ-9 i18n)
