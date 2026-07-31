# emilkowalski 视角审查报告 (R62)

> 日期: 2026-07-31 / 视角: Design Engineering / 项目: chroniccare v0.25.0+1
> Baseline: `docs/reviews/v0.27/review-emilkowalski-v027.md`（35 个发现）

## 0. 元信息

- 审查范围: `lib/core/theme/{app_tokens.dart,app_theme.dart}` + `lib/presentation/widgets/{page_scaffold,press_feedback,loading_skeleton,theme_toggle_button}.dart` + `lib/presentation/widgets/animations/*` + 抽样 5 页（home/vent/assessment/trend_calendar/medication_calendar/setup）
- 修正状态（vs v0.27 R58 baseline）:
  - ✅ 已修: 6 项（T13 snackbar / T21 loading dispose / T29 删 4 const shadow / T32 textStyleCaption 0→14 引用 / T08 删 3 dead score token / T11 IconButton 24→13 改善 46%）
  - 🔶 部分修: 2 项（T10 ListTile 24→11 改善 54% / T16 inline TextStyle 6 page 但**总量退步** 191→206）
  - ⏳ 未修: 6 项（T01/T02 god file + T03/T04/T35 god page + T07 privacy CI + T17 a11y 7→6 持平）
  - 🆕 本轮新发现: 4 项（R-NEW-01..04）

## 1. 顶层架构审视（emil 视角）

**强项维持**:

1. **设计 token 单点真相 100% 维持**: `Color(0x` 仅 30 处全部在 `app_tokens.dart`（R49 dark mode 胜利，0 泄漏）。`Curves\.` 0 命中在 `app_tokens.dart` 之外 = 动效 100% token 化。`Future.delayed` 实际代码层仅 1 处（`home_page.dart:411`，注释 3 处）= dispose race 几乎清零。
2. **11+ dynamic color getter + 4 theme-aware shadow*Of 集中器**：`app_tokens.dart:78-140` / `430-465` 配合 v0.27 R59 删除 4 个 const shadow 版本，**杜绝 R49 同款 silent bug 重现**。
3. **精神心理患者友好决策精准命中**：`LoadingSkeleton` shimmer 走 1.2s 渐变 + 600ms 暂停"呼吸"（`loading_skeleton.dart:121-138`，已修 EMIL-T21 race）；`CelebrationBounce` 用 `curveBackOut` 1 次过冲（`celebration_bounce.dart:46-58`）；`Motion.duration/curve` 8+ 包装（`app_tokens.dart:740-751`）。
4. **集中 widget 库成熟**: `PressFeedback` 113 处 / `PressFeedbackIconButton` 22 处（grep 含自身）/ `AppListTile` 58 处 / `AppSnackBar.showX` 100% 集中（6 处全部在自身文件）。

**弱项（核心债务）**:

1. **`app_tokens.dart` 779 行 god file 未拆**（EMIL-T02 🔶 P1 维持）— 100+ token 仍平铺，无 `AppColors/AppMotion/AppTypography` 子模块分组。emil "decisions should be nameable" 在可发现性维度未推进。
2. **inline TextStyle 退步**（EMIL-T09 🔶 **退步 0%→负 8%**）— 206 处（v0.27 报 191，本轮退步 15）。`trend_calendar.dart` 11 处 + `medication_report_pdf_layout.dart` 12 处 + `edit_medication_dialog.dart` 7 处是重灾区。`textStyleCaption` 现 14 处用 = `EMIL-T32` 修，但 `textStyleMicro` 仍仅自用 1 处（`app_tokens.dart:569`），`textStyleTitle/Headline` 仍 0 引用 = 抽了没用，emil "taste = subtraction" 反例再添 2 例。
3. **4 个 god page 未拆**（EMIL-T03/T04/T24/T28 ⏳ P1 维持）— `setup_page.dart` 448 行 + `home_page.dart` 432 行 + `trend_calendar.dart` 521 行 + `mood_recorder.dart` 603 行。
4. **Spring 物理动效 0 引入**（EMIL-T12 ⏳ P2 维持）— vent/contact/medication 3 处 swipe-to-dismiss 仍走 tween `Dismissible`，emil "spring interruptibility" 体感折扣持续。

## 2. 底层逐行排查

### 2.1 P0 (必修)

| # | 文件:行 | 问题 | 修复方案 | 难度 |
|---|--------|------|---------|------|
| **P0-1** | `lib/presentation/pages/trend/trend_calendar.dart:111/132/251/312/332/363/392/417/462/477/486` | 11 处 inline `TextStyle(fontSize, fontWeight, color)` 集中在本 1 文件；其中 8 处可走 `textStyleCaption/Body/Headline` 集中器 | 3 round 子任务：先 `app_tokens.dart` 加 2 个缺位 token（`textStyleScoreMd=18/w700`），再批量替换 11 处，最后跑 `flutter test` + `flutter analyze` | **M** |
| **P0-2** | `lib/core/data/services/medication_report_pdf_layout.dart:12` + `edit_medication_dialog.dart:7` + `assessment_page.dart:7` + `setup_step_medication.dart:6` | 5 个 page 共 41 处 inline TextStyle，是 v0.28 头号工程 | 同 P0-1 模式：先扫 + 抽缺位 token + 批量替换 | **L** |

### 2.2 P1 (重要)

| # | 文件:行 | 问题 | 修复方案 | 难度 |
|---|--------|------|---------|------|
| **P1-1** | `lib/presentation/widgets/medication_report_dialog.dart:47` + `last_startup_error_banner.dart:81` + `mood_recorder.dart:517/525` + `vent_audio_section.dart:83` + `vent_detail_page.dart:182/266` + `trend_calendar.dart:99/118` + `notification_failure_banner.dart:54` | 11 处裸 `IconButton(`（R58: 24, R62: 13, 改善 46%）— 仍有 11 处未走 `PressFeedbackIconButton` | 一次性替换为 `PressFeedbackIconButton`（pattern 同 R23-40 已修 13 处）| **S** |
| **P1-2** | `lib/presentation/pages/contact/contacts_list_widget.dart:1` + `edit_medication_dialog.dart:1` + `reminders_hub_page.dart:2` + `setup_step_welcome.dart:1` + `assessment_reminder_section.dart:2` + `medication_row.dart:0` 等共 11 处 | 11 处裸 `ListTile(` 残留（EMIL-T10 改善 24→11, 54%）| 走 `AppListTile.standard` / `AppListTile.carded` 集中器（需先扩 API 支持 `onLongPress` 跟 `Hero` — `vent_list_page` 已注释"deliberate skip"）| **M** |
| **P1-3** | `lib/core/theme/app_tokens.dart:1-666` (779 行 god file) | 100+ token 平铺，缺 5 子模块分组（`app_colors.dart` / `app_motion.dart` / `app_typography.dart` / `app_spacing.dart` / `app_shadow.dart`）| 拆 5 子模块，`app_tokens.dart` 退化为 barrel file（emil 头号可发现性债）| **M** |
| **P1-4** | `lib/core/theme/app_tokens.dart:488-602` | 5 个 TextStyle helper 0 引用（`textStyleTitle` / `textStyleHeadline` / `textStyleBodyStrong` / `textStyleButtonInverse` / `textStyleMicro` — grep 验证，**仅 self-define + 1-2 处用**）| 删 4 个 + 留 `textStyleMicro` 1 个 + 改 inline 调用走 `textStyleCaption/Body/BodyStrong` 已存 helper | **XS** |
| **P1-5** | `lib/presentation/pages/setup/setup_page.dart:1-448` + `home_page.dart:1-432` + `trend_calendar.dart:1-521` + `mood_recorder.dart:1-603` | 4 个 god page 状态机 + 业务编排 + UI 全混 | 抽 4 个 `*State` Notifier，page 退化为 build-only shell（5 round 渐进，先 setup 后 home）| **L×4** |
| **P1-6** | `lib/core/theme/app_theme.dart:17-22` 静态工厂 + `app_tokens.dart:135-140` `disabledColor` 手挑 light/dark | 4 处 `isDark ? darkVar : lightVar` 在 `app_theme.dart` 内 = 静默 dark mode 风险（R49 教训）| 改 `AppTheme._build(BuildContext, Brightness)`，或在 `_build` 内读 `Theme.of(context).colorScheme.error` | **S** |

### 2.3 P2 (次要)

| # | 文件:行 | 问题 | 修复方案 | 难度 |
|---|--------|------|---------|------|
| **P2-1** | `lib/presentation/widgets/animations/celebration_bounce.dart:42-44` | 庆祝用 `MotionScheme.delight.duration`（500ms），但 `_controller` 自身不包 `Motion.duration()` 走 reduce-motion — `didChangeDependencies` 仅在 `value < 1.0` 时跳到 1.0，**`onCompleted` 仍 fire** 触发页面副作用 | 初始化时一次性 `Motion.duration(context, dur)` 或在 `addStatusListener` 内判断 `MediaQuery.of(context).disableAnimations` | **XS** |
| **P2-2** | `lib/presentation/pages/medication/widgets/medication_row.dart` + `refill_manage_page.dart` + `assessment_widgets.dart` + `trend_calendar.dart` 共 5 处 | 5 处散落 `withValues(alpha: 0.1/0.15/0.3)` 硬编码 alpha，未走 `tintedXxxSoft/Deep/Border` 集中器（`app_tokens.dart:155-210`）| 5 处替换为 `AppTokens.tintedWarningSoft(context)` 等 | **S** |
| **P2-3** | `lib/presentation/pages/trend/trend_page.dart:240-256` | `SegmentedButton` 缺 `PressFeedback` 包裹（`medication_calendar.dart:84-105` 已修，trend 仍裸）| 仿 medication_calendar 包裹 PressFeedback | **XS** |
| **P2-4** | `lib/presentation/widgets/dismissible` 3 处（vent_list / contact / medication）| `Dismissible` tween-based，缺 velocity-based 释放 + boundary damping（emil "spring interruptibility"）| 抽 `SwipeToDismissWithSpring` widget（`SpringSimulation` + velocity-based）| **M** |
| **P2-5** | `lib/presentation/widgets/app_semantics.dart` 6 处用（R58: 7 持平）| `AppSemantics.button(label: ...)` 集中器未推广到全部 IconButton / 自定义按钮（EMIL-T17 持平）| 扫全代码库 IconButton 残留 11 处 + 3 自定义 button，加 Semantics 包裹 | **M** |
| **P2-6** | `lib/presentation/pages/medication/medication_calendar_page.dart:374-378` `_colorFor` 阈值 | `0.5` / `1.0` magic 阈值未走 token（颜色已走 `adherencePartial` / `adherenceAlmost`，阈值没）| 抽 `AppTokens.adherenceThresholdPartial = 0.5` / `adherenceThresholdFull = 1.0` | **XS** |

### 2.4 P3 (可选)

| # | 文件:行 | 问题 | 修复方案 | 难度 |
|---|--------|------|---------|------|
| **P3-1** | `lib/presentation/widgets/theme_toggle_button.dart:30` | 主题切换走 `PressFeedbackIconButton` instant swap，**0 AnimatedTheme 过渡**（EMIL-T19 deliberately skip — 精神心理患者慎用 abrupt theme flip）| 维持 instant，**加 ARB 注释 `// Deliberate skip AnimatedTheme per emil guidance`** | **XS** |
| **P3-2** | `lib/core/theme/app_tokens.dart:225-228` | `fgOnSuccess` / `fgOnWarning` 是 const，但同文件其他 helper 全走 dynamic getter — 不一致 | 改 dynamic getter（但跟 `success` const 同步）| **XS** |
| **P3-3** | `lib/presentation/pages/setup/setup_step_welcome.dart:6` inline TextStyle | setup 4 步之一残留 inline，跟 trend_calendar 同款 | 走 `textStyleCaptionStrong` / `textStyleLabelMedium` 集中器（已存）| **S** |

## 3. 本轮新发现（R-NEW）

| # | 文件:行 | 问题 | 修复方案 | 难度 |
|---|--------|------|---------|------|
| **R-NEW-01** | `lib/core/theme/app_tokens.dart:62-65` 注释 | 注释"v0.18 (P1-5) batch 1: 加 7 个 getter + 替换 EmptyState + vent_list 最 critical 处。batch 2+ 替换剩余 90+ 处" — **注释承诺的 batch 2+ 至今未做**，仅 R49 干完 dark mode 100% 但注释未更新 | 更新注释到现状（R62 已 100% 走 dynamic getter 替换），删除误导性 "batch 2+" 描述 | **XS** |
| **R-NEW-02** | `lib/presentation/pages/home/home_page.dart:411` `Future.delayed(celebrationDisplayMs)` | 唯一非注释 `Future.delayed`（`app_tokens.dart:301` 已抽 token，但 home_page 实际值 = `AppTokens.celebrationDisplayMs` = 1800ms，已走 token ✅）— **R58 EMIL-T14 抽 `CelebrationOverlay.show` 集中器未做**，仍 inline 24 行 `OverlayEntry` + `Positioned` | 抽 `CelebrationOverlay.show(context, message)` 集中器（模式同 `MoodDialog.show`）| **S** |
| **R-NEW-03** | `lib/presentation/pages/medication/widgets/edit_medication_dialog.dart:406 行` + `setup_page.dart:448 行` | 两 god file **都未进入 R57-58 god file 拆分 round**（R57 仅拆 app_router + app_routes）| 优先拆 setup 4 步（已拆 widget 目录）+ edit_med 表单（4 widget 拆 4 文件）| **L** |
| **R-NEW-04** | `lib/core/theme/app_tokens.dart:621-635` 响应式断点注释 | `breakpointCompact=600` / `breakpointMedium=840` 注释为"Material 3 推荐的 window size class 边界"，但项目实际 `PageScaffold` 仅判 `>= 840` 一档（`page_scaffold.dart:33`），**`breakpointMedium=840` 等于 `breakpointExpanded=840` 造成死 token**（`windowSizeOf` 判 `medium` 仅 0 像素宽）| 改 `breakpointMedium=600`（M3 spec 一致）或 `windowSizeOf` 删 medium 分支 | **XS** |

## 4. 设计系统健康度（R62 实测）

| 维度 | R58 评 | **R62 评** | Δ | 关键证据 |
|---|---|---|---|---|
| 动效 token 化 | 100% | **100%** | 维持 | `Curves\.` 在 `app_tokens.dart` 外 = 0 命中 |
| 色彩 token 化 | 100% | **100%** | 维持 | `Color(0x` 在 `app_tokens.dart` 外 = 0 命中 |
| dark mode 兼容 | 100% | **100%** | 维持 | 11+ dynamic getter + 4 shadow*Of context-aware + 4 const shadow 已删 |
| icon 尺寸 token 化 | ~100% | **~100%** | 维持 | iconSizeInline=18 等 6 档 |
| spacing token 化 | 100% | **100%** | 维持 | `SizedBox((width\|height):\s*[0-9]` 在 presentation/ = 0 命中 |
| **文字 TextStyle 化** | 36% (191 inline) | **32% (206 inline)** | **退步 8%** | trend_calendar 11 / medication_report_pdf_layout 12 / edit_med 7 |
| AppListTile 覆盖率 | 71% (24 裸) | **84% (11 裸)** | ✅ +13% | 24 → 11 |
| 触感 PressFeedback | 108 | **113** | ✅ +5 | 86 → 113（含自身 13 + icon 22） |
| **SnackBar 集中器** | 11 漏 | **0 漏** | ✅ 100% | showSnackBar( 仅 6 处在 app_snack_bar.dart 自身 |
| **a11y 集中器** | 7 | **6** | 🔶 持平 | AppSemantics.container/button/exclude 6 处用（R58: 7） |
| dead token 残留 | 3 (textStyleScoreLg/Xl/Xxl) | **5** (textStyleTitle/Headline/BodyStrong/ButtonInverse/Micro) | **退步** | 0 引用验证 + 新发现 4 个候选 |
| **shimmer race** | 1 风险点 | **0** | ✅ | Timer 替代 Future.delayed + dispose cancel |
| **withValues(alpha:** | 散落 21+ | **5 泄漏** | ✅ 改善 | app_tokens 内 26 + app_theme 内 2，**仅 5 个 presentation 泄漏** |

## 5. v0.28 头 round 推荐（按 emil 杠杆排序）

| Rank | 编号 | 标题 | 严重度 | 工作量 | 收益 |
|------|------|------|--------|--------|------|
| 1 | **P0-1+P0-2** | inline TextStyle 206→<80（trend_calendar 11 + 5 hot page 30 优先）| **P0** | L | emil "decisions should be nameable" 文字维度 32%→80%+ |
| 2 | **P1-3** | `app_tokens.dart` 779→5 子模块 | P1 | M | 头号可发现性 |
| 3 | **P1-4** | 删 5 个死 TextStyle helper（**含 R-NEW 新发现**）| P1 | XS | "taste = subtraction" |
| 4 | **P1-1** | 11 处裸 IconButton 走 `PressFeedbackIconButton` | P1 | S | EMIL-T11 收尾 |
| 5 | **P1-2** | 11 处裸 ListTile 走 `AppListTile` | P1 | M | EMIL-T10 收尾（需扩 API）|
| 6 | **P1-6** | `app_theme._build` 加 context，修 4 处 silent dark mode 风险 | P1 | S | 防 R49 同款 bug |
| 7 | **R-NEW-02** | 抽 `CelebrationOverlay.show` 集中器 | P1 | S | EMIL-T14 收尾 |
| 8 | **P2-2** | 5 处 `withValues(alpha:)` 走 `tintedXxxSoft` | P2 | S | tinted 集中器 100% 利用 |
| 9 | **P2-4** | 抽 `SwipeToDismissWithSpring` 集中器 | P2 | M | emil spring physics |
| 10 | **P1-5** | 4 个 god page 拆 state Notifier | P1 | L×4 | emil 1 page 1 主题 |

## 6. emil 哲学对照

- ✅ **"Good defaults matter more than options"**: `MotionScheme` 4 档 / `Haptics` 4 类 / `AppSnackBar.showX` 5 类 / `PressFeedback` 2 模式 / `AppListTile` 2 模式
- ✅ **"Decisions should be nameable"**: 100% token 化（除文字）/ `swallowError` / `*.show(context, ref)` 静态 API
- ✅ **"Unseen details compound"**: loading 呼吸 / 庆祝 1 次过冲 / barrierDismissible crisis / Shimmer Timer dispose / reduce-motion 包装
- ❌ **"Taste = subtraction"**: 5 个死 TextStyle helper（R-NEW 退步 3→5）/ `textStyleMicro` 抽了 0 用 / `breakpointMedium=840` 死 token / app_tokens 779 行未拆
- 🔶 **"Cohesion matters"**: AppListTile 84%（提升中）/ IconButton 84%（提升中）/ 4 god page 未拆（持平）

## 7. 精神心理患者特殊决策（R62 维持）

1. ✅ **Loading shimmer "呼吸"**（`loading_skeleton.dart:121-138` + dispose race 已修 EMIL-T21）
2. ✅ **CelebrationBounce 1 次过冲**（`celebration_bounce.dart:46-58`，**R-NEW 建议**：`_controller` 加 reduce-motion `Motion.duration` 包装）
3. ✅ **PressFeedback 不接管 onTap**（`press_feedback.dart:107-115`）= 100+/day 按钮仍得 InkWell ripple
4. ✅ **Haptics.warning** 删除警示（4 类触感）
5. ✅ **Undo 4 秒反悔窗口**（`AppSnackBar.undo`）
6. ✅ **PageTransitionSwitcher fade 而非 slide**（`page_transition_switcher.dart:53-55`）
7. 🔶 **HoldToConfirm 0 引入**（EMIL-T12 / R62 持平）— 精神心理患者情绪低谷误删可逆保护缺失

## 8. 报告总结

| 维度 | R58 评 | R62 评 | Δ |
|---|---|---|---|
| 顶层架构 | 7/10 | **7/10** | 持平（god page 4 个未拆）|
| 设计系统健康度 | 8/10 | **8/10** | 持平（textStyle 退步但 ListTile/IconButton/snackbar 改善抵消）|
| 动画 / 动效 | 9/10 | **9/10** | 持平（spring 仍 0 引入）|
| Dark mode | 10/10 | **10/10** | 维持 |
| 触感 | 9/10 | **9/10** | 持平 |
| 无障碍 | 7/10 | **7/10** | 持平（AppSemantics 7→6 微退步）|
| 精神心理患者特殊 | 9/10 | **9/10** | 持平（HoldToConfirm 缺）|

**R62 头号胜利**：`AppSnackBar.showX` 集中器 100% 落地（11→0 漏，**唯一 100% 集中器维度**）；`shimmer dispose race` 修；`AppListTile` 覆盖率 71%→84%。

**R62 头号债务**：inline TextStyle **退步 191→206**（8% 退步）— 唯一在 v0.28 头 round 必修项。新发现 5 个死 TextStyle helper（vs R58 3 个）= "taste = subtraction" 退步。

**v0.28 头 5 round**：P0-1+P0-2（文字 token 化 32%→80%+）+ P1-3（app_tokens 拆 5 子模块）+ P1-4（删 5 死 helper）+ P1-1（IconButton 11 收尾）+ P1-2（ListTile 11 收尾）。

**v1.0 长期**：EMIL-T01（`package:chroniccare_ui/` design system 抽包）— 顶层架构债终极解。

---

**报告路径**: `D:\Batch\chroniccare\reports\round62-seven-lens\lens\01-emilkowalski.md`
> **总计 22 个发现**（P0 ×2 + P1 ×6 + P2 ×6 + P3 ×3 + R-NEW ×4 = 已合并 EMIL-T 编号）
> **vs R58 baseline**: ✅ 已修 6 / 🔶 部分修 2 / ⏳ 未修 6 / 🆕 新发现 4
