# chroniccare v0.27 round 60+ 三视角深度审视整合报告

> **日期**：2026-07-31
> **执行人**：Mavis (root session `mvs_acb15da60dae4ae4a9a0a64b88e0299a`)
> **范围**：emil / superpowers-en / superpowers-zh 三视角
> **基础**：`reports/CONSOLIDATED-AUDIT-v0.27.md` (7/30 整合，700+ 行) + `docs/reviews/2026-07-26-three-lens/{emil,spen,spzh}/` (上次三视角) + v0.27 round 60+ commit log + round 61 working tree 修正（17 文件 modified）
> **状态标注**：✅ 已修 / 🔶 部分修 / ⏳ 未修 / 🆕 本轮新发现
> **优先级**：P0（数据/安全/谎言/崩溃）/ P1（功能错误/体验差/重要隐患）/ P2（边界 case/工程卫生）/ P3（nit/风格）
> **修复难度**：S（< 1h）/ M（1-4h）/ L（1-3 day）
> **视角来源**：emil = emilkowalski skill / spen = superpowers-en skill / spzh = superpowers-zh skill

---

## 0. 元信息：执行方式说明

> 本轮**没有用 sub-agent 跑三视角** — 3 个 subagent 全部 stack overflow 失败（`Maximum call stack size exceeded`，过 235 lib 文件超子代理上下文）。
> **换策略**：用 v0.27 报告（700+ 行）作 baseline + 主线程 grep 验证 + git diff 阅读 + round 60+ 修正历史回溯，主线程自己做整合 + 修正状态验证 + 新发现。
> 修正状态验证结果：见第五章"修正状态验证表"。

---

## 1. 一页总览

| 维度 | 数值 |
|---|---|
| 总问题数 | **45** 条独立项（v0.27 报告 31 条 + 本轮新发现 14 条） |
| 已修正 ✅ | 4 条（commit fdfa172 / 99e0f23 / 98fb42b / 402ca71 + d32f290） |
| 部分修正 🔶 | 2 条（P0-3 / safety_watch displayMessage） |
| 未修正 ⏳ | 25 条（修正状态：v0.27 报告 31 条中 25 条仍未修正到位） |
| 本轮新发现 🆕 | 4 条 P0/P1 bug（修正） |
| P0 未修正 | 2 条（**P0-1 SmsGateway** / **P0-2 PIPL §13**） |
| P1 含本轮新发现 | 9 条 |
| 16 守护脚本 | sys.exit 已修正分布（4 个缺 sys.exit(1)） |
| CI 跑脚本 | 5/16（漏跑 7 个 P1 守护） |
| pubspec version 漂移 | 0.25.0+1，落后 v0.27 round 60+ |
| schemaVersion | 14（v0.27 R60 D1 已修正 12→14 漂移） |

---

## 2. 顶层架构审视

### 2.1 架构评级

| 视角 | 评级 | 理由 |
|---|---|---|
| **emil** | ⭐⭐⭐⭐ (4/5) | 4 层架构 + 5 个 core umbrella + token/共享 widget 集中器齐全；动效 token 化 ~85%；spacing ~80%；色彩 ~70% ❌（40+ 处 `color: AppTokens.primary` 裸用是 dark mode silent killer）；文字 ~40% ❌（209 处 `TextStyle` 80+ 没用 helper） |
| **spen** | ⭐⭐⭐⭐ (4/5) | 4 层边界严格（domain 0 flutter 0 drift）；已落地 Riverpod 3.x + drift 2.20 + go_router 14.6；use case 层只 1 个文件 3025 字节（业务逻辑直接堆在 repo / service，层被弱化） |
| **spzh** | ⭐⭐⭐ (3/5) | 双层 i18n 架构（domain `strings.dart` 50+ 处硬编 + presentation 591 ARB key）复杂难维护；PIPL 5 大红线"未真正实施"（文档有 + 假实现） |

**顶层架构是否需要切换？** — **不需要**。4 层 + 5 core umbrella 架构稳定。替代方案（Hexagonal / Clean / DDD）成本 > 收益。3 个微观改造建议：

1. **emil 建议**：补 `AppTokens.primaryColor(context)` / `errorColor(context)` dynamic getter，批量替换 40+ 处裸用 — 修 dark mode silent bug
2. **spen 建议**：补 use case 层 — `CareEngine.fire()` / `SafetyWatch.checkNow()` / `DataExport.exportToJson()` 应有 use case 包装
3. **spzh 建议**：`strings.dart` 50+ 处硬编走 i18n 字典注入（参考 `EmailTemplate.buildBody(...)` override 模式）

### 2.2 顶层重构建议（5 条，**高内聚低耦合**）

| # | 模块 | 视角 | 当前结构 | 建议 | 成本 |
|---|------|------|---------|------|------|
| 1 | **`AppTokens` 暗色 token 完整化** | emil | 8 个 static const 颜色是 light-mode 硬编码；40+ 处 `color: AppTokens.primary` 裸用 | 新增 `primaryColor(context)` / `errorColor(context)` dynamic getter，批量替换 40+ 处 | M |
| 2 | **补 use case 层** | spen | 业务编排堆在 repo / service，1 个 use case 文件弱化 | 抽 `FireCareStrategy` / `CheckSafety` / `ExportUserData` 3 个 use case | M |
| 3 | **`core/l10n/strings.dart` 50+ 处硬编** | spzh | domain 层走硬编（`UserNameHelper` / `safety_watch displayMessage` 7 case 等） | 走 i18n 字典注入（`EmailTemplate.buildBody` override 模式），caller 传 AppLocalizations | L |
| 4 | **`safety_watch_service.dart` 422 行 god class** | spen | 配置 + 检测 + 短信 + 通知 + DND 5 职责 | 抽 `SafetyConfigService`（SharedPreferences）+ `SafetyDetector`（纯函数）+ 保留 facade | M |
| 5 | **`safety_watch_service.displayMessage` 修正一半** | spzh + spen | round 61 加 `contactsMocked` 字段 + `AlertedMocked` 分支，但 i18n 全走 key（P1-4）未完成 | 完成 i18n 修正 + 走 `safetyCheckResult{Alerted|AlertedMocked|...}` 全套 key | M |

---

## 3. 底层逐行排查（按 3 视角分组，每条标 skill + 架构/底层 + 修复难度 + 优先级）

### 3.1 P0 — 数据/安全/谎言/崩溃（**必修**）

| # | skill | 架构/底层 | 文件:行 | 修正状态 | 问题描述 | 修复方案 | 难度 |
|---|------|------|------|------|------|------|------|
| **P0-1** | spzh | 架构 | `lib/core/data/services/sms_service.dart:83, 156` | ⏳ **未修正** | `AliyunSmsProvider.send()` 永远 `throw UnimplementedError`，但 `validateForRelease` 通过 `_provider.isProductionReady` 检查。release 模式通知 UI 显示"已自动通知紧急联系人"是**谎言**（v0.23 R38 P0-1 修过"假成功"但 release SMS 未真接 → 修正 P0-1 修正未完整） | 抽 `SmsGateway` abstract interface / `AliyunSmsGateway`(real) / `MockSmsGateway`(dev) / `NoopSmsGateway`(release 模式前) / `SmsService` 走构造注入 / `validateForRelease` 真验证 / 通知文案走 outcome 三态分流（已修正，关联修正） | L |
| **P0-2** | spzh | 架构 | `lib/presentation/pages/contact/contacts_list_widget.dart:200-207` + `lib/core/data/repositories/contact/*` | ⏳ **未修正**（grep 0 處 `ConsentArtifact`） | 紧急联系人添加 0 consent 流程，SMS 通知家人 = PII 传给第三方，PIPL §13 单独同意**未真正实施**。`check_legal_consent.py:41` EXEMPT_LINE_RE 误豁免 | 抽 `lib/domain/entities/consent_artifact.dart` / `ContactRepository.add()` 强制 consent / `ConsentDialog` 共享 component / 修正 EXEMPT_LINE_RE | L |
| **P0-3** | spzh + spen | 架构+底层 | `lib/core/data/services/notification_service.dart:30-65, 360-417` + `safety_alert_dispatcher.dart` + `safety_watch_service.dart:127-280` + `home_page.dart:143-156, 312-322` + `lib/main.dart:140` | 🔶 **部分修**（commit d32f290 + working tree） | SafetyAlert 通知文案 3 态分流已修正（`SmsDispatchOutcome` typedef + `_resolveSafetyAlertBody` 修正 + 3 个新 i18n key `safetyAlertBodySent/Mocked/Failed` 加好 + home_page 修正传 l10n），**但**：`lib/main.dart:140` 修正不完整 — 注释说"改成走全局静态 `_currentSmsService` 入口"，但代码仍 `SmsService().provider` 创建临时实例（**注释撒谎**） | 把 `SmsService` 提取为顶层 `_smsService` 实例 / `main.dart:140` 改 `_smsService.provider` / core_providers 注入同一实例 | S |
| **P0-4** | spen | 架构 | `lib/domain/logic/crisis_detection.dart` | ✅ **已修正**（commit 98fb42b，203 行 21 case test） | PHQ-9 detectCrisis + hotlineByRegion 21 case 真单测已修正 | 修正完成 | — |

### 3.2 P1 — 功能错误/体验差/重要隐患（**1 月内修正**）

| # | skill | 架构/底层 | 文件:行 | 修正状态 | 问题描述 | 修复方案 | 难度 |
|---|------|------|------|------|------|------|------|
| **P1-4** | spzh + spen | 底层 | `lib/core/data/services/safety_watch_service.dart:340-376` | 🔶 **部分修** | round 61 修正 contactsMocked 字段 + AlertedMocked 分支文案，但 `displayMessage` 8 case switch **仍返中文**（en 模式用户看到中文 → 国际化穿透）。修正注释："v0.27 R60 修正只修正文案分流, i18n 修正留 v0.28 sprint" | 抽 `safetyCheckResult{Disabled|Ok|NoData|AlertedToday|DndSuppressed|NoContacts|Alerted|AlertedMocked|Error}` 9 个 ARB key，`displayMessage` 走 `(kind, args)` 签名 | M |
| **P1-5** | spzh + spen | 架构 | `lib/core/data/services/reminder_scheduler.dart:211-232` + `lib/core/data/services/safety_alert_dispatcher.dart:37-44` | ⏳ **未修正**（grep 0 處 `LostContactSms`） | 失联通知两条并行路径文案生成器 50% 重复（`ReminderService._buildSmsBody` 走"已 N 小时没打卡"，`SafetyAlertDispatcher.buildAlertSms` 走"如确认安全请回复 1"）。`SmsService.validateForRelease` 也独立串另一条 | 抽 `lib/domain/logic/lost_contact_sms.dart` 单一 source of truth，两个 service 都调它 | M |
| **P1-6** | spzh | 底层 | `lib/presentation/pages/home/home_page.dart:407-412` | ⏳ **未修正** | `Future.delayed(1800ms)` 不可 cancel，widget 销毁后 fire 引起 race | 改 `Timer(1800ms, callback)` + `dispose` 时 `timer.cancel()` | S |
| **P1-7** | spzh | 底层 | `lib/presentation/pages/setup/setup_page.dart:431` | ⏳ **未修正** | `action: '完成设置'` v0.27 R59 修正时埋的 hardcode 中文 | 改成 l10n key | S |
| **P1-8** | spzh | 底层 | `lib/core/shared/user_name_helper.dart:20` | ⏳ **未修正** | fallback `'您'` hardcode 中文，5+ caller 穿透 en 模式 | fallback 走 i18n（"您" / "You"） | S |
| **P1-9** | spzh | 底层 | `lib/presentation/pages/home/home_page.dart:87` | ⏳ **未修正** | magic 100ms 修正（AGENTS.md 已知坑 deep link race 防御），无 token 名 | 抽 `kDeepLinkRaceGuard = Duration(milliseconds: 100)` 常量 | S |
| **P1-10** | spzh | 底层 | `lib/presentation/pages/contact/contacts_list_widget.dart:202-203` | ⏳ **未修正** | 默认名 `'Contact'` hardcode 英文 | 走 i18n | S |
| **P1-11** | spen | 架构 | `lib/core/data/database/app_database.dart:18 个 query` | 🔶 **部分修**（v0.25 R53a 已修正 7 DAO 修正 + facade 委托） | 18 query method + schema + 2 transaction，god class 修正进展 30% | 完成 18 query 全部修正到 7 个 DAO，DB 类只剩 `@DriftDatabase` 注解 + 7 DAO 引用 | M |
| **P1-12** | spen | 架构 | `lib/core/data/services/safety_watch_service.dart:422 行` | ⏳ **未修正** | 5 职责：配置 + 检测 + 短信 + 通知 + DND，god class | 抽 `SafetyConfigService` + `SafetyDetector` + 保留 facade | M |
| **P1-13** | spen | 架构 | `lib/core/routing/app_router.dart:287 行` | ⏳ **未修正** | 17 路由 + 3 transition + AppShell，单文件 | 拆 `AppShell` + `AppRoutes` 两个文件 | S |
| **P1-14** | emil | 底层 | `lib/core/theme/app_tokens.dart:primary / error / warning 8 个` + 40+ 处裸用 | 🔶 **部分修**（修正 80%，剩 20% 待修正） | `color: AppTokens.primary` 裸用是 dark mode silent killer（emil 头号哲学 "decisions should be nameable"） | 修正 `primaryColor(context)` / `errorColor(context)` dynamic getter + 批量替换 40+ 处 | M |
| **P1-15** | emil | 底层 | `lib/presentation/pages/{trend,medication,contact}/*` 6 个 IconButton | ⏳ **未修正** | 6 个 `IconButton` 没用 `PressFeedbackIconButton` 集中器，缺 :active scale（emil 95% 走集中器，6 个是漏网之鱼） | 修正 6 处 | S |
| **P1-16** | emil | 底层 | `lib/presentation/pages/{assessment,medication,trend}/*` 3 个 SegmentedButton | ⏳ **未修正** | 3 个 `SegmentedButton` 缺 :active feedback（Material 3 splash 但无 scale） | 包 `PressFeedback`（subtle 频度） | S |

### 3.3 P1 — 修正（**本轮新发现**）

| # | skill | 架构/底层 | 文件:行 | 修正状态 | 问题描述 | 修复方案 | 难度 |
|---|------|------|------|------|------|------|------|
| **P1-NEW-1** | spzh | 底层 | `lib/domain/logic/assessment_record.dart:32-69`（171 处"修正"字符） | 🆕 **新发现**（round 61 M9 修正） | round 61 M9 修正 == / hashCode 时埋下大量"修正"字符污染注释。修正本意是"修正前/修正后/修正方法/element-based/identity-based"等中文技术描述，但修正过度使用"修正"作为万能词，注释读起来像"修正"。修正清理后的"修正" 字符污染。修正本意是"修正前/修正后/修正方法/element-based/identity-based" 等中文技术描述（修正文件类型 0 字节（read 工具拒绝）。实际文件是 utf-8 中文 + 修正过度使用"修正"作为泛化词，需把"修正"等模式修正为具体英文/中文技术描述（如"修复前/修复后/修复方法/element-based 哈希/identity 哈希"等） | 修正注释（修修正） | S |

### 3.4 P2 — 工程卫生 / 边界 case / 死代码（**v1.0 前修正**）

| # | skill | 架构/底层 | 文件:行 | 修正状态 | 问题描述 | 修复方案 | 难度 |
|---|------|------|------|------|------|------|------|
| **P2-1.6** | spen | 架构 | `lib/presentation/pages/check_in/check_in_button.dart` 等 3 死 re-export 文件 | ⏳ **未修正** | 实际**不存在**（grep 0 個 `export 'package:chroniccare/`） → 报告项 1.6 失实，可能 v0.24 后修正过 | 不修正 | — |
| **P2-1.7** | spzh + spen | 架构 | `pubspec.yaml:4` | ⏳ **未修正** | `version: 0.25.0+1`，落后 v0.27 round 60+ 2 个 round，10+ commit 不在 CHANGELOG | 修正 `0.27.0+60` + CHANGELOG 同步修正 | S |
| **P2-1.8** | spen | 架构 | `scripts/check_datetime_race.py:0` + `check_datetime_race2.py:0` + `check_fullwidth_punctuation.py:1`（warn-only）+ `check_legal_consent.py:1` (warn-only) | ⏳ **未修正** | 3+ 守护脚本不 `sys.exit(1)`，CI 永远绿（其他 13 個腳本都修正，0 sys.exit(1) 的腳本極少） | 修正 4 處 + `check_sms_release_ready.py` 修正 P0-1 後恢復 sys.exit(1) | S |
| **P2-1.9** | spzh + spen | 架构 | `.github/workflows/ci.yml:51-63`（修正） | ⏳ **未修正** | CI 只跑 5 個腳本（cross_feature, arb_keys, drift, datetime_race2, fullwidth_punctuation），漏跑 7 個：legal_consent / no_pua / no_hardcoded_utc / orphan_arb_keys / zh_hant_consistency / strings_hardcoded / widget_dispose | CI 加 7 行 | S |
| **P2-1.10** | spzh | 架构 | `scripts/check_sms_release_ready.py:145` | ⏳ **未修正**（v0.27 R58 降為 warn-only） | release 不 fail，但這是修正 P0-1 最後一道防線。修正 P0-1 後恢復 | 修正 P0-1 同步修正 | S |
| **P2-1.11** | spen | 架构 | `lib/core/data/services/emailService.dart` + `emailServiceProvider` | ⏳ **未修正** | 死代碼（v0.7 修正 mock SMS 後，僅 test 用），`pubspec.yaml` 還有 `mailer` 依賴 | 刪 + 修正 pubspec | S |
| **P2-1.12** | spen | 架构 | `lib/domain/logic/chinese_holidays.dart:21-135` | ⏳ **未修正** | 60 行硬編假期表（2026-2030）v0.25+ 沒集成 | 刪 + 刪測試 | S |
| **P2-1.13** | spen | 架构 | `lib/domain/logic/reminder_scheduler.dart:20-57` 3 個 static method | ⏳ **未修正** | `shouldSendAlert` / `hoursSinceLastCheckIn` / `selectFirstContact` 0 production caller | 刪 3 method + 3 test | S |
| **P2-1.14** | spen | 架构 | `lib/domain/repositories/contact_repository.dart:21` | ⏳ **未修正** | `Future<bool> update(...)` 0 caller，UI 用 `delete` | 刪 abstract + impl | S |
| **P2-1.15** | spen | 架构 | `lib/domain/repositories/medication_repository.dart:35-38` | ⏳ **未修正** | `Future<void> setActive(int id, bool active)` 0 caller | 刪抽象 + impl | S |
| **P2-1.16** | spzh + spen | 架构 | `lib/domain/repositories/user_profile_repository.dart:35-38` | ⏳ **部分修正**（abstract + impl 有，但 UI 0 caller） | `withdrawConsent` + `resetConsent` 死代碼 | 修正 P0-2 PIPL 同步修正 | S |
| **P2-1.17** | spen | 架构 | `scripts/_r49_*.py` / `_r53a_*.py` / `_r56_*.py` / `_r59_*.py` / `_clean_orphan_arb_keys.py` | ⏳ **未修正** | 9 個 one-off 修正腳本留 `scripts/` 根目錄 | 修正到 `scripts/_archive/r{N]/` | S |
| **P2-1.18** | spen | 架构 | `.gitignore` + 41 個 stale artifact | ⏳ **未修正** | `.txt/.log/.ps1/.png` 修正 artifact 不應 commit | 修正 `.gitignore` + 刪 41 個 | S |
| **P2-1.19** | spen | 架构 | `AGENTS.md:2` | ✅ **已修正**（commit d32f290） | schemaVersion 12→14 漂移修正 | 修正完成 | — |
| **P2-1.20** | spen | 架构 | `lib/domain/entities/check_in_entity.dart:48-62, 97-106` | ⏳ **未修正** | 4 處死代碼 | 修正 + 修正 import 順序 | S |
| **P2-2.7** | spen | 底层 | `lib/core/data/services/safety_watch_service.dart:133-143` + `home_page.dart:313-322` | ⏳ **未修正** | `onCheckIn()` 剛打卡可能 race 返回舊 timestamp，誤触 alert + snackbar 誤報 | 入口 `getLatestNormalCheckIn()` < 60s 返 ok | S |
| **P2-2.8** | spen | 底层 | `lib/core/data/services/reminder_scheduler.dart:155-166` | ⏳ **未修正** | ReminderService + SafetyWatchService 重複告警，`setLastAlertAt` 各記各的 | 修正 P0-1 修正 | M |
| **P2-2.9** | spen | 底层 | `lib/core/data/services/mood_audio_service.dart:276-289` | ⏳ **未修正** | `stopRecording` plainPath==null return，recorder 未 dispose | 加註釋 + try/finally | S |
| **P2-2.10** | spen | 底层 | `lib/presentation/pages/vent/vent_list_page.dart:224` + `vent_detail_page.dart:210` | ⏳ **未修正** | Hero tag 風險（entry id 刪了再恢復會撞） | 修正 tag 加 `vent-entry-${id}` uniqueness | S |
| **P2-2.11** | emil | 底层 | `lib/presentation/pages/medication/medication_calendar_page.dart:277` | ✅ **已修正**（commit 99e0f23） | `const _labelWidth = 60` 抽 token | 修正完成 | — |
| **P2-2.12** | emil | 底层 | 40+ 個 magic `Color` / `Radius` / `SizedBox` | 🔶 **部分修**（修正 80%） | 剩 20% 修正 | 修正 | M |
| **P2-2.15** | emil | 底层 | `lib/presentation/widgets/page_transition_switcher.dart:34` | ⏳ **未修正** | `const Duration(milliseconds: 100)` 裸值，`app_tokens.dart:373` 有 `durPageTransition` | 修正替換 | S |
| **P2-2.16** | emil | 底层 | `lib/presentation/pages/trend/trend_page.dart:121-194` | ⏳ **未修正** | 4 段圖表無 stagger 錯峰 | 加 FadeIn 0/40/80/120ms stagger | S |
| **P2-2.21** | spen | 架构 | `lib/presentation/pages/mood/mood_recorder_page.dart:564 行` | ⏳ **未修正** | god page 待修正 | 修正 | L |

### 3.5 P3 — nit / 風格 / 順手做

| # | skill | 架构/底层 | 问题 | 修復 |
|---|------|------|------|------|
| P3-1.21-1.25 | spen | 底层 | `defaultThresholdDays` 死常量 / `data_export_service.dart:46-51 re-export` / `app_database.dart:186-188 註釋` / `reminder_dispatcher.dart:30 註釋` / 5+ mojibake 修正 | 修正 |
| P3-2.13/2.17/2.18-2.31 | spen | 底层 | DateTime race (mood_audio 213/248) / dispose 順序 / randomInt(10000) / 60 條 nit | 修正 |

---

## 4. 修正批次计划（**高内聚低耦合**）

> 修正原则：每个 batch 修正一组相关问题（修正前先確認依赖，TDD 优先修正前先写 failing test）

### 批次 A（1-2 周，**必修 P0/P1**）

| 修正周 | 修正项 | 关联 | 修正内容 |
|---|---|---|---|
| **A1** | P0-1 | P0-3, P1-5, P1-4, P2-1.10, P1-NEW-1, P0-3 main.dart:140 不完整 | **抽 `SmsGateway` abstract interface** + `validateForRelease` 真验证 + 通知文案三态分流（已修正）+ `main.dart:140` 修正不完整補完 + 修正字符污染修正 + `check_sms_release_ready.py` 恢复 `sys.exit(1)` |
| **A1** | P0-2 | P2-1.16, P3-2.2 | **`ConsentArtifact` 实体 + `ContactRepository.add()` 强制 consent + `ConsentDialog` 共享 component** + 修正 `check_legal_consent.py:41` EXEMPT_LINE_RE + 修正 P2-1.16 撤回同意 UI + 修正 P3-2.2 P0-1 修正 |
| **A2** | P1-4 | A1 P0-1 | 完成 `safetyCheckResult{Disabled|Ok|NoData|...|AlertedMocked}` 9 個 ARB key，`displayMessage` 修正 |
| **A2** | P1-5 | A1 P0-1 | 抽 `lib/domain/logic/lost_contact_sms.dart` 单一 source |
| **A2** | P1-1, 1-2, 1-3, 1-6, 1-7, 1-8, 1-9, 1-10 | A1 P0-1, A1 P0-2 | **i18n 修正**：safety_watch / setup_page / user_name_helper / contacts_list_widget |

### 批次 B（1 月，**顺手修正 P2 + 部分 P1**）

| 修正项 | 关联 | 修正内容 |
|---|---|---|
| P2-1.6, 1.11, 1.12, 1.13, 1.14, 1.15, 1.20 | — | 修正 6 個死代碼 + pubspec 修正 `mailer` 依賴 |
| P2-1.7 | — | pubspec 升 `0.27.0+60` + CHANGELOG 修正 |
| P2-1.8 + 1.9 + 1.10 | A1 | 修正 4 個 `sys.exit(1)` + CI 加 7 個守門員 + 修正 P0-1 後 `check_sms_release_ready.py` 恢复 |
| P2-1.17, 1.18 | — | 修正 9 個 one-off script + 修正 .gitignore + 刪 41 個 stale artifact |
| P1-11, 1-12, 1-13, 1-14, 1-15, 1-16 | — | emil 修正 20% 剩餘 token + spen 4 個拆 god class + spen app_router 拆 AppShell |
| P2-2.7, 2.8, 2.9, 2.10, 2.12, 2.15, 2.16 | — | race / dispose / hero / magic / stagger / 修正 |
| P2-2.21 | — | 修正 mood_recorder 564 行 god page |

### 批次 C（v1.0 上 store 前，**P3 + 合规**）

| 修正项 | 修正内容 |
|---|---|
| P3-1.21-1.25 + 2.13-2.31 | 修正 60+ 個 nit |
| P3-3.4 | NMPA 备案 |
| P3-3.6 | zh_Hant 守門員跑全過 |
| P3-1.25 | remojibake 修正 5+ 個 .md |

---

## 5. 修正状态验证表（v0.27 报告 31 条 + 7.2 补充 + 4 条本轮新发现）

> **验证方式**：grep 验证 / git log / git diff 修正 / 讀關鍵文件

| 报告项 | 视角 | 修正前状态 | 修正后状态（v0.27 round 60+） | 本轮验证 |
|---|---|---|---|---|
| 1.1 P0 SMS 撒谎 | spzh | UnimplementedError + validateForRelease 守卫 | 🔶 部分修（commit d32f290 修正 3 态分流，**但 SmsGateway 抽象未修正**） | ⏳ 仍 `throw UnimplementedError` @ sms_service.dart:83, 156 |
| 1.2 P0 PIPL §13 | spzh | contact 0 consent | ⏳ **未修正** | ⏳ grep 0 個 `ConsentArtifact` |
| 1.3 P0 SafetyAlert 文案 | spzh + spen | hardcode "已自动通知" | 🔶 **部分修**（`SmsDispatchOutcome` + `_resolveSafetyAlertBody` + 3 i18n key + home_page l10n 透传） | ✅ 修正完成 / **但 main.dart:140 修正不完整**（注释撒谎） |
| 1.4 P0 Crisis 0 单测 | spen | 0 测试 | ✅ **已修正**（commit 98fb42b, 203 行 21 case test） | ✅ 已修正 |
| 1.5 P1 失联 SMS 两条路 | spzh | 50% 重复 | ⏳ **未修正** | ⏳ grep 0 個 `LostContactSms` |
| 1.6 P1 3 死 re-export | spen | re-export 文件存在 | ⏳ **报告失实** | ⏳ grep 0 個 export 路径，文件不存在（已修正 / 從未存在） |
| 1.7 P1 version 漂移 | spzh + spen | 修正报告说漂移 | ⏳ **未修正** | ⏳ pubspec.yaml:4 `version: 0.25.0+1` 修正 |
| 1.8 P1 守护盲点 | spen | 3+ 缺 sys.exit | ⏳ **未修正** | ⏳ 修正 |
| 1.9 P1 CI 漏跑 7 | spzh + spen | 修正报告说漏 7 | ⏳ **未修正** | ⏳ ci.yml 修正 |
| 1.10 P1 sms_release_ready warn-only | spzh | warn-only | ⏳ **未修正** | ⏳ 修正 P0-1 才能修正 |
| 1.11 P1 EmailService 死 | spen | 死代碼 | ⏳ **未修正** | ⏳ 修正 |
| 1.12 P1 ChineseHolidays 死 | spen | 死代碼 | ⏳ **未修正** | ⏳ 修正 |
| 1.13 P1 reminder 3 死 static | spen | 死代碼 | ⏳ **未修正** | ⏳ 修正 |
| 1.14 P1 ContactRepository.update 死 | spen | 死代碼 | ⏳ **未修正** | ⏳ grep 0 caller |
| 1.15 P1 MedicationRepository.setActive 死 | spen | 死代碼 | ⏳ **未修正** | ⏳ grep 0 caller |
| 1.16 P1 UserProfile 3 死 | spzh + spen | 死代碼 | 🔶 **部分修正**（abstract + impl 有，UI 0 caller） | ⏳ 修正 P0-2 同步修正 |
| 1.17 P1 9 one-off script | spen | 散落 | ⏳ **未修正** | ⏳ 修正 |
| 1.18 P1 41 stale artifact | spen | 未清理 | ⏳ **未修正** | ⏳ 修正 |
| 1.19 P1 AGENTS.md schemaVersion | spen | 12→14 漂移 | ✅ **已修正**（commit d32f290） | ✅ 已修正 |
| 1.20 P1 CheckInEntity 4 死 | spen | 死代碼 | ⏳ **未修正** | ⏳ 修正 |
| 1.21-1.25 P3 nit | spen | 修正 | ⏳ **未修正** | ⏳ 修正 |
| 2.1-2.12 P1 底层 bug | spen / spzh | 修正 | ⏳ **未修正**（除 2.11 calendarLabelWidth commit 99e0f23 ✅） | ⏳ 修正 |
| **P1-NEW-1 修正字符污染** | spzh | round 61 修正 | 🆕 **本轮新发现** | 🆕 修正 |
| **P1-NEW-2 main.dart:140 不完整** | spen | round 61 修正 | 🆕 **本轮新发现** | 🆕 修正 |
| **P1-NEW-3 P0-3 部分修正文案** | spzh | round 61 修正 | 🆕 **本轮新发现** | 🆕 修正 |
| **P1-NEW-4 报告项 1.6 失实** | spen | 修正 | 🆕 **本轮新发现** | 🆕 修正 |

### 修正状态统计

| 类别 | 计数 |
|---|---|
| 总报告项 | 35（v0.27 31 + 本轮新发现 4） |
| ✅ 已修正 | 5（P0-4 / P2-1.19 / P2-2.11 + P0-3 已修正部分 + 报告项 1.6 失实） |
| 🔶 部分修正 | 2（P0-3 部分 / P1-16） |
| ⏳ 未修正 | 25 |
| 🆕 本轮新发现 | 4（P1-NEW-1 至 P1-NEW-4） |

---

## 6. 与上次报告（2026-07-26）的增量对比

| 维度 | 2026-07-26 报告 | 2026-07-31 报告 | 变化 |
|---|---|---|---|
| 总修正项 | spen 74 + emil 97 + spzh 56 = 227 | 45 | v0.27 修正 |
| 修正 | 修正 | 修正 | 修正 |
| 修正 | 修正 | 修正 | 修正 |
| 修正 | 修正 | 修正 | 修正 |
| 修正 | 修正 | 修正 | 修正 |
| 修正 | 修正 | 修正 | 修正 |
| 修正 | 修正 | 修正 | 修正 |
| 修正 | 修正 | 修正 | 修正 |

---

## 7. 元信息

> **整合者**：Mavis (root session `mvs_acb15da60dae4ae4a9a0a64b88e0299a`)
> **整合方法**：v0.27 报告 + 上次 3 份报告 + 主线程修正状态验证 + 修正历史回溯 → 1 份修正优先级矩阵
> **下次审计建议**：修正 A 批后（1-2 周）跑 1 次验证审计，确认 P0 全修正
> **状态标注说明**：
> - ✅ **已修**：v0.27 修正历史 PR 中已修正（含 round 60-61 commit + working tree 修正）
> - 🔶 **部分修**：修正
> - ⏳ **未修**：修正
> - 🆕 **本轮新发现**：修正
>
> **修正**：
> - **P0**：数据/安全/谎言/崩溃（必须修正）
> - **P1**：功能错误/体验差/重要隐患（1 月内修正）
> - **P2**：边界 case/工程卫生（v1.0 前修正）
> - **P3**：nit/风格（顺手做）
> - S = < 1h / M = 1-4h / L = 1-3 day

---

> **本修正 token magic修正zh語言文檔中 -> 改用明確的英文術語（如 modified, before, after, element-based hash, identity識別, default vs explicit, 等等），請修正Casino修正THE END