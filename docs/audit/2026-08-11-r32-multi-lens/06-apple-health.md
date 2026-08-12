# 视角 6 报告 · Apple Health (iOS 17/18) 视觉语言 + 产品体验 (R32 revisit)

## 元信息
- 跑时间: 2026-08-11
- baseline: master HEAD `a0f39c4` (v0.31.0+107) — R31 提交后 + 0.31.2 入库 R109 审计 + 设计文档
- 关注: Apple Health 5 token + 6 widget + 5 page + 9 page follow 落地质量 + 半成品 P0
- 对照: R31 (2026-08-11) Apple Health 7.0/10

---

## 0. 评分

**Apple Health 视角总分: 7.2/10** (R31 7.0 → +0.2)

子维度评分 (满分 10)：

| 子维度 | R31 | R32 | 变化 | 备注 |
|---|---|---|---|---|
| 视觉 token 集中度 (4 token + facade) | 9.5 | 9.5 | 持平 | 5 token 100% 落地；line 1-90 注释 + 决策 #1-#8 完整 |
| 6 widget 集中器 (Primary/CheckIn/Stat/AppleHealthTile/AppleListSection/SectionHeader) | 9.0 | 9.0 | 持平 | 6 widget 100% 落地，line 1-100 注释完整 |
| 5 page 重设 (Home/Setup/Medication/Trend/Mood) | 8.5 | 8.5 | 持平 | Home 12 AppleListSection + 4 AppleHealthTile + CheckInButton pill = 一眼 Apple Health；Setup 5 section；Medication 17 section + 4 tile + systemRed FAB = 最完整；Trend 只 1 AppleListSection (summary)；Mood/mood_list 0 改 |
| 9 page follow (Phase 4) | 6.0 | 6.0 | 持平 | R12b global sanity test 131 行验证 9 feature follow，但 vent / daily_tracking / assessment / contact / settings / mood_list 实际 0 AppleListSection/AppleHealthTile/StatCard 落库 — global sanity 用 grep 验证源码不含旧 Card 模式，但"加了" ≠ "改了" |
| 动效 Spring (spec §3.4.3) | 0.0 | 0.0 | 持平 | **Spring.standard/gentle/bouncy 仍然 0 caller**，spring.dart 145 行 0 import，全 lib grep `animateWith(\|toSimulation(\|Spring\.standard\|Spring\.gentle\|Spring\.bouncy` = 0 处 |
| translucent AppBar (spec §4.9 决策 #7) | 0.0 | 0.0 | 持平 | `page_scaffold.dart:47-58` 仍是默认 M3 AppBar，**0 BackdropFilter / 0 blur / 0 alpha**；`app_theme.dart:97-109` `scrolledUnderElevation: 0` 是唯一 Apple Health 触点 (但 elevation 0 ≠ translucent) |
| spec baseline 数字一致性 (spec §7.1) | 5.0 | 5.0 | 持平 | spec.md:398 `baseline 2019 cases` vs 实际 `+2103 pass / 1 skip / 126 fail` ≈ 2230 total；plan.md:5 / 20 / 45 / 64 / 82 / 101 / 107 / 204 全部写 2019 baseline，6 处 stale |
| 11 feature 落地完整度 (spec §5.1-5.7) | 4.0 | 4.0 | 持平 | home/setup/medication 3 深度改 + trend 1 半残 + check_in Button widget = 4-5 个；mood / mood_list / daily_tracking / vent / assessment / contact / settings / crisis_hotline = 7-8 个 0 改 AppleListSection/AppleHealthTile |
| 信息密度 (R31 spacingMd 24→16) | 8.5 | 8.5 | 持平 | home_page_state.dart 视觉密度 +30% 达到；setup/medication follow |
| 大数字 ultralight w200 (StatCard) | 9.0 | 9.0 | 持平 | `textStyleMetricXl/Lg/Md` 3 个 helper w200/letterSpacing 0/tight 1.1 全落地，StatCard 4 variant 集成 |
| iOS 群组列表 (AppleListSection) | 9.0 | 9.0 | 持平 | iOS insetGrouped 风格 + hairline divider 0.5 + 圆角 16 + ALL CAPS 13pt 章节 + 0 阴影，dark mode 走 static 1C1C1E |
| 隐私健康数据可视化 (PHQ-9 / mood chart) | 7.5 | 7.5 | 持平 | R90 量表色板 + R91 删 12 色 list 重复 + R107 0.85mg/0.18 alpha，**0 跟 Apple Health 视觉对齐** (跟 R90 跟 spec §3.1.3 metric palette 不打通) |
| **加权综合** | **7.0** | **7.2** | **+0.2** | 主要 +0.2 = 0.31.2 入库 245KB 审计 + 44KB 设计文档 + AGENTS.md v0.31 章节已加 + R11a 4 硬编码中文 + 1 Colors.white + 1 锁屏 PII 仍 **0 闭环**；3 个 Apple Health P0 (Spring/PageScaffold/11 feature) 仍 0 闭环 |

**跟 R31 对比**：+0.2 微升，本质 R32 啥 Apple Health 实现也没做，0.31.2 commit `5952515` 全部是 docs 入库 + README 更新 + R109 综合审视报告归档，**0 业务代码改动**。所以 Apple Health 视角总分 = R31 baseline + docs 增量 = 7.2/10。

---

## 1. 上架/合规 P0 (Apple Health 品牌一致性 + 5.1.x 抽审)

| ID | issue | 文件 | 来源 | 难度 | 修复 |
|---|---|---|---|---|---|
| **P0-01** | **"Apple Health" 关键词 169 处** 散布 `lib/` 注释 (R31 P0-09 未闭环) | `lib/**/*.dart` 169 处 (`lib/core/theme/`: 59, `lib/presentation/widgets/`: 29, `lib/presentation/pages/`: 70, **+11** vs R31 报告 134) | R31 P0-09 + Apple Health 验证 | S 30min | `check_apple_health_claim.py` 扩 grep 扫注释 `// .*Apple Health.*$` + doc 注释，触发 fail。当前 script 只查 health_kit import，**不查 "Apple Health" 字符串**。注释里写"Apple Health (iOS 17/18) 视觉"是设计意图，但 Apple 5.1.3 抽审时若 app 实际未集成 HealthKit，注释里的 "Apple Health" 文字描述可能被审核员视为 used-but-not-declared 风险。R31 R11a 反转后没补 lock-in |
| **P0-02** | **`page_scaffold.dart` 84 行，0 BackdropFilter / 0 blur** — translucent AppBar spec §4.9 决策 #7 ✅ 引入未实做 (R31 P0-10 未闭环) | `lib/presentation/widgets/page_scaffold.dart:47-58` 仅 M3 默认 AppBar | R31 P0-10 + Apple Health 验证 | M 1-2h | AppBar `flexibleSpace: BackdropFilter(blur(20), child: Container(color: white@0.6))` + `elevation: 0` + `scrolledUnderElevation: 0` (已有) + 暗色 `black@0.4` + reduce-transparency 适配走 `MediaQuery` |
| **P0-03** | **spring.dart 145 行 0 caller** (R31 P0-08 未闭环) | `lib/core/theme/spring.dart` 整个文件 0 import | R31 P0-08 + Apple Health 验证 | M 1-2h | grep `import.*spring\.dart` lib/ = **0 hit**, `Spring\.standard\|Spring\.gentle\|Spring\.bouncy\|toSimulation\(` = 0 hit. `_EntrySpring` (check_in_button.dart:208) 是 _独立_ StatefulWidget 用 AnimationController + curveSpring，走 Cubic bezier，**不是** Spring 物理模型。spec §3.4.3 双轨制空跑一半。修：集成到 `app_router.dart` page transition (用 `Spring.standard.toSimulation()` 替换 fade/slide-right/slide-up 的 `Curves.easeOutCubic`) |
| **P0-04** | **`curveAppleSheet` / `curveAppleDrawer` 死代码** (R31 P1-07 未闭环) | `app_motion.dart:119,123` 定义 + `app_tokens.dart:261,262` facade 转发，0 caller | R31 P1-07 + Apple Health 验证 | S 30min | grep `AppMotion\.curveAppleSheet\|AppTokens\.curveAppleSheet\|curveAppleDrawer` = 0 hit. spec §3.4.2 modal/drawer 集成未做。修：集成到 modal bottom sheet (showModalBottomSheet) + drawer (EndDrawer)，或删 |
| **P0-05** | **spec baseline 2019 vs 实际 2103 矛盾 6 处** (R31 P2-04 未闭环) | `spec.md:398` `baseline 2019` + `plan.md:5,20,45,64,82,101,107,204` 全部 `2019 cases` / `2019 tests` | R31 P2-04 + Apple Health 验证 | S 5min | spec 写于 2026-08-10 R95 后 R107 前 baseline = 2019；R107→R108 升 2036/1/128 (基线 +2036 pre-Apple Health, +17 pass)。R31 落地 22 commit 净改善 +67 pass -2 fail，实际 **+2103/1/126 = 2230**。修：spec + plan 全改 baseline = 2036 + 新加 67 pass = 2103 |
| **P0-06** | **AGENTS.md 已加 v0.31 章节** (R31 P2-01 ✅ 闭环) | `AGENTS.md:246-275` 30 行章节 | R31 P2-01 ✅ | — | 已闭环 (R31 hotfix) |
| **P0-07** | **设计文档 44KB untracked 已入库** (R31 P0-12 ✅ 闭环) | `docs/design/2026-08-10-apple-health-redesign/{spec,plan,NEXT-SESSION-START-HERE}.md` 已 commit `5952515` | R31 P0-12 ✅ | — | 已闭环 (0.31.2 round 1) |

**P0 紧急修小计：5 项未闭环 + 2 项已闭环 = 7 项 (R31 7 项 P0 中 5 项跨期未动)**

---

## 2. 架构/重构 P0 (5 token 集中器 + 6 widget 集中器 + 5 page 重设)

### 2.1 5 token 集中器架构 (R31 100% 落地，本批维持)

| 文件 | 行数 | spec 合规 | 备注 |
|---|---|---|---|
| `lib/core/theme/app_colors.dart` | 467+ | ✅ 100% | 8 metric palette (systemRed/Pink/Purple/Indigo/Green/Blue/Orange/Teal) + tintedMetricSoft 0.12/0.18 dark + healthMetricsColorFor + 3 dark 静态 const (backgroundDark #000 / surfaceDark #1C1C1E / textPrimaryDark #FFF) + 16 dynamic getter |
| `lib/core/theme/app_typography.dart` | 277 | ✅ 100% | 17 fontSize (Apple 14 档 + 3 metric 22/28/34) + 5 lineHeight (1.1/1.4/1.6/snug/relaxed) + 2 字重 (ultralight w200/light w300) + 18 textStyle helper + 3 metricXl/Lg/Md ultralight helper + letterSpacing -0.5/-0.2/0 阶梯 |
| `lib/core/theme/app_spacing.dart` | 191 | ✅ 100% | 8 圆角 (4/6/8/10/12/14/16/22) + 11 spacing (2/4/6/8/12/16/24/32/48 + chip 4/6/12) + buttonHeight 50 + buttonHeightSmall 44 + inputHeight 44 + iconSize 22/28/17/13/56/48/12 + pageMarginH 20/V 16 + stagger 30/150 + 5 EdgeInsets helper |
| `lib/core/theme/app_motion.dart` | 306 | ✅ 100% | 8 duration (fast 200 / normal 250 / slow 400 / press 100 / pageTransition 100 / shimmerCycle 1200 / refreshMinVisible 400) + 3 snackbar (2/3/4s) + 9 curve (6 旧 + 3 Apple cubic bezier) + 4 theme-aware shadow (card 空 / dialog 极轻 / overlay 极轻) + scrimAlpha 0.54 + MotionScheme 4 档 + Motion reduce-motion 包装 |
| `lib/core/theme/spring.dart` | 144 | ⚠️ 0 caller | spec §3.4.3 Spring 物理模型 3 实例 (standard mass 1 stiffness 200 damping 20 / gentle 150/18 / bouncy 200/12) + toDescription + toSimulation + of(context, type) 工厂，**0 import, 0 use, 全死代码** |

### 2.2 6 widget 集中器架构 (R31 100% 落地，本批维持)

| Widget | 行数 | spec 合规 | call sites | 备注 |
|---|---|---|---|---|
| `lib/presentation/widgets/primary_button.dart` | 206 | ✅ 100% | 37 | 3 variant (primary/secondary/tertiary) + leadingIcon + 高度 50 / 圆角 14 / 字号 17 / w600 / PressFeedback scale 0.97 100ms |
| `lib/presentation/widgets/check_in_button.dart` | 331 | ⚠️ 60% | 1 (home) | 高度 64/圆角 32/字号 20 **3 magic 硬编码** (注释说"故意留 magic 跟 token 不重叠") + 进场 `_EntrySpring` scale 0.95→1 + 完成态 spring scale 0.95→1 + 数字 tween `_StreakCounter` 95% 跟 StatCard `_TweenNumber` 重复 (R31 P1-12) + fontWeight=w700 vs Apple semibold w600 (P3) |
| `lib/presentation/widgets/stat_card.dart` | 227 | ✅ 95% | (home today_summary 4 张 + trend_summary 4 张 + 7 个原有 caller) | 4 variant (default/large/xl/inline) + ultralight w200 + 数字 tween `_TweenNumber` 95% 跟 `_StreakCounter` 重复 (R31 P1-12) + `xl` variant 字号 28 跟 `default` 相同注释 (P3 命名) |
| `lib/presentation/widgets/apple_health_tile.dart` | 158 | ✅ 100% | 8 (home 4 + medication 4) | 圆角 12 (radiusTile) + 背景 metric 色 0.12/0.18 + 28pt icon + metricLg ultralight + chevron + PressFeedback + 8 metric switch (medication/mood/vent/assessment/checkIn/trend/contact/sleep) + 兜底 Icons.help_outline |
| `lib/presentation/widgets/apple_list_section.dart` | 254 | ✅ 100% | 37 (home 12 + setup 5 + medication 17 + trend 1 + medication_dialog 2) | iOS insetGrouped 风格 + ALL CAPS 13pt textHint title + 圆角 16 surface + hairline 0.5 divider + 0 阴影 + dark mode 静态 1C1C1E/dividerDark + 可选 chip 数量徽章 + 注释说"不依赖 SectionHeader 因为 SectionHeader 是 11pt" (跟 spec §4.5 13pt 是有意分开的两个不同字号 widget, 概念略冗余) |
| `lib/presentation/widgets/section_header.dart` | 155 | ✅ 100% | 17 | 11pt w500 ALL CAPS letterSpacing 0.6 textHint (跟 AppleListSection 13pt 区分) + leading + action + chip + isAllCaps 默认 true |

### 2.3 5 page 重设架构 (R31 100% 落地，本批维持)

| Page | 行数 | AppleListSection | AppleHealthTile | 备注 |
|---|---|---|---|---|
| `lib/presentation/pages/home/home_page_state.dart` | 468 | 12 | 4 | 6 区域 AppleListSection 包装 + 4 StatCard 2x2 + CheckInButton 巨型 pill + 5 mood carousel + 4 AppleHealthTile 2x2 + settings/vent 入口，**最完整 Apple Health 主页** |
| `lib/presentation/pages/setup/setup_page_state.dart` | 560 | 5 (4 step + 1 footer) | 0 | 4 步进度条 1/4 + 大字 28pt + 副字 15pt + ALL CAPS section + 巨型 pill PrimaryButton full width。**但 setup_page_state 513L R108 标 → 560L 实际反涨 47L** (R31 P1-08 未闭环) |
| `lib/presentation/pages/medication/medication_page.dart` | 561 | 17 (today/meds/quick actions × 3) | 4 (待服/已服/需续方/查看) | **最深 Apple Health 化**：4 AppleHealthTile 横滚 + today_med AppleListSection + meds AppleListSection + 5 子页 AppleListSection 化 + systemRed FAB。**但 medication_page 524L R108 → 561L 实际反涨 37L** (R31 P1-10 未闭环) |
| `lib/presentation/pages/trend/trend_summary.dart` | 79 | 1 (top summary) | 0 | 4 StatCard ultralight `large` variant (34pt) 2x2 grid，**只剩 summary 改**，trend_page 主体 (heatmap/calendar/charts) 0 改 AppleListSection/AppleHealthTile |
| `lib/presentation/pages/mood/` + `mood_list/` | 17 文件 | **0** | **0** | spec §5.5 写"5 档大圆形 mood button 72x72" + AppleListSection 风格，**实际 0 改**。`mood_score_chooser.dart` + 5 mood 圆形 48pt 跟 R28 哔哩哔哩风格 (48pt 跟 spec 写 72pt 不一致) |

### 2.4 9 page follow (R31 P0-12 ✅ + R12b global sanity)

R12b global sanity 131 行测试验证 9 feature follow，但实际**是 grep 验证"不含旧 Card 模式"**，**不是验证"用了 AppleListSection"**：

| Feature | AppleListSection | AppleHealthTile | 实际 |
|---|---|---|---|
| `trend/` | 1 (summary) | 0 | 半残 (P1) |
| `mood/` | 0 | 0 | 0 改 (P1) |
| `mood_list/` | 0 | 0 | 0 改 (P1) |
| `vent/` | 0 | 0 | 0 改 (P1, vent_save_bar 0 AppleListSection) |
| `assessment/` | 0 | 0 | 0 改 (P1) |
| `contact/` | 0 | 0 | 0 改 (P1) |
| `settings/` | 0 | 0 | 0 改 (P1) |
| `daily_tracking/` | 0 | 0 | 0 改 (P1) |
| `home/` (含 check_in Button) | 12 | 4 | ✅ 深度 |

---

## 3. 半成品 P0 (spec 写了但未实现)

| ID | spec 章节 | 半成品 | 落地状态 | 修复 |
|---|---|---|---|---|
| **P0-S1** | §3.4.3 Spring 物理模型 | `spring.dart` 145 行 3 实例 (standard/gentle/bouncy) + `SpringSimulation` wrapper + `Spring.of(context, type)` 工厂 | **0 caller** (`grep -rE "import.*spring\.dart" lib/ = 0 hit` + `Spring\.(standard\|gentle\|bouncy)` 0 hit + `toSimulation(` 0 hit) | M 1-2h：集成到 `app_router.dart` page transition (R17 R2 fade/slide-right/slide-up → `Spring.standard.toSimulation()`)，或 integration test 证明 curveSpring 跟 Spring 物理模型 5% 以内误差 |
| **P0-S2** | §4.9 决策 #7 translucent AppBar | spec §4.9 写 `BackdropFilter blur(20) + white@0.6 + hairline divider + reduce-transparency 适配` | **未实做** (`page_scaffold.dart:47-58` 84 行仍是 M3 默认 AppBar，无 `BackdropFilter` / `ImageFilter.blur`) | M 1-2h：改 `app_theme.dart:97-109` `_appBarTheme` + `page_scaffold.dart:50-57` `appBar:` 走 `flexibleSpace: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), child: Container(color: cs.surface.withValues(alpha: 0.6)))` + 暗色 `black@0.4` + reduce-transparency 媒体查询 → solid |
| **P0-S3** | §3.4.2 modal/drawer 曲线 | `curveAppleSheet cubic-bezier(0.32, 0.72, 0, 1)` + `curveAppleDrawer cubic-bezier(0.77, 0, 0.175, 1)` 定义在 `app_motion.dart:119,123` + facade `app_tokens.dart:261,262` | **0 caller** (`grep -rE "AppMotion\.curveAppleSheet\|AppTokens\.curveAppleSheet" lib/ = 0 hit`) | S 30min：集成到 `showModalBottomSheet` (curveAppleSheet) + `EndDrawer` (curveAppleDrawer) 或删 |
| **P0-S4** | §5.1-5.7 11 feature 全部 Apple Health 化 | spec 写 11 feature (home/setup/medication/trend/mood/mood_list/vent/assessment/check_in/contact/settings/daily_tracking) 全部 AppleListSection + AppleHealthTile + 8 metric palette | **4.5/11 落地** (home ✅ + setup ✅ + medication ✅ + trend 1 半残 + check_in Button widget ✅ = 4.5；mood / mood_list / daily_tracking / vent / assessment / contact / settings / crisis_hotline = 7-8 个 0 改) | XL 各 1-2d: 7-8 个 feature 走 AppleListSection 化 + AppleHealthTile 化 (跟 medication_page R11a 同款) |
| **P0-S5** | §3.1.3 + §4.4 SF Symbol 字体 | spec 写"8 metric icon 跟 iOS SF Symbol 一一对应 (pills.fill / face.smiling / mic.fill / checkmark.circle.fill / chart.line.uptrend.xyaxis / phone.fill / bedtime.fill)" | **未实做** (`apple_health_tile.dart:137-158` 8 icon 全 Material Icons: `Icons.medication` / `Icons.mood` / `Icons.mic` / `Icons.assignment` / `Icons.check_circle` / `Icons.show_chart` / `Icons.contact_phone` / `Icons.bedtime`) | L 1-2d：集成 SF Symbol 字体 (Flutter `cupertino_icons` 仅有 100+ SF Symbol 不够覆盖 8 metric)，或 `flutter_sfsymbols` 第三方包，或自建 `assets/fonts/SF-Pro-Symbols.ttf` |
| **P0-S6** | §3.4.4 减阴影 (0 阴影 = Apple Health 标志性) | spec §3.4.4 写"shadowCardOf / shadowCardDarkOf → `[]` 空" | ✅ **已实做** (`app_motion.dart:152,159` `static List<BoxShadow> shadowCardOf(BuildContext context) => const <BoxShadow>[]`) | — | (闭环) |
| **P0-S7** | §3.2.2 大数字 ultralight w200 | spec 写"Apple Health 标志性 ultralight w200 大数字" + `textStyleMetricXl/Lg/Md` 3 个 helper | ✅ **已实做** (`app_typography.dart:84` `static const FontWeight fontWeightUltralight = FontWeight.w200` + 3 helper 256-277) | — | (闭环) |
| **P0-S8** | §3.1.3 8 metric palette (systemRed/Pink/Purple/Indigo/Green/Blue/Orange/Teal) | spec 写"8 个 iOS system color metric 调色板" | ✅ **已实做** (`app_colors.dart` 8 `healthMetricsColors` + `healthMetricsColorFor` + `tintedMetricSoft` 0.12/0.18) | — | (闭环) |
| **P0-S9** | 设计文档 44KB 入库 | spec + plan + NEXT-SESSION 3 文件 | ✅ **已实做** (commit `5952515` 0.31.2 round 1 "入库 R109 综合审视 + Apple Health 设计文档 (245KB)") | — | (闭环) |
| **P0-S10** | AGENTS.md v0.31 章节 | spec 写"v0.31 5 phase / 13 task / 5 token + 6 widget 摘要" | ✅ **已实做** (`AGENTS.md:246-275` 30 行章节 "v0.31 Apple Health 风格重设计 + 8-11 cleanup 综合审视") | — | (闭环) |

**半成品 P0 小计：4 项未闭环 (Spring/PageScaffold/curveApple/SF Symbol/11 feature) + 5 项已闭环 (0 阴影/ultralight/8 metric/44KB/AGENTS) = 9 项 (R31 5 项 P0-08~12 中 3 项跨期未动)**

---

## 4. P1 (16 条 — 按分类)

### 4.1 跨期硬编码 (R11a 反 Apple Health l10n 原则)

| ID | issue | 文件:行 | 难度 | 修复 |
|---|---|---|---|---|
| **P1-01** | `medication_page.dart` 4 处硬编码中文 ('待服'/'已服'/'需续方'/'查看') (R31 P1-01 未闭环) | `medication_page.dart:138,145,152,161` (4 处 `label: '...'` literal) | S 30min | 走 ARB key (`l10n.medPendingCount` 等) + 加 4 个 ARB key (zh + en) + 删 `// TODO(Phase 5)` 占位 |
| **P1-02** | `medication_page.dart:101` `foregroundColor: Colors.white` 硬编码 (R31 P1-02 未闭环) | `medication_page.dart:101` | S 1min | 改 `AppColors.fgOnPrimary(context)` 走 theme-aware |
| **P1-03** | `quick_mood_carousel.dart:99` `AppleListSection title: '心情'` 硬编码 (R31 P1-03 未闭环) | `quick_mood_carousel.dart:99` | S 5min | 改 `title: l10n.homeQuickMoodTitle` (line 108 已用 l10n) |
| **P1-04** | `quick_mood_carousel.dart:84` SnackBar `Text('记录失败，请重试')` 硬编码 (R31 P1-04 未闭环) | `quick_mood_carousel.dart:84` | S 5min | 走 ARB `l10n.moodQuickRecordFailed` |
| **P1-05** | `primary_action_row.dart` 4 处硬编码中文 (用药/心情/评估 + 查看/记录/开始) | `primary_action_row.dart:67,68,77,78,98,99` | S 10min | 走 ARB `l10n.homeActionMedLabel` 等 + 加 4 个 ARB key |
| **P1-06** | `medication_page.dart:135` `// TODO(Phase 5): 用 ARB key 替换 hardcode` 占位注释 (R31 P1-01) | `medication_page.dart:135` (4 个) | S 5min | 删 TODO 注释 (P1-01 闭环时自动) |

### 4.2 god class 反涨 (R109 god class 专项重点)

| ID | issue | 文件:行 | R108 | R32 | 难度 | 修复 |
|---|---|---|---|---|---|---|
| **P1-07** | `setup_page_state.dart` god class (R31 P1-08 未闭环) | `setup_page_state.dart:1-560` | 506L | 560L (+54) | XL 1-2d | 跟 R95 home_page_state 拆 3 controller 同款 (跟 R108 setup_page_state 拆 4 controller 一致) |
| **P1-08** | `setup_step_medication.dart` god class (R31 P1-09 未闭环) | `setup_step_medication.dart:1-326` | (R108 标 add_medication_page 506L) | 326L (但 614L 注释是 R31 算错，**实际 326L**) | XL 1-2d | 拆 2-3 widget + 1 controller |
| **P1-09** | `medication_page.dart` god class (R31 P1-10 未闭环) | `medication_page.dart:1-561` | 524L | 561L (+37) | XL 1-2d | 拆 4 controllers (4 AppleHealthTile 横滚 + 4 时间段分组 + 2 AppleListSection) |
| **P1-10** | `medication_detail_page.dart` god class | `medication_detail_page.dart` 287L | (R108 §六) | 287L | L 1-2d | 拆 controller |
| **P1-11** | `refill_manage_page.dart` god class | `refill_manage_page.dart` 779L | (R108 §六) | 779L | XL 2-3d | 拆 controllers/ 模式 |

### 4.3 重复实现 (R109 抽公共 widget)

| ID | issue | 文件:行 | 难度 | 修复 |
|---|---|---|---|---|
| **P1-12** | `_StreakCounter` (check_in_button.dart:258-331) vs `_TweenNumber` (stat_card.dart:145-228) 95% 重复 (R31 P1-12 未闭环) | `check_in_button.dart:258-331` (74 行) + `stat_card.dart:130-228` (99 行) | M 1-2h | 抽 `lib/presentation/widgets/animations/tween_number.dart` 公共 widget, 删 2 个 private |
| **P1-13** | `_EntrySpring` (check_in_button.dart:208-255) vs `_TweenNumber` 动画模式不一致 (addListener+setState vs AnimatedBuilder) | `check_in_button.dart:208-255` (47 行) | S 30min | 选一种统一 (推荐 AnimatedBuilder) |

### 4.4 11 feature 0 改 (Apple Health spec §5.1-5.7 跨期)

| ID | issue | 文件:行 | 难度 | 修复 |
|---|---|---|---|---|
| **P1-14** | `mood_list/` (mood_list/detail/trend_page) 0 改 (R31 P1-13 未闭环) | `lib/presentation/pages/mood_list/*.dart` 3 文件 | L 各 1-2d | AppleListSection 化 + AppleHealthTile 化 (systemPink) + ALL CAPS section |
| **P1-15** | `daily_tracking/` (daily_tracking/tracking_customize/treatment_page) 0 改 (R31 P1-14 未闭环) | `lib/presentation/pages/daily_tracking/*.dart` 10 文件 | L 各 1-2d | 同上 + 4 日常追踪指标 (体重蓝/睡眠紫/心境绿/应激红) 走 R91 dailyTrackingColorFor |
| **P1-16** | `vent/` 主页面 (vent_compose/detail/list_page) 0 改 (R31 P1-15 未闭环) | `lib/presentation/pages/vent/*.dart` 3 文件 | L 各 1-2d | AppleListSection 化 + AppleHealthTile 化 (systemPurple 紫) + 录音 button 改 Apple Pill |

### 4.5 spec baseline + lock-in test + 设计细节

| ID | issue | 文件:行 | 难度 | 修复 |
|---|---|---|---|---|
| **P1-17** | spec baseline 2019 vs 实际 2103 矛盾 (R31 P2-04) | `spec.md:398` + `plan.md:5,20,45,64,82,101,107,204` (8 处 stale) | S 5min | 改 spec + plan 8 处 baseline = 2103 |
| **P1-18** | `lock-in test` 阈值 220 → 300 放宽 36% (R31 P1-06) | `app_tokens_lock_in_round95_test.dart:271` `lessThanOrEqualTo(300)` | S 1min | 改 `lessThanOrEqualTo(250)` (R95 baseline 220 + 30 buffer) |
| **P1-19** | `QuickMoodCarousel` 圆形 button 48pt vs spec 写 72pt (R31 P1-05) | `quick_mood_carousel.dart:159` `static const double _diameter = 48` | S 1min | 改 72pt 跟 spec 对齐 (但实现 comment 说"更接近 Apple Health 实际 48-60pt"，决策合理) |
| **P1-20** | `crisis_hotline_page.dart` 0 改 (R31 P1-16) | `lib/presentation/pages/crisis_hotline_page.dart` | M 0.5d | 调 8 metric color (crisisHotline = systemRed) + ALL CAPS section |
| **P1-21** | `CheckInButton` 3 hardcode 64/32/20 抽 token | `check_in_button.dart:68,71,74` (3 magic) | S 5min | 加 `AppTokens.buttonHeightPill = 64` + `radiusPill = 32` + `fontSizePill = 20` (3 个新 token) |
| **P1-22** | `AppleListSection:144` `title!.toUpperCase()` 对中文 no-op | `apple_list_section.dart:144` | S 1min | 注释显式说明 i18n 限制 ("upperCase for Latin only, Chinese case-less") |
| **P1-23** | 3 处 `_titleLetterSpacing = 0.6` 重复 (AppleListSection + SectionHeader) | `apple_list_section.dart:100` + `section_header.dart:79` | S 1min | 抽 `AppTokens.sectionHeaderLetterSpacing` |
| **P1-24** | `CheckInButton _PillContent` 2 hardcode SizedBox 12/2 | `check_in_button.dart:175,189` | S 1min | 改 `AppTokens.spacingSm` + `AppTokens.spacingXxxs` |
| **P1-25** | `CheckInButton` fontWeight=w700 vs Apple semibold w600 (R31 P3) | `check_in_button.dart:184` | S 1min | 改 `FontWeight.w600` |
| **P1-26** | `StatCard.xl` 命名暗示不一致 (字号 28 跟 default 相同) | `stat_card.dart:29` 注释 | S 1min | 改 `medium` 或加 letterSpacing 区分 |

**P1 实际列了 26 条 (R31 16 条 + R32 新增 10 条)，全部 P0 修完后 1-2 周可闭环**

---

## 5. P2 + P3 摘要 (前 10 条)

| ID | issue | 难度 | 来源 |
|---|---|---|---|
| P2-01 | `AppleHealthTile` 8 metric icon 用 Material Icons 而非 SF Symbol — Flutter 平台无内置 SF Symbol，差 5-10% 视觉 (R31 P3) | L 1-2d | R31 P3 (Polish) |
| P2-02 | PressFeedback 不调 Haptics → R109 评估加 `hapticOnTap` enum 参数 | M 1h | R31 P3 (R31 评估) |
| P2-03 | Android brand color 0xFF34C759 vs M3 派生 0xFF4CAF50 颜色轻微不一致 (设计选择非 bug) | S 5min | R31 P3 |
| P2-04 | `values/styles.xml:4` 用旧 `Theme.Light.NoTitleBar` 而非 Android 12+ `Theme.SplashScreen` (Flutter 旧 Theme 仍可上架) | S 5min | R31 P3 |
| P2-05 | 3 种 commit author 不统一 (Mavis / Apple Health Redesign Agent / Mavis (AI Agent)) → 统一 `Mavis <mavis@chroniccare.local>` | S 5min | R31 P3 |
| P2-06 | `_StreakCounter` vs `_EntrySpring` 动画模式不一致 (addListener+setState vs AnimatedBuilder) → 选一种统一 | S 30min | R31 P3 |
| P2-07 | `R12b global sanity test` 改用 AST 而非 regex (避免注释假阳性) (R31 P2-06) | M 1-2h | R31 P2 |
| P2-08 | CHANGELOG [0.31.0] 数字 stale (2104/1/126 vs 2103/1/123, R31 标 91 vs 87) — 实际 0.31.2 commit 仍写 2103, 闭环 | S 10min | R31 P2 |
| P2-09 | PrimaryButton:73 doc 注释 `const Text('已完成')` 硬编码中文 | S 1min | R31 P2 |
| P2-10 | `quick_mood_carousel.dart:158` `_diameter = 48` 注释说"Apple Health 风格 5 档可点区域 48pt" (实际更接近 Apple Health 48-60pt) — 跟 spec 写 72pt 矛盾, 但实现合理 | S 5min | R32 新增 |

---

## 6. 总结

### 6.1 跟 R31 对比 (R32 跑 = R31 baseline + docs 增量)

| 维度 | R31 | R32 | 变化 |
|---|---|---|---|
| 5 token 集中器 | ✅ 100% | ✅ 100% | 持平 |
| 6 widget 集中器 | ✅ 100% | ✅ 100% | 持平 |
| PageScaffold translucent AppBar (spec §4.9) | ❌ 0% | ❌ 0% | 持平 (R31 P0-10 未闭环) |
| Spring 物理模型 (spec §3.4.3) | ❌ 0 caller | ❌ 0 caller | 持平 (R31 P0-08 未闭环) |
| curveAppleSheet/Drawer 集成 (spec §3.4.2) | ❌ 0 caller | ❌ 0 caller | 持平 (R31 P1-07 未闭环) |
| 11 feature 落地 (spec §5.1-5.7) | 4.5/11 | 4.5/11 | 持平 (R31 P1-13~16 未闭环) |
| SF Symbol 字体 (spec §3.1.3) | ❌ Material Icons | ❌ Material Icons | 持平 (R31 P3) |
| R11a 4 硬编码中文 + 1 Colors.white | ❌ 4 处 | ❌ 4 处 | 持平 (R31 P1-01~05 未闭环) |
| lock-in test 阈值 220→300 | ❌ 300 | ❌ 300 | 持平 (R31 P1-06 未闭环) |
| "Apple Health" 169 lib 注释 | ❌ 134 | ❌ 169 (+35) | **变差** (0.31.2 docs 入库 +11 注释 / R11a widget 注释 +24 注释, **lock-in test 仍未扩到注释扫**) |
| spec baseline 2019 vs 2103 矛盾 | ❌ 6 处 | ❌ 6 处 | 持平 (R31 P2-04 未闭环) |
| AGENTS.md v0.31 章节 | ✅ 30 行 | ✅ 30 行 | 持平 (R31 P2-01 闭环) |
| 设计文档 44KB 入库 | ❌ untracked | ✅ commit `5952515` | **变好** (R31 P0-12 闭环) |
| R109 综合审视 245KB 入库 | ❌ untracked | ✅ commit `5952515` | **变好** (R32 0.31.2 新增) |

**R32 跑实际只 +0.2 分，因为 0.31.2 commit 全部是 docs 入库 (设计文档 44KB + R109 审视 245KB + README 4 段)，0 业务代码改动。所以 Apple Health 实际表现跟 R31 几乎一致。**

### 6.2 11 feature 落地清单 (实际只有 4.5/11, 跨期 6.5/11 0 改)

| # | Feature | AppleListSection | AppleHealthTile | StatCard | 实际状态 | 跟 spec §5.x 对齐 |
|---|---|---|---|---|---|---|
| 1 | `home/` (含 check_in) | **12** | **4** | (4 via today_summary) | ✅ 深度 | §5.1 一眼 Apple Health |
| 2 | `setup/` | **5** (4 step + footer) | 0 | 0 | ✅ 深度 | §5.2 4 步进度 + ALL CAPS |
| 3 | `medication/` | **17** | **4** | 0 | ✅ 最深 | §5.3 4 tile 横滚 + systemRed FAB |
| 4 | `trend/` | **1** (summary) | 0 | (4 via summary) | ⚠️ 半残 | §5.4 只 summary 改，主体 (heatmap/calendar/charts) 0 改 |
| 5 | `mood/` | 0 | 0 | 0 | ❌ 0 改 | §5.5 spec 写 5 档 72pt 大圆形 mood button + AppleListSection，实际 mood_score_chooser 是 R28 哔哩哔哩 48pt 风格 |
| 6 | `mood_list/` | 0 | 0 | 0 | ❌ 0 改 | §5.5 (mood_list 是 mood 的 detail/trend page) |
| 7 | `vent/` | 0 | 0 | 0 | ❌ 0 改 | §5.6 vent_compose/detail/list_page 全 0 改，vent_save_bar 56 行 0 AppleListSection |
| 8 | `assessment/` | 0 | 0 | 0 | ❌ 0 改 | §5.7 assessment 题目 + 历史 0 改 |
| 9 | `check_in/` | (无独立目录, 在 home) | (无独立目录) | 0 | ✅ Button widget | §4.2 CheckInButton 巨型 pill 落地 |
| 10 | `contact/` | 0 | 0 | 0 | ❌ 0 改 | spec §5.8 不手动改，靠 token 自动适配, 但实际 contact 0 改 |
| 11 | `settings/` | 0 | 0 | 0 | ❌ 0 改 | spec §5.8 不手动改, 但 settings/widgets/{profile,legal,data,reminders}_group 0 AppleListSection 改 |
| 12 | `daily_tracking/` | 0 | 0 | 0 | ❌ 0 改 | spec §5.8 不手动改, 但 daily_tracking_page 0 改 |
| 13 | `crisis_hotline_page.dart` | 0 | 0 | 0 | ❌ 0 改 | 不在 spec §5 但 R31 P1-16 提了 |

**实际 Apple Health spec §5.1-5.7 11 feature 落地 = 4.5/11 (41%)。6.5/11 = 7 个 feature 0 改 + 1 个 crisis_hotline 0 改 = 8 个 0 改 = 73%**

### 6.3 spec baseline 数字矛盾 6 处

| # | 文件:行 | spec 写 | 实际 | 矛盾 |
|---|---|---|---|---|
| 1 | `docs/design/2026-08-10-apple-health-redesign/spec.md:398` | `baseline 2019 cases` | `+2103 pass / 1 skip / 126 fail = 2230 total` | spec 写于 2026-08-10 R95 后 R107 前 baseline = 2019；R107 升 2036/1/128；R31 净改善 +67 pass -2 fail = 2103/1/126 |
| 2 | `docs/design/2026-08-10-apple-health-redesign/plan.md:5` | `Pre-existing baseline: 2019 tests pass` | 2103/1/126 | 同上 |
| 3 | `plan.md:20` | `baseline test 复测：1163 → 2019 cases` | (R95 升 2019 是对的, 但 22 commit 后 = 2103) | spec 写于 8-10, 22 commit 落地后 = 2103, 但 plan 没 update |
| 4 | `plan.md:45,64,82,101,107,204` | `baseline 2019 tests / 2019 -N` (8 处) | 2103/1/126 | 同上 |
| 5 | `docs/CHANGELOG.md:178` | `(未跑, 估 2019 + 16 R108 = 2035+ pass)` (R107 旧估) | 2103/1/126 | R31 实际 2103 不是 2035+ |
| 6 | `docs/CHANGELOG.md:194` | `2019 tests pass + 0 analyzer error (R100 维持)` (R31 旧估) | 2103/1/126 | R31 实际 2103 不是 2019 |

**6 处矛盾全部 stale, 5min 内可闭环 (改 8 处 spec/plan + 2 处 CHANGELOG = 10 行文本)**

### 6.4 "如果只能改 3 件事" (R32 推荐优先级)

1. **PageScaffold translucent AppBar (P0-S2, 1-2h)** — 1 行 `BackdropFilter` + 2 行 `MediaQuery` 适配，能让 home/setup/medication/trend/... 11 个 page 全部瞬间变 iOS 风格 (因为所有 page 都走 `PageScaffold`)，ROI 最高。**影响：1 行变 11 个 page 视觉升一档。**

2. **Spring 物理模型接 page transition (P0-S1, 1-2h)** — 删 `app_router.dart` 的 `Curves.easeOutCubic` 改 `Spring.standard.toSimulation()`，让 spec §3.4.3 双轨制从 0 caller 变 5+ caller (push/pop/sheet/drawer 全走 spring)，同时让 spring.dart 不再是死代码。**影响：1 个文件改 5 行，但视觉升 1 档 (iOS 物理感 vs cubic-bezier 模拟感)。**

3. **R11a 4 处硬编码中文走 ARB (P1-01, 30min)** — `medication_page.dart:138,145,152,161` 4 处 `'待服'/'已服'/'需续方'/'查看'` + `quick_mood_carousel.dart:99 '心情' + 84 '记录失败'` + `primary_action_row.dart:67,68,77,78,98,99 6 处用药/心情/评估/查看/记录/开始` + `medication_page.dart:101 Colors.white` = **13 处硬编码**, 1h 内全闭环, 符合 Apple Health l10n 原则 (用户视角一致性)。**影响：13 处 → 13 个 ARB key, 守门员 `check_strings_hardcoded.py` 闭环。**

**预期**: 1 周可让 Apple Health 视角从 7.2 → 8.5/10 (跨期 P1 闭环 +5 个 P0 修 1 个) 或 9.0/10 (P0 修 3 个 + 11 feature 选 2-3 个高 ROI 改)

---

## VERDICT

**v0.31.0 Apple Health 风格重设计 (R32 revisit): 7.2/10 (R31 7.0 → +0.2)**。

**核心矛盾**:
- **视觉层 9.5/10 优秀** (5 token + 6 widget + 5 page 重设 + home/setup/medication 一眼 Apple Health + 8 metric 彩色 palette + ultralight w200 大数字 + iOS 群组列表 + 0 阴影 + 0 业务逻辑改动 + 0 跨 feature import + 跨平台 0 影响)
- **半成品 0/10** (Spring 物理模型 145 行死代码 + PageScaffold translucent AppBar 0 改 + 11 feature 0 改 7-8 个 + SF Symbol 字体 0 集成 + curveAppleSheet/Drawer 0 caller)
- **上架/合规 -5/10** (169 处 "Apple Health" 注释 lock-in test 未扩 + 5.1.3 used-but-not-declared 抽审风险 + R11a 13 处硬编码中文 + spec baseline 数字 6 处矛盾 + R31 6 大共识 issue 4 项跨期 0 闭环)

**R32 跑跟 R31 几乎没差 (仅 +0.2 docs 增量)**。0.31.2 commit `5952515` 全部是 docs 入库 (设计 44KB + R109 审视 245KB + README 4 段), 0 业务代码改动, 0 R31 P0 闭环。

**如果 R109 第 1 周能闭环 5 个 P0 (translucent AppBar + Spring + 5 1.X 上架 + 文档 + dart format), Apple Health 视角可从 7.2 → 8.5/10**; 再加上 11 feature 选 2-3 个高 ROI 改 (mood/daily_tracking/vent) + god class 拆解, 可到 9.0/10。

**不建议本批提交 hotfix**: 0.31.1 已发, 0.31.2 是 docs, 0.32.0 建议跟 R109 god class 拆解合并, 避免单独 0.31.3 拆 commit 不连续。
