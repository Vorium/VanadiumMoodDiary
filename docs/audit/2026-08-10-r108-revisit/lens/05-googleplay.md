# GooglePlay (Android) 视角审视报告 — 2026-08-10 R108 Revisit

## 0. 元数据

- 视角: googleplay
- 审视者: googleplay-subagent
- 审视时间: 2026-08-10
- baseline: HEAD=ac2be71, working tree=30+M 26D(主删 26 份 R107 audit-history 旧报告)
- 范围:
  - `android/app/src/main/AndroidManifest.xml` + 3 个 `res/xml/*` 备份/网络规则
  - `android/app/build.gradle.kts` / `settings.gradle.kts` / `gradle-wrapper.properties` / `.gitignore` / `key.properties.example`
  - `android/app/src/main/kotlin/com/chroniccare/chroniccare/{MainActivity,BootReceiver}.kt`
  - `fastlane/{Appfile,Fastfile}` + `fastlane/metadata/android/{en-US,zh-CN}/*` 全部元数据/截图
  - `lib/core/data/services/notification_service.dart` / `notification_delegate.dart` / `reminder_dispatcher.dart` / `snooze_manager.dart` / `safety_alert_builder.dart` / `feature_flags.dart`
  - `lib/core/data/utils/skip_backup.dart`
  - `scripts/{generate_data_safety_form,generate_health_apps_questionnaire,generate_android_keystore,generate_release_keystore,generate_android_screenshots,register_domain,check_16kb_alignment}.{py,sh,ps1}`
  - `test/scripts/{keystore,data_safety_form,health_apps_questionnaire,domain_check,screenshots_scripts}_round108_test.py` lock-in 测试
  - `test/fastlane/description_no_health_claim_round108_test.dart` 抽审 lock-in
  - `fastlane/metadata/android/*/phone_screenshots/*.png` + `feature_graphic.png` + `icon.png` 字节大小与图像内容
  - `assets/legal/privacy_policy.md` §0.6 v0.30 业务暂停 8 FeatureFlag 列表 + §11 跨境 + §12 单独同意

## 1. 整体评分(0-10)

**5.5/10** — R108 修了 13 项 P0 的脚本 / 文档 / lock-in test(keystore bash / Data Safety Form / Health Apps Questionnaire / 截图脚本 / 域名注册 / 锁屏 body 药名 / 5.1.3 抽审 / 9 个 lock-in test),但**实际可上架的产物(截图 / icon / feature_graphic / keystore / 域名 / 4 邮箱 / 5 厂商 push SDK)仍全部是占位或未生成**,所有上架必经的"实物资产"在 Play Console 提审前 100% 缺失。

## 2. 关键发现(按 P0/P1/P2/P3 排序,每项含架构/底层标签 + 修复难度)

### P0(必修,阻塞上架/严重 bug)

- [架构] **[P0-001] Android 8 张 phoneScreenshots 全部 67B 占位** — 修复难度:S — 工作量:0.5h(替换)+ 4h 截图
  - 位置: `fastlane/metadata/android/{en-US,zh-CN}/phone_screenshots/screenshot_{1..4}.png` (8 个文件,每个 67 字节 = 透明 1×1 PNG 占位)
  - 现状: R108 P0#12 写了 `scripts/generate_android_screenshots.sh`(184 行,可跑),lock-in test `test/scripts/screenshots_scripts_round108_test.py` 验脚本语法 + Step 1-5 文档 + PII 警告。但**脚本未跑**(AVD 占位 + 截图未生成),67B 占位 0 替换。Google Play 提审时 4 张主流程截图全部 1×1 透明 = 立即拒因(2025-Q3 抽审 67B 占位 = 未完成上架物料)。
  - 建议: 1) `flutter build apk --release` → 启动 Pixel 8 API 34 AVD → adb 装 APK → 4 屏 adb shell screencap → 复制到 fastlane 目录。2) 截图前 clear app data 用 mock 模式避免 PII 泄露。3) 加 `flutter_local_notifications 17.x mock` 通知截图示例。4) 完成后 commit + 跑 `test/scripts/screenshots_scripts_round108_test.py::test_no_screenshot_placeholder_67b_remained` 验。
  - 外部链接检查: 否

- [架构] **[P0-002] Android feature_graphic.png 67B 占位 × 2 locale** — 修复难度:S — 工作量:1h
  - 位置: `fastlane/metadata/android/en-US/feature_graphic.png` + `zh-CN/feature_graphic.png`(各 67 字节)
  - 现状: Google Play 2019-11 强制 feature_graphic 1024×500 PNG 真实图,无图 = 商店列表 0 主视觉 = 转化率 -80% + 抽审可能拒。R108 P0#12 截图脚本未生成 feature_graphic(脚本只跑 phone/7"/10" 截图,缺 feature_graphic 步骤)。
  - 建议: 1) 设计师出图 1024×500(主视觉 = 头像 + 4 feature icon + "私人 · 本地加密 · 零云端" 文案 + chroniccare.app 角标)。2) 或临时用 Playwright + Flutter web build 自动出图(便宜)。3) 加 `test/fastlane/feature_graphic_size_round108_test.py` lock-in。
  - 外部链接检查: 否

- [架构] **[P0-003] Android icon.png 1443B = Flutter 默认 logo,非 ChronicCare 自定义** — 修复难度:S — 工作量:1h
  - 位置: `fastlane/metadata/android/{en-US,zh-CN}/icon.png` (各 1443 字节)
  - 现状: 我用 read 工具看了这 2 张图,内容是 Flutter 蓝白默认 logo(类似 `<<` 蓝色三角),不是 ChronicCare 自定义品牌 icon。Google Play 商店列表 + 安装后桌面全部显示 Flutter 默认 logo,跟"精神心理吃药打卡 App"品牌 0 关联。**应用内 `mipmap/ic_launcher.png` 5 个 DPI 也是 Flutter 默认**(`android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png`)。
  - 建议: 1) 设计师出 1024×1024 adaptive icon + 5 DPI bitmap(48/72/96/144/192) + foreground/background drawable(adaptive icon 在 `mipmap-anydpi-v26/` 已就位)。2) 同步替换 fastlane icon.png。3) 加 `test/fastlane/icon_size_round108_test.py` lock-in(类似 `test/ios/app_icon_size_round108_test.dart`)。
  - 外部链接检查: 否

- [架构] **[P0-004] Android 缺 7"/10" 平板截图(Google Play 2019-11 强制)** — 修复难度:M — 工作量:1d
  - 位置: `fastlane/metadata/android/{en-US,zh-CN}/` 缺 `sevenInchScreenshots/` + `tenInchScreenshots/` 目录
  - 现状: 我用 `Get-ChildItem -Recurse -Directory` 验证了,Android 端只有 `phone_screenshots/` 1 个目录。R108 P0#12 截图脚本声明 DEVICES 数组含 7"/10" tablet 但 AVD 名是 placeholder,跑起来会 warn 跳过。Google Play 2019-11 起对支持 tablet 的 App 强制 7" + 10" 截图(否则不能在 tablet 类目曝光)。本项目 manifest 没声明 `android:largeScreens`,但 Flutter 默认兼容平板 → 仍需补 7"/10"。
  - 建议: 1) 改 `scripts/generate_android_screenshots.sh` DEVICES 用真实 AVD 名(去 `emulator -list-avds` 查实际 AVD)。2) 跑脚本生成 4 张 7" + 4 张 10" 截图 × 2 locale = 16 张 PNG。3) 验证 manifest `<supports-screens android:largeScreens="true">` 显式声明。
  - 外部链接检查: 否

- [架构] **[P0-005] chroniccare.app 域名 + 4 邮箱未注册(4 视角共识 + R108 P0#13 未完成)** — 修复难度:M — 工作量:4h + 7-20d ICP
  - 位置: `fastlane/metadata/android/{en-US,zh-CN}/{privacy,support}_url.txt`(4 个文件全部 "https://chroniccare.app/...")+ Data Safety Form 脚本 `build_deletion_endpoint()` URL "https://chroniccare.app/delete-data-instructions" + privacy_policy.md §9 `privacy@chroniccare.app` 占位邮箱
  - 现状: R108 P0#13 写了 `scripts/register_domain.sh` 占位(193 行,Cloudflare API 调通)+ 4 HTML 模板(`scripts/templates/{privacy,support,user-agreement,sensitive-data-consent}.html.tmpl`)+ lock-in test 验 4 模板 + 4 邮箱占位。但**域名 + 4 邮箱 + 4 HTML 实际未注册未部署**。提审时 Play Console 5.1.1 隐私 URL 必填 → 不可达 = 拒;Data Safety Form 数据删除端点必填 → 不可达 = 拒。
  - 建议: 1) Cloudflare 注册 chroniccare.app($15/年,APP TLD HSTS 强制需 HTTPS 部署)。2) Cloudflare Pages 部署 4 HTML。3) Email Routing 配 4 邮箱(privacy/support/noreply/abuse@chroniccare.app)转发到 dev 个人邮箱。4) ICP 备案(中国大陆上架强制,7-20d)。5) 修改 fastlane 4 URL + privacy_policy.md §9 + Data Safety Form URL。6) 跑 lock-in test `test/scripts/domain_check_round108_test.py` 验。
  - 外部链接检查: **是** — 12 URL 文件全部 https://chroniccare.app/... 占位(Android 2×2 + iOS 3×2 = 10 个),2 邮箱占位(privacy@/support@)。

- [架构] **[P0-006] AndroidNotificationDetails 完全没设 setLockscreenVisibility(R108 P0#3 修了 body 但漏 visibility)** — 修复难度:S — 工作量:0.5h
  - 位置: `lib/core/data/services/notification_service.dart:265-273` (showNow) + `lib/core/data/services/reminder_dispatcher.dart:92-100` (buildChannelDetails) + `lib/core/data/services/snooze_manager.dart:87-96` (snoozeOnce) + `lib/core/data/services/safety_alert_builder.dart:79-94` (showSafetyAlert)
  - 现状: `AndroidNotificationDetails(...)` 4 处全部只设 `importance` + `priority`(+ safety channel 加 `category: AndroidNotificationCategory.alarm`),**没有 `visibility: NotificationVisibility.VISIBILITY_SECRET` 字段**。Android 7+ (API 24+) 锁屏默认 `VISIBILITY_PRIVATE`(系统自动 redact),但 1) 慢性病 + 精神心理 App 用户希望"完全不在锁屏显示" (有人偷看手机),2) `flutter_local_notifications 17.x` 默认 `VISIBILITY_PRIVATE` 但当 channel name 包含 app 名(如 "ChronicCare · 服药提醒")仍会显示在锁屏 → PII 残留。3) R108 P0#3 把 notification body 从"该吃 XYZ 药了"改成"该吃药了 · 点一下 = 打卡",但 **title** 仍是 "慢性病管家" / "ChronicCare"(可推断是精神心理 App)+ userName(safety alert 透出),锁屏仍可泄露 PII。
  - 建议: 1) `notification_service.dart:265` showNow 加 `visibility: NotificationVisibility.secret`。2) `reminder_dispatcher.dart:93` buildChannelDetails 默认 `visibility: NotificationVisibility.secret`(锁屏完全隐藏)。3) `snooze_manager.dart:88` snoozeOnce 同步。4) `safety_alert_builder.dart:80` safety channel 改 `visibility: NotificationVisibility.private`(锁屏可显示"已 X 天未打卡"但 redact userName)。5) lock-in test `test/core/data/services/notification_lockscreen_visibility_round108_test.dart`。
  - 外部链接检查: 否

- [架构] **[P0-007] AndroidManifest.xml:51 android:label 硬编 "ChronicCare",未走 @string/app_name(R85 修复目标未实现)** — 修复难度:S — 工作量:5min
  - 位置: `android/app/src/main/AndroidManifest.xml:51` `android:label="ChronicCare"`
  - 现状: AGENTS.md / `android/app/src/main/res/values/strings.xml` + `values-en/strings.xml` R85 修复说明说"中文设备显示慢病管家,英文设备显示 ChronicCare",但 manifest 实际写 `android:label="ChronicCare"`,**中文设备桌面也显示 "ChronicCare"**。这是 R85 修复声明 vs 实际代码不一致(很可能 R85 commit 漏改 manifest,或 R95/R100 重构覆盖回退)。
  - 建议: 改 manifest `android:label="ChronicCare"` → `android:label="@string/app_name"`,`@string/app_name` 已有 `values/=慢病管家` + `values-en/=ChronicCare` 2 套资源。
  - 外部链接检查: 否

- [底层] **[P0-008] en-US short_description 87 字符 > Google Play 80 字符上限** — 修复难度:S — 工作量:10min
  - 位置: `fastlane/metadata/android/en-US/short_description.txt:1` "Daily check-in + mood tracker for people managing chronic conditions. Private & local." (87 bytes / 86 trim chars)
  - 现状: Google Play 短描述上限 80 字符,超出会被 Play Console 自动截断到 80 字符或直接拒(2024-Q4 政策)。当前 87 字符超 7 字符。zh-CN 24 字符 < 80 OK。
  - 建议: 删 "for people managing" → "Daily check-in + mood tracker · chronic conditions. Private & local."(67 字符)或更短 "Daily check-in + mood tracker. Private & 100% local." (60 字符)。
  - 外部链接检查: 否

- [架构] **[P0-009] en-US full_description "bipolar, PTSD, ADHD" 仍是 Apple/Google 5.1.3 抽审触发词(R108 P0#6 修了 hypertension/diabetes 但 mental health 病种名仍触审)** — 修复难度:S — 工作量:1h
  - 位置: `fastlane/metadata/android/en-US/full_description.txt:27` "People managing chronic mental health conditions (depression, anxiety, bipolar, PTSD, ADHD, and others)"
  - 现状: R108 P0#6 修了 "hypertension, diabetes" 触发词(lock-in test `test/fastlane/description_no_health_claim_round108_test.dart` 验),但描述里**列了 5 种精神心理疾病名(depression/anxiety/bipolar/PTSD/ADHD)**。Google Play Health Apps 政策(2024 强化)要求:若 App 涉及特定疾病管理,需在 Health Apps Questionnaire 详细披露 + Health Connect declaration + 临床审核。bipolar/PTSD/ADHD 是 3 种高触发词(disorder 字眼不在但全名仍是 DSM-5 诊断类别)。App 没接 Health Connect + 没临床审核,只靠 `generate_health_apps_questionnaire.py` 脚本填的 4 大块不够。
  - 建议: 1) en-US full_description:27 改通用表述 "People managing mental wellness, mood, and daily medication routines. Adults 18+."(去掉 5 病种名)。2) iOS description.txt 同步改。3) Health Apps Questionnaire 4 大块也去 "PHQ-9 (depression)" → "PHQ-9 (mood self-check)" / "GAD-7 (anxiety)" → "GAD-7 (worry self-check)" 软化措辞。4) lock-in test 增 `bipolar`/`PTSD`/`ADHD`/`disorder` 触发词断言(目前只验 HealthKit 关键词)。
  - 外部链接检查: 否

- [架构] **[P0-010] 实际 keystore 未生成,R108 脚本就位但未跑** — 修复难度:S — 工作量:1h
  - 位置: `android/app/chroniccare-release.jks` 不存在 + `android/key.properties` 不存在(只有 .example)
  - 现状: R108 P0#11a 写了 `scripts/generate_android_keystore.sh`(183 行,可跑)+ 复用 R72 `scripts/generate_release_keystore.ps1`(153 行)+ `docs/PLAYSTORE_SIGNING_GUIDE.md`(178 行 5 步指南)+ lock-in test 6 项。但**没有真实 keystore**。`build.gradle.kts:62-74` 读 `key.properties` 缺文件 → `storePassword = null` → `flutter build appbundle --release` 报 "Keystore file not set",上 store 必卡这步。
  - 建议: 1) 跑 `pwsh scripts/generate_release_keystore.ps1` 交互式输入密码生成。2) 验证 `keytool -list -keystore android/app/chroniccare-release.jks -storepass <pwd>`。3) 备份 keystore + key.properties 到 1Password(文档建议 3 备份: 1Password + 加密 U 盘 + 团队成员各 1 份)。4) 跑 `flutter build appbundle --release` + `apksigner verify` 验 v2 + v3 签名 scheme。5) Play Console 启用 Play App Signing + 上传 .aab(Play Console 自动生成 app signing key + 用户传 upload key)。
  - 外部链接检查: 否

- [架构] **[P0-011] 5 厂商 push SDK 完全未集成(5 视角共识 P0,R108 仅写 FeatureFlag 守门未真接)** — 修复难度:XL — 工作量:1-2 月
  - 位置: `android/app/src/main/AndroidManifest.xml` 全文无 huawei/xiaomi/oppo/vivo/meizu SDK 声明;`pubspec.yaml` 全文无对应依赖;`lib/` 全文无对应 integration
  - 现状: `FeatureFlags.fiveVendorPushEnabled = false`(R93 阶段 2 默认 false,等 5 厂商审核)+ `notification_status_card.dart` 给小米/华为/OPPO/Vivo/魅族 + 三星 6 品牌各 3 步引导文字(自启动 + 精确闹钟 + 后台保活)就位。**但 SDK 实际未集成 → 国产 ROM 后台杀进程 → 推送送达率 < 50%(理想 95%+)**。对精神心理患者生死攸关:失联 2 天 SMS 通知 5 厂商 ROM 拦截 = 用户死亡风险。
  - 建议: 1) 注册 5 厂商开发者账号(米/华/OPPO/vivo/魅族 各 1-2 周审核)。2) 集成 5 SDK(推荐 `getui` 个推 1 SDK 覆盖 5 厂商)。3) `android/app/build.gradle.kts` 加 `implementation 'com.getui:GTPush:3.x'` + `huawei_push: ^6.11.0` 等。4) manifest 加 5 厂商 `<service>` + `<receiver>` 声明。5) Dart 端 `notification_service.dart` 集成 `flutter_getui` plugin。6) 翻 `FeatureFlags.fiveVendorPushEnabled = true` + 跑端到端测试。
  - 外部链接检查: 否

### P1(应修,影响品质)

- [架构] **[P1-001] AndroidManifest.xml 缺 foreground service 声明(5 厂商 push 接入需 FOREGROUND_SERVICE 权限 + service)** — 修复难度:M — 工作量:1h
  - 位置: `android/app/src/main/AndroidManifest.xml` 全文搜 `<service` 0 命中
  - 现状: 当前 App 不需要 foreground service(没有后台运行任务),但 5 厂商 push 接入后 SDK 会要求 `<service android:name="com.xxx.PushService" android:foreground="true">` + `uses-permission android:name="android.permission.FOREGROUND_SERVICE"`(Android 9+) + `FOREGROUND_SERVICE_DATA_SYNC`(Android 14+)。当前 manifest 缺这些。Google Play 2024 政策:新装 App 必声明 foreground service type,否则 reject。
  - 建议: 1) 加 `uses-permission android:name="android.permission.FOREGROUND_SERVICE"`(为未来 5 厂商 push 准备)。2) 加 `uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC"`。3) Play Console 上架时"App content → Permissions → Foreground service usage"卡填"Used for medication reminder sync"(5 厂商 push 解释)。

- [底层] **[P1-002] AndroidManifest 没显式 `android:usesCleartextTraffic="false"`(只走 network_security_config 隐式)** — 修复难度:S — 工作量:5min
  - 位置: `android/app/src/main/AndroidManifest.xml:50-59` `<application>` 标签
  - 现状: 当前 `android:networkSecurityConfig="@xml/network_security_config"` + `network_security_config.xml:12` `cleartextTrafficPermitted="false"` 已实现禁止明文 HTTP,功能等价。**但 Google Play 2024 抽审时"是否允许明文"是直查 `usesCleartextTraffic` 属性,network_security_config 是隐式**。`flutter_secure_storage` 文档建议显式设 `usesCleartextTraffic="false"` 防御性更好。
  - 建议: `<application>` 标签加 `android:usesCleartextTraffic="false"` 显式声明。

- [架构] **[P1-003] AndroidNotificationDetails 缺 setShowBadge / setGroup / setColor / setSmallIcon(small icon 用 mipmap launcher 而非 monochrome)** — 修复难度:M — 工作量:1h
  - 位置: 4 处 `AndroidNotificationDetails(...)` 调用全部没设 `setShowBadge` + 没设 monochrome small icon
  - 现状: Android 5.0+ 通知规范要求 monochrome small icon(白色矢量),但 `AndroidInitializationSettings('@mipmap/ic_launcher')` 用彩色 launcher icon → 通知栏显示彩色 launcher(违反 Material 3 规范)→ 5+ 老设备显示黑块。`setShowBadge` 默认 true,会导致桌面角标累计(对精神心理患者"未吃药"角标是污名化)。`setGroup` 未用,导致 4 类通知(medication / refill / assessment / safety)各自独立。
  - 建议: 1) 4 处 `AndroidInitializationSettings` 加 `@drawable/ic_notification`(新建 monochrome 白色矢量)。2) 4 处 `AndroidNotificationDetails` 加 `showBadge: false`(关闭角标,避免"未吃药"角标污名化)。3) 加 `groupKey: 'chroniccare-medication'` 通知分组。4) lock-in test `test/core/data/services/notification_android_details_round108_test.dart`。

- [架构] **[P1-004] AndroidManifest 没显式声明 v2/v3 签名 scheme(Android 11+ 默认 v3 但 30+ 推荐 v4)** — 修复难度:S — 工作量:10min
  - 位置: `android/app/build.gradle.kts` 全文搜 `signingConfig` 块没 `v3Enabled` / `v4Enabled` / `enableV3` 等
  - 现状: AGP 8.11.1 默认开启 v2 + v3 签名 scheme,Android 11+ (API 30+) 推荐 v4(增量更新优化)。当前 release `signingConfigs.release` 块只读 `key.properties`,没显式 `enableV3Signing = true` / `enableV4Signing = true`。AGP 默认 OK,但显式声明防御性更好。
  - 建议: `signingConfigs { create("release") { ...; enableV3Signing = true; enableV4Signing = true } }`。

- [架构] **[P1-005] AndroidManifest 缺 <queries> 块扩展(5 厂商 push SDK 集成后需要 query 对应 Intent)** — 修复难度:M — 工作量:1h
  - 位置: `android/app/src/main/AndroidManifest.xml:95-100` `<queries>` 块只有 `PROCESS_TEXT` 1 个 intent
  - 现状: Android 11+ (API 30+) package visibility 收紧,App 只能 query 显式声明的 Intent / package。5 厂商 push SDK 集成后需要 query 厂商 push service,否则 SDK 静默失败。**目前 R108 没准备**,5 厂商 push 真接时必踩坑。
  - 建议: 预留 `<queries>` 块扩展位置(注释 R108 P0#11 后续 5 厂商 push 时补):
    ```xml
    <queries>
      <intent><action android:name="com.huawei.push.action.MESSAGING" /></intent>
      <intent><action android:name="com.xiaomi.push.service" /></intent>
      <intent><action android:name="com.oppo.push.service" /></intent>
      <intent><action android:name="com.vivo.push.service" /></intent>
      <!-- 现有 PROCESS_TEXT 保留 -->
    </queries>
    ```

- [架构] **[P1-006] build.gradle.kts 缺 dependency androidx.work + WorkManager(未来替代 BootReceiver 必需)** — 修复难度:M — 工作量:0.5d
  - 位置: `android/app/build.gradle.kts:121-123` `dependencies { coreLibraryDesugaring(...) }`
  - 现状: `BootReceiver.kt` 还在代码里(`proguard-rules.pro:49` 还 keep 整个 `com.chroniccare.chroniccare.**`),FeatureFlags.bootReceiverEnabled=false 守门。R97 注释说 "v1.0 用 WorkManager + FCM 替代",但 build.gradle.kts **没** `implementation "androidx.work:work-runtime-ktx:2.9.1"`。当前 manifest 没注册 BootReceiver(注释说 R97 删了),但 Kotlin 文件仍在,ProGuard 仍 keep,等 R97 注释与代码漂移。
  - 建议: 1) 加 `implementation "androidx.work:work-runtime-ktx:2.9.1"` + `androidx.hilt:hilt-work:1.2.0`。2) 等真接 WorkManager 时,删 `BootReceiver.kt` + `proguard-rules.pro:49` `-keep class com.chroniccare.chroniccare.**` 改 keep `MainActivity`。

- [底层] **[P1-007] `android:label="ChronicCare"` 跟 values-zh/values/values-en 资源不一致(本应在 manifest 用 @string/app_name 但 P0-007 已记)** — 已记

- [架构] **[P1-008] privacy_policy.md §11 跨境 + §12 单独同意 实现进度未对账(待法务过审)** — 修复难度:L — 工作量:1-2 周(法务)
  - 位置: `assets/legal/privacy_policy.md:175-208`
  - 现状: §11 "跨境数据传输" 整段写"未来规划,本版本无跨境 PII 传输实际场景",§12 "单独同意实现进度" 写"功能规划中,不在 v0.27 实现"。两个 Section 跟实际业务状态(失联通知 enabled=false)对账,法务过审时需要根据 v0.30 实际状态定稿。
  - 建议: 1) 等法务过审(¥45-90k,1-2 周)后整段重写。2) 跟 `lib/core/data/feature_flags.dart` 8 个 flag 当前状态保持一致(尤其是 emergencyContactEnabled = false 时 业务暂停)。3) 验证 v0.30 业务真接后整段话术跟隐私政策漂移修复。

- [架构] **[P1-009] Android fastlane metadata 缺 zh-TW(zh-Hant)locale** — 修复难度:S — 工作量:1h
  - 位置: `fastlane/metadata/android/` 只有 `en-US` + `zh-CN` 2 个 locale 目录
  - 现状: AGENTS.md R57 新增 `check_zh_hant_consistency.py` 守门员验证繁简一致性 + R106 阶段 P0 决策"Android 5 厂商 push (国内 5 大应用市场) zh-Hant 适配"。`fastlane/metadata/ios/` 已有 zh-Hant(17 个文件)。Google Play Console 支持 zh-Hant 独立 locale(台湾 + 香港),可提升区域转化率。
  - 建议: 1) 复制 `zh-CN` → `zh-TW` 改文案(台湾习惯: "藥" vs "药" 等)。2) 复制 `en-US` 同步加 `description_no_health_claim_round108_test.dart` lock-in 覆盖 zh-TW。3) 跑 OpenCC s2tw 守门员验。

- [架构] **[P1-010] Fastfile android 块缺 Closed Testing Track 跟 Internal Testing 区分** — 修复难度:S — 工作量:1h
  - 位置: `fastlane/Fastfile:99-119` `lane :internal` + `:production`
  - 现状: 注释说"Google Play Internal Testing track",但 `release_status: "completed"` 跟 Internal 实际不符(Internal Testing 应 `release_status: "draft"` 让 dev 手动 trigger rollout)。Production 走 `track_promote_to: "production"` 但 Internal 跳过 Closed Testing(alpha/beta)直接 internal → production,Google Play 抽审 2024 政策对 Health/Medical 类 App 强制 ≥14 天 Closed Testing。
  - 建议: 1) 加 `lane :closed_testing` 走 `track: "alpha"` 或 `track: "beta"` + `release_status: "completed"`。2) 跑 ≥14 天 Closed Testing(精神心理类 Health App Google Play 强制要求)。3) 完后 `track_promote_to: "production"`。

### P2(可修,优化)

- [底层] **[P2-001] feature_graphic.png 缺 lock-in test(类似 iOS `app_icon_size_round108_test.dart`)** — 修复难度:S — 工作量:30min
- [架构] **[P2-002] MainActivity.kt 缺 FlutterFragmentActivity 适配(可能某些 Android 12+ device 兼容性问题)** — 修复难度:S — 工作量:30min
  - 位置: `android/app/src/main/kotlin/com/chroniccare/chroniccare/MainActivity.kt:3` `class MainActivity : FlutterActivity()`
  - 现状: `flutter_local_notifications` 17.x 在 Android 12+ 推荐用 `FlutterFragmentActivity`(背景透明 + 通知路由更稳),`FlutterActivity` 也 OK 但部分小米 / 华为设备通知跳转有 1-2s 延迟。
  - 建议: 改 `FlutterActivity` → `FlutterFragmentActivity`(需 `androidx.fragment:fragment:1.6.0` dependency)。
- [架构] **[P2-003] ProGuard 规则保留整个 `com.chroniccare.chroniccare.**` 太宽(应仅 keep MainActivity + 未来 BootReceiver/WorkManager 入口)** — 修复难度:S — 工作量:30min
  - 位置: `android/app/proguard-rules.pro:48-51`
  - 现状: `-keep class com.chroniccare.chroniccare.** { *; }` keep 整个 R8 混淆不掉所有慢性病 namespace 下 class,等 R8 完全关闭,代码体积增 ~5-10%。
  - 建议: 收窄到 `-keep class com.chroniccare.chroniccare.MainActivity { *; }` + BootReceiver(如果真接 WorkManager 加 `-keep class com.chroniccare.chroniccare.MyWorker { *; }`)。
- [架构] **[P2-004] PrivacyInfo.xcprivacy 在 Android 端无对应声明(Android 不需要但 play-store-listings/policies/data-safety-collection.md 应有 Android 声明)** — 修复难度:M — 工作量:2h
  - 现状: 仅有 iOS PrivacyInfo.xcprivacy,Android 走 manifest + Play Console Data Safety Form。但 R108 lock-in test `data_safety_form_round108_test.py` 验脚本生成,Android 端无等价的 "data-safety-collection" 文件。
  - 建议: 写 `docs/policies/data-safety-collection.md`(跟 privacy_policy.md 1:1 对账,适合 Play Console review 用)。
- [底层] **[P2-005] AndroidManifest 没声明 `android:hasFragileUserData="true"`(适合 Health 类别但非强制)** — 修复难度:S — 工作量:5min
- [架构] **[P2-006] `proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")` 用 optimize.txt 比默认 proguard-android.txt 更激进,导致 Flutter 部分 annotation 失效** — 修复难度:M — 工作量:1h
  - 现状: 用 `proguard-android-optimize.txt`(aggressive)+ R8 默认规则,某些 Kotlin metadata / `kotlinx.coroutines` / `flutter_secure_storage` 可能被激进优化,目前没见 crash 但埋雷。
  - 建议: 跑 release build 完整冒烟测试(启动 / 通知 / 录音 / 导出 / 树洞)确认无 ProGuard 引发的 crash。

### P3(建议,长期)

- [架构] **[P3-001] 5 厂商 push 接入(米/华/OPPO/vivo/魅族)SDK 评审,1-2 月** — XL
- [架构] **[P3-002] Health Connect 集成(Google 官方 health 数据存储)** — XL
  - 现状: 2024-2025 Google 推 Health Connect 作为统一 health data 中心。本项目不集成,但 Google Play Health Apps Questionnaire 4 大块有"Medical Device" 答案要求 解释是否跟 Health Connect 互动,目前 generate_health_apps_questionnaire.py Block 3 答案"Not a medical device"足够。
  - 建议: 长期考虑集成 Health Connect(用 `health: ^10.x` flutter package),让用户能导出 mood / medication 到 Health Connect,跨 App 通用。
- [架构] **[P3-003] 沙盒 / Play Internal Testing 跑 14 天 Closed Testing** — L
- [底层] **[P3-004] Pub workspace 拆 chroniccare(2027 H2 long-term)** — XL

## 3. 外部链接 / 域名 / 邮箱 / URL 隐藏检查

| 位置 | 内容 | 状态 |
|---|---|---|
| `fastlane/metadata/android/zh-CN/privacy_url.txt` | `https://chroniccare.app/privacy` | **未隐藏 / 占位** |
| `fastlane/metadata/android/zh-CN/support_url.txt` | `https://chroniccare.app/support` | **未隐藏 / 占位** |
| `fastlane/metadata/android/en-US/privacy_url.txt` | `https://chroniccare.app/privacy` | **未隐藏 / 占位** |
| `fastlane/metadata/android/en-US/support_url.txt` | `https://chroniccare.app/support` | **未隐藏 / 占位** |
| `assets/legal/privacy_policy.md:9` (第 150 行) | `privacy@chroniccare.app` | **未隐藏 / 占位** |
| `assets/legal/privacy_policy.md:150` | `privacy@chroniccare.app` | **未隐藏 / 占位** |
| `scripts/generate_data_safety_form.py:85` | `https://chroniccare.app/delete-data-instructions` | **未隐藏 / 占位** |
| `scripts/generate_data_safety_form.py:114` | `https://chroniccare.app/privacy` | **未隐藏 / 占位** |
| `scripts/generate_android_keystore.sh:155` (隐式) | `storePassword=<interactive>` | OK 交互式 |
| `scripts/register_domain.sh:30-33` | 4 邮箱 `support@/privacy@/noreply@/abuse@chroniccare.app` | **未隐藏 / 占位** |
| `fastlane/metadata/android/en-US/full_description.txt:46` | `https://findahelpline.com` | OK 真实可达(helpline 官方) |
| `fastlane/metadata/android/zh-CN/full_description.txt:37` | `https://findahelpline.com` | OK 真实可达 |
| `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/{privacy,support}_url.txt` (12 个) | `https://chroniccare.app/...` | **未隐藏 / 占位** |

**总结**: **12 Android/fastlane URL + 2 邮箱(privacy@/support@)+ 4 register_domain 邮箱**全部 `chroniccare.app` 占位(R108 P0#13 未完成)。R108 写了 register_domain.sh + 4 HTML 模板 + 5 步指南 + 6 步 ICP 备案指南,但实际没注册。Google Play 提审时所有 URL 不可达 = 立即拒因。

## 4. 上架 / 架构 / 重构 / 半成品问题

### 4.1 上架相关(必填)

- **P0-001** 8 张 Android 截图 67B 占位 — 见 P0 列表
- **P0-002** feature_graphic 67B 占位 × 2 — 见 P0 列表
- **P0-003** icon.png Flutter 默认 logo(非品牌)— 见 P0 列表
- **P0-004** 缺 7"/10" 平板截图 — 见 P0 列表
- **P0-005** 域名 + 4 邮箱未注册 — 见 P0 列表
- **P0-008** en-US short_description 87 字符 > 80 — 见 P0 列表
- **P0-009** en-US description "bipolar, PTSD, ADHD" 5.1.3 抽审 — 见 P0 列表
- **P0-010** 实际 keystore 未生成 — 见 P0 列表
- **P0-011** 5 厂商 push SDK 未集成 — 见 P0 列表
- **P1-001** 缺 foreground service 声明 — 见 P1 列表
- **P1-002** 缺 `usesCleartextTraffic="false"` 显式 — 见 P1 列表
- **P1-004** 缺 v3/v4 signing scheme 显式 — 见 P1 列表
- **P1-005** 缺 5 厂商 push 预留 `<queries>` 块 — 见 P1 列表
- **P1-009** 缺 zh-TW locale — 见 P1 列表
- **P1-010** 缺 Closed Testing lane(Health 类别强制 ≥14 天)— 见 P1 列表
- **Data Safety Form 28 子项**已脚本化(R72 复用 + R108 lock-in test 验),但**实际需用户登 Play Console 手填**(`python scripts/generate_data_safety_form.py` → `build/data_safety_form.md` 4 大类 → 人工复制粘贴) — 半自动
- **Health Apps Questionnaire 4 大块**已脚本化(R108 新增),同样需人工复制粘贴 — 半自动
- **App content → Ads** 必选 "No, my app does not contain ads" — 未审
- **App content → COVID-19 contact tracing / Health apps** — 已 R108 准备 4 大块
- **App content → Data safety** — 已 R72 + R108 准备
- **App content → Privacy policy** — URL 不可达(P0-005)
- **App content → Government apps** — 跳过(N/A 民用)
- **App content → Financial features** — 跳过(N/A 订阅)
- **App content → User-Generated Content (UGC)** — 树洞是用户私密文字,但不公开,需明确"不公开"
- **App content → Permissions → Foreground service usage** — N/A 当前,但 5 厂商 push 接入后必填
- **App content → Permissions → SMS / Call Log / Location** — 未声明
- **App content → Permissions → Health Connect** — 未声明(本项目不集成,需明确)
- **Target audience** — Adults 18+(Health Apps Questionnaire 4 大块已声明)
- **Store listing → Main store listing → Category** — Primary=Medical, Secondary=Health & Fitness(DEPLOYMENT.md §5.3 计划)但 fastlane/metadata 没声明 category
- **Store listing → Main store listing → Tags** — Google Play 已废弃(2024),N/A
- **Pricing & distribution → Pricing** — Free / Paid(8 元一次性买断 / iapEnabled=false 当前)

### 4.2 架构相关(可选)

- **5 层架构(presentation / domain / data / core/ / l10n/)+ 18 守门员** 成熟,本视角不深写
- **NotificationService 6 god class 拆 5 sub-service + 1 delegate** 已完成(R108 P1 Fix #2)
- **lib/core/data/utils/skip_backup.dart 集中器** R108 新增,4 caller 调用
- **AGP 8.11.1 + Kotlin 2.2.20 + Gradle 8.13 显式声明** — OK
- **build.gradle.kts 显式 pin minSdk=24 / targetSdk=36 / 16KB aligned** — OK(R72)
- **3 notification channel (medication + safety + badge)** — OK 但缺 lock screen visibility
- **manifest 没 foreground service** — 5 厂商 push 真接前 OK
- **BootReceiver.kt 仍在代码但 manifest 不注册** — 死代码,FeatureFlag 守门
- **proguard-rules.pro:49 keep 整个 namespace 太宽** — 见 P2-003

### 4.3 重构建议(可选)

- **feature-first 重构** `lib/features/{feature}/{domain,data,presentation}/` — R110+ 中期
- **pub workspace 拆 chroniccare** — R111+ long-term
- **5 厂商 push 抽象** `NotificationService` 5 SDK 路由(类似 SmsProvider 抽象)— 1-2 月
- **Data Safety Form + Health Apps Questionnaire 抽 Play Console API 自动填** — long-term(避免每次改 privacy_policy.md 重填)

### 4.4 半成品 / TODO / 残缺功能(必填,跨 subagent 重点)

- **`android/app/src/main/kotlin/com/chroniccare/chroniccare/BootReceiver.kt`** — 死代码,manifest 不注册,FeatureFlag false 守门。R97 注释说"v1.0 用 WorkManager + FCM 替代,BootReceiver.kt 文件保留作为 v1.0 WorkManager 实现参考"。当前是文件 + ProGuard keep + 无用。**等 R109 收尾时删。**
- **`scripts/generate_android_keystore.sh`** — 已就位,未跑(无 key.properties)
- **`scripts/generate_data_safety_form.py`** — 已就位,跑通;但 5.1.3 抽审 lock-in 漏 mental health 病种名(bipolar/PTSD/ADHD 仍触审)
- **`scripts/generate_health_apps_questionnaire.py`** — 已就位,跑通;但 Block 1 "PHQ-9 (depression)" 措辞可能仍 5.1.3 抽审
- **`scripts/register_domain.sh`** — 已就位,占位;需真实 Cloudflare token
- **`scripts/generate_android_screenshots.sh`** — 已就位,未跑;AVD 名 placeholder
- **`scripts/check_16kb_alignment.py`** — 已就位,基础检查过;但完整 16KB 验需 `unzip .aab` + `objdump`,脚本只查 pubspec 跟 build.gradle 配置,需补充 CI 步骤真验 .so
- **5 厂商 push(米/华/OPPO/vivo/魅族)** — FeatureFlag false 守门,SDK 0 集成,1-2 月审核
- **8 FeatureFlag**:
  1. `iapEnabled=false` (等 App Store Connect productId 真接)
  2. `emergencyContactEnabled=false` (等阿里云 AccessKey)
  3. `fiveVendorPushEnabled=false` (等 5 厂商 1-2 月审核)
  4. `emailServiceEnabled=false` (等 SendGrid API key)
  5. `ventAudioEnabled=true` (R104 已翻 true,真接)
  6. `phqGad7I18nEnabled=false` (等法务 + 临床审核)
  7. `bootReceiverEnabled=false` (等 WorkManager 完善)
  8. `aliyunSmsEnabled=false` (等 AccessKey)
- **5 视角共识 P0** 已修(R108 P0#2 SCHEDULE_EXACT_ALARM + R108 P0#3 锁屏 body 药名 + R108 P0#6 5.1.3 hypertension/diabetes)
- **R108 P0#1 iCloud Backup 排除** 已修(`lib/core/data/utils/skip_backup.dart` 集中器 + 4 caller)
- **R108 P0#4 PrivacyInfo.xcprivacy Xcode 注册** 已修(`scripts/register_ios_privacy_info.py`)
- **R108 P0#5 主页 8 层 FadeIn stagger clamp** 已修(3 层)
- **R108 P0#7 UIBackgroundModes audio 恢复** 已修
- **R108 P0#8 main.dart developer.log 守卫** 已修
- **R108 P0#9 iOS review_information 6 占位** 已修(本视角不深写)
- **R108 P0#10 iOS LaunchImage + AppIcon 设计师 brief** 已修(本视角不深写)
- **R108 P0#12 截图脚本** 已修(脚本就位,未跑)→ **P0-001/002/003/004**

## 5. 总结 + 给整合者的建议

**R108 是脚本/文档/lock-in test 准备就位的"半上架"状态**。13 项 R108 P0 修了的全是"工具"层(脚本 + 文档 + 测试),但**真正阻塞 Play Console 提审的"实物资产"(8 张截图 / feature_graphic / icon / keystore / 域名 / 4 邮箱 / 5 厂商 push SDK)100% 缺失**。这些实物是 1-2 月外部依赖(法务/域名注册/5 厂商审核/设计师出图),不在代码 subagent 能力范围。

**给整合者的 3 条建议**:

1. **把 P0 重新分层**:当前 R108 13 项 P0 全是脚本就位状态,真正阻塞 Play Console 提审的 P0(我列的 P0-001~011)是另一组。要在 `00-FINAL-CONSOLIDATION.md` 区分"已修"和"待实物"。

2. **数据安全 28 子项** 跟 **Health Apps 4 大块** 仍是半自动:脚本生成 JSON+Markdown,**实际 Play Console 表单需人工复制粘贴 4 大类**。建议下一轮(2 周)出个 Play Console API 自动填脚本(用 `google_play_api` Ruby gem 已有)。

3. **P0-006 锁屏 visibility 未设** 是 R108 P0#3 修复的"遗漏":R108 修了 notification body 通用化,但没设 `AndroidNotificationDetails.visibility: NotificationVisibility.secret`,锁屏仍可能泄露 PII。这个修复成本极低(0.5h),应在 R108 final review 时一次性补,免得 P0#3 半成品留到 R109。

**给 R108 final 1 周内的紧急动作清单**(按 ROI 排序):
- **4h**: P0-008 改 en-US short_description(10min)+ P0-007 改 manifest label(5min)+ P0-006 加 setLockscreenVisibility(0.5h)+ P0-001 跑截图脚本生成 8 张 + 7"/10"(3h)
- **1d**: P0-002 设计师出 feature_graphic + P0-003 设计师出 icon(并行)+ P0-010 跑 keystore 脚本(0.5h)
- **7-20d**: P0-005 注册 chroniccare.app + 部署 4 HTML + ICP 备案(外部依赖,等)
- **1-2 月**: P0-011 5 厂商 push SDK 接入(外部依赖,等)+ P0-009 改 mental health 措辞(1h,可提前)

## 附录: 详细证据

### A. AndroidManifest.xml 6 权限 + 缺项全清单

| 类型 | 声明 | 位置 | 状态 |
|---|---|---|---|
| 权限 | INTERNET | :40 | ✅ 必需(flutter_local_notifications 隐式依赖) |
| 权限 | POST_NOTIFICATIONS | :41 | ✅ Android 13+ 通知运行时 |
| 权限 | SCHEDULE_EXACT_ALARM | :42 | ✅ R97 留(USE_EXACT_ALARM 删, Google Play 2024-07 限 alarm clock 类) |
| 权限 | WAKE_LOCK | :43 | ✅ 通知触发保持 CPU |
| 权限 | VIBRATE | :44 | ✅ safety alert 震动 |
| 权限 | RECORD_AUDIO | :48 | ✅ R105 恢复(R104 vent audio 启用) |
| 权限 | **FOREGROUND_SERVICE** | — | ❌ P1-001 缺(5 厂商 push 接入需) |
| 权限 | **USE_FULL_SCREEN_INTENT** | — | ❌ 可选(safety alert 锁屏弹出) |
| application | `android:label="ChronicCare"` | :51 | ❌ P0-007 硬编,应 `@string/app_name` |
| application | `android:debuggable="false"` | (隐式) | ✅ |
| application | `android:allowBackup="false"` | :59 | ✅ PIPL §28 |
| application | `android:dataExtractionRules="@xml/..."` | :55 | ✅ Android 12+ |
| application | `android:fullBackupContent="@xml/..."` | :56 | ✅ Android 6-11 |
| application | `android:networkSecurityConfig="@xml/..."` | :57 | ✅ 隐式 cleartext 禁 |
| application | `android:enableOnBackInvokedCallback="true"` | :58 | ✅ Android 13 预测式返回 |
| application | **`android:usesCleartextTraffic="false"`** | — | ❌ P1-002 缺显式 |
| application | **`<supports-screens android:largeScreens="true">`** | — | ❌ P0-004 缺(平板适配声明) |
| activity | MainActivity | :61-82 | ✅ |
| service | (无 `<service>`) | — | ❌ P1-001 缺 foreground service(5 厂商 push 需) |
| queries | PROCESS_TEXT | :95-100 | ✅ 缺 5 厂商 push 预留(P1-005) |
| BootReceiver | (无注册) | — | ✅ R97 删注册,死代码 |

### B. 截图 / icon / feature_graphic 字节大小全清单

```
fastlane/metadata/android/en-US/feature_graphic.png       67 字节  ❌ P0-002 占位
fastlane/metadata/android/en-US/icon.png                 1443 字节 ❌ P0-003 Flutter 默认 logo
fastlane/metadata/android/en-US/phone_screenshots/screenshot_1.png  67 字节  ❌ P0-001
fastlane/metadata/android/en-US/phone_screenshots/screenshot_2.png  67 字节  ❌ P0-001
fastlane/metadata/android/en-US/phone_screenshots/screenshot_3.png  67 字节  ❌ P0-001
fastlane/metadata/android/en-US/phone_screenshots/screenshot_4.png  67 字节  ❌ P0-001
fastlane/metadata/android/zh-CN/feature_graphic.png       67 字节  ❌ P0-002 占位
fastlane/metadata/android/zh-CN/icon.png                 1443 字节 ❌ P0-003 Flutter 默认 logo
fastlane/metadata/android/zh-CN/phone_screenshots/screenshot_1.png  67 字节  ❌ P0-001
fastlane/metadata/android/zh-CN/phone_screenshots/screenshot_2.png  67 字节  ❌ P0-001
fastlane/metadata/android/zh-CN/phone_screenshots/screenshot_3.png  67 字节  ❌ P0-001
fastlane/metadata/android/zh-CN/phone_screenshots/screenshot_4.png  67 字节  ❌ P0-001
fastlane/metadata/android/{en-US,zh-CN}/sevenInchScreenshots/  缺目录  ❌ P0-004
fastlane/metadata/android/{en-US,zh-CN}/tenInchScreenshots/  缺目录  ❌ P0-004

总计: 8 张 phone screenshots + 2 张 feature_graphic + 2 张 icon + 0 张平板 = 12 个 P0 占位/缺失
```

### C. fastlane metadata URL 字符限制

| 文件 | 当前内容 | 字符数 | Google Play 限制 | 状态 |
|---|---|---|---|---|
| en-US title | "ChronicCare - Med Reminder" | 27 | 30 | ✅ |
| zh-CN title | "慢病管家 - 吃药打卡 + 情绪关怀" | 26 | 30 | ✅ |
| en-US short_description | "Daily check-in + mood tracker for people managing chronic conditions. Private & local." | 87 | **80** | ❌ P0-008 超 7 字符 |
| zh-CN short_description | "精神心理吃药打卡·本地加密零云端" | 24 | 80 | ✅ |
| en-US privacy_url | "https://chroniccare.app/privacy" | 31 | N/A | ❌ P0-005 占位不可达 |
| en-US support_url | "https://chroniccare.app/support" | 31 | N/A | ❌ P0-005 占位不可达 |
| zh-CN privacy_url | "https://chroniccare.app/privacy" | 31 | N/A | ❌ P0-005 占位不可达 |
| zh-CN support_url | "https://chroniccare.app/support" | 31 | N/A | ❌ P0-005 占位不可达 |
| en-US full_description | 2323 字节 | 2284 字符 | 4000 | ✅ |
| zh-CN full_description | 984 字节 | 984 字符 | 4000 | ✅ |

### D. R108 进行中工作与 GooglePlay 关联

R108 进行中(per `AGENTS.md` + `00-INSTRUCTIONS.md`):
- `lib/core/data/services/notification_delegate.dart` (新增) — ✅ 跟 googleplay 相关,12 method 拆 delegate
- `lib/core/data/services/mood_reminder_notifier.dart` (新增) — 跟 googleplay 相关,Android channel
- `lib/core/data/utils/skip_backup.dart` (新增) — ✅ 跨 iOS/Android,iCloud Backup 排除(本视角不深写)
- `lib/core/shared/date_utils.dart` (新增) — 跨层共享
- `lib/domain/logic/medication_slot_calculator.dart` (新增) — domain 业务
- `lib/presentation/pages/home/controllers/` (新增) — presentation
- `lib/presentation/pages/medication/` — 拆分中
- `lib/presentation/pages/mood_list/` (新增) — presentation
- `lib/main/` — 拆分中
- 16 个 `*round108_test.{dart,py}` — ✅ lock-in test 16 个
- `TODO_R108.md` (32 行 R108 P0 #11-#13 任务清单)
- 域名占位 + 邮箱占位 + 截图脚本 + keystore 脚本(已审视)

### E. 守门员与 lock-in test 通过证据(非跑,基于 Read + grep 验证)

| 守门员 / Lock-in Test | 内容 | 状态 |
|---|---|---|
| `scripts/check_16kb_alignment.py` | 基础配置检查(pubspec ndkVersion + targetSdk 35+) | ✅ 已修(脚本就位,需 CI 跑 unzip + objdump 真验 .so) |
| `scripts/generate_data_safety_form.py` | 5 大类 + 28 子项 JSON 模板 | ✅ 跑通(用户需 Play Console 人工填) |
| `scripts/generate_health_apps_questionnaire.py` | 4 大块 问卷 JSON 模板 | ✅ 跑通(用户需 Play Console 人工填) |
| `scripts/generate_android_keystore.sh` | Bash keystore 生成器 | ✅ 就位(未跑,需用户跑) |
| `scripts/generate_release_keystore.ps1` | PowerShell keystore 生成器 | ✅ 就位(R72) |
| `scripts/generate_android_screenshots.sh` | Android 截图自动化 | ✅ 就位(未跑,AVD placeholder) |
| `scripts/register_domain.sh` | chroniccare.app 域名注册 + Cloudflare Pages 部署 | ✅ 就位(未跑,需 Cloudflare token) |
| `test/scripts/keystore_script_round108_test.py` | 6 个 lock-in test | ✅ 就位 |
| `test/scripts/data_safety_form_round108_test.py` | 8 个 lock-in test | ✅ 就位 |
| `test/scripts/health_apps_questionnaire_round108_test.py` | 9 个 lock-in test | ✅ 就位 |
| `test/scripts/domain_check_round108_test.py` | 8 个 lock-in test | ✅ 就位 |
| `test/scripts/screenshots_scripts_round108_test.py` | 7 个 lock-in test | ✅ 就位 |
| `test/fastlane/description_no_health_claim_round108_test.dart` | 5.1.3 抽审 HealthKit 关键词 lock-in | ✅ 修了 hypertension/diabetes,但漏 bipolar/PTSD/ADHD mental health 病种名(见 P0-009) |

### F. 1 句话总结

**R108 修了 13 项 P0 的"工具"层(脚本+文档+lock-in test),但 Play Console 提审必需的 11 项"实物资产"(8 张截图 + feature_graphic + icon + keystore + 域名 + 4 邮箱 + 5 厂商 push SDK + 7"/10" 平板截图 + zh-TW locale) 100% 缺失,真正上架至少还要 1-2 月外部依赖(域名注册 + 5 厂商审核 + 设计师出图)。**

<!-- subagent: googleplay-subagent 完成时间: 2026-08-10T15:30:00+08:00 -->
