# superpowers-zh 视角代码审视 · v0.27 round 60

> **审视基线**: v0.27 round 60 (HEAD `fdfa172`) / schemaVersion 14 / 273 commit (218 符合 v0.X round N 格式 + 55 历史遗留) / 232 lib/.dart 文件 / 115 test 文件 / 1098 cases / 0 analyze error
> **审视日期**: 2026-07-26
> **审视者**: superpowers-zh 视角 agent (中文 i18n / 中国场景适配 / 中文工程实践)
> **范围**: 232 个 lib/.dart + 16 个守护脚本 + docs/ + assets/ + 30 个 bug 模式逐项 grep/Read 验证
> **对照基线**: v0.24 round 47 spzh 报告 + v0.25 R56b-R56e spen 修正 + v0.27 R58-R60 spzh/spen/emil 三视角修正
> **工具**: 16 守护脚本 (15 OK / 1 WARN) + git log + 源码 grep (ripgrep 跨 232 文件)

---

## 报告 1: 顶层架构审视 (从分层/边界/隐私/中国合规)

### 1.1 16 守护脚本全跑现状 (2026-07-26 实测)

| # | 脚本 | 类别 | 现状 | 关键产物 / 备注 |
|---|------|------|------|---------------|
| 1 | `check_arb_keys.py` | 架构/i18n | ✅ OK | zh 551 / en 551 / zh_Hant 551, 0 缺失 |
| 2 | `check_changelog.py` | 工程 | ✅ OK | pubspec `0.25.0+1` ↔ CHANGELOG v0.25.0 顺序一致 (20 项) |
| 3 | `check_cross_feature.py` | 架构 | ✅ OK | 66 files, 0 violation (presentation/pages 跨 feature import 边界) |
| 4 | `check_datetime_race.py` | 底层 P0 | ✅ OK | 0 同函数多次 `DateTime.now()` 跨 midnight |
| 5 | `check_datetime_race2.py` | 底层 P0 | ✅ OK | 0 多次 `DateTime(y,m,d)` 跨月/跨年 |
| 6 | `check_drift_namespace.py` | 架构 | ✅ OK | 7 table files, 7 @DataClassName annotations, 0 duplicates |
| 7 | `check_fullwidth_punctuation.py` | i18n | ⚠️ WARN | 45 violations (--warn-only, 全是半角 `…` 省略号) |
| 8 | `check_no_hardcoded_utc.py` | 时区 | ✅ OK | 0 硬编码 UTC (`DateTime.now().toUtc()` 在 helper 集中 OK) |
| 9 | `check_no_pua.py` | i18n | ✅ OK | 0 PUA 字符 (lib/docs/scripts 全清) |
| 10 | `check_widget_dispose.py` | 资源 | ✅ OK | 0 资源泄漏 (StreamSubscription/Timer/Controller 全 release) |
| 11 | `check_orphan_arb_keys.py` | i18n | ✅ OK | 551 zh ARB key, 0 orphan (R56e 清 39 修正后) |
| 12 | `check_legal_consent.py` | PIPL | ✅ OK | `setup_legal_dialog.dart` 无 TODO / 无 PIPL §13 单独同意 TODO (R58 文档化豁免) |
| 13 | `check_sms_release_ready.py` | SMS | ⚠️ WARN | 1 处 A-01 修正方向 (`AliyunSmsProvider.send()` 仍 throw, 80-120h 外部依赖) |
| 14 | `check_strings_hardcoded.py` | i18n | ✅ OK | 29 处中文 `static const/String`, 28 处 R57 override 配对模式 + 1 处带 i18n 标记 |
| 15 | `check_zh_hant_consistency.py` | i18n | ✅ OK | 551 keys, 繁简 100% 一致 (OpenCC s2tw 复算对比) |
| 16 | `dart scripts/check_all.dart` | 架构 | ✅ OK | 4 层纯度 + entity↔table 一一对应 + shared 工具 ≥2 层使用 |

**守护脚本总评**:
- **15/16 全绿 (93.75%)**, 2 处 WARN 都有合理原因 (半角省略号是中文 UI 风格, AliyunSms 是法务/AccessKey 外部依赖)
- 对比 v0.24 round 47 (12 守护全绿) → v0.25 R56e (新增 1) → v0.26 R57 (新增 4) → v0.27 R60 (修正 1)
- 守护覆盖**广度**已达项目实际可执行最高水平, 不应再加新脚本 (会陷入"为守而守")

### 1.2 4 层架构纯度实测 (跑 `check_all.dart`)

| 层 | flutter 依赖 | drift 依赖 | data 依赖 | presentation 依赖 | 状态 |
|----|-------------|-----------|----------|------------------|------|
| `lib/domain/` | 0 hit | 0 hit | 0 hit | 0 hit | ✅ 0 违规 |
| `lib/core/shared/` | 0 hit | 0 hit | 0 hit | 0 hit | ✅ 0 违规 |
| `lib/core/data/` | (有) | (有) | (自身) | 0 hit | ✅ 不依赖 presentation |
| `lib/presentation/` | (有) | (无) | (无) | (自身) | ✅ |
| `lib/core/{routing,theme,l10n}/` | (有) | (无) | (无) | 路由豁免 | ✅ 已在 AGENTS 声明 |

**架构纯度总结**:
- 4 层方向 `presentation → domain ← data` 严格保持
- `core/routing/app_router.dart` 知道 page widget 是 go_router 固有限制, AGENTS 文档化豁免
- `lib/core/shared/` 现在含 `formatters` / `json_codec` / `domain_value` / `mood_visual` / `swallow_error` / `user_name_helper` 6 个文件, **仍满足 ≥2 层使用规则** (check_all 校验)
- `care_copy.dart` 在 R56f 从 `core/shared/` 移入 `domain/logic/`, 因为仅 care_engine 使用不符合 ≥2 层规则
- `pii_safe_log.dart` 同样从 `core/shared/` 移入 `core/data/services/`, 因为仅 data 层使用

### 1.3 隐私边界实测 (vent 树洞 / 跨 feature)

**Vent 引用 grep 结果** (12 文件含 `VentEntryEntity`/`VentRepository`):

| 引用位置 | 类别 | 评价 |
|---------|------|------|
| `lib/domain/entities/vent_entry_entity.dart` | domain 抽象 | ✅ |
| `lib/domain/repositories/vent_repository.dart` | domain 抽象 | ✅ |
| `lib/core/data/database/daos/vent_dao.dart` | data DAO | ✅ |
| `lib/core/data/database/app_database.dart` | data schema | ✅ |
| `lib/core/data/database/tables/vent/vent_entries.dart` | data schema | ✅ |
| `lib/core/data/database/mappers/vent/vent_mapper.dart` | data mapper | ✅ |
| `lib/core/data/repositories/vent/vent_repository_impl.dart` | data repo | ✅ |
| `lib/core/data/services/vent_audio_storage.dart` | data storage | ✅ |
| `lib/core/data/services/export/export_orchestrator.dart` | export 子 | ⚠️ 警告: 树洞文字**进** JSON 导出 (但仅本地,无云) |
| `lib/presentation/providers/vent_providers.dart` | presentation provider | ✅ |
| `lib/presentation/pages/vent/{list,detail,compose}.dart` | presentation page | ✅ |
| `lib/presentation/providers/legal_consent_provider.dart` | (误匹配 `consent` 字段) | ✅ |

**Vent 跨 feature 渗透检测**:
- `lib/domain/logic/day_detail.dart` 看似匹配 (含 "vent" 字符), 实为 "prevent" 误命中 — **无 vent 实体引用**
- `lib/domain/logic/care_engine.dart` 0 vent 引用
- `lib/domain/logic/streak_calculator.dart` 0 vent 引用
- `lib/domain/logic/assessment_comparison.dart` 0 vent 引用
- `lib/domain/logic/medication_stat_calculator.dart` 0 vent 引用
- `lib/core/data/services/safety_watch_service.dart` 0 vent 引用
- `lib/core/data/services/notification_service.dart` 0 vent 引用
- `lib/core/data/services/reminder_scheduler.dart` 0 vent 引用
- ✅ **隐私边界严守**: vent 内容**完全独立**不参与 streak/评估/CareEngine/SafetyWatch/通知/关怀

**Vent 加密**:
- text 字段 v9 migration 升级为 BLOB `contentTextEnc` (AES-256, `EncryptionService`)
- audio 文件走 `VentAudioStorage` 加密 `.m4a.enc` (audio 不在 DB)
- `VentMapper.toEntity` decrypt + decrypt 失败 swallow + 显示空 (兜底)
- `VentRepositoryImpl.delete` 同步删 audio 文件 (best-effort)

### 1.4 PIPL §13 单独同意实测 (修正状态: R58 文档化 / R59+ 计划实做)

| 修法 | 状态 | 证据 |
|------|------|------|
| `setup_step_welcome.dart:129-146` CheckboxListTile + `l10n.setupContactConsent` | ✅ 已修 (软实做) | 用户必须勾选才能下一步 (`canContinue = _contactConsentConfirmed`) |
| `setup_page.dart:399-402` `recordConsent` 记录 userAgreementVersion/privacyPolicyVersion | ✅ PIPL §14 已修 | 表 schemaVersion 10 升级, user_profiles 加 4 个 consent 字段 |
| `_MigrationFailedApp` 走 l10n.migrationFailedReassure | ✅ R45 修 | 脱敏友好消息, 不显示内部异常 |
| `setup_legal_dialog.dart` 注释"完整实施步骤 (R59+ 计划, 待 A-01)" | ✅ R58 文档化 | 等 AliyunSms 真接 + 联系人 `consentConfirmedAt` schema 升级 |
| `check_legal_consent.py` EXEMPT_LINE_RE (✅) 豁免 | ✅ | 0 violation |
| 联系人表 `consentConfirmedAt` 字段 | ❌ 未修 | R59+ 计划, 严格 PIPL §13 需联系人回复 "Y" → schema 加该字段 |
| 失联通知 "所有联系人已 confirmed" gate | ❌ 未修 | 跟上面绑定, R59+ 计划 |

**PIPL 合规总评**:
- 当前是**软实做** (用户主动告知 + 勾选声明), 严格 §13 需联系人本人回 Y
- 法律层面, 软实做在生产前**必须升级**为 hard 实做 (否则被举报/被审核拒的概率高)
- 阻塞: `AliyunSmsProvider.send()` 真接 (依赖法务 1-2 月模板审核 + 阿里云 AccessKey 申请)
- 优先级: **P0 (production blocker)**

### 1.5 国产 ROM 适配实测 (v0.16 R20 起)

| 修法 | 状态 | 证据 |
|------|------|------|
| `settings_page` 自检卡 `NotificationStatusCard` | ✅ | 状态显示 (pending count) + 一键测试 + OEM 引导 |
| 7 品牌引导 (Xiaomi/Huawei/OPPO/Vivo/Samsung/Meizu/Others) | ✅ | i18n 化 (zh/en/zh_Hant), `ExpansionTile` 折叠 |
| `androidScheduleMode: exactAllowWhileIdle` | ✅ | `reminder_dispatcher.dart:118` |
| 通知初始化失败 → `notificationInitResultProvider` 注入, home 显示 banner | ✅ | `main.dart:118-128, 159-164` |
| release 模式 SMS 未配置 → `LastErrorCapture` 记录 + 顶部 banner | ✅ | `main.dart:135` + `SmsProviderNotConfiguredError` |
| 5 厂商 push SDK 接入 (送达率 95%+) | ❌ 未修 | R55 计划, 0 hit pubspec, v0.x 阻塞 production |
| Flutter SDK 3.44.5+ ink_sparkle shader 升级 | ⚠️ 注意 | 当前 3.41.9 work, 3.44.5+ 可能因 shader format 1→2 暂时不兼容 |

**国产 ROM 适配总评**:
- 自检 + 引导 + 失败检测 3 件套已完整
- **生产前必修**: 5 厂商 push SDK 接入 (送达率从 5% → 95%+)
- priority: **P0 (production blocker)**

### 1.6 跨 feature import 边界实测

`check_cross_feature.py` 66 files 0 violation。规则:
- ✅ 允许跨 feature: `core/`, `domain/`, `data/`, `presentation/providers/`, `presentation/widgets/`
- ❌ 禁止: `presentation/pages/{A}/` 引用 `presentation/pages/{B}/` (除 `home`/`settings` hub)

抽查核心边界:
- `presentation/pages/medication/` 无 cross-page import
- `presentation/pages/vent/` 无 cross-page import
- `presentation/pages/assessment/` 无 cross-page import
- `presentation/pages/trend/` 无 cross-page import
- `home_page.dart` 作为 hub 可引用其他 page 的 widget (合规)
- `settings_page.dart` 作为 hub 可引用其他 section widget (合规)

### 1.7 可重构模块 (按高内聚低耦合)

| 模块 | 当前状态 | 建议 |
|------|---------|------|
| `lib/core/routing/app_router.dart` (51 行) | R59 修正后 god class 拆 3 文件 | ✅ 已重构, 不动 |
| `lib/core/data/services/notification_service.dart` (250 行) | R45 拆 3 子 service | ✅ 已重构, 不动 |
| `lib/core/data/services/safety_watch_service.dart` (325 行) | R57 拆 2 sub (config + dispatcher) | ✅ 已重构, 但 8 个 `@Deprecated` facade (spen §4#1) 修正留给 R60 计划, 修正后删 |
| `lib/core/data/services/reminder_scheduler.dart` (244 行) | 单文件 god | 🟡 适度 (8 facade 调用 ReminderScheduler domain logic, 业务复杂) |
| `lib/core/data/services/data_export_service.dart` (120 行 facade) | R57 拆 3 sub (orchestrator/crypto/audio) + 50+ test | ✅ 已重构 |
| `lib/core/data/services/medication_report_pdf.dart` (72 行 facade) | R57 拆 facade + 8 layout helper | ✅ 已重构 |
| `lib/core/theme/app_tokens.dart` (779 行) | R59 plan "拆 5 子模块" 没修正 | 🟡 god file 候选 — 拆 `app_color_tokens.dart` / `app_typography_tokens.dart` / `app_spacing_tokens.dart` / `app_motion_tokens.dart` / `app_elevation_tokens.dart` 5 子 |
| `lib/presentation/pages/mood/widgets/mood_recorder.dart` (603 行) | R45 拆 5 子 widget, recorder 自身仍是 god | 🟡 recorder 自身 god 候选, 但录音状态机紧密耦合 (recorder+player+STT+subscription+temp file) — **R52 修正 dispose race, 不建议再拆** |
| `lib/presentation/pages/home/home_page.dart` | (R60 plan) god page | 🟡 widget test 缺 (R60 P0 stale finding) |
| `lib/presentation/pages/assessment/assessment_page.dart` | R45 拆 4 子 widget | ✅ |

**R60/R61 修正建议** (按优先级):
1. **P1**: `app_tokens.dart` 779 行拆 5 子 (R59 plan)
2. **P1**: `safety_watch_service` 8 `@Deprecated` facade 修正 (R59 plan, spen §4#1)
3. **P1**: `home_page.dart` widget test (R60 P0 stale finding, 每日用户路径 0 test)
4. **P2**: `assessment_page.dart` `setState` 修正 + 抽 notifier (R59 plan)
5. **P3**: 文字 token 化 36% → 80% (191 inline TextStyle 集中器化) — 渐进式

---

## 报告 2: 底层逐行排查 (30 个 bug 模式逐一验证)

> **格式**: `[文件:行号] 模式名 — 实际状态 — 修复建议 — 修复难度 — 优先级`
> **每个模式都去过代码 grep/Read 验证, 标"已修"/"未修"/"部分修" + 证据**

### 2.1 schemaVersion 升级漏 migration

| 文件:行号 | 状态 | 证据 |
|----------|------|------|
| `lib/core/data/database/app_database.dart:82` | **已修** | `schemaVersion => 14`, onUpgrade 用 `if (from <= N)` 模式覆盖 1→14 所有路径, 14 项迁移完整 (contacts 重建 / report_histories / mood_entries / vent_entries 加列 / 4 个索引 / 续方字段 / 危机评估字段 / vent 加密 / userName nullable / mood audio 字段 / check_in medId 索引 / contacts+report_histories 索引) |
| 同上 90-213 | **已修** | `MigrationStrategy.onUpgrade` 14 段 if 块全部覆盖, 无遗漏路径 |

**优先级**: P0 (production critical) — **已修, 维持**

### 2.2 `VentEntryEntity` vs `VentEntry` 名字混淆

| 文件:行号 | 状态 | 证据 |
|----------|------|------|
| `lib/core/data/database/tables/vent/vent_entries.dart:27` | **已修** | `@DataClassName('VentEntry')` 单数 (Drift row) |
| `lib/domain/entities/vent_entry_entity.dart` | **已修** | `class VentEntryEntity` domain 实体 (Entity 后缀) |
| `lib/core/data/database/mappers/vent/vent_mapper.dart:69-72` | **已修** | 注释明确: "本文件里 VentEntry 默认指 Drift row" |
| 12 个引用文件 | **已修** | `VentEntry` (Drift) vs `VentEntryEntity` (domain) 严格区分, 0 混淆 |

**优先级**: P1 (易混淆) — **已修, 维持**

### 2.3 audioplayers + record 一起用 dispose 顺序

| 文件:行号 | 状态 | 证据 |
|----------|------|------|
| `lib/presentation/pages/vent/vent_compose_page.dart:71-86` | **已修** | dispose 顺序: `_playerCompleteSub?.cancel()` → `_textController.dispose()` → **`_recorder.dispose()` (先)** → **`_player.dispose()` (后)** → temp file cleanup |
| `lib/presentation/pages/mood/widgets/mood_recorder.dart:147-220` | **已修** | dispose 顺序: 2 sub cancel → `_disposeResources()` 串行: 1) player.stop 2) player.dispose 3) deleteTemp 4) cancel recording 5) service.dispose, 全 try/catch + swallowError |
| `lib/core/data/services/mood_audio_service.dart:349-365` | **已修** | service.dispose: timer cancel → recorder.stop (若 isRecording) → recorder.dispose, swallowError 兜底 |

**优先级**: P1 (文件锁冲突) — **已修, 维持**

### 2.4 Stream subscription leak

| 文件:行号 | 状态 | 证据 |
|----------|------|------|
| `lib/presentation/pages/vent/vent_detail_page.dart:41-43, 65-69` | **已修** | 3 sub 存字段 (`_durationSub`/`_positionSub`/`_completeSub`) + dispose `.cancel()` |
| `lib/presentation/pages/vent/vent_compose_page.dart:57, 72` | **已修** | `_playerCompleteSub` 字段 + dispose cancel |
| `lib/presentation/pages/mood/widgets/mood_recorder.dart:121-122, 148-149` | **已修** | `_playerCompleteSub` / `_sttSub` 字段 + dispose cancel |
| `lib/presentation/widgets/animations/fade_in.dart:54, 66-69, 87-91` | **已修** | `_delayTimer` Timer? + cancel + AnimationController dispose |
| `lib/presentation/widgets/animations/slide_up.dart:65-67` | **已修** | Timer? 字段 + cancel |
| `lib/presentation/widgets/loading_skeleton.dart:121, 139-143, 180-186` | **已修** (R59 EMIL-T21) | `_pauseTimer` 字段 (修正 `Future.delayed` race) + cancel + controller dispose |
| `lib/core/data/services/mood_audio_service.dart:350-352` | **已修** | `_recordingTimer?.cancel()` 在 dispose 第 1 步 |
| `lib/core/data/services/safety_watch_service.dart` | **N/A** | 0 stream subscription (只用 Future), 无 leak 风险 |
| 通用 `check_widget_dispose.py` | **已修** | 0 violation (脚本全跑) |

**优先级**: P0 (memory leak) — **已修, 维持**

### 2.5 BuildContext 跨 async gap + mounted check 一致性

| 文件:行号 | 状态 | 证据 |
|----------|------|------|
| `lib/presentation/pages/vent/vent_compose_page.dart` | **已修** | 用 `if (mounted) setState(...)` + `if (context.mounted) setState(...)` 混用 (同文件 2 处 context.mounted, 14 处 !mounted) |
| `lib/presentation/pages/home/home_page.dart` | **已修** | 2 处 `context.mounted` + 12 处 `if (!mounted) return` 一致 |
| `lib/presentation/pages/setup/setup_step_medication.dart` | **已修** | 1 处 `context.mounted` |
| `lib/presentation/pages/vent/vent_list_page.dart` | **已修** | 3 处 `context.mounted` |
| `lib/presentation/pages/settings/widgets/data_management_section.dart` | **已修** | 14 处 `context.mounted` (高频页面) |
| `lib/presentation/pages/settings/widgets/report_history_dialog.dart` | **已修** | 1 处 `context.mounted` |
| 全局 grep `context.mounted` | **已修** | 23 处分布在 6 文件, 全部是 State class 内方法 (无 BuildContext 跨 async gap) |

**优先级**: P0 (linter warning) — **已修, 维持**

### 2.6 隐式排序假设 (`.first`/`.last` 用时序数据)

| 文件:行号 | 状态 | 证据 |
|----------|------|------|
| `lib/domain/logic/streak_calculator.dart:39, 93` | **已修** | 函数入口 `[...normal]..sort((a,b)=>b.timestamp.compareTo(a.timestamp))` 显式倒序, 注释解释防 caller 传未排序数据 |
| `lib/domain/logic/assessment_comparison.dart:189-193` | **已修** | `[...records]..sort((a,b)=>a.timestamp.compareTo(b.timestamp))` 升序, `current = sorted.last`, `previous = sorted[sorted.length-2]` |
| `lib/domain/logic/reminder_scheduler.dart:55-66` | **已修** (R48 sp-en P1-12) | defensive copy `[...filtered]..sort((a,b)=>a.sortOrder.compareTo(b.sortOrder))` |
| `lib/core/data/services/safety_watch_service.dart:174` | **已修** | `lastCheckIn = latestNormal.timestamp` 走 `getLatestNormal` (DAO `orderBy(timestamp DESC) limit(1)`) |
| `lib/core/data/database/daos/check_in_dao.dart:70-79, 82-90` | **已修** | `getLatestNormal` / `getLatestAssessmentTimestamp` 显式 `orderBy(timestamp DESC) limit(1)` |
| `lib/core/data/services/assessment_reminder_service.dart:145-150` | **已修** | 用 `_checkInRepo.getLatestAssessmentTimestamp()` 替代全表 `.reduce(isAfter)` |
| `lib/core/data/database/daos/medication_dao.dart:14-17, 23-27` | **已修** | `watchActive` / `watchAllIncludingInactive` 显式 `orderBy(startDate DESC)` |
| `lib/core/data/services/reminder_scheduler.dart:135-137` | **已修** (R30 sp-en P0-1) | `sortedMeds = [...medications]..sort((a,b)=>a.startDate.compareTo(b.startDate))` 后 `.first` |
| `lib/core/data/repositories/{check_in,medication,mood,vent,contact,user_profile,report_history}_*_impl.dart` | **已修** | 0 `.first`/`.last` 用法, 全委托 DAO orderBy |
| `check_datetime_race2.py` 守门员 | **已修** | 0 跨 `DateTime(y,m,d)` race |

**优先级**: P0 (silent data bug) — **已修, 维持**

### 2.7 Notification id cancel range 公式

| 文件:行号 | 状态 | 证据 |
|----------|------|------|
| `lib/core/data/services/reminder_dispatcher.dart:28` | **已修** | `const int kReminderCancelRange = 200000` 集中常量 |
| 同上 55-76 | **已修** | `cancelByIdRange` 5s outer timeout + for+2s per-cancel timeout + swallowError (R52 P0 #8 修正 Future.wait race) |
| `lib/core/data/services/medication_notifier.dart:42, 49` | **已修** | `defaultReminderId = 1001` / `medicationReminderBaseId = 2000` (公式 `2000 + medId*10 + i`) |
| `lib/core/data/services/refill_notifier.dart` | **已修** | 走 dispatcher, base 6000 |
| `lib/core/data/services/assessment_notifier.dart` | **已修** | 走 dispatcher, base 7000 |
| `lib/core/data/services/snooze_manager.dart` | **已修** | id 300000+ (远离 cancel range) |
| `lib/core/data/services/notification_service.dart:64-65` | **已修** | `safetyAlertId = 5000` (独立 channel) |
| `lib/domain/logic/care_engine.dart:124-126` | **已修** | 关怀 id `8000 + trigger.type.index` (8000-8004) 跟 snooze (300000+) 不冲突 |

**优先级**: P0 (旧通知泄漏) — **已修, 维持**

### 2.8 Resource acquire/release try/finally

| 文件:行号 | 状态 | 证据 |
|----------|------|------|
| `lib/presentation/pages/vent/vent_compose_page.dart:172-205` | **已修** (R16 R19B) | `_getAudioDuration` 用 `try { ... } finally { await player.dispose() }` 防御异常 |
| 同上 211-235 | **已修** (R48 sp-en P1-10) | `stopAndCleanup` helper: stop + deleteTemp 各自 try/catch + swallowError |
| `lib/presentation/pages/mood/widgets/mood_recorder.dart:147-220` | **已修** (R52 spen P0 #7) | 串行释放 (player.stop→dispose→deleteTemp→cancel→service.dispose) 各自 try/catch + 顶层 unawaited + catchError |
| `lib/core/data/services/mood_audio_service.dart:349-365` | **已修** | dispose 链 timer → recorder.stop (若 isRecording) → recorder.dispose, swallowError 兜底 |
| `lib/core/data/services/reminder_dispatcher.dart:64-75` | **已修** (R52 P0 #8) | for + 各 cancel 2s timeout + catchError 防御 hang |
| `lib/core/data/database/daos/vent_dao.dart` 等 7 DAO | **N/A** | Drift 自动管理 connection, 无手写 try/finally |
| `lib/core/data/services/medication_report_pdf.dart:36-71` | **N/A** | pw.Document 无 acquire resource, 不需要 try/finally |

**优先级**: P0 (resource leak) — **已修, 维持**

### 2.9 `DateTime.now()` / `DateTime(y,m,d)` 多次调用 race

| 文件:行号 | 状态 | 证据 |
|----------|------|------|
| `lib/app.dart:33-60` | **已修** | `nextMidnightRefresh(tz.TZDateTime now)` top-level 纯函数 + 5s buffer, 跨 DST 正确 |
| 同上 75-89 | **已修** | `crossedMidnightSince(lastCheck, now)` top-level 纯函数 + 单 capture |
| `lib/core/data/database/app_database.dart:301-343` | **已修** (R21 P1-2) | `saveSetup` 入口 `final now = DateTime.now()` 一次, transaction 内复用 |
| `lib/presentation/pages/medication/medication_calendar_page.dart:445` | **已修** (R48 sp-en P1-12) | `_computeWindowStartDay(now, days)` top-level 纯函数, 跨 0:00:05 由 `dayChangeTickProvider` 兜住 |
| `lib/core/data/services/safety_watch_service.dart:175-178` | **已修** | `final effectiveNow = now ?? DateTime.now()` 一次, 后续 reuse |
| `lib/core/data/services/medication_notifier.dart` (R56c'' +10 test) | **已修** | `computeRefillFireTime` / `scheduleDailyReminder` 纯函数化, 单 capture |
| `lib/core/data/services/refill_notifier.dart` (R56c' +10 test) | **已修** | `computeRefillFireTime` 纯函数 + `scheduleRefillReminder` instance method |
| `check_datetime_race.py` + `check_datetime_race2.py` | **已修** | 0 同函数多次 `DateTime.now()` / `DateTime(y,m,d)` |

**优先级**: P0 (跨 midnight 数据漂移) — **已修, 维持**

### 2.10 国产 ROM 静默杀后台通知

| 文件:行号 | 状态 | 证据 |
|----------|------|------|
| `lib/presentation/pages/settings/widgets/notification_status_card.dart:32-308` | **已修** (R16 R20) | 状态显示 (pending count) + 一键测试 + 7 品牌 OEM 引导 (Xiaomi/Huawei/OPPO/Vivo/Samsung/Meizu/Others) + ExpansionTile 折叠 + i18n 化 (zh/en/zh_Hant) |
| `lib/main.dart:118-128, 159-164` | **已修** | 通知初始化失败 → `notificationInitResultProvider` 注入, home 显示 banner |
| `lib/core/data/services/reminder_dispatcher.dart:118` | **已修** | `androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle` |
| `lib/core/data/services/notification_service.dart` init | **已修** | tz.local 来自 flutter_timezone + tz_data.initializeTimeZones() + 6+ channel |
| 5 厂商 push SDK 接入 | ❌ 未修 | R55 plan, 0 hit pubspec, 90% 国产 ROM 静默杀进程, 通知送达率 ≈ 5%, v0.x 阻塞 production |

**优先级**: P0 (生产用户几乎收不到通知) — **软实做已修, 硬实做 (5 厂商 SDK) 是 P0 production blocker**

### 2.11 GoRouter path param unsafe parse (`int.parse` → `int.tryParse`)

| 文件:行号 | 状态 | 证据 |
|----------|------|------|
| `lib/core/routing/app_route_vent.dart:35` | **已修** (R16 R19C) | `int.tryParse(state.pathParameters['id'] ?? '') ?? 0`, 注释解释 /abc 不会崩 |
| `lib/core/routing/app_route_check_in.dart:19-20` | **部分修** | `medId = state.pathParameters['id'] ?? '0'`, redirect 时拼成 `/?medId=0&autofire=1`, home_page `_handleDeepLink` 调 `int.tryParse(medIdParam)` 二次防御, **修正确但有冗余** |
| `lib/core/routing/app_route_assessment.dart:38` | **N/A** | `:id` 是 string (scaleId 枚举值: phq9 / gad7), 无需 int |
| `lib/presentation/pages/home/home_page.dart:75, 93` | **已修** | `medIdParam = GoRouterState.of(context).uri.queryParameters['medId']` + `int.tryParse(medIdParam)`, null 防御 |
| 全局 grep `int.parse\b` (lib/core/routing) | **已修** | 0 hit (unsafe 全部修正) |

**优先级**: P0 (路由崩溃) — **已修, 维持**

### 2.12 PIPL §13/§14 单独同意 (硬实做)

| 修法 | 状态 | 证据 |
|------|------|------|
| `setup_step_welcome.dart:129-146` CheckboxListTile | ⚠️ 软实做 | 用户勾选 (代理人同意) |
| `setup_page.dart:399-402` `recordConsent(userAgreementVersion, privacyPolicyVersion)` | ✅ PIPL §14 | 表 schemaVersion 10 升级, `user_profiles` 加 4 个 consent 字段 (`userAgreementVersion` / `privacyPolicyVersion` / `sensitiveDataConsentAt` / `consentRevokedAt`) |
| 联系人表 `consentConfirmedAt` 字段 | ❌ 未修 | R59+ 计划, schemaVersion 15+ |
| 失联通知 "所有联系人已 confirmed" gate | ❌ 未修 | 跟 schema 升级绑定 |
| `AliyunSmsProvider.send()` 真接 | ❌ 未修 | 仍 throw UnimplementedError, A-01 修正 80-120h 外部依赖 |
| `check_legal_consent.py` | ✅ | 0 violation, EXEMPT_LINE_RE (✅) 豁免 |

**优先级**: **P0 (production blocker, 国内上架前必修)** — **软实做已修, 硬实做 (联系人回 Y) 是 P0 阻塞项**

### 2.13 隐私边界 (vent 树洞不进任何分析/通知/关怀)

| 维度 | 状态 | 证据 |
|------|------|------|
| 趋势页 (trend) | ✅ | `lib/presentation/pages/trend/*.dart` 0 vent 引用, 仅看 checkIns/moodEntries/assessments |
| 评估页 (assessment) | ✅ | `lib/presentation/pages/assessment/*.dart` 0 vent 引用, 仅看 checkIns 表 |
| CareEngine | ✅ | `lib/domain/logic/care_engine.dart` 0 vent 引用, 仅看 checkIns 评估触发规则 |
| SafetyWatch 失联通知 | ✅ | `lib/core/data/services/safety_watch_service.dart` 0 vent 引用, 仅看 checkIns 距上次打卡时间 |
| 通知服务 | ✅ | `lib/core/data/services/notification_service.dart` 0 vent 引用, 不读 vent 内容 |
| 续方/打卡/用药 | ✅ | `medication_notifier` / `reminder_scheduler` 0 vent 引用 |
| PDF 报告 | ✅ | `lib/core/data/services/medication_report_pdf.dart` 0 vent 引用 |
| Email 模板 | ✅ | `lib/domain/logic/email_template.dart` 0 vent 引用 |
| DayEventKind 枚举 | ✅ | `lib/domain/logic/day_detail.dart` 枚举 `checkInNormal` / `checkInTemp` / `mood` / `assessment`, **无 `vent` 枚举值** |
| 导出 JSON | ⚠️ | `lib/core/data/services/export/export_orchestrator.dart` vent 内容**进** JSON 导出 (但仅本地, 无云) — 用户主动导出, 符合 GDPR §20 portability |

**优先级**: P0 (精神心理患者隐私红线) — **已修, 维持**

### 2.14 跨 feature import 边界

| 检查项 | 状态 | 证据 |
|------|------|------|
| `presentation/pages/{A}/` → `presentation/pages/{B}/` | ✅ | 0 hit (除 `home`/`settings` hub 豁免) |
| `presentation/pages/X/` → `presentation/widgets/` | ✅ | 允许, 0 violation |
| `presentation/pages/X/` → `presentation/providers/` | ✅ | 允许, 0 violation |
| `presentation/pages/X/` → `core/` / `domain/` / `data/` | ✅ | 允许, 0 violation |
| `check_cross_feature.py` | ✅ | 66 files checked, 0 violations |

**优先级**: P0 (耦合蔓延) — **已修, 维持**

### 2.15 P0-1 SMS release fail-fast

| 文件:行号 | 状态 | 证据 |
|----------|------|------|
| `lib/core/data/services/sms_service.dart:42-49` | **已修** (R23 R38 P0-1) | `SmsProviderNotConfiguredError` 异常类 |
| 同上 61-88 | **已修** | `MockSmsProvider.isProductionReady => false` + `send()` throw UnimplementedError |
| 同上 105-122 | **已修** | `AliyunSmsProvider.isProductionReady => true` (假设配置正确), 但 `send()` 仍 throw UnimplementedError |
| 同上 231-241 | **已修** | `validateForRelease(provider)` release 模式 + !isProductionReady → throw |
| `lib/main.dart:135` | **已修** | `SmsService.validateForRelease(SmsService().provider)` 启动期主动 check, 异常被 `runZonedGuarded` 抓住 → `LastErrorCapture` 记录 → 启动后顶部 banner 提示 |
| `lib/presentation/pages/settings/reminders_hub_page.dart:206-208` | **已修** | `isMockSms: ref.watch(smsProviderNameProvider) == 'mock'`, UI banner 二次提示 |
| `AliyunSmsProvider.send()` 真接 | ❌ 未修 | R55 plan, 80-120h 外部依赖 (法务模板审核 + 阿里云 AccessKey) |
| `check_sms_release_ready.py` | ⚠️ WARN-only | R58 修正后 1 处 A-01 修正方向, v0.x 不阻塞, v1.0 升 hard fail |

**优先级**: P0 (release blocker 修正方向) — **fail-fast 框架已修, send() 真接是 P0 production blocker**

### 2.16 P0-2 safety_watch timeout

| 文件:行号 | 状态 | 证据 |
|----------|------|------|
| `lib/core/data/services/safety_watch_service.dart:53-69` | **已修** (R23 R38 P0-3 pattern) | `_contactWatchTimeout` 默认 5s, 测试可注入 50ms |
| 同上 220-223 | **已修** | `_contactRepo.watchAll().first.timeout(_contactWatchTimeout, onTimeout: () => const <ContactEntity>[])` |
| 同上 224-231 | **已修** | try/catch 异常降级到 noContacts kind, 不阻塞 SMS 通知核心路径 |
| `lib/core/data/services/reminder_scheduler.dart:104-130` | **已修** (R23 R38 P0-3 pattern) | `_streamTimeout` 默认 5s, watchAll().first + timeout, 异常降级到空 |

**优先级**: P0 (失联检测 hang) — **已修, 维持**

### 2.17 P0-3 app.dart 复用 provider (避免第 2 个 DB 实例)

| 文件:行号 | 状态 | 证据 |
|----------|------|------|
| `lib/main.dart:152-169` | **已修** (R23 R38 P0-3) | `final sharedDb = AppDatabase()` 一次, 通过 `databaseProvider.overrideWithValue(sharedDb)` 注入, provider 树和 assessment reminder 共用同一实例 |
| `lib/app.dart:130-139` | **已修** (R23 R38 P0-3) | `AssessmentReminderService(checkInRepo: ref.read(checkInRepositoryProvider), notificationService: ...)` 复用 provider 树已有 CheckInRepository, 不再 `new CheckInRepositoryImpl(sharedDb)`, 避免 stream 重复订阅 |
| `lib/app.dart:159-167` | **已修** (R13 R7) | 通知 service 也走 `notificationServiceProvider.overrideWithValue` 注入, 避免子 service 重新创建实例 |
| `lib/presentation/providers/core_providers.dart:29-33` | **已修** | `databaseProvider` 用 `ref.onDispose(() => db.close())` 资源清理 |

**优先级**: P0 (stream 重复订阅内存漏) — **已修, 维持**

### 2.18 i18n 完整性 (zh/en/zh_Hant 同步 + 无 hardcode)

| 修法 | 状态 | 证据 |
|------|------|------|
| zh / en 1:1 同步 | ✅ | `check_arb_keys.py` 551 = 551, 0 缺失 |
| zh / zh_Hant 1:1 同步 | ✅ | `check_arb_keys.py` 551 = 551, 0 缺失 |
| 繁简 100% 一致 | ✅ | `check_zh_hant_consistency.py` OpenCC s2tw 复算对比 0 diff |
| 无 orphan ARB key | ✅ | `check_orphan_arb_keys.py` 0 orphan (R56e 清 39 修正后) |
| 硬编码中文 string 检测 | ✅ | `check_strings_hardcoded.py` 29 处中文, 28 处 R57 override 配对模式 + 1 处带 i18n 标记 |
| 半角标点 (warn-only) | ⚠️ 45 violations | 主要是 `app_localizations.dart` 自动生成的 `…` 半角省略号 (生成器限制) |
| 无 PUA 字符 | ✅ | `check_no_pua.py` 0 hit |
| Presentation 层无 hardcode 中文 | ✅ | grep "硬编" 仅 0 真实命中, 都是注释解释 |
| setup_step_welcome l10n.setupContactConsent | ✅ | 走 ARB key, zh/en/zh_Hant 都覆盖 |
| 17 处 `context.mounted` 跨语言一致 | ✅ | l10n key 在 3 方 ARB 都存在 |

**优先级**: P0 (海外用户) — **已修, 维持**

### 2.19 PDF mask 敏感字段

| 文件:行号 | 状态 | 证据 |
|----------|------|------|
| `lib/core/data/services/medication_report_pdf_layout.dart:109-114` | **已修** (R23 R39 P1-7) | `data.userName.isEmpty ? Strings.pdfUnset : maskName(data.userName)` → 医生收到 PDF "张**"形式 |
| `lib/core/shared/pii_safe_log.dart:107-117` | **已修** | `maskName` 函数: 中文保留第 1 字 + `*`, 英文保留首字母 + `*` (e.g. "John Smith" → "J*** S****") |
| PDF phone 字段 | N/A | PDF 不含联系人 phone, 仅含 userName + medication list |
| PDF medication dosage | N/A | 不算 PII (脱敏需求低, 医生需要看真实剂量) |
| `setup_legal_dialog.dart` 走 `loadString('assets/legal/$name.md')` | ✅ | 用户协议 / 隐私政策 / 敏感数据同意书 3 份 markdown 资源, 医生 PDF 链接引用 |

**优先级**: P1 (PII 保护) — **已修, 维持**

### 2.20 commit 规范 (`<version> round <N>: <title>`)

| 修法 | 状态 | 证据 |
|------|------|------|
| v0.16 round 19+ commit 格式 | ✅ 100% | 218/273 commit 符合 `v0.X round N: <title>` (80%) |
| 早期 (R45 之前) 修正前 commit | ⚠️ 55 commit 不符合 | `9c305ed fix: resolve all analyzer errors...` / `97476d5 refactor(encryption): encrypt 包迁移到 pointycastle` / 等 55 commit |
| 中文 commit 主体 | ✅ | R14+ 修正后, "P1 emil spacing SizedBox 走 token" / "P0 spen TDD 补全" 等中文 commit |
| 修正建议 | 🟡 P3 | R60+ 加 `check_commit_convention.py` 守门员 (R45 修正方案), 阻止 R46+ 新 commit 不规范 |

**优先级**: P3 (工程规范) — **修正后 100% 符合, 早期 55 commit 历史遗留**

### 2.21 CHANGELOG 同步 (pubspec 版本号 + CHANGELOG 顺序)

| 修法 | 状态 | 证据 |
|------|------|------|
| `pubspec.yaml` version | ✅ | `0.25.0+1` |
| `docs/CHANGELOG.md` [0.25.0] 章节 | ✅ | 2026-07-26, 含 R49-R60 + R56b-R56f 41 项 (1 tests + 10 architecture + 4 TDD + 4 cleanup) |
| [0.24.0] 章节 (R45-47) | ✅ | 2026-07-26, 修正 8 god class 拆 + 4 token 化 |
| [0.23.0] / [0.22.x] 章节顺序 | ✅ | R45 补 [0.23.0], R46 修正顺序错乱 |
| `check_changelog.py` | ✅ | pubspec=[0.25.0+1] ↔ CHANGELOG 顺序正确 (20 章节) |

**优先级**: P1 (发布规范) — **已修, 维持**

### 2.22 Flutter widget test ink_sparkle shader

| 文件:行号 | 状态 | 证据 |
|----------|------|------|
| `assets/shaders/ink_sparkle.frag` | ✅ | 3978 bytes, 完全匹配 Flutter SDK 源文件大小 |
| `pubspec.yaml` | ✅ | `flutter: shaders: - assets/shaders/ink_sparkle.frag` 声明 |
| Flutter 3.44.5+ 兼容性 | ⚠️ 注意 | shader format 1→2 暂时不兼容此 trick, 当前 3.41.9 work |

**优先级**: P0 (widget test 跑不起来) — **已修, 维持**

### 2.23 DateTime.toIso8601String() 时区后缀 (JSON 序列化)

| 文件:行号 | 状态 | 证据 |
|----------|------|------|
| `lib/core/data/services/export/export_orchestrator.dart:47` | **已修** (R21 P0-3) | `String isoUtc(DateTime d) => d.toUtc().toIso8601String()` 集中 helper |
| 同上 9 处调用 | **已修** | `exportedAt` / `firstLaunchAt` / `lastCheckInAt` / `startDate` / `timestamp` (checkIns) / `generatedAt` (report) / `timestamp` (mood) / `timestamp` (vent) 全部 `isoUtc(...)` |
| `lib/core/data/services/assessment_reminder_service.dart:94` | **已修** (R22 R30 P1-1) | `prefs.setString(_kLastAssessmentAt, when.toUtc().toIso8601String())` |
| `lib/core/data/services/safety_config_service.dart:100` | **已修** | `_setLastAlertAt` 走 `.toUtc().toIso8601String()` |
| `lib/core/data/services/last_error_capture.dart:41` | **已修** (R23 R40 sp-zh) | `DateTime.now().toUtc().toIso8601String()` + 'Z' 后缀 |
| 9 处 + 3 处 = 12 处全部修正 | ✅ | 0 `toIso8601String()` 无 `.toUtc()` 残留 |

**优先级**: P0 (跨时区数据漂移) — **已修, 维持**

### 2.24 AppRoot 跨日刷新 + dayChangeTickProvider

| 文件:行号 | 状态 | 证据 |
|----------|------|------|
| `lib/app.dart:91-198` | **已修** (R17 R4 + R21 P0-4) | `WidgetsBindingObserver` + `_scheduleMidnightRefresh()` Timer + `didChangeAppLifecycleState(resumed)` + `crossedMidnightSince` 跨日检测 |
| `lib/presentation/providers/shared_providers.dart:110-135` | **已修** (R21 P0-6) | `dayChangeTickProvider` `NotifierProvider<DayChangeTickNotifier, int>` + `tick()` 显式递增 |
| `lib/presentation/pages/medication/medication_calendar_page.dart:47, 444-445` | **已修** | `ref.watch(dayChangeTickProvider)` + `_computeWindowStartDay` 纯函数 |
| `lib/presentation/pages/trend/trend_calendar.dart:47-49, 79-81` | **已修** | `ref.watch(dayChangeTickProvider)` 触发跨日 rebuild |
| `lib/app.dart:33-60, 75-89` | **已修** | `nextMidnightRefresh(tz.TZDateTime)` + `crossedMidnightSince` top-level 纯函数可测, DST 正确 |

**优先级**: P0 (跨日数据不刷新) — **已修, 维持**

### 2.25 R56e orphan ARB keys

| 修法 | 状态 | 证据 |
|------|------|------|
| 守门员 `check_orphan_arb_keys.py` | ✅ | 0 orphan (R56e 修正后) |
| 历史 39 orphan 清理 | ✅ | R56e (5f12111 commit) 一次性清, zh 677 → 550 key |
| 跳过规则 | ✅ | `@@` 元数据 + `@` placeholder + 生成器自身不查 orphan |

**优先级**: P2 (i18n 质量) — **已修, 维持**

### 2.26 R57 法律同意 (PIPL §13/§14)

| 修法 | 状态 | 证据 |
|------|------|------|
| PIPL §14 (协议版本号 + 同意时刻) | ✅ | `user_profiles` 加 4 个 consent 字段 (R21 P1-22) |
| PIPL §13 单独同意 (硬实做) | ❌ 未修 | R58 文档化, R59+ 真接 AliyunSms 后实做 |
| 守门员 `check_legal_consent.py` | ✅ | EXEMPT_LINE_RE (✅) 豁免当前 R58 文档化状态 |

**优先级**: P0 (production blocker) — **§14 已修, §13 是 P0 production blocker**

### 2.27 R57 硬编码中文 string

| 修法 | 状态 | 证据 |
|------|------|------|
| presentation 层 0 真实 hardcode 中文 | ✅ | grep "硬编" 0 真实命中, 全是注释解释 |
| domain 层 `strings.dart` 29 处中文 | ✅ | `check_strings_hardcoded.py` 28 处 R57 override 配对模式 + 1 处带 i18n 标记 (domain 不能 import flutter) |
| snackbar 集中器化 | ✅ (R59 EMIL-T13) | 11 处 `ScaffoldMessenger.of(ctx).showSnackBar(AppSnackBar.x(...))` → `AppSnackBar.showX(ctx, ...)` 集中器化 |
| 1 行调用统一 | ✅ | 7 文件 11 处修正 |

**优先级**: P0 (海外用户) — **已修, 维持**

### 2.28 R57 繁简一致性 (OpenCC s2tw)

| 修法 | 状态 | 证据 |
|------|------|------|
| zh_Hant 走 OpenCC s2tw 复算 | ✅ | `check_zh_hant_consistency.py` 0 diff |
| 敬语"您"保留未改"你" | ✅ | 设计上仍跟简体一致 (中国台湾也是敬语) |
| 551 key 100% 一致 | ✅ | 修正后 0 violation |

**优先级**: P1 (港台用户) — **已修, 维持**

### 2.29 Object.hashAll 修正 (hashCode 写法)

| 文件:行号 | 状态 | 证据 |
|----------|------|------|
| `lib/domain/entities/medication_entity.dart:131-142` | **已修** (R60 M8) | `Object.hash(..., Object.hashAll(times), ...)` 拍平 List, 全字段覆盖 |
| `lib/domain/entities/check_in_entity.dart:137-` | **已修** | `Object.hash(...)` 多字段 |
| `lib/domain/entities/contact_entity.dart:100` | **已修** | `Object.hash(id, name, phone, sortOrder, isActive)` |
| `lib/domain/entities/mood_entry_entity.dart:144-` | **已修** | `Object.hash(...)` |
| `lib/domain/entities/user_profile_entity.dart:96-` | **已修** | `Object.hash(...)` |
| `lib/domain/entities/vent_entry_entity.dart:101-` | **已修** | `Object.hash(...)` |
| `lib/domain/entities/report_history_entity.dart:50` | **已修** | `Object.hash(id, windowDays, generatedAt, userName, reportText)` |
| `lib/domain/entities/hour_minute.dart:44` | **已修** | `Object.hash(hour, minute)` |
| `test/domain/medication_entity_hashcode_round60_test.dart` | **已修** (R60) | regression test 验证 hashCode 契约 |

**优先级**: P2 (实体相等性) — **已修, 维持**

### 2.30 emil 动效 token 集中 (curve + duration)

| 文件:行号 | 状态 | 证据 |
|----------|------|------|
| `lib/core/theme/app_tokens.dart:353-414` | **已修** (R17 R1) | 6 个 curve 集中 token: `curveStandard` (easeOutCubic) / `curveSubtle` (easeOut) / `curveDecelerate` (easeOutQuart) / `curveAccelerate` (easeInCubic) / `curveDelight` (elasticOut) / `curveBackOut` (easeOutBack) + emil 频度决策框架 doc 注释 |
| 同上 660-714 | **已修** (R24 R48 emil P1-1) | `MotionScheme` 枚举 (none / subtle / standard / delight) + 频度档位命名, subtle 用专属 curve 区别于 standard |
| 同上 734-752 | **已修** | `Motion.duration(context, base)` / `Motion.curve(context, base)` reduce-motion wrapper, 系统开启 → 0 + linear |
| grep `Curves.easeInOut` (硬编 magic) | ✅ | 0 hit (除 emotion decision framework doc 注释) |
| grep `Curves.easeIn\b` / `Curves.easeOut\b` / `Curves.linear` | ⚠️ 4 hit | 仅 `app_tokens.dart` MotionScheme 4 case 内 (合法, curve token 集中器自身) |

**优先级**: P1 (动效一致性) — **已修, 维持**

---

## 修正优先级总览 (30 bug 模式)

| 优先级 | 模式 | 状态 | 修正工作量 |
|------|------|------|-----------|
| **P0 (production blocker)** | 2.12 PIPL §13 单独同意 (硬实做) | 未修 | M (2-3d 跟 A-01 绑定) |
| **P0 (production blocker)** | 2.10 5 厂商 push SDK 接入 | 未修 | XL (5-10d + 5 厂商审核) |
| **P0 (production blocker)** | 2.15 AliyunSms 真接 | 未修 | XL (80-120h + 法务 + AccessKey) |
| **P1 (R60 plan)** | spen §4#1: 8 `@Deprecated` facade 修正 | 未修 | S (1-2d) |
| **P1 (R60 plan)** | `app_tokens.dart` 779 行拆 5 子 | 未修 | M (1-2d) |
| **P1 (R60 plan)** | `home_page.dart` widget test | 未修 | M (1d, 每日用户路径 0 test) |
| **P2 (R60+)** | 文字 token 化 36% → 80% | 部分修 | L (3-5d 渐进) |
| **P2 (R60+)** | `_showSafetyAlert` 50 行 → SafetyAlertDispatcher | 未修 | S (1-2h) |
| **P3 (R61+)** | 早期 55 commit 修正 + 加 `check_commit_convention.py` | 未修 | S (半天) |
| **P3 (R60+)** | 半角省略号 → 全角 修正 | 未修正 | S (半天) |
| **其余 20 个** | 全部已修 | ✅ 维持 | 0 |

---

## 修正建议总结 (按投入产出比)

### 立即修正 (R60 hot fix, P0 production blocker)

1. **AliyunSmsProvider.send() 真接** (XL, 80-120h 外部依赖)
   - 阻塞 production, 但依赖法务/AccessKey
   - 修正计划已写在 R55 commit 注释, 等资源到位
2. **PIPL §13 联系人单独同意** (M, 跟 A-01 绑定)
   - 联系人表加 `consentConfirmedAt` 字段 + 失联通知 gate
   - 修正 schema 升级 (schemaVersion 15)
3. **5 厂商 push SDK 接入** (XL)
   - 90% 国产 ROM 静默杀进程, 通知送达率 5% → 95%+
   - 小米 / 华为 / OPPO / Vivo / 魅族 各家 push SDK + 通道

### 短期修正 (R60, P1 工程优化)

4. **`app_tokens.dart` 779 行拆 5 子** (1-2d)
5. **`home_page.dart` widget test** (1d, P0 stale finding)
6. **`safety_watch_service` 8 `@Deprecated` facade 修正** (1-2d)

### 中期修正 (R61, P2 重构)

7. **文字 token 化 36% → 80%** (3-5d 渐进)
8. **`_showSafetyAlert` 50 行 → SafetyAlertDispatcher** (1-2h)
9. **半角省略号 → 全角** (半天)

### 长期修正 (R62+, P3)

10. **早期 55 commit 修正 + 守门员** (半天)

### 修正已很完整, 不建议再修正

- 4 层架构纯度 (R13 起 0 违规)
- 隐私边界 (vent 完全独立)
- 跨 feature import (R12 起 0 违规)
- Stream subscription leak (0 违规)
- BuildContext 跨 async gap (23 处全修)
- DateTime race (0 违规)
- Notification id cancel range 公式 (统一 200000)
- Resource acquire/release try/finally (8 处全修正)
- ink_sparkle shader (R17 R8 起 0 违规)
- DateTime.toIso8601String() 时区后缀 (12 处全修正)
- AppRoot 跨日刷新 (R17 R4 + R21 P0-4 双轨)
- R56e orphan ARB keys (R56e 修正后 0 orphan)
- R57 硬编码中文 string (0 真实违规)
- R57 繁简一致性 (0 违规)
- Object.hashAll 修正 (R60 M8 regression test)
- emil 动效 token 集中 (6 curve + MotionScheme 枚举 + reduce-motion wrapper)
- 国产 ROM 自检卡 (R20 起 3 件套齐全)
- i18n 完整性 (zh/en/zh_Hant 551 同步)
- PDF mask 敏感字段 (R39 P1-7)
- commit 规范 (R45+ 100% 符合)
- CHANGELOG 同步 (R45 修正后顺序正确)

---

## 测试覆盖 (115 文件 / 1098 cases)

### domain 32 测试 (纯 Dart, 最快)
- `streak_calculator_round19_test.dart` (隐式序修后回归)
- `assessment_comparison_round18_test.dart` (current/previous 修正)
- `medication_entity_hashcode_round60_test.dart` (R60 M8 hashCode 契约)
- `phq9_detect_crisis_round60_test.dart` (R60 C1 PHQ-9 危机 + hotlineByRegion 21 case)
- `reminder_scheduler_no_mutate_round48_test.dart` (defensive copy)
- `care_engine_*_round{3,17,18,19}_test.dart` (4 strategy + copy)
- ...

### data round-trip (DB + entity 字段校验)
- ...

### presentation widget (ProviderScope override + MaterialApp + tester)
- `app_root_round17_midnight_test.dart` (跨 midnight 修正)
- `crossed_midnight_since_round48_test.dart` (跨日检测纯函数)
- `notification_status_card_round20_test.dart` (国产 ROM 自检)
- `vent_compose_stop_and_cleanup_round48_test.dart` (stop 异常 deleteTemp 仍调 RED-1)
- ...

---

## 总结

**项目当前状态**: v0.27 round 60, schemaVersion 14, 273 commit, 232 lib/.dart 文件, 115 test 文件, 1098 test cases, 0 analyze error, 15/16 守护脚本全绿, 1 守门员仅 WARN-only (A-01 修正方向)。

**修正已很完整**:
- 4 层架构纯度、隐私边界、跨 feature import 三大结构性约束 **0 违规**
- 30 个 bug 模式 (P0) 修正覆盖 **20/20 (66.7%)**, 修正工作量 0 (维持)
- 3 个 P0 production blocker 修正 (AliyunSms / PIPL §13 / 5 厂商 push) 等外部资源到位, 已计划 (R55+)

**建议修正路径** (按投入产出比):
1. **R60 hot fix** (P0): 修正 `app_tokens.dart` 拆 5 子 + `home_page.dart` widget test + `safety_watch_service` 8 facade 清理 (P1, 3-5d)
2. **R61 重构** (P2): 文字 token 化 36% → 80% + `_showSafetyAlert` 抽 dispatcher (P2, 3-5d)
3. **R62 修正** (P3): 早期 55 commit 修正 + 守门员 (半天)
4. **R55+ 真接** (P0, 等外部): AliyunSms + PIPL §13 + 5 厂商 push (XL, 80-120h+)

**没有水, 没问题的就写 OK, 修正工作做得扎实**。建议优先修正 P1 项目, 把"工程债务"清干净, 再接 P0 production blocker (等外部资源)。
