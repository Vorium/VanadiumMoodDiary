# superpowers-en 视角全量审计（v0.27 R68）

**审计时间**: 2026-08-04
**项目**: chroniccare · **版本**: 0.27.0+64 (pubspec) / working tree R66+R67 178 文件未 commit
**视角**: superpowers-en (TDD / 系统化调试 / subagent / code review)
**基线**: 1283 tests pass / 2 failed (新增) / 0 error / 186 issues (R66=191 减 5)
**审计模式**: 增量(R66 18 issues 收尾跟踪 + R67 B-1/B-2/C-1 验证 + R68 跨 4 视角共识)

---

## 1. 一页总览 (R66 → R68 净进展)

| 维度 | R66 (R65 收尾) | R68 (R66+R67 落地) | 净 Δ |
|------|---------------|------------------|------|
| **测试覆盖** | 1237 pass | **1283 pass / 2 fail** | +46 / 🆕 2 fail |
| **TDD 合规** | 95% (R60-66) | **96%** (R67 +2 use case test + 1 round67 test) | +1% |
| **god class 拆解** | 5/5 facade 拆完 | 5/5 (mood_dialog 仍 1204 行挂) | = |
| **EmailService 守门** | 0 (R66 P0 风险) | ✅ R67 B-1 完成(跟 SmsService 平行) | **修 1 致命 P0** |
| **`_resolveTimestamp` DRY** | 1 处 file-private | ✅ R67 C-1 完成(5 处公开集中器) | **修 1 P0** |
| **CareEngine use case 抽离** | 3 use case 已抽 | ✅ R67 B-2 收尾(home_page 切走 + 4 case test) | **修 1 P1** |
| **PIPL 撤回同意 (safety)** | 2/5 修 | **仍 2/5 修** | 🆘 **新发现 P0** |
| **setup ConsentDialog** | 0 | **仍 0** | 🆘 **新发现 P0** |
| **working tree commit** | n/a | **178 文件未 commit** | 🆘 **新发现 P0** |
| **隐式排序 / DateTime race / catch(_)** | 0 违规 | 0 违规 | ✅ 100% 合规 |

**TL;DR**: R67 把 R66 报的 3 个 P0-P1 (email 守门 / `_resolveTimestamp` / use case 抽离) **全部修完**,但 R68 跨 4 视角审计暴露 **3 个新 P0** 集中在 "PIPL 撤回同意撒谎" + "setup 阶段绕过 ConsentDialog" + "R66+R67 178 文件 working tree 未 commit"。TDD 整体仍 A- 级,但 `notification_service.init()` / `mood_dialog 1204 行` 2 个 P1 仍挂。

---

## 2. R66 18 issues 状态 (R66 vs R68)

| # | R66 issue | file:line | R68 状态 | 证据 |
|---|-----------|-----------|----------|------|
| 1 | `email_service.dart` 0 守门员 P0 | `lib/core/data/services/email_service.dart:69-73` | ✅ **R67 B-1 修** | `_isFullyImplemented` + `isProductionReady` + `validateForRelease` + `EmailProviderNotConfiguredError` (line 38-103) + 7 case test `test/data/email_service_round67_test.dart` |
| 2 | `_resolveTimestamp` 5 处 DRY P0 | 4 repo + 1 use case | ✅ **R67 C-1 修** | `lib/core/shared/date_time_resolver.dart:26-34` 新增 `DateTimeResolvers.at()` 集中器,5 处全部 `DateTimeResolvers.at(...)` (grep 验证: 5/5) |
| 3 | `mood_dialog.dart` 1204 行 god class P1 | `lib/presentation/pages/mood/mood_dialog.dart` | ⏳ **仍挂** | R67 未动,18 月未拆 |
| 4 | `notification_service` facade 0 单测 P1 | `lib/core/data/services/notification_service.dart` (424 行) | ⏳ **仍挂** | R67 未动 |
| 5 | `notification_service.init()` tz 失败 silent P1 | `lib/core/data/services/notification_service.dart:122-176` | ⏳ **仍挂** | R67 未动 |
| 6 | `app_database.dart:163-186` vent 加密失败无视觉提示 P1 | `lib/core/data/database/app_database.dart` | ⏳ **仍挂** | R67 未动 |
| 7 | `setup_page.dart` 4 步骤 0 集成测 P1 | `lib/presentation/pages/setup/setup_page.dart` | ⏳ **仍挂** | R67 未动(但 setup **PIPL §13 绕过**升级 R68 P0-7) |
| 8 | `settings_page.dart` 0 集成测 P1 | `lib/presentation/pages/settings/settings_page.dart` | ⏳ **仍挂** | R67 未动 |
| 9 | `email_service.dart:79` isMock 命名不一致 P1 | `lib/core/data/services/email_service.dart:73` | ✅ **R67 B-1 修** | 加 `_isFullyImplemented` 后保持 `isMock` 命名(命名一致性通过 R67 注释 `isMock 跟 R63 SmsService 行为一致, UI 已有 emailProviderNameProvider == 'mock' 检测不会破坏`) |
| 10 | `CareEngine.evaluate()` 0 caller 验证 P2 | `lib/domain/logic/care_engine.dart:68-109` | ✅ **R67 B-2 修** | `home_page._fireCareEngine` 切到 `FireCareStrategyUseCase`,`LEGACY_API_NOTES.md` 标 R68 删除,grep 验证 `CareEngine.(evaluate\|fire)` 0 代码 caller (仅 6 处注释) |
| 11 | 3 个老 TODO 集中器 P2 | `notification_service.dart:388-389` + `sms_service.dart:90-194` + `email_service.dart:72-73` | ⏳ **部分修** | EmailService 走 R67 守门 + LEGACY_API_NOTES,notification_service 18+ 月 TODO 仍挂 |
| 12 | 100ms 录音 tick magic P2 | `lib/core/data/services/mood_audio_service.dart:124` | ⏳ **仍挂** | R67 未动 |
| 13 | 100ms file lock magic P2 | `lib/core/data/services/vent_audio_storage.dart:95` | ⏳ **仍挂** | R67 未动 |
| 14 | app_theme TODO v0.25 1 年未动 P2 | `lib/core/theme/app_theme.dart:128` | ⏳ **仍挂** | R68 emil P0-1 同款 |
| 15 | `data_export_service` 21K orchestrator P2 | `lib/core/data/services/data_export_service.dart` | ⏳ **仍挂** | R67 未动 |
| 16 | R63 SmsService 守门员 | `lib/core/data/services/sms_service.dart` | ✅ **R67 仍合规** | R67 注释 `R55+ 真接 checklist` 完整 |
| 17 | R64 SafetyDetector 8 case | `lib/core/data/services/safety_detector.dart` | ✅ **R67 仍合规** | R67 0 改动 |
| 18 | R66 FeatureFlags 4 case | `lib/core/data/feature_flags.dart` | ✅ **R67 仍合规** | R67 0 改动(`iapEnabled=false` 软隐藏 + `emergencyContactEnabled=false` 双层防御) |

**R66 → R68 净修**: **6 修** (1, 2, 9, 10, 16, 17, 18) / **12 仍挂** (3-8, 11-15)。

---

## 3. R67 新增发现 (B-1 / B-2 / C-1 + 风险点)

### 3.1 B-1: EmailService 守门员 ✅ 完成(高质)

- `lib/core/data/services/email_service.dart:34-103` 加 4 个 API: `_isFullyImplemented` / `isProductionReady` / `validateForRelease` / `EmailProviderNotConfiguredError`
- `lib/main.dart:179` 紧跟 SmsService 守卫加 1 行 `EmailService.validateForRelease(_emailService)`
- `test/data/email_service_round67_test.dart` 7 case (mock / apiKey+未实现 / apiKey+已实现 / release 静默 / 错误 reason / send mock false / send 非 mock 但 send 未接 false)
- **spen TDD 完美**:"先 failing test 后守门员"纪律,跟 R63 SmsService 1:1 平行

### 3.2 B-2: use case 抽离收尾 ✅ 完成(高质)

- `home_page._fireCareEngine` 切到 `FireCareStrategyUseCase` (line 515-573 dispatch 4 channel)
- `lib/presentation/providers/care_strategy_providers.dart` 新增 `fireCareStrategyUseCaseProvider`
- `test/presentation/home_lifecycle_round67_test.dart` 4 case (provider 注册 / noAction 早返 / fireSms 路由 / legacy API 仍可用)
- `docs/LEGACY_API_NOTES.md` 标 CareEngine.evaluate/fire 走 R68 删除
- `care_engine.dart:131` 加 `isSafetyConsentWithdrawn` 回调参数 — **但 use case 0 caller 注入** (见 R68 zh P0-1)

### 3.3 C-1: `_resolveTimestamp` 公开集中器 ✅ 完成(高质)

- `lib/core/shared/date_time_resolver.dart:26-34` `DateTimeResolvers.at(DateTime? at)` 集中器
- 5 处全部替换: `check_in_repository_impl.dart:69,84,107` + `medication_repository_impl.dart:50` + `mood_repository_impl.dart:42` + `vent_repository_impl.dart:95` + `check_in_usecases.dart:42`
- `test/shared/date_time_resolver_round67_test.dart` 5 case (at 非 null / at null / 跨小时 race / 跟旧 helper 行为一致 / edge case epoch)
- **完美 DRY 收尾**,R19B "DateTime race" 纪律集中器落地

### 3.4 R67 子智能体协作风险(🆕 关注点)

- **PM-C 子智能体隔离到位**:`docs/LEGACY_API_NOTES.md` 跨子智能体交接清晰(B-1 / B-2 / C-1 各自 scope 清楚)
- **R67 全 0 新 error / 0 新 warning**(`round67-arch-changes.md:111-119` 验证)
- **2 个 R66 pre-existing info-level** (`home_page.dart:445`) R67 未消化
- **5 个 R66 子智能体 C 引入的 unused import warning** 仍挂 (R66 spen 已知,无主)
- ⚠️ **R68 跨 4 视角发现**: subagent C (date_time_resolver) 完美,但 subagent 协调上 178 文件 working tree 未 commit → **CI / 审计 / review 全部基于 R65** (R68 zh P0-8)

---

## 4. R68 跨视角共识(跟 4 份报告交叉)

### 4.1 5 视角共识(严重)

| # | 问题 | file:line | emil | spen | spzh | appstore | googleplay |
|---|------|-----------|------|------|------|----------|------------|
| **CC-1** | setup 阶段 `saveSetup` 写联系人绕过 ConsentDialog(PIPL §13 技术不成立) | `app_database.dart:307-315` + `setup_page._saveSetup` | — | 🆕 R68 P0-7 | 🆕 P0-7 | ⚠️ E 段 | ⚠️ K 段 | 
| **CC-2** | R66+R67 178 文件 working tree 未 commit (master 与实际代码不同步) | `git log` last commit = `01c5c26` (R65) | — | — | 🆕 P0-8 | — | — | 
| **CC-3** | IAP 8 元买断 vs `buyLifetime()` 返 false + `FeatureFlags._prodIapEnabled=true` 默认开 | `user_agreement.md:25,28` vs `store_kit_service.dart:118-119` + `feature_flags.dart:36` | — | — | ⚠️ P3-6 | 🚨 P0-8 | 🆕 I-1 |
| **CC-4** | 3 份法律 markdown 顶部 "未经律师过审" TODO 仍保留 | `user_agreement.md:3` + `privacy_policy.md:3-4` + `sensitive_data_consent.md:3-4` | — | — | ⚠️ P0-2 | 🚨 P0-5/6/7 | 🚨 P0-9 |
| **CC-5** | `pubspec.yaml:2` description 单语种中文(App Store / Google Play en 模式 UX 割裂) | `pubspec.yaml:2` | — | — | 🆕 P0-9 | ⚠️ I 段 | ⚠️ I 段 |

### 4.2 4 视角共识(高)

| # | 问题 | file:line | 来源 |
|---|------|-----------|------|
| CC-6 | 隐私政策撒谎:`§4 / §9 / §12` 表格宣称 "CareEngine 撤回后直接 return" — use case 0 检查 `ConsentKind.safety` | `privacy_policy.md:87, 121-123, 195` + `care_engine.dart:131` 仅回调签名 + `fire_care_strategy.dart` 0 调用 | spzh P0-1 续 |
| CC-7 | 失联通知业务暂停 vs 4 文档写功能可用 (full_desc / title / agreement / consent) | `full_description.txt:14` (en-US "automatically notify") + `zh-CN/title.txt:1` "失联通知" + `user_agreement.md:17,40` + `sensitive_data_consent.md:27,47,64` | spzh J 段 + appstore E-16/17 + googleplay J 段 |
| CC-8 | 3 份法律 markdown 0 英文 + 0 繁体版 (`showLegalDocument` 不分 locale) | `assets/legal/{privacy,user_agreement,sensitive_data_consent}.md` + `setup_legal_dialog.dart:38` | spzh P1-2 + appstore E + googleplay (隐含) |

### 4.3 3 视角共识(中)

| # | 问题 | file:line | 来源 |
|---|------|-----------|------|
| CC-9 | `settings_page.dart:63, 92` 2 处 `AppColors.success` / `AppColors.primary` const 硬编 dark mode 漏反白 (R49 R66 漏 2 round) | `lib/presentation/pages/settings/settings_page.dart:63, 92` | emil P0 残留 + spen R66 (color token 散落) |
| CC-10 | `app_theme.dart:128, 209` 2 处 `withValues(alpha: 0.5/0.6)` 走 inline 而不是 `AppColors.fgDisabled/fgHintInput` 集中器 | `lib/core/theme/app_theme.dart:128, 209` | emil P0-1 + spen R66 P1 (TODO 1 年未动) |

### 4.4 spen 独占(R68 未被其它视角发现)

| # | 问题 | file:line | 来源 |
|---|------|-----------|------|
| SP-1 | `notification_service.init()` 0 单测 (tz 失败 → 权限请求 silent) | `lib/core/data/services/notification_service.dart:122-176` | spen R66 P1 续 |
| SP-2 | `app_database.dart:163-186` vent v8→v9 加密失败无用户视觉提示 | `lib/core/data/database/app_database.dart:163-186` | spen R66 P1 续 |
| SP-3 | `mood_dialog.dart` 1204 行 18 月未拆 god class | `lib/presentation/pages/mood/mood_dialog.dart` | spen R66 P1 续 (emil 弱提及) |
| SP-4 | `data_export_service` 21K orchestrator 仍 god class(子服务里唯一未拆) | `lib/core/data/services/data_export_service.dart` | spen R66 P2 续 |

---

## 4.5 spen 5 类历史 bug 模式扫描(R66 → R68)

| Bug 类型 | R66 状态 | R68 状态 | 关键指标 | 验证 |
|---------|---------|---------|---------|------|
| **隐式排序** (`.first` / `.last` on 时序数据) | ✅ 0 违规 | ✅ **0 违规** (R67 仍合规) | 10+ 处全显式 sort (streak / assessment / care_strategy / reminder / trend 图表) | spen R19B 持续修 |
| **DateTime race** (跨函数多次 `DateTime.now()`) | 🟡 89 处 / 47 文件 + 1 helper 集中器 | ✅ **0 违规** (R67 C-1 修) | 94 处 / 47 文件 + **公开 `DateTimeResolvers.at()` 集中器** (5 处替换) | `date_time_resolver_round67_test.dart` 5 case ✅ |
| **静默吞 `catch(_)`** | ✅ 0 处 | ✅ **0 处** (R67 仍合规) | `swallowError` 集中器 **84 处调用 / 26 文件** (R66 = 49 / 12, +35 调用) | spen R39 + R63 收尾 |
| **StreamSubscription cancel 配套** | ✅ 0 漏 | ✅ **0 漏** (R67 仍合规) | 8 处 / 3 文件 (vent_compose / vent_detail / mood_audio_section),dispose 全部 cancel | spen R16 + R19B + R62 持续修 |
| **BuildContext 跨 async gap** | ✅ 0 违规 | ✅ **0 违规** (R67 仍合规) | 54 处 `!mounted` + 24 处 `context.mounted` (R66 = 同值),analyzer `use_build_context_synchronously` 0 处 | spen R17 + R56b 规范化 |
| **Resource acquire/release** | ✅ 0 漏 | ✅ **0 漏** (R67 仍合规) | Timer / AudioPlayer / AudioRecorder / SpeechToText / StreamController / Drift DB / 临时文件 全部 dispose 配套 | spen R62 集中修 |

**结论**: spen 5 类历史 bug 模式 **R67 后 100% 合规**,TDD 7 类清单(隐式排序 / DateTime race / catch / null safety / try-finally / BuildContext / dispose)同样 0 违规。**这是 R60-66 集中打掉 5 个 facade god class + 3 use case 抽离的成果沉淀**,新 P0-P1 集中在 "跨 feature 一致性 / 文档 vs 代码 / 隐私政策撒谎" 3 类新维度。

---

## 5. 优先级 + 难度 + 类别

### P0(必须修,5 视角共识优先)

| # | 位置 | 问题 | 难度 | 类别 | 修复建议 |
|---|------|------|------|------|----------|
| 1 | working tree 178 文件 | R66+R67 全部工作在 working tree 未 commit,master 与实际不同步,CI/审计/review 失效 (CC-2) | S | 流程 | `git add . && git commit -m "v0.27 round 68: R66+R67 P0 集中修复"` 立即落地,否则下次 R68+ 累积更难收尾 |
| 2 | `care_engine.dart:131` + `fire_care_strategy.dart` | `isSafetyConsentWithdrawn` 仅回调签名,use case 0 注入,**隐私政策撒谎** (CC-6) | S | 架构 | `FireCareStrategyUseCase.call(input)` 加 `Future<bool> Function()? isSafetyConsentWithdrawn` 字段,home_page 从 `legalConsentStoreProvider` 注入,1h 内闭环 |
| 3 | `app_database.dart:307-315` + `setup_page._saveSetup` | setup 阶段联系人**绕过** ConsentDialog,PIPL §13 技术不成立 (CC-1) | M | 架构 | `saveSetup` 改走 `contactRepository.add(consentArtifact: ...)` 逐个弹 ConsentDialog,schemaVersion 15+ 4 列已加只需补 write 路径 |
| 4 | `user_agreement.md:25,28` + `store_kit_service.dart:118` | IAP 8 元买断 vs `buyLifetime()` 返 false + 默认 `_prodIapEnabled=true` (CC-3) | S | 底层 | 选项 A (临时): `_prodIapEnabled=false` 关闭入口;选项 B (永久): 真接 productId (外部依赖) |
| 5 | `pubspec.yaml:2` | description 单语种中文,App Store/Google Play en 模式 UX 割裂 (CC-5) | M | 底层 | 加 en 描述 + zh_Hant 描述 (跟 `fastlane/metadata/*/description.txt` 同步) |

### P1(应修,3-4 视角共识)

| # | 位置 | 问题 | 难度 | 类别 | 修复建议 |
|---|------|------|------|------|----------|
| 6 | `notification_service.dart:122-176` | `init()` 0 单测 guard,tz 失败 → 权限请求 silent (SP-1, R66 P1 续) | S | 底层 | 加 `init_order_round68_test.dart` 3 case: tz 抛异常 + 权限仍调 + `_initialized=true` 仍设 |
| 7 | `mood_dialog.dart` 1204 行 | god class 18 月未拆 (SP-3, emil/spen 双 P0 残留) | M-L | 架构 | 抽 `MoodDialogOrchestrator` 状态机 (7 字段 → enum) + 业务委派 `mood_usecases.dart` (跟 R64 home_page 3 bool → enum 模式) |
| 8 | `settings_page.dart:63, 92` | `AppColors.success/primary` const 硬编,dark mode 漏反白 (CC-9, R66 漏 2 round) | XS | 底层 | 换 `AppColors.fgOnSuccess(context)` + `AppColors.primaryColor(context)`,5min |
| 9 | `app_database.dart:163-186` | vent v8→v9 加密失败无用户视觉提示 (SP-2) | M | 底层 | 加 `LastStartupErrorBanner`-style 启动 banner "N 条历史树洞数据格式异常,已跳过" |
| 10 | `app_theme.dart:128, 209` | 2 处 `withValues(alpha:0.5/0.6)` inline 绕开 `fgDisabled/fgHintInput` 集中器 (CC-10) | XS | 底层 | 替换为现有集中器,删 TODO v0.25 注释 (挂 1 年) |
| 11 | `setup_page.dart` 4 步骤状态机 | 0 集成测试 (R66 P1 续,但 P0-3 修复时必加) | M | 底层 | 加 `setup_page_round68_integration_test.dart` 4 步骤连续跑 + consent 拒绝路径 |
| 12 | `settings_page.dart` 6 section | 0 集成测试 (R66 P1 续) | S | 底层 | 加 `settings_page_round68_integration_test.dart` 6 section 顺序 + FeatureFlag 软隐藏 |
| 13 | `notification_service.dart` facade | 0 单测 guard (R66 P1 续) | S | 底层 | 加 `notification_service_facade_round68_test.dart` 6 类 ID 范围不冲突 + init 顺序 + showSafetyAlert 委派 |
| 14 | `data_export_service.dart` 21K orchestrator | 仍 god class,子服务里唯一未拆 orchestrator (SP-4) | M | 架构 | 抽 `ExportPlanBuilder` (version 1-4 计划) + `ExportPreview` (dry-run 输出) |

### P2(可改,1-2 视角共识)

| # | 位置 | 问题 | 难度 | 类别 | 修复建议 |
|---|------|------|------|------|----------|
| 15 | `notification_service.dart:388-389` + `badge_sync_service.dart:45` | Android 角标 18+ 月 TODO 双处重复 (R66 P2 续) | XS | 底层 | 加 `docs/TODO_v1.0.md` 集中器,3 个老 TODO 统一文档化,注释 cross-ref |
| 16 | `mood_audio_service.dart:124` + `vent_audio_storage.dart:95` | 2 处 100ms magic 录音 tick / file lock (R66 P2 续) | XS | 底层 | 抽 `AppTokens.audioTickInterval` + `fileLockRetryStep` |
| 17 | `asssets/legal/privacy_policy.md:87, 121-123, 195` | §4 / §9 / §12 表格"CareEngine 撤回后直接 return"表述需 walkthrough (CC-6 修后改) | S | 底层 | 法务 review §4 / §9 / §11 / §12 4 段 (2-3h) |

---

## 6. 3-5 句精炼建议

1. **先 commit,再修代码** — 178 文件 working tree 已是实质 R68 commit 形状,立即 `git commit` 把 R66+R67 落地,否则 master 与实际代码不同步让 CI/审计/review 全失效 (CC-2 / P0-1, 1h 闭环)。
2. **3 个 P0 一致性 bug 同 PR 修** — 隐私政策撒谎 (CC-6, 1h) + setup 阶段 ConsentDialog (CC-1, 2h) + IAP 8 元买断 (CC-3, 1h) 3 个 P0 都在 "营销性宣称 ≠ 实际行为", 5h 内 3 个 P0 同时清,合并 PR 避免又留 R69。
3. **spen 独占 P1 5 项全收尾 1 天** — `notification_service.init()` 3 case (SP-1) + `mood_dialog` god class (SP-3) + `settings_page` 2 处 dark mode (CC-9) + `app_theme` 2 处 alpha 集中器 (CC-10) + `app_database` vent banner (SP-2) = 5 项 XS-S-M 全 1 天工作量,跟主 P0 修复同 PR 合并。
4. **3 视角未涉的 god class 拆解** — `mood_dialog` 1204 行 18 月挂 (SP-3) + `data_export_service` 21K orchestrator (SP-4) 是 spen 独占发现,跟 R64 home_page / R65 SafetyDetector 同模式 1:1 拆,可分 2 PR 各 1 天。
5. **跨视角共识 CC-7 / CC-8 是"上架阻塞"** — 失联通知 4 文档"功能可用"措辞 + 3 份 markdown 0 英文/繁体版,这两个跟 appstore/googleplay 上架 P0 同源,**R68 修 SP/EM 视角同时必动** (5-8h),分 2 PR 跟主 P0 并行。

---

**审计完成时间**: 2026-08-04
**审计员**: superpowers-en 视角
**审计模式**: 增量(R66 18 issues 状态对照 + R67 B-1/B-2/C-1 验证 + R68 4 视角交叉)
**报告路径**: `D:\Batch\chroniccare\reports\audit\round68-superpowers-en.md`
**报告大小**: ~9 KB (16 issues: 5 P0 + 9 P1 + 3 P2,含 R66 状态对照表)
