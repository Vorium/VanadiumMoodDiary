# 06 · Apple Design Lens 审计报告 (2026-08-16)

**审计对象**: v1.1.0+149 working tree (f9f4e2b5) — apple-design skill: HIG 基础 / 平台规范 / 材料与深度 / 排版 / 动效 / 黑暗模式
**方法**: 只读遍历 lib/core/theme 全部 8 文件 + presentation/widgets 集中器 + 13 页面目录 ALS 覆盖 + 动效接线 grep
**总分: 7.5 / 10**

## 1. HIG 基础

### 1.1 反馈 (每交互即时响应) — ✅ 良好
- PressFeedback scale 0.97 + 100ms (durPress R4 160→100) + Haptics.light: `lib/presentation/widgets/press_feedback.dart:74-98`
- 5 类 Haptics 语义 (tap/success/light/warning/error): `lib/presentation/widgets/feedback.dart:18-33`
- 禁用态假反馈已修 (enabled=false 原样渲染): `press_feedback.dart:102-104`, PrimaryButton 接线 `primary_button.dart:194`
- 打卡勾选态 isChecked + streak 数字 tween: `check_in_button.dart:299-324`
- 录音态指示 (计时器 + tabularFigures): `mood/widgets/mood_audio_recorder_widget.dart:608`
- 庆祝: CelebrationBounce scale 0→1.2→1.0 curveBackOut: `animations/celebration_bounce.dart:46-58`

### 1.2 空间一致性 — ⚠️ 发现 (P2)
**F-01 (架构/P2/低)**: 双重水平边距 — PageScaffold 已包 `pageMarginH=20` (`page_scaffold.dart:97-99`), AppleListSection 默认再包 20 (`apple_list_section.dart:121-122`) → 实际 40px。home/medication 传 `margin: EdgeInsets.zero` 但 trend 显式再传 20 (`trend_summary.dart:30`) — 同 app 两套 inset。建议: ALS 默认 margin 改 zero, 由 PageScaffold 唯一负责页边距。

**F-02 (架构/P2/中)**: tab 切换过渡与 iOS 惯例冲突 — ShellRoute 4 tab 走 `fadePage` 过渡 (`app_route_main.dart:51-65`), iOS tab bar 切换是**无过渡**内容直换 + 各 tab 状态保活 (StatefulShellRoute)。当前切 tab 有 250ms fade + 每次重建, 主页靠 `homeEntryPlayedProvider` 打补丁 (R113 Wave 7), 属"治标"。R114 已列入 StatefulShellRoute 分支保活。

### 1.3 克制 (每屏一个焦点) — ⚠️ 设计张力 (P2)
**F-03 (架构/P2/中)**: 首页焦点分散 — 双 hero 卡 (MoodHeroCard + VentHeroCard 同权重 `home_page_state.dart:286-291`) + 48pt compact 打卡按钮 (:300) + 4 彩色快捷 tile (`primary_action_row.dart`) + 2x2 今日指标 + FAB 工具栏 (`home_page_state.dart:237`) + 鼓励文案。6 个彩色 section + FAB = 无单一焦点; Apple Health 首页本身是长列表所以结构可辩护, 但双 hero 卡同权重 + FAB 工具栏是"每屏一个焦点"的破坏点。建议: 情绪(记录)与树洞(倾诉)二者定一主一辅 (视觉降级其一), FAB 工具栏收进设置或快捷区。

## 2. iOS 平台规范

### 2.1 导航返回 — ❌ P2 残留确认
**F-04 (底层/P2/低)**: 宽屏顶层路由无 AppBar 无返回按钮 — `page_scaffold.dart:88` `appBar: (title != null && !isWide) ? translucentBar : null`。>= 840pt (iPad/桌面) 下 push 进去的 `/tips/:id` `/worry/:id` 等完全无返回入口, 只能键盘/browser back。R104 的 canPop 自动返回按钮 (`page_scaffold.dart:48-56`) 在宽屏被短路。建议: 宽屏时在内容区顶部加内联返回按钮 (iOS 宽屏 split view 惯例是 toolbar/left rail, 至少要有可点返回)。

### 2.2 手势 (swipe-back) — ❌ P1 平台硬伤
**F-05 (架构/P1/中)**: 3 个 transition helper 全走 `CustomTransitionPage` (`app_routes.dart:49-109`) — **无 iOS interactive pop 手势**。iOS 惯例 = 右滑返回 + 上一页 33% 视差跟随; 本项目 slideRightPage 只滑 10% (`Offset(0.1, 0)` `app_routes.dart:75`) 且不可打断。修法: pageBuilder 在 iOS 平台用 `CupertinoPage`/`CupertinoPageTransitionsBuilder` (go_router 支持 Page), 或接 `PredictiveBack`。全 app 推栈页面都受影响, 这是与 Apple 平台惯例差距最大的单项。

### 2.3 insetGrouped 列表规范 — ✅ / ⚠️
- ALS 圆角 16 surface + hairline 0.5 divider: `apple_list_section.dart:117,222-227` ✅
- **F-06 (底层/P3/低)**: hairline 未全局落地 — 全局 `DividerThemeData thickness: 1` (`app_theme.dart:42-46`) + AppShell `VerticalDivider(thickness: 1)` (`app_shell.dart:155-159`) + Card 边框 1px。0.5 hairline 仅 ALS 内部。10 处 pages 裸 `Divider(` 走 1px。视觉"分隔线比内容重"。建议: DividerTheme 改 0.5, Card side 改 outlineVariant 或删。

### 2.4 ALL CAPS section header 11pt vs 13pt — ✅ 判定: 13pt 正确
- 现 13pt w500 + letterSpacing 0.6 (`section_header.dart:85-91`, `apple_list_section.dart:105-108`)。iOS 13+ insetGrouped section header 标准即 **13pt uppercase footnote** (11pt 是 iOS 12 旧标准)。当前 13pt 正确, R112 EM-02b 的 11→13 修正是对的。SectionHeader 与 ALS title 已统一 (R111 EM-02b)。

### 2.5 状态栏/安全区 — ✅
- PageScaffold body 包 SafeArea (`page_scaffold.dart:89`); AppBar translucent flexibleSpace 覆盖状态栏区 (surfaceTintColor transparent + elevation 0 `:75-84`)。全 lib 无 AnnotatedRegion/SystemUiOverlayStyle 硬编码 → 走 MaterialApp 默认亮度映射, 无脏代码。

### 2.6 Dynamic Type — ⚠️ P2 a11y
**F-07 (底层/P2/中)**: textScaler 全 lib 0 处显式处理; 关键风险在**固定尺寸容器**: `apple_health_tile.dart:71-81` tileHeight 110 / tileWidth 140 硬编码 — textScaler 2.0 时 28pt 数字放大到 56pt, 固定 110pt 高容器内 label+value+ellipsis 挤压。`buttonHeight 50/44` 固定 + 17pt 文字在 textScaler 1.6+ 溢出。Apple HIG 支持 Dynamic Type 到 310%。建议: tile 改 minHeight + 内容自适应, 按钮高度随 textScaler clamp, 加 1-2 个 textScaler=2.0 的 widget test。

## 3. 材料与深度

### 3.1 0 阴影 — ✅ 已落地
- `shadowCardOf/shadowCardDarkOf → []` (`app_motion.dart:151-159`), CardTheme elevation 0 (`app_theme.dart:216`), AppBar elevation/scrolledUnderElevation 0 (`app_theme.dart:101-102`)。dialog 极轻 blur 24 @ 0.08 (`app_motion.dart:166-175`)。✅ 唯一破例: CelebrationBounce 用 shadowOverlayOf (合理, 浮层语义)。

### 3.2 分隔线层级 — ⚠️ 同 F-06
- 层次用 container 色 (ALS surface) + hairline 表达, 方向正确; 1px vs 0.5 混用是残余。

### 3.3 半透明材料 — ⚠️ 现状核实
**F-08 (底层/P3/低)**: PageScaffold "translucent" AppBar 实际是 solid alpha 0.97/0.92 假透明 (`page_scaffold.dart:78-84`), R112 因 BackdropFilter 每帧重采样掉帧从 blur 降级 — 决策合理 (性能优先), 但当前实现既非 blur 也非真 solid: 滚动内容 1-3% 透出。iOS reduce-transparency 开启时 Apple 要求纯 solid; Flutter 读不到该开关 (`page_scaffold.dart:57-60` 注释自认)。现状 = "够用但非 iOS 材料"。v1.0 平台层 blur 方案待评估, 接受现状, 记录即可。

### 3.4 reduce-transparency 假代理 — ✅
- 现有代理是 reduce-**motion** 全覆盖 (见 §5.3); reduce-transparency 无代理, 但 R112 后无 blur 可减 → 实际影响为零。诚实记录: 注释已同步 (spec 决策 #7), 非虚假声明。

## 4. 排版

### 4.1 SF Pro 特质模拟 — ✅
- 14 档字号对齐 iOS (17 body / 13 footnote / 11 caption2): `app_typography.dart:39-61` ✅
- letterSpacing 阶梯: ≥22pt -0.5 (SF Pro Display 收紧), 17-20pt -0.2: `app_typography.dart:90-93,111-134` ✅
- ultralight w200 大数字 3 档 (34/28/22) 走 textPrimary: `app_typography.dart:257-278` ✅

### 4.2 optical sizing — ⚠️ P3
- Flutter 默认 Roboto/PingFang 无 optical sizing 概念; -0.5 tracking 是对 SF Pro Display 的近似 (可接受)。真 SF Pro 需字体资产 — 已列为 R114 长线 (SF Symbol 同批)。记录不追。

### 4.3 tabular figures — ❌ P2
**F-09 (底层/P2/低)**: StatCard 大数字 + TweenNumber 数字递增**无 `fontFeatures: tabularFigures`** (`stat_card.dart:94-106`, `animations/tween_number.dart`) — 数字变化时字符宽度跳动 (比例数字 1 vs 8 宽度不同), Apple Health 大数字 (SF 等宽数字特性) 不抖。全 lib 仅 2 处 audio 计时器用了 (`mood_audio_recorder_widget.dart:608`, `vent_audio_section.dart:121`)。建议: textStyleMetric*/TweenNumber builder 统一加 tabularFigures。

### 4.4 13pt caption 一致性 — ✅
- textStyleCaption 13pt w400 textSecondary 集中 (`app_typography.dart:180-186`), SectionHeader/ALS title 13pt 统一。✅

## 5. 动效

### 5.1 iOS 物理感 (spring) — ⚠️
- Spring.standard 唯一真 caller = CheckInButton 进场 (`check_in_button.dart:268`), R113 已补 reduce-motion (`:273-282`)。✅
**F-10 (架构/P2/低)**: `Spring.gentle` / `Spring.bouncy` 0 caller (`spring.dart:71-84`), R112-03 删 enum 时作为"spec §3.4.3 完整模型面"保留 — 两年无人接线。判定: **建议删** (emil "good defaults matter more than options" — 死模型面不如接真 caller; 若保留必须在 spec 写死"何时用 bouncy"的触发条件, 否则永远没人用)。同时 `AppMotion.curveSpring` (cubic 0.23,1,0.32,1) 需验证 caller (grep 显示仅注释引用 → 同批死代码候选)。

### 5.2 动量/打断性 — ⚠️
- Dismissible swipe delete 有 `swipe_delete_background.dart` 背景 ✅, 但默认 release 无 iOS 弹回物理 (Flutter Dismissible 用线性 resize, 可换 flutter_slidable 或自绘 spring)。
- 列表滚动阻尼 = 平台默认 BouncingScrollPhysics (iOS) / Clamping (Android), 无自定义 — ✅ 正确。
- **F-05 已覆盖**: 页面级 swipe-back 0 (最大动量缺口)。

### 5.3 减动效 (Reduce Motion) — ✅ 覆盖好
- 50 处 `Motion.duration/curve/prefersReduced` 接线 (13 文件): 路由过渡 3 helper (`app_routes.dart:53-95`), PageTransitionSwitcher (`page_transition_switcher.dart:54-57`), TweenNumber (`tween_number.dart:74-77`), PressFeedback (`press_feedback.dart:107`), loading_skeleton (`loading_skeleton.dart:219-230`)。
- didChangeDependencies 直跳终态: FadeIn (`fade_in.dart:74-84`), SlideUp (`slide_up.dart:72-76`), CelebrationBounce (`celebration_bounce.dart:80-86`), CheckInButton _EntrySpring (R113 BUG6 修复 `check_in_button.dart:273-282`)。
- 缺口: `Motion.curve` 在 PressFeedback 未用 (duration=0 时 curve 无效, 实质无影响 — P3 记录不追)。

## 6. 黑暗模式

### 6.1 全 token 适配 — ✅
- 静态 dark 色板 (`app_colors.dart:84-111`): backgroundDark #000000 / surfaceDark #1C1C1E (iOS secondarySystemGroupedBackground) ✅
- dynamic getter 桥接 M3 ColorScheme (7 getter + tinted/fg 系): `app_colors.dart:140-205` ✅
- ALS dark 显式走静态 surfaceDark 绕开 M3 紫调 surface (`apple_list_section.dart:123-131`) ✅ — 这是正确决策, M3 fromSeed dark surface 偏紫。

### 6.2 深色下对比度 — ✅ (R112 已修)
- fgOnSuccess #2E7D32 (5.1:1) / fgError #C62828 / fgOnWarning #E65100 / fgWarningStrong #BF360C 作文字色全达标 (`app_colors.dart:310-332`)。✅
- 残留: `warningColor()` getter 恒返亮橙 const (`app_colors.dart:152`) — dark 底上作**文字**色会崩, 但当前 callers 均为背景/图标语义; 记录为 P3 地雷。

### 6.3 材质层级 — ⚠️ P3
**F-11 (底层/P3/低)**: NavigationBar (窄屏 tab) 无 theme → M3 默认 surfaceContainer (dark #211F26 紫灰), 与 iOS #1C1C1E 家族不一致 (`app_theme.dart` 无 navigationBarTheme 段, `app_shell.dart:90-101`)。AppShell NavigationRail 同走 cs.surface (M3 派生)。建议: 加 `navigationBarTheme: backgroundColor = isDark ? surfaceDark : surface`。

## 7. ALS 化覆盖表 (13 页面目录 + 单文件页)

| 页面 | 状态 | 证据 |
|---|---|---|
| home | ✅ | hero×2 + 今日指标 + 快捷操作 (home_page_state.dart:286-344) |
| setup | ✅ | consent 5 / medication 4 / welcome 6 (setup_step_*.dart) |
| medication | ✅ | 7 文件 (medication_page 7, refill 8, calendar 4...) |
| settings | ✅ | settings_page + 14 widgets (reminders_group/profile_group/cbt_section...) |
| assessment | ✅ | 5 文件 (widgets 5, chart_card, history_list...) |
| daily_tracking | ✅ | daily_tracking_page 2 |
| trend | ⚠️ | 仅 trend_summary 4; trend_page/calendar/charts 0 |
| mood_list | ✅ | detail 10 / review 6 / list 2 |
| vent | ⚠️ | 仅 vent_list 5; compose / detail 0 |
| tips | ✅ | list 3 / detail 3 |
| worry | ✅ | timeline 2 / archive 2 |
| crisis_hotline | ✅ | 4 |
| **mood (记录主流程)** | ❌ | 0 — 且走 Material Dialog (`mood_recorder_page.dart:78,307`) 非 iOS sheet/page |

**结论**: R113 后 12/13 目录覆盖, 唯一 ❌ = mood 记录主流程 (AGENTS 已知 P1 残留实锤) + vent 子页 / trend 图表页 ⚠️。

## 8. 发现汇总 (11 项)

| # | 类型 | 严重性 | 难度 | 证据 | 一句话 |
|---|---|---|---|---|---|
| F-05 | 架构 | **P1** | 中 | app_routes.dart:49-109 | CustomTransitionPage 无 iOS swipe-back, 且 slide 仅 10% 无动量 |
| F-mood | 架构 | **P1** | 中 | mood_recorder_page.dart:78,307 | mood 主流程 0 ALS + Material Dialog 替代 iOS sheet (跨期 P1) |
| F-04 | 底层 | P2 | 低 | page_scaffold.dart:88 | 宽屏顶层路由 AppBar 整体消失 → 无返回按钮 |
| F-01 | 架构 | P2 | 低 | page_scaffold.dart:97 + apple_list_section.dart:121 + trend_summary.dart:30 | PageScaffold 20 + ALS 默认 20 = 40px 双重 inset, 各页不统一 |
| F-02 | 架构 | P2 | 中 | app_route_main.dart:51-65 + app_shell.dart:92 | tab 切换 fade 过渡 + 无 StatefulShellRoute 状态保活 (非 iOS) |
| F-09 | 底层 | P2 | 低 | stat_card.dart:94-106 | StatCard/TweenNumber 大数字无 tabularFigures, 数字递增抖动 |
| F-07 | 底层 | P2 | 中 | apple_health_tile.dart:71-81 | 固定 tile 110×140 + textScaler 0 处理 → Dynamic Type 挤压 |
| F-10 | 架构 | P2 | 低 | spring.dart:71-84 | gentle/bouncy spring 2 年 0 caller, 建议删或写死触发条件 |
| F-03 | 架构 | P2 | 中 | home_page_state.dart:286-344 | 双 hero 同权重 + FAB 工具栏, 首页焦点分散 (克制) |
| F-06 | 底层 | P3 | 低 | app_theme.dart:42-46 + app_shell.dart:155 | 全局 divider 1px vs ALS hairline 0.5, 层级表达不一致 |
| F-11 | 底层 | P3 | 低 | app_theme.dart (无 navigationBarTheme) | NavigationBar dark 走 M3 紫调 surfaceContainer ≠ #1C1C1E |

## 9. 评分与建议

**7.5/10** — token/集中器纪律、字号阶梯、0 阴影、reduce-motion 覆盖、dark 对比度修正是同类项目的上乘水准 (Apple Health 视觉层 8.5+); 扣分集中在**平台交互惯例**: swipe-back 缺失 (P1)、tab 语义、Dialog 替代 sheet、双重 inset、Dynamic Type 挤压。

**优先级建议 (R114)**:
1. F-05 swipe-back (P1, 0.5-1d) — iOS 平台惯例最大缺口
2. F-mood 记录流 sheet 化 + ALS (P1, 2-3d, AGENTS 已列)
3. F-04 宽屏返回按钮 (0.5h) + F-01 双重 inset 统一 (0.5h) + F-09 tabularFigures (0.5h) — 3 个低价高回报
4. F-10 spring 死代码删/接线 (0.5h) + F-06 hairline 全局化 (0.5h) + F-11 NavigationBar 主题 (0.25h)
5. F-02 StatefulShellRoute (1-2d, 长线) + F-07 Dynamic Type (1d) + F-03 首页焦点评审 (设计 0.5d)
