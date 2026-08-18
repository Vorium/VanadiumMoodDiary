# 整合总览表（v0.23 round 42）— 三视角 + 顶层架构

> **作者**：Mavis（root orchestrator）
> **基线**：v0.22 round 30 三份报告（emil 41 / spen 123 / spzh 64 = 228 项）+ v0.23 round 42 三份 worker 报告（emil 23 / spen 15 / spzh 62 = 100 项）+ owner 顶层架构审视
> **目的**：把 4 个视角（emil / spen / spzh / owner）合并成一张**可执行的**总览表（按 skill / 架构 vs 底层 / 修复难度 / 优先级）
> **状态**：完成
> **生成时间**：2026-07-24 13:00

---

## 0. Worker 报告交付

| 视角 | 报告 | 总问题 | P0 | P1 | P2 | P3 | 关键判断 |
|---|---|---|---|---|---|---|---|
| **emil** | `docs/reviews/v0.23/review_emil_round42.md` (558 行 / 46.5KB) | 23 | **0** | 1 | 11 | 11 | V+ 级别成熟项目；5 抽取 widget 全落地；token 化 99%；**71% P1 修完** |
| **superpowers-en** | `docs/reviews/v0.23/review_superpowers_en_round42.md` (1057 行 / 62.5KB) | 15 | **1** | 5 | 6 | 3 | **P0 regression**: app_router mojibake 修不完整；85% 剩余工作可 subagent 并行；TDD domain 100% / data 扩展 / presentation 欠账 |
| **superpowers-zh** | `docs/reviews/v0.23/review_superpowers_zh_round42.md` (660 行 / 61KB) | 62 | **21** | 30 | 9 | 2 | **round 30 修复率仅 13.6%（3/22 修）**；5 厂商 push / 法律文档 / version 0.22→0.23 / CHANGELOG / tag / 5 个"假完成"反模式 |
| **owner** | `docs/reviews/v0.23/_top_level_architecture_round42.md` (18.3KB) | 8 架构选项 + 5 god class | 0 | 5 (god class) | 3 (A/B/E) | 5 (D/F/G/H) | **架构健康度 9/10**；高内聚低耦合 100% 守住；最大弱点 = 单文件过大 |
| **合并去重** | `docs/reviews/v0.23/_integration_overview_round42.md`（本文件） | **~100** | **~22** | **~36** | **~27** | **~18** | 4 视角合并；P0 全是 round 30 已列但未真修 + spen 1 个 P0 regression；P1 集中清理 1 round 可消化大部分 |

---

## 1. 总览统计

| Skill | 总问题 | P0 | P1 | P2 | P3 |
|---|---|---|---|---|---|
| emil | 23 | 0 | 1 | 11 | 11 |
| superpowers-en | 15 | 1 | 5 | 6 | 3 |
| superpowers-zh | 62 | 21 | 30 | 9 | 2 |
| owner（顶层架构） | 13（8 架构 + 5 god class） | 0 | 5 | 3 | 5 |
| **去重合并** | **~100** | **~22** | **~36** | **~27** | **~18** |
| 重复项 | （A-05 ≈ owner C、5 个 god class 跟 spen 9 重复） | | | | |

**关键观察**：
- **emil 视角认为"成熟项目"，0 P0** —— 12 round 连续打磨让 token 化 + 抽取 widget 接近天花板
- **spen 视角找到 1 个 P0 regression** —— round 31 P0-1 修的 app_router mojibake 只修了 6 行注释块，文件其余 30 行仍存在 PUA 字符
- **spzh 视角找到 21 个 P0** —— 几乎全是 round 30 报告已列但 12 round 没真修的合规 P0 + 3 个新发现的 P0（pubspec 0.22+2 / CHANGELOG / tag / zh_Hant 简体副本）
- **owner 视角**：架构健康，但有 5 个 > 500 行 god class 需拆分

---

## 2. P0 必修清单（22 项，按"架构 vs 底层"分类）

### 2.1 架构层面 P0（顶层 / 跨模块 / 上架阻塞性）

| ID | Skill | 标题 | 位置 | 修复难度 | 关键阻塞 |
|---|---|---|---|---|---|
| **A-01** | spzh | 3 份法律文档 v0.22 草稿升级到 v0.23 + 律师外审 | `assets/legal/{privacy_policy,user_agreement,sensitive_data_consent}.md:3` | large(8-16h, 律师) | store 上架阻塞 |
| **A-05** | spzh / owner C | 5 厂商 push 通道架构化（HMS / MIPush / OPPO / vivo / 魅族） | `pubspec.yaml:18-58`<br>`notification_service.dart:1` | xlarge(80-120h) | 90% 国产 ROM 用户杀进程后 0 通知 |
| **B-01** | spzh | `app_zh_Hant.arb` 是简体副本（跟 `app_zh.arb` diff 1 行）—— **典型"假完成"反模式** | `lib/l10n/app_zh_Hant.arb` | medium(6-8h, 569 keys 繁简转换) | 繁体用户显示简体（命名误导） |
| **F-01** | spzh | CHANGELOG.md 缺 v0.23 章节（13 commit 0 条目） | `docs/CHANGELOG.md:5-477` | medium(4-6h) | 法务 / 用户无法追溯 v0.23 变更 |
| **F-04** | spzh | tag 缺 v0.18-0.23（6 个 minor 全无） | `git tag -l` | small(1h) | store 上架版本号无法对齐 git tag |
| **spen-1** | spen | `app_router.dart` mojibake 修不完整（30 行 / 上百 PUA 字符仍存在）| `lib/core/routing/app_router.dart:30+` 20+ 行 | trivial(30 分钟) + `check_no_pua.py` 守护(30 分钟) | grep / IDE 误导 |

### 2.2 底层 P0（单文件 / 单行 / 版本号 / 命名）

| ID | Skill | 标题 | 位置 | 修复难度 | 关键阻塞 |
|---|---|---|---|---|---|
| **A-02** | spzh | 隐私政策 §3 仍"用户姓名"（§1 修了 §3 漏修） | `assets/legal/privacy_policy.md:60` | trivial(0.1h) | PIPL §6 告知矛盾 |
| **A-03** | spzh | 隐私政策 §1 设备信息矛盾 | `assets/legal/privacy_policy.md:38` | trivial(0.3h) | PIPL 告知真实性 |
| **A-04** | spzh **NEW** | `pubspec.yaml:4` + `app_zh.arb:89` version 仍 0.22.0 → **PIPL §14 同意记录失去法律效力** | `pubspec.yaml:4`<br>`lib/l10n/app_zh.arb:89`<br>`lib/l10n/app_en.arb:74`<br>`lib/l10n/app_localizations_{zh,en}.dart:222/229` | trivial(0.2h) | store 上架版本号不一致 |
| **E-01** | spzh | `settingsAboutVersion` v0.22.0 → v0.23.0（B-01 修复后又复发） | `lib/l10n/app_zh.arb:89` | trivial(0.2h) | store 用户看 v0.22 误导 |
| 待填 | emil | （emil 0 P0） | | | |
| 待填 | owner | （owner 0 P0） | | | |

### 2.3 P0 必修工作量

- **不含 push 通道**：6 项架构 + 5 项底层 = 11 项，总耗时 **21-37h**（含律师外审 8-16h）
- **含 push 通道**：**101-157h（12-20 工作日）**
- **必杀点**：A-01（律师外审）+ A-05（5 厂商 push 接入）+ F-01+F-04（CHANGELOG+tag） = 4 项 store 上架阻塞

---

## 3. P1 应修清单（36 项，重点项）

### 3.1 架构层面 P1（顶层 / 跨模块）

| ID | Skill | 标题 | 位置 | 修复难度 |
|---|---|---|---|---|
| **owner god 1** | owner | 拆 `mood_dialog.dart` 797 行 | `lib/presentation/pages/mood/mood_dialog.dart` | medium(4-8h) |
| **owner god 2** | owner | 拆 `settings_page.dart` 688 行 | `lib/presentation/pages/settings/settings_page.dart` | medium(4-8h) |
| **owner god 3** | owner | 拆 `assessment_history_page.dart` 624 行 | `lib/presentation/pages/assessment/assessment_history_page.dart` | medium(4-8h) |
| **owner god 4** | owner | 拆 `trend_charts.dart` 595 行 | `lib/presentation/pages/trend/trend_charts.dart` | medium(4-8h) |
| **owner god 5** | owner | 拆 `edit_medication_dialog.dart` 397 行 | `lib/presentation/pages/medication/widgets/edit_medication_dialog.dart` | medium(4-8h) |
| **spen-mood** | spen | 拆 `mood_dialog.dart` 868 行（4×） + mood_dialog dispose 顺序串行化 | `lib/presentation/pages/mood/mood_dialog.dart:1-868` | large(8-16h) |
| **spen-2** | spen | 抽 `core/data/privacy/encrypted_audio_storage.dart` 基类（vent + mood 共享） | `core/data/services/{vent,mood}_audio_storage.dart` | small(4h) |
| **A-06** | spzh | 隐私政策 "健康数据" → "健康记录" | `assets/legal/privacy_policy.md:36` | small(0.5h) |
| **A-07** | spzh | DEPLOYMENT.md L155-157 残留敏感措辞 | `docs/DEPLOYMENT.md:155-157` | trivial(0.5h) |
| **A-08** | spzh | DEPLOYMENT.md §5 仍声明"非医疗器械"（法务确认） | `docs/DEPLOYMENT.md:184-185` | small(1h) |
| **B-04** | spzh | 失联阈值 36h → UI 可配 | `lib/domain/logic/care_engine.dart:103` | small(2h) |
| **B-05** | spzh | 农历 / 24 节气 / 节假日 streak 跳过 | `lib/domain/logic/streak_calculator.dart` | medium-large(8-12h) |
| **D-01** | spzh | AGENTS.md 加"P0 / 新 feature 必须先 brainstorming"硬性规则 | `AGENTS.md:122-138` | small(1h) |
| **D-02** | spzh | AGENTS.md + workflow-runner YAML（`docs/plans/v0.24.md`） | `AGENTS.md` 整文件 | medium(4-6h) |
| **emil P1-01** | emil | H-01 + H-03 + H-04 集中清理 7 处（PressFeedbackIconButton / LoadingTextButton / PageTransitionSwitcher 落地） | `home_header.dart:40-63` 等 7 处 | trivial(1.5h) |

### 3.2 底层 P1（单文件 / 单函数 / bug fix / 标点 / a11y / i18n）

| ID | Skill | 标题 | 位置 | 修复难度 |
|---|---|---|---|---|
| **B-03** | spzh | 邮件 / SMS 模板 hardcode 中文 | `lib/core/l10n/strings.dart:17-35` | small(1h) |
| **C-01** | spzh | `check_fullwidth_punctuation.py` ASCII_PUNCT 扩展（`/` `…` 等 7+ 种） | `scripts/check_fullwidth_punctuation.py:28` | trivial(0.5h) |
| **C-02** | spzh | `app_zh.arb` 11+ 处半角 `/` → 全角 | `app_zh.arb:67,88,166,185,249,272,286,316,488,556,569` | small(1h) |
| **C-03** | spzh | `app_zh.arb` 4+ 处半角 `…` → 全角 `……` | `app_zh.arb:236,388,425,438` | trivial(0.3h) |
| **C-04** | spzh | 您/你 统一（精神心理 App 应统一"您"） | `app_zh.arb:34 vs 617` | small(1h) |
| **E-04** | spzh | 您/你 不统一 | `app_zh.arb:34 vs 617` | small(1h) |
| **E-07** | spzh | 邮件 / SMS 模板 hardcode 中文 | `lib/core/l10n/strings.dart:17-35` | small(1h) |
| **F-02** | spzh | CHANGELOG.md 顺序错乱（v0.16 段在最后） | `docs/CHANGELOG.md:288-479` | small(1h) |
| **F-03** | spzh | CHANGELOG.md v0.16 段位置错乱 | `docs/CHANGELOG.md:479-585` | trivial(0.5h) |
| **spen-3** | spen | `care_strategies.isLateCheckInHabit` off-by-one（`> 3` 改 `> 2`）+ isolated test | `lib/domain/logic/care_strategies.dart:20` | trivial(2h) |
| **spen-4** | spen | `mood_audio_service` 3min auto-stop 依赖 page callback（强制 `unawaited(stopRecording())`）+ isolated test | `lib/core/data/services/mood_audio_service.dart:240-246` | small(1h) |
| **spen-5** | spen | `mood_audio_storage.encryptAndWrite` try/finally 漏（跟 vent round 22 P1 同款回归） + regression test | `lib/core/data/services/mood_audio_storage.dart:80-105` | small(1.5h) |
| **spen-6** | spen | `home_page._fireCareEngine` DateTime race（用打卡 `at` 而非 `DateTime.now()`） | `lib/presentation/pages/home/home_page.dart:354` | small(1h) |
| **spen-7** | spen | `mood_dialog` dispose 顺序（5 个 async cleanup 串行化） | `lib/presentation/pages/mood/mood_dialog.dart:111-156` | small(2h) |
| **spen-8** | spen | `flutter test --coverage` + lcov badge | CI | small(2h) |
| **spen-9** | spen | golden test 引入（先 1 page 试点） | CI | medium(4-6h) |
| **spen-10** | spen | trend 整片 0 测 | `lib/presentation/pages/trend/*` 7 文件 | large |
| **spen-11** | spen | settings page 0 测 | `lib/presentation/pages/settings/*` 6 文件 | large |
| **spen-12** | spen | contact 0 测 | `lib/presentation/pages/contact/*` | large |
| 待填 | emil | （emil 0 个 P1 之外 = 11 个 P2 跟 11 个 P3） | | |

### 3.3 P1 应修工作量

- **架构 P1（5 god class + 6 spen god + 4 spzh 顶层）**：15 项，总耗时 **60-100h**
- **底层 P1（17 项 spzh + 10 项 spen）**：27 项，总耗时 **40-60h**
- **总计**：**100-160h（13-20 工作日）**

---

## 4. 按"架构 vs 底层"分类总览（用户特别要求）

### 4.1 架构层面（顶层设计 / 跨模块 / 跨 feature / 流程 / god class）

| # | Skill | 标题 | 修复难度 | 优先级 |
|---|---|---|---|---|
| 1 | spzh / owner C | **5 厂商 push 通道架构化** | xlarge(80-120h) | **P0** |
| 2 | spzh | 3 份法律文档 v0.22 草稿升级 + 律师外审 | large(8-16h) | **P0** |
| 3 | spzh | `app_zh_Hant.arb` 真繁简转换 | medium(6-8h) | **P0** |
| 4 | spzh | CHANGELOG 补 v0.23 章节 | medium(4-6h) | **P0** |
| 5 | spzh | 补 v0.18-0.23 tag | small(1h) | **P0** |
| 6 | spen | `app_router.dart` mojibake 30 行 + `check_no_pua.py` 守护 | trivial(1h) | **P0** |
| 7 | spen | 抽 `core/data/privacy/encrypted_audio_storage.dart` 基类 | small(4h) | P1 |
| 8 | owner god 1-5 | 拆 5 个 > 500 行 god class | medium(4-8h each) | P1 |
| 9 | spen-mood | 拆 `mood_dialog.dart` 868 行 + dispose 串行化 | large(8-16h) | P1 |
| 10 | spzh | AGENTS.md 加 brainstorming + workflow-runner 硬性规则 | medium(4-6h) | P1 |
| 11 | spzh | 失联阈值 36h → UI 可配 | small(2h) | P1 |
| 12 | spzh | 农历 / 24 节气 / 节假日 streak 跳过 | medium-large(8-12h) | P1 |
| 13 | spen | `core/data/services/notification_service.dart` 600+ 行拆 4 orchestrator | large(1w) | P3 (TODO) |
| 14 | spen | `core/data/services/data_export_service.dart` 560 行拆 4 service | large(3-5d) | P3 (TODO) |
| 15 | owner A | riverpod_generator 引入 | small(1d) | P2 |
| 16 | owner B | privacy 子包化 | small(4-6h) | P2 |
| 17 | owner D | application/ 中间层 | medium(8-12h) | P3 |
| 18 | owner E | widget library 子目录化 | small(2-3h) | P2 |
| 19 | spzh | workflow-runner YAML（`docs/plans/v0.24.md`） | medium(4-6h) | P1 |
| 20 | spen | 抽 `core/data/services/audio_recorder_service.dart` 基类 | medium(2-3d) | P2 |

### 4.2 底层层面（单文件 / 单函数 / 单行 / 命名 / 注释 / 标点 / 版本号）

| # | Skill | 标题 | 修复难度 | 优先级 |
|---|---|---|---|---|
| 1 | spzh | `pubspec.yaml:4` + `app_zh.arb:89` version 0.22.0 → 0.23.0 | trivial(0.2h) | **P0** |
| 2 | spzh | 隐私政策 §3 "用户姓名" → "用户昵称"（6 处） | trivial(0.1h) | **P0** |
| 3 | spzh | 隐私政策 §1 设备信息矛盾 | trivial(0.3h) | **P0** |
| 4 | spzh | `settingsAboutVersion` v0.22.0 → v0.23.0 | trivial(0.2h) | **P0** |
| 5 | spen | `care_strategies.isLateCheckInHabit` off-by-one | trivial(0.5h) | P1 |
| 6 | spen | `mood_audio_service` 3min auto-stop 强制 stopRecording | small(1h) | P1 |
| 7 | spen | `mood_audio_storage.encryptAndWrite` try/finally 修 | small(1.5h) | P1 |
| 8 | spen | `home_page._fireCareEngine` DateTime race | small(1h) | P1 |
| 9 | spen | `mood_dialog` dispose 顺序 | small(2h) | P1 |
| 10 | spzh | 11+ 处半角 `/` → 全角（`app_zh.arb` 7+ 处 + 半角 `:` 4+ 处） | small(1h) | P1 |
| 11 | spzh | 4+ 处半角 `…` → 全角 `……` | trivial(0.3h) | P1 |
| 12 | spzh | 您/你 统一 | small(1h) | P1 |
| 13 | spzh | `check_fullwidth_punctuation.py` ASCII_PUNCT 扩展 | trivial(0.5h) | P1 |
| 14 | spzh | 邮件 / SMS 模板 hardcode 中文 i18n 化 | small(1h) | P1 |
| 15 | spzh | CHANGELOG 顺序错乱 + v0.16 段错位 | small(1h) | P1 |
| 16 | spzh | DEPLOYMENT.md L155-157 残留敏感措辞 | trivial(0.5h) | P1 |
| 17 | spen | `data_export_service._validateDate` fallback DateTime 不一致 | trivial(0.5h) | P2 |
| 18 | spen | `trend_calendar._calendarMonth` stale field | small(1h) | P2 |
| 19 | emil | SeverityIndicator 4 档配色塌成 2 档（emil F1 二阶段） | trivial(5min) | P2 |
| 20 | emil | shadow token dark mode 反白失效（D-04 P2） | small(30min) | P2 |
| 21 | emil | 5 个 inline `AnimatedSwitcher` 改用 `PageTransitionSwitcher` | small(1.5h) | P2 |
| 22 | emil | vent_compose 3 态切换无 origin 锚定 | small(1h) | P2 |
| 23 | emil | mood 5 评分按钮"已选"态突变 | small(1h) | P2 |
| 24 | emil | `AppListTile` 集中器（5+ 处 ListTile 重复） | small(1.5h) | P2 |
| 25 | emil | medication_calendar 10 行 stagger cap 200ms | trivial(1 行) | P2 |
| 26 | emil | trend 视图切换 list↔calendar 无 fade | trivial(10 分钟) | P2 |
| 27 | emil | contact 添加入口缺 PressFeedback | trivial(5 分钟) | P2 |
| 28 | emil | assessment quiz → result 切换瞬时 | trivial(10 分钟) | P2 |
| 29 | emil | shadowCard/shadowOverlay token 命名奇怪 | trivial(30 分钟) | P3 |
| 30 | emil | fade_in / slide_up 用 AnimatedBuilder 而非 FadeTransition | small(30min) | P3 |
| 31 | emil | `radiusCell` / `radiusCellLg` 命名奇怪 | trivial(30 分钟) | P3 |
| 32 | emil | 30+ 处 `TextStyle(fontSize: token)` 改用 `textStyle*().copyWith()` | small(1h) | P3 |
| 33 | emil | 评分按钮 padding 硬编码 → token | trivial | P3 |
| 34 | emil | setup 3 勾选行瞬时切换 | small(1h) | P3 |
| 35 | emil | EncouragementText 跨 streak 文案无 fade | trivial(10 分钟) | P3 |
| 36 | emil | D-NEW-02 `medication_report_dialog.dart:162` `Colors.black54` 残留 | trivial(5 分钟) | P3 |
| 37 | emil | D-NEW-05/06/07 trend / calendar / mood Semantics 硬编码中文 | small(3h) | P3 |
| 38 | emil | D-NEW-04 `SizedBox(width: 6)` 硬编码 | trivial | P3 |

---

## 5. 按修复难度 分布

| 难度 | 工作量 | 总数（4 视角去重） | 代表性问题 |
|---|---|---|---|
| trivial | < 1h | ~25 | A-04 version / A-02 §3 / A-03 §1 / E-01 / spen-3 off-by-one / spen-1 mojibake 30 行 / C-01 / C-03 / C-04 / F-03 / F-05 / F-06 / F-07 / F-08 / emil 11 项 |
| small | 1-4h | ~40 | C-02 11+ 半角 `/` / F-04 补 tag / E-04 您你 / D-01 brainstorming 规则 / spen-2 privacy 基类 / 5 个 god class 拆分（owner 1-5）/ spen-4 / spen-5 / spen-6 / spen-7 / spen-8 / emil 9 项 |
| medium | 4-8h | ~25 | O-04 zh_Hant 真做 / F-01 CHANGELOG v0.23 / D-02 workflow-runner / 4 个 god class 拆分（owner 2-5）/ spen-9 golden test / emil 3 项 / C-05 Strings 参数注入 |
| large | 8-16h | ~10 | A-01 法律文档律师外审 / 国密 SM4 / 农历节气 / spen-mood 拆 mood_dialog / spen 600+ 行拆 4 orchestrator（notification_service）/ spen data_export 拆 4 service |
| xlarge | > 16h | 1 | A-05 / owner C 5 厂商 push 通道（同一项）|

---

## 6. 按"该 round 修" 排序（v0.24 Round 43 集中清理候选）

### Round 43 必杀点（P0 集中清理，预计 1-2 个 round，9-17h 不含 push）

按工作量从轻到重：

1. **A-04 + E-01** `pubspec.yaml:4` + `app_zh.arb:89` version 0.22.0→0.23.0（0.2h + 0.2h）—— **顺手做** + 加 CI 守门脚本（pubspec version 跟 app_zh.arb 一致性）
2. **A-02** 隐私政策 §3 "用户姓名" → "用户昵称"（0.1h，6 处替换）
3. **A-03** 隐私政策 §1 设备信息矛盾（0.3h）
4. **F-04** 补 v0.18-0.23 tag（1h，`git tag -a v0.X.0 -m ...` × 6 + push）
5. **spen-1** 修 app_router mojibake 30 行（30 分钟 grep + 替换 + 验证）+ 加 `scripts/check_no_pua.py` 守护（30 分钟）
6. **F-01 / F-02 / F-03** CHANGELOG 顺序修正 + 补 v0.23 章节（4-6h）
7. **C-01 / C-02 / C-03 / C-04** 中文文案规范 4 项集中清理（2-3h）
8. **A-01** 法务外审 3 份法律文档（**8-16h 大头，必须先做**）

### Round 44-48（P0 厂商 push 接入，分 5 个 round，80-120h）

1. Round 44: HMS 接入（华为开发者联盟 + 推送证书，xlarge 16-24h）
2. Round 45: MIPush 接入（小米，xlarge 16-24h）
3. Round 46: OPPO PUSH 接入（含 realme / 一加，xlarge 16-24h）
4. Round 47: vivo Push 接入（含 iQOO，xlarge 16-24h）
5. Round 48: 魅族 FlymePush 接入（medium-large 4-8h）

### Round 49-50（P1 集中清理，1 个 round 内消化）

- emil P1-01（H-01 + H-03 + H-04 集中清理 7 处，1.5h）
- spen-2 抽 `core/data/privacy/encrypted_audio_storage.dart` 基类（4h）
- spen-3/4/5/6/7 5 个 spen P1 bug fix（8.5h）
- spen-10/11/12 trend / settings / contact widget test 补全（2-3d）
- spzh B-04 失联阈值 36h 可配（2h）
- spzh D-01 / D-02 AGENTS.md superpowers-zh 流程硬性规则（5h）
- spzh B-03 邮件 / SMS 模板 i18n 化（1h）

### Round 51-52（P2 集中清理，1 个 round 内消化）

- owner 5 个 god class 拆分（mood_dialog / settings_page / assessment_history_page / trend_charts / edit_medication_dialog，5×4-8h = 20-40h）
- owner A riverpod_generator 引入（1d）
- owner B privacy 子包化（4-6h）
- owner E widget library 子目录化（2-3h）
- spen-8 / spen-9 flutter test --coverage + golden test（6-8h）
- emil 11 项 P2 polish（不可见细节 + 该加/删动画 + SeverityIndicator 4 档配色）
- spzh C-05 Strings 参数注入 + C-06 check_fullwidth ARB 扩展

### Round 53+（P3 nice-to-have / 长期债务）

- spzh F-08 / F-09 AGENTS.md 守护脚本清单准确化 + P2 review 流程加段
- spen-13 notification_service 拆 4 orchestrator（P3 TODO 1w）
- spen-14 data_export_service 拆 4 service（P3 TODO 3-5d）
- spen-15 AliyunSmsProvider 真实实现（P3 TODO 1-2w）
- owner D application/ 中间层（看 v0.24 业务复杂度）

---

## 7. 关键观察（4 视角合并）

### 7.1 emil / spen / spzh / owner 4 视角互补性

| 视角 | 强项 | 弱项 |
|---|---|---|
| **emil** | UI / 动效 / 组件设计 / token 化 | **不查 P0 必修**（仅看设计 feel） |
| **spen** | P0 regression / TDD / systematic-debugging / subagent 友好度 | UI / 文案 / 中文规范（不在视野） |
| **spzh** | 国内合规 / 法律 / 5 厂商 push / 中文 i18n / 文档 | 通用工程（不深入 systematic-debugging 6 类） |
| **owner** | 顶层架构 / god class / 高内聚低耦合 / 跨边界耦合 | 单文件 bug 细节 |

**4 视角完全互补**：emil 找 UI 问题，spen 找工程 P0，spzh 找合规 P0，owner 看架构。**1 个 round 集中清理 4 视角全 P0** 是 v0.24 round 43 的核心工作。

### 7.2 round 30 → round 42 12 round 进展

- ✅ **emil 维度**：token 化 90% → 99%；5 抽取 widget 全部落地；71% P1 修完；0 P0
- ✅ **spen 维度**：build job 上 CI（最大胜利）；TDD +142 cases；85% 工作可 subagent 友好；**但 1 个 P0 regression**（mojibake 修不完整）
- ❌ **spzh 维度**：**修复率仅 13.6%**（3/22 修，**86% 未修**）；5 厂商 push 仍 0；法律文档 0 升级；5 个"假完成"反模式
- ✅ **owner 维度**：架构健康度 9/10（守住）；高内聚低耦合 100%

### 7.3 round 30 报告 P0/P1 修复率（spzh 视角）

- **P0 修复率 20%**（0/5 全真修，1 项 T-11 ROM 7 品牌部分修，1 项 T-03 修复后又复发）
- **P1 修复率 18%**（2/11）
- **P2 修复率 0%**（0/5）
- **P3 修复率 0%**（0/1）
- **整体修复率 13.6%**（3/22）

**根因**：v0.23 round 38 P0 集中清理（commit `a45e821`）**只清理了 spen 报告提的 P0**（SMS fail-fast / safety_watch timeout / app.dart provider 复用），**完全没动 spzh 报告提的合规 P0**。这是"什么是 P0"的认知偏差：技术债 ≠ 合规债，**合规 P0 是上架阻塞性 P0**。

### 7.4 3 个新发现 P0（spzh 报告 round 30 没有的）

1. **A-04** `pubspec.yaml:4` version `0.22.0+2` 但项目 v0.23 → **PIPL §14 同意记录失去法律效力**（这是 B-01 修复后又复发的根因——v0.1→v0.22 修了，但 v0.22→v0.23 没续修）
2. **F-01 / F-04** CHANGELOG 缺 v0.23 章节 + tag 缺 v0.18-0.23（v0.23 round 38-42 13 commit 0 条目 / 0 tag）
3. **B-01** `app_zh_Hant.arb` 是简体副本（diff 仅 @@locale）—— 命名"stub"误导后续 review，**典型"假完成"反模式**

### 7.5 spen 1 个 P0 regression

**round 30 报告 P0-1 "app_router.dart mojibake 35 PUA 字符" → round 31 commit `6d659cd` 修不完整**：

- commit 只动了 L9-14（顶部 6 行注释块），`grep -P '[\x{E000}-\x{F8FF}]'` 实测仍命中 30 行
- 文件其余 20+ 行注释仍保留原始 GBK 二次编码状态
- 根因：没有任何 regression test 守护这次修复，所以"半修"也没人发现
- 修复：30 分钟找替换词 + 30 分钟加 `scripts/check_no_pua.py` CI 守护

### 7.6 顶层架构 9/10 健康（owner 视角）

- **4 层 + 5 umbrella + 跨 feature 守门 + 隐私边界 100%** —— 跨边界耦合 0 violation
- **最大弱点：单文件过大**（5 个 > 500 行 god class：mood_dialog 797 / settings_page 688 / assessment_history_page 624 / trend_charts 595 / edit_medication_dialog 397）
- **8 个可采用的更优架构选项**（按 ROI 排序）：A riverpod_generator / B privacy 子包化 / C push 通道架构化 / D application/ 中间层 / E widget library 子目录化 / F Drift→Isar（不做）/ G Freezed union / H BLoC（不做）
- **v0.24 推荐**：A + B + E（small 1-2 day 总投入，长期受益）

---

## 8. v0.24 立项 5 必做（spzh 报告附录 B + owner 整合）

1. **法务外审 3 份法律文档**（A-01，large 8-16h，**必须先做**）
2. **`pubspec.yaml` + `app_zh.arb:89` version 0.22.0 → 0.23.0**（A-04，trivial 0.2h，**加 CI 守门**）
3. **5 厂商 push 通道接入**（A-05，xlarge 80-120h，分 5 round）
4. **CHANGELOG 补 v0.23 章节 + 补 v0.18-0.23 tag**（F-01 / F-04，medium 5-7h）
5. **`AGENTS.md` 加 superpowers-zh 流程硬性规则**（D-01 / D-02，small 4-6h）—— brainstorming + workflow-runner 入口

---

## 9. 给用户的 1 句话总结

> **v0.23 round 42 整体质量守住**（token 化 99% / 测试 845 全过 / 0 analyze error / 4 守护脚本绿 / build job 上 CI），**但 round 30 报告 86% P0/P1 未真修**（3/22 修），**4 视角新发现 22+ 个 P0 / 36+ 个 P1**，**最大风险仍是"5 厂商 push + 法律文档 + CHANGELOG+tag + 3 份法律文档"上架阻塞**，**v0.24 round 43 应做"合规 P0 单独立项 + 法务外审 + 5 厂商 push 接入"3 件事**，配套 brainstorming / workflow-runner 流程硬性规则。
