# emilkowalski 视角深度审计 (2026-08-10 cleanup)

**项目**: ChronicCare v0.30.0+85
**审计基线**: R95 (2026-08-07) → R105 (2026-08-09) + R96-R105 9 round 增量
**审计视角**: 设计 / UI / 动效 / 可访问性 / 视觉层级 / 集中器使用率
**对比基线**: R95 emil 9.0/10 → 本次

---

## 评分: 9.0 / 10 (持平 R95)

**持平原因 (R95 → R105)**: +1.0 加分 (6 god page 拆 + MotionScheme/Motion 集中器贯穿 + 18 守门员 + 危机热线 R92 + 锁屏脱敏 R101 + Haptics/Semantics/PressFeedback 4 类集中器); -1.0 减分 (R95-R105 引入 28 处新违规, 主要是主页 stagger / AppMotion 绕 facade / 集中器散落 / token 化夸大报告 102+ 但实际 ~60% 覆盖)

**达到 9.5**: 修 5 项 P0/P1 (#1 stagger clamp + #2 AppMotion 走 AppTokens + #3 AnimatedSwitcher Motion 包装 + #8 #9 loading/error 集中器化)
**达到 10.0**: 上面 5 项 + 调色板/反白/IA 重排/size token 化 11 项 P0/P1 全修

---

## 一、优点 (具体文件:行号引用)

### 1.1 Motion 集中器 + prefers-reduced-motion 100% 覆盖 ✅
- **`lib/core/theme/app_motion.dart:236-253`** `Motion.duration/curve` 自动读 `MediaQuery.disableAnimations` 包装, reduce-motion 命中时 `Duration.zero` + `Curves.linear`
- **`lib/core/theme/app_motion.dart:173-217`** `MotionScheme` 4 档 enum (none/subtle/standard/delight) + extension 强制 caller 选档
- **`lib/presentation/widgets/animations/fade_in.dart:79`** + **`slide_up.dart:75`** + **`celebration_bounce.dart:83`** + **`loading_skeleton.dart:226-244`** — 4 个 animations 集中器在 `didChangeDependencies` 同步 reduce-motion, 系统开了 → 跳到 value 1.0 + 取消 delayTimer
- **`lib/presentation/widgets/dimension_row.dart:66-95`** 教科书范例: AnimatedContainer + AnimatedDefaultTextStyle 都走 `Motion.duration/curve`, R48 P1-5 修前裸 `AppTokens.durFast` reduce-motion 仍 200ms 触发前庭不适
- **`lib/presentation/widgets/check_in_button.dart:31-58`** AnimatedContainer + AnimatedSwitcher 都走 Motion 包装

### 1.2 集中器 (EmptyState/ErrorState/LoadingSkeleton/AppSnackBar) 主路径覆盖 ✅
- **`lib/presentation/pages/trend/trend_page.dart:81-91`** + **`vent/vent_list_page.dart:99-106`** + **`assessment/assessment_history_page.dart:52`** 3 大态集中器完美使用
- **`lib/presentation/widgets/empty_state.dart:46-77`** R101 增强视觉 (Apple Health 风格): 96×96 渐变圆形背景 + 64dp 大 icon
- **`lib/presentation/widgets/loading_skeleton.dart:126-171`** `LoadingScrim` 集中器 (R70 emil B-2) — PDF 导出等 long task modal 自动包 AbsorbPointer 锁底层 + 0.54 scrim alpha
- **`lib/presentation/widgets/app_snack_bar.dart:118-162`** `showError/showInfo/showUndo/showWithAction` 4 类工厂直接接管 ScaffoldMessenger, 1 行调用

### 1.3 a11y 集中器 + Tooltip/liveRegion 全面落地 ✅
- **`lib/presentation/widgets/app_semantics.dart:26-65`** `container/button/exclude` 3 工厂, R45 P1-18 替代 6 处裸 `Semantics(...)` + 1 处 `ExcludeSemantics(...)`
- **`lib/presentation/widgets/check_in_button.dart:158-171`** streak 数字走 `AppSemantics.container(liveRegion: true)` + 内部 Text `exclude` 避免双重朗读, **R101 教科书级 liveRegion**
- **`lib/presentation/widgets/dimension_row.dart:50-63`** 1-5 评分按钮 `inMutuallyExclusiveGroup: true` + TalkBack 朗读 "评分 3, 已选"
- **`lib/presentation/pages/home/widgets/hero_illustration.dart:60-119`** 主页 hero 装饰 (☀️⛅☁️🌿) 整体包 `ExcludeSemantics`, TalkBack 不朗读 emoji
- **30+ 处 Tooltip 全部走 l10n** (theme_toggle / vent_list / medication_page / trend_calendar / crisis_hotline), 0 处硬编码

### 1.4 Hero / page transition 频度分级 + Haptics ✅
- **`lib/core/routing/app_routes.dart:43-103`** 3 类 transition 集中器 + emil 频度决策注释 (`fadePage` 主导航 / `slideRightPage` 子页 / `slideUpPage` 全屏深页), 全部走 `Motion.duration/curve`
- **`lib/presentation/widgets/animations/celebration_bounce.dart:40-45`** 庆祝弹跳走 `MotionScheme.delight.duration` (500ms) + `curveBackOut`, R71 P5.4 加 `RepaintBoundary` 防 1.8s 期间重 paint
- **`lib/presentation/widgets/feedback.dart:18-39`** `Haptics.tap/success/warning/light` 4 类命名, emil "feedback 反馈" 原则
- **`lib/presentation/pages/crisis_hotline_page.dart:233-252`** R97-P1-11 1 tap 拨打 (tel: intent), 走 url_launcher 不需 CALL_PHONE 权限

### 1.5 R95 6 个 god page 拆解 + 主页 HomeLifecycleState 状态机 ✅
- **`lib/presentation/pages/home/home_page.dart`** 138 行主壳 + `home_page_state.dart` 590 行 state
- **`lib/presentation/pages/home/home_page_state.dart:46-123`** `HomeLifecycleState` enum 5 状态 + 3 transition method 走 `switch` expression 强制穷举, R64 L2 refactor 教科书范例 — 3 bool flag 的 8 种组合里 3 种 race 风险改 enum 后抛 `StateError` 早发现
- **`lib/presentation/pages/setup/setup_page.dart`** 25 行主壳 + `setup_page_state.dart` 480 行 state, 4 step 走 `PageTransitionSwitcher(switchKey: _step, transitionBuilder: ...)` 集中器替代 R23 之前 inline 40+ 行
- **`lib/presentation/pages/settings/settings_page.dart:35-49`** 4 group 拼装主壳 51 行, 业务全在 4 个 group widget (sub-spec 8 task 17)

### 1.6 主题感知 + 锁屏通知脱敏 + 18 守门员 ✅
- **`lib/core/theme/app_colors.dart:99-145`** 13 个 dynamic getter 全部走 `Theme.of(context).colorScheme.X`, R49 P0 #1 修 dark mode `AppColors.primary` 0xFF6BCF7F 在深色背景对比度崩
- **`lib/core/theme/app_motion.dart:103-137`** 4 个 shadow getter 全部 theme-aware (R59 删 const shadow 防 R49 同款 silent bug)
- **`lib/core/data/services/safety_alert_builder.dart:100`** `l10n.safetyAlertTitle(name, daysWithoutCheckIn)` 替代硬编码中文, 锁屏通知 3 语 (zh/en/zh_Hant) 正确 (R101)
- 18 守门员全绿 (R95 加 `check_coverage.py`)

---

## 二、问题清单

| # | 文件:行 | 问题 | 层级 | 难度 | 优先级 | 修复建议 |
|---|---------|------|------|------|--------|----------|
| 1 | `home_page_state.dart:335-430` (8 处) | **主页 8 层 FadeIn stagger 累加 0-280ms 没用 `clamp(0, AppTokens.staggerCapMs)`**, `staggerStepMs=40` × 7 = 280ms 超 cap 200ms. 精神心理患者前庭敏感用户触发不适, 违反 R43 加 cap 设计意图. vent_list / medication_calendar 2 处已正确用 clamp | 动效 | 简单 | **P0** | 8 处加 `.clamp(0, AppTokens.staggerCapMs)` |
| 2 | `crisis_hotline_page.dart:219, 248` + `medication_calendar_page.dart:218` (3 处) | **3 处 `AppMotion.snackBarDurationShort` 绕 `AppTokens.X` facade**, 违反 R65 拆 motion 契约, R49 R91 同款 "2 source-of-truth" silent bug 风险 | 架构 | 简单 | **P0** | 3 处 `AppMotion.X` → `AppTokens.X`, grep `AppMotion\.` 在 lib 强制 0 引用 |
| 3 | `today_summary_card.dart:131` + `medication_page.dart:389` + `check_in_button.dart:121` (3 处) | **3 处 `AnimatedSwitcher(duration: AppTokens.durFast/Slow)` 漏 `Motion.duration`**, reduce-motion 命中仍有 200ms/500ms 动画 | a11y | 简单 | **P0** | 3 处加 `Motion.duration/curve` 包装 |
| 4 | `press_feedback.dart:91` | **`PressFeedback.curve: AppTokens.curveStandard` 漏 `Motion.curve`**, reduce-motion 下仍 easeOutCubic | a11y | 简单 | **P1** | 1 处改 `Motion.curve(context, AppTokens.curveStandard)` |
| 5 | 5 处 daily_tracking widgets (`weight/sleep/stress/anxiety/social_rhythm`) | **5 处裸 `SnackBar(content: Text(l10n.editMedSaveFailed(e.toString())))` 绕 `AppSnackBar.showError`**, R37 P1 工厂漏修 | 集中器 | 简单 | **P1** | 5 处全替换 `AppSnackBar.showError(context, action: l10n.xxxSave, error: e)` |
| 6 | `medication_calendar_page.dart:212-220` + `crisis_hotline_page.dart:216-220, 245-249` (3 处) | **3 处裸 SnackBar 绕 `AppSnackBar.showInfo`** | 集中器 | 简单 | **P1** | 3 处替换 |
| 7 | `quick_mood_carousel.dart:100-106` | **2 重违规: 1) 裸 `ScaffoldMessenger.showSnackBar` 绕 `AppSnackBar.showInfo/error`. 2) 硬编码中文 `Text('记录失败，请重试')` 应走 l10n**. 1.5 年历史 stub | i18n+集中器 | 简单 | **P1** | 替换 `AppSnackBar.showError` + `l10n.commonSaveFailed` ARB key |
| 8 | `assessment_center_page.dart:54-56` + `medication_page.dart:161-162` + `medication_detail_page.dart:208-210` + `mood_list/mood_trend_page.dart:100-101` (4 处) | **4 处 `loading: () => const Center(child: CircularProgressIndicator())` + `error: (e, _) => Center(child: Text('$e'))` 散落, 没用 LoadingSkeleton/ErrorState**. `medication_page.dart:162` `Text('$e')` 直接暴露 SQL exception 给用户 (信息安全双违反) | 集中器 | 简单 | **P1** | 4 处替换 LoadingSkeleton.fullScreen + ErrorState (含 onRetry) |
| 9 | 6 处 daily_tracking widgets + `treatment_page.dart:64` | **6 处 `Center(child: Text(l10n.commonLoadFailed(e.toString())))` 散落**, R29 抽 ErrorState 漏 daily_tracking 全模块 | 集中器 | 简单 | **P1** | 6 处替换 ErrorState |
| 10 | `medication_pill_icon.dart:9-16` (6 色) + `mood_trend_page.dart:311-317, 539-540` (5 色) | **11 处硬编码 `Color(0xFF...)` 调色板 (Apple Health 系统色), 没用 token**. R90 R91 修 assessment 12 色, mood_trend + medication_pill 漏 | token | 中 | **P1** | 抽 `app_colors.dart` `medicationPillColors` + `moodScoreColors` 集中器, 跟 R91 `dailyTrackingColors` 同款 |
| 11 | `medication_pill_icon.dart:63, 70` (2 处) | **2 处 `Text(color: Colors.white)` 硬编码, 没用 `AppTokens.fgOnPrimary`**, dark mode 下药丸图标文字反白失效, 跟 R22 P1-8 `check_in_button:205` 已知 case 同款 | dark mode | 简单 | **P1** | 2 处 `Colors.white` → `AppTokens.fgOnPrimary(context)` |
| 12 | `home_page_state.dart:334-430` (8 处) | **主页 entry 动效密度过高 (8 层 stagger 累加 280ms + scale + shimmer), emil 决策框架 100+/day 应 MotionScheme.none**, 仅 first-install onboarding 走 delight | UX (前庭) | 中 | **P1** | 主页 FadeIn 默认 `MotionScheme.none` (Duration.zero), 仅首次回首页走 delight 1 次 |
| 13 | `home_page_state.dart:300-440` (整 build) | **主页 8 层累计视觉重量 800-1000px (hero 140 + carousel 80 + 4 summary 项 + schedule 等)**, iPhone SE 375×667 累加 220dp 推 CTA 到折叠线, 必须滚动才能看到打卡按钮 | UX (小屏) | 中 | **P1** | R101 主页 IA 重排 (R95+ 路线图 task 10): TodaySummaryCard 4→2 项 + 砍 hero 140→80 |
| 14 | 30+ 处 `Icon(icon, size: N)` 硬编码 (medication 14 + mood 6 + vent 2 + assessment 4 + daily_tracking 3 + home 4) | **30+ 处 `Icon(..., size: 16/18/20/28/32/40/48/64)` 硬编码**, R56 加 4 iconSize 集中器但漏 token 化. **R95 sub-spec 5 "102+ 处" 是 inflated, 实际漏 30+ 处** | token | 中 | **P2** | 全项目 grep `size: \d+,$` 排序, 出现 ≥3 次的 size 加 iconSize 集中器 |
| 15 | 8+ 处 `SizedBox(height: 2/4)` 硬编码 (`today_summary_card:129` + `quick_mood_carousel:181` + `medication_detail:269` + 5 daily_tracking widgets) | **8+ 处 `SizedBox(height: 2/4)` 应走 `AppTokens.spacingXxxs=2.0` / `spacingXxs=4.0`**, R95 sub-spec 5 修了 EdgeInsets.all 120+ 但 SizedBox 仍漏 100+ | token | 简单 | **P2** | 8+ 处全 token 化 |
| 16 | `hero_illustration.dart:70, 85, 99, 109` (4 处) | **4 处 emoji `TextStyle(fontSize: 36/28/56/32)` 硬编码**, 应走 `AppTokens.fontSizeScoreLg=24/Xl=32`, `28/36/56` 无对应, 建议加 `fontSizeScoreHero{Lg=56/Md=36/Sm=28}` | token | 中 | **P2** | 抽 3 个新 fontSize token, 4 处全替换 |
| 17 | `mood_factor_analysis.dart:123` (1 处) | **`BorderRadius.circular(2)` 硬编码 magic**, 应走 `AppTokens.radiusCell=2.0` 集中器 (R40 加就是为极小圆角) | token | 简单 | **P2** | 1 处改 `BorderRadius.circular(AppTokens.radiusCell)` |
| 18 | `medication_report_dialog.dart:89` | **`textStyleMono(context, size: AppTokens.fontSizeBodySm)` size 传 token (重复), 集中器 default 就是 fontSizeBodySm**. R26 EMIL-INC-03 漏收尾 | DRY | 简单 | **P2** | 删 `size: AppTokens.fontSizeBodySm`, 用默认值 |
| 19 | `app_snack_bar.dart:30-44` | **`error?.toString() ?? 'unknown'` 兜底 "unknown" 硬编码英文**, 应走 l10n (R56 spzh C-09 strings.dart 守门员同款问题) | i18n | 简单 | **P2** | 加 ARB `commonErrorUnknown: "未知错误" / "Unknown error" / "未知錯誤"`, 1 处替换 |
| 20 | `home_fab_toolbar.dart:90, 117, 141` (3 处) | **3 个 stagger delay (40/80/120ms) 仍无 clamp, 但只 3 项 max 120ms < cap 200ms 影响小**. 跟主页 8 层风险不同, 但 R95 漏 apply | 动效 | 简单 | **P3** | 3 处加 `clamp(0, AppTokens.staggerCapMs)` 防御性 |
| 21 | 5+ 处 `swallowError(where, error, stack, note)` 注释 note 硬编码中文 (`home_page_state:516-518` + `quick_mood_carousel:94-98` + 3+ others) | **5+ 处 note 字段硬编码中文**, 应走 l10n (R56 spzh C-09 同款, R95 漏修) | i18n | 简单 | **P3** | `note: l10n.errorNoteXxx` 或改 enum |
| 22 | `today_summary_card.dart:78` | **`Color(MoodVisual.colorArgbFor(latestMood.score))` 强制 const 转, `MoodVisual` 在 `core/shared/` 跨层, 不在 `app_colors.dart` token 集中器, 违反 R27 "调色板统一管理"** | 架构 | 中 | **P3** | 移到 `AppColors.moodScoreColorFor(int score)`, MoodVisual 保留 emoji/label 工厂 |
| 23 | 全项目 (0 处) | **0 处 `MediaQuery.textScalerOf` clamp** (R104 A12 Dynamic Type 仍未修), textScaler=2.0 时按钮文字可能溢出. 主页 `app_theme.dart:131-134` 字号固定 | a11y | 中 | **P3** | 加 `textScalerOf(context).clamp(min: 1.0, max: 1.5)` 防止布局错位 |
| 24 | `app_colors.dart:268 success #66BB6A` | **dark 模式 + 0.6 alpha 对比度可能跌到 3.5:1, WCAG AA fail** | a11y | 中 | **P3** | 加 `tintChartLine` 类 disabledSuccessSoft (alpha 0.4-0.5 in dark) |
| 25 | 3 个 animations 集中器 (`fade_in:79` + `slide_up:75` + `celebration_bounce:83`) | **reduce-motion 检查是单向, 系统从 reduce 切到非 reduce 不会重启动画**, 边缘 case 但不致命 (用户重启 App 重置) | a11y | 中 | **P3** | 加 `MediaQuery.fromView` listener 监听系统 reduce-motion 切换 |
| 26 | `home_page_state.dart:686-693 _nextReminderTime` | **1.5 年没人测跨年/跨月 DST 边界**, 跨 midnight `DateTime.now()` 入口没存, 罕见 race | race | 中 | **P3** | 入口 `final now = DateTime.now()` 复用; 加 widget test 跨年/跨月 case |

---

## 三、跟 R95 9.0 对比

### 3.1 修了哪些 (R95 → R105)

| 类别 | 备注 |
|------|------|
| 主页 IA god page | 731→138 主壳 + 590 state (sub-spec 4 task 5) |
| setup 4-step god page | 517→25 主壳 + 480 state (sub-spec 6 task 6c) |
| settings 4 group god page | 261→70 行 (sub-spec 8 task 17) |
| data_management_section god widget | 606→44 行 (sub-spec 1 task 1) |
| `EdgeInsets.all(...)` token 化 | ~120 处 (sub-spec 5 task 3-4, 但漏 100+ SizedBox) |
| 5 地区危机热线页 | R92 落地 1 tap 拨打 (tel: intent) |
| 锁屏通知脱敏 | R101 safety_alert_builder 走 l10n |
| 主页 IP 化 hero + QuickMoodCarousel | R28 R81 加 (B 站"哗哩哗哩能量加油站" 风格) |
| TodaySummaryCard 4 项 | R30 R101 (Apple Health Pinned Favorites) |
| AssessmentMultiLineChart mini 趋势图 | R30 R90/R92 (80dp 高, 12 量表叠加 30 天) |

### 3.2 退了哪些 (R95 → R105) — 重点

| 类别 | R95 状态 | R105 状态 |
|------|----------|-----------|
| 主页 8 层 stagger clamp | R43 cap 200ms 设计意图 | **❌ 未 apply, 累加 280ms** |
| `AppMotion.X` 走 `AppTokens.X` facade | R65 拆 motion 契约 | **❌ 3 处绕 facade** |
| AnimatedSwitcher Motion 包装 | R48 修 dimension_row 范例 | **❌ 3 处 today_summary/medication/check_in_button 漏** |
| `Colors.white` token 化 | R22 P1-8 + R49 P0-1 修 | **❌ 2 处 medication_pill_icon 漏** |
| `Color(0xFF...)` 调色板 token 化 | R90 R91 修 assessment 12 色 | **❌ 11 处 mood_trend + medication_pill 漏** |
| 集中器覆盖 loading/error 3 大态 | R29/R70 抽 EmptyState/ErrorState/LoadingSkeleton | **❌ 9+ 处 daily_tracking + assessment + medication 漏** |
| 集中器覆盖 SnackBar | R37 P1 抽 AppSnackBar.showX | **❌ 10+ 处 daily_tracking + crisis + quick_mood 漏** |
| `Icon(size: N)` token 化 | R56 加 4 iconSize 集中器 | **❌ 30+ 处散落** |
| `PressFeedback.curve` Motion 包装 | R48 修 duration 漏 curve | **❌ 1 处 press_feedback.dart:91 漏** |

### 3.3 新增 (R95 之后)

- `HomeHeroIllustration` IP 化太阳云 hero + `QuickMoodCarousel` 4 档横滑 + `HomeFabToolbar` (R28 R81, B 站"哗哩哗哩能量加油站" 风格)
- `TodaySummaryCard` Apple Health Pinned Favorites (R30 R101)
- `AssessmentMultiLineChart` mini 趋势图 (R30 R90, 80dp 高 12 量表叠加 30 天)
- `Haptics.success/light/warning/tap` 4 类 (R21 P1-14) + `AppSemantics.container/button/exclude` 3 工厂 (R24 R45) + `PageTransitionSwitcher.transitionBuilder` (R23 R40)
- `AppLocalizations` 1500+ keys 3 语 100% 同步 (R95 sub-spec 3/7)

---

## 四、外部链接 / 隐藏链接 (grep `https?://` 在 `lib/`)

### 4.1 运行时代码
- ✅ **0 处运行时外链** — grep 只命中注释/docstring
- `lib/core/data/services/sms_service.dart:99, 102, 181` 注释提 `https://dysmsapi.aliyuncs.com/` + `https://help.aliyun.com/zh/sms/developer-reference/api-error-codes`, 实际 `send()` 走 mock (`aliyunSmsEnabled=false` 守门, R55 真接后才有实际 http)
- `lib/domain/logic/chinese_holidays.dart:17` 注释 `https://holidayapi.com` 解释"为什么不接网络 API", 实际数据全 hardcode 2024-2026 国历 + 农历

### 4.2 物料层
- ⚠️ `chroniccare.app` 域名未注册 (R95 task 40)
- ⚠️ `privacy@chroniccare.app` / `support@chroniccare.app` 邮箱未注册 (R95 task 41)
- ⚠️ `mailto:` / `tel:` scheme 0 处使用 (R95 路由用 url_launcher 但没具体 mailto)

### 4.3 文档
- 3 处注释提到外部 URL (阿里云 SMS + holidayapi), 均为说明性, 等付费启动真接时启用

---

## 五、半成品 / 散落 / token 化遗漏

### 5.1 半成品 (TODO / @Deprecated)
- `medication_calendar_page.dart:202-221` `_onAddLogStub` 显示 "补打卡 stub" SnackBar, R93 task 4/5 接入 `RecordCheckInUseCase.at` 未做
- `core/data/services/notification_service.dart` 424 行 god class, R95+ 路线图 task 9 待拆 facade
- 多个 widget @Deprecated 注释待 R96+ 清理

### 5.2 散落 (集中器违规)
详见问题清单 #5 #6 #7 #8 #9: 9+ 处 loading/error + 10+ 处 SnackBar 散落

### 5.3 token 化遗漏 (R95 sub-spec 5 task 3-4 报告夸大成 102+)

| 类别 | 实际遗漏 | 报告说 |
|------|----------|--------|
| `EdgeInsets.all(N)` | ~120 处 | 120+ ✅ |
| `Icon(..., size: N)` | 30+ 处 | ❌ 漏 |
| `SizedBox(height/width: N)` | 8+ 处 | ❌ 漏 |
| `BorderRadius.circular(N)` | 1 处 | ❌ 漏 |
| `Color(0xFF...)` 调色板 | 11 处 (6 med + 5 mood) | ❌ 漏 |
| `Colors.white/black` | 2 处 (5 PDF/thumbnail 排除) | ❌ 漏 |
| `TextStyle(fontSize: N)` 硬编码 | 5+ 处 (hero + cbt + mood_trend) | ❌ 漏 |
| `AnimatedSwitcher.duration` Motion 包装 | 3 处 | ❌ 漏 |
| `AppMotion.X` 走 `AppTokens.X` | 3 处 | ❌ 漏 |
| `stagger clamp` 防御 | 11 处 (主页 8 + fab 3) | ❌ 漏 |

**净 token 化遗漏 ~80+ 处**, 跟 R95 报告 "102+ 处" 对比, **实际覆盖 ~120 / 200 ≈ 60%**

---

## 六、动效频度表 (emil 4 档框架)

| 频度 | 决策 | 时长 | curve | 应用 |
|------|------|------|-------|------|
| **none** (100+/day) | MotionScheme.none | Duration.zero | Curves.linear | 按钮按下 (PressFeedback scale 160ms 算 subtle) / 列表项选中态 |
| **subtle** (tens/day) | MotionScheme.subtle | durFast 200ms | curveSubtle easeOut | PressFeedback scale / AnimatedSwitcher 切换 (isChecked / mood selected) |
| **standard** (occasional) | MotionScheme.standard | durNormal 300ms | curveStandard easeOutCubic | page transition (fade / slide-right) / modal / drawer / snackbar / Hero 装饰 / 评分按钮 |
| **delight** (rare) | MotionScheme.delight | durSlow 500ms | curveDelight elasticOut | celebration bounce (打卡成功) / 首次 onboarding 4 step slide-up / CheckIn button 打勾 |

| 位置 | 频度 | 决策 | 实际 | 评级 |
|------|------|------|------|------|
| `check_in_button.dart:31, 50` 背景+文字切换 | tens/day | subtle | durNormal + curveDelight/Standard/Accelerate | ✅ |
| `dimension_row.dart:66-95` 评分按钮 | tens/day | subtle | durFast + curveStandard | ✅ |
| `loading_skeleton.dart:62, 147, 195` spinner/scrim/shimmer | tens/occ | none/standard | strokeWidth 2.5 + 0.54 scrim + 600ms pause, reduce-motion 跳 opacity 1.0 | ✅ |
| `app_snack_bar.dart:42-95` SnackBar | occasional | standard | snackBarDuration{Short/Medium/Long} | ✅ |
| `animations/page_transition_switcher.dart:54` 视图切换 | occasional | standard | durPageTransition 100ms + curveStandard | ✅ |
| `animations/fade_in.dart:42` + `slide_up.dart:32` | occasional | standard | durSlow + curveStandard/Decelerate | ✅ |
| `animations/celebration_bounce.dart:44` 庆祝弹跳 | rare | delight | durSlow 500ms + curveBackOut + RepaintBoundary | ✅ |
| `app_routes.dart:43-103` 3 类 page transition | occasional/rare | standard | Motion.duration 包装, 3 类频度分级清晰 | ✅ |
| `medication_calendar_grid.dart:131` + `vent_list_page.dart:178` stagger | tens/day | subtle | clamp 0-200ms 防御 | ✅ |
| `home_page_state.dart:334-430` 主页 8 层 stagger | **100+/day** | **none** | ❌ 8 个 FadeIn 累加 280ms (无 clamp) | **❌** |
| `home_fab_toolbar.dart:90, 117, 141` 4 工具按钮 stagger | tens/day | subtle | ⚠️ 3 层 stagger 无 clamp (max 120ms < cap 200ms) | ⚠️ |
| `check_in_button.dart:121` streak 数字递增 | rare | delight | durSlow, **curve 写死不是 delight** | ⚠️ |
| `quick_mood_carousel.dart:163` 选中态 | tens/day | subtle | durFast + curveStandard | ✅ |
| `today_summary_card.dart:131` + `medication_page.dart:389` 数字/icon AnimatedSwitcher | tens/day | subtle | ❌ `duration: AppTokens.durFast` 漏 Motion | ❌ |
| `press_feedback.dart:91` + `notification_status_card.dart:219` curve | tens/day | subtle | ⚠️ curve 漏 `Motion.curve` | ⚠️ |

**频度合规总结**: 严格 emil 4 档 ~70%, 半合规 (curve 漏) ~15%, 半合规 (频度过密) ~10% (主页 8 层), 违规 ~5% (3 处 AnimatedSwitcher 漏 Motion)

---

## 七、a11y 覆盖率统计

### 7.1 prefers-reduced-motion

| 路径 | 覆盖 | 备注 |
|------|------|------|
| `app_motion.dart:236-253` Motion class | ✅ | 全项目 Motion 包装自动兜底 |
| `animations/fade_in.dart:79` | ✅ | didChangeDependencies 同步跳到 value 1.0 |
| `animations/slide_up.dart:75` | ✅ | 同上 |
| `animations/celebration_bounce.dart:83` | ✅ | 同上 |
| `loading_skeleton.dart:226-244` | ✅ | _Shimmer stop + value=1.0 |
| `dimension_row.dart:66-95` | ✅ | 2 个动画都走 Motion |
| `check_in_button.dart:31-58` | ✅ | AnimatedContainer + AnimatedSwitcher 都走 Motion |
| `press_feedback.dart:84-91` | ⚠️ | duration 走 Motion, **curve 漏 Motion.curve** |
| `today_summary_card.dart:131` | ❌ | `duration: AppTokens.durFast` 漏 Motion |
| `medication_page.dart:389` | ❌ | 同上 |
| `check_in_button.dart:121` _StreakCounter | ⚠️ | initState 写死, didChangeDependencies 重读 (R48 修), 双重路径风险 |

**覆盖率**: ~85% (8/9 集中器正确, 1 个 _StreakCounter 双重路径, 1 个 press_feedback curve 漏)

### 7.2 Semantics / Tooltip / liveRegion

| 类别 | 集中器 | 覆盖率 |
|------|--------|--------|
| 大区域 (container + label) | AppSemantics.container | ~80% (streak 是 R101 教科书级) |
| 互斥/选中 (button + label + inMutuallyExclusiveGroup) | AppSemantics.button | ~70% (评分 + 时间窗口 + 评估题) |
| 装饰排除 | AppSemantics.exclude | ~60% (hero / mood_detail / streak 内部) |
| liveRegion | AppSemantics.container(liveRegion: true) | 1 处 (streak) — 偏少, mood score / crisis connect / assessment submit 可加 |
| Tooltip | IconButton.tooltip: l10n.xxxTooltip | **~100%** (30+ 处全走 l10n) |

### 7.3 焦点 / 键盘 / textScaler / Color contrast

- `primary_button.dart:60-71` `FilledButton` + `secondary_button.dart:54-57` `OutlinedButton` + `press_feedback_icon_button.dart:96-112` `IconButton` 默认可获焦
- ⚠️ **0 处 `FocusTraversalGroup`** 显式声明 — 复杂页面 (assessment 12 题) 焦点顺序可能跳
- ⚠️ **0 处 `MediaQuery.textScalerOf` clamp** (R104 A12 Dynamic Type 仍未修), textScaler=2.0 时按钮文字可能溢出
- `app_colors.dart:43` R104 fix: `textHint #767676 → #595959 (7:1)` — 主 hint 色已修
- ⚠️ `app_colors.dart:268 success #66BB6A` 在 dark 模式 + 0.6 alpha 可能跌到 3.5:1, **WCAG AA fail**

---

## 八、修复路线图建议 (R96+)

### R96 (1 周, 0.5 → 0.8)
- **P0 #1** 主页 8 + 3 = 11 处 stagger clamp (1h)
- **P0 #2** 3 处 `AppMotion.X` → `AppTokens.X` (30 min)
- **P0 #3** 3 处 AnimatedSwitcher 走 `Motion.duration/curve` (1h)
- **P1 #4** 1 处 PressFeedback.curve 走 `Motion.curve` (30 min)
- **P1 #5 #6 #7** 9+ 处 SnackBar 集中器化 (2h, 含 1 处新增 l10n key)
- **P1 #8 #9** 9+ 处 loading/error 集中器化 (2h)

### R97 (1-2 周, 0.8 → 0.9)
- **P1 #10 #11 #12** 13+ 调色板 / 反白色 token 化 (1 天, 含 1 个新调色板 palette)
- **P1 #13 #14** 主页 IA 重排 + entry 动效简化 (3 天, R95+ 路线图 task 10 完整版)
- **P2 #15-#22** 50+ size/SizedBox/radius/fontSize 硬编码 token 化 (2 天)
- **P2 #19** 1 处 `error?.toString() ?? 'unknown'` 加 l10n (1h)

### R98 (2-3 周, 0.9 → 10.0)
- **P2 #24** emotion recorder 模块 SnackBar 集中器化 (1h)
- **P2 #23 #25** textScalerOf clamp + reduce-motion 双向监听 (1 天)
- **P3 #20 #21 #26** 11 处 stagger clamp 防御 + 5 处 swallowError note l10n 化 (2h)
- R104 A11/A12 P1 续 (iCloud Backup 排除 / Dynamic Type 适配)
- 6 视角审视 + 锁屏通知脱敏 R101 模式推广到所有 system notification

---

**报告版本**: v1 (2026-08-10)
**审计员**: emilkowalski 视角 (emil design eng)
**下次审计建议**: R98 后 (主页 IA 重排 + 全面 token 化完成后)
**关联报告**: 00-CONSOLIDATION_PROMPT.md / 03-spzh.md / 07-apple-health.md
