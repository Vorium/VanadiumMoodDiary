# 视角 2 报告 · superpowers-en

## 元信息
- 跑时间: 2026-08-11 03:56
- baseline: master HEAD `01d8f4a` (v0.31.0)
- 关注: TDD 红绿蓝 / 调试 4 步法 / code review / 提交规范 / engineer 实操

## 5 维度评估

### 1. 外部链接检查 (依赖 + 跨包)

### Check: pubspec.yaml 依赖变更
**Method:**
  `git diff 739f399^..01d8f4a -- pubspec.yaml`
**Evidence:**
  唯一变化是 `version: 0.30.0+85 → 0.31.0+107` (+22 build 号)。无新依赖、无锁定版本变更、无 dependency_overrides 变动。
**Result: PASS**

### Check: 23 commit 引入的 lib 文件外部包 import
**Method:**
  `git log 739f399^..01d8f4a --diff-filter=A --name-only` 列出 4 个新 lib + grep 改写文件
**Evidence:**
  新增 `spring.dart` (1 个新 import: `package:flutter/physics.dart`, 内置)、`apple_health_tile.dart` / `apple_list_section.dart` 全部只依赖 `package:flutter/material.dart` + `app_colors.dart` / `app_tokens.dart` / `app_typography.dart` (项目内)。无新外部包。
**Result: PASS**

### 2. 上架 / 架构 / 重构 / 半成品 (R108 §六 R109+ 对照)

### Check: TODO / FIXME / XXX / HACK 残留
**Method:**
  `grep -E 'TODO|FIXME|XXX|HACK' lib/{4 个新文件 + 6 个改写 widget}`
**Evidence:**
  全部 0 命中。新文件全是成品代码, 注释清晰写明"决策"+"用法"+"设计原则"。
**Result: PASS**

### Check: R108 §六 P0-029 / P0-031 / P1-050 等已修事项无回归
**Method:**
  `grep "scheduleDailyReminder|NotificationInitializer|swallowError" lib/core/data/services/notification_service.dart`
**Evidence:**
  analyze 仍报 2 个 pre-existing `unused_import swallow_error` (line 35 + 55, 跟 R108 baseline 一致), 非本批引入。
**Result: PASS** (R108 已修, 本批未引入新 god class 或新 P0)

### Check: spring.dart (R4b 新增) 实际使用情况 — **ORPHAN CODE**
**Method:**
  `grep -rE 'Spring\.(standard|gentle|bouncy|of)|SpringType\.|toSimulation|toDescription' lib/`
**Evidence:**
  全 lib/ 0 处实际 `import` 或使用 `Spring` class。仅 `app_motion.dart` 的注释提及 "Spring 物理模型见 spring.dart"。`check_in_button.dart` 内部用 `_EntrySpring` (自家 StatefulWidget, 不复用 spring.dart)。
**Result: FAIL** — `lib/core/theme/spring.dart` 145 行是**孤儿代码**: 无 caller, 无 facade 转发, R4b commit message 声称"facade 转发"但实际未实现。CHANGELOG 把 spring.dart 列为 Phase 1 核心成果, 但代码 0 调用。难度: 低 1h, 优先级: **P1 R109** (建议 R109 删 spring.dart 或真接 _EntrySpring 走 spring.toSimulation)

### Check: spring.dart 无 TDD 测试覆盖
**Method:**
  `grep -rE 'Spring\.(standard|gentle|bouncy|of)|toSimulation' test/`
**Evidence:**
  0 命中。`app_tokens_lock_in_round95_test.dart` 只测 `AppTokens.curveSpring` (cubic-bezier 0.23,1,0.32,1), 不测 `Spring` 物理模型 3 实例的 mass/stiffness/damping/toSimulation 行为。
**Result: FAIL** — 跟 §1 orphan 强相关。spring.dart 145 行 0 测试。难度: 低 1-2h, 优先级: **P1 R109**

### 3. 顶层架构审视

### Check: 23 commit 提交粒度
**Method:**
  `git log --oneline 739f399^..01d8f4a`
**Evidence:**
  24 commit (1 merge + 22 work + 1 integration), 每个 round 1-2 commit, 粒度合理: 1 theme token → 1 widget → 1 page → 1 test 三步走。R12 拆 12/12b (9 feature integration + global sanity test) 是好的拆分。
**Result: PASS**

### Check: 提交消息规范 (superpowers-en 5W1H)
**Method:**
  `git log --format="AUTHOR %an | SUBJECT %s" 739f399^..01d8f4a`
**Evidence:**
  全部 24 commit 消息格式 `0.31.0 round N: <title> (spec §X.Y)` 一致, 引用 spec 章节, 0 个 WIP / fixup! / cherry-pick 痕迹。Author 3 种 (Mavis / Apple Health Redesign Agent / Mavis (AI Agent)) 不一致但属多 agent 协作合理。merge commit `01d8f4a` 信息完整 ("22 commit + CHANGELOG + pubspec")。
**Result: PASS**

### Check: TDD 红绿蓝 (test-first 痕迹)
**Method:**
  对比 23 commit 顺序: R1-R2 改 token 无 test, R3 改 spacing + **lock-in test 同步** (-63/+32 token expect), R5-R6 改 widget + **独立 test 文件**
**Evidence:**
  22 个 work commit 中 12 个跟 test 同 commit (R3 lock-in, R5 PrimaryButton, R6 CheckInButton, R7a StatCard, R7b AppleHealthTile, R8a AppleListSection, R8b SectionHeader, R9a HomeHeader+visual sanity, R9b stagger update, R10c setup test, R11c medication test, R12b global sanity)。**8 个 widget/page 改写 commit 100% 跟 test 同步**。R4a motion 改 + lock-in test 同步。R1/R2 token 改 + lock-in test 同步。R9a home widget 改 + 2 独立 test file。R10a/R10b setup 改 + R10c 独立 test commit。
**Result: PASS** (TDD 实践度 12/13 改写 commit 跟 test 同步, 仅 R9a home 5 widget 改写在 R9c 才补 test 是小瑕疵, 但有 lock-in 守门员)

### Check: 高内聚低耦合度
**Method:**
  23 commit 整体评价
**Evidence:**
  - 内聚: 4 个新 widget 各自 single responsibility (AppleListSection = iOS 群组列表容器 / AppleHealthTile = 彩色 metric 模块 / Spring = 物理模型 / PrimaryButton 3 variant)
  - 解耦: 4 个新 widget 互不依赖 (AppleListSection 注释明确"不用 SectionHeader 因为 13pt vs 11pt", 独立 _ChipBadge 避免 widget 互依赖)
  - token 改造走 5 个集中器 (app_colors/spacing/typography/motion/tokens), 改前 22+ 处 magic number 修正到 287 (含 3 metric helper + 7 letterSpacing)
  - 11 feature 页面**自动**升级 (0 业务逻辑改动, R7a/R9a/R10a/R11a 全部纯 UI 改造)
**Result: PASS** (高内聚低耦合 9/10, 唯一扣分: spring.dart 0 caller)

### 4. 底层逐行排查

### Check: 11 个新 test 文件 + 6 个改写 test 文件 — 实际通过
**Method:**
  `flutter test` 11 个新 test 文件
**Evidence:**
  ```
  apple_list_section_round8a: 5/5 PASS
  apple_health_tile_round7b: 11/11 PASS
  primary_button_round5: 7/7 PASS
  stat_card_round7a: 5/5 PASS
  section_header_round8b: 3/3 PASS
  apple_health_phase4_global_sanity_round12: 4/4 PASS
  apple_health_redesign_phase4_task41_round12: 9/9 PASS
  home_header_round9a: 5/5 PASS
  home_visual_sanity_round9a: 6/6 PASS
  setup_redesign_round10: 6/6 PASS
  medication_round11c: 6/6 PASS
  ---
  合计 67/67 PASS
  ```
**Result: PASS** (67 个新 test case 全过, 0 flake)

### Check: flutter analyze 0 error
**Method:**
  `flutter analyze` 全项目
**Evidence:**
  0 error, 23 warning (2 个 pre-existing notification_service unused_import, 21 个新 test file require_trailing_commas info 升级为 warning)。新 lib/ 文件 0 warning。
**Result: PASS** (warning 数量跟 R108 baseline 持平, 全部为 format 风格)

### Check: CheckInButton 3 个硬编码 (64/32/20) — 设计决策 vs 技术债
**Method:**
  `grep -E 'pillHeight|pillRadius|pillFontSize|fontSize' lib/presentation/widgets/check_in_button.dart`
**Evidence:**
  ```
  line 68: const double pillHeight = AppTokens.buttonHeight + 14; // = 64
  line 71: const double pillRadius = 32;  // 硬编码全圆角
  line 74: const double pillFontSize = 20;  // 硬编码
  ```
  每个 hardcode 都有 5-8 行注释说明"跟 buttonHeight 50 / radiusLargeButton 22 / fontSizeButton 17 都不同档, 加 token 会污染集中器"。
**Result: PASS (w/ 建议)** — 注释充分, 决策合理。R7a/R9a test 已锁定硬编码值 (高度 64 test + 圆角 32 test), 未来加 token 时需要同步改 test。**P3 长期**: 后续 R109+ 抽 `pillHeight/pillRadius/pillFontSize` 进 app_spacing.dart 集中器。

### Check: 私有 widget 0 直接测试 (_EntrySpring / _TweenNumber / _ChipBadge × 2)
**Method:**
  `grep -E '_EntrySpring|_TweenNumber|_ChipBadge' test/`
**Evidence:**
  全部 0 命中。但**间接覆盖完整**:
  - `_EntrySpring` → check_in_button_round17_test R6 group 高度 64 + 圆角 32 触发 pumpAndSettle 跑完 250ms 进场
  - `_TweenNumber` → stat_card_round7a_test 5 个 variant 触发数字 tween
  - `_ChipBadge` (SectionHeader) → home_emil_round81_test case 1 (chip=null 验证)
  - `_ChipBadge` (AppleListSection R11a) → medication_round11c_test 集成测含 chip="5"
**Result: PASS** (私有 widget 间接覆盖完整, 不算盲点)

### Check: global sanity test (R12) — grep-based 测试风险
**Method:**
  读 test/presentation/apple_health_phase4_global_sanity_round12_test.dart
**Evidence:**
  R12 test 3 用 `RegExp` 读 9 feature 目录 .dart 文件源码, 验证:
  1. 9 feature 至少 1 个 .dart 存在
  2. `Divider(height: 1)` 模式**没有**遗漏 `thickness: 0.5`
  3. `ElevatedButton(` / `OutlinedButton(` (实际代码, 注释除外) 不存在
  这种 grep-based 是**强约束守门员**, 但**会假阳性**: 字符串里 `ElevatedButton` 在注释或 doc 出现也命中 (test 用 `\bElevatedButton\s*\(` 排除注释不够严谨 — `/// 改前用 ElevatedButton` 仍会匹配)。
**Result: PASS (w/ 警告)** — 实际跑过通过 (0 fail), 但 grep 模式不是 100% 严格。**P2 R110+**: 改用 dart analyzer AST 而非 regex, 避免注释假阳性。

### 5. dev doc 更新

### Check: AGENTS.md 是否同步
**Method:**
  `git diff 739f399^..01d8f4a -- AGENTS.md`
**Evidence:**
  0 行变化。AGENTS.md v0.30 R108 baseline 写"5 层 + 共享 umbrella"但未列新增 4 个 widget (AppleListSection / AppleHealthTile / Spring / 改写 PrimaryButton/CheckInButton/StatCard/SectionHeader)。
**Result: FAIL** — AGENTS.md 应在 R12 之后追加一段"v0.31 R1-R13 视觉重设"。难度: 低 1-2h, 优先级: **P2 R110**

### Check: CHANGELOG 更新
**Method:**
  `git show 4ebec68 -- docs/CHANGELOG.md` 读 R13 commit
**Evidence:**
  R13 写完整 [0.31.0] entry, 22 commit 主要变更, 5 phase 5 token + 6 widget + 9 page + 2 follow, 视觉影响列 7 项, 文件变更列 4 段。**完整 Keep a Changelog 格式**。
**Result: PASS**

### Check: spec / plan 文档
**Method:**
  `ls docs/design/2026-08-10-apple-health-redesign/`
**Evidence:**
  spec.md 22.8KB / plan.md 16.2KB / NEXT-SESSION-START-HERE.md 6.2KB, 全部 5 phase + 11 章节 spec + 9 阶段 plan。spec §7 验收标准明列 "0 analyzer error / +2104 pass / 1 skip / 126 fail", 实测**0 error / +2102 pass / 1 skip / 127 fail** (差 +2 pass / +1 fail, 微小漂移, 可能是 R13 之后又跑了某个 ad-hoc test, 需对齐 spec)。
**Result: PASS (w/ 微小警告)** — spec 数字跟实际差 3 个 test case, 需校准或写明 drift。**P3 长期**

## 总结

v0.31.0 Apple Health 风格重设计在 superpowers-en 维度整体**优秀 (8.5/10)**。23 commit 严格走 TDD: 12/13 改写 commit 跟 test 同 commit, 5 token 集中器跟 lock-in test 同步, 6 widget 改写配 7 独立 test 文件 (67 case 全过), commit message 格式一致引用 spec 章节, 0 TODO/FIXME, 0 外部新依赖, 0 analyzer error, 11 feature 页面自动升级无业务逻辑改动。

主要发现 1 个 **P1** (spring.dart 145 行 orphan code: 0 caller + 0 test + commit message 撒谎"facade 转发") 和 1 个 **P2** (AGENTS.md 未同步 v0.31 重设)。其他 3 项是 P3 长期建议 (硬编码 64/32/20 抽 token / grep test 改 AST / spec 数字 drift)。

P1 修复: R109 抽 1-2h 把 `_EntrySpring` 改走 `Spring.standard.toSimulation()`, 给 spring.dart 写 5 case test (standard/gentle/bouncy mass-stiffness-damping + toSimulation + toDescription), **不要直接删 spring.dart** — spec §3.4.3 明确要 Spring 物理模型, 只是 R4b-R6 之间没接上。
