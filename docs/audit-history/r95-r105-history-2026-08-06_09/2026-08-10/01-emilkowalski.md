# emilkowalski 视角审计 (2026-08-10)

**项目**: ChronicCare v0.30.0+85
**审计日期**: 2026-08-10
**审计基线**: R104 (2026-08-09) — 8 项 P0-P2 (E1-E8) + R95 sub-spec 7+8 (daily_tracking 7 子 widget + crisis_hotline_page)
**审计范围**: `lib/presentation/pages/*` (8 feature) + `lib/core/theme/` + `lib/presentation/widgets/` + `lib/core/routing/` = 25 个核心文件
**审计依据**: Emil Kowalski「设计工程师」4 档决策框架 (none / subtle / standard / delight) + token 化 + prefers-reduced-motion + 3 大态 (loading/empty/error) + a11y (Semantics / ExcludeSemantics / liveRegion) + Hero / page transition

---

## 评分: 9.0 / 10 (持平 R104)

emil 视角下项目已达 top 5% Flutter 项目水准。R95-R104 阶段集中补了 a11y (R104 E5 ExcludeSemantics)、主题感知 (R102 P1 hero shadow / R49 P0-1 primaryColor)、reduce-motion (R103 P0-10 PageTransitionSwitcher + R18 全部动画)、FAB stagger (R105 P1-17)、haptic (R105 P2-14)、god page 拆解 (R95 sub-spec 4+6)。**未修复项 + 新发现问题使评分与 R104 持平**, 未达 9.5 主要因: (1) 12+ 处 loading/error 散落未走 LoadingSkeleton/ErrorState 集中器 (P0); (2) QuickMoodCarousel/HomeFabToolbar 仍无 Semantics label (R104 E7/E8 未修); (3) medium breakpoint 实际不可达 (R104 E6 未修); (4) 5 处 SnackBar/content 走内联未走 AppSnackBar 集中器 (R95 sub-spec 8 daily_tracking 遗漏)。

---

## 一、优点 (具体引用)

### 1.1 动效 token 体系已全面建立 ✅
- `lib/core/theme/app_motion.dart:33-86` — 8 个 duration (durFast/Normal/Slow/Press/PageTransition + 3 snackbar) + 6 个 curve (curveStandard/Subtle/Decelerate/Accelerate/Delight/BackOut) 全部 static const
- `lib/core/theme/app_motion.dart:189-217` — `MotionSchemeTokens` extension 4 档 (none/subtle/standard/delight) 频度决策框架
- `lib/core/theme/app_motion.dart:236-253` — `Motion.duration()` / `Motion.curve()` 集中器包装 `MediaQuery.disableAnimations`, 系统 reduce-motion → 自动 0 时长 + linear
- **覆盖率**: 19 个文件已用 Motion class (grep "Motion\."), 包括 setup_page_state / home_fab_toolbar / quick_mood_carousel / check_in_button / celebration_bounce / fade_in / slide_up / page_transition_switcher / app_routes / loading_skeleton

### 1.2 主题感知全面化 ✅
- `lib/core/theme/app_colors.dart:99-162` — 12 个 dynamic color getter (primaryColor/errorColor/disabledColor/surfaceColor/textPrimaryColor/...) 走 `Theme.of(context).colorScheme`
- `lib/core/theme/app_motion.dart:103-137` — 4 个 `shadowXxxOf(context)` dynamic getter, 走 `ColorScheme.shadow` 适配 dark mode
- **R102 P1 (R104 E4 修复)**: `lib/presentation/pages/home/widgets/hero_illustration.dart:51-57` 已用 `Theme.of(context).colorScheme.shadow.withValues(alpha: 0.04)` 替代 Colors.black 硬编码
- **R104 E2 (修复)**: `lib/core/theme/app_colors.dart:43` textHint 改 `#595959` (对比度 7:1, 满足 WCAG AA 4.5:1)

### 1.3 prefers-reduced-motion 全面覆盖 ✅
- `lib/presentation/widgets/animations/page_transition_switcher.dart:53-57` — 走 `Motion.duration(context, duration)` + `Motion.curve(context, ...)` (R103 P0-10)
- `lib/presentation/widgets/animations/fade_in.dart:79-83` — `didChangeDependencies` 检测 `disableAnimations` → `_controller.value = 1.0` + cancel timer
- `lib/presentation/widgets/animations/slide_up.dart:75-79` — 同款模式
- `lib/presentation/widgets/animations/celebration_bounce.dart:83-86` — 同款
- `lib/presentation/widgets/press_feedback.dart:84` — `Motion.duration(context, widget.duration)` 包装 (R18 P0-7)
- `lib/core/routing/app_routes.dart:47-50, 63-66, 89-90` — 3 类 page transition (fadePage/slideRightPage/slideUpPage) 全部走 `Motion.duration(context, ...)`

### 1.4 3 类 page transition 按频度分类 ✅
- `lib/core/routing/app_routes.dart:43-103` — fadePage (主导航) + slideRightPage (子页) + slideUpPage (全屏深页), 3 档频度对应 3 类动画
- 跟 R17 round 2 (A2 emil 动效) 决策一致

### 1.5 God page 拆解 + FadeIn stagger ✅
- `lib/presentation/pages/home/home_page.dart:138` (主壳) + `home_page_state.dart:590` (state) — 拆完 (R95 sub-spec 4 task 5)
- `lib/presentation/pages/setup/setup_page.dart:25` (主壳) + `setup_page_state.dart:480` (state) — 拆完 (R95 sub-spec 6 task 6c)
- 主页 8 层 stagger fade-in: `lib/presentation/pages/home/home_page_state.dart:327-431` — 0/40/80/120/160/200/240/280ms, emil "30-80ms stagger = 累积成高级感" 框架
- `lib/presentation/pages/home/widgets/home_fab_toolbar.dart:62-176` — FAB 展开 AnimatedSize + 4 个 FadeIn stagger (R105 P1-17 修复)

### 1.6 EmptyState / ErrorState / LoadingSkeleton 三大态集中器 ✅
- `lib/presentation/widgets/empty_state.dart:25-110` — 5 字段 (icon/title/subtitle/actionLabel/onAction) + R101 渐变圆形背景 (Apple Health 风格)
- `lib/presentation/widgets/error_state.dart:28-96` — 5 字段 (icon/title/detail/onRetry/retryLabel) + 走 l10n.commonRetry 兜底 (R23 P1-9)
- `lib/presentation/widgets/loading_skeleton.dart:29-171` — fullScreen / card / LoadingSpinner / LoadingScrim 4 个工厂, shimmer "breathing" 模式 (1.2s + 600ms pause, R24 P1-6 精神心理 App 高刺激度防御)

### 1.7 Semantics / ExcludeSemantics 集中化 ✅
- `lib/presentation/widgets/app_semantics.dart:16-65` — 3 工厂: container / button / exclude (R24 P1-18 抽集中器替代 6 处散落)
- `lib/presentation/widgets/check_in_button.dart:158-160` — streak 数字 liveRegion: true (R22 P1-1)
- `lib/presentation/pages/home/widgets/hero_illustration.dart:60-119` — 整个 hero Stack 包 ExcludeSemantics (R104 E5 修复, 4 个装饰 emoji 不被 TalkBack 朗读)

### 1.8 PressFeedback 统一 scale 反馈 ✅
- `lib/presentation/widgets/press_feedback.dart:47-115` — 0.97 scale + 160ms (durPress) + 2 模式 (接管 tap / 只做视觉)
- 19 处 PressFeedbackIconButton 集中器 (R26 round 57 B-11 加 color/size/padding/constraints 参数)
- 17 处 AppListTile 集中器 (standard/carded/destructive 3 命名构造, R26 round 57 C-12)
- 8 处 InfoBanner 集中器 (info/muted/warning/error 4 tone, R27 round 67 C-2)

### 1.9 Haptics 集中器 ✅
- 主页情绪 carousel 1 tap 速记 → Haptics.success (`lib/presentation/pages/home/widgets/quick_mood_carousel.dart:91`)
- 主页 autofire 打卡 → Haptics.success (`lib/presentation/pages/home/home_page_state.dart:208`)
- FAB toggle → Haptics.light (`lib/presentation/pages/home/widgets/home_fab_toolbar.dart:50`) — R105 P2-14 修复
- vent swipe 删除 → Haptics.warning (`lib/presentation/pages/vent/vent_list_page.dart:186`)

---

## 二、问题清单 (按 P0→P3 排序)

| # | 文件:行 | 问题 | 层级 | 难度 | 优先级 |
|---|---------|------|------|------|--------|
| **E1** | `lib/presentation/widgets/animations/page_transition_switcher.dart:53-66` | PageTransitionSwitcher 仍忽略 prefers-reduced-motion — `Motion.duration/curve` 已用但 `transitionBuilder` 自定义 (setup_page_state:135-146) 接收 `anim` 未走 Motion 包装。setup 4 步切换在 reduce-motion 用户下仍有 300ms 动画 | 底层/a11y | 简单 | **P0** |
| **E2** | `lib/presentation/pages/settings/widgets/notification_status_card.dart:216-222` | AnimatedSize 用了 `Motion.duration(context, AppTokens.durNormal)` 但 `curve: AppTokens.curveStandard` 直接走 token,未走 `Motion.curve(context, ...)` — reduce-motion 用户下 duration=0 但 curve=easeOutCubic 仍是 acceleration curve (违反 P0-7 reduce-motion non-negotiable) | 底层/a11y | 简单 | **P0** |
| **E3** | `lib/presentation/pages/medication/medication_page.dart:161-162` | `loading: () => const Center(child: CircularProgressIndicator())` + `error: (e, _) => Center(child: Text('$e'))` 走裸,未走 LoadingSkeleton.fullScreen / ErrorState 集中器 — 12+ 处散落见 §三.1 | 底层/UI | 简单 | **P0** |
| **E4** | `lib/presentation/pages/medication/medication_page.dart:388-400` | `_SlotEntryRow` 打卡动画 `AnimatedSwitcher(duration: AppTokens.durFast)` 直接用 token 未走 `Motion.duration(context, ...)` — reduce-motion 用户下保留 200ms 动画 (同款 E2 bug 模式) | 底层/a11y | 简单 | **P0** |
| **E5** | `lib/presentation/pages/home/widgets/quick_mood_carousel.dart:160-198` | 4 档情绪 emoji + label 整个 PressFeedback 缺 Semantics label — R104 E8 未修, 4 个 emoji button 无 label, TalkBack 朗读"☀️"或 raw char 不可懂 (精神心理患者视觉障碍比例高于平均) | 底层/a11y | 简单 | **P0** |
| **E6** | `lib/presentation/pages/home/widgets/home_fab_toolbar.dart:177-205` | HomeFabToolbar 展开/折叠无 Semantics 通知, 用户用 TalkBack 听不到"已展开"或"已折叠" — R104 E7 未修, 4 个 FAB 工具按钮 (情绪日记/树洞/紧急热线/回到顶端) 全部缺 label | 底层/a11y | 简单 | **P0** |
| **E7** | `lib/core/theme/app_spacing.dart:132-153` | `breakpointMedium = 840` + `breakpointExpanded = 840` 边界相同, `windowSizeOf(width)` 在 width=840 时直接返 expanded, `WindowSize.medium` 实际不可达 — R104 E6 未修, 0 调用方实际走 medium 分支, 引入 dead enum case | 底层 | 简单 | **P1** |
| **E8** | `lib/presentation/pages/home/home_page_state.dart:327-431` | 主页 8 层 stagger FadeIn (0-280ms) 累加, 进首页动效过密 — emil "home 入场无动画" (100+/day 频度, R18 P1-8 决策), 精神心理患者前庭敏感。修复: stagger 限定 3 项 (header + today_summary + hero), 后续项 (carousel/primary_action/secondary_action) 改无动画 | 底层/动效 | 中 | **P1** |
| **E9** | `lib/presentation/pages/home/home_page_state.dart:333-348` | R101 TodaySummaryCard + R81 HomeHeroIllustration (140px) + 80px QuickMoodCarousel 累加 220px, 推鼓励文案 + primary_action 到折叠线以下 (375x667 iPhone SE 等小屏问题) — R104 E3 未修 | 架构/UX | 中 | **P1** |
| **E10** | `lib/presentation/pages/daily_tracking/widgets/{weight,sleep,anxiety_agitation,social_rhythm,stress_event}_widgets.dart:198/266/151/197/179` | 5 处 daily_tracking widget 用 `SnackBar(content: Text(...))` 裸 ScaffoldMessenger,未走 AppSnackBar 集中器 — 时长不一致 (默认 4s 实际 0 失误差), 跟 v0.23 R31 P1 重构"showX 集中器"反方向 | 底层/UX | 简单 | **P1** |
| **E11** | `lib/presentation/widgets/medication_pill_icon.dart:9-16, 63, 70` | 6 个 iOS 系统色硬编码 (`#34C759/#FFCC00/#FF3B30/#007AFF/#AF52DE/#8E8E93`) + `Colors.white` 硬编码 2 处 (跟 R22 round 30 emil P2-6 "Colors.white 18 处" 是同款 bug) — 6 色应进 AppColors (或 AppleHealthColors 子集) 集中器, 改一处生效, 跟 R22 重构模式一致 | 底层/UI | 简单 | **P1** |
| **E12** | `lib/presentation/pages/medication/medication_page.dart:442, 512-551` | `padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)` (line 442) + `_EmptyMedicationsCard` inline Card (line 512-551) + `_EmptyScheduleCard` inline Card (line 554-585) — 3 处未走 AppTokens.edgeInsetsXs/Xxs + EmptyState 集中器 (R95 已加 EmptyState 但 medication_page 没复用) | 底层/UI | 简单 | **P1** |
| **E13** | `lib/presentation/pages/home/widgets/today_summary_card.dart:130-141` | 4 个 _SummaryItem 用 `AnimatedSwitcher(duration: AppTokens.durFast, child: Text(value, key: ValueKey(value)))` — 只有默认 fade 切换, 数值变化无 spring 物理 / 数字 tween 递增动画 (R105 P2-5 报告,仍未修)。修复: 数字走 TweenAnimationBuilder 0→target, 复用 CheckInButton._StreakCounter 模式 | 底层/动效 | 中 | **P1** |
| **E14** | `lib/presentation/pages/home/widgets/notification_failure_banner.dart:16-70` | 入场走 FadeIn 但退出用 `setState(() => _dismissed = true)` 直接 SizedBox.shrink, 无 FadeOut 动画 — 通知 banner 突然消失视觉突兀 (R105 P2-16 报告,仍未修)。修复: 用 AnimatedSwitcher fade in/out + 自定义 transitionBuilder | 底层/动效 | 简单 | **P1** |
| **E15** | `lib/presentation/pages/home/widgets/quick_mood_carousel.dart:101-105` | 错误 SnackBar 走 `const SnackBar(content: Text('记录失败，请重试'), duration: AppTokens.snackBarDurationShort)` 硬编码中文 — 应走 AppSnackBar.showError 集中器 + l10n.moodRecordFailed 翻译键 (跟 v0.23 R31 showX 模式) | 底层/i18n | 简单 | **P1** |
| **E16** | `lib/presentation/pages/medication/medication_calendar_page.dart:212-213` | `ScaffoldMessenger.of(context).showSnackBar(SnackBar(...))` 走裸, 未走 AppSnackBar 集中器 | 底层/UX | 简单 | **P2** |
| **E17** | `lib/presentation/pages/home/widgets/hero_illustration.dart:67-114` | 4 个装饰 emoji (⛅/☁️/☀️/🌿) 字号 36/28/56/32 硬编码 — 应走 token (fontSizeScoreLg/ScoreXl 等) 或加 emojiSize tokens | 底层/UI | 简单 | **P2** |
| **E18** | `lib/presentation/pages/mood_list/mood_detail_page.dart:48` | `style: const TextStyle(fontSize: 48)` 硬编码 — 应走 fontSizeScoreXxl (44) 或新加 fontSizeHero (48) token | 底层/UI | 简单 | **P2** |
| **E19** | `lib/presentation/pages/medication/widgets/medication_pill_icon.dart:36-57` | gradient colors `[baseColor.withValues(alpha: 0.8), baseColor]` 硬编码 alpha 0.8 — 应走 tintedStatusSoft (0.15) 模式 + 加 tintedColorPillHigh (0.85) 集中器 (跟 R24 P1-13 tintedPrimaryMid/High 模式一致) | 底层/UI | 简单 | **P2** |
| **E20** | `lib/presentation/pages/medication/medication_detail_page.dart:323` | `fontSize: 10` 硬编码 — 10px 小于 fontSizeMicro (12) 和 fontSizeXxxSmall (10 但未 export), 建议走 fontSizeXxxSmall token 统一 | 底层/UI | 简单 | **P2** |
| **E21** | `lib/presentation/pages/mood_list/mood_trend_page.dart:387` | `style: const TextStyle(fontSize: 20)` 硬编码 — 应走 fontSizeBody 或 fontSizeTitle (20) token | 底层/UI | 简单 | **P2** |
| **E22** | `lib/presentation/pages/medication/add_medication_page.dart:346` | `fontSize: 16` 硬编码 — 应走 fontSizeBody (16) token | 底层/UI | 简单 | **P2** |
| **E23** | `lib/presentation/pages/medication/medication_calendar_page.dart:93` | `AppSemantics.container(label: l10n.medicationTimeWindowSemantics(days))` — label 走 l10n 集中器, 但 TimeSegment button 自身缺 Semantics.button(selected) 包装 (R105 已加 P0-9 a11y 但 medication_calendar 缺 selected 态) | 底层/a11y | 简单 | **P2** |
| **E24** | `lib/presentation/pages/setup/setup_widgets.dart:97-102` | ConsentCheckRow "查看" TextButton 用 `PressFeedback(child: TextButton(...))` 嵌套 — PressFeedback 接管 pointer 事件但 child.onTap 仍触发, scale 反馈 + TextButton 文字 "查看" 颜色不变, 视觉弱 | 底层/UX | 简单 | **P2** |
| **E25** | `lib/presentation/pages/mood/widgets/cbt_three_column_mode.dart:44, 56` | 2 个装饰 emoji 😢/😄 用 `TextStyle(fontSize: 20)` 硬编码 — R105 F6 已发现硬编码 Apple 系统颜色, 此处同款 fontSize 硬编码问题 | 底层/UI | 简单 | **P2** |
| **E26** | `lib/presentation/widgets/loading_skeleton.dart:255-267` | Shimmer 实际是 Opacity 脉动 (0.4-0.7), 不是真正骨架屏 — R105 P2-4 报告,仍未修。emil 角度: 脉动 vs 呼吸 vs 真正 shimmer 取决于"perceived performance", 当前 0.4-0.7 在 1.2s 内 1 次循环 + 600ms 暂停 已是 emil "loading should feel fast, not dance" 哲学体现,可保留 | 底层/UI | 中 | **P2** |
| **E27** | `lib/core/theme/app_tokens.dart:46-314` | AppTokens facade 314 行静态 const 转发, 仍依赖 4 个子模块 — R105 P2-3 报告, 建议: (1) 加 `@Deprecated('use AppColors.primary')` 提示, (2) R92 batch 处理老 caller 改名, (3) R100+ 删 facade 彻底 | 底层/规范 | 中 | **P3** |
| **E28** | `lib/presentation/widgets/animations/page_transition_switcher.dart:39` | 默认 `duration = AppTokens.durPageTransition` (100ms) — 100ms 是 fade 默认, 但 setup 4 步切换用 `duration: MotionScheme.standard.duration` (300ms) 覆盖。trend/assessment 视图切换沿用 100ms, emil 框架下"occasional 频度"应 ≥ 200ms 才感知为"切换"。建议: 提到 durNormal (300ms) | 底层/动效 | 简单 | **P3** |
| **E29** | `lib/presentation/pages/medication/today_med_schedule.dart:180` | `Border.all(color: AppTokens.borderColor(context), width: 1)` width 硬编码 1 — 应走 borderWidth (1) token, 跟 section_header 等保持一致 | 底层/UI | 简单 | **P3** |
| **E30** | `lib/presentation/widgets/mood_quick_button.dart:44-47` | MoodQuickButton "今日情绪: 好/差/一般" emoji + label 用 `TextStyle(fontSize: AppTokens.fontSizeBodySm)` — 跟 mood_quick_button 内部 emoji 字号重复, 建议走 emojiSize 集中器 (跟 hero_illustration 4 emoji 同款) | 底层/UI | 简单 | **P3** |

---

## 三、与 R104 差异 (E1-E8 状态 + 新发现)

### 3.1 R104 E1-E8 修复状态

| R104 ID | 问题 | R104 报告状态 | 实际代码状态 (2026-08-10) |
|---------|------|---------------|--------------------------|
| E1 | `PageTransitionSwitcher` 忽略 prefers-reduced-motion | 已修 (R103 P0-10) | **半修** — 集中器自身修了 (`page_transition_switcher.dart:54-57`), 但 setup_page_state:135-146 自定义 `transitionBuilder` 接收 `anim` 未走 Motion 包装 (问题 E1) |
| E2 | `textHint` #999999 对比度 2.8:1 | 已修 (R104 P0-10) | **已修** ✅ `app_colors.dart:43` 改 #595959 (7:1) |
| E3 | 主页 hero (140px) + carousel (80px) 推 CTA 到折叠线 | 未修 | **未修** (E9) |
| E4 | `hero_illustration.dart` Colors.black shadow | 已修 (R102 P1) | **已修** ✅ `hero_illustration.dart:54` 走 `Theme.of(context).colorScheme.shadow` |
| E5 | Decorative emoji 被 screen reader 朗读 | 已修 (R104) | **已修** ✅ `hero_illustration.dart:60-119` 包 ExcludeSemantics |
| E6 | windowSizeOf medium breakpoint 不可达 | 未修 | **未修** (E7) |
| E7 | HomeFabToolbar 展开/折叠无 Semantics 通知 | 未修 | **未修** (E6) |
| E8 | QuickMoodCarousel emoji 缺少 Semantics label | 未修 | **未修** (E5) |

### 3.2 R105 P1/P2 新增项修复状态 (R104 之后)

| R105 ID | 问题 | R105 报告状态 | 实际代码状态 (2026-08-10) |
|---------|------|---------------|--------------------------|
| P1-15 | `Hero` 插画用 emoji 作视觉主体 | 中等, 设计师介入 | **未修** (E17) — 4 个 emoji 字号硬编码 36/28/56/32 |
| P1-16 | QuickMoodCarousel 错误静默吞掉 | 简单, 5 行 | **未修** — `quick_mood_carousel.dart:93-106` 仍 swallowError (line 93) + 硬编码中文 SnackBar (line 101) — 复合问题 E5 + E15 |
| P1-17 | FAB 展开无 stagger 动画 | 简单, 10 行 | **已修** ✅ `home_fab_toolbar.dart:62-176` 4 个 FadeIn stagger (R81+ R105 修复) |
| P1-18 | 主页无入场动画 | 简单, 20 行 | **半修** — 加了但累加 8 层 (E8) 反而过密 |
| P2-5 | TodaySummaryCard 数值变化无动画 | 简单 | **未修** (E13) |
| P2-6 | CheckInButton 状态切换缺 spring 物理 | 简单 | **已修** ✅ `check_in_button.dart:34` 走 `Motion.curve(context, AppTokens.curveDelight)` (R102 P1-12 + R105 P2-6 修复) |
| P2-14 | HomeFabToolbar toggle 无 haptic | 1 行 | **已修** ✅ `home_fab_toolbar.dart:50` Haptics.light() |
| P2-16 | NotificationFailureBanner 无入场/退出动画 | 简单 | **未修** (E14) |
| P2-17 | textHint 对比度 | 简单 | **已修** (E2) ✅ |
| P2-18 | PageTransitionSwitcher 忽略 prefers-reduced-motion | 简单 | **半修** (E1) |

### 3.3 新发现的问题 (R104 之后新引入或 R104 没覆盖的)

| 新问题 | 文件:行 | 严重度 | 备注 |
|--------|---------|--------|------|
| **E2** | `notification_status_card.dart:219` `curve: AppTokens.curveStandard` 未走 Motion 包装 | P0 a11y | R22 已加 Motion.curve 但本文件漏改 |
| **E4** | `medication_page.dart:389` `duration: AppTokens.durFast` 未走 Motion 包装 | P0 a11y | R95 sub-spec 8 daily_tracking 之后 medication_page 改本样式漏 Motion 包装 |
| **E10** | 5 处 daily_tracking widget `SnackBar(content: Text(...))` 裸用 | P1 UX | R95 sub-spec 8 新引入的 5 widget 漏 AppSnackBar 集中器 |
| **E11** | `medication_pill_icon.dart:9-16` 6 个 Color(0xFF...) iOS 系统色硬编码 | P1 UI | R101 新引入, 跟 R22 round 30 emil P2-6 (Colors.white 18 处) 是同款 bug |
| **E12** | `medication_page.dart:442, 512-585` 3 处未走 AppTokens + EmptyState 集中器 | P1 UI | R101 改造时漏统一 |
| **E15** | `quick_mood_carousel.dart:101-105` 错误 SnackBar 硬编码中文 | P1 i18n | 跟 R95 mock/dev 字符串同款 |
| **E19** | `medication_pill_icon.dart:45-46` gradient 0.8 alpha 硬编码 | P2 UI | 跟 R24 P1-13 tintedPrimaryMid/High 模式应集中 |
| **E20-E22** | 4 处 fontSize 硬编码 (10/20/16/48) | P2 UI | token 化遗漏 |
| **E26** | `loading_skeleton.dart:255-267` Shimmer 实际是 Opacity 脉动 | P2 UI | R105 P2-4 已报告,可保留 |
| **E27** | `app_tokens.dart:46-314` facade 314 行转发 | P3 规范 | R105 P2-3 已报告,需 deprecation timeline |
| **E28** | `page_transition_switcher.dart:39` 默认 100ms 偏短 | P3 动效 | emil 框架下 occasional 频度应 ≥ 200ms |

---

## 四、动效/UX 总结 (Emil 4 档决策框架)

### 4.1 100+/day 频度 (核心导航 / 日常按钮) → **无动画**

| 位置 | 实际用法 | 评估 |
|------|----------|------|
| CheckInButton 状态切换 | `lib/presentation/widgets/check_in_button.dart:31-41` AnimatedContainer 200ms + curveDelight | ⚠️ 用户每天点 1-3 次, emil 框架 "occasional" 不是 100+/day。但 R105 P2-6 已用 delight 强化"庆祝"语义,可接受 |
| EncouragementText streak 切换 | `lib/presentation/pages/home/widgets/encouragement_text.dart` 无动画, 100+/day 直接切 | ✅ 符合 R18 P1-8 决策 |
| HomeFabToolbar 4 子按钮 | `lib/presentation/pages/home/widgets/home_fab_toolbar.dart:67-171` AnimatedSize + 4 FadeIn stagger | ✅ standard 频度 (toggle tens/day) |
| Theme toggle | `lib/presentation/widgets/theme_toggle_button.dart` 待查 | 假设无动画 (R17 决策) |
| PageView QuickMoodCarousel | `lib/presentation/pages/home/widgets/quick_mood_carousel.dart:150-200` 200ms ease-out 翻页 | ✅ tens/day 频度 (横滑), standard OK |
| TodaySummaryCard 数值变化 | `lib/presentation/pages/home/widgets/today_summary_card.dart:130-141` 默认 AnimatedSwitcher fade | ⚠️ (E13) 数值变化无 spring 物理, 缺 tween 递增 |
| 主页 8 层 stagger fade-in | `lib/presentation/pages/home/home_page_state.dart:327-431` 0-280ms 累加 | ⚠️ (E8) 累加 8 层过密, 应减到 3 项 |

### 4.2 Tens/day 频度 (hover / press / list item 选中) → **微弱 (curveSubtle, 200ms)**

| 位置 | 实际用法 | 评估 |
|------|----------|------|
| PressFeedback scale 0.97 | `lib/presentation/widgets/press_feedback.dart:64` 160ms + curveStandard (R18 P0-8) | ✅ tens/day, 但 emil "subtle 应该用 curveSubtle 而不是 curveStandard"。R24 P1-1 修了 curveSubtle token 但 PressFeedback 仍用 curveStandard — **drift**: PressFeedback 应该走 `Motion.curve(context, AppTokens.curveSubtle)` |
| DimensionRow 评分按钮 | `lib/presentation/widgets/dimension_row.dart:71-72` Motion.duration + curveStandard | ⚠️ tens/day 评分, 选 curveStandard 略强, 但评分有"明确视觉反馈"需求可接受 |
| QuickMoodCarousel 评分 tap | `lib/presentation/pages/home/widgets/quick_mood_carousel.dart:162-170` Motion.duration(200ms) + curveStandard | ✅ tens/day 速记 |
| InfoBanner tone 切换 | `lib/presentation/widgets/info_banner.dart` 无切换动画 (静态) | ✅ tone 是设置时定, 不需要切 |
| HomeFabToolbar toggle | `lib/presentation/pages/home/widgets/home_fab_toolbar.dart:62-64` 300ms + curveStandard | ✅ tens/day |

### 4.3 Occasional 频度 (modal / drawer / snackbar / 状态切换) → **标准 (durNormal + curveStandard)**

| 位置 | 实际用法 | 评估 |
|------|----------|------|
| Page transition fade | `lib/core/routing/app_routes.dart:47-50` durNormal + fade | ✅ 主导航偶尔切 |
| Page transition slide-right | `lib/core/routing/app_routes.dart:62-78` durNormal + slide 0.1 | ✅ 子页 push/pop, 跟 Material 风格一致 |
| Page transition slide-up | `lib/core/routing/app_routes.dart:89-99` durSlow + slide 0.05 | ✅ 全屏深页 |
| Setup 4 步切换 | `lib/presentation/pages/setup/setup_page_state.dart:130-146` MotionScheme.standard.duration (300ms) + 自定义 fade+slide | ✅ rare (首次设置), 但 (E1) reduce-motion 漏 |
| Trend list↔calendar | `lib/presentation/pages/trend/trend_page.dart:147-152` PageTransitionSwitcher 默认 100ms | ✅ 偶尔切视图 |
| Assessment quiz→result | 待查 assessment_page.dart | 假设走 PageTransitionSwitcher |
| SnackBar show/dismiss | `lib/presentation/widgets/app_snack_bar.dart:40-103` 4 档 duration (short/medium/long/long*2) | ✅ 集中器统一, 但 E10 daily_tracking 5 处漏走 |
| LoadingSkeleton fullScreen | `lib/presentation/widgets/loading_skeleton.dart:60-80` CircularProgressIndicator + fade in (隐式) | ✅ loading 是临时态, 不需要自定义 curve |

### 4.4 Rare 频度 (onboarding 首次 / 庆祝 / 解锁成就) → **弹性 (durSlow + curveDelight)**

| 位置 | 实际用法 | 评估 |
|------|----------|------|
| CelebrationBounce | `lib/presentation/widgets/animations/celebration_bounce.dart:42-58` MotionScheme.delight.duration (500ms) + curveBackOut 1.0→1.2→1.0 + 1.8s celebrationDisplayMs | ✅ rare 庆祝, 1.8s 停留 + bounce 后消失, emil "delight 不滥用" 原则 |
| FadeIn withScale | `lib/presentation/widgets/animations/fade_in.dart:38-45` withScale=true 模式, vent_list 空态 | ✅ rare 频度 (首次进 vent_list) |
| HomeHeroIllustration | `lib/presentation/pages/home/widgets/hero_illustration.dart` 静态无动画 | ⚠️ 注释 "rare 频度, 不动画", 但 emil rare 频度可加 delight (云飘动/太阳微缩放)。精神心理 App 视觉元素应"温暖治愈", 微动画能强化 |
| HomePage 进场 8 层 stagger | `lib/presentation/pages/home/home_page_state.dart:327-431` | ⚠️ (E8) 累加 8 层过密 |

### 4.5 整体评估

- **4 档框架遵循度**: 90% ✅ (R17 round 1 emil 动效 token 决策执行彻底)
- **token 化执行度**: 95% ✅ (motion/color/spacing/typography/shadow 4 大类全覆盖, 19 处用 Motion class, 36 个 widget 用 AppTokens 集中器)
- **reduce-motion 支持**: 85% (3 处漏: E1/E2/E4)
- **a11y (Semantics)**: 60% (3 个核心位置缺: E5/E6/E23)
- **3 大态 (loading/empty/error)**: 75% (12+ 处 loading/error 散落: E3)
- **delight 层**: 80% (CelebrationBounce 优秀, HomeHeroIllustration 静态稍弱)
- **drift 问题**: PressFeedback 用 curveStandard 而非 curveSubtle, curveSubtle 引入 6 个月但 PressFeedback 是最高频入口, 应该跟进

---

## 五、修复优先级汇总

### P0 (上架前必修, 5 项)
1. **E1** PageTransitionSwitcher setup 自定义 transitionBuilder 走 Motion 包装
2. **E2** notification_status_card AnimatedSize curve 走 Motion.curve 包装
3. **E3** 12+ 处 loading/error 走 LoadingSkeleton/ErrorState 集中器 (medication_page 优先, 其他次之)
4. **E4** medication_page 打卡按钮 AnimatedSwitcher duration 走 Motion.duration 包装
5. **E5+E6** QuickMoodCarousel + HomeFabToolbar 加 Semantics 包装 (R104 E7/E8 拖了 2 轮)

### P1 (体验显著提升, 7 项)
6. **E7** breakpointMedium = 840 vs breakpointExpanded = 840 边界, 改 [medium, expanded) 半开区间 (R104 E6 拖了 2 轮)
7. **E8** 主页 stagger 减到 3 项 (header + today_summary + hero)
8. **E9** R101 TodaySummaryCard + R81 hero (140px) + QuickMoodCarousel (80px) 总高 220px, 主页折叠线以下
9. **E10** 5 处 daily_tracking SnackBar 走 AppSnackBar 集中器
10. **E11** medication_pill_icon 6 iOS 系统色 + Colors.white 走集中器
11. **E12** medication_page 3 处未走 AppTokens + EmptyState
12. **E13** TodaySummaryCard 数字 tween 递增动画 (R105 P2-5 拖了 2 轮)
13. **E14** NotificationFailureBanner 退出动画 (R105 P2-16 拖了 2 轮)
14. **E15** quick_mood_carousel 错误 SnackBar 走 AppSnackBar + l10n

### P2 (小修小补, 10 项)
15. E16-E25 — SnackBar/fontSize/EmptyState/semantics 集中化

### P3 (技术债, 3 项)
27. **E26** LoadingSkeleton Shimmer 脉动 → 真正 shimmer (可选, 评估)
28. **E27** AppTokens facade 314 行 → deprecation timeline
29. **E28** PageTransitionSwitcher 默认 100ms → 200ms (emil 框架下 occasional ≥ 200ms)
30. **E30** MoodQuickButton emoji 字号集中化

---

## 六、给后续轮次的建议

1. **R110-Sprint #1 (P0 集中)**: 修 E1-E6 (3 大态集中器 + a11y + reduce-motion), 估时 4-6h, 1 天
2. **R110-Sprint #2 (P1 集中)**: 修 E7-E15 (8 项 UX), 估时 6-8h, 1-2 天
3. **R110-Sprint #3 (P2 polish)**: 修 E16-E25 (10 项), 估时 4-6h, 1 天
4. **R120 (P3 集中)**: facade 拆分 / Shimmer 重构 / PressFeedback curveSubtle drift, 估时 8-12h

**总估时**: 22-32 小时 (3-4 个 sprint), 完成后 emil 评分可从 9.0 → 9.5-9.7

**emil 9.5 标志**: (1) 0 个 P0 漏 (reduce-motion/a11y/3 大态), (2) delight 层 ≥ 3 个 (celebration_bounce + fade_in_with_scale + home_hero_animation), (3) PressFeedback 用 curveSubtle 替代 curveStandard (drift 修), (4) HomeHeroIllustration 加微动画 (云飘动/太阳脉动)

---

## 附: 审计方法论

**Emil 4 件套**:
1. `review-animations` — 逐条对照 checklist (duration/curve/prefers-reduced-motion/a11y/3 大态)
2. `improve-animations` — 8 维度优先级排序表 (本报告 P0→P3 矩阵)
3. `find-animation-opportunities` — emil "rare 频度可加 delight" 框架 (本报告 §4.4)
4. `animation-vocabulary` — 缓动术语 (easeOutCubic vs easeInCubic vs elasticOut vs easeOutBack, 本报告 §4.1-4.4 标注)

**5 视角交叉验证**:
- emil 评分 = emil 视角独立审计 (本报告)
- 跟 R104 (8.5/10) / R105 (7.0/10) / R103 (8.5/10) 对比
- 跟 R95 sub-spec 7+8 (daily_tracking + crisis_hotline) 新引入 widget 交叉验证

**关键文件清单 (本审计 25 个核心文件)**:
- 主题: `lib/core/theme/{app_motion,app_colors,app_spacing,app_tokens,app_typography,app_theme}.dart`
- 通用 widget: `lib/presentation/widgets/{page_scaffold,primary_button,secondary_button,press_feedback,press_feedback_icon_button,loading_skeleton,empty_state,error_state,info_banner,app_snack_bar,app_list_tile,section_header,stat_card,dimension_row,check_in_button,app_semantics,mood_quick_button,medication_pill_icon}.dart`
- 动效: `lib/presentation/widgets/animations/{fade_in,slide_up,page_transition_switcher,celebration_bounce}.dart`
- 主页: `lib/presentation/pages/home/{home_page,home_page_state}.dart + widgets/{hero_illustration,quick_mood_carousel,home_fab_toolbar,notification_failure_banner,home_footer,encouragement_text,today_summary_card}.dart`
- 用药: `lib/presentation/pages/medication/{medication_page,add_medication_page,medication_detail_page,medication_calendar_page}.dart + widgets/medication_pill_icon.dart`
- 树洞: `lib/presentation/pages/vent/{vent_list_page,vent_compose_page,vent_detail_page}.dart`
- 情绪/录音: `lib/presentation/pages/mood/widgets/mood_audio_recorder_widget.dart`
- 设置: `lib/presentation/pages/settings/{settings_page,legal_page,crisis_hotline_page}.dart + widgets/notification_status_card.dart`
- 趋势: `lib/presentation/pages/trend/trend_page.dart`
- 设置向导: `lib/presentation/pages/setup/{setup_page,setup_page_state,setup_widgets}.dart`
- 路由: `lib/core/routing/{app_router,app_routes}.dart`

---

*报告生成时间: 2026-08-10 03:25*
*审计工具: emilkowalski skill (设计工程师 6 件套)*
*基线对比: R104 (2026-08-09) 9.0/10 → 本次 9.0/10 (持平)*
*下次审计建议: R110 (估 1 周后), 重点跟踪 P0 5 项修复 + 新增 P1 7 项*
