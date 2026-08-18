# Lens 1: emil (UX/设计 quality)

**Date**: 2026-08-18
**Scope**: R128d 5 token 集中器转 pub workspace `chroniccare_theme` 后 UI/UX 一致性 + 视觉 token 化 + 微交互 + iOS/Android 习惯对齐 + Apple Health 风格
**Baseline**: 1.1.0+185 (R128d 收官), 2728 tests pass / 0 fail / 1 skip, 24 gatekeepers, 3 pub workspace package

## 总体评分

**7.5/10** (R31 8.0 → R120 7.5 持平 → R128e 7.5, R128a~R128d 4 commit 净持平 0 升 0 降)

## 核心 Findings

### ✅ 优点 (5 项, R128a~R128d 累计闭环)
1. **5 token 集中器转 pub workspace 公共入口 100% 落地**: `packages/chroniccare_theme/lib/chroniccare_theme.dart` 1 行 export 5 个集中器 (app_tokens + app_colors + app_typography + app_spacing + app_motion), 188 lib file 改 import 走公共入口, 191 implementation_imports 警告修真 → 0 violation (R128d step 1)
2. **5 旧 path re-export 兼容**: `lib/core/theme/app_{colors,motion,spacing,tokens,typography}.dart` 5 file 改 1 行 export 公共入口, 现有用户 0 改动 (跟 R128a notification 7 re-export 同模式)
3. **7 红线 0 regression**: 0 raw `IconButton` (除 `press_feedback_icon_button.dart` 内部 2 处, 集中器实现合法) / trailing commas 0 错 (459 issues 全是 info-level) / dead tokens 0 / PressFeedbackIconButton 23 file 统一 / PrimaryButton 集中器 / emil 决策框架 doc 注释 100% 落地
4. **AppleListSection 统一 100% 覆盖**: 44 lib file 引用 + 78 usage site, 主页 6 section + 设置 5 group + medication 4 subpage + crisis 全部 iOS insetGrouped 风格闭环
5. **Stagger 8→3 闭环保持**: 主页 hero 进场动画仍 3 step, 流畅度未退化

### ⚠️ 待优化 (7 项)

| # | 位置 | 问题 | 修复 | 难度 | 优先级 |
|---|---|---|---|---|---|
| E-1 | `packages/chroniccare_theme/lib/src/app_motion.dart:18,37` | **spring.dart 仍是 5 集中器"半集中"状态** — AGENTS.md R31 行 250 明确列 spring.dart 为 5 token 集中器之一 (app_colors / app_typography / app_spacing / app_motion / **spring.dart**), R128d step 1 拆了 4 个 spring 没拆, 5 集中器裂成 4 in package + 1 in `lib/core/theme/spring.dart` | 迁 `lib/core/theme/spring.dart` → `packages/chroniccare_theme/lib/src/spring.dart` + 修真 3 个 caller import (`check_in_button.dart:39` + `mood_score_buttons.dart:30` + `celebration_bounce.dart:6` 改 `package:chroniccare_theme/chroniccare_theme.dart`) | Small | **P0** |
| E-2 | `lib/presentation/widgets/apple_health_tile.dart:42-185` | **AppleHealthTile 0 tooltip 跨期残留** — R31 P0-08 锁屏 PII 修过 body, 8 metric 彩色模块无 hover/long-press tooltip, 用户不知 "checkIn"/"contact" metric 含义 (e.g. contact 实际是 crisis/失联通知 1.1.0 round 4b 删除) → 视觉 vs 数据 gap, "checkIn" metricId 在 medication_page.dart:132 用跟 checkIn 业务实际语义不符 | 加 `tooltip: l10n.metricTooltip(metricId)` 走 8 metric × zh/en/zh-Hant ARB + 修 "checkIn" metricId 跟 checkIn 业务冲突 (改 "checkIn" → "checkin" 或 "inbox") | Small | **P0** |
| E-3 | `packages/chroniccare_theme/lib/chroniccare_theme.dart:15-19` | **R128d 拆包 0 test 验证** — `packages/chroniccare_theme/test/` 不存在, 1685L 5 集中器 (colors 542L + motion 307L + tokens 374L + spacing 180L + typography 279L) 0 单测, 旧 test `app_tokens_lock_in_round95_test.dart` / `app_colors_contrast_round8_test.dart` / `motion_scheme_round14_test.dart` 仍留 `test/core/theme/` 走旧 path import, 拆包后失去 isolated package test 验证 | 建 `packages/chroniccare_theme/test/` + 3-5 个 smoke test (e.g. `app_colors_test.dart` 验 primary 0xFF34C759 + 8 health metric palette 全在 + dark mode 12 静态 const 完整 + AppTokens 24 转发 100% 一致) | Small | **P1** |
| E-4 | `lib/core/theme/app_theme.dart:18-24` | **dark mode 主色未显式覆盖 M3 ColorScheme dark variant** — M3 ColorScheme.fromSeed 自动派生 dark 调色可能跟 iOS systemGreen dark (0xFF248A3D = primaryDark) 不一致, 走 ColorScheme.primary 跟 AppTokens.primary (iOS systemGreen 0xFF34C759) 跨 light/dark 视觉不同 | 加 `onPrimary: isDark ? AppTokens.textPrimaryDark : Colors.white` 已做, 但 `primary: AppTokens.primary` 不分 dark/light 写死 → 修真 dark variant 用 AppTokens.primaryDark | Trivial | **P2** |
| E-5 | `lib/presentation/widgets/press_feedback.dart` | **PressFeedback 0 dark mode 视觉差异** — scale 0.97 + haptic 跨 light/dark 一致, 但 PressFeedback 包 PressFeedbackIconButton 时阴影 + splash 在 dark mode 仍是 M3 InkSparkle 默认, 跟 iOS 不带阴影风格冲突 | 加 `visualDensity` + 阴影 alpha 走 dark 0.0 (跟 AppMotion.shadowNone 一致) | Trivial | P3 |
| E-6 | `lib/features/medication/presentation/pages/medication/medication_page.dart:20` | `unused_import: 'dart:async'` warning (R128b crisis 迁 features/ 修真 + medication 1 commit 整包未清理残留) | `dart fix --apply` 自动修真或手删 line 20 | Trivial | P3 |
| E-7 | `lib/presentation/widgets/apple_health_tile.dart:11-13` | **Apple Health 视觉 vs 数据 gap tooltip 跨期残留** — design 注释提 "8 metric 选 1 (跟 AppColors.healthMetricsIds 1:1)", 实际硬编码 8 metricId switch, 新 metric 加时要手改 switch, 集中化原则被破坏 | 改 `static const Map<String, IconData> _metricIcons = {...}` + 加 assert 防御 + 8 metric tooltip ARB | Small | P2 |

### 🚫 红线 (0 项)
emil 已知 7 红线 (集中按钮 / trailing commas / dead tokens / 0 raw IconButton / 5 token 集中器 / iOS 视觉对齐 / 决策框架 doc 注释) 7/7 仍闭环。**唯一悬念** 是 E-1 spring.dart 拆包裂成 4+1, 是否破坏"5 token 集中器"完整性 — 这是跨期 R31 P0-08 spring.dart 0 caller 半成品修复后, R114 / R121 各接 1 个 caller 闭环, 现在 R128d 拆 4 漏 1 跟"R31 5 集中器"承诺不一致。

## 跨 Lens 共识

- **跟 superpowers-en**: 1685L 5 token 集中器 0 单测是 P1 共识, 跨期 R95 lock-in test 修真 5 集中器 (现在 1685L) 边界, 拆包后失去 isolated unit test → superpowers-en P0 文档同步漏洞 (CHANGELOG 0 R128 entry) 跟 emil E-1 spring 拆包不完整同源 (R128d 拆包不彻底)
- **跟 superpowers-zh**: 决策框架 doc 注释 (100+/day 无动画, tens/day 微弱, occasional 标准, rare 可加 delight) 仍 100% 落地, 无 regression
- **跟 flutter-spec**: 5 集中器转 pub workspace + re-export 兼容模式跟 R126 续 4 feature 完整迁移同模式 (125 旧 path re-export), 跨期 spec §3.4.3 完整 3 模型面 (standard / gentle / bouncy spring) R121 P1-4 已闭环
- **跟 Apple Health lens**: R31 9.5/10 视觉层优秀 4 commit 仍保持, AppleHealthTile + AppleListSection 集中器跨 5 feature 全覆盖, Apple Health 风格未退化
- **跟 frame-thinking**: spring.dart 拆包裂 4+1 = 物理模型被框架打断, 跟"完整 3 模型面"frame-thinking 共识冲突

## R128a~R128d 改动验证

| 指标 | 期望 | 实际 | 验证方法 |
|---|---|---|---|
| 5 token 集中器转 pub workspace | 1685L 5 file 全在 `packages/chroniccare_theme/lib/src/` | ✓ 5 file (colors 542 + motion 307 + tokens 374 + spacing 180 + typography 279 = 1682L) | `wc -l packages/chroniccare_theme/lib/src/*.dart` |
| 5 集中器 5 完整 | 5 = colors + typography + spacing + motion + spring | ✗ **spring.dart 仍留 `lib/core/theme/spring.dart` 118L** | `ls lib/core/theme/spring.dart` + `grep "Spring" packages/chroniccare_theme/lib/src/*.dart` 0 match |
| public API 完整 | `chroniccare_theme.dart` export 5 集中器 | ✓ 5 file export, 188 lib file 改 import 走公共入口 | `cat packages/chroniccare_theme/lib/chroniccare_theme.dart` |
| 旧 path re-export 兼容 | 5 file `lib/core/theme/app_*.dart` 1 行 export 新 path | ✓ 5 file 全部 re-export (跟 R128a notification 7 re-export 同模式) | `cat lib/core/theme/app_*.dart` |
| dart linter `implementation_imports` 修真 | 0 violation | ✓ 191 implementation_imports 修真 (R128d step 1 commit message) | `flutter analyze` 0 error / 0 此类 warning |
| 0 raw `IconButton` (除集中器内部) | 全 app 走 `PressFeedbackIconButton` | ✓ 23 file 用 `PressFeedbackIconButton`, 仅 2 处 raw 在 `press_feedback_icon_button.dart` (合法) | `grep -rn "IconButton(" lib/ --include="*.dart"` |
| 5 集中器 0 dead tokens | 5 file 静态 const 全部有 caller | ✓ 0 dead token (R95 lock-in 持续) | `flutter analyze` 0 unused_element (集中器 5 file) |
| AppleListSection 100% 覆盖 | 主页 + 设置 + medication + crisis 全部 iOS 风格 | ✓ 44 lib file 引用 + 78 usage site | `grep -rn "AppleListSection" lib/ --include="*.dart"` |
| AppleHealthTile 8 metric palette 彩色模块 | 8 metric 1:1 走 AppColors.healthMetricsIds | ✓ 8 metricId switch (medication / mood / vent / assessment / checkIn / trend / contact / sleep) | `grep -A 10 "_iconFor" lib/presentation/widgets/apple_health_tile.dart` |
| 7 红线 0 regression | 7/7 闭环保持 | ✓ 7/7 (E-1 spring 拆包 4+1 是"5 集中器"完整性破坏, 红线不直接 hit) | 自查 7 项 |

## R129+ 建议 (具体到文件:行, 估时, 估评分影响)

| # | 建议 | 文件:行 | 估时 | 估 Δ |
|---|---|---|---|---|
| 1 | **P0**: 迁 spring.dart → `packages/chroniccare_theme/lib/src/spring.dart` + 修真 3 个 caller import (R128e 跨期 E-1, emil 5 集中器完整性闭环) | `lib/core/theme/spring.dart:1-118` 整体迁 + 修真 3 caller (`lib/presentation/widgets/check_in_button.dart:39` + `mood_score_buttons.dart:30` + `celebration_bounce.dart:6`) | 1h | +0.2 → 7.7 |
| 2 | **P0**: AppleHealthTile 加 8 metric tooltip + 修 "checkIn" metricId 跟业务冲突 | `lib/presentation/widgets/apple_health_tile.dart:42-50` (加 tooltip param) + 新建 `l10n/app_zh.arb` + `app_en.arb` + `app_zh-Hant.arb` 8 metric tooltip (24 ARB key) | 1.5h | +0.2 → 7.9 |
| 3 | **P1**: 建 `packages/chroniccare_theme/test/` + 3-5 smoke test 验证 1685L 5 集中器 + 旧 test 修真走新 path | `packages/chroniccare_theme/test/app_colors_test.dart` + `app_typography_test.dart` + `app_spacing_test.dart` + 修真 4 旧 test (`test/core/theme/{app_tokens_lock_in_round95,app_colors_contrast_round8,motion_scheme_round14,app_tokens_dark_round18}_test.dart`) | 2h | +0.1 → 8.0 |
| 4 | **P1**: 修真 `medication_page.dart:20` unused_import `dart:async` (跨期 R128b 修真残留) | `lib/features/medication/presentation/pages/medication/medication_page.dart:20` | 5min | +0.05 |
| 5 | **P2**: dark mode 主色显式覆盖 M3 ColorScheme (走 AppTokens.primaryDark 而非 primary 写死) | `lib/core/theme/app_theme.dart:18-24` 修真 `primary: AppTokens.primary` → `primary: isDark ? AppTokens.primaryDark : AppTokens.primary` | 30min | +0.05 |
| 6 | **P2**: AppleHealthTile 8 metricId 集中化 (map 而非 switch, E-7) | `lib/presentation/widgets/apple_health_tile.dart:163-184` 改 `static const Map<String, IconData>` | 30min | +0.05 |
| 7 | **P3**: PressFeedback 0 dark mode 视觉差异 (shadow + splash 跨 light/dark 统一) | `lib/presentation/widgets/press_feedback.dart` 加 `BoxShadow` alpha 0 dark + 跟 AppMotion.shadowNone 一致 | 1h | +0.05 |

**R129 闭环 1-3 项** (3.5h) → emil 8.0/10。
**R129 闭环 1-7 项** (5.5h) → emil 8.2/10 (回到 R31 持平)。
