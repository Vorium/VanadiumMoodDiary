# AppStore 上架就绪度审计 (2026-08-10)

**项目**: ChronicCare v0.30.0+85
**审计日期**: 2026-08-10
**审计基线**: R104 (2026-08-09) + R105 review (2026-08-09)
**视角**: Apple App Store Review Guidelines 1.x / 2.x / 4.x / 5.x + HIG + Privacy Manifest + Required Reason API
**基线评分**: R104 = 6.5/10, R105 = 6.0/10

---

## 评分

**5.8/10** (vs R105 6.0/10, 净降 0.2)

**评分变化**:
- 加分 (R104 → R105 修复验证):
  - A11 medical disclaimer 进 onboarding 验证通过 (`setup_step_consent.dart:147-152` 第 5 勾 + `medical_disclaimer.md` 资产 + `showLegalDocument('medical_disclaimer')` 路由)
  - A12 user_agreement "8 元买断" → "当前版本免费" 措辞已对齐 (R101)
  - A13 store description 删 (失联通知规划中) 残留 — 已修 (en/zh-Hans/zh-Hant description 全部无 "规划中" 字样)
  - iOS mic/speech 权限描述已恢复 (R105 在 `Info.plist` 3 语 `InfoPlist.strings` 加回 `NSMicrophoneUsageDescription` + `NSSpeechRecognitionUsageDescription`)
- 扣分 (新发现 + 漏修):
  - 全部 3 个 locale iOS 截图目录**完全不存在** (`fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/iphone_6_7_screenshots` 等 8 个目录均 0 文件) — R104 标 P0 仍未修
  - `PrivacyInfo.xcprivacy` 没在 Xcode project 中注册 (`project.pbxproj` 0 引用 `PrivacyInfo` / `xcprivacy`) — 文件在磁盘但**没被打包进 .app** → Apple 2024-05 强制声明实际上 0 提交
  - `Runner.entitlements` 被 `Read` 工具读出是乱码 (mojibake): 原内容中文注释 "删 aps-environment" 在 GBK/CJK locale 显示乱码 — 提示该项目跨平台 (Windows) 文件读写有 BOM / 编码问题, xcodebuild 在 macOS 上**可能**也受影响
  - `iPhone 16 Pro Max` 适配证据缺失 (启动图 / AppIcon 是 2026-04 占位; 2024-09 发布的 iPhone 16 系列需新默认 LaunchImage 1024×1024, 当前 `LaunchImage.png` 68 字节 = 空白)
  - AppIcon 18 个 PNG 共 18 各种尺寸但都是 2026-04 占位 (282-1674 bytes), 2024-2026 默认模板色, 1024×1024 才 10932 bytes, 远低于真实 App Icon (应该 ≥ 50KB), 仍属 "default Flutter icon"
  - **R105 误判**: R105 报告说 "NSMicrophone / NSSpeech 已恢复", 但本审计**实际验证** R105 评论写在 R104 是 `feature_flags.dart` 翻 `true` 那一刻, 实际 `Info.plist` 注释块明确写 "R102 删除, R105 恢复" — **注释自相矛盾**: 同一个版本号 R105 在 3 个地方出现, 一处说 "已删", 一处说 "已恢复", 实际文件存在 → 文档漂移
  - 新发现 "无 medical disclaimer 在 metadata 描述里": `en-US/description.txt` / `zh-Hans/description.txt` / `zh-Hant/description.txt` 都在末尾放危机热线 (crisis hotline), 但**没有医学免责声明**。App Store 2.1 / 1.4.1 要求医疗类 App 在公开宣传里明示 "not a medical device" 状态, 当前仅靠 隐私政策 + 隐私 manifest + onboarding 内部勾选, store description 未在公开层做 disclaimer, Apple 抽审可能打回
  - `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/` 全部**缺 `app_icon.png`**, 3 套 locale 都没 icon 上传, ASC 用 `Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` (10932 bytes 占位)
  - **Apple Age Rating (内容评级) 仍 0 维护**: `LSApplicationCategoryType=healthcare-fitness` (iOS 12+) 会触发 ASC 问卷 "Health & Fitness - Medical/Treatment Information" → Apple 默认 17+ — 但 R104/R105 都未在 fastlane / ASC 配置里实际填问卷, 上架 100% 阻塞
  - **iCloud Backup 排除 (R104 A11 P1) 仍未修**: `native.dart:18` 走 `getApplicationDocumentsDirectory()` 写 SQLCipher db, `encrypted_audio_storage.dart:99-104` 写 audio 文件, 两处都**未**调 `FileManager.setAttributesItem(.isExcludedFromBackup = true)`, iOS 默认会把 app docs backup → iCloud, 精神心理患者敏感数据上 Apple iCloud (虽然加密) 但**仍走 iCloud 备份** (Guideline 5.1.1 风险)
  - **Dynamic Type (R104 A12 P1) 仍未修**: 81 个文件 275 处 `fontSize:` 硬编码, 0 `MediaQuery.textScalerOf(context)` 调用, 0 `textScaler` 适配, Apple 2.5.1 必查项
  - **锁屏通知脱敏 (R104/R105 A5 P1) 仍未修**: `lib/core/l10n/strings.dart:103-119` 仍硬编码 "💊 该吃药了：$medName $dosage$unit" 暴露药名+剂量到锁屏
  - **App Store Connect 缺 secondary category / 隐私实践 (Privacy Practices) 缺医疗细化项**: 医疗类 App 应在 ASC 隐私实践勾 "Health & Fitness" + "Medical" + "Treatments and Cures" 子类, fastlane 0 维护

---

## 一、App Completeness (Guideline 2.1)

### 1.1 截图 (6.7" / 6.5" / 5.5" / iPad 12.9") 严重缺失

| Locale | 6.7" | 6.5" | 5.5" | iPad 12.9" | iPad 11" | iPad 10.5" | Mac |
|--------|------|------|------|-----------|---------|-----------|-----|
| en-US | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| zh-Hans | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| zh-Hant | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

**全 24 个截图目录 + 0 个 PNG** (R104 / R105 标 P0, 仍未修)。Apple Guideline 2.3.3 强制要求每种 device 至少 1 张, **当前完全无法提交**。

**修复**:
1. macOS 跑 `flutter build ios --release` 出 `.app`
2. 模拟器 5 套 (iPhone 16 Pro Max 6.7" / iPhone 11 Pro Max 6.5" / iPhone 8 Plus 5.5" / iPad Pro 12.9" / iPad Pro 11") 截 5 张主流程图 (home / mood / vent / medication / assessment)
3. 3 locale × 5 设备 = 15 张, 加 iPad 12.9" / 11" / 5.5" 老设备兼容 = 33 张
4. 全部用真实数据 demo 账号填, 不能用 mock 占位 (Apple 抽审会对比 metadata 与功能)

### 1.2 描述 vs 实际功能

| Locale | 描述 | 实际 | 对齐? |
|--------|------|------|-------|
| en-US | "voice recordings are stored locally" | vent + mood audio (R104 启用) | ✅ 描述包含录音 |
| zh-Hans | 无 "录音" / "audio" 字样 | vent + mood audio (R104 启用) | ❌ 描述 < 实际 (2.1 "feature discrepancy" 拒) |
| zh-Hant | 无 "錄音" / "audio" 字样 | vent + mood audio (R104 启用) | ❌ 描述 < 实际 (2.1 拒) |

**R105 A16 已标记 P2 但未修**。

**修复**: `zh-Hans/description.txt` 在【樹洞】段补 "支持语音笔记本地加密" (zh-Hant 同步); 或 `feature_flags.dart:70` 回滚 `_prodVentAudioEnabled = false` 让代码与描述再次对齐 (更稳)。

### 1.3 iCloud Backup 排除 (R104 A11 P1) 仍未修

- `ios/Runner.xcodeproj/project.pbxproj` 0 引用 `setResourceAttribute` / `isExcludedFromBackup`
- `lib/core/data/database/connection/native.dart:18-22` 创建 db 文件, `lib/core/data/privacy/encrypted_audio_storage.dart:98-104` 创建 audio 目录 — 两处都未设置 `URLResourceKey.isExcludedFromBackupKey = true`
- iOS 默认把 `Documents/` 全部 backup 到 iCloud (iCloud Drive + iTunes), 精神心理患者敏感数据被 Apple 服务器存一份 (虽然 db 加密) → Guideline 5.1.1 (privacy) 风险

**修复 (MethodChannel)**:
```swift
// ios/Runner/AppDelegate.swift 加 helper
func excludeFromBackup(url: URL) {
  var url = url
  var values = URLResourceValues()
  values.isExcludedFromBackup = true
  try? url.setResourceValues(values)
}
```
Dart 侧在 `native.dart` 和 `encrypted_audio_storage.dart` 创建后调 MethodChannel 通知 native 排除。

### 1.4 启动图 LaunchImage 占位 (Apple HIG 2.5.4 风险)

- `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png` **68 bytes** (空白文件, IHDR 块 1×1 px 透明 PNG)
- `LaunchImage@2x.png` / `LaunchImage@3x.png` 同 68 bytes
- iPhone 16 Pro Max (6.7" = 1290×2796) 启动时全黑 + 默认 Flutter logo → 体验差 + App Store 2.5.4 "should look like default app" 抽审

**修复**:
1. Apple 已 deprecated `LaunchImage` 静态资源 (iOS 14+ 推荐 LaunchScreen.storyboard, 当前已用 ✓)
2. 但**仍**需要给老设备兼容, 加 1 张 1024×1024 占位 PNG 替代 68 byte 空白 (否则部分 iOS 14- 设备启动闪白)
3. 建议彻底删 `LaunchImage.imageset/`, 仅保留 `LaunchScreen.storyboard` (R105 已切此方案, 但 `.imageset` 还在)

### 1.5 评分 (满分 10)

**2/10** — 截图 0 张 / 描述 vs 实际不一致 / 启动图占位 / iCloud 排除 0 — 仅靠 Flutter 默认 + 已有 metadata 文本可过, 但 Apple 2.1 / 2.3 必拒。

---

## 二、Metadata (Guideline 2.3)

### 2.1 8 项 metadata 完整性

| 项 | en-US | zh-Hans | zh-Hant | 状态 |
|----|-------|---------|---------|------|
| `name.txt` | "ChronicCare" (12B) | "慢病管家" (13B) | "慢病管家" (13B) | ✅ |
| `subtitle.txt` | "Medication + Mood Tracker" (26B) | "吃药打卡 + 情绪关怀" (28B) | "吃藥打卡 + 情緒關懷" (28B) | ✅ ≤30 字符 |
| `keywords.txt` | 7 词 (55B) | 7 词 (49B) | 7 词 (49B) | ✅ ≤100 字符 |
| `description.txt` | 2274B | 1757B | 1698B | ✅ ≤4000 字符 |
| `promotional_text.txt` | 137B | 129B | 129B | ✅ ≤170 字符 |
| `privacy_url.txt` | https://chroniccare.app/privacy (32B) | 同 | 同 | ❌ 域名未注册 |
| `support_url.txt` | https://chroniccare.app/support (32B) | 同 | 同 | ❌ 域名未注册 |
| `copyright.txt` | "© 2026 chroniccare" (20B) | "© 2026 慢病管家" (21B) | "© 2026 慢病管家" (21B) | ✅ |

### 2.2 review_information / demo account (Guideline 2.3.3)

**完全缺失**:
- 无 `review_information/` 目录
- 无 `demo_account.txt` (本项目无 account 是 OK, 但需声明 "this app does not require login")
- 无 `first_name` / `last_name` / `email_address` / `phone_number` (App Store Review 团队联系信息)
- 无 `notes.txt` (审核员注释, Apple 2.3.3 强烈推荐写: "No account required, all data is local, app is offline-only")

**修复**:
```
fastlane/metadata/ios/review_information/
├── first_name.txt           # 项目 owner 名
├── last_name.txt            # 姓
├── email_address.txt        # 真实可达邮箱
├── phone_number.txt         # 含国家码 +86xxx
├── demo_user.txt            # "No account required — all data is local"
└── notes.txt                # 详细审核员指南
```

### 2.3 评分 (满分 10)

**5/10** — 8 项 metadata 文本齐, 隐私/支持 URL 不可达 (1 项), review_information 0 文件 (1 项), zh-Hans/zh-Hant 描述 < 实际 (1 项)。

---

## 三、Software Requirements (Guideline 2.5)

### 3.1 Dynamic Type (R104 A12 P1) — 严重缺失

- 81 个文件 275 处硬编码 `fontSize:`, 0 处 `MediaQuery.textScalerOf(context)` / `textScaler:` 调用
- 例: `lib/core/theme/app_tokens.dart:2`, `lib/core/theme/app_typography.dart:22` 全部写死 px
- Apple 2.5.1 必查, WCAG 1.4.4 同要求, 精神心理 App 用户**特别需要**大字模式 (抑郁 / 双相患者低视力常见)
- 精神心理 App 用 Dynamic Type = 病耻感规避 + 可达性双关

**修复**:
1. 改 `app_typography.dart` 用 `Theme.of(context).textTheme` (M3 默认已 `MediaQuery.textScaler` 响应)
2. 替换 275 处 `fontSize: X` 为 `style: Theme.of(context).textTheme.bodyLarge`
3. UI 测试: iOS 设置 → 显示与亮度 → 文字大小 → 6 级全跑
4. 短码 add `textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.6)` 避免大字号破布局 (LineChart / Bar chart)

### 3.2 VoiceOver / Semantics (HIG Accessibility)

- `Semantics(` / `ExcludeSemantics(` / `MergeSemantics(` 仅 11 文件 24 处调用
- `Tooltip(` 也很少 — 大量 emoji + 装饰图标无 label
- R104 报告 emil E5/E7/E8 已标 decorative emoji 被 screen reader 朗读 (P1, 未修)
- Apple 2.5.1 + WCAG 1.3.1 必查

**修复**:
1. 所有 `Icon(...)` (纯装饰) 加 `ExcludeSemantics(child: Icon(...))`
2. 所有 emoji (如 🌿 ✨) `ExcludeSemantics` 或加 `Semantics(label: ...)`
3. 主操作按钮 (打卡 / mood / vent) 加 `Semantics(button: true, label: l10n.checkInButtonTooltip)`
4. 跑 VoiceOver (macOS Xcode Accessibility Inspector) 全 8 个主流程

### 3.3 暗黑模式 (Guideline 2.5.1 友好非必须)

- `app_theme.dart:14` 有 dark mode 实现 ✓
- 但 R104 报告 emil E4 hero_illustration dark mode 不可见 (Colors.black shadow), flutter-spec F6/F7 4 文件硬编码 Apple 系统颜色
- 影响上架但不阻塞 (Apple 2.5.1 暗模式是 2024 推荐非必拒)

### 3.4 iPhone 16 Pro Max 适配 (HIG 设备适配)

- `IPHONEOS_DEPLOYMENT_TARGET = 14.0` (pbxproj) ✓
- 启动图 `LaunchImage.png` 68 字节空白 → iPhone 16 Pro Max 启动闪白
- `Info.plist:131-143` `UISupportedInterfaceOrientations` 包含 portrait + landscape, 但项目实际几乎都是 portrait (主页 hero + FAB 锁竖屏), landscape 进 settings 后顶部 toolbar 变形
- 无 iPhone 16 Pro Max 真实截图 (见 1.1)

**修复**:
1. 删 `LaunchImage.imageset/`, 仅 `LaunchScreen.storyboard`
2. `UISupportedInterfaceOrientations~iphone` 砍到 portrait-only (项目 95% portrait, 砍 landscape 减 review 风险)
3. 截 iPhone 16 Pro Max 真机图 (1290×2796 px)

### 3.5 Apple Watch / iPad 多任务

- `UIRequiresFullScreen = false` (R61) → iPad Split View 启用 ✓
- 无 Apple Watch App → 不需要 watchOS 适配
- 无 iMessage / Share Extension → 不需要 extension 审核

### 3.6 评分 (满分 10)

**4/10** — Dynamic Type 0 适配 (主因) / VoiceOver 弱 / 暗黑模式部分 / 启动图空白 / landscape 锁屏未做。

---

## 四、Privacy (Guideline 5.1.1)

### 4.1 隐私政策 URL 可达性 (Guideline 5.1.1 + 2.3.3)

- `privacy_url.txt` 3 locale 全 `https://chroniccare.app/privacy`
- `support_url.txt` 3 locale 全 `https://chroniccare.app/support`
- **域名未注册** (R103/R104/R105 标 P0 仍未修)
- Apple 2.3.3 强制 Support URL 可达 (HTTP 404 = 必拒); 5.1.1 强制 Privacy URL 是 HTTPS (HTTP 200 + 含政策内容)

**修复** (见 `STOREFRONT_RELEASE_SOP.md` #1):
1. 注册 `chroniccare.app` (.app TLD 强制 HTTPS, Cloudflare Registrar $15/yr)
2. 部署 4 个 HTML 页面 (privacy / support / agreement / consent)
3. ICP 备案 (中国大陆上架 7-20 天)
4. 替换 `fastlane/metadata/ios/*/privacy_url.txt` + `support_url.txt` (实测必须 HTTPS 200, 302 也拒)

### 4.2 "Data Not Collected" claim (App Privacy 在 ASC)

- `PrivacyInfo.xcprivacy` 声明 4 类收集 (HealthAndFitness / AudioData / ContactInfo / UserContent) Linked=false / Tracking=false
- App Store Connect → App Privacy 需逐项**人工**填写 (与 PrivacyInfo.xcprivacy 对齐), fastlane 0 维护
- R100 修后 ASC App Privacy 表单需手填 7 大类:
  1. Contact Info → "Not collected" ✓
  2. Health & Fitness → "Collected, not linked to you, not used for tracking" ✓
  3. Financial Info → "Not collected" ✓
  4. Location → "Not collected" ✓
  5. Sensitive Info → "Collected, not linked to you" ⚠️ (PHQ-9 / GAD-7 = Sensitive)
  6. Diagnostics → "Not collected" ✓
  7. Identifiers → "Not collected" ✓
  8. Usage Data → "Not collected" ✓
  9. Purchases → "Not collected" ✓ (iapEnabled=false)
  10. Audio Data → "Collected, not linked to you" ✓
  11. User Content (Vent 文字) → "Collected, not linked to you" ✓
  12. Browsing History → "Not collected" ✓
  13. Search History → "Not collected" ✓

**修复**: ASC 后台手动勾 (无法 fastlane 自动化, Apple 后台无 API)。

### 4.3 第三方 SDK (Guideline 5.1.1)

- `pubspec.yaml` 0 analytics / 0 ad SDK / 0 crash reporter (Sentry/Firebase/Crashlytics) ✓
- `url_launcher` 6.3.1 (Apple 5.1.1 列为 network SDK, 但仅 tel: scheme 实际**不打网络**)
- `share_plus` 10.1.4 (调系统 UIActivityViewController, 不出数据)
- `flutter_local_notifications` 17.2.3 (本地通知, 不走 APNs)
- `in_app_purchase` 3.3.0 (iapEnabled=false, 不实际触发)
- `pdf` 3.11.1 + `printing` 5.13.4 (本地 PDF 生成, 零网络)
- 0 个 SDK 声明需在 App Privacy "Data Used to Track You" 勾

**验证**: 全部 SDK 实际行为与 PrivacyInfo 声明 "Tracking=false" 一致 ✓

### 4.4 评分 (满分 10)

**5/10** — 隐私 manifest 已写 + 0 第三方 SDK + Data Not Collected 原则对齐, 但 (1) 域名未注册 (2) ASC App Privacy 表单 0 维护 (3) Sensitive Info / Health 勾法需与法务确认。

---

## 五、Privacy Manifest (强制 2024-05)

### 5.1 NSPrivacyTracking

```xml
<key>NSPrivacyTracking</key>
<false/>
```

✅ 正确 (项目无 IDFA / 无 ATT / 无广告 SDK)

### 5.2 NSPrivacyTrackingDomains

```xml
<key>NSPrivacyTrackingDomains</key>
<array/>
```

✅ 正确 (无 tracking domain)

### 5.3 NSPrivacyCollectedDataTypes

4 类 (HealthAndFitness / AudioData / ContactInfo / UserContent) 全 Linked=false, Tracking=false, Purpose=AppFunctionality。

**与运行时实际一致** (R105 验证): vent 录音启用 → AudioData ✓; PHQ-9 启用 → HealthAndFitness ✓; 紧急联系人预存储 → ContactInfo ✓; Vent 文字 → UserContent ✓。

⚠️ **缺 1 类**: `NSPrivacyCollectedDataTypeSensitiveInfo` — 精神心理 App 处理 PHQ-9 / GAD-7 评分 (敏感健康信息), Apple 模板要求**单独**列 SensitiveInfo 不能合并到 HealthAndFitness。R105 漏。

**修复**:
```xml
<dict>
  <key>NSPrivacyCollectedDataType</key>
  <string>NSPrivacyCollectedDataTypeSensitiveInfo</string>
  <key>NSPrivacyCollectedDataTypeLinked</key>
  <false/>
  <key>NSPrivacyCollectedDataTypeTracking</key>
  <false/>
  <key>NSPrivacyCollectedDataTypePurposes</key>
  <array>
    <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
  </array>
</dict>
```

### 5.4 NSPrivacyAccessedAPITypes (Required Reason)

5 类声明:
- `UserDefaults` CA92.1 + CA92.2 ✓ (FlutterSharedPreferences + flutter_secure_storage 内部)
- `FileTimestamp` C617.1 ✓ (path_provider 读 file mtime)
- `SystemBootTime` 35F9.1 ✓ (WidgetsBindingObserver 检测跨日)
- `DiskSpace` 85F4.1 ✓ (audio 磁盘剩余)
- `ProcessInfo` AC67.1 ✓ (flutter_local_notifications thermalState)

**新发现缺 1 类**: **`NSPrivacyAccessedAPICategoryActiveKeyboard`** — 任何用键盘的 App 都需声明 reason E620.1 (实现在 App 内) 或 E620.2 (App extension)。精神心理 App 大量 `TextField` (vent_compose / mood factor / assessment 答题) — 键盘事件大量触发, **必查项**。

**修复**:
```xml
<dict>
  <key>NSPrivacyAccessedAPIType</key>
  <string>NSPrivacyAccessedAPICategoryActiveKeyboard</string>
  <key>NSPrivacyAccessedAPITypeReasons</key>
  <array>
    <string>E620.1</string>
  </array>
</dict>
```

### 5.5 **严重: PrivacyInfo.xcprivacy 没注册到 Xcode project**

`grep "PrivacyInfo|xcprivacy"` 在 `project.pbxproj` **0 匹配**:
- 文件存在于 `ios/Runner/PrivacyInfo.xcprivacy` (4990 bytes)
- 但 `project.pbxproj` 没引用 `PrivacyInfo.xcprivacy` 到 PBXFileReference / PBXResourcesBuildPhase
- **结果**: xcodebuild 打包时**不会**把 `PrivacyInfo.xcprivacy` 复制到 `.app/`, Apple 抽审时读 .app 看 0 manifest → **必拒**

**修复**:
1. Xcode → Runner → 右键 Add Files → 选 `PrivacyInfo.xcprivacy` → 勾 "Copy items if needed" + target=Runner
2. 或编辑 `project.pbxproj` 加:
   ```
   /* PrivacyInfo.xcprivacy */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml.privacy; path = PrivacyInfo.xcprivacy; sourceTree = "<group>"; };
   ```
   + `97C147031CF9000F007C117D /* PrivacyInfo.xcprivacy in Resources */ = {isa = PBXBuildFile; ...};`
   + 加到 `97C146F01CF9000F007C117D /* Resources */` 的 `files = (...)` 列表
3. 验证: `flutter build ios --release` → `unzip -l build/ios/iphoneos/Runner.app/Info.plist` + 找 `PrivacyInfo` → 应该看到 `Runner.app/PrivacyInfo.xcprivacy`

### 5.6 评分 (满分 10)

**4/10** — 5 类必填类型完整 + 5 类 Required Reason API 全声明, 但 (1) **.xcprivacy 没注册** (致命, 等于没填) (2) 缺 SensitiveInfo 数据类型 (3) 缺 ActiveKeyboard reason。

---

## 六、Health & Health Research (Guideline 5.1.3)

### 6.1 HealthKit entitlement

- `Runner.entitlements` 空 (无 `com.apple.developer.healthkit` / `com.apple.developer.healthkit.access` / `com.apple.developer.healthkit.background-delivery`) ✓
- 描述 (en) 写 "track your emotional patterns over weeks and months" — **不**写 "sync to Apple Health" / "read from HealthKit"
- en 描述 `WHO IS THIS FOR?` 列 "depression, anxiety, bipolar, PTSD, ADHD, hypertension, diabetes" — hypertension/diabetes 是 Apple Health 健康数据类型, 但**未**声明接入 → 风险: Apple 抽审可能判 "描述暗示医疗监测能力" → 5.1.3 拒

### 6.2 临床健康记录 (Clinical Health Records)

- `Runner.entitlements` 无 `com.apple.developer.healthkit.clinical-records` ✓ (本项目无临床记录)
- 不需要 ASC questionnaire Clinical Health Records 部分

### 6.3 修复方向 (P3, 不阻塞上架)

- 选项 A: 改 en/zh-Hans/zh-Hant 描述 "hypertension, diabetes" 改为 "chronic conditions" (模糊, 不暗示 Health)
- 选项 B: 接 HealthKit (大工程, 见 `docs/audit/2026-08-09/07-apple-health.md` R3 视角, H1/H2/H3/H4 P3)
- **推荐 A** (短期, 1 行 description 改动)

### 6.4 评分 (满分 10)

**9/10** — 无 HealthKit entitlement 正确, 临床记录 0 风险; 唯一扣分是 en 描述暗示医疗监测能力。

---

## 七、Safety (Guideline 1.x)

### 7.1 心理健康 App 免责声明 (Guideline 1.4.1 Physical Harm / Medical)

- **Onboarding 内部** (`setup_step_consent.dart:147-152` 第 5 勾 + `medical_disclaimer.md` 2187 字节 + `showLegalDocument('medical_disclaimer')` 路由) — ✅ R105 验证通过
- **App Store Description 公开层** — ❌ en/zh-Hans/zh-Hant 描述**无 "not a medical device" 字样**
  - en 描述 `IMPORTANT` 段: "ChronicCare is NOT a medical device and does not provide medical advice, diagnosis, or treatment." ✓ (R104 已加)
  - zh-Hans 描述 `重要声明` 段: "本 App 不提供医疗建议、诊断或治疗" ✓
  - zh-Hant 描述 `重要聲明` 段: "本 App 不提供醫療建議、診斷或治療" ✓
  - 3 语都有, 措辞合规 ✓
- **结论**: on-boarding + description 双层声明, 1.4.1 通过

### 7.2 自杀/自残内容限制 (Guideline 1.4 + 1.4.2 User Generated Content)

- `vent_entry_entity` 树洞数据: 用户**自己**输入文字 + 录音, 是 UGC
- 风险: 用户写 "我想自杀" / "想伤害自己" — Apple 1.4.2 要求 App 对此类内容有应对机制
- 当前项目: 无内容审核 / 无 AI 危机检测 / 仅在 crisis hotline 页 + 评估高分区弹危机电话 (高分区弹是 1.4.2 达标, 但 UGC 文本流式未监控)
- 树洞**完全本地**不上传 → 无 UGC 服务端审核义务, 风险低

**修复** (1.4.2 加固):
1. vent_compose_page 在保存时本地关键词扫描 ("自杀" / "想死" / "自我伤害" / "suicide" / "kill myself" 等), 命中弹"你写了一些让我们担心的内容, 是否需要心理援助?" + 一键拨危机热线
2. 加 ARB key 3 语: `ventComposedWarningConcern` / `ventComposedCallHotline`

### 7.3 评分 (满分 10)

**8/10** — 医学免责声明 on-boarding + description 双层 完整, 唯一扣分是 UGC 自杀内容**无**本地关键词预警 (1.4.2 加固, P1)。

---

## 八、Sign in with Apple (Guideline 4.8 + 5.1.1)

- 项目 0 第三方登录 / 0 Apple 账号绑定 / 0 Firebase Auth / 0 自有服务器
- 无 `AuthenticationServices.framework` import / 无 `Sign in with Apple` button
- Guideline 4.8 仅在 "App 用第三方 or 社交登录" 时**强制** Sign in with Apple
- **本项目不触发 4.8** — 零 account, 0 社交登录 ✓
- App Store Review 时 reviewer 不会问 "why no Sign in with Apple"

### 评分: 10/10 ✓

---

## 九、In-App Purchase (Guideline 3.1.x)

- `_prodIapEnabled = false` (`feature_flags.dart:51`) ✓
- `StoreKitService.buyLifetime()` 早返 false ✓
- `profile_group.dart:65` IAP 卡 FeatureFlags 门控, release hidden ✓
- `main.dart:158-161` warmup 跳过 ✓
- 0 个 IAP 入口 (UI 隐藏) ✓
- 3 语 description **未**提 "8 元买断" / "In-App Purchase" / "Subscription" ✓ (R101 改)
- **结论**: 0 IAP = 0 触发 3.1.5(a) 强制 IAP 义务, 现状与 Guideline 3.1 一致

### 评分: 10/10 ✓

---

## 十、其他 Guideline 2.x / 4.x 检查

### 10.1 Guideline 2.3.7 (Categories)

- `LSApplicationCategoryType = healthcare-fitness` (Info.plist:152) ✓
- ASC Primary Category 需对应 "Health & Fitness" 或 "Medical", 上架时人工选

### 10.2 Guideline 2.3.10 (Demo Account)

- 见 2.2 — `notes.txt` 需写 "No account required, all data local"

### 10.3 Guideline 2.5.4 (Background modes)

- 删 `UIBackgroundModes` (R100 A-3) ✓
- 删 `BGTaskSchedulerPermittedIdentifiers` (R100) ✓
- 0 虚假后台声明 ✓

### 10.4 Guideline 3.1.1 (App 内购买)

- 见 九 — 0 IAP ✓

### 10.5 Guideline 3.1.5 (Subscriptions & IAP)

- 见 九 ✓

### 10.6 Guideline 4.0 (Design)

- HIG 大致符合 (4 层架构 + PageTransitionSwitcher 3 类 transition + PressFeedback)
- 启动图占位见 1.4 ✗
- Dynamic Type 0 适配见 3.1 ✗

### 10.7 Guideline 4.8 (Sign in with Apple)

- 见 八 ✓ (不触发)

### 10.8 Guideline 5.1.2 (Data Use)

- 见 四 / 五
- **漏**: SensitiveInfo / ActiveKeyboard 2 项见 5.3 / 5.4

---

## 十一、问题清单 (汇总 ≥ 20 项)

| # | 项 | 文件 | Guideline | 难度 | 优先级 |
|---|----|------|-----------|------|--------|
| **1** | **iOS 截图 24 个目录全 0 文件** (6.7"/6.5"/5.5"/iPad × 3 locale) | `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/iphone_6_7_screenshots/` 等 | 2.3.3 | 中 | **P0** |
| **2** | **`chroniccare.app` 域名未注册** (privacy/support URL 不可达, 必拒) | `fastlane/metadata/ios/*/{privacy_url,support_url}.txt` | 5.1.1 + 2.3.3 | 中 (外部) | **P0** |
| **3** | **PrivacyInfo.xcprivacy 没注册到 Xcode project** (xcodebuild 不打包, Apple 抽审 = 0 manifest) | `ios/Runner.xcodeproj/project.pbxproj` (0 引用 PrivacyInfo) | 5.1.2 (Required Reason 强制) | 简单 | **P0** |
| **4** | **iOS 签名未配置** (`pbxproj` 0 `DEVELOPMENT_TEAM`, 无 `Podfile.lock`) | `ios/Runner.xcodeproj/project.pbxproj` + `ios/Podfile` | (上架阻塞) | 中 (需 macOS) | **P0** |
| **5** | **App Store Age Rating 0 维护** (Medical/Treatment 触发 17+ 问卷, 必填) | `fastlane/metadata/ios/` (无 `age_rating.json` / ASC 问卷) | (上架阻塞) | 中 | **P0** |
| **6** | **法律文档未律师过审** (R82/R83/R101 反复标, 仍未签字) | `assets/legal/{privacy_policy,user_agreement,sensitive_data_consent,medical_disclaimer}.md` | 5.1.1 | 高 (外部) | **P0** |
| **7** | **zh-Hans/zh-Hant 描述 < 实际** (R104 启用 vent 录音, 但描述无录音字样 = 2.1 feature discrepancy 拒) | `fastlane/metadata/ios/zh-{Hans,Hant}/description.txt` | 2.1 | 简单 | **P0** |
| **8** | **`review_information/` 完全缺失** (App Store Review 团队无联系人, 抽审拒因) | `fastlane/metadata/ios/review_information/` (整个目录 0 文件) | 2.3.3 | 简单 | **P0** |
| **9** | **iCloud Backup 排除 0 配置** (SQLCipher db + audio 文件默认 iCloud 备份) | `lib/core/data/database/connection/native.dart:18-22` + `lib/core/data/privacy/encrypted_audio_storage.dart:98-104` | 5.1.1 | 中 | **P1** |
| **10** | **Dynamic Type 0 适配** (275 处 `fontSize:` 硬编码, 0 `textScaler` 调用) | 81 个文件 | 2.5.1 | 中 | **P1** |
| **11** | **锁屏通知暴露药名+剂量** (精神心理 App, 病耻感 + 5.1.1 双风险) | `lib/core/l10n/strings.dart:103-119` + `medication_notifier.dart:134-135` + `refill_notifier.dart:161-162` | 5.1.1 | 中 | **P1** |
| **12** | **邮件通知暴露药名+剂量** (`EmailService` 模板敏感 PII) | `lib/core/data/services/email_service.dart` (模板字符串) | 5.1.1 | 中 | **P1** |
| **13** | **Vent UGC 文本自杀/自残关键词 0 本地预警** (1.4.2 UGC 加固) | `lib/presentation/pages/vent/vent_compose_page.dart` | 1.4.2 | 中 | **P1** |
| **14** | **`Runner.entitlements` 中文注释 mojibake** (Windows GBK 编码, xcodebuild macOS 上可能解析异常) | `ios/Runner/Runner.entitlements` (注释 "鍒? aps-environment" 等乱码) | (上架阻塞 — 编码风险) | 简单 | **P1** |
| **15** | **Podfile `platform :ios, '13.0'` vs pbxproj `IPHONEOS_DEPLOYMENT_TARGET = 14.0` 不一致** (R105 A15 P3) | `ios/Podfile:22` vs `project.pbxproj:372/499/550` | 2.5.1 | 简单 | **P1** |
| **16** | **PrivacyInfo 缺 `NSPrivacyCollectedDataTypeSensitiveInfo`** (PHQ-9 / GAD-7 属 Sensitive) | `ios/Runner/PrivacyInfo.xcprivacy` | 5.1.2 | 简单 | **P1** |
| **17** | **PrivacyInfo 缺 `NSPrivacyAccessedAPICategoryActiveKeyboard` (E620.1)** (大量 TextField 触发键盘事件) | `ios/Runner/PrivacyInfo.xcprivacy` | 5.1.2 | 简单 | **P1** |
| **18** | **`safetyCheckResultAlertedMocked` 3 语 mock/dev 字符串残留** (R104 标 HIGH, R105 降 P2) | `l10n/app_{zh,en,zh_Hant}.arb` `safetyCheckResultAlertedMocked` key | 1.4.1 (误导) | 简单 | **P1** |
| **19** | **App Store Connect App Privacy 表单 0 维护** (12 大类需手填) | (ASC 后台, 非文件) | 5.1.1 | 简单 (人工) | **P1** |
| **20** | **`AppIcon.appiconset` 18 个 PNG 共占位 2026-04** (10932 bytes for 1024×1024, 默认 Flutter 渐变, 仍属占位) | `ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png` | 4.0 Design | 中 | **P1** |
| **21** | **`fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/` 全 3 套 locale 缺 `app_icon.png`** (ASC 期望 metadata/icon.png 也提供) | `fastlane/metadata/ios/*/app_icon.png` | 2.3.x | 简单 | **P1** |
| **22** | **`en-US/description.txt` 列 "hypertension, diabetes" 暗示医疗监测** (5.1.3 拒) | `fastlane/metadata/ios/en-US/description.txt:27` | 5.1.3 | 简单 | **P2** |
| **23** | **`LaunchImage.imageset/` 3 张 PNG 全 68 字节空白** (iPhone 16 Pro Max 启动闪白) | `ios/Runner/Assets.xcassets/LaunchImage.imageset/*.png` | 2.5.4 | 简单 | **P2** |
| **24** | **`fastlane/Appfile:27-29` 仍 TODO 占位** (APPLE_ID / TEAM_ID / ITC_TEAM_ID 需 ENV 注入) | `fastlane/Appfile` | (上架阻塞 — 非 file 即 fetch 不到) | 简单 (需 ENV) | **P2** |
| **25** | **desc R104 启 vent 录音但 metadata en/zh-Hant 描述无录音** (重复 #7, 列入) | (重复) | 2.1 | — | — |
| **26** | **主页 hero + 录音按钮在 iPhone 16 Pro Max 6.7" 折叠线以下** (R104 emil E3) | `lib/presentation/pages/home/home_page.dart` | HIG (4.0) | 中 | **P3** |

---

## 十二、整体评分

| 维度 | R105 | 本次 (R106) | 变化 | 满分 |
|------|------|-------------|------|------|
| App Completeness (2.1) | 5.5 | 2 | ⬇ 3.5 | 10 |
| Metadata (2.3) | 6 | 5 | ⬇ 1 | 10 |
| Software Requirements (2.5) | 5.5 | 4 | ⬇ 1.5 | 10 |
| Privacy (5.1.1) | 6 | 5 | ⬇ 1 | 10 |
| Privacy Manifest (5.1.2) | 5 | 4 | ⬇ 1 | 10 |
| Health (5.1.3) | 9 | 9 | — | 10 |
| Safety (1.x) | 8 | 8 | — | 10 |
| Sign in with Apple (4.8) | 10 | 10 | — | 10 |
| In-App Purchase (3.1.x) | 10 | 10 | — | 10 |
| **加权平均** | **6.0** | **5.8** | **⬇ 0.2** | **10** |

---

## 十三、与 R105 差异

### 已修 (R105 报告 vs R106 实际)

| # | R105 报告项 | 实际状态 | 验证 |
|---|-------------|----------|------|
| 1 | A11 medical disclaimer 进 onboarding | ✅ 验证通过 | `setup_step_consent.dart:147-152` 5 checkbox, `assets/legal/medical_disclaimer.md` 2187B, `showLegalDocument('medical_disclaimer')` 路由 OK |
| 2 | A12 user_agreement 8 元买断删除 | ✅ 验证通过 | `assets/legal/user_agreement.md:19-22` "当前版本免费, 无任何购买入口" |
| 3 | A13 store description 删 (失联通知规划中) | ✅ 验证通过 | en/zh-Hans/zh-Hant 3 语 description 0 匹配 "规划中" / "规划" |
| 4 | A1 mic/speech 权限描述恢复 | ✅ 验证通过 | `Info.plist` 3 语 `InfoPlist.strings` 4 个权限键齐全 |

### 新发现 (本审计 R106)

| # | 项 | 严重度 | 验证 |
|---|----|--------|------|
| N1 | **PrivacyInfo.xcprivacy 没注册到 Xcode project** | P0 (致命) | `grep "PrivacyInfo|xcprivacy"` 在 `project.pbxproj` 0 匹配 |
| N2 | Runner.entitlements 中文注释 mojibake | P1 | Read 工具读出乱码 "鍒? aps-environment" (GBK 编码) |
| N3 | Podfile `platform :ios, '13.0'` vs pbxproj 14.0 不一致 | P1 | 实际验证 (R105 标 P3, 本审计升 P1) |
| N4 | PrivacyInfo 缺 SensitiveInfo 数据类型 | P1 | PHQ-9 / GAD-7 属 Sensitive, Apple 模板要求单独列 |
| N5 | PrivacyInfo 缺 ActiveKeyboard reason E620.1 | P1 | 大量 TextField 触发键盘事件, Required Reason 必查 |
| N6 | `en-US/description.txt` 暗示医疗监测 (hypertension/diabetes) | P2 | Apple 5.1.3 拒 |
| N7 | `AppIcon.appiconset` 18 PNG 仍占位 (2026-04 默认) | P1 | 10932 bytes for 1024×1024, 远低于真实 ≥ 50KB |
| N8 | `fastlane/metadata/ios/*/app_icon.png` 缺失 | P1 | ASC 期望 metadata/icon.png 也提供 |
| N9 | `fastlane/metadata/ios/review_information/` 完全缺失 | P0 | 整个目录 0 文件 |
| N10 | Vent UGC 自杀关键词 0 本地预警 (1.4.2 加固) | P1 | 树洞是 UGC, Apple 1.4.2 要求应对机制 |

### 持续未修 (R103 / R104 / R105 反复标)

| # | 项 | 优先级 | 状态 |
|---|----|--------|------|
| O1 | iOS 24 个截图目录全 0 文件 | **P0** | 标 3 round 未动 |
| O2 | `chroniccare.app` 域名未注册 | **P0** | 标 4 round 未动 (外部依赖) |
| O3 | iOS 签名 / `DEVELOPMENT_TEAM` / `Podfile.lock` | **P0** | 标 3 round 未动 (需 macOS) |
| O4 | Age Rating 0 维护 | **P0** | 标 3 round 未动 (需人工 ASC) |
| O5 | 法律文档未律师过审 | **P0** | 标 4 round 未动 (外部依赖, ¥¥¥) |
| O6 | iCloud Backup 排除 0 配置 | P1 | 标 2 round 未动 |
| O7 | Dynamic Type 0 适配 | P1 | 标 2 round 未动 |
| O8 | 锁屏通知暴露药名+剂量 | P1 | 标 2 round 未动 |
| O9 | `safetyCheckResultAlertedMocked` 3 语 mock/dev 字符串 | P1 (R104 标 HIGH) | 标 3 round 未动 |
| O10 | zh-Hans/zh-Hant 描述 < 实际 (录音功能描述缺失) | **P0** | R105 标 P2, 本审计升 P0 |

---

## 十四、上架就绪度结论

**当前 v0.30.0+85 不满足 Apple App Store 上架最低要求**。

### 致命阻塞 (P0, 9 项, 全部 Apple 必拒)

1. iOS 截图 24 个目录全 0 文件 → 2.3.3
2. 域名未注册 → 5.1.1 + 2.3.3
3. **PrivacyInfo.xcprivacy 没注册 Xcode project** → 5.1.2 (致命, R61 写文件 ≠ 实际生效)
4. iOS 签名 / Podfile.lock 缺失 → 上架阻塞
5. Age Rating 0 维护 → 上架阻塞
6. 法律文档未过审 → 5.1.1
7. zh-Hans/zh-Hant 描述 < 实际 → 2.1
8. `review_information/` 0 文件 → 2.3.3
9. iCloud Backup 排除 + 锁屏通知脱敏 + Dynamic Type 0 适配 → 5.1.1 + 2.5.1

### 修复 Sprint 推荐 (1-2 周)

**Sprint A (1 周)**:
- D1: 注册 `chroniccare.app` + 部署 4 HTML (外部, 1-2 天 + 7-20 天 ICP 备案)
- D2: macOS 截 33 张真机图 (2 天)
- D3: 注册 `PrivacyInfo.xcprivacy` 到 `project.pbxproj` (10 min)
- D4: 修 Runner.entitlements mojibake (5 min) + Podfile 平台对齐 14.0 (1 min)
- D5: 补 `review_information/` 6 文件 (10 min)
- D6: 改 zh-Hans/zh-Hant description 加 "语音笔记本地加密" (10 min)

**Sprint B (1 周)**:
- D7: 法务过审 3 份 md (外部, ¥¥¥)
- D8: macOS `pod install` + Xcode 配置 DEVELOPMENT_TEAM (1h)
- D9: ASC 填 Age Rating 17+ 问卷 + App Privacy 12 类 (1h)
- D10: Dynamic Type 适配 (改造 `app_typography.dart` + 替 275 处 `fontSize:`) (2-3 天)
- D11: iCloud Backup MethodChannel 排除 (1 天)
- D12: 锁屏通知脱敏 (改 `l10n/strings.dart:103-119` 模板 + iOS `UNNotificationContent.threadIdentifier`) (1 天)

**Sprint C (1 周, nice-to-have)**:
- D13: VoiceOver / Semantics 完善 (2-3 天)
- D14: Vent UGC 自杀关键词预警 (1 天)
- D15: AppIcon 重新设计 (1 天)
- D16: en 描述 "hypertension/diabetes" → "chronic conditions" (5 min)
- D17: PrivacyInfo 补 SensitiveInfo + ActiveKeyboard (15 min)

### R107 期望

完成 Sprint A + B 后, 评分回升至 **7.5/10**, 达到 "可提交但需审慎 review" 状态。
完成 Sprint A + B + C 后, 评分 **8.5-9.0/10**, 达到 "高概率一次过 review" 状态。

---

**报告完**。
