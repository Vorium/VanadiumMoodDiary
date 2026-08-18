# Medication Page Redesign — Spec

> **重建日期**: 2026-08-18 (从代码 + pubspec 注释重建)
> **原始 spec 已删**, 本文档基于 `lib/` 实际代码推断, 设计缘由可能与原作者意图有出入。

## 1. 背景

用药管理 (medication) 是慢性病管理的核心 P1 功能。原 `MedicationPage` 设计较简单 (列表 + 添加按钮), R31 Apple Health redesign 后改为 iOS 风格可视化。

## 2. 目标

- iOS 17/18 "Apple Health favorites" 风格的 4 横滚 metric 模块 (110×140 顶部 tile)
- 今日 schedule + 我的药物 双 section 视觉分层
- 4 段时间窗计算 (早/中/晚/睡前)
- 3 步向导添加药物

## 3. 实施状态

✅ 已实施。R31 11a + R116 round 4 瘦身 380→~280 行 + R110 round 3 route 入 shell。

## 4. 关键文件

| 路径 | 行数 | 角色 |
|---|---|---|
| `lib/features/medication/presentation/pages/medication/medication_page.dart` | 286 | 主页面 (ConsumerWidget) |
| `lib/presentation/pages/medication/medication_page.dart` | 7 | re-export shim (R126 step 7) |
| `lib/features/medication/presentation/pages/medication/add_medication_page.dart` | 231 | 3 步向导添加 |
| `lib/features/medication/presentation/pages/medication/medication_detail_page.dart` | — | 详情 |
| `lib/features/medication/presentation/pages/medication/medication_calendar_page.dart` | — | 日历视图 |
| `lib/features/medication/presentation/pages/medication/refill_manage_page.dart` | — | 续方管理 |
| `lib/features/medication/presentation/pages/medication/widgets/today_med_schedule.dart` | — | 今日用药 schedule 子组件 |
| `lib/features/medication/presentation/pages/medication/widgets/*` | 21 个 | 拆分子组件 |
| `lib/domain/logic/medication_page_stats_calculator.dart` | — | 统计计算 |
| `lib/domain/logic/medication_slot_calculator.dart` | — | 4 时段窗口计算 |
| `lib/features/medication/domain/entities/medication_entity.dart` | — | Domain entity |
| `lib/features/medication/data/tables/medications.dart` | 50 | Drift table |
| `lib/core/data/database/daos/medication_dao.dart` | — | DAO |
| `lib/features/medication/data/services/medication_report_pdf.dart` | 71 | PDF 报告 facade |
| `lib/features/medication/data/services/medication_report_pdf_layout.dart` | 321 | PDF layout |

## 5. UI 结构 (从代码推断)

```
MedicationPage (ConsumerWidget)
├── AppleHealthTile 横滚 4 顶部模块 (110×140)
│   ├── MedicationHealthMetric (systemRed)
│   ├── MoodHealthMetric (systemPink)
│   ├── VentHealthMetric (systemPurple)
│   └── AssessmentHealthMetric (systemTeal)
├── AppleListSection "今日用药"
│   └── TodayMedSchedule (按时段分组: 早/中/晚/睡前)
├── AppleListSection "我的药物"
│   └── MedicationListCell (复用 med_item)
└── FloatingActionButton (systemRed, add)
```

## 6. 路由

| 路径 | 来源 | Widget | Transition |
|---|---|---|---|
| `/medication` | `app_route_medication.dart:69-77` | `MedicationPage` | fade |
| `/medication/add` | `app_route_medication.dart:79-86` | `AddMedicationPage` | slide-up |
| `/medication/calendar` | `app_route_medication.dart:61-68` | `MedicationCalendarPage` | slide-right |
| `/medication/detail/:id` | `app_route_medication.dart:88-101` | `MedicationDetailPage` | slide-right |

## 7. 关键设计决策

- **iOS 视觉**: 顶部 4 横滚 metric tile + insetGrouped AppleListSection, 整体跟随 Apple Health 风格
- **配色**: `AppColors.healthMetricsColorFor('medication')` → systemRed (#FF3B30)
- **3 步添加向导**: 基础信息 → 时间窗 → 提醒设置
- **时段窗口**: 早/中/晚/睡前 4 段, 由 `medication_slot_calculator.dart` 计算
- **PDF 导出**: facade + layout 分离, 70 + 321 行, 用 `pdf: ^3.11.1` + `printing: ^5.13.4`
- **Refill 提醒**: `Medication.refillAt` + `refillReminderDays` 字段, 由 `domain/logic/refill_scheduler.dart` 计算
- **stat 计算**: `medication_page_stats_calculator.dart` 纯函数, 单测覆盖

## 8. 关联

- Apple Health 视觉风格: `docs/design/2026-08-10-apple-health-redesign/spec.md`
- i18n: zh / en / zh_Hant 全翻译, ARB `app_zh.arb` 3331 行模板
- 通知: medication refill + 用药提醒, 走 `flutter_local_notifications` + 5 厂商 push 准备 (FeatureFlags 默认关)
- 守门员: `scripts/check_cross_feature.py` 锁 features/medication 不被其他 feature 直接 import

## 9. 局限 (重建损失)

- ❌ 原始 R31 / R116 决策的具体会议记录
- ❌ R110 round 3 route 移入 shell 的 P0/P1 选择理由
- ❌ 4 metric tile 顺序的具体设计意图 (medication→mood→vent→assessment 依据)
- ❌ 3 步向导分步理由 (为何不是 2/4 步)
- ❌ PDF layout 321 行具体字段映射

> **恢复建议**: `git log --all -- docs/specs/medication-page-redesign.md` + `git show <hash>` 可读原 spec