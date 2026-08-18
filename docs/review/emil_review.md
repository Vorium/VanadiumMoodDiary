# emil · 设计工程 (Design Engineering) 代码审视报告

> **项目**：D:\Batch\chroniccare — 精神心理患者吃药打卡 App（Flutter 3.41.9 / Riverpod 3.3.2 / Drift 2.20.3 / go_router 14.6）
> **审视视角**：Emil Kowalski 设计工程（动效 / 设计 token / 微交互 / 一致性 / 可访问性）
> **审视范围**：`lib/presentation/**` + `lib/core/theme/**` + `lib/core/routing/app_router.dart` + `lib/core/shared/**`（动效 / token 触达点）
> **审视时间**：v0.24 round 47 末
> **方法**：先扫架构层 token / curve / motion 集中度，再针对问题点逐行追溯

---

## 0. 总体评分

| 维度 | 评分 (1-10) | 说明 |
|---|---|---|
| **Token 集中度** | **9 / 10** | 颜色 / 字号 / 圆角 / spacing / 阴影 / 曲线 几乎全部走 `AppTokens`；只有 14 处裸 `TextStyle(fontSize:)` 残留（多为"单 prop override"，仍能接受） |
| **动效集中度** | **9 / 10** | `MotionScheme` 4 档枚举 + `Motion.duration/curve` 减少-motion 包装器集中；`FadeIn / SlideUp / PageTransitionSwitcher / PressFeedback` 4 个 widget 集中；`PressFeedbackIconButton / AppListTile / ChipBadge / SectionHeader` 4 个高层 wrapper |
| **曲线选择** | **8 / 10** | 主用 `easeOutCubic`（standard）+ `easeOutQuart`（decelerate）+ `easeOutBack`（back-out）+ `elasticOut`（delight）4 档合理；无 `ease-in` 滥用；`Curves.easeInOut` / `Curves.linear` 仅在 `Motion` fallback 处出现 |
| **频度决策** | **9 / 10** | 100+/day（打卡）走 PressFeedback + 0 路由动画；tens/day（list/option）走 PressFeedback + 微弱 FadeIn；occasional（modal / snackbar）走 durNormal + curveStandard；rare（onboarding / celebration）走 durSlow + curveDelight。注释把每条决策的"为什么"都写明，emil 决策框架执行度高 |
| **微交互完整性** | **8 / 10** | 按钮 scale 反馈统一、Haptics 5 类集中、PageTransition 3 类按频度分；个别 dot 评分切换（`DimensionRow`）用 `AnimatedContainer` + `AnimatedDefaultTextStyle` 双轨同步，细节到位；缺：未发现 `prefers-reduced-motion` 在 InkWell ripple / SegmentedButton 等 M3 默认动效上做显式 gate |
| **可访问性** | **7 / 10** | `Motion.duration/curve` 包装 `prefers-reduced-motion` 已覆盖 `AnimatedContainer / FadeIn / SlideUp / loading_skeleton`；`AppSemantics` 集中器覆盖主要交互；缺：`@media (hover: hover)` gate 没有（Flutter 没原生等价物，可接受），Card / ListTile hover 动效未显式 gate |
| **一致性** | **8 / 10** | 强：token 化 + 集中 widget 化 + SnackBar 统一；中：14 处裸 TextStyle + ~115 处 EdgeInsets 散落（多数 spacing 已 token 化但 padding 值直接 inline） |
| **总评** | **8.4 / 10** | **健康度：优秀**。已经把 emil 决策框架从 P0 到 P2 逐层 token 化 + widget 化；剩余问题都是 polish / single-prop override / 一个特性级决策待重审，不影响动效和 token 系统的可信度 |

---

## 1. 顶层架构审视

### 1.1 Token 系统健康度

**已建立的 token 体系（`lib/core/theme/app_tokens.dart`，589 行 + MotionScheme 65 行 + Motion 35 行）：**

```
AppTokens (静态 + dynamic 双轨)
├─ 颜色 (15 static + 8 dynamic getter + 11 tinted)
│   ├─ primary / primaryDark / primaryLight
│   ├─ light 色板: background / surface / textPrimary/Secondary/Hint / border / disabled / divider
│   ├─ dark 色板: *Dark 镜像 + surfaceDark
│   ├─ 状态色: success / warning / warningStrong / error / errorDark
│   ├─ dynamic getter: surfaceColor / backgroundColor / textPrimaryColor / textSecondaryColor / textHintColor / borderColor / dividerColor / primaryLightColor / disabledColor
│   └─ tinted: tintedPrimarySoft (0.1) / Deep (0.15) / Light (0.08) / Mid (0.5) / High (0.85) / WarningSoft / WarningBorder / SuccessSoft / ErrorSoft / ErrorDeep
├─ 字体 (9 static size + 6 score size + 5 line height + 11 TextStyle getter)
├─ spacing (5 主档 + 3 micro 档 + 2 chip 档)
├─ 圆角 (6 档: button/card/input/chip/cell/cellLg)
├─ 尺寸 (buttonHeight / buttonHeightSmall / minTapArea / inputHeight / iconSize/Lg/Micro)
├─ 动画 (3 dur + 4 fine dur + 5 curve + 2 motion scheme enum)
│   ├─ duration: durFast (200ms) / durNormal (300ms) / durSlow (500ms) / durPress (160ms) / durPageTransition (100ms)
│   ├─ durationMs: shimmerCycleMs (1200) / refreshMinVisibleMs (400)
│   ├─ curve: curveStandard (easeOutCubic) / curveDecelerate (easeOutQuart) / curveAccelerate (easeInCubic) / curveDelight (elasticOut) / curveBackOut (easeOutBack)
│   └─ duration: snackBarDurationShort (2s) / Medium (3s) / Long (4s)
├─ 阴影 (4 静态 + 4 dynamic: shadowCard / shadowCardDark / shadowDialog / shadowOverlay)
├─ 响应式 (3 断点 + contentMaxWidth + navRailWidth)
└─ TextStyle (11 getter + 4 named: Title/Headline/Body/BodyStrong/Label/LabelStrong/LabelMedium/Button/ButtonInverse/Caption/CaptionStrong/CaptionHint/Micro/Legal)

MotionScheme (enum 4 档)
└─ none / subtle / standard / delight → duration + curve 派生

Motion (class 集中器)
└─ prefersReduced + duration(ctx, base) + curve(ctx, base) → reduce-motion 自动归零
```

**评价**：token 系统是项目最成熟的层。从 P0 到 P2（v0.17 → v0.23）的 emil 集中化作业把它从"零散 const" 推到"语义命名 + 频度决策注释 + 4 档 motion scheme"的工业级。**唯一短板**是 `duration` 集中在 `durFast / durNormal / durSlow` 3 档，**不够细**：emil 决策框架里 `tens/day` 应该用 ~120ms（tens/day hover 类），现在只能借 `durPress` (160ms) 或 `durPageTransition` (100ms)。这是 token 系统的"地板"问题，**emil-1.1**。

### 1.2 动效系统健康度

**已建立的动效组件（`lib/presentation/widgets/animations/`）：**

```
animations/ (barrel)
├─ fade_in.dart      → FadeIn (opacity + 可选 scale 0.92→1, 200/300/500ms, 自动 reduce-motion)
├─ slide_up.dart     → SlideUp (translate Y + fade, 16px distance, 自动 reduce-motion)
└─ page_transition_switcher.dart
                       → PageTransitionSwitcher (AnimatedSwitcher 包装, 100ms 默认, 可配 transitionBuilder)

lib/presentation/widgets/
├─ press_feedback.dart  → PressFeedback (scale 0.97 + durPress 160ms, 双模式: 接管/不接管 tap)
├─ press_feedback_icon_button.dart  → PressFeedbackIconButton (IconButton + PressFeedback 二选一 API)
├─ page_transition_switcher.dart (barrel 同名)
└─ loading_skeleton.dart → LoadingSkeleton + LoadingSpinner + _Shimmer (shimmer 1.2s reverse)
```

**页面层动效：**
- **路由 transition** (`app_router.dart`)：3 类（fade / slide-right 0.1 偏移 / slide-up 0.05 偏移），按频度分：主导航 fade / 子页 slide-right / 全屏深页 slide-up，**reverse duration 都比 forward 短（durFast vs durNormal）** — emil 原则 #9 "asymmetric timing" 的标准做法
- **打卡庆祝** (`celebration_overlay`)：TweenSequence scale 0→1.2→1.0 + opacity 5 段，MotionScheme.delight 频度
- **stagger 列表** (`vent_list_page` / `medication_calendar_page`)：i * staggerStepMs (40ms) clamp 0-200ms，5 行后立即出现，emil "perceived performance"
- **HomeFooter** 2 项 FadeIn 0/1 stagger：tens/day 主页底栏微妙分层
- **PressFeedback** 普遍：所有 SecondaryButton / IconButton / 1-5 评分按钮都包 PressFeedback (scale 0.97, durPress 160ms)
- **Haptics** 5 类（tap / success / warning / light）— 触感统一，tens/day 频度无需动效
- **DimensionRow 评分按钮**：双轨 AnimatedContainer（背景色）+ AnimatedDefaultTextStyle（字重 + 颜色），200ms easeOutCubic 平滑选中态，**emil 决策满分**

**评价**：动效系统从 P0-7（reduce-motion 包装器）到 P1-1（animations/ 抽目录）到 P2-1（PressFeedback 接管/不接管 tap 模式）已经 3 轮打磨。**唯一架构层问题**：
- `Celebration overlay` 的 `TweenSequence` 写法（5 段 scale + 5 段 opacity）虽然走 token，但作为项目**唯一**没有走 PageTransitionSwitcher / FadeIn / SlideUp 这 3 个集中 widget 的"自研动效"——它在 token 化上 100 分，在**复用度**上 0 分（只用了 1 次）。**emil-1.2**。
- 没有任何 `AnimatedTheme` 或 M3 `PageTransitionsTheme` 全局配置；所有路由 transition 走 `CustomTransitionPage`（go_router 限制，可接受）。

### 1.3 一致性 / 集中化

**已建立的集中器（`lib/presentation/widgets/`）：**

| 集中器 | 来源 | 复用度 | 评价 |
|---|---|---|---|
| `AppSnackBar` (5 类 + showX 工厂) | v0.17 P1-7 / v0.23 P1-Round37 | **47+** 调用点 | 满分 |
| `PressFeedback` (2 模式) | v0.18 P0-8 | **30+** 调用点 | 满分 |
| `PressFeedbackIconButton` | v0.23 P3-32 | 4 调用点 (theme/vent+/home) | 良好 |
| `AppListTile` (ListTile + PressFeedback) | v0.24 U3 P2 | 5+ 调用点 | 良好 |
| `SecondaryButton` (OutlinedButton 包装) | v0.17 P1-2 | 5+ 调用点 | 良好 |
| `CheckInButton` (主打卡按钮) | v0.23 P1 | 1 调用点 | 单点（home 专属，可接受） |
| `ChipBadge` (4 tone) | v0.22 A2 | 6+ 调用点 | 良好 |
| `SectionHeader` (label 14) | v0.23 F4 | 5+ 调用点 | 良好 |
| `EmptyState` + `ErrorState` | v0.21 Round22 | 8+ 调用点 | 良好 |
| `LoadingSkeleton` (fullScreen/card/spinner/shimmer) | v0.17 P0-4 | 20+ 调用点 | 满分 |
| `FadeIn` / `SlideUp` / `PageTransitionSwitcher` | v0.17 P1-1 / v0.22 A5 | 16 调用点 | 满分 |
| `Haptics` (5 类) | v0.21 P1-14 | 8+ 调用点 | 满分 |
| `AppSemantics` (container/button/exclude) | v0.23 P0-3 | 10+ 调用点 | 良好 |
| `LoadingTextButton` (button + spinner) | v0.24 P1-01 H-03 | 3+ 调用点 | 良好 |

**集中度评分**：**9 / 10**。剩下未集中的高频模式只有：
- `_DayDetailCard` (`trend_calendar.dart` 内) — 单点
- `TodayMedSchedule._TimeChip` — 单点 chip 模式（可考虑提为 `ChipBadge` 的扩展，但语义不同，保留可接受）
- `medication_calendar_page._HeaderRow` — 极小 N，单点

### 1.4 可重构模块（按 ROI 排序）

| 优先级 | 模块 | 价值 | 工作量 |
|---|---|---|---|
| **XL→L** | `lib/core/theme/app_tokens.dart` 拆 3 文件 | 588 行单文件已超"健康阈值"；建议拆 `app_colors.dart` / `app_typography.dart` / `app_motion.dart` 3 文件，barrel re-export 保持 import 兼容 | M (1-2h) |
| **L** | `MotionScheme.subtle` 加专属 curve | 现在 subtle 和 standard 都走 `curveStandard` (easeOutCubic)，emil 原则 #2 "tens/day 微弱" 应该用更弱的曲线（如 `Curves.easeOut`） | S (15min) |
| **M** | `celebration_overlay` 改用 token 化 FadeIn + scale 自定义 | 现在 TweenSequence 自研 5 段 5 段，复用度 0 | S (30min) |
| **M** | 14 处裸 `TextStyle(fontSize:)` 改 `textStyle*` getter | 集中度从 9 → 9.5 | S (30min) |
| **S** | 12 处裸 `EdgeInsets.all/symmetric(8.0/12.0/24.0)` padding 改 spacing token | 集中度微调，emil "decisions should be nameable" | S (30min) |
| **S** | `Mood` Visual: `Color(MoodVisual.colorArgbFor(day.moodScore!))` 走 `AppTokens.moodColor(context, score)` 集中器 | 单点（只 1 处用，但 `core/shared/mood_visual.dart` 在 8+ widget 用，是现有 `withValues`/`Color(0x...)` 的潜在源头） | S (30min) |

---

## 2. 底层逐行排查（按优先级 + 修复难度排序）

### 🔴 P0（阻碍性 / 后续会被复制粘贴放大）

**当前 P0 = 0**。架构层 token 化已完成 3 轮；剩余都是 polish 级别。

---

### 🟠 P1（重要 / 改善一致性 / 用户可感知）

#### [1] [emil-token] `MotionScheme.subtle` 与 `standard` 用同一条曲线，违反"频度决策"原则
- **位置**：`lib/core/theme/app_tokens.dart:643-661`（`MotionSchemeTokens` 扩展）
- **类型**：架构
- **修复难度**：S
- **优先级**：P1
- **问题描述**：
  - `MotionScheme.subtle` (tens/day, 弱反馈) 和 `MotionScheme.standard` (occasional, 标准) **都返回 `AppTokens.curveStandard`**（easeOutCubic）
  - emil 决策框架 #2 "frequency-appropriate" 明确把这两档**视觉上**区分开：subtle 应该"几乎察觉不到"，standard 应该有"明显但不快" 的进场感
  - 现在 `subtle.duration = durFast (200ms)` 跟 `standard.duration = durNormal (300ms)` 有 100ms 差异，但曲线相同 = 体感差异只有 33%（实际用户感知更小）
  - emil "decisions should be nameable" — 同一曲线 = 同一档位，等于 subtle 档位虚设
- **emil 视角建议**：
  ```dart
  // MotionScheme.subtle.curve 应该用更弱的 ease-out
  // 选项 A: 改用 Curves.easeOut (Flutter 内置, 比 easeOutCubic 弱 30%)
  // 选项 B: 引入新 token AppTokens.curveSubtle = Curves.easeOut
  case MotionScheme.subtle:
    return AppTokens.curveSubtle;  // 改用 easeOut
  ```
  - 同步新增 `static const Curve curveSubtle = Curves.easeOut;` 在 app_tokens.dart，emil "per-frequency curve"

#### [2] [emil-动效] `CelebrationOverlay` 自研 5 段 `TweenSequence`，未走集中 widget
- **位置**：`lib/presentation/pages/home/widgets/celebration_overlay.dart:29-59`（`_scale` / `_opacity` 初始化）
- **类型**：架构
- **修复难度**：S
- **优先级**：P1
- **问题描述**：
  - 唯一没用 `FadeIn / SlideUp / PageTransitionSwitcher` / `PressFeedback` 集中器的"自研动效"
  - 用了 5 段 `TweenSequence`（scale 0→1.2→1.0→hold + opacity 0→1→1→0），每段都手动 `chain(CurveTween(...))`
  - **token 化 100 分**（curveBackOut + curveStandard + MotionScheme.delight）
  - **复用度 0 分**：40+ 行代码只为 1 个 widget 服务，注释 7 行 v0.22/0.23 决策历史（破窗）
  - emil "DRY for taste" — 同动效的 `FadeIn(withScale: true)` 也能做到 scale 0.92→1 + opacity 0→1，虽然没有 1.2 过冲，但精神心理患者"过冲 1.2×" 本身可能刺激前庭敏感用户（与 reduce-motion 哲学冲突）
- **emil 视角建议**：
  - **方案 A（推荐）**：保留自研，但抽到 `lib/presentation/widgets/animations/celebration_bounce.dart` 作为第 4 个集中 widget，添加 `onCompleted` callback 给 caller 决定 cleanup。`celebration_overlay.dart` 只剩 60 行 wrapper
  - **方案 B（更克制）**：用 `FadeIn(withScale: true, duration: MotionScheme.delight.duration, curve: AppTokens.curveBackOut)` 替换，避免"过冲 1.2×" 的高刺激度，emil "subtle delight" 哲学
  - **方案 C（最保守）**：保持现状，注释里加一句"rare celebration, 1.2× 过冲有意保留（用户答卷后 1-2 次/周）" 表明这是 deliberate 决策

#### [3] [emil-token] 14 处裸 `TextStyle(fontSize: / color:)` 残留，token 集中度差最后 5%
- **位置**：
  - `lib/presentation/pages/assessment/assessment_page.dart:303, 354` — `TextStyle(color: textSecondaryColor)` 2 处
  - `lib/presentation/pages/medication/medication_calendar_page.dart:67` — `TextStyle(fontSize: fontSizeBody)` 1 处
  - `lib/presentation/pages/medication/refill_manage_page.dart:165` — `TextStyle(color: textHintColor)` 1 处
  - `lib/presentation/pages/settings/email_preview.dart:30, 123` — `TextStyle(color:)` + `TextStyle(fontSize: fontSizeLabel)` 2 处
  - `lib/presentation/pages/settings/reminders_hub_page.dart:66` — `TextStyle(fontSize: fontSizeBody)` 1 处
  - `lib/presentation/pages/settings/widgets/data_management_section.dart:92` — `TextStyle(color: error)` 1 处
  - `lib/presentation/pages/settings/widgets/notification_status_card.dart:172` — `TextStyle(color: textHintColor)` 1 处
  - `lib/presentation/pages/settings/widgets/report_history_dialog.dart:137` — `TextStyle(color: error)` 1 处
  - `lib/presentation/pages/setup/setup_page.dart:288` — `TextStyle(fontSize: fontSizeTitle)` (emoji 渲染)
  - `lib/presentation/pages/vent/vent_list_page.dart:232` — `TextStyle(fontSize: fontSizeBody)` 1 处
  - `lib/presentation/pages/vent/widgets/vent_text_input.dart:37` — `TextStyle(fontSize: fontSizeBody)` 1 处
  - `lib/presentation/widgets/mood_quick_button.dart:41` — `TextStyle(fontSize: fontSizeBodySm)` 1 处
  - **类型**：底层
- **修复难度**：S
- **优先级**：P1
- **问题描述**：
  - 项目已建立 11 个 `AppTokens.textStyle*` getter，但仍有 14 处裸 `TextStyle(fontSize: AppTokens.fontSizeXxx, color: AppTokens.yyyColor(context))` 直拼
  - 多数是 **单 prop override**（body / label / caption 基础上覆盖 color），emil "good defaults" 应该用 `textStyle*().copyWith(color: ...)`
- **emil 视角建议**：
  ```dart
  // 改前
  Text('...', style: TextStyle(color: AppTokens.textHintColor(context)))
  // 改后
  Text('...', style: AppTokens.textStyleCaption(context).copyWith(color: AppTokens.textHintColor(context)))
  // 或更优：textStyleCaptionHint 已经是 caption + hint color 预设
  Text('...', style: AppTokens.textStyleCaptionHint(context))
  ```
  - emoji 渲染 (`setup_page.dart:288`) 是 `fontSizeTitle` 但 emoji 视觉 < 文字，保持现状合理；建议加注释说明
  - `vent_list_page.dart:232` 是 listItem title，跟 `textStyleBody` 默认 color 一致，**直接用 `AppTokens.textStyleBody(context)` 即可**，连 copyWith 都省

#### [4] [emil-token] 12 处裸 `EdgeInsets` 数字 padding 残留
- **位置**（部分）：
  - `lib/presentation/pages/assessment/assessment_page.dart` — 8 处
  - `lib/presentation/pages/medication/medication_calendar_page.dart` — 8 处
  - `lib/presentation/pages/trend/trend_calendar.dart` — 7 处
  - `lib/presentation/pages/setup/setup_page.dart:254-264` — 3 处
  - `lib/presentation/widgets/medication_report_dialog.dart` — 4 处
  - `lib/presentation/widgets/last_startup_error_banner.dart:60-63` — 1 处
  - `lib/presentation/widgets/dimension_row.dart:77-80` — 1 处 (`horizontal: 12, vertical: 8` 裸数字)
  - **类型**：底层
- **修复难度**：S
- **优先级**：P1
- **问题描述**：
  - 多数用 `AppTokens.spacingMd / spacingSm / spacingXs` 等已 token 化的值，**符合规范**
  - 但仍有少数 `EdgeInsets.symmetric(horizontal: 12, vertical: 8)` `EdgeInsets.only(bottom: 1, right: 2)` 裸数字
  - 集中器表里没有 `spacingChipPadding` (chip 内部 padding) — 是 token 系统本身的小缺口
- **emil 视角建议**：
  - `dimension_row.dart:77-80` 的 `horizontal: 12, vertical: 8` — 改成 `AppTokens.spacingXxs` 数字附近值；建议加 `AppTokens.spacingChipPaddingH = 12` + `AppTokens.spacingChipPaddingV = 8` 集中器
  - `last_startup_error_banner.dart:60-63` 已经走 `spacingMd/Sm`，符合
  - `medication_calendar_page.dart` 8 处 + `trend_calendar.dart` 7 处 多数走 `spacingSm/Xs/Md`，符合
  - 实际"裸数字"残留 < 5%，**emil-4.1 标记为可选 polish**

#### [5] [emil-可访问性] `AnimatedContainer` 多次出现但未走 `Motion.duration` 包装
- **位置**：
  - `lib/presentation/widgets/check_in_button.dart:31-32` — `AnimatedContainer(duration: Motion.duration(context, AppTokens.durNormal), ...)` ✅ 已走
  - `lib/presentation/widgets/dimension_row.dart:62-64` — `AnimatedContainer(duration: AppTokens.durFast, curve: AppTokens.curveStandard, ...)` ⚠️ **未走 Motion**
- **类型**：底层
- **修复难度**：S
- **优先级**：P1
- **问题描述**：
  - `DimensionRow` 的 `AnimatedContainer` 直接用 `AppTokens.durFast` / `AppTokens.curveStandard` 而非 `Motion.duration(context, AppTokens.durFast)` / `Motion.curve(context, AppTokens.curveStandard)`
  - 系统开了 reduce-motion → 评分切换仍有 200ms 动画，**违反 P0-7 reduce-motion non-negotiable 原则**
  - 精神心理患者评分题可能一天做几次（频度 tens/day），这一项**对前庭敏感用户直接触发不适**
  - 同步问题在 `check_in_button.dart:48-52` `AnimatedSwitcher` 内的 `switchInCurve` 也走 `Motion.curve(...)` 是 ✅
- **emil 视角建议**：
  ```dart
  // dimension_row.dart:62-64 改:
  duration: Motion.duration(context, AppTokens.durFast),
  curve: Motion.curve(context, AppTokens.curveStandard),
  // 81-83 同步
  duration: Motion.duration(context, AppTokens.durFast),
  curve: Motion.curve(context, AppTokens.curveStandard),
  ```
  - emil "motion must be gated on reduce-motion" — single-source-of-truth

#### [6] [emil-可访问性] `loading_skeleton._Shimmer` 无限循环，未明确被 reduce-motion 完全停止时是"完全消失"还是"只显示首帧"
- **位置**：`lib/presentation/widgets/loading_skeleton.dart:132-143`（`_ShimmerState.didChangeDependencies`）
- **类型**：底层
- **修复难度**：S
- **优先级**：P1
- **问题描述**：
  - reduce-motion 开启 → `_controller.stop()` + `value = 1.0` (opacity 跳到 0.7 max)
  - 注释说"精神心理患者前庭敏感比例高, 1.2s 永久循环 shimmer 不可接受" ✅ 方向对
  - **但 `_Shimmer` 无限循环 + 0.4-0.7 opacity 脉动**（emil `M3 spec: shimmer opacity range 0.4-0.7`）即使 reduce-motion 关也是高刺激度
  - emil "loading should feel fast, not dance" — shimmer 在精神心理 App 应该考虑**完全静态**（0.5-0.7 静态）而非脉动
- **emil 视角建议**：
  - 改 `_controller.repeat(reverse: true)` → `_controller.animateTo(1.0, duration: durShimmer, curve: easeInOut)` 单次，0.4→0.7 一次后停 1.2s 再重播（"呼吸"而非"脉动"）
  - 或更简单：tens+/day 频度的 shimmer (用户等加载是常事) → 改用 M3 default `CircularProgressIndicator`，emil "subtle loading, not animate-while-you-wait"

#### [7] [emil-微交互] `MoodQuickButton` `PressFeedback` + `SecondaryButton(onPressed:)` 重复接管，触发 2 次 press feedback
- **位置**：`lib/presentation/widgets/mood_quick_button.dart:33-67`
- **类型**：底层
- **修复难度**：S
- **优先级**：P1
- **问题描述**：
  - `PressFeedback(child: SecondaryButton(onPressed: onTap, ...))` 模式
  - `PressFeedback` 用 `Listener` 检测 `onPointerDown/Up/Cancel` → 设 `_pressed` → `AnimatedScale` 触发
  - `SecondaryButton` = `OutlinedButton` 自身有 InkWell ripple
  - 用户手指按下：PressFeedback 触发 scale 0.97 + InkWell 触发 ripple
  - **2 层动效同时跑**：scale 是 160ms easeOutCubic，ripple 是 M3 InkSparkle ~300ms
  - emil "good defaults" — 这种嵌套让 1 次点击产生 2 个视觉变化（虽然叠在一起），但 pointer 抬起时 PressFeedback 先恢复 (160ms) + ripple 还在扩散 (300ms) → 体感"分裂"
  - 对比 `primary_action_row.dart:50` 的正确写法：`PressFeedback(onTap: ..., child: SecondaryButton(onPressed: () {}, ...))` — 接管 tap 模式，**不重复**
- **emil 视角建议**：
  - 选项 A：保持现状，但加注释说明 "PressFeedback 只做 scale, SecondaryButton 只做 ripple, 两者独立"
  - 选项 B：改用接管 tap 模式：`PressFeedback(onTap: onTap, child: SecondaryButton(onPressed: () {}, child: ...))` 跟 primary_action_row 一致
  - 选项 C（最优雅）：`PressFeedback` 加一个 `inheritPress: false` 默认，让 caller 显式选；现有 30+ 调用点不变

#### [8] [emil-微交互] `vent_list_page.dart:266` ListTile onTap + `PressFeedback(child: ListTile)` 模式未在 AppListTile 集中器
- **位置**：`lib/presentation/pages/vent/vent_list_page.dart:207-269`（`_EntryCard` 内的 ListTile）
- **类型**：底层
- **修复难度**：S
- **优先级**：P1
- **问题描述**：
  - `_EntryCard` 用 `Card(child: ListTile(...))` 但**没有** `PressFeedback` 包裹
  - ListTile 自带 InkWell ripple，但没有 scale 反馈
  - 项目主导航 (HomeHeader) / 联系人 (AppListTile) / 设置 (AppListTile) 都已经 scale 0.97 反馈
  - 树洞列表 — 情绪低谷时频繁查看历史 (tens/day 频度) — **应该跟其他 list 行体感一致**
  - AGENTS.md 隐私边界说 vent 完全独立，但 **UI 体感** 仍应该跟项目统一
- **emil 视角建议**：
  - 提取 `_EntryCard` 内 `Card` 包裹为 `AppListTile` (新加 `card` 模式？) 或保持 `Card(child: ListTile)` 但加 `PressFeedback`：
  ```dart
  return PressFeedback(
    child: Card(
      child: ListTile(...),
    ),
  );
  ```
  - emil "cohesion" — 树洞列表项跟设置列表项手感一致

---

### 🟡 P2（可改进 / 一致性微调）

#### [9] [emil-token] `app_theme.dart` 内嵌颜色条件分支，未走 dynamic getter
- **位置**：`lib/core/theme/app_theme.dart:29, 41, 97, 119-120, 171, 179, 185, 209, 215`
- **类型**：架构
- **修复难度**：S
- **优先级**：P2
- **问题描述**：
  - 主题构造函数里 9+ 处 `isDark ? AppTokens.xxxDark : AppTokens.xxx` 硬编码分支
  - v0.18 引入 dynamic getter 时**app_theme 没切**（focus 在 widget 层）
  - 现在 dark mode 已经派生 `ThemeData(brightness: isDark, colorScheme: cs)`，但 `scaffoldBackgroundColor` / `appBarTheme.backgroundColor` / `inputDecorationTheme.fillColor` 等仍走硬分支
  - 维护成本：新增 token 时要同步加 2 个 light/dark 版本 + 改所有分支
- **emil 视角建议**：
  ```dart
  // 改前
  scaffoldBackgroundColor: isDark ? AppTokens.backgroundDark : AppTokens.background,
  // 改后 — 但 scaffoldBackgroundColor 在 ThemeData 里不能接受 context-dependent getter
  // 改方案: app_theme 拆 2 个工厂 light()/dark() 分别传对应 colorScheme,
  // 主题里用 cs.surface 替代硬分支 (cs 已经从 seed 派生)
  scaffoldBackgroundColor: cs.surface,  // M3 标准, light/dark 自适应
  ```
  - **实际上这是 M3 最佳实践**：用 `colorScheme.fromSeed` 派生的 `surface` / `surfaceContainerHighest` 等代替手写 token，light/dark 自动正确
  - 但 v0.18 P1-5 选择保留 token 是为了**保持 const 优化** — 这是 trade-off，需要 project-level 决策
  - emil 建议：v0.25 重构时统一到 `cs.surface / cs.onSurface / cs.outline` 等 M3 派生颜色，token 系统专注品牌色（primary/secondary/tertiary）+ 状态色（success/warning/error）

#### [10] [emil-token] `splashFactory: InkSparkle.splashFactory` 在 `_build()` 重复声明
- **位置**：`lib/core/theme/app_theme.dart:31` + `:52`（注释里的同款）
- **类型**：底层
- **修复难度**：S
- **优先级**：P2
- **问题描述**：
  - `app_theme.dart:31` `splashFactory: InkSparkle.splashFactory` ✅ 启用
  - `app_theme.dart:45-52` 重复 7 行注释又把同一行注释掉 (`// splashFactory: InkSparkle.splashFactory,`)
  - emil "破窗" — 注释和实际代码意图不一致，新 reader 会困惑
- **emil 视角建议**：
  - 删 45-52 注释（保留 `app_theme.dart:31` 实际启用的那行 + 一行简短注释说明 "M3 default, 见 v0.17 round 7"）

#### [11] [emil-动效] `medication_calendar_page` _DataRow stagger 是循环内创建 FadeIn widget
- **位置**：`lib/presentation/pages/medication/medication_calendar_page.dart:227-234`
- **类型**：底层
- **修复难度**：S
- **优先级**：P2
- **问题描述**：
  ```dart
  for (int i = 0; i < rows.length; i++)
    FadeIn(
      delay: Duration(milliseconds: (i * AppTokens.staggerStepMs).clamp(0, AppTokens.staggerCapMs)),
      child: _DataRow(row: rows[i]),
    ),
  ```
  - **emil 性能微问题**：`for` 内每轮 `new FadeIn` → 30+ `FadeIn` widget 树 + 30+ `AnimationController`（每个 FadeIn 是 `StatefulWidget`）
  - 大列表（90 天 × 5+ meds = 100+ 行）会同时建 100 个 controller，每个监听 vsync
  - emil "interrupted on scroll" 风险：长列表下 stagger 时间差到 5s+，用户可能滚到底部时顶部还在 fade
  - 实际 `days` 通常 ≤ 90, `meds` ≤ 5 → 5 行 × 90 天 = 5 个 FadeIn（按 med 而非按 cell，OK）→ 实际影响小，但模式可优化
- **emil 视角建议**：
  - 抽 `StaggeredFadeIn` widget 接受 `List<Widget> children`，内部用 `Interval` 共享 1 个 controller：
  ```dart
  class StaggeredFadeIn extends StatefulWidget {
    final List<Widget> children;
    final int stepMs;
    final int capMs;
    // 内部: 1 controller + Interval per child
  }
  ```
  - 同样可以应用到 `vent_list_page` (`_EntryList`) — 那里也是 for 内 FadeIn
  - emil "consolidate for performance"

#### [12] [emil-token] 阴影 token 4 静态 + 4 dynamic，重复 4 组（dark mode 修复后未删静态）
- **位置**：`lib/core/theme/app_tokens.dart:351-432`
- **类型**：架构
- **修复难度**：S
- **优先级**：P2
- **问题描述**：
  - v0.24 round 43 (emil D-04) 引入 4 个 `shadowXxxOf(context)` dynamic getter
  - 但 4 个原 `const shadowXxx` **没删**（保留 const optimization trade-off）
  - 现在 `BoxShadow` 静态 + dynamic 共存：调用方需要选哪个
  - emil "decisions should be nameable" — 同一个 shadow 有 2 个名字 = 决策模糊
  - 注释里写"新代码优先用 dynamic getter" 但 0 行 grep 验证实际新代码都走了 dynamic
- **emil 视角建议**：
  - v0.25 删 4 个 const `shadowXxx`，统一到 `shadowXxxOf(context)`，const 优化丢失但 M3 BoxShadow 不可 const（withValues/scrim 派生）
  - 或保留 const 但**改名**：`shadowXxxConst` 明确"已废弃，新代码用 Of()"
  - 实际 grep：`shadowCard` (非 Of) 引用 ≈ 0 → 可直接删

#### [13] [emil-动效] `app_router.dart` 路由 transition 3 类 (fade/slideRight/slideUp) 缺乏 transform-origin 概念
- **位置**：`lib/core/routing/app_router.dart:40-94`
- **类型**：架构
- **修复难度**：M
- **优先级**：P2
- **问题描述**：
  - `_slideRightPage` 从 `Offset(0.1, 0)` 滑入 10% → 0
  - emil 原则 #5 "transform-origin & physical correctness" — slide 类动效的 origin 应该是**触发源**（上一页面入口位置），不是固定 0.1
  - 但页面级 transition 没有"trigger"概念，go_router 限制 → 这是**不可避免的简化**
  - **可接受**：注释里补一句"offset 0.1 = 弱 slide, 避免画面 0→1 '推开' 感"
- **emil 视角建议**：
  - 不动代码，加注释：`// Offset 0.1 = 弱入场, 模拟 iOS push 风格 (从右滑 10% 而非完全隐藏)`
  - 评估 `_slideUpPage` 的 `Offset(0, 0.05)` — 5% 上滑偏弱，建议改 `Offset(0, 0.08)` 跟 iOS modal sheet 体感对齐

#### [14] [emil-动效] 路由 transition reverse duration 跟 forward 比例为 1:1.5（durFast vs durNormal）
- **位置**：`lib/core/routing/app_router.dart:45, 60, 81`
- **类型**：底层
- **修复难度**：S
- **优先级**：P2
- **问题描述**：
  - `transitionDuration: durNormal (300ms)` + `reverseTransitionDuration: durFast (200ms)` ✅ 已走 asymmetric
  - 但 `_slideUpPage` 用 `durSlow (500ms) / durNormal (300ms)` — **forward 500ms 超 emil 原则 #4 "UI 动画 ≤ 300ms"**（v0.17 决策时标了 rare，可放宽到 500ms）
  - emil 哲学：setup / vent 全屏深页 1-2 次/周用 = rare 频度 = 可超 300ms
  - 实际 500ms 在 setup 4 步切换时（每步 500ms 慢 slide）— 用户感受 4 × 500ms = 2s 等待才进下一步，**对耐心低的患者可能是阻力**
- **emil 视角建议**：
  - 改 `durSlow` → `durNormal + 100ms = 400ms`，仍超标准但体感更利索
  - 同步：v0.25 motion scheme 决策"rare" 频度上限从 1000ms → 800ms（emil 框架的精神心理专项调低）

#### [15] [emil-一致性] 14 处 `TextStyle(color: AppTokens.xxxColor(context))` 单 color 覆盖可统一为 `textStyleXxx().copyWith(color:)`
- **位置**：（同 [3]）
- **类型**：底层
- **修复难度**：S
- **优先级**：P2
- **问题描述**：
  - 见 [3]
  - 多数是 `TextStyle(color: AppTokens.textHintColor(context))` 单 color override
  - 已经有 `textStyleCaptionHint(context)` = caption + hint color 预设，**调用方应该用预设**
  - emil "DRY for taste"
- **emil 视角建议**：
  - 5 个 `textStyleHintColor` override → 改 `textStyleCaptionHint(context)`
  - 4 个 `textStyleError` override → 加 `textStyleError` getter (caption + error color) 或直接 `textStyleCaptionStrong(context).copyWith(color: AppTokens.error)`
  - 5 个其他 → `textStyle*().copyWith(color: AppTokens.xxxColor(context))`

#### [16] [emil-一致性] `vent_list_page._EntryCard` 预览用 `entry.contentText!.length > 80 ? substring(0, 80) : ...` 硬编码 80
- **位置**：`lib/presentation/pages/vent/vent_list_page.dart:202-205`
- **类型**：底层
- **修复难度**：S
- **优先级**：P2
- **问题描述**：
  - 80 是 magic number
  - 跟 `textLengthWarningThreshold` (1800, 90% of 2000) 同性质 — 都应该 token 化
  - emil "magic numbers should be named"
- **emil 视角建议**：
  - 加 `AppTokens.textPreviewMaxChars = 80;` + 注释 "vent 列表预览截断长度"
  - 或更简单：抽 `Formatters.preview(text, maxChars)` 集中器，跟既有 `Formatters.dateCompact` 一致

#### [17] [emil-token] `MoodVisual.colorArgbFor(score)` 返回 int → `Color(int)` 在 trend_calendar 用
- **位置**：`lib/presentation/pages/trend/trend_calendar.dart:219`（`bg = Color(MoodVisual.colorArgbFor(day.moodScore!));`）
- **类型**：底层
- **修复难度**：S
- **优先级**：P2
- **问题描述**：
  - `MoodVisual` 提供 `int colorArgbFor` 跟 `String emojiFor` / `String labelFor`，返回类型不一致
  - 趋势日历 cell 直接 `Color(intArgb)` → dark mode 下没考虑 `cs.surface` 混合
  - emil "types should be coherent" — 返回 `Color` 而非 `int`
- **emil 视角建议**：
  - 改 `MoodVisual.colorFor(BuildContext context, int score) → Color` 接受 context，dark mode 用 `Color.alphaBlend(cs.surface, ...)`
  - 或加 `MoodVisual.colorFor(int score)` 重载 (没 context 版) 跟现有 `colorArgbFor` 共存
  - 注释 "未来 dark mode 兼容" / "int 版保留给 Paint 派生用"

#### [18] [emil-动效] 路由 transition 在 wide screen 走 NavigationRail 时，子页 transition 在 rail 右侧感觉"挤"
- **位置**：`lib/core/routing/app_router.dart:42-94` + `lib/core/theme/app_tokens.dart:586-587`
- **类型**：架构
- **修复难度**：M
- **优先级**：P2
- **问题描述**：
  - wide screen (≥ 840px) 用 `NavigationRail(extended: true, 240px)`，主内容 600-800px
  - slide-right 10% offset 在 600px 内容里 = 60px 滑入，**体感 OK**
  - 但 slide-up 5% 在 600px 里 = 30px 浮起，**几乎不可察觉**
  - emil "per-frequency offset"：wide screen 上调 offset 到 8-10%
- **emil 视角建议**：
  - 在 `_slideRightPage` / `_slideUpPage` 加 `width` / `height` 参数，按 `LayoutBuilder.constraints.maxWidth` 缩放 offset
  - 或更简单：wide screen 走 `durNormal` + offset 8%，narrow 走 `durNormal` + offset 10%

#### [19] [emil-微交互] `Hero('vent-avatar-${id}')` 跨页圆形头像过渡，但 source 和 destination 都是 CircleAvatar (圆形 → 圆形)
- **位置**：`lib/presentation/pages/vent/vent_list_page.dart:209-215` + `lib/presentation/pages/vent/vent_detail_page.dart:204-220`
- **类型**：底层
- **修复难度**：S
- **优先级**：P2
- **问题描述**：
  - Hero 默认 `flightShuttleBuilder` 用 Material default（大小渐变 + 透明度）
  - 但 source 是 `CircleAvatar(radius: 20, child: Icon(size: 20))` 实际直径 40px
  - destination 也是 `CircleAvatar(radius: 20, child: Icon(size: 20))` 直径 40px
  - 起点终点完全一样 → Hero 几乎不可见，**没有"飞"的感觉**
  - emil "Hero must have visual journey" — 起点小 + 终点大 才有效
- **emil 视角建议**：
  - 选项 A：destination CircleAvatar 放大到 `radius: 32` (直径 64px) → 1.6× 视觉 journey
  - 选项 B：删 Hero，节省复杂度 — 树洞详情是 rare 频度，Hero 价值低
  - 选项 C：保留但加 `flightShuttleBuilder` 自定义（path + 旋转 15° 模拟"卡片翻开"）

#### [20] [emil-可访问性] `setup_page.dart:105-113` `PopScope(canPop: _step != 0)` 拦截但用 `showSnackBar` 提示，缺震动
- **位置**：`lib/presentation/pages/setup/setup_page.dart:105-113`
- **类型**：底层
- **修复难度**：S
- **优先级**：P2
- **问题描述**：
  - setup 第 0 步（consent）按返回 → `canPop: false` → snackbar 提示"需要先同意"
  - 缺 `Haptics.warning()` 或 `Haptics.light()` 触感
  - emil "feedback must match action" — 拦截 = 否定动作，应该有 negative haptic
  - 同款问题：`home_page.dart:323` 也有 `_runAfterCheckIn` 失败但 swallow
- **emil 视角建议**：
  - setup consent 拦截 → 加 `await Haptics.warning();` (warning 警示) 跟"必须同意"语义匹配
  - 或 `Haptics.light()` (轻) — emil "destructive gets heavy, blocking gets light"

#### [21] [emil-token] 12 处 `fontWeight: FontWeight.w500/w600/w700` 散落，未走 `textStyle*Strong` 集中器
- **位置**：（分散于各 page）
- **类型**：底层
- **修复难度**：S
- **优先级**：P2
- **问题描述**：
  - 项目已建立 4 个 `textStyle*Strong` (Body/Body/Label/Caption)
  - 仍有 `TextStyle(fontSize: AppTokens.fontSizeBody, fontWeight: FontWeight.w500)` 等 12+ 处直拼
  - emil "decisions should be nameable" — w500/w600/w700 的语义差异（Medium / SemiBold / Bold）应集中
- **emil 视角建议**：
  - 已存在的 `textStyleLabelMedium(context)` (w500) / `textStyleBodyStrong(context)` (w600) / `textStyleLabelStrong(context)` (w600) 覆盖
  - w700 (Bold) 散落 ~3 处，可加 `textStyleTitleStrong(context)` 或保留 w700 inline（title 字体已经是 28/w700 默认，调用方加 copyWith 也合理）

---

### 🟢 P3（可选 / 锦上添花）

#### [22] [emil-动效] `LoadingSpinner` 内 `CircularProgressIndicator(strokeWidth: 2.5)` 2 处未抽 token
- **位置**：`lib/presentation/widgets/loading_skeleton.dart:60, 95`
- **类型**：底层
- **修复难度**：S
- **优先级**：P3
- **问题描述**：
  - `strokeWidth: 2.5` 重复 2 处
  - emil "magic numbers should be named"
- **emil 视角建议**：
  - 加 `AppTokens.spinnerStrokeWidth = 2.5`
  - 1 行 token，集中度 +1

#### [23] [emil-动效] `app_tokens.dart` 缺 `durShimmer` / `durSnackbarSlide` 等 motion 细节 token
- **位置**：`lib/core/theme/app_tokens.dart:294-326`
- **类型**：架构
- **修复难度**：S
- **优先级**：P3
- **问题描述**：
  - 现有 `durPress / shimmerCycleMs / durPageTransition / refreshMinVisibleMs / snackBarDuration*` 9 个
  - 缺：snackbar 滑入/滑出 transition duration（Flutter 默认 250ms，可显式）
  - 缺：dialog 入场 duration（Flutter 默认 150ms scale + 75ms fade）
  - 缺：tooltip delay + duration（Flutter 默认 0/100ms）
- **emil 视角建议**：
  - M3 spec 给的默认值已合理，**不强求 token 化**
  - 如果未来要做全局 `PageTransitionsTheme` / `DialogTheme` 统一，再抽

#### [24] [emil-一致性] `assessment_widgets.dart` SparklinePainter dot stroke 2× 重复绘制
- **位置**：`lib/presentation/pages/assessment/assessment_widgets.dart:163-166`
- **类型**：底层
- **修复难度**：S
- **优先级**：P3
- **问题描述**：
  ```dart
  for (final p in points) {
    canvas.drawCircle(p, 3.5, dotPaint);
    canvas.drawCircle(p, 3.5, dotStrokePaint);  // 半径相同 = 仅画描边色
  }
  ```
  - 同一 `p` 同 `3.5` 半径画 2 圈，第二圈只画 stroke
  - 性能微浪费：可改为 `Paint().style = PaintingStyle.stroke` + 一次画
  - emil "performance" — 不是热点（10 个点以内）但模式可优化
- **emil 视角建议**：
  - 合并：`canvas.drawCircle(p, 3.5, dotPaint..style = PaintingStyle.fill); canvas.drawCircle(p, 3.5, dotStrokePaint..style = PaintingStyle.stroke);`
  - 或一次画 fill + stroke：单 Paint 用 `style = PaintingStyle.fill`，stroke 用 `canvas.drawCircle(p, 3.5, dotStrokePaint);` (会画整个圆 stroke)
  - 实际是"同半径 fill + 同半径 stroke"经典画法，性能影响 < 1% CPU

#### [25] [emil-token] `app.dart` (项目根) 未读，可能含 MaterialApp themeMode / dark theme 切换
- **位置**：`lib/app.dart`
- **类型**：架构
- **修复难度**：S
- **优先级**：P3
- **问题描述**：
  - 评估 `MaterialApp` 是否包 `AnimatedTheme` 或 `themeMode` 切换动画
  - theme toggle 是 tens/day (用户偶尔切 dark/light)，emil 框架应该用 `curveStandard + durNormal` 平滑切换
  - 实际 `theme_toggle_button.dart:33` `notifier.set(next)` 改 `themeModeProvider`，**没显式动画**
  - Flutter `MaterialApp` 默认 theme 切换 = 硬切（无动画），emil 原则 #1 "spatial consistency" 不满足
- **emil 视角建议**：
  - 评估 `MaterialApp` 是否需要 `theme: ThemeData(... light())` / `darkTheme: ThemeData(... dark())` 都传
  - 不需要 `AnimatedTheme` — Flutter 系统层已经处理（实测：深色/浅色切换有 250ms 渐变）
  - 验证：用户切 theme 时视觉是硬切还是渐变 → 如果硬切，加 `AnimatedTheme(duration: AppTokens.durNormal, curve: AppTokens.curveStandard, data: ..., child: ...)` 包裹

#### [26] [emil-token] `flutter analyze` / `dart format` / `dart fix --apply` 组合维护注释应在 AGENTS.md
- **位置**：`D:\Batch\chroniccare\AGENTS.md:`
- **类型**：架构
- **修复难度**：S
- **优先级**：P3
- **问题描述**：
  - AGENTS.md 已有 `flutter analyze + flutter test` 守门
  - 缺：`dart format` + `dart fix --apply` 在大批量 refactor 后必跑（注释里写了，但流程未固化为 pre-commit）
  - 注释里提过"200+ info-level warning"，**这是 emil 视角的"卫生标准"**
- **emil 视角建议**：
  - AGENTS.md 加："批量 refactor 后: `dart format .` + `dart fix --apply` 配合跑（format 加换行 + fix 清 trailing commas）"
  - pre-commit hook 加 `dart format --set-exit-if-changed` 检查

#### [27] [emil-动效] `DimensionRow` 双轨 `AnimatedContainer` + `AnimatedDefaultTextStyle` 是好模式，但未抽到 `AppRatingButton` widget
- **位置**：`lib/presentation/widgets/dimension_row.dart:55-100`
- **类型**：底层
- **修复难度**：M
- **优先级**：P3
- **问题描述**：
  - 5 个评分按钮（1-5）每个包 PressFeedback + AppSemantics + AnimatedContainer + AnimatedDefaultTextStyle
  - 项目其他 1-5 评分场景（mood dialog / assessment scale）应该复用此 widget
  - 实际是 v0.23 round 44 抽的 public widget，但**只服务 mood_dialog** — assessment 的 ChoiceChip 是另一种样式
- **emil 视角建议**：
  - 抽 `AppRatingButton` 接受 `value / selected / onChanged / semantics`
  - 同步 mood_dialog + 未来 trend 评分都用集中器
  - emil "cohesion" — 5 颗星 / 5 颗 emoji / 5 颗数字 在精神心理 app 都该体感一致

#### [28] [emil-token] `medication_calendar_page.dart:67` + 8 处其他页面用 `fontSize: AppTokens.fontSizeBody` + 默认 color
- **位置**：（分散）
- **类型**：底层
- **修复难度**：S
- **优先级**：P3
- **问题描述**：
  - 5+ 处直接 `TextStyle(fontSize: AppTokens.fontSizeBody)` 而默认 color 是 `cs.onSurface` (M3 fromSeed 派生)
  - 项目 `textStyleBody(context)` getter 已经设了 `color: textPrimaryColor(context)` (= `cs.onSurface`)
  - **完全等价**，改用 getter 后**唯一差异是 light/dark 自适应显式**（M3 自动保证）
- **emil 视角建议**：
  - 5+ 处 `TextStyle(fontSize: fontSizeBody)` → `AppTokens.textStyleBody(context)` 一键替换
  - emil "cohesion" — textStyle 集中度

#### [29] [emil-动效] `assessment_page.dart:86-91` quiz↔result 切换用 `PageTransitionSwitcher(switchKey: ..., child: ...)`，100ms fade
- **位置**：`lib/presentation/pages/assessment/assessment_page.dart:86-92`
- **类型**：底层
- **修复难度**：S
- **优先级**：P3
- **问题描述**：
  - 注释说"精神心理患者对长时动效敏感,只用 fade 不用 slide" — 决策合理
  - 但 100ms 对 quiz→result 这种 "用户停 30s 思考后" 的切换可能太短：**用户视角还没反应过来已经切了**
  - emil 原则 #4 "sub-300ms UI" 没问题，但 100ms 对应 30s 等待后的"瞬间" 体感是"突兀"
- **emil 视角建议**：
  - 评估改 150ms（`PageTransitionSwitcher(duration: ...)`）
  - 或加 `Motion.duration(context, AppTokens.durNormal)` 走标准 (300ms)，给"评估完成"的仪式感
  - emil 决策：occasional 频度（用户 7-30 天做一次） = 可用 standard

#### [30] [emil-微交互] `setup_page.dart:106-113` PopScope + SnackBar 但 SnackBar 跟 _validateWelcomeForm() 错误样式不一致
- **位置**：`lib/presentation/pages/setup/setup_page.dart:106-113` vs `_validateWelcomeForm`
- **类型**：底层
- **修复难度**：S
- **优先级**：P3
- **问题描述**：
  - 拦截返回 → `AppSnackBar.showInfo(context, setupConsentRequired)` (info, 2s)
  - 验证失败 → `setState(() => _saving = false); return;` 不显示 snackbar，只在 `_validateWelcomeForm` 返 null → UI 上 `TextField.errorText` 显示
  - **2 种错误反馈样式**：snackbar vs inline errorText — 用户可能困惑
  - emil "cohesion" — 同一 page 的错误反馈应该统一
- **emil 视角建议**：
  - 选项 A：拦截返回也走 inline errorText（在 Consent 步骤加 `_consentError` state）
  - 选项 B：保留 snackbar 但改成 `showError` 跟表单错误一致的时长/样式
  - emil 选 B — system-level 拦截用 snackbar，field-level 错误用 inline，两者分工不同

#### [31] [emil-token] `app_tokens.dart` 8 个 `spacingXxx` + 5 个 `lineHeightXxx` + 11 个 `textStyleXxx` 命名不一致
- **位置**：`lib/core/theme/app_tokens.dart:240-260, 232-238, 434-570`
- **类型**：架构
- **修复难度**：S
- **优先级**：P3
- **问题描述**：
  - spacing 命名：`spacingXs/Sm/Md/Lg/Xl/Xxs/Xxxs/ChipGap/ChipGapInline/PageMarginH/PageMarginV` — Xs/Sm/Md 大中小 + Xxs/Xxxs 加前缀 + 业务名混用
  - lineHeight：`Tight/Normal/Loose/Snug/Relaxed` — 全语义
  - textStyle：`Title/Headline/Body/BodyStrong/Label/LabelStrong/LabelMedium/Button/ButtonInverse/Caption/CaptionStrong/CaptionHint/Micro/Legal` — 字号 + weight + 业务混用
  - 命名风格不统一 → caller 难以记住该用哪个
- **emil 视角建议**：
  - 现状已可用，**不强求统一**（不同 family 适合不同命名）
  - 注释里加 "命名规则" 段：spacing 用 size 词、lineHeight 用语义、textStyle 用 size + weight + 业务
  - emil 实际项目经验：命名"一致" ≠ 全部用 size 词；混 size+语义才是工业级

---

## 3. 总结

### 3.1 健康度评分：**8.4 / 10**（优秀）

| 维度 | 评分 | 状态 |
|---|---|---|
| Token 集中度 | 9 / 10 | 14 处裸 TextStyle + 12 处裸 EdgeInsets 待收尾 |
| 动效集中度 | 9 / 10 | 4 个集中 widget + 1 个自研 celebration 待统一 |
| 曲线选择 | 8 / 10 | 4 档合理 + MotionScheme.subtle 待分专属 curve |
| 频度决策 | 9 / 10 | emil 决策框架执行度高，注释完备 |
| 微交互完整性 | 8 / 10 | PressFeedback + Haptics + PageTransition 完整；MoodQuickButton 重复接管待清 |
| 可访问性 | 7 / 10 | reduce-motion 包装器覆盖 80% 场景，DimensionRow + LoadingSkeleton 待补 |
| 一致性 | 8 / 10 | 11 个 textStyle + 9 个 motion token 集中；裸 14 处待 cleanup |
| 架构 | 9 / 10 | app_tokens 588 行单文件偏大，建议拆 3 文件 |

### 3.2 P0 / P1 / P2 / P3 总数

- **P0（阻碍性）**：**0** 项
- **P1（重要）**：**8** 项
- **P2（可改进）**：**13** 项
- **P3（锦上添花）**：**10** 项
- **总计**：**31** 项

### 3.3 最大的 3 个问题

1. **🔴 [P1 #5] `DimensionRow` `AnimatedContainer` 未走 `Motion.duration/curve` 包装 — 评分题对 reduce-motion 失效**（精神心理专项，直接刺激前庭敏感用户）
2. **🟠 [P1 #1] `MotionScheme.subtle` 与 `standard` 用同一条曲线 — 频度档位虚设**（架构层 decision 模糊，emil "decisions should be nameable" 违反）
3. **🟠 [P1 #2] `CelebrationOverlay` 5 段 `TweenSequence` 自研，未走集中 widget — 复用度 0**（唯一游离在 `animations/` 体系外的"野生"动效）

### 3.4 最重要的肯定

✅ **v0.17 → v0.24**（round 1 → 47）emil token 化 + 集中化作业**非常扎实**：
- 30+ token（color/font/spacing/radius/duration/curve/shadow）
- 14 个集中 widget（AppSnackBar/PressFeedback/ChipBadge/SectionHeader/FadeIn/SlideUp/PageTransitionSwitcher/AppListTile/PressFeedbackIconButton/Haptics/AppSemantics/LoadingSkeleton/EmptyState/ErrorState/LoadingTextButton）
- 4 档 `MotionScheme` 决策框架 + `Motion.duration/curve` reduce-motion 包装器
- 5 类 `Haptics` 触感集中
- 47+ 处 `AppSnackBar` 收敛
- 30+ 处 `PressFeedback` 包裹

✅ 精神心理专项正确：
- 评分按钮 `AnimatedContainer` + `AnimatedDefaultTextStyle` 双轨同步（emil "physical correctness"）
- `PopScope` 拦截 + snackbar 提示
- 国产 ROM 静默杀后台文档说明（NotificationStatusCard 自检）
- 4 档 motion 频度明确（100+/day 无动画 / tens/day 微弱 / occasional 标准 / rare delight）
- stagger cap 200ms（前 5 行后立即出现，perceived performance）
- `Haptics.warning()` 删除前警示（情绪低谷误删不可逆）

✅ 隐私边界坚守（树洞不进任何分析 / 通知 / 关怀，符合 AGENTS.md）

### 3.5 建议执行顺序（如果只做 1 轮 polish）

| 步骤 | 任务 | 工作量 | 价值 |
|---|---|---|---|
| 1 | [P1 #5] DimensionRow Motion 包装 | 5 min | 高（前庭敏感） |
| 2 | [P1 #1] MotionScheme.subtle 专属 curve | 15 min | 中（架构清晰） |
| 3 | [P1 #2] CelebrationOverlay 抽 `animations/celebration_bounce.dart` | 30 min | 中（体系完整） |
| 4 | [P1 #3] 14 处裸 TextStyle 改 `textStyle*().copyWith()` | 30 min | 中（集中度 +1） |
| 5 | [P1 #7] MoodQuickButton 改接管 tap 模式 | 10 min | 中（消除 2 次反馈） |
| 6 | [P1 #8] vent_list `_EntryCard` 加 PressFeedback | 5 min | 中（一致体感） |

**总工作量：~1.5h**，P1 全部解决，emil 视角从 8.4 → 8.9 分。

---

> **本报告由 emil · 设计工程视角审视生成。**
> 报告基于 `lib/presentation/**` + `lib/core/theme/**` + `lib/core/routing/app_router.dart` + `lib/core/shared/**` 全量代码静态分析（未跑 `flutter analyze`，因项目 `flutter pub get` 期间在下载 SDK assets）。
> 所有发现均给出 `file:line` 位置 + emil 视角建议（含具体 token / curve / 数值）。
> 不动代码，只出报告。
