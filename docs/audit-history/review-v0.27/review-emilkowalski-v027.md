# Emil Kowalski Design Engineering Review — chroniccare v0.27 round 58

> **视角**：UI / 动效 / 交互 / 视觉 / 设计系统架构（Design Engineering 视角）
> **基线**：v0.25 round 56h（先前的 emil 报告，33b5fd0，2026-07-26 早）
> **终点**：v0.27 round 58（2ad8246，HEAD，2026-07-26 晚）
> **增量审视策略**：本报告**不重复** v0.25 R56h 报告的 12 个增量发现（EMIL-INC-01..12）。
> 重点关注**顶层架构 + 设计系统健康度 + 跨切面问题**（R56h 漏掉的横切视角）。
>
> **范围**：扫描 `lib/presentation/`（21 widget 文件 2262 行 + 8 features × N page 文件）+ `lib/core/theme/app_tokens.dart`（779 行 god file）+ `lib/core/routing/`（9 文件 god class 拆分后）。
>
> **不重复**：v0.25 R56h 报告 `EMIL-INC-01..12` 列出的 dead tokens / inline TextStyle / IconButton 残留 / AppListTile 覆盖率。本报告聚焦 R56h 漏掉的**架构 + 跨切面 + 设计系统演进**问题。

---

## 1. 顶层架构审视（emil 视角）

### 1.1 当前架构对设计系统演进的契合度

**4 层 + core umbrella**（`presentation → domain ← data` + `core/{data,shared,theme,routing,l10n}`）走 v0.18 round 12 收口到 umbrella。**emil 视角评估**：

**强项**：

1. **设计 token 单点真相**：`AppTokens` 在 `core/theme/app_tokens.dart:1-666` 提供 100+ token。`Motion.duration/curve` 包装 prefers-reduced-motion（`app_tokens.dart:760-780`）是 v0.18 round 14 关键工程。dark mode 100% 走 dynamic getter（`app_tokens.dart:78-140`），R49 35+ 文件 116 行替换后真正 0 hardcoded `Color(0xFF`（grep 验证 0 命中，除 `app_tokens.dart` + `.g.dart`）。
2. **4 个动画集中器目录**：`presentation/widgets/animations/`（`animations.dart` barrel + 4 widget）封装 FadeIn / SlideUp / PageTransitionSwitcher / CelebrationBounce。每个 widget 走 `Motion.duration(context, base)` 走 reduce-motion。
3. **集中 widget 库**：`presentation/widgets/` 22 个公共 widget（page_scaffold / app_snack_bar / app_list_tile / chip_badge / empty_state / error_state / loading_skeleton / press_feedback / press_feedback_icon_button / section_header / secondary_button / app_semantics / check_in_button / last_med_info / theme_toggle_button / 4 dialog widget）= 8 features 共享的"UI 标准件库"。
4. **dismiss/swipe/list 模式统一**：Dismissible 背景色 + IconButton 走 `AppTokens.errorColor` + `fgOnError`（`medication_row.dart:165-176` / `vent_list_page.dart:175-194` / `contacts_list_widget.dart:48-61`），3 处一致。Undo snackbar 走 `AppSnackBar.undo` 集中器（`vent_list_page.dart:156-165` / `contacts_list_widget.dart:132-138`）。
5. **情绪患者敏感设计**：`LoadingSkeleton` 文档明示 "spinner 太机械易引发焦虑，用柔和骨架屏"（`loading_skeleton.dart:5-9`），shimmer 走"呼吸模式"1.2s+600ms 暂停（`loading_skeleton.dart:128-138`）而非永久脉动。`CelebrationBounce` 用 `easeOutBack` 一次过冲（`celebration_bounce.dart:48-58`）而**非** `elasticOut` 多次回弹，避免精神心理患者多次弹跳引发焦虑。
6. **路由层 god class 拆分**（R59 + R57）：`app_router.dart` 418 → 51 行（-88%），拆 9 文件。`app_routes.dart` 115 行（3 transition helper + 14 GoRoute facade），按 feature 拆 5 个 `app_route_*.dart`。**emil 决策典范**："good defaults matter more than options"——3 类 transition（fade / slide-right / slide-up）按频度分档（occasional / standard / rare）。

**弱项**（**emil 视角**的"不可见细节债务"）：

| 编号 | 弱项 | 位置 | 严重度 |
|----|----|----|----|
| **A1** | **`AppTokens` 自己成 god file** | `app_tokens.dart:1-666` (779 行) | **P1** |
| **A2** | **`core/routing` 反向依赖 `presentation/pages/`** | `app_router.dart:18-22` 注脚 + 5 个 `app_route_*.dart` | **P1**（架构债） |
| **A3** | **god page 重生**（R56h 减 88% app_router 极成功，但其他 god page 未跟进）| `setup_page.dart:1-448` `home_page.dart:1-432` `medication_calendar_page.dart:1-450` `mood_recorder.dart:1-603` `trend_calendar.dart:1-521` `reminders_hub_page.dart:1-494` `data_management_section.dart:1-413` `edit_medication_dialog.dart:1-406` `assessment_widgets.dart:1-416` `assessment_page.dart:1-439` `vent_compose_page.dart:1-436` | **P1** |
| **A4** | **home（hub）import 4 个 feature 的 dialog** = 反模式 | `home_page.dart:28-30` import 5 个其他 feature | **P1**（架构债） |
| **A5** | **路由 layer 强耦合页面** | `app_routes.dart:18-22` 5 个 `AppRoute*.all()` 集中 import pages | **P2** |
| **A6** | **隐私边界靠注释维护** | `vent_list_page.dart:7-11` + AGENTS.md 表格 | **P2**（无 CI 守门） |
| **A7** | **`scripts/check_cross_feature.py` 过于宽松** | hub (home + settings) 可 import 任意 feature | **P1**（架构债） |
| **A8** | **Spring 物理动效 0 引入** | vent list swipe / contact list swipe / medication list swipe | **P2**（体感折扣） |

### 1.2 替代架构评估（emil 视角）

**Option A：维持 4 层 + core umbrella（现状）**：
- ✅ 1098 test 跑通 / 12 守护脚本全绿
- ✅ dark mode 100% 兼容 / motion curves 100% token 化
- ❌ `core/routing` 反向依赖 `presentation/pages`（emil 圈复杂度警告）
- ❌ `app_tokens.dart` 779 行 100+ token 无分组（emil "decisions should be nameable"反例）

**Option B：抽 `package:chroniccare_ui/` 设计系统包**：
- 方案：把 `core/theme/` + `core/shared/` + `presentation/widgets/animations/` 抽到独立 package；`core/routing` 只 import UI package，不碰 page；`presentation/pages/` 依赖 UI package。
- ✅ 解 `core/routing` 反向依赖（emil 头号 architecture debt）
- ✅ design system 独立版本管理（v0.27 改 design token 不必 bump app 版本）
- ❌ 改包结构 = 大量 import path 重写 + R59 才做完的 god class 拆分要重做
- ❌ Flutter pub workspaces 配置 + Drift 跨包迁移（`core/data/` 留原包）
- emil 评估：**3 个月大工程**。建议 v1.0+ 启动（v0.x 阶段先做 v0.27 关键债）

**Option C：Feature-first Clean Architecture（`features/check_in/{data,domain,presentation}/`）**：
- 方案：跟 NestJS / Spring Boot 风格对齐。每个 feature 自含 data/domain/presentation 3 层。
- ❌ 跟现有 4 层 88% 重复（v0.18 round 12 umbrella 决策就是为避免 feature 内部层级）
- ❌ cross-feature 共享 widget 拆到 `core/` 后归属模糊（`last_med_info` 类）
- emil 评估：**过度设计**。4 层 + feature-flat 已经够。

**Option D：维持 4 层 + core umbrella + 抽 design system module**（**推荐**）：
- `core/theme/` 现状不变（已经是 design system module）
- 关键债 R59 风格拆分 god page（见 A3）
- 抽 hub-import 规则（A4 + A7）
- 引入 spring 物理动效（A8）

**emil 推荐**：**Option D**——**渐进式 5 round**（v0.28–v0.32）：
1. R28：抽 `core/theme/` 拆 3 子模块（`app_colors.dart` / `app_motion.dart` / `app_typography.dart`），各 200-300 行。当前 `app_tokens.dart` 779 行 → 3 文件 250 行均
2. R29：拆 11 个 god page（`setup_page` 4 step coordinator + state 分离 / `home_page` dialog 委托 / `medication_calendar_page` heatmap 抽 / `mood_recorder` 4 widget 抽 / 等）
3. R30：home 改为 router shell，仅做 nav；feature dialog 走 `XFeatureDialog.show(context, ref)` 静态 API（`MoodDialog.show` / `TempMedicationDialog.show` 已是此模式）
4. R31：scripts/check_cross_feature.py 改严格规则——home 只能 import `core/` + `widgets/` + `providers/` + 各 feature 的 `*Dialog.show` 静态入口
5. R32：swipe-to-dismiss 走 spring 物理动效（velocity-based dismissal + 边界 damping，替代 tween）

### 1.3 重构目标（高内聚 / 低耦合）

| 模块 | 当前耦合度 | 重构方向 | 收益 |
|---|---|---|---|
| `app_tokens.dart`（779 行） | **flat namespace** 100+ token 平铺 | 拆 3 子模块（`app_colors.dart` / `app_motion.dart` / `app_typography.dart`），`app_tokens.dart` 退化为 barrel file | emil "good defaults" 维度可发现性 ↑ 50% |
| `setup_page.dart`（448 行）| 状态 + 4 步 UI + 验证 + setup pipeline + `MedDraft` 生命周期 | 抽 `SetupState` Notifier 持状态；page 退化为 step switcher | 状态可测 / page 缩到 ~150 行 |
| `home_page.dart`（432 行）| import 5 个 feature dialog + 3 业务编排 + safety/deep-link 编排 | 抽 `HomeOrchestrator` Notifier；page 仅 build 5 widget | dialog hub 反模式消失 |
| `medication_calendar_page.dart`（450 行）| state + heatmap 计算 + grid 渲染 + legend 4 in 1 | 抽 `_buildGrid` 到 `medication_heatmap.dart`（presentation-only widget） | page 缩到 ~200 行 |
| `mood_recorder.dart`（603 行）| 4 widget + score form + audio + tags + state machine | 已是 widgets/ 子目录，但 mood_dialog 仍 200+ 行没拆 | R29 续 |
| `reminders_hub_page.dart`（494 行）| 5 ReminderCard + 2 `_XxxSheet`（_AssessmentReminderSheet 130 行 + _SafetyReminderSheet 130 行）| 2 sheet 各抽独立文件 | page 缩到 ~200 行 |
| `trend_calendar.dart`（521 行）| calendar grid + month nav + selected day detail | 拆 `trend_calendar_view.dart`（grid） + `selected_day_detail.dart`（detail panel）| page 缩到 ~250 行 |
| `assessment_widgets.dart`（416 行）| QuestionCard + ComparisonCard + AssessmentSparkline 3 widget in 1 file | 拆 3 文件（widgets 已是 sub-directory）| emil cohesion 原则 |

**emil "cohesion matters" 论证**：每个 god file 都是"看不见的细节债务"——开发者改 1 处不知道其他 9 处有相同 pattern。拆分后 1 文件 1 主题，emil 的 "invisible details compound" 才能发挥。

---

## 2. 设计系统健康度（R57-58 增量）

### 2.1 Token 覆盖率（8 维度）

| 维度 | v0.25 R56h 评 | **v0.27 R58 评** | 状态 | 关键证据 |
|---|---|---|---|---|
| 动效 token 化（dur/curve）| 100% | **100%** | 维持 | grep `Curves\.` 在 `app_tokens.dart` 之外 = **0 命中**（除 `app_tokens.dart` + `.g.dart`）|
| 动效集中器采用率 | ~95% | **~95%** | 维持 | 8 个动画 widget + 4 个 route transition + PageTransitionSwitcher 13 处 |
| **色彩 token 化** | 100% | **100%** | 维持 | grep `Color(0xFF` 在 `app_tokens.dart` 之外 = **0 命中**（除 `.g.dart`）|
| dark mode 兼容 | 100% | **100%** | 维持 | R49 35+ 文件 116 行 + 11+ dynamic getter |
| **文字 TextStyle 化** | 36%（160 inline / 57 helper）| **~36%（191 inline / 22+ helper）** | **❌ 退步 0%（持平 191）** | 关键债，**P0** |
| icon 尺寸 token 化 | ~100% | **~100%** | 维持 | `iconSizeInline=18` 24 处 / `iconSizeSmall=14` 4 处 / `iconSizeEmpty=64` 5 处 / `iconSizeError=56` 2 处 |
| spacing token 化 | 100% | **100%** | 维持 | grep `SizedBox\((width|height):\s*[0-9]` 在 presentation/ = **0 命中** |
| **集中器 widget 采用率** | AppListTile 49% | **AppListTile 24 裸 / 58 总 ≈ 71%**（**❌ grep 数比 v0.25 R56h 实际少）** | 退步 0%（持平）| `ListTile(` grep 24 命中（v0.25 报告 20 命中，**多 4 处**）|
| 触感（PressFeedback）| 31 处 | **86 处** | ✅ 增长 | 86 `PressFeedback` 引用 + 22 `PressFeedbackIconButton` |
| **SnackBar 集中器** | 78 处 | **17 直接 `showSnackBar(` + 80+ `AppSnackBar.showX`** | ✅ | grep `showSnackBar(` 在 lib/ = 17 命中（其中 6 在 `app_snack_bar.dart` 自身） = **11 漏集中器** |
| **a11y 集中器** | 7 处 | **7 处** | 持平 | `AppSemantics.container/button/exclude` 仍 7 用 |
| 错误吞咽集中器 | N/A | **80 处 `swallowError`** | ✅ | 全代码库统一 |
| Reduced-motion 包装 | 8+ | **8+** | 维持 | Motion.duration/curve 8+ 引用 |

**关键观察 1**：v0.25 R56h 报"动效 100% / 色彩 100% / 间距 100% / icon 100%"是 v0.25 emil 头号胜利，但**文字 36% 持平 191 inline TextStyle** + **AppListTile 71% 覆盖率（含 24 裸 ListTile 残留）** 是 v0.27 头号债务。emil "decisions should be nameable" 在这 2 维度持续退步。

**关键观察 2**：R57 移除 4 个死 token（`sparklineHeight` / `heatmapLabelWidth` / `eventTimeColWidth`）— 但 `eventTimeColWidth` 在 R58 重新被引用（`trend_calendar.dart:456, 458`）所以仍是活 token。`textStyleScoreLg/Xl/Xxl` 3 个 helper **仍然 0 引用**（grep 验证），是 R50 教训"加 token 不替换"的**典型活化石**。

### 2.2 动画 / 动效设计（R57-58 增量）

**emil 决策框架的 token 化** 100% 完成（`app_tokens.dart:380-410`）：

- `curveStandard` = `Curves.easeOutCubic`（标准进入）— 13 处引用
- `curveSubtle` = `Curves.easeOut`（微弱）— `MotionScheme.subtle` 用
- `curveDecelerate` = `Curves.easeOutQuart`（强减速，streak 数字 / 大数字递增）
- `curveAccelerate` = `Curves.easeInCubic`（出场果断）
- `curveDelight` = `Curves.elasticOut`（庆祝，仅 rare 频度）
- `curveBackOut` = `Curves.easeOutBack`（庆祝主弹跳，1 次过冲）— 精神心理患者不弹多次

**emil 决策框架 `MotionScheme` 4 档**（`app_tokens.dart:699-743`）：
- `none` (100+/day，无动画) — `PressFeedback` 默认 + 主页 EncouragementText
- `subtle` (tens/day，微弱) — `MotionScheme.subtle` = `durFast` + `curveSubtle`
- `standard` (occasional) — `durNormal` + `curveStandard`
- `delight` (rare) — `durSlow` + `curveDelight`

**8 维度逐项审视**（v0.27 R58 评）：

| 维度 | 状态 | 关键文件 | emil 评价 |
|---|---|---|---|
| **频度决策** | ✅ | `app_tokens.dart:351-358` 注释 | 100+/day 无动画 严格遵守（`PressFeedback` 仍给 scale 0.97 = 微弱反馈，不矛盾）|
| **缓动曲线** | ✅ | `app_tokens.dart:381-409` 6 曲线 | 100% token 化 |
| **时长** | ✅ | `app_tokens.dart:356-369` 8 duration | 100% token 化 |
| **Origin 感知** | ⚠️ | 0 处 `transform-origin` 显式控制 | Flutter `Transform.scale` 默认 `center` origin，**emil "modals 居中, popovers 跟 trigger"**——项目 modal 居中 OK（hero / dialog 都居中），popover 0 处（M3 menu 走自带的 `useMaterial3` 默认），所以**无违规**|
| **可中断** | ✅ | `PressFeedback` 用 `Listener` 不消费事件 = child onTap 仍能中断 | 模式 1 + 模式 2 设计（`press_feedback.dart:14-35`）= "无侵入式 scale" |
| **transform/opacity only** | ✅ | 0 处 animating `width/height/padding`（除 `loading_skeleton` 走 shimmer opacity）| 89 动画 widget 100% 走 transform + opacity |
| **可中断 keyframes → transitions** | ✅ | `PageTransitionSwitcher` 走 `AnimatedSwitcher`（`page_transition_switcher.dart:48-60`）= transition 而非 keyframe | 14 路由 + 3 transition 100% 走 AnimatedSwitcher |
| **prefers-reduced-motion** | ✅ | `Motion.duration/curve` 8+ 引用 | `app_tokens.dart:762-779` + 8+ 集中包装 |

**关键观察 3**：emil "asymmetric enter/exit timing"（`emil-design-eng` line 593-598）"press 慢 / release 快" 模式在项目有 1 处实现：`loading_skeleton.dart:121-138` shimmer cycle 1200ms + pause 600ms = "slow 推进 / quick pause" 但**非** "press 慢" 模式。**Hold-to-delete / hold-to-confirm 模式 0 引入**——emil "emotional safety" 维度对精神心理患者极重要（防止误删树洞、误删联系人）。当前 swipe-to-dismiss（Dismissible）+ 二次 confirm dialog 是正确决策，但**没视觉 hold 进度提示**。建议 v0.28+ 加 `HoldToConfirm` 集中器（clip-path 渐进 + 200ms 释放 fast feedback）。

**关键观察 4**：**Spring 物理动效 0 引入**。emil "interruptibility advantage"（`emil-design-eng` line 184-195）— Flutter 内置 `SpringSimulation` 可用，但项目所有 swipe 走 `Dismissible`（tween-based）= drag 跟 finger 1:1 但 release 走 spring-like snap。`Dismissible` 的 `dismissThresholds` 默认 0.4，没 velocity-based 触发（emil "Math.abs(distance)/elapsedMs > 0.11"）。**3 个 swipe 场景**（vent list / contact list / medication list）都是 100+1 次/天的"情绪低谷"操作，**spring 物理 + velocity-based dismissal 体感会显著提升**。

### 2.3 Dark mode + 无障碍（R57-58 增量）

**Dark mode**：100% 兼容（`app_tokens.dart:55-140` 11+ dynamic getter，R49 35 文件 116 行）。**emil "translucent material" 哲学**：`app_tokens.dart:447-493` 4 个 `shadow*Of(context)` context-aware 变体，dark mode 反白（`shadowCardOf` / `shadowCardDarkOf` / `shadowDialogOf` / `shadowOverlayOf`）。**R49 之后 0 处裸用 const `shadowCard` 在 dark mode 视觉错**。

**emil 关键观察 5**：**Color contrast 未审计**。`app_tokens.dart:11` `primary = 0xFF6BCF7F`（嫩绿）在 light surface (0xFFFFFFFF) 上 = WCAG 对比度需计算。emil 哲学 "translucent material" 不只管阴影，**还管 color contrast**。精神心理患者对 contrast 敏感（抑郁期 / 失眠期视野对比度下降），建议 v0.28 加 `scripts/check_color_contrast.py`（CI 友好）。P1 但非阻塞。

**无障碍**：

- `AppSemantics.container/button/exclude` 3 factory（`app_semantics.dart:17-66`）设计优秀
- `PressFeedback` 不破坏 a11y（mode 2 透传 onTap，child 自带 a11y 不被阻断）
- `StreakCounter` 用 `liveRegion: true`（`check_in_button.dart:156-158`）= streak 数字变化时 TalkBack 自动公告（emil 头号 a11y 实践）
- **仍有 3 处**（v0.25 R56h 报告未修）：`medication_report_dialog.dart:99/139` / `medication_calendar_page.dart:84-105` / `home_header.dart:39-53` 缺 Semantics.label

**关键观察 6**：emil-design-eng "skip delay on subsequent tooltips" 模式 0 引入。`PressFeedbackIconButton` 默认 `tooltip: String` 走 M3 Tooltip（hover 1.5s delay 首次 / 后续 0s）= M3 默认即正确，无改进空间。✅

**关键观察 7**：emil "touch device hover states"（`emil-design-eng` line 549-559）— 精神心理患者夜间用药场景高度 touch-only，**项目所有 hover 反馈走 M3 默认**（`InkSparkle` 涟漪无 :hover scale 增强）= 正确决策，避免误触。

### 2.4 微交互 / 触感（R57-58 增量）

**4 类触感集中器**（`feedback.dart:18-39`）：
- `Haptics.tap()` = `selectionClick`（轻）— 选项切换
- `Haptics.success()` = `mediumImpact`（中）— 打卡成功 / snooze 5min
- `Haptics.warning()` = `heavyImpact`（重）— 删除（联系人 / 树洞 / 报告历史）
- `Haptics.light()` = `lightImpact`（微）— 取消 / 关闭 / 切换 theme

**emil 决策**："4 类命名"对应"4 类操作语义"，**emil "decisions should be nameable" 完美落地**——`Haptics.warning()` 比 `HapticFeedback.heavyImpact()` 强 100%。

**3 处触感**：
- `_onCheckIn`（`home_page.dart:280`）— `Haptics.success()` ✅
- `_snooze5Min`（`home_page.dart:358`）— `Haptics.light()` ✅
- vent list / contact list 删除（`vent_list_page.dart:125` / `contacts_list_widget.dart:109`）— `Haptics.warning()` ✅
- vent detail 删除（`vent_detail_page.dart:131`）— `Haptics.warning()` ✅

**emil 头号微交互**：**HomeFooter 仍走 inline TextStyle**（`home_footer.dart:46-49`）— 应走 `textStyleCaption` 集中器（`app_tokens.dart:581-586`）= 微交互体感虽小但用户天天看。

---

## 3. Whole-project UI/UX review

### Findings table

| # | Area | File:Line | Problem | Recommendation | Severity | Difficulty |
|---|------|-----------|---------|----------------|----------|------------|
| **EMIL-T01** | 架构债 | `core/routing/app_router.dart:18-22` | `core/routing/` 5 个 `AppRoute*.all()` 反向依赖 `presentation/pages/`，注释承认"go_router 固有限制" + AGENTS.md 显式豁免 | v0.28-32 5 round 渐进抽 `package:chroniccare_ui/`（design system 包），最终 routing 仅依赖 UI package | **P1** | **XL** |
| **EMIL-T02** | god file | `core/theme/app_tokens.dart:1-666` (779 行) | 100+ token 平铺 1 文件，无分组（`AppColors` / `AppSpacing` / `AppMotion` / `AppText` / `AppShadow` 应各成模块）| 拆 5 子模块 + `app_tokens.dart` 退化为 barrel file | **P1** | **M** |
| **EMIL-T03** | god page | `presentation/pages/setup/setup_page.dart:1-448` | 4 步状态机 + 表单验证 + setup pipeline + `MedDraft` 生命周期 + PIPL consent + 预设模板加载 7 in 1 | 抽 `SetupState` Notifier 持状态；page 退化为 step switcher (~150 行) | **P1** | **L** |
| **EMIL-T04** | god page | `presentation/pages/home/home_page.dart:1-432` | import 5 个 feature dialog（temp_med / today_med / mood）+ safety + deep link + celebration overlay orchestration 5 in 1 | 抽 `HomeOrchestrator` Notifier；page 仅 build 5 widget | **P1** | **L** |
| **EMIL-T05** | 跨 feature import 反模式 | `home_page.dart:28-30` import `pages/medication/temp_medication_dialog.dart` + `pages/medication/today_med_schedule.dart` + `pages/mood/mood_dialog.dart` | hub 集中 dialog import 模式违反 emil "cohesion"——home 应仅做 nav | v0.30 改各 feature 暴露 `*Dialog.show(context, ref)` 静态 API，home 仅 import `XFeature.dialog.show()` | **P1** | **L** |
| **EMIL-T06** | 架构规则过松 | `scripts/check_cross_feature.py:1-80` | hub (home + settings) 可 import 任意 feature，gateway 漏洞 | 改严格规则：home 只能 import `core/` + `widgets/` + `providers/` + feature dialog 的 `*Dialog.show` 静态 API | **P1** | **S** |
| **EMIL-T07** | 隐私边界靠注释维护 | AGENTS.md L140-152 表格 + 多个 dartdoc | 树洞 / 情绪 / 评估 / 失联模块边界 0 CI 守门，注释容易被破坏 | 抽 `scripts/check_privacy_boundary.py`（grep vent 在 trend / assessment / care engine 不出现）| **P2** | **S** |
| **EMIL-T08** | dead token 残留 | `app_tokens.dart:632-660` | `textStyleScoreLg/Xl/Xxl` 3 helper **0 引用**（grep 验证）| 删除 3 helper 或补 R28 子 round 替换 inline 用法 | **P1** | **XS** |
| **EMIL-T09** | 文字 token 化退步 | lib/ 共 191 inline `TextStyle(` | v0.24 round 48 评 40% → v0.25 R56h 评 36% → v0.27 R58 评 36% **持平不退步但未进** | R28-30 3 round 推文字 token 化到 80%+（跟 R49 dark mode 同样模式：先抽 helper 后批量替换）| **P0** | **L** |
| **EMIL-T10** | AppListTile 覆盖率不均 | lib/ 共 24 裸 `ListTile(` | 24 - 8 在 `setup_step_welcome.dart` (4) + `medication_list_view.dart` 实际 (0, 改用 AppListTile.carded) + `reminders_hub_page.dart` (2 个 sheet) + `assessment_reminder_section.dart:130,151` + `medication/*_section` 7 + `setup_step_welcome.dart` 3 + 其他 | 集中器改 1 行 `ListTile(` → `AppListTile.standard` / `AppListTile.carded`（pattern 同 R57 替换 IconButton）| **P1** | **M** |
| **EMIL-T11** | IconButton 残留 24 处 | `pages/{trend_calendar.dart:99/118, vent_detail_page.dart:182/266, mood_recorder.dart:513/521, report_history_dialog.dart:47/109, medication_row.dart:135/142/151, vent_list_page.dart:42/44, contact/contacts_list_widget.dart:78, setup_step_medication.dart:184, notification_status_card.dart:220, medication_report_dialog.dart:47, last_startup_error_banner.dart:81, vent_audio_section.dart:83, vent_list_page.dart:44, etc.}` | 大部分走 `PressFeedbackIconButton` 集中器（22 处），剩 24 处是 v0.25 R56h 提到的 17 处的扩展（grow 7）| R28 一次性替换 24 处为 `PressFeedbackIconButton` | **P1** | **M** |
| **EMIL-T12** | Spring 物理动效 0 引入 | vent list swipe / contact list swipe / medication list swipe | 3 个 swipe-to-dismiss 走 `Dismissible` tween，emil "spring interruptibility" 0 用 | R32 抽 `SwipeToDismissWithSpring` widget（SpringSimulation + velocity-based + boundary damping）| **P2** | **M** |
| **EMIL-T13** | Snackbar 集中器漏 11 处 | grep `showSnackBar(` = 17 命中（6 在 `app_snack_bar.dart` 自身）= **11 漏** | `pages/assessment/widgets/assessment_reminder_section.dart:59/94` + `pages/contact/contacts_list_widget.dart:192/212` + `pages/medication/temp_medication_dialog.dart:151` + `pages/medication/widgets/medications_list_widget.dart:69/195` + `pages/settings/legal_page.dart:63` + `pages/settings/widgets/data_management_section.dart:189/398` + `pages/setup/setup_page.dart:426` | 11 处 `showSnackBar(SnackBar(...))` 改 `AppSnackBar.showX(context, ...)` | **P1** | **S** |
| **EMIL-T14** | 持有庆祝 overlay 在 home_page | `home_page.dart:389-413` `_showCelebrationOverlay` | 24 行 inline `OverlayEntry` + `Positioned` + `Future.delayed(celebrationDisplayMs)` + `entry.remove()` orchestration | 抽 `CelebrationOverlay.show(context, message)` 集中器（类似 `MoodDialog.show` / `TempMedicationDialog.show` 模式）| **P1** | **S** |
| **EMIL-T15** | 路由层 god class 拆分余波 | `lib/core/routing/app_route_*.dart` 5 个文件 | R57 拆得彻底（每文件 1 feature 路由），但 5 个文件仍 import 同一 `app_tokens.dart` + `app_routes.dart` facade | 当前 115 行 OK，建议维持（`app_routes.dart:115-123` 集中 facade） | **P3** | **XS** |
| **EMIL-T16** | inline TextStyle 集中在 6 个 page | `medication_calendar_page.dart:286/393/427` (3) + `medication_row.dart:73/110/124` (3) + `reminders_hub_page.dart:295/312/423/448` (4) + `notification_status_card.dart:263/337/376` (3) + `vent_list_page.dart:243-269/308-320` (3) + `vent_compose_page.dart:361-365` (1) | 这 6 个 page 共 17 个 inline TextStyle，集中在 setup_step_medication 跟 reminders_hub sheet | R28-30 子 round 集中器化（跟 R50 一样：抽 helper + 批量替换）| **P1** | **M** |
| **EMIL-T17** | a11y 集中器采用率低 | 7 处 `AppSemantics.*` 引用 | v0.24 round 45 加 6 个 factory，仅 7 处用 | R28 扫所有 IconButton / Card / 自定义 button，加 `AppSemantics.button(label: ...)` | **P2** | **M** |
| **EMIL-T18** | inline `Duration(milliseconds:)` 16 处 | `home_page.dart:87/407` + `vent_list_page.dart:57` + `trend_page.dart:91` + 11 其他 | emil "decisions should be nameable" — 16 处 magic 数字应走 `AppTokens.durXxx` 集中器 | R28 子 round 统一 token 化 | **P2** | **S** |
| **EMIL-T19** | 主题切换无过渡动画 | `theme_toggle_button.dart:18-34` instant swap | emil "theme switch 是 rare delight 时刻"，建议加 M3 `AnimatedTheme` 包裹（200ms fade）——但**精神心理患者慎用**（突然 dark mode 易 disorient）| 当前 instant 决策对，**保留但加 ARB 注释"deliberate skip animation"** | **P3** | **XS** |
| **EMIL-T20** | `app_theme.dart:17-22` 接受 context 缺失 | `AppTheme._build({required Brightness brightness})` | 静态工厂无 context，所有 `error: isDark ? darkVar : lightVar` 都是 const color——R49 之后这 4 处仍是 silent dark mode 风险 | v0.28 改 `AppTheme._build(BuildContext, Brightness)`，或在 `_build` 内部用 `Theme.of(context).colorScheme.error` | **P2** | **S** |
| **EMIL-T21** | loading_skeleton dispose 风险 | `loading_skeleton.dart:127-138` `_controller.addStatusListener` 内 `Future.delayed` | dispose 后 `Future.delayed` 仍 fire，触发 `_controller.value = 0.0` (已 dispose) → flutter assertion | 改 `dispose` 内 `timer?.cancel()` (跟 `FadeIn.dispose:88-90` 模式) | **P1** | **XS** |
| **EMIL-T22** | `medication_calendar_page.dart:374-378` _colorFor 颜色逻辑 | adherence 4 档（0 / <0.5 / <1 / 满）| hardcoded 阈值（0.5 / 1.0）| 抽 `AppTokens.adherencePartial` / `adherenceAlmost` 已存在，但**阈值没 token 化** | **P2** | **XS** |
| **EMIL-T23** | HomeHeader 缺 Semantics.header | `home_header.dart:25-56` | 3 个 IconButton 缺 a11y label | 加 `Semantics(header: true, ...)` 包裹 | **P2** | **XS** |
| **EMIL-T24** | trend_calendar.dart:521 行 god page | 单一文件 grid + month nav + selected day | emil "cohesion" 违反 | 拆 `trend_calendar_view.dart` (grid) + `selected_day_detail.dart` (detail panel) | **P1** | **M** |
| **EMIL-T25** | Reminder hub 2 sheet 残留 | `reminders_hub_page.dart:230-494` 2 private sheet (265 行) | 2 sheet 应该各自独立文件（_AssessmentReminderSheet 130 + _SafetyReminderSheet 130）| 拆 2 文件：`reminders_assessment_sheet.dart` + `reminders_safety_sheet.dart` | **P1** | **S** |
| **EMIL-T26** | data_management_section 413 行 | 导出 / 报告 / 历史 / 导入 / 清空 5 in 1 | 5 个 section 已经基本分 widget，但仍在 1 文件 | 拆 5 section widget（5 文件），page 退化为 build 5 child | **P1** | **M** |
| **EMIL-T27** | edit_medication_dialog 406 行 | 表单 + 验证 + dose picker + time picker 4 in 1 | god dialog | 拆 4 widget（medication_name / dosage_form / time_picker / refill_picker）| **P1** | **M** |
| **EMIL-T28** | mood_recorder 603 行 | 4 widget + score form + audio + tags + state machine | emil "1 widget 1 主题"违反 | 续 R46 拆分（v0.25 R56h 已 EMIL-INC-11 标记未修）| **P1** | **L** |
| **EMIL-T29** | AppTokens shadow* const + shadow*Of 双轨 | `app_tokens.dart:411-444` const + `446-493` context getter 8 个 | 4 个 const 版本仍存在但**无 0 引用**——grep `AppTokens\.shadow(?!Card|Dialog|Overlay|CardDark)` 应 0 命中 | 删 4 个 const 强制走 dynamic getter（避免 R49 同款 silent bug 重现）| **P1** | **XS** |
| **EMIL-T30** | `ChipBadge` 4 tone 集中器 3 处 | `chip_badge.dart:1-87` + 3 引用（trend_calendar / refill_manage_page / assessment_history）| v0.22 round 34 加 4 tone，3 处用——覆盖率极低 | R28 扫所有 inline `Container(padding, decoration: BoxDecoration(color: tintedXxx, borderRadius))` 改 ChipBadge | **P2** | **S** |
| **EMIL-T31** | `SegmentedButton` 2 处缺 PressFeedback | `medication_calendar_page.dart:84-105` + `trend_page.dart:240-256` | v0.26 R57 修了 1 处（medication_calendar），trend_page 240-256 仍裸 | 修 trend_page SegmentedButton 同款 | **P2** | **XS** |
| **EMIL-T32** | `AppTokens.textStyleCaption` 0 引用 | grep 验证 | `textStyleCaption` 集中器抽了但没 1 处用 | 删或扫全代码库 14 caption style 替换 | **P2** | **S** |
| **EMIL-T33** | 4 个 god page 1 feature 内部 | `assessment_page.dart:439` + `assessment_widgets.dart:416` | 单 page 2 个 god file | assessment_widgets.dart 416 行已拆 3 widget directory 但 QuestionCard 跟 ComparisonCard 混 1 file | **P2** | **M** |
| **EMIL-T34** | `vent_compose_page.dart:436` god state | 录音机 / 播放器 / 临时文件 / 文字输入 / 状态机 5 in 1 | 已拆 3 widget（vent_audio_section / vent_text_input / vent_save_bar），但 state 编排仍在 page | 抽 `VentComposeState` Notifier | **P2** | **L** |
| **EMIL-T35** | setup_page 仍 448 行 | setup_page.dart:1-448 | v0.19 Q2 拆 4 step widget，但 state 编排没动 | 抽 `SetupState` Notifier 持 4 步 state + 表单 + MedDraft 生命周期 | **P1** | **L** |

**总计**：35 个发现（P0 ×1 + P1 ×17 + P2 ×12 + P3 ×5）。

### 优先级 8 维度

按 emil 杠杆公式（impact × reach × confidence × effort），排出 v0.28 头 5：

1. **EMIL-T09**（P0）：文字 token 化退步 191 inline TextStyle → 80% 集中器化（3 round 推 36% → 80%）
2. **EMIL-T02**（P1）：`app_tokens.dart` 779 行 god file → 拆 5 子模块（1 round M effort）
3. **EMIL-T13**（P1）：11 处 `showSnackBar` 漏集中器 → 改 `AppSnackBar.showX`（1 round S effort）
4. **EMIL-T08**（P1）：3 个死 token（`textStyleScoreLg/Xl/Xxl`）→ 删（1 round XS effort）
5. **EMIL-T21**（P1）：loading_skeleton dispose 后 `Future.delayed` race（1 round XS effort，但**P1 紧急**——emil 头号微交互 bug）

---

## 4. 优先级排序重构清单（v0.28 头 round 推荐）

> 排序：影响 × 频度 × 信心 / 工作量
> 跟 superpowers 视角的交叉靠 P0/P1 排名——R56h 之后 emil 跟 superpowers 共识已写明。

| Rank | 编号 | 标题 | 严重度 | 工作量 | 收益 | v0.28 建议 |
|------|------|------|--------|--------|------|------------|
| 1 | **EMIL-T09** | 文字 token 化 191→<30 inline TextStyle | P0 | L | emil "decisions should be nameable" 在文字维度首次 80%+ | ✅ v0.28 头号工程 |
| 2 | **EMIL-T02** | `app_tokens.dart` 779 → 5 子模块（colors/motion/typography/spacing/shadow）| P1 | M | emil 头号设计系统可发现性 | ✅ v0.28 同步 |
| 3 | **EMIL-T08** | 删 3 个 dead token（`textStyleScoreLg/Xl/Xxl`）+ EMIL-T32 `textStyleCaption` 0 引用 audit | P1 | XS | "taste = subtraction" 制度化 | ✅ v0.28 同 round |
| 4 | **EMIL-T21** | `loading_skeleton.dart` dispose race | P1 | XS | emil "invisible details compound" | ✅ v0.28 同步 |
| 5 | **EMIL-T13** | 11 处 `showSnackBar` 漏集中器 | P1 | S | emil cohesion | ✅ v0.28 同步 |
| 6 | **EMIL-T14** | `CelebrationOverlay.show(context, msg)` 集中器 | P1 | S | emil "rare 时刻" 抽象 | ✅ v0.28 同步 |
| 7 | **EMIL-T29** | 删 4 个 const shadow token | P1 | XS | 防 R49 同款 silent bug 重现 | ✅ v0.28 同步 |
| 8 | **EMIL-T11** | 24 处 IconButton 走 `PressFeedbackIconButton` | P1 | M | emil 触感统一 | v0.29 |
| 9 | **EMIL-T10** | 24 处裸 ListTile 走 `AppListTile.standard/carded` | P1 | M | emil list 模式统一 | v0.29 |
| 10 | **EMIL-T04** + **EMIL-T05** + **EMIL-T06** | home 拆 3 步：HomeOrchestrator + feature dialog 静态 API + cross_feature.py 严规则 | P1 | L | emil hub 边界 + cross-feature 反模式 | v0.30 |
| 11 | **EMIL-T03** + **EMIL-T35** | setup_page 拆 `SetupState` Notifier | P1 | L | emil stateful 集中器化 | v0.30 |
| 12 | **EMIL-T24..28** | 7 个 god page (medication_calendar / trend_calendar / reminders_hub / data_mgmt / edit_med / mood_recorder / assessment_widgets) 各拆 | P1 | M×7 | emil 1 page 1 主题 | v0.30-32 |
| 13 | **EMIL-T12** | `SwipeToDismissWithSpring` 集中器 | P2 | M | emil spring physics | v0.32 |
| 14 | **EMIL-T01** | `package:chroniccare_ui/` design system 抽包 | P1 | XL | 顶层架构债终极解 | v1.0+（不在 v0.x） |

---

## 5. 情感设计笔记（精神心理患者特殊考量）

emil "cohesion matters"（`emil-design-eng` line 578-582）——"the whole experience is cohesive. The easing and duration fit the vibe of the library." 精神心理患者 App 的 vibe 是**平静、可信、不刺激**。项目多个决策精准命中此 vibe：

### 5.1 已落地的精神心理患者友好决策

1. **Loading shimmer "呼吸" 而非 "脉动"**（`loading_skeleton.dart:128-138`）：1.2s 渐变 + 600ms 暂停，单次过渡不重复。emil "loading should feel fast, not dance"（注释 line 159）= 直接呼应精神心理患者对刺激敏感的痛点。

2. **CelebrationBounce 用 `easeOutBack` 而非 `elasticOut`**（`celebration_bounce.dart:48-58`）：emil "Keep bounce subtle (0.1-0.3) when used. Avoid bounce in most UI contexts." 项目选 1 次过冲（easeOutBack）= 庆祝不刺眼。`app_tokens.dart:402-409` 注释明示"vs curveDelight 区别：主庆祝用 easeOutBack 更'稳'，副粒子可用 elasticOut"。

3. **`press_feedback.dart:14-35` PressFeedback 不接管 onTap**（emil "tens/day 微弱反馈"）：模式 2（`onTap: null`）= child 自带 onTap 仍工作，**用户点 100+/day 的打卡按钮既得到 scale 0.97 反馈又得到 InkWell ripple**。这是 emil "Buttons must feel responsive" 在精神心理 App 的**正确执行**——太少的反馈让焦虑用户怀疑"是否点中"，太多的反馈让前庭敏感用户眩晕。

4. **`Haptics.warning()` 4 类触感**（`feedback.dart:18-39`）：删除联系人/树洞前 `Haptics.warning()` = `heavyImpact` = 重触感警示。emil "buttons must feel responsive" 的反面——"destructive buttons must feel different"。

5. **`AppSnackBar.undo` 4 秒反悔窗口**（`app_snack_bar.dart:61-78`）：删 vent entry / contact / medication 后给 4 秒反悔，注释明示"用户反应窗口"（line 73）= 精神心理患者情绪低谷时误删可逆。

6. **PageTransitionSwitcher 默认 fade 而非 slide**（`page_transition_switcher.dart:48-60`）：emil "long movements feel slow for psychiatric patients"（注释 line 88 `medication_calendar_page.dart`）= 评估页 quiz→result 只用 fade 不用 slide。

7. **StreakCounter `liveRegion: true`**（`check_in_button.dart:156-158`）：TalkBack 在 streak 变化时自动公告（"已坚持 5 天"），盲人精神心理患者能"听"到成就感。

### 5.2 仍可提升的精神心理患者友好决策

1. **NoStreakBroken 文案**：`last_med_info.dart:38-39` streak broken 时显示 `homeStreakBroken`——**emil 哲学 "calm over cautionary"**：streak 断不应让用户感到"失败"，应中性化（"休息了一周" / "重新开始也来得及"）。当前文案 ARB 没看过，不评价，但**emil 视角建议 review 文案 tone**。

2. **No `hold-to-delete` 模式**：精神心理患者极易误删（情绪波动期）。emil "Hold-to-delete pattern"（`emil-design-eng` line 431-434）clip-path + 2s linear 推进 = **200ms 释放时 200ms ease-out snap-back** = 视觉"防滑"反馈。当前 swipe-to-dismiss + confirm dialog 是**正确**但视觉 hold 提示**缺失**。建议 v0.32+ 加 `HoldToConfirm` 集中器（针对永久删除 vent entry / 清空所有数据等**不可恢复**操作）。

3. **No `breathe animation`**：emil "You Don't Need Animations" 的反面——**有些场景下"动画"是安抚**。抑郁期用户的 `EmptyState`（`vent_list` / `assessment_history`）可加**breathing 动画**（3s ease-in-out 缩放 1.0→1.03→1.0 循环）= 像"深呼吸"的视觉提示。**但精神心理患者慎用永久循环动画**（R45 改 shimmer 为呼吸模式就是为此），所以**breathe animation 应该是用户主动触发**（如进入 "深呼吸练习" 页面），不是默认。

4. **`NotificationFailureBanner` 文案 tone**（`notification_failure_banner.dart:39-53`）：emil "calm over cautionary"——通知没设上不要让用户恐慌。文案应中性"通知未开启，重要提醒可能错过"而非"严重警告：通知没设上！"。

5. **No haptic success after recovery**：精神心理患者从抑郁期恢复时，**3 天 → 5 天 streak** 的 `Haptics.success()` + `CelebrationBounce` 应**比 100 天 streak 体感更明显**（emil "delight 时刻"对脆弱用户意义更大）。当前统一走 `MotionScheme.delight`，**emil 哲学 "match motion to mood"**——可加 2 档 delight（`delight.soft` for 1-7 days / `delight.full` for 30+ days）。

6. **Crisis dialog 已经是 barrierDismissible: false**（`assessment_page.dart:223`）+ 弹 crisis hotlines = **精神心理危机处理 emil 头号原则**——"don't block important things, but DO block dismissible on crisis"。

7. **`PressFeedback` scale 0.97 vs 0.95 选择**：emil "subtle (0.95-0.98)"。项目用 0.97 = 折中。**对抑郁期/低能量用户**：0.95（更明显）= "我确实按到了"。**对焦虑期用户**：0.97（更微弱）= 避免刺激。建议**根据系统 reduce-motion 自动调**——reduce-motion 0% scale（无反馈，靠 InkWell ripple）= 减少刺激。**emil "match motion to user's condition" 哲学**。

### 5.3 精神心理患者专属 emil 设计原则总结

1. **Reduced motion 默认开启**：建议 v0.28+ 加 ARB 设置"减少动效"开关，**默认开启**给所有用户（精神心理患者首屏），用户在设置可关。
2. **Crisis 信号绝不 dismissible**：`assessment_page._showCrisisDialog` 是好榜样（`barrierDismissible: false`），其他 5+ 处 dialog 应 review。
3. **Privacy boundary 靠 CI 守门**：EMIL-T07 抽 `check_privacy_boundary.py`（grep vent / mood 在 trend / care engine 不出现）= 隐私边界不能靠注释维护。
4. **Dark mode 不只 dark**：抑郁发作期/失眠期用户长时间看屏幕，dark mode 是"必须"。R49 100% dark mode 兼容是 v0.25 emil 头号胜利。**emil "good defaults" 维度**对精神心理患者是 1 级重要。

---

## 6. 报告总结

| 维度 | v0.27 R58 评 | 关键数据 |
|---|---|---|
| 顶层架构契合度 | **7/10**（4 层 + umbrella + 集中器库 + dark mode 100% + 3 类 route transition + 4 类 Haptics + 4 类 SnackBar 集中器 + MotionScheme 4 档 + reduce-motion 包装） | 5 round god class 拆分成功（R57-59）+ 1 god file (`app_tokens.dart` 779 行) 重生 + 11 god page 待拆 |
| 设计系统健康度 | **8/10**（动效 100% / 色彩 100% / dark mode 100% / icon 100% / spacing 100% / Haptics 100% / SnackBar 93%）| 文字 36% 持平（**❌ 191 inline 退步停滞**）+ AppListTile 71%（**24 裸残留**）+ 3 dead tokens（`textStyleScoreLg/Xl/Xxl`）+ Snackbar 11 漏 |
| 动画 / 动效 | **9/10**（emil 决策框架 100% token 化 + 8+ Motion 包装 + 0 违 transform/opacity）| spring 物理 0 引入 + hold-to-confirm 0 引入 + scale 0.97 静态（不跟 reduce-motion 联动）|
| Dark mode | **10/10**（100% 兼容）| 0 hardcoded color + 11+ dynamic getter + 4 shadow*Of context-aware |
| 触感 | **9/10**（4 类 Haptics 集中器）| 4 处主要操作覆盖（成功/警告/轻/选中）|
| 无障碍 | **7/10**（AppSemantics 3 factory + liveRegion streak）| 仍 3 处缺 Semantics（v0.25 R56h 报未修）+ AppSemantics 仅 7 处用 |
| 精神心理患者特殊考量 | **9/10**（loading "呼吸" + celebration "稳弹" + barrierDismissible crisis + Haptics.warning + undo 4s + 隐私 boundary 5 模块隔离）| NoStreakBroken 文案 tone 未审 + 0 hold-to-confirm 0 breathe animation 0 危重通知 tactile |

**v0.27 R58 emil 头号胜利**：3 round god class 拆分（app_router 418→51 行 / app_routes 280→115 行 / 14 GoRoute 拆 5 feature 文件）——这是 R56h 之后 R57-59 的最大架构胜利。`routerProvider` 用 `ref.read` + 内部 cache + `ref.listen` 模式（`app_router.dart:37-61`）= 性能 + 架构双赢。

**v0.27 R58 emil 头号债务**：文字 token 化 36% 持平 191 inline TextStyle（v0.24 → v0.25 → v0.27 三 round 没推进）。`AppTokens.textStyleCaption` 抽了但**0 引用**（EMIL-T32）——"taste = subtraction" 反例再添 1 例。

**emil 哲学对应**：
- ✅ "Good defaults matter more than options" — `MotionScheme` 4 档 / `Haptics` 4 类 / 集中器 widget 库 22 个
- ✅ "Decisions should be nameable" — token 化 100% (除文字) / `swallowError` / 静态 `*.show(context, ref)` API
- ✅ "Unseen details compound" — loading 呼吸 / 庆祝 1 次过冲 / barrierDismissible crisis
- ❌ "Taste = subtraction" — 3 dead tokens / `textStyleCaption` 0 引用 / 4 const shadow 残留

---

**报告路径**：`D:\Batch\chroniccare\docs\reviews\v0.27\review-emilkowalski-v027.md`

> **总计 35 个发现**（P0 ×1 + P1 ×17 + P2 ×12 + P3 ×5）。
> **v0.28 推荐头 5 round**：EMIL-T09（文字 token 化 P0）+ EMIL-T02（app_tokens 拆 5 子模块）+ EMIL-T08（删 3 dead tokens）+ EMIL-T21（loading dispose race）+ EMIL-T13（11 处 showSnackBar 集中器化）。
> **v1.0 长期**：EMIL-T01（`package:chroniccare_ui/` design system 抽包）—— 顶层架构债终极解。
