# Apple Health 视角审计 (2026-08-13, R111)

## 基线

- 版本: `pubspec.yaml:5` → **0.32.0+140** (git head `6bbb308`, R110 round 3 审计后 + 10 个 commit, round 7b 测试批收尾中)
- 双线: HealthKit 集成 (守门员 `check_apple_health_claim.py` enforced) + Apple Health 视觉 spec (§1-§10) 采纳度
- 方法: 只读。全量 grep `AppleListSection` / `AppleHealthTile` / `StatCard` / `Spring.` / `health_kit` + 逐 feature 目录核对 + spec 文档 vs 代码漂移
- 对照: R110 审计 `docs/audit/2026-08-13-multi-lens/07-apple-health.md` (AH-01~12)

## A. HealthKit 集成 = 确定性 0 (unchanged, enforced)

| 层 | 证据 | 结果 |
|---|---|---|
| Dart lib/ | grep health_kit / HKHealthStore / HealthKit = **0 hits** | 0 |
| pubspec + lock | 0 HealthKit 依赖 (pubspec 仅 audioplayers 等) | 0 |
| Runner.entitlements | 空 dict, 无 com.apple.developer.healthkit | 0 entitlement |
| Info.plist | 仅 health-related 是 `healthcare-fitness` 类别 (info.plist:147-152), 无 NSHealthShare/UpdateUsageDescription | 0 声明 |
| PrivacyInfo.xcprivacy:36-49 | HealthAndFitness 保持删除 + R1.0 重接清单注释 (5-15d + HealthAndFitness + NSHealthShareUsageDescription + health_kit 依赖) | 一致 |
| 守门员 | `python3 scripts/check_apple_health_claim.py --ci` = **OK — 项目无 Apple Health 假声明风险** | enforced |

**结论: HealthKit = 0 且 enforced, 当前 App Store 合规 (5.1.3 无抽审风险), 不阻塞上架。v1.0 (2027-Q1) 计划不变。** AH-01/02/03 为 by-design 残留。

## B. Findings

| ID | 类别 | 标题 | 证据(file:line) | 难度 | 优先级 |
|---|---|---|---|---|---|
| AH-01 | healthkit | 0 HealthKit 集成确认 (非 launch-blocking, v1.0 2027-Q1) | 全链路 (见 §A) | — | P3 (开工时) |
| AH-02 | healthkit | 上 HealthKit 时需反转过 4 个守门员 (check_apple_health_claim + description_no_health_claim test + lock-in test + PrivacyInfo) | scripts/check_apple_health_claim.py / test/lock_in/apple_health_mention_lock_in_round9_test.dart | S 0.5d | P3 (开工时) |
| AH-03 | healthkit | PrivacyInfo 注释自带重接清单 | PrivacyInfo.xcprivacy:48-49 | S | P3 |
| AH-04 | spec | **8 个 feature 仍 0 AppleListSection/AppleHealthTile/StatCard** (mood / mood_list / vent / assessment / contact / settings / daily_tracking / crisis_hotline) — R110 跨期残留 | 见 §C 核对表; mood_detail_page.dart:44,154,208,222 (Card) / assessment_history_list.dart:20 (Card) / vent_list_page.dart:163 (ListView.separated) / crisis_hotline_page.dart:146 (ListView) | XL 1-2d/页 | **P1** |
| AH-05 | 视觉 | Mood chooser 48pt vs spec §5.5 72pt (文档化 deliberate deviation, EM-11 未落地) | quick_mood_carousel.dart:170-172 | S | P3 |
| AH-06 | 视觉 | 3 套色板不打通: healthMetricsColors (8) / assessmentPalette (12) / kMoodScoreColors (5) 各自独立, "不打通"注释在案 | app_colors.dart:487-494 | M 2-3h | P2 |
| AH-07 | spec | Spring 双轨制最低满足: R32 P0-08 闭环, `Spring.standard.toSimulation()` 1 caller (_EntrySpring); 路由 3 transition 仍 curve-based (spec §3.4.3 取舍) | check_in_button.dart:86,219-242 / spring.dart:145L / app_routes.dart:44-97 | M 1-2h | P2 (已闭环, 扩 caller 可选) |
| AH-08 | a11y | Translucent AppBar 实现 ✓ (blur 20 + surface 0.6/0.4) **但 reduce-transparency 适配仍是代理**: `MediaQuery.disableAnimationsOf` 当 reduce-transparency 用 (开 reduce-motion 才走 solid), 非真 iOS reduce-transparency 检测 | page_scaffold.dart:63,86-103 | M 1-2h (AccessibilityInfo/native bridge) | **P2** |
| AH-09 | spec | **SF Symbol 0 集成**: pubspec 无 fonts section / 无 ttf / 无 cupertino_icons; apple_health_tile 8 metric 全 Material icon (Icons.medication/mood/mic/...) | pubspec.yaml:87-97 / apple_health_tile.dart:157-174 | L 1-2d | P2 |
| AH-10 | 视觉 | 8-metric palette 实调点少: sleep(systemTeal) 0 caller; AppleHealthTile 只被 medication/mood/vent 3 个 metricId 实例化 | app_colors.dart:422-430 / primary_action_row.dart:64-87 / medication_page.dart:124-147 | M | P2 |
| AH-12 | 隐私 | **隐私边界 airtight 保持**: 0 http/dio/firebase; SQLCipher + 本地 AES; HealthKit 接时需 ConsentKind.healthSync + PIPL §13/§14 | AppDelegate.swift:41-89 | — | P0-keep |
| AH-13 | spec 漂移 | **spec §5 完成度数字过期**: 声称 home "12 ALS + 4 AHT" (实测 17 ALS / 5 文件) + medication "17 ALS" (实测 55 ALS / 9 文件) | spec.md:318 vs home 5 文件 / medication 9 文件实测 | S 0.5h | P2 |
| AH-14 | spec 漂移 | **spec.md:69 reduce-transparency 描述过期**: 声称 "page_scaffold.dart:61-65 恒 translucent (`&& false` 死分支)" — R32 已删死分支, 现为 disableAnimationsOf 代理 + 注释文档化取舍 | spec.md:69 vs page_scaffold.dart:59-63,86-88 | S 0.5h | P3 |
| AH-15 | spec 漂移 | **vent FAB 未落地**: spec §5.6 要求 "FAB 添加 (systemPurple)", 实际 vent_list_page 无 FloatingActionButton, 用 AppBar 内 PressFeedbackIconButton(Icons.add) | spec.md:366-367 vs vent_list_page.dart:50-54 | M 2h | P2 |
| AH-16 | 视觉 | AppleHealthTile 8-metric 面板只用了 3 个 metricId: primary_action_row 4 tile (medication/mood/vent/+1) + medication_page 4 tile 全 'medication'; checkIn/trend/contact/sleep 0 tile 调用 | primary_action_row.dart:64-87 / medication_page.dart:124-147 | M 2-3h | P2 |
| AH-17 | spec 漂移 | **spec §7.1 test baseline "2103" 过期**: 实测 test/ 目录 `test(`/`testWidgets(` ≈ 2279 处; AGENTS.md 2019 更旧 (SP-zh-02 已记); R110 审计时 ~2246 pass / 9 fail | spec.md:401 vs `grep -rho "testWidgets(\|test(" test/ \| wc -l` | S 0.5h | P3 |

## C. spec §5 逐 feature 采纳核对表 (R111 实测)

| feature | spec § | 状态 | 实测 |
|---|---|---|---|
| Home | §5.1 重点改 | ✅ 已改 | 5 文件 17 ALS + StatCard 2x2 (today_summary_card) + AppleHealthTile 2x2 (primary_action_row) + QuickMoodCarousel 5×48pt + CheckInButton 64pt pill + spring 进场 |
| Setup | §5.2 重点改 | ✅ 已改 | 4 文件 20 ALS (consent 5 / medication 4 / welcome 10 / widgets 1) |
| Medication | §5.3 重点改 | ✅ 已改 | 9 文件 55 ALS + 4 AHT (全 medication metricId, systemRed) |
| Trend | §5.4 中等改 | ✅ 已改 | trend_summary.dart 4 ALS + 4 StatCard (2x2) |
| Mood / MoodList | §5.5 中等改 | ❌ 0 ALS | mood_detail_page Card×4; mood_score_chooser (CBT 1-10) 无 Apple 化; 72pt mood button 未落地 (48pt 文档化偏离 AH-05) |
| Vent | §5.6 中等改 | ❌ 0 ALS | vent_list_page ListView.separated; 无 FAB (AH-15); 录音 button 未改 Apple Pill |
| Assessment | §5.7 中等改 | ❌ 0 ALS | assessment_history_list.dart:20 Card; quiz/result panel 未改 |
| CheckIn | §5.8 自动 | ✅ token 自动 | spec 设计如此, 不手动改结构 |
| Contact | §5.8 自动 | ⚠️ 0 ALS | contacts_list_widget 未 ALS 化 (AH-04 计入) |
| Settings | §5.8 自动 | ⚠️ 0 ALS | 6 文件 0 ALS (AH-04 计入) |
| DailyTracking | §5.8 自动 | ⚠️ 0 ALS | 0 ALS (AH-04 计入) |
| CrisisHotline | (AH-04 清单) | ❌ 0 ALS | ListView + 无 Apple 化 (crisis_hotline_page.dart:146) |

**采纳度: 4/11 已改 (home/setup/medication/trend) + 3/11 自动适配 (checkIn/contact/settings/daily_tracking 部分), 4-5 个"中等改" feature 完整未动 = 最大视觉债。**

## D. R110 跨期残留验证

| ID | 状态 | 说明 |
|---|---|---|
| AH-01/02/03 | ⚠️ 残留 (by design) | HealthKit 0 集成 = 合规状态, v1.0 计划内 |
| AH-04 | ❌ 残留 (**P1**) | 8 feature 0 AppleListSection, 一处未改 |
| AH-05 | ⚠️ 残留 (文档化) | 48pt vs 72pt, EM-11 未落地 |
| AH-06 | ❌ 残留 (P2) | 3 套色板仍不打通 (R110 round 6 "mood 色单源" 只统一了 mood score 内部, kMoodScoreColors 注释仍声明独立) |
| AH-07 | ✅ 闭环 | Spring 接线实锤 (check_in_button.dart:86,242) |
| AH-08 | ⚠️ 部分闭环 | translucent 实现 ✓; reduce-transparency 从 `&& false` 死分支 → disableAnimationsOf 代理 (R32 修), 仍非真检测 |
| AH-09 | ❌ 残留 (P2) | SF Symbol 0 |
| AH-10 | ❌ 残留 (P2) | sleep 0 caller |
| AH-12 | ✅ 保持 | 隐私 airtight |

## E. 新风险点 (R111 新增)

1. **AH-13/14/17 spec-code 漂移 3 处**: spec 文档 (完成度数字 / reduce-transparency 描述 / test baseline) 与代码实际不符 — 下次改动以 spec 为准会做错决策, 建议 R111 顺手把 spec.md 3 处同步 (共 1.5h)
2. **AH-15 vent FAB 缺失**: 用户在 vent 页靠 AppBar icon 添加, 与 spec §5.6 的 systemPurple FAB 不符 — 既是 spec 漂移也是功能视觉缺口
3. **AH-16 tile 面板单色**: 8-metric 彩色面板 (spec 决策 #5 "8 个全面板") 实际只有 3 个 metric 出现在 tile 上且 medication 重复 5 次 — 视觉丰富度远低于 spec 意图
4. **AH-08 代理风险**: disableAnimationsOf 当 reduce-transparency 用, 开 reduce-motion 的视觉障碍用户会连带丢失 translucent 效果 (可接受但非语义正确); 上架前若抽审 a11y 可能被问

## 总结

1. **HealthKit = 0 且 enforced, 合规** (守门员 OK, entitlements/Info.plist/PrivacyInfo 三处一致), v1.0 2027-Q1 计划不变
2. **spec §5 采纳 4/11**: home/setup/medication/trend 已改 (51+ 文件 ALS 化), mood/mood_list/vent/assessment/crisis_hotline 等 8 个 feature 仍 0 AppleListSection = **最大视觉债 (AH-04, P1)**
3. **已闭环**: Spring 物理接线 (R32 P0-08, 1 caller) + translucent AppBar (blur 20) + 5 token/6 widget 集中器 + 3 核心页重设
4. **假代理残留**: reduce-transparency 用 disableAnimationsOf 代理 (AH-08), 真检测待 R111 后
5. **新发现 5 项**: spec 数字漂移 3 处 (AH-13/14/17) + vent FAB 未落地 (AH-15) + 8-metric 面板实际只用 3 色 (AH-16)

**最值得修 3 件事**: ① AH-04 8 feature ALS 化 (P1, 1-2d/页); ② AH-08 reduce-transparency 真代理 (P2, 1-2h); ③ spec 漂移 3 处同步 + vent FAB (AH-13/15, 2.5h)
