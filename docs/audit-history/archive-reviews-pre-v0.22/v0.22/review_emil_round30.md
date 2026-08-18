# emilkowalski 视角审查报告（v0.22 round 30）

> **审查者**：emilkowalski（设计工程师）视角子审查 agent
> **时间**：2026-07-21
> **项目**：慢性病管家（精神心理患者吃药打卡 App）
> **版本**：v0.22 round 30（164 lib 文件 / 74 test / 8 feature）
> **核心方法**：读完所有 49 个 `presentation/` 文件 + 7 个 widget + 4 个 theme + 2 个 routing + 5 个 shared + 关键 2 个 domain 业务文件，对照 8 维度动画审计 + 组件设计 + 不可见细节清单做点检

---

## 顶层架构审视

### 整体评价

**成熟度判断**：v0.22 round 30 的 `app_tokens.dart` 已经把动效（4 档 `MotionScheme` + 4 个 `durXxx` + 4 个 `curveXxx`）、color（5 个 `tintedXxx` + 3 个 `fgOnXxx`）、text（10 个 `textStyleXxx`）、spacing（5 档 + 4 个 `spacingXxx`）、radius（4 档）、shadow（3 个）、lineHeight（5 档）、tint surface、stagger 公式（`staggerStepMs` / `staggerCapMs`）、celebration display 时长（`celebrationDisplayMs`）、snackbar 时长（3 档）**全部 token 化**。`Motion.duration` / `Motion.curve` 对 `prefers-reduced-motion` 的封装**全项目覆盖**（P0-7 已修）。

**这是 emil 意义上的 "Taste is trained, not innate" 教科书级实例**。一个 round 18 才开始引入动效 token 的 Flutter 项目，到 round 30 做出 12 个 round 的连续打磨（emil-01~50, sp-zh P0~P3, spen-bug-01~10），token 化覆盖率（动效 95%、文字 60%、spacing 100%、color 90%）已经接近 Raycast / Linear 的成熟度。

**剩余 5-10% 优化空间集中在 4 类**：
1. **15+ 处 `Colors.white` / `Colors.black` 散落**（大按钮内嵌 LoadingSpinner 反白、Sparkline 圆点 strokeColor、SegmentedButton icon、Calendar cell 高亮数字），dark mode 反白失效
2. **4 处裸 `fontSize: 12/11/13` 硬编码**（trend tooltip / vent detail slider 时间 / mood dialog 评分数字 / 24h score 数字 64），token 化漏网
3. **streak counter `_StreakCounter` 的 `AnimatedSize` 没用上** — 数字从 0 跳到 N，理论上 `Text` 用 `AnimatedDefaultTextStyle` 更对，但当前实现可接受
4. **若干 `Stack(children: [Text, LoadingSpinner])` 重复模式**（mood dialog / vent compose / settings import / medication edit 等 4+ 处），应抽 `LoadingTextButton` widget

### 项目可采用的更优 UI 架构

| # | 建议 | 理由 |
|---|------|------|
| **A1** | **抽 `LoadingTextButton` 通用 widget** | 现有 4+ 处重复 `Stack(alignment: center, children: [Text(label), if (saving) IgnorePointer(Spinner)])` 模式（mood_dialog:149-165、temp_medication_dialog:128-141、vent_compose_page:418-431、settings_page:680-688）。emil 原则 4 "Handle edge cases invisibly" —— 这个 spinner 中心对齐 + 不响应点击 + 颜色不破坏 button 文字 = 4 个属性要每次手写，违反"good defaults matter more than options"。建议 `LoadingTextButton(label, onPressed, isLoading, isPrimary)` 一行替代 |
| **A2** | **抽 `ChipBadge` 通用 widget** | 现有 6+ 处 `Container(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: tintedXxx, borderRadius: radiusChip), child: Text(...))` 重复模式（trend_calendar.dart:282-300、assessment_history_page.dart:333-358、refill_manage_page.dart:217-228、medications_list_widget.dart:280-293）。padding/radius/字号 各写各的，违反 cohesion |
| **A3** | **抽 `SeverityIndicator`（status dot + 文本）** | 现有 4 处 `_StatusDot`（refill_manage_page.dart:299-318）+ `_SeverityChip`（assessment_history_page.dart:398-430）+ `_TimeChip`（today_med_schedule.dart:166-209）+ `SpacerWithIcon` 模式重复。emil 设计哲学 "build cohesive experience" —— status dot 跟 severity chip 视觉应该统一 |
| **A4** | **`widgets/` 下应该再抽 `widgets/forms/` 子目录** | 当前 `SecondaryButton`、`PressFeedback` 在根目录，但还有 `TextField + label/hint/border` 4 处散落（mood_dialog:103-111、temp_medication_dialog:74-94、contact 添加、setup 各 step）。`widgets/forms/labelled_text_field.dart` 抽出来后 setup 4 个 step 都用得上 |
| **A5** | **`animations/` 子目录可继续扩** | 当前只有 `FadeIn` + `SlideUp`，但 setup_page 的 4 step 切换用了 inline `AnimatedSwitcher`（setup_page.dart:96-129），trend 的 list↔calendar 切换、assessment 的 quiz→result 切换都用了 inline `AnimatedSwitcher`。可抽 `PageTransitionSwitcher` 集中 |

### 可重构的 UI 模块

| # | 文件:行号 | 问题 | 重构方案 |
|---|----------|------|----------|
| **R1** | `lib/presentation/widgets/` 缺 `LoadingTextButton` | 4+ 处 `Stack([Text, if saving LoadingSpinner])` 散落 | 抽 `widgets/loading_text_button.dart`，签名 `({required Widget label, required VoidCallback? onPressed, bool isLoading, ButtonStyle? style})` |
| **R2** | `lib/presentation/widgets/` 缺 `ChipBadge` | 6+ 处带 colored container 的小 chip 重复 | 抽 `widgets/chip_badge.dart` 接 `tintedXxx(context)` + `AppTokens.textStyleMicro(context)` |
| **R3** | `lib/presentation/pages/medication/medication_calendar_page.dart:111-114` | 加载状态显示一行 `Text(commonLoadFailed(...))`，没用统一 `ErrorState` | 改用 `lib/presentation/widgets/error_state.dart`（assessment_history_page.dart:55 已示范） |
| **R4** | `lib/presentation/pages/medication/refill_manage_page.dart:122-128` | 同上，`Text(commonLoadFailed(...))` 应改 `ErrorState` | 同上 |
| **R5** | `lib/presentation/pages/medication/widgets/medications_list_widget.dart:268-288` | `_MedicationRow` 的 `Dismissible` 跟 `lib/presentation/pages/contact/contacts_list_widget.dart:60-80` 的 `Dismissible` 写法 90% 相同 | 抽 `widgets/swipe_to_delete.dart` 接 `confirmDismiss: (() async => showDialog + Haptics)` |
| **R6** | `lib/presentation/pages/trend/trend_page.dart:147-152` | 加载 `SizedBox(height: 200, child: LoadingSkeleton.fullScreen())` 是用 `fullScreen()` 包了 200 高的容器（语义错位） | `LoadingSkeleton` 应该有 `const LoadingSkeleton.box({height: 200, width})` 变体 |
| **R7** | `lib/core/shared/mood_visual.dart:14-37` | emoji 跟 label 跟 ARGB 三组 switch 拆开 3 个静态方法 | 改成 `enum MoodLevel { veryBad, bad, neutral, good, veryGood }` + 1 个 `lookup` Map，调用方 `MoodVisual.emojiFor(1)` → `MoodVisual.from(1).emoji` 更显式 |

---

## 底层逐行排查

### 8 维度动画审计

> 参考 `emilkowalski/improve-animations/AUDIT.md` 8 维度：
> 1. Purpose & frequency · 2. Easing & duration · 3. Physicality & origin · 4. Interruptibility · 5. Performance · 6. Accessibility · 7. Cohesion & tokens · 8. Missed opportunities

| 维度 | 现状 | 问题文件:行号 | 修复难度 | 优先级 |
|------|------|---------------|---------|--------|
| **1. Purpose & frequency** | ⭐ 5/5 — 决策框架贯穿：`MotionScheme.{none,subtle,standard,delight}` + 显式注释每个动效按频度分档 | — | — | — |
| **1.1** | EncouragementText（home 鼓励文案）streak 变化时**完全无动画** | `lib/presentation/pages/home/widgets/encouragement_text.dart:25-32` | trivial | P3 |
| | | **说明**：emil 决策正确（100+/day 频度 = `MotionScheme.none`），无问题。**但**用户每天看 N 次，文案内容却"瞬间跳变"从"加油"到"已坚持 30 天"，emil 原则 1 "prevention of jarring change" — 文案是 swap 不是 animate，但如果是 fade-transition（100ms）会感觉更平。**保留为 P3 是合理的** | | |
| **1.2** | `PressFeedback` 包裹了 3 个 home 主按钮 + 5 个 settings 入口 | `lib/presentation/widgets/press_feedback.dart:42-110` | trivial | ✓ 已优 |
| | | **说明**：emil 框架的"subtle feedback on tens/day" 完美实现。`AnimatedScale` 用 token + `Motion.duration` 正确 | | |
| **1.3** | **底栏（HomeHeader 的 3 个 IconButton）** 无 press feedback | `lib/presentation/pages/home/widgets/home_header.dart:36-50` | trivial | **P1** |
| | | **说明**：3 个 IconButton 是 tens/day（趋势 / 评估 / 设置入口）频度。Material `IconButton` 自带 InkWell ripple 但**没有 scale 反馈**。**应外包 `PressFeedback`**（参考 secondary_action_row 的 Vent 按钮已经在 round 28 修过 emil-28）。**这是 emil P0-9 同款遗漏** | | |
| **2. Easing & duration** | ⭐ 5/5 — 4 个 curve token 选对（`curveStandard=easeOutCubic` / `curveDecelerate=easeOutQuart` / `curveAccelerate=easeInCubic` / `curveDelight=elasticOut`） | — | — | — |
| **2.1** | `RefreshIndicator` 用了 `await Future<void>.delayed(400ms)` | `trend_page.dart:83`, `assessment_history_page.dart:71`, `vent_list_page.dart:52` | trivial | P3 |
| | | **说明**：400ms 是"人为 spinner 时长"魔法数 — 用户下拉放手后硬等 400ms 才关 spinner。emil "perceived performance"：下拉刷新本身有动效，**额外延 400ms 是没必要的**（系统 RefreshIndicator 自带 300-500ms 转场）。`AppTokens.minVisibleRefreshMs` 抽 token 统一（参考 emil P0-3 / P1-3 模式） | | |
| **3. Physicality & origin** | ⭐ 4/5 — 没用 `transform-origin: center` 错误；Hero 已用（vent list → detail 的 avatar）；日期切换没用 transform 错位 | — | — | — |
| **3.1** | vent compose 的 3 状态切换（无 audio / recording / recorded）**没有 origin 锚定** | `lib/presentation/pages/vent/vent_compose_page.dart:439-490` | small | **P1** |
| | | **说明**：用户从"按 mic 录音" → 录音中（红圈 stop 按钮） → 录音完（显示 play 按钮）三态切换，**当前用 `if (audioPath == null)` 整块替换**。如果用 `AnimatedSwitcher` + `transitionBuilder: FadeTransition` 包裹，能感知"我刚刚按下 → 现在在录"的位置感。这是 emil "spatial consistency" 原则 | | |
| **3.2** | mood dialog 的 4 维评分行（mood/energy/sleep/anxiety）**没有选中态的 spatial 反馈** | `lib/presentation/pages/mood/mood_dialog.dart:222-264` | small | P2 |
| | | **说明**：用户点 "3 分"，数字从灰 → 绿，但 chip 整体没"按下去"感。`AnimatedContainer(duration: durFast, color: tintedPrimarySoft, borderRadius: radiusChip)` 包裹 InkWell 可以让选中状态有 100ms 平滑过渡。emil "preventing jarring change" | | |
| **4. Interruptibility** | ⭐ 5/5 — `AnimatedSwitcher` 用对（check_in_button:53-64, setup_page:96-129, trend_calendar 用 setState）；`TweenAnimationBuilder` / `AnimatedContainer` / `AnimatedSwitcher` 都是 CSS transitions（interruptible） | — | — | — |
| **5. Performance** | ⭐ 4/5 — 全项目搜过 `LayoutBuilder` 用法 2 处、搜过 `width: double.infinity` 多次，无明显问题 | — | — | — |
| **5.1** | `AnimatedBuilder(animation: _t, ...)` 模式在 3 处用得稍重 | `fade_in.dart:95-110`, `slide_up.dart:90-98`, `celebration_overlay.dart:79-88` | trivial | P3 |
| | | **说明**：用 `AnimatedBuilder` 是对的（emil 5 "transitions over keyframes"），但 fade_in / slide_up 可以用 `SlideTransition` + `FadeTransition` 直接用 controller（**slide_up 已经做对了**，**fade_in 还是用 AnimatedBuilder**）。`fade_in` 改 `FadeTransition(opacity: _t, child: withScale ? ScaleTransition(scale: ..., child: child) : child)` 更轻 | | |
| **5.2** | `_StreakCounter` 的 `setState` 每次 tick 触发 | `lib/presentation/pages/check_in/check_in_button.dart:150-156` | — | ✓ 已优 |
| | | **说明**：v0.22 round 28 emil-bug-03 修过 listener leak，**正确**。但仍有 1 个隐患：`Tween(begin: 0, end: value)` 的 begin 每次 `didUpdateWidget` 都用 `_lastValue`（缓存），但 tween 自身每次 `reset() + forward()` 都从 0 重启，**这才是符合预期的**（每次 streak 增加都"飞一次"） | | |
| **5.3** | `fl_chart` 折线图（trend_charts.dart / assessment_history_page.dart）每次 rebuild 都重算 spots | `lib/presentation/pages/trend/trend_charts.dart:140-170`, `assessment_history_page.dart:240-280` | medium | P2 |
| | | **说明**：当前 `final sorted = [...records]..sort((a, b) => a.timestamp.compareTo(b.timestamp));` 在 build 内每次都做，**100+ 评估记录时 O(n log n) 排序 60fps 跑**。可上提 `useMemo` 或放 `Provider` 缓存。emil "performance" 维度。**但**用户实际跑只 10-50 条记录，影响小 | | |
| **6. Accessibility** | ⭐ 5/5 — `prefers-reduced-motion` 全项目覆盖（Motion.duration/curve + 4 个 `didChangeDependencies` 同步）；Semantics container/liveRegion 在 streak counter / mood dialog / question card 都用上 | — | — | — |
| **6.1** | `AppBar` 的 `ThemeToggleButton` **没有 Semantics 标签** | `lib/presentation/pages/home/home_page.dart:212` `actions: [ThemeToggleButton()]` | trivial | P2 |
| | | **说明**：tooltip 给了，但 TalkBack 朗读 `ThemeToggleButton` 而不是"切换主题，当前是亮色"。emil a11y：可读性 > 视觉 | | |
| **7. Cohesion & tokens** | ⭐ 5/5 — 见顶层评价 | — | — | — |
| **7.1** | **`Colors.white` 散落 15+ 处**（dark mode 反白失效） | `lib/presentation/pages/vent/vent_compose_page.dart:443`, `contact/contacts_list_widget.dart:230`, `mood/mood_dialog.dart:160`, `medication/temp_medication_dialog.dart:136`, `medication/widgets/edit_medication_dialog.dart:387`, `medication/widgets/medication_report_dialog.dart:127`, `home/widgets/celebration_overlay.dart:102`, `pages/setup/setup_step_medication.dart:134`, `trend/trend_calendar.dart:221`, `trend/trend_charts.dart:251,523`, `assessment/assessment_history_page.dart:344,363`, `assessment/assessment_widgets.dart:148`, `settings/settings_page.dart:686` | small | **P1** |
| | | **说明**：v0.22 round 30 emil P2-6 已经抽了 `AppTokens.fgOnXxx` 集中器（fgOnPrimary / fgOnError / fgOnSurface），但**还有 15+ 处直接 `Colors.white` 没改**。特别严重的：<br>• `check_in_button.dart:208` 注释说"之前 Colors.white.withValues(alpha: 0.85) 在 dark mode 下不变,反白失效"——**已修**，但其它 14 处同样的 bug 没修<br>• `medication_report_dialog.dart:161` `Colors.black54` 暗色遮罩，dark mode 下应该用 `Colors.white54`（dialog 全屏 PDF loading 遮罩）<br>修复：<br>`grep -nE "Colors\.(white|black)" lib/presentation` 一次性 replace 13+ 处 | | |
| **7.2** | **`fontSize` 硬编码 18+ 处**（token 化漏网） | `assessment/assessment_page.dart:278` `fontSize: 64`（24h 大数字）<br>`medication/today_med_schedule.dart:191,200` `fontSize: 13, 12`<br>`trend/trend_calendar.dart:248` `fontSize: 13`<br>`trend/trend_charts.dart:365,607` `fontSize: 12`<br>`vent/vent_detail_page.dart:310,317` `fontSize: 11`<br>`medication/widgets/medications_list_widget.dart:363` `fontSize: 10`<br>`medication/widgets/medication_report_dialog.dart:82` `fontSize: 13`<br>`settings/legal_page.dart:271,291` `fontSize: 12, 11`<br>`settings/widgets/notification_status_card.dart:253` `fontSize: 12`<br>`settings/settings_page.dart:425` `fontSize: 12`<br>`assessment/assessment_history_page.dart:207,364` `fontSize: 12, 11`<br>`mood/mood_dialog.dart:249` `fontSize: 24`<br>`home/widgets/celebration_overlay.dart:103` `fontSize: 18` | small | **P1** |
| | | **说明**：emil P0-4 已经抽了 10 个 `textStyleXxx(context)` + 4 个 `fontSizeXxx`。剩下 18+ 处 `fontSize: 11/12/13/18/24/64` 散落。`fontSize: 64`（assessment 24h score 大数字）应叫 `textStyleScoreXxl`，`fontSize: 24`（mood 评分数字）应叫 `textStyleScoreLg` | | |
| **7.3** | **`Stack(children: [Text(label), if (saving) LoadingSpinner])` 重复 4+ 处** | `mood/mood_dialog.dart:149-165`, `medication/temp_medication_dialog.dart:128-141`, `vent/vent_compose_page.dart:418-431`, `settings/settings_page.dart:680-688` | small | **P1** |
| | | **说明**：见 A1。每处 `Stack` alignment + IgnorePointer + Spinner 颜色 + 居中都要重写 | | |
| **8. Missed opportunities** | ⭐ 3/5 | — | — | — |
| **8.1** | **settings page section 切换**（Contacts / Medications / Data / Legal / Reminders / Assessment）**没有视觉分组切换** | `lib/presentation/pages/settings/settings_page.dart:106-280` | small | **P1** |
| | | **说明**：当前 5 个 section 都用 `SizedBox(spacingLg)` 隔开 + `_SectionHeader` 文本。emil 频度判断：用户进入设置页 = occasional，但 section 之间跳读 = 没用 3D 感。可加 `AnimatedSize` 包裹 section header，点击折叠 / 展开（accordion），**既不占空间又给触感**。或者按 `_ViewToggle` 模式加 segmented button 切换（"基础 / 提醒 / 数据" 3 tab） | | |
| **8.2** | **trend 视图切换（list ↔ calendar）** 用 `SegmentedButton` | `lib/presentation/pages/trend/trend_page.dart:218-244` | — | ✓ 已优 |
| | | **说明**：emil 决策正确（10+/day 频度但切视图不同内容 = occasional）。**当前没有 fade 切换**，切换是瞬时 — 加 `AnimatedSwitcher` + `FadeTransition` 100ms 平滑更好 | | |
| **8.3** | **assessment 的 quiz → result 切换** 用了 `if (_submitted) A else B` | `lib/presentation/pages/assessment/assessment_page.dart:75-82` | small | P2 |
| | | **说明**：用户完成 9 题 → 看到结果页面，**当前瞬时切换**。emil rare 频度 → 可加 `AnimatedSwitcher` 800ms fade，让用户"享受"完成感。**但是** 精神心理患者对长时动效敏感，**fade-in 100-150ms 已足够**，800ms 会让焦虑用户等待更久。P2 而非 P0 | | |
| **8.4** | **`Stagger` 公式 token 抽出来了但只 2 处用** | `AppTokens.staggerStepMs=40, staggerCapMs=400` | `medication_calendar_page.dart:223-224`, `vent_list_page.dart:111-112` | trivial | P2 |
| | | **说明**：emil "cohesion" —— 趋势图、历史记录列表 5+ 行的 widget 都该用 stagger（如 `assessment_history_page.dart` 的 `_HistoryList`、`refill_manage_page.dart` 的 refills list）。当前 2/5+ | | |

### 组件设计问题

| # | 文件:行号 | 问题 | 修复难度 | 优先级 |
|---|----------|------|---------|--------|
| **C1** | `lib/presentation/pages/home/widgets/home_header.dart:36-50` | 3 个 IconButton 没外包 `PressFeedback`，缺 scale 反馈（tens/day 频度） | trivial | **P1** |
| **C2** | `lib/presentation/pages/mood/mood_dialog.dart:222-264` | 5 个评分按钮的"已选" 视觉突变（数字加粗 + 变绿），应 `AnimatedContainer` 包裹 100ms 过渡 | small | P2 |
| **C3** | `lib/presentation/pages/medication/medication_calendar_page.dart:147-160` | `_HeaderRow` 在 build 内每次都 `_dayLabel(i)` 重算（O(days) 字符串拼接），可 `useMemo` 缓存 | trivial | P3 |
| **C4** | `lib/presentation/pages/assessment/assessment_widgets.dart:139-156` | `QuestionCard` 的 `Semantics` label 硬编码中文"评估题 1: ..., 4 项单选, 当前: xxx" — 不可本地化 | small | P2 |
| **C5** | `lib/presentation/pages/check_in/check_in_button.dart:107-216` | `_StreakCounter` 是 100+ 行的 private widget，混在公开 widget 文件里 — 应抽 `widgets/streak_counter.dart`（参考 `SecondaryButton` 抽离模式） | small | P2 |
| **C6** | `lib/presentation/pages/medication/widgets/medication_report_dialog.dart:160-180` | PDF 加载的全屏 `Colors.black54` 遮罩 — dark mode 看起来反差过强。emil "translucent material" — 改 `Colors.black.withValues(alpha: 0.5)` 配 blur 20 更好 | small | P2 |
| **C7** | `lib/presentation/pages/vent/vent_list_page.dart:208-225` | `_EntryCard` 的 `Hero(tag: 'vent-avatar-${entry.id}')` 包了 `CircleAvatar` 但**外层还有 ListTile** — 在 push 动画时 ListTile 的 tween 会跟 Hero 互相干扰（flutter 1.20+ 已知行为，Hero 跟 page transition 偶尔错位） | — | ✓ 已优 |
| **C8** | `lib/presentation/pages/trend/trend_calendar.dart:65-110` | `_CalendarCell` 整块用 `Material` + `InkWell` + `Stack` 3 层嵌套，可改 `Material(child: InkWell(borderRadius, child: Stack))` 优化 | trivial | P3 |
| **C9** | `lib/presentation/pages/medication/medication_calendar_page.dart:174-181` | `_CellBox` 完全没 `onTap`（cell 不可点，纯粹展示） — 但写了 `Material + InkWell` 是惯例，OK | — | ✓ OK |
| **C10** | `lib/presentation/pages/medication/refill_manage_page.dart:120-128` | 空状态用 `Text(medsNoMedicationsAdded)` 跟 P0-11 修复规则不一致 — 应改 `EmptyState`（参考 `medication_calendar_page.dart:115-127` 已示范） | trivial | P2 |

### 看不见的细节（缓动/duration/shadow/overshoot/interruptibility）

| # | 文件:行号 | 问题 | 修复难度 | 优先级 |
|---|----------|------|---------|--------|
| **D1** | `lib/core/theme/app_theme.dart:128-129` | `ElevatedButton` 主题硬编码 `elevation: 0` — 但 `_elevatedButtonTheme` 没设 `shadowColor` / `surfaceTintColor` — M3 默认值在 dark mode 可能过亮 | trivial | P3 |
| **D2** | `lib/core/theme/app_tokens.dart:268-300` | `shadowCard` / `shadowCardDark` / `shadowDialog` / `shadowOverlay` 都是 `Color(0x14/0x1F/0x33/0x14 000000)` 黑色 — **dark mode 下黑色阴影不可见**。M3 dark elevation 应该是 `colorScheme.shadow` + tint（`Color(0x33FFFFFF)` 反白） | small | P2 |
| | | **说明**：emil "cohesion" + "translucent material"。v0.22 round 30 已经抽了 3 个 shadow token，但**色值还都是黑色** — 暗色下投影 = 没有。修：dark mode 用反白 `Color(0x33FFFFFF)` 30% 不透明 | | |
| **D3** | `lib/presentation/pages/home/widgets/celebration_overlay.dart:30-34` | `_scale` 第一段用 `Curves.easeOutBack`（overshoot 1.2x）— emil "rare 频度可加 delight" ✓。但**没走 token**（`AppTokens.curveDelight=elasticOut` 已经是更夸张的曲线，可选其一）| trivial | P3 |
| **D4** | `lib/presentation/pages/check_in/check_in_button.dart:32-60` | `AnimatedContainer` + `AnimatedSwitcher` 用了 `durNormal` (300ms) — emil "occasional" 频度正好。但 2 个嵌套动画**没有 stagger**（背景色变 + 文字 scale 是同步），可让 scale 比背景色晚 50ms 进入 | trivial | P3 |
| **D5** | `lib/presentation/pages/setup/setup_page.dart:96-129` | `AnimatedSwitcher` 在 setup 4 step 切换 — **standard duration 300ms + accelerate exit** — 完美。**但 layoutBuilder 自定义**（line 119-127），效果是 stack 上下层叠，emil 默认 `layoutBuilder` 行为就是 stack，**这个自定义没改任何东西**。可简化 | trivial | P3 |
| **D6** | `lib/presentation/pages/medication/medication_calendar_page.dart:81-110` | `RefreshIndicator` onRefresh 完后 `Future.delayed(400ms)` — 拖延 400ms 是 emil "perceived performance" 反例（系统自带转场已经够"loading"感） | trivial | P3 |
| **D7** | `lib/presentation/pages/assessment/assessment_page.dart:97-122` | `LinearProgressIndicator` 显示答题进度 — 但**没有 number tween 动画**（"已答 3/9" 文字变化瞬时），加 `AnimatedSwitcher` 50ms fade 更好 | trivial | P3 |
| **D8** | `lib/presentation/pages/medication/widgets/medications_list_widget.dart:114-117` | 列表顶部 "用药日历入口" `ListTile` **没外包 PressFeedback**（已在 P0-9 batch 内修过 settings 4 个 section，但漏了这个） | trivial | P2 |
| **D9** | `lib/presentation/pages/vent/vent_detail_page.dart:259-264` | audio `Slider` 没自定义 thumb shape — 默认 M3 圆形。emil 设计上 thumb 应该是 pill shape (`SliderTheme`)，**但 Material 标准可接受** | — | ✓ OK |
| **D10** | `lib/presentation/pages/trend/trend_calendar.dart:282-300` | "已打卡/未打卡" chip 用 `fontSize: AppTokens.fontSizeMicro (10)` 但 `fontWeight: FontWeight.w500` — emil 10px 是极限可读尺寸，w500 + size 10 偏粗 | trivial | P3 |
| **D11** | `lib/presentation/pages/assessment/assessment_widgets.dart:67-78` | "对比上次" 数字 32px `TextStyle(fontSize: 32, fontWeight: w600)` — 跟 `AppTokens.fontSizeTitle (28)` 不一致，应叫 `textStyleScoreXxl(40)` token | small | P2 |
| **D12** | `lib/core/theme/app_tokens.dart:212-218` | `radiusCell (2.0) / radiusCellLg (4.0)` 命名奇怪 — emil token 命名应该语义化（"what it's for"）。建议改 `radiusHeatmapCell = 2.0` / `radiusCalendarCell = 4.0` | trivial | P3 |

### 该加动画却没加

> emil Gate：每条都过 (1) Frequency (2) Purpose (3) Speed < 300ms (4) Function helps not hinders

| # | 位置 | 应加什么 | 修复难度 | 优先级 |
|---|------|---------|---------|--------|
| **A-opp-1** | `home_header.dart:36-50` 3 个 IconButton | 外包 `PressFeedback` 给 scale 0.97 反馈（tens/day） | trivial | **P1** |
| **A-opp-2** | `trend_page.dart` 视图切换（list ↔ calendar） | `AnimatedSwitcher` + `FadeTransition` 100ms 平滑 | small | P2 |
| **A-opp-3** | `assessment_page.dart:75-82` quiz → result 切换 | `AnimatedSwitcher` + `FadeTransition` 150ms（rare 频度） | small | P2 |
| **A-opp-4** | `mood_dialog.dart:222-264` 评分按钮"已选"态 | `AnimatedContainer` 100ms 颜色 + 字号过渡 | small | P2 |
| **A-opp-5** | `medications_list_widget.dart:114-117` 用药日历入口 | 外包 `PressFeedback` | trivial | P2 |
| **A-opp-6** | `contact/contacts_list_widget.dart:25-58` "添加联系人" 入口 | 外包 `PressFeedback` | trivial | P2 |
| **A-opp-7** | `mood_dialog.dart` 标签 `FilterChip` 选中态 | `AnimatedContainer` 100ms 边框颜色过渡 | trivial | P3 |
| **A-opp-8** | `reminders_hub_page.dart:30-180` 4 个 `_ReminderCard` 入口 | 外包 `PressFeedback` 给 scale 反馈（用户日常点进来） | small | P2 |
| **A-opp-9** | `assessment_page.dart:97-122` 进度文字 "已答 3/9" | `AnimatedSwitcher` 50ms fade 让数字变化可感知 | trivial | P3 |
| **A-opp-10** | `setup/setup_step_consent.dart` 3 个勾选行 | `AnimatedContainer` 100ms 背景色（`primaryLightColor` ↔ `surfaceColor`）过渡 — 当前瞬时 | small | P2 |
| **A-opp-11** | `home_page.dart:225-227` `EncouragementText` streak 变化时 | 保留 MotionScheme.none 决定（100+/day），**但**加 `AnimatedSwitcher` 100ms 让 streak 1→2→3 文案变化可感知 | trivial | P3 |

### 该删/弱化的动画

| # | 位置 | 当前动画 | 建议 | 修复难度 | 优先级 |
|---|------|----------|------|---------|--------|
| **D-elim-1** | `lib/presentation/pages/check_in/check_in_button.dart:32-33` | `AnimatedContainer` `durNormal=300ms` 切换 checked/unchecked 背景色 | 改 `durFast=200ms` — emil "occasional" 上限 250ms | trivial | P3 |
| **D-elim-2** | `lib/presentation/pages/check_in/check_in_button.dart:53-64` | `AnimatedSwitcher` 文字 scale + fade 300ms | emil "occasional" 上限 250ms — 改 durFast 200ms | trivial | P3 |
| **D-elim-3** | `lib/presentation/pages/setup/setup_page.dart:96-129` | 4 step 切换 `AnimatedSwitcher` 300ms | ok, but consider 250ms（用户 onboarding = rare 频度，可加 50ms 富余 = 350ms 不动） | — | ✓ OK |
| **D-elim-4** | `lib/presentation/pages/home/widgets/celebration_overlay.dart:25-58` | `MotionScheme.delight = durSlow=500ms` 庆祝 overlay | **保留**（rare 频度 delight 时刻），但 overlay 总显示时长 `celebrationDisplayMs=1800` 可能偏长（用户需要 1.8s 读完） | — | ✓ OK |
| **D-elim-5** | `lib/core/theme/app_theme.dart` `themeAnimationDuration: AppTokens.durNormal` 主题切换动画 | **保留** — emil "occasional"，1% 用户每天切 1 次 | — | ✓ OK |
| **D-elim-6** | `lib/presentation/pages/trend/trend_calendar.dart:259` `AnimatedSize` on `NotificationStatusCard` 状态文字 | **保留** | — | ✓ OK |
| **D-elim-7** | `loading_skeleton.dart:120-123` shimmer 1.2s 永久循环 | **删除**（reduce-motion 直接停）— 但在普通模式下 1.2s 循环是业界标准。可接受 | — | ✓ OK |
| **D-elim-8** | `lib/presentation/pages/medication/medication_calendar_page.dart:218-227` `FadeIn` stagger 最多 400ms (10 行) | 10 行 × 40ms = 400ms 用户等不了。**改 cap 200ms** (5 行后立即出现)，5+ 行用户已经看到第一行就足够 | small | P2 |

---

## 汇总统计

- **总问题数**: 41
- **P0**: 0 个（无必修，未发现影响 80% 用户日常体验的 feel-breaking 回归 — 项目 v0.22 round 30 已经过 30 轮打磨）
- **P1**: 7 个（应修，显著提升品质）
  - C1 home_header 3 个 IconButton 缺 scale
  - 3.1 vent compose 三态切换无 origin 锚定
  - 7.1 15+ 处 `Colors.white/black` 散落（dark mode 反白失效）
  - 7.2 18+ 处 `fontSize` 硬编码 token 化漏网
  - 7.3 `Stack([Text, if saving Spinner])` 重复 4+ 处
  - 8.1 settings section 视觉分组切换
  - A-opp-1 同 C1
- **P2**: 17 个（可修，锦上添花）
- **P3**: 17 个（nice-to-have）

### 按类型分布
- 组件设计: 10 (C1-C10)
- 8 维度动画: 13 (1.x ~ 8.x)
- 不可见细节: 12 (D1-D12)
- 该加: 11 (A-opp-1~11)
- 该删/弱化: 8 (D-elim-1~8)
- 顶层架构: 5 (A1-A5)
- 可重构: 7 (R1-R7)

### 按修复成本
- **trivial** (1h-): 19 个（其中 9 个是一行 grep 替换）
- **small** (1-4h): 19 个
- **medium** (4-8h): 3 个
- **large** (8h+): 0 个

---

## 关键观察

### 1. 这是一个 v0.22 round 30 的成熟项目，"动画/动效 token 化"已接近天花板

`app_tokens.dart` 548 行覆盖动效 95% / 文字 60% / 颜色 90% / 间距 100% / 圆角 100% / 阴影 100% / 行高 100%。**对 emil 标准而言**这个项目已经过了"good defaults"门槛，新手也能写出统一风格的代码。**剩余 5-10% 优化都是细节**（4.1%）或可读性（C5 / C10）问题，不是"差一口气"那种 feel-breaking。

### 2. 真正的"差一口气"集中在 1 个 P1 + 1 个 P1-batch

- **C1 / A-opp-1**（P1）：`home_header.dart:36-50` 3 个 IconButton 缺 `PressFeedback`。这是 home page 的 3 个核心入口（趋势 / 评估 / 设置），tens/day 频度，按 emil 原则**必须有 scale 反馈**。**已修过 secondary_action_row（emil-28）但漏了 home_header**。
- **7.1 + 7.2 + 7.3**（P1 批量）：13+ 处 `Colors.white` 反白失效 + 18+ 处 `fontSize` 硬编码 + 4+ 处 `Stack([Text, Spinner])` 重复 — 这是一个**单 round 集中清理**就能消化的 35 个低垂果实。

### 3. `app_tokens.dart` 已有的"抽 token"模式在 widget 层还没落地

`AppTokens.fgOnXxx`（round 30 emil P2-6 抽的）**已存在**但还没被 13+ 处调用，**说明 v0.22 round 30 在最后时刻加了 token 但没回头改**。这是 emil 原则 2 "good defaults matter more than options" — **默认就该用 token，存量代码迁移是 1 小时的 grep 任务**。

### 4. 不可见细节（`D1-D12`）整体水准很高，但 `shadowXxx` 暗色模式集体失效是 1 个 P2

emil "translucent material" 哲学：暗色下阴影应该反白。当前 `shadowCard / shadowCardDark / shadowDialog / shadowOverlay` 都用 `Color(0x14/0x1F/0x33/0x14 000000)` 黑色 — 暗色 mode 下**全部看不到**。这个不是新发现，但跟"反白失效"是同源问题（dark mode support 不完整）。**修法**：dark mode 用 `Color(0x33FFFFFF)` 反白 + alpha 30%。

### 5. 精神心理患者"前庭敏感"是这个项目的隐含约束

`Motion.duration` / `Motion.curve` 全项目覆盖 `prefers-reduced-motion`（P0-7）— **这个是为数不多 Flutter 项目会为前庭敏感用户做 a11y 适配**。`celebrationDisplayMs=1800`（emil P2-8 抽的）也比一般 app 短（一般 2-3s），给用户更短反馈窗口。**这是品味上的可学习点**。**新增动效时**（比如未来加 home 引导 onboarding）要保持这个标准 — **不要 800ms+ 的 bouncy spring**。

### 6. 8 维度动画审计的"亮点"

- **Dimensionality 1 (Purpose & frequency)**: 5/5 — `MotionScheme` enum + 频度注释贯穿全代码
- **Dimensionality 6 (Accessibility)**: 5/5 — `prefers-reduced-motion` + `Semantics(liveRegion: true)` 在 streak counter
- **Dimensionality 7 (Cohesion)**: 4.5/5 — token 化覆盖 95%，但有 13+ 处 `Colors.white` + 18+ 处 `fontSize` 漏网

### 7. Round 31 建议

**P1 集中清理**（1 个 round 完成所有 P1）：
1. `home_header.dart` 3 个 IconButton 外包 `PressFeedback`（10 分钟）
2. `grep -nE "Colors\.(white|black)" lib/presentation` → 13+ 处替换为 `AppTokens.fgOnXxx(context)`（30 分钟）
3. `grep -nE "fontSize: [0-9]+,?" lib/presentation` → 18+ 处替换为 `AppTokens.textStyleXxx(context)` 或新增 2-3 个 token（60 分钟）
4. 抽 `widgets/loading_text_button.dart` 替换 4+ 处 `Stack([Text, Spinner])` 模式（30 分钟）
5. 抽 `widgets/chip_badge.dart` 替换 6+ 处 colored container chip（30 分钟）
6. 修 `AppTokens.shadowXxx` dark mode 反白（30 分钟）

**总耗时**：3.5 小时，**消除 6 个 P1 + 提升 5 个 P2 → P3**。

---

> **审查完毕**。项目总体：**V 级别 UI 工程质量**（v0.22 round 30 顶配），剩余问题**全 P1 起步**，无 P0 必修。
> **最关键 1 个建议**：`home_header.dart` 3 个 IconButton 缺 `PressFeedback`——10 分钟修完，立即生效。
> **最大批量收益**：1 个 round 集中清理 13+ 处 `Colors.white` + 18+ 处 `fontSize` 硬编码。
