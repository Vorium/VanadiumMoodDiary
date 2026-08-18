# Apple Health Visual Redesign — Spec

> **重建日期**: 2026-08-18 (从代码 + plan.md 推断)
> **原始 spec.md 已删**, 但 `spec.en.md` (83 行) + `plan.md` (382 行) 仍存在
> **Apple Health SDK 集成**: ⚠️ HealthKit SDK 未集成, 本 spec 是"视觉风格"重设, 不是 SDK 集成

## 1. 背景

R31 (2026-08-10) 起项目经历 5 阶段 11+ feature iOS 17/18 风格视觉重设, 目标是让 app 看起来像 Apple Health "favorites" 风格彩色 metric 模块, 但**应用内数据完全本地化, 不上 Apple Health**。

## 2. 核心设计原则

### 2.1 5 Token 集中器

| Token | 文件 | 行数 | 角色 |
|---|---|---|---|
| AppColors | `packages/chroniccare_theme/lib/src/app_colors.dart` | 27KB | iOS system color + 8 health metric palette |
| AppTypography | `packages/chroniccare_theme/lib/src/app_typography.dart` | 13KB | 17pt body + 13pt caption + ultralight w200 |
| AppSpacing | `packages/chroniccare_theme/lib/src/app_spacing.dart` | 9KB | 圆角 14/10 + buttonHeight 50 |
| AppMotion | `packages/chroniccare_theme/lib/src/app_motion.dart` | 14KB | 0 shadow + 3 Apple cubic-bezier + MotionScheme 4 档 |
| Spring | `packages/chroniccare_theme/lib/src/spring.dart` | 4KB | Spring 物理模型 (standard / gentle / bouncy) |

入口: `import 'package:chroniccare_theme/chroniccare_theme.dart';`

### 2.2 6 Widget 集中器

| Widget | 文件 | 行数 | 角色 |
|---|---|---|---|
| AppleHealthTile | `lib/presentation/widgets/apple_health_tile.dart` | 191 | 8 metric 110×140 横滚 tile |
| AppleListSection | `lib/presentation/widgets/apple_list_section.dart` | 244 | iOS insetGrouped 风格章节 |
| SectionHeader | `lib/presentation/widgets/section_header.dart` | — | iOS ALL CAPS 11pt gray |
| PrimaryButton | `lib/presentation/widgets/primary_button.dart` | — | Apple Pill 3 variant |
| CheckInButton | — | — | 64pt giant pill spring entry |
| StatCard | `lib/presentation/widgets/stat_card.dart` | — | ultralight w200 4 variants |

### 2.3 8 Health Metric Palette

`lib/presentation/widgets/apple_health_tile.dart:51-52` 定义:
```dart
enum HealthMetric {
  medication,   // systemRed    #FF3B30
  mood,         // systemPink   #FF375F
  vent,         // systemPurple #AF52DE
  assessment,   // systemTeal   #5AC8FA
  checkIn,      // systemGreen  #34C759
  trend,        // systemBlue   #007AFF
  contact,      // systemOrange #FF9500
  sleep,        // systemIndigo #5856D6
}
```

获取: `AppColors.healthMetricsColorFor(metricId)`

## 3. 11+ Feature 重设

R31 5 阶段重设覆盖:
1. 主页 (HomePage) — 4 tab 简化 + AppleListSection
2. 用药页 (MedicationPage) — Apple Health 风格 4 横滚 metric
3. 评估中心 (AssessmentCenterPage) — iOS insetGrouped 卡片
4. 情绪列表 (MoodListPage) — AppleListSection 改造
5. 趋势 (TrendPage) — iOS 17 chart 风格
6. 树洞 (VentListPage) — iOS 列表
7. 设置 (SettingsPage) — iOS settings grouped
8. 提醒中心 (RemindersHubPage) — iOS notifications
9. 续方 (RefillManagePage) — iOS 列表
10. 危机热线 (CrisisHotlinePage) — 大号按钮 tel: scheme
11. 启动 (AppRoot) — R32 R112 translucent AppBar solid alpha 0.97/0.92

## 4. 9 follow-up 改进

R31 后 9 轮微调 (R32/R95/R108/R110/R112/R116):
- PageScaffold translucent AppBar (R32 round 3) — 修前 BackdropFilter blur 20 滚动 60fps 掉帧
- Apple cubic-bezier 3 套 (curveAppleSheet / curveAppleDrawer / curveSpring)
- 4 档 MotionScheme (none / subtle / standard / delight) — emil 决策框架
- prefers-reduced-motion 包装 (app_motion.dart:289-306)
- 3 transition helper (fadePage / slideRightPage / slideUpPage)
- 入场动画 fade 0.92→1.0 + Spring.standard (3 runtime callers)
- Page transitions 主导航 fade 250ms / 子页 slide-right 250ms / 全屏 slide-up 400ms (R114 B2)
- SnackBar duration short 2s / medium 3s / long 4s
- iOS ALL CAPS 11pt gray SectionHeader

## 5. HealthKit SDK 集成 (占位)

⚠️ **HealthKit SDK 未集成**, 仅 stub:

**位置**: `lib/core/platform/health_kit/health_kit_service.dart` (204 行)

**结构**: 4 段式
- `abstract class HealthKitChannel`
- `class NoOpHealthKitChannel implements HealthKitChannel`
- `class HealthKitFactory`
- `class HealthKitService`

**FeatureFlag**: `lib/core/data/feature_flags.dart:55-58` `_prodHealthKitEnabled = false` + `healthKitEnabled` getter

**设计意图** (从代码注释推断):
"5-6 月后真接" — 加 pubspec `health_kit: ^4.x` + iOS `Runner.entitlements` entitlement + `Info.plist` NSHealthShareUsageDescription + 真接 impl

**守门员**: `scripts/check_apple_health_claim.py` 5 规则锁
1. `Apple Health` 字面只能在特定 widget 出现
2. 不允许 claim `Apple Health integration` 当未集成 SDK
3. `healthKitEnabled` FeatureFlag 默认 false
4. tooltip 必须明确"应用内数据, 不上 Apple Health"
5. lib/ 主体禁止 healthKit import

## 6. 集成决策 (Feature Flags)

`feature_flags.dart:31-33` 锁定 0 副作用:
```dart
// MoodEntry → Apple Health 联动 0 副作用
moodToAppleHealthSyncEnabled = false  // 默认
```

## 7. 5 阶段路线 (R31)

R31 plan.md 382 行:
- Phase 1: 5 token 集中器
- Phase 2: 6 widget 集中器
- Phase 3: 11 feature 重设
- Phase 4: 9 follow-up
- Phase 5: 守门员 lock-in

## 8. 关键文件

| 路径 | 行数 | 角色 |
|---|---|---|
| `packages/chroniccare_theme/lib/src/app_colors.dart` | 27KB | 颜色 |
| `packages/chroniccare_theme/lib/src/app_typography.dart` | 13KB | 字号 |
| `packages/chroniccare_theme/lib/src/app_spacing.dart` | 9KB | 间距 |
| `packages/chroniccare_theme/lib/src/app_motion.dart` | 14KB | 动效 |
| `packages/chroniccare_theme/lib/src/spring.dart` | 4KB | Spring 物理 |
| `lib/presentation/widgets/apple_health_tile.dart` | 191 | 8 metric tile |
| `lib/presentation/widgets/apple_list_section.dart` | 244 | insetGrouped |
| `lib/presentation/widgets/page_scaffold.dart` | 131 | 通用骨架 |
| `lib/core/platform/health_kit/health_kit_service.dart` | 204 | HealthKit stub |
| `lib/core/data/feature_flags.dart` | — | FeatureFlags |
| `scripts/check_apple_health_claim.py` | 154 | 5 规则锁 |
| `docs/design/2026-08-10-apple-health-redesign/plan.md` | 382 | R31 plan |
| `docs/design/2026-08-10-apple-health-redesign/spec.en.md` | 83 | EN spec |
| `docs/design/2026-08-17-redesign-mockup/index.html` | 917 | HTML mockup |

## 9. 关联

- Mood 4 维分数: `lib/features/mood/data/tables/mood_entries.dart`
- Apple Health 字面锁: `test/lock_in/apple_health_mention_lock_in_round9_test.dart`
- Apple Health phase 4 global sanity: `test/presentation/apple_health_phase4_global_sanity_round12_test.dart`

## 10. 局限

- ❌ R31 完整 11+ feature 列表
- ❌ 8 metric 顺序的具体设计意图
- ❌ HealthKit SDK 真接的具体技术选型
- ❌ 守门员 5 规则的具体测试用例