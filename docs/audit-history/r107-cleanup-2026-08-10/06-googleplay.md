# Google Play 上架就绪度审计（v0.30 R105 视角）

**审计日期**: 2026-08-10
**项目版本**: 0.30.0+85 (R105)
**审计视角**: Google Play Store 6 大块 + Health Apps 问卷 + Data Safety Form + 国产 ROM 适配
**基线声明**: R104/R105 自评 40%，本审计对照验证

---

## 1. 评分

| 维度 | 分数 | 状态 |
|------|------|------|
| **总评分** | **55%**（↑15% vs R105 自评 40%） | ⬆ 可上架但需补关键项 |
| 1. App Completeness | 35% | 🔴 致命：截图/平板/全图形素材全占位 |
| 2. Metadata | 70% | 🟡 文本到位，feature_graphic 67B 占位 |
| 3. Data Safety Form | 0% | 🔴 未提交（需 Play Console 手填 7 大类） |
| 4. Health Apps Questionnaire | 0% | 🔴 未提交（需 Play Console 手填心理健康/医疗设备/临床） |
| 5. Device & Network Abuse | 85% | 🟢 USE_EXACT_ALARM 已删，仅缺 SCHEDULE_EXACT_ALARM 运行时检查 |
| 6. 国产 ROM 适配 | 60% | 🟡 5 厂商 + 自检卡 + FeatureFlag 占位到位，但 FeatureFlag=false 隐藏引导 |
| 7. APK 签名 / ProGuard / Play Integrity | 50% | 🟡 signingConfig 已切 release（-PdebugSigning fallback），但 keystore 0 生成 |
| 8. 16KB page size | 90% | 🟢 配置到位，缺最后实跑 `unzip + objdump` 验 |
| 9. Data Backup / Cleartext / WebView | 95% | 🟢 allowBackup=false + cleartext 禁 + 0 网络 |
| 10. i18n 完整度 | 70% | 🟡 en + zh-CN + zh-Hant (3 语 ARB), strings.xml 缺 zh-rTW / zh-rCN 资源 |

---

## 2. Google Play 6 大块逐一评估

### 2.1 App Completeness 🔴 35%

| 资产 | 文件 | 状态 | 关键问题 |
|------|------|------|----------|
| 手机截图 (en-US) | `fastlane/metadata/android/en-US/phone_screenshots/screenshot_1..4.png` | 🔴 **67 字节占位** | R100 P0-2 修了 video.txt 占位但**截图未重拍**，全 67B (1×1 透明 PNG) |
| 手机截图 (zh-CN) | `fastlane/metadata/android/zh-CN/phone_screenshots/screenshot_1..4.png` | 🔴 同上 | 同上 |
| 平板 7" 截图 | `phoneScreenshots/tenInch/*` + `sevenInch/*` | ❌ **不存在** | Google Play 2019-11 强制需 ≥1 张 |
| 10" 平板截图 | 同上 | ❌ 不存在 | 同上 |
| feature_graphic | `en-US/feature_graphic.png` | 🔴 **67B 占位** | Google Play 1024×500 PNG 强需求 |
| App icon | `mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png` + `mipmap-anydpi-v26/ic_launcher.xml` | ✅ 完整 | 自带 adaptive icon 模板 (background/foreground vector) |
| 应用图标 (Play) | `en-US/icon.png` + `zh-CN/icon.png` | 🟡 1443B 占位 | Play Console 要求 512×512 PNG |
| Promotional Graphics | `fastlane/metadata/android/*/promo_*.png` | ❌ 不存在 | 非强制，但健康类 App 强烈建议 |

**Play Console 上架阻断**:
- 缺真实截图（手机 4 张）→ 上传被拒 "Screenshots required"
- 缺 7"/10" 平板截图（仅手机单一 form factor 不通过）→ "Tablet design required"

### 2.2 Metadata 🟡 70%

| 字段 | en-US | zh-CN | 评价 |
|------|-------|-------|------|
| `title.txt` | "ChronicCare - Med Reminder" (27 chars) | "慢病管家 - 吃药打卡 + 情绪关怀" (18 chars) | ✅ <30 chars 上限 |
| `short_description.txt` | "Daily check-in + mood tracker…" (87 chars) | "精神心理吃药打卡·本地加密零云端" (20 chars) | ✅ <80 chars 上限 |
| `full_description.txt` | 2327 chars (隐私+功能+WHO+免责+危机热线) | 696 chars (中文版) | ✅ 含 medical disclaimer + crisis hotline + 5 隐私承诺 |
| `feature_graphic.png` | 🔴 67B 占位 | — | ❌ 必填 |
| `icon.png` | 🟡 1443B 占位 | 1443B | 🟡 必填 512×512 |
| `video.txt` | ✅ R100 已删 (P0-2 修复) | ✅ R100 已删 | ✅ 修前是占位风险 |
| `phoneScreenshots/` (大写) | ❌ | ❌ | fastlane 用下划线 `phone_screenshots` |
| `changelogs/85.txt` | ❌ | ❌ | R100 未建 — 上架后必须补每版本 release notes |
| `listing_*.txt` (其他语) | ❌ | ❌ | fastlane 缺该机制 |
| **zh-TW (繁体) metadata** | ❌ **不存在** | — | 🔴 台灣/香港用戶無本地化 |

**优点**：
- 英文 full_description 写得非常专业（medical disclaimer 强、PHQ-9/GAD-7 标注、危机热线 5 区域）
- 中文版含 PIPL §28 隐私 + 5 区域心理危机热线
- title 删了 "(失联通知规划中)" 误导表述 (R100 P0-5 修复)

**阻断**:
- 缺繁体 metadata — 台港新马繁体市场无本地化
- 缺 7"/10" 平板描述
- 缺 release_notes (changelogs/85.txt)

### 2.3 Data Safety Form 🔴 0% 未提交

Play Console 强制 7 大类手填。本项目对应：

| 类别 | 实际收集 | 13 子项 (collected/shared/user control/handling) | 应填声明 |
|------|----------|---------------------------|----------|
| **Location** | ❌ 不收 | 0/0/N/A | "App doesn't collect this data" |
| **Personal info** | 🟡 昵称 (v0.21 nullable) | collected=✓, shared=✗, control=delete/edit | "Collected, not shared, deletable" |
| **Financial info** | ❌ 不收 (IAP 走 Google 平台) | 0/0/N/A | 注明"Google Play 平台 IAP 自处理" |
| **Health & fitness** | 🟡 **强制披露**: 药名/剂量/打卡/PHQ-9/GAD-7/mood | collected=✓, shared=✗, encrypted=✓ | "Collected, encrypted on device, deletable" |
| **Messages** | ❌ 不收 | 0/0/N/A | "App doesn't collect this data" |
| **Photos & videos** | ❌ 不收 (vent audio 是 Audio 类) | 0/0/N/A | "App doesn't collect this data" |
| **Audio** | 🟡 vent audio (R104 启用) + mood audio | collected=✓, shared=✗, encrypted=✓ | 同上 |
| **Files & docs** | ❌ 不收 (除本地加密 audio) | 0/0/N/A | "App doesn't collect this data" |
| **Calendar** | ❌ 不收 | 0/0/N/A | 同上 |
| **Contacts** | 🟡 **紧急联系人 (PIPL §23)** | collected=✓, shared=✗ | 注明**未实际触发 SMS** (FeatureFlag.emergencyContactEnabled=false) |
| **App activity** | 🟡 打卡/用药/情绪/评估 (本地) | collected=✓, shared=✗ | 同上 |
| **Web browsing** | ❌ 不收 (0 网络) | 0/0/N/A | "App doesn't collect this data" |
| **App info & performance** | 🟡 crash log (runZonedGuarded 本地) + 设备型号判断通知兼容性 | collected=✓, shared=✗ | "Collected locally for crash diagnostics, not shared" |

**安全实践披露**:
- "Data is **encrypted in transit**": ✗ 不适用 (无网络)
- "Data is **encrypted at rest**": ✅ 必填 "Yes — AES-256 (SQLCipher + field-level)"
- "Users can **request that data be deleted**": ✅ 必填 "Yes — App 内删除 + 卸载清空"
- **Independent security review**: ✗ 否 (诚实填) — 私人项目无 SOC2 / ISO 27001

**阻断**:
- 必须 Play Console 7 大类 × 4 子项 = 28 项手填
- **Health & fitness 类别强制加密披露** (PIPL §28 + HIPAA 风控)
- **紧急联系人披露 + 第三方告知** (PIPL §23, 需说明"本版本未实际触发")

### 2.4 Health Apps Questionnaire 🔴 0% 未提交

Google Play 2024 强制健康类 App 填的 4 大块：

| 块 | 本项目状态 | 应填 |
|----|------------|------|
| **App type** | Health & Fitness | ✅ "Health & Fitness — self-tracking" |
| **Health data collected** | 🟡 7 类: 药名/剂量/打卡时间/PHQ-9/GAD-7/mood score/vent audio | ✅ 必填列表 + 各数据用途 |
| **Medical device claim** | ✅ **不是医疗设备** (medical_disclaimer.md §4 明确声明) | ✅ 必填 "App is NOT a medical device" |
| **Clinical claim** | ✅ **不做临床建议** (medical_disclaimer.md §1+§2 明确) | ✅ 必填 "App does NOT provide medical advice, diagnosis, or treatment" |

**额外健康类 App 必填**:
- **User consent for health data** ✅ 已实装 (3 同意勾选: 用户协议 + 隐私政策 + 敏感个人信息处理同意书 — `assets/legal/sensitive_data_consent.md`)
- **Data retention policy** ✅ 卸载=清空
- **Account requirement** ✅ 无账号

**阻断**:
- 必须在 Play Console 提交 Health Apps Questionnaire
- medical_disclaimer.md 已 R83/R101 修订，措辞符合"NOT a medical device" + "NOT provide medical advice"

### 2.5 Device & Network Abuse 🟢 85%

| 检查项 | 状态 | 备注 |
|--------|------|------|
| **USE_EXACT_ALARM** | ✅ **R97 已删** | Google Play 2024-07 限 alarm clock/calendar, 精神心理服药不在范围 |
| **SCHEDULE_EXACT_ALARM** | ✅ 保留 (user-revocable) | 精神心理服药提醒走这条 |
| **INTERNET** | ✅ 仅 in_app_purchase 隐式依赖 | 即 `iapEnabled=false` 仍需声明 (plugin 强制) |
| **POST_NOTIFICATIONS (Android 13+)** | ✅ **R97-P1-6 修复 in-context 申请** | setup 配完药后 + 设置页"测试通知"按钮 + reminders_hub |
| **RECORD_AUDIO** | ✅ R97 删 / R105 恢复 (R104 ventAudioEnabled=true) | 跟 vent + mood 录音业务一致 |
| **WAKE_LOCK / VIBRATE** | ✅ 通知触发 CPU 保持 + 震动 | 正常 |
| **RECEIVE_BOOT_COMPLETED** | ✅ R97 删除 (BootReceiver.kt 保留作 v1.0 WorkManager 参考) | 实际未注册到 manifest — Android 14+ 不会触发 |
| **Network cleartext** | ✅ `network_security_config.xml` 禁明文 | trust-anchors=system only |
| **WebView** | ✅ 0 网络, 0 WebView | |
| **P1-13 TODO SCHEDULE_EXACT_ALARM 运行时检查** | 🟡 未实装 | `canScheduleExactAlarms()` 未在 rescheduleAll 入口调, 用户撤回权限会静默降级 inexact |
| **隐式 ABI 过滤** | ✅ `abiFilters.addAll(listOf("arm64-v8a", "x86_64"))` (R70 修复) | 排 32-bit 旧设备 + x86 emulator |

**唯一阻断**:
- **P1-13**: `canScheduleExactAlarms()` 运行时检查 — 用户撤回 SCHEDULE_EXACT_ALARM 后 zonedSchedule 静默降级 inexact (~15min 延迟), 精神心理患者服药提醒不准时
- 修法: `rescheduleAll` 入口调 `AndroidFlutterLocalNotificationsPlugin.canScheduleExactNotifications()` / `canScheduleExactAlarms()` (Android 12+), false 时引导去系统设置
- 工时: 0.5 day

### 2.6 国产 ROM 适配 🟡 60%

| 厂商 | 自检卡引导文案 | FeatureFlag 守门 | SDK 接入 | 状态 |
|------|----------------|-------------------|----------|------|
| **小米 (MIUI)** | ✅ `notificationStatusCardOemBrandXiaomi` + 3 step | `fiveVendorPushEnabled=false` → 整段 hidden | ❌ 未接 | 🟡 引导文案在但 UI 隐藏 |
| **华为 (EMUI/HarmonyOS)** | ✅ `notificationStatusCardOemBrandHuawei` + 3 step | 同上 | ❌ 未接 | 🟡 |
| **OPPO (ColorOS)** | ✅ `notificationStatusCardOemBrandOppo` + 3 step (含 realme/一加) | 同上 | ❌ 未接 | 🟡 |
| **vivo (Funtouch/OriginOS)** | ✅ `notificationStatusCardOemBrandVivo` + 3 step (含 iQOO) | 同上 | ❌ 未接 | 🟡 |
| **魅族 (Flyme)** | ✅ `notificationStatusCardOemBrandMeizu` + 2 step | 同上 | ❌ 未接 | 🟡 |
| 三星 (OneUI) | ✅ R22 sp-zh T-11 扩 | — | — | ✅ |
| 其他 (Knox/小众) | ✅ R22 扩 | — | — | ✅ |
| **自检卡 3 件套** | ✅ status 显示 / 测试通知 / 查看待发队列 | — | — | ✅ |
| **"测试通知"按钮** | ✅ R97-P1-6 修 (测试前先 requestPermission) | — | — | ✅ |
| **安全网 `workmanager` fallback** | ❌ 未接 | — | ❌ | BootReceiver.kt 是空半成品 |
| **精确闹钟 system 引导** | 🟡 SCHEDULE_EXACT_ALARM 撤回时无引导 (P1-13) | — | — | 🟡 |

**核心矛盾**:
- 自检卡写得很专业（7 厂商 + 静默杀后台检测 + 测试通知）— **R22 改的**
- 但 `FeatureFlags.fiveVendorPushEnabled = false` → `_OemBackgroundHint()` **整段 hidden** (notification_status_card.dart:261-264)
- 用户在国产 ROM 收不到通知时, 看 settings 看不到任何引导
- **修前/修后**: 修前 (R22) 有 5 厂商引导 + 7 品牌通用引导; R93 阶段 2 为避 Google Play 误导, 整段 hidden
- **修复方案**: 把 7 品牌**通用引导** (三星 + 其他) 单独 visible, 5 厂商 (米/华/OPP/vivo/魅族) hidden — 这样用户在国产 ROM 仍能查"通用设置"路径, 但不会被诱导去找"5 厂商 SDK 接入"按钮
- 工时: 0.5 day

---

## 3. 问题清单（按优先级 P0 → P3）

| # | 文件:行 | 问题 | 类别 | 难度 | 优先级 | 修复建议 | 工时 |
|---|---------|------|------|------|--------|----------|------|
| 1 | `fastlane/metadata/android/*/phone_screenshots/screenshot_1..4.png` | **67B 假图占位** (4 张 × 2 locale) | App Completeness | 易 | **P0 阻断** | 1) 启动 Android emulator + Playwright 跑 `flutter test integration_test` 录 4 主流程 (home + setup + check-in + assessment) → 2) 截图 1080×1920 + 7"/10" 平板 form factor | 1.5 day |
| 2 | `fastlane/metadata/android/*/feature_graphic.png` | **67B 假图** (2 locale) | App Completeness | 易 | **P0 阻断** | 设计 1024×500 PNG (Figma / Canva / Photoshop) — 模板: App logo + tagline + 4 主功能 icon | 0.5 day |
| 3 | `fastlane/metadata/android/*/icon.png` | **1443B 占位** (2 locale) | App Completeness | 易 | **P0 阻断** | 导出 mipmap-xxxhdpi/ic_launcher.png 升 512×512 — `flutter_launcher_icons` 自动生成 | 0.5 day |
| 4 | `android/key.properties` + `playstore_signing_key.jks` | **不存在**, signingConfig 默认走 `-PdebugSigning` fallback (R97-P0-5 修) | APK 签名 | 易 | **P0 阻断** | 跟 `docs/PLAYSTORE_SIGNING_GUIDE.md` 5 步走: `keytool -genkey` + 填 4 值 + 启用 Play App Signing | 0.5 day |
| 5 | Play Console Data Safety Form | **未提交** (0/7 类) | Data Safety | 中 | **P0 阻断** | 手填 7 类 × 4 子项 = 28 项 (本报告 §2.3 给完整模板) | 0.5 day |
| 6 | Play Console Health Apps Questionnaire | **未提交** | Health Apps | 中 | **P0 阻断** | 手填 4 大块 (本报告 §2.4 给完整模板) | 0.5 day |
| 7 | `fastlane/metadata/android/zh-TW/` | **不存在** (繁中市场) | Metadata | 易 | **P1** | `cp -r zh-CN/ zh-TW/` + 翻译 title/short/full (3 文件) | 0.5 day |
| 8 | `android/app/src/main/res/values-zh-rTW/strings.xml` + `values-zh-rCN/strings.xml` | **不存在** (桌面 app_name zh-TW 缺) | i18n | 易 | **P1** | `cp values/ values-zh-rCN/values-zh-rTW/` — `app_name` 写繁简差异 (R85 P0-57 修过 en/zh 切) | 0.25 day |
| 9 | `fastlane/metadata/android/en-US/phoneScreenshots/sevenInch/` + `tenInch/` | **不存在** | App Completeness | 中 | **P1 阻断** | 启动 Android 7"/10" emulator (Pixel Tablet API 35) 录 2 张主流程 (home + check-in) | 1.0 day |
| 10 | `lib/core/data/services/notification_service.dart:313-325` | **P1-13 TODO**: SCHEDULE_EXACT_ALARM 运行时检查未实装 | Device Abuse | 中 | **P1** | `rescheduleAll` 入口调 `AndroidFlutterLocalNotificationsPlugin.canScheduleExactNotifications()` + false 引导系统设置 | 0.5 day |
| 11 | `lib/presentation/pages/settings/widgets/notification_status_card.dart:261-264` | **5 厂商引导整段 hidden** (FeatureFlag=false) | 国产 ROM | 易 | **P2** | 拆"通用引导" (三星 + 其他) 出来 visible, 5 厂商 hidden | 0.5 day |
| 12 | `lib/core/data/services/notification_service.dart:138-141` | `init()` 时 `DarwinInitializationSettings` request*Permission=false 走 in-context (R97 修) — **Android 13+ POST_NOTIFICATIONS 申请时序正确** | Notification | — | — | ✅ 已合规, 无需改 | — |
| 13 | `fastlane/metadata/android/*/changelogs/85.txt` | 不存在 (R100 P0-3 范围外) | Metadata | 易 | **P2** | 写 v0.30.0 release notes (中英繁 3 语) | 0.25 day |
| 14 | `android/app/src/main/AndroidManifest.xml` | **无 `tools:targetApi` / `tools:ignore`** 防御性声明 | 兼容性 | 易 | **P3** | 加 `<uses-permission android:name="SCHEDULE_EXACT_ALARM" tools:ignore="ProtectedPermissions"/>` 防 lint | 0.1 day |
| 15 | `android/app/src/main/AndroidManifest.xml:50-59` | **缺 `<meta-data android:name="com.google.android.backup.api_key">` 等** | Data Backup | 易 | **P3** | 跟 `allowBackup="false"` + `data_extraction_rules` 一致, 不需补 — 当前配置已正确 | — |
| 16 | `android/app/src/main/AndroidManifest.xml:62` | `<activity android:name=".MainActivity">` 缺 `<meta-data android:name="android.max_aspect">` | 兼容性 | 易 | **P3** | 适配 Pixel Fold / 折叠屏 — 当前 18.5:9, Play 推荐 21:9 | 0.1 day |
| 17 | `lib/main.dart:213` | `NotificationService()` 顶层 final 启动时 init (不弹权限) | Notification | — | — | ✅ R97 修, 启动不弹 | — |
| 18 | `lib/core/data/services/safety_watch_service.dart:107-116` | `bootReceiverEnabled=false` 走 disabled 路径 | 国产 ROM | — | — | ✅ 已 FeatureFlag 守门, R93 阶段 2 隐藏 | — |
| 19 | `assets/legal/privacy_policy.md` | 完整 PIPL §28/§13/§23/§38/§14 + 4 修订历史表 | 隐私 | — | — | ✅ R83/R101 律师审核集中修 | — |
| 20 | `android/app/src/main/res/xml/data_extraction_rules.xml` + `backup_rules.xml` | **exclude** chroniccare.sqlite + flutter_secure_storage + vent_audio + mood_audio | Data Backup | — | — | ✅ R61 修, 防 Google Drive 备份 PII | — |
| 21 | `android/app/src/main/res/xml/network_security_config.xml` | `cleartextTrafficPermitted="false"` | Cleartext | — | — | ✅ R61 修, 0 网络 0 风险 | — |
| 22 | `android/app/proguard-rules.pro` | Flutter + 11 plugin keep 完整 | ProGuard | — | — | ✅ R63 修, `com.chroniccare.chroniccare.**` keep | — |
| 23 | Play Integrity API / SafetyNet | **未接** (无 `play_licensing` / `play_core` / `play_integrity` 依赖) | Play Integrity | 中 | **P3** | 可选 — 精神心理 App 跟金融类不同, 不强制 | 1-2 day (真接时) |
| 24 | `android/app/src/main/res/drawable/ic_launcher_background.xml` + `foreground.xml` | adaptive icon vector drawable 存在 | App icon | — | — | ✅ 标准 Material 3 自带 | — |
| 25 | `android/gradle.properties` | `useAndroidX=true` (默认) + `Xmx8G` (R95 加) | Build | — | — | ✅ 标准 | — |

**汇总**: 25 项已检, **P0 6 项全部阻断上架**, P1 4 项 (2 项是上架阻断), P2/P3 5 项优化.

---

## 4. 跟 R105 自评 40% 的差异

| 项 | R105 自评 | 本审计 | 差异原因 |
|----|-----------|--------|----------|
| **总评分** | 40% | **55%** | R105 漏估了 R61/R63/R67/R97 集中修复的价值 (Android 隐私规范 / 签名切 release / BootReceiver 删 / USE_EXACT_ALARM 删) |
| AndroidManifest 6 防护 (R61+R63) | 🟡 50% | ✅ 95% | allowBackup=false + cleartext 禁 + 3 backup_rules + data_extraction_rules + enableOnBackInvokedCallback + debuggable=false 全到位 |
| ProGuard / R8 混淆 | 🟡 50% | ✅ 90% | R63 11 plugin keep 完整, `com.chroniccare.chroniccare.**` 防 R8 误判业务包 |
| ABI / minSdk / targetSdk | ✅ 80% | ✅ 95% | R63 显式 pin minSdk=24 + targetSdk=36, R70 abiFilters arm64+x86_64 |
| 签名切 release | 🟡 30% | 🟡 50% | R97-P0-5 修了 signingConfig 默认走 release (但 keystore 仍 0 生成, 需 Play Console 上传前 walkthrough) |
| 5 厂商 push / FeatureFlag | 🟡 40% | 🟡 60% | 11 个 FeatureFlag 守门到位, 但 5 厂商 SDK 0 接入 + 引导整段 hidden, 用户在国产 ROM 收不到通知无救济 |
| 通知权限 in-context | 🟡 40% | ✅ 95% | R97-P1-6 修了 setup 配完药后 + 设置页 + reminders_hub 三处调 requestPermission, 启动不弹 |
| 16KB page size | 🟡 50% | ✅ 90% | sqlcipher_flutter_libs 0.6.5+ 满足, targetSdk=36 + Flutter 3.41.9 默认 ndk 27, 缺最后 unzip + objdump 实跑验 |
| Data Safety Form | ❌ 0% | ❌ 0% | **0 提交**, 必须 Play Console 手填 28 子项 |
| Health Apps 问卷 | ❌ 0% | ❌ 0% | **0 提交**, 必须 Play Console 手填 4 大块 |
| App Completeness 截图 | ❌ 30% | ❌ 35% | R100 P0-2 删 video.txt 占位, **但截图全 67B 假图未重拍**, 平板截图全缺 |
| i18n 完整度 | 🟡 60% | 🟡 70% | en + zh-CN + zh-Hant ARB 3 语 sync (R56e 1091 keys), 但 strings.xml 缺 zh-rTW/zh-rCN 资源 (桌面 app_name 切), zh-TW fastlane metadata 全缺 |

**结论**: R105 自评偏严 15% — 实际 Android 侧 (manifest / 隐私 / 签名切 / 通知权限) 修复很扎实, 但 **Play Console 后台手填项** (Data Safety + Health Apps) 和 **素材制作** (截图/feature_graphic) 仍 0 进度, 拉低总评分.

---

## 5. 16KB page size 验证

**配置层验证** (✅ 通过):

| 检查项 | 实际 | 通过 | 来源 |
|--------|------|------|------|
| `targetSdk` | 36 (≥35 强制) | ✅ | `android/app/build.gradle.kts:35` |
| `minSdk` | 24 (R63 pin) | ✅ | `android/app/build.gradle.kts:34` |
| `compileSdk` | `flutter.compileSdkVersion` (隐式 36) | ✅ | `android/app/build.gradle.kts:12` |
| `sqlcipher_flutter_libs` | `^0.6.5` (0.6.8 locked) | ✅ | `pubspec.yaml:24` (R82 升级) |
| `record` | `^5.2.0` (≥4.4.0 16KB OK) | ✅ | `pubspec.yaml:64` |
| `audioplayers` | `^6.1.0` (≥5.0.0 16KB OK) | ✅ | `pubspec.yaml:65` |
| `flutter_secure_storage` | `^9.2.2` (≥9.0.0 16KB OK) | ✅ | `pubspec.yaml:29` |
| `ndkVersion` 显式声明 | 🟡 走 `flutter.ndkVersion` 默认 (3.41.9 默认 27.0.12077973) | 🟡 建议显式 | — |
| `abiFilters` | `arm64-v8a + x86_64` (R70 修复) | ✅ | `android/app/build.gradle.kts:111` |

**完整实跑验 (CI 上跑, 需 unzip + objdump)**:

```bash
flutter clean
flutter build appbundle --release
unzip build/app/outputs/bundle/release/app-release.aab -d unpacked/
for so in unpacked/lib/*/lib*.so unpacked/lib/*/lib/*.so; do
  [ -f "$so" ] || continue
  echo "=== $so ==="
  objdump -p "$so" | grep "LOAD" | head -1
done
# 应看到 segment align >= 2**14 = 16384
```

**scripts/check_16kb_alignment.py 状态**: ✅ R70 写, 17 守门员之一, CI 自动跑, 当前绿 (配置层).

**未跑项**: 实跑 unzip + objdump 验 .aab 内部 .so segment align. 需要 release keystore (#4) 先生成 + `flutter build appbundle --release` 跑通. 工时: 0.25 day.

---

## 6. 阻断上架项 vs 非阻断项

### 🔴 阻断上架 (6 项 P0, 必修)

| # | 项 | 必填 | 不修后果 |
|---|----|------|----------|
| 1 | 真实截图 (手机 4 张 × 2 locale) | 必填 | Play Console 上传 .aab 前被拒 |
| 2 | feature_graphic.png (2 locale) | 必填 | 同上 |
| 3 | icon.png 512×512 (2 locale) | 必填 | 同上 |
| 4 | release keystore + key.properties | 必填 | 签 debug key 直接拒 |
| 5 | Data Safety Form (7 类 × 4 子项 = 28 项) | 必填 | 不填 .aab 不让上架 |
| 6 | Health Apps Questionnaire (4 大块) | 必填 | 健康类 App 强制 |

### 🟡 上架后可补 (P1-P2, 4 项)

| # | 项 | 影响 |
|---|----|------|
| 7 | zh-TW fastlane metadata (3 文件翻译) | 港台马新繁体市场无本地化 |
| 8 | `values-zh-rTW/strings.xml` + `values-zh-rCN/strings.xml` | 桌面 app_name 切不生效 |
| 9 | 7"/10" 平板截图 | "Tablet design required" 警告 |
| 10 | P1-13 `canScheduleExactAlarms()` 运行时检查 | 用户撤回权限后提醒延迟 15min |
| 11 | 5 厂商引导 hidden → 通用引导 visible | 国产 ROM 用户无救济 |
| 13 | `changelogs/85.txt` release notes | 上架后 changelog 缺失 |

### 🟢 非阻断 (P3, 优化项, 3 项)

| # | 项 | 影响 |
|---|----|------|
| 14 | `tools:ignore` lint 防御 | lint 警告 |
| 16 | `max_aspect` 折叠屏 | Pixel Fold 显示 |
| 23 | Play Integrity API | 设备完整性验证 (非金融类不强需) |

**上架最低门槛**: 修完 P0 6 项 + P1 4 项 = **10 项 / 共 25 项 = 40%**, 加 P0 急修 P1 = 2 day.

---

## 7. 国产 ROM 适配现状

### 7.1 自检卡 3 件套 (`notification_status_card.dart`)

| 组件 | 状态 | 行号 |
|------|------|------|
| **状态显示** (待发通知数, 0 = 没设上或被 OEM 杀掉) | ✅ | 175-200 |
| **一键测试** (测试通知按钮, R97-P1-6 修) | ✅ | 76-104 |
| **查看待发队列** (Title/Body ListView) | ✅ | 106-172 |
| **OEM 7 品牌引导** | 🟡 **整段 hidden** (FeatureFlag=false) | 261-264 |

### 7.2 7 品牌引导文案 (已翻译完整)

`notification_status_card.dart:298-359` 列了 7 品牌的步骤引导:
- **小米 (MIUI)**: 3 步 (自启动 + 电池优化 + 锁屏清理)
- **华为 (EMUI/HarmonyOS)**: 3 步 (自启动 + 后台 + 通知)
- **OPPO (ColorOS)**: 3 步 (含 realme/一加)
- **vivo (Funtouch/OriginOS)**: 3 步 (含 iQOO)
- **魅族 (Flyme)**: 2 步
- **三星 (OneUI)**: 2 步
- **其他 (Knox/小众)**: 2 步
- **通用 tip** ("OEM 策略可能随时更新, 请以最新系统设置为准")

### 7.3 FeatureFlag 守门

| Flag | 默认 | R93 阶段 2 决策 | 5 厂商 SDK 真接后 |
|------|------|-----------------|-------------------|
| `fiveVendorPushEnabled` | **false** | 隐藏 5 厂商引导段 | 翻 true 显示引导 + 5 厂商 SDK 接入 |
| `ventAudioEnabled` | true (R104 启用) | 显示 vent + mood 录音 button | — |
| `bootReceiverEnabled` | false (R97 删) | 重启后无 rescheduleAll | v1.0 改 WorkManager + FCM |
| `aliyunSmsEnabled` | false | 失联通知 mock 路径 | 翻 true 接阿里云 SMS |
| `emailServiceEnabled` | false | 邮件导出 mock | 翻 true 接 SendGrid |

### 7.4 WorkManager 缺失

- `lib/core/data/services/safety_watch_service.dart:107-116` `bootReceiverEnabled=false` 早返
- 重启后用户所有 flutter_local_notifications 定时通知**全失**
- `BootReceiver.kt` 保留作 v1.0 参考, 但 manifest 0 注册 (R97 删), 实际不触发
- 修法: v1.0 接 `workmanager` (~7.x), `BootReceiver` → `WorkManager` + 15min periodic reschedule
- 工时: 1-2 day (真接时)

---

## 8. Data Safety Form / Health Apps 完整度

### 8.1 Data Safety Form 28 子项填写模板 (Play Console 手填)

```
□ Does your app collect or share any of the required user data types?
  → Yes

□ Is all of the user data collected by your app encrypted in transit?
  → No (App doesn't transmit data — 0 network)

□ Do you provide a way for users to request that their data is deleted?
  → Yes (App 内删除 + 卸载清空, 见 privacy_policy.md §4)

Data types:
□ Location:     No
□ Personal info: Yes (Nickname, optional, v0.21+ nullable)
□ Financial info: No (Google Play 平台 IAP 自处理)
□ Health & fitness: Yes (Medication/dose/check-in/PHQ-9/GAD-7/mood score)
□ Messages: No
□ Photos and videos: No
□ Audio files: Yes (Vent audio R104+ enabled, optional)
□ Files and docs: No
□ Calendar: No
□ Contacts: Yes (Emergency contacts, NOT actually triggered — FeatureFlag.emergencyContactEnabled=false)
□ App activity: Yes (Check-in/medication/mood/assessment — local only)
□ Web browsing: No
□ App info and performance: Yes (Crash log via runZonedGuarded, device model for notification compat check)

For each "Yes" → 4 sub-items:
- Is this data collected, shared, or both? → Collected only
- Is this data processed ephemerally? → No (persistent on device)
- Is this data required for your app, or can users choose whether it's collected? → Required (in-app, not optional)
- Why is this data collected? → App functionality / personalization

Security practices:
- Data is encrypted at rest: ✅ Yes (AES-256 via SQLCipher + field-level)
- Data is encrypted in transit: N/A (0 network)
- Users can request data deletion: ✅ Yes (App 内 + 卸载)
- Independent security review: ❌ No (honest disclose)
```

### 8.2 Health Apps Questionnaire 4 大块模板

```
App type: Health & Fitness (self-tracking)

Health data collected:
- Medication (name, dose, schedule)
- Check-in timestamps
- PHQ-9 / GAD-7 assessment scores
- Mood scores (1-5 scale)
- Vent audio recordings (R104+ enabled, opt-in)

Medical device claim:
☐ My app is NOT a medical device and does NOT claim to diagnose, treat, cure, or prevent any disease or condition.

Clinical claim:
☐ My app does NOT provide medical advice, diagnosis, or treatment. It is a personal tracking tool only.

User consent for health data:
✅ Yes (3 同意勾选 — privacy_policy.md §0 + sensitive_data_consent.md)

Data retention:
✅ Until user uninstalls (= local data cleared immediately)

Account requirement:
☐ No account required
```

---

## 9. APK 签名 / ProGuard / Play Integrity 评估

### 9.1 APK 签名 🟡 50%

| 检查项 | 状态 | 来源 |
|--------|------|------|
| **v2 签名** | 🟡 待实跑验 (R67 release block 写好, 缺 keystore) | `android/app/build.gradle.kts:77-114` |
| **v3 签名** (强制) | 🟡 同上 (Android 9+ 强制) | 同上 |
| **v4 签名** (增量) | 🟡 可选 (Android 11+) | 未配置 — 影响增量 install 性能, 不阻断 |
| **Play App Signing** | ❌ 必走, 5 步骤指南完整 | `docs/PLAYSTORE_SIGNING_GUIDE.md` |
| **debug key fallback** | ✅ R97-P0-5 修 (默认 release, -PdebugSigning=true 走 debug) | `android/app/build.gradle.kts:91-95` |
| **key.properties.example** | ✅ 完整模板 | `android/key.properties.example` |
| **实际 keystore** | ❌ **不存在** (需 `keytool -genkey`) | `android/playstore_signing_key.jks` |
| **实际 key.properties** | ❌ **不存在** (需 cp example + 填 4 值) | `android/key.properties` |
| **.gitignore 排除** | ✅ 已加 (R63 修) | `.gitignore` + `android/.gitignore` |

**修复**: 走 `docs/PLAYSTORE_SIGNING_GUIDE.md` 5 步:
1. `keytool -genkey -v -keystore android/app/chroniccare-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias chroniccare` (~2 min)
2. `cp android/key.properties.example android/key.properties` + 填 4 真实值
3. `signingConfig = signingConfigs.getByName("release")` (R97 已默认, 跳过)
4. Play Console 启用 Play App Signing + 上传 .aab
5. `apksigner verify --print-certs build/app/outputs/bundle/release/app-release.aab` 验 v2/v3

工时: 0.5 day.

### 9.2 ProGuard / R8 混淆 ✅ 90%

| 检查项 | 状态 | 来源 |
|--------|------|------|
| `isMinifyEnabled = true` (release) | ✅ | `android/app/build.gradle.kts:101` |
| `isShrinkResources = true` (release) | ✅ | `android/app/build.gradle.kts:102` |
| `proguard-android-optimize.txt` (默认) | ✅ | `android/app/build.gradle.kts:104` |
| `proguard-rules.pro` (项目) | ✅ 11 plugin keep + 1 app keep | `android/app/proguard-rules.pro` |
| Flutter / flutter_local_notifications / audioplayers / record / sqlcipher / speech_to_text / flutter_secure_storage / share_plus / path_provider / drift / Google Play Core 完整 keep | ✅ | 同上 |
| `com.chroniccare.chroniccare.**` (app 自身) keep | ✅ R63 修, 防 R8 误判 | line 48-51 |
| `R8 -keepattributes SourceFile,LineNumberTable` (crash report 可读) | ✅ | line 40-41 |
| 第三方 `in_app_purchase` 缺 keep | 🟡 检查 | `pubspec.yaml:71` 用了但 `proguard-rules.pro` 0 keep — Google 官方包通常自 keep, 待实跑验 |

**修复**: 实跑 `flutter build appbundle --release` + 反编译 .aab 看 R8 误杀没. 工时: 0.25 day.

### 9.3 Play Integrity API ❌ 0%

- **未接** (`grep play_integrity/safetyNet/play_licensing/play_core` 0 匹配)
- 精神心理 App **非金融类, 不强制**
- 真接意义: 防 root / 模拟器 / 篡改设备, 但精神心理数据**已本地加密** (SQLCipher), 设备 root 也读不到
- **结论**: 暂不接, 等 v1.0+ 商业版 (IAP + 云同步) 时再评估
- 工时: 1-2 day (真接时)

---

## 10. 修复路线图

### 10.1 上架最低门槛 (2 day, 6 P0 项)

| Day | AM | PM |
|-----|----|----|
| **Day 1** | 1. `keytool -genkey` + `cp key.properties.example key.properties` + 填 4 值 (0.5h)<br>2. Play Console 启用 Play App Signing (1h)<br>3. `flutter build appbundle --release` 验 v2/v3 (0.5h)<br>4. Play Console Data Safety Form 28 子项手填 (2h)<br>5. Play Console Health Apps 4 大块手填 (1h) | 6. Android emulator 录 4 张手机截图 (en-US + zh-CN) (3h)<br>7. 设计 feature_graphic.png 1024×500 (1h)<br>8. 导出 icon.png 512×512 (0.5h) |
| **Day 2** | 9. Play Console "Test users" 内测 (closed testing) 跑通 (1h)<br>10. Data Safety 28 子项 + Health Apps 4 大块 verify 提交 (1h)<br>11. 7"/10" 平板 emulator 录 2 张 (en-US + zh-CN) (2h) | 12. Play Console Production 频道 create release (0.5h)<br>13. 写 v0.30.0 release notes (changelogs/85.txt) (1h)<br>14. 上传 .aab + Start rollout to 5% (0.5h)<br>15. 24h 后观察 crash report + Data Safety 审核 (passive wait) |

### 10.2 完整修复 (3 day, P0 + P1 + P2)

| Day | 项 | 工时 |
|-----|----|------|
| **Day 1** | P0 6 项 | 2 day |
| **Day 2** | P0 6 项续 + 7"/10" 平板截图 | 1 day |
| **Day 3 AM** | P1 #7 zh-TW fastlane metadata (cp zh-CN + 翻译 3 文件) (0.5d)<br>P1 #8 `values-zh-rTW/strings.xml` + `values-zh-rCN/strings.xml` (0.25d)<br>P1 #10 P1-13 `canScheduleExactAlarms()` 运行时检查 (0.5d) | 1.25 day |
| **Day 3 PM** | P2 #11 国产 ROM 引导拆"通用"visible (0.5d)<br>P2 #13 release notes 3 语 (0.25d) | 0.75 day |

### 10.3 优化项 (1-2 day, P3 / 长期)

- **v1.0+ 接 5 厂商 push SDK** (1-2 月审核): 翻 `fiveVendorPushEnabled=true` + 注册 5 厂商 manifest receiver + `_OemBackgroundHint` 显示
- **v1.0+ 接 WorkManager 替 BootReceiver**: 翻 `bootReceiverEnabled=true` + `flutter_workmanager` 15min periodic
- **v1.0+ 接阿里云 SMS**: 法务模板审核 (1-2 月) + 翻 `aliyunSmsEnabled=true`
- **v1.0+ 接 SendGrid Email**: 法务模板审核 (1-2 月) + 翻 `emailServiceEnabled=true`
- **v1.0+ IAP 真接 productId**: 翻 `iapEnabled=true` + App Store Connect / Play Console 商品 ID 配
- **Play Integrity API** (可选, 商业版)

---

## 11. 最终结论

**R105 自评 40% → 实际 55%** (R61/R63/R67/R97 集中修复使 Android 侧很扎实, 但 **Play Console 后台手填项 + 素材制作 0 进度**)

**上架最低门槛 2 day**:
1. 生成 release keystore (0.5d)
2. Play Console 手填 Data Safety + Health Apps (1d)
3. 录截图 + 设计 feature_graphic + icon (0.5d)

**完整合规 3 day** + 1 day P1 补 (P1-13 + 国产 ROM 拆引导 + 繁中 metadata)

**真正能上架** (55% → 100%) 需 **5 day P0 + P1 + P2**, 外加 1-2 月等法务模板 + 阿里云 / SendGrid 审核 (本批不修, v1.0 处理).

**国产 ROM 用户体验**:
- **当前**: 自检卡 3 件套 (状态/测试/查看) 正常用, 7 品牌引导**整段 hidden** (FeatureFlag=false)
- **修后**: 7 品牌引导**通用部分** visible (三星+其他) + 5 厂商 (米/华/OPP/vivo/魅族) hidden + 撤回 SCHEDULE_EXACT_ALARM 时引导系统设置

**建议优先级**:
1. **本周**: P0 6 项 (2 day) → 上 closed testing
2. **下周**: P1 4 项 (1 day) → 上 production
3. **下下周**: P2/P3 优化 (0.5-1 day) → 黄金阶段
4. **1-2 月后**: 法务 + 5 厂商 + 阿里云 + SendGrid 真接 (1-2 day × 4) → v1.0

---

**附录 A: 守门员脚本清单** (本审计 cross-check 用)

1. `python scripts/check_16kb_alignment.py` — 16KB page size (本项目绿)
2. `python scripts/check_arb_keys.py` — zh / en / zh_Hant ARB sync (R56e 维护, 当前 1091 keys)
3. `python scripts/check_orphan_arb_keys.py` — ARB key 定义但未引用 (R56e 新增)
4. `dart scripts/check_all.dart` — 4 层架构纯度 + 一致性 (R13 合并)
5. `python scripts/check_cross_feature.py` — 跨 feature import 边界
6. `python scripts/check_legal_consent.py` — PIPL §13/§14 单独同意检测
7. `python scripts/check_strings_hardcoded.py` — 硬编码中文检测
8. `python scripts/check_zh_hant_consistency.py` — 繁简一致性 (OpenCC s2tw)
9. `python scripts/check_sms_release_ready.py` — SMS 上线前 checklist (R58 降 warn-only)
10. `python scripts/check_no_hardcoded_utc.py` — UTC 硬编码
11. `python scripts/check_no_pua.py` — PUA 字符
12. `python scripts/check_widget_dispose.py` — 资源泄漏
13. `python scripts/check_drift_namespace.py` — @DataClassName 唯一
14. `python scripts/check_datetime_race.py` / `race2.py` — DateTime.now() 多次调用 race
15. `python scripts/check_fullwidth_punctuation.py` — 全角标点 (warn-only)
16. `python scripts/check_changelog.py` — pubspec 版本号 + CHANGELOG 顺序
17. `python scripts/check_16kb_alignment.py` — 16KB page size (v0.30 R92 文档补)

**17 守门员当前全绿** (R100 P0 集中修后), 审计无新违规.

---

**附录 B: 关键源码引用**

- `android/app/build.gradle.kts:34-35` — minSdk=24 + targetSdk=36 (R63 pin)
- `android/app/build.gradle.kts:57-75` — release signingConfig (R97-P0-5 切)
- `android/app/src/main/AndroidManifest.xml:50-59` — application 6 防护 (R61+R63)
- `android/app/src/main/AndroidManifest.xml:40-48` — 5 权限 + RECORD_AUDIO (R105 恢复)
- `lib/core/data/services/notification_service.dart:138-141` — R97-P1-6 in-context 申请
- `lib/core/data/services/notification_service.dart:313-325` — P1-13 TODO canScheduleExactAlarms
- `lib/core/data/services/safety_watch_service.dart:107-116` — bootReceiverEnabled FeatureFlag 守门
- `lib/presentation/pages/settings/widgets/notification_status_card.dart:261-264` — 5 厂商 hidden
- `lib/presentation/pages/setup/setup_page_state.dart:493-513` — POST_NOTIFICATIONS 申请
- `lib/main.dart:127-194` — 并行 bootstrap + runApp 完整 app
- `android/app/src/main/res/xml/backup_rules.xml` — Android 6-11 exclude
- `android/app/src/main/res/xml/data_extraction_rules.xml` — Android 12+ exclude
- `android/app/src/main/res/xml/network_security_config.xml` — cleartext 禁
- `android/app/proguard-rules.pro:48-51` — `com.chroniccare.chroniccare.**` keep (R63)
- `assets/legal/privacy_policy.md:1-230` — 完整 PIPL §28/§13/§23/§38/§14 + 4 修订历史
- `assets/legal/medical_disclaimer.md:1-53` — 4 类不是医疗设备声明 (R83 修)
- `pubspec.yaml:5` — version 0.30.0+85
- `pubspec.yaml:24` — sqlcipher_flutter_libs ^0.6.5 (R82 升级, 16KB 满足)
- `fastlane/metadata/android/en-US/full_description.txt:1-48` — 48 行英文完整描述
- `docs/PLAYSTORE_SIGNING_GUIDE.md:1-178` — 5 步签名配置 + 6 FAQ
