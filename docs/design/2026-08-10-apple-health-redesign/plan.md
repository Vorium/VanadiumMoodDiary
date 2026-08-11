# Apple Health Redesign · Implementation Plan

> **Spec**: `spec.md` (v0.1 draft, 2026-08-10)
> **Strategy**: 5 phase · 13 task · subagent-driven · 1-2 周跨 session
> **Pre-existing baseline**: 2103 tests pass · 0 analyzer error · 18 守门员全绿 (v0.30 R107)

---

## Phase 0: Setup (本 session 0 task)

**目标**：spec / plan 写完，用户确认。

**Task 0.0**（本 conversation）：
- ✅ Spec 写完 → `docs/design/2026-08-10-apple-health-redesign/spec.md`
- ✅ Plan 写完 → 本文件
- 🔄 关键决策点 8 个 → ask_user 1 个 ask（最高优先 4 个）
- 🔄 用户通过 → 进入 Phase 1

**Task 0.1**（开新 session 时跑）：
- baseline test 复测：1163 → 2103 cases 全过
- 18 守门员复测：全绿
- 当前 master 干净：`git status` 0 modified

---

## Phase 1: Token 重定义（4 task · 4-6h · 1 subagent）

> **风险最高**：token 改 100% 透传到 11 feature 页面。Phase 1 完必须跑全 baseline。

### Task 1.1: `app_colors.dart` 改写
**目标**：从 M3 嫩绿系 → Apple Health iOS system color + 8 metric palette
**Step**（每 step 2-5 分钟）：
1. 改 `background #FAFAFA → #F2F2F7`
2. 改 `textPrimary #1A1A1A → #000000` (light) / `#FFFFFF` (dark)
3. 改 `textSecondary / textHint` → iOS 3C3C43 alpha
4. 改 `border / divider` → iOS separator C6C6C8
5. 改 `primary #6BCF7F → #34C759` (iOS systemGreen)
6. 新增 `static const List<Color> healthMetricsColors`（8 个 iOS system color）
7. 新增 `static Color healthMetricsColorFor(String metricId)` lookup
8. 新增 `static Color tintedMetricSoft(BuildContext c, String metricId)` helper
9. 改 `backgroundDark #121212 → #000000` / `surfaceDark #1E1E1E → #1C1C1E`
10. 保留 `success / warning / error` 状态色（已是 iOS 系）

**改动文件**：`lib/core/theme/app_colors.dart`
**测试**：跑 baseline 2103 tests，看 fail 数（应 < 20 个，主要是 dark mode visual）
**验证**：`flutter analyze` 0 error + `flutter test` baseline 2103 -N 通过

### Task 1.2: `app_typography.dart` 改写
**目标**：加 ultralight + 调字号（17pt body / 13pt caption）+ 行高 + letter spacing
**Step**：
1. 改 `fontSizeButton 20 → 17`
2. 改 `fontSizeBody 18 → 17`
3. 改 `fontSizeLabel 16 → 15`
4. 改 `fontSizeCaption 14 → 13`
5. 改 `fontSizeMicro 10 → 11` / `fontSizeXxxSmall 8 → 9`
6. 新增 `fontSizeMetricXl 34` / `fontSizeMetricLg 28` / `fontSizeMetricMd 22`
7. 改 `lineHeightTight 1.2 → 1.1` / `lineHeightNormal 1.5 → 1.4` / `lineHeightLoose 1.8 → 1.6`
8. 新增 `fontWeightUltralight FontWeight.w200` / `fontWeightLight FontWeight.w300`
9. 新增 `textStyleMetricXl(c)` / `textStyleMetricLg(c)` / `textStyleMetricMd(c)` 3 个 helper（ultralight 大数字）
10. 现有 `textStyleTitle/Headline/Body/...` 加 `letterSpacing: -0.5/-0.2/0` 按 size 阶梯
11. 更新 `textStyleButton` 用新字号 17 + letterSpacing -0.2

**改动文件**：`lib/core/theme/app_typography.dart`
**测试**：同 Task 1.1 baseline 复测
**验证**：analyze + test

### Task 1.3: `app_spacing.dart` 改写
**目标**：圆角缩小 + 间距减小 + 高度从 88→50
**Step**：
1. 改 `radiusButton 24 → 14`
2. 改 `radiusInput 12 → 10`
3. 改 `buttonHeight 88 → 50`
4. 改 `buttonHeightSmall 56 → 44`
5. 改 `inputHeight 56 → 44`
6. 改 `iconSize 24 → 22` / `iconSizeLg 32 → 28` / `iconSizeInline 18 → 17` / `iconSizeSmall 14 → 13` / `iconSizeEmpty 64 → 56` / `iconSizeError 56 → 48`
7. 改 `spacingMd 24 → 16` / `spacingLg 40 → 24` / `spacingXl 80 → 48`
8. 改 `pageMarginH 16 → 20` / `pageMarginV 24 → 16`
9. 新增 `spacingXxxl 32` / `radiusTile 12` / `radiusLargeButton 22`
10. 改 `staggerStepMs 40 → 30` / `staggerCapMs 200 → 150`

**改动文件**：`lib/core/theme/app_spacing.dart`
**测试**：baseline 复测，特别看 spacing 改对密集列表的影响
**验证**：analyze + test + 1 visual sanity（home_page 不再过空）

### Task 1.4: `app_motion.dart` 改写
**目标**：加 spring + 0 shadow + Apple curve
**Step**：
1. 改 `durNormal 300 → 250` / `durSlow 500 → 400` / `durPress 160 → 100`
2. `durFast 200` 保留
3. 新增 `curveSpring cubic-bezier(0.23, 1, 0.32, 1)` (Apple springOut 近似)
4. 新增 `curveAppleSheet cubic-bezier(0.32, 0.72, 0, 1)`
5. 新增 `curveAppleDrawer cubic-bezier(0.77, 0, 0.175, 1)`
6. **关键改**：`shadowCardOf` 返回 `[]`（空，Apple Health 0 阴影）→ 注释说明
7. `shadowCardDarkOf` 同上
8. `shadowDialogOf` 极轻（blurRadius 24, offset 0,8, alpha 0.08）
9. `shadowOverlayOf` 极轻
10. 新增 `Spring` class（mass / stiffness / damping）+ 3 静态实例 `standard / gentle / bouncy`
11. 现有 `MotionScheme / MotionSchemeTokens` 保留

**改动文件**：`lib/core/theme/app_motion.dart` + 新增 `lib/core/theme/spring.dart` (单独文件)
**测试**：baseline 复测（shadow 改影响 visual 较多，预计 5-10 test fail）
**验证**：analyze + test

### Phase 1 验收
- [ ] 4 个 token 文件全改完
- [ ] 18 守门员全绿
- [ ] `flutter test` baseline 2103 -N（预计 N ≤ 20）通过
- [ ] 5+ 现有 widget test 加 visual assertion（确认新字号/圆角生效）
- [ ] 1 截图（home_page 前后对比）

---

## Phase 2: 关键 widget 重写（4 task · 6-8h · 4 subagent 并行）

> **4 subagent 并行**（每个独立 widget 改动无耦合）

### Task 2.1: `PrimaryButton` 重写（subagent A）
**目标**：3 variant Apple Pill 风格
**Step**：
1. 现有 `PrimaryButton` 改造：
   - 默认 `variant: PrimaryButtonVariant.primary` (filled)
   - 新增 `variant: PrimaryButtonVariant.secondary` (tonal)
   - 新增 `variant: PrimaryButtonVariant.tertiary` (text)
   - 新增 `leadingIcon` 字段
2. 内部包 `PressFeedback` 提供 scale(0.97) 100ms 反馈
3. 高度 50 / 圆角 14 / 字号 17 / w600
4. `isFullWidth: false` 兼容 dialog 内
**改动**：`lib/presentation/widgets/primary_button.dart`
**测试**：
- 保留现有 test + 加 3 个 variant test
- 1 golden test
**验证**：analyze + test + 1 视觉 sanity

### Task 2.2: `CheckInButton` 重写（subagent B）
**目标**：Apple Health 巨型 pill CTA
**Step**：
1. 高度 64 (`buttonHeight + 14`)
2. 圆角 32 (`radiusLargeButton`，pill 形状)
3. 字号 20 / w600
4. 居中：icon/emoji + 文字 + 副标题（连续天数）
5. 背景：`primaryColor(ctx)`
6. 打卡完成态：
   - 变 `disabledColor(ctx)` 灰
   - 显示对勾动画（AnimatedSwitcher + scale 0.95→1 spring）
7. 保留 `_StreakCounter`（tween 递增）
8. loading 状态保留
**改动**：`lib/presentation/widgets/check_in_button.dart`
**测试**：现有 test 保留 + 加 spring 进场 test
**验证**：analyze + test + 1 视觉

### Task 2.3: `StatCard` 重写 + 新增 `AppleHealthTile`（subagent C）
**目标**：Apple Health 大数字 + 彩色 metric 模块
**Step A**（StatCard）：
1. 数字默认 34 / w200 ultralight / tight 1.1
2. 单位小字 13 / w400 / textSecondary
3. label 在下 13 / w400 / textHint
4. 4 个 variant: `default / large / xl / inline`
5. 数字递增 tween（仿 `_StreakCounter` 模式，单独抽 `TweenNumber` widget）
**Step B**（新 `AppleHealthTile`）：
1. 圆角 12 容器
2. 背景：metric 色 @ alpha 0.12
3. 左上：metric icon 28pt metric 色
4. 中：metric 名 (caption) + 当前值 (metricLg ultralight)
5. 右：chevron
6. 点击 callback
7. 支持 8 metric（medication/mood/vent/assessment/checkIn/trend/contact/sleep）
8. dark mode 适配
**改动**：
- `lib/presentation/widgets/stat_card.dart`
- `lib/presentation/widgets/apple_health_tile.dart` (新增)
**测试**：
- StatCard 现有 test + 1 ultralight test
- AppleHealthTile 新增 8 metric test
- 1 dark mode test
**验证**：analyze + test

### Task 2.4: 新增 `AppleListSection` + 改 `SectionHeader`（subagent D）
**目标**：iOS 群组列表 + ALL CAPS section header
**Step A**（新 `AppleListSection`）：
1. 标题（AppleListSectionHeader, 13pt w500 ALL CAPS letter-spacing 0.6 textHint）
2. 内容白色圆角 16 容器
3. 内部 cell 用 hairline divider（0.5px）
4. cell 高度 44pt
5. 可选 footer text（说明）
6. dark mode 适配（surface 1C1C1E）
**Step B**（SectionHeader 改造）：
1. 改 16pt → 11pt (`fontSizeCaptionSm`)
2. 改 w500 → w500 (不变)
3. 改 textSecondary → textHint
4. 新增 ALL CAPS 模式（`isAllCaps: bool`）
5. letter-spacing 0.6 (ALL CAPS)
**改动**：
- `lib/presentation/widgets/apple_list_section.dart` (新增)
- `lib/presentation/widgets/section_header.dart`
**测试**：
- AppleListSection 新增 1 golden test
- SectionHeader 现有 test 保留 + 1 ALL CAPS test
**验证**：analyze + test

### Phase 2 验收
- [ ] 5 widget 全重写 + 3 widget 新增
- [ ] 8+ 新 widget test 全过
- [ ] 18 守门员全绿
- [ ] baseline 2103 + 8 新 case 全过
- [ ] 1 截图：home_page 显示 AppleHealthTile 彩色块

---

## Phase 3: 核心 3 页重设（3 task · 6-8h · 3 subagent 并行）

> **3 subagent 并行**（每个独立页面改）

### Task 3.1: `HomePage` 重设（subagent E）
**目标**：Apple Health 仪表盘
**Step**：
1. 改 `home_header.dart`：大字 greeting 28pt + 副字日期 15pt + theme toggle 32x32
2. 改 `today_summary_card.dart`：4 个 StatCard 2x2 网格（间距 12）
3. 改 `quick_mood_carousel.dart`：5 个圆形 mood button 48x48 + 选中 spring 放大 1.1
4. 改 `primary_action_row.dart`：2x2 AppleHealthTile 网格（medication/mood/vent/assessment）
5. 改 `secondary_action_row.dart`：保持，但用 spacingMd 16
6. 整体 spacing：24 → 16
7. 顶部加 `AppleListSection` 章节分组
8. `home_page_state.dart` build 整合
**改动**：
- `lib/presentation/pages/home/widgets/*.dart` (5 个 widget 文件)
- `lib/presentation/pages/home/home_page_state.dart` (build 段)
- `lib/presentation/pages/home/home_page.dart` (基本不动)
**测试**：现有 home test 保留 + 加 4 StatCard grid test
**验证**：analyze + test + 1 截图

### Task 3.2: `SetupPage` 4 步重设（subagent F）
**目标**：Apple 引导流程
**Step**：
1. 顶部加进度条 1/4（细 hairline）
2. 改大标题 28pt + 副标题 15pt
3. 改 `setup_step_welcome.dart`：表单改 AppleListSection 风格
4. 改 `setup_step_consent.dart`：consent 项改 ALL CAPS section header + 大字条款
5. 改 `setup_step_medication.dart`：medication list 改 AppleListSection
6. 改 `setup_step_done.dart`：完成态大对勾 + 大字 "已就绪"
7. 底部按钮：PrimaryButton full width
**改动**：
- `lib/presentation/pages/setup/setup_step_welcome.dart`
- `lib/presentation/pages/setup/setup_step_consent.dart`
- `lib/presentation/pages/setup/setup_step_medication.dart`
- `lib/presentation/pages/setup/setup_step_done.dart`
- `lib/presentation/pages/setup/setup_widgets.dart`
**测试**：现有 4 step test 保留 + 加 1 ALL CAPS test
**验证**：analyze + test + 1 截图（4 步各 1 张）

### Task 3.3: `MedicationPage` 重设（subagent G）
**目标**：Apple tile + section 风格
**Step**：
1. 顶部 8 个 AppleHealthTile 横滚（medication 主题红色）
2. 主区 `today_med_schedule.dart` 改 AppleListSection
3. `medication_calendar_page.dart` 章节改 ALL CAPS header
4. `refill_manage_page.dart` 改 AppleListSection
5. `add_medication_page.dart` 表单改 AppleListSection
6. `medication_detail_page.dart` 详情改 AppleListSection
7. FAB 添加 medication（systemRed 圆点）
**改动**：
- `lib/presentation/pages/medication/today_med_schedule.dart`
- `lib/presentation/pages/medication/medication_calendar_page.dart`
- `lib/presentation/pages/medication/refill_manage_page.dart`
- `lib/presentation/pages/medication/add_medication_page.dart`
- `lib/presentation/pages/medication/medication_detail_page.dart`
- `lib/presentation/pages/medication/medication_page.dart`
**测试**：现有 5 子页 test 保留 + 加 1 AppleListSection test
**验证**：analyze + test + 1 截图

### Phase 3 验收
- [ ] 3 核心页重设完
- [ ] baseline 2103 + 12 新 case 全过
- [ ] 18 守门员全绿
- [ ] 5 截图：home + setup (4步) + medication (5子页)

---

## Phase 4: 中等页 follow + 清理（1 task · 4-5h · 1 subagent）

> **1 subagent 串行**（影响小，主要靠 token 自动化 + 微调）

### Task 4.1: Trend / Mood / MoodList / Vent / Assessment / CheckIn / Contact / Settings / DailyTracking follow
**目标**：所有未在 Phase 3 改的页面跟新 token 适配
**Step**：
1. 跑 1 遍这 9 个 feature 的截图，找出还残留 M3 旧风格的元素
2. 章节统一改 `SectionHeader`（ALL CAPS）— grep `SectionHeader(` 0 替换
3. `Card + Padding` 模式批量改 `AppleListSection` — 优先 9 个 feature
4. 按钮替换 `ElevatedButton` / `OutlinedButton` → `PrimaryButton` variant — grep
5. 列表分隔线改 `Divider(thickness: 0.5)` — hairline
6. 验证：9 feature 截图 + analyze + test
**改动**：
- `lib/presentation/pages/trend/*`
- `lib/presentation/pages/mood/*` + `mood_list/*`
- `lib/presentation/pages/vent/*`
- `lib/presentation/pages/assessment/*`
- `lib/presentation/pages/check_in/*`
- `lib/presentation/pages/contact/*`
- `lib/presentation/pages/settings/*`
- `lib/presentation/pages/daily_tracking/*`
**测试**：现有 test 保留 + 加 1 统一 test
**验证**：analyze + test + 9 截图

### Phase 4 验收
- [ ] 9 feature 全 follow
- [ ] baseline 2103 + 16 新 case 全过
- [ ] 18 守门员全绿
- [ ] 9 截图

---

## Phase 5: 验证 & 收尾（1 task · 2-3h · 1 reviewer subagent）

### Task 5.1: 全面验证
**Step**：
1. `flutter analyze` 0 error
2. `flutter test` 全过（baseline 2103 + 累计 16+ 新 case）
3. 18 守门员全绿（特别是 `check_no_pua` / `check_changelog` / `check_arb_keys` / `check_orphan_arb_keys` / `check_strings_hardcoded` / `check_zh_hant_consistency` / `check_coverage` / `check_16kb_alignment`）
4. `flutter build web` + 手动截图 11 feature 对比
5. CHANGELOG 写 [0.31.0] 或 [0.32.0] 总结（Apple Health redesign）
6. 跑 `check_changelog.py` 确认版本号同步
7. 提交风格：`<version> round N: <title>`，参考 git log
8. 主 commit 风格：
   - 1 commit: `0.31.0 round 1: redesign app to Apple Health style (token + 5 widget + 11 page)`
   - 或拆 5 commit（按 phase）

### Phase 5 验收
- [ ] 0 analyzer error
- [ ] 0 test fail
- [ ] 18 守门员全绿
- [ ] 11 feature 截图对比（before/after）
- [ ] CHANGELOG 写完

---

## Rollback 策略

### 按 phase 回滚
每 phase 完跑 1 个 commit tag（v0.31.0-rc1 / v0.31.0-rc2 / ...），出问题可直接回滚到上一个 tag。

### 单 widget 回滚
每个 widget 改是独立 commit，revert 单文件即可。

### 紧急回滚
所有改动在工作分支（`feat/apple-health-redesign`），main 0 影响。完整体检后 merge。

---

## 风险追踪

| 风险 | 概率 | 影响 | 缓解 |
|---|---|---|---|
| R1: token 改 100+ widget regression | 高 | 高 | Phase 1 完必跑 baseline，分批改 |
| R2: dark mode contrast bug | 中 | 中 | 跑 contrast 守门员 |
| R3: Spring 跟 MotionScheme 冲突 | 中 | 中 | 双轨制（按场景选） |
| R4: 11 feature 改完总 regression | 中 | 高 | 5 phase 流水，phase 之间 baseline |
| R5: 新增彩色 metric palette 跟现有 success/warning 冲突 | 低 | 低 | 8 metric 是独立常量，不复用 status 色 |
| R6: 截图对比需要 emulator 跑通 | 中 | 低 | flutter build web + python http server 跑 |
| R7: 用户对主色 #6BCF7F → #34C759 不满意 | 中 | 中 | 决策点 1 必问 |

---

## 沟通 / 报告节奏

- 每个 task 完 → 报告 1 段：改了啥 + 测试通过 + 截图（如有）
- 每个 phase 完 → 1 份 phase 总结 + 3-5 截图
- 整体完 → 1 份最终报告 + before/after 对比 + CHANGELOG

---

## 时间汇总

| Phase | 估时 | 并行 | 实际 session 数 |
|---|---|---|---|
| Phase 0 | 0.5h | 1 | 1（本 conversation） |
| Phase 1 | 4-6h | 1 | 1-2 |
| Phase 2 | 6-8h | 4 | 1-2 |
| Phase 3 | 6-8h | 3 | 1-2 |
| Phase 4 | 4-5h | 1 | 1 |
| Phase 5 | 2-3h | 1 | 1 |
| **总计** | **22-30h** | - | **5-8 session** |

按每个 session 1-4h 实际跑量，估 1-2 周内完成。
