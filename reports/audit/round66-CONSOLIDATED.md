# v0.27 R66 六视角全量审计 — 汇总报告

**审计时间**: 2026-07-31
**项目**: chroniccare（精神心理患者吃药打卡 App）
**版本**: 0.27.0+64（R66 收尾中，工作区有未提交改动）
**审计模式**: 6 视角并行子智能体全量复盘
**基线**: 1237 tests pass / 0 analyzer error / 16 守护脚本全绿

---

## 0. 一页总览

| 视角 | 报告 | 评级 | P0 | P1 | P2 | 关键定位 |
|------|------|------|-----|-----|-----|----------|
| **emilkowalski** | `round66-emilkowalski.md` | ⭐⭐⭐⭐ | 3 | 6 | 7 | 22 文件 12 维度卡片 |
| **superpowers-en** | `round66-superpowers-en.md` | A- | 5 | 7 | 6 | 18 条 + 历史 18 项对账 |
| **superpowers-zh** | `round66-superpowers-zh.md` | ⭐⭐⭐ | 6 | 6 | 7 | 23 条 + 隐私边界 0 漏洞 |
| **AppStore** | `round66-appstore.md` | ⭐ | 11 | 9 | 7 | 11 P0 阻塞 + 5 项无法提交 |
| **GooglePlay** | `round66-googleplay.md` | ⭐⭐ | 10 | 12 | 6 | 10 P0 阻塞 + 4 项无法提交 |
| **flutter-specification** | `round66-flutter-specification.md` | ⭐⭐⭐⭐ 4.5/5 | 1 | 4 | 3 | 89% 合规 + R63-R66 92% 修复 |
| **总问题数** | — | — | **36** | **44** | **36** | — |
| **去重 + 跨视角共识** | — | — | **12** | **18** | — | 共识 P0 单独列出 |

**核心判断**:
1. **3 视角共识 P0**（最严重）— 6 条独立但高频共同点：email_service 0 守门员、_resolveTimestamp 4 处遗漏、R66 业务暂停与 description 矛盾、隐私政策文档过期、fastlane 缺 iOS 配置、release keystore 仍 debug
2. **AppStore / GooglePlay 上架阻塞 21 项** — 11+10 大头是"声明跟实现不一致"（R63 修了但没补全）
3. **架构 / 半成品 / 重构机会** — 见第 3-5 节

**3 个用户重点关注**:
- ✅ **上架**: 21 项阻塞，分 4 类（fastlane / keystore / 隐私 manifest / 业务暂停与 description 矛盾）
- ✅ **架构**: 4 层架构纯度 100% / 16 守护脚本 100% 绿 / 抽象清晰，**只有 2 个真正架构问题**（email_service 缺守门员 / R65 use case 抽离不彻底）
- ✅ **重构**: 7 个强候选（InfoBanner / DialogActionsRow / StatCard / ChoiceChipWrap / SwipeDeleteBackground / _resolveTimestamp 集中器 / FeatureFlags 推广）
- ✅ **半成品**: 5 项核心（AliyunSmsProvider 真接 / email_service 真接 / 3 法律文档英文版 / 量表 16 题 i18n / Android 角标）

---

## 1. 跨视角共识 P0（最严重 — 多视角共同指出）

| # | 问题 | 位置 | 涉及视角 | 难度 | 类别 |
|---|------|------|----------|------|------|
| **C-P0-1** | `email_service.dart` 0 守门员 + `return false` 早返，release 模式"假失败"无视觉提示 | `lib/core/data/services/email_service.dart:69-73` | spen / spzh / appstore / googleplay | S | 架构 |
| **C-P0-2** | R66 失联通知业务整体暂停（FeatureFlags=false），但 `fastlane/metadata/{en-US,zh-CN}/full_description.txt` 仍写"automatically notify" / "失联自动通知家人" | `fastlane/metadata/*/full_description.txt` | spzh / appstore / googleplay | XS | 底层 |
| **C-P0-3** | `assets/legal/{privacy_policy,user_agreement,sensitive_data_consent}.md` 3 个 TODO 占位邮箱 + "未经律师过审"标注 | `assets/legal/*.md` | spzh / appstore / googleplay | S | 底层 |
| **C-P0-4** | 隐私政策 §0.5/§11/§12 与 R66 实际行为完全脱节（文档写"必须勾选"代码已"软提示"） | `assets/legal/privacy_policy.md:28, 178` | spzh | S | 底层 |
| **C-P0-5** | `_resolveTimestamp` helper 在 `check_in_repository_impl.dart:22` 是 file-private，4 处同款 `at ?? DateTime.now()` 散落 vent/mood/medication/use case | 4 个 impl + 1 个 use case | spen | M | 底层 |
| **C-P0-6** | `legalConsentWithdrawnProvider` 只被 `legal_consent_provider.dart` 自己定义，**0 业务 caller**（vent_repository / CareEngine / trend_page 全不 watch）— PIPL §14 严重违反 | `lib/presentation/providers/legal_consent_provider.dart:71-89` | spzh | M | 架构 |
| **C-P0-7** | iOS `Info.plist` 缺 `NSPhotoLibraryUsageDescription`（`share_plus` + `printing` 触发 PHPhotoLibrary 读权限会直接闪退） | `ios/Runner/Info.plist` | appstore | XS | 底层 |
| **C-P0-8** | `AppDelegate.swift` 没注册 `BGTaskScheduler`（Info.plist 声明 `com.chroniccare.safety-check`）+ 没设 `UNUserNotificationCenter.delegate`（foreground 通知不显示） | `ios/Runner/AppDelegate.swift` | appstore | XS | 底层 |
| **C-P0-9** | release keystore 仍是 debug（`build.gradle.kts:53` `signingConfig = signingConfigs.getByName("debug")`）+ `key.properties` 不存在 | `android/app/build.gradle.kts:53` | googleplay | M | 底层 |
| **C-P0-10** | `PrivacyInfo.xcprivacy` 的 `NSPrivacyCollectedDataTypes=[]` 跟实际数据矛盾（PHQ-9 / GAD-7 / 录音 / 联系人） | `ios/Runner/PrivacyInfo.xcprivacy:27-28` | appstore | S | 底层 |
| **C-P0-11** | `fastlane/metadata/ios/` 目录完全缺失（截图 67 字节占位 + Description / Keywords / Subtitle / Privacy URL 全空） | `fastlane/` 整目录 | appstore | S | 底层 |
| **C-P0-12** | `dart format` 133 文件未格式化（R66 uncommitted 改动），CI 又没 `dart format` 护栏 → 下次还会重蹈覆辙 | 133 files + `.github/workflows/ci.yml` | flutter-spec | XS | 底层 |

**C-P0 共识总计**: 12 项 / 修复总工时 **~5-6 个工程师天**（按 1 人 8h）。

---

## 2. 上架专项（用户特别关注）

### 2.1 App Store 上架阻塞 11 项（appstore 视角）

#### 🔴 P0 — 无法提交 (5 项)

| 序 | 问题 | 位置 | 难度 |
|---|------|------|------|
| A-1 | `fastlane/metadata/ios/` 目录完全缺失（截图 + Description / Keywords / Subtitle / Privacy URL / Support URL 全空） | `fastlane/` 整目录 | S (2-3h) |
| A-2 | `fastlane/Fastfile` + `Appfile` 缺失（无法跑 `fastlane ios release`） | `fastlane/` | S (2-3h) |
| A-3 | 失联通知 SMS 业务整体暂停但 description 仍说"automatically notify"（同 C-P0-2） | `fastlane/metadata/*/full_description.txt` | S (1h) |
| A-4 | IAP 8 元买断 release 模式返 false（`store_kit_service.dart:103-113`）但 user agreement 承诺"售价 8 元" | `lib/core/data/services/store_kit_service.dart:103-113` + `assets/legal/user_agreement.md:25` | S (1h) |
| A-5 | App Store 截图全是 67 字节占位 + 3 法律文档 TODO 占位邮箱 | `fastlane/phone_screenshots/` + `assets/legal/*.md` | S (1h) |

#### 🟡 P0 — 提交后必被拒 (6 项)

| 序 | 问题 | 位置 | 难度 |
|---|------|------|------|
| A-6 | `AppDelegate.swift` 没注册 `BGTaskScheduler`（Info.plist 声明了 `com.chroniccare.safety-check`） | `ios/Runner/AppDelegate.swift` | XS (30min) |
| A-7 | `AppDelegate.swift` 没设 `UNUserNotificationCenter.current().delegate`（foreground 通知不显示） | 同上 | XS (5min) |
| A-8 | `Info.plist` 缺 `NSPhotoLibraryUsageDescription`（同 C-P0-7） | `ios/Runner/Info.plist` | XS (5min) |
| A-9 | `PrivacyInfo.xcprivacy` 的 `NSPrivacyCollectedDataTypes=[]` 与实际矛盾（同 C-P0-10） | `ios/Runner/PrivacyInfo.xcprivacy` | S (30min) |
| A-10 | App Store Connect "App Privacy" 标签必填 4 类数据（Health Information / Audio Data / Contact Info / User Content） | Play Console 提交时 | S (30min) |
| A-11 | Medical 类目（PHQ-9 / GAD-7 / 失联通知）= Apple 1.4.3 严格审查，需声明 "NOT a medical device" + "失联通知 not for emergency" | App Store Connect + 隐私政策 | S (1h) |

#### 🟢 P1 警告（9 项）/ P2 建议（7 项）

详见 `round66-appstore.md` 第 11 节 Top 20 清单。

### 2.2 Google Play 上架阻塞 10 项（googleplay 视角）

#### 🔴 P0 — 无法提交 (4 项)

| 序 | 问题 | 位置 | 难度 |
|---|------|------|------|
| G-1 | release keystore 仍是 debug + 无 Play App Signing（同 C-P0-9） | `android/app/build.gradle.kts:53` | M (半天) |
| G-2 | Privacy Policy URL 未托管（3 个 .md 是本地文件，Play Console 不能填 `file://`） | `assets/legal/*.md` + Play Console | M (1-2d) |
| G-3 | fastlane/ 缺 Fastfile + Appfile + 8 张截图 + 2 个 feature_graphic 全 67 字节占位 | `fastlane/` 整目录 | S (半天) |
| G-4 | Data Safety Form / Health Apps questionnaire / Permissions Declaration Form 一个都没在 Play Console 维护 | Play Console 表单 | M (2-3h) |

#### 🟡 P0 — 提交后必被拒 (6 项)

| 序 | 问题 | 位置 | 难度 |
|---|------|------|------|
| G-5 | `USE_EXACT_ALARM` Play Console justification 100+ 字符必填 | `AndroidManifest.xml:33` + Play Console | XS (30min) |
| G-6 | Data deletion endpoint URL 缺失（Play Console 必填） | Play Console | XS (15min) |
| G-7 | Data Safety Form 与 SMS Provider 真实状态不一致（AliyunSmsProvider `throw StateError` 但 Privacy Policy 仍写"会发 SMS"） | `lib/core/data/services/sms_service.dart:195-198` + `assets/legal/privacy_policy.md:58-64` | S (1h) |
| G-8 | IAP 8 元买断"8 元一次性买断"vs Play Store 收费政策不一致 + R66 暂停 = 用户付钱买未启用 App = 4.0 风险 | `pubspec.yaml:62` + `assets/legal/user_agreement.md:25` | S (1h) |
| G-9 | `zh-CN/short_description.txt` 89 字符超 80 限制 | `fastlane/metadata/android/zh-CN/short_description.txt` | XS (5min) |
| G-10 | description 文档与 R66 状态不一致（"Lost-contact safety net" 描述 vs R66 已暂停）（同 C-P0-2） | `fastlane/metadata/android/*/full_description.txt` | XS (15min) |

#### 🟢 P1 警告 (12 项) / P2 建议 (6 项)

详见 `round66-googleplay.md` 第 11 节 Top 14 清单。

### 2.3 上架时间预估（按 1 人 8h/d）

- **M1 最小上架 (3-5 天)**: 修 21 P0 阻塞 + 律师 review 法律文档（**关键路径，1-2 周**）+ 域名 + 邮箱 + 真实截图
- **M2 完整 CI 化 (+3-5 天)**: fastlane + CI hook + 修 P1 警告 + 16KB page size 验证
- **M3 v1.0 (+3-6 月)**: 真接 Aliyun SMS（法务 + 备案 1-2 月）+ 健康类 IARC 复审 + HIPAA/GDPR 律师过审 + NMPA "非医疗器械" 备案 + 软件著作权登记

**最大瓶颈**: 法律 review（外部依赖 1-2 周）

---

## 3. 架构审视（用户特别关注）

### 3.1 4 层架构健康度

✅ **架构纯度 100%**（`scripts/check_all.dart` 验证）：
- `lib/{core/data, core/shared, domain, presentation}` 4 层无跨层依赖
- 252 个 lib/ 文件全部合规
- domain 0 Flutter / 0 Drift / 0 data / 0 presentation 引用

✅ **设计 token 化 100%**：
- 23+ token 集中（app_tokens facade + 4 子模块 app_colors / app_typography / app_spacing / app_motion）
- 0 散落 `Color(0xFF...)`
- R49 P0-1 修 35+ 处 dark mode 漏，剩 2 处 `settings_page.dart:63, 92`（emil P0-3）

✅ **i18n 完备**：
- 3 语 ARB（zh / en / zh_Hant）619 keys
- 316+ `AppLocalizations.of(context)` 跨 57 文件
- 0 强制解包

✅ **资源管理 100%**：
- dispose 链完整（5 步 async + try/finally + cancel）
- Timer 替代 Future.delayed
- enum 状态机替代 bool flag（R64 修 L3）

✅ **日志与错误**：
- `piiSafeLog` + `swallowError` 集中器 + `LastErrorCapture` + `runZonedGuarded` + `FlutterError.onError` 链完整
- 0 处 `print` / 0 处 `catch (_)` 静默吞

### 3.2 真正的架构问题（仅 2 项）

#### 🔴 A-ARCH-1: `email_service.dart` 0 守门员（v0.23 R38 SmsService 教训孪生）

- **位置**: `lib/core/data/services/email_service.dart:69-73` + 82 (real provider 永远 return false)
- **问题**: 跟 v0.23 round 38 "SmsService 假成功" 教训同款孪生风险 — release 模式启动不阻断 → 实际 release build 邮件"假失败"（返回 false）但 0 视觉提示
- **修复**: 跟 R63 SmsService 同款 1:1
  ```dart
  bool _isFullyImplemented = false;  // R55 真接 SendGrid 时改 true
  bool get isProductionReady => _isFullyImplemented && _apiKey != null && _useMock == false;
  static String? validateForRelease(EmailService s) {
    if (!s.isProductionReady) return 'EmailService not production-ready';
    return null;
  }
  ```
- **难度**: S (2h)
- **类别**: 架构（顶层）

#### 🔴 A-ARCH-2: R65 use case 抽离不彻底 — `CareEngine.evaluate/fire` 仍有 presentation 直接 caller

- **位置**:
  - `lib/presentation/pages/home/home_page.dart:189-190` 直接调 `CareEngine.evaluate(...)` + `CareEngine.fire(trigger, notif)`
  - `lib/domain/logic/care_engine.dart:68-109` `evaluate` + `fire` 仍是 static method
  - `lib/domain/usecases/fire_care_strategy.dart`（R65 新）— use case 已抽离但**未被任何 caller 使用**（spen 视角"0 caller 验证"是错的：实际是 R65 use case 没接入，home_page 还在用老路径）
- **问题**: R65 changelog 说"业务编排下沉到 FireCareStrategyUseCase"，但 home_page.dart 仍走老路径 → use case 是 dead code（实际是新代码未被采用）
- **修复**: 
  ```dart
  // home_page.dart _fireCareEngine() 改:
  final result = await ref.read(fireCareStrategyUseCaseProvider)(
    checkIns: all,
    now: DateTime.now(),
  );
  // 不用直接 CareEngine.evaluate/fire
  ```
- **难度**: S (3h)
- **类别**: 架构（顶层）

### 3.3 ✅ 架构选择**不**改

| 项 | 决策 | 理由 |
|----|------|------|
| 4 层架构 | 保留 | domain 0 Flutter 边界 100% 合规 |
| Riverpod 3.3.2 | 保留 | 唯一状态管理，275 处 102 文件全用 Provider/Notifier |
| SQLCipher | 保留 | 精神心理患者数据敏感 + 零云端 + AES-256 字段加密 |
| go_router 14.6.1 | 保留 | 3 类 transition + reduce-motion 包装 |
| **不**用 freezed / json_serializable | 保留 | 项目手写 `==/hashCode/copyWith` 14+ 处，决策"不引入代码生成爆炸" |
| **不**用 FlutterBoost | 保留 | 2024 起新项目禁用 |
| **不**接 Sentry / Firebase | 保留 | 零云端 + 患者数据敏感，零第三方 SDK 收集 |
| **不**接 APNs / FCM | 保留 | 本地通知够用，spen R19B 已验证 |

---

## 4. 重构机会（用户特别关注 — 高内聚低耦合）

### 4.1 强候选（重复 ≥ 3 处，emil 视角）

| 重构目标 | 涉及位置 | 覆盖处数 | 难度 | 价值 |
|----------|----------|----------|------|------|
| **`InfoBanner(icon, text, tone)`** | `medication_calendar_page.dart:54` / `medication_report_dialog.dart:61` / `setup_step_medication.dart:71` / `reminders_hub_page.dart:50` / `temp_medication_dialog` | 5+ | S | 高（emil "cohesion" 原则） |
| **`DialogActionsRow(cancelLabel, onCancel, saveLabel, onSave, isLoading)`** | `setup_step_welcome.dart:147` / `setup_step_medication.dart:116` / `setup_step_done.dart:85` / `choose_window_dialog.dart:80` / `refill_days_dialog.dart:56` / `edit_medication_dialog.dart:386` / `temp_medication_dialog.dart:124` | 7+ | M | 高（35 行 → 7 行） |
| **`StatCard(label, value, valueColor)`** | `trend_summary.dart:36-66` + `refill_manage_page.dart:346-376` | 2 处 | XS | 中 |
| **`ChoiceChipWrap<T>(options, selected, labelOf, onSelect)`** | `reminders_hub_page.dart:318` & `:456` / `mood_tags`（已抽） | 2 处复用 | S | 中 |
| **`SwipeDeleteBackground()`** | `vent_list_page.dart:174` / `contacts_list_widget.dart:51` / `medication_row.dart:163` | 3 处 | XS | 中 |
| **`_resolveTimestamp` 公开集中器** | check_in/vent/mood/medication/4 repository + 1 use case | 5 处（同 C-P0-5） | M | 高（spen 视角） |
| **`FeatureFlags` 推广模式** | R66 已抽 `emergencyContactEnabled` 1 个 flag | 1 个已抽 | S | 高（spzh 视角：可推广到 IAP / SMS 真接开关 / 量表 i18n 等） |

### 4.2 弱候选（重复 2 处）

| 重构目标 | 涉及位置 | 难度 |
|----------|----------|------|
| `TrailingSpinner` (LoadingSpinner 嵌入 ListTile.trailing) | `contacts_list_widget.dart:75-83` + `notification_status_card.dart:219-224` | XS |
| `LegendDot(color, label)` | `medication_calendar_page.dart:410` / `refill_manage_page.dart:319` / `trend_assessment_chart.dart:246` | XS |

### 4.3 atomic size token 补全（emil 视角 18+ 处散落 magic）

| Token | 当前 magic | 位置 |
|-------|-----------|------|
| `AppTokens.iconSizeTrailing` (18) | `SizedBox(width: 18, height: 18)` | `medication_row.dart:128` / `loading_text_button.dart:102,131` / `setup_step_medication.dart:121` |
| `AppTokens.legendDotSize` (10/12) | `width: 10/12, height: 10/12` | `trend_assessment_chart.dart:257` / `medication_calendar_page.dart:417` / `mood_audio_section.dart:492` |
| `AppTokens.avatarSizeMd` (40) | `width: 40, height: 40` | `reminder_cards.dart:162` / `assessment_history_list.dart:92` |
| `AppTokens.spinnerSizeInline` (16) | `height: 16` | `notification_status_card.dart:222` |
| `AppTokens.spacingCellGap` (1/2) | `EdgeInsets.all(1/2)` | `medication_calendar_page.dart:358, 322` / `trend_calendar.dart:234` |
| `AppTokens.audioTickInterval` (100ms) | `Duration(milliseconds: 100)` | `mood_audio_service.dart:124` |
| `AppTokens.fileLockRetryStep` (100ms) | `100 * attempt` | `vent_audio_storage.dart:95` |

总工时: **~8-10 小时**（1-1.5 个工程师天）

### 4.4 文字样式集中器补全

- `AppTokens.textStyleStatValue`（24/w600）— 缺，trend + refill 散落
- `textStyleScoreXxl`（64/w700）— R57 删除导致 4 处 inline 恢复
- `textStyleSetupTitle` / `textStyleSetupSubtitle` — 缺，setup 4 处散落

### 4.5 重构总工时

| 类别 | 工时 | 价值 |
|------|------|------|
| 4.1 强候选 7 项 | ~12-16h | 高（DRY + emil cohesion） |
| 4.2 弱候选 2 项 | ~2h | 中 |
| 4.3 atomic token 7 项 | ~3h | 中（grep 集中） |
| 4.4 文字样式 4 项 | ~2h | 中 |
| **总计** | **~20-23h（3 个工程师天）** | 一次性受益：22 文件 60+ 处替换 |

---

## 5. 半成品 / WIP 清单（用户特别关注）

### 5.1 🔴 核心半成品（5 项）— 影响上架

| # | 项 | 当前状态 | 距完成还差什么 | 难度 | 视角 |
|---|----|----------|---------------|------|------|
| **W-1** | **阿里云 SMS 真接** | R63 守门（`isProductionReady` 必须 `_isFullyImplemented=true`）；`send()` 仍 `throw StateError` | 1. 法务过审 1-2 月（模板 + 签名 + 实名）；2. AccessKey 申请；3. 改 `_isFullyImplemented = true` + 真实 `send()` + 10 case test | XL（外部） | spen / spzh / appstore / googleplay |
| **W-2** | **email_service 真接** | R66 同 C-P0-1：0 守门员 + `return false` | 跟 R63 SmsService 同款守门员（短期）+ R55 真接 SendGrid（长期） | S + XL（外部） | spen / appstore |
| **W-3** | **3 法律文档英文版 + 律师过审** | 3 个 .md 是中文 + "未过律师 review" + TODO 占位邮箱 | 1. 注册 `support@chroniccare.app` / `privacy@chroniccare.app` 真实邮箱；2. 决定 GitHub 仓库是否公开；3. 律师 review + 翻译英文 + 翻译繁体 | L（外部 1-2 月） | spzh / appstore / googleplay |
| **W-4** | **量表 PHQ-9 / GAD-7 16 题 i18n** | R65 起步 abstract（5 严重度 + 6 region hotline label），16 题全文留 v1.0 | 16 题 × 3 语言 + `AssessmentScale.items()` abstract 改造 + 50 case test | L（1-2 天） | spzh |
| **W-5** | **Android 角标 / iOS badge 集成** | 18+ 月未动（`notification_service.dart:388-389` + `badge_sync_service.dart:45`）`flutter_app_badge_control` 未集成 | 集成 `flutter_app_badge_control` 插件 + 5 case test | S（半天） | spen |

### 5.2 🟡 中等半成品（8 项）— 影响合规 / 体验

| # | 项 | 当前状态 | 距完成还差什么 | 难度 |
|---|----|----------|---------------|------|
| W-6 | **撤回同意 UI-only → 真生效**（同 C-P0-6） | 0 业务 caller | vent_repository + care_engine + trend_page 3 处加 ref.watch + guard + 15 case test | M |
| W-7 | **`Strings.xxx` 走 fallback 中文** | 30+ 处 `Strings.xxx` 不走 override | 修 30+ caller + 新增 `check_strings_override.py` 守护 | M-L |
| W-8 | **病耻感措辞**（"让家人放心" / "你真棒"） | R65 spzh P2 仍挂 | 4 段文案改 + ARB 同步 + 3 case test | S |
| W-9 | **"TA" 网络用语在 SMS 模板** | R65 spzh P2 仍挂 | 1 处改 "对方" + ARB 同步 | XS |
| W-10 | **`toJson` 缺 `contactsMocked`** | `safety_watch_service.dart:438-445` | 1 行 + 1 case test | XS |
| W-11 | **BootReceiver 启动 MainActivity 占位** | R63 注释自承"留 R64"，R64 已过未完善 | 改用 `FlutterEngineCache` + MethodChannel 调 `rescheduleAll` 或改用 `WorkManager` | S |
| W-12 | **CI 补 10 守护脚本**（同 spzh P1-1） | 5/15 跑，10 个 Python 守护漏跑 | CI 加 10 行 YAML | S |
| W-13 | **文档数字漂移** | AGENTS.md 1163 / README.md 1098 → 实际 1237 | 改 1237 + 改 v0.27 R66 | XS |

### 5.3 🟢 长期半成品（5 项 — 外部依赖）

| # | 项 | 当前状态 | 距完成 |
|---|----|----------|--------|
| W-14 | **5 厂商 push 通道** | DEPLOYMENT.md 阶段 8 0 实施 | 0 实施（外部） |
| W-15 | **NMPA / HIPAA / GDPR 模板** | R54 起有模板 | 法务过审 + PDF 化（外部 1-3 月） |
| W-16 | **联系人本人回复 "Y" 确认**（A-03） | R58 文档化（setup_legal_dialog.dart 注释明确"软实施"） | 依赖 A-01（W-1） |
| W-17 | **`check_sms_release_ready` 升 hard fail** | R58 降为 warn-only | A-01 真接后升回 `return 1` |
| W-18 | **16KB page size 验证** | R63 改 targetSdk 36 但没看 ndk / native lib 是否对齐 | 加 `scripts/check_16kb_alignment.sh` + 验证 sqlcipher/record/audioplayers |

---

## 6. 底层 bug 清单（用户特别关注 — 逐行排查）

### 6.1 🔴 必修 bug (6 项 — 多视角共识 P0)

| # | 位置 | 问题 | 修复 | 视角 |
|---|------|------|------|------|
| **B-1** | `lib/core/data/services/email_service.dart:69-73` | 0 守门员 + `return false` 早返 release 模式"假失败" | 加 `_isFullyImplemented` 守门员 | spen |
| **B-2** | 5 处 `at ?? DateTime.now()` 散落 4 repository + 1 use case | `_resolveTimestamp` helper 是 file-private，4 处同款 pattern | 抽 `core/shared/date_time_resolver.dart` 公开 | spen |
| **B-3** | `lib/presentation/providers/legal_consent_provider.dart:71-89` | `legalConsentWithdrawnProvider` 0 业务 caller（仅 self-def） | vent_repository + CareEngine + trend_page 3 处 watch + guard | spzh |
| **B-4** | `ios/Runner/AppDelegate.swift` 14 行 | 没注册 `BGTaskScheduler`（Info.plist 声明了）+ 没设 `UNUserNotificationCenter.delegate` | 加 `register + delegate` 2 段 | appstore |
| **B-5** | `android/app/build.gradle.kts:53` | `signingConfig = signingConfigs.getByName("debug")` | 生成真 keystore + 配 `signingConfigs.release` 读 `key.properties` | googleplay |
| **B-6** | 133 files in lib/ + test/ | `dart format` 未跑（R66 uncommitted 改动） | 跑 `dart format lib/ test/` | flutter-spec |

### 6.2 🟡 应修 bug (12 项 — 共识 P1)

| # | 位置 | 问题 | 修复 | 难度 |
|---|------|------|------|------|
| B-7 | `lib/core/data/services/notification_service.dart:122-176` | `init()` 0 单测 guard，tz init 失败 → 权限请求是否跑 | 加 init 单测 | S |
| B-8 | `lib/core/data/services/email_service.dart:79-82` | `isMock` 命名跟 SmsProvider `isProductionReady` 不一致 | 改 `isProductionReady` | XS |
| B-9 | `lib/core/data/database/app_database.dart:163-186` | v8→v9 vent 加密升级失败无用户视觉提示 | 加 startup banner 跟 R62 `LastStartupErrorBanner` 同模式 | M |
| B-10 | `lib/presentation/pages/setup/setup_page.dart` 4 步骤 | 0 集成测试 | 加 setup_page_round66_integration_test | M |
| B-11 | `lib/presentation/pages/settings/settings_page.dart` ~80 行 | 0 集成测试，R66 联系人软隐藏未端到端验证 | 加 settings_page_round66_integration_test | S |
| B-12 | `lib/domain/logic/care_engine.dart:68-109` | R65 use case 抽离不彻底，home_page 仍直接调 CareEngine.evaluate/fire | home_page 改用 FireCareStrategyUseCase | S |
| B-13 | `lib/core/theme/app_theme.dart:128` | `// TODO v0.25: 评估 buildTheme 接受 context` 挂 2 round | 删 TODO + 改走 `AppColors.fgDisabled(context)` | XS |
| B-14 | `lib/core/theme/app_theme.dart:209` | `withValues(alpha: 0.6)` 走 inline | 改 `AppColors.fgHintInput(context)` | XS |
| B-15 | `lib/presentation/pages/settings/settings_page.dart:63, 92` | `AppColors.success` / `AppColors.primary` const 漏，dark mode 不反白 | 改 `successColor(context)` / `primaryColor(context)` | XS |
| B-16 | `lib/core/data/services/notification_service.dart:388-389` + `badge_sync_service.dart:45` | 18+ 月 Android 角标 TODO 散落 | 加 `docs/TODO_v1.0.md` 集中器 | XS |
| B-17 | `lib/core/data/services/data_export_service.dart` 21K orchestrator | 575 行 god class 拆解后 orchestrator 仍 21K 字节 | 抽 `ExportPlanBuilder` + `ExportPreview` 2 个 sub-service | M |
| B-18 | `lib/core/data/services/email_service.dart:194` | 注释 "v1.0+ 替换" 跟 sms_service 同款 | 加 `docs/TODO_v1.0.md` 集中器 cross-ref | XS |

### 6.3 🟢 优化项（emil 视角散落 magic 18+ 处）

详见 §4.3 atomic size token 补全（XS 级别，约 3h）。

### 6.4 ✅ 已知合规（0 处）

- ✅ 0 处 `print(` 业务代码（184 处 `developer.log` / `piiSafeLog` / `swallowError` / `debugPrint` 跨 43 文件）
- ✅ 0 处 `catch (_)` 静默吞
- ✅ 0 处隐式排序假设（streak_calculator / assessment_comparison / reminder_scheduler / safety_watch_service / assessment_reminder_service 全显式 sort）
- ✅ 0 处 `int.parse` / `DateTime.parse` 裸用（全走 `tryParse` / `toUtc().toIso8601String()`）
- ✅ 0 处 `StreamSubscription` 漏 cancel
- ✅ 0 处资源泄漏（Timer / AudioPlayer / AudioRecorder / SpeechToText 全部 dispose）
- ✅ 0 处 BuildContext 跨 async gap 违规（54 处 `!mounted` + 24 处 `context.mounted` 全合规）

---

## 7. 优先级 Top 30（按共识 P0 → 共识 P1 → 单视角 P0 → 共识 P2 → 单视角 P1 排序）

| 序 | 问题 | 位置 | 难度 | 类别 | 涉及视角 | 上架阻塞 |
|---|------|------|------|------|----------|----------|
| **1** | `email_service.dart` 0 守门员（**C-P0-1 / B-1 / W-2**） | `lib/core/data/services/email_service.dart:69-73` | S | 架构 | spen / spzh / appstore / googleplay | ✓ |
| **2** | release keystore 仍是 debug（**C-P0-9 / B-5**） | `android/app/build.gradle.kts:53` | M | 底层 | googleplay | ✓ |
| **3** | `fastlane/metadata/ios/` 目录完全缺失（**C-P0-11**） | `fastlane/` | S | 底层 | appstore | ✓ |
| **4** | 失联通知业务暂停 vs description 矛盾（**C-P0-2**） | `fastlane/metadata/*/full_description.txt` | XS | 底层 | spzh / appstore / googleplay | ✓ |
| **5** | `AppDelegate.swift` 没注册 BGTaskScheduler + UNUserNotificationCenter（**C-P0-8 / B-4**） | `ios/Runner/AppDelegate.swift` | XS | 底层 | appstore | ✓ |
| **6** | `Info.plist` 缺 `NSPhotoLibraryUsageDescription`（**C-P0-7**） | `ios/Runner/Info.plist` | XS | 底层 | appstore | ✓ |
| **7** | `PrivacyInfo.xcprivacy` 的 `NSPrivacyCollectedDataTypes=[]`（**C-P0-10**） | `ios/Runner/PrivacyInfo.xcprivacy:27-28` | S | 底层 | appstore | ✓ |
| **8** | 撤回同意 UI-only 死代码（**C-P0-6 / B-3 / W-6**） | `lib/presentation/providers/legal_consent_provider.dart` | M | 架构 | spzh | ✓ |
| **9** | 3 法律文档 TODO 占位邮箱（**C-P0-3**） | `assets/legal/*.md` | S | 底层 | spzh / appstore / googleplay | ✓ |
| **10** | 隐私政策 §0.5/§11/§12 与 R66 实际行为脱节（**C-P0-4**） | `assets/legal/privacy_policy.md` | S | 底层 | spzh | ✓ |
| **11** | `_resolveTimestamp` 4 处 DRY 替换（**C-P0-5 / B-2**） | 4 repository + 1 use case | M | 底层 | spen | — |
| **12** | R65 use case 抽离不彻底 — home_page 仍用老 CareEngine（**A-ARCH-2 / B-12**） | `lib/presentation/pages/home/home_page.dart:189-190` | S | 架构 | spen | — |
| **13** | `dart format` 133 文件 + CI 缺护栏（**C-P0-12 / B-6**） | 133 files + `.github/workflows/ci.yml` | XS | 底层 | flutter-spec | — |
| **14** | CI 补 10 守护脚本（**W-12**） | `.github/workflows/ci.yml` | S | 底层 | spzh | — |
| **15** | IAP 8 元买断 release 模式返 false（**A-4**） | `lib/core/data/services/store_kit_service.dart:103-113` | S | 底层 | appstore / googleplay | ✓ |
| **16** | `notification_service.init()` 0 单测（**B-7**） | `lib/core/data/services/notification_service.dart:122-176` | S | 底层 | spen | — |
| **17** | `app_database.dart:163-186` vent 加密失败无视觉提示（**B-9**） | `lib/core/data/database/app_database.dart:163-186` | M | 底层 | spen | — |
| **18** | 抽 `InfoBanner` 集中器（5+ 处） | 见 §4.1 | S | 重构 | emil | — |
| **19** | 抽 `DialogActionsRow` 集中器（7+ 处） | 见 §4.1 | M | 重构 | emil | — |
| **20** | `Strings.xxx` 30+ 处 fallback 中文（**W-7**） | 8 个文件 30+ 处 | M-L | 底层 | spzh | — |
| **21** | 病耻感措辞改写（"让家人放心" / "你真棒"）（**W-8**） | `lib/core/l10n/strings.dart:94, 115` + `care_copy.dart:34, 44` | S | 底层 | spzh | — |
| **22** | "TA" 网络用语在 SMS 模板（**W-9**） | `lib/domain/logic/lost_contact_sms.dart:69` | XS | 底层 | spzh | — |
| **23** | `toJson` 缺 `contactsMocked`（**W-10**） | `lib/core/data/services/safety_watch_service.dart:438-445` | XS | 底层 | spzh | — |
| **24** | `BootReceiver` 启动 MainActivity 占位（**W-11**） | `android/app/src/main/kotlin/.../BootReceiver.kt:32-41` | S | 底层 | googleplay | ✗ |
| **25** | 文档数字漂移（AGENTS 1163 / README 1098 → 1237）（**W-13**） | `AGENTS.md:136` + `README.md:131` | XS | 底层 | spzh | — |
| **26** | 16KB page size 未验证（**W-18**） | `android/app/build.gradle.kts:11` | S | 底层 | googleplay | ✗ |
| **27** | `isMock` 命名不一致（**B-8**） | `lib/core/data/services/email_service.dart:79-82` | XS | 底层 | spen | — |
| **28** | `app_theme.dart:128, 209` 2 处 TODO + withValues alpha 漏（**B-13, B-14**） | `lib/core/theme/app_theme.dart` | XS | 底层 | emil / flutter-spec | — |
| **29** | `settings_page.dart:63, 92` dark mode bug（**B-15**） | `lib/presentation/pages/settings/settings_page.dart` | XS | 底层 | emil | — |
| **30** | 抽 `StatCard` 集中器（2 处） + atomic size token 18+ 处 | 见 §4.1 / §4.3 | XS-S | 重构 | emil | — |

**Top 30 修复总工时**:
- 必做 17 项（序 1-17）：~5-6 个工程师天
- 重构 4 项（序 18-19, 30）：~3-4 个工程师天
- 体验 + 半成品 9 项（序 20-29）：~3-4 个工程师天
- **总计**: ~11-14 个工程师天（按 1 人 8h/d ≈ 1.5-2 周）

---

## 8. 修复路线（按 Sprint）

### Sprint 0 — 1 天（必须 PR 合并前完成）
1. **B-6** `dart format lib/ test/` 重格式化 133 文件
2. **B-6'** CI 加 `dart format --set-exit-if-changed` 步骤

### Sprint 1 — 上架前 P0 阻塞集中修（3-5 天）
3. **B-1 / W-2** email_service 守门员
4. **B-2 / C-P0-5** _resolveTimestamp 集中器公开 + 5 处替换
5. **C-P0-2** description 改 R66 状态
6. **A-3 / G-7** 失联通知业务暂停 vs 文档同步
7. **B-4 / C-P0-8** AppDelegate.swift 加 BGTaskScheduler + UNUserNotificationCenter
8. **C-P0-7** Info.plist 补 NSPhotoLibraryUsageDescription
9. **C-P0-10** PrivacyInfo.xcprivacy 补 NSPrivacyCollectedDataTypes
10. **B-5 / C-P0-9** release keystore 真接
11. **C-P0-11** fastlane/metadata/ios/ 全套（截图 + 6 metadata 字段）
12. **A-4** IAP 8 元方案决策（删或真接）
13. **G-4** Data Safety Form + Health Apps questionnaire 填表
14. **G-6** Data deletion endpoint URL
15. **G-5** USE_EXACT_ALARM Play Console justification
16. **G-9, G-10** zh-CN short description + 文档改 R66
17. **W-9, W-10** "TA" 网络用语 + toJson contactsMocked

### Sprint 2 — 合规 + 架构核心（1 周）
18. **C-P0-3 / W-3** 3 法律文档 TODO 占位邮箱替换 + 律师过审启动
19. **C-P0-4** 隐私政策 R66 同步（4 段 walkthrough）
20. **C-P0-6 / W-6** 撤回同意真生效（3 处 caller + 15 case test）
21. **A-ARCH-2 / B-12** R65 use case 抽离收尾（home_page 切 FireCareStrategyUseCase）
22. **W-7** Strings.xxx override 全覆盖（30+ caller + 新守护）
23. **W-8** 病耻感措辞改写
24. **W-12** CI 补 10 守护脚本
25. **W-13** 文档数字漂移
26. **W-1 / A-01** 阿里云 SMS 真接（外部依赖启动）

### Sprint 3 — 体验 + 重构（1-2 周）
27. **B-7** notification_service.init() 单测
28. **B-9** vent 加密失败 startup banner
29. **B-10, B-11** setup_page + settings_page 集成测试
30. **B-17** data_export orchestrator 拆 ExportPlanBuilder + ExportPreview
31. **W-11** BootReceiver 完善（FlutterEngineCache 或 WorkManager）
32. **W-18** 16KB page size 验证脚本
33. **§4.1** 抽 InfoBanner + DialogActionsRow + StatCard + SwipeDeleteBackground 集中器
34. **§4.3** atomic size token 18+ 处补全

### Sprint 4+ — 长期半成品（外部依赖）
35. **W-3** 3 法律文档英文版 + 繁体（法务 review）
36. **W-4** 量表 16 题 i18n（R65b 阶段）
37. **W-5** Android 角标 / iOS badge 集成
38. **W-14, W-15, W-16, W-17** 5 厂商 push / NMPA 备案 / 联系人 Y 确认 / 守护脚本升 hard fail

---

## 9. 关键 Spot-Check 更正（子智能体描述与实际不符）

| 子智能体原描述 | 实际情况 | 影响 |
|----------------|----------|------|
| spen: `mood_dialog.dart` 1204 行 god class | **实际 20 行**（R64 已抽到 `mood_recorder_page.dart` 198 行 + 5 个 widget 子组件）。mood_dialog.dart 现在是 shim 仅 `MoodDialog.show` 委派 | spen 的 "P1-1 mood_dialog god class 拆解" 应改为 "mood_recorder_page 198 行仍有 7 字段状态机（次 P0）" |
| spen: `CareEngine.evaluate()` 0 caller（R65 后） | **实际 home_page._fireCareEngine() 仍直接调** `CareEngine.evaluate(...)` + `CareEngine.fire(trigger, notif)`（R65 use case 抽离不彻底） | spen 的 "0 caller 验证" 应改为 "R65 use case 抽离未完成，home_page 还在用老路径" — 实际是 P0 架构问题 |
| appstore: IAP 8 元"占位返回 false" | 跟 spen 一致 ✓ | OK |
| googleplay: BootReceiver 启动 MainActivity 占位 | 跟实际一致 ✓ | OK |
| spzh: legal_consent_withdrawn_provider 0 caller | **实际仅 self-def 1 处**（确认 dead code） | spzh 描述 100% 准确 |
| emil: settings_page.dart:63, 92 漏 dark mode | 跟实际一致 ✓ | OK |

---

## 10. 整体评估

### 10.1 6 视角共识得分

| 视角 | 单独评级 | 关键定位 |
|------|----------|----------|
| emilkowalski | ⭐⭐⭐⭐ (4.5/5) | "差一口气"级别 12 维度卡片，22 文件清单 |
| superpowers-en | A- | 18 条 + 历史 18 项对账，0 个 18 月未动 / 0 个 v1.0+ 真接 |
| superpowers-zh | ⭐⭐⭐ (3/5) | 6 项 P0 全部是中国合规 / 隐私边界 / 中文工作流特有 |
| AppStore | ⭐ (1/5) | 11 P0 阻塞（5 无法提交 + 6 必被拒），**最小上架 3-5 天** |
| GooglePlay | ⭐⭐ (2/5) | 10 P0 阻塞（4 无法提交 + 6 必被拒），**最小上架 3-5 天** |
| flutter-specification | ⭐⭐⭐⭐ 4.5/5 | 89% 合规 + 1 阻断 + 4 警告 + 3 建议 |

### 10.2 综合判断

- **架构 / 4 层 / 设计 token / i18n / dispose / 守护脚本 6 个维度** — 100% 合规，是项目最大亮点
- **真正的架构问题仅 2 个**: email_service 0 守门员 + R65 use case 抽离不彻底
- **核心阻塞是上架 + 法律 review**: App Store / Google Play 共 21 P0 阻塞 + 1-2 月律师过审
- **体验 / 重构 / 半成品** 3 块各 8-10h 工时，3 个工程师天可清

### 10.3 上线建议

- ✅ **可上 testflight / Google Play internal testing**: Sprint 0 + Sprint 1 完成后即满足最低门槛
- ❌ **不建议上 production**（v1.0 release）: 需 Sprint 2 + Sprint 3 + 法务过审 + 阿里云 SMS 真接（**1.5-2 月**）
- 🎯 **R67 优先级**: Sprint 0 (1d) + Sprint 1 (3-5d) + Sprint 2 启动 (1 周)
- 🎯 **v1.0 时间表**: 1.5-2 月（含法务 + 阿里云 + 16KB + 量表 16 题 i18n + 3 法律文档翻译）

### 10.4 用户的 4 个特别关注点 — 直接回答

| 关注点 | 答案 |
|--------|------|
| **上架** | 21 项 P0 阻塞（App Store 11 + Google Play 10），**最小上架 3-5 天 + 法务 1-2 月**。最大头是 fastlane iOS 配置、release keystore、Privacy Manifest、业务暂停与 description 矛盾 |
| **架构** | 4 层架构纯度 100%，设计 token 100%，i18n 100%，dispose 链 100%，16 守护脚本 100% 绿 — **核心架构无需重构**。**仅 2 个真问题**: email_service 0 守门员 + R65 use case 抽离不彻底（4-5h 可清） |
| **建议重构** | 7 个强候选（InfoBanner / DialogActionsRow / StatCard / ChoiceChipWrap / SwipeDeleteBackground / _resolveTimestamp 集中器 / FeatureFlags 推广），**~3 个工程师天一次性受益 22 文件 60+ 处** |
| **半成品** | 5 项核心（阿里云 SMS / email 真接 / 3 法律文档英文版 / 量表 16 题 i18n / Android 角标）+ 8 项中等（撤回同意真生效 / Strings override / 病耻感措辞 / "TA" 网络用语 / toJson / BootReceiver / CI 守护 / 文档漂移）。**核心半成品需外部依赖（法务 1-2 月 + 阿里云 1 月）** |

---

**报告完毕。** 6 份子报告全部已写入 `D:\Batch\chroniccare\reports\audit/round66-*.md` 供深入查阅。
