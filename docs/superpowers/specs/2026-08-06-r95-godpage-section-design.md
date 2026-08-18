# R95 God Page Section Split — Design Spec

> **重建日期**: 2026-08-18 (从代码注释推断)
> **原始 spec 已删**, 基于代码内 R95/R116 注释推断

## 1. 背景

项目早期 God Page 集中化倾向严重, 单个 widget 文件超过 600 行 (`MoodTrendPage` 原始 653 行, `MedicationPage` 380 行)。R95 起多轮拆 god page + section, 改善可维护性。

## 2. 目标

- 单一 widget 文件 ≤ 400 行
- 业务逻辑 → `lib/domain/logic/` 纯函数
- 视觉组件 → `lib/features/*/presentation/pages/*/widgets/`
- 状态提升 + props callback 模式

## 3. 已完成的拆分布局

### 3.1 MoodTrendPage 拆分 (R95 + R116)

**位置**: `lib/features/mood/presentation/pages/mood_list/mood_trend_page.dart:1-12` 注释明确 "R116: 653L god class → 拆 4 文件"

**拆分结果**:
- `lib/features/mood/presentation/pages/mood_list/mood_trend_page.dart` (104 行) — 主页面
- `lib/domain/logic/mood_trend_calculator.dart` — 纯函数 + enum
- `lib/features/mood/presentation/pages/mood_list/widgets/mood_trend_line_chart.dart` — 折线图
- `lib/features/mood/presentation/pages/mood_list/widgets/mood_distribution_chart.dart` — 分布图
- `lib/features/mood/presentation/pages/mood_list/widgets/mood_cbt_chart.dart` — CBT 重评图

### 3.2 MedicationPage 拆分 (R116 round 4)

**位置**: `lib/features/medication/presentation/pages/medication/medication_page.dart:1-19` 注释 (R31 11a + R116 瘦身 380→~280)

**拆分结果**:
- 主页面 286 行
- `_SlotEntryRow` (92L) → `widgets/medication_slot_entry_row.dart`
- 21 个子 widget

### 3.3 AssessmentPage 拆分 (R92)

**位置**: `lib/features/assessment/presentation/pages/assessment_page.dart` (312 行)

**拆分结果**:
- `AssessmentQuizPanel` + `AssessmentResultPanel` props callback 模式
- 9 个拆分子组件

### 3.4 MoodReviewPage 拆分 (round 5e Task 15)

**位置**: `lib/features/mood/presentation/pages/mood_list/mood_review_page.dart` (234 行)

**拆分结果**:
- 纯函数聚合器 → `lib/domain/logic/mood_review_aggregator.dart`

## 4. 关键设计决策

- **状态提升**: 子组件通过 props 接收数据 + callback 抛事件
- **纯函数优先**: 业务规则放 `lib/domain/logic/`, 0 Flutter 0 Drift 依赖
- **widget 集中器**: `lib/presentation/widgets/` 提供通用 AppleHealthTile / AppleListSection / PageScaffold
- **R95 多轮拆分**: 多 god page 多 round 持续拆, 不一次性完成

## 5. 实施状态

✅ 主线 god page 拆分完成。后续 feature-first 重构 (R110-R128) 进一步拆到 package 级别。

## 6. 关键文件

| 路径 | 行数 | 角色 |
|---|---|---|
| `lib/features/mood/presentation/pages/mood_list/mood_trend_page.dart` | 104 | 趋势页主 |
| `lib/domain/logic/mood_trend_calculator.dart` | — | 趋势纯函数 |
| `lib/features/mood/presentation/pages/mood_list/widgets/mood_trend_line_chart.dart` | — | 折线图 |
| `lib/features/mood/presentation/pages/mood_list/widgets/mood_distribution_chart.dart` | — | 分布图 |
| `lib/features/mood/presentation/pages/mood_list/widgets/mood_cbt_chart.dart` | — | CBT 图 |
| `lib/features/medication/presentation/pages/medication/medication_page.dart` | 286 | 用药页主 |
| `lib/features/medication/presentation/pages/medication/widgets/medication_slot_entry_row.dart` | 92 | 时段行子组件 |
| `lib/features/assessment/presentation/pages/assessment_page.dart` | 312 | 单量表答题 |
| `lib/features/mood/presentation/pages/mood_list/mood_review_page.dart` | 234 | 情绪回顾 |
| `lib/domain/logic/mood_review_aggregator.dart` | — | 情绪回顾聚合 |
| `docs/architecture/FEATURE_FIRST_PLAN.md` | 12.5KB | R110 + R125 5 阶段路线 |

## 7. 关联

- Feature-first 渐进重构: R110 + R125 + R126 + R127 + R128
- 设计 token 集中器: `packages/chroniccare_theme/`
- PageScaffold 通用页面骨架: `lib/presentation/widgets/page_scaffold.dart`

## 8. 局限

- ❌ R95 完整 god page 列表
- ❌ 每轮拆分的时间投入
- ❌ 拆分前后可维护性度量