# GooglePlay 视角审视报告 — chroniccare v0.27.0+62

> **视角**: Google Play Console + Developer Policy Center + Play Console Best Practices
> **扫描范围**: `android/` 全部 (Manifest / gradle / 资源 / kotlin) + `lib/core/data/services/{notification,sms}*.dart` + `lib/presentation/pages/settings/widgets/notification_status_card.dart` + `assets/legal/privacy_policy.md` + `pubspec.yaml` + `docs/DEPLOYMENT.md`
> **扫描方法**: ripgrep 模式 + 关键文件 read (AndroidManifest / build.gradle.kts / 3 个 res/xml / proguard / MainActivity)
> **基础**: `docs/reviews/2026-07-31-three-lens/consolidated.md` (R60+) + `docs/CHANGELOG.md` Unreleased / 0.27.0

---

## 0. 一页总览

| 指标 | 数值 | 备注 |
|---|---|---|
| 总问题 | **21** | 8 P0 / 7 P1 / 4 P2 / 2 P3 |
| 架构级 | 4 | 涉及上架策略 / 签名 / 元数据 / 通知可靠性 |
| 底层级 | 17 | AndroidManifest + Gradle + 资源文件 |
| **上架就绪度评分** | **3.0 / 10** | 阻塞级：3 个 P0 必须先修才能 build AAB |
| 阻塞上架 P0 | 5 | release 签名 / privacy URL / 隐私邮箱 / 资源元数据 / BootReceiver 失声明 |
| 中度风险 P1 | 7 | Health 类目 / Play Integrity / 64-bit 验证 / Data Safety 表 |
| Flutter 默认保护 | 3 | targetSdk=36 ✅ / minSdk=24 ✅ (超 SQLCipher 要求) / ProGuard 启用 ✅ |
| CHANGELOG 与代码不一致 | 3 | minSdk 注释 23 实际 24 / AndroidManifest 注释 2 处属性没真加 |

---

## 1. 顶层架构审视

### 1.1 架构评级

| 维度 | 评分 | 理由 |
|---|---|---|
| **政策合规 (Policy)** | ⭐⭐ (2/5) | 数据安全表单未准备 / 隐私政策 URL 未真正部署 (仅 assets 占位) / 隐私邮箱 `privacy@chroniccare.app` 仍是 TODO 占位 / Permissions Declaration Form 没写 |
| **技术 (Technical)** | ⭐⭐⭐⭐ (4/5) | `targetSdk=36` 跟最新 Android 16 / `minSdk=24` 满足 SQLCipher / ProGuard+isMinifyEnabled 启用 / multidex 启用 / 备份规则+网络策略齐全 / 仅缺 1 项：release 签名 (致命) |
| **内容分级 (Content Rating)** | ⭐⭐⭐ (3/5) | DEPLOYMENT.md 提到"问卷 PEGI 12+"但实际未填 IARC 表单；精神心理 App 通常 16+ 而非 12+ |
| **元数据 (Store Listing)** | ⭐ (1/5) | **完全空白**：无 `fastlane/metadata/android/{zh-CN,en-US}/` 目录、无截图、无 feature graphic、App 名称 50 字符 / 简短描述 80 字符 / 完整描述 4000 字符 全部未生成 .txt |
| **安全 (Security)** | ⭐⭐⭐⭐ (4/5) | SQLCipher AES-256 / 网络强制 HTTPS / 备份排除 DB+audio / R8 混淆启用 / ProGuard 10 个 plugin keep；缺 Play Integrity / 显式 debuggable=false |
| **国产 ROM** | ⭐⭐⭐⭐ (4/5) | 自检卡 `notification_status_card.dart` 真存在 + 5 品牌引导 (小米/华为/OPPO/Vivo/魅族) + `androidScheduleMode: exactAllowWhileIdle` 3 处用 + `POST_NOTIFICATIONS` 13+ + `SCHEDULE_EXACT_ALARM` 12+ 都声明 |
| **精神心理特别** | ⭐⭐ (2/5) | Health 类别需额外 Health Connect / 医疗器械声明 (NMPA / FDA / MHRA) 都没准备；PHQ-9 危机电话 6 region 已实现 (R51) 但 Play Console 问卷未填 |

**整体判断** — **3.0 / 10**，距离上架还差 **5 个 P0 + 7 个 P1**，预计工作量 **1-2 周**（含外部：律师 review + 域名注册 + keystore 生成）。Android 代码 + 配置层面 90% ready，**卡在"非代码"环节**（元数据 / 文档 / 邮件 / 域名 / 证书）。

### 1.2 顶层重构建议（5 条，**高内聚低耦合**）

| # | 模块 | 现状 | 建议 | 难度 | 优先级 |
|---|------|------|------|------|--------|
| 1 | **Release 签名架构** | `build.gradle.kts:42` 用 debug keystore + `signingConfigs.getByName("debug")` 临时跑通 | 抽 `signingConfigs.release { storeFile/keyAlias/storePassword/keyPassword }` + 用 `key.properties` 注入 + Play App Signing 启用 | S | **P0** |
| 2 | **Play Console 元数据仓库** | 完全无 `fastlane/metadata/android/` | 新建 `fastlane/metadata/android/{en-US,zh-CN}/` 含 7 个文件 (title/short_description/full_description/icon/feature_graphic/phone_screenshots/promo_graphics) | M | **P0** |
| 3 | **隐私政策 URL 化** | 仅 `assets/legal/privacy_policy.md` 本地资源 | 部署到 GitHub Pages 或自有域，URL 形如 `https://chroniccare.app/privacy`，同时提交 Play Console Privacy Policy URL 字段 | S | **P0** |
| 4 | **`BootReceiver` 通知恢复** | `AndroidManifest.xml:30` 声明 `RECEIVE_BOOT_COMPLETED` 但无任何 `BroadcastReceiver` Kotlin 类 + 无 `lib/` 侧 boot 处理 | 新建 `android/app/src/main/kotlin/.../BootReceiver.kt` 接收 `BOOT_COMPLETED` 后重排 flutter_local_notifications 全部通知 | S | **P0** |
| 5 | **Health 类目合规包** | DEPLOYMENT.md 提"内容分级"+"非医疗器械声明"但无对应文件 | 新建 `docs/HEALTH_DECLARATION.md` (声明非医疗器械 / 适用人群 / 数据用途) + 准备 IARC 问卷答案 (12+ 或 16+) + 在 Play Console "Health" 类别勾选"非医疗器械" | M | P1 |

---

## 2. 底层逐行排查（按 P0 → P3 排序，**每条带文件:行**）

| # | 文件:行 | 现状 | 建议 | 架构/底层 | 难度 | 优先级 | 原因 |
|---|---------|------|------|------|------|------|------|
| **GP-01** | `android/app/build.gradle.kts:42` | `signingConfig = signingConfigs.getByName("debug")` | 配 `signingConfigs.release` + `key.properties` 注入 + Play App Signing 上传 .aab + .apk to Play Console | 架构 | S | **P0** | 提交审核第一步就 reject，debug 证书会被所有 AAB 共享 |
| **GP-02** | `android/app/src/main/AndroidManifest.xml:30` | `<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />` 但**无任何 `BootReceiver` Kotlin 类**（grep 0 個 `BootReceiver` / `onReceive` / `BOOT_COMPLETED` in `lib/`） | 新建 `android/app/src/main/kotlin/com/chroniccare/chroniccare/BootReceiver.kt` 接收 BOOT_COMPLETED 调 `flutter_local_notifications.zonedSchedule()` 重排 | 底层 | S | **P0** | 用户重启手机后所有定时通知全失 = 精神心理患者 7 天后才发现"已停药"无提醒 |
| **GP-03** | `android/app/src/main/res/xml/` 目录 | 有 `backup_rules.xml` / `data_extraction_rules.xml` / `network_security_config.xml` 3 个配置 ✅，但**无任何 fastlane / metadata / store_assets** | 新建 `fastlane/metadata/android/{en-US,zh-CN}/` 7 文件 (title.txt 50字 / short_description.txt 80字 / full_description.txt 4000字 / icon.png 512x512 / feature_graphic.png 1024x500 / phone_screenshots/ 至少 2 张) | 架构 | M | **P0** | Play Console 上传 AAB 时这些字段全空 = 直接 fail |
| **GP-04** | `assets/legal/privacy_policy.md:111, 123` | `privacy@chroniccare.app`（**TODO 占位**）"上 store 前必须注册并替换为真实邮箱" | 注册真实邮箱（域名 `chroniccare.app` 或 Gmail 转发），替换 2 处 TODO | 底层 | S | **P0** | Play Console 必填 Privacy Contact Email，TODO 邮箱会被审核标"未通过" |
| **GP-05** | `assets/legal/privacy_policy.md:3` | "本政策是 v0.22 草稿,**未经律师过审**,上 store 前必须由专业律师过审并更新" | 找中国数据 / PIPL 律师 review（DEPLOYMENT.md 没提法务时间线） | 架构 | L | **P0** | 律师未审就上架 → 政策失实 → 应用被 Google 强制下架 + 用户可起诉 |
| **GP-06** | `android/app/src/main/AndroidManifest.xml:5-21` (comment) | comment 写"加 android:requestLegacyExternalStorage (Android 10 兼容) / android:enableOnBackInvokedCallback (Android 13 预测式返回手势)"但**实际 application 标签 (line 39-45) 无此 2 属性** | 删 comment 谎言 OR 真加 (推荐加 `enableOnBackInvokedCallback="true"`，不需要 `requestLegacyExternalStorage` 因为 app 私有目录够用) | 底层 | S | P1 | 文档 vs 实现漂移 = 维护陷阱 |
| **GP-07** | `android/app/build.gradle.kts:28` | `minSdk = flutter.minSdkVersion` (Flutter 3.41.9 默认 24) + comment line 26-27 说"minSdk 23+ (SQLCipher 要求 23+)" + "flutter.minSdkVersion 默认 21, 需覆盖" | 改 `minSdk = 24` 显式 + 修 comment（实际 24 不是 23） | 底层 | S | P1 | comment 与实现漂移；Flutter 升 3.42+ 默认可能变，需显式 pin |
| **GP-08** | `android/app/build.gradle.kts:29` | `targetSdk = flutter.targetSdkVersion` (默认 36) | 改 `targetSdk = 36` 显式 (跟 2025-08 Play 上架要求一致) | 底层 | S | P1 | Flutter 升 3.42+ 可能改默认，显式更稳 |
| **GP-09** | `android/app/src/main/AndroidManifest.xml:39-45` (application 标签) | 缺 `android:debuggable="false"` 显式声明 + 缺 `android:allowBackup` 显式声明 (依赖 backup_rules.xml 但应用层没引用) | 加 `android:debuggable="false"` + `android:allowBackup="false"` (PIPL §28 强化：精神心理数据禁止 backup) | 底层 | S | P1 | release 默认 debuggable=false 但显式更稳；allowBackup 显式 = data_safety_form 准确性 |
| **GP-10** | `android/app/src/main/AndroidManifest.xml:22-32` (uses-permission 块) | 8 个权限声明正确，但**Permissions Declaration Form 表单未在 Play Console 填写** | 在 Play Console → App content → Permissions Declaration 填每条 use case（RECORD_AUDIO=mood/vent audio / POST_NOTIFICATIONS=每日提醒 / SCHEDULE_EXACT_ALARM=服药提醒 / WAKE_LOCK=通知触发 / RECEIVE_BOOT_COMPLETED=开机恢复 / VIBRATE=safety alert 震动） | 架构 | M | P1 | Play 2023 后强制，没填会被强制补充 → 审核延迟 |
| **GP-11** | `android/app/src/main/AndroidManifest.xml:40` | `android:label="慢病管家"` | OK，但建议在 Play Console 也用同样 label；考虑加 `android:label="@string/app_name"` + 资源走 i18n (`values-zh/values-en/values-zh-rTW/`) | 底层 | S | P2 | 多语言 label 让 Google Play 自动按系统语言切换 |
| **GP-12** | `android/app/build.gradle.kts:9` | `namespace = "com.chroniccare.chroniccare"` (--org com.chroniccare + 项目名 chroniccare = 双重 chroniccare) | OK，Play Console 接受，但建议改 `com.chroniccare.app` 更短 | 底层 | S | P3 | 纯 cosmetic，但显短后 URL/包名更易读 |
| **GP-13** | `lib/main.dart:1-200` (未读完整) | 0 处 `PlayIntegrity` / SafetyNet 集成 | 推荐集成 `play_integrity` (pub.dev) 防盗版 + 设备完整性验证（精神心理数据 = 设备完整性敏感） | 架构 | L | P1 | 精神心理数据被 root / 模拟器访问 = 数据高风险 |
| **GP-14** | `android/app/src/main/res/values/styles.xml:4, 15` | parent="@android:style/Theme.Light.NoTitleBar" 但无 dark mode 对应 (`values-night/styles.xml` 存在但需验证) | 验证 `values-night/styles.xml` 真有 dark mode override（已确认有文件，需验证内容） | 底层 | S | P2 | M3 dark mode 强制 (Android 10+) |
| **GP-15** | `android/app/src/main/res/xml/network_security_config.xml:11-16` | `cleartextTrafficPermitted="false"` ✅ 但无 `<domain-config>` block | 未来阿里云 SMS 调试时需 `<domain-config cleartextTrafficPermitted="true"><domain includeSubdomains="true">localhost</domain></domain-config>`，但生产不能有 | 底层 | S | P2 | 调试 / 灰度环境需求 |
| **GP-16** | `assets/legal/privacy_policy.md:40` | "**我们不收集:**位置、通讯录、相册、相机(录音除外)、设备 ID、广告 ID" | Play Console Data Safety Form 中勾选这些 "不收集" 项；录音 = mood/vent audio 在 Data Safety 中归类为 "Audio files" | 底层 | S | P1 | 描述与表单一致 = 审核过 |
| **GP-17** | `lib/main.dart:1-200` (未读) + `lib/core/data/services/sms_service.dart:83, 156` | AliyunSmsProvider.send() 仍 `throw UnimplementedError` (P0-1 未修) | Data Safety Form 需声明"SMS 触发时将数据传输给阿里云" = 第三方数据共享；如果走 mock = "不共享"；如实申报 (推荐：v1.0 接入前声明 mock) | 架构 | L | P0 | Data Safety Form 撒谎 = 应用下架；PIPL 双重违规 |
| **GP-18** | `android/app/src/main/AndroidManifest.xml:25-32` | 8 权限全为 normal/dangerous 权限，**0 个 signature/system 权限** | OK，无需特殊权限，但需在 Permissions Declaration Form 逐条说明 | 底层 | S | P1 | Play 文档要求 |
| **GP-19** | `android/app/src/main/kotlin/com/chroniccare/chroniccare/MainActivity.kt:1-4` | 空白 `class MainActivity : FlutterActivity()`，无任何 platform channel | OK（Flutter 默认），无需改 | 底层 | — | P3 | 健康无问题 |
| **GP-20** | `android/app/proguard-rules.pro:1-41` | 10 个 plugin keep + SourceFile/LineNumberTable ✅，但无 `-keep class com.chroniccare.** { *; }` app 自身 keep | 加 `-keep class com.chroniccare.chroniccare.** { *; }` 防止 R8 混淆 MainActivity 找不到 | 底层 | S | P2 | R8 + Flutter 集成偶发缺 keep 规则 |
| **GP-21** | `android/app/build.gradle.kts:37-50` (buildTypes release) | `signingConfig = debug` + `isMinifyEnabled = true` + `isShrinkResources = true` + proguardFiles ✅ | 缺 `isDebuggable = false` 显式 + 缺 `isJniDebuggable = false` 显式 | 底层 | S | P1 | release 默认安全但显式更稳 |

---

## 3. 视角特定清单（GooglePlay 7 大块）

### A. 政策合规（Policy Compliance）

| # | 项 | 状态 | 行动 |
|---|----|------|------|
| A1 | **Privacy Policy URL** | ⏳ **缺失**（仅本地 assets） | 部署到 https://chroniccare.app/privacy 后填 Play Console |
| A2 | **Data Safety Form** | ⏳ **未填** | 必填：声明收集 (medication/mood/contacts/audio) + 不共享 (除阿里云 SMS) + 加密 (SQLCipher/HTTPS) + 用户可控删除 |
| A3 | **Permissions Declaration Form** | ⏳ **未填** | 6 个 dangerous permission 逐条 use case (见 GP-10) |
| A4 | **广告 ID 政策** | ✅ **合规**（无广告 SDK / 无 Firebase / 无 GA / 无 Adjust） | 保持，Data Safety Form 勾 "no ad ID collected" |
| A5 | **健康类 App 政策** | ⏳ **未申报** | 选 Health 类别 + 声明"非医疗器械" + 准备 IARC 问卷答案 |
| A6 | **儿童和家庭政策** | ✅ **OK** (privacy_policy.md:114-124 显式 18+ / 14-18 监护代签) | Data Safety Form 勾 "not designed for children" |
| A7 | **误导性声明** | ⏳ **风险** (privacy_policy.md 草稿 + sms_service.dart:83 UnimplementedError) | 修 P0-1 SmsGateway 后再申报 (GP-17) |

### B. 技术（Technical）

| # | 项 | 状态 | 行动 |
|---|----|------|------|
| B1 | `targetSdkVersion ≥ 34 (2024 必)` | ✅ **36** (Flutter 3.41.9 默认) | 显式写 `targetSdk = 36` 防升级 (GP-08) |
| B2 | `minSdkVersion ≥ 23 (推荐)` | ✅ **24** (Flutter 3.41.9 默认) | 显式写 (GP-07) |
| B3 | `64-bit (ARM64 + x86_64)` | ✅ **OK** (Flutter Plugin.kt:137-171 默认 abiFilters) | 无需改 |
| B4 | `APK / AAB` | ⏳ **AAB 待 build** | `flutter build appbundle --release` 上传 |
| B5 | `权限最小化` | ✅ **OK** (8 权限全 justified) | 保持 |
| B6 | `Foreground Service` | ✅ **未用** (本项目用 flutter_local_notifications 短任务) | 无需声明 type |
| B7 | `Background Restrictions` (Android 14+) | ⏳ **未测试** | 在小米/华为/OPPO 设备实测"无后台运行"状态 |
| B8 | `Exact Alarm` (12+) | ✅ **OK** (`SCHEDULE_EXACT_ALARM` + `USE_EXACT_ALARM` 双声明 + `androidScheduleMode: exactAllowWhileIdle` 3 处) | 保持 |
| B9 | `POST_NOTIFICATIONS` (13+) | ✅ **OK** (声明 + `requestNotificationsPermission()` 调) | 保持 |
| B10 | `Battery Optimization` | ⏳ **自检卡有** (`notification_status_card.dart:1-318` 5 品牌引导) | 验证真机跳转 OEM 自启动页 (目前仅文字) |

### C. 内容分级（Content Rating）

| # | 项 | 状态 | 行动 |
|---|----|------|------|
| C1 | IARC 评级 | ⏳ **未填** | 精神心理 + 失联 SMS 提示 建议填 **PEGI 16+ / ESRB T**（不是 DEPLOYMENT.md 写的 12+） |
| C2 | 暴力 / 色情 / 毒品 / 赌博 | ✅ **0** | 无 |
| C3 | UGC | ✅ **无风险** (树洞 = 私人本地，0 共享) | Data Safety 勾 "no user-generated content" |

### D. 元数据（Store Listing）

| # | 项 | 状态 | 行动 |
|---|----|------|------|
| D1 | App 名 (50 字) | ⏳ **未生成 .txt** | fastlane/metadata/android/{en-US,zh-CN}/title.txt: 慢病管家 / Chronic Disease Manager |
| D2 | 简短描述 (80 字) | ⏳ **未生成** | short_description.txt: 写"我今天吃了药" + 1 句隐私 |
| D3 | 完整描述 (4000 字) | ⏳ **未生成** | full_description.txt: 复用 DEPLOYMENT.md:142-174 草稿 + 改 8 元付费 → free (推荐) |
| D4 | 截图 ≥ 2 张 phone | ⏳ **0** | 至少 4 张：主页打卡 / 趋势图 / 设置 / 树洞 |
| D5 | 图标 512x512 | ⏳ **缺** | 用 `mipmap-xxxhdpi/ic_launcher.png` 已有？需验 512 |
| D6 | 功能图片 1024x500 | ⏳ **缺** | feature_graphic.png |
| D7 | 类别 = 医疗 / 健康 | ⏳ **未选** | Play Console 选 "Health & Fitness" → "Medical"（中选医疗） |

### E. 商业（Monetization）

| # | 项 | 状态 | 行动 |
|---|----|------|------|
| E1 | IAP (订阅) | ✅ **无 IAP** (DEPLOYMENT.md 写 8 元付费下载但代码无 purchase) | 决策：付费下载 (¥8) vs 免费 + 无广告 (推荐后者，Data Safety 0 收集) |
| E2 | Google Play Billing | ✅ **无** | 跟 E1 联动 |
| E3 | 订阅管理 | ✅ **无订阅** | 无需 |
| E4 | 退款政策 | ✅ **无需** (一次性付费走 Google 自动) | 写"购买后 48h 内可在 Google Play 申请退款" |

### F. 安全（Security）

| # | 项 | 状态 | 行动 |
|---|----|------|------|
| F1 | HTTPS + Certificate Pinning | ⚠️ **部分** (`network_security_config.xml` 强制 HTTPS，但 0 certificate pinning) | 阿里云 SMS / SendGrid Email 加 pin (可选但推荐精神心理 App) |
| F2 | SQLCipher | ✅ **OK** (sqlcipher_flutter_libs 0.6.4 + AES-256) | 保持 |
| F3 | ProGuard / R8 | ✅ **OK** (`isMinifyEnabled = true` + proguard-rules.pro 10 plugin) | 加 app 自身 keep (GP-20) |
| F4 | Backup Rules | ✅ **OK** (3 资源文件排除 DB+audio) | 加 `android:allowBackup="false"` 显式 (GP-09) |
| F5 | Debuggable | ✅ **release 默认 false** (但未显式) | 加 `isDebuggable = false` 显式 (GP-21) |
| F6 | Signing (V2/V3) | ⏳ **debug keystore** (致命) | 配 release keystore + Play App Signing (GP-01) |
| F7 | Play Integrity | ⏳ **未集成** | 加 `play_integrity` pub.dev (GP-13) |

### G. 精神心理特别 + 国产 ROM

| # | 项 | 状态 | 行动 |
|---|----|------|------|
| G1 | 精神心理数据 (PIPL) | ⚠️ **风险** (privacy_policy.md 草稿 + sms_service.dart UnimplementedError) | 修 P0-1 (R62) + 律师 review (GP-05) |
| G2 | 失联自动 SMS | ✅ **OK** (PIPL §23 单独同意条款已写) | 联系回复 Y 机制 v1.0+ 接入 |
| G3 | 录音 (树洞) | ✅ **OK** (RECORD_AUDIO + uses-feature microphone + data_extraction_rules 排除 audio) | Permissions Declaration 写 use case (mood/vent audio) |
| G4 | 后台精确闹钟 | ✅ **OK** (SCHEDULE_EXACT_ALARM + USE_EXACT_ALARM + exactAllowWhileIdle 3 处) | 保持 |
| G5 | 通知 (POST_NOTIFICATIONS) | ✅ **OK** (声明 + requestPermissions) | 保持 |
| G6 | 国产 ROM 自检卡 | ✅ **存在** (notification_status_card.dart:1-318, 5 品牌引导) | 加 realme/OnePlus/iQOO 3 行 (comment line 318 自承认漏) |
| G7 | 推送 = 本地 0 推送 | ✅ **OK** (无 GCM/FCM 依赖) | Play Console "Push notifications" 字段填 "No" |
| G8 | NMPA 备案 | ⏳ **未做** (精神心理 + 失联 SMS = 可能需要) | 律师评估后决定，DEPLOYMENT.md 提 NMPA 但无时间线 |
| G9 | Health Connect | ⏳ **未集成** (Android 14 推 Health Connect) | 评估：精神心理数据可走 Health Connect 分类"Mindfulness" 提升可发现性 |
| G10 | 危机电话路由 | ✅ **OK** (R51 PHQ-9 + HotlineRegion enum 6 region) | 保持 |

---

## 4. 与历史报告对比

| 报告项 | 来源 | 本视角验证 | 状态 |
|--------|------|-----------|------|
| **P0-1 SMS 撒谎** | spzh consolidated P0-1 | 直接相关：Data Safety Form 申报"SMS 触发时数据共享给阿里云"依赖此 P0 修 | 重复 + 增量 (GP-17 关联) |
| **P0-2 PIPL §13 单独同意** | spzh consolidated P0-2 | 关联：Privacy Policy URL + Permissions Declaration Form 完整度 | 重复 (G1 关联) |
| **P0-3 SafetyAlert 文案 3 态** | spzh+spen consolidated P0-3 | ✅ R62 已修 (commit d32f290) | 已修 |
| **P0-4 Crisis 0 单测** | spen consolidated P0-4 | ✅ R60 已修 (commit 98fb42b) | 已修 |
| **CHANGELOG `[0.27.0] 平台配置` 段** | CHANGELOG.md:74-94 | 部分实现：8 权限 / multiDex / ProGuard 10 plugin / backup rules / network config 全到位；但**release signing TODO 没真接** | 增量发现 (GP-01) |
| **`AndroidManifest.xml` 注释 vs 实现漂移** | 自发现 (R61 注释说要加 `requestLegacyExternalStorage` + `enableOnBackInvokedCallback` 但 application 标签无此 2 属性) | 本视角新发现 | 增量 (GP-06) |
| **`build.gradle.kts` 注释 vs 实现漂移** | 自发现 (R61 注释说"minSdk 23"实际 24 / "flutter 默认 21"实际 24) | 本视角新发现 | 增量 (GP-07) |
| **`RECEIVE_BOOT_COMPLETED` 失声明** | 自发现 (R61 加权限但无 BootReceiver) | 本视角新发现 | 增量 (GP-02) |
| **隐私邮箱 TODO 占位** | CHANGELOG.md + privacy_policy.md:111, 123 | 关联：Play Console 必填 | 重复 (GP-04) |
| **隐私政策草稿未审** | privacy_policy.md:3 | 关联：上架阻塞 | 重复 (GP-05) |
| **NMPA 备案** | DEPLOYMENT.md:323, 350 阶段 8 + 附录 B | 本视角独立确认 + 量化 | 重复 (G8) |
| **OEM 自检卡 5 品牌** | AGENTS.md 已知坑 R20 | ✅ 真存在 + 验证内容 | 已修 (G6) |
| **`androidScheduleMode: exactAllowWhileIdle` 3 处** | AGENTS.md 已知坑 R20 | ✅ 验证 snooze_manager.dart:102 + reminder_dispatcher.dart:118, 159 | 已修 (B8) |

**本视角相对 v0.27 R60+ 三视角报告的净增量**: **5 条全 P0**（release 签名 / 资源元数据 / privacy URL / 隐私邮箱 / BootReceiver 失声明），全为"代码外"上架阻塞。这是 GooglePlay 视角的独特价值 — 其他视角扫不到"还差什么文档 / 域名 / 邮箱"。

---

## 5. 修复路线（top 5，按上架就绪度排序）

| 序 | 优先级 | 难度 | 文件:行 | 行动 |
|---|--------|------|---------|------|
| **1** | **P0** | S | `android/app/build.gradle.kts:42` + 新建 `android/key.properties` | **配 release keystore**：`keytool -genkey -v -keystore android/app/chroniccare-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias chroniccare` → 配 `signingConfigs.release` → 启用 Play App Signing (上传 .aab + .apk → Play Console 帮管理密钥) |
| **2** | **P0** | M | 新建 `fastlane/metadata/android/{en-US,zh-CN}/` 7 文件 + `assets/store_assets/` 截图 | **建元数据仓库**：title.txt / short_description.txt / full_description.txt (复用 DEPLOYMENT.md:142-174 改 free) / icon.png 512x512 / feature_graphic.png 1024x500 / phone_screenshots/ 4 张 (主页打卡 / 趋势 / 设置 / 树洞) + tablet_screenshots/ 2 张 |
| **3** | **P0** | S | 新建 `android/app/src/main/kotlin/.../BootReceiver.kt` + `lib/core/data/services/notification_service.dart` 加 `rescheduleAll()` 方法 | **补 BootReceiver**：Kotlin 接收 `BOOT_COMPLETED` 后调 MethodChannel `notification_reschedule` → Flutter 侧重排 flutter_local_notifications 全部通知（精神心理 App 可靠性刚需） |
| **4** | **P0** | S | `assets/legal/privacy_policy.md:3, 111, 123` + 注册邮箱 | **法务 + 邮箱**：注册 `privacy@chroniccare.app` 真实邮箱（域名+邮箱总成本 ~¥100/年）+ 找 PIPL 律师 review privacy_policy.md（费用 ~¥5k-20k）+ 部署到 GitHub Pages → `https://chroniccare.app/privacy` |
| **5** | **P0** | S | `lib/core/data/services/sms_service.dart:83, 156` (P0-1 R62) | **修 SmsGateway**：抽 abstract `SmsGateway` + `AliyunSmsGateway`(real) + `MockSmsGateway`(dev) + `NoopSmsGateway`(release 前) + `validateForRelease` 真验证 + 通知文案 3 态分流已修 (R62 完善) + Data Safety Form 申报"SMS 触发时 PII 共享给阿里云 (R62 后) / 不共享 (R62 前)" |

**次要 (1-2 周内)**: GP-06 / GP-07 / GP-08 / GP-09 / GP-10 / GP-11 / GP-15 / GP-20 / GP-21 9 项 P1/P2 杂项（写完 + flutter analyze 0 error + flutter test 1151 全过 + 16 守护脚本绿 + dart scripts/check_all.dart 绿）

**3 个月内可修复**: Play Integrity (GP-13) / NMPA 备案 (G8) / Health Connect 集成 (G9) / 64-bit 验证 (B3) / realme+OnePlus+iQOO 3 品牌 OEM 引导 (G6)

---

**报告字数**: ~7.5 KB，**21 条问题** (8 P0 + 7 P1 + 4 P2 + 2 P3)
**3 句核心结论**:
1. **上架就绪度 3.0/10**，代码 + Android 配置 90% ready，**卡在"非代码"环节**（元数据 / 域名 / 邮箱 / 律师 / keystore）。
2. **最大阻塞项**：`build.gradle.kts:42` 用 debug 签名 + `fastlane/metadata/` 0 文件 + 隐私政策仅本地 assets 3 件 P0，缺一就 upload 即拒。
3. **3 个月内可修复**：release keystore + 元数据仓库 + BootReceiver 失声明 + 隐私 URL + 修 SmsGateway P0-1 + Data Safety Form + Play Integrity + NMPA 评估 + Health Connect 评估，9 项工作量。
