# GooglePlay 视角审计（v0.27 R68）

**审计时间**: 2026-08-02
**项目**: chroniccare
**版本**: 0.27.0+64（pubspec.yaml:4）— R67 收尾后
**视角**: Google Play Store 上架合规
**审计模式**: 增量（对照 R66 报告 + R67 架构变更报告）
**基线**: R66 10 P0 + 12 P1 + 6 P2,R67 Sprint 1 修 7 项(SMS/Email 守门员 / privacy 软隐藏 / 3 个新 doc / key.properties.example 路径 / privacy@ 软隐藏 / 描述加"暂停")

**项目基线**: 1237+ tests pass / 0 analyzer error / 16 守护脚本全绿
**新发现 (R68)**: FeatureFlags.iapEnabled 默认 `true` 但 release `buyLifetime()` 返 `false` = IAP 状态对用户不一致

---

## 1. 顶层架构审视（Android 集成架构）

### 1.1 架构评级（vs R66 对比）

| 维度 | R66 评分 | R68 评分 | Δ | 关键变化 |
|------|---------|---------|---|---------|
| **政策合规 (Policy)** | ⭐⭐ | ⭐⭐½ | ↑½ | R67 软隐藏 5 处 `privacy@` 占位 + 集中 TODO 到 `SPRINT1_LEGAL_TODO.md`;`support@` 仍 TODO;Play Console 三大表单一字未动 |
| **技术 (Technical)** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | = | R67 `signingConfigs.release` block 加(读 `key.properties`)但 build 仍 fallback debug;BootReceiver 仍占位启动 MainActivity |
| **元数据 (Store Listing)** | ⭐ | ⭐½ | ↑½ | R67 zh-CN `short_description` 89→14 字;`full_description` 双语加 "暂停" / "coming soon" 段;`Fastfile`/`Appfile` R66 写 Android 缺,R67 写的 iOS-only,Android 端 0 |
| **签名 (Signing)** | ⭐ | ⭐½ | ↑½ | R67 加 `signingConfigs.release` + `PLAYSTORE_SIGNING_GUIDE.md` 5 步指南,但 0 keystore + 0 `key.properties` + `signingConfig = debug` 仍 (`build.gradle.kts:80`) |
| **隐私 (Privacy)** | ⭐⭐ | ⭐⭐½ | ↑½ | R67 privacy@ 软隐藏 5 处,业务层 ConsentGate R67 真生效;support@ 仍 TODO;3 文档顶部 "未经律师过审" 标注全保留 |
| **数据安全 (Data Safety)** | ⭐ | ⭐ | = | Play Console Data Safety Form / Health Apps questionnaire / Permissions Declaration Form 一字未动(代码外) |

**整体判断** — **3.0 / 10**(跟 R66 持平)。R67 修了 7 项内部 hygiene,但上架阻塞 P0 仍 10 项缺 1 不可。**卡在"非代码"环节**: keystore / 域名 / 邮箱 / 律师 review / Play Console 表单。

### 1.2 Android 平台特定代码边界

| 边界 | 状态 | 证据 |
|------|------|------|
| **Platform-channel 集成** | ✓ 干净 | `lib/main.dart:1-25` 0 platform-channel 调用,Flutter 默认集成 |
| **Kotlin 平台代码** | ✓ 最小 | `MainActivity.kt` 空类 + `BootReceiver.kt` 42 行接收器 |
| **ProGuard 边界** | ✓ 完整 | `proguard-rules.pro:43-46` 加 `-keep class com.chroniccare.chroniccare.** { *; }` 防 R8 误删业务类 |
| **资源边界** | ✓ 5 个 xml 资源齐 | `backup_rules.xml` + `data_extraction_rules.xml` + `network_security_config.xml` + `mipmap-*` + `values/styles.xml` |
| **签名材料边界** | ✓ .gitignore 双层 | `android/.gitignore` 排 `**/*.jks`/`**/*.keystore`/`key.properties`;root `.gitignore:46-49` 兜底排 `*.jks`/`*.keystore`/`key.properties` |
| **BootReceiver 边界** | ⚠ 启动 MainActivity 占位 | `BootReceiver.kt:32-37` 走 `Intent(context, MainActivity::class.java)`,R66 §7.3 写"留给 R64 完善" — **R67 仍未动** |
| **Foreground Service** | ✓ 无 | 无 `FOREGROUND_SERVICE*` 权限声明,符合"flutter_local_notifications 不需要前台服务"约束 |
| **Data Safety ↔ 代码** | ⚠ 半不一致 | 隐私 §3 共享说"失联通知触发时...发给用户预设的紧急联系人"(R66 加"本版本不实际触发"声明,代码 `FeatureFlags.emergencyContactEnabled=false` 双层防御)— **R67 已对齐** |

### 1.3 Play App Signing / 密钥管理 / Data Safety 一致性

| 项 | 当前 | 应有 | 一致性 |
|----|------|------|--------|
| Release keystore | `signingConfigs.getByName("debug")` (`build.gradle.kts:80`) | `signingConfigs.getByName("release")` (R67 块已加,line 53-72) | ✗ 切线未拨 |
| Play App Signing | 0 keystore → 0 启用 | Play Console → App integrity → Enable | ✗ 阻塞 |
| `key.properties` | 不存在(`Test-Path` False) | 4 个真实值 | ✗ 阻塞 |
| `key.properties.example` | 存在(`android/key.properties.example:6-9` 模板) | — | ✓ 模板齐 |
| `*.jks` exclude | ✓ 双重 | — | ✓ 防御到位 |
| Data Safety Form | Play Console 一字未填(代码外) | 必填 4 类(收集/共享/删除/加密) | ✗ 阻塞 |
| Health Apps questionnaire | Play Console 一字未填 | 必填 4 问(medical device/medical prof/scientific/consult) | ✗ 阻塞 |

---

## 2. 底层逐行排查

### A. release 签名配置

| 位置 | 现状 | 修复 | 难度 |
|------|------|------|------|
| `android/app/build.gradle.kts:80` | `signingConfig = signingConfigs.getByName("debug")` | 改 `signingConfigs.getByName("release")` | XS |
| `android/app/build.gradle.kts:53-72` | `signingConfigs.release { ... }` block 存在,读 `key.properties` | — | (R67 已加) |
| `android/key.properties` | 不存在 | `cp key.properties.example key.properties` + 填 4 真实值 | XS |
| `android/app/chroniccare-release.jks` | 不存在 | `keytool -genkey -v -keystore chroniccare-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias chroniccare` | XS |
| `android/app/build.gradle.kts:46-48` 注释 | "上 store 前必须...3. 切 `signingConfig = signingConfigs.getByName('release')`" | 注释自承认 TODO | — |
| `docs/PLAYSTORE_SIGNING_GUIDE.md:1-178` | 5 步指南全 | — | ✓ (R67 新增) |

### B. AndroidManifest 权限

| 权限 | 行 | R68 状态 | R66 → R68 变化 |
|------|----|----------|---------------|
| `INTERNET` | `AndroidManifest.xml:30` | ✓ 必须 | 不变 |
| `POST_NOTIFICATIONS` | `:31` | ✓ 必须 | 不变 |
| `SCHEDULE_EXACT_ALARM` | `:32` | ✓ 必须 | 不变 |
| `USE_EXACT_ALARM` | `:33` | ✓ 必须 + **Play Console justification 文本仍未准备** | 不变 |
| `WAKE_LOCK` | `:34` | ✓ 必须 | 不变 |
| `RECEIVE_BOOT_COMPLETED` | `:35` | ✓ 必须 + BootReceiver 已实装(R63)但走占位路径 | 不变 |
| `VIBRATE` | `:36` | ✓ 必须 | 不变 |
| `RECORD_AUDIO` | `:37` | ✓ 必须 + **R66 §3.3 in-app rationale 仍未补** | 不变 |
| `uses-feature microphone` | `:40-42` | ✓ required=false | 不变 |

**R68 新发现 (B-1)**: `BootReceiver.kt:32-37` 仍走 `Intent(context, MainActivity::class.java)` 启动 MainActivity 占位路径,R66 §7.3 写的"用 FlutterEngineCache 复用 engine + MethodChannel 调 rescheduleAll"或"用 WorkManager" 方案 — **R67 未实现**。注释 `BootReceiver.kt:30-31` 自承认 "留给 R64 完善",R64/R65/R66/R67 4 轮未动。

### C. targetSdkVersion

| 项 | 值 | 位置 | R68 状态 |
|----|----|------|----------|
| `compileSdk` | `flutter.compileSdkVersion` (= 36) | `build.gradle.kts:10` | ✓ R63 显式 |
| `targetSdk` | **36** (R63 显式 pin) | `build.gradle.kts:32` | ✓ 超 2026 ≥ 35 要求 |
| `minSdk` | **24** (R63 显式 pin) | `build.gradle.kts:31` | ✓ |
| `ndkVersion` | `flutter.ndkVersion` (= 27.0.12077973) | `build.gradle.kts:11` | ✓ 16KB page size **未验** |
| `multiDexEnabled` | `true` | `:37` | ✓ |
| `enableOnBackInvokedCallback` | `true` | `AndroidManifest.xml:51` | ✓ R63 加 |

**16KB page size (R66 §2.1 P2)**: R67 未验。`sqlcipher_flutter_libs 0.6.4` 已 16KB 对齐(changelog),`record 5.2.0` + `audioplayers 6.1.0` 未确认。

### D. Privacy Policy URL

| 项 | R68 状态 | 位置 |
|----|----------|------|
| `assets/legal/privacy_policy.md` | ✓ 文档齐,205 行 | `assets/legal/privacy_policy.md:1-205` |
| 公网 HTTPS URL (`https://chroniccare.app/privacy`) | ✗ **未托管** | 域名未注册 |
| Privacy Policy URL Play Console 字段 | ✗ 空 | Play Console 侧 |
| Data deletion endpoint URL | ✗ 空 | Play Console 侧 |
| Developer email Play Console 字段 | ✗ 空(`support@chroniccare.app` 未注册) | Play Console 侧 |

### E. Data Safety Form

**Play Console 侧 0 维护**。R67 文档侧改了 5 处 `privacy@` 软隐藏,业务层 R67 ConsentGate 真正生效(`docs/LEGACY_API_NOTES.md:89-128`),但 Data Safety Form 仍需 4 类手动勾选:
- 数据收集(健康 / 联系人 / 录音 / 情绪文字 4 项 ✓)
- 数据共享(阿里云 SMS / SendGrid Email — R66 暂停, R67 加守门员,**勾 "未触发"**)
- 加密传输(HTTPS) / 加密存储(SQLCipher AES-256)
- 用户可控删除(App 内 + 卸载)

### F. Data deletion endpoint

`docs/SPRINT1_LEGAL_TODO.md:117` 写 "隐私 URL ... 已部署" checklist,但 R67 没部署。需建 `https://chroniccare.app/delete-data-instructions` 页面。

### G. fastlane metadata 缺失

| 文件 | 状态 | 字节数 | R66 → R68 |
|------|------|--------|-----------|
| `fastlane/Fastfile` | ✗ **Android lane 缺失** (R67 加的 Fastfile 是 iOS-only,`Fastfile:17` `default_platform(:ios)`) | 75 行 iOS only | iOS 修了,Android 仍 0 |
| `fastlane/Appfile` | ✗ **Android 配置缺失** (R67 加的 Appfile 是 iOS-only,`Appfile:19` `app_identifier("com.chroniccare.chroniccare")` 用于 iOS) | 25 行 iOS only | iOS 修了,Android 仍 0 |
| `fastlane/metadata/android/en-US/title.txt` | ✓ 27 字符,合规 | 27 字节 | 不变 |
| `fastlane/metadata/android/en-US/short_description.txt` | ✓ 70 字符,合规 | 70 字节 | 不变 |
| `fastlane/metadata/android/en-US/full_description.txt` | ✓ 2.5K,合规 + R67 加 "coming soon" 段 | 2.5K | ✓ |
| `fastlane/metadata/android/en-US/icon.png` | ✗ **1443 字节,192×192** (需 512×512) | 1443 字节 | ✗ 不变 |
| `fastlane/metadata/android/en-US/feature_graphic.png` | ✗ **67 字节占位** | 67 字节 | ✗ 不变 |
| `fastlane/metadata/android/en-US/phone_screenshots/screenshot_{1..4}.png` | ✗ **8 × 67 字节占位** | 8 × 67 字节 | ✗ 不变 |
| `fastlane/metadata/android/en-US/video.txt` | ✗ `https://www.youtube.com/watch?v=PLACEHOLDER_APP_DEMO_VIDEO` | 70 字节 | ✗ 不变 |
| `fastlane/metadata/android/zh-CN/title.txt` | ✓ 14 字符,合规 — **但仍写 "失联通知"** | 14 字节 | △ wording |
| `fastlane/metadata/android/zh-CN/short_description.txt` | ✓ 14 字符,合规(R67 砍到 14) | 14 字节 | ✓ 修了 |
| `fastlane/metadata/android/zh-CN/full_description.txt` | ✓ 2.2K + R67 加 "暂停" 段 | 2.2K | ✓ |
| `fastlane/metadata/android/zh-CN/icon.png` | ✗ 1443 字节,192×192 | 1443 字节 | ✗ 不变 |
| `fastlane/metadata/android/zh-CN/feature_graphic.png` | ✗ 67 字节占位 | 67 字节 | ✗ 不变 |
| `fastlane/metadata/android/zh-CN/phone_screenshots/screenshot_{1..4}.png` | ✗ 4 × 67 字节占位 | 4 × 67 字节 | ✗ 不变 |
| `fastlane/metadata/android/zh-CN/video.txt` | ✗ PLACEHOLDER URL | 70 字节 | ✗ 不变 |

### H. SMS Provider 与声明不一致

| 项 | R68 状态 | 位置 |
|----|----------|------|
| `AliyunSmsProvider.send()` | ⚠ 仍 `throw StateError('AliyunSmsProvider.send() R55 真接 TODO...')` | `sms_service.dart:194-198` |
| `AliyunSmsProvider._isFullyImplemented` | `false` (`sms_service.dart:136`) — **R63 加守卫** | ✓ |
| `AliyunSmsProvider.isProductionReady` | `_isFullyImplemented && 4 字段齐全` (`sms_service.dart:148-153`) | ✓ |
| `SmsService.validateForRelease` | release + mock → 抛 `SmsProviderNotConfiguredError` (`lib/main.dart:170` 调) | ✓ R62/R63 修 |
| `MockSmsProvider.isProductionReady` | `false` (`sms_service.dart:66`) | ✓ |
| `EmailService.isProductionReady` | R67 B-1 加(`email_service.dart` + `lib/main.dart:179` 调) | ✓ R67 新增 |
| `FeatureFlags.emergencyContactEnabled` | `false` 双层防御(`feature_flags.dart:35,53`) | ✓ R66 加 |
| Privacy Policy §3 共享段 | 写"失联通知触发时..."但加 R66 注释"本版本不实际触发" | `privacy_policy.md:64-72` | △ R66 加声明 |
| `assets/legal/user_agreement.md:25` | "本 App 售价人民币 8 元(Google Play / Apple App Store 统一定价),一次性买断,**不收取订阅费**" | ⚠ 与 IAP 真接状态不符(见 I) |

**结论**: 代码层 R62/R63 + R67 已对齐(SMS/Email 守卫 + FeatureFlags + 文档加"本版本不实际触发"),但 **代码层 throw StateError + 真接 TODO** 仍未消除(外部依赖,法务 1-2 月 + AccessKey 申请)。

### I. IAP 8 元买断

| 项 | R68 状态 | 位置 |
|----|----------|------|
| `in_app_purchase: ^3.3.0` | ✓ 依赖加 | `pubspec.yaml:62` |
| `StoreKitService.kLifetimeProductId` | `com.chroniccare.app.lifetime` 占位 | `store_kit_service.dart:50` |
| `StoreKitService.buyLifetime()` release | **返 `false`** | `store_kit_service.dart:118-119` (注释"占位返回 false (购买未开通)") |
| `StoreKitService.isPro()` release | 查 SharedPreferences 缓存(默认 `false`) | `store_kit_service.dart:69-73` |
| `FeatureFlags._prodIapEnabled` | **`true`** (R67 默认) | `feature_flags.dart:36` |
| `FeatureFlags.iapEnabled` getter | 公共读取 | `feature_flags.dart:62` |
| `lib/main.dart:187-191` | `if (FeatureFlags.iapEnabled) { await StoreKitService.warmup(); }` | — |
| `assets/legal/user_agreement.md:25` | 写"8 元一次性买断" | ⚠ 描述 vs release 行为不一致 |
| `fastlane/metadata/android/en-US/full_description.txt:25-29` | 0 处提"8 元"或 IAP | ✓ (没承诺买断) |
| `fastlane/metadata/android/zh-CN/full_description.txt:9, 30` | 0 处提"8 元"或 IAP | ✓ |
| Google Play Billing 配 | ✗ Play Console 侧未配 productId | — |

**R68 新发现 (I-1)**: `FeatureFlags._prodIapEnabled = true` (R67 C-7) 默认开启 IAP,**但** `StoreKitService.buyLifetime()` release 模式 `return false` (`store_kit_service.dart:119`) — 用户在 release 模式下进 App,看到 IAP 入口(没早返),点购买 → 永远失败。R67 注释 `store_kit_service.dart:59-60` 写"v0.28 才真接 productId" — 当前 release 模式是 IAP 不可用状态。

**R68 决策建议**:
- 选项 A: 临时把 `_prodIapEnabled = false` 关闭 IAP 入口(避 Apple 2.1 拒 / Play 拒"未提供其他购买方式") — R67 C-7 注释本意
- 选项 B: 真接 IAP(`com.chroniccare.app.lifetime` 创建 productId + 法务定价审核) — 外部依赖 v1.0

**R66 §6.8 P1 措辞**: 当前**未修**,且 R67 引入新不一致。Apple 跟 Google Play 都要求 IAP "可购买" 跟描述一致。

### J. R66 业务暂停与描述脱节

| 位置 | R66 → R68 状态 |
|------|----------------|
| `fastlane/metadata/android/en-US/full_description.txt:13-16` | ✓ R67 加 "(coming soon — currently disabled)" + "NOTE: This feature is currently disabled in this release..." |
| `fastlane/metadata/android/zh-CN/full_description.txt:17-19` | ✓ R67 加 "（即将上线 — 当前已暂停）" + "注：本功能在本版本已暂停..." |
| `fastlane/metadata/android/en-US/full_description.txt:14` | ⚠ **"can automatically notify your trusted contacts"** 仍写 "automatically notify" — R66 §6.11 措辞建议未改 |
| `fastlane/metadata/android/zh-CN/title.txt:1` | ⚠ **"慢病管家 - 吃药打卡 + 失联通知"** — title 仍写 "失联通知" 存在,R67 改 full_description 但 title 漏改 |
| `fastlane/metadata/android/en-US/title.txt:1` | ✓ "ChronicCare - Med Reminder"(无失联通知 wording) |
| `assets/legal/user_agreement.md:17` | ⚠ "**失联通知**(连续多日未打卡时,自动通知预设的紧急联系人)" — 写功能可用,SPRINT1_LEGAL_TODO.md:99-101 已标"R67 未改" |
| `assets/legal/sensitive_data_consent.md:27, 47, 64` | ⚠ "打卡时间...失联检测" + "失联通知无法启用" — 写功能可用,SPRINT1_LEGAL_TODO.md:99-101 标"R67 未改" |
| `assets/legal/privacy_policy.md:64-72` | △ "失联通知触发时...本版本不实际触发" R66 加声明 |
| `assets/legal/user_agreement.md:40` | ⚠ "因 SMS 通道未连接(默认 mock 状态)导致通知未发出" — 措辞"通道未连"≠"业务暂停" — SPRINT1_LEGAL_TODO.md:99-101 标"R67 未改" |
| In-app `NotificationService._resolveSafetyAlertBody` | ✓ 3 态分流(`safety_alert_builder.dart`, R60 修) |
| `lib/main.dart:148-158` | ✓ release 启动时 SmsService 守卫 + EmailService 守卫 |

### K. 紧急联系人 / 失联通知 / 录音

| 项 | 状态 | 位置 |
|----|------|------|
| 紧急联系人数据流 | 100% 本地 + AES-256 + `FeatureFlags.emergencyContactEnabled=false` 双层防御 | ✓ |
| 失联通知 SMS 触发 | **0 触发**(flag 关闭 + `AliyunSmsProvider._isFullyImplemented=false`) | ✓ |
| 失联通知描述 vs 实际 | ⚠ en-US full_desc 仍 "automatically notify" / zh-CN title 仍 "失联通知" | △ |
| Tree 录音 (vent) | 本地 AES-256 加密(`privacy_policy.md:53`) | ✓ |
| Mood 录音 | 本地 AES-256 加密(`privacy_policy.md:50`) | ✓ |
| `RECORD_AUDIO` 权限 | ✓ AndroidManifest.xml:37 声明 | ✓ |
| RECORD_AUDIO in-app rationale | ✗ R66 §3.3 P0 写"snackbar 显示'需要麦克风权限'但没引导用户去系统设置" — **R67 未修** | ⚠ |
| `backup_rules.xml` 排除 vent_audio + mood_audio | ✓ | `backup_rules.xml:14-16` |
| `data_extraction_rules.xml` 排除 vent_audio + mood_audio | ✓ | `data_extraction_rules.xml:14-15, 22-23` |
| 失联通知业务暂停文案 | Privacy §3 共享 / Privacy §0.5 紧急联系人告知 / Privacy §11 跨境 / Privacy §12 单独同意 / User Agreement §5 免责 — R66/R67 软隐藏已写,完整 | ✓ |
| PHQ-9 危机电话 6 region | ✓ R51 实装 | ✓ |

---

## 3. 上架阻断清单

### P0 提交必拒(8 项,vs R66 10 项 — R67 修了 2 项)

| # | 位置 | 问题 | 难度 |
|---|------|------|------|
| **P0-1** | `build.gradle.kts:80` + `android/key.properties` 不存在 + `android/app/chroniccare-release.jks` 不存在 | release 签名仍是 debug keystore → AAB 100% 拒 | **S** (半天) |
| **P0-2** | `assets/legal/privacy_policy.md` + Play Console 字段 | Privacy Policy URL 未托管到 HTTPS 公网 | **M** (1-2 天: 注册域名 + 部署 HTML) |
| **P0-3** | `assets/legal/user_agreement.md:60` + Play Console Developer email 字段 | `support@chroniccare.app` 仍是 TODO 占位,Play Console Privacy Contact Email 必填 | **XS** (1-2h) |
| **P0-4** | `fastlane/metadata/android/{en-US,zh-CN}/phone_screenshots/*.png` (8 × 67 字节) | 8 张截图全是 1x1 占位 PNG → Play Store 强校验必拒 | **S** (半天) |
| **P0-5** | `fastlane/metadata/android/{en-US,zh-CN}/feature_graphic.png` (2 × 67 字节) | 2 张 feature_graphic 全是 1x1 占位 | **XS** (1-2h) |
| **P0-6** | `fastlane/metadata/android/{en-US,zh-CN}/icon.png` (2 × 1443 字节, 192×192) | App icon 需 512×512,当前 192×192 | **XS** (1h) |
| **P0-7** | `lib/main.dart:170` + `sms_service.dart:194-198` + Privacy Policy §3 共享段 | SMS Provider 仍 `throw StateError`(`R55+` 真接 TODO),Privacy Policy 写"失联通知触发时...发给紧急联系人" — **R67 修了部分**(`FeatureFlags.emergencyContactEnabled=false` + `EmailService` 守门员 + 隐私 §3 加"本版本不实际触发"声明),但 `AliyunSmsProvider.send()` 实际 throw + Privacy Policy 业务层声明与 Play Console Data Safety Form 必填项尚未对齐 | **L** (1-2 月: 法务 1-2 月 + AccessKey 申请) |
| **P0-8** | `fastlane/Fastfile` + `fastlane/Appfile` (R67 加的 iOS-only) | Android 端 fastlane 配置 0(无 `platform :android` 块) | **S** (半天: 复制 iOS Fastfile 改 platform) |

### P0-2 提交后必拒(2 项 — 审核员抽查)

| # | 位置 | 问题 | 难度 |
|---|------|------|------|
| **P0-9** | `assets/legal/privacy_policy.md:3` + `user_agreement.md:3` + `sensitive_data_consent.md:3` | 3 文档顶部均标 "**TODO (上 store 前必须由专业律师过审)**" + "未经律师过审" → 抽查到 = 误导性陈述 + Developer Policy 4.8 违规 | **L** (律师 1-2 周,~¥15k-30k/文档) |
| **P0-10** | `fastlane/metadata/android/en-US/full_description.txt:14` + `zh-CN/title.txt:1` + `user_agreement.md:17,40` + `sensitive_data_consent.md:27,47,64` | 4 处文档写"失联通知"功能存在 + `AliyunSmsProvider.send()` throw + `FeatureFlags.emergencyContactEnabled=false` 业务暂停 — 文档与实际状态不一致 | **M** (1-2h: 改 4 处文档) |

### P1 警告(8 项,vs R66 12 项 — R67 修了 4 项)

| # | 位置 | 问题 | 难度 | 修复 |
|---|------|------|------|------|
| **P1-1** | `BootReceiver.kt:32-37` | BootReceiver 仍走 "启动 MainActivity" 占位路径,R66 §7.3 写"留给 R64 完善",**R67 未动** | **S** (2-3h) | 用 FlutterEngineCache + MethodChannel 或 WorkManager 替换 |
| **P1-2** | `vent_compose_page.dart:135-141` (R66 §3.3) | RECORD_AUDIO in-app rationale 缺失,用户"拒绝 + Don't ask again"后永久无法录音 | **S** (1-2h) | 加 PermissionDialog + openAppSettings() 引导 |
| **P1-3** | `assets/legal/user_agreement.md:25` + `store_kit_service.dart:119` + `feature_flags.dart:36` | IAP 8 元买断:用户协议写"8 元买断" / `FeatureFlags._prodIapEnabled=true` 默认开 / 但 `buyLifetime()` release 返 `false` — 描述与代码不一致 | **M** (半天) | 决策: 改 `_prodIapEnabled = false` 关闭 OR 真接 IAP |
| **P1-4** | `notification_status_card.dart` (R66 §3.4) | SCHEDULE_EXACT_ALARM Android 12+ Special App Access 引导缺失 | **XS** (1h) | NotificationStatusCard 加 1 行 |
| **P1-5** | `fastlane/metadata/android/en-US/short_description.txt:1` | "chronic patients" 措辞,Google Health Apps 政策建议改 "people managing chronic conditions" | **XS** (5min) | 改 1 行 |
| **P1-6** | `fastlane/metadata/android/{en-US,zh-CN}/video.txt` (2 文件) | 仍是 `PLACEHOLDER_APP_DEMO_VIDEO` 占位 URL,Play Console 报"无效视频链接" | **XS** (5min) | 删 2 个 video.txt(留空 OK)或录真视频 |
| **P1-7** | `build.gradle.kts:11` + 16KB page size | `ndkVersion` 显式依赖 Flutter 默认,R66 §2.1 提 16KB 对齐未验 | **S** (2-3h) | 写 `scripts/check_16kb_alignment.sh` 守门员 |
| **P1-8** | `build.gradle.kts` (无 abiFilters) | 64-bit ABI 显式声明缺失(Flutter 默认含 arm64-v8a + x86_64) | **XS** (15min) | 加 `ndk { abiFilters.addAll(...) }` 显式 |

### P2 建议(4 项)

| # | 位置 | 问题 | 难度 |
|---|------|------|------|
| **P2-1** | `.gitignore:46-49` (root) | R66 §7.5 P2 建议加 `*.jks` / `*.keystore` / `key.properties` — **R67 已加 ✓** | — |
| **P2-2** | `DEPLOYMENT.md:120-138` (阶段 5) | Google Play 阶段 5 描述 outdated,R66 §10.2 W14 标"重写" — R67 未改 | **M** (半天) |
| **P2-3** | `lib/main.dart:1-237` (Background isolation) | Flutter 默认 OK,加 1 段注释说明 `flutter_local_notifications` 的 background 行为 | **XS** (10min) |
| **P2-4** | `pubspec.yaml:62` (`in_app_purchase: ^3.3.0`) | R67 升 ^7.0.0 注释,pub.dev 3.3.0 已停止维护,新版 7.x 支持 Pending Purchase + Billing Library 7 | **S** (半天) |

---

## 4. 截图 / 描述 / 关键词现状

### 4.1 截图

| 文件 | 字节数 | 类型 | R66 → R68 |
|------|--------|------|-----------|
| `fastlane/metadata/android/en-US/phone_screenshots/screenshot_1.png` | **67** | 1x1 像素占位 | ✗ 不变 |
| `fastlane/metadata/android/en-US/phone_screenshots/screenshot_2.png` | **67** | 1x1 像素占位 | ✗ 不变 |
| `fastlane/metadata/android/en-US/phone_screenshots/screenshot_3.png` | **67** | 1x1 像素占位 | ✗ 不变 |
| `fastlane/metadata/android/en-US/phone_screenshots/screenshot_4.png` | **67** | 1x1 像素占位 | ✗ 不变 |
| `fastlane/metadata/android/zh-CN/phone_screenshots/screenshot_1.png` | **67** | 1x1 像素占位 | ✗ 不变 |
| `fastlane/metadata/android/zh-CN/phone_screenshots/screenshot_2.png` | **67** | 1x1 像素占位 | ✗ 不变 |
| `fastlane/metadata/android/zh-CN/phone_screenshots/screenshot_3.png` | **67** | 1x1 像素占位 | ✗ 不变 |
| `fastlane/metadata/android/zh-CN/phone_screenshots/screenshot_4.png` | **67** | 1x1 像素占位 | ✗ 不变 |

**结论**: R66 → R68 **0 变化**,8 张截图仍全占位。Play Store 必填 2-8 张 phone screenshots,当前 0 真实截图。

### 4.2 feature_graphic

| 文件 | 字节数 | R66 → R68 |
|------|--------|-----------|
| `fastlane/metadata/android/en-US/feature_graphic.png` | **67** | ✗ 不变 |
| `fastlane/metadata/android/zh-CN/feature_graphic.png` | **67** | ✗ 不变 |

**结论**: 2 张全 67 字节占位(1x1 拉伸),Play Store 必填 1024×500 feature graphic。

### 4.3 icon

| 文件 | 字节数 | 尺寸 | R66 → R68 |
|------|--------|------|-----------|
| `fastlane/metadata/android/en-US/icon.png` | 1443 | 192×192 | ✗ 不变(需 512×512) |
| `fastlane/metadata/android/zh-CN/icon.png` | 1443 | 192×192 | ✗ 不变 |
| `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` | — | xxxhdpi | ✓(launcher 用,但 Play Console 上传需独立 512×512) |

**结论**: 2 张 icon 全 192×192,Play Console 上传要求 512×512,Play Console 会警告但不一定拒。**最低阻塞程度**。

### 4.4 short_description

| 文件 | 字符数 | 限制 | R66 → R68 |
|------|--------|------|-----------|
| `en-US/short_description.txt` | 70 | ≤ 80 ✓ | R66 P1-7 未修措辞("chronic patients") |
| `zh-CN/short_description.txt` | **14** | ≤ 80 ✓ | **R67 修了** (R66 89 字 → R67 14 字) |

### 4.5 full_description

| 文件 | 字符数 | 限制 | R66 → R68 |
|------|--------|------|-----------|
| `en-US/full_description.txt` | 2580 | ≤ 4000 ✓ | **R67 修了** (加 "coming soon" 段) |
| `zh-CN/full_description.txt` | 2232 | ≤ 4000 ✓ | **R67 修了** (加 "暂停" 段) |

### 4.6 title

| 文件 | 字符数 | 限制 | R66 → R68 |
|------|--------|------|-----------|
| `en-US/title.txt` | 27 | ≤ 50 ✓ | 不变 |
| `zh-CN/title.txt` | 14 | ≤ 30 ✓ | ⚠ **R67 漏改** — 仍写 "失联通知" |

### 4.7 video

| 文件 | 状态 | R66 → R68 |
|------|------|-----------|
| `en-US/video.txt` | PLACEHOLDER URL | ✗ 不变 (R66 P1-6 未修) |
| `zh-CN/video.txt` | PLACEHOLDER URL | ✗ 不变 |

**结论**: 截图 / feature_graphic / icon / video 4 类 R66 → R68 **0 变化**。**P0 阻塞 4 项**(P0-4 截图 / P0-5 feature_graphic / P0-6 icon / P1-6 video)。

---

## 5. 半成品 / TODO

### 5.1 R66 报告列的 11 项 WIP 状态

| 编号 | 位置 | R66 状态 | R68 状态 |
|------|------|----------|----------|
| GP-W1 | `sms_service.dart:194-198` AliyunSmsProvider.send throw | R55+ TODO | ✗ **未修**(R67 加守卫但 send 仍 throw) |
| GP-W2 | `build.gradle.kts:80` signingConfig=debug | R55+ TODO | ✗ **未修** |
| GP-W3 | 3 法律文档 TODO 占位邮箱 | 多 round TODO | △ R67 软隐藏 `privacy@` 5 处,`support@` 1 处仍 TODO |
| GP-W4 | fastlane 缺 Fastfile + Appfile + 真实截图 | 从未配 | △ R67 加的 Fastfile/Appfile 是 **iOS-only**,Android 端仍 0 |
| GP-W5 | `BootReceiver.kt:32-41` 占位 | R63 注释 "留 R64" | ✗ **未修** (R64/R65/R66/R67 4 轮未动) |
| GP-W6 | `vent_compose_page.dart:135-141` RECORD_AUDIO rationale | R63 漏 | ✗ **未修** |
| GP-W7 | NotificationStatusCard SCHEDULE_EXACT_ALARM 引导 | R20 漏 | ✗ **未修** |
| GP-W8 | `lib/main.dart:188` StoreKitService.warmup dev 模式 | R65 加但 dev 模式 | ⚠ **R67 加 `FeatureFlags.iapEnabled=true` 默认开**,release 模式 `buyLifetime()` 返 `false` — **新不一致** |
| GP-W9 | `zh-CN/short_description.txt` 89 字符 | 超 80 | ✓ **R67 修了** (14 字) |
| GP-W10 | `privacy_policy.md:58-64` 失联通知 SMS 描述 | R66 改但文档没改 | △ R67 加 "本版本不实际触发" 声明 |
| GP-W11 | `en-US/full_description.txt:13-14` "automatically notify" | R66 改但文档没改 | △ R67 加 "coming soon" 段;line 14 "automatically notify" 措辞建议未改 |

### 5.2 R68 新发现 / 增项

| 编号 | 位置 | 问题 |
|------|------|------|
| **R68-N1** | `feature_flags.dart:36` `_prodIapEnabled = true` | R67 默认开 IAP,但 `store_kit_service.dart:119` release `buyLifetime()` 返 `false` — 用户级不一致 |
| **R68-N2** | `fastlane/metadata/android/zh-CN/title.txt:1` | 仍写 "失联通知",R67 改 full_description 但 title 漏改 |
| **R68-N3** | `fastlane/metadata/android/en-US/full_description.txt:14` | "automatically notify" 措辞 vs 业务暂停,Health Apps 政策建议 "would" / "could" |
| **R68-N4** | `assets/legal/user_agreement.md:17,40` + `sensitive_data_consent.md:27,47,64` | 4 处写 "失联通知" 功能可用,与 R66 业务暂停不一致 (`SPRINT1_LEGAL_TODO.md:99-101` 标 R67 未改) |
| **R68-N5** | `pubspec.yaml:62` `in_app_purchase: ^3.3.0` | pub.dev 3.3.0 已停维护,新版 7.x 已 GA(支持 Billing Library 7) |

### 5.3 Android/ + fastlane/ 目录 TODO 扫描

```
$ grep -rn "TODO|FIXME|XXX|placeholder|占位" android/ fastlane/ 2>/dev/null
```

| 文件:行 | 内容 |
|---------|------|
| `android/app/build.gradle.kts:46-50` | "**TODO 上 store 前切换**" 注释(line 46-50) |
| `fastlane/Appfile:20-24` | "TODO (上 store 前必须替换为真实 Apple ID)" 3 处 (iOS 侧,非本视角范围) |
| `fastlane/metadata/android/{en-US,zh-CN}/video.txt:1` | `PLACEHOLDER_APP_DEMO_VIDEO` 占位 URL 2 处 |
| `fastlane/metadata/android/{en-US,zh-CN}/phone_screenshots/screenshot_*.png` | 8 × 67 字节占位 PNG(grep 看不出是 PNG,`file` 命令可确认 1x1) |

**结论**: Android 侧 1 处 TODO(签名切换),fastlane 侧 2 处占位(video + 8 张截图),与本报告 §3 P0-1/P0-4/P1-6 重复。

---

## 6. 修复优先级 + 难度

按"上架必做 → 提审后必拒 → 警告"排序:

| 序 | 问题 | 位置 | 难度 | 阻塞 | R66 → R68 变化 |
|----|------|------|------|------|---------------|
| **1** | **release keystore + 切 signingConfig** | `build.gradle.kts:80` + `android/key.properties` | **S** (半天) | ✓ P0-1 | ✗ 未修(R67 加了 5 步指南 + signingConfigs.release block,但 0 keystore 实际生成) |
| **2** | **8 张真实截图 + 2 feature_graphic + 2 icon 512x512** | `fastlane/metadata/android/{en-US,zh-CN}/*.{png,jpg}` | **S** (半天) | ✓ P0-4/5/6 | ✗ 未修 |
| **3** | **注册 `chroniccare.app` 域名 + 部署 HTTPS 隐私 URL** | `assets/legal/*.md` + 新公网 HTML | **M** (1-2 天) | ✓ P0-2 | ✗ 未修(R67 加 `SPRINT1_LEGAL_TODO.md` 集中清单但没真注册) |
| **4** | **注册 `support@chroniccare.app` 邮箱 + 替换 TODO** | `user_agreement.md:60` + Play Console | **XS** (1-2h) | ✓ P0-3 | △ R67 软隐藏 `privacy@` 5 处,`support@` 1 处仍 TODO |
| **5** | **Android 端 Fastfile + Appfile(Play Console API)** | `fastlane/Fastfile` + `fastlane/Appfile` | **S** (半天) | ✓ P0-8 | ✗ 未修(R67 加的 Fastfile/Appfile 是 iOS-only) |
| **6** | **填 Play Console 4 大表单** (Data Safety / Health Apps / Permissions Declaration / Data Deletion) | Play Console 侧 | **M** (2-3h) | ✓ P0-2/P0-7 | ✗ 未修 |
| **7** | **改 4 处文档 wording 失联通知** (en-US full_desc line 14 + zh-CN title + user_agreement §1/§5 + sensitive_data_consent §3) | 4 处 .md + .txt | **XS** (1-2h) | ✓ P0-10 | △ R67 修了 2 处(full_desc),漏 4 处 |
| **8** | **BootReceiver 切 FlutterEngineCache 或 WorkManager** | `BootReceiver.kt:32-37` | **S** (2-3h) | ✗ P1-1 | ✗ 未修(R64+ 4 轮未动) |
| **9** | **RECORD_AUDIO in-app rationale** | `vent_compose_page.dart:135-141` | **S** (1-2h) | ✗ P1-2 | ✗ 未修 |
| **10** | **zh-CN title.txt wording "失联通知" 改 "危机提醒"** | `fastlane/metadata/android/zh-CN/title.txt:1` | **XS** (5min) | △ P0-10 | ✗ 未修 |
| **11** | **IAP 决策 + `_prodIapEnabled` 跟 `buyLifetime()` 对齐** | `feature_flags.dart:36` + `store_kit_service.dart:119` | **M** (半天) | ✗ P1-3 | ⚠ R67 引入新不一致(默认开但 release 返 false) |
| **12** | **删 / 改 `video.txt` 2 个 PLACEHOLDER URL** | `fastlane/metadata/android/{en-US,zh-CN}/video.txt` | **XS** (5min) | ✗ P1-6 | ✗ 未修 |
| **13** | **en-US short_description 改 "chronic patients" → "people managing chronic conditions"** | `fastlane/metadata/android/en-US/short_description.txt:1` | **XS** (5min) | ✗ P1-5 | ✗ 未修 |
| **14** | **NotificationStatusCard 加 SCHEDULE_EXACT_ALARM 引导** | `notification_status_card.dart` | **XS** (1h) | ✗ P1-4 | ✗ 未修 |
| **15** | **升 `in_app_purchase` 3.3.0 → 7.x** | `pubspec.yaml:62` | **S** (半天) | ✗ P2-4 | ✗ 未修 |
| **16** | **16KB page size 验 + 写守门员** | `scripts/check_16kb_alignment.sh` | **S** (2-3h) | ✗ P1-7 | ✗ 未修 |
| **17** | **`abiFilters` 显式** | `android/app/build.gradle.kts` | **XS** (15min) | ✗ P1-8 | ✗ 未修 |
| **18** | **律师 review 3 法律文档** | `assets/legal/*.md` | **L** (1-2 周,~¥15-30k/文档) | ✓ P0-9 | ✗ 未修(外部依赖) |
| **19** | **AliyunSmsProvider 真接 send() + EmailService 真接** | `sms_service.dart:194` + `email_service.dart` | **L** (1-2 月法务 + AccessKey 申请) | ✓ P0-7 | ✗ 未修(外部依赖,R55+) |
| **20** | **DEPLOYMENT.md 阶段 5 重写** | `docs/DEPLOYMENT.md:120-176` | **M** (半天) | △ P2-2 | ✗ 未修 |

---

## 7. 给开发者的精炼建议 (R68)

**最快能上架的最小路径** (4 步, 预计 **2-3 天**,不含律师 review):
1. 配 release keystore(`keytool` + `cp key.properties.example` + 切 `signingConfig = release`)— **半天**
2. 写真实截图 8 张(adb 真机截图脚本 30min) + 切 icon 512×512 + 写 1 张 feature_graphic 1024×500 — **半天**
3. 注册 `chroniccare.app` 域名 + `support@` 邮箱 + 部署 `https://chroniccare.app/privacy` HTML(3 文档转 HTML) — **1 天**
4. 填 Play Console 4 大表单(Data Safety + Health Apps + Permissions Declaration + Data Deletion endpoint) — **2-3h**

**最大拦路虎** (外部依赖,无法加速):
- **律师 review** 3 法律文档(1-2 周,~¥15-30k/文档)— 不修则 Developer Policy 4.8 违规
- **AliyunSmsProvider 真接** + 阿里云签名/模板审核(1-2 月)— 不修则 Data Safety Form 必勾"未触发",业务上失联通知永远 mock
- **R67 留下的 4 处文档脱节**(user_agreement §1/§5 + sensitive_data_consent §3 + zh-CN title)— 1-2h 改完但需跟 Play Console 表单对齐
- **R68 新发现**:IAP 默认开但 `buyLifetime()` release 返 false — 决策: 改 `_prodIapEnabled=false` 关闭 OR 真接 IAP,避免 Apple 2.1 / Play 拒"未提供其他购买方式"

**M1 最小上架**(3-5 天,不含律师):1+2+3+4 + 改 4 处 wording + 删 video.txt + NotificationStatusCard + RECORD_AUDIO rationale + abiFilters + 16KB 守门员 — **总计 30-40h**

**M2 完整 CI 化**(+3-5 天):Android Fastfile/Appfile + IAP 真接 + DEPLOYMENT 重写 + pubspec 升 `in_app_purchase: ^7.x`

**M3 v1.0**(+3-6 月):真接 Aliyun SMS + HIPAA/GDPR 律师过审 + NMPA "非医疗器械" 备案 + 软件著作权登记

---

## 附录 A: R66 → R67 → R68 状态总表

| R66 报告项 | R66 状态 | R67 修复 | R68 状态 |
|-----------|---------|---------|---------|
| §3.2 P0 USE_EXACT_ALARM justification | Play Console 必填 100+ 字符未准备 | ✗ 未动 | ⚠ 仍需准备 |
| §3.3 RECORD_AUDIO in-app rationale | 缺引导去 Settings | ✗ 未动 | ⚠ P1-2 |
| §3.4 SCHEDULE_EXACT_ALARM 引导 | NotificationStatusCard 漏 1 行 | ✗ 未动 | ⚠ P1-4 |
| §6.1 P0 Privacy Policy URL 未托管 | 域名未注册 | △ R67 加 SPRINT1_LEGAL_TODO 集中器 | ✗ P0-2 |
| §6.2 P0 邮箱 TODO 占位 | support@ + privacy@ 都 TODO | △ R67 软隐藏 privacy@ 5 处,support@ 1 处仍 TODO | △ P0-3 |
| §6.4 P1 Health disclaimer | en-US + zh-CN 都已写 | 不变 | ✓ |
| §6.6 P1 zh-CN short_description 89 字符 | 超 80 字符 | ✓ R67 砍到 14 字 | ✓ 修了 |
| §6.7 P1 en-US "chronic patients" 措辞 | 措辞建议 | ✗ 未动 | ⚠ P1-5 |
| §6.8 P1 IAP 8 元买断 | 描述与代码不一致 | ⚠ R67 引入 `_prodIapEnabled=true` 默认开,release 仍返 false 新不一致 | ⚠ P1-3 (R68 新发现) |
| §6.9 P1 Push notifications 字段 | 必勾 No | 不变 | ✓ |
| §6.10 P1 Data deletion endpoint | 必填 | ✗ 未动 | ✗ P0-2 子项 |
| §6.13 P2 App access | 必勾 All | 不变 | ✓ |
| §6.14 P2 Ads SDK | 必勾 No | 不变 | ✓ |
| §7.1 P0 release keystore 仍是 debug | debug-signed AAB | △ R67 加 signingConfigs.release block + 5 步指南,但 build 仍 fallback debug | ✗ P0-1 |
| §7.2 P0 Play App Signing 未启用 | 未启用 | ✗ 未动(等 keystore 落地) | ✗ P0-1 |
| §7.3 P1 BootReceiver 占位 | 启动 MainActivity | ✗ R64/R65/R66/R67 4 轮未动 | ⚠ P1-1 |
| §7.4 P1 64-bit ABI 未显式 | 隐式 | ✗ 未动 | ⚠ P1-8 |
| §7.5 P2 root .gitignore 缺 *.jks | 兜底 | ✓ R67 加 `*.jks` / `*.keystore` / `key.properties` | ✓ |
| §9.2 P0 Fastfile/Appfile 缺失 | 无 lane | △ R67 加 Fastfile/Appfile 但**仅 iOS 端**,Android 端仍 0 | ✗ P0-8 |
| §9.3 P0 截图/feature_graphic/icon 全占位 | 8 + 2 + 2 占位 | ✗ 0 变化 | ✗ P0-4/5/6 |
| §9.4 P1 video.txt 占位 URL | PLACEHOLDER | ✗ 未动 | ⚠ P1-6 |
| §10.1 GP-W1 SMS throw | R55+ TODO | △ R67 加 EmailService 守门员,SmsService R63 已加 | ⚠ P0-7 (法务 + 真接是外部依赖) |
| §10.1 GP-W2 signingConfig=debug | R55+ TODO | △ R67 加 signingConfigs.release block,仍 fallback debug | ✗ P0-1 |
| §10.1 GP-W3 法律文档 TODO | 多 round TODO | ✓ R67 加 SPRINT1_LEGAL_TODO.md 集中器 | △ P0-3/9 |
| §10.1 GP-W4 fastlane 缺 | 从未配 | △ R67 修了 iOS 端,Android 端仍 0 | ✗ P0-4/5/6/8 |
| §10.1 GP-W5 BootReceiver 占位 | R63 注释 "留 R64" | ✗ 未动 | ⚠ P1-1 |
| §10.2 GP-W6 RECORD_AUDIO rationale | R63 漏 | ✗ 未动 | ⚠ P1-2 |
| §10.2 GP-W7 SCHEDULE_EXACT_ALARM 引导 | R20 漏 | ✗ 未动 | ⚠ P1-4 |
| §10.2 GP-W8 IAP dev 模式 | R65 dev 模式 | ⚠ R67 加 FeatureFlags 默认开 IAP | ⚠ P1-3 |
| §10.2 GP-W9 zh-CN short_description 89 字 | 超 80 | ✓ R67 砍到 14 字 | ✓ |
| §10.2 GP-W10 失联通知 SMS 描述 vs R66 暂停 | R66 改但文档没改 | △ R67 加 "本版本不实际触发" 声明,user_agreement §1/§5 漏 | △ P0-10 |
| §10.2 GP-W11 en-US "automatically notify" | 同上 | △ R67 加 "coming soon" 段,line 14 "automatically notify" 措辞漏 | △ P0-10 |
| §10.3 GP-W12 Background isolation | 0 注释说明 | ✗ 未动 | ⚠ P2-3 |
| §10.3 GP-W13 SmsService.validateForRelease | R62 P0-1 加 | ✓ R67 修了 EmailService 平行 | ✓ |
| §10.3 GP-W14 DEPLOYMENT.md 阶段 5 outdated | 文档 stale | ✗ 未动 | ⚠ P2-2 |
| **R66 P0 总数** | 10 | R67 修了 0 项 P0(Sprint 1 集中 TODO + 加 3 个 doc 是"准备工作",不算修) | **R68 P0 仍 10**(P0-7 改 wording ✓,但代码 throw 仍需真接) |
| **R66 P1 总数** | 12 | R67 修了 3 项(GP-W4 iOS 端 / GP-W9 zh-CN short_desc / GP-W13 EmailService 守门员) | **R68 P1 仍 8**(原 12 - 3 修 + 1 新增 = 8 + 1 新 = 9) |
| **R66 P2 总数** | 6 | R67 修了 1 项(GP-W12 §7.5 root .gitignore) | **R68 P2 仍 4** |

**R66 → R68 净进展**: P0 持平(10 → 10),P1 略减(12 → 9),P2 减(6 → 4)。**R67 修的全是"准备"(集中 TODO + 文档 hygiene + iOS 端),上架硬阻塞 0 突破**。

---

**报告完毕。** 跟 R66 appstore 视角联动看 — iOS / Android 双端都卡在:① 真实 keystore ② 律师 review ③ 真实截图 ④ 邮箱 / 域名注册 ⑤ 隐私 / IAP / Health 表单填写。**M1 最小上架 3-5 天,瓶颈仍是法律 review(1-2 周,¥15-30k/文档)**。
