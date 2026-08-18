# Apple Health 视角审视报告 — 2026-08-13 R112

## 0. 元数据

- 视角: Apple Health 风格 / HealthKit 合规 (06)
- 审视者: apple-health subagent
- 审视时间: 2026-08-13
- baseline: HEAD=6bbb308, working tree=127M + 13?? (R112 = R111 hotfix 执行中)
- 方法: 只读。逐节读 spec.md (§1-§10) 建 checklist → 实读 `lib/core/theme/` 全部 8 文件 + `lib/presentation/widgets/` 6 个集中器 + 抽查 home/setup/medication/trend/vent/mood/assessment/settings/contact 页面 → grep 全量计数 (AppleListSection / AppleHealthTile / StatCard / Spring. / Color(0xFF / healthMetricsColorFor) → 跑守门员 `check_apple_health_claim.py` → 核对 iOS 三处 HealthKit 声明一致性。
- 范围文件清单:
  - `docs/design/2026-08-10-apple-health-redesign/spec.md` (503 行, 全读)
  - `lib/core/theme/`: app_colors (502) / app_typography (278) / app_spacing (192) / app_motion (306) / spring (145) / app_theme (245) / app_tokens (facade, 抽查) 全读
  - `lib/presentation/widgets/`: primary_button (211) / check_in_button (307) / stat_card (140) / apple_health_tile (177) / apple_list_section (257) / section_header (161) / page_scaffold (140) / press_feedback (抽查) 全读
  - 页面抽查: home_page_state / home widgets (home_header, today_summary_card, primary_action_row, secondary_action_row, quick_mood_carousel) / setup_page_state / medication_page / vent_list_page / vent_compose_page / mood_score_chooser / app_shell
  - iOS 配置: `ios/Runner/PrivacyInfo.xcprivacy` (146) / `ios/Runner/Runner.entitlements` / `ios/Runner/Info.plist` (抽查) / `pubspec.yaml` (抽查)
  - 守门员: `scripts/check_apple_health_claim.py` (全读 + 实跑)
  - 旧报告 `docs/audit/2026-08-13-r111-multi-lens/06-apple-health.md` 仅当待验证清单

## 1. 整体评分 (0-10)

**7.0 / 10** — 设计系统 token 落地近乎完美 (lib/presentation 0 处硬编码 Color, 实测验证), HealthKit 合规 enforced, R112 又闭环 EM-14/16/18/21 4 项视觉修复; 但 spec §5 页面采纳仍 4/11, 8 个 feature 0 AppleListSection 的 P1 视觉债与 R111 完全一致 0 进展, 且 spec 完成度数字出现新的不可复现膨胀 (home "17 ALS" vs 实测 4)。

## 2. 关键发现 (按 P0/P1/P2/P3 排序)

### P0

无。HealthKit 合规链路 (守门员 + PrivacyInfo + entitlements + Info.plist + pubspec) 五处一致, 无假声明风险, 不阻塞上架。

### P1

- [架构] **[AH-04-r112] 8 个 feature 仍 0 AppleListSection 化 — 最大视觉债跨期残留, 0 进展**
  - 难度: XL — 工作量: 1-2d/页
  - 位置: 实测 `grep AppleListSection|AppleHealthTile|StatCard` → `lib/presentation/pages/{mood,mood_list,vent,assessment,contact,settings,daily_tracking,crisis_hotline_page.dart}` = **0 命中**; 证据: mood/widgets/mood_score_chooser.dart:51-80 (DimensionRow 4 连, 0 Apple 化) / vent/vent_list_page.dart:255 (`Card`) / assessment/widgets/assessment_history_list.dart (`Card`) / crisis_hotline_page.dart (ListView)
  - 现状: spec §5.5/5.6/5.7 三个"中等改" + contact/settings/daily_tracking 三个"自动适配" + crisis_hotline 全部保持旧方言 (Card+ListTile)。与 R111 AH-04 逐 feature 比对, 一处未变。
  - 建议: R112 hotfix 范围外, 进 R112/R113 视觉专项 (AGENTS 路线图已有 "EM-02/AH-04 8 feature ALS 化 1-2d/页"); 建议先做 vent (已有 AppBar icon 可顺手补 FAB) → assessment history → mood_list。

### P2

- [底层] **[AH-13-r112] spec §5 完成度数字膨胀, 与代码不可复现** — 难度:S — 工作量:0.5h
  - 位置: `docs/design/2026-08-10-apple-health-redesign/spec.md:318` vs 本次 grep 实测
  - 现状: spec 声称 home "17 ALS" (实测 `AppleListSection(` 调用 4 处) / setup "20 ALS" (实测 5 处) / medication "55 ALS / 9 文件" (实测 17 处 / 8 文件) / trend "4 ALS" (实测 1 处)。总实测 27 处 runtime 调用。R111 注记的数字本身就没能复现, R112 又原样继承。
  - 建议: 用 `grep -c "AppleListSection("` 重算 4 个 feature 真实调用数写回 spec:318, 并注明统计口径 (调用点 vs 文件数)。
- [视觉] **[AH-16-r112] 8-metric 面板实际只用 4 色, 3 处 tile 全是同色同 icon** — 难度:M — 工作量:2-3h
  - 位置: `lib/presentation/pages/medication/medication_page.dart:126-148` (4 个 AppleHealthTile **全 `metricId: 'medication'`**) / `lib/presentation/pages/home/widgets/primary_action_row.dart:65-97` (medication/mood/vent/assessment)
  - 现状: tile 实调 9 处 = medication×5 + mood×1 + vent×1 + assessment×1; checkIn/trend/contact/sleep = 0 tile。medication_page 的 4 个横滚 tile 用同一个 systemRed + 同一个 `Icons.medication` 图标, 视觉上 4 块同质 (spec §5.3 意图是 "medication / refill / history / ..." 不同 metric 映射)。`tintedMetricSoft` 0 runtime caller (死 token, AppleHealthTile 自己 inline `withValues(alpha:)`, apple_health_tile.dart:89)。palette 本身 8 色完整 (app_colors.dart:422-431)。
  - 建议: medication 4 tile 改映射不同语义色 (refill=orange, history=blue 等), 或至少 icon 区分; `tintedMetricSoft` 接回 AppleHealthTile 或删。
- [a11y] **[AH-08-r112] reduce-transparency 仍是 disableAnimationsOf 假代理** — 难度:M — 工作量:1-2h
  - 位置: `lib/presentation/widgets/page_scaffold.dart:63,86-103`; spec.md:69 已文档化 (R111 同步, AH-14 闭环 ✅)
  - 现状: 用户开 reduce-motion → 连带丢 translucent (走 solid), 语义错位但已注释文档化取舍。Flutter 未暴露 iOS reduce-transparency 媒体查询, 真代理需 AccessibilityInfo/原生 bridge。
  - 建议: 维持现状或 R113 起接 `MediaQuery.platformBrightness`+原生 channel; 上架前 a11y 抽审风险低 (可解释)。
- [spec] **[AH-15-r112] vent FAB 未落地 (spec §5.6 systemPurple FAB)** — 难度:M — 工作量:2h
  - 位置: spec.md:366-367 vs `lib/presentation/pages/vent/vent_list_page.dart:50-54` (AppBar `PressFeedbackIconButton(Icons.add)`, 无 FloatingActionButton)
  - 现状: 与 R111 完全一致, 0 进展。medication 的 systemRed FAB 已落地 (medication_page.dart:83-88, `healthMetricsColorFor('medication')`), vent 缺失形成同 App 内不对称。
  - 建议: 与 AH-04 vent ALS 化同批做, FAB 走 systemPurple + radiusLargeButton。
- [spec] **[AH-09-r112] SF Symbol 0 集成** — 难度:L — 工作量:1-2d
  - 位置: `pubspec.yaml` (无 fonts section, 仅 shaders+assets); `apple_health_tile.dart:155-176` 8 metric 全 Material `Icons.*`
  - 现状: spec §3.1.3 决策记录未要求 SF 字体, 但 iOS 17/18 视觉语言 claim 依赖 Material 图标占位。跨期残留, 不阻塞。
  - 建议: v1.0 前引入 cupertino_icons 或真 SF Symbols (需字体 license 评估), 至少 tile 8 icon 换 `CupertinoIcons` 免费档。

### P3

- [spec] **[R112-AH-101] headline 22 与 lineHeightRelaxed 1.5 未落地** — 难度:S — 工作量:10min
  - 位置: `app_typography.dart:40` (fontSizeHeadline = 24.0, spec §3.2.1 要求 24→22) / `app_typography.dart:78` (lineHeightRelaxed = 1.6, spec §3.2.3 要求 1.6→1.5)
  - 现状: 两处 token 值保持旧值且无注释说明是有意偏离。其余 12 档字号 + 5 档行高全部按 spec 落地。
  - 建议: 改值或补注释 ("有意保留"决策记录), 二选一消除 spec-code 漂移。
- [spec] **[R112-AH-102] hairlineDivider 命名 helper 从未落地 + 全局 dividerTheme 仍 1px** — 难度:S — 工作量:0.5h
  - 位置: spec §3.4.4 "新增 hairlineDivider helper" vs 代码 0 命中; `app_theme.dart:42-46` (dividerTheme thickness: 1) / AppleListSection 私有 `_hairlineThickness = 0.5` (apple_list_section.dart:111)
  - 现状: 0.5px hairline 只存在于 AppleListSection 私有常量, 全 App 默认 Divider 仍是 1px 实色 (spec §1.3 问题 #10 的目标)。0 阴影 (shadowCardOf→[]) 已 100% 落地 (app_motion.dart:151-158)。
  - 建议: 要么抽公共 `hairlineDivider(context)` helper + dividerTheme 改 0.5, 要么 spec 标注"仅 AppleListSection 内"。
- [底层] **[R112-AH-103] AppleHealthTile 文件头注释漂移: "默认高度 ~88pt" vs 实值 110** — 难度:S — 工作量:5min
  - 位置: `apple_health_tile.dart:13` (头注释 "默认高度 ~88pt") vs `apple_health_tile.dart:72` (tileHeight = 110, R109 修 unbounded width 时 88→110)
  - 现状: 同一文件两处数字矛盾, 后来者改 UI 会被误导。
- [底层] **[R112-AH-104] Spring 物理模型 4 个 API 中 3 个 0 runtime caller** — 难度:S — 工作量:1h
  - 位置: `spring.dart:133-144` (`Spring.of` — context 参数 `ignore: unused_local_variable` 占位) / `Spring.gentle` / `Spring.bouncy` 0 caller; 唯一 runtime caller = `check_in_button.dart:245` (`Spring.standard.toSimulation`) + 5 case test `test/core/theme/spring_round10_test.dart`
  - 现状: 双轨制最低满足 (R32 P0-08 闭环), 但 145 行模型只有 1 处接线 + `Spring.of(context)` 工厂是完全死代码。quick_mood_carousel 的"选中 spring 放大 1.1"实为 curveSpring cubic-bezier 模拟 (quick_mood_carousel.dart:178-182), 非物理 spring。
  - 建议: 要么 R112 后接 2-3 个新 caller (celebrate overlay / tile hover), 要么删 gentle/bouncy/of 并缩小 spec 承诺。
- [spec] **[AH-17-r112] spec §7.1 test baseline "2103" 仍过期** — 难度:S — 工作量:5min
  - 位置: spec.md:401 ("baseline 2103 cases") vs 实测 `grep -o "testWidgets(\|test(" test/ | wc -l` = 2312 处声明, R112 实测 2377 pass / 4 fail / 1 skip
- [spec] **[R112-AH-105] spec §4.6 SectionHeader 11pt 与 R112 实际 13pt 漂移 (有意, 未写回 spec)** — 难度:S — 工作量:10min
  - 位置: spec.md:287 ("fontSizeCaptionSm (11)") vs `section_header.dart:75-78` (R112 round 8 EM-02b fix: 11→13 统一 AppleListSection, 注释声明 "Apple iOS insetGrouped 实际是 13pt")
  - 现状: 代码有意偏离 spec 且注释完整, 但 spec 未同步 → 下次按 spec 改会回退。
- [P3-keep] **[AH-01/02/03-r112] HealthKit = 0 集成确认 (v1.0 2027-Q1 计划不变)** — 全链路证据见 §4.4/附录, 守门员 enforced, 合规不阻塞。

## 3. 外部链接 / 域名 / 邮箱 / URL 检查 (只扫描 lib/ + fastlane/ + docs/)

| 位置 | 内容 | 状态 |
|---|---|---|
| `docs/design/2026-08-10-apple-health-redesign/spec.md` | 0 外部 URL | N/A |
| `lib/` (本视角扫描范围) | 0 外部 URL | N/A |
| `fastlane/` | 本视角未发现 "Apple Health" 字样 | 无声明 |

(域名/邮箱检查由 04-appstore / 05-googleplay 视角负责, 本视角范围无外部链接。)

## 4. 四类问题 (用户点名)

### 4.1 上架相关

- **HealthKit 假声明风险 = 0, 五处一致** (实跑验证):
  1. 守门员 `python3 scripts/check_apple_health_claim.py` = **OK, exit 0** (本次实跑)
  2. `PrivacyInfo.xcprivacy:36-49` — HealthAndFitness 已删 (R108 P0-020), 注释自带 v1.0 重接清单 (HealthAndFitness + NSHealthShareUsageDescription + health_kit 依赖, 5-15d)
  3. `Runner.entitlements` — 空 dict, 无 com.apple.developer.healthkit
  4. `Info.plist:147-152` — 仅 `healthcare-fitness` App 类别, 无 NSHealthShare/UpdateUsageDescription
  5. `pubspec.yaml` — 0 health_kit / health 依赖
  - lib/ + ios native 全量 grep `HKHealthStore|health_kit|HealthKit|HKSample` = **0 命中** (含 dead import 检查)
  - "Apple Health" 关键词在 lib/ 全部为设计参考注释 ("参照 Apple Health Tab Bar" app_shell.dart:18, "参照 Apple Health State of Mind" mood_entries.dart:104, "Apple Health 风格" R32 集中器注释等), **无一处声称集成**; ARB/fastlane 用户面文案 0 处 "Apple Health" → 无 5.1.3 used-but-not-declared / declared-but-not-used 风险。

### 4.2 架构相关

- 5 token 集中器 + 6 widget 集中器全部落地且集中 (无重复定义); `app_tokens.dart` facade 保持老 caller 兼容。
- **token 覆盖率实测**: `lib/presentation/` 硬编码 `Color(0xFF` = **0 处** (spec §7.1 ≥95% 目标实测达标); 非 token `fontSize:` 仅 9 处、非 token `BorderRadius.circular(` 仅 7 处。
- 集中器使用率: PrimaryButton 33 处调用 / AppleListSection 27 处 / StatCard 4 文件 14 例 / AppleHealthTile 2 文件 9 例 / CheckInButton 1 页 (home)。
- 死代码: `Spring.of` + `Spring.gentle/bouncy` (0 caller)、`tintedMetricSoft` (0 caller)、`curveAppleSheet/Drawer` 已在 R32 删 (注释在案, app_motion.dart:118-122)。
- 4 层纯度不受本视角影响 (theme 全在 `core/theme/`, widget 全在 `presentation/widgets/`, 无跨层泄漏)。

### 4.3 重构建议

- 短期 (R112 hotfix 后): AH-13 spec 数字重算写回 (0.5h) + R112-AH-101/102/103/105 4 处 spec-code 漂移同步 (共 ~1h)。
- 中期 (R113 视觉专项): AH-04 8 feature ALS 化 (1-2d/页, 建议 vent → assessment → mood_list 顺序); AH-16 medication 4 tile 语义化 (2-3h); AH-15 vent FAB 随 vent ALS 化同批。
- 长期 (R110 feature-first / v1.0): SF Symbol (AH-09) + Spring 接线扩 2-3 caller (R112-AH-104) + reduce-transparency 真代理 (AH-08) + HealthKit 真接 (v1.0 2027-Q1, PrivacyInfo 注释自带重接清单)。

### 4.4 半成品 / TODO / 残缺功能

| 项 | 状态 (R112 实测) |
|---|---|
| Spring 物理模型 | 半成品: 1 runtime caller (`check_in_button.dart:245`), gentle/bouncy/of 0; 5 case test 有 |
| SF Symbol | 0 (Material Icons 占位, pubspec 无 fonts) |
| reduce-transparency | 假代理 (`disableAnimationsOf`), spec:69 已文档化 |
| vent FAB | 未落地 (AppBar icon 代替, AH-15) |
| hairlineDivider helper | 未落地 (仅 AppleListSection 私有常量) |
| 8-metric palette | 面板完整 (8 色), 实调 4 色 + sleep/checkIn/trend/contact 0 tile (AH-16) |
| HealthKit | 0 集成 (by-design, 守门员 enforced, v1.0 2027-Q1) |

**R112 新闭环验证 (EM 系列, 实读确认)**: EM-14 (PressFeedback.enabled 禁用态 0 假反馈, press_feedback.dart:70,104) / EM-16 (fgOnWarning 替换 1.9:1 对比度, today_summary_card.dart:97-99 + mood_factor_analysis.dart:113-115) / EM-18 (MoodButton 走 Motion wrapper 收口最后一个 reduce-motion 盲区, quick_mood_carousel.dart:178-182) / EM-21 (mood_label.dart + scale_name_l10n.dart, en locale mood 标签不再显示中文)。R111 的 AH-14 (spec:69 reduce-transparency 描述) 也已同步 ✅。

## 5. 总结 + 给整合者的建议

1. **合规面 10/10**: HealthKit 0 集成五处一致 + 守门员实跑 OK + lib 0 假声明关键词, 上架 5.1.3 无风险, 无需任何动作。
2. **设计系统面 9.5/10**: 5 token 集中器按 spec 落地 (2 处数值偏差 R112-AH-101 除外), presentation 0 硬编码色, 6 widget 集中器全部在库且被真实使用。
3. **页面采纳面 4/11 不变**: AH-04 8 feature 0 ALS = 唯一 P1, 与 R111 逐项比对 0 进展, 是下轮视觉专项的最优先项。
4. **spec 漂移出现新形态**: R111 同步了完成度数字但数字本身无法复现 (home 17 vs 实测 4; medication 55 vs 实测 17) — 建议整合者给 spec.md:318 一个可复现的统计口径 (grep `AppleListSection(` 调用点计数), 否则每轮审计都会继续发现数字打架。
5. **R112 批次对 Apple Health 视角是净收益**: EM-14/16/18/21 四项视觉修复实锤落地 + SectionHeader 13pt 统一, 抵消了 0 页面进展的停滞, 评分维持 7.0 (上轮 7.0)。

**最值得修 3 件事**: ① AH-04 8 feature ALS 化 (P1, 1-2d/页); ② AH-13 + R112-AH-101/102/103/105 共 5 处 spec-code 漂移同步 (合计 ~1.5h); ③ AH-16 medication 4 tile 语义化 (2-3h)。

## 附录: 详细证据

### A. spec §3 token 逐节落地表

| spec § | 项 | 状态 | 证据 (file:line) |
|---|---|---|---|
| 3.1.1 | background F2F2F7 / surface / textPrimary / border / divider | ✅ | app_colors.dart:57-75 |
| 3.1.2 | primary 34C759 / primaryDark 248A3D | ✅ | app_colors.dart:49-52 |
| 3.1.3 | 8 metric palette 全色 | ✅ | app_colors.dart:422-431 |
| 3.1.4 | tintedMetricSoft 0.12 | ⚠️ 定义但 0 caller | app_colors.dart:462-464 |
| 3.1.5 | dark 000000 / 1C1C1E / FFFFFF | ✅ | app_colors.dart:81-85 |
| 3.2.1 | 14 档字号 | ⚠️ headline 24 未改 22 | app_typography.dart:40 |
| 3.2.1 | metric 34/28/22 | ✅ | app_typography.dart:58-60 |
| 3.2.2 | w200/w300 + 3 helper | ✅ | app_typography.dart:84-85,256-277 |
| 3.2.3 | 行高 tight/normal/loose | ⚠️ relaxed 1.6 未改 1.5 | app_typography.dart:72-78 |
| 3.2.4 | letterSpacing -0.5/-0.2/0 | ✅ | app_typography.dart:114,132,149 |
| 3.3.1 | radius 14/16/10/8/4/6/12/22 | ✅ | app_spacing.dart:111-122 |
| 3.3.2 | buttonHeight 50 / small 44 / input 44 / icons | ✅ | app_spacing.dart:134-147 |
| 3.3.3 | spacing 12/16/24/48/32 + pageMargin 20/16 | ✅ | app_spacing.dart:40-46,99-100 |
| 3.3.4 | stagger 30/150 | ✅ | app_spacing.dart:50-54 |
| 3.4.1 | durFast/Normal/Slow/Press | ✅ | app_motion.dart:49-63 |
| 3.4.2 | curveSpring 0.23/1/0.32/1 | ✅ (Sheet/Drawer 已删, 注释在案) | app_motion.dart:116-122 |
| 3.4.3 | Spring 类 + 3 实例 + of() | ⚠️ 1 runtime caller | spring.dart:77-99,133-144; check_in_button.dart:245 |
| 3.4.4 | 0 阴影 card / dialog 0.08 / overlay 0.06 | ✅ | app_motion.dart:151-189 |
| 3.4.4 | hairlineDivider helper | ❌ 未落地 | 0 grep 命中; 仅 apple_list_section.dart:111 私有常量 |
| 3.4.5/6 | MotionScheme 4 档 / Motion 包装 | ✅ | app_motion.dart:225-306 |

### B. spec §4/§5 页面采纳核对表 (R112 实测)

| feature | spec § | 状态 | 实测证据 |
|---|---|---|---|
| Home | §5.1 | ✅ | 7 section 结构 (home_page_state.dart:304-399); 4 文件 4 ALS; stagger 0/30/60ms; CheckInButton 64pt (check_in_button.dart:72); AHT 2x2 (primary_action_row.dart:64-97, medication/mood/vent/assessment); StatCard 2x2 (today_summary_card.dart: 4); QuickMoodCarousel 5×48 (quick_mood_carousel.dart:167-168); HomeHeader 28pt/15pt/透明 (home_header.dart:63-80) |
| Setup | §5.2 | ✅ | SetupProgressBar (setup_page_state.dart:135); 5 ALS (consent 2/welcome 2/medication 1) |
| Medication | §5.3 | ✅ | 17 ALS / 8 文件; 4 AHT 全 'medication' (medication_page.dart:126-148); systemRed FAB (medication_page.dart:88) |
| Trend | §5.4 | ✅ | trend_summary.dart:29 (1 ALS + 4 StatCard); 图表保留自有色板 (0 healthMetricsColorFor) |
| Mood/MoodList | §5.5 | ❌ | 0 ALS; mood_score_chooser.dart:51-80 DimensionRow; 48pt vs spec 72pt (文档化偏离, spec 未同步) |
| Vent | §5.6 | ❌ | 0 ALS (vent_list_page.dart:255 Card); 无 FAB (vent_list_page.dart:50-54 AppBar icon); 录音按钮未改 Pill |
| Assessment | §5.7 | ❌ | assessment_history_list.dart Card; quiz/result 未改 |
| CheckIn | §5.8 | ✅ token 自动 | 按 spec 设计 |
| Contact/Settings/DailyTracking | §5.8 | ⚠️ | 0 ALS (contacts_list_widget Card; settings_page 0 ALS) |
| CrisisHotline | (AH-04 清单) | ❌ | crisis_hotline_page.dart ListView |

**采纳度: 4/11 重设 (home/setup/medication/trend) + 3/11 token 自动, 8 feature 0 ALS — 与 R111 完全一致。**

### C. 关键 grep 计数 (R112 实测)

- `AppleListSection(` runtime 调用: 全 lib 27 处 = medication 17 + setup 5 + home 4 + trend 1
- `AppleHealthTile(` runtime 调用: 9 处 = medication_page 4 + primary_action_row 4 (+1 定义)
- `StatCard(` runtime: 14 例 / 4 文件 (today_summary 4 / trend_summary 4 / medication_detail 2 / refill_manage 4)
- `healthMetricsColorFor(` runtime: quick_mood_carousel:105, secondary_action_row:52,66, medication_page:88, apple_health_tile:86
- `Spring.` runtime: check_in_button.dart:245 唯一; `Spring.of/gentle/bouncy` = 0
- `Color(0xFF` in lib/presentation: **0**; 非 token fontSize 9 处; 非 token BorderRadius 7 处
- `test(` + `testWidgets(` 声明数: 2312 (spec §7.1 写 "2103" 过期)
- HKHealthStore/health_kit/HealthKit 在 lib+ios: **0**

<!-- subagent: apple-health 完成时间: 2026-08-13T00:00:00Z -->
