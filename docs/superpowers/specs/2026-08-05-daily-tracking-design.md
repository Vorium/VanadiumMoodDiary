# Daily Tracking Design — Spec

> **重建日期**: 2026-08-18 (从代码重建)
> **原始 spec 已删**, 基于 `lib/presentation/pages/daily_tracking/` + `lib/core/data/database/tables/daily_tracking/` 推断

## 1. 背景

日常追踪 (Daily Tracking) 是除 mood 主线外的辅助追踪功能, 涵盖 6 子模块: 睡眠 / 体重 / 应激源 / 社会节律 / 治疗 / 焦虑急躁。用户可自由开关 + 收藏常用。

## 2. 目标

- 6 子模块统一入口 `/daily-tracking`
- 用户可自定义开启/关闭子模块
- 跨日趋势图 (12.5KB 多指标)
- 4 段 (emotional / physical / behavioral / medical) 分类
- AppleListSection 风格卡片 (R112 EM-02/AH-04 改造)

## 3. 实施状态

✅ 已实施。v0.30 round 91 sub-spec 7 + R112 AppleListSection 改造。

## 4. 关键文件

| 路径 | 行数 | 角色 |
|---|---|---|
| `lib/presentation/pages/daily_tracking/daily_tracking_page.dart` | 346 | 主入口 (ConsumerWidget) |
| `lib/presentation/pages/daily_tracking/treatment_page.dart` | 3.8KB | 治疗子页 |
| `lib/presentation/pages/daily_tracking/tracking_customize_page.dart` | 7.9KB | 自定义开启/关闭 |
| `lib/presentation/pages/daily_tracking/widgets/*` | 6 个 | 子模块 widget (sleep/social_rhythm/stress_event/weight/anxiety_agitation/mood_period) |
| `lib/presentation/providers/daily_tracking_providers.dart` | 8.7KB | Provider |
| `lib/presentation/providers/tracking_config_provider.dart` | 4.4KB | 开关 + 收藏配置 |
| `lib/presentation/widgets/charts/daily_tracking_multi_chart.dart` | 12.5KB | 多指标趋势图 |
| `lib/core/data/database/tables/daily_tracking/sleep_entries.dart` | — | Sleep table |
| `lib/core/data/database/tables/daily_tracking/weight_entries.dart` | — | Weight table |
| `lib/core/data/database/tables/daily_tracking/stress_events.dart` | — | Stress table |
| `lib/core/data/database/tables/daily_tracking/social_rhythm_entries.dart` | — | Social rhythm table |
| `lib/core/data/database/tables/daily_tracking/treatment_entries.dart` | — | Treatment table |
| `lib/core/data/database/tables/daily_tracking/anxiety_agitation_entries.dart` | — | Anxiety/agitation table |
| `lib/core/data/database/daos/{sleep,weight,stress_event,social_rhythm,treatment,anxiety_agitation}_dao.dart` | 6 个 | DAO |
| `lib/domain/entities/{sleep,weight,stress_event,social_rhythm,treatment,anxiety_agitation}_entry.dart` | 6 个 | Entity |
| `lib/domain/logic/sleep_calculator.dart` | — | 睡眠时长 |
| `lib/domain/logic/bmi_calculator.dart` | — | BMI |

## 5. 6 子模块

| 子模块 | 表 | 类别 |
|---|---|---|
| SleepEntries | `sleep_entries` | physical |
| WeightEntries | `weight_entries` | physical |
| StressEvents | `stress_events` | emotional |
| SocialRhythmEntries | `social_rhythm_entries` | behavioral |
| TreatmentEntries | `treatment_entries` | medical |
| AnxietyAgitationEntries | `anxiety_agitation_entries` | emotional |

## 6. UI 结构

```
DailyTrackingPage (ConsumerWidget)
├── Header: "日常追踪"
├── TodayTrackingSummary (header 今日摘要)
├── AppleListSection "已开启"
│   ├── SleepListWidget
│   ├── WeightListWidget
│   ├── SocialRhythmListWidget
│   ├── StressEventListWidget
│   ├── TreatmentListWidget
│   └── AnxietyAgitationListWidget
│   (顺序按 pinnedItems config)
└── FAB → TrackingCustomizePage
```

## 7. 关键设计决策

- **TrackingCategory**: enum (emotional / physical / behavioral / medical) — 4 段分组
- **pinnedItems**: config 状态, 用户可拖拽排序
- **AppleListSection 改造**: R112 EM-02/AH-04 改 AppleListSection (daily_tracking_page.dart:84-97), 跟随 iOS 视觉
- **跨日趋势**: `daily_tracking_multi_chart.dart` 12.5KB 多指标叠加
- **心境 4 段图**: `mood_period_aggregator_chart.dart` 单独 widget
- **可定制化**: `/daily-tracking/customize` 让用户自由选择开启哪些子模块

## 8. 路由

| 路径 | 来源 | Widget | Transition |
|---|---|---|---|
| `/daily-tracking` | `app_route_daily_tracking.dart:43-51` | `DailyTrackingPage` | slide-right |
| `/daily-tracking/customize` | `app_route_daily_tracking.dart:112-119` | `TrackingCustomizePage` | slide-right |
| `/sleep` | `app_route_daily_tracking.dart:63-69` | `SleepListWidget` | slide-right |
| `/social-rhythm` | `app_route_daily_tracking.dart:71-78` | `SocialRhythmListWidget` | slide-right |
| `/stress-events` | `app_route_daily_tracking.dart:79-86` | `StressEventListWidget` | slide-right |
| `/weight` | `app_route_daily_tracking.dart:87-94` | `WeightListWidget` | slide-right |
| `/anxiety-agitation` | `app_route_daily_tracking.dart:95-102` | `AnxietyAgitationListWidget` | slide-right |
| `/treatment` | `app_route_daily_tracking.dart:103-110` | `TreatmentPage` | slide-right |

## 9. 关联

- 心境聚合: `lib/domain/logic/mood_period_aggregator.dart`
- 守门员: `scripts/check_cross_feature.py`
- Feature-first: R128 stages 4/5 期间 daily_tracking 仍在 `lib/presentation/pages/`

## 10. 局限

- ❌ Round 91 sub-spec 7 的具体决策
- ❌ 6 子模块选择标准 (为何不含运动 / 饮食?)
- ❌ pinnedItems 的具体 UX (是否有拖拽?)