# Apple Health (HealthKit + 视觉 spec) 视角审计 (2026-08-13)

## A. HealthKit 集成 = 确定性的 0

| 层 | 证据 | 结果 |
|---|---|---|
| Dart lib/ | grep health_kit / HKHealthStore / HealthKit = **0 hits** | 0 |
| pubspec + lock | 0 HealthKit 依赖 | 0 |
| Runner.entitlements:12 | 空 dict, 无 com.apple.developer.healthkit | 0 entitlement |
| Info.plist:53-73 | 仅 Microphone/Speech/PhotoLibrary, 无 NSHealthShare/UpdateUsageDescription | 0 声明 |
| PrivacyInfo.xcprivacy:36-49 | HealthAndFitness 已删 (R108: "声明但未集成 → 5.1.3 拒审") | 一致 |
| AppDelegate.swift | 无 HealthKit framework / HK bridge | 0 native |
| 守门员 | check_apple_health_claim.py:49-86 **FAIL** on health_kit import — 0 集成是强制而非偶然 | enforced |

**结论: HealthKit 集成 = 0 (整条链路一行都没有), 且被守门员主动封死。当前 0 状态 App Store 合规, 正确不阻塞上架 (v1.0 2027-Q1 计划)。**

## B. Findings

| ID | 类别 | 标题 | 证据 | 难度 | 优先级 |
|---|---|---|---|---|---|
| AH-01 | healthkit | 0 HealthKit 集成确认 (非 launch-blocking, v1.0 计划) | 全链路 | — | P0-runtime-n/a |
| AH-02 | healthkit | 上 HealthKit 时需反转过 4 个守门员 (check_apple_health_claim + description_no_health_claim test + lock-in test + PrivacyInfo) | check_apple_health_claim.py:49-86 / test/lock_in/apple_health_mention_lock_in_round9_test.dart:18-37 | S | P3(开工时) |
| AH-03 | healthkit | PrivacyInfo 注释自带重接清单 (R1.0: 5-15d + HealthAndFitness + NSHealthShareUsageDescription + health_kit 依赖) | PrivacyInfo.xcprivacy:48-49 | S | P3 |
| AH-04 | spec | **11-feature 视觉地图 = 4.5/11: 8 个 feature 0 AppleListSection/AppleHealthTile/StatCard** (mood/mood_list/vent/assessment/contact/settings/daily_tracking/crisis_hotline 仍 Card+ListTile) | mood_detail_page.dart:43 / assessment_history_list.dart:20 / settings/profile_group.dart:71,97,209 / contacts_list_widget.dart:47 / crisis_hotline_page.dart:32-36 | XL 1-2d/页 | **P1** |
| AH-05 | 视觉 | Mood chooser 48pt vs spec §5.5 72pt (文档化 deliberate deviation) | quick_mood_carousel.dart:170 | S | P3 |
| AH-06 | 视觉 | PHQ-9/GAD-7 量表色板不打通 8-metric palette (注释"跟 healthMetricsColors 不打通") | app_colors.dart:487-494 | M | P2 |
| AH-07 | 视觉 | Spring: R32 P0-08 闭环 (1 caller _EntrySpring), 路由仍 curve; spec §3.4.3 双轨制最低满足 | check_in_button.dart:241-243 / app_routes.dart:50,72,97 | M 1-2h | P2 |
| AH-08 | a11y | Translucent AppBar 已实现 (blur 20 + surface 0.6/0.4) **但 reduce-transparency 适配是假 stub** (用 disableAnimations 代理 + `&& false` 恒真 translucent) | page_scaffold.dart:61-65,88-105 | M 1h | **P2** |
| AH-09 | spec | **SF Symbol 0 集成**: 无 fonts section / 无 ttf / 无 cupertino_icons; apple_health_tile 8 metric 全 Material icon | pubspec.yaml:87-97 / apple_health_tile.dart:157-173 | L 1-2d | P2 |
| AH-10 | 视觉 | 8-metric palette 仅 5 call 点, sleep(systemTeal) 0 caller | app_colors.dart:422-430 | M | P2 |
| AH-12 | 隐私 | **隐私边界 airtight**: 0 http/dio/firebase/socket; SQLCipher + 本地 AES + share_plus (用户发起) + tel: + IAP(flag off); iCloud 经 AppDelegate setSkipBackup 排除 — HealthKit 接时需 ConsentKind.healthSync + PIPL §13/§14 合规设计 (HK 自身 iCloud 同步冲突已在 reports 记录) | AppDelegate.swift:41-89 | — | P0-keep |

## C. 最小 HealthKit v1 切片成本 (2027-Q1)

依赖安装 + 2 Info.plist key + entitlement + PrivacyInfo HealthAndFitness 恢复 (~0.5d) · mood stateOfMind 写入服务 + 设置 consent/toggle (2-3d) · sleep/weight 读取做趋势相关 (2-3d) · ConsentKind.healthSync + iCloud 披露法务文案 (1-2d) · 守门员反转 4 处 (1d) · 测试 (2d) · ASC 问卷重答 (0.5d) ≈ **2-3 周**。

## 总结

1) HealthKit = 0 且 enforced, 合规; 2) spec §5.1-5.7 视觉地图 4.5/11, 8 feature 未转化 = 最大视觉债 (P1); 3) R32 闭环实锤: Spring 接线 + translucent AppBar; 4) 假 stub: reduce-transparency; 5) 接线前置条件: 隐私/法务设计必须先于任何 HK 集成。