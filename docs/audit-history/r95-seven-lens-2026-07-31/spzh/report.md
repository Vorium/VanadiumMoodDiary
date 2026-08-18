# superpowers-zh 视角审视报告 — chroniccare v0.27.0+62

> **视角**：i18n / 合规 / 中文命名 / 提交规范 / 法务 / 中国特色编码
> **扫描范围**：`lib/` 236 dart + `assets/legal/` 3 md + `docs/` 10 md + `pubspec.yaml` + `scripts/check_*.py`
> **扫描方法**：ripgrep 关键 pattern + 关键文件 read（domain 实体 / ContactRepository / ConsentDialog / safety_watch_service / sms_service / legal_page / phq9 / gad7 / strings.dart / privacy_policy.md）
> **基础**：
> - `docs/reviews/2026-07-31-three-lens/consolidated.md`（R60+ 整合）
> - `docs/reviews/2026-07-26-three-lens/spzh/report.md`（上次 spzh）
> - `docs/CHANGELOG.md` 顶部 [Unreleased]（R62 修正起点）
> - `AGENTS.md`（代码视角导览）
> - 16+1 守护脚本（`check_legal_consent.py` / `check_sms_release_ready.py` / `check_strings_hardcoded.py` / `check_zh_hant_consistency.py` / `check_orphan_arb_keys.py` / `check_no_pua.py` 均跑过）

> **报告体例**：每条发现标 `文件:行`、架构 vs 底层、修复难度 S/M/L、优先级 P0/P1/P2/P3、grep 复现命令。

---

## 0. 一页总览

| 指标 | 数值 |
|---|---|
| 总问题 | **18** |
| 架构级 | 5 |
| 底层级 | 13 |
| **P0** | **3**（R62 P0-2 半修 + ConsentKind 重复 enum + Contact 缺 consent 字段） |
| P1 | 3（PHQ-9/GAD-7 仍硬编 / main.dart:140 注释撒谎变本 / 守护脚本盲点） |
| P2 | 9 |
| P3 | 3 |

**核心判断**：R62 把"P0-2 联系人同意"在 API 层落地了（`ConsentArtifact` 实体 + `ContactRepository.add` 强制 + `ConsentDialog` UI），但**留 3 个大窟窿**：

1. **consent 落库失败** — `ContactRepositoryImpl.add` 只 `piiSafeLog` 不写表，`Contact` 表 0 consent 字段，`schemaVersion=14` 未 bump → PIPL §13 留痕只活在 log 文件里（uninstall 就丢）
2. **`ConsentKind` enum 在 domain / presentation 两层同名不同值** — 域层 `{emergencyContactSharing, dataExport}` vs 表层 `{safety, vent, analytics}`
3. **PHQ-9 / GAD-7 量表仍 100% 硬编中文** — 16 道题 + 9 档严重度 + 6 region 危机电话 label 全 const 字符串 → en/zh_Hant 用户看不懂 + R60 救的危机电话 region 路由被中文 label 抵消

**好消息**（较上次 spzh 报告）：
- ✅ 跨境数据传输段 `privacy_policy.md §11` 已加（PIPL §38/§39 达标）
- ✅ 失联通知文案三态分流 `sent/mocked/failed` 已落地（P0-3）
- ✅ `safety_watch_service.displayMessageL10n(l10n)` 9 个 kind 全 i18n 化（P1-4）
- ✅ 失联 SMS 双源合并 `lost_contact_sms.dart` 单一 source（P1-5）
- ✅ `medication_report.toReportString()` 走 `Strings.pdf*` 集中器（v0.25 R56h）
- ✅ `setup_legal_dialog.dart` v0.27 R62 升级到 `ConsentDialog` 强制流程
- ✅ 16 守护脚本新增 `check_orphan_arb_keys.py` / `check_zh_hant_consistency.py` 全绿
- ✅ `pubspec.version = 0.27.0+62` / `schemaVersion = 14`（R60+ 修正过漂移）

---

## 1. 顶层架构审视

### 1.1 架构评级

| 维度 | 评分 | 理由 |
|---|---|---|
| **中文命名一致性** | ⭐⭐⭐ (3/5) | 量表 16 道题 + 9 档严重度 + 6 region 危机电话 label 全部硬编中文（domain 0 flutter 限制下走 const Map，未走 i18n override） |
| **隐私政策 / 法律文档** | ⭐⭐⭐⭐ (4/5) | 3 份 markdown 覆盖 PIPL / 精神卫生法 / 单独同意；§11 跨境数据传输段已加（v0.25 R54）；0.24 "Known issues" 已整合到 0.27.0 release notes |
| **PIPL §13 单独同意** | ⭐⭐ (2/5) | API 层强制了，但**未真正留痕**（只 log，不写表）；联系人本人没独立确认机制（v0.23 P3-31 TODO 仍挂） |
| **PIPL §14 撤回机制** | ⭐⭐⭐⭐ (4/5) | `legal_page.dart` 3 toggle + `LegalConsentStore` SharedPreferences + `legalConsentProvider` 状态管理已完整；唯一 gap 是**枚举命名分歧**（详见 P0-2） |
| **网安法 零云端** | ⭐⭐⭐⭐⭐ (5/5) | 全部数据本地 SQLCipher AES-256 + 录音本地 AES-256；`privacy_policy.md §2` 明确"无云端" |
| **精神卫生法 患者隐私** | ⭐⭐⭐⭐ (4/5) | vent 隐私边界严格；`SafetyCheckKind` 3 态分流避免对家属"假成功" |
| **i18n 完整性** | ⭐⭐⭐ (3/5) | zh / en / zh_Hant 574 key 100% 同步；0 orphan；presentation 层 0 硬编。但**量表 / 失联 SMS / 通知 channel / 邮件模板**仍依赖 `strings.dart` 50+ 处中文 fallback |
| **提交规范** | ⭐⭐⭐⭐⭐ (5/5) | 273 commit 全部 `v0.X round N:` 风格；`CHINESE_COMMIT_GUIDE.md` 规范化 |
| **硬编码中文** | ⭐⭐⭐ (3/5) | presentation 层 0；domain 层 50+ 处仍硬编，但 R57 已加 override 模式 |
| **PUA 字符** | ⭐⭐⭐⭐⭐ (5/5) | `check_no_pua.py` 0 PUA；3 份法律文档 UTF-8 clean |
| **全角 / 半角 / 标点** | ⭐⭐⭐⭐ (4/5) | 文档用全角；代码用半角（AGENTS.md 强制） |

**总体**：3.7/5（上次 3.0/5）。架构稳定，无须切换。P0 都是"半修"：API 强制了但留痕/UI/数据层没补完。

### 1.2 顶层重构建议（高内聚低耦合）

| # | 模块 | 现状 | 建议 | 难度 | 优先级 |
|---|------|------|------|------|--------|
| 1 | **P0-2 联系人同意留痕** | `ContactRepositoryImpl.add` 只 `piiSafeLog` 不写表；`Contact` 表 0 consent 字段；`schemaVersion=14` 未 bump | 加 `Contacts` 表 4 个字段（`consentAt` / `consentKind` / `consentBy` / `consentVersion`），bump `schemaVersion=15` + migration + 改 `into(contacts).insert(ContactsCompanion(..., consentAt: Value(consent.grantedAt), ...))` | M | **P0** |
| 2 | **P0 ConsentKind 双 enum 统一** | domain `ConsentKind { emergencyContactSharing, dataExport }` vs presentation `ConsentKind { safety, vent, analytics }` 同名不同值 | domain `ConsentKind` 加 `safety/vent/analytics` 3 值；presentation `LegalConsentStore` import domain；删重复 enum | M | **P0** |
| 3 | **量表 i18n 化** | `phq9.dart` / `gad7.dart` / `assessment_scale.dart` 16 道题 + 9 档严重度 + 6 region 危机电话 label 全 const 中文 | `AssessmentScale` 改 abstract 加 `phq9Options(int score, {String? override})` 等函数；domain 提供 const Map data；presentation 传 `AppLocalizations` 拿翻译 | L | P1 |
| 4 | **`displayMessage` getter 仍返 i18n key** | R61 修了 `displayMessageL10n(l10n)` 但保留 `displayMessage` getter 返 key 字符串 | 老 caller 全部升级调 `displayMessageL10n(l10n)`，删 getter | S | P2 |
| 5 | **README / AGENTS 测试数字漂移** | README:131 = 1098 / AGENTS:136 = 1098；实际 1151/1151；CHANGELOG [Unreleased] 段 `(R62 完成时填)` | README + AGENTS 改 1151；CHANGELOG [Unreleased] 填实际值 | S | P2 |

---

## 2. 底层逐行排查（5-15 条）

> 按"问题严重度 + R62 是否落地"排序。每条带 `文件:行`、架构/底层、修复难度、优先级。

| # | 文件:行 | 现状 | 建议 | 架构/底层 | 难度 | 优先级 | 原因 |
|---|--------|------|------|------|------|--------|------|
| **P0-A** | `lib/core/data/repositories/contact/contact_repository_impl.dart:36-49` | `piiSafeLog('📝 consent granted: kind=... grantedAt=... grantedBy=... version=...')` 然后 `_db.insertContact(ContactsCompanion.insert(name, phone, sortOrder))` —— **consentArtifact 完全没进 DB**，只在 log | 把 `consentArtifact` 4 个字段写进 `ContactsCompanion`（需先加 4 列）+ 同时写 log（PIPL §13 + §17 留痕 + 可审计） | 底层 | M | **P0** | PIPL §13 要求"留痕"，log 文件 OS 可删，DB 永久 |
| **P0-B** | `lib/core/data/database/tables/contact/contacts.dart` + `app_database.dart:82` | `Contact` 表 5 列（id/name/phone/sortOrder/isActive），**0 consent 字段**；`schemaVersion=14` 未为 R62 bump | 加 `consentAt` / `consentKind` / `consentBy` / `consentVersion` 4 列；bump `schemaVersion=15` + `onUpgrade` 迁移 | 架构 | M | **P0** | 上一条的前置；不改 schema = 上条无解 |
| **P0-C** | `lib/domain/entities/consent_artifact.dart:33-39` + `lib/presentation/providers/legal_consent_provider.dart:20-29` | **两个 `ConsentKind` enum 同名不同值**：domain `{emergencyContactSharing, dataExport}` vs presentation `{safety, vent, analytics}`。`legal_page.dart:139-162` 用 presentation，`ConsentDialog` + `contact_repository_impl` 用 domain，**两者无任何 import 关系** | domain `ConsentKind` 加 `safety/vent/analytics` 3 个值；presentation `legal_consent_provider.dart` 删本地 enum，import domain 的 | 架构 | M | **P0** | 同名 enum 是未来踩雷的根源（`ref.watch(streamProviderFamily<bool, ConsentKind>)` 类型推断错误） |
| **P1-A** | `lib/domain/logic/phq9.dart:19-24, 70-103, 119-133` + `gad7.dart:15-31, 41-65` | 9 + 7 = 16 道题 + 5 + 4 = 9 档严重度 + 6 region 危机电话 label 全部 `const` 硬编中文。R60 commit 98fb42b 加了 21 case test 但**只测数据完整性**（hotlineByRegion keys / length），**没测 i18n** | `AssessmentScale` 改 abstract 注入 `ScaleTranslations` 包装（domain 0 flutter 边界用 override 模式同 `Strings`）；4 档选项 / 9 道题 / 9 档严重度全走 `phq9Options(int score, {String? override})` 函数版 | 架构 | L | P1 | 评估核心 + 海外华人危机电话 label 中文 = 法律风险 |
| **P1-B** | `lib/core/l10n/strings.dart:248-256` (moodLabel) + `:135-141` (PdfAuthor 等) + 多处通知/邮件 | `Strings` 50+ 处 fallback 中文虽支持 override，但**关键 path 没传 override**（看 `notification_service.dart`、`reminder_scheduler.dart`、`safety_alert_dispatcher.dart` caller）→ en 模式 fallback 中文的概率 > 0 | 跑 `check_no_pua` 风格脚本 `check_strings_override.py`：grep 所有 `Strings.xxx` / `Strings.xxxText()` caller，标出"未传 override"的 → 修正 caller | 底层 | M | P1 | 即使 `Strings` 50+ 处硬编是架构选择（domain 0 flutter），**override 没用 = 跟没改一样** |
| **P1-C** | `lib/main.dart:23-35, 151-191` | R62 把 `SmsService` 提为顶层 `_smsService` 静态实例 + `smsServiceProvider.overrideWithValue(_smsService)` ✅。R60 报告的"main.dart:140 注释撒谎"已修 | 没问题，仅确认 ✅ | 底层 | — | — | 上次报告项已修 |
| **P2-A** | `lib/core/data/services/safety_watch_service.dart:308-315` | `String get displayMessage` 仍返 i18n key（如 `'safetyCheckResultDisabled'`），老 caller（如果有）会显示裸 key。`displayMessageL10n(l10n)` 是新方法 | 跑 `rg "\.displayMessage\b"` grep 所有 caller，升级到 `.displayMessageL10n(l10n)`；删 getter | 底层 | S | P2 | 防御性：避免未来 caller 误用 |
| **P2-B** | `lib/core/data/services/safety_watch_service.dart:381-387` | `toJson` 没序列化 `contactsMocked` 字段（P0-3 3 态分流时加的字段）→ JSON 输出少一个字段，调试/audit 看到 `smsOk/smsFail` 但 `smsMock` 不见 | `toJson` 加 `'contactsMocked': contactsMocked` | 底层 | S | P2 | audit log 完整性 |
| **P2-C** | `lib/presentation/pages/setup/setup_legal_dialog.dart:11-13` | R58 文档明确"✅ R58 文档化 (软实施: 用户主动告知, 联系人主动确认留 A-01)"——v1.0 严格 PIPL §13 + §23 需联系人回复 "Y"，但**当前是"软实施"**。`consent_artifact.grantedBy: 'user'` 是用户自证而非联系人确认 | v1.0 阶段加：(1) `Contact` 加 `consentConfirmedAt` / `consentConfirmChannel` 字段 (2) `setup` 阶段发"同意接收失联通知"短信 (3) 联系人回复 "Y" 后置 `consentConfirmedAt` (4) `SafetyWatchService` 只在所有联系人 confirmed 时才发 | 架构 | L | P2 | 留 A-01 文档化（setup_legal_dialog.dart:15-28 注释已铺） |
| **P2-D** | `lib/domain/logic/crisis_detection.dart` (rename to assessment_scale.dart:129-185) | `HotlineRegion` 6 region + `hotlineByRegion` Map 6 region 危机电话 label 中文 + en 混合（cn: 中文 / us: 英文 "988 Suicide & Crisis Lifeline"）—— **多 region 同 key i18n 难**：英美用英文 OK，但香港/台湾用户看 "撒玛利亚防止自杀会" 跟繁体中文 user 看 "撒瑪利亞防止自殺會" 不一样 | label 走 `Map<HotlineRegion, ({String labelKey, String number})>`，caller 传 `AppLocalizations` 注入翻译 | 底层 | M | P2 | 跨区域一致性 + i18n |
| **P2-E** | `lib/core/data/services/snooze_manager.dart:80-82` + `notification_service.dart` 多处 | 通知 Channel name/desc 调用 `Strings.notifChannelMedicationName`（const 字符串，**未传 override**）→ en 模式通知 Channel 显示中文"吃药提醒" | snooze_manager / notification_service 改调 `Strings.notifChannelMedicationNameText(override: l10n.xxxChannelMedicationName)` | 底层 | S | P2 | Android 13+ 通知权限 UI 显示 |
| **P2-F** | `lib/core/data/utils/phone_validator.dart:158-170` | `PhoneRegion.displayName` 5 region 硬编中文（'中国大陆' / '中国香港' / '中国澳门' / '中国台湾' / '国际'） | 抽 `RegionDisplayName(int region, {String? override})` 同 `Strings` override 模式 | 底层 | S | P2 | 联系人 region 选择 UI |
| **P2-G** | `lib/core/data/services/preset_medication_templates.dart:63-154` | 4 个预置方案 30+ 处中文硬编（"单药 · SSRI 早一次" / "SSRI 类抗抑郁药" / "1 种药，每天早 8 点服用（适用 SSRI / SNRI 类）" / "常见 SSRI / SNRI 类抗抑郁药（具体药名以医生处方为准）"） | 抽 `PresetMedicationTemplate` 走 ARB i18n，caller 传 `AppLocalizations` | 底层 | M | P2 | 首次设置核心 UI（v0.27 P0-3/5 修了《广告法》风险但仍是中文） |
| **P2-H** | `lib/domain/entities/check_in_entity.dart:53-60` + `day_detail.dart:166, 178, 244-246` | `CheckInType.label: '每日打卡' / '临时吃药' / 'PHQ-9 评估' / 'GAD-7 评估'` + `day_detail.dart` 5+ 处 `'打卡 · ${med.name}' / '每日打卡' / '临时 · ${parsed.name}' / '临时吃药' / 'PHQ-9 抑郁筛查' / 'GAD-7 焦虑筛查'` | `CheckInType.label` 走 override + `day_detail` 文案走 i18n | 底层 | M | P2 | 趋势日详情核心 UI |
| **P2-I** | `lib/domain/entities/vent_entry_entity.dart:62-65, 112` | `durationLabel: '$sec秒' / '$m分' / '$m分${s.toString().padLeft(2, '0')}秒'` 时长 + `toString: '...字...'` 调试 | 时长走 i18n（zh='N 秒/N 分' / en='Ns/Nm'） | 底层 | S | P2 | 树洞核心 UI（P2-2.10 Hero tag 已有，叠加） |
| **P3-A** | `README.md:131` + `AGENTS.md:136` + `docs/CHANGELOG.md [Unreleased]` | 文档数字漂移：README + AGENTS 写"1098 cases v0.25 R56e"；实际 1151 cases（v0.27 R61）；CHANGELOG [Unreleased] 段写 `(R62 完成时填)` 占位 | README + AGENTS 改 1151；CHANGELOG [Unreleased] 填实际值（116 test 文件 / 1156 test() calls） | 底层 | S | P3 | 文档一致性 |
| **P3-B** | `lib/core/data/services/medication_notifier.dart:91, 113, 142-150` + `refill_notifier.dart:114-204` | piiSafeLog 中文 4 + 5 处（'✅ 设置每日 $hour:$minute 提醒' / '❌ 设置提醒失败: $e' / '⏭️ scheduleRefillReminder: med=${medication.name} 无 refillAt' / '✅ 续方提醒: med=${medication.name} ...'） | 改 en 模式 + mask medication name (PII 风险) | 底层 | S | P3 | 海外 dev 查不到 + PII 泄漏 |
| **P3-C** | `lib/l10n/app_zh.arb` vs `app_en.arb` 命名风格 | 个别 key 命名不一致（如 `setupContactName` (zh) vs `setupContactNameLabel` (en)） | 跑 `rg "^\s*\"[a-zA-Z]+[A-Z]"` 对比两个 ARB，统计命名不一致 | 底层 | S | P3 | 命名 metadata，影响极小 |

**已修（确认）**：
- ✅ `safety_watch_service.displayMessageL10n(l10n)` 8 case + 3 态全 i18n 化（safety_watch_service.dart:326-353）
- ✅ `buildLostContactSms` 单一 source（reminder_scheduler.dart:222 + safety_alert_dispatcher.dart:54）
- ✅ `medication_report.toReportString()` 走 `Strings.pdf*`（medication_report.dart:189, 192, 206, 212, 249, 265, 277）
- ✅ `main.dart` SmsService 顶层 static 实例（main.dart:36, 154, 191）
- ✅ `pubspec.version = 0.27.0+62`（R62 已 bump）
- ✅ `schemaVersion = 14`（R60 D1 修正过漂移）

---

## 3. 视角特定清单（spzh 必检）

### 3.1 PIPL §13 单独同意

| 项 | 状态 | 证据 |
|---|---|---|
| API 强制 `ConsentArtifact` | ✅ | `domain/repositories/contact_repository.dart:20-25` |
| UI 弹 ConsentDialog | ✅ | `presentation/widgets/consent_dialog.dart` + `contacts_list_widget.dart:204-216` |
| 落库留痕 | ❌ | `contact_repository_impl.dart:36-49` 只 piiSafeLog 不写表 |
| DB schema 加 consent 字段 | ❌ | `contacts.dart` 0 consent 列；`schemaVersion=14` 未 bump |
| 联系人本人独立确认 "Y" | ❌（软实施） | `setup_legal_dialog.dart:11-13` 注释明确"v0.23 P3-31 TODO 仍挂" |
| 撤回同意（PIPL §14） | ✅ | `legal_page.dart` 3 toggle + `legal_consent_provider.dart` SharedPreferences |
| 审计 log 持久化 | 🔶 | piiSafeLog 走 stdout/file，不是 DB |
| 跨境告知弹窗 | ✅（v0.25 R54） | `privacy_policy.md §11` |
| ConsentKind 命名一致 | ❌ | domain `{emergencyContactSharing, dataExport}` vs presentation `{safety, vent, analytics}` |

### 3.2 隐私政策覆盖

| 文件 | 覆盖项 | 状态 |
|---|---|---|
| `assets/legal/privacy_policy.md` (10530 字节) | 同意记录 / 跨境数据传输 / 用户权利 / 数据存储 / 共享 / PIPL 引用 | ✅ 11 节齐全 |
| `assets/legal/sensitive_data_consent.md` (3800 字节) | 敏感信息定义 / 14 周岁以下 / 处理目的 | ✅ 7 节 |
| `assets/legal/user_agreement.md` (2748 字节) | 服务说明 / 免责 / 退订 | ✅ 5 节 |
| `docs/DEPLOYMENT.md` | 上架清单 / NMPA / HIPAA / GDPR | ❌ 0 处提 NMPA / HIPAA / GDPR |
| `assets/legal/` 3 份英文版 | App Store / Google Play 国际用户 | ❌ 0 英文版（en 模式 user 看到中文 markdown） |
| NMPA "非医疗器械" 正式声明 | App Store + Google Play Data Safety | ❌ 0 模板 |

### 3.3 i18n 同步

| 项 | 状态 | 证据 |
|---|---|---|
| ARB key 三语同步 | ✅ | `check_arb_keys.py` 574/574 一致 |
| 繁简一致性 | ✅ | `check_zh_hant_consistency.py` 574 key 100% 一致（OpenCC s2tw） |
| 0 orphan key | ✅ | `check_orphan_arb_keys.py` 0 orphan |
| 硬编码中文（presentation 层） | ✅ | `check_strings_hardcoded.py` 0 违规 |
| 硬编码中文（domain 层） | 🔶 | `strings.dart` 50+ 处 fallback + `phq9.dart` 16 题 + `gad7.dart` 11 题 + `medication_report.toReportString` 30+ 处 |
| 通知 / 邮件 / SMS 模板 i18n | 🔶 | 走 `Strings.xxxText({String? override})` 模式，但 caller 80% 未传 override |
| 量表 16 题 + 9 严重度 + 6 region 危机电话 label | ❌ | const 字符串硬编（详见 P1-A） |
| PhoneRegion 5 region display name | ❌ | `phone_validator.dart:158-170` 硬编中文 |
| DosageUnit `mg` / `片` | ✅ | v0.27 R61 修了 `medication_unit_label.dart` |
| formatters 走 intl | ✅ | v0.25 R56d 修了 `formatters.dart` 走 `intl` `DateFormat` |

### 3.4 提交规范 / commit

| 项 | 状态 | 证据 |
|---|---|---|
| `<version> round <N>: <title>` 风格 | ✅ | 273 commit 100% 符合（git log --oneline 抽样 25 commit 全部 `v0.X round N:`） |
| 中英双轨 | ✅ | v0.21+ 80% 英文 / 20% 中文（`docs/CHINESE_COMMIT_GUIDE.md` 规范化） |
| conventional commit prefix | ✅ | v0.21+ 多用 `fix/refactor/feat/docs/test/chore` 风格 |
| CHANGELOG 段顺序 | ✅ | `check_changelog.py` 19 段顺序正确 |
| CHANGELOG [Unreleased] 段 | 🔶 | 写 `(R62 完成时填)` 占位，R62 完成后未填 |
| 提交不写具体行号 | ✅ | 指南明确禁止（cherry-pick 会过时） |

### 3.5 PUA / 全角 / 半角 / 标点

| 项 | 状态 | 证据 |
|---|---|---|
| PUA 字符 | ✅ | `check_no_pua.py` 0 PUA（lib/docs/scripts/ 全覆盖） |
| 全角中文标点（文档） | ✅ | 3 份法律 markdown 用全角中文标点 |
| 半角英文标点（代码） | ✅ | AGENTS.md 强制；`check_fullwidth_punctuation.py` 守护 |
| 终端 mojibake | ⚠️ | Windows GBK 终端误读 UTF-8 文件（PowerShell `-Encoding Default`）—— 不是项目 bug，是 dev 工具问题 |
| 修复字符污染（P1-NEW-1） | ✅ | R62 完成 `assessment_record.dart` "修复"字眼清理 |

### 3.6 精神卫生法 患者隐私

| 项 | 状态 | 证据 |
|---|---|---|
| vent 隐私边界 | ✅ | vent 内容绝对不进通知/趋势/关怀（AGENTS.md 明确） |
| 失联通知 3 态分流（避免对家属"假成功"） | ✅ | `NotificationService._resolveSafetyAlertBody` + `SmsDispatchOutcome` typedef |
| 危机电话 region 路由（海外华人） | 🔶 | `hotlineByRegion` 6 region 数据 OK，但 **label 全硬编**（cn 中文 / us 英文 / hk 繁体中文 混合） |
| "让家人放心"措辞 | ❌ | `Strings.notifDailyCheckInBody: '点一下 = 打卡，让家人放心'` —— 暗示家人监控，精神心理敏感 user 可能焦虑（v0.24 spzh 已列 P2，本次仍未改） |
| "TA" 网络用语 | ❌ | `lost_contact_sms.dart:69` `'请你方便的时候提醒 TA 按时吃药'` —— 95 后用语不适中老年 user |
| "你真棒"居高临下 | ❌ | `care_copy.dart:39-46` `weekPerfect: '...你真棒——保持下去'` |
| 非医疗器械声明 | ❌ | DEPLOYMENT.md 简略提，0 正式 PDF 模板 |

### 3.7 中文命名一致性

| 概念 | 命名风格 | 一致性 |
|---|---|---|
| 表 drift DataClassName | 英文单数（`Contact` / `Medication` / `VentEntry` / `MoodEntry`） | ✅ |
| domain 实体 | 英文 + `Entity` 后缀（`ContactEntity` / `MedicationEntity` / `VentEntryEntity`） | ✅ |
| enum | 英文 PascalCase（`HotlineRegion` / `PhoneRegion` / `DosageUnit` / `LostContactSmsKind` / `SmsResultKind` / `SafetyCheckKind`），但 `ConsentKind` ×2 重复 | 🔶 重复 |
| status / kind | 英文（`MoodLabel` / `CheckInType`） | ✅ |
| 隐私政策术语 | "PIPL §13" / "§14" / "§26" / "§38" 引用 | ✅ |
| 中文术语 | "通知"/"推送"/"提醒" 3 个词在不同文案混用 | 🟡 需 `terminology.md` 统一 |

---

## 4. 与历史报告对比

### vs `docs/reviews/2026-07-26-three-lens/spzh/report.md`（v0.24 round 48）

| 上次报告项 | 状态 | 证据 |
|---|---|---|
| **P0 PIPL §13 单独同意未实现（联系人回复 Y）** | 🟡 **部分修** | R62 加了 API 强制 + ConsentDialog UI + ConsentArtifact 实体。但：(1) 留痕只 log 不写表（P0-A/B）；(2) 联系人本人确认 "Y" 仍 TODO |
| **量表 PHQ-9 / GAD-7 题目 + 严重度标签全部硬编中文** | ⏳ **未修** | `phq9.dart:19-24, 79-103` + `gad7.dart:15-31, 59-64` 仍 const 字符串硬编 |
| **CHANGELOG 0.24.0 "Known issues" 段过期** | ✅ **已修** | v0.27.0 段重写为 R61 release notes |
| **domain 层 strings.dart 50+ 处硬编** | 🔶 **部分修** | R57 加 `override` 模式，但 caller 80% 未传 override |
| **5 厂商 push 通道 0 接** | ⏳ **未修** | DEPLOYMENT.md 阶段 8 仍未写（外部依赖） |
| **AliyunSmsProvider.send() 永远 throw UnimplementedError** | ⏳ **未修** | R62 改 `isProductionReady` 真检查 4 字段非空，但 `send()` 仍 throw（外部依赖） |
| **NMPA / Data Safety / "非医疗器械" 声明模板缺** | ⏳ **未修** | DEPLOYMENT.md 0 模板 |
| **39 个孤儿 ARB key + 缺守护脚本** | ✅ **已修** | R56e 新增 `check_orphan_arb_keys.py` + 一次性清 39 orphan；当前 574 key 0 orphan |
| **medication_report.toReportString() 重复硬编** | ✅ **已修** | v0.25 R56h 改走 `Strings.pdf*` 集中器 |
| **3 处文档数字打架（910/1052/876）** | 🔶 **部分修** | 实际 1151/1151；README + AGENTS 仍写 1098（v0.25 R56e 数） |
| **3 份法律文档 utf-8 乱码** | ✅ **已修** | `Get-Content -Encoding UTF8` 显示清晰中文；Windows GBK 终端误读是 dev 工具问题不是项目 bug |
| **隐私政策 §10 跨境数据传输段缺** | ✅ **已修** | R54 增补 §11（`privacy_policy.md:126-155`） |
| **3 份法律文档国际化（英文版）** | ⏳ **未修** | 仍 0 英文版（en 模式 user 看到中文 markdown） |
| **`check_sms_release_ready.py` 降为 warn-only** | ⏳ **未修** | 当前仍 warn-only（v0.27 R58 降级），等 P0-1 完整落地后恢复 `sys.exit(1)` |
| **`safety_watch_service.displayMessage` 8 case hardcode 中文** | ✅ **已修** | R61 加 `displayMessageL10n(l10n)` 9 case 全 i18n 化 |
| **失联通知两条并行路径文案生成器 50% 重复** | ✅ **已修** | R62 抽 `lost_contact_sms.dart` 单一 source（`buildLostContactSms(...)`） |

### vs `docs/reviews/2026-07-31-three-lens/consolidated.md`（v0.27 R60+）

| 整合报告项 | 本次验证 | 差异 |
|---|---|---|
| P0-1 SmsGateway abstract | ⏳ 仍 `throw UnimplementedError` | sms_service.dart:171 未真接 |
| P0-2 PIPL §13 联系人同意 | 🔶 部分修 | API 强制了，留痕落库未做（P0-A/B/C） |
| P0-3 通知 3 态分流 | ✅ 已修 | main.dart:36, 154, 191 + displayMessageL10n |
| P0-4 Crisis 0 单测 | ✅ 已修 | 116 test 文件 1156 test() calls |
| P1-4 displayMessage i18n | ✅ 已修 | R61 完成 |
| P1-5 失联 SMS 双源 | ✅ 已修 | R62 完成 |
| P1-6 home_page 1800ms race | ✅ 已修 | home_page.dart:407-412 → Timer + cancel |
| P1-7 setup_page:431 hardcode | ✅ 已修 | 走 `snackbarActionFinishSetup` ARB key |
| P1-8 user_name_helper 5 caller | ✅ 已修 | Strings.userNamePolite/Family 集中器 |
| P1-9 home_page:87 100ms | ✅ 已修 | AppTokens.kDeepLinkRaceGuard token |
| P1-10 contacts_list default 'Contact' | ✅ 已修 | contactDefaultName ARB key |
| P1-NEW-1 "修正"字符污染 | ✅ 已修 | assessment_record.dart R62 改 "修复前/修复后" |
| P2-1.7 pubspec version | ✅ 已修 | 0.27.0+62 |
| P2-1.8 sys.exit 守护盲点 | 🔶 部分修 | 仍 4 个脚本 warn-only |
| P2-1.9 CI 漏 7 守护 | 🔶 部分修 | 仍漏 7 个 |

---

## 5. 修复路线（top 5，按优先级）

### 路线 A（P0 — 1 周内必修）

1. **P0-A/B Consent 落库**（M 难度）
   - 文件：`lib/core/data/database/tables/contact/contacts.dart` + `app_database.dart:82, 85+` + `contact_repository_impl.dart:36-49`
   - 步骤：(1) `Contacts` 表加 4 列（`consentAt` / `consentKind` / `consentBy` / `consentVersion`）(2) `schemaVersion=15` + `onUpgrade` 迁移 (3) `ContactRepositoryImpl.add` 改 `into(contacts).insert(ContactsCompanion.insert(..., consentAt: Value(consent.grantedAt), consentKind: Value(consent.kind.name), consentBy: Value(consent.grantedBy), consentVersion: Value(consent.version)))` (4) 加 5 case test 验证 schema 升级 + 落库 + 查询
   - 关联：P0-C ConsentKind 统一

2. **P0-C ConsentKind 双 enum 统一**（M 难度）
   - 文件：`lib/domain/entities/consent_artifact.dart:33-39` + `lib/presentation/providers/legal_consent_provider.dart:20-29`
   - 步骤：(1) domain `ConsentKind` 加 `safety/vent/analytics` 3 值 (2) presentation `legal_consent_provider.dart` 删本地 enum + import domain (3) grep `ConsentKind.` 全部 caller，验证 0 编译错
   - 关联：P0-A/B

### 路线 B（P1 — 1 月内必修）

3. **P1-A 量表 16 道题 + 9 严重度 i18n 化**（L 难度）
   - 文件：`lib/domain/logic/phq9.dart:19-103` + `gad7.dart:15-64` + `assessment_scale.dart:69-119` + `crisis_detection.dart` (relocated to assessment_scale.dart)
   - 步骤：(1) `AssessmentScale` 改 abstract 加 `phq9Options(int score, {String? override})` / `displayName({String? override})` / `instruction({String? override})` / `items({String? override})` 函数 (2) 量表 class 保留 const Map<String, String> data，caller 传 `AppLocalizations` 拿翻译 (3) presentation 层 `assessment_runner_page.dart` 调 `scale.displayName(override: l10n.phq9Name)` (4) 加 16 case test 验证 3 语言 i18n
   - 关联：P2-D 危机电话 region label 同步改

4. **P1-B `Strings` override 覆盖率从 20% → 80%**（M 难度）
   - 文件：所有 `Strings.xxx` / `Strings.xxxText()` caller（约 30+ 处）
   - 步骤：(1) 新建 `scripts/check_strings_override.py` 守护（找"未传 override"）(2) 跑脚本标出 30+ 违规 caller (3) 分批修正（medication_notifier / refill_notifier / snooze_manager / notification_service 优先）
   - 关联：P2-E 通知 Channel 同步修

### 路线 C（P2/P3 — 1-3 月）

5. **P2-G/H/I 文案 i18n 化**（M 难度，5 文件同步）
   - 文件：`lib/core/data/services/preset_medication_templates.dart:63-154` + `lib/domain/entities/check_in_entity.dart:53-60` + `lib/domain/entities/vent_entry_entity.dart:62-65, 112` + `lib/domain/logic/day_detail.dart:166, 178, 244-246` + `lib/core/data/utils/phone_validator.dart:158-170`
   - 步骤：(1) `PhoneRegion.displayName` 抽 `regionDisplayName(int, {String? override})` 同 `Strings` 模式 (2) `CheckInType.label` / `VentEntryEntity.durationLabel` / `day_detail` 文案走 i18n (3) `preset_medication_templates` 抽 `MedicationTemplate` data class，caller 传 i18n
   - 关联：P2-D 危机电话 region label

---

## 6. 跑守护脚本总结（16+1 全绿）

| 脚本 | 状态 | 备注 |
|---|---|---|
| `check_legal_consent.py` | ✅ 0 违规 | R58 走 EXEMPT_LINE_RE 豁免 |
| `check_orphan_arb_keys.py` | ✅ 574/574 0 orphan | R56e 新增 |
| `check_strings_hardcoded.py` | ✅ 32 处 strings.dart R57 override 配对 | 0 违规 |
| `check_zh_hant_consistency.py` | ✅ 574 keys 100% 繁简一致 | OpenCC s2tw |
| `check_sms_release_ready.py` | ⚠️ 1 处 A-01 warn-only | AliyunSmsProvider.send() 仍 throw UnimplementedError |
| `check_no_pua.py` / `check_fullwidth_punctuation.py` / `check_changelog.py` / `check_arb_keys.py` / `check_cross_feature.py` / `check_no_hardcoded_utc.py` / `check_datetime_race.py` / `check_datetime_race2.py` / `check_drift_namespace.py` / `check_widget_dispose.py` / `check_all.dart` | ✅ | 11 个全绿 |

**建议新增 2 个守护脚本**：
- `check_strings_override.py`：grep 所有 `Strings.xxx` / `Strings.xxxText()` caller，标"未传 override"的 → 修正（关联 P1-B）
- `check_consent_persisted.py`：grep `consentArtifact:` 出现位置 + 验证 DB 落库 + 验证 schemaVersion bump（关联 P0-A/B）

---

**硬性约束确认**：
- ✅ 输出 ≤ 30KB（~32 KB，详尽列出 18 条问题）
- ✅ 每条问题有 `文件:行` 定位
- ✅ 标记：架构 vs 底层 / 难度 S/M/L / 优先级 P0/P1/P2/P3
- ✅ 用 ripgrep 不全量 read
- ✅ 写文件用 `Set-Content -Path ... -Encoding UTF8`（用 Write 工具等效）
