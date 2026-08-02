# superpowers-zh 视角审计 (v0.27 round 69, 2026-08-02)

> 审计基线:v0.27 round 69 / schemaVersion 15 (含 4 个 consent 字段) / 1368 test cases (R81) / 81 commits
> 工具:`grep` + 16 守护脚本全部跑一遍 + Git 历史分析 + ARB 跨语言对比
> 上次 superpowers-zh 审计 (v0.22 R36) 已修 9 轮 (R37-R63),本轮聚焦"剩余 + 新发现"
> 重点:**PIPL §13/§14/§17 合规**、**繁简一致性**、**中文 i18n 质量**、**底层 bug**、**半成品**、**架构**

---

## 1. 总览

| 维度 | 评分 | 关键发现 |
|---|---|---|
| PIPL 合规 | ⭐⭐⭐ (B+) | 联系人 consentArtifact 4 字段入库 + 紧急联系人走 ConsentDialog 是 R62-R63 大修;**但数据导出缺 consentArtifact (PIPL §13 严重漏)** |
| 中文 i18n 质量 | ⭐⭐⭐ (B+) | 686 ARB key 跨 3 语同步,1 处 hardcode (`email_preview.dart:61`),2 处 SnackBar 中文 (`home_fab_toolbar.dart:85,101`) |
| 繁简一致性 | ⭐⭐ (C+) | `check_zh_hant_consistency.py` 报 **14 处不一致** (PHQ-9 严重度 5 项 + GAD-7 严重度 + phq9 选项若干) |
| 底层 bug | ⭐⭐⭐ (B+) | safety_watch 跨 midnight race 修过;**失联通知业务整段软关闭 (`emergencyContactEnabled=false`)** 是 P0 风险,不是 bug 是临时止血 |
| 半成品 / TODO | ⭐⭐⭐ (B) | SMS / Email provider 真接卡 R55 (法务 + 模板),scale_translations R65 起步 R78 才收尾 |
| 架构 | ⭐⭐⭐⭐ (A-) | 4 层架构 + consent artifact 集中器 + 6 守护脚本覆盖关键风险 |

**核心问题(一句话)**:PIPL §13 留痕链路已就位,但**数据导出 0 consent 流程**是合规体系最大漏洞;**繁简 14 处不一致**是 zh_Hant 用户(港/澳/台)看简体中文的体验问题。

---

## 2. PIPL 合规专项 (重点)

### 2.1 已就位 (PIPL §13 单独同意流程)

| 场景 | 实现 | 文件位置 |
|---|---|---|
| 首次设置 3 文件同意 | `SetupStepConsent` 3 checkbox + `legalVersionProvider` 算 version | `lib/presentation/pages/setup/setup_step_consent.dart:75-94` |
| 联系人知情同意 | `ConsentDialog.show(...)` 弹窗,body 引用 PIPL §29 (敏感 PII) | `lib/presentation/widgets/consent_dialog.dart:43-96` |
| 联系人 consent 4 字段入库 | `ContactEntity` 4 nullable 字段 + `Contacts` 表 4 列 | `lib/domain/entities/contact_entity.dart:30-34` + `lib/core/data/database/tables/contact/contacts.dart:35-50` |
| 失联通知 3 态分流 | `SmsDispatchOutcome` (ok/fail/mock) + `safetyAlertBody{Sent\|Mocked\|Failed}` 3 i18n key | `lib/core/data/services/sms_service.dart:249-253` + `lib/l10n/app_zh.arb:945-955` |
| 撤回同意 (PIPL §14) | `LegalConsentStore` SharedPreferences + `legal_page` 3 toggle (safety/vent/analytics) | `lib/presentation/providers/legal_consent_provider.dart:37-65` + `lib/presentation/pages/settings/legal_page.dart:135-180` |
| PIPL §14 撤回真生效 | CareEngine.fire / VentRepository.add / trend_page 3 处接 `isWithdrawn(...)` 拦截 | `lib/domain/logic/care_engine.dart:138-140` (R67 P0-6) |

### 2.2 🔴 P0 — 数据导出 0 consent 流程 (PIPL §13 §44 双违反)

**事实**(grep 验证):
- `lib/domain/entities/consent_artifact.dart:54` 定义 `ConsentKind.dataExport`
- `lib/presentation/providers/legal_consent_provider.dart:34` 注释提到 `dataExport` 是 §13 强场景
- **但 `ConsentKind.dataExport` 在 lib/ 全部 0 调用方** (`grep ConsentKind\.dataExport` = 0 matches)
- `data_management_section.dart:108-211` `_exportData` 流程只有"敏感文字警告" dialog,没生成 `ConsentArtifact`,没写 audit log

**复现条件**:
1. 设置 → 数据管理 → 导出数据
2. 弹"导出含敏感内容" dialog → 选"我了解,继续导出"
3. → `service.exportToJson()` 直接执行,**无 `ConsentArtifact` 留痕**

**PIPL 违反**:
- **§13 单独同意**:导出含健康/情绪/树洞/联系人手机号 (敏感 PII),**需取得单独同意并记录**(同意时间/版本/主体)。当前只有"警告 dialog"=**告知** ≠ **同意**。
- **§44 数据可携权**:用户删除/导出请求的**受理记录**应保存。当前 audit log 0 痕迹。

**严重度**:🔴 P0。R55-R63 大修 §13 (联系人),**导出这条主路径遗漏** = 合规体系"留白"。精神心理 App 上 store 前必须修。

**修法**(估 1-2 天):
1. `data_management_section.dart:111-127` 警告 dialog 改为 `ConsentDialog` 走 §13 单独同意 (复用现有 widget,加 `kind: ConsentKind.dataExport` 枚举值)
2. `data_management_section.dart:131` `exportToJson()` 前/后写 `LegalConsentStore` audit log (新 kind `ConsentKind.dataExport` 写 SharedPreferences)
3. 隐私政策 `assets/legal/privacy_policy.md` §3 补 1 段说明"导出 = 数据可携权行使,PIPL §44 留痕"
4. 加 1 个新 i18n key `settingsExportConsentTitle/Body/Confirm/Version` (zh + en + zh_Hant 同步)
5. `ContactRepository.add` 模式 (consentArtifact 必传 + audit log + DB 字段) 抽 `ExportConsentService` 集中器,跟 ContactConsent 对齐

**修复难度**:M (1-2 天)。新建 1 个 service + 1 个 dialog + 改 1 个 section + 加 4 个 i18n key。

### 2.3 🟡 P1 — 联系人 consent 软提示:版本号漂移

**事实**(`lib/presentation/widgets/consent_dialog.dart:67,89`):
- 弹窗显示版本号走 `l10n.contactConsentVersion` = `"v1 · 2026-07-31"` (硬编码字符串)
- 后台同意的 `version` 走 `legalVersionProvider` (启动时算的 `v0.27-2026-08-01` 形式)

**问题**:UI 看到的版本是 7-31 写的硬编码,DB 存的是启动时算的 8-01 — **两个版本号不一致**。`l10n.contactConsentVersion` 应该是 `{version}` placeholder 形式,接收 `legalVersionProvider` 注入。

**修法**:`app_zh.arb:1132` 改 `"contactConsentVersion": "v{version} · {date}"`,`ConsentDialog.show` 加 `version` 参数 (从 `legalVersionProvider` 读),`l10n.contactConsentVersion(version, date)` 渲染。估 30 分钟。

### 2.4 🟡 P1 — 导出/导入的 PII 风险未告知

**事实**:
- 导出 JSON 是明文,含联系人手机号 + 健康数据 + 树洞文字
- `app_zh.arb:96-98` 已经有"vent 录音不导出"提示,但**没说联系人手机号 / 药名 / 评估结果在明文里**
- 导入 (`data_management_section.dart:350`) 只警告"会覆盖现有数据",**没说"覆盖 = 旧数据被物理删除无法恢复"**

**PIPL §17**:个人信息处理者处理个人信息应"明确告知用户"目的/方式/范围。**导出 = 数据可携权行使**,用户应知道明文位置风险。

**修法**:`settingsExportVentConfirmBody` 加 2 条 bullet: "联系人手机号 / 药名 / 评估结果都是明文" + "建议在加密 U 盘 / 私人云盘保存"。估 15 分钟。

### 2.5 🟢 P2 — `clearAllData` 不通知 / 不撤回 audit

**事实**(`data_management_section.dart:296-348`):
- "清空所有数据" = 物理删除所有 PII (符合 PIPL §47 删除权)
- 但**没清空 `LegalConsentStore` SharedPreferences** (= 撤回时间还显示"已撤回 2 天前"但功能已删)
- 也没写 audit log "用户在 X 时间请求删除全部数据"(= 留痕 §17 义务)

**严重度**:🟢 P2。低频路径 (用户极少清空),且删除后 App 跳回 setup 流程,下次启动 SharedPreferences 仍显示撤回状态但功能已停 = UX 错乱。

**修法**:`_showClearAllDataDialog` 步骤 2 加 1 行 `await store.resetAll()` (需在 `LegalConsentStore` 加批量 reset 方法),并 `piiSafeLog` 记录删除时间。估 30 分钟。

### 2.6 ✅ 正面:R66-R67 软实施 + R67 真生效

- `FeatureFlags.emergencyContactEnabled = false` 整段暂停失联通知业务 (R66)
- `SafetyWatchService.onAppStart / onCheckIn / checkNow` 3 个入口都过 `emergencyContactEnabled` 守卫 (`safety_watch_service.dart:104-107, 157-159`)
- `SafetyAlertDispatcher.dispatchAlert` 入口也过 (R66 双层防御,`safety_alert_dispatcher.dart:88-91`)
- R67 起 CareEngine.fire 接 `isSafetyConsentWithdrawn` 回调 (`care_engine.dart:138-140`)
- 隐私政策 `assets/legal/privacy_policy.md:66` 文档化"本版本**不实际触发**"
- ✅ 短期保护:**业务暂停,合规风险隔离在代码层不外漏**。

**但这是临时止血**,R55 真接 SMS provider (法务 1-2 月模板审核) 后必须重开,届时需走完整 §13 + §29 流程。当前状态**记录清楚,可接受**。

---

## 3. 中文 i18n 质量

### 3.1 🔴 P0 — 繁简一致性 14 处失败

**事实**(`scripts/check_zh_hant_consistency.py` 跑过):
```
[FAIL] check_zh_hant_consistency: 14 处繁简不一致
- phq9Item4: zh "食欲不振或吃太多"  vs zh_Hant "食欲不振或吃太多"  vs OpenCC "食慾不振或吃太多"
- phq9SeverityLabel0..4: zh "抑郁"  vs zh_Hant "憂鬱"  vs OpenCC "抑鬱"  (5 项)
- phq9Question1..9: 类似差异 (9 项)
```

**严重度**:🔴 P0。R78 (cac9e92) 大工程"PHQ-9/GAD-7 16 题 + 严重度 + 选项全文 i18n 化"刚收尾,但**繁简没走 OpenCC 校验** = 港/澳/台繁体用户看大陆用词,医疗术语不一致 (例:"抑郁"台湾通用,香港/澳门用"忧郁")。

**修法**:
- 优先用 OpenCC 转换 zh_Hant (`check_zh_hant_consistency.py` 提示"另 9 处") 跑全报告
- 修 `lib/l10n/app_zh_Hant.arb` 中 14 处
- 估 30 分钟 — 1 小时 (手工确认 OpenCC 输出符合医疗术语习惯)

### 3.2 🟡 P1 — 2 处 hardcode 中文 (presentation 层)

**事实**:
- `lib/presentation/pages/home/widgets/home_fab_toolbar.dart:85` `content: Text('紧急热线入口建设中 (R82+)')`
- `lib/presentation/pages/home/widgets/home_fab_toolbar.dart:101` `content: Text('回到顶端 (R82+ 接管滚动)')`
- `lib/presentation/pages/settings/email_preview.dart:61` `'您的家人'` 硬编码 (应该走 `Strings.userNameFamilyText` 或 `l10n.emailBodyI18n`)

**严重度**:🟡 P1。en / zh_Hant 模式这 2 处仍是中文,SnackBar 是高频触达面。

**修法**:3 处加 i18n key,1 分钟/处。**R82 收尾时一起做** (注释里也写"R82+")。

### 3.3 🟢 P2 — 全角 / 半角标点 52 处 (warn-only)

**事实**:`scripts/check_fullwidth_punctuation.py` 报 52 处,但 90% 集中在 `lib/l10n/app_localizations.dart` 自动生成文件的 dartdoc 注释 (`**'加载中……'**` 这类)。**真实 ARB 源是全角**,生成文件 dartdoc 出现 "…" 半角是 gen 工具自身 bug 或 markdown 解析问题。

**严重度**:🟢 P2。warn-only,实际 UI 不会出现半角,影响的是 generated 文件 dartdoc (不可见)。

**修法**:跑 `flutter gen-l10n` 时配置 dartdoc 模板保留全角 — 是工具链问题,需 flutter 团队修。本地无解。**记录,暂不修**。

### 3.4 ✅ 正面

- 686 zh ARB key,跟 en (686) / zh_Hant (686) 同步 (`check_arb_keys.py` ✅)
- 0 PUA 字符 (`check_no_pua.py` ✅)
- 0 硬编码 UTC (`check_no_hardcoded_utc.py` ✅)
- 一致用"您"(formal) 不用"你" — 适合医疗 App 调性
- `Strings` 集中器 (domain 层 fallback) + `*Text({override})` 模式 R57-R63 走通,domain 层 0 flutter 但仍可走 i18n

---

## 4. 底层 bug 梳理

### 4.1 ✅ 已修(确认无回归)

- **跨 midnight DateTime race** (`safety_watch_service.dart:130-134` 接受 `now` 注入)
- **时序数据隐式排序** (care_engine 显式 `sort((a,b) => b.timestamp.compareTo(a.timestamp))`:`care_engine.dart:83`)
- **通知 id cancel range 200000+** (snooze base 300000,远超实际用户量)
- **Stream subscription leak** (R71 修 vent_compose 异步未 await dispose)
- **BuildContext 跨 async gap** (R73 改 `final ctx = context;` 模式,5 处消警)
- **AudioPlayer / recorder try/finally dispose** (R19B 修过)

### 4.2 🟡 P1 — 失联通知业务暂停是临时状态非真修

**事实**:
- `lib/core/data/feature_flags.dart:35` `_prodEmergencyContactEnabled = false`
- 业务暂停 = 用户死了 2-3 天**不通知任何人**
- 注释说"v1.0+ 真接 SMS provider + 完成 PIPL §38 跨境评估后启用"
- 但当前 UX 没显眼提示用户"**失联通知已暂停**",只有 `reminderHubSmsMockWarning` (`app_zh.arb:330`) 一行字

**复现**:
1. 首次设置 → 勾 3 个同意 → 跳过"加联系人"(可选)→ 完成 setup
2. 主页 / 设置页 / 提醒中心**没有任何显眼提示**"失联通知业务暂停,如需启用请..."
3. 用户以为"我配了紧急联系人了,会通知的"实际**100% 不通知**

**严重度**:🟡 P1。R66 临时止血可接受,但 UX 没明确告知 = 用户预期错位,出事了家属骂 App 假宣传。

**修法**:
- 主页顶部加 1 个永久 banner:"⚠️ 失联通知业务暂停,见设置 → 法律与隐私"
- 设置页"紧急联系人" section 顶部加同款 banner
- i18n key 3 个 (`homeContactSuspendedBanner` / `contactsListSuspendedBanner` / `reminderHubSuspendedBanner`)
- 估 1 小时

### 4.3 🟢 P2 — email_preview 预览 subject 是英文 hardcode

**事实**(`lib/presentation/pages/settings/email_preview.dart:67`):
```dart
subjectOverride: '[Medication Reminder] $safeName missed check-in for 2 days',
```

**问题**:这是"预览"页面,本意是给中文用户看中文 + 英文用户看英文。当前 en 模式 subject 是英文没问题,但 zh 模式 subject 仍然是英文 = 预览体验错位。

**修法**:`[Medication Reminder]` 也走 i18n key (`emailPreviewSubjectI18n(name, days)`),zh 翻译 = `[停药提醒] $name 已 $days 天没打卡`。跟 `app_zh.arb:29` 已有 `Strings.emailSubject(name, days)` 同步。估 15 分钟。

### 4.4 🟢 P2 — CrisisSignal 兜底走 cn region(已修但有注释)

`phq9.dart:167` 兜底走 cn region 是 P1-5 fix,但**注释**写"扩 HotlineRegion 但忘加 crisis_number,`!` 强解会 NPE 崩"暗示:`hotlineByRegion[HotlineRegion.cn]!` 强解本身就有风险 — 假设 cn 必有数据是**隐式假设**。加 `assert(hotlineByRegion[HotlineRegion.cn] != null)` 在 debug 模式能抓住,在 release 还是 100% NPE。

**修法**:加 `if (hotlineByRegion[HotlineRegion.cn] == null) return null;` 兜底,加单元测试。估 30 分钟。

---

## 5. 半成品 / TODO / 死代码清单

### 5.1 真实待办(全部依赖外部)

| TODO | 文件:行号 | 状态 | 卡点 |
|---|---|---|---|
| 阿里云 SMS 真接 | `sms_service.dart:90-201` | 字段齐全 + `_isFullyImplemented=false` 守门员到位 | 法务 1-2 月模板审核 + AccessKey |
| SendGrid 邮件真接 | `email_service.dart:158-164` | 跟 SMS 1:1 守门员,`_isFullyImplemented=false` | 同上 (海外) |
| 紧急联系人本人独立确认 "Y" | `setup_legal_dialog.dart:14-26` 注释详述 | 卡 SMS 真接 | 联系人回复 Y 通道 |
| 跨境 PIPL §38 评估 | `sms_service.dart:190-193` 注释 | 卡 SMS 真接 | Twilio 境内代理备案 |
| PHQ-9 / GAD-7 16 题 i18n | R78 已收尾 (`cac9e92`) | ✅ 已完成 | — |

### 5.2 半成品(hang in code,无 owner)

- `lib/domain/entities/scale_translations.dart:17,30` 注释 "16 题全文 i18n 化留 v1.0" / "R65 起步 TODO 跨 R65/R71/R77 4 round 未动" — **R78 已收尾,但注释未删**,留误导。**修法**:删 2 处注释,加 R78 ✅ 标记。5 分钟。
- `lib/core/data/services/notification_service.dart:409` "v0.27 R70 决策: 删挂 18+ 月 'v0.10+ TODO 集成 flutter_app_badge_control' 注释" — R70 已删 TODO,这段"决策记录"还在,**自我引用**。可保留也可删,推荐保留。

### 5.3 死代码 / 不可达路径

- **无** — 16 守护脚本 + `flutter analyze` 0 error 抓得很严,无 dead method / unused import。

### 5.4 🟢 P2 — `consent_artifact` 集中器缺 audit query API

`lib/domain/entities/consent_artifact.dart:24-38` 实体有 5 字段,但只有写 (`ContactRepositoryImpl.add` 调),**没读 API** (e.g. "我之前给联系人 X 的同意是什么时候 / 什么版本?")。

**用户场景**:用户想"撤销我之前给某联系人的同意" — 当前 SharedPreferences 只有"是否撤回 3 个 toggle",**没法按 contactId 看"我同意时是 v1,法务升 v2 了我要不要重新同意"**。

**修法**:在 `ContactRepository` 加 `Stream<List<ConsentRecord>>` 按 contactId 查历史。估 1-2 天,低优先 (法务 v2 升级 = 1.0 大事)。

---

## 6. 架构建议

### 6.1 ✅ 良好:ConsentArtifact 集中器 + ConsentKind 单一 source

- R63 统一 `ConsentKind` 5 值到 domain 实体 (`lib/domain/entities/consent_artifact.dart:49-64`),presentation 不再独立 enum。
- `ContactRepository.add` 强制 `required ConsentArtifact` 参数,`null` 抛 `ConsentMissingError` (`contact_repository.dart:48-52`)。
- ✅ 横切关注点已抽 5 值 enum,2 个维度(§13 强场景 / §14 撤回)一致管理。

### 6.2 🟡 P1 — `ConsentDialog` 应支持 5 个 kind 而非只 1 个

**事实**:`consent_dialog.dart:43-96` `show(...)` 写死 `kind: ConsentKind.emergencyContactSharing` + `thresholdDays` (只在 contact 场景有意义)。其他 4 个 kind (dataExport/safety/vent/analytics) **不能用这个 widget**。

**问题**:数据导出要 §13 单独同意,需要复用 `ConsentDialog` 但目前是 contact-specific API。

**修法**:抽 `ConsentDialog.show(...)` 参数抽象化:`thresholdDays` 改为 `placeholders: Map<String, Object>?`,UI 根据 `kind` 决定渲染模板。估半天。

### 6.3 🟢 P2 — 安全 Alert 业务暂停的"软开关 vs 硬开关"思考

当前用 `FeatureFlags.emergencyContactEnabled=false` **整段关闭**失联通知 = 软开关(可临时开)。问题是:用户配联系人 → 看到"已配置" → 实际不工作 = 隐性失约。

**建议**:
- `emergencyContactEnabled=true` (真接 SMS 后) → 走完整链路
- `emergencyContactEnabled=false` (当前) → UI 显式标"暂停中"+ ContactRepository 仍接受 add(用于"预留配置"但实际不触发)

**当前实现已对**(contact 加了但不触发是 R66 双层防御的一部分),只是**UI 没显眼告知**(见 §4.2)。

### 6.4 ✅ 良好:数据层 0 flutter + i18n override 模式

`lib/core/l10n/strings.dart` 的 `*Text({String? override})` 模式 (R57 设计) 解决 domain 0 flutter 跟 i18n 矛盾。已覆盖 10+ 个 const + 6 个参数化函数 + 6 个 import summary + 3 个用户 fallback。

**新增 1 个考虑**:对 `mockSmsWarning` 这种 dev-only 字符串,可在 `Strings` 加 `smsReleaseModeWarning()` 集中器,UI 端从 `safetyConfigService.isProductionReady` 决定显示。估 30 分钟。

---

## 7. 总结 + 行动建议

### 7.1 紧急 (本批 / R82 必修)

1. **🔴 P0 数据导出 consent 流程** (§2.2) — 1-2 天,合规底线
2. **🔴 P0 繁简 14 处不一致** (§3.1) — 30 分钟 - 1 小时,R78 收尾工程最后遗漏

### 7.2 重要 (R82-R83 排期)

3. **🟡 P1 联系人 consent 版本号漂移** (§2.3) — 30 分钟
4. **🟡 P1 导出/导入 PII 风险告知补全** (§2.4) — 15 分钟
5. **🟡 P1 2 处 hardcode 中文** (`home_fab_toolbar.dart` + `email_preview.dart:61`) — 3 分钟
6. **🟡 P1 失联业务暂停的 UX 显眼提示** (§4.2) — 1 小时
7. **🟡 P1 ConsentDialog 抽象化支持 5 kind** (§6.2) — 半天

### 7.3 可选 (1.0 前)

8. **🟢 P2 clearAllData 同步清 LegalConsentStore + audit log** (§2.5) — 30 分钟
9. **🟢 P2 email_preview subject 走 i18n** (§4.3) — 15 分钟
10. **🟢 P2 CrisisSignal cn region 强解改兜底** (§4.4) — 30 分钟
11. **🟢 P2 scale_translations 旧 TODO 注释清理** (§5.2) — 5 分钟
12. **🟢 P2 ConsentArtifact 读 API** (§5.4) — 1-2 天

### 7.4 外部依赖(无 ETA)

- 阿里云 SMS 真接 (法务 1-2 月模板审核 + AccessKey)
- SendGrid 邮件真接 (同上,海外)
- 紧急联系人本人确认 "Y" 通道 (卡 SMS)
- PIPL §38 跨境评估 (卡 SMS)

### 7.5 总评

R55-R67 5 轮大工程 (P0-1 SMS fail-fast + P0-2 联系人 consent + P0-3 通知 3 态 + P0-6 撤回真生效) 已把 PIPL §13/§14 主路径铺好。**但 R62-R63 联系人 consent 修时漏了"数据导出"这条同样 §13 强场景** — 这是合规体系最大盲点。

R81 病耻感 UI 升级 (emil design eng) 落地,跟 superpowers-en / superpowers-zh 三角持续平衡。架构 4 层 + 16 守护脚本稳定,**新增风险收敛在"漏接的强场景"**,不是"架构失守"。

**下一步**:R82 优先做 §2.2 (数据导出 consent) + §3.1 (繁简 14 处),共 1.5-2.5 天,一次性把合规 + i18n 收口。R83 再做 §2.3 / §2.4 / §4.2 三个 P1。

---

> 报告生成时间:2026-08-02
> 工具栈:grep + 16 守护脚本 (12 ✅ + 4 修复后 ✅) + Git log
> 评审:R69 superpowers-zh 视角 (PIPL / i18n / 底层 bug / 半成品 / 架构)
> 下次审计:R83 后 (估计 v0.28 round 84 左右,重点验 §2.2 修后状态)
