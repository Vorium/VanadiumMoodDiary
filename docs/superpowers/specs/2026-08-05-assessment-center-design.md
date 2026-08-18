# Assessment Center Design — Spec

> **重建日期**: 2026-08-18 (从代码重建)
> **原始 spec 已删**, 基于 `lib/features/assessment/` + `lib/domain/logic/scale_registry.dart` 推断

## 1. 背景

心理评估 (Assessment) 提供 10+ 标准量表, 用户周期性自评。R30 round 90 引入"评估中心"作为量表入口统一页, 替代散落在各处的单量表入口。

## 2. 目标

- 单一入口 `/assessment-center` 展示所有可用量表
- 10 张开放 + 2 张 unavailable 卡片 grid
- 顶部 mini 趋势图 (12 量表叠加 30 天)
- 量表题目 i18n 三语支持 (zh / en / zh_Hant)
- 危机信号自动检测 → 弹 CrisisSignal dialog

## 3. 实施状态

✅ 已实施。R90 + R92 P0#14 + R93 阶段 2 i18n 隐藏 (PHQ-9/GAD-7 默认 false)。

## 4. 关键文件

| 路径 | 行数 | 角色 |
|---|---|---|
| `lib/features/assessment/presentation/pages/assessment_center_page.dart` | 125 | 评估中心入口 (ConsumerWidget) |
| `lib/features/assessment/presentation/pages/assessment_page.dart` | 312 | 单量表答题页 |
| `lib/features/assessment/presentation/pages/assessment_history_page.dart` | 122 | 历史列表 |
| `lib/features/assessment/presentation/providers/assessment_providers.dart` | 2.4KB | Provider |
| `lib/features/assessment/presentation/widgets/*` | 9 个 | 拆分子组件 (CenterCard / UnavailableCard / QuizPanel / ResultPanel / SummaryStrip / ChartCard / HistoryList / Sparkline / ComparisonCard) |
| `lib/presentation/widgets/charts/assessment_multi_line_chart.dart` | — | 12 量表叠加 30 天趋势图 (80pt 高) |
| `lib/domain/logic/scale_registry.dart` | 35-46 | 10 量表注册 |
| `lib/domain/logic/assessment_scale.dart` | — | 量表 abstract base |
| `lib/domain/logic/phq9.dart` / `gad7.dart` / `isi.dart` / `pss.dart` / `whodas.dart` / `asrm.dart` / `level2_*.dart` (4) | — | 10 个量表实现 |
| `lib/domain/logic/assessment_comparison.dart` | — | 量表间对比 |
| `lib/domain/logic/assessment_record.dart` | — | 量表 entry record |
| `lib/domain/logic/assessment_reminder_policy.dart` | — | 评估提醒策略 |
| `lib/features/assessment/domain/entities/assessment_entry.dart` | — | Entity |
| `lib/core/data/database/daos/assessment_dao.dart` | — | DAO |
| `lib/features/assessment/domain/repositories/assessment_repository.dart` | — | Repository abstract |

## 5. 量表清单 (从 `scale_registry.dart` 推断)

10 开放:
1. PHQ-9 (抑郁)
2. GAD-7 (焦虑)
3. ISI (失眠严重度)
4. PSS (知觉压力量表)
5. WHODAS 2.0 (WHO 残疾评定)
6. DSM-5 Level 2 — Depression
7. DSM-5 Level 2 — Anxiety
8. DSM-5 Level 2 — Mania
9. DSM-5 Level 2 — Psychosis (age 17-24)
11. ASRM (Altman 自评躁狂量表)

2 永久关闭 (`unavailableScaleIds = ['nsesss', 'crdpss']` — R117 P2-6):
- NSESSS
- CRDPSS

## 6. UI 结构

```
AssessmentCenterPage (ConsumerWidget)
├── Header: "评估中心"
├── AssessmentMultiLineChart (80pt 高, 12 量表叠加 30 天)
├── GridView (crossAxisCount: 2)
│   ├── AssessmentCenterCard × 10
│   └── AssessmentUnavailableCard × 2 (灰显)
└── NavigationRow → AssessmentHistoryPage
```

## 7. 关键设计决策

- **量表 i18n**: PHQ-9 / GAD-7 共 16 题, R65b 阶段开启翻译, R93 默认 `FeatureFlags.phqGad7I18nEnabled = false` 隐藏卡片 (i18n 不充分)
- **危机检测**: `scale.detectCrisis(scores, result)` 在 `AssessmentPage:188-249` 弹 `CrisisSignal` dialog
- **顶部趋势图**: R90 Task 5 placeholder → R92 P0#14 替换为真实 `assessment_multi_line_chart.dart`
- **未开放卡片**: 灰显 + 文案解释, 用户不能误入 (避免半成品体验)
- **3 栏抽屉**: 答题 / 结果 / 历史 — 顶部 mini 图提供长期趋势概览

## 8. 路由

| 路径 | 来源 | Widget | Transition |
|---|---|---|---|
| `/assessment-center` | `app_route_assessment.dart:38-44` | `AssessmentCenterPage` | slide-right |
| `/assessment` | `app_route_assessment.dart:46-49` | redirect → `/assessment/phq9` | — |
| `/assessment/history` | `app_route_assessment.dart:52-59` | `AssessmentHistoryPage` | slide-right |
| `/assessment/:id` | `app_route_assessment.dart:60-67` | `AssessmentPage` | slide-right |

## 9. 数据模型

```dart
class AssessmentEntry {
  String id;
  DateTime timestamp;
  String scaleId;  // 'phq9' / 'gad7' / ...
  int totalScore;
  int severityRank;  // 0=normal, 1=mild, 2=moderate, 3=severe
  List<int> answers;  // 每题分数
  Map<String, dynamic> metadata;
}
```

## 10. 关联

- i18n 量表题目: `lib/domain/entities/scale_translations.dart` + 子目录
- 守门员: `scripts/check_arb_keys.py` + `check_orphan_arb_keys.py`
- 危机热线: `lib/features/crisis/` + `/crisis-hotline` 路由

## 11. 局限

- ❌ 原始 R90 task breakdown + R92 P0#14 修复的具体决策
- ❌ 10 量表选择标准 (为何 NSESSS / CRDPSS 永久关闭)
- ❌ `AssessmentMultiLineChart` 12 量表叠加的具体视觉设计