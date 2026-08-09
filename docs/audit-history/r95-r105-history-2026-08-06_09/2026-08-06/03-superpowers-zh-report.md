# superpowers-zh 软件工程审计 (中国特色重点)

> **审计日期**: 2026-08-06
> **审计对象**: `D:\Batch\chroniccare` (Flutter 3.41.9 / Dart 3.12.2 / Riverpod 3.3.2 / Drift 2.20.3 / go_router 14.6)
> **当前版本**: pubspec `0.30.0+85` / CHANGELOG `[0.30.0] - 2026-08-05 (R91)` / git `cf91020` on `master`
> **审计范围**: 全量只读,重点 4 个中国特色子技能 (中文代码审查 / 中文提交规范 / 中文文档 / 中文 Git 工作流)
> **守门员实测**: 14/16 ✅ + 1/16 ⚠️ warn-only + 1/16 GBK 控制台乱码 (但本机状态 OK)

---

## 总体评估

| 维度 | 评分 (1-10) | 国内最佳实践差距 | 备注 |
|---|---|---|---|
| **工程水位 (代码 / 架构)** | **8.0** | 小 | 4 层架构 + 16 守门员 + 1000 ARB keys 同步 + 0 PUA / 0 race / 0 leak,跟国际中型项目持平 |
| **国内合规上架准备** | **3.5** | **大** | PIPL §13 已实施 / §14 撤回 R67 真接,但 §23 / §28 / §38 / §50 / §51 / §54 仍是文档声明层面,法务 0 签字 |
| **资质 / 备案 / 5 厂商 push** | **1.0** | **极大** | SMS 仍 `UnimplementedError` / Email mock-only / 5 厂商 push 0 接 / 软件著作权 0 申 / ICP 0 备案 / 域名 0 注 |
| **中文规范 (代码 / 提交 / 文档)** | **7.5** | 小 | 全角标点 135 violations 仍是 warn-only;terminology.md + R57 override 模式 + R59 集中器 都很扎实 |
| **中文 Git 工作流** | **6.5** | 中 | 单 dev + 自定义 `<version> round <N>` 格式合理,但无 remote / 无 PR 流程 / 无 tag release / worktree 残留 |

**一句话总结**: **代码层和工程自动化是国内中型项目天花板,但中国合规上架全链路仍未跑通 (法务 0 签字 + 备案 0 进行 + SMS/Email/5 厂商 push 0 真接) — 2026-08-06 当前状态可发布到海外 GitHub (自我学习项目) 但不能上中国任何 store。**

**16 守门员实测 (2026-08-06 实跑)**:
| # | 守门员 | 状态 | 详情 |
|---|---|---|---|
| 1 | check_arb_keys.py | ✅ | zh 1000 / en 1000 / zh_Hant 1000, 双向 0 缺漏 |
| 2 | check_changelog.py | ✅ | pubspec=0.30.0+85 跟 CHANGELOG 顺序对 (31 entry) |
| 3 | check_cross_feature.py | ✅ | 94 files, 0 violations |
| 4 | check_datetime_race.py | ✅ | 0 (GBK 乱码但实际 OK) |
| 5 | check_datetime_race2.py | ✅ | 0 (GBK 乱码但实际 OK) |
| 6 | check_drift_namespace.py | ✅ | 13 tables, 0 duplicates |
| 7 | check_fullwidth_punctuation.py | ⚠️ | **135 violations**,R58 降为 warn-only,**CI `--ci` 模式会 fail** |
| 8 | check_no_hardcoded_utc.py | ✅ | 0 |
| 9 | check_no_pua.py | ✅ | 0 PUA |
| 10 | check_widget_dispose.py | ✅ | 0 leak |
| 11 | check_orphan_arb_keys.py | ✅ | 1000 zh / 0 orphan |
| 12 | check_legal_consent.py | ✅ | setup_legal_dialog.dart 无 TODO / 无 PIPL §13 TODO |
| 13 | check_sms_release_ready.py | ✅ | AliyunSmsProvider send() throw UnimplementedError 但 R58 warn-only |
| 14 | check_strings_hardcoded.py | ✅ | 32 处 const + 32 处 R57 override 配对,其余带 i18n 标记 |
| 15 | check_zh_hant_consistency.py | ✅ | 1000 keys, 100% 繁简一致 (OpenCC s2tw) |
| 16 | check_16kb_alignment.py | ✅ | build.gradle.kts 显式 ndkVersion, targetSdk=36 |
| + | check_all.dart (Dart) | ✅ | 4 层架构纯度 + 一致性 双通过 |

---

## A. 14 通用子技能 (重点确认)

> superpowers-en 14 个子技能 (brainstorming / writing-plans / TDD / subagent-driven-development / systematic-debugging / code-review / git-worktrees / ...)。本审计范围不重复 superpowers-en 视角已覆盖,只列 **superpowers-zh 视角下中文化后需额外确认** 的部分。

| 子技能 | 中文化要求 | 当前状态 | 评估 |
|---|---|---|---|
| brainstorming | brainstorming 流程中文版 | docs/ 缺独立 brainstorming 流程 doc | P3 (无 doc 但脑暴流程在 R91 spec/plan 隐式使用) |
| writing-plans | plan doc 模板中文版 | `.superpowers/sdd/specs/`, `.superpowers/sdd/plans/` 中文 | ✅ 完整,每个 sub-spec 5-7 task,每 task 1 commit |
| TDD | TDD 模板中文版 | test/ 205 文件,1 file 1 round 命名 | ✅ 严格遵循 `{module}_{roundN}_test.dart` |
| subagent-driven-development | subagent 用法中文版 | AGENTS.md "子 agent 场景" 段 | ✅ 简版,建议 P2 加 .superpowers/sdd/progress.md 同步 |
| systematic-debugging | debug 流程中文版 | AGENTS.md "调试" + "已知坑" 18 条 | ✅ 系统化 (隐式排序 / race / dispose / OEM / shader) |
| code-review | code review checklist 中文版 | `.github/PULL_REQUEST_TEMPLATE.md` 6 段 | ✅ 中文 6 段 checklist (命名/测试/资源/架构/可读/上架) |
| git-worktrees | worktree 命名规范 | **只 1 个 worktree 残留** (`.worktrees/feat-cbt-thought-report`) | ⚠️ 命名 OK,但残留无清理,见 B-4 §3 |
| test-driven-development | TDD 守门员 | ci.yml 集成 16 守门员 | ✅ |
| verification-before-completion | "完成前验证" 中文版 | DEPLOYMENT.md "阶段 7.5 上架前 must-check 清单" + CHANGELOG 每 round Verification 段 | ✅ |
| refactoring | 重构守门员 | check_architecture_consistency 集成 (R68 合并到 check_all.dart) | ✅ |
| code-review-pr | PR 模板 | `.github/PULL_REQUEST_TEMPLATE.md` 中文 6 段 | ✅ |
| systematic-debugging (root-cause) | 根因分析 | AGENTS.md "已知坑" 18 条是反向根因库 | ✅ |
| deployment | 上架部署指南 | DEPLOYMENT.md + STOREFRONT_RELEASE_SOP.md 双 doc | ✅ |
| testing-best-practices | 测试最佳实践 | 1098 → 1617 test cases (R88 1487 → R91 1617) | ✅ |

**A 段总评**: 14 个跟 superpowers-en 重复的子技能,中文化对齐 OK。**最大缺口**: superpowers-en 的 `brainstorming` 子技能在 `AGENTS.md` 缺独立引用,新需求进来直接进 task 5 步,缺少 brainstorming 阶段的强制拦截 (P3)。

---

## B-1. 中文代码审查

> 范围: `lib/` (342 .dart) + `lib/l10n/` (1000 keys × 3 lang) + 16 守门员 / `docs/terminology.md` 集中器

### B-1.1 优势 (做得好)

| # | 项 | 证据 | 评估 |
|---|---|---|---|
| 1 | **R57 override 配对模式** (string const + xxxText({override}) 函数并存) | `lib/core/l10n/strings.dart` 32 处 const + 32 处 R57 override 配对 | 架构级 (优秀) — domain 0 flutter + 允许 presentation override 走 ARB |
| 2 | **terminology.md 集中器** (R59) | 5 大类术语统一 (App/本应用/多语言/PII/医疗) + ADR-059-1 | 架构级 (优秀) |
| 3 | **16 守门员** (含 4 个中国特色: check_legal_consent / check_zh_hant / check_strings_hardcoded / check_sms_release_ready) | ci.yml 全部接入 | 架构级 (优秀) |
| 4 | **PUA 字符 0** (check_no_pua.py ✅) | R88 历史 362 PUA 全清 | 底层 (优秀) |
| 5 | **罗马化规则** (中英空格) | `docs/terminology.md` §7 + `check_fullwidth_punctuation.py` | 底层 (优秀) |
| 6 | **业务术语"树洞/失联/紧急联系人/打卡"全文一致** | grep "树洞" 368 hits, "失联" 395 hits, "打卡" 958 hits (lib+docs+assets+scripts+test) | 底层 (优秀) |
| 7 | **病耻感措辞中性化** (R72) | "让家人放心" → "踏实/多一点坚持","你真棒" → "今周已全部准时" | 架构级 (优秀 — R72 spzh 视角 P0-5 续) |
| 8 | **"TA" → "对方"** (R72 spzh R66 P0-5 续) | 18 → 16 hits 实际替换 | 底层 (良好) |
| 9 | **setup_legal_dialog.dart** PIPL §13 文档化清晰 | R58 / R62 / R83 三轮 P0 fix,见 L1-30 注释 | 架构级 (优秀) |
| 10 | **R67 撤回同意业务层真接** (PIPL §14 严格) | care_engine.dart:138-140 `isSafetyConsentWithdrawn` 守卫 + ventRepository 拒绝写入 | 架构级 (优秀) |

### B-1.2 问题清单

| # | 文件:行 | 问题 | 类型 (架构/底层) | 难度 | 优先级 |
|---|---------|------|----------------|------|--------|
| 1 | `lib/l10n/app_localizations.dart:471/477/483/621/933/1419` (等多处,共 135 violations) | **半角标点 (逗号/冒号/分号/问号/感叹号/斜杠/括号 + 半角省略号 U+2026)** 出现在中文 string literal 内,**违反术语 §7 全角规则** | 底层 | 1 | **P0** (CI `--ci` 模式会 fail,但 R58 降为 warn-only,**上架前必修**) |
| 2 | `lib/core/l10n/strings.dart:30/40/43/50/52/58` | 32 处 `static const String` 含中文 (R57 override 配对模式已修),但**注释里出现"v1.0+ 完全脱离本文件"承诺,R91 后仍未做** | 架构 | 3 | P2 |
| 3 | `lib/core/l10n/strings.dart:58` `emailFooter` const | "由慢病管家 App 发送" — **"App" 混用**,terminology.md §2 禁用,应改"由慢病管家本应用发送" (R59 仅修了 14 处 ARB,strings.dart 漏改) | 底层 | 1 | P1 |
| 4 | `lib/core/l10n/strings.dart:38` | `'我是 $name，已经 $days 天没在 App 里打卡了。\n...'` — **"App" 混用** 同上 | 底层 | 1 | P1 |
| 5 | `lib/core/l10n/strings.dart:96` `'点一下 = 打卡，留个今天的踏实'` | "点一下 = 打卡" 用了半角 `=` 和 `,`,在中文 string 内应全角 | 底层 | 1 | P1 |
| 6 | `lib/core/l10n/strings.dart:30` `'[停药提醒] $name 已经 $days 天没吃药了'` | "停药" 措辞偏负面,建议"漏药提醒"或"用药提醒" (跟术语 §6 "续方" 一致) | 底层 | 1 | P2 |
| 7 | `lib/core/data/services/sms_service.dart` | AliyunSmsProvider.send() **仍 throw UnimplementedError** (R58 降为 warn-only) — 上 store 前必修 | 架构 | 5 | **P0** (1-2 月外部依赖) |
| 8 | `lib/core/data/services/email_service.dart` | **EmailService 是 mock-only**,无 dio 依赖,无真实 SendGrid 集成 (v0.22 R29 删 dio) | 架构 | 5 | **P0** (1-2 周 + 阿里云邮箱模板审核) |
| 9 | `lib/core/data/services/notification_service.dart` | **5 厂商 push SDK 0 接** (米/华/OPP/vivo/魅族),国产 ROM 送达率 < 70% (R55 计划 1-2 月) | 架构 | 5 | **P0** |
| 10 | `lib/core/data/feature_flags.dart:38` `_prodIapEnabled = false` | 8 元买断功能**业务整体暂停** + user_agreement.md §3 仍写"8 元买断" = 描述 vs 实际不一致 (LEGAL_REVIEW_BRIEF §1.3 标 P0) | 架构 | 3 | **P0** (文案 / 实际不符) |
| 11 | `lib/core/data/feature_flags.dart:35` `_prodEmergencyContactEnabled = false` | 失联通知业务**整体暂停** + 隐私政策 §0.5/§3/§12 仍描述 "失联通知会发 SMS" (LEGAL_REVIEW_BRIEF §1.1 标 P0) | 架构 | 4 | **P0** (PIPL §17 告知不准确) |
| 12 | `lib/core/data/feature_flags.dart:42` `_prodBootReceiverEnabled = true` | WorkManager 后台接收**0 实现** (R65 标 TODO),目前仍依赖 flutter_local_notifications 的系统级通知 | 架构 | 4 | P1 (非 P0 因为有 flutter_local_notifications 兜底) |
| 13 | `lib/presentation/pages/setup/setup_legal_dialog.dart:25-32` | "v1.0 严格 PIPL §13 + §23 升级" 注释列 5 项 TODO (1. SMS 发送 2. 联系人回复 Y 3. confirmed 标记 4. UI 状态 5. 30 天提醒) | 底层 | 5 | P1 (跟 A-01 SMS 真接绑) |
| 14 | `lib/presentation/pages/setup/setup_legal_dialog.dart` | R58 软实施 vs R67 业务层真接的描述散在 3 段注释,无统一阶段表 | 底层 | 1 | P3 |
| 15 | `lib/domain/logic/assessment_scale.dart` | PHQ-9 / GAD-7 / 8 新量表 (R90) **题目全文仍 const class 兜底中文** (R78 决策留 v1.0),en / zh_Hant locale 用户看中文题目 | 架构 | 4 | P1 (v1.0 大工程) |
| 16 | `lib/domain/entities/check_in_entity.dart` | `isAssessment` 走 `_assessmentScaleIds` const set (R91 C2 fix) — 8 新量表 enum 加了,**但 R65 没给 8 新量表加 `checkInType*` ARB key**,caller 走 `scaleById(type.wire).displayName` 兜底 | 底层 | 2 | P2 |
| 17 | `lib/l10n/app_zh.arb` | R59 修了 14 处 "App" → "本应用" / "慢病管家",**但 grep 验证 strings.dart L30/38/58/96 等仍含 "App"** — 漏改集中器 | 底层 | 1 | P1 |
| 18 | `lib/core/data/database/app_database.dart:128-279` | schemaVersion 18 migration 注释**大量中文** (v0.18 R18 → v0.30 R91 累积),优点是 history 可追溯,**缺点是注释行数 > 实际 migration 代码 4x** | 底层 | 1 | P3 (风格) |
| 19 | `lib/main.dart:28-41` (R62 注释) + `:43-54` (R67 注释) | 2 段 P0 修复历史注释 100+ 字 — 单行信息密度高,易过期 (未来 R70+ 仍引用 R62 旧注释) | 底层 | 1 | P3 (风格) |
| 20 | `lib/core/l10n/strings.dart:154-...` (PDF 报告段) | PDF 区块标题 (pdfSectionRoutineMeds / pdfSectionTempMeds / pdfSectionSummary) const + override 双轨 — **R88 加 CbtThoughtRecordPdf 后没复用 strings.dart 集中器**,新建文件 `lib/core/data/services/cbt_thought_record_pdf.dart` 自带硬编码中文 | 架构 | 2 | P2 |
| 21 | `lib/core/data/services/cbt_thought_record_pdf.dart` (R88 新增) | **新服务自带头部/页脚/章节标题硬编码中文**,未走 strings.dart 集中器 (R72 PDF 集中器未覆盖) | 架构 | 2 | P2 |
| 22 | `lib/presentation/services/scale_translations_l10n.dart` (R90 新增) | 8 新量表 56 个 switch-case stub 题目返 `''` 兜底 — **en / zh_Hant locale 用户看 PHQ-9 中文题目**,R78 PHQ-9 决策一致留 v1.0 | 架构 | 4 | P1 (v1.0 大工程, 法务 + 临床翻译) |
| 23 | `lib/` 整体 | grep TODO 22 hits (非 commit 注释) — R56e R58 R59 R62 R67 多次清理, **剩余 22 主要是 v0.30 R91 新 sub-spec 7 (sleep / social_rhythm / stress / weight / anxiety / treatment) 临时占位 TODO** | 底层 | 1 | P2 |
| 24 | `lib/core/data/services/sms_service.dart` | MockSmsProvider 与 AliyunSmsProvider 平行,**无 TwilioSmsProvider** (R55 SMS_PROVIDERS.md 计划 1-2 月) — 海外用户 0 通道 | 架构 | 4 | P2 (海外 store 必备) |

### B-1.3 总结

- **R57-R91 已修**: 32 处 strings.dart const override 配对 / 14 处 ARB "App" → "本应用" / R72 病耻感措辞中性化 / R67 撤回同意业务层真接 / R62 R67 SMS+Email fail-fast / R91 16 守门员稳定
- **仍欠**: 全角标点 135 violations warn-only / 失联通知业务整体暂停 (PIPL §17 告知不准确) / IAP 业务整体暂停 (Apple 2.1 拒) / 5 厂商 push 0 接 / AliyunSmsProvider 仍 UnimplementedError / EmailService mock-only / R88 CbtThoughtRecordPdf 未走集中器

---

## B-2. 中文提交规范

> 范围: `git log` 431 commits / `docs/CHINESE_COMMIT_GUIDE.md` / `docs/GIT_WORKFLOW.md` / `AGENTS.md` 提交风格段

### B-2.1 优势 (做得好)

| # | 项 | 证据 | 评估 |
|---|---|---|---|
| 1 | **自定义 `<version> round <N>` 格式** (vs conventional commit) | 431 commits 100% 遵循,R82 PULL_REQUEST_TEMPLATE 显式豁免 conventional | 架构级 (合理 — 单 dev + 历史可追溯) |
| 2 | **每个 sub-spec 拆 5-7 task × 1 commit** | R90 12 commits / R91 11 commits,CHANGELOG 一一对应 | 架构级 (优秀) |
| 3 | **CHANGELOG 段粒度细分** (What / Why / Impact / Tests / Notes) | R90 R91 每 entry 5 段 | 优秀 |
| 4 | **CHANGELOG R88 段 self-deprecating** | "注: R85 task 1 R86 cleanup 把 moodEntriesProvider 移到 shared 的 defered 项仍未做, 留 R89+ 单独 PR" | 优秀 (诚实) |
| 5 | **PowerShell `$variable` 限制已文档化** | CHINESE_COMMIT_GUIDE.md §Subject 规则段 | 底层 (细致) |
| 6 | **拆分 vs squash 决策表** (4 场景) | CHINESE_COMMIT_GUIDE.md §拆分 | 优秀 |
| 7 | **Type 分布合理** (前 50 commits) | `ui: 12 / fix: 8 / data: 7 / spec/plan: 5 / trend: 2 / settings: 1 / final: 1 / page: 1 / cleanup: 1 / other: 11` | 良好 (sub-spec 化自然结果) |
| 8 | **无 merge commit 大爆炸** (除 2 个 `Merge:` sub-spec 完成) | cf91020 (R91) + 974a83e (R90) 共 2 merge | 优秀 |
| 9 | **R82 上架冲刺批次 A 标记** | R82 R83 R84 都标 "上架冲刺" — 跟 R67 Sprint 1 (Sprint1_LEGAL_TODO) 平行 | 良好 |

### B-2.2 问题清单

| # | 文件:行 | 问题 | 类型 (架构/底层) | 难度 | 优先级 |
|---|---------|------|----------------|------|--------|
| 1 | `docs/CHINESE_COMMIT_GUIDE.md:18` | "实际项目历史 (v0.21 round 22-26) 80% 英文 / 20% 中文" — **跟 CHINESE_COMMIT_GUIDE "subject 用中文" 矛盾**,自承认指南偏理想,WHITEPAPER §14.3 偏实用 | 底层 | 1 | P3 (诚实即可) |
| 2 | `git log` 前 50 | 11 commits 是 "other" 类别 (非 v0.x round 格式) — `349c4f0 docs(sdd)` `e5af96d docs(sdd)` `e83f4be v0.30 round 88 (spec/plan)` `f4cf6b9 v0.30 round 91 (spec/plan)` — 2 个 `docs(sdd)` **不遵循自定义格式** | 底层 | 1 | P2 (1 句迁移说明) |
| 3 | `docs/CHINESE_COMMIT_GUIDE.md` 全文 | 缺 conventional commit vs 自定义格式的 **决策依据** (为什么不用 feat:/fix:/chore:?) — 单 dev 解释无 | 底层 | 1 | P3 |
| 4 | 整个 git log | **0 个 `BREAKING CHANGE:` / `feat!:`** 标记 (vs conventional commit 强制) — v0.18 R12 5 子层并入 umbrella 实质是 breaking change,**commit message 没标记** | 底层 | 1 | P2 (历史 issue) |
| 5 | 整个 git log | 0 个 release tag (`git tag -l` 空) — `GIT_WORKFLOW.md` §Tag/Release 说"每个 minor version 打 tag",**实际 0 tag** | 架构 | 1 | P1 (R82 上架前必修) |
| 6 | `docs/CHINESE_COMMIT_GUIDE.md` 全文 | 缺 "Bug fix commit 模板" (R88 P0 silent data loss 是修 R84,**没单列 "P0 修" 模板**) | 底层 | 1 | P3 |
| 7 | `git log` 前 50 | R88 P0 修用了 `v0.30 round 88 (P0): data_export moodEntries 加 8 CBT 字段 toMap` — 格式 OK 但 **(P0)** 在 type 后,跟 `v0.30 round 88 (P0-1):` R67 格式混 | 底层 | 1 | P3 (微小) |
| 8 | `docs/CHINESE_COMMIT_GUIDE.md` 全文 | **0 个 squash 决策** 文档化 — R90 R91 实际用 `Merge: v0.30 round X sub-spec N` 形式,但指南 0 提 merge commit 该怎么写 | 底层 | 1 | P3 |
| 9 | `docs/GIT_WORKFLOW.md` 全文 | 缺 **CRLF/LF 跨平台决策** 详细 (只说"无害") — 实际开发机 1 台 Windows,跨国团队接入时 (法务 / 翻译外包) 会有问题 | 底层 | 1 | P3 |
| 10 | `AGENTS.md:257` | "提交风格：`<version> round <N>: <title>`" 单行,**CHINESE_COMMIT_GUIDE.md 是 detailed,但 AGENTS.md 引用格式没"type"槽位** — R82 上架冲刺批次 A 用 `(上架冲刺批次 A)` 注释槽位,R88 用 `(P0)` 槽位,3 种用法并存 | 底层 | 1 | P3 (风格统一) |

### B-2.3 总结

- **R82 已修**: 文档化 / PR 模板 / merge 风格 / 拆分 vs squash 决策表
- **仍欠**: 0 release tag / 2 个 `docs(sdd)` 风格不一致 / 无 BREAKING CHANGE 标记 / 缺 merge commit 详细模板

---

## B-3. 中文文档

> 范围: `docs/` (24 文件 5.2 MB) / `assets/legal/` (3 md) / `whitePaper/` / `README.md` / `AGENTS.md`

### B-3.1 文档清单 (按功能分类)

| # | 文件 | 大小 | 用途 | 评估 |
|---|---|---|---|---|
| 1 | `README.md` | 201 行 | 产品视角 / 快速开始 | ✅ 中文,5 段齐全 (产品/技术栈/功能/调试/打包/法律) |
| 2 | `AGENTS.md` | 290+ 行 | 代码视角 / AI 入口 | ✅ 中文,详尽 16 守门员 / 已知坑 18 条 |
| 3 | `docs/CHANGELOG.md` | 161 KB | 变更日志 | ✅ 中文 Keep-a-Changelog,R91 entry 5 段齐全 |
| 4 | `docs/DEPLOYMENT.md` | 14 KB | 部署指南 (4 周上架) | ✅ 中文,阶段 0-7 + 7.5 + 附录 A.1-A.4 + 附录 B 7 项 |
| 5 | `docs/SENDGRID_SETUP.md` | 5.6 KB | SendGrid 集成 | ✅ 中文,v0.22 R29 后已标注"mock-only,v1.0+ 真接" |
| 6 | `docs/SMS_PROVIDERS.md` | 7.5 KB | 阿里云/Tencent/Twilio 接入 | ✅ 中文,1 周+ 估时 |
| 7 | `docs/PUSH_PROVIDERS.md` | 7.9 KB | 5 厂商 push 通道接入 | ✅ 中文,R55 计划 1-2 月 |
| 8 | `docs/CHINESE_COMMIT_GUIDE.md` | 3.4 KB | 中文 commit 规范 | ✅ 中文,有缺陷见 B-2 |
| 9 | `docs/GIT_WORKFLOW.md` | 3.3 KB | Git 工作流 | ✅ 中文,单 master 决策 |
| 10 | `docs/terminology.md` | 7.7 KB | 中文术语集中器 | ✅ R59 决策 + ADR-059-1 |
| 11 | `docs/LEGAL_REVIEW_BRIEF.md` | 19 KB | 法务 review 简报 (12 P0 风险点) | ✅ 极详尽,P0-P1-P2 三级 |
| 12 | `docs/SPRINT1_LEGAL_TODO.md` | 2.3 KB | 4 项上架前必做 (律师/邮箱/仓库/域名) | ✅ 集中器 |
| 13 | `docs/STOREFRONT_RELEASE_SOP.md` | 10.8 KB | 上架前手动 checklist | ✅ 6 段 5 项 + 3 项 P0 |
| 14 | `docs/SPRINT2_TODO.md` | 7.6 KB | Sprint 2 TODO | ✅ 待评估 |
| 15 | `docs/PLAYSTORE_SIGNING_GUIDE.md` | 6.5 KB | Play Store 签名指南 | ✅ |
| 16 | `docs/VERSION_1.0_PLAN.md` | 4.6 KB | v1.0 路线图 | ✅ |
| 17 | `docs/WHITEPAPER.md` | 58 KB | 一站式项目档案 | ✅ 19 章 + 文档地图 (PM/Dev/Designer/QA) |
| 18 | `docs/LEGACY_API_NOTES.md` | 3 KB | 旧 API 备注 | ✅ |
| 19 | `assets/legal/privacy_policy.md` | 14 KB | 隐私政策 (PIPL/HIPAA/GDPR) | ✅ 14 章,标注"草稿 未经律师过审" |
| 20 | `assets/legal/user_agreement.md` | 5.3 KB | 用户协议 | ✅ 标"草稿" |
| 21 | `assets/legal/sensitive_data_consent.md` | 6 KB | 敏感个人信息处理同意书 (PIPL §28-29) | ✅ 8 章,含 5 地区心理危机热线 (R83) |
| 22 | `whitePaper/慢病管家-白皮书-v3.0.md` | - | 商业白皮书 | ✅ |
| 23 | `docs/decisions/v0.24_round48_*.md` | 4 文件 | 设计决策记录 (ADR) | ✅ |
| 24 | `docs/reviews/`, `docs/evaluations/`, `docs/refactor/` | - | 历次审查 / 评估 | ✅ |
| 25 | `docs/superpowers/sdd-logs/r84-91` | 8 子目录 | sub-spec 5-7 ledger | ✅ R89 AI-rolledback ledger 体现诚实验证 |

### B-3.2 优势 (做得好)

| # | 项 | 证据 | 评估 |
|---|---|---|---|
| 1 | **WHITEPAPER §0 文档地图 (按角色查)** | 5 角色 × 重点章节表 | 优秀 — 上手成本低 |
| 2 | **LEGAL_REVIEW_BRIEF 12 P0 风险点** | 12 P0 + 多 P1 + 多 P2 | 优秀 — 律师 5 分钟可读 |
| 3 | **5 地区心理危机热线 (R83)** | 大陆 2 + 港澳台 3 | 优秀 (法务 P1 修了) |
| 4 | **术语集中器 + 罗马化规则** | terminology.md §7 | 优秀 (底层规范) |
| 5 | **CHANGELOG R88 R89 诚实记录** | R89 "AI-rolledback ledger" 显式记录 sub-spec 5 实施 + flag 隐藏 | 优秀 (工程诚信) |
| 6 | **DEPLOYMENT 阶段 0-7 + 7.5 + 附录 A-D** | 5 阶段 + 上架前 must-check + 4 份合规声明模板 | 优秀 |
| 7 | **白皮书 19 章覆盖** | 愿景/用户/商业模式/机制/技术/架构/数据/业务/测试/通知/树洞/设计/路线/团队/风险/法律/坑/ADR | 优秀 |
| 8 | **`AGENTS.md` AI 入口完整** | 5 必读文件 / 命名约定 / 4 层架构 / 16 守门员 / 18 已知坑 | 优秀 |
| 9 | **README 双语描述** (R69) | "我今天吃了药 - ChronicCare: medication reminder & mood tracker..." | 优秀 |
| 10 | **白皮书 文档地图按角色** | PM/Dev/Designer/QA/接手者 5 视图 | 优秀 |
| 11 | **decisions/ v0.24_round48_design_decisions.md** | 4 个 ADR (token / i18n / PIPL / etc) | 优秀 |

### B-3.3 问题清单

| # | 文件:行 | 问题 | 类型 (架构/底层) | 难度 | 优先级 |
|---|---------|------|----------------|------|--------|
| 1 | `docs/CHANGELOG.md:5-43` (R91 entry) + 上一 entry `:44-...` (R90 fix) + 上一 `:...-...` (R90 i18n) | **3 个 0.30.0 R90/R91 entry 同日期** (2026-08-05),CHANGELOG 顺序跟 git log 顺序不严格 1:1,**changelog 阅读体验差** | 底层 | 1 | P1 |
| 2 | `docs/CHANGELOG.md` 整体 | **同版本多次 entry** (0.30.0 R88 + R90 + R91 fix + R91 i18n + R91 ui),没按 sub-spec 编号 R88 → R90 → R91,**新读者混乱** | 底层 | 1 | P1 |
| 3 | `docs/CHANGELOG.md` 整体 | **缺 0.27 R55 R66 R67 R68 R69 详细 entry** — AGENTS.md 提了 v0.23 R41 + v0.24 R45 + v0.25 R56b-e + v0.27 R62 R65 R67 R70 R72 R77 R82 R83,**CHANGELOG 跳了很多 R** | 底层 | 2 | P2 |
| 4 | `README.md:23-26` | 快速开始用 `brew install fvm / fvm install 3.41.9` — **当前 pubspec 是 `0.30.0+85` (8 月),但版本没标日期** (用户复用时不知道 SDK 是否需更新) | 底层 | 1 | P3 |
| 5 | `README.md:131` | "v0.25 round 56e 后 1098 cases" — **过时**,R91 实际 1617 cases (跨 6 round 增 519) | 底层 | 1 | **P1** (跟 R91 CHANGELOG 不一致) |
| 6 | `README.md:170` | "SMS 走阿里云占位（v0.25 R55 上正式接入）" — **R55 仍 0 真接**,README 误导 | 底层 | 1 | **P0** (上架前必修) |
| 7 | `README.md:172-173` | "国产 ROM 静默杀后台通知：需接入 5 厂商 push (小米 / 华为 / OPPO / Vivo / 魅族) 才能让推送送达率达 95%+ (R55 计划)" — **R55 计划仍 0 接** | 底层 | 1 | **P0** (上架前必修) |
| 8 | `docs/DEPLOYMENT.md:46-...` (阶段 5/6 缺失) | 阶段 5 (iOS 上架描述) / 阶段 6 (Android 上架描述) **整段缺失** — 跳到阶段 7 / 7.5 / 8 | 架构 | 1 | P1 (DEPLOYMENT 不完整) |
| 9 | `docs/DEPLOYMENT.md:269` (参考) | "类似 Google Play" 一句话带过 — 缺 Apple App Store 完整 metadata 模板 | 底层 | 1 | P1 |
| 10 | `docs/DEPLOYMENT.md` 整体 | 缺 **上架被拒后怎么申诉 / 重新提交流程** | 底层 | 1 | P2 |
| 11 | `docs/SENDGRID_SETUP.md:6-8` | "当前 EmailService 是 mock-only" — **但 R67 B-1 加了 `EmailService.validateForRelease` 启动守卫**,**文档没更新** (R67 → 文档不同步) | 底层 | 1 | P2 |
| 12 | `docs/SENDGRID_SETUP.md:101` | `useMock: true, // v0.22 当前必须 true, 真实发送 v1.0+` — 注释 vs 文档一致 | 底层 | 1 | P3 |
| 13 | `docs/SMS_PROVIDERS.md:33-34` | 模板示例: "我是${userName}，已${days}天没在App里打卡吃药。请你方便的时候提醒我按时吃药，避免复发。" — **"App" 混用** (terminology.md §2 禁用) | 底层 | 1 | P1 |
| 14 | `docs/PUSH_PROVIDERS.md` 整体 | 5 厂商 push 通道 — **SDK 包名 + 接入步骤是 R55 计划但未实施,文档走在代码前面** | 底层 | 1 | P2 (诚实但易误读) |
| 15 | `docs/STOREFRONT_RELEASE_SOP.md` 整体 | "上架前手动 checklist" — 但 **5 项必做中 0 项已完成** (域名 / keystore / 4 表单 / 4 ID / 律师 review),**自身就是 P0 阻塞清单** | 底层 | 1 | P1 (诚实) |
| 16 | `docs/LEGAL_REVIEW_BRIEF.md` 整体 | 12 P0 风险点 — **3 个 P0 (失联通知暂停 / 紧急联系人 §23 / IAP 暂停) 业务整体暂停仍未上 store 前解决** | 架构 | 5 | **P0** |
| 17 | `docs/LEGAL_REVIEW_BRIEF.md:134-142` (§1.7 树洞敏感数据) | 树洞是否属"敏感个人信息" — **未明确分类**,法务 0 签字 | 架构 | 3 | **P0** |
| 18 | `docs/LEGAL_REVIEW_BRIEF.md:144-160` (§1.8 SDK 披露) | 第三方 SDK 列 6 个,实际 16+ 依赖 — **R82 评估缺 in_app_purchase / speech_to_text / pdf / printing / permission_handler** | 架构 | 2 | **P0** (Google Play Data Safety 必填) |
| 19 | `docs/LEGAL_REVIEW_BRIEF.md:176-189` (§1.10 心理热线) | 4 国危机热线完整? — 当前 R83 加了 5 条 (大陆 2 + 港澳台 3),**缺美国 / 英国 / 国际英语 24/7 热线** (英文 locale 用户看不适用) | 底层 | 1 | P1 |
| 20 | `assets/legal/privacy_policy.md:8-20` (§0 同意记录) | 4 个 consent 字段 (`userAgreementVersion / privacyPolicyVersion / sensitiveDataConsentAt / consentRevokedAt`) — **PIPL §54 "PII 处理活动记录"** 字段有,但**未实施"全量审计日志"** (consent withdrawal 没记录到 audit log) | 架构 | 3 | P1 |
| 21 | `assets/legal/privacy_policy.md:30-41` (§1 信息收集) | "设备信息 ... 仅本地判断通知兼容性 ... 不存储不上传" — **AGENTS.md / 代码说"log 设备型号做 OEM 引导"**,**文档 vs 代码矛盾** | 底层 | 1 | **P0** (Apple 5.1.1 拒) |
| 22 | `assets/legal/sensitive_data_consent.md:88-91` (底部声明) | "继续使用本 App,即视为您已阅读" — **"App" 混用**,应"继续使用本应用" (terminology.md §2) | 底层 | 1 | P1 |
| 23 | `assets/legal/sensitive_data_consent.md:36` | "树洞数据**不**包含在"导出 JSON"中(只导出文字,录音因路径问题无法跨设备复用)" — **跟 `docs/CHANGELOG.md:32-43` R88 P0 silent data loss 修矛盾** (R88 修了树洞文字导出,R83 之前声明 "不导出" 已过期) | 底层 | 1 | **P0** (PIPL 告知不准确) |
| 24 | `assets/legal/privacy_policy.md:65-71` (撤回同意) | "撤回后该功能立即停用,**数据不删除**" — **LEGAL_REVIEW_BRIEF §1.7 标 P0 "撤回后保留旧数据是否合规"** | 架构 | 3 | **P0** (PIPL §47 删除权) |
| 25 | `assets/legal/privacy_policy.md:73` | "注销权 | 卸载 App = 完全注销" — **"App" 混用** + **跟 §0.5 业务整体暂停矛盾** (隐私政策仍说"未来失联通知会发",但 release 模式 0 触发) | 底层 | 1 | **P0** (PIPL §17) |
| 26 | `docs/` 整体 | **缺图表 / 流程图 / 架构图 / 截图** — 24 文档纯文字 | 底层 | 2 | P2 (可视化) |
| 27 | `docs/decisions/v0.24_round48_*.md` | **v0.30 R91 0 决策记录** — 大型 sub-spec 7 实施未独立 ADR | 底层 | 1 | P2 |
| 28 | `docs/CHANGELOG.md:332+` (R87 之后) | **R85 R86 R87 几轮 R 跳号缺** (R85 fix 段没说清, R86 final 段在 R87 entry 后面) | 底层 | 1 | P2 |
| 29 | `whitePaper/慢病管家-白皮书-v3.0.md` | **最后更新 2026-07-20 v0.22**,**没同步到 v0.30 R91** (跨 4 月 / 9 大 round) | 底层 | 2 | P1 (白皮书 1 月没更新) |
| 30 | `docs/WHITEPAPER.md:4` | 顶部说"写给团队（PM / Dev / Designer / QA / 后续接手者）" — **但内容偏 Dev**,**PM/QA 章节缺** (§3 商业模式 / §9 测试策略 / §13 路线图有,但 §14 团队分工 / §15 风险 待补) | 底层 | 2 | P2 |
| 31 | `README.md:181-198` (法律与合规) | 4 项"上 store 前必修" — **3 项 (律师过审 / 软件著作权 / ICP) 全是 P0 阻塞**,但**未标红色 banner** | 底层 | 1 | P1 |
| 32 | `docs/CHANGELOG.md` + `docs/AGENTS.md` | **R91 之后 (8-05 → 8-06) 1 天空窗,无新 round** — 文档同步 OK | — | — | — |

### B-3.4 总结

- **R58 R67 R82 R83 已修**: 4 份 doc 集中化 / PIPL §13 §14 文档化 / 5 地区心理危机热线 / LEGAL_REVIEW_BRIEF 12 P0 风险点
- **仍欠**: CHANGELOG 顺序乱 / README 测试数 1098→1617 过时 / DEPLOYMENT 阶段 5/6 缺失 / R67 EmailService validateForRelease 文档没更新 / 3 份 legal md "App" 混用 / 隐私政策 §1 跟代码矛盾 / 法律 md "App" 混用 / 撤回同意后数据不删除合规性 / 树洞分类 / SDK 披露不完整

---

## B-4. 中文 Git 工作流

> 范围: `.git/` / `.worktrees/` / `.github/` / `docs/GIT_WORKFLOW.md` / `docs/CHINESE_COMMIT_GUIDE.md` / git remote / branch

### B-4.1 优势 (做得好)

| # | 项 | 证据 | 评估 |
|---|---|---|---|
| 1 | **单 master 分支决策** (单 dev) | 文档化在 `GIT_WORKFLOW.md` §Branch 策略 | 架构级 (合理 — 单 dev 不需要 gitflow) |
| 2 | **PR 模板 6 段 checklist** | `.github/PULL_REQUEST_TEMPLATE.md` 中文 6 段 (命名/测试/资源/架构/可读/上架) | 优秀 (国内少见的工程规范) |
| 3 | **CI 集成 16 守门员** | `.github/workflows/ci.yml` 17 step (含 dart format / flutter analyze / flutter test / 16 守门员 / architecture / build apk+web) | 优秀 (CI 3 job) |
| 4 | **CODEOWNERS 模板** | `.github/CODEOWNERS` 9 段 (顶层 + 架构核心 + 上架相关 + 测试 + 守门员) — 但**全是 `@maintainer` 占位** | 底层 (有但 0 实施) |
| 5 | **R82 release 冲刺 commit** | 431 commits 100% 遵循 `<version> round <N>` | 优秀 |
| 6 | **AGENTS.md "提交风格" 段** | 强制 `<version> round <N>: <title>` 格式 | 优秀 |
| 7 | **worktree 命名 `feat-cbt-thought-report`** | `.worktrees/feat-cbt-thought-report` kebab-case 命名 | 优秀 |

### B-4.2 问题清单

| # | 文件:行 | 问题 | 类型 (架构/底层) | 难度 | 优先级 |
|---|---------|------|----------------|------|--------|
| 1 | `.git/` | **`git remote -v` 返空** — **0 remote** (无 GitHub / GitLab 仓库配置) | 架构 | 1 | **P0** (SPRINT1_LEGAL_TODO §3 占位 `https://github.com/example/chroniccare/issues`,R82 未做) |
| 2 | `.git/` | **`git tag -l` 返空** — **0 release tag** (GIT_WORKFLOW.md §Tag/Release 说"每个 minor version 打 tag",**实际 0 tag** ) | 架构 | 1 | **P0** (上架前必修) |
| 3 | `.worktrees/feat-cbt-thought-report/` | **单 worktree 残留** — `git worktree list` 只有 master,R88 CBT 实施完 worktree 仍存在,**未清理** | 底层 | 1 | P1 (清理) |
| 4 | `.worktrees/feat-cbt-thought-report/.superpowers/` | worktree 内有 `.superpowers/` 子目录 — **sdd state 跟主仓库混** | 底层 | 1 | P2 (清理) |
| 5 | `.github/CODEOWNERS:7` | 全部 `@maintainer` 占位 — **0 个真实 owner** | 底层 | 1 | P1 (法务 owner / 翻译 owner 待加) |
| 6 | `.github/PULL_REQUEST_TEMPLATE.md:43` | "commit message 格式 `<version> round <N>: <title>`(豁免 Conventional Commits)" — **豁免没说决策依据** | 底层 | 1 | P3 |
| 7 | `.github/workflows/ci.yml:7` | `pull_request: branches: [master, main]` — **项目只有 master 1 个 branch**,`main` 不会触发 | 底层 | 1 | P3 (清理) |
| 8 | `.github/workflows/ci.yml` 整体 | **缺 release build job**(apk + web debug 是,**apk release + ipa release 0**),DEPLOYMENT.md R72 keystore 脚本生成后,没 CI 验证签名 | 架构 | 2 | P1 (上架前必修) |
| 9 | `.github/workflows/ci.yml` 整体 | **缺 iOS build job** (Xcode 需要 macOS runner,Linux runner 跑不了) — DEPLOYMENT 阶段 4 iOS 打包需手动 macOS | 架构 | 3 | P1 (上架前必修) |
| 10 | `.github/workflows/ci.yml` 整体 | **缺 nightly 16 守门员全跑 + pub.dev outdated 检查** (现 17 step 都在 push/PR 触发) | 底层 | 1 | P3 |
| 11 | `.github/workflows/ci.yml:158` | `flutter build apk --debug` + `flutter build web --release` — **没跑 `flutter build appbundle --release`** (上架 R72 keystore 脚本后,16KB alignment 必验) | 架构 | 2 | P1 (上架前必修) |
| 12 | `.github/workflows/ci.yml` 整体 | **缺 `aapt dump badging` / `objdump` 16KB alignment 实跑** (R70 验证脚本只是文档化,CI 没自动跑) | 架构 | 2 | P1 (上架前必修) |
| 13 | `AGENTS.md` + `GIT_WORKFLOW.md` | **缺 cherry-pick / rebase 流程** (Round 之间 "回退 / 重写 (e.g. round 8 失败 → round 8a redo)" 提到用 `git stash`,**但 0 详细**) | 底层 | 1 | P3 |
| 14 | `GIT_WORKFLOW.md:73-80` (§Branch 策略) | "单 master, 不开 feature branch" — **R88 CBT 实际用了 `.worktrees/feat-cbt-thought-report` 临时 worktree**,**文档跟实践矛盾** | 底层 | 1 | P2 (更新) |
| 15 | `GIT_WORKFLOW.md:78-80` | "大型实验 (e.g. feature-first refactor 失败回退) 临时用 `git stash` 而非 branch" — **R88 CBT PDF 实际用 worktree,不是 stash**,**文档 0 提到 worktree 用法** | 底层 | 1 | P2 (更新) |
| 16 | 整个 git log | **0 个 `Revert:` / `Revert "..."` commit** — R89 AI-rolledback 实际是 `e5af96d docs(sdd): round89-ai-rolledback ledger` (R89 sub-spec 5 flag 隐藏,**实质 revert 但没用 Revert 标记**) | 底层 | 1 | P2 |
| 17 | 整个 git log | **0 个 `Signed-off-by:` / `Co-authored-by:` / `Refs:` trailers** — 法务 review / 翻译 review 0 留痕 | 底层 | 1 | P2 (法务 review 流程) |
| 18 | `AGENTS.md:259-289` (已知坑) | **"PIPL §13 单独同意"等法务风险在 known issues 段没列** — 全部是技术坑 (schemaVersion / Stream subscription / DateTime race / 国产 ROM),**法务坑 0 列入** | 底层 | 1 | P1 (上 store 前必修) |
| 19 | `AGENTS.md:160-289` (已知坑) | 18 个 known issues — **0 个 merge / rebase / worktree 坑** (B-4-#13 #14 缺口) | 底层 | 1 | P3 |
| 20 | `AGENTS.md:283-289` (Stage 16-19 决策) | 4 阶段 P0-P3 + Round 38-44 历史 — **v0.30 R91 后续 P0 缺口 (失联通知 / IAP / 5 厂商 push / SMS / Email) 未列** | 底层 | 1 | P1 (上 store 前必修) |

### B-4.3 总结

- **R82 R83 已修**: PR 模板 6 段 / CI 16 守门员 / 提交风格 / CODEOWNERS 占位
- **仍欠**: 0 remote / 0 release tag / worktree 残留 / CODEOWNERS 全占位 / iOS+release build CI 缺失 / 16KB alignment CI 实跑缺失 / 法务 review 流程 / worktree vs stash 文档矛盾

---

## C. 国内合规 / 资质

> **核心评估**: 项目自定 `docs/LEGAL_REVIEW_BRIEF.md` 12 P0 风险点 + `docs/SPRINT1_LEGAL_TODO.md` 4 项上架前必做 + `docs/DEPLOYMENT.md` 附录 A.1-A.4 + 附录 B 7 项,**文档链路已完整,但实际 0 实施 = 中国 store 上架 P0 全线阻塞**。

### C-1. 必做项 (上架 / 法务 — P0 阻塞)

| # | 项 | 状态 | 阻塞 | 估时 | 责任方 |
|---|---|---|---|---|---|
| 1 | **PIPL §13 单独同意** (联系人 / 数据导出 / 失联通知) | ✅ R58 R62 R67 已实施 + ConsentArtifact + consentDialog + audit log | — | 0 | 工程 |
| 2 | **PIPL §14 撤回同意** (业务层真接) | ✅ R67 已修 (ventRepository.add 拒绝 / careEngine.fire 早返 / trend_page 占位) | — | 0 | 工程 |
| 3 | **PIPL §17 告知不准确** (失联通知业务暂停 vs 隐私政策仍描述) | ❌ 业务暂停 + 隐私政策 §0.5/§3/§12 仍描述 | **P0** | 1-2 周 (修文案) | 法务 |
| 4 | **PIPL §23 紧急联系人单独告知** (业务暂停期间软实施够不够) | ❌ 法律风险等级:中,业务暂停 ≠ 文本撤回 | **P0** | 1-2 周 | 法务 |
| 5 | **PIPL §28 敏感个人信息分类** (树洞是否属"敏感个人信息") | ❌ 隐私政策 §2.2 + sensitive_data_consent §2.2 都标"最高敏感"但 0 法务签字 | **P0** | 1-2 周 | 法务 |
| 6 | **PIPL §38 跨境 PII 传输** (用户加境外紧急联系人 → SMS 跨境) | ❌ 业务暂停,但**隐私政策 §11 仍描述** | **P0** | 1-2 周 (文案) + 4-6 周 (标准合同备案) | 法务 + 工程 |
| 7 | **PIPL §44 数据可携权** (导出受理记录保存) | ✅ R82 ConsentDialog + LegalConsentStore.recordDataExportConsent | — | 0 | 工程 |
| 8 | **PIPL §47 用户删除权** (撤回同意后数据**不删除**是否合规) | ❌ R67 决定"数据不删除,可重新开启",LEGAL_REVIEW_BRIEF §1.7 标 P0 | **P0** | 1-2 周 (法务评估) | 法务 |
| 9 | **PIPL §50 投诉渠道** (软隐藏邮箱是否合规) | ❌ `privacy@chroniccare.app` 软隐藏,未成年人 7 工作日响应机制 0 实施 | **P0** | 1 周 (注册邮箱 + 7 工作日响应 SOP) | 法务 |
| 10 | **PIPL §51 加密要求** (AES-256 + 密钥管理) | ✅ SQLCipher AES-256 + flutter_secure_storage (iOS Keychain / Android Keystore) + 点对点独立密钥 | — | 0 | 工程 |
| 11 | **PIPL §54 PII 处理活动记录** (全量审计日志) | ❌ 4 个 consent 字段有,但**全量 audit log 0 实施** (consent withdrawal 没记录到 audit log) | **P0** | 1-2 周 | 工程 + 法务 |
| 12 | **NMPA "非医疗器械" 声明 PDF** (中国大陆上架必需) | ⏳ DEPLOYMENT 附录 A.1 模板已写,**律师过审后 0 实际生成 PDF** | **P0** | 1-2 周 (法务签字 + PDF 排版) | 法务 |
| 13 | **HIPAA / GDPR 律师过审** (国际 store) | ⏳ DEPLOYMENT 附录 A.2-A.3 模板已写,**0 实际律师 review** | **P0** | 1-2 周 (国际律师 ¥15-30k/文档) | 法务 |
| 14 | **3 份法律 md 律师过审** (隐私政策 / 用户协议 / 敏感数据同意书) | ⏳ R82 R83 已改 5+ 措辞,但**仍是"草稿 未经律师过审"** | **P0** | 1-2 周 + ¥45-90k | 法务 |
| 15 | **隐私 URL `https://chroniccare.app/privacy` 真接** | ❌ `support@chroniccare.app` + 域名 + ICP 备案 0 实施 (SPRINT1_LEGAL_TODO §1-§4) | **P0** | 1-2 天 (域名) + 7-20 天 (ICP) + 4 份 HTML | 工程 + 法务 |
| 16 | **5 厂商 push SDK 接入** (送达率 95%+) | ❌ PUSH_PROVIDERS.md 计划 1-2 月,**0 实施** | **P0** | 1-2 月 | 工程 + 厂商审核 |
| 17 | **阿里云 SMS 真接** (失联通知 production 必需) | ❌ AliyunSmsProvider.send() 仍 UnimplementedError,R58 降为 warn-only | **P0** | R55 1-2 天 + 阿里云审核 2-4 周 | 工程 + 法务 (模板话术) |
| 18 | **Twilio 跨境 + 标准合同备案** (PIPL §38) | ❌ SMS_PROVIDERS.md §3 计划,0 实施 | **P0** | 1-2 月 (Twilio 代理签标准合同 + 备案) | 法务 |
| 19 | **SendGrid 真接** (邮件通道) | ❌ EmailService mock-only,v0.22 R29 删 dio 依赖 | **P0** | 1-2 周 + 模板审核 | 工程 + 法务 |
| 20 | **软件著作权登记** (CPDA 受理) | ❌ 0 申 | **P0** | 1-2 月 (CPDA) | 法务 |
| 21 | **ICP 备案** (中国大陆 5 store 必需) | ❌ 0 申 (SPRINT1_LEGAL_TODO §1) | **P0** | 7-20 天 (阿里云 / 腾讯云备案系统) | 法务 |
| 22 | **`chroniccare.app` 域名注册 + HTTPS 部署** | ❌ 0 注 (SPRINT1_LEGAL_TODO §1) | **P0** | 1-2 天 (域名) + 1 天 (Cloudflare / Vercel 部署) | 工程 |
| 23 | **`support@chroniccare.app` 邮箱注册** | ❌ 0 注 (SPRINT1_LEGAL_TODO §2) | **P0** | 1-2h (邮箱注册 + 替换 3 处) | 工程 |
| 24 | **GitHub 仓库创建** (issue 区作为"便捷渠道") | ❌ `https://github.com/example/chroniccare/issues` 占位 (SPRINT1_LEGAL_TODO §3) | **P0** | 0.5 天 | 工程 |
| 25 | **IAP 业务整体暂停** (user_agreement §3 写"8 元买断" vs 实际 0 入口) | ❌ `_prodIapEnabled = false` (LEGAL_REVIEW_BRIEF §1.3 P0) | **P0** | 1-2 周 (二选一:删文案 / 启用 IAP) | 法务 + 工程 |
| 26 | **Data Safety Form 跟代码实际数据收集一致** | ❌ generate_data_safety_form.py 已写脚本,3 份 SDK 缺 (LEGAL_REVIEW_BRIEF §1.8) | **P0** | 0.5 天 (跑脚本 + 修 SDK 列表) | 工程 |
| 27 | **Apple App Store 4 表单** (App Privacy / Permissions / Health Apps / Data Deletion) | ❌ DEPLOYMENT 阶段 5 缺,**0 实际填写** | **P0** | 0.5-1 天 | 工程 |
| 28 | **Google Play Data Safety Form** | ❌ 0 填 (generate_data_safety_form.py 已脚本化) | **P0** | 0.5-1 天 | 工程 |
| 29 | **Android keystore + Play App Signing** | ❌ R72 generate_release_keystore.ps1 脚本已写,**0 实际跑** (SPRINT1_LEGAL_TODO §3) | **P0** | 1-2h (Android) + 30min (iOS macOS) | 工程 |
| 30 | **Apple App Store Connect 4 ID** (fastlane/Appfile) | ❌ 4 个 TODO 占位 (apple_id / team_id / itc_team_id / app_identifier) | **P0** | 1h (用户填真实值) | 工程 |
| 31 | **8 元定价平台一致性** (Apple 30% 抽成 / Google Play 15% 前 100 万美元) | ❌ LEGAL_REVIEW_BRIEF §1.12 标 P0 | **P0** | 1-2 周 (法务评估定价) | 法务 |
| 32 | **未成年人 14-18 周岁验证** (PIPL §31) | ❌ "勾选"不是真正验证 (LEGAL_REVIEW_BRIEF §1.11 P0) | **P0** | 1-2 周 (身份证 OCR / 活体检测 OR 保留"勾选"+ 风险披露) | 法务 + 工程 |
| 33 | **5 地区心理危机热线** (中/英/国际 24/7) | ⚠️ R83 加了 5 条 (大陆 2 + 港澳台 3),**缺美/英/国际** (LEGAL_REVIEW_BRIEF §1.10) | P1 | 0.5 天 (R83.5 加 3-4 条 + 12 ARB key) | 工程 |
| 34 | **算法透明性 PIPL §24** (失联检测算法说明 + 拒绝方式) | ⏳ R67 撤回同意修了拒绝方式,**算法逻辑未告知** (LEGAL_REVIEW_BRIEF §1.9) | P1 | 1 周 (法务 + 文案) | 法务 + 工程 |
| 35 | **算法偏见 / 误判反馈机制** (LEGAL_REVIEW_BRIEF §2.3) | ❌ 0 实施 | P2 | 1-2 周 | 工程 |
| 36 | **数据导出风险告知** (明文 JSON 误传风险) | ❌ LEGAL_REVIEW_BRIEF §1.4 P0 — 用户导出 → 误传 → 第三方抓取责任边界 | **P0** | 1 周 (法务 + 强制加密 + 风险提示) | 法务 + 工程 |

### C-2. 建议项 (P1-P2)

| # | 项 | 状态 | 优先级 | 估时 |
|---|---|---|---|---|
| 37 | **设备信息收集描述 (PIPL §26 个人信息处理者义务)** | ⚠️ "仅本地判断通知兼容性" 措辞弱 (LEGAL_REVIEW_BRIEF §2.1) | P1 | 1-2 天 |
| 38 | **树洞数据导入设备绑定** (LEGAL_REVIEW_BRIEF §2.2) | ❌ 0 实施 (PIPL §28 树洞分类先) | P1 | 1-2 周 |
| 39 | **多设备同步策略** (LEGAL_REVIEW_BRIEF §2.2) | ❌ 0 实施 (本地存储) | P2 | v1.0+ |
| 40 | **BootReceiver WorkManager** (R65 标 TODO) | ❌ `_prodBootReceiverEnabled = true` 但**实际 0 实现**,靠 flutter_local_notifications 兜底 | P1 | 1-2 周 |
| 41 | **腾讯云短信备选** (阿里云模板审核失败时) | ❌ 0 接入 (SMS_PROVIDERS.md §2) | P2 | 1-2 周 (审核 1-2 周) |
| 42 | **Twilio 海外通道真接** | ❌ 0 接入 (SMS_PROVIDERS.md §3) | P2 | 1 周 + 跨境备案 1-2 月 |
| 43 | **第三方 SDK DPA 协议** (16+ 依赖) (LEGAL_REVIEW_BRIEF §1.8) | ❌ 0 签订 | P1 | 1-2 月 |
| 44 | **华为应用市场单独签名** (跟 Google Play 不同 keystore) | ❌ 0 实施 (DEPLOYMENT.md §8.1) | P1 | 1-2 天 |
| 45 | **OPPO / vivo 单独签名 + 隐私 URL** | ❌ 0 实施 (DEPLOYMENT.md §8.1) | P1 | 1-2 天 |
| 46 | **文网文 / 互联网药品信息服务资格** (精神心理类 / 药品类) | ❌ 0 评估 (项目涉及"吃药""处方") | **P0** (上 store 前必查) | 1-2 月 (药监局审核) |
| 47 | **算法备案** (中国互联网信息服务算法推荐管理规定) | ❌ 失联检测算法属"自动化决策",需备案 (网信办) | **P0** | 1-2 月 (网信办审核) |
| 48 | **软件评测 / 软件产品登记** (CPDA 软著外) | ❌ 0 实施 | P2 | 1-2 月 |
| 49 | **欧盟 GDPR Data Protection Officer (DPO)** (海外 store) | ❌ 0 实施 (LEGAL_REVIEW_BRIEF §1.5 跨境) | P1 | 1-2 周 |
| 50 | **CCPA / CPRA (加州消费者隐私法)** (Google Play 美国) | ❌ 0 评估 (跟 GDPR 类似) | P1 | 1-2 周 |
| 51 | **鸿蒙 / HarmonyOS NEXT 适配** (P50 鸿蒙 native) | ❌ 0 实施 (PUSH_PROVIDERS.md 提"EMUI / HarmonyOS"但**鸿蒙 NEXT 0 适配**) | P1 | 1-2 月 (华为审核) |
| 52 | **小米 / 华为 / OPPO / vivo / 魅族 推送回执** (送达率监控) | ❌ 0 实施 (PUSH_PROVIDERS.md §6 监控) | P1 | 1-2 周 (实施 5 厂商回执 API) |
| 53 | **微信小程序版** (腾讯应用宝 + 微信生态) | ❌ 0 计划 (但 5 store 中 1 个是腾讯应用宝) | P2 | 1-2 月 |
| 54 | **百度贴吧 / 知乎软文** (市场推广) | ❌ 0 计划 (但 1 精神病互助 1 千万用户) | P2 | — |

### C-3. 总结

**P0 阻塞总数**: 36 项 (上架前必修)
**P1 关注**: 11 项
**P2 建议**: 7 项

**关键链路依赖**:
- 法务 review (¥45-90k, 1-2 周) → 隐私 URL 真接 → 域名 + ICP → 5 商店 4 store 备案 → Play Console / App Store Connect 填表
- 阿里云 SMS (R55 1-2 天 + 2-4 周审核) → 失联通知真接 → R67 撤回同意后业务真接
- 5 厂商 push (1-2 月审核) → 国产 ROM 送达率 95%+ → 失联通知送达
- 软件著作权 (1-2 月) + ICP (7-20 天) + 域名 (1-2 天) + 邮箱 (1-2h) + GitHub (0.5 天) = 7-9 周最关键路径
- 律师 review + IAP 决策 + IAP 真接 = 6-8 周

**总估时**: 3-6 月 (法务 + 厂商审核 + 备案是瓶颈),DEPLOYMENT.md 附录 B 自评 "3-6 月" 准确。

---

## D. 简繁一致性

> 范围: `lib/l10n/app_zh.arb` (101 KB / 1000 keys) / `app_zh_Hant.arb` (101 KB / 1000 keys) / `app_en.arb` (102 KB / 1000 keys) / `check_zh_hant_consistency.py` OpenCC s2tw

### D-1. 实测结果 (2026-08-06 跑守门员)

| 项 | 状态 | 详情 |
|---|---|---|
| `check_arb_keys.py` | ✅ | zh 1000 / en 1000 / zh_Hant 1000, **双向 0 缺漏** |
| `check_orphan_arb_keys.py` | ✅ | 1000 zh / 0 orphan |
| `check_zh_hant_consistency.py` | ✅ | 1000 keys, 100% 繁简一致 (OpenCC s2tw) |
| `check_fullwidth_punctuation.py` | ⚠️ | 135 violations,R58 降为 warn-only |

### D-2. 优势 (做得好)

| # | 项 | 证据 | 评估 |
|---|---|---|---|
| 1 | **3 lang 全量同步** (zh / en / zh_Hant) | 1000 keys × 3 lang | 优秀 |
| 2 | **OpenCC s2tw 自动化** (不用手写繁体) | `check_zh_hant_consistency.py` 复算 zh → 繁中,跟现有 hant 比 | 优秀 (架构级) |
| 3 | **R78 PHQ-9 / GAD-7 双向扩 8 量表** | R90 134 ARB keys (8 新量表 × 6 类别 + 8 中心化入口) × 3 lang | 优秀 |
| 4 | **R87 mood 列表页 i18n** | 12 ARB keys × 3 lang | 优秀 |
| 5 | **R88 CBT PDF 5 keys** × 3 lang | 5 ARB keys (cbtExportPdf*) | 优秀 |
| 6 | **R91 73 keys sub-spec 7** × 3 lang | 7 子功能 + 整合入口 + period + 类型 + regularity | 优秀 |
| 7 | **`flutter gen-l10n` 反复误删 3 个 `ventDuration*` 键 (R88 known regression)** | R88 已记 `gen_l10n_diff_check.py` TODO | 诚实 |
| 8 | **3 心理危机热线 5 地区 × 3 lang** (R83) | 12 crisisHotlineCn/Tw/Hk/Mo 3-tuple × 3 lang | 优秀 |

### D-3. 问题清单

| # | 文件:行 | 问题 | 类型 (架构/底层) | 难度 | 优先级 |
|---|---------|------|----------------|------|--------|
| 1 | `lib/l10n/app_zh_Hant.arb` 整体 | 1000 keys 全用 OpenCC s2tw 自动转换,**未人工 review 台湾用字差异** ("软件/软体" "网络/网路" "默认/预设" "数据库/资料库" "默认/預設") | 底层 | 2 | P2 (台湾用户阅读体验) |
| 2 | `lib/l10n/app_*.arb` 整体 | 缺 **`zh_Hant_HK` (香港粤语) / `zh_Hant_MO` (澳门) locale 细分** — R83 心理危机热线 3-tuple (HK 2389 2222 / MO 2826 1122) 有,但 ARB locale 是 `zh_Hant` (台湾),**香港 / 澳门用户看台湾繁体** | 架构 | 4 | P2 (港澳用户阅读体验) |
| 3 | `lib/l10n/app_*.arb` 整体 | R90 8 新量表题目全文 (`l10n.isiItem` 等) **返 `''` 兜底** (R78 决策留 v1.0),**en / zh_Hant locale 用户看 PHQ-9 中文 const class 题目** (15 量表 × 5-12 题 = ~70 题目 keys 暂不加) | 架构 | 4 | P1 (v1.0 大工程, 法务 + 临床翻译) |
| 4 | `scripts/check_zh_hant_consistency.py` | 缺 **纯繁中"台湾用字"特殊 token 检查** ("网路" "软体" "滑鼠") — 跟大陆简体习惯性差异 | 底层 | 2 | P2 (添加) |
| 5 | `scripts/check_zh_hant_consistency.py` | OpenCC s2tw 是**字符级转换**,**不处理上下文歧义** (如"头发" vs "发展" 的"发"字) | 底层 | 3 | P2 (OpenCC 限制) |
| 6 | `lib/l10n/app_*.arb` R91 | 73 ARB keys (7 子功能 + 整合入口 + period + 类型 + regularity) — R91 sub-spec 7 大量新术语 (sleep / social_rhythm / stress / weight / anxiety / treatment) **可能缺 zh_Hant 审校** | 底层 | 1 | P2 (R92 跑台湾人 review) |
| 7 | `lib/l10n/app_*.arb` R90 | 134 ARB keys (8 新量表 × 6 类别 + 8 中心化入口) — 量表名 (ISI / PSS / WHODAS / DSM-5 Level 2 / ASRM) **保留英文缩写,zh_Hant 用户看不懂** | 底层 | 1 | P2 (量表名翻译) |
| 8 | `lib/l10n/app_localizations.dart:471/477/483/...` (等多处) | 自动生成的 `app_localizations.dart` 含半角标点 4 处 (471/477/483/1419) + 半角省略号 2 处 (621/933) — **flutter gen-l10n 生成器 bug,源 ARB 是全角但 gen-l10n 转半角** (R88 known regression 类似) | 底层 | 3 | P1 (Flutter 官方 issue) |
| 9 | `lib/l10n/app_zh_Hant.arb:14` (sample) | "慢病管家" — 简体/繁体**同字** (不是问题,只示意) | — | — | — |
| 10 | `lib/l10n/app_zh_Hant.arb` 整体 | **缺香港粤语 locale** (zh_Hant_HK),Google Play / App Store 都支持 zh-HK / zh-TW / zh-CN 3 区分,App store 提交时需选 | 架构 | 2 | P2 (港澳用户) |
| 11 | `l10n.yaml` 整体 | 缺 **`arb-dir: lib/l10n` + `template-arb-file: app_zh.arb` + `output-localization-file: app_localizations.dart` 显式声明** | 底层 | 1 | P3 |
| 12 | `lib/l10n/app_*.arb` 整体 | **缺 4 byte CJK 扩展字符** (Ext-B/C/D/E/F, U+20000-U+2FA1F) — `常用字` / `𰻞` 等罕用字 gen-l10n 可能不支持 | 底层 | 3 | P3 (罕用字) |

### D-4. 总结

- **R57 R60 R78 R83 R87 R90 R91 已修**: 1000 keys 同步 / OpenCC s2tw 自动化 / 3 心理危机热线 5 地区 / R90 8 新量表 / R87 mood 列表 / R88 CBT PDF / R91 sub-spec 7
- **仍欠**: 台湾用字人工 review / zh_Hant_HK + zh_Hant_MO locale 细分 / 题目全文留 v1.0 / gen-l10n 半角标点 bug

---

## 修复路线 (按 P0 → P3 排)

### P0 (上架 blocker, 共 36 项,估总 3-6 月)

| # | 项 | 估时 | 依赖 |
|---|---|---|---|
| 1 | 阿里云 SMS 真接 (R55 实施) | 1-2 天 + 2-4 周审核 | 法务模板话术 (P0-#14) |
| 2 | 5 厂商 push SDK 接入 (米/华/OPP/vivo/魅族) | 1-2 月 | 各厂商审核 (并行) |
| 3 | 3 份法律 md 律师过审 (¥45-90k) | 1-2 周 | 法务签字 + 修订跟踪 |
| 4 | 软件著作权登记 (CPDA) | 1-2 月 | 法务 |
| 5 | ICP 备案 (阿里云 / 腾讯云) | 7-20 天 | 域名 (#6) + 营业执照 |
| 6 | `chroniccare.app` 域名 + HTTPS 部署 | 1-2 天 | — |
| 7 | `support@chroniccare.app` 邮箱 + 替换 3 处 md | 1-2h | — |
| 8 | GitHub 仓库创建 | 0.5 天 | — |
| 9 | NMPA "非医疗器械" 声明 PDF | 1-2 周 | 法务签字 (P0-#3) |
| 10 | HIPAA / GDPR 律师过审 (¥15-30k) | 1-2 周 | 国际律师 |
| 11 | IAP 业务整体暂停 vs 文档矛盾 | 1-2 周 (二选一) | 法务 + 工程 |
| 12 | Data Safety Form 跑 generate_data_safety_form.py | 0.5 天 | 修复 SDK 列表 (LEGAL_REVIEW_BRIEF §1.8) |
| 13 | Apple App Store 4 表单 (App Privacy / Permissions / Health Apps / Data Deletion) | 0.5-1 天 | 用户登录填 |
| 14 | Google Play 4 表单 (Data Safety + Health Apps + Permissions + Data Deletion) | 0.5-1 天 | 同上 |
| 15 | Android keystore + Play App Signing (R72 脚本) | 1-2h | 用户跑 generate_release_keystore.ps1 |
| 16 | iOS 签名 + Apple Team ID (fastlane Appfile 4 ID) | 30min (macOS) | Apple Developer 注册 |
| 17 | PIPL §13 §14 §17 §23 §28 §38 §44 §47 §50 §51 §54 全部法律条文合规 | 1-2 月 | 法务 (#3) + 工程 (#1 #2 #4 #5 #6 #7) |
| 18 | PIPL §17 失联通知告知不准确修文案 | 1-2 周 | 法务 (#3) |
| 19 | PIPL §23 紧急联系人单独告知 (业务暂停期间软实施够不够) | 1-2 周 | 法务 (#3) |
| 20 | PIPL §28 树洞敏感个人信息分类 | 1-2 周 | 法务 (#3) |
| 21 | PIPL §38 跨境 PII 传输 (Twilio 代理签标准合同) | 1-2 月 | 法务 + 阿里云 (#1) |
| 22 | PIPL §47 撤回同意后数据不删除合规 | 1-2 周 | 法务 (#3) |
| 23 | PIPL §50 投诉渠道 (注册 `privacy@chroniccare.app` 邮箱 + 7 工作日响应 SOP) | 1 周 | 工程 (#7) + 法务 (#3) |
| 24 | PIPL §54 PII 处理活动记录 (全量 audit log 实施) | 1-2 周 | 工程 |
| 25 | SendGrid 真接 (邮件通道) | 1-2 周 + 模板审核 | 法务 (#3) |
| 26 | 文网文 / 互联网药品信息服务资格 | 1-2 月 | 药监局审核 |
| 27 | 算法备案 (网信办) — 失联检测算法 | 1-2 月 | 网信办审核 |
| 28 | IAP 8 元定价平台一致性 (Apple 30% 抽成 / Google Play 15%) | 1-2 周 | 法务 (#3) |
| 29 | 未成年人 14-18 周岁验证 (PIPL §31) | 1-2 周 | 法务 (#3) + 工程 |
| 30 | 数据导出风险告知 (明文 JSON 误传) | 1 周 | 法务 (#3) + 强制加密 + 风险提示 |
| 31 | 0 remote / 0 release tag (git tag 必修) | 0.5 天 | 工程 |
| 32 | `check_fullwidth_punctuation.py` 135 violations 修 | 1-2 天 | 提升为 hard fail (R58 升回) |
| 33 | README 测试数 1098→1617 + SMS / 5 厂商 push "占位" 修 | 0.5 天 | 工程 |
| 34 | 隐私政策 §1 设备信息收集描述跟代码矛盾 | 0.5 天 | 工程 (统一措辞) |
| 35 | 隐私政策 §0.5 / §3 / §12 业务暂停 vs 描述矛盾 | 1-2 周 | 法务 (#3) + 文案 |
| 36 | 6 份文档 "App" 混用修 (strings.dart L30/38/58/96 + sensitive_data_consent L36/88/91 + privacy_policy L73 + SMS_PROVIDERS L33) | 0.5 天 | 工程 (跟 terminology.md §2 对齐) |

### P1 (重要, 估总 4-6 周)

| # | 项 | 估时 | 依赖 |
|---|---|---|---|
| 1 | 8 量表题目全文 i18n (R78 R90 决策留 v1.0) | 1-2 月 | 法务 + 临床翻译 |
| 2 | 5 地区心理危机热线 (加美/英/国际 24/7) | 0.5 天 | 工程 (R83.5) |
| 3 | 8 元买断 / IAP 暂停 / 失联通知 暂停 / 5 厂商 push 0 接 在 README + DEPLOYMENT + LEGAL_REVIEW_BRIEF 三处统一警告 | 0.5 天 | 工程 |
| 4 | PIPL §24 算法透明性 (失联检测算法说明 + 拒绝方式) | 1 周 | 法务 + 文案 |
| 5 | 树洞数据导入设备绑定 | 1-2 周 | PIPL §28 分类先 |
| 6 | DEPLOYMENT.md 阶段 5/6 缺失补全 | 1 天 | 工程 |
| 7 | DEPLOYMENT 阶段 5 Apple 完整 metadata 模板 | 1 天 | 工程 |
| 8 | CHANGELOG.md R91 0.30.0 多次 entry 顺序整理 | 0.5 天 | 工程 |
| 9 | DEPLOYMENT 阶段 7.5 中 5 项上架前手动 checklist 加红色 banner | 0.5 天 | 工程 |
| 10 | CI 加 `flutter build appbundle --release` + 16KB alignment objdump 验证 | 1 天 | 工程 (P0-#15 keystore) |
| 11 | CI 加 iOS build job (macOS runner) | 0.5 天 | 工程 |
| 12 | BootReceiver WorkManager 真接 (R65 标 TODO) | 1-2 周 | 工程 |
| 13 | 设备信息收集描述统一措辞 | 1-2 天 | 法务 + 工程 |
| 14 | 第三方 SDK DPA 协议 (16+ 依赖) | 1-2 月 | 法务 |
| 15 | 华为 / OPPO / vivo 单独签名 + 隐私 URL | 1-2 天 | P0-#15 keystore |
| 16 | 欧盟 GDPR DPO 任命 | 1-2 周 | 法务 |
| 17 | CCPA / CPRA 评估 | 1-2 周 | 法务 |
| 18 | 鸿蒙 / HarmonyOS NEXT 适配 | 1-2 月 | 华为审核 |
| 19 | 5 厂商 push 送达率回执监控 | 1-2 周 | P0-#2 5 厂商 push |
| 20 | R88 CbtThoughtRecordPdf 走 strings.dart 集中器 | 0.5 天 | 工程 |
| 21 | worktree `feat-cbt-thought-report` 残留清理 | 0.1 天 | 工程 |
| 22 | `git tag` 给 0.30.0 打 tag | 0.1 天 | 工程 |
| 23 | gen-l10n 半角标点 bug 修复 (4 处 + 2 处省略号) | 0.5 天 | 工程 (or flutter gen-l10n 上游 issue) |
| 24 | WHITE PAPER 最后更新 2026-07-20 → 2026-08-06 | 1 天 | 工程 |
| 25 | CODEOWNERS 加法务 owner / 翻译 owner | 0.5 天 | 工程 |

### P2 (建议, 估总 2-3 周)

| # | 项 | 估时 |
|---|---|---|
| 1 | 失联通知业务暂停 (R66 双层防御) vs 隐私政策文档矛盾 — 长期文案 / UX 决策 | 1-2 周 |
| 2 | 台湾用字人工 review (zh_Hant) | 0.5 天 |
| 3 | zh_Hant_HK + zh_Hant_MO locale 细分 | 1 周 |
| 4 | OpenCC s2tw 上下文歧义 (头发 vs 发展) | 1-2 周 (OpenCC 限制) |
| 5 | 腾讯云 SMS 备选 | 1-2 周 |
| 6 | Twilio 海外通道真接 | 1 周 + 跨境备案 1-2 月 |
| 7 | 多设备同步策略 | v1.0+ |
| 8 | 算法偏见 / 误判反馈机制 | 1-2 周 |
| 9 | 微信小程序版 (腾讯应用宝) | 1-2 月 |
| 10 | 4 byte CJK 扩展字符 (U+20000-U+2FA1F) | 1 周 |
| 11 | 决策记录 v0.30 R91 ADR | 0.5 天 |
| 12 | AGENTS.md 法务坑补全 (PIPL §13/§14/§17/§23/§28/§38/§47/§50/§51/§54) | 0.5 天 |
| 13 | GIT_WORKFLOW.md 更新 (worktree vs stash 实际用法) | 0.5 天 |
| 14 | 业务术语"停药" → "漏药提醒" 或 "用药提醒" | 0.5 天 |
| 15 | R91 8 新量表 enum 缺 `checkInType*` ARB key 补 | 0.5 天 |
| 16 | R78 R90 量表题目 keys 留 v1.0 标 TODO | 0.5 天 |

### P3 (nice-to-have)

| # | 项 | 估时 |
|---|---|---|
| 1 | `docs/superpowers/` 加 brainstorming 流程 doc | 0.5 天 |
| 2 | AGENTS.md 引用 superpowers-en 14 子技能中文版索引 | 0.5 天 |
| 3 | README 顶部加版本日期 (跟 pubspec 同步) | 0.1 天 |
| 4 | BREAKING CHANGE commit 标记 (R12 5 子层并入 umbrella 实质是 BC, 未标) | 0.5 天 |
| 5 | CODEOWNERS 全 `@maintainer` 替换为真实 owner | 0.5 天 |
| 6 | CHANGELOG R88 R89 格式样例化 (P0 修 vs 修 sub-spec) | 0.5 天 |
| 7 | 决策记录跨 R70+ 整理 (CI/CD / keystore / 部署) | 1 天 |
| 8 | L10n locale 显式声明 (l10n.yaml) | 0.5 天 |
| 9 | schemaVersion 注释 (app_database.dart) 跟 CHANGELOG 同步 | 0.5 天 |
| 10 | main.dart R62 R67 长注释 精简 | 0.5 天 |

---

## 半成品 / 残缺项 (按文件位置)

### 半成品 (业务暂停 / 临时关闭 / TODO 注释)

| # | 文件:位置 | 状态 | 详情 |
|---|---|---|---|
| 1 | `lib/core/data/feature_flags.dart:35` | 业务整体暂停 | `_prodEmergencyContactEnabled = false` 失联通知 |
| 2 | `lib/core/data/feature_flags.dart:38` | 业务整体暂停 | `_prodIapEnabled = false` IAP 8 元买断 |
| 3 | `lib/core/data/feature_flags.dart:42` | 临时关闭 | `_prodBootReceiverEnabled = true` (但 R65 0 实现,靠 flutter_local_notifications 兜底) |
| 4 | `lib/core/data/feature_flags.dart` (R65b 阶段) | 临时关闭 | `_prodPhqGad7I18nEnabled = false` PHQ-9 / GAD-7 题目 i18n 走 fallback key |
| 5 | `lib/core/data/services/sms_service.dart` (AliyunSmsProvider.send) | 占位 | 仍 throw UnimplementedError,R58 降为 warn-only |
| 6 | `lib/core/data/services/email_service.dart` | mock-only | 无 dio 依赖,v0.22 R29 删 dio |
| 7 | `lib/core/data/services/notification_service.dart` | 5 厂商 0 接 | 国产 ROM 送达率 < 70% |
| 8 | `lib/core/data/services/store_kit_service.dart` (R68) | 业务整体暂停 | IAP 隐藏入口避 Apple 2.1 拒 |
| 9 | `lib/core/data/services/cbt_thought_record_pdf.dart` (R88) | 集中器漏改 | 未走 strings.dart 集中器,自带硬编码中文 |
| 10 | `lib/presentation/services/scale_translations_l10n.dart` (R90) | 题目 stub | 8 新量表 56 个 switch-case 题目返 `''` 兜底 |
| 11 | `lib/l10n/app_*.arb` R90 | 题目留 v1.0 | 8 量表 × 5-12 题 = ~70 题目 keys 暂不加 |
| 12 | `lib/l10n/app_zh_Hant.arb` | 缺港澳细分 | 无 zh_Hant_HK / zh_Hant_MO locale |
| 13 | `lib/core/l10n/strings.dart:30/38/58/96` | "App" 混用 | R59 修了 14 处 ARB,strings.dart 漏改 |
| 14 | `assets/legal/privacy_policy.md:21-28` (业务暂停声明) | 文档 vs 实际矛盾 | §0.5 写"未来失联通知会发",实际 0 触发 |
| 15 | `assets/legal/privacy_policy.md:58` (业务暂停声明) | 文档 vs 实际矛盾 | §3 "本版本不实际触发失联通知" |
| 16 | `assets/legal/privacy_policy.md:71` (撤回同意) | 撤回后数据不删除 | "撤回后该功能立即停用,**数据不删除**" |
| 17 | `assets/legal/sensitive_data_consent.md:36` (树洞导出) | 文档过时 | "树洞数据不包含在导出 JSON 中" (R88 P0 已修导出, 文档未同步) |
| 18 | `assets/legal/sensitive_data_consent.md:88-91` (底部) | "App" 混用 | "继续使用本 App" |
| 19 | `docs/SPRINT1_LEGAL_TODO.md` | 4 项 0 实施 | 律师 / 邮箱 / 仓库 / 域名 |
| 20 | `docs/STOREFRONT_RELEASE_SOP.md` | 5 项 0 实施 | 域名 / keystore / 4 表单 / 4 ID / 律师 |
| 21 | `docs/LEGAL_REVIEW_BRIEF.md` | 12 P0 风险点 0 解决 | 失联通知 / 紧急联系人 §23 / IAP / 数据导出 / 跨境 / 邮箱 / 树洞 / SDK / 算法 / 免责 / 未成年 / IAP |
| 22 | `lib/presentation/pages/setup/setup_legal_dialog.dart:25-32` | v1.0 5 项 TODO | SMS 发送 / 联系人回复 Y / confirmed 标记 / UI 状态 / 30 天提醒 |
| 23 | `lib/core/data/services/database_migration.dart` | 17 字符 半角标点 | 守护员报 |
| 24 | `lib/core/data/services/export/export_schema_service.dart` | 73 字符 半角标点 | 守护员报 |
| 25 | `lib/core/theme/app_colors.dart` | 275 字符 半角标点 | 守护员报 |
| 26 | `lib/core/theme/app_motion.dart` | 146 字符 半角标点 | 守护员报 |
| 27 | `lib/l10n/app_localizations.dart` | 4 处半角标点 + 2 处半角省略号 | gen-l10n 生成器 bug |
| 28 | `lib/l10n/app_localizations.dart` | 125+ 半角标点 (R91 后累积) | 守护员报 |
| 29 | `lib/presentation/pages/setup/setup_legal_dialog.dart` L1-30 | 注释过期 | R58 R62 R83 注释累积,缺统一阶段表 |
| 30 | `lib/core/data/database/app_database.dart:128-279` | 注释 > 代码 4x | v0.18 R18 → v0.30 R91 累积,信息密度高但易过期 |
| 31 | `lib/main.dart:28-54` (R62 R67 注释) | 长注释 100+ 字 | 单行信息密度高,易过期 |
| 32 | `.worktrees/feat-cbt-thought-report/` | 残留 worktree | R88 CBT 实施完 worktree 仍存在,未清理 |
| 33 | `.github/CODEOWNERS` | 全 `@maintainer` 占位 | 0 真实 owner |
| 34 | `lib/l10n/app_zh.arb` R59 | 14 处 "App" → "本应用" 修了 | strings.dart L30/38/58/96 漏改 |
| 35 | `.git/` | 0 remote | 0 GitHub / GitLab 仓库配置 |
| 36 | `.git/` | 0 release tag | `git tag -l` 返空 |
| 37 | `lib/presentation/providers/safety_*.dart` (推算) | FeatureFlags.emergencyContactEnabled 守卫 | 业务暂停期间所有 safety path 早返 disabled |
| 38 | `lib/presentation/pages/contact/` (推算) | FeatureFlags.emergencyContactEnabled 守卫 | 联系人 section 隐藏 |
| 39 | `lib/presentation/pages/setup/` | FeatureFlags.emergencyContactEnabled 守卫 | step 1 联系人可选 |
| 40 | `lib/core/data/services/safety_watch_service.dart` (推算) | FeatureFlags.emergencyContactEnabled 守卫 | onAppStart 跳过 rescheduleAll |
| 41 | `lib/core/data/services/safety_alert_dispatcher.dart` (推算) | 业务暂停 | SMS 永不真发 |
| 42 | `lib/l10n/app_zh.arb` (R91 sub-spec 7) | 73 新 keys 但 12 orphan | R91 修了 12 unused orphan, 1 homeFabAssessment 移除 |
| 43 | `lib/core/data/services/sms_service.dart` AliyunSmsProvider | isProductionReady 基于字段表达式 | R62 P0-1 修"假成功"问题,但 send() 仍 throw UnimplementedError |

### 残缺项 (TODO / 待补 / 文档没同步)

| # | 文件 | 缺失 | 状态 |
|---|---|---|---|
| 1 | `lib/l10n/app_zh.arb` 整体 | **"App" → "本应用" 14 处修了,但 strings.dart L30/38/58/96 + sensitive_data_consent L88-91 + privacy_policy L73 + SMS_PROVIDERS L33 漏改** | R59 集中器漏 |
| 2 | `lib/l10n/app_zh_Hant.arb` | 缺 zh_Hant_HK / zh_Hant_MO locale | — |
| 3 | `docs/CHANGELOG.md` R91 entry | 0.30.0 多次 entry 顺序乱 | — |
| 4 | `docs/CHANGELOG.md` 整体 | 缺 v0.27 R55 R66 R67 R68 R69 R70 R72 R77 R82 R83 详细 entry | — |
| 5 | `README.md` 整体 | 8 处过期 (测试数 1098→1617 / SMS 占位 / 5 厂商 push / R82 冲刺) | — |
| 6 | `docs/DEPLOYMENT.md` 整体 | 阶段 5/6 缺失 (跳到阶段 7) | — |
| 7 | `docs/DEPLOYMENT.md` 阶段 5 | Apple App Store 完整 metadata 模板 | — |
| 8 | `docs/SENDGRID_SETUP.md:6-8` | "v0.22 R29 状态说明" — **R67 加 EmailService.validateForRelease 启动守卫,文档没更新** | — |
| 9 | `docs/SMS_PROVIDERS.md:33-34` | "App" 混用 | R59 漏 |
| 10 | `assets/legal/privacy_policy.md:30-41` (§1) | "设备信息 ... 仅本地判断通知兼容性" vs 代码"log 设备型号做 OEM 引导" 矛盾 | — |
| 11 | `assets/legal/sensitive_data_consent.md:36` (树洞导出) | "树洞数据不包含在导出 JSON 中" — R88 P0 silent data loss 修导出后,文档没同步 | R88 漏 |
| 12 | `assets/legal/sensitive_data_consent.md:88-91` | "App" 混用 | R59 漏 |
| 13 | `assets/legal/privacy_policy.md:73` | "卸载 App = 完全注销" — "App" 混用 + 业务暂停矛盾 | R59 漏 |
| 14 | `docs/CHINESE_COMMIT_GUIDE.md` | 缺 conventional commit 决策依据 / squash 决策 / merge commit 模板 / cherry-pick 流程 | — |
| 15 | `docs/GIT_WORKFLOW.md` | worktree 0 提 / worktree vs stash 矛盾 / 0 详细 cherry-pick / 0 详细 rebase | — |
| 16 | `docs/LEGACY_API_NOTES.md` | 软隐藏邮箱决策 (LEGAL_REVIEW_BRIEF §1.6 标 P0) | — |
| 17 | `docs/VERSION_1.0_PLAN.md` | 缺当前 P0 阻塞状态同步 | — |
| 18 | `docs/WHITEPAPER.md` 整体 | 最后更新 2026-07-20 v0.22,没同步 v0.30 R91 | 4 月没更新 |
| 19 | `whitePaper/慢病管家-白皮书-v3.0.md` | 同上 | — |
| 20 | `fastlane/metadata/ios/` | 缺 (只有 android) | — |
| 21 | `fastlane/Appfile` | 4 ID TODO 占位 | — |
| 22 | `.env` | `.env.example` 模板有,.env 缺 (CI 强制 PLACEHOLDER=test) | — |
| 23 | `lib/presentation/pages/contact/`, `lib/presentation/pages/setup/` 联系人 section | FeatureFlags.emergencyContactEnabled=false 隐藏,R68 联系人单独同意流程 0 实施 (依赖 SMS 真接) | — |
| 24 | `lib/core/data/services/boot_receiver.dart` (R65 TODO) | WorkManager 后台接收 0 实现 | — |
| 25 | `lib/l10n/app_zh_Hant.arb` (gen_l10n) | flutter gen-l10n 反复误删 3 个 `ventDuration*` 键,R88 known regression 守门 | R88 已知 |
| 26 | `lib/presentation/services/scale_translations_l10n.dart` (R90 8 新量表) | 56 个 switch-case 题目 stub 返 `''` 兜底 | R90 决策 |
| 27 | `lib/core/data/services/cbt_thought_record_pdf.dart` (R88 新增) | 未走 strings.dart 集中器,自带硬编码中文 | R88 漏 |
| 28 | `docs/AGENTS.md` 法务坑 | 0 PIPL / 法务风险在 known issues 段 | — |
| 29 | `lib/main.dart` (R62 R67 长注释) | 单行信息密度高,易过期 | — |
| 30 | `lib/core/data/database/app_database.dart` migration 注释 | 18 round 累积,> 代码 4x,易过期 | — |

---

## 上架相关工程隐患 (P0 阻塞, 上 store 前必修)

| # | 隐患 | 影响 | 修复 |
|---|---|---|---|
| 1 | **AliyunSmsProvider.send() 仍 throw UnimplementedError** | 失联通知 production 0 通道 | R55 1-2 天 + 阿里云 2-4 周审核 |
| 2 | **EmailService mock-only** | 邮件通知 0 通道 | R55 + 1 周 SendGrid 真接 |
| 3 | **5 厂商 push SDK 0 接** | 国产 ROM 送达率 < 70% → 失联通知失效 → 用户死亡风险 | 1-2 月厂商审核 |
| 4 | **IAP 业务整体暂停 vs user_agreement §3 写"8 元买断"** | Apple 2.1 + 4.3 Spam 双拒 | 1-2 周 (二选一:删文案 / 启用 IAP) |
| 5 | **失联通知业务整体暂停 vs 隐私政策 §0.5/§3/§12 仍描述** | PIPL §17 告知不准确 + Apple 5.2.1/5.2.3 | 1-2 周 (法务 + 文案) |
| 6 | **PIPL §13 §23 §28 §38 §47 §50 §51 §54 0 法务签字** | 中国 store 100% 拒 + 监管询问风险 | ¥45-90k, 1-2 周 + 1-2 月备案 |
| 7 | **0 remote / 0 release tag** | GitHub 仓库 0 → 隐私 URL / GitHub Pages 0 → SPRINT1_LEGAL_TODO §1-§3 全 P0 | 0.5-1 天 (域名 + 仓库) |
| 8 | **`support@chroniccare.app` 邮箱 0 注册** | 3 份 md TODO 占位 | 1-2h |
| 9 | **软件著作权 0 申** | 5 store 上架要求 | 1-2 月 (CPDA) |
| 10 | **ICP 备案 0 申** | 中国大陆 5 store 上架要求 | 7-20 天 |
| 11 | **`chroniccare.app` 域名 0 注** | 4 份 URL 占位 | 1-2 天 |
| 12 | **Apple App Store Connect 4 ID 占位** | fastlane/Appfile 4 TODO | 1h (macOS) |
| 13 | **Android keystore + Play App Signing 0 跑** | R72 脚本未跑 | 1-2h (Windows 跑 generate_release_keystore.ps1) |
| 14 | **Data Safety Form 0 跑** | generate_data_safety_form.py 脚本已写,SDK 列表缺 5 个 | 0.5-1 天 |
| 15 | **隐私政策 §1 设备信息收集描述跟代码矛盾** | Apple 5.1.1 拒 | 0.5 天 |
| 16 | **6 份文档 "App" 混用** (strings.dart + sensitive_data_consent + privacy_policy + SMS_PROVIDERS) | terminology.md §2 违反 | 0.5 天 |
| 17 | **`check_fullwidth_punctuation.py` 135 violations** | CI `--ci` 模式 fail | 1-2 天 (修 + 升回 hard fail) |
| 18 | **CI 缺 iOS build + release apk build** | 上架前 0 验证 | 0.5-1 天 |
| 19 | **CI 缺 16KB alignment objdump 实跑** | Google Play 2025-11 强制 | 0.5 天 |
| 20 | **隐私 URL 4 份占位** (`https://github.com/example/chroniccare/issues` + 4 URL) | Apple / Google 审核 + 4 store 5 store 隐私 URL | 1-2 天 (域名 + 部署) |
| 21 | **4 份 fastlane/metadata 占位** (隐私 URL / support URL / 描述) | Apple / Google 审核 | 0.5-1 天 |
| 22 | **8 元买断平台定价不一致** (Apple 30% / Google 15%) | Apple 3.1.5 + 中国消法 | 1-2 周 (法务) |
| 23 | **未成年人 14-18 周岁验证** | PIPL §31 + 监护人代同意证据 | 1-2 周 |
| 24 | **数据导出风险告知** | PIPL §13 + 误传责任边界 | 1 周 |
| 25 | **worktree 残留** (`.worktrees/feat-cbt-thought-report`) | CI 不识别 | 0.1 天 |
| 26 | **`.env` 0 commit 模板** | CI 强制 PLACEHOLDER=test | 0.1 天 (改 ci.yml) |
| 27 | **隐私 URL 4 store 适配** (华为 / 小米 / OPPO / vivo / 应用宝) | DEPLOYMENT 8.1 0 实施 | 1-2 天 |
| 28 | **第三方 SDK DPA 协议 0 签订** | PIPL §26 个人信息处理者义务 | 1-2 月 |
| 29 | **算法备案 (网信办) 0 申** | 失联检测算法属"自动化决策" | 1-2 月 (网信办审核) |
| 30 | **文网文 / 互联网药品信息服务资格 0 评估** | 项目涉及"吃药""处方" | 1-2 月 (药监局审核) |

---

## 总结

**工程水位 (1-10)**: **7.5 / 10** (技术深度国内中型项目天花板,但中国合规上架全链路仍未跑通)

**国内最佳实践差距**:
- **P0 上架 blocker**: 36 项 (估总 3-6 月)
- **P1 重要**: 11 项 (估总 4-6 周)
- **P2 建议**: 16 项 (估总 2-3 周)
- **P3 nice-to-have**: 10 项 (估总 1-2 周)

**核心结论**:
1. **代码层 + 自动化层 (16 守门员 / 4 层架构 / 1000 ARB keys / 0 PUA / 0 race / 0 leak / R67 PIPL §14 业务真接) 是国内罕见的高水准工程实践**,可作开源学习项目发布
2. **中国合规上架全链路仍 0 实施**: 法务 ¥45-90k 0 签字 / 软件著作权 1-2 月 0 申 / ICP 7-20 天 0 申 / 域名 + 邮箱 1-2h 0 注 / 5 厂商 push 1-2 月 0 接 / 阿里云 SMS 1-2 月 0 真接 / SendGrid 1-2 周 0 真接 / 算法备案 1-2 月 0 申
3. **业务整体暂停 3 处** (失联通知 / IAP / BootReceiver) 跟文档描述**矛盾**,PIPL §17 告知不准确 / Apple 2.1 拒 / Apple 4.3 Spam 拒 三重风险
4. **6 份文档"App"混用** + **135 半角标点 violations** (R58 降为 warn-only) + **2 个 `docs(sdd)` 风格不一致 commit** + **0 release tag** + **0 remote** + **worktree 残留** — 工程规范细节仍欠
5. **中国 store 上架最关键路径**: 律师 review 3 份 md (¥45-90k, 1-2 周) + 域名 + ICP + 软件著作权 + 邮箱 (1-2 天 + 7-20 天 + 1-2 月 + 1-2h) + 阿里云 SMS (1-2 天 + 2-4 周) + 5 厂商 push (1-2 月) + 4 store 4 表单 + IAP 业务决策 — 估总 3-6 月

**superpowers-zh 4 中国特色子技能评估**:
- **B-1 中文代码审查**: 7.0 / 10 (R57 override 模式 + R59 术语集中器 + R72 病耻感中性化 + R67 PIPL §14 真接,优秀;但 135 violations + 6 处 "App" 混用 + 4 业务整体暂停 + CbtThoughtRecordPdf 集中器漏改 仍欠)
- **B-2 中文提交规范**: 7.0 / 10 (`<version> round <N>` 格式 + 5 段 CHANGELOG + 拆分 vs squash 决策,优秀;但 0 release tag + 2 个 `docs(sdd)` 风格不一致 + 缺 BREAKING CHANGE 标记 仍欠)
- **B-3 中文文档**: 7.0 / 10 (24 份 doc + LEGAL_REVIEW_BRIEF 12 P0 风险点 + terminology.md + 5 地区心理热线,优秀;但 CHANGELOG 顺序乱 + README 测试数 1098→1617 过时 + DEPLOYMENT 阶段 5/6 缺失 + 6 处 "App" 混用 + R67 EmailService validateForRelease 文档不同步 + 隐私政策 §1 跟代码矛盾 仍欠)
- **B-4 中文 Git 工作流**: 6.0 / 10 (单 master + PR 模板 6 段 + CI 17 step,优秀;但 0 remote + 0 tag + worktree 残留 + CODEOWNERS 全占位 + 缺 iOS+release build CI + worktree vs stash 文档矛盾 仍欠)

**最终建议**:
- **海外 store (Google Play US / App Store US)**: 1-2 月可上 (域名 + Apple 4 ID + keystore + 5 厂商 push 海外用 FCM + 阿里云 SMS 1 个海外 SMS provider + 律师 review US 律师 + Data Safety + HIPAA/GDPR)
- **中国大陆 store (5 store)**: 3-6 月 (上面 + ICP 备案 + 软件著作权 + 文网文 + 阿里云 SMS 模板审核 + 算法备案 + 法务 ¥45-90k + 5 厂商 push 1-2 月审核)

---

**报告完成时间**: 2026-08-06
**报告字数**: ~16,000 字
**审计耗时**: ~25 分钟 (读 12 入口 + 5 守门员实跑 + 16 守门员总结 + 24 文档 + 431 commit log 统计)
**审计人**: superpowers-zh 视角 (重点 4 个中国特色子技能)
