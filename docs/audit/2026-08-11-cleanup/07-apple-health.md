# 视角 7 报告 · Apple Health 视觉语言

## 元信息
- 跑时间: 2026-08-11
- baseline: master HEAD `01d8f4a` (v0.31.0)
- 关注: Apple Health (iOS 17/18) 视觉语言细节 + v0.31.0 23 commit 落地质量

## 5 维度评估

### 1. 外部链接检查
- [OK] 无任何外部链接 / 域名 / URL / 邮箱需审计
- [ISSUE] `lib/` 全代码库 grep "Apple Health" = **171 处** 跨 **57 个文件**, v0.31.0 diff 新增 **134 处** "Apple Health" 字面提及。R108 P0-004 (Apple 5.1.3 used-but-not-declared 抽审) 通过 lock-in test 锁了 fastlane description 关键词, **但 v0.31.0 重新把 "Apple Health" 写进 lib 代码注释 + 文档**。例: `app_typography.dart:1` `spring.dart:1` `apple_health_tile.dart` `apple_list_section.dart` `check_in_button.dart` `primary_button.dart` `medication_page.dart` 等 50+ 文件都新加 "Apple Health" 注释。**R108 修复被部分反转**。
- [OK] 无 SF Symbol 同名 icon 选错 (Material Icons 是 closest equivalent, Flutter 平台无 SF Symbol)

### 2. 上架 / 架构 / 重构 / 半成品
- [ISSUE] **P0 spec §4.9 未落地**: `lib/presentation/widgets/page_scaffold.dart` **未改**, AppBar 仍是默认 M3 不透明 AppBar, 缺 BackdropFilter blur(20) + white @ alpha 0.6 + hairline divider (滚动时显示) + reduce-transparency 适配。spec §4.9 决策 #7 ✅ "引入" **未实做**。修复: 1-2h
- [ISSUE] **P0 spec §3.4.3 Spring 物理模型 = 0 使用方**: `lib/core/theme/spring.dart` 定义 `Spring.standard/gentle/bouncy` + `SpringSimulation` (145 行新文件), 但全 lib 库 grep `Spring\.(standard|gentle|bouncy|of)` / `animateWith(` / `SpringSimulation` **0 处实际使用**。所有现有 spring 动画 (`check_in_button.dart` 完成态) 都走 `curveSpring` (Cubic bezier), 没用 `SpringSimulation`。Spring 类 100% 死代码。修复: 1-2h (集成到 page transition + modal 进出)
- [ISSUE] **P1 curveAppleSheet / curveAppleDrawer 死代码**: `app_motion.dart:119,123` 定义, `app_tokens.dart:261,262` facade 转发, 但全 lib 库 grep `AppMotion.curveAppleSheet|AppTokens.curveAppleSheet` **0 处使用**。只有 `curveSpring` 被用 (1 处 in check_in_button.dart)。修复: 集成到 sheet / drawer, 或删
- [ISSUE] **P1 spec §5.1-5.7 "11 feature 全部 Apple Health 化" 部分未做**:
  - **未改** feature: `lib/presentation/pages/mood_list/` (mood_list_page / mood_detail_page / mood_trend_page + widgets/ 0 改)
  - **未改** feature: `lib/presentation/pages/daily_tracking/` (daily_tracking_page / tracking_customize_page / treatment_page 0 改)
  - **未改** feature: `lib/presentation/pages/vent/` (vent_compose_page / vent_detail_page / vent_list_page 0 改, 只 `widgets/vent_save_bar.dart` 1 文件)
  - **未改** feature: `crisis_hotline_page.dart` 0 改
  - **部分改** feature: `medication` 主页面 ✅ / `trend` 只 2 文件 / `assessment` 只 3 widget / `contact` 只 1 widget / `mood` 只 1 widget (cbt_prompt_sheet)
  - 实际深度改写 feature: **home + setup + medication + trend (部分) + check_in (CheckInButton widget)** = 4-5 个完整 + 3-4 个半残
- [OK] 5 token 文件按 spec 100% 落地 (app_colors / app_typography / app_spacing / app_motion / app_tokens facade + spring.dart)
- [OK] 5 widget (PrimaryButton / CheckInButton / StatCard / AppleHealthTile / AppleListSection) 全部按 spec 落地, 17 个 test 文件 + 70 个 test case 配套
- [OK] `pubspec.yaml` 0.30.0+85 → 0.31.0+107 同步; `CHANGELOG.md` 0.31.0 entry 写好

### 3. 顶层架构审视
**整体评价**: v0.31.0 是表层 UI token + 5 widget 改写, 业务层 (domain/data) 0 改动。落地质量上, **home / setup / medication** 三个核心页面已经"一眼 Apple Health" (巨型 pill CheckInButton + 4 StatCard 2x2 网格 + 8 metric 彩色 tile + iOS 群组列表 + ALL CAPS 章节), 但 spec 描述的 5 个关键决策 (translucent AppBar / 真实 Spring / 全 11 feature 覆盖 / dark mode 同步 / 减阴影) **只完整做了 2-3 个** (减阴影 ✅ / 8 metric 调色板 ✅ / 大数字 ultralight ✅), 真实跑起来跟 iOS 18 Apple Health 仍差 30-40% 视觉一致度。

**高内聚低耦合度**: 8/10 (5 widget 集中器, 5 token 文件, 跟现有 lib 0 循环 import)

**重构建议** (R109+):
1. **PageScaffold translucent AppBar 落地** (P0, 2h) - 补 spec §4.9
2. **Spring.standard 实际接到 page transition** (P0, 1-2h) - 补 spec §3.4.3
3. **mood_list + daily_tracking + vent 主页面 3 个 feature 完整改写** (P1, 1-2d)
4. **"Apple Health" 关键词 lock-in test 扩展到 lib/**/*.dart + design spec** (P0, 1h) - 修 R108 P0-004 反转
5. **删除 curveAppleSheet / curveAppleDrawer 死代码** (P2, 30min)

### 4. 底层逐行排查
- **已遍历**: 9 个新 / 改 widget (PrimaryButton/CheckInButton/StatCard/AppleHealthTile/AppleListSection/SectionHeader/spring.dart + 改 4 + 新增 1) + 5 token 文件 + 4 page (home/setup/medication/trend) + 6 widget 文件
- **找到 bug**:
  1. **[底层] CheckInButton fontWeight=w700 (hardcode)** - 跟 Apple Health "Mindful Minutes" 巨型 CTA 风格 (semibold w600) 略偏粗。spec §4.2 没明说字重。`check_in_button.dart:184` `fontWeight: FontWeight.w700`。**难度: S, 优先级: P3** (1 行改)
  2. **[底层] QuickMoodCarousel 圆形 button 48pt** - spec §5.5 写 72pt, 实际 48pt。**实现 comment 说 "Apple Health 风格 5 档可点区域 48pt"** (更接近 Apple Health 实际 48-60pt), 但跟 spec 不一致。**难度: S, 优先级: P2** (1 行常量改)
  3. **[底层] spec §4.5 SectionHeader ALL CAPS 13pt + letterSpacing 0.6 对中文 case-less 无效** - iOS HIG ALL CAPS 仅对 Latin 字符有意义, 中文不区分大小写, 章节头在中文 locale 下视觉只是 13pt w500 + letterSpacing 0.6, 跟英文 locale 略不同。Apple Health 中文 (简体) 也是 13pt 灰色但无 ALL CAPS (case-less)。**难度: S, 优先级: P2** (locale 适配)
  4. **[底层] AppleHealthTile 8 metric icon 用 Material Icons 而非 SF Symbol** - 8 icon (medication/mood/mic/assignment/check_circle/show_chart/contact_phone/bedtime) 都是 Material Icons, 跟 iOS SF Symbol (pills.fill / face.smiling / mic.fill / checkmark.circle.fill / chart.line.uptrend.xyaxis / phone.fill / bedtime.fill) 形状略不同。Flutter 平台无内置 SF Symbol, 只能 closest Material equivalent, 但视觉差 5-10%。**难度: L (SF Symbol 字体集成 1-2d), 优先级: P3** (Polish, 非阻塞)
  5. **[底层] spacing 偏差**: 多处 `SizedBox(height: 12/16)` 硬编码, 没走 `AppTokens.spacingSm/Md` 集中器 (e.g. `quick_mood_carousel.dart` line 99, `today_summary_card.dart` line 91, 102, 114, `primary_action_row.dart` line 83, 93)。**难度: S, 优先级: P2** (批量 grep + 改 token)
  6. **[底层] apple_list_section Round 11a revert**: 注释说 "不用 [SectionHeader] 因为它是 11pt (per spec §4.6), 这里要 13pt (per spec §4.5)" - **这意味着 AppleListSection.title 跟 SectionHeader 是有意分开的两个不同字号 widget**, 不复用。 复用率低, 概念略冗余。**难度: L (设计决策, 1d), 优先级: P3**
  7. **[底层] lock-in test 阈值放宽**: `app_tokens_lock_in_round95_test.dart` "全局 TextStyle 数字 ≤ 220 (R95 baseline)" 改成 "≤ 300 (v0.31 Apple Health baseline)" - 上限放宽 36%, 失去回归保护能力。**难度: S, 优先级: P2** (1 行改回 250)
  8. **[底层] CheckInButton 数字 tween 范围**: `_TweenNumber._tryParseInt` 把 "1.2kg" 走 static 不动, 但 "0" / "10" 走 tween, "0" → "0" tween 0 秒无效果。边界 case OK。**难度: 无需修**
  9. **[底层] Spring.standard 没接到 Navigation** - 路由 push/pop 仍用 `app_router.dart` 的 fade/slide-right/slide-up (v0.17 R2 加), 没用 `Spring.standard.toSimulation()`。**难度: S, 优先级: P1** (0.5h 集成)

- **优化点**:
  - spec §4.7 HomeHeader greeting 28pt ✅ 改完, 但 R101 "header default title" ARB 文案要随 R109 dark mode 调
  - spec §3.1.4 `tintedMetricSoft` 实现 OK (alpha 0.12 light / 0.18 dark) ✅
  - 8 metric color 跟 spec §3.1.3 1:1 一致 (systemRed / systemPink / systemPurple / systemIndigo / systemGreen / systemBlue / systemOrange / systemTeal) ✅

### 5. dev doc 更新
- **AGENTS.md**: 5 维度 0 章节 + R108 §六 R109+ 路线图未更新 v0.31.0 已落地部分 (Phase 1 收尾)。**未改**。R110 时再统一更新
- **CHANGELOG.md**: `[0.31.0] - 2026-08-10 (Apple Health 风格重设计 · 5 phase / 13 task / 22 commit)` 已写 ✅, 84 行新条目, 详细列 5 token + 6 widget + 4 页面 + 18 test 文件
- **设计 spec** (`docs/design/2026-08-10-apple-health-redesign/spec.md`): 22KB 详细, 跟实现高度一致 (1-2 偏差: 48pt vs 72pt, PageScaffold 未改)

## 总结

**v0.31.0 是 token + 关键 widget 层次的 Apple Health 化, 不是 100% 重设计**。home/setup/medication 三个核心页面 + 5 个集中 widget 落地质量高, 跟 iOS 18 Apple Health 视觉差 20-30%。但 spec 描述的 5 大决策 (translucent AppBar / 真实 Spring / 全 11 feature / 全 SF Symbol / 11pt ALL CAPS 章节头) 只完整做了 2-3 个。最严重的两个 P0 gap: (1) **PageScaffold AppBar 未实现 translucent** (spec §4.9 决策 #7 跳过), (2) **Spring.standard 0 使用方** (spec §3.4.3 双轨制空跑一半), 加 **R108 P0-004 "Apple Health" 字面 lock-in 被 v0.31.0 重新反转 (134 处新增)**。11 feature 真正深度改写只 4-5 个 (home/setup/medication/check_in), mood_list/daily_tracking/vent 主页面 0 改, 跟 "全 11 feature 重设计" 描述不符。

**总评**: 7.0/10 (R107 cleanup 8.0 → 倒退 1.0, 主要扣分 = 3 个 P0 gap + 1 个 11 feature 描述虚标)
