# emilkowalski 视角审计 (v2, 2026-07-21 第二轮)

> 审计基线：v0.22 round 36 / schemaVersion 12 / Flutter 3.41.9 / Dart 3.12.2
> 工具：grep-first + flutter analyze (0 issue) + flutter test (748/748 pass)
> 上次审计（v1, 7/20）后已修 9 轮 (round 28-36)，本轮聚焦"剩余问题 + 新发现"

---

## 1. 顶层架构审视（5 条）

### 1.1 mood_dialog.dart 838 行 = 真正 god class，录音 + 评分 + STT 混在一起 ⭐⭐⭐
- **现象**：v0.22 round 31 P0 加录音 + STT 后，mood_dialog 从 750 行涨到 838 行。`_MoodDialogContentState` 一个 state 同时管：4 维度评分（mood/energy/sleep/anxiety）、标签多选、文字备注、录音状态机（idle/recording/recorded/playing）、STT partial 流、临时解密文件清理、AudioPlayer + 2 个 StreamSubscription。
- **改法**：拆 4 个子组件（`MoodScoreRow` / `MoodRecorder` / `MoodTags` / `MoodDialogActions`），录音 + STT 抽 `MoodRecorder` widget 单独 200-300 行。`mood_dialog.dart` 缩到 ~300 行（只做 dialog 容器 + 数据编排）。
- **改造成本**：🟠 1-2 天（要 preserve 录音 / 评分 / 保存 / 4 维度独立性）
- **用户感知收益**：⭐⭐⭐ — mood 录入是 tens/day 频度，弹 dialog 时的初始化慢、reload 卡顿都会被打磨

### 1.2 notification_service.dart 631 行 = facade 但仍偏厚 ⭐⭐
- **现象**：v0.22 round 30 (spen) 抽 `BadgeSyncService`（-40 行）、v0.18 round 18 抽 `SnoozeManager`（-90 行）后，notification_service 仍 631 行。承担 6 类通知：medication (id 2000+) / refill (6000+) / assessment (7000+) / safety (5000) / badge / snooze 编排。
- **改法**：抽 `MedicationNotifier`（schedule 编排 + cancel + reschedule）独立 ~200 行；`AssessmentNotifier` / `RefillNotifier` 类似。主 service 缩到 ~250 行（init + 委托 5 sub-service）。
- **改造成本**：🟠 1-2 天（要 preserve 5 类 id 范围 + cancel range 公式一致）
- **用户感知收益**：⭐ — 内部结构，不直接可见

### 1.3 ScaffoldMessenger 直接调用 55 处 vs AppSnackBar 集中器 74 处 — 集中器覆盖率 57% ⭐⭐
- **现象**：v0.22 round 29 抽 `AppSnackBar` 集中器后，home_page 8 处 / vent_compose 8 处 / mood_dialog 7 处 / settings_page 7 处 / medications_list_widget 5 处 / assessment_reminder_section 4 处仍直接 `ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(...)))`。集中器仅 57% 覆盖。
- **改法**：所有 `SnackBar(content: Text(...))` → `AppSnackBar.xxx(context, ...)`。机械替换半天。
- **改造成本**：🟡 半天
- **用户感知收益**：⭐⭐ — snackbar 颜色 / duration / reduced motion 统一

### 1.4 withValues(alpha:) 21 处散落 8 文件 vs 5 个 tinted token ⭐
- **现象**：v0.22 round 29 emil-21~22 加了 5 个 `tintedPrimarySoft/Deep/Light + tintedWarningSoft + tintedErrorSoft`，但实际 widget 调用点只换了 1 批，21 处 `color.withValues(alpha: 0.X)` / `Color(0xXX000000)` 仍散落。trend_calendar 1、check_in_button 2、refill_manage_page 2、notification_failure_banner 1、home_footer 1、assessment_widgets 1、assessment_history_page 3。
- **改法**：grep 21 处逐个换 `AppTokens.tintedXxx`。半天。
- **改造成本**：🟢 半天
- **用户感知收益**：⭐ — dark mode 颜色一致性

### 1.5 setup_page.dart 429 行内 4 步骤用 Inline AnimatedSwitcher 切，可抽 WizardStepTransition ⭐
- **现象**：`setup_page.dart:118-148` 内联 `AnimatedSwitcher(duration: 250ms, transitionBuilder: FadeTransition + SlideTransition)` 4 步骤切换。`MotionScheme` 已定义但 setup 步骤切换绕开 token（默认 250ms ease，跟 `Motion.standard` 300ms easeOutCubic 不一致）。
- **改法**：抽 `WizardStepTransition` widget 走 `Motion.duration/curve`。同 round 内可顺手。
- **改造成本**：🟢 1h
- **用户感知收益**：⭐ — 跨 step 转场更平滑

---

## 2. 底层逐行排查

### 🔴 P0 — 必修（3 条）

**P0-1. en.arb 缺 6 个 OEM key（v0.22 round 33 漏 en 翻译）**
- **位置**：`lib/l10n/app_zh.arb` 定义了 6 个 key：`notificationStatusCardOemBrandOthers` / `BrandSamsung` / `StepOthers1` / `StepOthers2` / `StepSamsung1` / `StepSamsung2`，但 `app_en.arb` 0 翻译。
- **严重度**：🔥 P0。en 模式国产 ROM 自检卡降级显示中文（或 key 字符串）— **l10n fallback bug**。
- **修法**（10 分钟）：`python scripts/check_arb_keys.py` 已自动检测。补 6 个 en 翻译。
- **用户感知收益**：⭐⭐⭐ — en 用户看自检卡是中文 = 产品 bug。

**P0-2. mood_dialog 838 行 god class 是主要性能 / 可维护性风险**
- 见顶层 1.1。
- 严重度：🟠 P0（结构 P0，不是 bug P0 — 影响未来 2-3 round 的迭代速度）。

**P0-3. settings_page 错误态不统一 (上次 P0-2 仍残留)**
- **位置**：`settings_page.dart:127-128`(`contactsAsync.error`) + `:140-141`(`medsAsync.error`)。v0.22 round 29 抽 `ErrorState` 集中器，但 settings 仍用 `Text(commonLoadFailed(e.toString()))`。
- **修法**（5 分钟）：2 处替换为 `ErrorState(title: ..., detail: e.toString(), onRetry: () => ref.invalidate(contactsProvider))`。
- **用户感知收益**：⭐⭐ — settings 出错时给"重试"按钮。

### 🟡 P1 — 应修（10 条）

**P1-1. AppSnackBar 集中器覆盖率 57%（55 处直接调用）**
- 见顶层 1.3。半天批量替换。

**P1-2. fontSize hardcode 17 处（4 文件），trend 系列已修**
- 分布：medication_report_pdf 11（PDF 端合理）+ main 3（升级 dialog，合理）+ app_tokens 2（token 定义本身）+ settings_page 1（`fontSize: 12`）。
- 修法：仅 settings_page:365 / 382 / 590 + main 3 改 token。`medication_report_pdf` PDF 端不强制。
- 工作量：🟢 30 分钟。

**P1-3. Semantics a11y 仅 6 处（上次报告 4 → 现在 6，+2 但仍稀疏）**
- 分布：mood_dialog 2 / check_in_button 2 / medication_calendar_page 1 / assessment_widgets 1。
- 重要 ListTile (settings / reminders / vent / medication) 大量无 Semantics。
- 修法：settings_page / reminders_hub_page / vent_list / medications_list 重要 ListTile 加 `Semantics(label: ..., button: true)`。1-2 天。
- 用户感知：⭐⭐ — TalkBack / VoiceOver 用户。

**P1-4. PressFeedback 覆盖率 28 处 — 关键 ListTile 仍漏网**
- v0.22 round 36 emil 集中清理 37 处，但 `reminders_hub_page` 5 个 card 内部配置按钮、`refill_manage_page` ListTile、`medications_list_widget` 3 个 IconButton、`contacts_list_widget` 添加按钮、`legal_page` _ConsentTile Switch 等仍漏。
- 修法：列出 15+ ListTile 统一外包 PressFeedback。1 天。
- 用户感知：⭐⭐ — tens/day 频度按钮手感统一。

**P1-5. BorderRadius.circular(\d) 6 处漏 token**
- `trend_charts.dart:66, 94` `circular(4)` → `AppTokens.radiusCellLg=4`；`medication_report_pdf.dart:118/165/207/282` `circular(4/6)`（PDF 端合理，不强求）。
- 修法：仅 trend_charts 2 处。5 分钟。

**P1-6. EdgeInsets 数字 hardcode 10 处（5 文件）**
- `main.dart:3`（升级 dialog，合理）+ `contacts_list_widget.dart:1` + `trend_calendar.dart:1` + `medication_report_pdf.dart:4`（PDF 端）+ `medication_calendar_page.dart:1`。
- 修法：grep 5 处非 PDF 端改 token。30 分钟。

**P1-7. `medication_calendar_page.dart:344` + `medication_report_dialog.dart:102, 111, 132, 160` 主按钮无 PressFeedback**
- 修法：4 处主按钮外包 PressFeedback。15 分钟。

**P1-8. catch (_) 8 处剩 5 处容错 / 2 处 best-effort**
- 详情见 spen 视角 报告 P1-3。5 处容错中 3 处是 schema guard（data_export_service:199/204/210 + json_codec:37 + assessment_record:51）合理，**2 处 best-effort 应走 swallowError**：
  - `settings_page.dart:520` 写历史失败（注释"不影响主流程"）
  - `notification_status_card.dart:106` web PlatformException
- 修法：2 处换 `swallowError(where: '...', error: e, stack: st)`。10 分钟。

**P1-9. setup_page 转场未走 MotionScheme**
- `setup_page.dart:118-126` `AnimatedSwitcher` 默认 250ms（vs `Motion.standard` 300ms easeOutCubic）。抽 `WizardStepTransition` 走 token。
- 修法：1h。

**P1-10. `loading_skeleton.dart` _maybeShimmer 注释与实现脱节（上次报告残留）**
- `_maybeShimmer()` 注释说"respect reduce-motion"，但内部只调 `_controller.repeat()`，首次 build 仍启动 controller。
- 修法：删 `_maybeShimmer` 入口，让 `didChangeDependencies` 全权负责；或函数内 `if (MediaQuery.of(context).disableAnimations) return`。30 分钟。

### 🟢 P2 — 可修（10 条）

**P2-1. _ReminderCard "配置" 按钮无 PressFeedback** — `reminders_hub_page.dart` 内
**P2-2. `setup_step_medication.dart:248/252/307/313` InputChip / ActionChip / FilterChip 无 PressFeedback**
**P2-3. `medication_report_dialog.dart:118/149` `Colors.black54` 反白漏 dark mode**
**P2-4. `mood_dialog.dart:160` `Colors.white` spinner 漏 dark mode**（v0.22 round 36 P1 集中清理时漏掉）
**P2-5. Haptics 不集中**：home_page 3 处 HapticFeedback.mediumImpact / lightImpact 散落，未走 `Haptics.tap/success` 集中器
**P2-6. `staggerDelay = i * 40` 公式散 2 处**：vent_list_page + medication_calendar_page，magic number。抽 `AppTokens.staggerStepMs=40` + `staggerCapMs=400`
**P2-7. `celebrationDisplayMs=1800` hardcode**（home_page 庆祝 overlay 自动消失）— 已有 token 但 v0.22 round 30 加的，部分位置未用
**P2-8. `mood_quick_button.dart:42 fontSize: 22` 漏 token**（应新增 `fontSizeTitle=22` 档或用 `fontSizeButton=20`+ close 调整）
**P2-9. `app_router.dart:215-280` Error widget 用 `BorderRadius.circular(8)` 漏 token**
**P2-10. `dividerTheme.thickness: 1, space: 1` (app_theme.dart:42-43) 偏紧** — M3 标准 0.5/16-24

### ⚪ P3 — 锦上添花
- **P3-1**. `boxShadow` color 用 `0x14000000` const const 硬编码 4 处，dark mode 阴影没法动态增强
- **P3-2**. 5 个 page（home/contact/mood/medication/trend）仍 6+ 处 `Theme.of(context).colorScheme.onSurfaceVariant` 未走 `AppTokens.textSecondaryColor(context)`
- **P3-3**. 字体 `height: 1.2` 在 `check_in_button.dart:72,180` 主按钮偏紧
- **P3-4**. `app_router.dart` Error widget `EdgeInsets.all(24)` + `Colors.red` 漏 token
- **P3-5**. `vent_list_page.dart:224` `EdgeInsets.only(top: 4)` magic 4
- **P3-6**. `legal_page.dart:64-67` `SnackBar(content: Text(withdraw ? '已撤回' : '已重新同意'))` 2 个 l10n key 缺（zh-only，en 模式降级）
- **P3-7**. `legal_page.dart` 协议版本号 `v0.22-2026-08-01` 跟 pubspec.yaml version 字段未自动同步
- **P3-8**. `assessment_widgets.dart:202` '未选' hardcode 中文（zh-only）

---

## 3. 整体评级
**A-**。emil 视角上次报告 12 条 P0/P1 修完 11 条（剩 1 条 settings 错误态），新增 1 条 l10n 一致性 P0。

## 4. 关键 3 个发现
1. 🔥 **P0-1 l10n**：6 个 OEM key 缺 en 翻译（round 33 加 zh 时漏 en），en 模式国产 ROM 自检卡降级中文。10 分钟修。
2. 🔥 **P1-3 a11y**：Semantics 6 处 vs 上百个 ListTile 严重不足，TalkBack 用户无法用。
3. 🔥 **P0-2 结构**：mood_dialog 838 行是 v0.22 round 31 加录音后涨出来的真 god class，1-2 天拆 4 子组件。
