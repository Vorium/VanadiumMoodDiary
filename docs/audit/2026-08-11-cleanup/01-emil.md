# 视角 1 报告 · emil (Emil Kowalski 设计工程)

## 元信息
- 跑时间: 2026-08-11 (v0.31.0 Apple Health 风格重设计审视)
- baseline: master HEAD `01d8f4a` v0.31.0 (23 commit 净 +3943 / 0 error / 90 issues)
- 关注: 动效 / 组件设计 / 看不见的细节 / iOS HIG / spring vs duration / 缓动曲线
- 范围: presentation 层新组件 (PrimaryButton/CheckInButton/StatCard/AppleHealthTile/AppleListSection/SectionHeader/spring.dart) + token 4 件套 (app_colors/typography/spacing/motion) + home/medication/setup 整合改文件

## 5 维度评估

### 1. 外部链接检查
- [OK] `lib/core/theme/spring.dart:18-19` 只 import `flutter/material.dart` (BuildContext) + `flutter/physics.dart` (SpringDescription/SpringSimulation), 0 远程 URL — emil "Spring 物理模型 走 flutter 内置"
- [OK] `lib/presentation/widgets/apple_health_tile.dart:33-37` 4 个 internal import, 0 远程包
- [OK] `lib/presentation/widgets/primary_button.dart:31-34` 2 个 internal import + material, 0 远程包
- [OK] `lib/presentation/widgets/stat_card.dart:19-22` 2 个 internal + material
- [OK] `lib/presentation/widgets/apple_list_section.dart:32-34` 1 个 internal + material
- [OK] `lib/presentation/widgets/section_header.dart:15-17` 1 个 internal + material
- [OK] `lib/presentation/widgets/check_in_button.dart:35-41` 7 个 internal + material, 0 远程包
- [OK] token 4 件套 (app_colors/typography/spacing/motion) 全部 import `flutter/material.dart` + 自家 internal, 0 远程
- **总计**: 0 远程 URL 漏隐藏, 0 pubspec 错配 — emil "DRY for taste" R65 facade + R31 子模块拆分到位

### 2. 上架 / 架构 / 重构 / 半成品

#### 上架阻塞（跨视角共识 + R108 P0-001 漏闭环）
- **[ISSUE P0-A] R108 P0-001 TODO_R108.md 5 大上架前 P0 0 闭环** — `TODO_R108.md` (项目根, R108 进行中文件) 16 个子任务全部 `[ ]`, 5 大项 keystore bash / data_safety 验证 / health_apps 脚本 / 截图脚本 / 域名 + 4 邮箱 HTML 模板 = 0 完成。**R108 报告中已标, v0.31.0 没修**。
- **[ISSUE P0-B] R108 P0-002 FadeIn default `duration = AppTokens.durSlow` 500ms 仍存在** — `lib/presentation/widgets/animations/fade_in.dart:41`, diff `739f399^..01d8f4a` 0 行。50+ caller 跑 500ms = "拖泥带水" (R108 emil 报告 P0-002)。
- **[ISSUE P0-C] R108 P1-001 7 处 raw IconButton 仍 7 处** — Round 11a 改 `medication_page.dart:76` → `medication_page.dart:87` 净 0 改善 (R108 漏修 → v0.31.0 仍漏, **反而引入 1 处新漏**：`medication_page.dart:86-92` 用 `PressFeedback(child: IconButton(...))` 而非 `PressFeedbackIconButton` 集中器)。当前 7 处全清单:
  - `medication_page.dart:87` (R11a 新引入, 自我违反 R57 集中器)
  - `medication/add_medication_page.dart:135` (R11 改了 medication 5 子页但漏)
  - `medication/medication_page.dart:87` (同上, 改 1 处又漏 1 处)
  - `daily_tracking/daily_tracking_page.dart:77`
  - `daily_tracking/tracking_customize_page.dart:144` (新发现, R108 报告漏列)
  - `crisis_hotline_page.dart:185, 192` (2 处, R108 报告列)
  - `mood_list/mood_detail_page.dart:28` (新发现, R108 报告漏列)
- **[ISSUE P0-D] R108 P1-003 QuickMoodCarousel 硬编码中文 `'记录失败，请重试'` 仍存在** — `lib/presentation/pages/home/widgets/quick_mood_carousel.dart:84` (R9a 改 AppleListSection 时未修, 反而引入新硬编码 `'心情'` at line 99)

#### v0.31.0 新引入半成品（spec "subagent 跑超时被 token 切断" 风险）
- **[ISSUE P0-E] `Spring` 物理模型 (lib/core/theme/spring.dart) 0 caller** — 145 行 + 1 lock-in test (`test/core/theme/app_tokens_lock_in_round95_test.dart` 中 spring 段), grep `Spring\.|SpringType|toSimulation|animateWith\(` 命中仅 spring.dart 自身 + app_motion.dart 注释 2 处。`SpringType.standard/gentle/bouncy` 3 档 + `Spring.of(context, type)` 工厂方法 0 实际使用。**R4 注释写"适用: 通用 push/hover/state change / page transition / modal 进出"但代码全走 `curveSpring` 模拟 (check_in_button:104,113,230,233 + quick_mood_carousel:170 = 5 处), 物理 Spring 跟 "curve 模拟 spring" 双轨制未落地**。这是 P0 半成品。
- **[ISSUE P1-A] 3 Apple cubic-bezier 2 个 0 caller** — `curveSpring` 用 5 处 (check_in_button 4 + quick_mood_carousel 1) ✅, 但 `curveAppleSheet` (`Cubic(0.32, 0.72, 0, 1)`) + `curveAppleDrawer` (`Cubic(0.77, 0, 0.175, 1)`) 0 命中。spec §3.4.2 "iOS modal 从底部升起" + "iOS drawer 滑入/滑出" 用例未落地。
- **[ISSUE P1-B] R11a medication_page.dart 4 处硬编码中文 + 1 TODO 占位** (新引入, R108 没列):
  - L138 `label: '待服'`
  - L145 `label: '已服'`
  - L152 `label: '需续方'`
  - L161 `value: '查看'`
  - L135 `// TODO(Phase 5): 用 ARB key 替换 hardcode` (自我承认)
- **[ISSUE P1-C] R11a medication_page.dart:101 `Colors.white` 硬编码** — FAB `foregroundColor: Colors.white` 应走 `Theme.of(context).colorScheme.onPrimary` (同 R108 cross-project Colors.white 模式)
- **[ISSUE P1-D] R9a QuickMoodCarousel.dart:99 AppleListSection `title: '心情'` 硬编码** — line 108 内部已用 `l10n.homeQuickMoodTitle` 但 AppleListSection 标题写死
- **[ISSUE P1-E] R108 P2-001 `_StreakCounter` 60fps setState 缺 RepaintBoundary 仍未修** — `lib/presentation/widgets/check_in_button.dart:267-331` `addListener + setState` 模式 60 次/秒 rebuild, 跟 R71 CelebrationBounce 加 RepaintBoundary 模式不一致; 同时 `_EntrySpring` (line 216-254) 走 `AnimatedBuilder` 模式 → 同 widget 内 2 套动画模式不一致

#### 跨视角 spec/data 矛盾（必报整合者）
- **[ISSUE P1-F] spec 写 "baseline 2102/1/127 → 2102/1/127 (净改善 +66 pass / -1 fail)" 跟实际跑不符** — 实际 `flutter test` 跑出 2103 pass / 1 skip / **126** fail, 净 +1/-1（不是 +66/-1）。spec 写的"+66/-1" 跟实际净改善+1/-1 严重不符, 需 spec 作者核 baseline 锁定方式（可能是 R108 末期 regression 而不是 R31 改完的 23 commit 净改善, 或 R12b 4 个 sanity test 加的 pass 数被 R11 medication 5 子页 test fail 抵消）

### 3. 顶层架构审视

**整体评价**: 23 commit 落地 95% 干净, design token 4 件套 (app_colors/typography/spacing/motion) 集中化是 R65 之后最成熟的 "design engineering" 时刻。**Apple Health 8 metric palette (medication/mood/vent/assessment/checkIn/trend/contact/sleep) + ultralight w200 大数字 + ALL CAPS section header + iOS hairline divider 0.5 + 0 阴影** 4 大视觉签名全部到位, 跟 Apple iOS 17/18 Health app 视觉一致。

**高内聚低耦合度**: **8.5/10** (R108 8.5 → 持平, v0.31.0 没新拆 god class, 也没新引入耦合) — 4 层架构 1:1 + 23 commit 集中在 presentation 层 + token 4 件套跨层复用, **跨 feature import 0 violation** (grep 100+ 命中全是同 feature 内 widget 引用, setup ↔ home 是 R95 文档化 public naming 解决循环 import, 跟 R108 9 视角架构报告 8.4 一致)

**重构建议 (emil 哲学)**:
- **P0 必修**: 修 5 处 P0 issue (A/B/C/D/E) + 1 处 P1-A 死代码删除。R109 一周内闭环。
- **R110 feature-first**: 23 commit 都在 `lib/presentation/widgets/`, 已成 "Apple Health 组件库", 适合 R110 抽 `lib/features/apple_health_components/` 子 package (跟 pub workspace 配套)
- **token 体系饱和警告**: AppTokens facade 23 commit 后 ~370 行, 转发 80+ 字段 (R65 + R31 累计)。emil "good defaults matter more than options" — facade 内部不需新增字段, 后续应"只删不增"。Spring 0 caller + 2 Apple curve 0 caller = 已饱和征兆
- **R109 god class 路线图 (跟 R108 整合一致)**: medication_page.dart 现在 ~360L (R11a 整合后) — 仍待拆, 建议把 4 AppleHealthTile 横滚 + 4 时间段分组 + 2 AppleListSection 拆 controllers/ 模式（跟 home_page_state R108 拆 3 controller 同款）

### 4. 底层逐行排查

- **已遍历**: 9 个核心文件 (PrimaryButton 207L / CheckInButton 331L / StatCard 228L / AppleHealthTile 159L / AppleListSection 255L / SectionHeader 156L / spring.dart 145L / app_motion.dart 307L / home_page_state.dart 468L) + medication_page.dart:1-200 + setup_page_state.dart:1-200 + PressFeedback 116L
- **找到 bug**: 见 §2 P0-A ~ P1-F (5 P0 + 6 P1, 全部带文件:行号)
- **优化点**:
  - [P2-A] `setup_page_state.dart:133` `Size.fromHeight(12)` magic + 注释 `// 4+3+4` 应抽 `appBarProgressBarHeight` token (跨页面复用 R10 progress bar)
  - [P2-B] `setup_page_state.dart:147` `Offset(0, 0.04)` magic 滑动应抽 `setupPageSlideOffsetY` token
  - [P2-C] R108 P2-005 `PressFeedback` 不调 Haptics 设计决策, 23 commit 0 改造 — R109 评估加 `hapticOnTap: HapticsKind` enum 参数
  - [P2-D] `CheckInButton` 硬编码 `pillHeight = AppTokens.buttonHeight + 14` (64) / `pillRadius = 32` / `pillFontSize = 20` (line 68-74), 注释说"加 token 污染 AppSpacing", 但 spen 跨视角共识 3 magic 留隐患 — 建议保留"故意留 magic" 决策但加 `lock-in test` 验证 (跟 R31 "lock-in test 同步" 模式一致)
  - [P2-E] `_StreakCounter` 跟 `_EntrySpring` 同 widget 内 2 套动画模式 (addListener+setState vs AnimatedBuilder) 不一致 — 选一种统一

### 5. dev doc 更新
- **AGENTS.md**: 改了 — 上一轮 R108 revisit (2026-08-10) 已加 R108 路线图 §"v0.30 R108 revisit 综合审视", 但 v0.31.0 23 commit 后未追加 v0.31 章节。R31 后应加 "v0.31 Apple Health 风格重设计" 章节列 23 commit + Spring 0 caller 半成品状态 + R108 P0-001/002/P1-001/003 漏闭环
- **CHANGELOG**: 跑了 — Round 13 (4ebec68) commit message 写 "CHANGELOG 0.31.0 + pubspec 0.31.0+107 (Apple Health 风格重设计收尾)", 但需跑 `python scripts/check_changelog.py` 验证 (py 不可用, 仅 git log 确认)
- **spec 文档**: `docs/audit/2026-08-11-cleanup/00-spec.md` §"跑前 baseline 锁定" 写 "净改善 +66 pass / -1 fail" 跟实际 +1/-1 矛盾, 建议 spec 作者重新跑 `flutter test` 锁定 baseline 数字
- **R12b test 文件**: `test/presentation/apple_health_phase4_global_sanity_round12_test.dart` 4/4 pass ✅, 但 grep-based 验证 = 单元覆盖薄弱, R109 应加 widget test 真测 (Phase 5)

## 总结

**emil 设计工程视角 R31 评分 8.5/10 (跟 R108 持平)**: 4 件套 token 集中化 (app_colors/typography/spacing/motion) + 8 metric palette + ultralight w200 大数字 + ALL CAPS section header + iOS hairline 0.5 divider + 0 阴影 = Apple Health 视觉签名 95% 到位, 跟 R108 整合 "mature" 评级一致。**但是**: (1) Spring 物理模型 + 2 Apple cubic-bezier **0 caller 死代码** (R4 半成品) + (2) **R108 P0-001 5 大上架前 P0 + P0-002 FadeIn 500ms + P1-001 7 处 raw IconButton + P1-003 硬编码中文 0 闭环** + (3) v0.31.0 R11a 自我引入 4 处硬编码中文 + 1 处 `Colors.white` + 1 处新漏 IconButton 包装, **新引入问题抵消了 token 化改善**。**R109 闭环建议**: 1 周内清 5 个 P0 (A/B/C/D/E) + 2 个 P1 死代码删除 (A/B), ROI 极高 (Apple Health 视觉全清 + 上架前 P0 一次性闭环), 闭环后回 9.0/10。
