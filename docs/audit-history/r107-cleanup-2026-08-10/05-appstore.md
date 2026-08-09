# Apple App Store 上架就绪度审计

> 审计时间：2026-08-10
> 项目版本：v0.30.0+85 (round 104-105 之后)
> 审计员视角：Apple App Store Review Guidelines + HIG + Privacy Manifest + Required Reason API
> 参考基线：R104/R105 自评 6.0/10

---

## 0. 评分

| 维度 | 评分 | 说明 |
|---|---|---|
| **整体上架就绪度** | **4.5 / 10** | 较 R105 6.0 退步 1.5 分。v0.30 R100 删除 UIBackgroundModes + R105 启用 vent audio 但未加回 audio background mode + 3 个 P0 阻断项未修 |
| **代码 / 文档就绪** | 7.5 / 10 | 5 步 setup consent 流程、Privacy Manifest 6 类、Export Compliance、InfoPlist.strings per-locale、ITSAppUsesNonExemptEncryption 等都齐 |
| **资源 / Metadata 就绪** | 1.5 / 10 | 截图 0 张、review_information 缺失、AppIcon 10.7KB 占位、LaunchImage 68B 占位、subtitle / keywords 凑数、support URL 不可达 |
| **合规 / 法律就绪** | 7.0 / 10 | 隐私政策 + 用户协议 + 敏感数据 + 医学免责 4 份 MD 都过律师审 + 5 步 setup 流程 + ConsentGate 业务层真接 |
| **iOS HIG / Accessibility** | 3.5 / 10 | Dynamic Type 0 适配（28 处 fontSize 硬编码）、VoiceOver 弱（18 处 Semantics）、Dark Mode 有但未全审、Lock Screen PII 泄漏 |
| **Privacy / Data Safety** | 4.0 / 10 | PrivacyInfo.xcprivacy 6 类已填但漏 Sensitive Info + ProcessInfo + 缺 NSPrivacyAccessedAPICategoryActiveKeyboard 防御声明、缺 iCloud Backup 排除、通知 body 药名 PII 泄漏 |

**总评：4.5 / 10 — 不建议直接上传**，至少需要 1 个 P0 sprint + 1 个 P1 sprint 才能进入"可提交"状态。

---

## 1. 七大块逐一评估

### 1.1 App Completeness (Guideline 2.1) — **3/10**

| 项 | 状态 | 详情 |
|---|---|---|
| 功能完备 | ✅ | 打卡 / 用药 / 情绪 / 评估 / 树洞 / 录音（已启用）5 大模块代码全在，1997+ tests pass |
| 截图 | ❌ | `fastlane/screenshots/**` 不存在；ASC 必填 6.7" + 6.1" + 5.5" + iPad 各尺寸 |
| App 描述 vs 实际一致 | ⚠️ | en/zh-Hans/zh-Hant description.txt 都提到 vent + mood audio（已启用 ✓）；但 IAP "8 元买断" 在 R100 后已暂停，文案却保留 |
| 视频预览 | ❌ | 0 个 video preview |
| 紧急 BUG / 占位 | ⚠️ | 业务暂停 5 项用 FeatureFlag 守护 + UI hidden（合规） |

**R105 6.0 评估的"功能完备"是满分，但"截图 / 视频 / 描述一致性"是 0 分。** 

### 1.2 Metadata (Guideline 2.3) — **4/10**

8 项 metadata 已全部填充（3 locale × 8 = 24 文件都到位）：

| 项 | en-US | zh-Hans | zh-Hant | 备注 |
|---|---|---|---|---|
| name.txt | ChronicCare | 慢病管家 | 慢病管家 ✓ | per-locale 通过 InfoPlist.strings 覆盖 |
| subtitle.txt | Medication + Mood Tracker | 吃药打卡 + 情绪关怀 | 吃藥打卡 + 情緒關懷 ✓ | 30 chars 内 ✓ |
| description.txt | 2274B ✓ | 1757B ✓ | 1698B ✓ | 3 文案都符合 4000 chars 上限 |
| keywords.txt | medication,reminder,mood,... (55B) | 吃药,提醒,... (49B) | 吃藥,提醒,... (49B) ⚠️ | **en 7 词 / zh 7 词，接近 100 字符上限**，未充分利用 |
| promotional_text.txt | 137B ✓ | 129B ✓ | 129B ✓ | 170 字符内 |
| privacy_url.txt | chroniccare.app/privacy ⚠️ | 同 ⚠️ | 同 ⚠️ | **域名未注册 → Apple 审核点 URL 必失败** |
| support_url.txt | chroniccare.app/support ⚠️ | 同 ⚠️ | 同 ⚠️ | **同上** |
| copyright.txt | © 2026 chroniccare ⚠️ | 同 | 同 | 缺 © + 主体全名 + 年份 |

| 缺失项 | 影响 |
|---|---|
| `fastlane/metadata/ios/review_information/` | **目录不存在**。需含：first_name / last_name / email_address / phone_number / demo_user / demo_password / notes。Apple 上传表单硬阻塞 |
| `fastlane/metadata/ios/{locale}/` 内 Apple 分类 / 隐私勾选 | ASC 后台手填 13 大类需逐一勾 |
| `fastlane/metadata/ios/{locale}/apple_tv_privacy_policy` 等 | 不适用本项目 |

### 1.3 Software Requirements (Guideline 2.5) — **3.5/10**

| 项 | 状态 | 详情 |
|---|---|---|
| Dynamic Type (HIG § Accessibility) | ❌ | `grep "MediaQuery.textScaler\|textScaleFactor"` → 0 处使用。`fontSize: \d+` 硬编码 28 处（10 文件）。Apple HIG 强制支持，禁用 = 拒 |
| VoiceOver / Semantics | ⚠️ | `Semantics()` / `semanticsLabel` 18 处使用（9 文件），但 `app_semantics.dart` 5 处是集中封装，UI 中 emoji / 装饰性 icon 多未 excludeSemantics |
| Dark Mode | ✅ | `AppTheme.dark()` 已就位，themeMode 用户可切换 |
| 设备适配 | ⚠️ | iPhone 16 Pro Max 6.9" / iPad Pro 13" 适配证据缺失（无截图），`UIRequiresFullScreen=false` 已开 |
| iPad 多任务 | ✅ | 已开 Split View |
| Scene 启动 | ✅ | UISceneStoryboardFile=Main + SceneDelegate.swift 已就位 |
| 启动图 | ❌ | `LaunchImage.png` / `@2x.png` / `@3x.png` 全部 68 字节空白占位 |
| AppIcon | ⚠️ | `Icon-App-1024x1024@1x.png` 仅 10932 字节（10.7 KB），但 `assets/brand/app_icon_master.png` 有 435870 字节真实设计——**未移植到 iOS AppIcon.appiconset** |
| 高刷屏 (120Hz) | ✅ | CADisableMinimumFrameDurationOnPhone=true 已设 |
| Export Compliance | ✅ | ITSAppUsesNonExemptEncryption=false（标准库加密）✓ |
| Scene 多窗口 | ✅ | UIApplicationSupportsMultipleScenes=true |
| 设备方向 | ✅ | iPhone 3 方向 / iPad 4 方向 |

**R105 6.0 → 4.5 退步的关键原因**：R100 删除 UIBackgroundModes audio + R104 ventAudioEnabled=true 启用录音 = **声明跟实际不一致**（Apple 2.5.4 拒因 "declared capability not used" 跟 "used capability not declared" 双面拒）。

### 1.4 Privacy (Guideline 5.1.1) — **6.5/10**

| 项 | 状态 | 详情 |
|---|---|---|
| 隐私政策 URL | ⚠️ | chroniccare.app/privacy 域名未注册 → Apple 审核员点开 404 = 拒 |
| Data Not Collected 声明 | ✅ | 业务真暂停后所有数据 100% 本地，零云端声明 + Privacy Manifest 已填 4 类 collected data types |
| 第三方 SDK 披露 | ✅ | privacy_policy.md §7 列出 22 个 SDK 全部无 PII 收集 + in_app_purchase 真实披露 |
| 5 步 consent 流程 | ✅ | setup 5 步：consent / welcome / medication / done；consent 内 5 个勾选（用户协议 / 隐私政策 / 敏感数据 / 年龄严正声明 / 医学免责）|
| PIPL §14 撤回同意 | ✅ | R67 ConsentGate 业务层真接（vent / safety / analytics 3 项撤回后业务立即停）|
| PIPL §13/§23 单独同意 | ⚠️ | 紧急联系人业务暂停中，预存储 OK 但**未真接"单独告知第三方"流程** → 业务真接时 P0 |
| Children (1.4.3) | ✅ | setup 加年龄严正声明 + 隐私政策 §10 措辞 + 14-18 监护人代签 |
| 通知 body 脱敏 | ❌ | `strings.dart:107` notifMedicationTitle = `💊 该吃药了：$medName` 药名明文 PII；`strings.dart:108-110` body 含 `med.dosage / med.dosageUnit` 剂量明文；iOS 锁屏默认 `presentAlert=true` → **PII 锁屏泄漏** |
| iCloud Backup 排除 | ❌ | `grep isExcludedFromBackup` lib/ 0 处使用 → **SQLite 默认随 iCloud 自动备份** → 精神心理患者数据上传 Apple iCloud 是严重 PII 泄漏 |

### 1.5 Privacy Manifest (强制 2024-05) — **7.5/10**

`ios/Runner/PrivacyInfo.xcprivacy` 现状：

| 字段 | 状态 | 详情 |
|---|---|---|
| NSPrivacyTracking | ✅ | false（无 IDFA）|
| NSPrivacyTrackingDomains | ✅ | 空 array |
| NSPrivacyCollectedDataTypes | ⚠️ | 填 4 类：HealthAndFitness / AudioData / ContactInfo / UserContent<br>**缺 NSPrivacyCollectedDataTypeSensitiveInfo**（PHQ-9 / GAD-7 评估答案属敏感）<br>4 类用途全 `PurposeAppFunctionality` ✓ |
| NSPrivacyAccessedAPITypes | ⚠️ | 填 5 类：UserDefaults (CA92.1+CA92.2) / FileTimestamp (C617.1) / SystemBootTime (35F9.1) / DiskSpace (85F4.1) / ProcessInfo (AC67.1)<br>**缺 NSPrivacyAccessedAPICategoryActiveKeyboard** 防御性声明（即便项目无自定义键盘，TextField 焦点切换会触发 UIKit 内部 keyboard event API）<br>**缺 NSPrivacyAccessedAPICategoryFileTimestamp 的 C617.2**（多 app 共享场景） |

| 关键问题 | 详情 |
|---|---|
| **PrivacyInfo.xcprivacy 未注册到 Xcode project** | `ios/Runner.xcodeproj/project.pbxproj` 第 223-232 行的 `97C146EC1CF9000F007C117D /* Resources */` buildPhase 只注册 4 个文件（LaunchScreen.storyboard / AppFrameworkInfo.plist / Assets.xcassets / Main.storyboard），**缺 PrivacyInfo.xcprivacy** → xcodebuild 不会复制到 .app bundle → 审核员看不到 manifest = 拒 |

### 1.6 Health & Health Research (Guideline 5.1.3) — **N/A 8/10**

| 项 | 状态 | 详情 |
|---|---|---|
| HealthKit entitlement | ✅ | Runner.entitlements 完全空（连 aps-environment 都删了 R70）→ **无 HealthKit 接入** ✓ |
| 临床健康记录 | ✅ | 无 HealthKit Clinical Health Records 接入 ✓ |
| 描述暗示医疗监测 | ✅ | description.txt + medical_disclaimer.md 都明确"非医疗器械，未经 FDA / NMPA 审批" |
| 类别 | ✅ | LSApplicationCategoryType=healthcare-fitness 已设 |
| 医学免责声明 | ✅ | setup 第 5 勾选 + store description "IMPORTANT" 段 + 4 文档集中 |

**项目自定位"个人追踪工具而非医疗设备"清晰，跟 Apple Health 类别合规**。但 App Store Connect 后台 Primary Category 选 Health & Fitness → Medical / Treatment Information 会触发 **ASC 问卷**（Health Information Disclosure Questionnaire），需手填"无 HealthKit 接入 / 无任何医疗决策"。

### 1.7 Safety (Guideline 1.x) — **7.5/10**

| 子项 | 状态 | 详情 |
|---|---|---|
| 1.4.1 Medical | ✅ | 5 步 consent + medical_disclaimer.md + 描述自定位非医疗 |
| 1.4.3 Kids | ✅ | 4 文档 + setup 流程 + 14-18 监护代签 |
| 1.4.4 Physical Harm | ⚠️ | 精神心理类属"敏感人群" — 危机资源链接全（6 区域热线 + 国际 findahelpline.com）✓；R97 加 url_launcher 一键拨打 tel: intent ✓ |
| 1.4.5 Developer Info | ✅ | copyright.txt / privacy URL / support URL 都填（即便 URL 不可达）|

---

## 2. 问题清单（按 P0-P3 + 难度 + 预计工时）

| # | 文件:行 | 问题 | 类别 | 难度 | 优先级 | 修复 + 预计工时 |
|---|---|---|---|---|---|---|
| 1 | `ios/Runner.xcodeproj/project.pbxproj:223-232` | **PrivacyInfo.xcprivacy 未注册到 Resources buildPhase** → xcodebuild 不打包 → 审核拒 | Manifest | 简单 | **P0** | Xcode GUI 加 file ref + Resources 阶段勾，PBXFileReference + PBXBuildFile 2 处 edit，15 min |
| 2 | `lib/core/data/database/connection/native.dart:17-19` | **SQLite DB 默认随 iCloud Backup** → 精神心理患者 PII 上 Apple iCloud | Privacy | 中 | **P0** | `getApplicationDocumentsDirectory()` 后调 `setResourceValue(NSURLIsExcludedFromBackupKey)` + iOS 端 `setResourceValues`；纯 Dart 端需写 MethodChannel 或用 path_provider 提供的 appSupportDir + iOS bridge。3h |
| 3 | `lib/core/l10n/strings.dart:103-110` + `medication_notifier.dart:134-135` | **通知 title / body 药名 + 剂量 PII 明文** → 锁屏泄漏 | Privacy | 中 | **P0** | (a) iOS 端加 `visibility: NotificationVisibility.private` 让锁屏只显示"提醒"标题；(b) title 改抽象"该吃药了" / body 改"点开查看详情"。1h |
| 4 | `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage*.png` | **3 个启动图 68 字节空白** → 启动 1-2 秒白屏 / 蓝屏 | Software | 简单 | **P0** | 从 `assets/brand/app_icon_master.png` 生成 3 张 1024×1024 / 2048×2048 / 3072×3072 真实 LaunchImage；或删 LaunchImage 走 iOS 13+ default image。1h |
| 5 | `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` | **AppIcon 1024×1024 10932 字节 = 占位** | Software | 简单 | **P0** | 把 `assets/brand/app_icon_master.png` (435870 字节) 复制 + 重命名为 1024×1024 单 PNG（不能有 alpha 通道否则 App Store 拒）。30 min |
| 6 | `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/privacy_url.txt` + `support_url.txt` | **chroniccare.app 域名未注册** → Apple 审核员点开 404 = 拒 | Metadata | 简单 | **P0** | 注册 chroniccare.app（Godaddy / Namecheap / Cloudflare Registrar，约 $10/年） + GitHub Pages / Cloudflare Pages 部署 4 文档 + privacy URL / support URL 落地页。4h |
| 7 | `fastlane/metadata/ios/review_information/` | **目录不存在**（ASC 上传表单硬阻塞）| Metadata | 简单 | **P0** | 创建 review_information/first_name.txt + last_name.txt + email_address.txt + phone_number.txt + demo_user.txt + demo_password.txt + notes.txt。30 min |
| 8 | `ios/Runner/Info.plist:153-160` 注释 | **R100 删 UIBackgroundModes audio + R104 ventAudioEnabled=true 启用录音** → "声明 vs 实际" 矛盾 | Software | 简单 | **P0** | 加回 `UIBackgroundModes=[audio]` (vent 录音需要后台权限，Apple 2.5.4 拒因)。5 min |
| 9 | `ios/Runner/PrivacyInfo.xcprivacy` | **缺 NSPrivacyCollectedDataTypeSensitiveInfo**（PHQ-9 / GAD-7 评估答案属 Apple 模板的 SensitiveInfo）| Manifest | 简单 | **P1** | 加 SensitiveInfo dict (Linked=false, Tracking=false, Purposes=AppFunctionality)。5 min |
| 10 | `ios/Runner/PrivacyInfo.xcprivacy` | **缺 NSPrivacyAccessedAPICategoryActiveKeyboard** 防御性声明 | Manifest | 简单 | **P1** | 加 ActiveKeyboard dict (Reasons=["3ECE.1"])。5 min |
| 11 | `lib/` (28 处) | **fontSize 硬编码 28 处 / 10 文件** → Dynamic Type 0 适配 | Software | 中 | **P1** | 改走 `MediaQuery.textScalerOf(context).scale(baseFontSize)` 或 `Theme.of(context).textTheme.bodyMedium.fontSize`；或加 `TextScaler.linear(MediaQuery.textScalerOf(context).scale(1.0))` 全局 baseline。3h |
| 12 | `lib/presentation/widgets/` 多处 emoji | **装饰性 emoji 缺 excludeSemantics:true** → VoiceOver 朗读 🎉🌱💊 等无意义字符 | Software | 简单 | **P1** | 所有装饰性 emoji 包 `ExcludeSemantics(child: Text('🎉'))`。1h |
| 13 | `fastlane/metadata/ios/*/copyright.txt` | **缺 © + 主体全名** | Metadata | 简单 | **P1** | 改 `© 2026 chroniccare (Shanghai) Health Technology Co., Ltd.` 等。5 min |
| 14 | `fastlane/metadata/ios/*/keywords.txt` | 7 词 / 接近 100 字符上限未充分利用 | Metadata | 简单 | **P1** | en 改 9 词（medication,reminder,mood,depression,anxiety,chronic,pill,habit,tracker）；中文同理。5 min |
| 15 | `lib/presentation/` 整体 | **semanticsLabel 18 处但覆盖率低**（9 文件）| Software | 中 | **P1** | 所有 iconButton / button 包 `Tooltip(message: ...)` 或 `Semantics(label: ...)`；表单输入加 hintSemantics。4h |
| 16 | `lib/presentation/` | **iPhone 16 Pro Max 6.9" 适配证据缺失**（无截图）| Software | 中 | **P1** | 用 Simulator 跑 6.9" + 截图 + 修 layout；或加 `MediaQuery.sizeOf(context).width > 430` 走双栏布局。2h |
| 17 | `assets/` | **fastlane/screenshots 0 张**（ASC 必填）| Metadata | 中 | **P0** | 5 个核心页（home / medication / mood / assessment / vent）跑 Simulator 截 6.7" + 6.1" + 5.5" + iPad Pro 13" 共 4 设备 × 5 屏 = 20 张 + Apple Design Resources 套壳。3h |
| 18 | `ios/Runner/Info.plist` | **`LSRequiresIPhoneOS=true`** 但 desc 提 "慢性病管家不是医疗工具" → 医疗误导 | Safety | 简单 | **P1** | desc 强调"非医疗工具" + 提交 ASC review notes 主动声明。30 min |
| 19 | `lib/core/data/services/notification_service.dart:142-186` | **`requestAlertPermission/Badge/Sound` 全 false** → 通知静默无 banner 提示 | Software | 中 | **P2** | `requestPermission()` 已存在（R97-P1-6）但 setup 流程配完药后**未调用** → 提醒永远静默。修 setup_page_state.dart 加调用。30 min |
| 20 | `lib/core/data/services/notification_service.dart:200-214` | **`requestPermission` iOS+Android 逻辑"或"** — Android 没授权 + iOS 已授权时返 true | Software | 简单 | **P2** | 改成 `iosOk == true && androidOk != false` (Android 不支持返 null 视作 OK)。5 min |
| 21 | `lib/` (0 处) | **App 不支持 Apple Sign in (无第三方登录) → 不需要** 但有用户协议 | Safety | — | — | N/A |
| 22 | `ios/Runner/PrivacyInfo.xcprivacy` | **5 类全填但未给 R5 (SensitiveInfo) Apple 模板仔细 review** | Manifest | 简单 | **P2** | Apple 官方文档查 "SensitiveInfo collected data type" 字段要求。30 min |
| 23 | `ios/Runner/Info.plist` | **缺 NSCameraUsageDescription**（即便无拍照，PHQ-9 未来可能加图片打分）| Privacy | 简单 | **P2** | 加 NSCameraUsageDescription 描述（即便目前未用，留 Apple 模板项）。5 min |
| 24 | `lib/core/data/services/notification_service.dart:152-158` | **`DarwinInitializationSettings` 全 false** → setup 配完药后用户**不知道需要去系统设置开通知** | Software | 中 | **P2** | setup 流程内显式调 `requestPermission()` + UI 引导"去系统设置"。1h |
| 25 | `ios/Runner/Info.plist` | **缺 ITSAppUsesNonExemptEncryption 详细说明** (export compliance) | Privacy | 简单 | **P2** | 已有 false ✓ — 但需在 ASC review notes 重申"标准库加密,无自定义算法"。5 min |
| 26 | `lib/app.dart:265-291` | **themeMode 用户切换后未持久化** → 重启回到 system | Software | 简单 | **P2** | themeModeProvider 用 SharedPreferences 持久化。1h |
| 27 | `ios/Runner/Info.plist:144-150` | **`LSApplicationCategoryType=healthcare-fitness`** 触发 ASC Health Information Disclosure Questionnaire → 需手填 | Safety | 简单 | **P2** | ASC 后台答 6 问：no HealthKit / no medical decision / no clinical advice / no FDA / no NMPA。30 min |
| 28 | `lib/presentation/pages/setup/setup_step_consent.dart:14-44` | **5 步勾选全在 Step 0** — Apple HIG 建议拆 1+1+1+1+1 多步走 | Software | 简单 | **P3** | UX 改进非阻断。2h |
| 29 | `fastlane/` 整体 | **fastlane 0 screenshot 维护**（CI 友好）| Metadata | 中 | **P3** | 加 `fastlane/snapfile` + `Fastfile` + `snapshot.js` + `screenshots.json` 描述文件。4h |
| 30 | `lib/core/theme/app_tokens.dart` | **缺少 Dynamic Type scale 策略**（base × scale）| Software | 中 | **P3** | 加 `AppTokens.fontSizeTitleScaled(context)` 系列 helper。3h |

**统计**：30 个问题 — P0 9 个 / P1 7 个 / P2 9 个 / P3 5 个 — 总工时 ~38h（约 1.5 sprint）

---

## 3. 跟 R105 6.0 的差异

| 项 | R105 (6.0) | R104-105 后 | Δ |
|---|---|---|---|
| 截图 0 张 | -0.5 | -1.5 (持续未补) | -1.0 |
| IAP "8 元买断" 描述 vs iapEnabled=false 不一致 | -0.5 | -0.5 (R100 决策: 隐藏 IAP 入口但保留文本) | 0 |
| vent audio 已启用但 UIBackgroundModes audio 仍删 | 0 | **-1.0** (R100 删 + R104 启 = 矛盾暴露) | -1.0 |
| PrivacyInfo.xcprivacy 未注册到 Xcode project | 0 | **-1.0** (R61 写但漏注册 — 之前自评漏检) | -1.0 |
| iCloud Backup 0 排除 (精神心理患者 PII 上 Apple) | -0.3 | **-1.0** (R104 启用 vent audio 后音频文件也未排除 → 严重升级) | -0.7 |
| 通知 body 药名 PII 锁屏泄漏 | 0 | **-0.5** (R104 启用 vent audio 但 PII 风险同步升高) | -0.5 |
| 5 步 setup consent 完整 | +0.5 | +0.5 (R67-R104 持续完善) | 0 |
| 4 文档法律审 (R83) | +1.0 | +1.0 (律师审核集中修复 6 处) | 0 |
| Privacy Manifest 5 类填齐 | +0.5 | +0.5 (R61+R71) | 0 |
| InfoPlist.strings per-locale (3 locale) | +0.3 | +0.3 (R70) | 0 |
| Export Compliance ITSAppUsesNonExemptEncryption=false | +0.2 | +0.2 (R62) | 0 |
| iOS 14+ foreground 通知 willPresent | +0.3 | +0.3 (R75 修) | 0 |
| 危机热线一键拨打 (url_launcher) | 0 | +0.3 (R97-P1-11) | +0.3 |
| **合计** | **6.0** | **4.5** | **-1.5** |

**退步的核心原因**：
- R100 删除 UIBackgroundModes 是出于"Apple 2.5.4 拒" 担心，但 R104 启用 vent audio 后**未同步加回 audio** → 留隐患。
- R61 写 PrivacyInfo.xcprivacy 但**漏注册到 Xcode project** → 2 周年 bug 暴露。
- R104 启用 vent audio 后，**iCloud Backup 排除 + 通知 body 脱敏** 两个 PII 风险同步升高但未配套修。

---

## 4. 阻断上架项（P0）vs 非阻断项

### 4.1 阻断上架项（9 项，必须修才能上传）

| # | 项 | 拒因 | Apple Guideline |
|---|---|---|---|
| 1 | PrivacyInfo.xcprivacy 未注册 Xcode project | "Privacy Manifest required but missing from bundle" | Privacy Manifest 强制 2024-05 |
| 2 | SQLite DB 默认 iCloud Backup | "Sensitive user data backed up to iCloud without disclosure" | 5.1.1 + Data Safety |
| 3 | 通知 body 药名 + 剂量锁屏 PII | "User-identifiable health data exposed in lock screen notifications" | 5.1.1 + HIG Notifications |
| 4 | LaunchImage 68 字节空白 | "App shows blank/white screen on launch" | 2.1 App Completeness |
| 5 | AppIcon 1024×1024 占位 | "App icon does not meet marketing guidelines" | 2.3.7 + HIG App Icon |
| 6 | privacy_url / support_url 域名未注册 | "Privacy policy URL is unreachable" (必点) | 5.1.1 + 2.3 |
| 7 | review_information 目录缺失 | "App cannot be submitted — review information incomplete" | 2.3 |
| 8 | vent audio 已启用但 UIBackgroundModes audio 缺 | "Declared capabilities don't match actual usage" | 2.5.4 |
| 9 | fastlane/screenshots 0 张 | "Cannot submit without required screenshots" | 2.3.10 |

**9 项全部为 P0 阻断，估算工时 ~12.5h（约 1.5 工作日）**。

### 4.2 非阻断项（21 项，审核员会标但通过）

- P1 7 项：Dynamic Type / VoiceOver / Sensitive Info / ActiveKeyboard / keywords 优化 / iPhone 16 适配 / copyright 补全
- P2 9 项：requestPermission 实际调用 / NSCameraUsageDescription / themeMode 持久化 / Health 问卷 / etc.
- P3 5 项：fastlane CI 化 / Dynamic Type scale helper / 多步 consent / 等等

**P1+P2+P3 共 21 项 + 12.5h 阻断项 = 33.5h ≈ 4-5 工作日**。

---

## 5. 修复路线图

### Phase 1: 上架前必做（1.5 sprint / ~12.5h）

| Sprint | 周 | 内容 | 验收 |
|---|---|---|---|
| **Sprint 1: P0 阻断** | Week 1 | 修问题 #1-9（9 项 P0 阻断）| flutter analyze 0 error / flutter test 1997+ pass / Apple 拒因检查 0 项 |
| **Sprint 2: P1 + P2 关键** | Week 2 | 修问题 #9-15, #19-20, #24, #26-27（14 项）| HIG 11 项全过 / Privacy Manifest 7 类 / Data Safety 13 类手填 / ASC 后台问卷完成 |

### Phase 2: 上架后必做（1 sprint / ~14h）

| Sprint | 周 | 内容 | 验收 |
|---|---|---|---|
| **Sprint 3: 业务真接前置** | Week 3 | 真接 IAP productId / 阿里云 SMS 模板审核 / SendGrid API key / 5 厂商 push SDK | 4 业务恢复后无 P0 |

### Phase 3: 长期优化（持续 / 30h+）

| Sprint | 周 | 内容 |
|---|---|---|
| **Sprint 4: 架构优化** | Week 4+ | fastlane CI 化 / Dynamic Type 全覆盖 / 5 步 consent 拆细步 / 截图 4 设备 5 屏全齐 / iPhone 16 Pro Max 6.9" 完整适配 |

### 5.1 上架前检查清单（Apple App Store Connect 上传前）

- [ ] 4 文档（隐私 / 用户 / 敏感数据 / 医疗免责）律师签字
- [ ] 域名 chroniccare.app 注册 + 4 文档 + privacy URL + support URL 部署
- [ ] AppIcon 1024×1024 + LaunchImage 3 张真实图片
- [ ] PrivacyInfo.xcprivacy 注册到 Xcode project
- [ ] SQLite DB + audio 文件 iCloud Backup 排除
- [ ] 通知 body 脱敏（visibility=private）
- [ ] UIBackgroundModes audio 加回
- [ ] 5 设备 × 5 屏 = 25 张截图
- [ ] fastlane metadata 3 locale × 8 项 + review_information 7 文件
- [ ] ASC 后台 13 类 Privacy Practices 全部勾
- [ ] ASC 后台 Health Information Disclosure 6 问全答
- [ ] Data Safety (App Store Connect) 5 大类 × 14 子项全填
- [ ] Age Rating 问卷（Apple 默认 17+ healthcare-fitness 类别）
- [ ] Export Compliance (CCATS / annual self-classifier report)
- [ ] Demo Account（如果是注册式 App — 本项目无注册可填 "No demo account required"）
- [ ] Contact Info（first_name / last_name / email / phone）

---

## 6. 隐私 / 合规 / 法律评估

### 6.1 隐私（Privacy）

| 维度 | 评分 | 关键问题 |
|---|---|---|
| 数据最小化 | 9/10 | 5 类已声明 + 零云端 ✓ |
| 数据加密 | 9/10 | SQLCipher AES-256 + FlutterSecureStorage Keychain + Audio AES-256 字段级 ✓ |
| 传输安全 | 10/10 | 零网络传输，零云端 |
| 锁屏 PII | **3/10** | 通知 body 药名 + 剂量明文 PII（**问题 #3 P0 阻断**）|
| iCloud Backup | **0/10** | SQLite + audio 默认 iCloud Backup（**问题 #2 P0 阻断**）|
| 撤回同意 | 9/10 | ConsentGate 业务层真接 3 项 ✓ |
| 单独同意 | 7/10 | setup 5 勾选 + 隐私政策 §0 但紧急联系人业务暂停中未做 §13/§23 真接 |

### 6.2 合规（Compliance）

| 法规 | 状态 | 详情 |
|---|---|---|
| 《PIPL》（个保法）| ✅ | 隐私政策 §0-§12 + 业务层 ConsentGate |
| 《未成年人保护法》§44 | ✅ | setup 第 4 勾选（年龄严正声明）|
| Apple App Store Review Guidelines 5.1.1 | ⚠️ | 9 项 P0 阻断中 #2 #3 属 5.1.1 直接拒因 |
| Apple App Store Review Guidelines 5.1.3 Health | ✅ | 无 HealthKit 接入 + 描述自定位非医疗 |
| Apple App Store Review Guidelines 1.4.1 Medical | ✅ | setup 第 5 勾选 + medical_disclaimer.md |
| Apple Privacy Manifest (2024-05) | ⚠️ | 5 类已填但漏注册 + 缺 SensitiveInfo + ActiveKeyboard |
| HIPAA (US) | N/A | 业务未到美国市场（无 en-US 业务运营）|
| GDPR (EU) | N/A | 业务未到欧盟市场（无 EU 描述）|

### 6.3 法律（Legal）

| 维度 | 状态 | 备注 |
|---|---|---|
| 4 文档律师审核 | ✅ | R83 律师集中修复 6 处（隐私 §0.5/§3/§7/§10/§11/§12 + 用户协议 §1/§5）|
| 域名 / 邮箱 / 仓库 | ⚠️ | chroniccare.app 未注册 + privacy@chroniccare.app 占位 |
| 撤回记录 | ✅ | 4 文档 §0 / 隐私政策 §4 / 敏感数据 §7 |
| 未成年人保护 | ✅ | 隐私政策 §10 + setup 第 4 勾选 + 严正声明 |
| 跨境传输 | ✅ | 隐私政策 §11 完整披露 + 当前版本 0 跨境 |
| 单独同意 | ⚠️ | 当前业务暂停中 / 未来 SMS 真接时 P0 必接 §13/§23 |
| 业务真接合规链 | ⚠️ | 4 业务（IAP / SMS / 5 厂商 push / SendGrid）依赖外部审核 1-2 月 |

---

## 7. 截图 / 描述 / Metadata 完整度

### 7.1 截图完整度：**0/10**

| 设备 | 数量 | 必需 | 状态 |
|---|---|---|---|
| iPhone 6.7" (iPhone 15 Pro Max / 16 Pro Max) | 5+ | 必填 | ❌ 0 |
| iPhone 6.1" (iPhone 15 / 16) | 5+ | 必填 | ❌ 0 |
| iPhone 5.5" (iPhone 8 Plus) | 5+ | 必填 | ❌ 0 |
| iPad 12.9" (iPad Pro 13") | 5+ | 必填 | ❌ 0 |
| iPad 11" (iPad Air 11") | 可选 | 推荐 | ❌ 0 |
| Apple TV 4K | N/A | — | — |

**0 张 = 上传时 Apple 提示 "No screenshots available"，手动上传路径被强制**。

### 7.2 描述完整度：**8/10**

| 维度 | 评分 | 备注 |
|---|---|---|
| 中文描述情感共鸣 | 9/10 | "我今天吃了药"开篇有力量 + 危机资源链接 6 区域 + 医疗免责清晰 |
| 英文描述本地化 | 7/10 | 较中文弱 — 缺 "non-medical device" 显式强调（仅 description 末段有）|
| 繁中描述 | 7/10 | 类似英文问题 |
| 关键词覆盖 | 6/10 | en 7 词（medication / reminder / mood / mental / health / chronic / tracker）— 缺 depression / anxiety / pill / habit / streak |
| 视频预览 | 0/10 | 0 个 video preview（可选但推荐）|
| 截屏对应描述 | 0/10 | 0 张截屏无法对应描述 |

### 7.3 Metadata 完整度：**7.5/10**

| 项 | 评分 | 备注 |
|---|---|---|
| 8 项 metadata × 3 locale | 10/10 | 24 文件全填 ✓ |
| review_information | 0/10 | **目录不存在**（P0 阻断 #7）|
| Apple 分类 (Primary Category) | 7/10 | LSApplicationCategoryType=healthcare-fitness ✓ 但 ASC 后台需手勾 + 触发 Health 问卷 |
| Age Rating | ?/10 | 需 ASC 后台答问卷（默认 17+ 因 healthcare-fitness 类别）|
| Privacy Practices (13 大类) | ?/10 | 需 ASC 后台手填 |
| Data Safety (5 大类 × 14 子项) | ?/10 | 需 ASC 后台手填（Apple 2021-06 起强制）|
| 截图上传 | 0/10 | 0 张 |
| 视频预览 | 0/10 | 0 个 |

---

## 8. 总结

### 8.1 关键发现

1. **代码层极成熟**（v0.30.0+85, 1997+ tests, 4 层架构, 17 守护脚本, R104 启用 vent audio）—— 这是项目的强项。
2. **iOS 资源 / Metadata 层几乎空白** —— LaunchImage 占位 / AppIcon 占位 / 截图 0 / review_information 0 / 域名未注册 —— 这是项目的最大短板。
3. **Privacy Manifest 已写但漏注册 Xcode** —— **单点 bug 但 P0 阻断**。
4. **iCloud Backup + 通知 body 药名 PII 泄漏** —— 精神心理类 App 的核心隐私风险。
5. **法律 / 4 文档 / 5 步 setup 流程 / ConsentGate 业务层** —— 已达律师审标准，合规层完成度高。

### 8.2 上架决策

| 选项 | 建议 |
|---|---|
| **立刻上架** | ❌ 不建议，9 项 P0 阻断 |
| **2 周内上架** | ✅ Sprint 1 修 9 项 P0（~12.5h）+ Sprint 2 修 P1+P2 关键（~14h）+ 准备截图 25 张（~3h）= 30h ≈ 1.5 周 |
| **1 月内上架** | ✅ 上面 + 业务真接前置（IAP / SMS 4 业务外部审核 1-2 月）|
| **2026 Q4 上架** | ✅ 全部 + 长期优化 |

### 8.3 上架评分

- **代码就绪度**：7.5/10
- **资源 / Metadata 就绪度**：1.5/10 ⬅️ 最大短板
- **法律 / 合规就绪度**：7.0/10
- **整体上架就绪度**：**4.5/10**

**最终建议**：先把 9 项 P0 阻断项（Sprint 1 12.5h）走完，再决定是否提交。如果资源允许，先做 Sprint 1-2 再提交；如果是时间敏感（比如抢首发），至少要把 P0 #1（PrivacyInfo 注册）+ #2（iCloud Backup 排除）+ #3（通知 body 脱敏）+ #5（AppIcon 真图）+ #6（域名注册）+ #7（review_information 7 文件）+ #8（UIBackgroundModes audio）这 7 项必做。

---

*最后更新：2026-08-10 (v0.30 round 104-105 之后)*
*审计员：Apple App Store 视角深度审计员*
*审计范围：iOS 14+ deployment target / Apple App Store Review Guidelines + HIG + Privacy Manifest + Required Reason API*
