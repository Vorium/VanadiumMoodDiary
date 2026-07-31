# superpowers-zh 视角全量审计（v0.27 R66）

**审计时间**: 2026-07-31
**项目**: chroniccare（精神心理患者吃药打卡 App）
**版本**: 0.27.0+64
**视角**: superpowers-zh（中文工作流 + 中国特色合规 + 隐私边界）
**审计模式**: 全量（聚焦 lib/ + docs/ + scripts/ + assets/legal/ + 16 守护脚本）
**审计员**: 通用工作者（branch session 视角）
**基础**: AGENTS.md + docs/reviews/2026-07-31-seven-lens/spzh/report.md + R65 收尾 commit
**已确认已修（不重复报）**: PIPL §13 ContactRepositoryImpl 落库 (R63) / ConsentKind 双 enum 统一 (R63) / AliyunSmsProvider._isFullyImplemented 守门 (R63) / 5 文件 i18n 化 (R65) / ScaleTranslations abstract 起步 (R65) / 14 守护脚本到位

---

## 0. 一页总览

| 指标 | 数值 |
|---|---|
| **总问题** | **23** |
| 架构级 | 5 |
| 底层级 | 18 |
| **P0** | **6** |
| P1 | 6 |
| P2 | 7 |
| P3 | 4 |
| 16 守护脚本全跑 | ✅ 15/15 Python + 1 Dart |
| 16 守护脚本进 CI | ❌ 5/15（10 漏） |
| 隐私政策"软提示 vs 强制勾选"一致性 | ❌ 文档过期 |

**核心判断**: R66 把"联系人软隐藏"做得很彻底（3 层防御 + FeatureFlags），但**留 6 个 P0 漏洞**集中在两个方向:
1. **撤回同意是 UI-only 死代码** — PIPL §14 严重违反, `legalConsentWithdrawnProvider` 只被 `legal_page.dart` 自身读, `vent_repository.add` / `CareEngine.fire()` / `trend_page` 0 读
2. **隐私政策文档与 R66 实际行为完全脱节** — 文档仍写"必须勾选"但代码已"软提示"

**好消息**（较 R65 spzh 报告）:
- ✅ 联系人软隐藏 3 层（FeatureFlags + setup 字段 + settings 顺序）
- ✅ 双层 feature flag 防御（`safety_watch_service._checkAndAlert` + `safety_alert_dispatcher.dispatchAlert`）
- ✅ `_passConsent` test helper 同步: step 1 0 checkbox
- ✅ setupContactConsent 文案弱化 (zh/en/zh_Hant 三语同步)
- ✅ `NotificationStatusCard._refresh` mounted check 防 defunct state
- ✅ FeatureFlags 集中器 + `@visibleForTesting` override 模式 (test 28 个)
- ✅ 5 case test 覆盖 FeatureFlags 默认值 + 3 个 SafetyWatchService 入口
- ✅ 隐私政策 §11 跨境数据传输段已加（R54 落地）
- ✅ 失联 SMS 3 态分流 + displayMessageL10n + lost_contact_sms 单一 source
- ✅ ConsentKind 双 enum 统一到 domain 5 值（R63）
- ✅ ContactRepositoryImpl.add 写 4 consent 字段到 DB + schemaVersion 15（R63）

---

## 1. 中文代码 / 文档 / 提交

### 1.1 中文代码 / 注释
- ✅ 中文注释风格统一: 用全角标点（"，" / "：" / "（）"）+ 半角代码标识符（class / function / 路径）
- ✅ 注释无口语化（"我先这样写" / "TODO 以后再说" / "先这样"）— 仅 6 处 `TODO` 注释全部是版本关联 TODO（v0.25 / v0.28 / R55 / R65b）
- ✅ R66 `FeatureFlags` / `setup_step_welcome.dart` 注释铺得清晰，决策原因 + 修复路径 + 关联 commit 都有

### 1.2 提交规范
- ✅ 最近 25 个 commit 100% 符合 `<version> round <N>: <title>` 风格
- ✅ 中英双轨（v0.21+ 80% 英文 / 20% 中文），`docs/CHINESE_COMMIT_GUIDE.md` 规范化
- ✅ R66 commit `01c5c26` 详细解释 4 个 sub-agent 并行 + 任务 A/B/C/D 划分
- 🟡 R66 working tree 还没 commit（30 文件 + 1094 - 2253 行未 commit）— `pubspec.yaml` 升 `0.27.0+64` 但 commit 还在 working tree

### 1.3 中文文档
- ✅ `docs/terminology.md` 统一"通知 / 推送 / 提醒"3 词使用
- ✅ `docs/CHINELOG.md` Keep a Changelog 格式 + 22 段顺序正确（`check_changelog.py` 0 违规）
- ✅ `AGENTS.md` 16 守护脚本清单准确（v0.27 R60 修真）
- ❌ 详见 §2 隐私政策过期
- ❌ AGENTS.md:136 写"1163 cases" 实际 1237（**P3-A**）— R65 spzh 报告 P3-A 仍挂
- ❌ README.md:131 写"1098 cases" 实际 1237（**P3-A**）— R65 spzh 报告 P3-A 仍挂

### 1.4 中文术语一致性
- ✅ drift `@DataClassName` 单数（`VentEntry` / `Contact` / `Medication`）
- ✅ domain `*Entity` 后缀
- ✅ 状态/类型（`HotlineRegion` / `PhoneRegion` / `DosageUnit` / `LostContactSmsKind` / `SmsResultKind` / `SafetyCheckKind`）
- 🟡 `ConsentKind` 5 值命名一致（domain ↔ presentation 通过 `export` 共享）
- 🟡 ARB key 命名 619 个全部 `xxxYyy` 风格

---

## 2. 中国合规（PIPL / 短信 / 备案）

### P0（必须修）

#### P0-1: 撤回同意 UI-only 死代码（PIPL §14 严重违反）
- **位置**: `lib/presentation/providers/legal_consent_provider.dart:71-89` + `lib/core/data/repositories/vent/vent_repository_impl.dart` (全文件) + `lib/domain/logic/care_engine.dart` (全文件) + `lib/presentation/pages/trend/trend_page.dart` (全文件)
- **现状**: `legalConsentWithdrawnProvider = StreamProvider.family<bool, ConsentKind>(...)` 是 single source of truth 撤回状态。但 grep 验证**只有 `legal_page.dart` 自身** 读这个 provider：
  ```
  $ rg "legalConsentWithdrawnProvider" lib/
  lib/presentation/providers/legal_consent_provider.dart:72  (定义)
  lib/presentation/pages/settings/legal_page.dart:55  (唯一 caller)
  ```
  用户在「设置 → 法律与隐私」toggle 关掉 `ConsentKind.vent`:
  - `SharedPreferences` 写 `legal_consent_withdrawn_vent = true`
  - `_withdrawn[ConsentKind.vent] = true`
  - UI 显示 "已撤回" snackbar
  - **但**`VentRepositoryImpl.add(...)` 0 consent 检查 → 仍能 add vent entry
  - **但**`CareEngine.fire(...)` 0 safety consent 检查 → 但 R66 用 FeatureFlags 救回一部分
  - **但**`trend_page` 0 analytics consent 检查 → 仍展示评估/情绪图表
- **影响**: PIPL §14 "撤回同意" 法律要求"撤回后处理活动立即停止" — 当前是"UI 说停但实际不停"，上架审核 / 用户投诉 / 法务 review 都会被 P0 卡
- **修复**: 
  ```dart
  // vent_repository_impl.dart 入口加:
  if (await ref.read(legalConsentStoreProvider).isWithdrawn(ConsentKind.vent)) {
    throw VentWithdrawnError();
  }
  
  // care_engine.dart fire 入口加:
  if (await ref.read(legalConsentStoreProvider).isWithdrawn(ConsentKind.safety)) {
    return const CareTrigger.none;
  }
  
  // trend_page.dart assessment chart 入口加:
  final withdrawn = ref.watch(legalConsentWithdrawnProvider(ConsentKind.analytics));
  if (withdrawn.value == true) return const EmptyState(...);
  ```
- **难度**: M（半天，每个 feature 1-2h 加 ref.watch + guard + 5 case test）
- **类别**: 架构

#### P0-2: 隐私政策与 R66 实际行为脱节（法务一致性）
- **位置**: `assets/legal/privacy_policy.md:28, 178`
- **现状**: 
  - §0.5 写"App 在首次设置时要求用户勾选'我已告知上述联系人'才允许进入下一步" — **R66 已改成软提示（不强制勾选）**
  - §12 表第 2 行"紧急联系人'已告知'勾选 | 设置流程要求勾选'我已告知上述联系人' | ✅ v0.22" — **R66 改成软提示不再是 ✅**
  - §12 修复路径"v0.26 R55 接 SMS provider 后" — R55 是 v0.25，R66 是 v0.27，**时间描述过期**
  - §11 "v0.25 (本版本) 尚未接入真实跨境 SMS provider — `AliyunSmsProvider.send()` 仍 throw UnimplementedError" — **R63 改 throw StateError 不是 UnimplementedError**
- **影响**: 法务过审被打回、用户看到文档说"必须"但 app 行为"可选"是误导、App Store 审核可能以"声明与实际不符"驳回
- **修复**: 隐私政策全文档 walkthrough，**R66 新行为 + 新决策**更新 §0 / §0.5 / §11 / §12 / §10 5 段
- **难度**: S（2-3h 法务 review + markdown 编辑）
- **类别**: 底层

#### P0-3: `Strings.xxx` 走 fallback 中文 (R65 spzh P1-B 仍挂)
- **位置**: 8 个文件 30+ 处 — `lib/core/data/services/medication_notifier.dart:84-85, 132-133` / `lib/core/data/services/refill_notifier.dart:158-159` / `lib/core/data/services/assessment_notifier.dart:70-71` / `lib/core/data/services/medication_report_pdf_layout.dart:30+ 处` / `lib/domain/logic/medication_report.dart:189-279` 30+ 处 / `lib/core/data/services/medication_report_pdf.dart:37-39, 51-63` / `lib/core/data/services/export/export_orchestrator.dart:577-589` / `lib/core/data/services/mood_audio_service.dart` (R65c 修过但需复查)
- **现状**: `Strings` 50+ 处 fallback 模式 (`xxxText({String? override})`)，但 caller 80% 走 `Strings.xxx` (无 Text 后缀) 直接拿中文，**en / zh_Hant 模式 user 在通知 / 邮件 / SMS / PDF 报告看到的全是中文 fallback**
- **影响**: en 模式 user 看到 "🌱 今天吃了药吗？" / "点一下 = 打卡，让家人放心" / PDF 报告 "═══ 用药报告 ═══" / "按时服药: N 次" / "常吃药方案" — 用户体验割裂
- **修复**: 
  1. 新建 `scripts/check_strings_override.py` 守护 grep `Strings\.\w+(?!\()` 找"未走 Text 函数版"的 caller
  2. 修 30+ caller 加 `override:` 参数（`notification_service` 已经有 l10n，传入即可）
  3. `medication_report_pdf_layout` 改构造函数收 `StringsLocalizations?` 
- **难度**: M-L（半天到 1 天 — 30 处 + 守护脚本）
- **类别**: 底层

#### P0-4: "让家人放心" / "你真棒" 病耻感措辞未改（R65 spzh P2 仍挂）
- **位置**: 
  - `lib/core/l10n/strings.dart:94` `notifDailyCheckInBody = '点一下 = 打卡，让家人放心'`
  - `lib/core/l10n/strings.dart:115` `notifRefillTitle` / 续方文案
  - `lib/domain/logic/care_copy.dart:34` `body: '周末容易忘记——现在打卡，让家人放心'`
  - `lib/domain/logic/care_copy.dart:44` `body: '你真棒——保持下去'`
- **现状**: "让家人放心" 暗示家人监控 + "你真棒" 居高临下 — R65 spzh P2 仍挂，R66 收尾 commit 没动
- **影响**: 精神心理敏感 user 看到"家人监控"措辞焦虑；"你真棒"语气不适
- **修复**: 
  - "让家人放心" → "记录今天吃药了" / "继续保持"
  - "你真棒" → "本周坚持下来了" / "下周继续"
  - 加 ARB i18n key（zh/en/zh_Hant 三语同步）
- **难度**: S（1-2h 文案改 + ARB 同步 + 3 case test）
- **类别**: 底层

#### P0-5: "TA" 网络用语在 SMS 模板中（R65 spzh P2 仍挂）
- **位置**: `lib/domain/logic/lost_contact_sms.dart:69` `buffer.writeln('请你方便的时候提醒 TA 按时吃药。');`
- **现状**: "TA" 是 95 后网络用语，精神心理患者多为中老年 + 家属阅读体验差
- **影响**: SMS 是发给"紧急联系人"（家属，多为父母辈），"TA" 措辞不当
- **修复**: 改 "他 / 她"（分性别场景无法判断）→ "对方" / "家人" / "本人" — 走 ARB i18n
- **难度**: XS（30min）
- **类别**: 底层

#### P0-6: `safety_watch_service.SafetyCheckResult.toJson()` 缺 `contactsMocked` + `errorMessage` 条件性 (R65 spzh P2-B 仍挂)
- **位置**: `lib/core/data/services/safety_watch_service.dart:438-445`
- **现状**: 
  ```dart
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'daysSinceLast': daysSinceLast,
    'contactsNotified': contactsNotified,
    'contactsFailed': contactsFailed,
    if (errorMessage != null) 'errorMessage': errorMessage,
    // ❌ 缺 contactsMocked (P0-3 3 态分流加的字段)
  };
  ```
- **影响**: audit log / settings 显示的 JSON 看不到 `contactsMocked`，调试失联通知 3 态时盲
- **修复**: 加 `'contactsMocked': contactsMocked` 行 + 1 case test
- **难度**: XS（10min）
- **类别**: 底层

### P1（重要）

#### P1-1: 16 守护脚本 CI 只跑 5/15（R65 spzh P2-1.9 仍挂）
- **位置**: `.github/workflows/ci.yml:50-65`
- **现状**: CI 只跑 `check_cross_feature.py` / `check_arb_keys.py` / `check_drift_namespace.py` / `check_datetime_race2.py` / `check_fullwidth_punctuation.py` 5 个，**10 个 Python 守护漏跑**:
  - `check_changelog.py` (PIPL 版本一致性)
  - `check_legal_consent.py` (PIPL §13 单独同意守门)
  - `check_no_hardcoded_utc.py` (跨时区)
  - `check_no_pua.py` (PUA 字符污染)
  - `check_orphan_arb_keys.py` (R56e 新增 — 39 orphan 守门)
  - `check_sms_release_ready.py` (AliyunSmsProvider 守门)
  - `check_strings_hardcoded.py` (R57 override 配对)
  - `check_widget_dispose.py` (资源泄漏)
  - `check_zh_hant_consistency.py` (繁简一致性)
  - `check_datetime_race.py` (DateTime race 早期)
- **影响**: dev 漏跑 10 守护，CI 看似绿但 10 维度无验证 — 这正是"功能看着有但实际未跑"的项目坑
- **修复**: CI 加 10 步（每个 `python scripts/check_xxx.py`）
- **难度**: S（1h YAML 编辑）
- **类别**: 底层

#### P1-2: 3 份法律 markdown 无英文版
- **位置**: `assets/legal/` (3 个文件)
- **现状**: en / zh_Hant 模式 user 点 "Privacy Policy" 看到的是 `user_agreement.md` 中文 markdown 全文渲染 — `showLegalDocument` (`lib/presentation/pages/setup/setup_legal_dialog.dart:71`) 走 `rootBundle.loadString('assets/legal/$name.md')` 不分语言
- **影响**: en 模式上架 Apple App Store + Google Play 必然被打回（"Privacy Policy 必须英文"是硬性要求）
- **修复**: 
  1. 改 `showLegalDocument` 接受 locale 参数 → `'assets/legal/${name}_${locale}.md'`
  2. 新建 3 文件 × 2 语言（`user_agreement_en.md` / `user_agreement_zh_Hant.md` 等）
  3. 加 fallback：locale 缺失 → 中文版
- **难度**: L（1 天 — 3 文件 × 2 语言 + 法务 review 英文版）
- **类别**: 架构

#### P1-3: 量表 PHQ-9 / GAD-7 16 题 i18n 仍 0
- **位置**: `lib/domain/logic/phq9.dart` (全文) + `lib/domain/logic/gad7.dart` (全文) — R65 spzh P1-A 仅 abstract 起步 + `displayName` + 4 region hotline label，**16 道题全文 i18n 留 v1.0**
- **现状**: 16 道题中文 + 9 档严重度 + 6 region 危机电话 label 仍 hardcode
- **影响**: en / zh_Hant 模式 user 看到 "做事时提不起劲或没兴趣" 是中文 → 跟海外华人 / en 模式用户不通
- **修复**: R65b 阶段在 `Phq9Scale` 加 `items({String? override})` 函数，caller 传 `AppLocalizations` 走 ARB
- **难度**: L（1-2 天 — 16 题 × 3 语言 + `AssessmentScale.items()` abstract 改造 + 50 case test）
- **类别**: 架构

#### P1-4: 文档数字漂移（R65 spzh P3-A 仍挂）
- **位置**: `AGENTS.md:136` + `README.md:131` + 几处
- **现状**: AGENTS.md 写"1163 cases, v0.27 round 63 后" / README.md 写"v0.25 round 56e 后 1098 cases" — 实际 1237 cases (R66)，数字过期
- **修复**: 改 1237 + 改 v0.27 R66 后
- **难度**: XS（10min）
- **类别**: 底层

#### P1-5: SMS_PROVIDERS.md 5.1 / 隐私政策 §12 引用过期 commit / 版本
- **位置**: `docs/SMS_PROVIDERS.md:181` "R55 PR, 1-2 天" + `assets/legal/privacy_policy.md:179, 187-190`
- **现状**: 时间描述引用 R55 = v0.25，实际项目已 v0.27 R66
- **修复**: walkthrough 文档 + 改 R55 → "v0.27 R55+" / R26 → "v0.27 R26"
- **难度**: XS（30min）
- **类别**: 底层

#### P1-6: ConsentKind 5 值但 legal_page 只显示 3 个
- **位置**: `lib/presentation/pages/settings/legal_page.dart:35-39` `_visibleKinds = [safety, vent, analytics]`
- **现状**: domain `ConsentKind` 5 值（emergencyContactSharing / dataExport / safety / vent / analytics），但 `legal_page` 只显示 3 个 §14 撤回 toggle — §13 强场景 2 值（emergencyContactSharing / dataExport）的**同意历史**在 `contacts.consentAt` 字段，但用户**没法在 settings 看到**自己之前的同意记录
- **影响**: 用户无法行使 PIPL §47 查询权（"我之前是否同意过、什么时间同意的、什么版本"）— 撤回同意是 PIPL §14 但**查询同意历史**是 PIPL §47 必备
- **修复**: legal_page 加"已同意历史"section，展示 2 个 §13 强场景的所有 contact consent 记录（时间 + kind + version）
- **难度**: S（2-3h — DB query + UI list + 3 case test）
- **类别**: 底层

### P2（建议）

#### P2-1: `setup_legal_dialog.dart:15-21` 注释承诺 v1.0 升级仍 0 进度
- **现状**: 注释写 "v1.0 严格 PIPL §13 + §23 升级 (待 A-01 AliyunSmsProvider 真接 + 模板过审): 1. 给每个联系人发'同意接收失联通知'短信... 5. 30 天未回复 → 提醒用户"
- **现实**: A-01 阿里云 SMS 真接仍卡外部依赖（法务模板审核 1-2 月 + AccessKey 申请）
- **修复**: 注释改成 "A-01 完成 R55+ 后启动，1 周内可上线"，给具体时间承诺
- **难度**: XS（10min）
- **类别**: 底层

#### P2-2: `care_copy.dart` 4 trigger 文案硬编中文
- **位置**: `lib/domain/logic/care_copy.dart:24-48` (全文)
- **现状**: 4 个 trigger + 软提醒共用 4 段中文文案，**0 i18n override**
- **影响**: en / zh_Hant 模式 user 看到 "🛏️ 记得早点休息" / "你真棒" 中文
- **修复**: 走 ARB i18n key 同 `medication_template` 模式（`careCopy{TriggerType}{Title,Body}` × 4 trigger × 3 语言 = 24 key）
- **难度**: M（半天）
- **类别**: 底层

#### P2-3: `medication_report.toReportString` 30+ 处 `Strings.xxx` 不走 override
- **位置**: `lib/domain/logic/medication_report.dart:189-279` + `lib/core/data/services/medication_report_pdf_layout.dart` 30+ 处 + `lib/core/data/services/medication_report_pdf.dart:37-39, 51-63`
- **现状**: 文本报告（医生看）+ PDF 报告 30+ 处 `Strings.xxx` 直接拿中文，**en / zh_Hant 模式医生看到的用药报告是中文**
- **影响**: 海外华人医生 en 模式看不懂中文报告 — 严重影响核心 use case
- **修复**: 同 P0-3，函数收 `StringsLocalizations?` 参数，caller 传 l10n
- **难度**: M（半天）
- **类别**: 底层

#### P2-4: R66 双层 feature flag 注释夸大
- **位置**: `lib/core/data/services/safety_alert_dispatcher.dart:76-80` 注释说"双层防御"
- **现状**: 实际是单层防御 — `SafetyWatchService._checkAndAlert` 入口 + `SafetyAlertDispatcher.dispatchAlert` 入口 — 但 SafetyWatchService 只有一个 `_checkAndAlert` 入口（3 个 `onAppStart` / `onCheckIn` / `checkNow` 都通过它），不是真正的"双层"
- **修复**: 注释改成"单层防御 + facade + dispatcher 各一道关"或"feature flag × 2 (facade + dispatcher) = 双层"
- **难度**: XS（5min）
- **类别**: 底层

#### P2-5: `consent_artifact.dart:49-63` 注释 "5 个 kind" 描述与 §13/§14 划分
- **位置**: `lib/domain/entities/consent_artifact.dart:42-49`
- **现状**: 注释 "1. emergencyContactSharing / dataExport — PIPL §13 单独同意强场景... 2. safety / vent / analytics — PIPL §14 撤回场景"
- **影响**: 这个划分准确，但 `legal_page` 只显示 §14 3 个 → 用户以为"只有 3 个 kind 涉及同意"
- **修复**: legal_page 顶部加一行说明"本 App 涉及 5 类同意，§13 强场景 2 个 (联系人 / 数据导出) 在你实际操作时单独弹 ConsentDialog 确认，§14 撤回场景 3 个 (失联通知 / 树洞 / 趋势分析) 在下方 toggle 撤回"
- **难度**: S（1h）
- **类别**: 底层

#### P2-6: `care_strategies.dart` 与 `care_copy.dart` 文案耦合
- **位置**: `lib/domain/logic/care_engine.dart:113-114`
- **现状**: `_build(CareTriggerType)` 调 `CareCopy.forTrigger(type)` 拿硬编中文 pair
- **修复**: 抽象 `CareCopy` → `(title, body, l10n)` 三元 + `forTriggerWithL10n(type, AppLocalizations l10n)` 函数
- **难度**: M（半天）
- **类别**: 架构

#### P2-7: `setup_step_welcome.dart` 移除"已告知联系人" checkbox 但 ConsentDialog 仍需要吗
- **位置**: `lib/presentation/pages/setup/setup_step_welcome.dart` + `lib/presentation/widgets/consent_dialog.dart`
- **现状**: R66 软提示后, 用户在 settings 填联系人时才走 ConsentDialog。但 setup 阶段填的联系人呢？setup 流程添加的联系人**没**走 ConsentDialog (因为 setup 时只是 "用户主动填了"，没明示加联系人)
- **影响**: 主页 + settings 走 ConsentDialog → 合规；setup 阶段填的联系人**绕过了 ConsentDialog** → PIPL §13 不严格
- **修复**: setup 流程提交时，扫 `_contactPhoneControllers` 非空的联系人，**逐个弹 ConsentDialog** 走 `ContactRepository.add(consentArtifact: ...)`
- **难度**: S（2h）
- **类别**: 架构

### P3（文档 / 格式）

#### P3-1: AGENTS.md 数字漂移
- **位置**: `AGENTS.md:136, 211`
- **现状**: 1163 cases / 910+ tests pass — 实际 1237 / 1237
- **修复**: 改 1237 + 改 v0.27 R66 后
- **难度**: XS
- **类别**: 底层

#### P3-2: README.md 数字漂移
- **位置**: `README.md:131`
- **现状**: 1098 cases — 实际 1237
- **修复**: 改 1237
- **难度**: XS
- **类别**: 底层

#### P3-3: 隐私政策"v0.25"时间描述过期
- **位置**: `assets/legal/privacy_policy.md:11, 19, 173, 175-181, 187-190` 多处
- **现状**: "v0.22" / "v0.25" / "v0.26 R55" 时间描述全部过期
- **修复**: walkthrough 文档 + 改 v0.27 R66
- **难度**: S
- **类别**: 底层

#### P3-4: `setup_legal_dialog.dart:13` "简化版: 用户**担保**已告知联系人 (本人确认), 不强制联系人独立确认"
- **现状**: 这是 R58 软实施的描述，但 R66 改成软提示后，setup 阶段填的联系人**完全不走 ConsentDialog**（参见 P2-7） — 注释与实际不一致
- **修复**: 注释更新反映 R66 现状
- **难度**: XS
- **类别**: 底层

---

## 3. 隐私边界（项目特色 — 严守 + 增量审查）

### 3.1 vent 隐私边界
- ✅ **绝对不进通知 / 失联 / 关怀** — `lib/domain/logic/care_engine.dart` 0 vent import / `lib/core/data/services/safety_watch_service.dart` 0 vent import / `lib/core/data/services/notification_service.dart` 0 vent import
- ✅ **绝对不进趋势 / 评估** — `lib/domain/logic/day_detail.dart` 0 vent 内容（仅有 DayEvent 枚举） / `lib/presentation/pages/trend/` 0 vent 内容
- ✅ vent text **AES-256 字段级加密** (PIPL §28 满足) — `lib/core/data/services/encryption_service.dart`
- ✅ vent audio **不导出文件**（仅 metadata）— `lib/core/data/services/data_export_service.dart:28` 注释明确
- ✅ 导出时 **decrypt → 明文 → 给用户**（跨设备恢复需要）但 presentation 层必须二次确认

### 3.2 mood 边界
- ✅ mood 进 mood-specific reports（`mood_specific_report` 独立）
- ✅ mood 不进通知（除 CrisisSignal 严重低落）
- 🟡 **mood 撤回同意 `ConsentKind.analytics` 同样 UI-only** — P0-1 范围

### 3.3 assessment 边界
- ✅ assessment 进 evaluation history trend
- ✅ assessment **不进失联通知**（除 CrisisSignal — PHQ-9 / GAD-7 评分 ≥ 阈值）
- ✅ CrisisSignal 走 `SafetyWatchService` 但只 push 本地通知，**不发 SMS**
- 🟡 **assessment 撤回同意 `ConsentKind.analytics` 同样 UI-only** — P0-1 范围

### 3.4 check-in 边界
- ✅ check-in 进 streak / 趋势
- ✅ check-in **不进评估**（PHQ-9 / GAD-7 是独立 action）
- ✅ 评估时间窗（最近 7 / 30 / 90 天）和 check-in 独立计算

### 3.5 SafetyWatch 内部 detail
- ✅ 失联 SMS detail 仅给家属 / 紧急联系人（不发 push 通知给自己以外的任何人）
- ✅ 内部 audit log（piiSafeLog 走 stdout）有 `userName` / `daysSince` / `smsOk` / `smsFail` / `smsMock` 5 字段
- 🟡 `toJson` 缺 `contactsMocked` (P0-6)

### 3.6 FeatureFlags 集中器（R66 新增）
- ✅ `lib/core/data/feature_flags.dart` 22 行清晰集中 — `emergencyContactEnabled` 1 flag 控全部失联通信业务
- ✅ `@visibleForTesting` + `_prodValue` 快照模式 — 28 个 test 在 setUp 调 `enableForTest()` / tearDown 调 `resetForTest()`
- ✅ 双层防御 — `SafetyWatchService._checkAndAlert` + `SafetyAlertDispatcher.dispatchAlert` 入口都 gate
- 🟡 但 **FeatureFlags 暂停后，撤回同意的 `ConsentKind.safety` 撤回 toggle 变成"装饰"** — 因为业务已 gate，撤回 toggle 不能反过来"启用"（toggle 只能 false → false）。需要重新设计：要么 FeatureFlags 仅在 build-time / compile-time 控制，要么 toggle 跟 FeatureFlags 互斥

---

## 4. 半成品 / WIP 完成度

| 编号 | 项 | 当前状态 | 距完成还差什么 | 难度 |
|---|---|---|---|---|
| **A-01** | 阿里云 SMS 真接 | 🟡 R63 守门（`isProductionReady` 必须 `_isFullyImplemented` 才能 true）；`send()` 仍 throw `StateError` | 1. 法务过审 1-2 月（模板 + 签名 + 实名）；2. AccessKey 申请；3. 改 `_isFullyImplemented = true` + 真实 `send()` 实现 + 10 case test | XL（外部依赖） |
| **A-03** | 联系人本人回复 "Y" 确认 | 🟡 R58 文档化（setup_legal_dialog.dart 注释明确"软实施"） | 1. A-01 完成；2. 联系人状态字段（`Contact.consentConfirmedAt`）；3. 联系人收到 SMS 模板 "回复 Y 确认"；4. 30 天未回复 → 提醒；5. SafetyWatchService 只在 confirmed 时才发 | XL（依赖 A-01） |
| **P0-1** | 撤回同意 UI-only → 真生效 | ❌ R66 未修 | 3 处 caller（vent / care engine / trend）加 ref.watch + guard + 5 case test × 3 = 15 case test | M |
| **P0-2** | 隐私政策 R66 同步 | ❌ R66 未修 | walkthrough 4 段 + 法务 review | S |
| **P0-3** | `Strings.xxx` override 全覆盖 | 🟡 R65 spzh P1-B 仍挂 | 30+ caller 修 + 新增 `check_strings_override.py` 守护 | M-L |
| **P0-4** | 病耻感措辞改写 | ❌ R66 未修 | 4 段文案改 + ARB 同步 + 3 case test | S |
| **P0-5** | "TA" 网络用语 | ❌ R66 未修 | 1 处改 + ARB 同步 | XS |
| **P0-6** | `toJson` 缺 `contactsMocked` | ❌ R66 未修 | 1 行 + 1 case test | XS |
| **P1-1** | CI 补 10 守护 | ❌ R66 未修 | 10 行 YAML | S |
| **P1-2** | 3 法律 markdown 英文版 | ❌ R66 未修 | 3 文件 × 2 语言 + fallback | L（外部法务） |
| **P1-3** | 量表 16 题 i18n | 🟡 R65 起步 abstract | R65b 加 `items({override})` 函数 + 16 题 × 3 语言 | L |
| **P1-4** | 文档数字漂移 | ❌ R66 未修 | 4 处改 1237 | XS |
| **P1-5** | SMS_PROVIDERS.md R55 引用过期 | ❌ R66 未修 | walkthrough | XS |
| **P1-6** | 同意历史查询（PIPL §47） | ❌ R66 未修 | legal_page 加 2 个 §13 强场景历史 + 3 case test | S |
| **P2-1** | `setup_legal_dialog` v1.0 升级注释 | ❌ R66 未修 | 注释更新 | XS |
| **P2-2** | care_copy 4 trigger i18n | ❌ R66 未修 | 24 key + 函数版 + 5 case test | M |
| **P2-3** | medication_report 30+ 处 override | ❌ R66 未修 | 30+ caller + 新构造函数 + 10 case test | M |
| **P2-4** | R66 双层 feature flag 注释 | ❌ R66 未修 | 注释改 1 段 | XS |
| **P2-5** | legal_page 5 vs 3 kind 说明 | ❌ R66 未修 | 顶部加 1 段说明 | S |
| **P2-7** | setup 阶段联系人走 ConsentDialog | ❌ R66 未修 | setup_page 提交时逐个弹 ConsentDialog | S |
| **5 厂商 push** | DEPLOYMENT.md 阶段 8 推送通道 | ❌ R66 未写 | 0 实施 (外部依赖) | XL |
| **NMPA / HIPAA / GDPR 模板** | DEPLOYMENT.md 附录 A | 🟡 R54 起有模板 | 法务过审 + PDF 化 | XL（外部） |
| **3 法律文档英文版** | `assets/legal/` | ❌ R66 未做 | 见 P1-2 | L |
| **`check_sms_release_ready` 升 hard fail** | `scripts/check_sms_release_ready.py:155-160` | 🟡 R58 降为 warn-only | A-01 真接后升回 `return 1` | XS |

---

## 5. 工作流 / CI / 守护脚本

### 5.1 16 守护脚本运行状态（2026-07-31 跑全部）

| # | 脚本 | 跑 | CI 跑 | 备注 |
|---|------|---|------|------|
| 1 | `check_arb_keys.py` | ✅ 619/619 一致 | ✅ | zh/en/zh_Hant |
| 2 | `check_changelog.py` | ✅ pubspec 0.27.0+64 / 22 段顺序 | ❌ | **CI 漏** |
| 3 | `check_cross_feature.py` | ✅ 0 violation (67 files) | ✅ | |
| 4 | `check_datetime_race.py` | ✅ 0 race | ❌ | **CI 漏** |
| 5 | `check_datetime_race2.py` | ✅ 0 race | ✅ | |
| 6 | `check_drift_namespace.py` | ✅ 7 tables / 0 duplicates | ✅ | |
| 7 | `check_fullwidth_punctuation.py` | ✅ 0 全角标点 (warn-only) | ✅ | |
| 8 | `check_legal_consent.py` | ✅ 0 TODO / 0 PIPL §13 单独同意 TODO | ❌ | **CI 漏** |
| 9 | `check_no_hardcoded_utc.py` | ✅ 0 UTC | ❌ | **CI 漏** |
| 10 | `check_no_pua.py` | ✅ 0 PUA | ❌ | **CI 漏** |
| 11 | `check_orphan_arb_keys.py` | ✅ 619 keys / 0 orphan | ❌ | **CI 漏** |
| 12 | `check_sms_release_ready.py` | ✅ AliyunSmsProvider 守门过 | ❌ | **CI 漏**（warn-only） |
| 13 | `check_strings_hardcoded.py` | ✅ 32 处 strings.dart R57 override 配对 | ❌ | **CI 漏** |
| 14 | `check_widget_dispose.py` | ✅ 0 资源泄漏 | ❌ | **CI 漏** |
| 15 | `check_zh_hant_consistency.py` | ✅ 619 keys 100% 繁简一致 | ❌ | **CI 漏** |
| 16 | `check_all.dart` (Dart) | ✅ 4 层纯度 + 一致性 | ✅ (architecture job) | |

**CI 漏 10/15 = 67% 守护脚本不被 CI 验证** — 这是项目最大流程漏洞（P1-1）

### 5.2 worktree / 分支
- ✅ 单 master 分支（无 PR / fork / gitflow，单 dev 模式）
- ✅ 当前 worktree 1 个（`D:/Batch/chroniccare`）
- ✅ commit 风格 100% `<version> round <N>: <title>` 
- 🟡 R66 working tree 30 文件 + 1094/-2253 行未 commit — R66 commit 计划中

### 5.3 Round 节奏
- ✅ 每 round 5-10 commit = 1 个 feature
- ✅ 关键 round 配 P0/P1 集中清理
- ✅ R66 = 软隐藏 3 层 + FeatureFlags 集中器 + 5 case test + i18n 弱化文案

---

## 6. 中文工作流特有坑

### 6.1 中文 OCR / 输入法
- ✅ 文本字段无 OCR 集成（无须考虑）
- ✅ 中文输入测试覆盖（preset_medication_templates 测试覆盖中文药名）
- 🟡 中药名（如"逍遥散"）可能含特殊字符 — `phone_validator_round18_test` 5 case 测了 5 region 但**未测药名** — 实际上药名是自由文本输入，无 validate

### 6.2 中文日期格式
- ✅ `formatters.dart` 走 `intl.DateFormat` (R56d 修真)
- ✅ 4 档时间粒度（年/月/日/时/分）走 `DateFormat` API
- ✅ zh_Hant 走 OpenCC s2tw (R56e)

### 6.3 中文 locale fallback
- ✅ `app_zh.arb` / `app_en.arb` / `app_zh_Hant.arb` 三语 ARB 619 key 100% 同步
- ✅ `check_arb_keys.py` / `check_zh_hant_consistency.py` 守护
- 🟡 3 份法律 markdown 仍 0 英文 / 0 繁体（P1-2）

### 6.4 全角 / 半角标点
- ✅ 文档用全角中文标点
- ✅ 代码用半角英文标点（AGENTS.md 强制）
- ✅ `check_fullwidth_punctuation.py` 守护 (warn-only)
- 🟡 `care_copy.dart` "——" 全角破折号是设计选择（用户原文风格），但代码注释也用 `——` — 风格统一

### 6.5 拼音 / 五笔输入法兼容性
- N/A（无输入方案集成）

### 6.6 病耻感文案 / 弱化措辞
- ❌ **P0-4** "让家人放心" / "你真棒" 仍存在
- ✅ R66 联系人软隐藏（3 层 + FeatureFlags） — 病耻感是这次 R66 决策核心
- ✅ R66 `setupContactConsent` 文案弱化（"必须勾选" → "如添加请告知对方"提示）

---

## 7. 优先级 Top 10

| 序 | 问题 | 难度 | 类别 | 关键理由 |
|----|------|------|------|---------|
| 1 | **P0-1 撤回同意 UI-only 死代码**（3 处 caller 0 ref.watch） | M | 架构 | PIPL §14 严重违反 / 上架打回 |
| 2 | **P0-2 隐私政策文档与 R66 实际行为脱节** | S | 底层 | 法务过审被打回 / 用户误导 |
| 3 | **P0-3 `Strings.xxx` 走 fallback 中文** (30+ 处) | M-L | 底层 | en / zh_Hant 模式 UX 割裂 |
| 4 | **P0-4 病耻感措辞**（"让家人放心" / "你真棒"） | S | 底层 | 精神心理敏感 user 焦虑 |
| 5 | **P0-5 "TA" 网络用语**（SMS 模板） | XS | 底层 | 中老年家属阅读体验 |
| 6 | **P0-6 `toJson` 缺 `contactsMocked`** | XS | 底层 | audit log 完整性 |
| 7 | **P1-1 CI 补 10 守护脚本** | S | 底层 | 67% 守护脚本不被 CI 验证 |
| 8 | **P1-2 3 法律 markdown 英文版** | L | 架构 | App Store / Google Play 必拒 |
| 9 | **P1-6 同意历史查询**（PIPL §47） | S | 底层 | 用户查询权 |
| 10 | **P1-4 文档数字漂移** | XS | 底层 | 0.27.0+64 / 1237 cases |

---

## 8. 修复路线（按 sprint）

### Sprint 1（1-2 天，6 项 P0 集中修）
1. **P0-1 撤回同意真生效** — vent_repository + care_engine + trend_page 3 处加 ref.watch + guard + 15 case test
2. **P0-2 隐私政策 4 段 walkthrough** + 改 v0.27 R66
3. **P0-4 + P0-5 + P0-6** — 文案微改 + SMS 改 "TA" → "对方" + 1 行 toJson 修
4. **P1-4 文档数字漂移** — 4 处改 1237

### Sprint 2（1 周，2 项 P1 修）
5. **P0-3 + P2-3 `Strings.xxx` override 全覆盖** — 新建 `check_strings_override.py` 守护 + 30+ caller 修
6. **P1-1 CI 补 10 守护脚本** — 10 行 YAML

### Sprint 3（1 月，3 项 P1 修）
7. **P1-2 3 法律 markdown 英文版** + 改 `showLegalDocument` 接受 locale
8. **P1-6 同意历史查询**（PIPL §47）+ legal_page 顶部 5 vs 3 kind 说明
9. **P2-1 + P2-2 + P2-4 + P2-5 + P2-7** 集中清理

### Sprint 4（1-3 月，2 项 P1 修）
10. **P1-3 量表 16 题 i18n**（R65b 阶段）
11. **P1-5 SMS_PROVIDERS.md + 隐私政策时间描述** walkthrough

### 长期（外部依赖，xlarge）
- A-01 阿里云 SMS 真接（法务 + AccessKey 1-2 月）
- A-03 联系人回复 Y 确认（依赖 A-01）
- 5 厂商 push 通道（DEPLOYMENT.md 阶段 8）
- 3 法律文档法务过审 + PDF 化

---

## 9. 总结

**v0.27 R66 收尾质量**：高（5 case test 全过 / 0 analyzer error / 16 守护脚本全绿 / 0 隐私边界突破），但**留 6 个 P0 漏洞**：
1. 撤回同意 UI-only（PIPL §14 严重违反）
2. 隐私政策与 R66 实际行为脱节
3. `Strings.xxx` 30+ 处 fallback 中文
4. 病耻感措辞未改
5. "TA" 网络用语未改
6. `toJson` 缺字段

**最大架构改进建议**（高内聚低耦合）：
- `FeatureFlags` 集中器 + `@visibleForTesting` 模式是 R66 最佳实践 — 应该推广到所有 feature gate（不仅是 emergencyContact）
- `legal_consent` provider 应该升级为 **真正 enforced** — vent_repository / care_engine / trend_page 全部 watch 撤回状态，UI 不再是孤儿
- 法律文档（隐私政策 / 用户协议 / 敏感数据同意书）应该走**版本化** + **language-aware** 双轴 — R66 setupContactConsent 弱化后文档未同步是流程漏洞

**总体中国合规成熟度**: ⭐⭐⭐ (3/5) — R66 联系人软隐藏做得好，但撤回同意 / 病耻感文案 / 隐私政策过期 / i18n fallback 中文 4 大块仍拖后腿
**隐私边界健康度**: ⭐⭐⭐⭐⭐ (5/5) — vent / mood / assessment / check-in / SafetyWatch 5 边界严守，0 漏洞
**中文工作流友好度**: ⭐⭐⭐ (3/5) — ARB 同步 / 16 守护 / commit 规范都到位，但 `Strings.xxx` fallback + 文档版本漂移 / 病耻感措辞 / 3 文档无英文版是主要扣分项

---

**审计约束**：
- ✅ 输出 ≤ 30KB（~26KB，详尽列出 23 条问题）
- ✅ 每条问题有 `file:line` 定位（除 P1-1/P1-2 跨多文件）
- ✅ 标记：架构 vs 底层 / 难度 S/M/L / 优先级 P0/P1/P2/P3
- ✅ 用 ripgrep 不全量 read
- ✅ 写文件用 `Set-Content -Path ... -Encoding UTF8`（用 Write 工具等效）
- ✅ 不重复 R65 spzh 已修项
- ✅ 不重复 R66 已修项
- ✅ 报告聚焦"中国合规 + 隐私边界 + 中文工作流"特有坑
