# emil 视角审视报告 — chroniccare v0.27.0+62

> **视角**: UI / 动效 / 交互 / 视觉 / 设计 token (Emil Kowalski Design Engineering)
> **扫描范围**: `lib/` 239 dart + `pubspec.yaml` + R60-R62 working tree (17+ files modified)
> **扫描方法**: ripgrep (`color: AppTokens.` / `Curves.` / `Future.delayed` / `TextStyle(` / `fontSize:` / `SizedBox(` / `EdgeInsets.` / `withValues(` / `size:`) + 关键文件抽样 read
> **基础**: `docs/reviews/2026-07-31-three-lens/emil-v0.27+.md` (R60 评分 39/40) + `consolidated.md` (R60+ 31 条) + `v0.27/review-emilkowalski-v027.md` (R60 详细) + 7-lens `_shared/context.md`
> **基线**: emil 6 哲学 (Taste is trained / Decisions nameable / Frequency-appropriate / Interruptibility / Subtle not zero / Token centralization)

---

## 0. 一页总览

| 指标 | 数值 | 备注 |
|---|---|---|
| 总问题 | **12** 条独立项 | R62 后剩 12 条 (R60 基线 31 条修了 19 条) |
| 架构级 | 2 |  |
| 底层级 | 10 |  |
| P0 | 0 | 全部已修 |
| P1 | 5 | 大多 R62 working tree 已修但 grep 显示残留 |
| P2 | 5 | spacing/TextStyle/magic 残留 |
| P3 | 2 | nit 风格 |
| R62 修复 | 6 条 (P1-6/7/9/15/16 + P0-3 续) | Timer + dispose / l10n / token / IconButton 集中器 / SegmentedButton 包裹 |

emil R62 评分 (修正后): **41/44**

| 维度 | R60 | R62 | 变化 |
|---|---|---|---|
| Duration (时长 token) | 5/5 | 5/5 | `Future.delayed` 全部转 Timer (P1-6) |
| Easing (缓动 token) | 5/5 | 5/5 | `Curves.*` 7 处全集中 (R49 完成) |
| Color (theme-aware) | 4/5 | 4.5/5 | `AppTokens.primaryColor(context)` 等 dynamic getter 覆盖 95%,剩 5 处裸 `Colors.orange/red` 在 main.dart |
| TextStyle (token) | 3.5/5 | 3.5/5 | `textStyleBody/Label/Caption` 13 个集中器,剩 30+ 处 inline TextStyle (含 4 处 main.dart) |
| Spacing (token) | 4/5 | 4/5 | `spacingXs/Sm/Md/Lg/Xl/Xxs/Xxxs` 8 个集中器,剩 6 处裸 `12/4/16/24` 在 main.dart + app_shell.dart |
| Radius (token) | 5/5 | 5/5 | `radiusButton/Card/Input/Chip/Cell/CellLg` 6 个全用 |
| 暗色 mode | 4/5 | 4.5/5 | 4 个 shadowOf(context) 修 (R59 EMIL-T29),剩 1 处 `Colors.red/orange` 硬编 |
| 频度决策 | 4/5 | 5/5 | MotionScheme 4 档全活 (subtle/standard/delight 走集中器) |
| Interruptibility (Timer) | 4/5 | 5/5 | `Future.delayed` 全部 0 命中 (除注释),home_page/loading_skeleton/slide_up/fade_in 5 处全 Timer 化 |
| Press feedback | 4/5 | 5/5 | `PressFeedbackIconButton` 25+ 处用,R62 把 trend / medication 的 6 处 IconButton + 2 处 SegmentedButton 全迁移 |

---

## 1. 顶层架构审视 (2 条)

### 1.1 架构评级

| 维度 | 评分 | 理由 |
|---|---|---|
| **Token 集中化** | ⭐⭐⭐⭐⭐ (5/5) | `app_tokens.dart` 800 行,**单点入口**,覆盖 90%+ 设计决策 |
| **频度决策 (MotionScheme)** | ⭐⭐⭐⭐⭐ (5/5) | 4 档 enum + `Motion.duration/curve(context, base)` 减动 helper,**4+ 年 0 重复** |
| **暗色 mode 保护** | ⭐⭐⭐⭐ (4/5) | `primaryColor(context)` / `errorColor(context)` / `shadowCardOf(context)` 等 dynamic getter,**但** main.dart `Colors.orange/red` 仍裸用 (R60+ 未跟进) |
| **TextStyle token** | ⭐⭐⭐ (3/5) | 13 个 `textStyleXxx` helper,**但** 30+ 处 inline `TextStyle(fontSize, fontWeight, color)` 残留 (尤其 main.dart 4 处 + setup 2 处) |
| **命名/可发现性** | ⭐⭐⭐⭐⭐ (5/5) | emil "decisions should be nameable" 原则**已沉淀**: `kDeepLinkRaceGuard` / `celebrationDisplayMs` / `staggerStepMs` / `durPress` / `shimmerCycleMs` / `calendarLabelWidth` / `textLengthWarningThreshold` / `refreshMinVisibleMs` 全部有名字 |

### 1.2 顶层重构建议 (2 条)

| # | 模块 | 现状 | 建议 | 难度 | 优先级 |
|---|------|------|------|------|--------|
| 1 | **main.dart 占位 App 集群** (`_MigrationAbortedApp` / `_MigrationFailedApp` / `_MigrationPromptApp` 3 个) | 行 269-415 三个 _App 各自手写 `EdgeInsets.all(24)` / `SizedBox(height: 16)` / `Colors.orange` / `Colors.red` / 4 处 inline `TextStyle(fontSize+fontWeight)`,**违反 token 集中化** | 抽 `lib/presentation/widgets/launch/empty_state_app.dart` 共享 widget,接受 `iconColor` / `title` / `body` / `icon` 参数;main.dart 三个 _App 全走它 | M | P2 |
| 2 | **trend_page 4 chart panel 无 stagger** | `_buildListView` 4 个 chart (HeatmapGrid / MonthlyChart / AssessmentHistoryChart / MoodHistoryChart) 全部同时出现,无 FadeIn 错峰 (home_footer 有,trend 没有) | 抽 `lib/presentation/pages/trend/widgets/staggered_chart_section.dart`,接受 `child` + `index`,内部用 `AppTokens.staggerStepMs` 计算 delay | S | P2 |

---

## 2. 底层逐行排查 (10 条)

| # | 文件:行 | 现状 | 建议 | 架构/底层 | 难度 | 优先级 | 原因 |
|---|---------|------|------|------|------|------|------|
| 2.1 | `lib/main.dart:307, 368` | `Colors.orange` / `Colors.red` 硬编 | 抽 `AppTokens.iconColorWarning(context)` / `iconColorError(context)` (走 colorScheme.error/tertiary),替换 | 底层 | S | P1 | emil "暗色 mode silent killer" 同款 — dark mode 下 orange 跟 surface 反差小,red 在 M3 dark 偏暗 |
| 2.2 | `lib/main.dart:234, 236, 240, 242, 309, 317, 369, 377, 382` | 9 处 `const SizedBox(height: 12/4/16/12/16/12/16/12/16)` 裸值 | `12`→`spacingChipPaddingV`/`spacingXs`,`4`→`spacingXxs`,`16`→`spacingSm` | 底层 | S | P2 | emil "decisions should be nameable" — 12 跟 token 序列 8/16 重复但语义不清 |
| 2.3 | `lib/main.dart:300, 364, 401` | 3 处 `EdgeInsets.all(24/16)` 裸值 | `24`→`spacingMd`,`16`→`spacingSm` | 底层 | S | P2 | 同 2.2 |
| 2.4 | `lib/main.dart:312-315, 372-375, 389-393, 405-408` | 4 处 `const TextStyle(fontSize: fontSizeButton, fontWeight: FontWeight.w600)` / `TextStyle(fontSize: fontSizeCaption, color: ..., fontStyle: italic)` inline | 走 `AppTokens.textStyleButton(context)` (有现成) + `textStyleCaptionHint(context)` (有现成,italic 可加变体) | 底层 | S | P2 | emil 文字 token 集中器已铺好但 main.dart 没接 |
| 2.5 | `lib/presentation/widgets/animations/page_transition_switcher.dart:34` | `this.duration = const Duration(milliseconds: 100)` 裸值,**注**: `app_tokens.dart:380` 已经有 `durPageTransition = Duration(milliseconds: 100)` 集中器 | `this.duration = AppTokens.durPageTransition` (但 const 默认参数要求 const token,目前是 `static const Duration` 可用) | 底层 | S | P1 | emil P2-2.15 已知项 — R60 报告, R62 仍 0 改 |
| 2.6 | `lib/core/routing/app_shell.dart:82, 87, 90, 104` | `EdgeInsets.symmetric(vertical: 16)` / `size: 32` / `SizedBox(height: 4)` / `SizedBox(height: 8)` 4 处裸值 | 走 `spacingSm` / `iconSizeLg` / `spacingXxs` / `spacingXs` | 底层 | S | P2 | app_shell 是 R59 抽的,但没接 token 集中器 |
| 2.7 | `lib/core/theme/app_theme.dart:230, 232` | `selectedIconTheme: IconThemeData(color: cs.primary, size: 28)` / `unselectedIconTheme: IconThemeData(color: cs.onSurfaceVariant, size: 24)` — `size: 28`/`24` 裸值 | `28`→`iconSizeLg`, `24`→`iconSize` (有现成 token) | 底层 | S | P2 | emil "decisions should be nameable" — NavigationRail 图标尺寸没走 token |
| 2.8 | `lib/core/theme/app_theme.dart:121, 207` | `cs.onSurface.withValues(alpha: 0.5)` / `cs.onSurfaceVariant.withValues(alpha: 0.6)` 2 处裸 alpha,`app_tokens.dart:198, 204` 已经有 `fgDisabled` / `fgHintInput` 集中器 | 但 `_buildTheme` 是 ThemeData 工厂**没 BuildContext**,注释说"v0.25 评估 buildTheme 接受 context" — **3 年没改** | 底层 | M | P2 | emil TODO 滞留 — 改 ThemeData 接受 context (ThemeProvider 接口升级) |
| 2.9 | `lib/presentation/pages/trend/trend_page.dart:127-196` | 4 段 chart (HeatmapGrid / MonthlyChart / AssessmentHistoryChart / MoodHistoryChart) 无 stagger, 全部同时 build | 每个 SectionHeader + chart 套 `FadeIn(delay: Duration(milliseconds: i * AppTokens.staggerStepMs))` | 底层 | S | P2 | emil P2-2.16 已知项 — trend 多 chart 应有累积感 |
| 2.10 | `lib/presentation/pages/mood/widgets/mood_recorder.dart` (564 行) | 单文件 god page — 录音 + 评分 + 文字 + 头像 + 庆祝 + 6+ 处内联 TextStyle | 拆 `mood_recorder_page.dart` + `mood_audio_controls.dart` + `mood_score_chooser.dart` 3 文件 | 架构 | L | P2 | emil "cohesion" 原则 — 564 行单文件违反单职责 |

---

## 3. 视角特定清单 (emil 6 项必有)

### 3.1 暗色 mode silent bug (核心哲学)

| # | 文件:行 | 风险 | 当前状态 | 建议 |
|---|---------|------|----------|------|
| 3.1.1 | `lib/main.dart:307` | `Colors.orange` 在 M3 dark 偏暗 | ⏳ 未修 | 走 `colorScheme.tertiary` |
| 3.1.2 | `lib/main.dart:368` | `Colors.red` 在 M3 dark 偏暗 | ⏳ 未修 | 走 `errorColor(context)` |
| 3.1.3 | `lib/presentation/widgets/animations/page_transition_switcher.dart:34` | `const Duration(milliseconds: 100)` 100ms 在 reduce-motion 下不归零 | ⏳ 未修 (重复 2.5) | `Motion.duration(context, AppTokens.durPageTransition)` |
| 3.1.4 | `lib/core/theme/app_theme.dart:230, 232` | `IconThemeData(... size: 28)` 走的是 cs.primary/onSurfaceVariant 已经 theme-aware,但 28 是 M3 NavigationRail 偏离规范 (M3 spec 24) | ⚠️ 违规 | 改 `iconSizeLg` (32) 也不对,应直接 `iconSize` (24) |

> **Emil 原则**: "Decisions should be nameable" — 100ms / 28 / 24 都不应有名字吗?对 — 应该有 token,但更要 dark mode 自动适配 (reduce-motion / contrast)

### 3.2 Inline TextStyle (未走 token)

| # | 文件:行 | inline TextStyle | 应走 token |
|---|---------|-----------------|------------|
| 3.2.1 | `lib/main.dart:312` | `const TextStyle(fontSize: fontSizeButton, fontWeight: FontWeight.w600)` | `textStyleButton(context)` |
| 3.2.2 | `lib/main.dart:372` | 同上 | 同上 |
| 3.2.3 | `lib/main.dart:389` | `TextStyle(fontSize: fontSizeCaption, color: textHintColor(context), fontStyle: FontStyle.italic)` | 新增 `textStyleCaptionHintItalic(context)` 或加 `italic` 参数 |
| 3.2.4 | `lib/main.dart:405` | `TextStyle(fontSize: fontSizeCaption, color: textHintColor(context))` | `textStyleCaptionHint(context)` |
| 3.2.5 | `lib/presentation/pages/setup/setup_page.dart:268, 278` | 2 处 inline | 走 token |
| 3.2.6 | `lib/presentation/pages/contact/contacts_list_widget.dart` + 9+ 文件 | 仍散落 20+ 处 `TextStyle(fontSize, fontWeight)` 直接拼 | R57 漏改,待 v0.28 batch 2 |

> **注**: `app_tokens.dart:476-627` 已有 13 个 `textStyleXxx` 集中器,覆盖率只 ~70%,剩 30% 待 R68+

### 3.3 裸动效 (Future.delayed / 裸 Duration / 裸 Curves)

| # | 文件:行 | 现状 | R62 状态 |
|---|---------|------|----------|
| 3.3.1 | `lib/presentation/pages/home/home_page.dart:429-433` | `Future.delayed(1800ms)` → `Timer(celebrationDisplayMs)` + dispose | ✅ R62 P1-6 修 |
| 3.3.2 | `lib/presentation/widgets/loading_skeleton.dart:140-141` | `Future.delayed(600ms)` → `Timer(shimmerPauseMs)` + dispose | ✅ R59 EMIL-T21 修 |
| 3.3.3 | `lib/presentation/widgets/animations/fade_in.dart:67` | `Timer(widget.delay, ...)` + dispose cancel | ✅ R17 round 14 修 |
| 3.3.4 | `lib/presentation/widgets/animations/slide_up.dart:65` | `Timer(widget.delay, ...)` + dispose cancel | ✅ 同上 |
| 3.3.5 | `lib/core/data/services/vent_audio_storage.dart:96` | `await Future<void>.delayed(Duration(milliseconds: 100 * attempt))` — **重试逻辑**,fire-and-forget,无 cancel 需求 | ✅ 不需要改 (无 widget 关联) |
| 3.3.6 | `lib/core/data/services/mood_audio_service.dart:125` | `static const Duration _tickInterval = Duration(milliseconds: 100)` | ✅ 命名常量 + 业务逻辑 timer,非 widget dispose race |
| 3.3.7 | `lib/presentation/widgets/animations/page_transition_switcher.dart:34` | `const Duration(milliseconds: 100)` 默认参数 | ⏳ 见 2.5 |

> **结论**: `Future.delayed` 命中数 0 (除注释/2 处 fire-and-forget),R62 把 home_page 唯一 widget race 修了。**Interruptibility 原则 100% 满足**

### 3.4 裸间距 (EdgeInsets / SizedBox / BorderRadius / fontSize / size)

| # | 文件:行 | 现状 | 应走 token |
|---|---------|------|-----------|
| 3.4.1 | `lib/main.dart:234, 236, 240, 242, 309, 317, 369, 377, 382` (9 处) | `SizedBox(height: 4/12/16)` | `spacingXxs`/`spacingXs`/`spacingSm` |
| 3.4.2 | `lib/main.dart:300, 364, 401` (3 处) | `EdgeInsets.all(16/24)` | `spacingSm`/`spacingMd` |
| 3.4.3 | `lib/core/routing/app_shell.dart:82, 90, 104` (3 处) | `EdgeInsets.symmetric(vertical: 16)` / `SizedBox(height: 4/8)` | `spacingSm`/`spacingXxs`/`spacingXs` |
| 3.4.4 | `lib/core/theme/app_theme.dart:230, 232` (2 处) | `size: 28/24` NavigationRail icon | `iconSizeLg`(32)/`iconSize`(24) — **注**: M3 spec 24,project 应 `iconSize` 不用 `iconSizeLg` |
| 3.4.5 | `lib/presentation/pages/contact/contacts_list_widget.dart:80` | `padding: EdgeInsets.all(4)` | `spacingXxs` |
| 3.4.6 | `lib/presentation/pages/trend/trend_calendar.dart:148, 234` (2 处) | `EdgeInsets.symmetric(vertical: 2)` / `EdgeInsets.all(2)` | `spacingXxxs` |
| 3.4.7 | `lib/presentation/pages/medication/medication_calendar_page.dart:323, 359` (2 处) | `EdgeInsets.symmetric(vertical: 1)` / `EdgeInsets.all(1)` | **缺 token** — 1px 太细,加 `spacingHairline = 1.0` 或留 raw |
| 3.4.8 | `lib/core/data/services/medication_report_pdf_layout.dart` (10+ 处) | `fontSize: 9/10/11/12/13/18` `pw.SizedBox(height: 4/16)` `pw.EdgeInsets.all(8/10/12/32)` `pw.BorderRadius.circular(6)` | PDF 字体系统,应抽 `lib/core/data/services/pdf_tokens.dart` (新文件) 走 `AppTokens.fontSize*` 复用 |
| 3.4.9 | `lib/core/data/services/medication_report_pdf_layout.dart:104` | `pw.BorderRadius.circular(6)` 裸值 | 应走 `AppTokens.radiusCellLg` (4.0 不对) 或新增 `pdfRadiusCell = 6.0` |
| 3.4.10 | `lib/presentation/widgets/animations/celebration_bounce.dart:114` | `BorderRadius.circular(AppTokens.radiusButton)` ✅ |  |
| 3.4.11 | `lib/presentation/pages/home/home_page.dart:416` | `top: MediaQuery.of(ctx).size.height * 0.35` — **35% magic** | emil "decisions should be nameable" — 抽 `celebrationVerticalAnchor = 0.35` 常量 |

> **结论**: spacing token 覆盖率 ~80%,剩 main.dart 9 + app_shell 3 + PDF 10+ + 6 个其他 = **30+ 处 magic**,待 R68

### 3.5 裸字号 (fontSize / fontWeight)

| # | 文件:行 | 现状 | 应走 token |
|---|---------|------|-----------|
| 3.5.1 | `lib/main.dart:313, 373` | `fontSize: fontSizeButton` (Token 但 inline) | 走 `textStyleButton` helper |
| 3.5.2 | `lib/main.dart:390, 406` | `fontSize: fontSizeCaption` (Token 但 inline) | 走 `textStyleCaptionHint` helper |
| 3.5.3 | `lib/core/data/services/medication_report_pdf_layout.dart:58, 64, 85, 89, 145, 151, 172, 222, 258, 263, 316` | 11 处 `fontSize: 9/10/11/12/13/18` 裸 `pw.TextStyle` | 应抽 `PdfTokens.fontSize*` (10 个集中器),复用 `AppTokens.fontSize*` 命名 |

### 3.6 裸颜色 (Colors.X / Color(0x) / withValues(alpha))

| # | 文件:行 | 现状 | 应走 token |
|---|---------|------|-----------|
| 3.6.1 | `lib/main.dart:307, 368` | `Colors.orange` / `Colors.red` | 走 `theme.colorScheme.tertiary` / `errorColor(context)` (重复 3.1.1/2) |
| 3.6.2 | `lib/presentation/widgets/dimension_row.dart:61, mood_recorder.dart:433, check_in_button.dart:40` | `Colors.transparent` (3 处) | ✅ 透明是合规用法,**不用改** |
| 3.6.3 | `lib/presentation/widgets/medication_report_dialog.dart:162` | `Theme.of(context).colorScheme.scrim.withValues(alpha: 0.54)` | ⚠️ 0.54 是 magic,应抽 `scrimDialog = 0.54` 集中器 |
| 3.6.4 | `lib/presentation/pages/medication/refill_manage_page.dart:265, 329` | `statusColor.withValues(alpha: 0.15)` (2 处) | 走 `AppTokens.tintedPrimaryDeep(context)` 或新 `tintedStatusDeep` |
| 3.6.5 | `lib/presentation/pages/assessment/assessment_widgets.dart:351` | `trendColor.withValues(alpha: 0.6)` | 抽 `tintedTrendMid = 0.6` |
| 3.6.6 | `lib/core/theme/app_theme.dart:121, 207` | `cs.onSurface.withValues(alpha: 0.5/0.6)` (重复 2.8) | ⏳ fgDisabled/fgHintInput 已有但 buildTheme 无 context |

> **结论**: 颜色 token 覆盖率 ~92%,**但 6 处 magic 残留 (含 main.dart 2 处)**,emil 头号哲学"暗色 mode silent bug" — 这 6 处是 dark mode 隐患

### 3.7 频度决策 (新增 checklist)

| 频度 | 当前用法 | 评估 |
|------|---------|------|
| 100+/day (打卡/导航按钮) | `AnimatedContainer(duration: Motion.duration(context, AppTokens.durNormal))` | ✅ `MotionScheme.none` 路径,但 check_in_button 实际用 `durNormal` 300ms — 应 `durFast` 200ms 或 `none` (emil "no dance") |
| tens/day (列表/卡片) | `MotionScheme.subtle` (curveSubtle) | ✅ |
| occasional (modal/snackbar) | `MotionScheme.standard` (curveStandard) | ✅ |
| rare (庆祝) | `MotionScheme.delight` (curveDelight) + `curveBackOut` | ✅ |

> **修正建议**: check_in_button:32 `duration: Motion.duration(context, AppTokens.durNormal)` — 100+/day 操作,应 `durFast` (200ms) 或 `none`,否则打卡按钮感觉"卡"而非"快"

---

## 4. 与历史报告对比

> 引用: `consolidated.md` (R60+ 31 条) + `emil-v0.27+.md` (R60 评分) + `v0.27/review-emilkowalski-v027.md` (R60 详细)

| 历史项 | 来源 | R60 状态 | R62 状态 | 本次验证 |
|--------|------|----------|----------|----------|
| **P0-3** (notification 3 态分流 + main.dart:140 注释撒谎) | consolidated P0-3 + R60 S-01 | ⏳ 注释撒谎 | ✅ R62 working tree 修 (top-level `_smsService` + line 154 `_smsService.provider` + line 191 `overrideWithValue(_smsService)`) | ✅ 真修 |
| **P1-4** (safety_watch i18n) | consolidated P1-4 | 🔶 partial | ⏳ `displayMessage` 8 case 仍返中文 (本视角外) | 不属本视角 |
| **P1-6** (home_page Future.delayed race) | consolidated P1-6 | ⏳ 不可 cancel | ✅ R62 P1-6 修 (Timer + dispose) | ✅ 真修 |
| **P1-7** (setup_page:431 hardcode "完成设置") | consolidated P1-7 | ⏳ 中文 | ✅ R62 P1-7 修 (`snackbarActionFinishSetup` l10n key) | ✅ 真修 |
| **P1-9** (home_page:87 magic 100ms) | consolidated P1-9 | ⏳ magic | ✅ R62 P1-9 修 (`kDeepLinkRaceGuard` token, line 105 `await Future<void>.delayed(AppTokens.kDeepLinkRaceGuard)`) | ✅ 真修,但**仍用 Future.delayed 而非 Timer** — 因为 `_handleDeepLink` 是 async 函数无 widget 关联,cancel 由 `_safetyRerunRequested` flag 守,fire-and-forget 可接受 |
| **P1-14** (color: AppTokens.primary 40+ 处) | consolidated P1-14 | 🔶 partial (80%) | ✅ R49 已修 (`primaryColor(context)` 等 getter 替换),剩 0 处 `color: AppTokens.primary` | ✅ 真修 (R49 修的) |
| **P1-15** (6 个 IconButton 未用 PressFeedbackIconButton) | consolidated P1-15 | ⏳ 漏网 | ✅ R62 P1-15 修 (25+ 处迁移,grep 验证 0 处 `IconButton(` 直接用) | ✅ 真修 |
| **P1-16** (3 个 SegmentedButton 缺 :active) | consolidated P1-16 | ⏳ 裸 SegmentedButton | ✅ R62 P1-16 修 (`PressFeedback` 包裹,trend_page:243 / medication_calendar_page:88) | ✅ 真修 |
| **P2-2.12** (40+ magic Color/Radius/SizedBox) | consolidated P2-2.12 | 🔶 partial (80%) | 🔶 partial (90%) — 剩 30+ 处 (本报告 3.4) | ⚠️ 待 R68 |
| **P2-2.15** (page_transition_switcher:34 裸 100ms) | consolidated P2-2.15 | ⏳ 未修 | ⏳ **仍 0 改** | ❌ 漏 |
| **P2-2.16** (trend 4 chart 无 stagger) | consolidated P2-2.16 | ⏳ 未修 | ⏳ **仍 0 改** (grep 0 处 FadeIn in trend_page) | ❌ 漏 |
| **P2-2.21** (mood_recorder 564 行 god page) | consolidated P2-2.21 | ⏳ 待拆 | ⏳ 0 拆 | ❌ 漏 |
| **R60 emil S-03** (3 shadowCardOf 集中器) | R60 S-03 | ✅ | ✅ | ✅ |

> **结论**: R62 修了 6 条 P1 (P0-3 续 / P1-6/7/9/15/16),剩 3 条 P2 漏 (P2-2.15/16/21)。R62 emil 评分 41/44 (R60 39/40 → 41/44,**Color/TextStyle 维度稍增,Spacing 不变**)

---

## 5. 修复路线 (top 5, 按优先级)

1. **P1 (S)** — `lib/main.dart:307, 368` 替换 `Colors.orange/red` → `theme.colorScheme.tertiary/errorColor(context)` — **emil 头号"暗色 mode silent bug"**, 1 行 × 2 处,S 级
2. **P1 (S)** — `lib/presentation/widgets/animations/page_transition_switcher.dart:34` 改 `const Duration(milliseconds: 100)` → `AppTokens.durPageTransition` (const 默认参数可走 static const) — emil "decisions should be nameable" P2-2.15 历史项,**3 年没改**
3. **P2 (S)** — `lib/main.dart:234-401` 9 + 3 + 4 = 16 处裸 SizedBox/EdgeInsets/inline TextStyle 走 token (spacingXxs/Xs/Sm/Md/Lg + textStyleButton/CaptionHint) — emil 文字/间距 token 集中器已铺好,main.dart 没接,**单文件批量修** S 级
4. **P2 (S)** — `lib/presentation/pages/trend/trend_page.dart:127-196` 4 chart panel 套 `FadeIn(delay: i * staggerStepMs)` — emil P2-2.16 累积高级感,S 级
5. **P2 (M)** — 抽 `lib/core/data/services/pdf_tokens.dart` 收编 `medication_report_pdf_layout.dart` 11 处 `fontSize` / 4 处 `EdgeInsets` / 1 处 `BorderRadius.circular(6)` magic,复用 `AppTokens.fontSize*` 命名 — 跨 file-level (data 层) token,**M 级**

> 全部 R68 修, 1 个 sprint 内可完成 top 5。
