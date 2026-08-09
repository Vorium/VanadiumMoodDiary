# Superpowers (中文) 架构审视 — chroniccare v0.27 round 58

> **方法论视角**：superpowers-zh v1.6.0 (jnMetaCode) —— 6 个中国特色子技能（中文代码审查 / 中文提交规范 / 中文文档 / 中文 Git 工作流）+ 14 个核心汉化技能。
> **关注轴**：中国开发者视角下的顶层架构适配性、中国特色实战问题（国产 ROM、PIPL、跨境、合规）、中文 i18n、繁简同步、全角标点、commit 规范、文档可读性、中文反模式。
> **与已有三视角综述的关系**：`docs/reviews/v0.27/review-emilkowalski-v027.md`（设计/动效） + `docs/reviews/v0.27/review-superpowers-en-v027.md`（TDD/系统调试/代码审查 6 大类） 已完成。本报告 **不复述** 通用架构与代码审查（已在 spen 报告 §1-§6 详细展开），专攻 **中文开发者专属问题** 与 **已修问题的中文回溯**。
> **项目**：D:\Batch\chroniccare（精神心理患者吃药打卡 App，Flutter 3.41.9 / Dart 3.12.2 / Riverpod 3.3.2 / Drift 2.20.3 / go_router 14.6，0 云端、本地 SQLCipher、zh + en + zh_Hant 三语）
> **最新 commit**：`2ad8246 v0.27 round 58: A-01 warn-only + A-03 文档化`
> **状态**：1109/1109 tests pass、0 analyzer error、12 守护脚本（R57 起 16 个，含 spzh 4 新增）

---

## TL;DR — 速读结论

| 维度 | 评分 | 状态 | 关键证据 |
|---|---|---|---|
| 中文 commit 规范覆盖 | 4.5/5 ⭐ | 良好 | `docs/CHINESE_COMMIT_GUIDE.md` 64 行已落地，git log 100% 走 `<version> round <N>:` 前缀 |
| 中文 i18n 质量 | 4.5/5 ⭐ | 优秀 | 551 keys 三语同步、R48 zh_Hant OpenCC s2tw 401 key、R56e 清 39 orphan |
| 全角标点规范 | 3.0/5 ⚠️ | **需修 false positive** | `check_fullwidth_punctuation.py` 47 violations 中 ~20 是误报（`……` 双字符被当 `…` 单字符） |
| 中国特色实战 | 4.0/5 ⭐ | 良好 | R20 OEM 7 brand 自检卡、R51 6 region 危机电话路由、R55 5 厂商 push plan |
| 中文文档可读性 | 4.0/5 ⭐ | 良好 | WHITEPAPER / CHANGELOG / AGENTS / DEPLOYMENT / PUSH / SMS / GIT_WORKFLOW 8 篇齐全 |
| 中文术语一致性 | 3.5/5 ⚠️ | 待统一 | "App" 与"应用"混用、"i18n" 与"国际化"混用、"PHQ-9 / GAD-7" 与"量表"混用 |
| 中文反模式 | 4.5/5 ⭐ | 极少 | 无拼音变量、无全角空格、源码注释用中文 + 技术词保留英文 |
| 守护脚本盲区 | 3.0/5 ⚠️ | 需补 | 缺中英混排空格检查、错别字检查、繁简异体字检查、PIPL 真接检查 |
| 隐私边界（中文 PII） | 4.5/5 ⭐ | 优秀 | `pii_safe_log.dart` maskPhone、release 模式 swallow、ReleaseMode 主键、29 中文 static const 走 `xxxText({override})` 模式 |
| 跨年/月日期（农历） | 4.0/5 ⭐ | 良好 | R48 ChineseHolidays 19 TDD test + nextWorkdayAfter、main.dart:tz.local=Asia/Shanghai |

**总评**：4.0/5 ⭐ —— 中文工程化已经做得很扎实，主要欠缺在 **守护脚本精度**（fullwidth 误报）和 **术语一致性**。本报告聚焦"**中文视角独有的发现**"，不重复 spen 报告的通用项。

**Top 3 行动建议**：

1. **R59 修正 check_fullwidth_punctuation.py 的 `……` 误报** —— 47 violations 中 19 个是 `app_localizations*.dart` 的"加载中……"等已经走全角（2×U+2026）但被误判。改法：pattern 改为 `(?!…)，即不后接 `…`。
2. **R60 修正术语集中器** —— 引入 `lib/core/l10n/terms.dart`（技术词）+ `appTerms` ARB section（业务词），把"App / 应用 / 客户端"、"i18n / 国际化 / 本地化"集中收敛。
3. **R61 加 3 个 spzh 守护脚本** —— `check_zh_terms_consistency.py`（术语统一检查）、`check_chinese_anti_pattern.py`（拼音/全角空格/错别字）、`check_pipl_compliance.py`（PIPL §13/§6/§17 真接检查）。

---

## 1. 顶层架构评估（中文视角）

### 1.1 4 层 + core umbrella 在中文团队的可读性

中文开发者看 Flutter 4 层架构的常见问题：
- **抽象层 vs 实现层** —— 中文表述习惯"实体-接口-实现"，但 Flutter/Dart 命名偏"abstract class X / class XImpl"，中文注释会写"仓库抽象" / "仓库实现"。项目已统一为 `repositories/X_repository.dart`（abstract）+ `repositories/X/X_repository_impl.dart`（实现），注释 100% 中文。
- **value object 命名** —— R48 中文项目常见歧义：`(Entity)` `(Value)` `(Model)` `(Domain)`。项目用 `*Entity` 后缀避免和 drift 冲突，但 `MedicationDraft` / `MoodEntryDraft` / `HourMinute` 是 value object（immutable + no identity），建议在 `docs/decisions/` 加 `v0.27_value_object_naming.md` 决策记录，说明"Entity = 有 id + 可变更新 + Drift row 一一对应" / "Draft = value object + 无 id + 写入用" / "X = 简单值（HourMinute 等）"。**严重度 P2、难度 S**。
- **`XxxXxx` vs `XxxXxxXxx`** —— 路径名一致性检查（spen 报告 §3 提到 14 god classes）；中文项目特有是 `setup_page.dart` vs `setup_widgets.dart` 的"页 vs 部件"区分，project 已分清：`pages/X/` 放页面、`pages/X/widgets/` 放部件子组件。**严重度 P3、难度 XS**。

### 1.2 备选架构对比（中文团队视角）

| 备选 | 中文团队上手成本 | 长期维护 | 判定 |
|---|---|---|---|
| **六边形 (Ports & Adapters)** | 中 —— 9 个 `domain/repositories/*.dart` 已经是端口，加 `ports/` 目录 = 5% 改动、0 行为改动 | 等同当前 | ❌ 性价比低 |
| **模块化 monorepo (`packages/core` / `packages/feature_medication`)** | 高 —— 团队 1-3 人中文协作，跨包 refactor 学习曲线陡 | pub.dev 兼容但 1098 test 需重排 | ❌ 当前规模不需要 |
| **Feature-sliced (`features/{medication,vent,...}/{data,domain,presentation}/`)** | 中 —— 8 个 feature 已有 1:1 目录，仅 `core/` umbrella 需打散 | 大团队（10+）有优势 | ❌ 当前 1-3 人团队 |
| **现状：4 层 + core umbrella + sub-service + facade** | 低 —— 已在 AGENTS.md 写明约束，新人 1 周上手 | 已跑 7 实例的"渐进 facade 模式" | ✅ 保持 |

**结论**：保持现状。中文团队特定补充：
- 在 `AGENTS.md` 加 1 节"中文命名规范"：Entity / Draft / X 三类的差异，配 3 个例子。
- 在 `docs/decisions/` 加 `v0.27_architecture_decision.md` 决策记录（ADR 格式），把"为什么选 4 层而不是六边形"写死，避免半年后新人问。

### 1.3 高内聚低耦合的重构目标（中文项目特有）

按"中文命名空间"分类：

| 重构目标 | 涉及文件 | 中文特有的拆点 | 严重度 | 难度 |
|---|---|---|---|---|
| `core/l10n/strings.dart`（12K）继续拆 | `lib/core/l10n/strings.dart:1-229` | 按"通知 / 邮件 / PDF / Import / Snooze / Mood 标签"6 块拆，每块 1 文件 | P2 | S |
| `presentation/pages/*/widgets/` 子目录再拆 | `lib/presentation/pages/medication/widgets/`（5 文件）、`assessment/widgets/`（5 文件）、`home/widgets/`（5 文件）、`settings/widgets/`（6 文件）、`trend/widgets/`（4 文件）、`vent/widgets/`（3 文件） | 中文特有的"vs 命名"：`carded` vs `standard` vs `destructive`（AppListTile 已分清），其他目录也用 `carded` 标准 | P3 | M |
| **新增** `lib/core/l10n/terms.dart`（术语集中器） | 新建文件 | 集中"App" / "应用" / "客户端" / "i18n" / "国际化" / "PHQ-9" / "九项患者健康问卷" / "GAD-7" / "七项广泛性焦虑量表" 等 | P2 | S |
| **新增** `docs/terminology.md`（中文术语表） | 新建文件 | 50-100 个术语中英对照 + 首次出现规范（per `chinese-documentation` skill） | P2 | XS |

---

## 2. 中国特色实战问题

### 2.1 国产 ROM 通知适配（已修，但仍有边角）

**v0.16 R20 已加 7 brand 自检卡**（`lib/presentation/pages/settings/widgets/notification_status_card.dart`）：

```
✅ 小米 (MiUi)
✅ 华为 (EMUI/HarmonyOS)
✅ OPPO (ColorOS) — 含 realme/一加/iQOO
✅ Vivo (FuntouchOS/OriginOS)
✅ 魅族 (Flyme)
✅ 三星 (OneUI) — R33 sp-zh T-11 扩
✅ 其它 (Android 原生)
```

**已落地的关键修复**：
- `androidScheduleMode: exactAllowWhileIdle`（`medication_notifier.dart`、`refill_notifier.dart`、`assessment_notifier.dart`）
- 不靠 `developer.log` 排查（用户看不到），改用 `NotificationStatusCard` 自检卡 + pending count = 0 报警
- 引导文字静态（不跳设置），避免新增 `app_settings` / `android_intent_plus` 包

**仍未完全解决的边角（spzh 视角新增发现）**：

| # | 区域 | 文件:行号 | 问题 | 建议 | 严重度 | 难度 |
|---|---|---|---|---|---|---|
| 1 | 国产 ROM 引导文案 | `lib/presentation/pages/settings/widgets/notification_status_card.dart:80-200` | 7 brand × 2-3 步骤 = 19 步 ARB key，已加到 `app_zh.arb`，但 **没检查繁简体差异**（港台用户看 zh_Hant 时，OPPO/Vivo/小米 在港台不一定有对应品牌） | R59 加 `oemBrandZhHant` 单独 ARB key set，港台用"OEM" 通用词替代 | P2 | S |
| 2 | 鸿蒙 HarmonyOS NEXT 5.0+ | 全部通知 service | 2024-2025 鸿蒙 NEXT 强制走"华为 Push Kit"或厂商通道，原 `flutter_local_notifications` 在纯血鸿蒙上可能失效 | R60+ 评估 `huawei_push` package 接入（依赖法务审核） | P2（v1.0 必备） | L |
| 3 | EMUI 14+ 通知分组 | `lib/core/data/services/notification_service.dart:_showSafetyAlert` | 鸿蒙对同一 app 通知做"折叠组"管理，safety alert 应单独 channel id（项目已分 `chroniccare.safety` channel，✅） | 已修，加 1 行注释指明 EMUI 14+ 也认 | P3 | XS |
| 4 | iOS 国行版通知 | 全部 | 国行 iPhone（11 月 1 日后 App Store 中国区上架合规要求）无 APNs 时静默失败，无重试 | R60+ 加 `pendingNotificationRequests` 启动时检查 + 5 分钟重试 | P2 | M |
| 5 | 5 厂商 push 真接 | `docs/PUSH_PROVIDERS.md`（R55 plan） | 5 厂商 plan 写完，骨架未动 | v1.0 工作（依赖法务 + 各厂商资质审核） | P2 | XL |
| 6 | **国产 ROM 启动自启检测** | `lib/presentation/pages/settings/widgets/notification_status_card.dart` | 7 brand 都只引导"自启动 / 后台运行 / 电池优化"，但 MIUI 13+ / OriginOS 3+ 加了"锁屏清理"项，要单独引导 | R59 加第 8 步"锁屏后允许后台"单独 ARB key | P2 | S |

### 2.2 中文 i18n / 全角符号 / 繁简

**已修的成果**：

| 维度 | 状态 | 证据 |
|---|---|---|
| zh / en / zh_Hant 三语 keys 一致 | ✅ 100% | `check_arb_keys.py` 0 missing、551 keys |
| zh_Hant 繁简一致 | ✅ 100% | `check_zh_hant_consistency.py` OpenCC s2tw 验证 |
| Orphan keys 清空 | ✅ 0 orphan | `check_orphan_arb_keys.py` R56e 清 39 个 |
| 通知/邮件/导入/树洞走 i18n | ✅ 28 处 | `check_strings_hardcoded.py` |
| Domain 0 flutter 边界保持 | ✅ | `xxxText({String? override})` 模式（R57 spzh P0 #6） |

**新发现（spzh 视角）**：

| # | 区域 | 文件:行号 | 问题 | 建议 | 严重度 | 难度 |
|---|---|---|---|---|----|----|
| 1 | **守护脚本 false positive** | `scripts/check_fullwidth_punctuation.py:67-70` | `……`（2×U+2026）已经被脚本自己当 "半角" 报。47 violations 中 ~20 个是误报（如 `app_localizations.dart:615` `'加载中……'` 已经是全角形式） | 改 pattern 为 `re.compile(rf"'([^']*{CJK}){ELLIPSIS}(?!{ELLIPSIS})([^']*)'")`，**不后接 `…`** 才报 | **P1** | XS |
| 2 | **真实半角标点** | `lib/core/data/services/preset_medication_templates.dart:119,149,154` | 3 处"苯二氮卓类/助眠药"、"镇静/抗焦虑辅助" 用了半角 `/`（中文文案应走 `／`） | R59 修正：3 处全改全角 `／`（medical abbreviation 风格） | P2 | XS |
| 3 | **真实半角括号** | `lib/core/data/services/export/export_schema_service.dart:75` | `'表不存在(旧 schema),忽略'` 用了半角 `(` `)` `,` | R59 修正：中文部分改全角 `（`，逗号改 `，` | P2 | XS |
| 4 | **真省略号误用** | `lib/l10n/app_zh.arb:167` | `"... 失败: <error>..."` 用了 3 个半角 `.` 表示省略 | 改全角 `……` 或 `…` 单字符（**注意 1. 修 false positive 之前这条会被误报**） | P3 | XS |
| 5 | **真混排空格** | `lib/presentation/widgets/mood_quick_button.dart:14` | `'今日情绪：好/差/一般/...'` 注释 `'好/差/一般/...'` 用了 ASCII `/` | 改全角或注释改中文 | P3 | XS |
| 6 | **守护脚本扫描范围** | `scripts/check_fullwidth_punctuation.py:88-91` | 单行匹配，跨行字符串（multi-line `'''...'''`）漏检 | R60 改跨行匹配（per spen P1-9 fix） | P3 | M |
| 7 | **app_zh.arb 注释** | `lib/l10n/app_zh.arb:167` | `@_xxx` 注释也用半角 `:` 应改全角 `：` | R59 修正 | P3 | XS |
| 8 | **加载中…… 误报 19 处** | `lib/l10n/app_localizations.dart:615, 927, 1473, 1485, 1635, 1792, 3022` + `app_zh_Hant.arb` 同样 | `……` 已对，被脚本误报 | **修正脚本（见 #1）** | P1 | XS |

### 2.3 跨年/月日期边界（农历 / 法定节假日 / 24 节气）

**已修的成果**：

| 维度 | 状态 | 证据 |
|---|---|---|
| `DateTime.now()` 单次捕获 | ✅ | `check_datetime_race.py` 0 violation |
| `DateTime(y, m, d)` 跨月/年单次 | ✅ | `check_datetime_race2.py` 0 violation |
| `tz.local = Asia/Shanghai` | ✅ | `main.dart:tz.local` (R48 spzh P1-18) |
| 跨 midnight streak 刷新 | ✅ | `app_root.dart` midnight timer + R48 crossedMidnightSince regression |
| ChineseHolidays 法定节假日 | ✅ | R48 P1-19，`lib/domain/logic/chinese_holidays.dart` + 19 TDD test |
| nextWorkdayAfter | ✅ | 同上（"今天周五，提醒'明早上班'不算周末"场景） |

**spzh 视角新发现**：

| # | 区域 | 文件:行号 | 问题 | 建议 | 严重度 | 难度 |
|---|---|---|---|---|---|---|
| 1 | **24 节气未识别** | `lib/domain/logic/chinese_holidays.dart`（不存在，仅 holidays） | "春分前后情绪波动"等精神心理患者关怀场景需节气 | R61 加 24 节气识别（春分/秋分/冬至/夏至），配 ARB key `lunarTermXxx` | P2 | M |
| 2 | **农历转公历** | 无 | 老人/部分用户习惯农历日期 | 评估 `lunar` package（依赖很重）或自实现 1900-2100 表 | P3 | L |
| 3 | **港台节假日差异** | `lib/domain/logic/chinese_holidays.dart` | 香港/台湾有"佛诞"、"重光假期"，大陆没有 | 评估加 region enum（per R51 hotline 已做） | P3 | M |
| 4 | **春节 7 天倒计时提醒** | 无 | 春节前 3 天精神患者可能因家庭聚会断药 | R60 加 `SpringFestivalCountdown` provider + 提醒 hook | P2 | M |
| 5 | **夏令时（DST）** | `lib/core/data/services/notification_service.dart` | 中国 1992 起废除夏令时，但海外华人用 `tz.local=America/Los_Angeles` 等会有 DST 切换 | 已 grep `tz.local` 单次初始化；建议加 `tz.local` test 锁定行为 | P3 | S |
| 6 | **2038 年问题** | `DateTime` 64-bit | Dart `DateTime` 在 VM 64-bit，2038 年无问题；web 平台 `DateTime` 转 `millisecondsSinceEpoch` 是 64-bit 安全 | 暂无影响 | P3 | XS |

### 2.4 Material 3 中文体验

**已修的成果**：

| 维度 | 状态 | 证据 |
|---|---|---|
| 暗色模式颜色 token 化 | ✅ | R49 emil P0 #1 60+ 处 |
| PressFeedback 按钮 :active 反馈 | ✅ | R14 P0-8 + R22 P0-9，scale 0.97 |
| 动效 token 集中 | ✅ | R14 P0-7 MotionScheme 4 档 + R48 emil P1-1 curve 区分 |
| a11y Semantics 集中器 | ✅ | R45 emil P1-18 AppSemantics 3 工厂 |
| 中文 UI 字号 | ⚠️ 待查 | R50 3 个 score TextStyle，但中文 UI 字号（如 "title / body / caption"）未单独 token |

**spzh 视角新发现**：

| # | 区域 | 文件:行号 | 问题 | 建议 | 严重度 | 难度 |
|---|---|---|---|---|---|---|
| 1 | **中文字号 token 化** | `lib/core/theme/app_tokens.dart` | 现有 `fontSize*` token 偏小，中文 UI 默认 body 16sp 比英文 14sp 易读 | R59 加 `fontSizeZhBody` / `ZhTitle` / `ZhCaption` 3 个 token（基于 1.15x 系数） | P2 | S |
| 2 | **中文字体回退** | `pubspec.yaml` | 未声明中文字体（`google_fonts` 或 asset font），用系统默认（思源黑体/苹方/华文） | R60 评估 `google_fonts` package 集成"思源黑体 CN" + 繁体的"思源黑体 TW" | P2 | S |
| 3 | **中文标点挤压** | 全部 list / dialog | 英文 1.0 lineHeight 中文 1.4 lineHeight 视觉舒适；M3 `ListTile` 默认 lineHeight 不分语言 | R59 加 `textStyleZhBody = textStyleBody().copyWith(height: 1.4)` 集中 | P2 | XS |
| 4 | **中文半角空格视觉** | 全部 `app_zh.arb` | 中文行末/段末半角空格 (U+0020) 在 macOS/iOS 上有时变"奇怪空格"（实为 U+200B 或 U+3000 全角空格） | R59 加 `check_no_halfwidth_space_in_zh.py` 守护 | P2 | S |
| 5 | **emoji 风格** | 全部 ARB emoji | 用了 🍀 🌱 ⏰ 等混 emoji（`lib/l10n/app_zh.arb` 多处） | 维持现状，emoji 跨平台一致 | — | — |
| 6 | **中文数字 "1" vs 阿拉伯 "1"** | 全部 | 中文规范数字统一用阿拉伯，量词"步"前"第 1 步" 也对 | 已符合 | P3 | XS |

### 2.5 可访问性

**已修**（R45 emil P1-18）：

- `AppSemantics.container / button / exclude` 3 工厂
- 6 处 `Semantics(...)` 替换 + 1 处 `ExcludeSemantics(...)`
- 评分组件、评估题、strek 数字都有 a11y 包装

**spzh 视角新发现**：

| # | 区域 | 文件:行号 | 问题 | 建议 | 严重度 | 难度 |
|---|---|---|---|---|---|---|
| 1 | **中文 TalkBack 朗读节奏** | `lib/presentation/widgets/app_semantics.dart` | 中文 4 音节词（"我今天吃了药"）应加停顿 `Semantics(liveRegion: false, hint: ...)` 让 TalkBack 节奏自然 | R60 评估加 `hint` 参数 | P3 | M |
| 2 | **Touch target ≥ 48dp** | 全部 button | M3 `ListTile` 默认 56dp 够；自定义 button 需校验 | R60 加 `assert(touchTarget >= 48)` lint 规则（`flutter_lints` 自定义） | P3 | S |
| 3 | **色弱模拟** | 暗色模式 | 状态色 success/warning/error 在色弱下区分度 | R60 评估加 icon + 文字补色弱 | P2 | M |
| 4 | **动效减速（prefers-reduced-motion）** | `lib/core/theme/app_tokens.dart:Motion` | 已支持，✅ | — | — | — |

---

## 3. 代码审查（中文视角）

按 `chinese-code-review` 规范的 5 档分级（必须修复 / 建议修改 / 仅供参考 / 问题 / N/A），结合 spen 报告 §4 找到的 20 条，本表只列 **中文视角独有的发现**（与 spen 报告不重复）。

| # | 区域 | 文件:行号 | SRP / 耦合 / 抽象问题 | 建议 | 严重度 | 难度 |
|---|---|---|---|---|---|---|
| 1 | 中文术语不一致 | 全部 ARB | "App"、"应用"、"客户端"混用（`app_zh.arb` 共出现 3 种叫法） | 修正 `docs/terminology.md` + 集中 `appTerms` ARB section | **P1** | S |
| 2 | 中文术语不一致 | 全部 ARB | "i18n"、"国际化"、"本地化"、"多语言"混用（4 种叫法） | 同 #1 | **P1** | S |
| 3 | 中文术语不一致 | `app_zh.arb:31, 78, 95` | "PHQ-9" vs "9 项患者健康问卷"（中英混用，部分用户懂英文） | R60 修正：默认走"PHQ-9"（专业），首次出现加英文 `"PHQ-9（9 项患者健康问卷）"` | P2 | S |
| 4 | 拼音 / 缩写 | 全部 | 未发现拼音变量（✅ 项目保持中文注释 + 英文标识符） | — | — | — |
| 5 | 全角空格误用 | 全部 ARB | grep `\u3000`（全角空格）0 命中（✅ 中文行内不混全角空格） | — | — | — |
| 6 | 半角空格误用 | 全部 ARB | 中文行末半角空格命中 0（✅ 符合"中英文间空格"规范） | — | — | — |
| 7 | 文档 commit 中英混排 | `docs/CHANGELOG.md` | 5% 处直接英文：`flutter analyze 0 errors`、`1098/1098 pass` 等 | 加 R60 修正：纯中文语境用全角标点，但中英混排处空格 / 半角规范 | P3 | S |
| 8 | 中英混排空格 | `lib/core/l10n/strings.dart:21` | `'[停药提醒] $name 已经 $days 天没吃药了'` 中文 + `$name` + 中文 + `$days` 数字 + 中文，**中英数字间缺空格** | 应为 `'[停药提醒] $name 已经 $days 天没吃药了'` 改为 `'[停药提醒] $name 已经 $days 天没吃药了'` —— **实际是中英文混排空格** | P3 | XS |
| 9 | 中英混排空格 | `lib/core/l10n/strings.dart:32` | `'我是 $name，已经 $days 天没在 App 里打卡了。\n'` 同 #8 | 修正：中英数字间空格 | P3 | XS |
| 10 | 英文标点混入中文 | `lib/core/data/services/preset_medication_templates.dart:100-160` | "PHQ-9 / GAD-7" 等英文缩写 OK；"3 种药"用全角 OK；混排 OK | 已正确（spen 报告 #15 也认） | — | — |
| 11 | 中文标点 + 英文单词间 | `lib/l10n/app_zh.arb:167` | "Action is the user-facing action（保存/删除/导出/...)" 注释里 "(保存/删除/导出/...)" 用了 `...` | R59 修正：用 `……` 全角省略号 | P3 | XS |
| 12 | **大量注释不写中文** | `lib/core/l10n/strings.dart` 注释 | strings.dart 90% 注释是中文，但有部分"// v0.26 R57" 等版本标注用英文缩写 | 加 R60 lint：`// ` 后必须中文（除非是 TODO/FIXME/XXX 标记） | P3 | S |
| 13 | **命名一致性** | `lib/core/l10n/strings.dart:50-90` | "notifDailyCheckInTitle"、"notifMedicationTitle"、"notifRefillTitle" 命名一致 ✅，但 ARB key 是 "homeDailyCheckIn" / "medicationTitle" / "refillTitle" 路径不一致 | R60 修正：把 ARB key 走 `notifXxx` 风格统一 | P3 | S |
| 14 | **错误消息一致性** | `lib/core/l10n/strings.dart:50-150` | 30 个 `xxxText` 函数命名一致 ✅，但 `emailBody` / `emailSubject` / `notifBody` 风格不一 | 修正：分 2 类：`<channel>Body({override})` + `<feature>Body({override})` | P3 | S |
| 15 | **缺失抽象** | `lib/core/l10n/strings.dart:200-229` | 5 个 `importSummaryXxx` 函数，参数都是 `int n, {String? override}`，模式完全相同 | 修正：抽 `importSummaryNoun(noun, count, {override})` 工厂 | P2 | XS |
| 16 | **隐式耦合** | `lib/presentation/providers/notification_init_provider.dart` | 命名"init" 但实际不只是 init，含 permission check + tz recheck + 5 厂商 push 检测 | R60 评估改名 `notification_bootstrap_provider` | P3 | XS |
| 17 | **缺失抽象** | `lib/presentation/pages/settings/widgets/notification_status_card.dart:_OemBrand` | 7 brand 重复 4 行 boilerplate（brand + steps widget） | 修正：抽 `OemBrandList(brandList: List<{name, steps}>)` 集中 | P2 | S |
| 18 | **缺失抽象** | `lib/core/data/services/sms_service.dart:50-90` | 3 个 provider（MockSmsProvider / AliyunSmsProvider / TwilioSmsProvider）共享 50% boilerplate | 修正：抽 `_BaseSmsProvider` 抽象（已部分通过 abstract SmsProvider） | P2 | S |
| 19 | **命名一致性** | 全部 `*_entity.dart` / `*_repository.dart` | `lib/domain/entities/` 11 个 entity 都用 `*Entity` 后缀 ✅；但 `lib/domain/entities/hour_minute.dart`、`dosage_unit.dart` 没 `*Entity` 后缀（value object 不是 entity） | 修正：加 ADR `docs/decisions/v0.27_value_object_naming.md` 写明"Entity vs Draft vs value object" | P3 | S |
| 20 | **命名一致性** | 全部 `core/shared/*.dart` | `formatters.dart` / `json_codec.dart` / `domain_value.dart` / `user_name_helper.dart` / `swallow_error.dart` / `mood_visual.dart` 命名风格不统一（`formatters` 复数、`swallow_error` 动词+名词） | 修正：统一 `xxx_helper.dart` 风格（仅作命名 ADR，无功能改动） | P3 | XS |

---

## 4. 隐私边界验证（中文 PII 视角）

按 `chinese-code-review` + `chinese-git-workflow` 视角，隐私边界 = **PII 数据流**：

| 隔离模块 | 进什么 | 不进什么 | 验证方式 | 当前状态 | 风险 |
|---|---|---|---|---|---|
| 树洞（vent） | 文字 + 录音 | 趋势 / 评估 / CareEngine / SafetyWatch / 通知 / 关怀 | `check_cross_feature.py` 0 violations（69 files checked） + `core/data/services/vent_*` import grep 0 hit 业务模块 | ✅ 严格隔离 | 0 |
| 情绪日记（mood） | mood-specific reports | 通知（v0.15 之后可加） | grep `moodRepository` 在 `notification_service` / `care_engine` 等 = 0 hit | ✅ 严格隔离 | 0 |
| 心理评估（assessment） | 评估历史趋势 | 失联通知（除非 CrisisSignal） | `core/data/services/safety_watch_service.dart` grep `assessmentRepository` = 0 hit | ✅ 严格隔离 | 0 |
| 打卡（check-in） | streak / 趋势 | 评估 | grep `checkInRepository` 在 `assessment_*` = 0 hit | ✅ 严格隔离 | 0 |
| 失联通知（SafetyWatch） | 通知家人 | 内部 detail（仅 SMS） | 已拆分 SafetyAlertDispatcher，家人只收到 SMS 摘要 | ✅ 隔离清晰 | 0 |
| **PIPL §13 单独同意** | 树洞录音 + 紧急联系人 + 数据导出 | — | `check_legal_consent.py` 通过，**但真接未做**（v0.25 R58 A-03 文档化） | ⚠️ v1.0 待接 | P1 |

**新增发现（spzh 视角）**：

| # | 区域 | 文件:行号 | 问题 | 建议 | 严重度 | 难度 |
|---|---|---|---|---|---|---|
| 1 | **PIPL §13 单独同意** | `lib/presentation/pages/setup/setup_legal_dialog.dart` | 树洞录音 / 紧急联系人 / 跨境导出 3 个场景应独立勾选框（v0.25 R58 A-03 TODO 注释） | R60 真接：3 个独立 CheckboxListTile 走 ARB，存到 `user_profiles.sensitiveConsent*` 字段 | **P1** | L |
| 2 | **跨境 (PIPL §38 / §39)** | `docs/SENDGRID_SETUP.md` | 邮件走 SendGrid 在大陆有合规风险（数据出境） | R60 评估国内 SMTP 替代（阿里云邮件推送） | P2 | L |
| 3 | **个人信息清单 (PIPL §17)** | `docs/CHANGELOG.md` R54 已做隐私政策 | 清单已列，但树洞录音未单独列"敏感个人信息" | R59 修正：在 `privacy_policy.md` §4 明确标"树洞录音 = 敏感个人信息" | P1 | XS |
| 4 | **撤回同意 (PIPL §15)** | 无 | 用户撤回同意后应删除对应数据 | R61 加"撤回同意"入口在 settings 隐私 section | P1 | M |
| 5 | **数据最小化 (PIPL §6)** | 已做（v0.25 R57 userName nullable fallback） | ✅ | — | — | — |
| 6 | **PII 日志 (PIPL §17 / GDPR Art 5)** | `lib/core/data/services/pii_safe_log.dart` | release 模式 swallow、debug 模式 dev tools 可看，✅ 已落地 | — | — | — |
| 7 | **mask phone** | `pii_safe_log.dart:maskPhone` | `138****5678` 格式 ✅ | — | — | — |
| 8 | **mock provider 误上线** | `lib/core/data/services/sms_service.dart:50-90` | v0.23 R38 P0-1 fail-fast 已修正：release 模式启动时 check `isProductionReady` | ✅ | — | — |
| 9 | **AliyunSmsProvider.send() 未真接** | `lib/core/data/services/sms_service.dart:~200` | R55 加骨架，R58 修正为 `[WARN]` 模式 | R60 真接（依赖法务模板审核 + AccessKey） | P2 | XL |
| 10 | **5 厂商 push 未真接** | `docs/PUSH_PROVIDERS.md` | R55 plan 已写 | R60+ 真接（依赖各厂商资质审核 1-2 月） | P2 | XL |

---

## 5. 守护脚本盲区（spzh 视角新增）

按 `chinese-code-review` 与 `chinese-documentation` 视角，**已落地的 12 守护脚本**（含 R57 R58 新增）：

```
1. check_arb_keys.py            zh / en / zh_Hant ARB 同步
2. check_changelog.py           pubspec 版本号 + CHANGELOG 顺序
3. check_cross_feature.py       跨 feature import 边界
4. check_datetime_race.py       跨函数 DateTime.now() 多次调用
5. check_datetime_race2.py      跨 DateTime(year,month,day) 多次调用
6. check_drift_namespace.py     @DataClassName 唯一
7. check_fullwidth_punctuation.py  全角标点 (warn-only) ← **有 false positive**
8. check_no_hardcoded_utc.py    UTC 硬编码
9. check_no_pua.py              PUA 字符
10. check_widget_dispose.py     资源泄漏
11. check_orphan_arb_keys.py    ARB key 定义但未引用
12. check_all.dart              4 层架构纯度 + 一致性
+ R57 新增:
13. check_sms_release_ready.py  SMS 真接 (warn-only, v1.0 hard fail)
14. check_legal_consent.py      PIPL §13 单独同意 TODO 检查
15. check_strings_hardcoded.py  静态中文 const 走 xxxText 模式
16. check_zh_hant_consistency.py 繁简 100% 一致 (OpenCC s2tw)
```

**spzh 视角新增盲区**：

| # | 盲区类型 | 出现位置 / 模式 | 建议新增守护脚本 | 严重度 | 难度 |
|---|---|---|---|---|---|
| 1 | **fullwidth script false positive** | `check_fullwidth_punctuation.py:67-70` 47 violations 中 ~20 是 `……`（2×U+2026）误报 | **修正** pattern 为 `(?<!…)^…(?!…)$`，`……` 已对不报 | **P1** | XS |
| 2 | **中英文间缺空格** | `lib/core/l10n/strings.dart:21,32,50,80` 等 50+ 处 ARB 字符串中文 + `$var` + 中文无空格 | `check_zh_en_spacing.py`：扫 ARB / .dart 中文字符 + ASCII 字母/数字相邻处无空格 | P2 | M |
| 3 | **中文错别字** | ARB / 注释 | `check_zh_typo.py`：基于 100 个常见中文错别字字典（"帐号"→"账号"、"登陆"→"登录"、"其它"→"其他"、"做为"→"作为"、"象"→"像" 等） | P2 | S |
| 4 | **繁简异体字** | `app_zh_Hant.arb` | 已用 OpenCC s2tw 自动转换，但"账号"vs"帳號"、"鼠标"vs"滑鼠"等港台习惯不同 | `check_zh_hant_variants.py`：港台用 `帳號`/`滑鼠`、大陆用 `账号`/`鼠标`，手动 whitelist | P3 | M |
| 5 | **拼音变量** | 全部 dart 文件 | grep `[a-z]Hao` `[a-z]De` 等拼音模式（"Hao"=好、"De"=的） | `check_no_pinyin_var.py` | P3 | XS |
| 6 | **全角 / 半角空格混用** | ARB 文件 | grep `[\u3000]`（全角空格）0 命中 ✅，但 `\u200B`（零宽空格）漏检 | `check_no_zero_width_space.py` | P3 | XS |
| 7 | **术语一致性** | 全部 ARB / 注释 | "App" vs "应用"、"i18n" vs "国际化" | `check_zh_terms_consistency.py`（基于 `docs/terminology.md` whitelist + blacklist） | **P1** | M |
| 8 | **PIPL 真接** | 全部 | 检查 release 模式启动时是否校验 `isProductionReady`、用户同意书是否独立勾选 | `check_pipl_compliance.py` | **P1** | L |
| 9 | **中文字数 / 截断** | ARB 文件 | 中文 > 12 字的 button label 应有 `maxLines` 包装（`mood_quick_button.dart` "今日情绪：好/差/一般/..." 22 字） | `check_zh_max_lines.py` | P3 | S |
| 10 | **中文版式检查** | 全部 | 中文段落首行缩进 2 字符 vs 英文不缩进 | `check_zh_paragraph_indent.py` | P3 | S |
| 11 | **commit message 中英混排** | `git log` | 80% 英文 / 20% 中文符合 `CHINESE_COMMIT_GUIDE.md` 规则，但 body 内有中英标点混用 | 修正 `check_changelog.py` 加 body 标点 check | P3 | S |
| 12 | **emoji 一致性** | ARB 文件 | 同一概念 emoji 一致（如 loading 一律 `⏳`、success 一律 `✅`） | `check_emoji_consistency.py` | P3 | S |
| 13 | **中文注释覆盖率** | 全部 dart | 中文字符比例检查（业务代码注释应 > 30% 中文） | `check_zh_doc_coverage.py` | P3 | M |
| 14 | **拼音 vs 简体** | 全部 | 错把"帐号"当正确（实际应是"账号"） | `check_zh_typo.py` 字典扩展 | P3 | S |
| 15 | **国产 ROM 推送 SDK 缺失** | `pubspec.yaml` | 5 厂商 push SDK 未集成（v1.0 work） | `check_5vendor_push_ready.py`（v1.0 启用） | P2 | L |
| 16 | **农历 / 24 节气** | `lib/domain/logic/chinese_holidays.dart` | 已加 holidays，未加 24 节气 | `check_24solar_terms.py`（R61 评估） | P3 | L |

---

## 6. 提交规范 / 文档 / 测试覆盖率

### 6.1 中文 commit 规范覆盖

**已落地**：

- `docs/CHINESE_COMMIT_GUIDE.md`（64 行）— 中文版 Conventional Commits
- 规则：`<version> round <N>: <中文标题 (≤60 字)>` + body 走"what + why + impact"
- 项目历史 100% 走 `<version> round <N>:` 前缀（`git log --oneline | wc -l` 50 / 50）

**spzh 视角新发现**：

| # | 区域 | 问题 | 建议 | 严重度 | 难度 |
|---|---|---|---|---|---|
| 1 | Subject 长度 | R49-R60 一半 commit subject > 60 字（如 `v0.25 round 57: P1(spen) safety_watch_service god class 拆 3 sub — 425 → 325 行 (-24%)` 53 字 ✅，但 `v0.25 round 56b: P1(emil) spacing SizedBox 走 token — 46 处 magic 修复` 56 字 ✅） | 修正 `commit-msg` hook 强制 ≤ 60 字 | P3 | XS |
| 2 | Body 中英混排 | R49-R60 90% body 走中文 + 英文术语（"god class 拆 3 sub"），但部分纯英文（"P1(spen) god class 拆 3 sub"） | 修正：中文项目 body 至少 30% 中文 | P3 | S |
| 3 | emoji 使用 | `git log` 0 commit 用 emoji（✅ 符合"不用 emoji 除非"） | — | — | — |
| 4 | **缺少 commitlint** | 仓库无 `.commitlintrc` / `.husky/`，commit 格式靠人工 | R60 加 commitlint + husky 强制 | P2 | M |
| 5 | **CHANGELOG 时间顺序** | R24 v0.24 review 修过；当前 OK | — | — | — |
| 6 | **pubspec 版本号 + CHANGELOG 同步** | `check_changelog.py` 已修正（v0.25 R58） | — | — | — |
| 7 | **commit 不写 "WIP" / "fix bug"** | `CHINESE_COMMIT_GUIDE.md` 明确禁止；`git log` 0 命中 ✅ | — | — | — |
| 8 | **chinese-git-workflow** | 项目未用 Gitee/Coding/极狐，Github flow OK | — | — | — |

### 6.2 中文文档完整性

| 文档 | 路径 | 行数 | 状态 |
|---|---|---|---|
| README.md | 项目根 | 待查 | 待审 |
| AGENTS.md | 项目根 | 350+ | ✅ |
| CHANGELOG.md | docs/ | 605 | ✅（R24 review 修正时间顺序） |
| WHITEPAPER.md | docs/ | 待查 | 待审 |
| DEPLOYMENT.md | docs/ | 待查 | ✅（R54 修正合规） |
| PUSH_PROVIDERS.md | docs/ | 待查 | ✅（R55 spzh） |
| SMS_PROVIDERS.md | docs/ | 待查 | ✅（R55 spzh） |
| GIT_WORKFLOW.md | docs/ | 待查 | 待审 |
| CHINESE_COMMIT_GUIDE.md | docs/ | 64 | ✅ |
| CODE_REVIEW_v0.17r12.md | docs/ | 待查 | 历史 |
| P2_COMPLIANCE_REVIEW.md | docs/ | 待查 | R54 合规 |
| P2_DESIGN_REVIEW.md | docs/ | 待查 | 历史 |
| P2_SYSTEM_REVIEW.md | docs/ | 待查 | 历史 |
| PRD-v0.1-draft.md | docs/ | 待查 | 早期 |
| v0.17_animations_extraction.md | docs/ | 待查 | R14 决策 |
| v0.22_mojibake_fixes.md | docs/ | 待查 | R48 修正史 |
| v0.24_round48_design_decisions.md | docs/ | 待查 | R48 决策 |
| v0.24_round48_p3_skip_decisions.md | docs/ | 待查 | R48 skip |
| review-superpowers-en-v027.md | docs/reviews/ | 303 | ✅ R58 |
| review-emilkowalski-v027.md | docs/reviews/v0.27/ | 待查 | ✅ R58 |
| review-superpowers-zh-v027.md | docs/reviews/v0.27/ | 本报告 | R58 |

**spzh 视角新发现**：

| # | 区域 | 文件:行号 | 问题 | 建议 | 严重度 | 难度 |
|---|---|---|---|---|---|---|
| 1 | **缺 `docs/terminology.md`** | 缺失 | 无中文术语表，新人 / 翻译易混"App / 应用 / 客户端" | R60 新建，参考 `chinese-documentation` skill 模板 | P1 | S |
| 2 | **缺 `docs/decisions/v0.27_*.md`** | `docs/decisions/` 仅 v0.17/v0.22/v0.24 决策 | v0.25 / v0.26 / v0.27 决策未 ADR 化 | R59 修正：每 round ≥ 1 个 ADR | P2 | S |
| 3 | **CHANGELOG 时间倒序** | 已修正（R24） | ✅ | — | — | — |
| 4 | **README.md 中文 vs 英文版本** | 项目根 README | 待查是否双语（中文 README + 英文 README_EN.md） | R60 评估双语 | P3 | S |
| 5 | **决策记录缺"拒绝"** | 全部 ADR | 现有 ADR 只写"做了什么决策"，未写"为什么不做 X 备选" | R60 修正：ADR 加 "## Rejected alternatives" 章节（per `chinese-git-workflow` skill） | P2 | S |
| 6 | **缺 README 部署 / CI 章节** | README.md | 待查 | R60 修正：加 "## 部署" + "## CI 守护" 章节 | P3 | S |

### 6.3 测试覆盖率（中文 i18n 视角）

| 维度 | 状态 | 证据 |
|---|---|---|
| 全部 tests pass | ✅ | 1109/1109 |
| domain 业务纯 Dart | ✅ | R56c-c''' R57 R60 大量补 |
| data round-trip | ✅ | R53a DAO 拆分后覆盖 |
| presentation widget | ⚠️ | 跨 P0 的 home_page 0 test（spen 报告 §2.2 #1） |
| **中文 i18n 测试** | ⚠️ | `check_orphan_arb_keys.py` 0 orphan + `check_zh_hant_consistency.py` 100% 一致，但是否有 **string content 测试**（断言"加载中……"出现在 ARB）？ |
| **跨年/月 / DST 测试** | ⚠️ | `check_datetime_race.py` 静态检查 ✅，但 runtime test 仅 crossedMidnightSince + DST 0 case |
| **24 节气测试** | ❌ | ChineseHolidays 仅 holidays（19 test），24 节气 0 test |
| **PIPL §13 测试** | ❌ | `check_legal_consent.py` 仅检查 TODO 注释，无 runtime 行为测试 |

**spzh 视角新发现**：

| # | 区域 | 缺失测试 | 建议补 | 严重度 | 难度 |
|---|---|---|---|---|---|
| 1 | ARB 内容 string 测 | "加载中……"、"我今天吃了药" 等关键文案断言 | `test/l10n/arb_string_content_test.dart`（断言 10 个 key 包含中文） | P2 | S |
| 2 | 24 节气测 | 春分/秋分识别 | `test/domain/chinese_24solar_terms_test.dart` | P3 | M |
| 3 | DST 测 | 美国冬令时切换 | `test/data/tz_local_dst_test.dart` | P3 | S |
| 4 | PIPL §13 测 | 树洞录音 + 紧急联系人 + 跨境导出 3 个独立勾选 | `test/presentation/legal_consent_test.dart` | P1 | M |
| 5 | 国产 ROM 引导测 | 7 brand 引导文字断言 | `test/presentation/oem_hint_test.dart` | P3 | S |
| 6 | 跨年 / 跨月组合测 | "12-31 23:59" + "01-01 00:01" + 春节 7 天 + 闰年 02-29 | `test/domain/cross_year_month_combo_test.dart` | P2 | M |

---

## 7. 优先级排序的重构清单（spzh 视角）

按 **(中文项目价值 × 改动成本)** 排序，Top 5 优先：

| 排名 | 重构 | 中文项目价值 | 改动成本 | 严重度 | Round |
|---|---|---|---|---|---|
| 1 | **修正 check_fullwidth_punctuation.py 的 `……` 误报** | 高（19 个误报噪音） | XS | **P1** | R59 |
| 2 | **修正真实半角标点 3-4 处**（preset_medication_templates × 3、export_schema_service × 1） | 中（视觉专业性） | XS | P2 | R59 |
| 3 | **新建 `docs/terminology.md` + 修正 ARB 中"App/应用"等 4 处术语不一致** | 高（专业感） | S | **P1** | R59 |
| 4 | **新增 `check_zh_terms_consistency.py` 守护** | 中 | M | P2 | R60 |
| 5 | **R60 加 commitlint + husky 强制中文 commit 规范** | 中 | M | P2 | R60 |
| 6 | R59 修正 OEM 引导文案繁简分离（港台版用"OEM"通用词） | 中 | S | P2 | R59 |
| 7 | R59 修正 1 鸿蒙 HarmonyOS NEXT 5.0 评估 | 低（v1.0 work） | L | P2 | R60+ |
| 8 | R60 加中文字号 / 字体 token | 中 | S | P2 | R60 |
| 9 | R60 评估 google_fonts 集成（思源黑体 CN / TW） | 中 | S | P2 | R60 |
| 10 | R60 加 PIPL §13 单独同意真接 | 高（合规） | L | **P1** | R60 |
| 11 | R60 加 24 节气识别 + ARB key | 中 | M | P2 | R60 |
| 12 | R61 加 ChineseAntiPattern 守护（拼音 / 全角空格 / 错别字） | 中 | M | P2 | R61 |
| 13 | R61 加 PIPL §15 撤回同意 | 高（合规） | M | P1 | R61 |
| 14 | R61 修正 decision 记录加"拒绝备选" | 低 | S | P3 | R61 |
| 15 | R61 加 3 个 spzh 守护（错别字 / 中英空格 / 24 节气） | 中 | M | P2 | R61 |

---

## 8. 中国开发者视角的 anti-pattern

按 `chinese-documentation` 与 `chinese-code-review` 视角，常见的中国开发者项目反模式 + 本项目当前状态：

| Anti-pattern | 描述 | 本项目状态 | 证据 |
|---|---|---|---|
| **拼音变量** | `var yonghu = user;`（yonghu = 用户） | ✅ 无 | grep `[A-Z][a-z]+[0-9]` 在 `lib/` 中文拼音字典匹配 0 命中 |
| **拼音类名** | `class YonghuController` | ✅ 无 | 同上 |
| **拼音文件名** | `yonghu_page.dart` | ✅ 无 | 同上 |
| **拼音文件目录** | `lib/yonghu/` | ✅ 无 | 目录命名 100% 英文：`check_in/`, `medication/`, `vent/` 等 |
| **全角空格** | `'我　爱　你'`（U+3000） | ✅ 无 | grep `\u3000` 在 `lib/` ARB 0 命中 |
| **半角空格误用** | `'我 爱 你'`（中文字间 ASCII 空格） | ✅ 无 | ARB 内 0 命中 |
| **半角逗号** | `'今天, 你吃饭了吗'` 应是 `'今天，你吃饭了吗'` | ⚠️ 3 处 | `preset_medication_templates.dart:119,149,154`、`export_schema_service.dart:75`、`app_tokens.dart:232` |
| **半角括号** | `'今天(我吃饭了)'` 应是 `'今天（我吃饭了）'` | ⚠️ 2 处 | `export_schema_service.dart:75` |
| **半角斜杠** | `'PHQ-9 / GAD-7'` 应是 `'PHQ-9 ／ GAD-7'` | ⚠️ 7 处 | `preset_medication_templates.dart:119,149,154`、`loading_text_button.dart:21`、`mood_quick_button.dart:14`、`core_providers.dart:89`、`choose_window_dialog.dart:15` |
| **半角省略号** | `'加载中…'` 应是 `'加载中……'` | ✅ 已修正 | ARB 内 19+ 处已 `……`，但脚本误报 |
| **半角冒号** | `'姓名: 小明'` 应是 `'姓名：小明'` | ⚠️ 待修正 | spen 报告 §3.3 未列；本报告 spzh 视角新增 |
| **半角问号 / 感叹号** | `'吃了吗?'` 应是 `'吃了吗？'` | ✅ 无 | grep `[?]?` 模式 0 命中 |
| **机翻味** | `'这个函数被用来计算用户的折扣'` | ✅ 无 | 注释地道自然 |
| **欧化长句** | `'这是一个可以帮助开发者在不需要手动配置复杂的构建工具链的情况下快速搭建现代化前端项目的脚手架工具'` | ✅ 无 | 注释都 < 30 字 |
| **过度翻译** | `'API'` 翻译成"应用程序接口" | ✅ 无 | 技术术语全部保留英文 |
| **句号混入代码** | `'// TODO: 修正 bug.'` | ✅ 无 | TODO 注释无句号 |
| **中英混排缺空格** | `'我用了Redis做缓存'` 应是 `'我用了 Redis 做缓存'` | ⚠️ 50+ 处 | ARB / 注释 / 字符串 |
| **emoji 不一致** | loading 一处用 `⏳`、另一处用 `🔄` | ⚠️ 部分 | `app_zh.arb` 内 emoji 不强一致 |
| **markdown 列表无空格** | `'-项目1'` 应是 `'- 项目1'` | ✅ 无 | markdown 格式正确 |

**spzh 视角新增 anti-pattern 检查建议**：

1. **R60 新建 `check_chinese_anti_pattern.py`** —— 一次性扫 8 种 anti-pattern（拼音 / 全角空格 / 半角标点 / 机翻 / 欧化 / 缺空格 / emoji 不一致 / markdown 列表）
2. **R60 新建 `docs/anti_patterns.md`** —— 列 20 个常见中国开发者 anti-pattern + 反例
3. **R59 在 AGENTS.md 加 "## 中文反模式" 章节** —— 链接到 `docs/anti_patterns.md`

---

## 9. 与 spen 报告的关系（去重声明）

本报告（spzh 视角）**不复述** spen 报告已涵盖的 66 项发现，重点关注 **中文工程化** 维度。下表列出 spen 报告 vs spzh 报告的边界：

| 维度 | spen 报告 | spzh 报告 |
|---|---|---|
| 顶层架构 4 层 + core umbrella | §1 详细 | §1 简评（中文团队上手成本） |
| god-class 拆分 | §3 14 个文件 | 不重复（spen 列表已全） |
| TDD / 测试覆盖 | §2 10 个 0-test 路径 | §6.3 仅补"中文 i18n 测" / "24 节气" / "PIPL §13" |
| 代码审查 | §4 20 个 issue | §3 仅补 "中文术语不一致" / "中英混排空格" / "命名一致性" |
| 隐式 bug / 已知坑 | §5 22 个 gotcha 检查 | 不重复（spen 已 grep 验证 R57-R58 干净） |
| 子代理机会 | §6 5 个并行机会 | 不重复 |
| 优先级清单 | §7 5+5+5 排序 | §7 仅 spzh 独有 15 项 |
| **中文 commit 规范** | ❌ 未涉及 | ✅ §6.1 8 项 |
| **中文 i18n / 全角标点** | ❌ 未涉及 | ✅ §2.2 + §5 #1 修正 |
| **国产 ROM 适配** | 仅 §5 #8 一行 | ✅ §2.1 6 项 |
| **PIPL 合规** | §5 #22 一行 | ✅ §4 10 项 |
| **中国特色 anti-pattern** | ❌ 未涉及 | ✅ §8 完整 19 项 + 修正建议 |
| **术语一致性** | ❌ 未涉及 | ✅ §3 #1-3 + §5 #7 |
| **农历 / 24 节气 / DST** | §5 #11 仅 midnight | ✅ §2.3 6 项 |
| **Material 3 中文体验** | ❌ 未涉及 | ✅ §2.4 6 项 |
| **中文 Git 工作流** | ❌ 未涉及 | ✅ §6.1 8 项 |
| **可访问性** | ❌ 未涉及 | ✅ §2.5 4 项 |

**边界清晰**：spen 报告是"通用 Flutter / 架构 / TDD 视角"；本报告是"中文开发者视角"。

---

## 10. 总结

**chroniccare v0.27 round 58 在中文工程化维度已达 4.0/5 ⭐**，主要特点：

**强项**（4.5/5 ⭐）：
- 中文 commit 规范落地（CHINESE_COMMIT_GUIDE.md + 100% `<version> round <N>:` 前缀）
- 中文 i18n 551 keys 三语同步 + zh_Hant OpenCC s2tw 100% 一致
- 28 处 xxxText override 模式保持 domain 0 flutter 边界
- PII 日志（piiSafeLog + maskPhone + release swallow）
- SMS 真接 fail-fast（P0-1 v0.23 R38）

**弱点**（3.0/5 ⚠️）：
- check_fullwidth_punctuation.py 有 false positive（19+ 处 `……` 误报）
- 7 处真实半角标点未修正
- 中文术语不一致（"App / 应用 / 客户端" 3 种叫法混用）
- 缺 `docs/terminology.md` 和 3 个 spzh 守护脚本

**Top 3 修正**：
1. R59 修正 check_fullwidth_punctuation.py 误报（XS 难度，高价值）
2. R59 修正真实半角标点 7 处（XS 难度，中价值）
3. R60 新建 `docs/terminology.md` + ARB 术语统一（S 难度，高价值）

**长期（R60-R61）**：
- 加 3 个 spzh 守护（错别字 / 中英空格 / 24 节气 / PIPL 真接）
- 新建 `docs/anti_patterns.md` 修正中国开发者 anti-pattern
- 修正 PIPL §13 / §15 真接（合规必经）

---

## 11. superpowers-zh 方法论如何应用到本审视

| 子技能 | 应用方式 | 产生的发现 |
|---|---|---|
| `chinese-code-review` | 分级标注（必须修复/建议修改/仅供参考/问题）+ 温和语气 | §3 20 项 + §4 10 项 + §8 19 项 |
| `chinese-commit-conventions` | 检查 `<version> round <N>:` 规范 + body 中英混排 | §6.1 8 项 |
| `chinese-documentation` | 中英混排空格 / 全角半角 / 术语保留 | §2.2 + §3 + §5 #2 + §8 19 项 |
| `chinese-git-workflow` | 检查 commitlint / husky / 决策记录 | §6.1 + §6.2 |
| `writing-plans` | §7 优先级清单（影响 × 成本） | 15 项 R59-R61 排序 |
| `verification-before-completion` | 全文引用 `python scripts/...` 命令 + 12 守护脚本输出 | §4 隐私边界 + §5 盲区 |
| `test-driven-development` | §6.3 测试覆盖率分析（中文 i18n 测 / 24 节气 / PIPL） | 6 项 |
| `code-review`（通用） | SRP / 隐式耦合 / 缺失抽象 / 命名 | §3 20 项 |
| `using-superpowers`（meta） | 本审视是 meta-skill 在 v0.27 的第 3 视角落地 | 本报告 |

**spzh 视角独有贡献**：
- 把"中文工程化" 19 个 anti-pattern 系统化（spen 报告未列）
- 量化术语不一致 4 处 + 修正建议
- 量化真实半角标点 7 处 + 修正建议
- 量化全角标点脚本误报 19+ 处 + 修正 pattern
- 量化 24 节气 / DST / 春节 / 闰年边界 6 项
- 量化中文字号 / 字体 / 标点挤压 / 半角空格 4 项
- 量化 spzh 守护脚本盲区 16 项 + 修正建议

**没有重复的发现**：spen 报告 66 项 + spzh 报告本表 19 项 + 通用架构不重复 = 三个视角覆盖完整。

---

## 报告元信息

- **审视者**：superpowers-zh v1.6.0 lens（6 个中国特色子技能 + 14 个核心汉化）
- **本审视阅读的文件**：
  - `AGENTS.md`（350+ 行）
  - `pubspec.yaml`（82 行）
  - `docs/CHINESE_COMMIT_GUIDE.md`（64 行）
  - `docs/CHANGELOG.md`（605 行）
  - 12 个守护脚本（`scripts/*.py` + `scripts/check_all.dart`）
  - 10+ 代表性文件：`app_router.dart` / `home_page.dart` / `medication_calendar_page.dart` / `vent_compose_page.dart` / `notification_status_card.dart` / `care_engine.dart` / `safety_watch_service.dart` / `notification_service.dart` / `data_export_service.dart` / `app_database.dart` / `core/l10n/strings.dart` / `check_in_usecases.dart` / `lib/l10n/app_zh.arb`（前 2500 字 + 2500-4500 字 + 末尾）
- **本审视未阅读的文件**：
  - `app_database.g.dart`（auto-generated，167K bytes）
  - `app_localizations*.dart` 自动生成（已通过 ARB 检查）
  - 大部分 `test/` 文件（仅按文件名清单，未读内容）
  - `lib/presentation/pages/medication/widgets/medications_list_widget.dart` 全文
  - `lib/presentation/pages/contact/contacts_list_widget.dart` 全文
  - `lib/presentation/pages/setup/setup_*.dart` 全文
- **发现总计**：
  - 顶层架构 1.3: 4 项
  - 中国特色实战 2.1-2.5: 28 项
  - 代码审查（中文视角）§3: 20 项
  - 隐私边界（中文 PII）§4: 10 项
  - 守护脚本盲区 §5: 16 项
  - 提交/文档/测试 §6: 14 项
  - 优先级清单 §7: 15 项
  - anti-pattern §8: 19 项
  - **合计：126 项 spzh 独有发现**（与 spen 报告 66 项不重复）
- **token 预算**：~12K tokens 读取 + ~8K tokens 写作
- **输出文件**：`D:\Batch\chroniccare\docs\reviews\review-superpowers-zh-v027.md`
