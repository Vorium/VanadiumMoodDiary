# superpowers-zh 视角报告 (2026-08-09)

**评分**: 9.0/10
**基线**: R103 (2026-08-08)

## 中文架构/本地化审查

### 优点
- P0 硬编码中文全走 ARB (R95 sub-spec 3+7)
- app_database.dart 1499→0 中文注释翻译
- 18 ARB 守门员 (check_arb_keys + check_orphan_arb_keys + check_zh_hant_consistency)
- 3 语 ARB 同步 (zh/en/zh_Hant)
- 30+ 硬编码中文 → ARB (R65/R78/R90 + R95)

### 问题 — 硬编码中文残留 (用户可见)

| # | 文件:行 | 内容 | 难度 | 优先级 |
|---|---------|------|------|--------|
| Z1 | mood_detail_page.dart:219 | "录音" | 简单 | P0 |
| Z2 | mood_detail_page.dart:256 | "删除" | 简单 | P0 |
| Z3 | add_medication_page.dart:68 | "请输入药物名称" | 简单 | P0 |
| Z4 | add_medication_page.dart:112 | "已添加" | 简单 | P0 |
| Z5 | medication_page.dart:442 | "在用"/"已停" | 简单 | P0 |
| Z6 | today_summary_card.dart | 4 处硬编码中文 | 简单 | P0 |
| Z7 | daily_tracking_multi_chart.dart | 4 处硬编码中文 | 简单 | P0 |
| Z8 | mood_factor_analysis.dart:147 | "条" | 简单 | P1 |
| Z9 | safetyCheckResultAlertedMocked | "**开发模式** mock" | 简单 | P0 |

### 问题 — domain 层硬编码中文

| # | 文件:行 | 内容 | 难度 | 优先级 |
|---|---------|------|------|--------|
| Z10 | influence_category.dart:36-71 | 36 个中文影响因素 | 中 | P1 |
| Z11 | care_copy.dart:33-57 | 全部关怀文案硬编码中文 | 中 | P1 |
| Z12 | assessment_comparison.dart:68-79 | 趋势标签硬编码中文 | 简单 | P1 |
