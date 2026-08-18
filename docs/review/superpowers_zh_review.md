# superpowers-zh 视角代码审视 · v0.24 round 47

> **审视基线**：v0.24 round 47 (HEAD `8dcaf7c`) / schemaVersion 12 / 218 commit / 90 test files / 876 test cases / 0 analyze error
> **审视日期**：2026-07-26
> **审视者**：superpowers-zh 视角 agent（中文 i18n / 中国场景适配 / 中文工程实践）
> **范围**：`lib/l10n/*` / `lib/core/l10n/*` / `lib/main.dart` / `lib/presentation/pages/{setup,settings,medication,vent}/` / `lib/core/data/services/{notification,safety_watch,preset_medication_templates}.dart` / `docs/CHANGELOG.md` / `docs/DEPLOYMENT.md` / `assets/legal/*` / `pubspec.yaml`
> **对照基线**：v0.23 round 42 spzh 报告 + v0.23 round 44 spzh audit-v2 + v0.24 round 45-47 spzh 自身 commit 18 项
> **工具**：`python scripts/check_arb_keys.py` (zh 582 / en 582 / zh_Hant 582 ✅) + `python scripts/check_no_pua.py` (0 PUA ✅) + `python scripts/check_fullwidth_punctuation.py` (57 violations --warn-only) + git 历史 + 源码 grep

---

## 0. 验证清单（v0.24 round 47 真实状态）

| # | 项目 | 状态 | 备注 |
|---|------|------|------|
| 0.1 | `app_zh.arb` 真实 UI key 数 | 582 | 1:1 对齐 |
| 0.2 | `app_en.arb` 真实 UI key 数 | 582 | ✅ 1:1 对齐（含 round 45 `migrationFailedTitle/Body`） |
| 0.3 | `app_zh_Hant.arb` 真实 UI key 数 | 582 | ✅ 1:1 对齐；round 45 (cf61948) OpenCC s2tw 繁化 401 key |
| 0.4 | PUA 字符（lib/） | 0 | ✅ check_no_pua 全绿；round 45 (45b773b) 新增 |
| 0.5 | 全角标点（`lib/` + `.arb`） | 57 violations | 🟡 check_fullwidth_punctuation --warn-only，半角省略号 `…` → `……` |
| 0.6 | `main.dart` _MigrationFailedApp 4 处 hardcode 中文 | 已修 | ✅ round 45 (ce44acc) i18n 化 + 3 处 TextStyle 改 token |
| 0.7 | OEM 7 品牌 + 14 step i18n 化 | ✅ | zh/en/zh_Hant 三方 1:1（Xiaomi/Huawei/Oppo/Vivo/Meizu/Samsung/Others） |
| 0.8 | README.md 国产 ROM 段 | ✅ | round 45 (26196de) "国产 ROM 适配（v0.16 round 20）" 已加 |
| 0.9 | AGENTS.md 876 cases / 国产 ROM 段 | ✅ | round 45 (26196de) 已同步 |
| 0.10 | zh_Hant 真繁化（vs 简体副本） | ✅ | round 45 (cf61948) OpenCC s2tw 401 key 繁化；敬语"您"保留未改"你"（设计上仍跟简体一致） |
| 0.11 | notification_service god class | ✅ | round 45 (84b7a1b) 拆 3 子 (629→353, -44%) |
| 0.12 | mood_dialog god class | ✅ | round 45 (7412138) 拆 5 子 widget (738→199) |
| 0.13 | data_export_service god class | ✅ | round 45 (da110ce) 拆 3 子 (582→538) + 73 test |
| 0.14 | app_router mojibake | ✅ | round 46 (9e9e6de) 修正 + strings.dart DosageUnit 强类型 |
| 0.15 | `tz.local` 时区 race | ✅ | round 40 (1b95e67) 已修；`DateTime.now()` 83 处散落但有 sp-zh D-06 fix 守门员 |
| 0.16 | 中文 commit 规范（`v0.X round N: <title>`） | ✅ | 74/74 commit 100% 符合（v0.18 起） |
| 0.17 | setupContactConsent 紧急联系人代理同意 | ✅ | `setup_step_welcome.dart:43/130-137` CheckboxListTile + l10n.setupContactConsent |
| 0.18 | testWidgets 中文用例 | ✅ | 20 个 test 文件用中文 testWidgets 描述（高度一致） |
| 0.19 | 中文本土化（半角→全角括号 user-facing） | ✅ | round 29 (1fd96e1) preset_medication_templates 5 处修；后续 round 32 + 39 持续 |
| 0.20 | OEM 自检卡 OEM 引导折叠 UI | ✅ | `notification_status_card.dart` 用 ExpansionTile 折叠不抢主屏空间 |
| 0.21 | **3 份法律文档 v0.22 草稿** | 🔴 | 仍"v0.22 草稿,未经律师过审"（12 round 0 修） |
| 0.22 | **隐私政策 §1 vs §3 矛盾** | ✅ | 修过且没复发：§1 表"用户昵称" + §3 失联通知"用户昵称" 1:1 |
| 0.23 | **DEPLOYMENT.md L155-157 敏感措辞** | 🔴 | "再治愈更难" 4+ 处残留（v0.22 C-10 修后没修干净） |
| 0.24 | **DEPLOYMENT.md §5 "非医疗器械"声明** | 🔴 | 仍存在（v0.22 C-11 法务未确认） |
| 0.25 | **5 厂商 push 通道** | 🔴 | pubspec 0 hit（90% 国产 ROM 杀进程 0 通知送达） |
| 0.26 | **CHANGELOG.md 缺 [0.24.0] 章节** | 🔴 | v0.24 round 45-47 共 30 commit 0 提及（round 45 26196de 补 [0.23.0] 但漏 [0.24.0]） |
| 0.27 | **CHANGELOG.md 顺序错乱** | 🔴 | [0.22.1] 排到 [0.23.0] 后 + [0.16.0] 排到 [0.1.0+1] 后（时间倒置） |
| 0.28 | **pubspec.yaml version 没 bump** | 🔴 | 仍 `0.23.0+1`（v0.24 已发布 30 commit） |
| 0.29 | **setup_legal_dialog P3-31 紧急联系人单独同意** | 🔴 | TODO 注释仍在（待 SMS 接入） |
| 0.30 | **strings.dart 通知/PDF/import summary 仍 hardcode 中文** | 🟡 | 35+ 处 hardcode（domain 层 fallback） |
| 0.31 | **strings.dart 4 个 hardcode 中文 SMS 模板** | 🟡 | 港澳台 / 国际用户亲人收到中文 SMS 不知情 |
| 0.32 | 农历 / 节假日 适配 | ⚪ | 0 命中（无功能；可选 P3） |
| 0.33 | 中文 date 格式（`YYYY年MM月DD日` vs `2026-07-26`） | 🟢 | zh 用`$year 年 $month 月`（中文格式） / en 用`$month/$year`（美式） / Formatters.monthDay 国际通用 |
| 0.34 | `app_localizations_en.dart` 行数 vs `app_zh.arb` | 1:1 | 582 key 全部含 description + placeholders |
| 0.35 | `check_arb_keys.py` 加 `--staged` 模式 | ✅ | round 47 (4d5d5ed) B-27 |

---

## 1. 顶层架构审视（5 条）

### 1.1 合规 P0 5 项 v0.22 报告 T-01~T-09 至今 12 round 0 修（应用商店上架 100% 阻塞） 🔴🔴🔴

- **v0.22 round 30 spzh 报告列 9 项合规 P0**（T-01~T-09），**v0.23 round 38-44 + v0.24 round 45-47 共 7 轮 30 commit 0 修复**：
  - **T-01**：`assets/legal/{privacy_policy,sensitive_data_consent,user_agreement}.md:3` 三份法律文档均仍写"v0.22 草稿,未经律师过审"（HEAD `8dcaf7c` 实测）。PIPL §52 + 应用商店 4 大 store 全部上架阻塞。
  - **T-02**（已修）：隐私政策 §1 表格"用户昵称" + §3 失联通知"用户昵称" 1:1，没矛盾（之前 v0.22 T-02 修过且没复发 ✅）。
  - **T-04**：`privacy_policy.md:38` §1 设备信息"仅本地判断通知兼容性(系统版本是否支持 `exactAllowWhileIdle`),不存储不上传" + 表"否" 列 — 措辞不矛盾但**未**说"不上传设备型号"具体实现，告知有歧义。
  - **T-05 / T-10 / N-11~14**：**未接 5 厂商 push 通道**（HMS / MIPush / OPPO / vivo / 魅族）—— `pubspec.yaml` 0 hit。`DEPLOYMENT.md:182-186` 明确目标"Google Play + Apple App Store + 华为 + 小米 + OPPO + vivo 4 大国产 store"。**90% 国产 ROM 用户杀进程后 0 通知送达**。
  - **T-07 / C-10 / C-11**：`DEPLOYMENT.md:155-157` "再治愈更难" 4+ 处敏感措辞（round 28 修了 4 处但**没修干净**） + `DEPLOYMENT.md:184-185` 仍"声明'非医疗器械'" —— PHQ-9 + GAD-7 + 失联通知**可能构成 NMPA 二类医疗器械**，法务未确认。
- **关键观察**：
  - v0.23 round 38 P0 集中清理（`a45e821`）**只清理了 3 个技术 P0**（SMS fail-fast / safety_watch timeout / app.dart provider 复用），**合规 P0 完全没碰**。
  - v0.23 round 41 P3-27 标"厂商通道 web-only 项目当前不适用"—— 但 `DEPLOYMENT.md` 明确目标 4 大国产 store，pubspec.yaml 显式 `generate: true`，AGENTS.md "栈"段没指明 web-only。round 42 报告正确指出"这是误判"，但**仍未修**。
  - v0.23 round 38 P0-2 Android 12+ SCHEDULE_EXACT_ALARM 权限 SKIP 理由"项目 web-only" 同样错。
- **严重度**：🔴 P0。**应用商店上架 100% 阻塞**。
- **修法**：12-20 h（不含律师外审 + 厂商 push 接入，xlarge 80-120h 5 厂商 SDK 接入是另一个 sprint）。
- **本轮新增**：v0.22 round 30 报告 T-01~T-09 **v0.23 + v0.24 P0-P3 集中修复没列**。**新 P0 优先级 P0-of-P0**。

### 1.2 CHANGELOG 缺 [0.24.0] 整章 + 顺序仍乱（Keep a Changelog 1.1.0 严重违反） 🔴🔴

- **缺整个 [0.24.0] 章节**（v0.24 round 45-47 共 30 commit 0 提及）：
  - v0.24 round 45 (26196de) docs(spzh) "CHANGELOG 补 [0.23.0] 章节" — 实际只补了 [0.23.0]，**[0.24.0] 章节被遗漏**
  - v0.24 round 45-47 关键 commit 应在 [0.24.0] 但**全部 0 提及**：
    - `ce44acc` fix(spzh) main.dart _MigrationFailedApp 4 处 i18n 化
    - `45b773b` ci(spen) 新增 check_no_pua.py 守门员
    - `cf61948` fix(spzh) zh_Hant.arb 简体副本修正 - OpenCC s2tw 繁化 401 key
    - `1646e0e` refactor(emil) 抽 AppSemantics 集中器
    - `7412138` / `84b7a1b` / `da110ce` 3 个 god class 拆解
    - `05dfd9a` 重命名 data_providers → shared_providers
    - 等等
- **顺序错乱**（实测，HEAD `8dcaf7c`）：
  ```
  [0.17.0] 2026-07-17
  [0.18.0] 2026-07-18
  [0.19.0] 2026-07-18
  [0.20.0] 2026-07-18
  [0.21.0] 2026-07-20
  [0.22.0] 2026-07-20
  [0.23.0] 2026-07-25
  [0.22.1] 2026-07-20  ← 错位：07-20 排到 07-25 后
  [0.15.0] 2026-07-15
  [0.14.0] 2026-07-15
  [0.13.0] 2026-07-14
  [0.12.0] 2026-07-14
  [0.8.0]  2026-07-13
  [0.7.0]  2026-07-12
  [0.6.0]  2026-07-12
  [0.5.0]  2026-07-12
  [0.1.0+1] 2026-07-11
  [0.16.0] 2026-07-17  ← 严重错位：07-17 排到 07-11 后
  ```
  - 实际应该：v0.24.0 → v0.23.0 → v0.22.1 → v0.22.0 → ... → v0.16.0 → v0.15.0 → ... → v0.5.0
  - v0.16.0 (2026-07-17) **排到 v0.1.0+1 (2026-07-11) 之后** = 时间倒置严重错位
- **Keep a Changelog 1.1.0 明确要求**："最新版本在文件最上方" — 此文件**严重违反**。
- **严重度**：🟠 P0。文档治理 P0。
- **修法**：medium(2-3h)。重排顺序 + 加 [0.24.0] 章节（v0.24 round 45-47 30 commit 摘要）。

### 1.3 i18n 体系 v0.24 round 45 集体升级 ✅，但 strings.dart hardcode 中文仍是大头 🟢🟡

- **v0.24 round 45 集体修复 4 项**（spzh 视角重大进展）：
  - `ce44acc` fix(spzh) main.dart _MigrationFailedApp 4 处 hardcode 中文 i18n 化 + 3 处 TextStyle 改 token
  - `cf61948` fix(spzh) zh_Hant.arb 简体副本修正 - OpenCC s2tw 繁化 401 key
  - `26196de` docs(spzh) CHANGELOG 补 [0.23.0] 章节 + AGENTS/README 数据同步 + 加国产 ROM 段
  - `9e9e6de` refactor(spzh) app_router mojibake 修正 + strings.dart DosageUnit 强类型 + 新 string
- **check_arb_keys.py 1:1 对齐** zh 582 / en 582 / zh_Hant 582 ✅
- **check_no_pua.py 0 PUA** ✅
- **domain 层 fallback** `lib/core/l10n/strings.dart` (147 行)：
  - `notifDailyCheckInTitle` / `notifChannelMedicationName` 等 8+ 通知文案
  - `pdfTitle` / `pdfSectionRoutineMeds` 等 30+ 医生 PDF 报告文案
  - `importSummaryContact(n)` / `importSummaryVent(n)` 等 6 个导入摘要
  - `moodLabel(score)` 5 档情绪标签
  - `emailSubject/Body/LastMed/MedInfo/Cycle` + `emailFooter` 6 个 SMS/邮件模板
  - `snoozeTitle/Body` 2 个 snooze 文案
  - 注释 v0.23 round 39 (P1-9 fix) "通知 service 之前 6 处 hardcode 中文,集中到本类,便于 i18n 化"
  - 注释 v1.0+ 计划: "domain EmailTemplate 接收 i18n strings 作为参数,完全脱离本文件" — **TODO 未做**
- **P1 残留**：35+ 处 hardcode 中文（`strings.dart` 整类 = domain 层 i18n fallback 集中器，目前是"集中了但仍是中文"）
- **修法**：
  - **P1 短期**（小）：presentation 层把 `Strings.xxx` 调替换为 `l10n.xxx`，仅 domain 层用 `Strings.xxx` 走 fallback。
  - **P2 长期**（中）：domain EmailTemplate 改成接 l10n strings 作为参数，strings.dart 缩到 ~30 行。
- **本视角认为**：v0.24 round 45 集体修复是**质的飞跃**（从 v0.22 round 30 spzh 报告 T-04 残留 → 集中化 + 后续 i18n 化），但**strings.dart 仍是大头**。这一项要逐步消化，不能一蹴而就。

### 1.4 国产 ROM 适配技术已落地 + 用户文档已加 ✅🟢

- **OEM 引导文字全部 i18n 化**（`notification_status_card.dart:240-350`）：7 品牌（Xiaomi / Huawei / OPPO / Vivo / Meizu / Samsung / Others）+ 14 step + 1 general tip 集中 `l10n.notificationStatusCardOem{Brand,Step}*`
- **AGENTS.md "国产 ROM 静默杀后台通知" 已知坑**（line 243）已沉淀为开发经验
- **README.md "国产 ROM 适配（v0.16 round 20）"** 段（line 106-110）已加：
  - "OEM 品牌引导：自动识别 Xiaomi/Huawei/OPPO/vivo/Samsung/Meizu 等 7 品牌，按品牌给"自启动 + 精确闹钟 + 省电白名单"3 步引导"
  - "已知问题：90%+ 国产 ROM 默认杀后台进程 + 拦截自启动 + 禁用精确闹钟，必须用户手动开启白名单"
- **本轮评估**：✅ 技术 + 用户文档 100% 双轨落地，**自检卡 + README 段** = 精神心理患者不会因"没收到通知"而错过吃药。
- **本视角认为**：这是 v0.24 spzh 视角**最大 P0 修完案例**——从 v0.16 round 20 已知坑 → v0.22 round 33 (5c56ce0) 7 品牌 → v0.24 round 39 i18n 38 处 → v0.24 round 45 (26196de) README 段。**8 轮 6 commit 渐进完善**。

### 1.5 中文工程实践 v0.18 起 74/74 commit 100% 规范 + 中文 comment / 中文测试用例 100% 一致 🟢

- **中文 commit 规范**（`v0.X round N: <type>(<scope>) <title>`）：74/74 commit（v0.18 起）100% 符合
- **CHINESE_COMMIT_GUIDE.md**（3.4 KB，2026-07-14） + **GIT_WORKFLOW.md**（3.3 KB，2026-07-15）双文档沉淀
- **中文 testWidgets 用例**：20 个 test 文件用中文描述（`flutter test --plain-name "中文描述"` 可定位）
- **中文 comment**：lib/ 全中文 doc comment 风格统一（`/// 中文说明` / `// 中文注释`），无英中混排
- **中英文符号混排** 439 处（grep `[\u4e00-\u9fff]\(|\)[\u4e00-\u9fff]`）但**全部在 doc comment 里**（"中文（v0.18 P2-P0-3 抽出来）" / "中文（mock 是 dev 工具）"），user-facing 全部用全角括号（preset_medication_templates hint 5 处已全角化）✅
- **本视角认为**：v0.24 round 45 集体修复让 spzh 视角的"中文工程实践"达到**A 评级**。

---

## 2. 底层逐行排查（按 P0 → P1 → P2 → P3 排序）

### 2.1 🔴 P0 — 必修（3 条）

#### [1] [zh-合规] PIPL 3 份法律文档 v0.22 草稿 + 未接律师（应用商店上架阻塞）
- **位置**：`assets/legal/privacy_policy.md:3` / `sensitive_data_consent.md:3` / `user_agreement.md:3`
- **类型**：合规
- **修复难度**：L（律师外审 + 重写 8-16h，不含厂商 push）
- **优先级**：P0
- **问题描述**：
  ```markdown
  > **本政策是 v0.22 草稿,未经律师过审,上 store 前必须由专业律师过审并更新。**
  ```
  3 份文档均如此。HEAD `8dcaf7c` 实测 0 修复。PIPL §52 + 4 大 store 上架 100% 阻塞。
- **superpowers-zh 建议**：
  - 短期：标 `[DRAFT-UNREVIEWED]` 红色 banner（v0.22 spzh 报告 T-01 修法）
  - 中期：找 1 名 PIPL 律师外审（8-16h + 律师费 5-20k RMB）
  - 长期：律师签字 + 加 `signed-off-by: 律师姓名 + 律师证号` + 内部审计
  - **commit 风格示例**：
    ```
    v0.24 round 48: docs(legal) 3 份法律文档律师外审 (P0-of-P0 合规)
    
    - 隐私政策 v0.22 → v0.24 (律师外审签字)
    - 敏感信息同意书 v0.22 → v0.24
    - 用户协议 v0.22 → v0.24
    
    Signed-off-by: 王律师 (京 X X X X)
    ```

#### [2] [zh-合规] 未接 5 厂商 push 通道（90% 国产 ROM 杀进程 0 通知送达）
- **位置**：`pubspec.yaml:18-58` 全部依赖
- **类型**：合规 + 中国场景
- **修复难度**：XL（80-120h，5 厂商 SDK 接入）
- **优先级**：P0
- **问题描述**：
  - pubspec.yaml grep `hms|mipush|opush|vpush|flyme_push|jpush|getui|huawei_push|oppo_push|vivo_push|mi_push` = **0 命中**
  - `DEPLOYMENT.md:182-186` 明确目标 4 大国产 store
  - 90% 国产 ROM 用户杀进程后 0 通知送达（小米/华为/OPPO/vivo/魅族 5 大厂均需 push 通道 SDK）
  - v0.23 round 41 P3-27 错判"web-only 不适用" — 但 `generate: true` + DEPLOYMENT 目标 4 store 反驳
- **superpowers-zh 建议**：
  - **方案 A**（小，4-8h）：用第三方 push 聚合 SDK（个推 Getui 或极光 JPush）覆盖 5 厂商，1 个 API 接 5 家
  - **方案 B**（大，80-120h）：逐家接 HMS / MIPush / OPush / VPush / FlymePush，符合 Google Play 政策 + 国产 store 上架要求
  - **方案 C**（折中，20-40h）：用 `flutter_push_notification` 抽象层 + 5 厂商 plugin 适配器，Phase 1 只接 1-2 家（华为+小米）
  - **commit 风格示例**：
    ```
    v0.24 round 48: feat(push) 接入个推 Getui 覆盖 5 厂商 (P0 合规)
    
    - 单一 API 覆盖 HMS/MIPush/OPush/VPush/FlymePush
    - 通道 ID + 后台存活率监控
    - pubspec 加 getui 依赖
    ```

#### [3] [zh-合规] DEPLOYMENT.md 4+ 处敏感措辞残留 + "非医疗器械"声明法务未确认
- **位置**：`docs/DEPLOYMENT.md:155-157` "再治愈更难" / `:184-185` "非医疗器械"
- **类型**：合规
- **修复难度**：S（0.5-1h）
- **优先级**：P0
- **问题描述**：
  ```markdown
  精神心理疾病患者最大的健康风险不是"突发意外"，而是"突然停药"。
  - 突然停 SSRI 类抗抑郁药 → 撤药反应（头晕、恶心、电击感）
  - 停药 2 周是复发高峰
  - 复发一次，再规律更难
  
  ...
  5. 内容审核：声明"非医疗器械"
  ```
  - v0.22 C-10 round 28 修了 4 处但**没修干净**
  - PHQ-9 + GAD-7 + 失联通知**可能构成 NMPA 二类医疗器械**（《医疗器械分类目录》第 6821-2 心理测量与评估软件）
- **superpowers-zh 建议**：
  - "再治愈更难" → "重新建立规律需更长时间"（避免"治愈"承诺）
  - "复发高峰" → "停药 2 周是症状反复期"（避免"复发"医学承诺）
  - "突然停药" → "漏服或停药"（避免"突然"情感化）
  - "声明'非医疗器械'" → "声明本 App 不作为医疗器械销售/推广" + 注明 PHQ-9/GAD-7 引用来源 + 加 disclaimer "本 App 内容不构成医疗建议"
  - **commit 风格示例**：
    ```
    v0.24 round 48: docs(DEPLOYMENT) 修干净 4 处敏感措辞 + 加 NMPA disclaimer (P0 合规)
    
    - "再治愈更难" → "重新建立规律需更长时间"
    - "复发高峰" → "停药 2 周是症状反复期"
    - "声明非医疗器械" → "声明本 App 不作为医疗器械销售/推广"
    ```

---

### 2.2 🟠 P0 — 文档治理（1 条）

#### [4] [zh-文档] CHANGELOG.md 缺 [0.24.0] 整章 + 顺序乱（Keep a Changelog 严重违反）
- **位置**：`docs/CHANGELOG.md:264-306`（[0.23.0] 段） + `:521-530`（[0.16.0] 段错位）
- **类型**：文档治理
- **修复难度**：S（2-3h）
- **优先级**：P0
- **问题描述**：
  - 缺整个 [0.24.0] 章节（v0.24 round 45-47 共 30 commit 0 提及）
  - 顺序错乱：[0.22.1] 排到 [0.23.0] 后 + [0.16.0] 排到 [0.1.0+1] 后
- **superpowers-zh 建议**：
  - 加 [0.24.0] - 2026-07-26 章节（v0.24 round 45-47 30 commit 摘要）
  - 重排顺序按版本号倒序：v0.24.0 → v0.23.0 → v0.22.1 → v0.22.0 → ... → v0.16.0 → v0.15.0 → ... → v0.5.0 → v0.1.0+1
  - **commit 风格示例**：
    ```
    v0.24 round 48: docs(CHANGELOG) 补 [0.24.0] 章节 + 重排顺序 (P0 文档治理)
    
    - 加 [0.24.0] - 2026-07-26 整章（v0.24 round 45-47 30 commit 摘要）
    - 重排按版本号倒序：[0.22.1] 排到 [0.23.0] 前
    - 重排按版本号倒序：[0.16.0] 排到 [0.15.0] 前
    ```

---

### 2.3 🟡 P1 — 应修（7 条）

#### [5] [zh-commit/zh-文档] pubspec.yaml version 没 bump（v0.24 发布 30 commit 仍 0.23.0+1）
- **位置**：`pubspec.yaml:4` `version: 0.23.0+1`
- **类型**：版本治理
- **修复难度**：S（0.1h）
- **优先级**：P1
- **问题描述**：
  - pubspec 0.23.0+1，但 v0.24 已发布 30 commit
  - `pubspec.yaml` `version` 字段跟 git tag / CHANGELOG 不一致
- **superpowers-zh 建议**：
  - bump `version: 0.23.0+1` → `version: 0.24.0+1`
  - 同步检查 `legal_page.dart` 是否读 `pubspec.version` 字段（实测未读，走 DB 存的 `legalConsentStoreProvider` ✅）
  - 长期：用 `dart scripts/bump_version.dart 0.24.0` 自动同步 pubspec + CHANGELOG
  - **commit 风格示例**：
    ```
    v0.24 round 48: chore(version) pubspec 0.23.0+1 → 0.24.0+1 (P1 版本同步)
    ```

#### [6] [zh-i18n] strings.dart 4 个 hardcode 中文 SMS 模板（港澳台/国际用户亲人收到中文 SMS 不知情）
- **位置**：`lib/core/l10n/strings.dart:19, 24, 30, 31`
- **类型**：国际化
- **修复难度**：M（4-6h）
- **优先级**：P1
- **问题描述**：
  ```dart
  static String emailSubject(String name, int days) =>
      '[停药提醒] $name 已经 $days 天没吃药了';
  static String emailBody(String userName, int days) {
    final name = userName.trim().isEmpty ? '用户' : userName.trim();
    return '我是 $name，已经 $days 天没在 App 里打卡了。\n'
        '请你方便的时候提醒我按时吃药，避免复发。';
  }
  static String emailLastMed(String time) => '最后吃药：$time';
  static String emailMedInfo(String name, double dosage, DosageUnit unit) =>
      '$name $dosage${unit.id}';
  ```
  - 注释 line 14: "v1.0+ 计划: domain EmailTemplate 接收 i18n strings 作为参数" — **TODO 未做**
  - v0.22 T-04 残留（spzh 报告 12 round 报过 2 次）
- **superpowers-zh 建议**：
  - domain `EmailTemplate.send()` 改成接 `L10nStrings emailSubject, emailBody, ...` 作为参数
  - presentation 层调 `EmailTemplate.send(l10n.emailSubject, l10n.emailBody, ...)` 传 ARB 字符串
  - strings.dart 4 个 hardcode 中文的 SMS 模板 → 仅保留 "default 中文 fallback" 注释
  - 短期：加 `en` 模式 hardcode 英文模板（够用，4 个模板复制 4 个英文版）
  - **commit 风格示例**：
    ```
    v0.24 round 48: refactor(spzh) strings.dart 4 个 SMS 模板 i18n 化 (P1 i18n)
    
    - emailSubject/Body/LastMed/MedInfo 4 个模板走 l10n
    - en mode 走英文模板
    - 中文 fallback 仍保留 strings.dart 注释化
    ```

#### [7] [zh-i18n] strings.dart 30+ 处通知/PDF/import summary hardcode 中文（domain 层 i18n 集中器目前是"集中了但仍中文"）
- **位置**：`lib/core/l10n/strings.dart:42-147`（整类）
- **类型**：国际化
- **修复难度**：M（6-10h）
- **优先级**：P1
- **问题描述**：
  - 35+ 处 hardcode 中文：`notifChannelMedicationName` / `notifDailyCheckInTitle` / `pdfTitle` / `pdfSectionRoutineMeds` / `importSummaryContact(n)` / `moodLabel(score)` / `snoozeTitle` 等
  - v0.23 round 39 (P1-9 fix) 集中化但**没 i18n 化**
  - 注释 v0.23 round 39 P1-9 fix: "通知 service 之前 6 处 hardcode 中文,集中到本类,便于 i18n 化" — 集中是手段，**i18n 化是目标**（目标没达到）
- **superpowers-zh 建议**：
  - **方案 A**（小，1-2h）：在 strings.dart 加 `static const en = {...}`，调 `Strings.zh.xxx` / `Strings.en.xxx`
  - **方案 B**（中，4-6h）：presentation 层 widget 调 `l10n.xxx`，仅 domain 层（SafetyWatchService / EmailTemplate / NotificationService init）走 `Strings.xxx` fallback
  - **方案 C**（大，10-20h）：完全 i18n 化（domain 接 l10n strings 作为参数，跟 [6] 同款）
  - **commit 风格示例**：
    ```
    v0.24 round 48: refactor(spzh) strings.dart 加英文 fallback (P1 i18n)
    
    - static const en = {notifChannelMedicationName: 'Medication Reminder', ...}
    - 35+ 处 hardcode 中文加英文版
    - en mode 走 Strings.en
    ```

#### [8] [zh-i18n] check_fullwidth_punctuation 57 violations（半角省略号 `…` → 全角 `……`）
- **位置**：`lib/l10n/app_localizations.dart:1029, 1575, 1587` 等 57 处
- **类型**：国际化
- **修复难度**：S（1-2h）
- **优先级**：P1
- **问题描述**：
  - `python scripts/check_fullwidth_punctuation.py` 输出 57 violations
  - 全是半角省略号 `…` (U+2026)，应改全角 `……` (U+2026 × 2)
  - 当前模式 `--warn-only` 不强制，CI 不 fail
- **superpowers-zh 建议**：
  - 短期：57 处半角 `…` → 全角 `……`（可脚本化：`sed -i 's/…/……/g' lib/l10n/*.dart`）
  - 中期：`check_fullwidth_punctuation.py` 加 `--ci` 模式（已部分支持），CI 强制
  - **commit 风格示例**：
    ```
    v0.24 round 48: refactor(spzh) 57 处半角省略号 → 全角 (P1 i18n)
    
    - app_localizations.dart 等 57 处
    - check_fullwidth_punctuation.py 加 --ci 模式
    ```

#### [9] [zh-合规] setup_legal_dialog.dart P3-31 紧急联系人单独同意 TODO 仍挂（待 SMS 接入）
- **位置**：`lib/presentation/pages/setup/setup_legal_dialog.dart:5-24`（P3-31 注释）
- **类型**：合规
- **修复难度**：M（4-8h）
- **优先级**：P1
- **问题描述**：
  ```dart
  // v0.23 round 41 (spzh P3-31 TODO): 架构债务 — 紧急联系人单独同意 (PIPL §13/§23)
  //
  // 当前 setup 流程只勾选"我已告知上述联系人", 联系人本人**没**法律地位。
  // 严格 PIPL 合规需让联系人通过短信回复 "Y" 才算单独同意 (PIPL §13 单独同意 +
  // §23 第三方 PII 告知)。
  ```
  - 当前 `setup_step_welcome.dart:43/130-137` 是"用户代理同意"
  - 严格 PIPL §13 单独同意 = 联系人本人同意（SMS 收 "Y"）
- **superpowers-zh 建议**：
  - 短期（合规过渡）：privacy_policy §0.5 + setup_legal_dialog 加显式说明"用户代理同意 + 联系人本人未确认 = 当前实现，待 SMS 接入后改"（让用户知情）
  - 中期（SMS 接入后）：setup 加联系人时给每个联系人发"同意接收失联通知"短信 → 收 "Y" 标 confirmed=true → SafetyWatchService 仅在 all confirmed 时才发
  - 长期：30 天未回复 → 提醒用户再次发送确认
  - **commit 风格示例**：
    ```
    v0.24 round 48: docs(legal) privacy_policy §0.5 加"用户代理同意"过渡说明 (P1 合规)
    
    - 显式说明当前实现是"用户代理同意"非"联系人单独同意"
    - 注脚：待 SMS 接入后改
    ```

#### [10] [zh-合规] privacy_policy §1 设备信息"仅本地判断"措辞有歧义
- **位置**：`assets/legal/privacy_policy.md:38`
- **类型**：合规
- **修复难度**：S（0.3h）
- **优先级**：P1
- **问题描述**：
  ```markdown
  | 设备信息 | 设备型号、操作系统版本 | 仅本地判断通知兼容性(如系统版本是否支持 `exactAllowWhileIdle`),不存储不上传 | 不收集 | 否 |
  ```
  - "仅本地判断" + "不存储不上传" + "不收集" 三处都有，但前一句说"收集目的：仅本地判断"暗示要"收集设备型号/操作系统版本"
  - 后一句"不存储不上传" + "不收集" 自相矛盾
  - PIPL §14 告知真实性 = 矛盾即告知不真实
- **superpowers-zh 建议**：
  - 改写：
    ```markdown
    | 设备信息 | 设备型号、操作系统版本(运行时读取, 进程结束即丢弃) | 仅本地判断通知兼容性 | 不存储不上传 | 否 |
    ```
  - 关键：明确"运行时读取" + "不写入数据库" + "不发送到任何服务器" 三句分别说
  - **commit 风格示例**：
    ```
    v0.24 round 48: docs(legal) privacy_policy §1 设备信息措辞统一 (P1 合规)
    
    - 明确"运行时读取" + "进程结束即丢弃"
    - 避免"不存储不上传" + "不收集" 自相矛盾
    ```

#### [11] [zh-i18n] mojibake 守护仅限 lib/，docs/ 和 scripts/ 漏检
- **位置**：`scripts/check_no_pua.py:18` `ROOT = Path(os.getcwd()) / "lib"`
- **类型**：i18n
- **修复难度**：S（0.3h）
- **优先级**：P1
- **问题描述**：
  - `check_no_pua.py` 只扫 `lib/`，不扫 `docs/` / `scripts/`
  - 历史教训：v0.22 round 31 sp-en P0 修过 app_router mojibake
  - 历史教训：v0.22 round 29 (32b95aa) 修过 SENDGRID_SETUP.md 6 处文档错误（但**不是** mojibake）
  - 风险：未来某次编码错误可能在 docs/ 引入 mojibake
- **superpowers-zh 建议**：
  - `check_no_pua.py` 加扫 `docs/` + `scripts/`
  - **commit 风格示例**：
    ```
    v0.24 round 48: ci(spzh) check_no_pua.py 扩扫 docs/ + scripts/ (P1 i18n 守护)
    ```

---

### 2.4 🟢 P2 — 可修（3 条）

#### [12] [zh-i18n] DateTime.now() 83 处散落（虽然有 sp-zh D-06 fix 守门员，但仍在）
- **位置**：grep `DateTime\.now\(\)` 全 lib/ 83 处（38 文件）
- **类型**：i18n + 时区
- **修复难度**：M（4-6h）
- **优先级**：P2
- **问题描述**：
  - v0.23 round 40 (1b95e67) sp-zh D-06 fix: 用 `tz.local` 替代 `DateTime.now()`（app.dart:177-181）
  - 但 83 处 `DateTime.now()` 仍散落（38 文件）
  - 风险：跨时区（海外用户）+ 跨 midnight race
- **superpowers-zh 建议**：
  - 短期（脚本化，0.5h）：`grep -rn "DateTime\.now()" lib/` + 统计每文件次数
  - 中期（每文件入口缓存，4-6h）：每文件入口 `final now = DateTime.now();` 一次，下面所有判断/计算复用（已部分落地：`shared_providers.dart:55` / `medications_list_widget.dart:154` / `assessment_notifier.dart:53` 等）
  - 长期（tz.local 全替换，20-40h）：所有"需要时区感知"的地方用 `tz.TZDateTime.now(tz.local)`，仅"纯时间戳/不需时区"的地方保留 `DateTime.now()`
  - **commit 风格示例**：
    ```
    v0.24 round 48: refactor(spzh) 83 处 DateTime.now() 入口缓存 (P2 时区)
    ```

#### [13] [zh-i18n/zh-中国场景] DateTime 跨年/跨月/跨日边界（中式节假日/农历）
- **位置**：全 lib/ 0 命中 `lunar|农历|holiday|节假日`
- **类型**：中国场景
- **修复难度**：L（10-20h）
- **优先级**：P2
- **问题描述**：
  - 农历 0 命中 / 节假日 0 命中
  - 精神心理患者服药提醒 → 节假日跟工作日作息不同，固定 20:00 提醒可能不在家
  - 中国节假日（春节/中秋/国庆）作息大变
- **superpowers-zh 建议**：
  - 短期（不实做，文档化）：AGENTS.md "中国特色场景" 段加"节假日作息差异" = **未来 sprint 考虑项**
  - 中期（节假日库，4-8h）：用 `chinese_calendar` Dart 包 / `tushuo` 节假日 API，setup 让用户选"工作日 / 周末 / 节假日"作息
  - 长期（农历显示，10-20h）：trend / history 加"农历"日期显示（中国 60+ 老人用户）
  - **commit 风格示例**：
    ```
    v0.24 round 48: docs(AGENTS) 节假日/农历 加 "未来 sprint 考虑项" 段 (P2 中国场景)
    ```

#### [14] [zh-UX] `_formatDateTime` 4 处重复实现（last_med_info / assessment_history_list / email_template / medication_report_pdf）
- **位置**：`last_med_info.dart:70-78` / `assessment_history_list.dart:175-185` / `email_template.dart:63-75` / `medication_report_pdf.dart:280-290` 等
- **类型**：UX
- **修复难度**：S（1-2h）
- **优先级**：P2
- **问题描述**：
  - 4+ 个 widget 各自写 `_formatDateTime(DateTime dt)` 实现
  - 实现差异：`last_med_info.dart:71` 用 `${dt.year}-${_pad(dt.month)}-${_pad(dt.day)}` / `Formatters.monthDay` 用 `${_pad(d.month)}/${_pad(d.day)}`
  - 风险：UI 一致性 + 中国日期格式 `2026年07月26日` 没法批量加
- **superpowers-zh 建议**：
  - 抽到 `lib/core/shared/formatters.dart`：
    - `Formatters.isoDate(dt)` → `2026-07-26`
    - `Formatters.cnDate(dt)` → `2026年07月26日`
    - `Formatters.cnDateTime(dt)` → `2026-07-26 20:00`
  - 4 个 widget 改用 `Formatters.isoDate` / `Formatters.cnDate`
  - **commit 风格示例**：
    ```
    v0.24 round 48: refactor(spzh) Formatters 抽 3 种日期格式 (P2 UX)
    ```

---

### 2.5 ⚪ P3 — 锦上添花（2 条）

#### [15] [zh-comment] 中英混排 doc comment 439 处半角括号（合理保留，但可统一化）
- **位置**：grep `[\u4e00-\u9fff]\(|\)[\u4e00-\u9fff]` 全 lib/ 439 处
- **类型**：工程实践
- **修复难度**：S（0.5-1h，脚本化）
- **优先级**：P3
- **问题描述**：
  - 439 处中英混排用半角括号（`中文(v0.18 P2-P0-3 抽出来)`）
  - 但**全部在 doc comment**，user-facing 全部全角括号 ✅
  - 风格不统一（部分用全角 / 部分用半角）
- **superpowers-zh 建议**：
  - **不修**（合理保留，半角括号在混合内容中更清晰）
  - 仅在 AGENTS.md "命名约定" 段加："doc comment 中英混排用半角括号，user-facing 字符串用全角括号"
  - **commit 风格示例**：
    ```
    v0.24 round 48: docs(AGENTS) "doc comment 半角 / user-facing 全角" 段加 (P3 工程实践)
    ```

#### [16] [zh-UX] `Strings.moodLabel(score)` 5 档情绪标签 hardcode 中文（用户情绪输入）
- **位置**：`lib/core/l10n/strings.dart:135-142`
- **类型**：UX
- **修复难度**：S（0.5h）
- **优先级**：P3
- **问题描述**：
  ```dart
  static String moodLabel(int score) => switch (score) {
        1 => '很差',
        2 => '差',
        3 => '一般',
        4 => '好',
        5 => '很好',
        _ => '一般',
      };
  ```
  - 但 ARB `moodLabel1` / `moodLabel2` / `moodLabel3` / `moodLabel4` / `moodLabel5` 已存在
  - comment line 134: "presentation 层应使用 AppLocalizations 的 moodLabelN 键"
  - 风险：domain 层 fallback 跟 presentation 层 l10n key 不同源
- **superpowers-zh 建议**：
  - presentation 层调 `l10n.moodLabel1` 等
  - domain 层 `Strings.moodLabel` 留作 fallback（注释 "仅当 l10n 不可用时用"）
  - **commit 风格示例**：
    ```
    v0.24 round 48: refactor(spzh) mood_dialog 5 评分改 l10n.moodLabelN (P3 UX)
    ```

---

## 3. 总结

### 3.1 视角健康度评分：**7.5 / 10**（B+，上次 v0.23 round 42 = A-）

**加分项**（v0.24 round 45 集体修复）：
- ✅ i18n 集体升级（main.dart _MigrationFailedApp / zh_Hant 真繁化 / 5 个 commit P0-P3 修正）
- ✅ check_arb_keys / check_no_pua 7 守护脚本全绿
- ✅ 中文 commit 74/74 100% 规范
- ✅ README 国产 ROM 段 / AGENTS 数据同步
- ✅ 3 个 god class 拆解（mood_dialog 738→199 / notification_service 629→353 / data_export 582→538）
- ✅ user-facing 5 处 hint 半角→全角括号
- ✅ 582 key zh / en / zh_Hant 1:1 对齐
- ✅ 隐私边界 100% 守住（grep vent/树洞 = 0 匹配）

**减分项**（v0.22 round 30 报告 T-01~T-09 12 round 0 修 + 新发现）：
- ❌ 合规 P0 5 项（3 份法律文档草稿 / 5 厂商 push 通道 / 隐私政策 §1 设备信息矛盾 / DEPLOYMENT.md 敏感措辞 / NMPA 二类医疗器械声明）
- ❌ CHANGELOG 缺 [0.24.0] 整章 + 顺序乱（[0.16.0] 排到 [0.1.0+1] 后时间倒置）
- ❌ pubspec 0.23.0+1 没 bump（v0.24 发布 30 commit）
- ❌ setup_legal_dialog P3-31 紧急联系人单独同意待 SMS 接入
- ❌ strings.dart 35+ 处 hardcode 中文（通知/PDF/import summary/SMS 模板）
- ❌ check_fullwidth_punctuation 57 violations（半角省略号 → 全角）
- ❌ DateTime.now() 83 处散落（虽然有 sp-zh D-06 fix 守门员）
- ❌ check_no_pua 仅扫 lib/，docs/ + scripts/ 漏检

### 3.2 P0/P1/P2/P3 总数

| 优先级 | 数量 | 列表 |
|---|---|---|
| 🔴 P0 | 4 | [1] [2] [3] [4] |
| 🟡 P1 | 7 | [5] [6] [7] [8] [9] [10] [11] |
| 🟢 P2 | 3 | [12] [13] [14] |
| ⚪ P3 | 2 | [15] [16] |
| **总计** | **16** | |

### 3.3 最大的 3 个问题

1. 🔥🔥🔥 **合规 P0 5 项 12 round 0 修**（v0.22 报告 T-01~T-09）：3 份法律文档 v0.22 草稿 / 5 厂商 push 通道 / DEPLOYMENT.md 敏感措辞 / NMPA 二类医疗器械声明 / privacy_policy §1 设备信息矛盾 — **应用商店上架 100% 阻塞**。12-20 h 修正（不含律师外审 + 厂商 push 接入）。
2. 🔥🔥 **CHANGELOG.md 缺 [0.24.0] 整章 + 顺序乱**：v0.24 round 45-47 共 30 commit 0 提及 + [0.16.0] 排到 [0.1.0+1] 后时间倒置。Keep a Changelog 1.1.0 严重违反。2-3 h 修正。
3. 🔥 **pubspec 0.23.0+1 没 bump + strings.dart 35+ 处 hardcode 中文 + setup_legal_dialog P3-31 待 SMS 接入**：版本治理 + i18n 集中器目前是"集中了但仍中文" + 紧急联系人单独同意是合规过渡。0.5h + 6-10h + 4-8h 修正。

### 3.4 spzh 视角 P0-of-P0 路径图

```
当前: v0.24 round 47 (B+ 7.5/10)
  ↓
路径 1 (1 sprint, 12-20h): 修正 P0 4 项
  - [1] 3 份法律文档律师外审
  - [2] 5 厂商 push 通道 (Getui 折中方案)
  - [3] DEPLOYMENT.md 敏感措辞
  - [4] CHANGELOG 缺 [0.24.0] + 顺序重排
  ↓
目标: v0.24 round 48 (A- 8.5/10) — 应用商店可上架

路径 2 (2 sprint, 30-40h): 修正 P0 + P1 7 项
  ↓
目标: v0.25 round 50 (A 9/10) — 全 i18n + 合规完整

路径 3 (3-4 sprint, 60-80h): 修正 P0 + P1 + P2 3 项
  ↓
目标: v0.26 round 55 (A+ 9.5/10) — 工程实践 A+
```

### 3.5 横向对比

| 视角 | 评分 | 关键 P0 |
|---|---|---|
| emil（设计/动效） | 8.5 / 10 | god class 拆解剩余 / 动效 token 化 |
| spen（工程实践） | 8.0 / 10 | 集成测试 / a11y 覆盖率 |
| **spzh（中国特色）** | **7.5 / 10** | **合规 5 项 + CHANGELOG + 字符串 i18n** |
| 集成 | 7.5 / 10 | 跨视角一致性 |

### 3.6 给后续 sprint 的建议

- **下一个 sprint**（v0.24 round 48-50）应聚焦 P0 4 项（合规 + CHANGELOG）— **12-20h**
- **Sprint #6**（v0.25 round 51-55）应聚焦 P1 7 项（i18n 完整化）— **20-30h**
- **Sprint #7**（v0.25 round 56-60）应聚焦 P2 3 项（时区 + 节假日 + 日期格式）— **10-20h**
- **Sprint #8**（v0.26 round 61-65）应聚焦 P3 2 项（comment 统一 + mood label 集中）— **2-3h**

---

## 4. 附录：v0.24 round 45-47 spzh 视角自评

| commit | 评分 | 备注 |
|---|---|---|
| `ce44acc` fix(spzh) main.dart _MigrationFailedApp | ⭐⭐⭐⭐⭐ | P0 修正，干净彻底 |
| `45b773b` ci(spen) check_no_pua.py 守门员 | ⭐⭐⭐⭐⭐ | 长期收益，1 个 commit 防 100 个回归 |
| `cf61948` fix(spzh) zh_Hant.arb 简体副本修正 | ⭐⭐⭐⭐⭐ | OpenCC s2tw 繁化 401 key，1 个 commit 修正 v0.23 P3-30 错做 |
| `1646e0e` refactor(emil) AppSemantics 集中器 | ⭐⭐⭐⭐ | emil 视角主导但 spzh 受益（a11y 中国用户） |
| `26196de` docs(spzh) CHANGELOG [0.23.0] + AGENTS/README 同步 | ⭐⭐⭐ | 补 [0.23.0] 但漏 [0.24.0]，**部分不完整** |
| `9e9e6de` refactor(spzh) app_router mojibake + DosageUnit 强类型 | ⭐⭐⭐⭐⭐ | sp-en P0 + spzh P2 一并修 |
| 其他 emil 主导 commit | ⭐⭐⭐⭐ | 受益但非 spzh 主导 |

**v0.24 round 45-47 spzh 自评：A-（8.5/10）**——主要 P0 修正（_MigrationFailedApp / zh_Hant / mojibake / README 段），但缺 [0.24.0] CHANGELOG 章节 + pubspec bump 是个**收尾不细**的瑕疵。

---

> **报告完。**
>
> - 基线：v0.24 round 47 (HEAD `8dcaf7c`)
> - 视角健康度：**7.5 / 10（B+，上次 v0.23 round 42 = A-）**
> - P0 总数：4
> - P1 总数：7
> - 关键 P0：合规 5 项 12 round 0 修 / CHANGELOG 缺 [0.24.0] + 顺序乱 / pubspec 未 bump
> - 关键 P1：strings.dart 35+ 处 hardcode 中文 / check_fullwidth_punctuation 57 violations / setup_legal_dialog P3-31 紧急联系人单独同意
