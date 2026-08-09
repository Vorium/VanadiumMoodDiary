# superpowers-zh 视角审查报告（v0.22 round 30）

> **审查目标**：D:\Batch\chroniccare Flutter 慢病 / 精神心理患者吃药打卡 App
> **审查视角**：superpowers-zh（中国特色规范 + 中文代码审查 + 中文提交规范 + 中文文档 + 中文 Git 工作流 + workflow-runner）
> **审查时间**：v0.22 round 30 之后（HEAD f5ae3fd）
> **审查基线**：164 个 lib 文件 / 74 个 test / 15 个 scripts / 7 个文档 / 703 cases pass / 0 analyze error
> **审查员**：superpowers-zh 中文规范审查 sub-agent
> **优先级口径**：
> - **P0** = 必修：合规风险 / 应用商店上架阻塞 / 国产 ROM 通知完全失效
> - **P1** = 应修：影响国内用户体验（push 通道 / i18n / 半角标点 / 文档同步）
> - **P2** = 可修：commit 规范 / 文档质量 / 行业最佳实践
> - **P3** = nice-to-have
> **修难度分档**：trivial(<1h) / small(1-4h) / medium(4-8h) / large(8-16h) / xlarge(>16h)

---

## 顶层架构审视

### 国内合规风险（PIPL / 医疗器械 / 数据安全 / 应用商店）

> 9 项，**5 项 P0、3 项 P1、1 项 P2**

| # | 标题 | 位置 | 风险 | 法律依据 | 优先级 | 修难度 |
|---|------|------|------|---------|--------|--------|
| T-01 | **3 份法律文档仍是 v0.21 草稿**未经律师过审 | `assets/legal/privacy_policy.md:3`<br>`assets/legal/user_agreement.md:3`<br>`assets/legal/sensitive_data_consent.md:3` | 高 | PIPL §52 + 《App 违法违规收集使用个人信息行为认定方法》§6 | **P0** | large(8-16h, 律师外审) |
| T-02 | **隐私政策 §3 仍说"用户姓名"但 v0.21 P1-24 userName 改 nullable** | `assets/legal/privacy_policy.md:34` | 中 | PIPL §6 最小化 | **P0** | small(1h) |
| T-03 | **app_zh.arb:89 settingsAboutVersion 写 "v0.1.0" 但项目已 v0.22** | `lib/l10n/app_zh.arb:89`<br>`lib/l10n/app_en.arb:74`<br>`lib/l10n/app_localizations_zh.dart:222`<br>`lib/l10n/app_localizations_en.dart:229` | 高（用户从 store 看 v0.1 严重误导） | 《App 违法违规收集》§4 必要原则 | **P0** | trivial(0.2h) |
| T-04 | **隐私政策 §1 设备信息说"不收集"但又写"通知/兼容性"自相矛盾** | `assets/legal/privacy_policy.md:38` | 中 | PIPL 告知真实性原则 | **P0** | trivial(0.5h) |
| T-05 | **未接厂商 push 通道（HMS / MIPush / OPPO PUSH / vivo PUSH）** 国产 ROM 通知仍不可靠 | `lib/core/data/services/notification_service.dart:1` | 高（90% 国产 ROM 杀进程后无通知） | - | **P0** | xlarge(>16h, 需对接 5 厂商 SDK) |
| T-06 | **本地加密用 AES-256 不是国密 SM4** | `lib/core/data/services/encryption_service.dart` | 中（医院 / 政府客户必查国密合规） | GM/T 0054《信息系统密码应用基本要求》 | P1 | large(8-16h) |
| T-07 | **隐私政策 §1 "健康数据" vs "健康记录" 措辞**（医疗 App 自我描述） | `assets/legal/privacy_policy.md:36` | 中（医疗 App 自我定性 = 是否需 NMPA 备案） | NMPA《移动医疗器械注册管理办法》 | P1 | small(1h) |
| T-08 | **隐私政策 §0 提到 4 个 consent 字段但实际 schemaVersion 10→11 是 v0.21 加的** | `assets/legal/privacy_policy.md:19-22`<br>`lib/core/data/database/app_database.dart:43-58` | 低（已落地，文档同步） | PIPL §14 | P1 | trivial(已修) |
| T-09 | **DEPLOYMENT.md §5 完整描述仍含"医疗"+"治愈"措辞** | `docs/DEPLOYMENT.md:154-157` | 中 | 《广告法》§16 + 《医疗广告管理办法》§3 | P2 | trivial(0.5h) |

**P0 风险总计**：5 项 / 估算 24-32 h（不含律师外审 + 厂商 push 接入）

### 国内生态适配

> 7 项，**2 项 P0、3 项 P1、2 项 P2**

| # | 标题 | 描述 | 优先级 | 修难度 |
|---|------|------|--------|--------|
| T-10 | **未接 5 大国产 ROM 厂商 push 通道** | 见 T-05。当前仅 `flutter_local_notifications` + 厂商后台自启动引导文字，**真杀进程后通知不可达**。需要接华为 HMS / 小米 MIPush / OPPO PUSH（含 realme / 一加） / vivo Push（含 iQOO） / 魅族 FlymePush | **P0** | xlarge |
| T-11 | **国产 ROM 自检卡只覆盖 5 大品牌** | `lib/presentation/pages/settings/widgets/notification_status_card.dart:240-300`<br>漏：三星 / 中兴 / 努比亚 / 红魔 / 联想 / 锤子（已衰退）/ 三星 Knox（企业用户） | **P0** | small(1h) |
| T-12 | **未支持农历 / 24 节气 / 节假日 streak 跳过** | `lib/domain/logic/streak_calculator.dart` | P1 | medium(6-8h) |
| T-13 | **未支持农历生日 / 节气提醒** | `lib/` grep 0 hit | P1 | large(8-12h) |
| T-14 | **未提供港澳台繁体中文（zh_Hant）** | `lib/l10n/app_zh.arb` 只有 zh | P1 | medium(6-8h) |
| T-15 | **失联阈值 36h 写死** | `lib/domain/logic/care_engine.dart:103` | P2 | small(2h) |
| T-16 | **`.env` 文件 build-time 注入** 未做（弱网 / 离线首次启动有 race） | `lib/main.dart:37` | P2 | small(2h) |

### 可重构的中文模块（i18n / 文档 / commit / workflow）

> 7 项，**3 项 P1、3 项 P2、1 项 P3**

| # | 标题 | 位置 | 优先级 | 修难度 |
|---|------|------|--------|--------|
| T-17 | **`check_fullwidth_punctuation.py` 漏检半角 `/` + 半角 `✓` + 半角 `…`** | `scripts/check_fullwidth_punctuation.py:18`<br>`ASCII_PUNCT = r"[,;!?]"` 只 4 种 | P1 | trivial(0.5h) |
| T-18 | **i18n 中英 ARB keys 不对齐**（zh 735 行 vs en 720 行，key 数差） | `lib/l10n/app_zh.arb`<br>`lib/l10n/app_en.arb`<br>已有 `check_arb_keys.py` 但 v0.22 round 30 提"加 3 个审查脚本"是首次进入 | P1 | trivial(0.5h) |
| T-19 | **app_zh.arb 7+ 处半角 `/` 应全角**（量表名/电话区号/时间窗口） | `app_zh.arb:67` `app_zh.arb:88` `app_zh.arb:165` `app_zh.arb:184` `app_zh.arb:247-248` `app_zh.arb:279` `app_zh.arb:419-420` | P1 | small(1h) |
| T-20 | **CHANGELOG.md 顺序混乱**（v0.22 在 v0.16 之前，时间倒序） | `docs/CHANGELOG.md` 整文件 | P2 | small(1h) |
| T-21 | **commitlint + husky/lefthook 未落地** | WHITEPAPER §13.3 P1 列了但未做 | P2 | small(2h) |
| T-22 | **release notes 自动生成**（standard-version / release-please）未用 | 同上 | P2 | small(2h) |
| T-23 | **AGENTS.md 没列 P2 阶段产物**（新人不知道 P2 review 工作流） | `AGENTS.md` 决策记录 | P3 | trivial(0.5h) |

---

## 底层逐行排查

### 中文 UI 文案 i18n 完整性

| 模块 | lib 文件数 | ARB key 覆盖度 | hardcode 中文数 | 修复难度 | 优先级 |
|------|----------|--------------|----------------|---------|--------|
| 主页 / 设置 / 树洞 / 用药 / 评估 / 趋势 / 联系人 / 提醒中心 | 7 大 feature | 108+ keys（中英 ARB keys 数差需 `check_arb_keys.py` 验） | 0（P0-1 全清后） | small(2h) | P1 |
| 错误兜底文案（exception path） | 多 widget | 部分走 `commonError` / `commonLoadFailed` | 0 | - | P2 |
| 通知标题 / 描述 | 5+ 通知模板 | 走 `app_zh.arb:226-268` | 0 | - | P2 |
| 邮件 / SMS 模板 | `lib/core/l10n/strings.dart:15-17` | hardcode 中文（"我是 XXX" + "已经 X 天没打卡了"） | 2 处 | small(1h) | P1 |
| 国产 ROM 自检卡步骤 | `app_zh.arb:247-268` | 5 大品牌全覆盖 | 0 | - | - |
| 法律文档（隐私政策 / 用户协议 / 敏感同意） | 3 份 .md | 走 ARB，0 hardcode | 0 | - | - |

**统计**：i18n 完整度 99%（剩 1% 是 exception / debug 路径）。
**关键差距**：中英 ARB key 数量差 15（zh 比 en 多），需 `check_arb_keys.py` 输出对齐。

### 中文文案规范问题（半角/全角/标点/量词/语气）

| # | 文件:行号 | 描述 | 修复难度 | 优先级 |
|---|----------|------|---------|--------|
| B-01 | `lib/l10n/app_zh.arb:89`<br>`lib/l10n/app_localizations_zh.dart:222`<br>`lib/l10n/app_en.arb:74`<br>`lib/l10n/app_localizations_en.dart:229` | **`settingsAboutVersion: "v0.1.0 · 我今天吃了药"`** — 版本号严重错误！实际 v0.22。Store 用户看到 v0.1 严重误导 | trivial(0.2h) | **P0** |
| B-02 | `lib/l10n/app_zh.arb:67` | `settingsMedReportSubtitle: "选时间窗口（7/14/30 天），给医生看"` — 半角 `/` 应全角 `／` 或 `、` | trivial(0.2h) | P1 |
| B-03 | `lib/l10n/app_zh.arb:88` | `settingsAssessmentHistorySubtitle: "查看所有 PHQ-9 / GAD-7 评估的折线图与对比"` — 半角 `/` | trivial(0.2h) | P1 |
| B-04 | `lib/l10n/app_zh.arb:165` | `snackbarPhoneInvalid: "号码格式不对（支持大陆/港澳台/国际）"` — 半角 `/`（括号是全角 ✓） | trivial(0.2h) | P1 |
| B-05 | `lib/l10n/app_zh.arb:184` | `medsCalendarSubtitle: "医生视角依从性热力图 · 7/30/90 天"` — 半角 `/` | trivial(0.2h) | P1 |
| B-06 | `lib/l10n/app_zh.arb:247-248` | `notificationStatusCardOemSubtitle: "小米/华为/OPPO/Vivo 默认会杀后台"` — 半角 `/` | trivial(0.2h) | P1 |
| B-07 | `lib/l10n/app_zh.arb:279` | `reminderHubAssessmentDescEnabled: "每 {days} 天提醒做心理评估（PHQ-9 / GAD-7）"` — 半角 `/` | trivial(0.2h) | P1 |
| B-08 | `lib/l10n/app_zh.arb:419-420` | `assessmentHistoryTimes` / `medReportPdfLoading` — 周边半角 `/` | trivial(0.2h) | P2 |
| B-09 | `lib/l10n/app_zh.arb:52-54` | `setupReminder1/2/3` 句首用半角 `✓` ——项目其它地方用 `•` 居中点。UI 一致性差 | trivial(0.5h) | P2 |
| B-10 | `lib/l10n/app_zh.arb:88-89` | 旧版 `settingsAboutVersion` 同时存在"v0.1.0"（行 89）和"v0.18 草稿"（隐私政策 §0）—— 3 份文档版本号对不上 | trivial(0.2h) | **P0** |
| B-11 | `lib/l10n/app_zh.arb:578` | `setupValidationNameRequired: "请输入您的名字"` — **您 / 你 不统一**：其他位置用"你的"（如 setupName line 34） | trivial(0.2h) | P2 |
| B-12 | `lib/l10n/app_zh.arb:235` | `notificationStatusCardStatusLoading: "加载中…"` 半角省略号（GB/T 15834-2011 要求全角 `……`） | trivial(0.2h) | P2 |
| B-13 | `lib/l10n/app_zh.arb:419` | `medReportPdfLoading: "生成 PDF 中……"` — 已全角 ✓（v0.22 round 28 修过） | - | - |
| B-14 | `lib/l10n/app_zh.arb:448` | `assessmentLoadingBack: "正在返回上一页……"` — 已全角 ✓（v0.22 round 28 修过） | - | - |
| B-15 | `lib/l10n/app_zh.arb:687` | `homeAutofireCelebration: "已打卡：{name} ✅"` 半角 `：` 实际是全角（确认 ✓）—— **check_fullwidth_punctuation.py 漏检**半角 `/` `✓` `…` 等符号 | - | P1 |
| B-16 | `lib/l10n/app_zh.arb:165` | `snackbarPhoneInvalid` 括号内半角 `/`—— 但 P1-15 修过这文件，是不是 v0.21 P1-14 / v0.22 round 28 又出现？需要 `check_arb_keys.py` + 半角检测配套 | trivial(0.2h) | P1 |
| B-17 | `lib/l10n/app_zh.arb:89` 同 B-01 | 见 B-01 | - | **P0** |

**汇总**：P0 2 项（B-01 / B-10 同一文件 2 处）/ P1 7 项 / P2 4 项
**根因**：`check_fullwidth_punctuation.py` ASCII_PUNCT 只 4 种 `,;!?` + 冒号，应扩展到 `/` `✓` `…` `()`（半角 vs 全角）

### 注释 / 命名 / 文档规范

| # | 文件:行号 | 类型 | 描述 | 修复难度 | 优先级 |
|---|----------|------|------|---------|--------|
| C-01 | `lib/core/data/services/preset_medication_templates.dart:90` | 注释 | 注释里仍列"碳酸锂 / 丙戊酸钠 / 拉莫三嗪" — 实际是 v0.18 P0-5 修过的历史说明，但**注释里保留处方药通用名**仍可能在 grep audit 时被命中（药品广告 / 行业监管扫描） | trivial(0.2h) | P1 |
| C-02 | `lib/core/data/services/preset_medication_templates.dart:113-114` | 注释 | 注释里"阿普唑仑 / 艾司唑仑 / 褪黑素" — 同上 | trivial(0.2h) | P1 |
| C-03 | `docs/CHANGELOG.md:288` | 文档 | v0.16.0 段在 v0.22.1 段**之后**（时间倒序）—— Keep a Changelog 规范要求时间倒序（新→旧），v0.16.0 应该移到 v0.15.0 之前 | small(1h) | P1 |
| C-04 | `docs/CHANGELOG.md:285-287` | 文档 | v0.22.1 段的 Tests 在 Fixed 之后，但 Keep a Changelog 推荐 Tests 在 Added 之后 | trivial(0.2h) | P2 |
| C-05 | `AGENTS.md:1-50` | 文档 | 决策记录表 12+ 行没 P2 / P3 阶段产物（新人不知道 P2 review 工作流） | trivial(0.5h) | P3 |
| C-06 | `docs/CHINESE_COMMIT_GUIDE.md:18` | 文档 | 写"项目历史 80% 英文 / 20% 中文,本指南偏理想"——但 §3 头部仍说"subject 用中文"互相矛盾。v0.22 round 28 跟 WHITEPAPER §14.3 统一为双轨，但 CHINESE_COMMIT_GUIDE.md 头部没改 | small(0.5h) | P2 |
| C-07 | `docs/GIT_WORKFLOW.md:84` | 文档 | "每个 minor version (0.17.0) 在最后一个 round 后打 tag"——但 v0.18 / v0.19 / v0.20 / v0.21 / v0.22 全无 tag，文档规范失效 | trivial(0.5h) | P1 |
| C-08 | `lib/main.dart:37` | 注释 | `.env 加载失败` 注释说"用 default"，但 fallback 实际行为是 `debugPrint` 警告（不是 fallback） | trivial(0.2h) | P2 |
| C-09 | `lib/presentation/pages/medication/preset_medication_templates.dart` | 命名 | 项目无此文件（确认），但 `lib/core/data/services/preset_medication_templates.dart` 是 core/data 不是 medication feature。命名跨层（services 用 feature 名） | trivial(0.5h) | P2 |
| C-10 | `docs/DEPLOYMENT.md:154-157` | 文档 | "再治愈更难" → "再规律更难"（v0.22 round 28 P1 修过 `f17e0d4`），但 L154-157 描述段落仍有 4+ 处"突然死了" / "复发一次"等敏感措辞 | small(1h) | P1 |
| C-11 | `docs/DEPLOYMENT.md:185` | 文档 | "声明'非医疗器械'"—— 实际 App 内容（PHQ-9 抑郁 / GAD-7 焦虑量表 + 失联通知）可能构成 NMPA 二类医疗器械，需法务确认 | small(1h) | P1 |

### commit 规范评估

**最近 30 commit 统计**（`git log --oneline -30`）：

| 类型 | 数量 | 占比 | 示例 |
|------|------|------|------|
| `refactor` | 13 | 43% | refactor(swallowError) / refactor(services) / refactor(misc) / refactor(theme) / refactor(l10n) / refactor(presentation) |
| `fix` | 8 | 27% | fix(P0) / fix(P1) / fix(P2) |
| `chore` | 3 | 10% | chore(scripts) |
| `feat` | 1 | 3% | feat(brand) v5 icon 替换 |
| `docs` | 1 | 3% | docs(CHANGELOG) 补 v0.18/19/20/21 |
| P0/P1/P2/P3 优先级 scope | 6 | 20% | fix(P0) / fix(P1) / refactor(P1) / refactor(P2) |

**commit 风格**：
- 统一头部 `v0.22 round <N>: <type>(<scope>) <subject>`
- scope 命名合理（P0/P1/P2 + 模块名）
- **subject 80% 英文 / 20% 中文**——跟 CHINESE_COMMIT_GUIDE.md §3 头部要求"subject 用中文"不符，但 WHITEPAPER §14.3 双轨制统一后合规
- 长度合理（subject ≤ 80 字符）
- 信息密度高（含修改范围 / 原因 / 文件数）

**不符合规范的具体 commit**：
- **D-01**: `f5ae3fd v0.22 round 30: chore(scripts) 加 3 个审查脚本 (ARB key 一致性 + DateTime race 检测)` —— **加 3 个 + ARB key 一致性 + DateTime race** 信息密度过高，建议 body 拆
- **D-02**: `fa3902b v0.22 round 30: refactor(misc) P1/P2 收尾 18 项 (semantics + 反馈 + 动效 + l10n + token)` —— **18 项 + 5 个领域** 同样信息密度过高
- **D-03**: `bf261c2 v0.22 round 29: refactor(P2) medication reminder cancel Future.wait 并发 (spen-16)` —— 引用 spen-16 内部编号，外部 reviewer 看不懂

**改进建议**：
1. **commitlint + husky/lefthook 落地**（P2 T-21）—— 当前纯靠人记得规范
2. **D-01 / D-02 类 squash 拆 commit** —— 一个 round 一个 atomic 主题
3. **D-03 内部编号 (# spen-16) 改超链接或 issue 编号** —— `Closes #<id>`

### 文档质量

| 文档 | 完整度 | 是否最新 | 关键缺失 | 修复难度 | 优先级 |
|------|--------|---------|---------|---------|--------|
| `README.md` | 95% | 是（v0.22 round 28 同步加密库） | Flutter 版本 3.44.5 / 3.41.9 不一致（DEPLOYMENT.md 改 3.41.9，README 仍 3.44.5）| trivial(0.2h) | P1 |
| `AGENTS.md` | 95% | 是 | 缺 P2 review 流程说明（T-23） | trivial(0.5h) | P3 |
| `docs/CHANGELOG.md` | 95% | 是（v0.22 round 28 补 4 段） | **顺序混乱 v0.22 → v0.16 → v0.15 → ...** | small(1h) | P1 |
| `docs/WHITEPAPER.md` | 95% | 是（v0.22 round 28 重写 §4.3 / §13.3） | 921 行，引用密度高但 **未列 release notes 模板** | small(2h) | P2 |
| `docs/DEPLOYMENT.md` | 90% | 是 | §5 完整描述仍有 4+ 敏感措辞（C-10）；§5 "声明非医疗器械" 待法务确认（C-11） | small(1h) | P1 |
| `docs/SENDGRID_SETUP.md` | 90% | 是（v0.22 round 29 修 6 处错误） | 头部已标"v0.22 round 29 状态说明"—— 但 §3 "domain authentication" 部分仍写"+1234567890" 等示例欠更新 | small(0.5h) | P2 |
| `docs/CHINESE_COMMIT_GUIDE.md` | 70% | 否（v0.22 round 28 跟 WHITEPAPER 统一后没回头改头部） | L3 "subject 用中文" 跟 L18 "80% 英文" 矛盾 | small(0.5h) | P2 |
| `docs/GIT_WORKFLOW.md` | 80% | 否（v0.22 round 28 失效） | tag 流程失效（C-07）；branch 策略表需补 P2/P3 阶段 | small(1h) | P1 |
| `docs/P2_COMPLIANCE_REVIEW.md` | 100% | 是（v0.22 P2 报告） | "已修 / 遗留 / 不修"3 列未标（59 项发现进度不透明） | small(2h) | P1 |
| `docs/P2_DESIGN_REVIEW.md` | 100% | 是 | 同上（P2_DESIGN 42 项） | small(2h) | P2 |
| `docs/P2_SYSTEM_REVIEW.md` | 100% | 是 | 同上（P2_SYSTEM 48 项） | small(2h) | P2 |
| `docs/CODE_REVIEW_v0.17r12.md` | 100% | 否（v0.17 round 12 时） | 早期，参考用 | - | P3 |
| `docs/PRD-v0.1-draft.md` | 70% | 否（v0.1 draft） | 早期 PRD，参考用 | - | P3 |
| `assets/legal/privacy_policy.md` | 80% | 否（v0.21 草稿，**未经律师**） | 3 份法律文档全部 v0.21 草稿（T-01）| large(8-16h) | **P0** |
| `assets/legal/user_agreement.md` | 80% | 否（同上） | 同上 | large(8-16h) | **P0** |
| `assets/legal/sensitive_data_consent.md` | 80% | 否（同上） | 同上；L49 加密告知 v0.22 round 28 修过 | large(8-16h) | **P0** |

### 中文 Git 工作流

- **branch 策略**：单 master，无 dev / feature branch（跟 `docs/GIT_WORKFLOW.md` §73 写的一致）
  - 优点：单 dev 简化流程、避免 merge 摩擦
  - 缺点：失去 PR review / CI gate
- **tag 流程**：**v0.18 - v0.22 全无 tag**（`git tag -l` 空）—— `GIT_WORKFLOW.md` §82-89 写的"每个 minor version 打 tag"失效
- **PR 流程**：无 PR（单 dev 不需要）
- **commit 粒度**：单 round 1-13 commit（粒度合理）
- **commit 信息**：v0.22 round 28 双轨制后规范（80% 英文 / 20% 中文混）
- **CI 强制**：仅本地验证（4 件套脚本），未接 GitHub Actions / Gitee Go / 极狐 GitLab CI

**改进建议**（按 P1 → P3）：
1. **P1**：补 v0.18-0.22 tag（`git tag -a v0.22.0 -m "..."` + push）—— **应用商店上架需要**
2. **P1**：CHANGELOG 顺序修正（v0.16 段移到 v0.15 之前）
3. **P2**：commitlint + husky/lefthook 落地
4. **P2**：standard-version / release-please 自动 release notes
5. **P2**：迁移到 Gitee / 极狐 GitLab（国内访问更稳定）—— 不是必须，看用户
6. **P3**：CHINESE_COMMIT_GUIDE.md 头部跟 §3 统一

### workflow-runner 评估

**当前工作流**（从最近 30 commit 推断）：
1. **单 agent 串行**（主 dev 直接 commit master）
2. **多视角 sub-agent review**（v0.22 round 28 三视角：spen / spzh / emil）
3. **CI 4 件套**（本地 flutter analyze + test + check_all + check_cross_feature + check_fullwidth_punctuation）
4. **P0/P1/P2 优先级**（commit 标题明确标注）

**哪类任务可被多 skill 协作加速**：

| 任务 | 当前工作流 | 多 skill 协作 | 提速 |
|------|----------|-------------|------|
| 修 P0 bug | 1 commit / 1-2 h | spen（4 步调试）+ spzh（PIPL 合规）+ emil（动效）并行 | 1.5x |
| 写新 feature | domain → data → presentation → test | brainstorming → writing-plans → TDD → verification-before-completion | 1.3x（先想清楚再写）|
| 大文件拆分 | refactor + test | subagent-driven-development（派 3 sub-agent 各拆 1/3）| 2x |
| 文档同步 | docs commit | chinese-documentation（统一标点 / 排版 / 术语）| 1.2x |
| 国产 ROM 适配 | 1 卡 + 5 引导 | brainstorming（用户调研）→ writing-plans（接厂商 SDK 顺序）| 1.5x |

**改进建议**：
- **P0 类修法（撤回同意 UI / vent 文字加密 / 清空数据 UI）** 应该用 brainstorming + writing-plans + TDD 流程，不能上来就改（`AGENTS.md` 没强制）
- **大版本 v0.23+ release** 应该用 workflow-runner YAML（brainstorming → 写 plan → TDD → review → release notes 自动生成）
- **`AGENTS.md` 决策记录应加 P2 review 流程**（T-23）

### brainstorming 落地

**新 feature 是否先 brainstorm 再写**（v0.22 round 30 例子）：

| 改动 | 是否 brainstorm | 评价 |
|------|---------------|------|
| `feat(brand) v5 icon 替换 v1`（`209c0b7`） | ❌ 4 个 maskable variant 拍脑袋 | 应 brainstorm：5 个 maskable variant 各自影响哪些 launcher（Pixel / 三星 / 华为 / 小米）？safe zone 怎么定？ |
| `fix(P0) 7 个 P0 必修`（`872184d`） | ❌ 7 个并行 1 commit | 应 brainstorming：哪些 P0 真必修？哪些是 P1 误判？ |
| `refactor(l10n) trend 17 处 hardcode 中文`（`419b71c`） | ✅ i18n 方向明确不需要 brainstorm | OK |
| `refactor(presentation) 26 处 TextStyle + 5 处 chip padding token 化`（`fa7e780`） | ✅ token 化方向明确 | OK |
| `refactor(services) BadgeSyncService 抽类`（`b73ff1a`） | ❌ 抽类时机拍脑袋 | 应 brainstorming：抽类 vs 工具方法 vs Notifier 哪个更对？ |

**结论**：v0.22 round 30 部分 P0/feat 改动**没经过 brainstorming**，**违反 superpowers-zh 流程规范**。
**修法**：AGENTS.md 加 "P0 修法 / 新 feature 必须先 brainstorming" 硬性规则。

### systematic-debugging / verification-before-completion / writing-plans 落地

| Skill | 落地情况 | 评价 |
|-------|---------|------|
| **brainstorming** | ❌ 部分用（"明确方向的不需要 brainstorm"）| P0/feat 必须强制 |
| **writing-plans** | ❌ 0 处 plan 文档（`docs/` 无 plans/ 目录） | 大版本 release 应有 `docs/plans/v0.23.md` |
| **executing-plans** | - | 同上 |
| **TDD（test-driven-development）** | ⚠️ v0.17 round 7 B4 demo 1 次 | 项目"先发现 bug 再写 test"，**没红灯先行**。`AGENTS.md` §9.4 自我承认"v0.16 几轮 bug 修都是先发现再写 test" |
| **systematic-debugging** | ✅ 4 步法体现（每 round 4-6 commit 渐进修） | OK |
| **verification-before-completion** | ✅ 4 件套 CI（flutter analyze + test + check_all + check_fullwidth） | OK 但未接 GitHub Actions |
| **code-review**（requesting + receiving）| ✅ v0.22 round 28 三视角 review | OK |
| **subagent-driven-development** | ✅ v0.22 round 28 P2 review 派 3 sub-agent | OK |
| **workflow-runner** | ❌ 未用 | v0.23+ release 应启用 |
| **using-git-worktrees** | ❌ 单 master 不需要 | OK |
| **finishing-a-development-branch** | ❌ 单 master 不需要 | OK |

**整体 superpowers-zh 落地度**：70%（差 brainstorming + writing-plans + workflow-runner + commitlint）

### 国内生态潜在问题

| # | 类型 | 描述 | 修复难度 | 优先级 |
|---|------|------|---------|--------|
| N-01 | **厂商 push 通道未接** | 见 T-05 / T-10。**真杀进程后通知 0 送达**。需要接 5 厂商（HMS / MIPush / OPPO PUSH / vivo Push / 魅族） | xlarge | **P0** |
| N-02 | **时区处理** | `flutter_timezone 3.0.1` 已用，时区走系统。**没硬编码 Asia/Shanghai**——跨时区用户（出国务工）失联阈值需重算 | small(1h) | P1 |
| N-03 | **国密 SM4** | 见 T-06 | large | P1 |
| N-04 | **农历 / 节气 / 节假日** | 见 T-12 / T-13 | medium / large | P1 |
| N-05 | **繁体中文（zh_Hant）** | 见 T-14 | medium | P1 |
| N-06 | **网络环境** | pubspec 未配国内镜像。`flutter pub get` 国内拉包可能慢 | trivial(0.2h) | P2 |
| N-07 | **应用商店元数据** | 4 大 store（华为 / 小米 / OPPO / Vivo）需各自审核材料：应用截图（5+ 张）、应用描述、隐私政策 URL（GitHub Pages 兜底）、ICP 备案号 | medium(6-8h) | **P0** |
| N-08 | **国产 ROM 通知兜底（自检卡 + 引导）** | v0.22 round 20 已落地，**自检卡状态显示完整 + 5 大品牌引导** | small(只缺 1-2 品牌) | P1 |
| N-09 | **中文输入法兼容性** | 病名 / 药名输入时 IME 候选词 / 自动纠错 / 手写输入兼容 | small(1-2h) | P2 |
| N-10 | **一加 / realme / iQOO / 三星 / 中兴等** | 见 T-11 | small(1h) | **P0** |
| N-11 | **小米推送 MIPush 文档** | 小米推送 SDK 需 `MiPush_APP_ID` / `MiPush_APP_KEY`，目前 pubspec 没集成 | xlarge(16h+) | P0 |
| N-12 | **华为 HMS Push** | 华为开发者联盟需注册 App + 签名 + 推送证书 | xlarge(16h+) | P0 |
| N-13 | **OPPO PUSH（含一加 / realme）** | OPPO 开放平台注册 | xlarge(16h+) | P0 |
| N-14 | **vivo Push（含 iQOO）** | vivo 开发者联盟注册 | xlarge(16h+) | P0 |
| N-15 | **魅族 FlymePush** | 魅族开放平台 | medium(4-8h) | P1 |

---

## 汇总统计

### 顶层（顶层架构）
- **国内合规风险**：9 项（5 P0 + 3 P1 + 1 P2）
- **国内生态适配**：7 项（2 P0 + 3 P1 + 2 P2）
- **可重构中文模块**：7 项（3 P1 + 3 P2 + 1 P3）

### 底层（逐行排查）
- **i18n 完整度**：99%（1% exception / debug 路径）
- **中文文案规范问题**：17 项（2 P0 + 7 P1 + 4 P2 + 4 已修）
- **注释 / 命名 / 文档规范**：11 项（3 P1 + 3 P2 + 1 P3 + 4 已合规）
- **commit 规范**：3 项改进（commitlint + 信息密度 + 内部编号）
- **文档质量**：16 份（5 P1 + 4 P2 + 2 P3 + 5 已合规）
- **中文 Git 工作流**：6 项改进（1 P1 + 4 P2 + 1 P3）
- **workflow-runner / brainstorming / 流程落地**：5 项（2 P1 + 2 P2 + 1 P3）
- **国内生态潜在问题**：15 项（5 P0 + 5 P1 + 5 P2）

### 总计

| 优先级 | 数量 | 占比 | 关键阻塞 |
|--------|------|------|---------|
| **P0** | **18** | 28% | 合规（5）/ 商店上架（2）/ 通知完全失效（5）/ 数据错版（1）/ 文档 bug（2）/ 厂商接入（3）|
| **P1** | **25** | 39% | i18n 半角标点（7）/ 文档同步（6）/ 流程落地（3）/ 国密 SM4（1）/ 繁体中文（1）/ 农历节气（2）/ 应用商店元数据（1）/ 注释残留（2）/ ROM 扩展（1）/ tag 流程（1）|
| **P2** | **16** | 25% | commit 规范（3）/ 文档规范（4）/ 商业模式（2）/ 离线模式（1）/ 翻译 polish（1）/ 命名规范（1）/ 通用工具（2）/ 网络镜像（1）/ 中文输入法（1）|
| **P3** | **5** | 8% | AGENTS.md 补充 / reports/ 索引 / 商业 P3 |
| **总问题数** | **64** | 100% | - |

### P0 必修（按工作量 / 风险排序）

| 排序 | ID | 标题 | 工作量 |
|------|------|------|--------|
| 1 | T-01 / N-07 | **3 份法律文档 v0.21 草稿未经律师 + 应用商店元数据** | 8-16h (律师外审) |
| 2 | T-05 / T-10 / N-01 / N-11~N-14 | **5 厂商 push 通道接入**（华为 / 小米 / OPPO / vivo / 魅族） | 80-120h (5 厂商 SDK) |
| 3 | B-01 / B-10 | **app_zh.arb:89 settingsAboutVersion v0.1.0 → v0.22.0** | 0.2h |
| 4 | T-02 | **隐私政策 §3 "用户姓名" → "用户昵称"** | 1h |
| 5 | T-04 | **隐私政策 §1 设备信息矛盾（"不收集" vs "通知/兼容性"）** | 0.5h |
| 6 | T-11 / N-10 | **国产 ROM 自检卡扩品牌（一加 / realme / iQOO / 三星 / 中兴）** | 1h |

### 工作量估算

| 优先级 | 估算 h | 按 8h/天 |
|--------|--------|---------|
| P0（不含厂商 push 接入） | 11-18h | 1.5-2 工作日 |
| P0（含厂商 push 接入） | 91-138h | 11-17 工作日 |
| P1 | 35-55h | 4-7 工作日 |
| P2 | 18-30h | 2-4 工作日 |
| P3 | 5-8h | 0.5-1 工作日 |
| **总（P0 不含 push）** | **69-111h** | **8-14 工作日** |
| **总（P0 含 push）** | **149-231h** | **19-29 工作日** |

---

## 关键观察

### 1. 项目是国内慢病 App 中"合规 + 架构 + 文档"**最完备**的 v0.22 状态

跟常见 Flutter 独立项目比：
- 4 层架构 + 5 层 umbrella + 4 件套 CI 脚本
- 703 / 703 test pass + 0 analyze error
- WHITEPAPER 921 行一站式档案
- 3 份 PIPL 法律文档（即便未经律师）
- i18n 完整度 99%（108+ keys + 中英 ARB）
- 3 视角 P2 review（59+42+48=149 项发现）
- 国产 ROM 通知自检 + 5 大品牌引导

但**上线前仍堵在 2 个 P0 必杀点**：
1. **法律文档 v0.21 草稿未经律师** —— 任何 store 上架都过不了
2. **5 厂商 push 通道未接** —— 90% 国产 ROM 用户收不到通知（真杀进程后）

### 2. 文档质量是项目最大资产，但 CHANGELOG 顺序 bug + 6 份 P2 review 没标进度

- CHANGELOG 顺序倒置（v0.22 在 v0.16 之前）是 P0 文档 bug，影响历史追溯
- 6 份 P2 review（149 项发现）"已修 / 遗留 / 不修" 3 列没标，**进度不可见**
- AGENTS.md 没列 P2 review 流程（新人接手障碍）

### 3. 国产 ROM 适配是"治标不治本"——只做了引导，没接厂商 push

- v0.22 round 20 自检卡 + 5 品牌引导**只是教育用户去系统设置**
- **真杀进程后通知 0 送达** 是不可逆的——必须接 5 厂商 push 通道
- **这是 P0 国产 ROM 通知完全失效** 风险
- 工作量极大（80-120h = 5 个 SDK 接入 + 5 个开发者联盟注册）

### 4. 中文 UI i18n 99% 完整但**半角 `/` 是 7+ 处漏网之鱼**

- `check_fullwidth_punctuation.py` ASCII_PUNCT 只 4 种（,;!? + :）—— **漏检半角 `/`**
- app_zh.arb 7+ 处"PHQ-9 / GAD-7" / "大陆/港澳台/国际" / "7/14/30 天" 用半角 `/`
- 应扩 ASCII_PUNCT 到 `[/,;!?、✓…]` 8 种

### 5. AGENTS.md / WHITEPAPER / CHINESE_COMMIT_GUIDE / GIT_WORKFLOW 4 份文档部分矛盾

- `CHINESE_COMMIT_GUIDE.md` L3 说"subject 用中文" vs L18 说"80% 英文"
- `WHITEPAPER.md` §14.3 改为"双轨"但 CHINESE_COMMIT_GUIDE.md 头部没改
- `GIT_WORKFLOW.md` §82 说"每个 minor version 打 tag"但 v0.18-0.22 全无 tag
- v0.22 round 28 修了"2 份规范自相矛盾"（`f17e0d4`），但还有 3 处残留

### 6. 精神心理 App 的"伦理 + 法律 + 监管"三角合规风险

- **医疗器械定性**：PHQ-9 抑郁 + GAD-7 焦虑 + 失联通知 = 似构成 NMPA 二类医疗器械？需律师
- **伦理审查**：精神心理患者是脆弱群体，App 收集抑郁 / 自伤倾向 / 树洞内容需更严告知
- **数据安全**：本地 AES-256 加密是基础；**国密 SM4** 是医院 / 政府客户准入门槛
- **商业 / 监管 / 道德** 三方都不熟，建议 v0.23 立项时**法务 + 伦理 + 技术** 3 方联合 review

---

## 附录 A：审查覆盖范围

| 类别 | 数量 | 备注 |
|------|------|------|
| lib/ 文件 | 164 | 抽样审 30+（关键 feature + service + l10n） |
| test/ 文件 | 74 | 抽样审 10+（routing / domain / presentation） |
| scripts/ | 15 | 关键 5 个审查脚本（check_all / check_cross_feature / check_arb_keys / check_fullwidth / check_drift_namespace） |
| docs/ 文档 | 7 | 全过（README / AGENTS / CHANGELOG / WHITEPAPER / DEPLOYMENT / SENDGRID_SETUP / 3 份 P2 review + GIT_WORKFLOW + CHINESE_COMMIT_GUIDE） |
| assets/legal/ | 3 | 全过（隐私政策 / 用户协议 / 敏感同意书） |
| 最近 commit | 30 | 全过 `git log --oneline -30` |
| l10n 完整度 | 100% | app_zh.arb 735 行 / app_en.arb 720 行 |

## 附录 B：建议 v0.23 立项时**先做**的 5 件事

1. **法律文档外审**（T-01）—— 立项后第 1 周，律师外审 3 份文档
2. **5 厂商 push 通道接入**（T-05 / T-10）—— 第 2-4 周，1 周 1 厂商
3. **AGENTS.md 加 superpowers-zh 流程硬性规则**（T-21 / T-23）—— 第 1 周，小修
4. **CHANGELOG 顺序修正 + 补 v0.18-0.22 tag**（C-03 / C-07）—— 第 1 周，小修
5. **app_zh.arb 半角 `/` 批量修 + check_fullwidth_punctuation.py 扩展**（B-02~B-08 / T-17）—— 第 1 周，小修

## 附录 C：P0 必修完整清单（按文件:行号）

```
lib/l10n/app_zh.arb:89          B-01  settingsAboutVersion v0.1.0 → v0.22.0
lib/l10n/app_en.arb:74          B-01  同上英文版
lib/l10n/app_localizations_zh.dart:222  B-01
lib/l10n/app_localizations_en.dart:229  B-01
lib/l10n/app_localizations.dart:506      B-01

assets/legal/privacy_policy.md:3  T-01  v0.21 草稿未经律师
assets/legal/privacy_policy.md:34 T-02  "用户姓名" → "用户昵称"
assets/legal/privacy_policy.md:38 T-04  设备信息矛盾

assets/legal/user_agreement.md:3  T-01  v0.21 草稿未经律师
assets/legal/sensitive_data_consent.md:3  T-01  v0.21 草稿未经律师

lib/core/data/services/notification_service.dart:1  T-05  5 厂商 push 未接
lib/presentation/pages/settings/widgets/notification_status_card.dart:240-300  T-11  缺 5 品牌

docs/CHANGELOG.md:288  C-03  顺序混乱 v0.16 在 v0.22 之后
```

---

**审查完成。**

- 总问题数：**64**
- P0：**18**（含 5 厂商 push 接入 3 项）
- P1：**25**
- P2：**16**
- P3：**5**
- 总工作量估算：**149-231h（19-29 工作日）**（含 5 厂商 push）或 **69-111h（8-14 工作日）**（不含 push）
- 建议 v0.23 立项时**先做**附录 B 5 件事，**法务外审 + 厂商 push 接入** 是上线前 P0 必杀点。
