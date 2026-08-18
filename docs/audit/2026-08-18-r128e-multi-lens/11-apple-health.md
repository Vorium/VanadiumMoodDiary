# Lens 11: Apple Health (HealthKit + 5.1.3 抽审 + Apple Health 视觉)

**Date**: 2026-08-18
**Scope**: HealthKit 集成 + 5.1.3 抽审 + Apple 5.1.1 敏感 App + Apple Health 视觉风格 (5 token 集中器 pub workspace) + spring.dart 物理模型 + crisis 5/5 i18n
**Baseline**: 1.1.0+180, 2728 tests pass / 0 fail / 1 skip, 24 gatekeepers, 1340 ARB keys, R128d step 3 收官 (5 token 转 pub workspace)

## 总体评分

**7.5/10** (R120 7.0 +0.5, R128c HealthKit stub + R128d 5 token 转 pub workspace + R128b crisis 5/5 收官是加分主因, 视觉层 9.5/10 优秀保持, HealthKit 仍 0 集成跨期)

## 核心 Findings

### ✅ 优点 / 强项 (6 项)

| # | 项 | 状态 | 文件:行 |
|---|---|---|---|
| AH-01 | R128c HealthKit stub 落地 (abstract + NoOp + flag=false 编译期锁定) | ✓ R128c 阶段 1 | `lib/core/platform/health_kit/health_kit_service.dart:32-204` |
| AH-02 | R128d 5 token 集中器转 pub workspace (chroniccare_theme) | ✓ 跨 5 feature + presentation/widgets + core/ + main 公共依赖 | `packages/chroniccare_theme/lib/chroniccare_theme.dart:15-19` (5 export) |
| AH-03 | R128b crisis 5/5 region i18n 完整 (CN/TW/HK/US/Intl) | ✓ 100% 闭环 | `lib/features/crisis/data/logic/hotline_regions.dart:28-90` |
| AH-04 | Apple Health 视觉 9.5/10 保持 (5 token + 6 widget + AppleListSection 6 section) | ✓ R31 累计 + R128d 公共化 | `lib/presentation/widgets/apple_health_tile.dart:5 metricId` |
| AH-05 | 守门员 `check_apple_health_claim.py` 0 violation (5 规则, R128c 加 5b) | ✓ | `scripts/check_apple_health_claim.py:129` (规则 5b: flag=false) |
| AH-06 | 5 token 集中器 100% 跨 package 公共 API (R128d 拆 package 后 0 倒退) | ✓ 174 presentation 文件用 | 全 import chroniccare_theme |
| AH-07 | Spring 物理模型 3 caller 全闭环 (R121 P1-4 修复) | ✓ standard + bouncy + gentle | `spring.dart` + 3 widget caller |
| AH-08 | PrivacyInfo.xcprivacy 0 HealthAndFitness (5.1.3 防御) | ✓ R108 + R112 累计 | `ios/Runner/PrivacyInfo.xcprivacy:68-94` |

### ⚠️ 待优化 (5 项)

| # | 项 | 状态 | 文件:行 | 估时 |
|---|---|---|---|---|
| AH-09 | **HealthKit 仍 0 真实集成** (R128c 阶段 1 stub 落地, 阶段 2 真接 5-6 月长期) | 🟡 v1.0+ | `health_kit_service.dart:108-110` (factory 返 NoOp) | 5-6 月 |
| AH-10 | **AppleHealthTile 视觉 vs 数据 gap 未补** (8 metric 看起来像 HealthKit 但 0 集成) | 🟡 R31 P0-004 跨期 | `apple_health_tile.dart:55-60` (注释提但 0 tooltip) | 1h |
| AH-11 | **spring.dart 仍 in lib/core/theme/** (R128d 转 package 时 0 拆) | 🟡 跨 package 0 拆 | `lib/core/theme/spring.dart:1-145` | 0.5h |
| AH-12 | **R31 11 feature 仍 0 改 AppleHealthTile 趋势图** (8 round 0 接入真实数据) | 🟡 跨期 | `apple_health_tile.dart:60-100` (只展示静态 value) | 1-2 周 |
| AH-13 | **"Apple Health 风格" 文档 lock-in 仅 1 文件** (R31 集中器注释覆盖窄) | 🟡 跨期 | `apple_health_tile.dart:34` | 0.5h |

### 🚫 红线 (0 项)

R128c 阶段 1 stub + PrivacyInfo 0 HealthAndFitness + Runner.entitlements 空 = Apple 5.1.3 used-but-not-declared 抽审 100% 防御。**emotion-first 0 HealthKit 集成 = 跟 5.1.3 抽审天然兼容**, 不是工程疏漏。

## 跨 Lens 共识 (3 项)

| # | 共识 | 跟谁 |
|---|---|---|
| AH-C1 | **HealthKit stub 0 真实集成** (R128c 阶段 1) = apple-health 跟 appstore 共识 (5.1.3 抽审防御统一战线) | Lens 9 |
| AH-C2 | **AppleHealthTile 视觉 vs 数据 gap** (8 metric 看起来像 HealthKit 但 0 集成) = apple-health 跟 pull-on-shelf 共识 (上架审核员疑惑"为何不接 HealthKit") | pull-on-shelf + emil |
| AH-C3 | **R128a~R128d 跨 4 round 0 引入 Apple Health 视觉倒退** (5 token 转 package 后 100% 保持) = apple-health 跟 flutter-spec 共识 (97% 跨期 0 倒退) | flutter-spec |

## R128a~R128d 改动验证 (apple-health 角度)

| Round | 期望 (Apple Health 角度) | 实际 | 状态 |
|---|---|---|---|
| **R128a** notification umbrella | 0 影响 Apple Health 视觉 / 0 引入 HealthKit 集成 | notification 8 文件, 0 import chroniccare_theme, 0 Apple Health 视觉影响 | ✓ 0 回归 |
| **R128b** crisis 5/5 收官 | 5 region i18n 完整, 0 视觉变化 | `hotline_regions.dart:28-90` 5 region ARB | ✓ 0 回归 |
| **R128c** HealthKit stub | abstract + NoOp + flag=false, **不**加 entitlement / **不**import health_kit / **不**改 PrivacyInfo | 7.5KB stub, 守门员 0 violation, 5.1.3 防御 100% 闭环 | ✓ 加分主因 |
| **R128d** 5 token 转 package | chroniccare_theme 公共 API, 5 token 100% 跨 package | `chroniccare_theme.dart:15-19` 5 export, 174 presentation 文件用, 0 视觉倒退 | ✓ 加分主因 |

**R128a~R128d 累计**: 加分 (R128c + R128d + R128b) / 0 视觉倒退 / 0 集成风险 / 0 拒审漏洞, 4 round 净 +0.5 评分 (7.0 → 7.5)。

## 5.1.3 抽审准备 (4 项)

| # | 项 | 状态 |
|---|---|---|
| AH-14 | 4 文档准备: 医疗免责声明 / 隐私政策 / 用户协议 / 临床审核证据 | 3/4 (PHQ-9/GAD-7 法务待) |
| AH-15 | PHQ-9 / GAD-7 16 题 i18n 走 fallback (`phqGad7I18nEnabled=false`) | ✓ R65b |
| AH-16 | emotion-first 定位 (不上 HealthKit, 不上 ResearchKit) | ✓ 1.1.0 round 4b |
| AH-17 | `description.txt` 5.1.1 抽审声明 (含 Apple Health 风格 + emotion-first 定位) | ✓ 文本就绪 |

## R129+ 建议

| # | 优先级 | 项 | 文件:行 | 估时 | 评分 |
|---|---|---|---|---|---|
| 1 | **P1** | AH-10 AppleHealthTile 加 tooltip "应用内数据,不上 Apple Health" | `apple_health_tile.dart:60-100` | 1h | +0.2 |
| 2 | **P1** | AH-11 spring.dart 拆 chroniccare_theme (R128d 漏拆) | `lib/core/theme/spring.dart` → `packages/chroniccare_theme/lib/src/spring.dart` | 0.5h | +0.1 |
| 3 | **P1** | AH-13 "Apple Health 风格" 锁扩 lib/ 注释 | 5 widget 集中器注释 | 0.5h | +0.1 |
| 4 | **P2** | AH-12 AppleHealthTile 接入真实数据 (mood/med/vent streak) | `apple_health_tile.dart:60-100` Riverpod Consumer | 1-2 周 | +0.3 |
| 5 | **P2** | 5.1.3 抽审 PHQ-9/GAD-7 法务 + 临床审核 | 4 文档起草 + 法务审核 | 1-2 周 | +0.3 |
| 6 | **P3** | AH-09 HealthKit 阶段 2 真接 (5-6 月) | factory 改 + pub dep + iOS entitlement | 5-6 月 | +1.0 |

**R129 hotfix (1 周)**: P1-1~P1-3 估时 2h, 评分 7.5 → 7.9 (+0.4)
**R129+ (1-2 周)**: P2-4~P2-5 估时 1-2 周, 评分 7.9 → 8.5 (+0.6)
**v1.0 (2027-Q1, HealthKit 真接)**: 估时 5-6 月, 评分 8.5 → 9.5+ (+1.0)

## 视觉层 vs 数据层 矛盾 (4 项, R31 跨期 0 闭环)

| # | 矛盾 | 风险 | 修复 |
|---|---|---|---|
| AH-18 | AppleHealthTile 8 metric 看起来像 HealthKit 但 0 集成 | 用户疑惑"为什么没数据" | AH-10 加 tooltip |
| AH-19 | "5.1.3 敏感 App 抽审" + "0 HealthKit" | Apple 抽审可能问"为何不接" | emotion-first 定位已闭环 |
| AH-20 | "Apple Health 风格" 文档 lock-in 仅 1 文件 | 不在 lib/ 注释 lock-in | AH-13 扩注释 |
| AH-21 | spring.dart 仍 in lib/core/theme/ (R128d 0 拆) | 跨 package 公共 API 不完整 | AH-11 拆 chroniccare_theme |

## 关键设计决策 (lock-in, R128e 重申)

- **emotion-first 优先 HealthKit**: 1.1.0 round 4b 删 4 文档 "HealthKit 集成" 段落 + R128c stub 0 真实集成
- **5.1.3 抽审必须**: 4 文档 + PHQ-9/GAD-7 法务 + 临床审核 (R120 P1-5 跨期 0 启动)
- **AppleHealthTile 是视觉 0 数据**: 不假装 HealthKit, 不写 `health_kit` 文档声明 (R108 删 HealthAndFitness)
- **守门员 0 violation**: 5 规则 + R128c stub 锁 flag=false
- **5 token 转 pub workspace**: R31 视觉 9.5 公共化 + R128d 跨 5 feature 共享 + spring.dart 待拆 (AH-11)

> **Apple Health 根本问题**: R128a~R128d 跨 4 round 净 +0.5 (7.0→7.5), 加分主因 = R128c stub (5.1.3 防御) + R128d 5 token 转 package (R31 视觉公共化) + R128b crisis 5/5。**真正根因 = R31 跨期 11 feature 仍 0 改 AppleHealthTile 趋势图** (视觉 vs 数据 gap), 跟 R31 P0-004 跨期 8 round 0 闭环一致。v1.0+ 阶段 2 HealthKit 真接 (5-6 月) 是 8.5 → 9.5 关键路径, 依赖 R124 5 厂商 push 审核 1-2 月 + HealthKit 审核 1 周同步翻 flag。
