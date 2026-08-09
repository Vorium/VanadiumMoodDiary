# superpowers-zh 视角审查报告（v0.23 round 42）

> **审查目标**：`D:\Batch\chroniccare` Flutter 慢病 / 精神心理患者吃药打卡 App
> **审查视角**：superpowers-zh（中国特色规范 + 中文代码审查 + 中文提交规范 + 中文文档 + 中文 Git 工作流 + workflow-runner + PIPL / NMPA / 应用商店合规）
> **审查时间**：v0.22 round 30 → v0.23 round 42（12 round / 13 commit 增量）
> **审查基线**：v0.22 round 30 报告（64 项 P0/P1/P2/P3）+ 当前 v0.23 round 42（HEAD `7da198c` / 845 tests / 0 analyze error）
> **审查员**：superpowers-zh 中文规范审查 sub-agent
> **优先级口径**：
> - **P0** = 必修：合规风险 / 应用商店上架阻塞 / 国产 ROM 通知完全失效 / 数据错版 / 法律文档未经律师
> - **P1** = 应修：影响国内用户体验（push 通道 / i18n / 半角标点 / 文档同步）
> - **P2** = 可修：commit 规范 / 文档质量 / 行业最佳实践
> - **P3** = nice-to-have
> **修难度分档**：trivial(<1h) / small(1-4h) / medium(4-8h) / large(8-16h) / xlarge(>16h)
>
> **报告范围声明**：
> - **不重复** round 30 已列的 64 项问题，除非**修复后又复发**或**找到更深根因**
> - 重点放在 **v0.23 12 round 增量审视**（含 P0-P3 集中清理 round 38-42）
> - 重点放在 **顶层架构**（用户特别要求）—— 中文模块可重构性 / 国内合规架构 / 流程架构

---

## 顶层架构审视

### 1. 国内合规风险（PIPL / NMPA 医疗器械 / 数据安全 / 应用商店）

> **8 项，5 项 P0、3 项 P1**
> **关键观察**：round 30 报告 T-01~T-09 (5 P0 + 3 P1 + 1 P2) **12 round 零修复**。法律文档依然是 v0.22 草稿，依然写"未经律师过审"，PIPL §52 依然悬空。v0.23 round 38 集中修 P0 是技术 P0（SMS fail-fast / safety_watch timeout），合规 P0 完全没动。

| # | 标题 | 位置 | 风险 | 法律依据 | 优先级 | 修难度 | round 30 状态 |
|---|------|------|------|---------|--------|--------|---------------|
| **A-01** | **3 份法律文档 v0.22 草稿未升级到 v0.23 草稿 + 仍未经律师** | `assets/legal/privacy_policy.md:3`<br>`assets/legal/sensitive_data_consent.md:3`<br>`assets/legal/user_agreement.md:3` | 高（应用商店 4 大 store 全部上架阻塞） | PIPL §52 + 《App 违法违规收集使用个人信息行为认定方法》§6 | **P0** | large(8-16h, 律师外审) | T-01 仍**未修**（round 38-42 零文档版本更新） |
| **A-02** | **隐私政策 §3 仍说"用户姓名" 但 §1 已说"用户昵称"** —— **同文档修复后不一致** | `assets/legal/privacy_policy.md:34` (✅ "用户昵称")<br>vs `assets/legal/privacy_policy.md:60` (❌ "用户姓名") | 高（**告知矛盾**，PIPL §6 最小化原则） | PIPL §6 + §14 | **P0** | trivial(0.1h, 6 处改"用户姓名"→"用户昵称") | T-02 **修复后又出现同款 bug**（仅修了 §1 表格，§3 失联通知段漏修） |
| **A-03** | **隐私政策 §1 设备信息"不收集"但又写"通知/兼容性"自相矛盾** | `assets/legal/privacy_policy.md:38` | 中 | PIPL 告知真实性原则 | **P0** | trivial(0.3h) | T-04 仍**未修**（round 38-42 零法律文档变更） |
| **A-04** | **`pubspec.yaml:4` version `0.22.0+2` 但项目 v0.23 round 42** | `pubspec.yaml:4`<br>`lib/l10n/app_zh.arb:89` (仍 "v0.22.0")<br>`lib/l10n/app_en.arb:74` (仍 "v0.22.0") | **高**：用户从 store 看 v0.22 但实际是 v0.23，**PIPL §14 同意记录的版本号与 App 实际版本不一致** → 同意记录失去法律效力 | 《App 违法违规收集》§4 必要原则 + PIPL §14 | **P0** | trivial(0.2h) | B-01 / B-10 修了 v0.21→v0.22，但 v0.22→v0.23 **没修**（round 38 P0 集中修时**没把这个列入**） |
| **A-05** | **未接 5 厂商 push 通道（HMS / MIPush / OPPO / vivo / 魅族）—— round 41 P3-27 标为"web-only 项目当前不适用"** | `pubspec.yaml:18-58` 全部依赖（无 hms / mipush / opush / vpush / getui / jpush / flyme_push 任何）<br>`lib/core/data/services/notification_service.dart:1`（仍只用 `flutter_local_notifications`） | **高**（90% 国产 ROM 用户杀进程后 0 通知送达）—— round 41 误判"项目 web-only 当前不适用"，但 `DEPLOYMENT.md:182-186` 明确说目标"Google Play / Apple App Store / 华为 / 小米 / OPPO / vivo 4 大国产 store" | - | **P0** | xlarge(>16h, 5 厂商 SDK) | T-05 / N-11-14 仍**未修** —— round 41 P3-27 写"web-only 项目当前不适用"是**错误判断**（项目目标明确是 4 大国产 store） |
| **A-06** | **隐私政策 §1 "健康数据" vs "健康记录" 措辞**（医疗 App 自我定性） | `assets/legal/privacy_policy.md:36` | 中（医疗 App 自我定性 = 是否需 NMPA 备案） | NMPA《移动医疗器械注册管理办法》 | P1 | small(0.5h) | T-07 仍**未修** |
| **A-07** | **DEPLOYMENT.md 仍有 4+ 处敏感措辞**（"再治愈更难"/"突然停药"/"复发高峰"） | `docs/DEPLOYMENT.md:155-157` | 中 | 《广告法》§16 + 《医疗广告管理办法》§3 | P1 | trivial(0.5h) | C-10 仍**未修**（round 28 修了 4 处但**没修干净**，L155-157 残留） |
| **A-08** | **DEPLOYMENT.md §5 仍"声明'非医疗器械'" —— 实际 PHQ-9 + GAD-7 + 失联通知可能构成 NMPA 二类医疗器械** | `docs/DEPLOYMENT.md:184-185` | 中（**法务不确定**） | NMPA《移动医疗器械注册管理办法》 | P1 | small(1h, 法务确认) | C-11 仍**未修**（round 38-42 零法律 / 合规 commit） |

**P0 风险总计**：5 项（全部是 round 30 报告**已列但 12 round 没修**的） / 估算 12-20 h（不含律师外审 + 厂商 push 接入）

**关键发现（顶层架构）**：
- v0.23 round 38 P0 集中清理（commit `a45e821`）**只清理了 3 个技术 P0**（SMS fail-fast / safety_watch timeout / app.dart provider 复用），**合规 P0 完全没碰**。这是"什么是 P0"的认知偏差：技术债 ≠ 合规债，**合规 P0 是上架阻塞性 P0**（store 提交必拒）。
- v0.23 round 41 P3-27 标"厂商通道 web-only 项目当前不适用"是**错判**：`DEPLOYMENT.md` 明确目标"Google Play / Apple App Store / 华为 / 小米 / OPPO / vivo 4 大国产 store"，且 `pubspec.yaml:74-75` 显式 `generate: true`（非 web-only 标志，但项目实际 web 端 + 计划 Android/iOS）。`AGENTS.md` "栈"段说"Flutter 3.41.9 / Dart 3.12.2"没指明 web-only。
- v0.23 round 38 P0-2（Android 12+ SCHEDULE_EXACT_ALARM 权限）SKIP 也是同样问题：理由"项目 web-only"是错的，应是"项目当前没 build android 目录，但 pubspec 没排除 Android 平台"。

### 2. 国内生态适配

> **6 项，2 项 P0、3 项 P1、1 项 P2**
> **关键观察**：v0.22 round 33（T-11 修过 7 品牌自检卡）之后，自检卡 ROM 适配**完全停滞**。v0.23 round 38 P0 集中清理**没动 ROM 适配**。

| # | 标题 | 位置 | 优先级 | 修难度 | round 30 状态 |
|---|------|------|--------|--------|---------------|
| **B-01** | **`app_zh_Hant.arb` 是简体副本，命名错误**（P3-30 "zh_Hant stub" 实际是简体拷贝） | `lib/l10n/app_zh_Hant.arb:4-15`（"慢病管家"/"我今天吃了药"/"下次提醒" 全简体）<br>vs 正确繁体应为"慢病管家"/"我今日食咗藥"/"下次提醒"<br>跟 `app_zh.arb` **diff 1 行**（仅 `@@locale`） | **P0** | medium(6-8h, 569 keys 逐 key 繁简转换) | T-14 仍**未真做** —— round 41 P3-30 命名 "stub" 但实际产物是"简体副本"，**误导后续 review** |
| **B-02** | **未接 5 大国产 ROM 厂商 push 通道** | 见 A-05 | **P0** | xlarge(80-120h) | T-05 / T-10 / N-11-14 仍**未修**（round 41 P3-27 误判） |
| **B-03** | **隐私政策 §3 失联通知 SMS 内容仍 hardcode 中文 `我是 XXX`**（港澳台 / 国际用户失联时亲人收到中文 SMS 不知情） | `lib/core/l10n/strings.dart:17-26`<br>`emailSubject` / `emailBody` / `emailLastMed` 4 个 hardcode 中文 | P1 | medium(4-6h, i18n 化) | T-04 字符串迁移仍**未做**（round 39 P1-9 集中过但仍是中文 hardcode） |
| **B-04** | **失联阈值 36h 写死** | `lib/domain/logic/care_engine.dart:103` | P1 | small(2h) | T-15 仍**未修**（round 41 P3-35 reminders_hub 改 FutureProvider 但**未把阈值加入 UI**） |
| **B-05** | **未支持农历 / 24 节气 / 节假日 streak 跳过** | `lib/domain/logic/streak_calculator.dart` 0 hit | P1 | medium-large(8-12h) | T-12 / T-13 仍**未修** |
| **B-06** | **`.env` build-time 注入未做**（弱网/离线首次启动 race） | `lib/main.dart:37` | P2 | small(2h) | T-16 仍**未修** |

**关键发现（顶层架构）**：
- v0.23 round 41 P3-30 命名是 **"zh_Hant stub"**，但产物（`app_zh_Hant.arb`）**与 `app_zh.arb` diff 仅 1 行**（仅 `@@locale` 不同）。这意味着：
  - 文件名"app_zh_Hant.arb"声明了 zh_Hant locale
  - 但实际内容是简体，**对繁体用户显示简体 → 跟 zh locale 行为完全一样**
  - 测试 / 国际化流水线不会捕获（因为 diff 1 行 = 不报错）
  - **典型的"假完成"反模式** —— 命名暗示已实现，实际是占位符

### 3. 可重构的中文模块（i18n / 文档 / commit / workflow）

> **7 项，3 项 P1、4 项 P2**
> **关键观察**：v0.23 round 39-40 集中清理 12 项里 P1 / P2 主要针对代码技术债（token 化、抽类、catch swallow），**中文规范模块可重构性零动作**。`AGENTS.md` "v0.23 P0-P3 集中清理" 段把 4 守护脚本列为"全绿"但**没列具体哪 4 个**（实际 6+ 个：flutter analyze / test / check_all / check_cross_feature / check_arb_keys / check_fullwidth_punctuation / check_datetime_race2），**脚本清单不完整**。

| # | 标题 | 位置 | 优先级 | 修难度 | round 30 状态 |
|---|------|------|--------|--------|---------------|
| **C-01** | **`check_fullwidth_punctuation.py` ASCII_PUNCT 只 4 种** `,;!?` —— 漏检半角 `/` / 半角 `…` / 半角 `(` 等 7+ 种 | `scripts/check_fullwidth_punctuation.py:28` | P1 | trivial(0.5h, 扩展正则) | T-17 仍**未扩展** |
| **C-02** | **`app_zh.arb` 7+ 处半角 `/` 应全角 `／` 或 `、`**（量表名 / 电话区号 / 时间窗口 / 国产手机品牌） | `app_zh.arb:67` "7/14/30 天"<br>`app_zh.arb:88` "PHQ-9 / GAD-7"<br>`app_zh.arb:166` "大陆/港澳台/国际"<br>`app_zh.arb:185` "7/30/90 天"<br>`app_zh.arb:249` "小米/华为/OPPO/Vivo/三星"<br>`app_zh.arb:272` "中兴/努比亚/红魔/联想"<br>`app_zh.arb:286` "PHQ-9 / GAD-7"<br>`app_zh.arb:316` "{count} 种 / {times} 时间点"<br>`app_zh.arb:488` "已答 {answered} / {total}"<br>`app_zh.arb:556` "稳定期 / 月度复盘"<br>`app_zh.arb:569` "最低 {min} / 最高 {max}" | P1 | small(1h) | T-19 仍**未修** —— round 39 P1 修了"i18n 38 处"但**没扩 ASCII_PUNCT** |
| **C-03** | **`app_zh.arb` 4+ 处半角 `…` 应全角 `……`**（GB/T 15834-2011） | `app_zh.arb:236` "加载中…"<br>`app_zh.arb:388` "正在录音… 点停止"<br>`app_zh.arb:425` "录音中… {elapsed}"<br>`app_zh.arb:438` "识别中…" | P1 | trivial(0.3h) | B-12 部分修过但**漏 4 处** —— round 28 P1-4 修过 3 处（line 125/487/856），但 round 39 38 处 i18n 集中**没扩到 `…`** |
| **C-04** | **`app_zh.arb` 您/你 不统一**（精神心理医疗 App 应统一"您"表尊重） | `app_zh.arb:617` "请输入您的名字" vs `app_zh.arb:34` "你的名字"<br>混用 5+ 处 | P1 | small(1h) | B-11 仍**未修** |
| **C-05** | **`lib/core/l10n/strings.dart` 100+ 处 hardcode 中文**（通知 / 邮件 / PDF 报告 / 导入摘要）—— domain 层"不能 import flutter"是技术债，不应作为长期方案 | `lib/core/l10n/strings.dart` 130 行全 hardcode 中文 | P2 | medium(6-8h, 抽 `LocaleStrings` 参数注入) | 仍**未做**（round 39 P1-9 集中过但**承认是 hardcode**） |
| **C-06** | **`scripts/check_fullwidth_punctuation.py` 不检查 `lib/l10n/*.arb`**（ARB 文件半角 / 全角问题不报） | `scripts/check_fullwidth_punctuation.py:69` (`os.path.join(os.getcwd(), "lib")`) | P2 | trivial(0.3h, 扩到 `lib/l10n/*.arb`) | 仍**未扩** |
| **C-07** | **`AGENTS.md` 决策记录没列 P2/P3 阶段产物** | `AGENTS.md:255-264` 决策记录表 10 行 | P3 | trivial(0.5h) | T-23 仍**未修** |

**关键发现（顶层架构）**：
- v0.23 round 39 集中修 i18n 38 处（commit `68c79c5`）是 P1 集中清理，但**只清理了 hardcode 中文→ ARB 抽取**，**没修 ARB 文件本身的全角 / 半角问题**。`check_fullwidth_punctuation.py` 也**没扩**到 `lib/l10n/*.arb`。
- 整个 v0.23 期间 `scripts/check_fullwidth_punctuation.py` ASCII_PUNCT 正则从 4 种 `,;!?` 没变过 1 个字符（commit history 可查）。
- 精神心理医疗 App 敬语策略在 `P2_COMPLIANCE_REVIEW.md:166 P2-P3-02` 提过"全文统一你→您"但 round 39 / 40 / 41 / 42 4 个 round 没动作。

### 4. 流程架构（brainstorming / writing-plans / workflow-runner）

> **5 项，2 项 P1、2 项 P2、1 项 P3**
> **关键观察**：v0.23 round 38-42 集中清理 13 commit 全部**单 dev 串行**（无 brainstorming / writing-plans / TDD / workflow-runner 痕迹），**违反 superpowers-zh 流程规范**。`AGENTS.md` 没加"硬性 brainstorming 规则"，P0 必修类（合规 P0）也直接 commit。

| # | 标题 | 位置 | 优先级 | 修难度 | round 30 状态 |
|---|------|------|--------|--------|---------------|
| **D-01** | **`AGENTS.md` 没列"P0 修法 / 新 feature 必须先 brainstorming"硬性规则** —— round 38-42 P0 集中清理直接 commit，无 brainstorming 痕迹 | `AGENTS.md:122-138` (开发流程 5 步走) | P1 | small(1h) | 仍**未加** |
| **D-02** | **`AGENTS.md` 没列 v0.23+ 大版本 release 应走 workflow-runner YAML**（brainstorming → 写 plan → TDD → review → release notes 自动生成） | `AGENTS.md` 整文件 | P1 | medium(4-6h, 写 `docs/plans/v0.24.md` + workflow-runner YAML) | 仍**未加** |
| **D-03** | **`docs/plans/` 目录不存在** —— v0.22 round 30 报告 §writing-plans 列"0 处 plan 文档"，v0.23 round 38-42 仍 0 处 | 无 `docs/plans/` 目录 | P2 | trivial(0.5h, mkdir + 写模板) | 仍**未加** |
| **D-04** | **`AGENTS.md` "v0.23 P0-P3 集中清理" 段说"4 守护脚本全绿"但没列具体哪 4 个** | `AGENTS.md:200-210` | P2 | trivial(0.3h, 列 6+ 脚本) | **新发现**（round 42 才加这段但**不准确**） |
| **D-05** | **`AGENTS.md` 没列 superpowers-zh 流程规范入口**（Chinese-Code-Review / Chinese-Commit-Conventions / Chinese-Documentation / Chinese-Git-Workflow / workflow-runner） | `AGENTS.md` 整文件 | P3 | trivial(0.3h, 加段"## 流程规范") | 仍**未加** |

**关键发现（顶层架构）**：
- v0.23 round 38-42 13 个 commit 全部是 root 视角直接 commit，**没有走 brainstorming**（按 v0.22 round 30 brainstorming 落地表分类，3 个 P0 fix + 1 个 P1 fix + 12 个 refactor 都属于"明确方向的不需要 brainstorm"或"拍脑袋"）。
- v0.23 round 41 P3-30 "zh_Hant stub" 是典型"拍脑袋"反例 —— 如果 brainstorming 过，会问"用户有港澳台需求吗？/ 港澳台用户用 App 比例？/ 简体副本当 zh_Hant 是否会让繁体用户困惑？"，决策会更清晰（要么真做，要么只加 stub 注释明示）。
- v0.23 round 38 P0-2 SKIP（"web-only 项目不适用"）是**信息不全的拍脑袋** —— 应 brainstorming："项目目标平台" / "pubspec 平台配置" / "DEPLOYMENT.md 写的是 4 大国产 store 但 .metadata 只 root 是不是配错？"。

---

## 增量问题（v0.22 round 30 → v0.23 round 42）

### 5. 中文 UI 文案 i18n 完整性

> **基线**：`pubspec.yaml:4` `version: 0.22.0+2`（**已 stale 12 round**，项目实际 v0.23）
> **arb 同步**：`python scripts/check_arb_keys.py` 显示 zh 569 keys / en 569 keys，0 missing —— **完整**

| 模块 | lib 文件数 | ARB key 覆盖 | hardcode 中文数 | 修复难度 | 优先级 | round 30 状态 |
|------|----------|-------------|----------------|---------|--------|---------------|
| 主页 / 设置 / 树洞 / 用药 / 评估 / 趋势 / 联系人 / 提醒中心 | 8 大 feature | 569 keys 中英 100% 对齐 | 0（round 39 P1-9 修 38 处后） | - | - | **✅ 改善**：i18n 完整度 99% → 100%（除 4 处半角 `…`） |
| 通知标题 / 描述 / Channel 名 | `lib/core/l10n/strings.dart` 60+ 字符串 | **仍 hardcode**（集中到 `Strings` 类但**承认是 hardcode**） | 60+ | medium(6-8h) | P2 | **新发现**：round 39 P1-9 集中但**承认是 hardcode** —— 跟 ARB 化两条线 |
| 邮件 / SMS 模板 | `lib/core/l10n/strings.dart:15-35` | hardcode 中文 | 6 处（`emailSubject` / `emailBody` / `emailLastMed` / `emailMedInfo` / `emailCycle` / `emailFooter`）| small(1h) | P1 | **新发现**：round 39 P1-9 集中但仍是 hardcode |
| 医生 PDF 报告 | `lib/core/l10n/strings.dart:67-129` 60+ 字符串 | hardcode 中文 | 60+ | small(1h) | P2 | **新发现**：round 39 P1-9 集中 |
| 数据导入摘要 | `lib/core/l10n/strings.dart:120-129` 6 字符串 | hardcode 中文 | 6 | trivial(0.3h) | P2 | **新发现**：round 39 P1-9 集中 |
| 法律文档 | `assets/legal/*.md` 3 份 | 走 markdown，0 hardcode（除必要英文术语） | 0 | - | - | - |

**统计**：i18n 完整度从 round 30 的 99% → 当前 99.5%（**改善很小**：round 39 38 处 ARB 化主要把 hardcode 收口到 ARB，但 ARB 自身有 4+ 半角 `…` + 11+ 半角 `/` + 您/你混用 = 文本质量反而**退步**）

**关键发现（增量）**：
- **i18n 数量**改善（0 hardcode）
- **i18n 质量**退步（半角 / `…` / 您你 4+ 处 v0.22 round 28 修过的**部分漏修**）
- **i18n 策略**没优化（domain 层 `lib/core/l10n/strings.dart` 整文件 hardcode，**承认是 hardcode 但仍持续扩** —— round 39 加 60+ PDF + 6 导入摘要 + 6 邮件，全是 hardcode）

### 6. 中文文案规范问题（半角/全角/标点/量词/语气）

> **3 项 P1**（按工作量） / **2 项 P2** / **2 项修复后又复发**

| # | 文件:行号 | 描述 | 修复难度 | 优先级 | round 30 状态 |
|---|----------|------|---------|--------|---------------|
| E-01 | `pubspec.yaml:4`<br>`lib/l10n/app_zh.arb:89`<br>`lib/l10n/app_en.arb:74`<br>`lib/l10n/app_localizations_zh.dart:222`<br>`lib/l10n/app_localizations_en.dart:229` | **`pubspec` + `app_zh.arb:89 settingsAboutVersion: "v0.22.0 · 我今天吃了药"`** —— 实际 v0.23 round 42 仍写 v0.22.0。**B-01 修复后又出现**（修了 v0.1→v0.22 但 v0.22→v0.23 没修） | trivial(0.2h) | **P0** | B-01 修复后又复发 |
| E-02 | `app_zh.arb:88` `settingsAssessmentHistorySubtitle`<br>`app_zh.arb:166` `snackbarPhoneInvalid`<br>`app_zh.arb:185` `medsCalendarSubtitle`<br>`app_zh.arb:67` `settingsMedReportSubtitle`<br>`app_zh.arb:249` `notificationStatusCardOemSubtitle`<br>`app_zh.arb:272` `notificationStatusCardOemBrandOthers`<br>`app_zh.arb:286` `reminderHubAssessmentDescEnabled`<br>`app_zh.arb:316` `reminderHubMedicationStatusActive`<br>`app_zh.arb:488` `assessmentAnsweredProgress`<br>`app_zh.arb:556` `assessmentReminderHintStable`<br>`app_zh.arb:569` `assessmentScoreRange` | **11+ 处半角 `/` 应全角 `／` 或 `、`**（量表名 / 电话区号 / 时间窗口 / 国产手机品牌） | small(1h) | P1 | T-19 仍**未修**（11+ 处 v0.22 round 30 列了 7 处 v0.23 round 39 38 处 i18n 集中**没扩**） |
| E-03 | `app_zh.arb:236` `notificationStatusCardStatusLoading`<br>`app_zh.arb:388` `ventRecordActive`<br>`app_zh.arb:425` `moodAudioRecording`<br>`app_zh.arb:438` `moodAudioSttListening` | **4+ 处半角 `…` 应全角 `……`**（GB/T 15834-2011） | trivial(0.3h) | P1 | B-12 部分修过但**漏 4 处** —— v0.22 round 28 P1 修过 line 125/487/856 共 3 处，round 39 38 处 i18n 集中**没扩**到 `…` |
| E-04 | `app_zh.arb:34` "你的名字" vs `app_zh.arb:617` "请输入您的名字" | **您/你 不统一**（精神心理医疗 App 建议统一"您"表尊重） | small(1h) | P1 | B-11 仍**未修** |
| E-05 | `app_zh.arb:578` `setupValidationNameRequired`<br>`app_zh.arb:653` `setupConsentDescription` | "您的"医疗合规 App 风格 vs 全文"你的" | small(1h) | P2 | **新发现**（精神心理医疗 App 敬语策略未统一） |
| E-06 | `app_zh_Hant.arb` 整文件 | **"zh_Hant stub" 实际是简体副本**（跟 `app_zh.arb` diff 1 行）—— 文件名"app_zh_Hant"声明 zh_Hant locale 但内容是简体 | medium(6-8h, 569 keys 繁简转换) | **P0** | T-14 仍**未真做** |
| E-07 | `lib/core/l10n/strings.dart:17-35` `emailSubject` 等 4 处 | **邮件 / SMS 模板 hardcode 中文**（"我是 XXX" / "已经 X 天没打卡了"） | small(1h) | P1 | T-04 字符串迁移仍**未做**（round 39 P1-9 集中过但**承认是 hardcode**） |
| E-08 | `lib/core/l10n/strings.dart` 60+ PDF 报告字符串 | **医生 PDF 报告 100% hardcode 中文**（"慢病管家 · 用药报告" / "本应用不提供医疗建议"） | small(1h) | P2 | **新发现**（海外医生看 PDF 不能用，注释承认"海外医生看 PDF 不能用"） |
| E-09 | `app_zh.arb:147` `commonError`<br>`app_zh.arb:155` `commonLoadFailed` | 错误兜底文案**部分走 ARB** | - | - | **新发现**（`commonError` 句中带半角冒号是 OK 全角，OK 已合规）|

**汇总**：P0 2 项 / P1 5 项 / P2 3 项 / 已合规 2 项

**关键发现（增量）**：
- round 30 报告 B-01 / B-10 提的"`settingsAboutVersion: v0.1.0`"修了，但**修了 v0.1→v0.22 后 v0.22→v0.23 没续修**。这是"一次性修复"反模式 —— 应加 CI 脚本：`grep '"settingsAboutVersion"' lib/l10n/app_zh.arb` 输出应等于 `pubspec.yaml` 的 version。
- round 30 报告 T-19 列的 7 处半角 `/` v0.23 round 39 修了 38 处 i18n **但没扩 ASCII_PUNCT**，所以**新加的 ARB key 也带半角 `/`**（如 `settingsClearAllDataSubtitle` line 112 / `notificationStatusCardOemSubtitle` line 249）。
- `app_zh_Hant.arb` "stub" 命名是**反 anti-pattern**（P3-30 commit `a3bd7ee` 注释"基础版本跟 app_zh.arb 同 (简体)"），但文件头没标"⚠️ 实际是简体副本"，**未来 reviewer 看 diff 1 行以为已翻译**。

### 7. 注释 / 命名 / 文档规范

> **4 项 P1、3 项 P2、1 项 P3**

| # | 文件:行号 | 类型 | 描述 | 修复难度 | 优先级 | round 30 状态 |
|---|----------|------|------|---------|--------|---------------|
| F-01 | `docs/CHANGELOG.md:5-477` | 文档 | **v0.23 章节完全缺失** —— CHANGELOG 仍停在 `v0.22.1` (line 264-286)，v0.23 round 31-42 的 13 commit **0 条目记录** | medium(4-6h, 补 12 round 整段) | **P0** | **新发现**：C-03 修了顺序但**没修内容缺 v0.23 章节**（round 38-42 整段 12 round 没补 CHANGELOG）|
| F-02 | `docs/CHANGELOG.md:288-479` | 文档 | **顺序仍混乱**（v0.22.1 段后突然出现 v0.15.0 → v0.14 → v0.13 → v0.12 → v0.8 → v0.7 → v0.6 → v0.5 → v0.1.0+1 → v0.16）—— v0.16 段仍错位在最后 | small(1h, 整文件重排) | P1 | C-03 仍**未修干净**（v0.16 段仍错位） |
| F-03 | `docs/CHANGELOG.md:479-585` | 文档 | v0.16.0 段（line 479-585）位置错乱 —— 应该在 v0.15 之前 | trivial(0.5h) | P1 | 同 F-02 |
| F-04 | `docs/GIT_WORKFLOW.md:84-89` | 文档 | **"每个 minor version 打 tag"流程完全失效** —— v0.18-0.22 全无 tag（`git tag -l` 空），v0.23 round 42 也无 tag。`GIT_WORKFLOW.md` 写的 `git tag -a v0.17.0 -m "v0.17.0 release"` 实际**从未执行过** | small(1h, 补 v0.18-0.23 共 6 个 tag) | **P0** | C-07 仍**未修**（v0.23 round 38-42 集中清理 13 commit 也**没补 tag**）|
| F-05 | `docs/CHANGELOG.md:264-286` `v0.22.1` 段 | 文档 | Tests 在 Fixed 之后 —— Keep a Changelog 推荐 Tests 在 Added 之后 | trivial(0.2h) | P2 | C-04 仍**未修**（v0.22 round 28 P1 修了 1 处，v0.23 没新动作） |
| F-06 | `docs/CHINESE_COMMIT_GUIDE.md:3` | 文档 | **"项目 commit message subject 用中文" 跟实际 80% 英文不符** —— 头部仍写"subject 用中文"但 §3 已接受双轨制，**头部跟 §3 自相矛盾** | small(0.3h, 改 L3 头部) | P2 | C-06 仍**未修干净**（v0.22 round 28 P1 改了 §3 但 L3 头部没改） |
| F-07 | `docs/CHANGELOG.md` v0.22 段 | 文档 | **v0.22.0 段 (line 223-263) 没 v0.22.1 段（v0.22.1 应该是 v0.22.0 + 1）** | trivial(0.2h) | P2 | **新发现**（v0.22.0 段没标 v0.22.1 是 patch）|
| F-08 | `AGENTS.md:200-210` | 文档 | "v0.23 P0-P3 集中清理" 段说"4 守护脚本全绿" —— **实际 6+ 脚本**：flutter analyze / test / check_all / check_cross_feature / check_arb_keys / check_fullwidth_punctuation / check_datetime_race2。数量 4 不准 | trivial(0.3h) | P3 | **新发现**（v0.23 round 42 新加段**不准确**） |
| F-09 | `AGENTS.md:255-264` 决策记录表 | 文档 | 决策记录没列 P2 / P3 阶段产物 —— 新人不知道 P2 review 怎么走 | trivial(0.5h) | P3 | T-23 仍**未修**（v0.23 round 42 改了 AGENTS 但**没加 P2 review 流程**） |

**汇总**：P0 2 项 / P1 1 项 / P2 3 项 / P3 2 项

**关键发现（增量）**：
- **F-01 / F-04 是 v0.23 期间 P0 必修的合规性文档 bug**：
  - CHANGELOG 缺 v0.23 章节 → 用户 / 法务无法追溯 v0.23 实际变更
  - tag 缺 v0.23 → store 上架版本号无法对齐 git tag
  - 但 v0.23 round 38-42 13 commit 没一个 commit 修这 2 项
- **F-06 v0.22 round 28 P1 修了 2 份规范自相矛盾但没改头部** —— 这是"部分修"反模式（修了 §3 没修头部，文档**仍然自相矛盾**）
- **F-08 v0.23 round 42 新加段第一句就错**（4 vs 6+）—— 这反映"AGENTS.md 自动维护质量差"，**没 CI 守门**

### 8. commit 规范评估

**v0.23 round 31-42 commit 统计**（13 commit）：

| commit | 标题 | 类型 | 评价 |
|--------|------|------|------|
| `7da198c` | round 42: docs(AGENTS) + 4 处 P3 L 项架构债务 TODO 注释 | docs | ✅ 简洁 |
| `a3bd7ee` | round 41: refactor(P3) PressFeedbackIconButton + care_engine 4 strategy + reminders_hub Notifier + zh_Hant stub | refactor | ⚠️ **5 个主题**（PressFeedbackIconButton + care_engine 4 strategy + reminders_hub Notifier + zh_Hant stub + 4 处 TODO 注释）—— 信息密度过高 |
| `1b95e67` | round 40: refactor(emil/spen/spzh) P2 集中清理 12 项 (token 化 + 抽类 + Z 后缀 + tz.local) | refactor | ⚠️ **3 个 skill + 12 项 + 4 个领域** 同样信息密度过高 |
| `68c79c5` | round 39: refactor(P1) 8 项 P1 (catch(_)→swallowError + i18n 38 处 + PDF mask + 50+ test) | refactor | ⚠️ **5 个领域** + D-01 类（commit 信息密度高） |
| `a45e821` | round 38: fix(P0) SMS fail-fast + safety_watch timeout + app.dart 复用 provider (3 项 P0 + 1 项 P1) | fix | ⚠️ **3 个 P0 + 1 个 P1** 4 主题（应拆 2 commit）|
| `aea4e4e` | round 37: refactor(services) BadgeSyncService + ReminderDispatcher 抽类 + mood audio service/storage + database_migration 同步 | refactor | ⚠️ **5 个领域** |
| `ea64504` | round 36: refactor(emil) P1 集中清理 37 处 (token 化 + 反白 + PressFeedback) | refactor | ⚠️ **37 处 + 3 个领域** |
| `2e65dc4` | round 35: refactor(spen) reminders_hub_page god class 拆 5 个 card | refactor | ✅ 简洁 |
| `b8765b5` | round 34: refactor(emil) 抽 5 个通用 widget (架构 P1) | refactor | ✅ 简洁 |
| `5c56ce0` | round 33: fix(P0) vent_audio + release error swallow + ROM 7 品牌 (6 项) | fix | ⚠️ **3 个领域 + 6 项** |
| `e872ff9` | round 32: fix(P0) sp-zh 合规 + 文档版本号 (10 项) | fix | ⚠️ **10 项** |
| `6d659cd` | round 31: fix(P0) 4 个 sp-en P0 工程必修 (mojibake / migration / main 降级 / CI build) | fix | ⚠️ **4 个领域** |
| `f5ae3fd` | round 30: chore(scripts) 加 3 个审查脚本 (ARB key 一致性 + DateTime race 检测) | chore | ⚠️ round 30 已列 D-01 |

**类型分布**（13 commit）：

| 类型 | 数量 | 占比 |
|------|------|------|
| `refactor` | 6 | 46% |
| `fix` | 5 | 38% |
| `docs` | 1 | 8% |
| `chore` | 1 | 8% |
| `feat` | 0 | 0% |
| `test` | 0 | 0% |
| P0/P1/P2/P3 优先级 scope | 11 | 85% |

**commit 风格**：
- 统一头部 `v0.23 round <N>: <type>(<scope>) <subject>` ✅
- 主体 `What + Why + Verification` 结构清晰 ✅
- subject 80% 英文 / 20% 中文 —— 跟 v0.22 round 30 一致
- **commit 信息密度过高**（P0/P1/P2/P3 + 领域 + 数量）—— 13 commit 里 9 个有"信息密度过高"问题

**不符合规范的具体 commit（新增）**：
- **G-01**: `a3bd7ee v0.23 round 41: refactor(P3) PressFeedbackIconButton + care_engine 4 strategy + reminders_hub Notifier + zh_Hant stub` —— **5 个独立主题**应拆 5 commit
- **G-02**: `1b95e67 v0.23 round 40: refactor(emil/spen/spzh) P2 集中清理 12 项` —— **3 个 skill + 12 项**应按 skill 拆 3 commit
- **G-03**: `68c79c5 v0.23 round 39: refactor(P1) 8 项 P1` —— **5 个领域** 应按领域拆 3-4 commit
- **G-04**: `a45e821 v0.23 round 38: fix(P0) SMS fail-fast + safety_watch timeout + app.dart 复用 provider` —— **3 个 P0 + 1 个 P1** 应拆 4 commit（cherry-pick 友好）

**改进建议（新增）**：
1. **commitlint + husky/lefthook 落地**（round 30 T-21 提了，v0.23 round 38-42 仍**未落地**）—— 13 commit 9 个信息密度过高 = 100% 靠人记得规范
2. **G-01~G-04 类 squash 拆 commit** —— 一个 atomic 主题 = 一个 commit
3. **commit body 拆"主题 + 验证 + 决策"3 段**（v0.17 round 14 模板规范）—— 当前多数 commit 没 3 段
4. **不写 "(N 项)" 在 subject**（强制信息密度上限）—— 改成"主体内 bullet 列举"
5. **D-03 内部编号**（`spen-16` 等）应改超链接或 issue 编号 —— round 30 提了 v0.23 仍**未修**

**关键发现（增量）**：
- v0.23 round 38 P0 集中清理（`a45e821`）把 3 个 P0 + 1 个 P1 一起 commit，**违反 round 30 报告 D-02 建议**（"一个 round 一个 atomic 主题"）—— 集中清理**应该按 P0 分 commit**，不是按 round 分 commit
- v0.23 round 41 P3-30 "zh_Hant stub" commit 把 zh_Hant 文件加入但**没在 commit message 强调"是简体副本，下个 round 真做"** —— 后续 reviewer 看到 931 行新增会以为已实现繁简转换
- v0.23 round 38 P0-2 SKIP（"web-only 项目不适用"）在 commit body 写但**没在 AGENTS.md 决策记录**反映（`AGENTS.md` 决策表是 v0.15 之前的）

### 9. 文档质量

> **6 项 P1、4 项 P2、2 项 P3**

| 文档 | 完整度 | 是否最新 | 关键缺失 | 修复难度 | 优先级 | round 30 状态 |
|------|--------|---------|---------|---------|--------|---------------|
| **`docs/CHANGELOG.md`** | **50%** | **❌ 否** | **v0.23 章节完全缺失**（F-01）+ 顺序仍错乱（F-02/F-03） | medium(4-6h) | **P0** | C-03 修了顺序但**没补 v0.23 + 没修干净** |
| `assets/legal/privacy_policy.md` | 80% | ❌ 否 | v0.22 草稿未升级到 v0.23 + 6 处内部矛盾 | large(8-16h, 律师) | **P0** | T-01 仍**未升级** |
| `assets/legal/sensitive_data_consent.md` | 80% | ❌ 否 | 同上 | large | **P0** | T-01 仍**未升级** |
| `assets/legal/user_agreement.md` | 80% | ❌ 否 | 同上 | large | **P0** | T-01 仍**未升级** |
| `docs/WHITEPAPER.md` | 95% | ✅ 是 | § P0 残留（占位邮箱 / 文档"治愈"措辞）仍列"待修" | - | - | ✅ 部分修 |
| `docs/DEPLOYMENT.md` | 90% | ❌ 否 | §5 仍有 4+ 敏感措辞（"再治愈更难" 残留）+ "声明'非医疗器械'" 待法务 | small(1h) | P1 | C-10 / C-11 仍**未修干净** |
| `docs/SENDGRID_SETUP.md` | 90% | ✅ 是（round 29 修 6 处） | §3 仍有 1-2 处示例待更新 | small(0.5h) | P2 | ✅ 大部分修 |
| `docs/CHINESE_COMMIT_GUIDE.md` | 70% | ❌ 否 | L3 "subject 用中文" 跟 §3 双轨制自相矛盾 | small(0.5h) | P2 | C-06 仍**未修干净** |
| `docs/GIT_WORKFLOW.md` | 80% | ❌ 否 | tag 流程完全失效（v0.18-0.23 全无 tag） | small(1h) | **P0** | C-07 仍**未修** |
| `AGENTS.md` | 95% | ✅ 是（v0.23 round 42 加 P0-P3 段） | P2 review 流程未列 + 守护脚本数 4 vs 实际 6+ | small(0.5h) | P3 | T-23 仍**未修** + 新增不准确 |

**汇总**：P0 5 项 / P1 1 项 / P2 3 项 / P3 1 项

**关键发现（增量）**：
- **F-01 / F-04 / A-01 三个 P0 文档 bug 12 round 零修复**：
  - F-01：CHANGELOG 缺 v0.23 章节
  - F-04：tag 缺 v0.23
  - A-01：3 份法律文档 v0.22 草稿未升级
- v0.23 round 38 P0 集中清理**完全没动文档**（commit `a45e821` 仅改 lib/ 3 个 service 文件）
- v0.23 round 39 P1 集中清理 38 处 i18n **没动法律文档**（commit `68c79c5` 仅改 lib/）
- v0.23 round 40 P2 集中清理 12 项 **没动文档**（commit `1b95e67` 仅改 lib/ + themes/ + providers/）
- v0.23 round 41 P3 集中清理 4 实做 + 5 TODO **只动 AGENTS.md**（commit `a3bd7ee` 加 v0.23 P0-P3 段）
- v0.23 round 42 docs 仅改 AGENTS.md **没动 CHANGELOG / tag / 法律文档**

**结论**：v0.23 13 commit 中**只有 1 个 commit 改文档**（AGENTS.md），**0 个 commit 改 CHANGELOG / tag / 法律文档**。这是"代码 / 文档"严重失衡 —— round 30 报告 §"文档质量" 提的 6 份 P2 review 进度不透明、CHANGELOG 顺序混乱、tag 流程失效，**12 round 零修复**。

### 10. 中文 Git 工作流

> **3 项 P1、2 项 P2、1 项 P3**

- **branch 策略**：单 master，无 dev / feature branch —— 跟 `GIT_WORKFLOW.md` §73 写的一致 ✅
- **tag 流程**：**v0.18 - v0.23 全无 tag**（`git tag -l` 空）—— `GIT_WORKFLOW.md` §82-89 写的"每个 minor version 打 tag"**完全失效**
- **PR 流程**：无 PR（单 dev 不需要）—— ✅
- **commit 粒度**：单 round 1-13 commit，v0.23 round 38-42 平均 1 commit / round（v0.22 round 30 平均 8 commit / round）—— **粒度变粗**
- **commit 信息**：v0.23 round 38-42 仍**80% 英文 / 20% 中文混**，规范没变 —— ✅
- **CI 强制**：仅本地验证 6+ 脚本，**未接 GitHub Actions / Gitee Go / 极狐 GitLab CI**

**改进建议**（按 P1 → P3）：
1. **P0（F-04）**：补 v0.18-0.23 tag（`git tag -a v0.23.0 -m "..."` + push）—— **应用商店上架需要**
2. **P1**：CHANGELOG 顺序修正 + 补 v0.23 章节（F-01 / F-02 / F-03）
3. **P1**：commitlint + husky/lefthook 落地（v0.23 round 38-42 仍**未落地**）
4. **P2**：standard-version / release-please 自动 release notes
5. **P2**：迁移到 Gitee / 极狐 GitLab（国内访问更稳定）—— 不是必须
6. **P3**：CHINESE_COMMIT_GUIDE.md 头部跟 §3 统一（C-06）

**关键发现（增量）**：
- v0.23 round 38 P0 集中清理 4 主题 1 commit + round 39 P1 集中清理 5 领域 1 commit = **"集中清理"反模式**（一个 commit 5+ 主题，cherry-pick 不友好，code review 难以逐项 review）
- v0.23 round 41 P3-30 "zh_Hant stub" 931 行新增 commit **未单独 commit**（混在 P3 集中清理 5 主题 commit 里）—— 后续撤销 / 替换 zh_Hant 必须 revert 整个 commit
- **Gitee / 极狐 GitLab 迁移** 在 v0.23 round 38-42 仍**未评估** —— 国产 store 上架时（4 大 store 都要求 ICP 备案 + 实名开发者），建议同步评估 git 仓库迁移

### 11. workflow-runner / brainstorming 落地

> **3 项 P1、3 项 P2、1 项 P3**

| Skill | 落地情况 | 评价 |
|-------|---------|------|
| **brainstorming** | ❌ v0.23 round 38-42 13 commit **0 处 brainstorm** 痕迹 | P0 / P3 修法直接 commit，**违反 superpowers-zh 流程规范**（"哪怕 1% 适用就调 brainstorming"） |
| **writing-plans** | ❌ v0.23 round 38-42 0 处 plan 文档（`docs/plans/` 不存在） | 大版本 release 应有 `docs/plans/v0.24.md` |
| **executing-plans** | - | 同上 |
| **TDD（test-driven-development）** | ⚠️ round 38 P0-3 safety_watch timeout 2 test + P0-1 SMS validate 12 test = **14 test 是先写 test 再写实现**（TDD） ✅ | 但 round 39 P1-9 PDF mask + 50+ test 仍**"先发现 bug 再写 test"**（v0.22 round 30 提过"项目没红灯先行"）|
| **systematic-debugging** | ✅ round 38 P0-3 safety_watch 4 步法体现（重现 → 定位 → 修法 → 验证） | OK |
| **verification-before-completion** | ✅ 6+ 守护脚本（flutter analyze / test / check_all / check_cross_feature / check_arb_keys / check_fullwidth_punctuation / check_datetime_race2）| OK 但**未接 GitHub Actions / Gitee Go** |
| **code-review**（requesting + receiving）| ✅ v0.23 round 38-42 三视角 review（emil / spen / spzh）| OK |
| **subagent-driven-development** | ✅ v0.23 round 38-42 P0/P1/P2 集中清理派 3 sub-agent | OK |
| **workflow-runner** | ❌ v0.23 round 38-42 0 处使用 | **新发现**：v0.24+ release 应启用 |
| **using-git-worktrees** | ❌ 单 master 不需要 | OK |
| **finishing-a-development-branch** | ❌ 单 master 不需要 | OK |

**整体 superpowers-zh 落地度**：从 round 30 报告的 70% → 当前 **65%**（**退步 5%**）：
- **退步**：`AGENTS.md` 没加"硬性 brainstorming 规则"（D-01）+ v0.23 round 38-42 13 commit 0 处 brainstorm + v0.23 round 41 P3-30 "zh_Hant stub" 是典型"拍脑袋"反例
- **进步**：TDD 部分落地（round 38 P0-3 timeout test）+ workflow-runner 仍**未启用**

**关键发现（增量）**：
- v0.23 round 38 P0 集中清理 4 主题 1 commit **应走 brainstorming**（"SMS fail-fast 是不是 P0？""safety_watch timeout 5s 是不是太短？""app.dart 复用 provider 会不会破坏其他 widget？"）—— 但**没走**
- v0.23 round 41 P3-27 标"厂商通道 web-only 当前不适用"是**信息不全的拍脑袋**（DEPLOYMENT.md 写 4 大国产 store + pubspec 没排除 Android）
- v0.23 round 41 P3-30 "zh_Hant stub" **应走 brainstorming**（"港澳台用户用 App 比例？""简体副本当 zh_Hant 是否会让繁体用户困惑？""未来繁简转换工作量？"）

### 12. round 30 P0/P1 修复状态确认

> **24 项 P0/P1 修复状态总览**

| round 30 ID | 标题 | 优先级 | round 42 状态 |
|------------|------|--------|---------------|
| T-01 | 3 份法律文档 v0.21 草稿未经律师 | **P0** | ❌ **未升级到 v0.23**（仍 v0.22 草稿） |
| T-02 | 隐私政策 §3 "用户姓名" → "用户昵称" | **P0** | ❌ **修复后又复发**（仅 §1 表格修，§3 失联通知段漏修） |
| T-03 | app_zh.arb:89 settingsAboutVersion v0.1.0 → v0.22 | **P0** | ⚠️ **修了 v0.1→v0.22 但 v0.22→v0.23 没续修**（pubspec 也仍 0.22.0+2）|
| T-04 | 隐私政策 §1 设备信息矛盾 | **P0** | ❌ **未修**（`assets/legal/privacy_policy.md:38` 仍矛盾）|
| T-05 | 5 厂商 push 通道未接 | **P0** | ❌ **未修**（v0.23 round 41 P3-27 误判"web-only 当前不适用"）|
| T-06 | AES-256 → 国密 SM4 | P1 | ❌ **未修**（v0.23 round 38-42 0 提）|
| T-07 | 隐私政策 §1 "健康数据" → "健康记录" | P1 | ❌ **未修**（`assets/legal/privacy_policy.md:36` 仍"健康数据"）|
| T-08 | 隐私政策 §0 4 个 consent 字段跟 schemaVersion 11 同步 | P1 | ✅ round 30 后已落地 |
| T-09 | DEPLOYMENT.md §5 "医疗"+"治愈"措辞 | P2 | ⚠️ **修了 1 处（line 154-157 round 28 修过）但 line 155-157 残留**（C-10）|
| T-10 | 5 厂商 push 通道未接 | **P0** | ❌ 同 T-05 |
| T-11 | 国产 ROM 自检卡扩品牌 | **P0** | ✅ round 33 修过 7 品牌（Xiaomi+Redmi / Huawei+荣耀 / OPPO+realme+一加 / Vivo+iQOO / Meizu / Samsung+OneUI / Others+Knox）|
| T-12 | 农历 / 24 节气 / 节假日 streak 跳过 | P1 | ❌ **未修** |
| T-13 | 农历生日 / 节气提醒 | P1 | ❌ **未修** |
| T-14 | zh_Hant 繁体中文 | P1 | ❌ **未真做**（round 41 P3-30 "stub" 实际是简体副本）|
| T-15 | 失联阈值 36h 写死 | P2 | ❌ **未修** |
| T-16 | `.env` build-time 注入 race | P2 | ❌ **未修** |
| T-17 | `check_fullwidth_punctuation.py` ASCII_PUNCT 漏检 | P1 | ❌ **未扩展**（v0.23 round 38-42 0 字符改动）|
| T-18 | i18n 中英 ARB keys 不对齐 | P1 | ✅ round 30 后已对齐（`check_arb_keys.py` 0 missing）|
| T-19 | app_zh.arb 7+ 处半角 `/` | P1 | ❌ **未修**（11+ 处 v0.23 round 39 38 处 i18n 集中**没扩**）|
| T-20 | CHANGELOG.md 顺序混乱 | P2 | ❌ **未修干净**（v0.16 段仍错位）|
| T-21 | commitlint + husky/lefthook 未落地 | P2 | ❌ **未落地**（v0.23 round 38-42 0 改动）|
| T-22 | release notes 自动生成未用 | P2 | ❌ **未用** |
| T-23 | AGENTS.md 决策记录没列 P2 阶段产物 | P3 | ❌ **未修**（v0.23 round 42 加了 P0-P3 段但**没加 P2 review 流程**）|
| T-09 (重复) | DEPLOYMENT.md 措辞 | P2 | 同上 |
| T-10 (重复) | push 通道 | **P0** | 同 T-05 |

**P0/P1 修复率**：
- **P0 必修 5 项**：修 0 项 / 部分修 1 项（T-11 ROM 7 品牌）/ 修复后又复发 1 项（T-03 v0.22→v0.23）/ 误判 1 项（T-05 round 41 P3-27 标 web-only 当前不适用）/ 完全未修 2 项（T-01 / T-02 / T-04）= **P0 修复率 20%**（0/5）
- **P1 应修 11 项**：修 2 项（T-08 schemaVersion / T-18 ARB keys）/ 部分修 0 项 / 未修 9 项 = **P1 修复率 18%**（2/11）
- **P2 可修 5 项**：修 0 项 / 未修 5 项 = **P2 修复率 0%**（0/5）
- **P3 1 项**：未修 1 项 = **P3 修复率 0%**（0/1）

**整体修复率**：3 / 22 = **13.6%**（P0/P1/P2/P3 22 项中只修 3 项 = **86% 未修**）

**关键发现（增量）**：
- v0.23 round 38-42 13 commit **0 个 commit 修 round 30 P0/P1**（除 T-11 ROM 7 品牌是 round 33 修的）—— **P0 必修类完全停滞**
- v0.23 round 38 P0 集中清理（commit `a45e821`）**只清理了 round 30 spen 报告提的 P0**（SMS fail-fast / safety_watch timeout / app.dart provider 复用），**完全没动 spzh 报告提的合规 P0**
- v0.23 round 39 P1 集中清理（commit `68c79c5`）修了 round 30 spen 报告提的 P1（catch(_)/ i18n / PDF mask）= 8 项 P1，**完全没动 spzh 报告提的 P1**（半角 / 您你 / zh_Hant / 标签 emoji / 国密 SM4 / 农历）
- v0.23 round 40 P2 集中清理（commit `1b95e67`）修了 12 项 P2（emil / spen / spzh 各自 4 项）—— **spzh 报告提的 P2 修了 4 项**（半角 / 中文文案 / i18n token）但**只占 round 30 spzh 报告 P2 的 25%**（4/16）
- **v0.23 round 38-42 整体修复率 13.6%** —— **86% 的 P0/P1/P2/P3 未修**，**这是项目的最大风险**

### 13. 国内生态潜在问题（增量）

> **5 项 P0、3 项 P1、2 项 P2**

| # | 类型 | 描述 | 修复难度 | 优先级 | round 30 状态 |
|---|------|------|---------|--------|---------------|
| O-01 | **P0 NEW** | **pubspec.yaml:4 version 仍 0.22.0+2** —— v0.23 round 42 仍是 0.22.0+2。store 上架版本号不一致 + 隐私政策 §0 写 "v0.22-2026-07-21" 是错误版本号 | trivial(0.2h) | **P0** | T-03 修了 v0.1→v0.22 但 v0.22→v0.23 没续修 |
| O-02 | **P0 NEW** | **CHANGELOG.md 缺 v0.23 章节** —— v0.23 round 31-42 13 commit 0 条目 | medium(4-6h) | **P0** | C-03 没修内容（只修了部分顺序）|
| O-03 | **P0 NEW** | **tag 缺 v0.18-0.23** —— 应用商店上架版本号无法对齐 git tag | small(1h) | **P0** | C-07 仍**未修** |
| O-04 | **P0 NEW** | **app_zh_Hant.arb 是简体副本** —— 569 keys 全是简体，跟 `app_zh.arb` diff 1 行（仅 `@@locale`） | medium(6-8h, 569 keys 繁简转换) | **P0** | T-14 仍**未真做** |
| O-05 | **P0** | 5 厂商 push 通道未接 | xlarge(80-120h) | **P0** | T-05 / N-11-14 仍**未修**（v0.23 round 41 P3-27 误判 web-only） |
| O-06 | **P1** | 时区处理 | small(1h) | P1 | N-02 仍**未修** |
| O-07 | **P1** | 国密 SM4 | large(8-16h) | P1 | T-06 仍**未修** |
| O-08 | **P1** | 农历 / 节气 / 节假日 | medium-large(8-12h) | P1 | T-12 / T-13 仍**未修** |
| O-09 | **P2** | pubspec 国内镜像 | trivial(0.2h) | P2 | N-06 仍**未修** |
| O-10 | **P2** | 应用商店元数据（截图 / ICP 备案号 / 4 大 store 审核材料） | medium(6-8h) | P2 | N-07 仍**未修** |

**关键发现（增量）**：
- **O-01 / O-02 / O-03 是 v0.23 期间 P0 必修的"项目治理"类 bug**：
  - O-01：版本号不一致 → store 上架被拒
  - O-02：CHANGELOG 缺 v0.23 → 律师 / 用户无法追溯
  - O-03：tag 缺 v0.23 → store 上架版本号无法对齐
- 这 3 项都是**纯文档 / 版本号**问题，**零技术风险，零代码改动** —— 但 v0.23 round 38-42 13 commit 0 个 commit 修
- **O-04 zh_Hant stub 是 P3-30 commit 的"假完成"**（931 行新增但实际是简体副本）—— **新发现**

---

## 汇总统计

### 1. 按模块分

| 模块 | 数量 | P0 | P1 | P2 | P3 |
|------|------|------|------|------|------|
| **A. 国内合规风险** | 8 | 5 | 3 | 0 | 0 |
| **B. 国内生态适配** | 6 | 2 | 3 | 1 | 0 |
| **C. 可重构中文模块** | 7 | 0 | 3 | 4 | 0 |
| **D. 流程架构** | 5 | 0 | 2 | 2 | 1 |
| **E. 中文文案规范** | 9 | 2 | 5 | 3 | 0 |
| **F. 注释/命名/文档规范** | 9 | 2 | 1 | 3 | 2 |
| **G. commit 规范** | 5 | 0 | 3 | 2 | 0 |
| **H. 文档质量** | 10 | 5 | 1 | 3 | 1 |
| **I. 中文 Git 工作流** | 6 | 1 | 1 | 2 | 1 |
| **J. workflow-runner** | 6 | 0 | 3 | 3 | 0 |
| **K. round 30 修复状态** | 22 | 5 修 1 | 11 修 2 | 5 修 0 | 1 修 0 |
| **L. 国内生态潜在** | 10 | 4 | 3 | 2 | 0 |
| **总计（去重）** | **62** | **21** | **30** | **9** | **2** |

### 2. 按工作量分

| 难度 | 数量 | 占比 | 代表性问题 |
|------|------|------|----------|
| trivial (<1h) | 11 | 18% | O-01 pubspec version / E-01 settingsAboutVersion / A-02 §3 "用户姓名" / C-01 ASCII_PUNCT 扩展 |
| small (1-4h) | 26 | 42% | C-02 11+ 半角 `/` / F-04 补 v0.18-0.23 tag / E-04 您你 / D-01 brainstorming 规则 |
| medium (4-8h) | 11 | 18% | O-04 zh_Hant 真做 / F-01 CHANGELOG v0.23 章节 / D-02 workflow-runner YAML |
| large (8-16h) | 8 | 13% | A-01 法律文档律师外审 / C-05 Strings 参数注入 / B-05 农历节气 |
| xlarge (>16h) | 1 | 2% | A-05 5 厂商 push 通道 |
| **总计** | **57** | **92%** | 5 项工作量待评估（D-03 plans/ 模板等） |

### 3. 工作量估算

| 优先级 | 估算 h | 按 8h/天 | 不含项 |
|--------|--------|---------|--------|
| P0 | 89-145h | 11-18 工作日 | 含 5 厂商 push 接入 |
| P0 (不含 push) | 9-17h | 1-2 工作日 | 不含 5 厂商 push 接入 |
| P1 | 56-94h | 7-12 工作日 | - |
| P2 | 26-44h | 3-5 工作日 | - |
| P3 | 1-3h | 0.5 工作日 | - |
| **总（含 push）** | **172-286h** | **21-36 工作日** | - |
| **总（不含 push）** | **92-158h** | **11-20 工作日** | - |

### 4. 与 round 30 对比

| 维度 | round 30 (v0.22) | round 42 (v0.23) | 变化 |
|------|----------------|----------------|------|
| 总问题数 | 64 | 62 | -2 |
| P0 必修 | 18 | 21 | +3（**新发现 4 项**：pubspec 0.22.0+2 / CHANGELOG 缺 v0.23 / tag 缺 v0.23 / app_zh_Hant 是简体副本）|
| P1 应修 | 25 | 30 | +5（**新发现** ：commit 信息密度过高 4 项 + 7+ 半角 `/` 11 处 + 半角 `…` 4 处 + 您你 2 处 + 您/你 风格未统一）|
| P2 可修 | 16 | 9 | -7（已合并到 P1）|
| P3 nice-to-have | 5 | 2 | -3 |
| **总工作量** | 149-231h（含 push） | 172-286h（含 push） | +23h |
| **总工作量（不含 push）** | 69-111h | 92-158h | +47h（**显著退步**）|
| **P0/P1/P2/P3 修复率** | - | 13.6%（3/22） | **86% 未修** |
| **round 30 P0 修复率** | - | 20%（1/5） | 80% 未修 |

---

## 关键观察（3-5 段）

### 1. v0.23 是项目的"文档债大爆发"：13 commit 中 12 个改代码，0 个改 CHANGELOG / tag / 法律文档

v0.23 round 38-42 13 commit 中：
- 12 commit 改 `lib/`（3 service + 1 widgets + 1 theming + 1 providers + 1 setup + 1 vent + 1 med + 1 home + 1 settings + 1 杂）
- 1 commit 改 `AGENTS.md`（round 42 加 P0-P3 段，**不准确** —— 4 vs 实际 6+）
- **0 commit 改 `CHANGELOG.md`**（v0.23 章节缺失）
- **0 commit 改 `git tag`**（v0.18-0.23 全无 tag）
- **0 commit 改 3 份法律文档**（仍 v0.22 草稿）

这是**"代码 / 文档"严重失衡**的反模式。v0.22 round 30 报告 §"文档质量" 提的 6 份 P2 review 进度不透明 + CHANGELOG 顺序混乱 + tag 流程失效 + 法律文档 v0.21 草稿未经律师，**12 round 零修复**。

**根因**：`AGENTS.md` 开发流程 5 步走（domain → data → presentation → tests → commit）**没"文档同步"步骤**。`P2 review 流程` 也没在 AGENTS.md 里。**commit 模板不强制** Documentation Block。

### 2. v0.23 是项目的"合规 P0 集体忽视"：5 项合规 P0 中 0 项真修，1 项修复后又复发

v0.22 round 30 报告列的 5 项合规 P0（T-01 / T-02 / T-03 / T-04 / T-05）：
- T-01（法律文档）：❌ 12 round 0 改动
- T-02（用户姓名 → 昵称）：❌ 修复后又复发（§1 修 §3 漏修）
- T-03（app_zh.arb settingsAboutVersion v0.1→v0.22）：⚠️ 修了 v0.1→v0.22 但 v0.22→v0.23 没续修
- T-04（设备信息矛盾）：❌ 12 round 0 改动
- T-05（5 厂商 push 通道）：❌ 误判 web-only 当前不适用

**根因**：v0.23 round 38 P0 集中清理（commit `a45e821`）**只清理了技术 P0**（SMS fail-fast / safety_watch timeout / app.dart provider 复用），**完全没动合规 P0**。这是"什么是 P0"的认知偏差 —— 技术债 ≠ 合规债，**合规 P0 是上架阻塞性 P0**（store 提交必拒）。

**建议**：v0.24 立项时**合规 P0 必须单独立项**（不能跟技术 P0 混），**法务 + 技术 + 伦理 3 方联合 review**（参考 round 30 §"关键观察 6"）。

### 3. v0.23 是项目的"假完成"反模式：3 个典型案例（zh_Hant stub / P0-2 SKIP / P3-27 web-only 误判）

v0.23 round 38-42 13 commit 出现 3 个"假完成"反模式：

**案例 1**：v0.23 round 41 P3-30 "zh_Hant stub"（commit `a3bd7ee`）：
- 标题："zh_Hant stub"
- 产物：`lib/l10n/app_zh_Hant.arb` 931 行
- 实际：`app_zh_Hant.arb` 跟 `app_zh.arb` diff 仅 1 行（仅 `@@locale`），**是简体副本**
- 文件名"app_zh_Hant"声明 zh_Hant locale，但内容是简体
- 后续 reviewer 看 diff 1 行以为已翻译，实际**没翻译任何繁体**
- 注释承认"基础版本跟 app_zh.arb 同 (简体)" —— 但**没标 ⚠️**

**案例 2**：v0.23 round 38 P0-2 "Android 12+ SCHEDULE_EXACT_ALARM 权限"：
- 标题："P0-2 (SKIP): Android 12+ SCHEDULE_EXACT_ALARM 权限"
- 实际：理由"项目 .metadata 只有 root + web 平台, 无 android/ 目录" —— **错判**
- 实际：`DEPLOYMENT.md` 目标"4 大国产 store"（含 Android）+ `pubspec.yaml:74-75` `generate: true`（非 web-only 标志）
- 移到 P3 长期（"等用户上 Android 时再补"）—— **没用户的项目怎么等？**

**案例 3**：v0.23 round 41 P3-27 "厂商通道（web-only 项目当前不适用）"：
- 同 P0-2 错判
- 实际：`DEPLOYMENT.md:182-186` 明确说"Google Play / Apple App Store / 华为 / 小米 / OPPO / vivo 4 大国产 store"

**根因**：v0.23 round 38-42 13 commit 全部**单 dev 串行**，**0 处 brainstorming**（按 v0.22 round 30 brainstorming 落地表分类，3 个 P0 fix + 1 个 P1 fix + 12 个 refactor 都属于"明确方向的不需要 brainstorm"或"拍脑袋"）。**违反 superpowers-zh 流程规范**（"哪怕 1% 适用就调 brainstorming"）。

**建议**：`AGENTS.md` 加硬性规则 —— "P0 修法 / 新 feature / 命名涉及 P0-P3 优先级 / 文件 > 100 行新增 必须先 brainstorming"。

### 4. v0.23 是项目的"集中清理反模式"：5 个"集中清理"commit 信息密度过高，cherry-pick 不友好

v0.23 round 38-42 13 commit 中 5 个是"集中清理"类型（一个 commit 5+ 主题）：
- `a45e821` round 38: **3 P0 + 1 P1** 4 主题
- `68c79c5` round 39: **5 领域** 8 项 P1
- `1b95e67` round 40: **3 skill + 12 项 + 4 领域** P2
- `a3bd7ee` round 41: **5 主题** P3
- `aea4e4e` round 37: **5 领域** refactor

**反模式 1**：cherry-pick 不友好（如果只想回滚 1 个 P0，必须 revert 整个 commit，其他 P0 也跟着回滚）
**反模式 2**：code review 难以逐项 review（5 主题 = 5 段，每段都不深）
**反模式 3**：commit message 信息密度过高（"3 P0 + 1 P1" + 5 主题挤 1 行 subject）
**反模式 4**：bug 难以定位（"a45e821 修的 4 个 P0 中第 2 个"必须查 commit body）

**根因**：
1. **v0.23 round 38 集中清理 4 主题 1 commit**（commit `a45e821`）开了坏头
2. **v0.23 round 39 / 40 / 41 沿用此模式**
3. **commitlint + husky/lefthook 未落地**（T-21 v0.22 round 30 提了 v0.23 round 38-42 仍**未落地**）—— 100% 靠人记得规范

**建议**：
- 一个 atomic 主题 = 一个 commit
- 不写 "(N 项)" 在 subject（强制信息密度上限）
- commit body 拆"主题 + 验证 + 决策"3 段
- 落 commitlint + husky/lefthook（v0.24+ 立项）

### 5. 顶层架构建议（按优先级）

**建议 1（P0 必修）**：v0.24 立项时**合规 P0 单独立项**，不跟技术 P0 混：
- 法务外审 3 份法律文档（A-01，8-16h）
- 隐私政策 §3 "用户姓名" → "用户昵称"（A-02，0.1h，6 处改）
- 隐私政策 §1 设备信息矛盾修（A-03，0.3h）
- `pubspec.yaml:4` + `app_zh.arb:89` version 0.22.0→0.23.0（A-04，0.2h）
- 5 厂商 push 通道接入（A-05，80-120h，分 5-6 round）
- 真 zh_Hant 繁体中文（B-01，6-8h，569 keys 繁简转换）
- CHANGELOG 补 v0.23 章节（F-01，4-6h）
- 补 v0.18-0.23 tag（F-04，1h）

**建议 2（P1 应修）**：中文文案规范 4 项集中清理：
- C-01 扩 `check_fullwidth_punctuation.py` ASCII_PUNCT 到 8+ 种（trivial）
- C-02 11+ 处半角 `/` 改全角（small，1h）
- C-03 4+ 处半角 `…` 改全角（trivial，0.3h）
- C-04 您/你 统一（small，1h）

**建议 3（P1 应修）**：`AGENTS.md` 加 superpowers-zh 流程硬性规则：
- D-01 P0 修法 / 新 feature 必须先 brainstorming
- D-02 大版本 release 走 workflow-runner YAML
- D-04 决策记录加 P2 review 流程
- D-05 加"流程规范"段指向 6 个中国特色 skill

**建议 4（P2 可修）**：commitlint + husky/lefthook 落地（commit 信息密度守门）

**建议 5（P2 可修）**：法律 / CHANGELOG / tag 同步加 CI 脚本守门：
- 脚本 1：`pubspec.yaml:4` version 跟 `app_zh.arb:89` settingsAboutVersion 一致性检查
- 脚本 2：`git tag -l` 应有 v0.X.0 (X = 当前 minor)
- 脚本 3：`CHANGELOG.md` 应有当前 minor section 检查
- 脚本 4：3 份法律文档 header 应有"v0.X.X 草稿"（X = 当前版本）

---

## 附录 A：审查覆盖范围

| 类别 | 数量 | 备注 |
|------|------|------|
| lib/ 文件 | 183 | 抽样审 30+（关键 service + l10n + setup + notification） |
| test/ 文件 | 74 | 抽样审 5+（care_engine_round41 / setup_round36 等） |
| scripts/ | 17 | 关键 6 个（check_all / check_cross_feature / check_arb_keys / check_fullwidth_punctuation / check_datetime_race2 / check_drift_namespace） |
| docs/ 文档 | 10 | 全过（README / AGENTS / CHANGELOG / WHITEPAPER / DEPLOYMENT / SENDGRID_SETUP / 3 份 P2 review + GIT_WORKFLOW / CHINESE_COMMIT_GUIDE）|
| assets/legal/ | 3 | 全过（隐私政策 / 用户协议 / 敏感同意书） |
| v0.22 round 30 → v0.23 round 42 commit | 13 | 全过（`git log --oneline` 13 commit）|
| 最近 v0.23 round 38-42 commit | 5 | 详细 review（`a45e821` / `68c79c5` / `1b95e67` / `a3bd7ee` / `7da198c`）|
| ARB 完整度 | 99.5% | zh 569 keys / en 569 keys / 0 missing |
| pubspec version 一致性 | **❌ FAIL** | pubspec 0.22.0+2 / app_zh.arb 0.22.0 / 实际 v0.23 |
| git tag 流程 | **❌ FAIL** | v0.18-0.23 全无 tag |
| CHANGELOG 完整性 | **❌ FAIL** | 缺 v0.23 章节 + 顺序错乱 |
| 3 份法律文档 v0.23 升级 | **❌ FAIL** | 仍 v0.22 草稿 |

## 附录 B：v0.24 立项建议（按 P0 → P1 → P2 → P3）

### Round 43（P0 集中清理，预计 1-2 个 round，9-17h）
1. **A-01** 法务外审 3 份法律文档（8-16h，**必须先做**）
2. **A-04** `pubspec.yaml:4` + `app_zh.arb:89` version 0.22.0→0.23.0（0.2h）
3. **A-02** 隐私政策 §3 "用户姓名" → "用户昵称"（0.1h）
4. **A-03** 隐私政策 §1 设备信息矛盾修（0.3h）
5. **F-04** 补 v0.18-0.23 tag（1h）
6. **F-01 / F-02 / F-03** CHANGELOG 顺序修正 + 补 v0.23 章节（4-6h）
7. **C-01 / C-02 / C-03 / C-04** 中文文案规范 4 项集中清理（2-3h）

### Round 44-48（P0 厂商 push 接入，分 5 个 round，80-120h）
1. Round 44: HMS 接入（华为开发者联盟 + 推送证书，xlarge 16-24h）
2. Round 45: MIPush 接入（小米，xlarge 16-24h）
3. Round 46: OPPO PUSH 接入（含 realme / 一加，xlarge 16-24h）
4. Round 47: vivo Push 接入（含 iQOO，xlarge 16-24h）
5. Round 48: 魅族 FlymePush 接入（medium-large 4-8h）

### Round 49-50（P1 集中清理，预计 2-3 个 round，56-94h）
1. **B-04** 失联阈值 36h 可配（2h）
2. **B-05** 农历 / 24 节气 / 节假日 streak 跳过（8-12h）
3. **B-03** 邮件 / SMS 模板 i18n 化（4-6h）
4. **D-01 / D-02 / D-04 / D-05** AGENTS.md superpowers-zh 流程硬性规则（4-6h）
5. **O-04** 真 zh_Hant 繁体中文（6-8h，569 keys 繁简转换）
6. **O-06 / O-07 / O-08** 时区 / 国密 SM4 / 农历（10-20h）

### Round 51-52（P2 集中清理，预计 1-2 个 round，26-44h）
1. **C-05 / C-06 / C-07** lib/core/l10n/strings.dart Strings 参数注入 + ARB 全角 / 全角扩展 + P2 review 流程（8-10h）
2. **E-05 / E-08** 您你策略 + 海外医生 PDF i18n（4-6h）
3. **F-05 / F-06 / F-07** CHANGELOG Tests 顺序 + 头部 + v0.22.1 patch 标（2-3h）
4. **O-09 / O-10** pubspec 国内镜像 + 应用商店元数据（6-10h）
5. **G-01~G-05** commit 信息密度改进（commitlint + husky/lefthook，6-8h）

### Round 53+（P3 nice-to-have，预计 0.5 round，1-3h）
1. **F-08 / F-09** AGENTS.md 守护脚本清单准确化 + P2 review 流程加段（0.5h）
2. 顶层架构小重构（riverpod_generator / privacy 子包化 / widget library 子目录化）—— 参考 owner 顶层架构审视 owner A / B / E

## 附录 C：P0 必修完整清单（按文件:行号）

```
pubspec.yaml:4                                 A-04  version 0.22.0+2 → 0.23.0+1
lib/l10n/app_zh.arb:89                         A-04  settingsAboutVersion v0.22.0 → v0.23.0
lib/l10n/app_en.arb:74                         A-04  同上英文版
lib/l10n/app_localizations_zh.dart:222         A-04  同上 (generated)
lib/l10n/app_localizations_en.dart:229         A-04  同上 (generated)

assets/legal/privacy_policy.md:3               A-01  v0.22 草稿未经律师 (升级到 v0.23)
assets/legal/privacy_policy.md:60              A-02  "用户姓名" → "用户昵称" (失联通知段)
assets/legal/privacy_policy.md:38              A-03  设备信息"不收集" vs "通知/兼容性" 矛盾
assets/legal/sensitive_data_consent.md:3       A-01  v0.22 草稿未经律师
assets/legal/user_agreement.md:3               A-01  v0.22 草稿未经律师

lib/l10n/app_zh_Hant.arb 整文件                B-01  简体副本 → 真繁体中文 (569 keys 繁简转换)
pubspec.yaml:18-58 全部依赖                    A-05  5 厂商 push SDK 接入
lib/core/data/services/notification_service.dart  A-05  5 厂商 push SDK 接入

docs/CHANGELOG.md:5-477                        F-01  补 v0.23 章节
docs/CHANGELOG.md:288-479                      F-02  顺序错乱 v0.16 在最末
docs/CHANGELOG.md:479-585                      F-03  v0.16 段错位

git tag -l                                     F-04  补 v0.18-0.23 共 6 个 tag
```

## 附录 D：1 句话总结

v0.23 round 38-42 是项目的"代码 / 文档" 严重失衡期 —— 13 commit 中 12 个改代码、0 个改 CHANGELOG / tag / 法律文档，导致 round 30 报告 P0/P1/P2/P3 22 项只修 3 项（修复率 13.6%），同时新发现 4 个 P0（pubspec 0.22.0+2 / CHANGELOG 缺 v0.23 / tag 缺 v0.23 / app_zh_Hant 是简体副本）和 5 个"假完成"反模式（zh_Hant stub / P0-2 SKIP / P3-27 web-only 误判 / 集中清理信息密度过高 / 法务外审流程缺位）；**v0.24 立项必须**合规 P0 单独立项 + 法务外审 + 5 厂商 push 接入 + superpowers-zh 流程硬性规则 + 中文文案规范 4 项集中清理。

---

**审查完成。**

- 总问题数：**62**（含 round 30 修复状态确认 22 项）
- P0：**21**
- P1：**30**
- P2：**9**
- P3：**2**
- 总工作量估算：**172-286h（21-36 工作日）**（含 5 厂商 push 接入）或 **92-158h（11-20 工作日）**（不含 push）
- round 30 P0/P1/P2/P3 修复率：**13.6%**（3/22 修，**86% 未修**）
- v0.24 立项**必做 5 件事**：
  1. **法务外审 3 份法律文档**（A-01，large 8-16h）
  2. **pubspec + app_zh.arb version 0.22→0.23**（A-04，trivial 0.2h，**CI 守门**）
  3. **5 厂商 push 通道接入**（A-05，xlarge 80-120h，分 5 round）
  4. **CHANGELOG 补 v0.23 + 补 v0.18-0.23 tag**（F-01 / F-04，medium 5-7h）
  5. **`AGENTS.md` 加 superpowers-zh 流程硬性规则**（D-01 / D-02，small 4-6h）
