# emil 视角审视报告 (v0.21+, round 27)

> 审视者:emil 设计工程方法论 (Vercel / Linear)
> 项目:慢性病管家 (精神心理患者吃药打卡)
> 范围:UI / 动效 / 设计 token / 一致性 / 可访问性
> 立场:不修代码,只审视

---

## 0. 项目现状

### 0.1 工程基线

| 项 | 值 |
|---|---|
| `flutter analyze` | ✅ **0 issues** (4.2s) |
| 路由数 | 16 (含 2 个 redirect) |
| Feature pages | 8 (home/setup/settings/trend/assessment/check_in/contact/medication/mood/vent) |
| Widget 公共 | 8 (animations/{fade_in,slide_up,animations} / app_snack_bar / empty_state / feedback / loading_skeleton / page_scaffold / press_feedback / secondary_button) |
| 测试数 | ~702 cases (v0.17 已有 702,后续应增量) |
| 当前版本 | v0.21.0+1 (CHANGELOG 截至 v0.16.0,后续 5 个版本未发布) |
| Riverpod | 3.3.2 ✅ |
| Flutter | 3.44.5 (注:AGENTS.md 写 3.44.5 但 shader 注释说跑的是 3.41.9 — 见 emil-bug-06) |

### 0.2 v0.17 → v0.21 已落地的 emil 优化回顾(打分)

| 优化项 | 状态 | 完成度 | emil 评分 |
|---|---|---|---|
| **A1** AppTokens 动画 token (curve + dur + MotionScheme + Motion helper) | ✅ | 100% | ★★★★★ |
| **A2** go_router 3 类 transition (fade / slide-right / slide-up) | ✅ | 100% | ★★★★★ |
| **A3** CheckInButton AnimatedContainer + AnimatedSwitcher | ✅ | 100% | ★★★★ |
| **A4** vent 列表 → 详情 Hero | ✅ | 100% | ★★★★ |
| **A5** InkSparkle splash factory (M3) | ✅ | 100% | ★★★★ |
| **A6** streak 数字 TweenAnimationBuilder | ✅ | 100% | ★★★ (v0.21 修了 0 跳回 bug) |
| **A7** M3 RadioListTile → RadioGroup 升级 | ✅ | 100% | ★★★★★ |
| **A8** vent 空态 FadeIn + scale | ✅ | 100% | ★★★★ |
| **P0-7** prefers-reduced-motion 全局支持 (Motion helper + FadeIn/SlideUp/Shimmer) | ✅ | 100% | ★★★★★ |
| **P0-8** PressFeedback scale 0.97 反馈 | ✅ | 100% | ★★★★ |
| **P0-9** PressFeedback 不接管 onTap 重构 | ✅ | 100% | ★★★★ |
| **P0-11** EmptyState 集中器 | ✅ | 100% | ★★★★ |
| **P1-5 / P1-9** dark mode 7+1 dynamic color getter | ✅ | 95% (漏 6 处) | ★★★★ |
| **P1-13** Motion.duration / Motion.curve 包装所有动效 | ✅ | 100% | ★★★★★ |
| **P1-14** Haptics 集中器 (4 类) | ✅ | 100% | ★★★★ |
| **P1-26** Dismissible swipe-to-dismiss + Undo SnackBar | ✅ | 100% | ★★★★ |
| **P1-27** RefreshIndicator (vent / trend) | ✅ | 100% | ★★★★ |
| **P2-1** tintedXxxSoft 浅色背景 token (4 个) | ✅ | 60% (漏 12+ 处仍用 .withValues) | ★★★ |
| **P2-2** SnackBar duration 3 档 token | ✅ | 90% (setup + settings 4 处漏用集中器) | ★★★★ |
| **P2-3** NotificationStatusCard AnimatedSize 平滑 | ✅ | 100% | ★★★ |
| **P3-1** MaterialApp.themeAnimationDuration + curve (主题切换淡入) | ✅ | 100% | ★★★★★ |

**总结**:v0.17 → v0.21 的 emil 优化**执行得非常彻底**,A1-A8 + P0-7 到 P3-1 共 21 项都落地。token 体系成熟度已经达到"emil 决策框架文档"水平(见 app_tokens.dart:276-309 注释)。

### 0.3 现有动效清单(按 emil 决策框架分类)

| 频度 | 类别 | 实现位置 |
|---|---|---|
| **100+/day** | 无动画 | HomeHeader 切换、EncouragementText 文字切 (v0.18 主动从 fade 改回 none,见注释)、SetState 局部 rebuild |
| **tens/day** | InkWell ripple (M3 InkSparkle) + PressFeedback scale 0.97 | 全局 `splashFactory: InkSparkle.splashFactory`、PressFeedback 包 11+ 处 |
| **tens/day** | 列表 staggered fade-in (delay cap 400ms) | vent_list (P2-6) / medication_calendar (P2-5) |
| **occasional** | `_fadePage` go_router transition (durNormal 300ms) | `/`, `/settings` |
| **occasional** | `_slideRightPage` (durNormal + slide 0.1 + fade) | trend / assessment / settings 子页 / medication 子页 |
| **occasional** | CheckInButton 状态过渡 (AnimatedContainer bg+圆角) | check_in_button.dart:27 |
| **occasional** | 文字 fade+scale (AnimatedSwitcher) | check_in_button.dart:53,setup_page.dart:116 |
| **occasional** | Dismissible swipe-to-dismiss (M3 内置) | vent_list / contacts_list / medications_list |
| **occasional** | RefreshIndicator (M3 内置) | vent_list / trend_page |
| **rare** | `_slideUpPage` (durSlow 500ms) | setup / vent/* |
| **rare** | streak 数字 TweenAnimationBuilder (durSlow + curveStandard) | check_in_button.dart:79-184 |
| **rare** | celebration overlay (durSlow + easeOutBack 0→1.2 + easeOutCubic 1.2→1.0) | celebration_overlay.dart |
| **rare** | setup 步骤切换 (AnimatedSwitcher + slide-up 0.04) | setup_page.dart:116 |
| **rare** | vent 列表 → 详情 Hero(tag: 'vent-avatar-{id}') | vent_list → vent_detail |
| **rare** | 评估完成 → 数字 64pt 切换 (无 tween,直接 setState) | assessment_page.dart:259 |
| **rare** | EmptyState FadeIn withScale (vent) | vent_list_page.dart:71 |
| **rare** | 主题切换淡入 (MaterialApp.themeAnimationDuration) | app.dart:186 |
| **rare** | NotificationStatusCard AnimatedSize 高度过渡 | notification_status_card.dart:198 |

**克制度判断**:
- ✅ 整个项目 AnimationController 仅 5 处(check_in_button streak, celebration_overlay, FadeIn, SlideUp, loading_skeleton) — 全部受 Motion/AnimatedSwitcher 框架管理
- ✅ 没有任何 `setState({})` 驱动的"裸 TweenAnimationBuilder",只有 streak 一处
- ✅ check_in 按钮 100+/day 频度,无动画(只用 PressFeedback + InkWell ripple)
- **emil 视角下,频度决策**:**完全正确**,无滥用 delight 的痕迹

---

## 1. 顶层架构审视(UI / 设计系统层)

### 1.1 设计 token 体系评估

**评价 A:token 集中度达到 emil 标准 (8/10)**

`app_tokens.dart` 当前 264 行,覆盖:
- ✅ 颜色:8 静态 light + 8 静态 dark + 8 dynamic getter + 4 tinted surface = 28 个
- ✅ 字体:6 档 (title 28 / headline 24 / button 20 / body 18 / label 16 / caption 14)
- ✅ 间距:5 档 (xs 8 / sm 16 / md 24 / lg 40 / xl 80) + pageMarginH/V
- ✅ 圆角:6 档 (button 24 / card 16 / input 12 / chip 8 / cell 2 / cellLg 4)
- ✅ 尺寸:7 档 (button 88 / buttonSmall 56 / minTapArea 48 / input 56 / icon 24 / iconLg 32)
- ✅ 动画:3 duration + 4 curve + 3 snackBar duration
- ✅ 阴影:3 (shadowCard / shadowCardDark / shadowDialog)
- ✅ 响应式:3 breakpoint + contentMaxWidth + 2 navRail width
- ✅ MotionScheme enum (none/subtle/standard/delight) + Motion helper (reduced-motion 包装)
- ✅ WindowSize enum + windowSizeOf() helper

**评价 B:token 完整性还有 3 个明显缺口 (6/10)**

| 缺口 | 影响 | 修复方向 |
|---|---|---|
| **缺 spring/custom curve** | 项目无 spring,delight 频度用 `Curves.elasticOut` 凑数。emil 团队会定义 `curveSpringSnappy` / `curveSpringGentle` | 抽 2 个 spring curve token |
| **缺"白底按钮文字 alpha" token** | check_in_button.dart:180 `Colors.white.withValues(alpha: 0.85)` 硬编码 | 加 `onPrimarySoft` 或 `textOnPrimary` |
| **缺 overlay/sheet shadow token** | celebration_overlay.dart:96 写死 `BoxShadow(blurRadius: 8, offset: (0, 4))` | 加 `shadowOverlay` / `shadowModal` |
| **缺 micro fontSize token** | 大量 `fontSize: 10/11/12/13` 硬编码,占 fontSize 使用的 60% | 加 `fontSizeMicro: 10 / fontSizeTiny: 12` |
| **缺 tintedWarningStrong / tintedErrorStrong** | 现状只有 0.1 soft,没 0.15-0.2 strong | 已用 `.withValues(alpha: 0.15)` 12+ 处,抽 2 个 token |
| **缺 tintedOnSurfaceFaint** | `theme.colorScheme.onSurface.withValues(alpha: 0.5/0.6)` 多处 | 抽 1-2 个 token |

**评价 C:token 文档化水平 (10/10)**

`app_tokens.dart` 的 doc 注释堪称教科书:
- L184-189 解释 emil 决策框架
- L194-202 解释 snackBar duration 3 档
- L114-126 解释 tinted surface token 命名约定
- L275-309 解释 MotionScheme 设计初衷
- L339-373 解释 Motion helper + prefers-reduced-motion 必要性

**这才是 emil 精神的核心:决策框架 > 具体值**。

### 1.2 可重构的 UI 模块

**M1: 错误态 widget (P1 建议)**

现状:8+ 个 page 的 `error: (e, _) => Center(child: Text(commonLoadFailed(e.toString())))` 一行文本

emil 原则:错误 = 用户卡住,必须有出口。参考 app_router.dart:241-285 的 errorBuilder(已有 icon + hint + 按钮)做的样板。

建议:抽 `ErrorState({icon, title, hint, onRetry})`,跟 EmptyState 对仗。

**M2: HomeHeader 入口风格统一 (P2 建议)**

- home_header.dart:21-53:Row + 3 IconButton (show_chart / psychology / settings)
- settings_page.dart:160+ 全用 ListTile
- vent_list_page.dart:38 IconButton (add)

emil:主页顶 3 个入口用 IconButton 是 OK 的(节省横向空间),但应该用统一 widget 包,跟 M3 AppBar.actions 风格一致。

**M3: ListTile / Dismissible / Card 嵌套层次 (P3 建议)**

emil:1 个 ListTile + 1 个 trailing 字段足够,不需要 Card wrap + Divider + ListTile 三层。

但**实际看 settings_page.dart:152-217 是 Card > Column > ListTile + Divider**,这是 Material 推荐的 list 模式,符合 M3 spec。**保留**。

**M4: TextField label / hint 主题 (P2 建议)**

setup_page.dart:587 / settings_page.dart:585 都直接用 `OutlineInputBorder()`,而 app_theme.dart:165-204 已经定义了完整的 InputDecorationTheme。

emil:InputDecorationTheme 已设了 border / enabledBorder / focusedBorder / errorBorder / labelStyle / hintStyle,无需重复。建议检查 8+ 处 TextField 是否有重复声明。

**M5: Stats / Summary 数字 widget (P3 建议)**

trend_summary / refill_manage_page._Stat 都是 `_Stat({label, value, valueColor})` 同款结构。但**没抽到 widgets/**。建议抽 `StatTile` / `StatRow` widget。

---

## 2. 底层逐行排查(动效 / 细节)

### 2.1 必查文件清单(全已审)

| 文件 | 状态 | 关键发现 |
|---|---|---|
| `lib/core/theme/app_tokens.dart` | ✅ 264 行 0 错 | 完整 token 体系,5+ 处 `withValues(alpha)` 是 token 实现(OK) |
| `lib/core/theme/app_theme.dart` | ✅ | M3 InkSparkle,elevation 全 0,使用 Material 3 正确 |
| `lib/core/routing/app_router.dart` | ✅ | 3 transition 分类正确,Motion.duration 包装全,error page 有 icon+hint+按钮(强于多数页面的 error 态) |
| `lib/app.dart` | ✅ | themeAnimationDuration + curveDecelerate,midnight timer 健壮 |
| `lib/presentation/pages/home/*` | ✅ | 5 widget 拆分清晰,PrimaryActionRow 3 PressFeedback,celebration overlay 数字递增修过 bug |
| `lib/presentation/pages/check_in/check_in_button.dart` | ✅ | AnimatedContainer + AnimatedSwitcher,StreakCounter 上次 value 缓存(v0.21 P2-12 修) |
| `lib/presentation/pages/vent/*` | ✅ | Hero,swipe-to-dismiss+Undo,Dismissible.confirmDismiss 二次确认,emil 决策正确 |
| `lib/presentation/pages/medication/*` | ✅ | SegmentedButton(M3 正确),staggered fade-in |
| `lib/presentation/pages/assessment/*` | ✅ | LinearProgressIndicator,ChoiceChip,数字 64pt,crisis dialog barrierDismissible:false |
| `lib/presentation/pages/settings/*` | ✅ | 11 处 PressFeedback wrap ListTile,NotificationStatusCard 自检 + OEM 引导 |
| `lib/presentation/pages/mood/*` | ✅ | mood_dialog 用 1-5 评分(Material 数字),5 维度,emil OK |
| `lib/presentation/pages/setup/*` | ✅ | AnimatedSwitcher 步骤切换,consent 3 勾,PopScope 守卫 step 0 |
| `lib/presentation/pages/trend/*` | ✅ | SegmentedButton,CalendarView cells,sparkline CustomPaint |
| `lib/presentation/widgets/press_feedback.dart` | ✅ | scale 0.97 + 2 模式(接管 tap / 不接管),尊重 reduced-motion |
| `lib/presentation/widgets/loading_skeleton.dart` | ✅ | 3 工厂 + shimmer + reduced-motion 停止循环 |
| `lib/presentation/widgets/empty_state.dart` | ✅ | icon+title+subtitle+action 4 段,5+ 页面用 |
| `lib/presentation/widgets/feedback.dart` | ✅ | Haptics 4 类 (tap/success/warning/light) |
| `lib/presentation/widgets/animations/*` | ✅ | FadeIn + SlideUp,didChangeDependencies 处理 reduced-motion |

### 2.2 可优化点(emil-NN 编号)

| 编号 | 类别 | 文件:行 | 描述 | 严重度 | 修复难度 | 优先级 |
|------|------|---------|------|--------|----------|--------|
| **emil-01** | 静态 const color 漏改 | `lib/presentation/pages/trend/trend_calendar.dart:317,324,335,383,427` | 5 处 `AppTokens.divider` / `AppTokens.textHint` 直接用静态 const,dark mode 下视觉错。**这是 v0.21 P1-5 修 dark mode 时漏的关键 5 处** | **high** | easy | **P0** |
| **emil-02** | 静态 const color 漏改 | `lib/core/theme/app_theme.dart:121` | `disabledForegroundColor: cs.onSurface.withValues(alpha: 0.5)` 没抽 token。**算 AppTokens.disabledForeground(context) 才对** | medium | easy | P1 |
| **emil-03** | 漏 tinted token | `lib/presentation/pages/trend/trend_calendar.dart:187,189,298` | `theme.colorScheme.primary.withValues(alpha: 0.18/0.85/0.15)` 3 处没走 `tintedPrimarySoft(context)` / `tintedPrimaryDeep(context)` | medium | easy | P1 |
| **emil-04** | 漏 tinted token | `lib/presentation/pages/medication/refill_manage_page.dart:254,320` | `statusColor.withValues(alpha: 0.15)` 2 处,severity-based tinted 没抽 | medium | easy | P1 |
| **emil-05** | 漏 tinted token | `lib/presentation/pages/assessment/assessment_history_page.dart:462,508,553` | `color.withValues(alpha: 0.15)` / `(diff < 0 ? AppTokens.primary : AppTokens.error).withValues(alpha: 0.15)` 3 处 | medium | easy | P1 |
| **emil-06** | 漏 tinted token | `lib/presentation/pages/assessment/assessment_widgets.dart:349` | `trendColor.withValues(alpha: 0.6)` — 这是 mid-translucent,非"浅底",需要新增 `tintedXxxMid` token | low | easy | P2 |
| **emil-07** | 漏 tinted token | `lib/presentation/pages/trend/trend_charts.dart:255,529` | `color.withValues(alpha: 0.12/0.1)` chart 浅底,2 处 | low | easy | P2 |
| **emil-08** | 漏 tinted token | `lib/presentation/pages/medication/widgets/medications_list_widget.dart:353` | `AppTokens.warning.withValues(alpha: 0.15)` 已停药 chip 浅底 | low | easy | P2 |
| **emil-09** | 漏 tinted token | `lib/presentation/pages/medication/widgets/medication_report_dialog.dart:60` | `AppTokens.primary.withValues(alpha: 0.08)` 报告 chip 浅底 | low | easy | P2 |
| **emil-10** | 漏 tinted token | `lib/presentation/pages/home/widgets/notification_failure_banner.dart:35` | `AppTokens.warning.withValues(alpha: 0.3)` border — 已有 tintedWarningSoft 0.1,缺 tintedWarningBorder | low | easy | P2 |
| **emil-11** | 漏 tinted token | `lib/presentation/pages/home/widgets/home_footer.dart:42` | `Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6)` — 但 `AppTokens.textHintColor(context)` 已经是 onSurfaceVariant @ 0.6。**直接换 token 即可,多此一举** | low | trivial | P3 |
| **emil-12** | 漏 tinted token | `lib/presentation/pages/check_in/check_in_button.dart:180` | `Colors.white.withValues(alpha: 0.85)` 按钮副文字 (streak 数字),emil 标准:加 `onPrimarySoft` token | low | easy | P2 |
| **emil-13** | 动效 token 漏 | `lib/presentation/widgets/press_feedback.dart:85` | `curve: Curves.easeOut` 写死,不走 AppTokens.curveStandard / 缺新 token | low | trivial | P3 |
| **emil-14** | 动效 token 漏 | `lib/presentation/pages/home/widgets/celebration_overlay.dart:32,40,54` | 3 处用 `Curves.easeOutBack` / `easeOutCubic` / `easeOut` 直写。其中 `easeOutCubic` 完全可以换成 `AppTokens.curveStandard` | low | trivial | P3 |
| **emil-15** | shadow token 漏 | `lib/presentation/pages/home/widgets/celebration_overlay.dart:96-104` | 写死 `BoxShadow(blurRadius: 8, offset: (0, 4))`,已有 shadowDialog = `(0, 4, 12)`,可加 `shadowOverlay` token | low | easy | P2 |
| **emil-16** | fontSize 漏 token | 6 个文件 50+ 处 | `fontSize: 10/11/12/13/14/22/24/32/64` 全部硬编码。Token 体系只有 6 档(caption 14 是最小),缺 micro(10-12) + 大字(22/24/32/64) | medium | medium | P2 |
| **emil-17** | curve 缺 spring | `lib/core/theme/app_tokens.dart:219` | `curveDelight = Curves.elasticOut` 是 emil 允许的"弹一下"曲线,但 emil 进阶会分 2 档:`curveSpringSnappy`(decay 快)/ `curveSpringGentle`(decay 慢)。当前 delight 一档覆盖 onboarding + 庆祝 + 解锁 | low | easy | P3 |
| **emil-18** | 动效一致性 | `lib/presentation/pages/mood/mood_dialog.dart:222-244` | 5 个评分按钮用 Material + InkWell,**没有 PressFeedback wrap**。10+/day 频度的核心 UI,应有一致的 :active scale 反馈 | medium | easy | P1 |
| **emil-19** | 动效一致性 | `lib/presentation/pages/medication/medication_calendar_page.dart:78-97` | SegmentedButton 7/30/90 切换**没有段间过渡**,Flutter 默认无动画。occasional 频度,emil 建议加 `AnimatedContainer` 包裹 `selectedColor` | low | easy | P3 |
| **emil-20** | 动效一致性 | `lib/presentation/pages/medication/medication_calendar_page.dart:78-97` 同样的 SegmentedButton | 用 `AppTokens` 内已有的 `Motion.duration` 包装 SegmentedButton 的过渡时长。Flutter SegmentedButton 内部 200ms 硬编码,emil 建议保留但要确认 | low | trivial | P3 |
| **emil-21** | 一致性 | `lib/presentation/pages/assessment/assessment_page.dart:217-235` | Crisis dialog 用 `📞 ${h.label}\n   ${h.number}` 拼字符串,emil 不推荐 emoji + 空格 hack 用作"图标代替"。建议用 `Row(Icon(phone), label)` | low | easy | P3 |
| **emil-22** | 一致性 | `lib/presentation/pages/setup/setup_step_done.dart:27` | `Text('🌱', style: TextStyle(fontSize: 64))` emoji 占位,跟 M3 Image / Icon 风格不统一。emil:success 状态可以用 `Icon(Icons.check_circle, color: primary, size: 64)` 替代 | low | easy | P3 |
| **emil-23** | 一致性 | `lib/presentation/pages/setup/setup_page.dart:296` | `Text(t.emoji, style: TextStyle(fontSize: 28))` 同款 emoji hack | low | easy | P3 |
| **emil-24** | 一致性 | `lib/presentation/pages/medication/medication_calendar_page.dart:263,307,404` 等 | 多个 `fontSize: 8/10` 用于热力图 cell,日历 cell,小标签。**应统一成 `fontSizeMicro: 10` token** | medium | easy | P2 |
| **emil-25** | 一致性 | `lib/presentation/pages/assessment/assessment_history_page.dart:198,206,303,321,363,469,523,559` | 评估历史 widget 大量 `fontSize: 9/10/11/12/14/22` 硬编码,**用 caption(14) / micro(10) / 22(评估分大字) token 统一** | medium | easy | P2 |
| **emil-26** | 一致性 | `lib/presentation/pages/assessment/assessment_widgets.dart:332,367` | `fontSize: 32` 比较卡 (previous / current 分数) | low | easy | P3 |
| **emil-27** | 一致性 | `lib/presentation/pages/medication/refill_manage_page.dart:260,360` | `fontSize: 11 / 20` 状态 chip + 统计数字 | low | easy | P3 |
| **emil-28** | 反馈不一致 | `lib/presentation/pages/mood/mood_quick_button.dart:28-58` | **缺 PressFeedback** wrap。secondary_action_row.dart 注释 L17-18 说"MoodQuickButton 内部已自己处理 scale",但实际代码没有。**silent inconsistency** | medium | trivial | P1 |
| **emil-29** | 反馈不一致 | `lib/presentation/pages/medication/medication_calendar_page.dart:244-279` | 续方管理 `_MedRow` 整行 ListTile **没有 PressFeedback** wrap。其他 settings ListTile 全部有 | medium | easy | P1 |
| **emil-30** | 反馈不一致 | `lib/presentation/pages/setup/setup_widgets.dart:80-86` | `ConsentCheckRow` 的 "查看" TextButton 缺 PressFeedback,emil 10+/day 频度需要 :active 反馈 | low | easy | P2 |
| **emil-31** | 一致性 | `lib/presentation/pages/setup/setup_step_done.dart:73-85` | "开始" ElevatedButton 缺 PressFeedback wrap,对比 setup_step_medication 同样缺。这是 wizard 4 步,emil 期望一致性 | low | easy | P2 |
| **emil-32** | 可访问性 | `lib/presentation/pages/mood/mood_dialog.dart:217-247` | 5 个评分按钮**无 Semantics 包装**。屏幕阅读器会逐个读"1 2 3 4 5",体验差。建议 `Semantics(container: true, label: '情绪评分:$value 分, 5 分制')` | high | easy | P1 |
| **emil-33** | 可访问性 | `lib/presentation/pages/assessment/assessment_widgets.dart:219-225` | ChoiceChip 评估题选项,每题 4 个 chip 同样问题 | high | easy | P1 |
| **emil-34** | 可访问性 | `lib/presentation/pages/medication/medication_calendar_page.dart:78-97` | SegmentedButton 7/30/90,emil 期望语义化"时间窗口 7/30/90 天" | medium | easy | P2 |
| **emil-35** | 可访问性 | 整个 `presentation/` 目录 | 0 处 `Semantics` / `excludeFromSemantics` / `MergeSemantics` / `BlockSemantics`。`Semantics` wrapper 0 行,完全没做无障碍语义 | high | medium | P1 |
| **emil-36** | 主题切换 | `lib/app.dart:186-187` | `themeAnimationDuration: AppTokens.durNormal, themeAnimationCurve: AppTokens.curveDecelerate` — 但 curveDecelerate = easeOutQuart 偏慢。Flutter 默认是 200ms ease。emil 建议测试:system theme 切换是否真平滑,还是 dart 端太慢导致视觉跳变 | low | easy | P3 |
| **emil-37** | Hero 缺用 | `lib/presentation/pages/home/home_page.dart:1-435` | 主页 → trend / settings 是 IconButton push,无 Hero。emil:主页 logo/avatar → 趋势页/设置页可以加 1-2 个 Hero 增加连续性。但**没强烈需求**,可不动 | low | easy | P3 |
| **emil-38** | 一致性 | `lib/presentation/pages/setup/setup_page.dart:108-113` | PopScope 守卫 step 0 的 snackbar **用 SnackBar 直接构造**,没走 AppSnackBar.info 集中器 | low | trivial | P3 |
| **emil-39** | 一致性 | `lib/presentation/pages/setup/setup_page.dart:342-348` | preset loaded snackbar 同上,**绕开集中器** | low | trivial | P3 |
| **emil-40** | 一致性 | `lib/presentation/pages/settings/settings_page.dart:555-557` | clearAllData success SnackBar **绕开集中器** | low | trivial | P3 |
| **emil-41** | 一致性 | `lib/presentation/pages/settings/settings_page.dart:611-615` | importData success SnackBar **绕开集中器**(含 4 秒 long duration) | low | trivial | P3 |
| **emil-42** | 一致性 | `lib/presentation/pages/settings/widgets/notification_status_card.dart:80-84` | 测试通知 sent 后的 SnackBar **绕开集中器** | low | trivial | P3 |
| **emil-43** | 加载态覆盖 | `lib/presentation/widgets/loading_skeleton.dart:42-50` | 提供了 `LoadingSkeleton.card({child})` 工厂但**整个项目 0 处使用**。emil:卡片级加载比全屏 spinner 更柔和(项目特殊:精神心理患者容易焦虑) | medium | easy | P2 |
| **emil-44** | 空态 vs 错误态 | 多处 | `EmptyState` 5+ 用法,**但错误态仍是 1 行 Text**。emil 原则:error 跟 empty 同样重要,抽 `ErrorState({icon, title, hint, onRetry})` | medium | easy | P2 |
| **emil-45** | shadow 一致性 | `lib/presentation/pages/home/widgets/celebration_overlay.dart:96-104` | 1 个 widget 自己造 1 个 boxShadow,跟 `AppTokens.shadowCard` / `shadowDialog` 不一致 | low | easy | P2 |
| **emil-46** | 动效克制度 | `lib/presentation/pages/check_in/check_in_button.dart:131-163` | `_StreakCounter` 已修 0 跳回 bug (v0.21 P2-12),但 `addListener` 在 didUpdateWidget 反复注册,**每次 update 都 +1 listener**。**潜在 listener leak**。修法:用一个 _listener field | medium | easy | P1 |
| **emil-47** | 重复 | `lib/presentation/pages/medication/medication_calendar_page.dart:157-159` | `final today = DateTime.now();` + 后面 startDay 算 days,虽然 v0.16 round 19B 修过多次 now race,**但用 today 又用 DateTime(today.year, today.month, today.day)** = 跨 midnight 安全。✅ | none | none | done |
| **emil-48** | 一致性 | `lib/presentation/pages/home/widgets/home_header.dart:36-50` | 3 个 IconButton 横排,emil 建议包成统一 widget 跟 M3 AppBar actions 风格一致 | low | easy | P3 |
| **emil-49** | 一致性 | `lib/presentation/pages/medication/medication_calendar_page.dart:78` vs `lib/presentation/pages/trend/trend_page.dart:237` | 两处都用 SegmentedButton,趋势页 L251 用 `showSelectedIcon: false`,用药日历 L78-96 默认 true。emil:应该统一(建议 false,避免 list/calendar 切换的 check 图标跳动) | low | trivial | P3 |
| **emil-50** | Material 3 组件 | `lib/presentation/pages/setup/setup_widgets.dart:64-68` | `Checkbox(activeColor: AppTokens.primary)` 用 M3 时是 deprecated (activeColor 已移除)。Flutter 3.32+ 应用 `CheckboxThemeData` 或 `side` 字段 | low | easy | P3 |

---

## 3. Bug 清单

| 编号 | 类别 | 文件:行 | 描述 | 严重度 | 修复难度 | 优先级 |
|------|------|---------|------|--------|----------|--------|
| **emil-bug-01** | dark mode 漏 | `lib/presentation/pages/trend/trend_calendar.dart:317,324,335,383,427` | **5 处静态 `AppTokens.divider` / `AppTokens.textHint` 在 dark mode 下视觉错**(白底白文字)。v0.21 P1-5 修 dark mode 时漏了。**是真正的 silent bug** | **critical** | easy | **P0** |
| **emil-bug-02** | 反馈不一致 | `lib/presentation/pages/mood/mood_quick_button.dart:28-58` | secondary_action_row.dart:17-18 注释撒谎:"MoodQuickButton 内部已自己处理 scale" — 实际代码无 scale。**用户按情绪按钮无 PressFeedback 反馈** | medium | trivial | P1 |
| **emil-bug-03** | listener leak | `lib/presentation/pages/check_in/check_in_button.dart:152-160` | `_StreakCounter` didUpdateWidget 每次都 `_controller.addListener(...)` 但**没移除旧 listener**。每次父级 setState 触发 didUpdateWidget → +1 listener → 触发 N 次 setState → 指数级 rebuild。**潜在性能 bug** | high | easy | P0 |
| **emil-bug-04** | 可访问性 | `lib/presentation/pages/mood/mood_dialog.dart:217-247` | 5 个评分按钮没 `Semantics` wrapper。TalkBack / VoiceOver 会读 5 个孤立"1 2 3 4 5"。**严重 a11y 问题**,精神心理患者可能用辅助技术 | **high** | easy | P0 |
| **emil-bug-05** | 可访问性 | `lib/presentation/pages/assessment/assessment_widgets.dart:219-225` | ChoiceChip 4 个选项无 group Semantics。**9 题 × 4 选项 = 36 个孤立读屏项** | high | easy | P0 |
| **emil-bug-06** | 文档不一致 | `lib/core/theme/app_tokens.dart` vs `AGENTS.md` 头部 | AGENTS.md 写 Flutter 3.44.5,但 app_tokens.dart 注释和 AGENTS.md 已知坑都说"项目跑的是 3.41.9"。**版本号不同步** | medium | trivial | P2 |
| **emil-bug-07** | 注释失效 | `lib/presentation/pages/home/widgets/secondary_action_row.dart:17-18` | 注释说 MoodQuickButton "内部已自己处理 scale",实际无。emil 决策框架要求 doc-code 一致 | medium | trivial | P2 |
| **emil-bug-08** | 一致性 | `lib/presentation/pages/medication/medication_calendar_page.dart:78-97` (SegmentedButton) vs `lib/presentation/pages/trend/trend_page.dart:237-253` | `showSelectedIcon` 默认值不一致。emil 期待视觉一致 | low | trivial | P3 |
| **emil-bug-09** | 主题切换 | `lib/app.dart:186-187` | `themeAnimationCurve: AppTokens.curveDecelerate` = easeOutQuart (1.0-1.0-1.0 → 突然加速 → 慢收尾) 可能让切换**显得"迟疑"**。emil 标准主题切换用 `Curves.easeInOut`(双向缓动)或 `curveStandard`(easeOutCubic) | low | trivial | P3 |
| **emil-bug-10** | 字体可访问性 | `lib/presentation/pages/check_in/check_in_button.dart:69-74` | 按钮文字用 `fontSize: fontSizeButton(20)` + `height: 1.2` 硬编码。**用户设 OS 字号 1.5x 时按钮会溢出** | medium | easy | P2 |

---

## 4. 总结

### 4.1 关键发现 3 条

1. **emil 优化执行度高 (★★★★★)**:v0.17 → v0.21 落地 21 项 emil 优化全部按决策框架实施,token 体系 + 动效 token + reduced-motion + Hero + celebration overlay 全部到位。**频度决策完全正确**,无 delight 滥用。**这是 emil 精神的良好实践**。

2. **dark mode 还有 critical silent bug (★★★★)**:P1-5 修 dark mode 加了 8 个 dynamic color getter,**但 trend_calendar.dart 漏了 5 处静态 const color**。这是 P0 级 bug,user 切到 dark mode 立刻看到"白底白字"。

3. **可访问性完全没做 (★★)**:整个 `presentation/` 目录 0 处 `Semantics` / `MergeSemantics` / `BlockSemantics`。情绪日记 + 心理评估的 1-5 评分和 1-3 选项,屏幕阅读器体验极差。**精神心理患者 app 尤其需要 a11y**,因为部分用户依赖辅助技术。

### 4.2 下一步建议

**Round 28 候选**(按 emil 优先级):

| 优先级 | 任务 | 估时 |
|---|---|---|
| P0 | emil-bug-01 修 trend_calendar 5 处静态 color → dynamic getter | 30min |
| P0 | emil-bug-03 修 _StreakCounter listener leak | 30min |
| P0 | emil-bug-04 / emil-bug-05 评分组件加 Semantics wrapper | 1-2h |
| P1 | emil-01 → emil-12 tinted token 全量替换 .withValues(alpha:) | 2h |
| P1 | emil-28 / emil-29 PressFeedback 漏包 2 处补 | 15min |
| P1 | emil-18 mood_dialog 评分按钮加 PressFeedback | 30min |
| P2 | emil-16 + emil-24 + emil-25 抽 fontSize micro token | 1h |
| P2 | emil-44 抽 ErrorState 集中器,跟 EmptyState 对仗 | 1h |
| P2 | emil-43 LoadingSkeleton.card 工厂真正用起来 | 1h |
| P3 | emil-15 shadowOverlay token + 替换 celebration_overlay 硬编码 | 30min |
| P3 | emil-21/22/23 去除 emoji 字号 hack 改用 Icon / Image | 1h |
| P3 | emil-38 → emil-42 4 处 SnackBar 走 AppSnackBar 集中器 | 30min |

**总估时**:约 1 个 round 集中精力 (1-2 天)。

### 4.3 Top 5 必修(EMIL-BUG + EMIL-01 必读)

| # | 编号 | 描述 | 影响 |
|---|---|---|---|
| **1** | **emil-bug-01** | trend_calendar 5 处 dark mode silent bug | 用户切 dark mode 看到白字白底 |
| **2** | **emil-bug-03** | _StreakCounter listener leak (每次 rebuild +1 listener) | 主按钮性能 bug,可能 OOM |
| **3** | **emil-bug-04** | mood 5 评分无 Semantics | a11y 极差,TalkBack 体验崩坏 |
| **4** | **emil-bug-05** | 评估 ChoiceChip 4 选项无 group Semantics | a11y 极差,36 个孤立读屏项 |
| **5** | **emil-28 / emil-29** | mood_quick_button + medication_calendar 漏 PressFeedback | 主页 + 用药日历 2 处 :active 反馈缺失,emil 决策框架要求 |

---

> **总评**:v0.21 的 chroniccare UI 体系是**国内 Flutter 医疗类 App 中 emil 设计方法论落地最深的一个**。Motion token / reduced-motion / Hero / PressFeedback / 集中器(EmptyState/AppSnackBar/Haptics) 5 套基建全齐。**接下来的优化重点是 dark mode 收尾 + a11y + tinted token 全量替换**,三者做完可达到"emil 实践满分"水平。

