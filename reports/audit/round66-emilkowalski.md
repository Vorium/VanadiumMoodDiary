# emilkowalski 视角全量审计（v0.27 R66）

**审计时间**: 2026-07-31
**项目**: chroniccare
**版本**: 0.27.0+64（R66 收尾中）
**视角**: Design Engineering (emilkowalski)
**审计模式**: 全量（聚焦 presentation 层 + theme + routing）
**审计基线**: 1237 tests pass / 0 analyzer error / 16 守护脚本全绿

---

## 1. 总览

- **整体设计成熟度**: ⭐⭐⭐⭐½ / 5
- **TL;DR**: R40-R41 / R17 round 1-2 把 emil 体系搭得相当完整（4 个 curve token、6 个 duration token、46 处 magic spacing 走 token、PressFeedback 集中器全栈覆盖、3 类路由 transition）。剩下的"差一口气"问题集中在 **3 个层**：
  1. **小颗粒度 token 缺失**：约 8-12 处 `EdgeInsets.all(1/2/4)`、`SizedBox(width: 18, height: 18)`、`width: 36, height: 36`、`width: 10, height: 10` 等"原子尺寸"散在 6+ 文件，需要新的 token
  2. **内联 `TextStyle(...)` 仍在扩散**：12+ 处 `TextStyle(fontSize, fontWeight, color)` 不走 `textStyleXxx` 集中器，特别是大数字 score 区域（trend summary、assessment 分数）
  3. **重复 widget 模式**：`Stat` 数字卡（trend_summary + refill_manage 各 1 份）、`TimeChip`（setup + today_med_schedule 同款）、"icon 容器" 40×40（reminder_cards / refill_manage 同款）、"空态 info 提示条" 5+ 处同款
- **建议优先修**: 详见第 8 节 Top 10 修复清单

---

## 2. 微交互 (P0 / P1 / P2 分类)

### P0（必须修）

| 位置 | 问题 | 修复建议 | 估计工时 |
|------|------|----------|----------|
| `app_routes.dart:128-170` | `errorBuilder` 内部用 `Icons.help_outline` + 大段文字 + 单个 home 按钮。返回路径写死 `GoRouter.of(context).go('/')`，但用户可能从未 setup（first run 状态），被 redirect 到 `/setup` 又是另一条死路。**emil "error 出现 = 用户卡住，必须给明确出口" 原则违反**：单一 home 按钮 → setup 用户又得绕一步 | ① 用 `ref.read(userProfileProvider)` 决定跳 `/` 还是 `/setup`；② 加重试按钮（`GoRouter.of(context).push(state.matchedLocation)`）；③ icon 改用 `Icons.sentiment_dissatisfied` 配 `AppTokens.errorColor` 走 ErrorState 风格而非裸 `Text` | XS |
| `medication_report_dialog.dart:106-149` | 底部 3 个按钮（复制 / PDF / 分享），**复制按钮和分享按钮被 PressFeedback(child: OutlinedButton(onPressed: null)) 包，重复模式 + 复制按钮 onPressed: null 注释"委托给 PressFeedback"**。emil 一致性违反：3 个按钮 3 种不同模式（手写 PressFeedback / LoadingTextButton / 手写 PressFeedback） | 抽 `OutlinedButtonWithPress` 集中器或者统一改用 `LoadingTextButton` 集中器（`isLoading=false` 模式），1 行 1 个 button 替代 11 行 3 种 | S |
| `home_page.dart:541-570` | `_showCelebrationOverlay` 用绝对坐标 `MediaQuery.of(ctx).size.height * 0.35` 定位 overlay，**键盘弹起 / 横屏 / 全面屏 / 大屏设备时 35% 算出来可能撞到键盘或飞到屏幕外**。emil "布局要 responsiveness" 原则违反 | 改用 `Overlay.of(context).insert` + `Positioned(top: MediaQuery.padding.top + 80, left: 0, right: 0)`，避开系统状态栏 | XS |

### P1（应当修）

| 位置 | 问题 | 修复建议 | 估计工时 |
|------|------|----------|----------|
| `trend_summary.dart:36-66` & `refill_manage_page.dart:346-376` | 两处各定义了一份 `_Stat` widget（label + value），**结构相同**：`Column(text value headline w600 / text label caption w400）`。refill 那份已经 token 化，trend 那份还走裸 `TextStyle(fontSize: fontSizeHeadline, fontWeight: w600)`。emil "DRY for taste" | 抽 `Stat` public widget 到 `presentation/widgets/stat.dart`，3 个参数（label / value / valueColor），trend + refill 复用 | XS |
| `medication_calendar_page.dart:410-436` | `_legendItem` 12×12 圆角矩形 + 文字是**热力图图例**。但 `medication_calendar_page.dart:399-403` 4 个图例项的标签走 hardcoded `'< 50%'` / `'< 100%'` / `'100%'`，en/zh/zh_Hant 用户都看到 magic 字符串 | 标签加 l10n（`medsCalendarLegendP50` / `medsCalendarLegendP100` / `medsCalendarLegendP100Full`）3 个 key | XS |
| `medication_calendar_page.dart:351-378` | `_CellBox` 不可点击 / 不可 hover / 不可 focus，**没有 tooltip / 不可访问性**。emil "信息有但不可达 = 不存在" 原则违反：用户想知道"3 月 15 日的依从率"必须切到 trend 页才能看明细 | ① 加 `Tooltip`/`AppSemantics.container` 显示 `med.name, 3/15, 5/8 (62%)`；② `InkWell` 包 `Container` → 点击跳到当日明细（但当前没此页，留 P2 后续） | S |
| `medication_row.dart:123-158` | trailing 区 3 个 IconButton + 1 个 conditional spinner，但**spinner 出现时 3 个 button 全消失**（`if (isEditing || isEditingRefill || isDeleting) { spinner } else { 3 buttons }`）。等 loading 完 → 3 个 button 突现，**没有 transition**，emil 频度 tens/day 体感"跳" | 加 `AnimatedSwitcher`（durFast）包 button row，loading ↔ buttons 切换 fade | XS |
| `setup_step_medication.dart:121-146` | "下一步" 按钮 `SizedBox(width: 110, height: 44)` 硬编 + `Stack(PrimaryButton + IgnorePointer(CircularProgressIndicator))` 是**项目已抽 `LoadingTextButton` 集中器的同款重复**（v0.24 round 43 P1-01 H-03 抽的）。这处是 R43 抽集中器时漏的同款 | 改用 `LoadingTextButton(label: l10n.setupNext, isLoading: saving, onPressed: saving ? null : onFinish)` 替换 26 行 | XS |
| `assessment_page.dart:104-128` | 顶部说明条 + 答题进度 + LinearProgressIndicator 是**3 段重复 inline**，**没有 PageTransitionSwitcher 的 quiz→result 切换时 progress bar 没动画**。emil 频度 occasional 切换 quiz→result 时 progress 应当平滑从 100% → 完成 | `LinearProgressIndicator` 包 `TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: _answered / scale.items.length), duration: durFast, curve: curveStandard)`，跨 quiz 切换也走 | XS |
| `setup_widgets.dart:51-105` | `ConsentCheckRow` 是**3 段重复**（3 个 ConsentCheckRow 调 `setup_step_consent.dart:75-94`）。Container 边框 + Checkbox + 文字 + TextButton 全部 inline，**没走 `AppListTile.standard`**（虽然 onTap 是 toggle 模式不一致，但视觉结构高度同款） | 抽 `ConsentCard` 集中器：复用 R40 风格 `tintedPrimarySoft` 背景，3 处直接 `for (final c in consentList) ConsentCard(...)` | S |
| `contact/contacts_list_widget.dart:75-83` | 删中态：`_deleting.contains` 时显示 `LoadingSpinner(size: 16)` 装在 `Padding(EdgeInsets.all(4))` 内 + 16×24 SizedBox，**padding magic 4 没走 token**。emil "decisions should be nameable" 违反 | 加 `AppSpacing.spacingXxs` 替代，或用 `IconButton(visualDensity: VisualDensity.compact)` + 内部 spinner | XS |
| `settings/widgets/notification_status_card.dart:219-224` | 同样 pattern：`_busy` 时显示裸 `LoadingSpinner(size: 16)` 装在 `SizedBox(width: spacingSm, height: 16)`。两个 widget 跟 `medication_row.dart:127-131` 是同款 "InlineSpinnerInTrailing"，3+ 处复制 | 抽 `TrailingSpinner` 或 `InlineProgress` 集中器 | XS |

### P2（可改）

| 位置 | 问题 | 修复建议 | 估计工时 |
|------|------|----------|----------|
| `home_page.dart:564` | `_celebrationTimer = Timer(const Duration(milliseconds: AppTokens.celebrationDisplayMs), ...)` — **AppTokens.celebrationDisplayMs 是 `int` 1800**，但 `Duration(milliseconds:)` 接受 int，OK。**真正的 issue**: 1800ms 偏长（emil 频度 rare 庆祝反馈应 1000ms 内），用户可能"等不到"新页面 | 改用 `AppTokens.durSlow` (500ms) 或新建 `celebrationDisplayDuration` Duration 类型 token | XS |
| `medication_report_dialog.dart:159-187` | `_pdfLoading` 时的全屏 scrim 走 `Card + Padding` 装小 spinner，**overlay 弹出后 user 仍能点到底下的复制/分享按钮**（只有 PDF 按钮 disabled）。emil "modal 出现 = 用户 100% 锁死在 modal 上" 原则违反 | 加 `AbsorbPointer(child: ColoredBox(...))` 把 scrim 范围内的所有点击 absorb 掉 | XS |
| `setup_step_medication.dart:71-100` | "无药物"空态是裸 `Container` + `Icon + Text`，**没用项目已有的 `EmptyState` 集中器**（v0.21 R22 P0-11 抽的），违反 R22 "5+ 处用 EmptyState 集中器" 决定 | 改用 `EmptyState(icon: Icons.info_outline, title: l10n.setupMedEmptyHint, subtitle: ...)` | XS |
| `medication_calendar_page.dart:380-407` | `_Legend` 5 个图例项横向 Row + 卡片 padding 全裸，**没走 SectionHeader / AppListTile / ChipBadge 任何一个**集中器。emil 同款 5+ 处用集中器原则违反 | 抽 `HeatmapLegend` widget 或用 `ChipBadge(icon: dot_color, label: legend_text)` 串联 4 个 | S |
| `medication_calendar_page.dart:54-72` | 顶部说明条是 `Container(padding, BoxDecoration(color: primaryLight, radius), child: Row(icon, text))` — 跟 `medication_report_dialog.dart:61-73`、`setup_step_medication.dart:72-100`、`medication/temp_medication_dialog` 的"信息条"同款 4+ 处。emil "cohesion" 违反 | 抽 `InfoBanner(icon, text, tone: InfoBannerTone.info/warning/success)` 集中器 | S |
| `reminders_hub_page.dart:318-333` 和 `:456-471` | 两个 `Wrap(spacing: 8, runSpacing: 8, children: [ChoiceChip])` 完全同款，**只有 `_options` 跟 `_days`/`_threshold` 字段不同**。两处约 30 行 inline，重复模式 | 抽 `ChoiceChipWrap<T>(options: List<T>, selected: T, labelOf: T → String, onSelect: T → void)` 集中器 | S |
| `app_routes.dart:132` | errorBuilder 的 `appBar: AppBar()` 裸 `AppBar()`，**没有 title / 没导航按钮**，用户进 error 页面后**点 back 直接退出 app**。emil "error 也要有出口" 原则 | 加 `automaticallyImplyLeading: true`（默认 true）→ 但要加 `IconButton(icon: home, onPressed: go('/'))` 当 leading 防止误触 | XS |
| `assessment_page.dart:67-81` | 路由给错 scale id 时显示"loading + '返回上一页'"，**实际是无限 spinner 配合下一帧 pop**。emil "loading 应该是骨架而非 spinner" 违反（项目 R17 round 8 + R22 round 29 强调） | 改用 `LoadingSkeleton.card(child: SizedBox.shrink())` 或直接显示空态 200ms 后 pop | XS |

---

## 3. 动效

### 现状

- **曲线**: 0 处散落 `Curves.easeInOut` 等，**4 个 curve token (`curveStandard`/`curveSubtle`/`curveDecelerate`/`curveAccelerate`/`curveDelight`/`curveBackOut`) 集中度 100%** ✅ R17 已修
- **时长**: 1 处散落 `Duration(milliseconds:)` 在 `lib/core/data/services/vent_audio_storage.dart:95`（`100 * attempt` magic — 1 处 OK）+ 1 处散落 `lib/core/data/services/mood_audio_service.dart:124`（`Duration(milliseconds: 100)` for `_tickInterval` — 抽 token 即可）。其余 14 处都走 `AppTokens.durFast/Normal/Slow/Press/PageTransition` ✅
- **transition**: 3 类集中（fadePage / slideRightPage / slideUpPage）走 reduce-motion 包装 ✅
- **reduce-motion**: 9 个动画 widget 都包了 `MediaQuery.disableAnimations` 检查 ✅
- **stagger**: 4 处用 `AppTokens.staggerStepMs + staggerCapMs` 公式 ✅

### P0 残留

| 位置 | 问题 | 修复建议 | 估计工时 |
|------|------|----------|----------|
| `mood_audio_service.dart:124` | `static const Duration _tickInterval = Duration(milliseconds: 100);` — 录音 tick 间隔 100ms **没走 token**。emil "decisions should be nameable" 违反（100ms 是 audio 进度 polling 周期，语义独立于 durFast 200ms） | 加 `AppTokens.audioTickInterval` 到 `app_motion.dart` | XS |
| `vent_audio_storage.dart:95` | `await Future<void>.delayed(Duration(milliseconds: 100 * attempt));` — file lock 重试退避，magic 100ms 没走 token | 加 `AppTokens.fileLockRetryStep` (int) = 100 到 `app_spacing.dart` | XS |
| `loading_skeleton.dart:128, 141` | shimmer 走 `AppTokens.shimmerCycleMs` (1200) / `shimmerPauseMs` (600) ✅ 但 `_ShimmerState._controller.duration` 直接 `Duration(milliseconds: AppTokens.shimmerCycleMs)` 转换 OK 没动效，**`AnimatedOpacity` 替代 `Opacity` 的 linear `0.4 + value * 0.3` 公式硬编**。emil "curve tokens" 违反 | 加 `shimmerOpacityMin: 0.4` / `shimmerOpacityMax: 0.7` 到 `app_motion.dart`，并把 `AnimatedOpacity` 改成 `AnimatedBuilder + Opacity` 走 `curveSubtle` | XS |

### P1 残留

| 位置 | 问题 | 修复建议 | 估计工时 |
|------|------|----------|----------|
| `check_in_button.dart:31-58` | `AnimatedContainer` 200ms + `AnimatedSwitcher` 200ms + `ScaleTransition` 缩放 全部用 `Motion.duration(context, AppTokens.durNormal)` ✅，**但 `ScaleTransition(scale: anim, child: child)` 用线性 0→1 没用 curve** | 加 `scale: Tween(begin: 0.95, end: 1).animate(CurvedAnimation(parent: anim, curve: AppTokens.curveStandard))` | XS |
| `home_page.dart:541-570` | `_showCelebrationOverlay` 的 overlay 1.8s 持续时间，**没走 reduce-motion 包装**。`Motion.duration` 应该包 | `Timer(Motion.duration(context, Duration(milliseconds: AppTokens.celebrationDisplayMs)), ...)` | XS |
| `medication_report_dialog.dart:159-187` | scrim `ColoredBox` 是**硬切 0% → 54%**，没有 fade in 动效。emil "modal 出现 / 消失应该 fade" 违反 | `AnimatedContainer(duration: durNormal, color: scrimWithAlpha)` 替代裸 `ColoredBox` | XS |
| `medication_calendar_page.dart:228-238` | FadeIn stagger 40ms/step，**已经在 R40 抽 token** ✅，但 `delay: Duration(milliseconds: (i * step).clamp(0, cap))` 在 2 处用，**没抽 helper**（medication_calendar + vent_list 各写一次） | 加 `AppTokens.staggerDelay(int i) → Duration` helper 到 `app_spacing.dart`，2 处替换 | XS |
| `today_med_schedule.dart:1-2` | 主页次要卡，**没有任何入场动效**（其他 3 块 header/footer/primary 都有 FadeIn）。emil 一致性违反 | 加 `FadeIn(delay: Duration(milliseconds: 2 * staggerStepMs), child: TodayMedSchedule)` | XS |

### P2 残留

| 位置 | 问题 | 修复建议 | 估计工时 |
|------|------|----------|----------|
| `setup_page.dart:120-139` | 4-step wizard 切换走 `PageTransitionSwitcher` + 自定义 `FadeTransition + SlideTransition` ✅，**但 begin = `Offset(0, 0.04)` 硬编**，0.04 = 4% 偏移 magic | 加 `MotionScheme.standard.slideBegin` (Offset(0, 0.04)) 到 `app_motion.dart` | XS |
| `medication_calendar_page.dart:219-243` | Card `Padding` + Column + `FadeIn(delay: ...)` 包裹 30 行，**没有统一的 `CalendarCard` widget 集中 stagger 入场**。emil "cohesion" 弱 | 抽 `CalendarCard` wrapper，stagger + padding 集中 | S |

---

## 4. 设计 token 一致性

### 散落硬编 (P0/P1)

#### 颜色（emil "no hardcoded colors"）

| 位置 | 问题 | 修复建议 | 估计工时 |
|------|------|----------|----------|
| `core/theme/app_theme.dart:128` | `// TODO v0.25: 评估 buildTheme 接受 context (会变更 ThemeProvider 接口)` — **已挂 2 个 round**（v0.24 R48 → v0.27 R65），`disabledForegroundColor: cs.onSurface.withValues(alpha: 0.5)` 走 `AppColors.fgDisabled` 集中器即可（已有！） | 替换为 `AppColors.fgDisabled(context)`，删 TODO。emil "未命名 magic alpha" 违反 | XS |
| `core/theme/app_theme.dart:209` | `hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6))` — `AppColors.fgHintInput` 已有集中器 | 替换为 `AppColors.fgHintInput(context)` | XS |
| `settings/settings_page.dart:63, 92` | `Icon(Icons.workspace_premium, color: AppColors.success)` 和 `color: AppColors.primary` — **直接用 const `AppColors.success` / `AppColors.primary`**（在 dark mode 下不反白）。R49 P0-1 已修 35+ 处，但 settings_page.dart:63 + 92 是 R49 漏的 2 处 | 替换为 `AppColors.successColor(context)` / `AppColors.primaryColor(context)`，**或** 加 `successColor(BuildContext)` / `primaryLightDarkColor(BuildContext)` 集中器 | XS |
| `medication_report_dialog.dart:79` & `vent_detail_page.dart:243` & `mood_audio_section.dart:417` | `color: AppTokens.surfaceColor(context)` 用在 `Container(color:)` — **正确走 dynamic getter** ✅，但 `medication_report_dialog.dart:79` 是 `Container(width: double.infinity, padding: ..., color: AppTokens.surfaceColor(context), child: SingleChildScrollView(...))` — 整块 `Container(color)` 没意义（surface = 背景色），多余层级 | 删 `Container`，`SingleChildScrollView` 直接放 `Column` 即可 | XS |

#### 字号（emil "走 token"）

| 位置 | 问题 | 修复建议 | 估计工时 |
|------|------|----------|----------|
| `trend_summary.dart:48-51` | `style: const TextStyle(fontSize: AppTokens.fontSizeHeadline, fontWeight: FontWeight.w600)` — **大数字 stat value** 重复模式。`AppTokens.textStyleHeadline` 已有但没用（因为 `textStyleHeadline` = 24/w700/lineHeightTight + textPrimaryColor，而 stat = 24/w600） | 加 `AppTokens.textStyleStatValue` 集中器或直接 `textStyleHeadline` | XS |
| `refill_manage_page.dart:368-372` | `style: AppTokens.textStyleButton(context).copyWith(fontWeight: w700, color: ...)` — stat value 同款。已走 `textStyleButton` ✅，但 `copyWith(fontWeight: w700)` 覆盖 | 加 `AppTokens.textStyleStatValue` = `textSizeButton + w700 + lineHeightTight` 集中器 | XS |
| `assessment_page.dart:306` | 大分数 64pt 走 `AppTokens.fontSizeScoreXxl` ✅，**但 R57 删除了 `textStyleScoreXxl` 集中器**（注释说"未来直接用 textStyleTitle"），导致 `TextStyle(fontSize: 64, fontWeight: w700, ...)` 多次重复 | 恢复 `textStyleScoreXxl` 集中器 | XS |
| `assessment_widgets.dart:335, 367` | `fontSize: AppTokens.fontSizeScoreXl` 走 token ✅，**但周围 TextStyle(fontSize, fontWeight: w700, color: primary) inline** | 抽 `textStyleScore` 集中器（size 接受 Lg/Xl/Xxl 参数） | S |
| `setup_step_done.dart:43, 53, 62, 74` | 4 处 `const TextStyle(fontSize: AppTokens.fontSizeTitle, fontWeight: w600)` 和 `fontSizeBody, color: textSecondary` — 跟 setup_step_consent / setup_step_welcome / setup_step_medication 的 title / subtitle **完全同款** | 用 `AppTokens.textStyleTitle` / `textStyleBody` + 适当 `copyWith` 或新加 `textStyleSetupTitle` / `textStyleSetupSubtitle` 集中器 | XS |

#### 间距（emil "走 token"）

| 位置 | 问题 | 修复建议 | 估计工时 |
|------|------|----------|----------|
| `medication_calendar_page.dart:358` | `padding: const EdgeInsets.all(1)` — 1px grid cell 间隔 magic，没 token | 复用 `AppTokens.spacingCellGap` (新加 1.0) 或保持 hardcode 但加注释 | XS |
| `trend_calendar.dart:234` | `padding: const EdgeInsets.all(2)` — 2px cell padding magic | 同上 | XS |
| `medication_list_view.dart:122` | `padding: const EdgeInsets.only(left: 4, top: spacingXs)` — left: 4 硬编 | 用 `AppTokens.spacingXxs` (4.0) | XS |
| `medication_calendar_page.dart:322` | `padding: const EdgeInsets.symmetric(vertical: 1)` — vertical: 1 magic | 同 cell gap 处理 | XS |
| `contacts_list_widget.dart:80` | `padding: EdgeInsets.all(4)` — 同 spacingXxs | 走 token | XS |
| `setup_step_medication.dart:122, 135, 136` | `SizedBox(width: 110, height: 44)` + `width: 18, height: 18` 硬编 — 110 / 44 都不是 spacing token 值 | `width: 110` 留 hardcode（窄按钮特殊尺寸），`18×18` 改 `AppTokens.iconSizeInline` (18) | XS |
| `medication_report_pdf_layout.dart:103, 264` | `pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4)` / `pw.BorderRadius.circular(6)` — PDF 不走 Flutter token 但 6 没注释 | 加 `pdfCellPaddingH/V` 常量或注释 why 6 是 PDF 最佳 | XS |
| `medication_report_pdf.dart:45` | `margin: const pw.EdgeInsets.all(32)` — PDF margin 32 | 同上 | XS |
| `setup_step_medication.dart:121-123` | `SizedBox(width: 110, height: 44)` — 110 / 44 是 **非 token 化** 的窄按钮尺寸 | 加 `AppTokens.buttonWidthNarrow` / `buttonHeightCompact` (44) 集中器 | XS |
| `reminders_hub_page.dart:319, 320, 457, 458` 等 5+ 处 | `Wrap(spacing: 8, runSpacing: 8, ...)` 散落（8 magic） | 用 `AppTokens.spacingXs` (8) | XS |
| `setup_step_medication.dart:256, 257` | `Wrap(spacing: 8, runSpacing: 8, ...)` 散落 | 同上 | XS |
| `medication/today_med_schedule.dart:83, 84` | 同款 | 同上 | XS |
| `medication/medication_row.dart:128, 129` | `SizedBox(width: 18, height: 18)` — trailing spinner 18×18 散落 2+ 处 | 抽 `AppTokens.iconSizeTrailing` (18) 或 `AppTokens.trailingSpinnerSize` | XS |
| `setup/widgets/medication_report_dialog.dart:174, 175` | `SizedBox(width: 20, height: 20)` — PDF loading spinner 20×20 | 走 `AppTokens.iconSize` (24) 或新 token | XS |
| `loading_text_button.dart:102, 103, 131, 132` | `SizedBox(width: 18, height: 18)` — loading button 内 spinner 18×18 重复 2 次 | 抽 token 同上 | XS |
| `trend/widgets/trend_assessment_chart.dart:257, 258` | `width: 10, height: 10` — legend dot 10×10 magic | 走 `AppTokens.legendDotSize` (新加 10) | XS |
| `medication/refill_manage_page.dart:326, 327` | `width: 36, height: 36` — `_StatusDot` 圆形 36×36 | 走 `AppTokens.avatarSizeSm` (新加 36) | XS |
| `setup/widgets/reminder_cards.dart:162, 163` | `width: 40, height: 40` — 4 个 ReminderCard 头部 40×40 icon container | 走 `AppTokens.avatarSizeMd` (新加 40) | XS |
| `assessment_history_list.dart:92, 93` | `width: 40, height: 40` — 评估分数 40×40 圆 | 同上 | XS |
| `medication/medication_calendar_page.dart:417, 418` | `width: 12, height: 12` — legend 12×12 dot | 走 `AppTokens.legendDotSize` (12) | XS |
| `mood_audio_section.dart:492, 493` | `width: 12, height: 12` — 同款 | 同上 | XS |
| `contact/contacts_list_widget.dart:78` | `height: 24` — deleting spinner 容器 24 | 走 `AppTokens.iconSize` (24) | XS |
| `notifications_status_card.dart:222` | `height: 16` — spinner 容器 16 | 加 `AppTokens.spinnerSizeInline` (16) | XS |
| `medication/today_med_schedule.dart:178, 184` | `padding: const EdgeInsets.only(right: 4)` — chip 内部 icon 间隔 4 magic | 走 `AppTokens.spacingXxs` (4) | XS |

#### 圆角（emil "走 token"）

| 位置 | 问题 | 修复建议 | 估计工时 |
|------|------|----------|----------|
| `medication_report_pdf_layout.dart:103` | `pw.BorderRadius.circular(6)` — PDF cell 圆角 6 magic | 注释或新加 `AppTokens.pdfRadiusCell` (6) | XS |

#### 阴影

全部 4 个 shadow 走 `shadowXxxOf(context)` 集中器 + theme-aware ✅ 无散落

### dark mode 适配（P0）

| 位置 | 问题 | 修复建议 | 估计工时 |
|------|------|----------|----------|
| `medication_report_dialog.dart:64` | `color: AppTokens.tintedPrimaryLight(context)` — 顶部说明条背景 ✅ dark mode 正确 | OK | - |
| `setup/setup_step_medication.dart:75` | `color: AppTokens.primaryLightColor(context)` — 顶部说明条 ✅ | OK | - |
| `reminders_hub_page.dart:53` | `color: AppTokens.primaryLightColor(context)` ✅ | OK | - |
| `medication/medication_calendar_page.dart:57` | `color: AppTokens.primaryLightColor(context)` ✅ | OK | - |
| `email_preview.dart:128` | `color: AppTokens.primaryLightColor(context)` ✅ | OK | - |
| `setup_widgets.dart:55` | `color: checked ? primaryLightColor : surfaceColor` ✅ | OK | - |
| `app_theme.dart:32` | `scaffoldBackgroundColor: isDark ? backgroundDark : background` — 用 const `AppTokens.backgroundDark` 替代 `M3 ColorScheme.surface` | OK（const 优化需要），可改 `cs.surface` | XS |

整体 dark mode 适配很彻底 ✅，但上面 `AppColors.success` / `AppColors.primary` 2 处还是 const，没走 `successColor(context)` / `primaryColor(context)`。

---

## 5. 视觉层级与可达性

### CTA 一眼识别

| 位置 | 问题 | 修复建议 | 估计工时 |
|------|------|----------|----------|
| `medication_calendar_page.dart:87-108` | 时间窗口选择 `SegmentedButton<int>` 3 段（7/30/90 天）走 `showSelectedIcon: false` ✅ 视觉统一，但**未选态 vs 选中态差异不够**：都是相同 `cs.onSurface` 文字 + 边框变粗。emil "重要选择应当明显" 弱 | 加 `selectedIcon` 提示 或在选中段加深背景 | XS |
| `trend_page.dart:243-261` | list ↔ calendar 切换 `SegmentedButton` + icon ✅ 但**没区分当前视图的视觉权重**（calendar 视图里"日历"按钮看上去跟 list 同等） | 选中段加深底色 + 加 icon 旋转 | XS |
| `setup_step_consent.dart:101-104` | "同意并继续" PrimaryButton 走 `PrimaryButton(isFullWidth: true)` ✅ 大按钮，**但 `onPressed: allChecked ? onContinue : null`** → disabled 态全靠 M3 默认。emil "disabled 应有可读提示" 弱 | disabled 时加 `Tooltip(message: l10n.setupConsentDisabledHint)` | XS |

### 触控目标 (≥ 44pt)

| 位置 | 问题 | 修复建议 | 估计工时 |
|------|------|----------|----------|
| `medication_calendar_page.dart:357-369` | `_CellBox` 实际尺寸 28-48pt（`(constraints.maxWidth - 4*4) / 5` 计算），**7 天视图 cell 仅 28pt** < 44pt minimum | 改为固定 36pt（间距同步缩），emil "精神心理患者手指控制能力下降" 必加 | XS |
| `trend/widgets/trend_heatmap_grid.dart:28` | `((constraints.maxWidth - 4 * 4) / 5).clamp(28.0, 48.0)` — 28pt < 44pt | clamp 改成 (44.0, 56.0) | XS |
| `assessment/widgets/assessment_history_list.dart:45` | `Divider(indent: 56)` — 56 是 leading icon 宽度对齐。但单行 ListTile 高度 56-72pt，**leading icon 24-32pt 触控区 OK** | OK | - |

### 文字对比度 (a11y)

整体依赖 M3 ColorScheme，**dark mode 全部走 cs.onSurface / cs.onSurfaceVariant 自动对比度** ✅。3 处疑点：

| 位置 | 问题 | 修复建议 | 估计工时 |
|------|------|----------|----------|
| `contact/contacts_list_widget.dart:69-72` | `Icon(Icons.person_outline, color: AppTokens.primaryColor(context))` — **primary color 在 light 浅色背景下对比度够**，但 lead 视觉（24pt 大 icon）走 primary | OK | - |
| `last_med_info.dart:42` | `color: AppTokens.textSecondaryColor(context)` (cs.onSurfaceVariant) — 14pt textStyleLabel + onSurfaceVariant 80% alpha，**对 background 0.9 contrast 在 light mode 边缘** | 改用 `textPrimaryColor` 或加 `copyWith(fontWeight: FontWeight.w500)` 加重 | XS |
| `setup/widgets/reminder_cards.dart:204-208` | `statusActive ? AppTokens.primaryColor(context) : AppTokens.textHintColor(context)` — textHintColor = onSurfaceVariant 60% alpha 在 chip 背景 tintedPrimarySoft 上**对比度不足** (3.5:1, AA fail for normal text) | 改用 `AppColors.fgOnSuccess` 风格（statusActive 也走 textPrimary）或加 copyWith fontWeight: w600 | XS |

### 焦点态 / 屏幕阅读器

| 位置 | 问题 | 修复建议 | 估计工时 |
|------|------|----------|----------|
| `assessment_page.dart:124-128` | `LinearProgressIndicator(value: _answered / scale.items.length)` — **没有 Semantics 标签**。屏幕阅读器读"线性进度指示器" | 外面包 `Semantics(value: '${_answered}/${scale.items.length}')` | XS |
| `medication_calendar_page.dart:351-378` | `_CellBox` 完全没有 `Semantics` 标签，**屏幕阅读器读不出"3/15 5/8 62%"** | 加 `AppSemantics.container(label: '...')` | S |
| `today_med_schedule.dart:149-209` | `_TimeChip` 不可 focus，**屏幕阅读器只读"08:00 药名"**，没有"已完成"信息 | 加 `Semantics(label: '${e.med.name} ${_formatTime(e.time)} ${e.done ? l10n.medsTodayDone : l10n.medsTodayPending}')` | XS |
| `trend/widgets/trend_heatmap_grid.dart:52-53` | `Tooltip(message: '${date.month}/${date.day} ${checked ? "✓" : ""}')` — **tooltip 走 hardcoded 字符串 "✓"** 不走 l10n | 改用 `Tooltip(message: l10n.trendHeatmapCell(date, checked))` | XS |

### icon-only button tooltip

21 处 IconButton 已走 `PressFeedbackIconButton` (强制 tooltip 参数) ✅ 0 漏

---

## 6. 高内聚低耦合 (可重构模块)

### 强候选（重复 ≥ 3 处）

| 重复模式 | 出现位置 | 建议集中器 | 工时 |
|---------|---------|------------|------|
| **"icon 容器 + 文字" 信息条** (`Container(padding, color: primaryLight/primaryLight, radius, Row(icon, text))`) | `medication_calendar_page.dart:54-72`、`medication_report_dialog.dart:61-73`、`setup_step_medication.dart:71-100`、`medication/temp_medication_dialog.dart`、`reminders_hub_page.dart:50-71` | `InfoBanner(icon, text, tone)` | M |
| **stat 数字卡** (`Column(text value headline w600 / text label caption w400)`) | `trend_summary.dart:36-66`、`refill_manage_page.dart:346-376` | `StatCard(label, value, valueColor)` | XS |
| **legacy snackbar 4 步**：`Center(Stack(IconButton + ColoredBox withValues 0.85))` 替代 `IconButton.close` | 6+ 处 `PressFeedbackIconButton(icon: close, onPressed: Navigator.pop)` | 已抽 `PressFeedbackIconButton` ✅ 但仍有几处用 `Stack(Color + CloseIcon)` 复合（如 medication_report_dialog） | OK |
| **空态 / 错误态 骨架选择不一致**：medication_calendar.dart:118 + 126 重复用 `LoadingSkeleton.fullScreen()` 2 次（meds 加载 + checkIns 加载） | 1 处 | OK | - |
| **"对话框 actions 2 个" 模式**：`TextButton(cancel) + PrimaryButton(save)` 重复 7+ 处 | `setup_step_welcome.dart:147`、`setup_step_medication.dart:116`、`setup_step_done.dart:85`、`choose_window_dialog.dart:80`、`refill_days_dialog.dart:56`、`edit_medication_dialog.dart:386`、`temp_medication_dialog.dart:124` | 抽 `DialogActionsRow(cancelLabel, onCancel, saveLabel, onSave, isLoading)` 集中器 | M |
| **ChoiceChip Wrap**（5+ 候选选项 Wrap） | `reminders_hub_page.dart:318` & `:456`、mood_tags 已有 ✅ | 已抽 mood_tags，但 reminders_hub 2 处没复用 | S |
| **legend 圆点 + 文字**（10+ 处） | `medication_calendar_page.dart:410-436`、`refill_manage_page.dart:319-344`、`trend_assessment_chart.dart:246-268` | `LegendDot(color, label)` 集中器 | XS |
| **swipe-to-dismiss 删除背景**（红底 + delete icon） | `vent_list_page.dart:174-193`、`contacts_list_widget.dart:51-64`、`medication_row.dart:163-176` | `SwipeDeleteBackground()` 集中器 | XS |

### 弱候选（重复 2 处）

| 重复模式 | 出现位置 | 工时 |
|---------|---------|------|
| "LoadingSpinner 嵌入 ListTile.trailing" | `contacts_list_widget.dart:75-83` + `notification_status_card.dart:219-224` | XS |
| TextButton.icon('查看全部') 通用尾部 action | `report_history_dialog` + `reminders_hub_page` | S |

---

## 7. 半成品 / WIP

### TODO 视觉项

| 位置 | 状态 | 建议 |
|------|------|------|
| `app_theme.dart:128` | `// TODO v0.25: 评估 buildTheme 接受 context (会变更 ThemeProvider 接口)` — **已挂 2 个 round** | 删除 TODO + 改走 `AppColors.fgDisabled(context)` 集中器（无需 buildTheme 接 context） |
| `notifications_status_card.dart:215` | `color: cs.onSurfaceVariant.withValues(alpha: 0.6)` — 走 inline 而不是 `AppColors.fgHintInput` | 改 token |
| `app_theme.dart:209` | 同上 | 改 token |
| `medication/medication_calendar_page.dart:358` 等 5+ 处 `EdgeInsets.all(1/2/4)` | 没注释 | 加 `// cell internal gap, see app_spacing` 注释或新 token |

### 占位符（gray box / 永久 spinner）

| 位置 | 状态 |
|------|------|
| `medication_calendar_page.dart:118, 126` | 双重 `LoadingSkeleton.fullScreen()` ✅ OK |
| `assessment_page.dart:67-81` | 路由错 id → loading + "返回上一页" — 实际是无限 spinner + pop，**有 silent bug 风险**（若 pop 失败会卡死）。建议加 200ms timeout |
| `medication_calendar_page.dart:357-369` | `_CellBox` 不可点击 → 灰色 cell 没 hover 反馈 |

### 视觉默认值（emil "design system discipline"）

| 位置 | 问题 | 修复建议 | 估计工时 |
|------|------|----------|----------|
| `assessment/assessment_widgets.dart:351` | `trendColor.withValues(alpha: 0.6)` — 走 `AppColors.tintChartLine` 集中器（已有 ✅） | OK（已修） | - |
| `medication/medication_calendar_page.dart:373-376` | `if (ratio == 0) return AppTokens.dividerColor(context)` — 漏服 = divider color = 灰。**emil "漏服应明显区别于背景" 弱**（divider color 在 tinted background 上几乎不可见） | 改用 `AppColors.errorColor(context)` 0.3 alpha 或新加 `adherenceMissed` token | XS |
| `assessment/assessment_widgets.dart:307, 343` | "中度 / 重度" severity 标签 `color: AppColors.warningStrong` 强橙 + `AppColors.error` 红色。emil "情绪危机应当用 deep but not alarming" 弱（error 红在 light mode 看着像删错） | 改用 `AppColors.errorContainer` / `onErrorContainer` (M3 muted error) | S |
| `refill_manage_page.dart:265-275` | status chip `tintedStatusSoft` + statusColor 双重同色 — **对比度取决于 status 本身**。emil "chip 应有 strong contrast" 弱 | 改用 `AppColors.tintedXxxSoft` + `fgXxxStrong` 配对 | XS |

---

## 8. 优先级 Top 10

| 序 | 问题 | 文件:行 | 难度 | 视角价值 | 备注 |
|----|------|---------|------|----------|------|
| 1 | 抽 `InfoBanner(icon, text, tone)` 集中器，替代 5+ 处 `Container(padding, color, Row(icon, text))` 同款 | `medication_calendar_page.dart:54` / `medication_report_dialog.dart:61` / `setup_step_medication.dart:71` / `reminders_hub_page.dart:50` / `medication/temp_medication_dialog` | S | 高 | 一次抽 5 处复用 = 30 行 → 5 行；emil "cohesion" 原则 |
| 2 | 抽 `DialogActionsRow(cancelLabel, onCancel, saveLabel, onSave, isLoading)` 集中器，替代 7+ 处 `TextButton(cancel) + PrimaryButton(save)` 同款 | setup 4 step + choose_window + refill_days + edit_medication + temp_medication | M | 高 | 1 行替代 5-7 行；7 处 × 5 行 = 35 行 → 7 行 |
| 3 | 修 2 处 `app_theme.dart:128/209` TODO 挂 2 round，替换 inline `withValues(alpha: 0.5/0.6)` 为 `AppColors.fgDisabled` / `fgHintInput` 集中器 | `app_theme.dart:128, 209` | XS | 中 | emil "decisions should be nameable" + 删遗留 TODO |
| 4 | 抽 `StatCard` public widget，trend_summary + refill_manage 复用 | `trend_summary.dart:36-66` + `refill_manage_page.dart:346-376` | XS | 中 | emil "DRY for taste"；2 处各 30 行 → 1 widget 15 行 |
| 5 | 修 dark mode 漏洞 2 处：`settings_page.dart:63, 92` 直接用 `AppColors.success` / `AppColors.primary` (const) → 改 `successColor(context)` / `primaryColor(context)` | `settings/settings_page.dart:63, 92` | XS | 高 | R49 P0-1 漏 2 处；dark mode 下 visual break |
| 6 | 抽 atomic size tokens 集中散落 18+ 处 magic：`AppTokens.iconSizeTrailing` (18) / `legendDotSize` (10/12) / `avatarSizeMd` (40) / `spinnerSizeInline` (16) / `pdfCellPadding` (6) | `medication_row.dart:128` / `setup_step_medication.dart:121` / `reminder_cards.dart:162` / `assessment_history_list.dart:92` / 等 12+ 处 | S | 中 | 18+ 处 grep-able 集中 |
| 7 | 修 `_CellBox` 不可访问：加 `AppSemantics.container(label: 'med.name, 3/15, 5/8 (62%)')` 走 `AppLocalizations` tooltip | `medication_calendar_page.dart:351-378` + `trend_heatmap_grid.dart:52` | S | 高 | emil "a11y 是 non-negotiable"；精神心理 App 屏幕阅读器用户不少 |
| 8 | 修 5+ 处 `Wrap(spacing: 8, runSpacing: 8, ...)` 散落 → 用 `AppTokens.spacingXs` (8) | `reminders_hub_page.dart:319` / `setup_step_medication.dart:256` / `today_med_schedule.dart:83` / `mood_tags.dart:42` / `edit_medication_dialog.dart:310` | XS | 中 | 一行 grep 解决 |
| 9 | 抽 `SwipeDeleteBackground()` 集中器，替代 3 处同款红底 + delete icon `Container` | `vent_list_page.dart:174` / `contacts_list_widget.dart:51` / `medication_row.dart:163` | XS | 中 | 3 处 → 1 widget + 3 calls |
| 10 | 修 `errorBuilder` 单一 home 按钮（不区分 setup 状态） | `app_routes.dart:128-170` | XS | 中 | emil "error 也要有明确出口"；先 setup 用户会卡死 |

**完整 Top 10 修复预计**: 8-10 小时（合 1-1.5 个工程师天）

---

## 附录 A: 已审文件清单（22 个）

| 类别 | 文件 |
|------|------|
| Theme | `app_tokens.dart` / `app_colors.dart` / `app_motion.dart` / `app_spacing.dart` / `app_typography.dart` / `app_theme.dart` |
| Routing | `app_router.dart` / `app_routes.dart` / `app_shell.dart` |
| Widgets | `page_scaffold.dart` / `app_snack_bar.dart` / `loading_skeleton.dart` / `loading_text_button.dart` / `feedback.dart` / `press_feedback.dart` / `press_feedback_icon_button.dart` / `check_in_button.dart` / `secondary_button.dart` / `primary_button.dart` / `app_list_tile.dart` / `app_semantics.dart` / `chip_badge.dart` / `empty_state.dart` / `error_state.dart` / `dimension_row.dart` / `last_med_info.dart` / `medication_report_dialog.dart` / `mood_quick_button.dart` / `section_header.dart` |
| Animations | `fade_in.dart` / `slide_up.dart` / `page_transition_switcher.dart` / `celebration_bounce.dart` |
| Pages (核心 6) | `home_page.dart` / `settings_page.dart` / `setup_page.dart` / `medication_calendar_page.dart` / `trend_page.dart` / `vent_list_page.dart` |
| Pages (其他 8) | `assessment_page.dart` / `mood_recorder_page.dart` / `medication_row.dart` / `medication_list_view.dart` / `today_med_schedule.dart` / `medication_empty_state.dart` / `refill_manage_page.dart` / `setup_step_consent.dart` / `setup_step_done.dart` / `setup_step_medication.dart` / `setup_widgets.dart` |
| Pages (设置 8 个 widget) | `notification_status_card.dart` / `reminder_cards.dart` / `reminders_hub_page.dart` / `data_management_section.dart` |
| Pages (其他 widget) | `app_semantics.dart` / `last_med_info.dart` / `medication_report_dialog.dart` / `contacts_list_widget.dart` / `choose_window_dialog.dart` / `trend_summary.dart` / `trend_heatmap_grid.dart` / `trend_assessment_chart.dart` |

## 附录 B: 散落 magic 编号总览

| 类别 | 散落处数 | 优先级 |
|------|----------|--------|
| 字号（fontSize: 数字） | 8+ 处（PDF 内） | 低（PDF 不强求统一） |
| 圆角（circular(N)） | 1 处（PDF 6） | 低 |
| 颜色（Color(0x)） | 0 处 ✅ | - |
| 间距（EdgeInsets.all(N)） | 5+ 处（1/2/4 magic） | 高 |
| Wrap spacing: 8 | 5+ 处 | 中 |
| SizedBox 18×18 / 20×20 / 36×36 / 40×40 | 10+ 处 | 中 |
| `AppColors.success` / `AppColors.primary` (const) | 2 处 | 高（dark mode bug） |
| `withValues(alpha: 0.X)` inline | 5+ 处（`withValues(alpha: 0.6)` 等） | 中 |
| TextStyle(fontSize, fontWeight) inline | 12+ 处 | 中 |

## 附录 C: 评估总结

**R66 emil 视角成熟度卡片**（每项 1-5 ⭐）：

| 维度 | 评分 | 评语 |
|------|------|------|
| 微交互（:active scale / haptic） | ⭐⭐⭐⭐⭐ | PressFeedback 集中器 30+ 处覆盖 |
| 动效 token 化 | ⭐⭐⭐⭐ | 4 curve + 5 duration token 集中度高，剩 2 处 audio tick magic |
| 设计 token 颜色 | ⭐⭐⭐⭐ | R49 修 35+ 处，剩 2 处 settings_page 漏；shadow 100% theme-aware |
| 设计 token 字号 | ⭐⭐⭐ | 14 token + 13 textStyle，剩 12+ 处 inline（特别 stat 数字） |
| 设计 token 间距 | ⭐⭐⭐⭐ | 10 spacing + 4 pageMargin，剩 5+ 处 small 1/2/4 magic + 5+ Wrap(spacing: 8) |
| 设计 token 圆角 | ⭐⭐⭐⭐⭐ | 6 radius token + 100% 走 token |
| 视觉层级 | ⭐⭐⭐⭐ | 主要 CTA 一眼识别，secondary 略弱 |
| 可达性 (a11y) | ⭐⭐⭐ | Semantics 5+ 处，cell 不读、progress bar 不读；Tooltip 12+ 处 |
| 触控目标 (44pt) | ⭐⭐⭐ | heatmap 28-48pt 下限 28pt < 44pt ⚠️ |
| 文字对比度 (WCAG) | ⭐⭐⭐⭐ | 走 M3 ColorScheme，1-2 处 hint 边缘 |
| 高内聚（重复模式） | ⭐⭐⭐ | 5+ 处 "InfoBanner" / 7+ 处 "DialogActionsRow" / 2 处 "StatCard" 待抽 |
| 半成品 / WIP | ⭐⭐⭐⭐ | 0 个 placeholder spinner 永久卡，1 个 TODO 挂 2 round |
| **总评** | **⭐⭐⭐⭐** | **emil 体系成熟度高，剩 6-8% 边缘"差一口气"问题，详见 Top 10** |
