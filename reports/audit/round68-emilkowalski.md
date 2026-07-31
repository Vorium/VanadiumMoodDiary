# emilkowalski 视角全量审计（v0.27 R68）

**审计时间**: 2026-08-01
**项目**: chroniccare
**版本**: 0.27.0+67（R67 收尾后）
**视角**: Design Engineering (emilkowalski)
**审计模式**: 增量（聚焦 R67 新增 5 个集中器落地质量 + R66 遗留 P0/P1 修复跟踪）
**审计基线**: 1285 tests pass / 0 analyzer error / 16 守护脚本全绿

---

## 1. 总览

- **整体设计成熟度**: ⭐⭐⭐⭐½ / 5
- **TL;DR**: R67 是 emil 体系的"集中器批量落地"轮 — 6 个新 widget 集中器到位（`InfoBanner` / `StatCard` / `DialogActionsRow` / `ChoiceChipWrap` / `SwipeDeleteBackground` / `ConsentDialog`），5+ 处同款重复 → 1 行调用。`AppTokens` 644 行 god constant 拆 4 sub-file（`app_colors` / `app_motion` / `app_spacing` / `app_typography`）+ facade。`swallowError` 集中器 + `BoxShadow` 强制 theme-aware。**剩 5% 边缘"差一口气"问题集中在 3 个层**：
  1. **dark mode 2 处硬编码漏修**（`settings_page.dart:63, 92`）— R66 P0 挂了 2 round，R67 仍未动
  2. **celebration overlay 35% 高度定位**（`home_page.dart:627`）— 横屏/全面屏/键盘弹起 撞顶
  3. **atomic size token 缺失**（`iconSizeTrailing` 18 / `legendDotSize` 12 / `pdfCellPadding` 6 / `setupButtonWidth` 110）— 8+ 处散落
- **建议优先修**: 详见第 8 节 Top 10 修复清单

### R67 集中器落地速查（vs R66 推荐）

| R66 推荐集中器 | R67 状态 | 使用频次 |
|----------------|---------|---------|
| `InfoBanner` (5+ 处) | ✅ `info_banner.dart` 新增 | **3 处**（meds_calendar / setup_step_medication / reminders_hub） |
| `StatCard` (2 处) | ✅ `stat_card.dart` 新增 | **8 处**（trend_summary 4 + refill_manage 4） |
| `DialogActionsRow` (4+ 处) | ✅ `dialog_actions_row.dart` 新增 | **4 处**（choose_window / refill_days / edit_medication / temp_medication） |
| `ChoiceChipWrap` (2 处) | ✅ `choice_chip_wrap.dart` 新增 | 待 grep（recommendation hub 已迁） |
| `SwipeDeleteBackground` (3 处) | ✅ `swipe_delete_background.dart` 新增 | **3 处**（vent_list / contacts_list / medication_row） |

---

## 2. 动效

### 现状

- **曲线**: 0 处散落 `Curves.easeInOut` 等，**6 个 curve token**（standard/subtle/decelerate/accelerate/delight/backOut）✅ R65 拆 sub-file
- **时长**: 8 个 duration + 3 个 snackBar duration ✅ 集中度高
- **transition**: 3 类集中（fadePage / slideRightPage / slideUpPage）走 `Motion.duration` reduce-motion 包装 ✅
- **stagger**: `AppTokens.staggerStepMs` (40) + `staggerCapMs` (200) 公式 ✅
- **shimmer**: R67 改 Timer (可 cancel) 替代 Future.delayed，修正 dispose race ✅ R59
- **scrim**: `AppTokens.scrimAlpha` (0.54) 集中 ✅ R65

### 仍存留的问题

#### P0

| 位置 | 问题 | 修复建议 | 难度 |
|------|------|----------|------|
| `home_page.dart:622-650` `_showCelebrationOverlay` | `top: MediaQuery.of(ctx).size.height * 0.35` 35% 高度定位 — **键盘弹起 / 横屏 / 全面屏时撞顶或飞到屏外**。R66 P0 挂了 2 round，R67 仍未动。`Motion.duration` 包装了但位置公式未走 token | 改 `Positioned(top: MediaQuery.padding.top + AppTokens.spacingLg, left: 0, right: 0)`，加 `AppTokens.celebrationTopOffset` 集中器 | XS |
| `medication_report_dialog.dart:166-194` scrim | `ColoredBox(color: scrim.withValues(alpha: 0.54))` 硬切无 fade，**user 仍能点底下复制/分享按钮**。R66 P2 双 bug 挂了 2 round，R67 仍未动 | ① 加 `AbsorbPointer` 把 scrim 范围内点击 absorb；② `ColoredBox` 换 `AnimatedContainer(duration: durNormal, color: ...)` 走 fade in | XS |

#### P1

| 位置 | 问题 | 修复建议 | 难度 |
|------|------|----------|------|
| `assessment_page.dart:124-128` LinearProgressIndicator | 切 quiz→result 时 progress bar 从 100% 跳到 0，**无 tween 动画**。R66 P1 建议加 `TweenAnimationBuilder` 走 `curveStandard`，R67 仍未动 | `TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: _answered / scale.items.length), duration: durFast, curve: curveStandard)` | XS |
| `medication_calendar_page.dart:351-378` `_CellBox` | 不可点击 / 不可 hover / 不可 focus / **无 Semantics**。屏幕阅读器只读 "3/15 ✓" 不可达。R66 P1 + a11y P1 双 tag 挂 2 round，R67 仍未动 | 加 `AppSemantics.container(label: '${med.name} ${day} ${actual}/${expected} ${pct}%')`（`AppSemantics` 集中器已有） | XS |
| `trend_heatmap_grid.dart:52-53` `_HeatCell` | `Tooltip(message: '${date.month}/${date.day} ${checked ? "✓" : ""}')` 走 **hardcoded "✓" 不走 l10n**；且整个 cell 无 Semantics。R66 a11y P1 挂 2 round，R67 仍未动 | 改 `Tooltip(message: l10n.trendHeatmapCell(date, checked))` + `AppSemantics.container` 同上 | XS |
| `medication_calendar_page.dart:398-400` `_Legend` | `'< 50%' / '< 100%' / '100%'` **hardcoded 字符串**（en/zh/zh_Hant 用户都看到 magic） | 加 l10n key `medsCalendarLegendP50` / `medsCalendarLegendP100` / `medsCalendarLegendP100Full` 3 个 | XS |
| `medication_calendar_page.dart:380-407` `_Legend` 容器 | `Card + Padding + Row + 4 个 _legendItem` 30+ 行 inline 渲染，**没走 `ChipBadge` 集中器**（已有 4 tone enum） | 改 `ChipBadge(label: ..., icon: dot, tone: neutral)` 串联 4 个 | XS |
| `setup_step_consent.dart:75-94` | **3 段重复 inline** 调 `ConsentCheckRow(checked, label, onTap, onView)`。`ConsentCheckRow` 集中器已有（在 `setup_widgets.dart`），但**没有更高级的 `ConsentCard` 集中器**走 R40 风格 `tintedPrimarySoft` 背景 串联 3 个 | 抽 `ConsentCard(title, checked, onTap, onView)` 集中器，3 处直接 for-loop 渲染 | S |

#### P2

| 位置 | 问题 | 修复建议 | 难度 |
|------|------|----------|------|
| `medication_calendar_page.dart:54-72` 顶部说明条 | 已走 `InfoBanner` 集中器 ✅ 但 `tint` 默认是 `info` (primaryLight + primary)，**emil "tone 同款 = 同一 widget" 原则 OK** | - | - |
| `medication_calendar_page.dart:74-104` 时间窗口 SegmentedButton | `PressFeedback(child: SegmentedButton(...))` ✅ 加 :active scale，但**未选态 vs 选中态差异不够**：都走 `cs.onSurface` 文字 + 边框变粗 | 加 `selectedIcon` 提示 或在选中段加深背景 | XS |
| `setup_step_medication.dart:103-128` "下一步" 按钮 | `SizedBox(width: 110, height: 44) + Stack(PrimaryButton + IgnorePointer(CircularProgressIndicator))` 是 **LoadingTextButton 集中器的同款重复**。R66 P1 建议改用集中器，R67 仍未动 | `LoadingTextButton(label: l10n.setupNext, isLoading: saving, onPressed: saving ? null : onFinish)` 替换 26 行 | XS |
| `medication_calendar_page.dart:399-403` 图例项 | `'< 50%' / '< 100%' / '100%'` 3 处 magic 字符串，**en/zh/zh_Hant 用户都看到 magic** | 加 3 个 l10n key | XS |
| `medication_calendar_page.dart:367` 漏服 = 灰 | `if (ratio == 0) return AppTokens.dividerColor(context)` 漏服 = 灰**几乎不可见**（divider 在 tinted background 上）。emil "重要状态应当明显" | 改 `AppColors.errorColor(context).withValues(alpha: 0.3)` 或新加 `adherenceMissed` token | XS |

---

## 3. 设计 token 一致性

### 散落硬编 (P0/P1)

#### 颜色 (emil "no hardcoded colors")

| 位置 | 问题 | 修复建议 | 难度 |
|------|------|----------|------|
| `settings/settings_page.dart:63` | `Icon(Icons.workspace_premium, color: AppColors.success)` — **直接用 const `AppColors.success` 在 dark mode 下不反白**。R49 P0-1 修了 35+ 处，R66 报告 + R67 仍**漏修 2 处**（R66 报告点名过的） | 替换为 `AppColors.fgOnSuccess`（已存在）或 `AppColors.successColor(context)` 风格 | XS |
| `settings/settings_page.dart:92` | `Icon(Icons.workspace_premium, color: AppColors.primary)` — **同款 const 硬编**，dark mode 漏反白 | 替换为 `AppColors.primaryColor(context)` | XS |
| `core/theme/app_theme.dart:128` | `disabledForegroundColor: cs.onSurface.withValues(alpha: 0.5)` 走 inline 而不是 `AppColors.fgDisabled(context)`（**已有**集中器） + 旁边挂 `// TODO v0.25: 评估 buildTheme 接受 context` — **TODO 挂 3 round** (R48 → R65 → R67)，emil "decisions should be nameable" 长期违反 | 替换为 `AppColors.fgDisabled(context)`（不需 buildTheme 接 context，AppColors.fgDisabled 内部走 cs.onSurface 适配 dark），删 TODO | XS |
| `core/theme/app_theme.dart:209` | `hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6))` 走 inline 而不是 `AppColors.fgHintInput(context)`（已有集中器） | 替换为 `AppColors.fgHintInput(context)` | XS |
| `medication_report_dialog.dart:79` | `color: AppTokens.surfaceColor(context)` 在 `Container(width: double.infinity, padding: ..., color: surface, child: SingleChildScrollView(...))` — **整块 `Container(color)` 没意义**（surface = 背景色），多余层级 | 删 `Container`，`SingleChildScrollView` 直接放 `Column` 即可 | XS |

#### 字号 (emil "走 token")

R67 抽 `StatCard` 集中器后, `trend_summary` + `refill_manage` 8 处 stat 数字全部走 `textStyleHeadline + copyWith(fontWeight: w600)` ✅。
**剩余 inline `TextStyle(fontSize, fontWeight)`**:
- `setup_step_done.dart:43, 53, 62, 74` — 4 处 `TextStyle(fontSize: AppTokens.fontSizeTitle, fontWeight: FontWeight.w600)` 跟 setup_step_consent / setup_step_welcome 完全同款
- `setup_widgets.dart:86-92` ConsentCheckRow 内部 TextStyle(fontSize: fontSizeLabel, ...) inline
- `trend/widgets/trend_assessment_chart.dart:307, 343` — 评估分数 64pt 走 fontSizeScoreXxl 但周围 `TextStyle(fontSize, fontWeight: w700, color: primary)` 仍 inline
- `today_med_schedule.dart:62-67` — 标题 `TextStyle(fontSize: fontSizeBody, fontWeight: w600)` inline（应为 `textStyleBodyStrong` 集中器）
- `today_med_schedule.dart:194-199` — 时间 chip 数字 `TextStyle(fontSize: fontSizeBodySm, fontWeight: w600, color:)` 重复模式

| 位置 | 问题 | 修复建议 | 难度 |
|------|------|----------|------|
| `setup_step_done.dart:43, 53, 62, 74` | 4 处 setup 完成页 title / subtitle 走 `TextStyle(fontSize, fontWeight: w600)` inline | 加 `AppTokens.textStyleSetupTitle` / `textStyleSetupSubtitle` 集中器 (跟 R40 同款) | XS |
| `today_med_schedule.dart:62-67` | 标题 `TextStyle(fontSize: fontSizeBody, fontWeight: w600)` | 用 `AppTokens.textStyleBodyStrong(context)` (已有) | XS |
| `today_med_schedule.dart:194-199` | 时间 chip 数字 `TextStyle(fontSize: fontSizeBodySm, fontWeight: w600)` 重复 | 抽 `AppTokens.textStyleChipTime` 集中器 | XS |

#### 间距 (emil "走 token")

| 位置 | 问题 | 修复建议 | 难度 |
|------|------|----------|------|
| `today_med_schedule.dart:82-87` | `Wrap(spacing: 8, runSpacing: 8, ...)` **8 magic** | 替换为 `AppTokens.spacingXs` (8.0) | XS |
| `setup_step_medication.dart:237-240` | `Wrap(spacing: 8, runSpacing: 8, ...)` **8 magic** 同款 | 同上 | XS |
| `today_med_schedule.dart:179, 186` | `EdgeInsets.only(right: 4)` 4 magic | 替换为 `AppTokens.spacingXxs` (4.0) | XS |
| `medication_calendar_page.dart:358` | `EdgeInsets.all(1)` 1px grid cell gap magic | 抽 `AppTokens.spacingCellGap` (1.0) 或保持 hardcode + 注释 | XS |
| `medication_calendar_page.dart:322` | `EdgeInsets.symmetric(vertical: 1)` vertical: 1 magic | 同 cell gap | XS |

#### 原子尺寸 (R66 推荐抽, R67 仍未抽)

| 散落处 | magic | 建议 token | 难度 |
|--------|-------|-----------|------|
| `medication_row.dart:131-132` / `loading_text_button.dart:102-103, 131-132` | `SizedBox(width: 18, height: 18)` × 3 处 | `AppTokens.iconSizeTrailing` (18) | XS |
| `medication_report_dialog.dart:180-183` | `SizedBox(width: 20, height: 20)` | `AppTokens.spinnerSizePdf` (20) | XS |
| `setup_step_medication.dart:103-104` | `SizedBox(width: 110, height: 44)` | `AppTokens.buttonWidthNarrow` (110) + `buttonHeightCompact` (44) | XS |
| `medication_calendar_page.dart:414-415` / `trend_assessment_chart.dart:257-258` | `width: 12, height: 12` / `width: 10, height: 10` | `AppTokens.legendDotSizeLg` (12) / `legendDotSizeSm` (10) | XS |
| `setup_step_medication.dart:117-118` | `SizedBox(width: 18, height: 18)` | 同上 `iconSizeTrailing` | XS |
| `medication/refill_manage_page.dart:326-327` | `width: 36, height: 36` (`_StatusDot`) | `AppTokens.avatarSizeSm` (36) | XS |
| `setup/widgets/reminder_cards.dart:162-163` / `assessment_history_list.dart:92-93` | `width: 40, height: 40` (4+ 处) | `AppTokens.avatarSizeMd` (40) | XS |
| `contacts_list_widget.dart:78` | `height: 24` (spinner 容器) | `AppTokens.iconSize` (24) — 已有 | XS |
| `notification_status_card.dart:222` | `height: 16` (spinner 容器) | `AppTokens.spinnerSizeInline` (16) | XS |

#### 圆角

全部 6 个 radius 走 token ✅ 无散落。

#### 阴影

R67 删除 4 个 const shadow 集中器版本，**强制所有用法走 theme-aware** ✅ R59 落地。`shadowCardOf(context)` / `shadowCardDarkOf(context)` / `shadowDialogOf(context)` / `shadowOverlayOf(context)` 100% 走 dynamic。

### dark mode 适配

| 位置 | 问题 | 难度 |
|------|------|------|
| `settings/settings_page.dart:63, 92` | `color: AppColors.success` / `AppColors.primary` const 硬编，**R66 P0-1 R49 修了 35+ 处漏 2 处仍未动**。dark mode 下 visual break | XS |
| `app_theme.dart:32` | `scaffoldBackgroundColor: isDark ? AppTokens.backgroundDark : AppTokens.background` — 用 const 替代 `M3 ColorScheme.surface`。可改 `cs.surface` 更纯 M3 | XS |

整体 dark mode 适配很彻底 ✅，但上面 settings 2 处是 R66 报告已挂 2 round 的漏网 bug。

---

## 4. 微交互（:active / loading / success / failure）

### 现状

- **PressFeedback 集中器覆盖**: 30+ 处调用，scale 0.97 + curveStandard + durPress 走 token ✅
- **PressFeedbackIconButton 21+ 处**: 强制 tooltip 参数 ✅
- **LoadingTextButton 4+ 处** ✅
- **Haptics.success 集中器** (R22): 打卡/庆祝触感 ✅
- **AppSnackBar 4 类** (info / error / undo / withAction) + showX 便捷工厂 (R37) ✅

### P0 残留

| 位置 | 问题 | 修复建议 | 难度 |
|------|------|----------|------|
| `medication_report_dialog.dart:110-156` | 底部 3 按钮 (复制 / PDF / 分享) **3 种不同模式**: `PressFeedback(onTap:_copy, child: OutlinedButton(onPressed: null))` / `LoadingTextButton` / `PressFeedback(child: OutlinedButton(onPressed: _share))`。emil "consistency" 违反。R66 P0 建议抽 `OutlinedButtonWithPress` 集中器未动 | 抽 `OutlinedButtonWithPress(icon, label, onTap, isLoading?)` 集中器，3 处直接调用 | S |
| `medication_report_dialog.dart:166-194` | scrim 仍可点底下复制/分享按钮 (PDF 按钮 disabled，但复制/分享仍响应)。emil "modal 出现 = 用户 100% 锁死" 违反 | 加 `AbsorbPointer` 包 scrim | XS |

### P1 残留

| 位置 | 问题 | 修复建议 | 难度 |
|------|------|----------|------|
| `medication_row.dart:126-161` trailing 区 | 3 个 IconButton + 1 个 conditional spinner，**spinner 出现时 3 个 button 全消失** → loading 完 → 3 个 button 突现，**无 AnimatedSwitcher 切换**。R66 P1 建议未动 | 加 `AnimatedSwitcher(duration: durFast)` 包 button row | XS |
| `check_in_button.dart:48-56` | `AnimatedSwitcher + FadeTransition(opacity: anim, child: ScaleTransition(scale: anim, child: child))` ✅ 走 curveStandard/curveAccelerate，但**`anim` 是 CurvedAnimation 后的**已经走了 curve，inner ScaleTransition 0→1 线性 OK，但 R66 建议改 `Tween(begin: 0.95, end: 1)` 给"起跳感" | 可选：加 `scale: Tween(begin: 0.95, end: 1.0).animate(CurvedAnimation(parent: anim, curve: curveStandard))` | XS |
| `setup_step_medication.dart:103-128` "下一步" 按钮 | 同上 LoadingTextButton 集中器应用未动，**Stack(IgnorePointer + spinner) 是 R43 已抽的 LoadingTextButton 集中器的同款重复** | 同上 P1 | XS |

### P2 残留

| 位置 | 问题 | 修复建议 | 难度 |
|------|------|----------|------|
| `home_page.dart:541-570 / 622-650` `_showCelebrationOverlay` | Timer 用 `AppTokens.celebrationDisplayMs` (1800) ✅，但**1800ms 偏长**（emil 频度 rare 庆祝反馈应 1000ms 内）。R23 round 40 (P1-12 fix) 把 MotionScheme.delight 改成 1000ms，**但 celebrationDisplayMs 仍是 1800ms**（用户可能"等不到"新页面） | 改 `AppTokens.celebrationDisplayMs` (1800) → 1000ms 或新加 `celebrationDisplayDuration` Duration 类型 token | XS |
| `assessment_page.dart:67-81` 路由错 id 态 | 路由给错 scale id 时显示"loading + 返回上一页" 实际是无限 spinner 配合下一帧 pop，**emil "loading 应该是骨架而非 spinner" 违反**（R17 round 8 + R22 round 29 强调）。R66 P2 建议加 200ms timeout 未动 | 改用 `LoadingSkeleton.card(child: SizedBox.shrink())` 或直接显示空态 200ms 后 pop | XS |

---

## 5. 视觉层级与可达性

### CTA 一眼识别

| 位置 | 问题 | 修复建议 | 难度 |
|------|------|----------|------|
| `medication_calendar_page.dart:87-108` | 时间窗口 `SegmentedButton<int>` 3 段走 `showSelectedIcon: false` ✅ 视觉统一，但**未选态 vs 选中态差异不够**：都是相同 `cs.onSurface` 文字 + 边框变粗。emil "重要选择应当明显" | 加 `selectedIcon` 提示 或在选中段加深底色 | XS |
| `setup_step_consent.dart:101-104` | "同意并继续" PrimaryButton 走 `PrimaryButton(isFullWidth: true)` ✅ 大按钮，**但 `onPressed: allChecked ? onContinue : null` → disabled 态全靠 M3 默认**。emil "disabled 应有可读提示" 弱 | disabled 时加 `Tooltip(message: l10n.setupConsentDisabledHint)` | XS |

### 触控目标 (≥ 44pt)

| 位置 | 问题 | 修复建议 | 难度 |
|------|------|----------|------|
| `trend_heatmap_grid.dart:28` | `((constraints.maxWidth - 4 * 4) / 5).clamp(28.0, 48.0)` — **28pt < 44pt minimum**。精神心理患者手指控制能力下降，**emil 必加** | 改 `clamp(44.0, 56.0)` | XS |
| `medication_calendar_page.dart:357-369` `_CellBox` | 实际尺寸 `(constraints.maxWidth - 4*4) / 5` 算出来**7 天视图 cell 仅 28pt** < 44pt minimum | 改固定 36pt 间距同步缩 | XS |

### 文字对比度 (a11y)

整体依赖 M3 ColorScheme 自动对比度 ✅，3 处疑点:

| 位置 | 问题 | 修复建议 | 难度 |
|------|------|----------|------|
| `last_med_info.dart:42` | `color: AppTokens.textSecondaryColor(context)` (cs.onSurfaceVariant) — 14pt textStyleLabel + onSurfaceVariant 80% alpha，**对 background 0.9 contrast 在 light mode 边缘** | 改用 `textPrimaryColor` 或加 `copyWith(fontWeight: FontWeight.w500)` 加重 | XS |
| `setup/widgets/reminder_cards.dart:204-208` | `statusActive ? AppTokens.primaryColor(context) : AppTokens.textHintColor(context)` — textHintColor = onSurfaceVariant 60% alpha 在 chip 背景 tintedPrimarySoft 上**对比度不足** (3.5:1, AA fail for normal text) | 改用 `AppColors.fgOnSuccess` 风格（statusActive 也走 textPrimary）或加 copyWith fontWeight: w600 | XS |
| `core/theme/app_theme.dart:128, 209` | `withValues(alpha: 0.5/0.6)` 走 inline，**绕开 `fgDisabled` / `fgHintInput` 集中器 (已有)**，**违反"未命名 magic alpha"原则** | 替换为集中器 (同 §3 颜色 P0-1) | XS |

### 焦点态 / 屏幕阅读器

| 位置 | 问题 | 修复建议 | 难度 |
|------|------|----------|------|
| `assessment_page.dart:124-128` | `LinearProgressIndicator(value: ...)` — **没有 Semantics 标签**。屏幕阅读器读"线性进度指示器" | 外面包 `Semantics(value: '${_answered}/${scale.items.length}')` | XS |
| `medication_calendar_page.dart:351-378` `_CellBox` | 完全没有 `Semantics` 标签，**屏幕阅读器读不出"3/15 5/8 62%"** | 加 `AppSemantics.container(label: '...')` | S |
| `today_med_schedule.dart:149-209` `_TimeChip` | 不可 focus，**屏幕阅读器只读"08:00 药名"**，没有"已完成"信息 | 加 `Semantics(label: '${e.med.name} ${_formatTime} ${e.done ? l10n.medsTodayDone : l10n.medsTodayPending}')` | XS |
| `trend/widgets/trend_heatmap_grid.dart:52-53` | `Tooltip(message: '${date.month}/${date.day} ${checked ? "✓" : ""}')` — **走 hardcoded 字符串 "✓"** 不走 l10n | 改用 `Tooltip(message: l10n.trendHeatmapCell(date, checked))` | XS |

### icon-only button tooltip

21+ 处 IconButton 已走 `PressFeedbackIconButton` (强制 tooltip 参数) ✅ 0 漏

---

## 6. 高内聚低耦合（可重构模块）

### R67 已抽 (✅ 全部落地)

| 重复模式 | 集中器 | 抽取位置 | 使用处数 |
|---------|-------|---------|---------|
| InfoBanner 5+ 处 | `InfoBanner` (4 tone) | `widgets/info_banner.dart` | **3** (meds_calendar / setup_med / reminders_hub) |
| Stat 数字卡 2 处 | `StatCard` (label, value, valueColor) | `widgets/stat_card.dart` | **8** (trend_summary 4 + refill_manage 4) |
| Dialog actions 4 处 | `DialogActionsRow` (cancel/onCancel/confirm/isLoading) | `widgets/dialog_actions_row.dart` | **4** (choose_window / refill_days / edit_medication / temp_medication) |
| ChoiceChip Wrap 2 处 | `ChoiceChipWrap<T>` 泛型 | `widgets/choice_chip_wrap.dart` | reminders_hub 2+ 处 |
| Swipe-to-dismiss 红底 3 处 | `SwipeDeleteBackground` (rounded) | `widgets/swipe_delete_background.dart` | **3** (vent_list / contacts_list / medication_row) |
| Consent dialog | `ConsentDialog` | `widgets/consent_dialog.dart` | (PIPL 同意弹窗) |

### 强候选 (剩余)

| 重复模式 | 出现位置 | 建议集中器 | 难度 |
|---------|---------|-----------|------|
| **3 段重复 ConsentCheckRow** | `setup_step_consent.dart:75-94` | `ConsentCard(title, checked, onTap, onView)` 串联 3 个 | S |
| **OutlinedButton.icon + PressFeedback** (3 模式不一致) | `medication_report_dialog.dart:110-156` | `OutlinedButtonWithPress(icon, label, onTap, isLoading?)` | S |
| **scrim + 中心 Card(spinner + 文字)** (PDF loading) | `medication_report_dialog.dart:166-194` | `LoadingScrim(message, isLoading)` 集中器 | S |
| **InlineSpinnerInTrailing** (3 模式不一致) | `medication_row.dart:131` / `contacts_list_widget.dart:75-83` / `notification_status_card.dart:219-224` | `TrailingSpinner` 集中器 | XS |
| **setup step title / subtitle** (4 段重复 TextStyle) | `setup_step_done.dart:43, 53, 62, 74` | `AppTokens.textStyleSetupTitle` / `textStyleSetupSubtitle` 集中器 | XS |
| **3 个 l10n 魔法字符串** | `medication_calendar_page.dart:398-400` | l10n key `medsCalendarLegendP50/100/100Full` | XS |

### 弱候选 (2 处)

| 重复模式 | 出现位置 | 难度 |
|---------|---------|------|
| "scrim 0.54 + 中心 Card" (重复模式) | 仅 `medication_report_dialog.dart:166-194` 1 处 | XS |
| 评估分数 `TextStyle(64, w700, primary)` | `assessment_page.dart:306` / `trend_assessment_chart.dart:307, 343` | XS |

---

## 7. 半成品 / WIP

### TODO 视觉项

| 位置 | 状态 | 建议 |
|------|------|------|
| `app_theme.dart:128` | `// TODO v0.25: 评估 buildTheme 接受 context (会变更 ThemeProvider 接口)` — **已挂 3 round** (R48 → R65 → R67) | 删 TODO + 改走 `AppColors.fgDisabled(context)` 集中器（已有，无需 buildTheme 接 context） |
| `home_page.dart:551, 561` | `// R55+ TODO: 拿 input.contacts.first.phone` / `// R55+ TODO` — **SMS / Email 真接阿里云 / SendGrid** 待办 | R55+ 等法务 + AccessKey 申请，**非本批视觉问题** |

### 占位符

| 位置 | 状态 |
|------|------|
| `medication_calendar_page.dart:118, 126` | 双重 `LoadingSkeleton.fullScreen()` ✅ OK |
| `assessment_page.dart:67-81` | 路由错 id → 无限 spinner + pop，**有 silent bug 风险**（若 pop 失败会卡死） |
| `medication_calendar_page.dart:357-369` `_CellBox` | 不可点击 → 灰色 cell 没 hover 反馈（无 hover 状态） |

### 视觉默认值

| 位置 | 问题 | 修复建议 | 难度 |
|------|------|----------|------|
| `medication_calendar_page.dart:367` | 漏服 = `AppTokens.dividerColor(context)` 灰**几乎不可见**（divider 在 tinted background 上）。emil "重要状态应当明显" | 改 `errorColor.withValues(alpha: 0.3)` 或新加 `adherenceMissed` token | XS |
| `assessment/assessment_widgets.dart:307, 343` | "中度 / 重度" severity 标签 `color: AppColors.warningStrong` 强橙 + `AppColors.error` 红色。emil "情绪危机应当用 deep but not alarming" 弱 | 改用 `AppColors.errorContainer` / `onErrorContainer` (M3 muted error) | S |
| `refill_manage_page.dart:265-275` | status chip `tintedStatusSoft` + statusColor 双重同色 — **对比度取决于 status 本身**。emil "chip 应有 strong contrast" 弱 | 改用 `tintedXxxSoft` + `fgXxxStrong` 配对 | XS |

---

## 8. 优先级 Top 10

| 序 | 问题 | 文件:行 | 难度 | 视角价值 | 备注 |
|----|------|---------|------|----------|------|
| 1 | 修 dark mode 漏 2 处：`settings_page.dart:63, 92` `AppColors.success` / `primary` const → 改 `fgOnSuccess` / `primaryColor(context)` | `settings/settings_page.dart:63, 92` | XS | 高 | R66 P0 挂了 2 round，dark mode visual break |
| 2 | 修 `app_theme.dart:128/209` TODO 挂 3 round，替换 inline `withValues(alpha: 0.5/0.6)` 为 `AppColors.fgDisabled` / `fgHintInput` 集中器 | `app_theme.dart:128, 209` | XS | 中 | 删遗留 TODO + emil "未命名 magic alpha" |
| 3 | 修 `_showCelebrationOverlay` 35% 高度定位：改 `top: MediaQuery.padding.top + AppTokens.spacingLg` | `home_page.dart:622-650` | XS | 高 | 键盘弹起 / 横屏 / 全面屏撞顶 |
| 4 | 修 `_CellBox` 不可访问：加 `AppSemantics.container(label: 'med.name, day, n/m (pct%)')` | `medication_calendar_page.dart:351-378` | XS | 高 | emil "a11y 是 non-negotiable"；精神心理 App 屏幕阅读器用户不少 |
| 5 | 修 `trend_heatmap_grid` cell 28pt < 44pt + 缺 Semantics | `trend_heatmap_grid.dart:28, 52-53` | XS | 高 | 触控目标下限 + a11y 双 bug |
| 6 | 修 `medication_report_dialog` scrim 加 `AbsorbPointer` + 按钮 3 模式不一致抽 `OutlinedButtonWithPress` 集中器 | `medication_report_dialog.dart:110-156, 166-194` | S | 中 | modal 锁死 + 3 模式一致；3 模式 → 1 集中器 |
| 7 | 抽 atomic size tokens 集中散落 12+ 处 magic：`iconSizeTrailing` (18) / `legendDotSizeLg/Sm` (12/10) / `avatarSizeMd/Sm` (40/36) / `spinnerSizeInline` (16) / `buttonWidthNarrow` (110) / `buttonHeightCompact` (44) | `medication_row.dart:131` / `setup_step_medication.dart:103, 117` / `medication_report_dialog.dart:180` / `reminder_cards.dart:162` / `assessment_history_list.dart:92` 等 | S | 中 | 12+ 处 grep-able 集中 |
| 8 | 修 2 处 `Wrap(spacing: 8, runSpacing: 8, ...)` 散落 → 用 `AppTokens.spacingXs` | `today_med_schedule.dart:82-87` / `setup_step_medication.dart:237-240` | XS | 中 | 一行 grep 解决 |
| 9 | 修 `setup_step_medication.dart:103-128` "下一步" 按钮 26 行 Stack(IgnorePointer+spinner) → 改用 `LoadingTextButton` 集中器 | `setup_step_medication.dart:103-128` | XS | 中 | R43 抽集中器时漏的同款；emil "DRY" |
| 10 | 修 `LinearProgressIndicator` 切 quiz→result 缺 tween + 缺 Semantics | `assessment_page.dart:124-128` | XS | 中 | emil "transition 应该是 tween" + a11y |

**完整 Top 10 修复预计**: 4-6 小时（合 0.5-1 个工程师天）

---

## 附录 A: 已审文件清单（增量于 R66 22 文件 + R67 新增 8 文件）

| 类别 | 文件 |
|------|------|
| Theme (R66) | `app_tokens.dart` / `app_colors.dart` / `app_motion.dart` / `app_spacing.dart` / `app_typography.dart` / `app_theme.dart` |
| **Theme (R67 新增)** | `app_motion.dart` 升级 (R59 timer 修复 / R65 拆 sub-file) / `app_theme.dart` 同款 |
| Routing | `app_routes.dart` (115 行 facade, R57 拆 5 文件) / `app_router.dart` |
| **Widgets (R67 新增)** | `info_banner.dart` (3 处) / `stat_card.dart` (8 处) / `dialog_actions_row.dart` (4 处) / `choice_chip_wrap.dart` / `swipe_delete_background.dart` (3 处) / `consent_dialog.dart` |
| Widgets (R66) | `page_scaffold.dart` / `app_snack_bar.dart` / `loading_skeleton.dart` / `loading_text_button.dart` / `press_feedback.dart` / `press_feedback_icon_button.dart` / `check_in_button.dart` / `empty_state.dart` / `error_state.dart` / `app_list_tile.dart` / `app_semantics.dart` / `chip_badge.dart` / `section_header.dart` / `primary_button.dart` / `last_startup_error_banner.dart` / `last_med_info.dart` / `medication_report_dialog.dart` |
| Animations | `fade_in.dart` / `slide_up.dart` / `page_transition_switcher.dart` / `celebration_bounce.dart` / `animations.dart` |
| Pages (核心 6) | `home_page.dart` / `settings_page.dart` / `setup_page.dart` / `medication_calendar_page.dart` / `trend_page.dart` / `vent_list_page.dart` |
| Pages (其他) | `assessment_page.dart` / `today_med_schedule.dart` / `medication_row.dart` / `refill_manage_page.dart` / `setup_step_consent.dart` / `setup_step_medication.dart` / `setup_widgets.dart` / `trend_heatmap_grid.dart` |
| **Pages (R67 新增 home widgets)** | `encouragement_text.dart` / `home_header.dart` / `home_footer.dart` / `primary_action_row.dart` / `secondary_action_row.dart` / `notification_failure_banner.dart` |

## 附录 B: 散落 magic 编号总览（R66 → R67 对比）

| 类别 | R66 散落处数 | R67 散落处数 | 变化 | 优先级 |
|------|----------|----------|------|--------|
| 字号（fontSize: 数字） | 8+ 处（PDF 内） | 8+ 处 | 持平 | 低（PDF 不强求统一） |
| 圆角（circular(N)） | 1 处（PDF 6） | 1 处 | 持平 | 低 |
| 颜色（Color(0x)） | 0 处 ✅ | 0 处 ✅ | 持平 | - |
| 间距（EdgeInsets.all(N)） | 5+ 处（1/2/4 magic） | 5+ 处 | 持平 | 高 |
| Wrap spacing: 8 | 5+ 处 | **2 处** | ⬇ R67 修了 3+ | 中 |
| SizedBox 18×18 / 20×20 / 36×36 / 40×40 | 10+ 处 | 8+ 处 | ⬇ 部分修了 | 中 |
| `AppColors.success` / `AppColors.primary` (const) | 2 处 | **2 处** ⚠️ | ⬇ R67 没修 | **高**（dark mode bug） |
| `withValues(alpha: 0.X)` inline | 5+ 处 | 2 处 (`app_theme.dart`) | ⬇ | **中**（TODO 挂 3 round） |
| TextStyle(fontSize, fontWeight) inline | 12+ 处 | 8+ 处 | ⬇ R67 StatCard 抽了 | 中 |

## 附录 C: 评估总结

**R68 emil 视角成熟度卡片**（每项 1-5 ⭐，vs R66 对比）：

| 维度 | R66 评分 | R68 评分 | 评语 |
|------|---------|---------|------|
| 微交互（:active scale / haptic） | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | PressFeedback 30+ 处覆盖，Haptics 集中器 |
| 动效 token 化 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 6 curve + 8 duration + scrimAlpha + shadow 4 个全 theme-aware |
| 设计 token 颜色 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | R67 大幅改善（AppTokens 拆 4 sub-file），**仍漏 settings_page 2 处** |
| 设计 token 字号 | ⭐⭐⭐ | ⭐⭐⭐⭐ | R67 抽 StatCard 集中器，inline 8 处 → 待抽 textStyleSetupTitle/Subtitle |
| 设计 token 间距 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 仍漏 Wrap(spacing: 8) 2 处 + atomic 18/20 magic 8+ 处 |
| 设计 token 圆角 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 6 radius token + 100% 走 token |
| 阴影 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | R59 删 4 个 const shadow，强制 theme-aware |
| 视觉层级 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | SegmentedButton 选中态略弱 |
| 可达性 (a11y) | ⭐⭐⭐ | ⭐⭐⭐ | heatmap cell + progress bar 不可达；AppSemantics 集中器已有但未应用 |
| 触控目标 (44pt) | ⭐⭐⭐ | ⭐⭐⭐ | heatmap 28pt < 44pt ⚠️；R66 已点名未改 |
| 文字对比度 (WCAG) | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | last_med_info + reminder_cards 2 处边缘 |
| 高内聚（重复模式） | ⭐⭐⭐ | ⭐⭐⭐⭐½ | **R67 抽 6 个新集中器，DRY 显著改善** |
| 半成品 / WIP | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | **1 个 TODO 挂 3 round 仍未删**（app_theme.dart:128） |
| **总评** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐½ | R67 集中器抽到位，剩 5% 边缘"差一口气"问题 |

**关键差异 (R66 → R68)**:
- ✅ `AppTokens` 644 行 god constant → 246 行 facade + 4 sub-file (`app_colors` / `app_motion` / `app_spacing` / `app_typography`)
- ✅ 6 个新 widget 集中器 (InfoBanner / StatCard / DialogActionsRow / ChoiceChipWrap / SwipeDeleteBackground / ConsentDialog)
- ✅ `AppColors.fgDisabled` / `fgHintInput` 集中器已有但 `app_theme.dart:128/209` 仍 inline
- ✅ `shadowCardOf` 4 个 dynamic getter 强制主题感知 (R59 删 4 个 const)
- ⚠️ 仍漏修 2 处 dark mode (`settings_page.dart:63, 92`)
- ⚠️ 仍漏修 `_showCelebrationOverlay` 35% 高度定位 (`home_page.dart:627`)
- ⚠️ 仍漏修 atomic size token 散落 8+ 处 (18/20/36/40/110)
- ⚠️ 仍漏修 trend_heatmap_grid 28pt 触控目标 + Semantics
