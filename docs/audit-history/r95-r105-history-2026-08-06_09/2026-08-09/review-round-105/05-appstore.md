# AppStore 视角报告 (R105, 2026-08-09)

**评分**: 6.0/10 (R104 6.5/10, 净降 0.5)
**基线**: R104 (2026-08-09) 00-summary + 05-appstore
**范围**: 未提交 batch 的 iOS 相关改动 (`feature_flags.dart` / `Info.plist` / `InfoPlist.strings` 3 语 / `fastlane/metadata/ios` / `assets/legal` / `AndroidManifest.xml`) + R104 未动项复查
**方式**: 逐文件 diff + 运行时 URL/权限可达性验证

---

## 核心结论

**本批次存在一处致命自相矛盾**: `feature_flags.dart:70` 把 `_prodVentAudioEnabled` 从 `false` 翻成 `true`（R104 注释"启用语音录制"），但**同一批次**把 `NSMicrophoneUsageDescription` + `NSSpeechRecognitionUsageDescription` 从 `Info.plist` 和 3 个 `InfoPlist.strings` 全删了（R102/R103 注释"因为 ventAudioEnabled=false"）。两侧的改动是**同一个 uncommitted batch**，互相矛盾：

1. **iOS**: 录音 UI 重新可见（`vent_compose_page.dart:455` + `mood_recorder_page.dart:375` 走 flag gate），但权限描述缺失 → 用户点录音 = **运行时 crash**（iOS 隐私 API 无 usage description 直接杀进程）+ App Store 2.5.1 拒因。
2. **Android**: 同一批次在 `AndroidManifest.xml:51` 用 `tools:node="remove"` 删掉 `RECORD_AUDIO`（注释写"ventAudioEnabled=false"）→ 录音 `SecurityException`。
3. **测试套件**: 3 个 test 仍断言默认 false（未同步）→ `flutter test` 必红。

R104 已修复的 4 项（A1/A7/A8/A9）确实落地，但被 2 个新 P0 regression + 1 个新 P1 文档矛盾对冲。

---

## 问题表

| 编号 | 问题 | 文件:行 | 架构/底层 | 难度 | 优先级 | 建议 |
|------|------|---------|-----------|------|--------|------|
| A1 | **批次自相矛盾**: `_prodVentAudioEnabled=true` 但同批删除 iOS mic/speech 权限描述 → iOS 录音 crash + Apple 2.5.1 拒（used-but-not-declared） | `feature_flags.dart:70` vs `Info.plist` R102/R103 注释块 / `InfoPlist.strings` 3 语 | 底层/权限 | 简单 | **P0** | 二选一: ①回滚 flag 回 `false`; ②重加 `NSMicrophoneUsageDescription` + `NSSpeechRecognitionUsageDescription`（英文基线 + zh-Hans/zh-Hant 覆盖） |
| A2 | Android 同批 `tools:node="remove"` 删 `RECORD_AUDIO`, 但 flag=true → Android 录音 SecurityException | `android/app/src/main/AndroidManifest.xml:51` vs `feature_flags.dart:70` | 底层/权限 | 简单 | **P0** | 跟 A1 同一决策, 恢复 `RECORD_AUDIO` 或回滚 flag |
| A3 | 3 个 test 断言 ventAudio 默认 false, 批次未同步 → `flutter test` 必红（CI regression） | `test/core/data/feature_flags_round93_test.dart:61-64`（未改）; `vent_compose_page_r93_hide_test.dart:21`; `mood_recorder_page_r93_hide_test.dart:82-94` | CI | 简单 | **P0** | flag 定型后同步测试期望; 或新增 `_prodVentAudioEnabled=false` 保默认 |
| A4 | `privacy_policy.md` §0.6 仍写"vent+mood 录音业务暂停/UI 完全 hidden", 与 flag=true 矛盾 → 隐私政策不准确（5.1.1 要求 policy 与实际处理一致） | `assets/legal/privacy_policy.md:40` | 文档/法务 | 简单 | P1 | flag 定型后同步 §0.6（录音已启用则删该行, 或写"录音本地加密存储"） |
| A5 | 锁屏通知暴露药名+剂量（精神健康敏感信息, 5.1.1 + health data 审查） | `lib/core/l10n/strings.dart:103-119`（`💊 该吃药了：$medName` + `$dosage$unit`）; `medication_notifier.dart:134-135`; `refill_notifier.dart:161-162` | 隐私 | 中 | P1 | 通知 body 脱敏（"到吃药时间了"）, 或 iOS 走 `DarwinNotificationDetails` 不展示预览; 精神心理用药对第三人可见=病耻感风险 |
| A6 | `chroniccare.app` 域名未注册（实测 HTTPS 不可达）; privacy/support URL 指向未注册域名 → 审核时 Support URL 必须可达（必拒） | `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/privacy_url.txt` + `support_url.txt` | 外部 | 中 | **P0** | 注册域名 + HTTPS 部署 4 份页面（见 `STOREFRONT_RELEASE_SOP.md` #1） |
| A7 | iOS 签名未配置（pbxproj 无 `DEVELOPMENT_TEAM`, 无 `Podfile.lock`） | `ios/Runner.xcodeproj/project.pbxproj` | 底层 | 中 | **P0** | macOS + `pod install` + Xcode Team 配置（需真机/账号） |
| A8 | iOS 真实截图缺失（`fastlane/metadata/ios/*/screenshots/` 无目录） | `fastlane/metadata/ios/` | 素材 | 中 | **P0** | 按 SOP 截 33 张真实截图（2.3.3） |
| A9 | 法律文档仍未律师审核; 且批次把修订历史"草稿(未经律师过审)"改成"初版/定稿", privacy_policy 还删了 `v0.28+ TODO 律师过审` 行 → 有"假装已过审"的误导风险 | `assets/legal/privacy_policy.md` 修订历史; `user_agreement.md`; `sensitive_data_consent.md` | 法务 | 高 | **P0** | 律师过审后再标"定稿"; 过审前恢复"草稿/待审"标记 |
| A10 | 内容评级（Apple Age Rating）未配置（fastlane 无 age_rating 文件, 需人工问卷） | `fastlane/metadata/ios/` | 配置 | 中 | **P0** | App Store Connect 填 17+（Medical/Treatment Information）问卷 |
| A11 | **已修复** (R104→now): 医疗免责声明进 onboarding（`setup_step_consent.dart:147-152` checkbox + `medical_disclaimer.md` 资产 + `showLegalDocument('medical_disclaimer')`） | `setup_step_consent.dart` / `pubspec.yaml:97` | 底层 | — | 已修复 | — |
| A12 | **已修复** (R104→now): `user_agreement.md` "8 元买断" → "当前版本免费, 无任何购买入口...不收取订阅费"（3.1.1 对齐） | `assets/legal/user_agreement.md:19-22` | 文档 | — | 已修复 | — |
| A13 | **已修复** (R104→now): Store description 删除失联通知/SMS/语音/"(失联通知规划中)" 等禁用功能描述（2.1 / 2.3.1） | `fastlane/metadata/ios/*/description.txt` | 素材 | — | 已修复 | — |
| A14 | 残留: `safetyCheckResultAlertedMocked` mock/dev 字符串仍在 3 语 ARB（release 不可达, 因安全流程 flag 关闭, 低风险但 R104 标 HIGH） | `app_zh.arb:1381` / `app_en.arb:1320` / `app_zh_Hant.arb:1359` | i18n | 简单 | P2 | flag 定型后清理（或保留但确认不可达） |
| A15 | Podfile `platform :ios, '13.0'` vs pbxproj `IPHONEOS_DEPLOYMENT_TARGET = 14.0` 不一致 | `ios/Podfile:22` vs `project.pbxproj` | 配置 | 简单 | P3 | 统一到 14.0 |
| A16 | Store description 移除了录音功能描述, 但 flag=true 后 App 实际有录音 → 描述低于实际（非拒因, 但需对齐） | `fastlane/metadata/ios/*/description.txt` | 素材 | 简单 | P2 | flag 定型后把录音重新写回描述或保持文本-only 定位 |

---

## 验证通过项（无问题）

| 检查项 | 状态 | 说明 |
|--------|------|------|
| IAP gating | ✅ | `iapEnabled=false`; `profile_group.dart:65` Pro 卡 `if (FeatureFlags.iapEnabled)`; `buyLifetime()` 早返 false; `main.dart:158` warmup 跳过 → release 无任何购买 UI |
| 外部链接 runtime | ✅ | 运行时代码 0 http(s); `url_launcher` 仅 `tel:` 危机热线（合法 scheme）; 描述里 findahelpline.com 是 store 元数据非 runtime |
| HealthKit | ✅ | `Runner.entitlements` 空（无 HealthKit）; `docs/specs/medication-redesign-apple-health.md` 是**UI 设计参考**非 HealthKit 集成 claim → 无虚假声明; 不上 HealthKit 不需要 questionnaire 补交 |
| PrivacyInfo.xcprivacy | ✅ | 存在, 5 类 required-reason API（UserDefaults CA92.1/92.2, FileTimestamp C617.1, SystemBootTime 35F9.1, DiskSpace 85F4.1, ProcessInfo AC67.1）; 声明 AudioData 收集与实际（录音已启用）一致 |
| Bundle id / 版本 | ✅ | `com.chroniccare.chroniccare` 与 SOP 一致; `CFBundleShortVersionString=$(FLUTTER_BUILD_NAME)` = 0.30.0, `CFBundleVersion=$(FLUTTER_BUILD_NUMBER)` = 85, 与 pubspec 0.30.0+85 一致 |
| 权限声明一致性 | ✅ | 保留的 2 项（NSPhotoLibraryAdd/Usage）对应 share_plus PDF 保存, 真实使用; 无 declared-but-unused（除 A1 反向问题） |
| UIBackgroundModes / BGTask | ✅ | 已删（R100 A-3）, 无假后台声明 |
| aps-environment | ✅ | 已从 entitlements 删除, 无 APNs 虚假声明 |
| 展示名本地化 | ✅ | `CFBundleDisplayName` Base=en + zh-Hans/Hant "慢病管家" per-locale 覆盖 |

---

## 评分说明

- **加分**: A11/A12/A13 三个 R104 P0 真实闭环; IAP/HealthKit/隐私清单核对无新增问题。
- **扣分**: 批次内部自相矛盾（A1/A2）是最严重问题——等于"把已删的权限又翻回来了但没把权限声明加回来", 同时导致 `flutter test` 红（A3）; privacy_policy 与代码矛盾（A4）; 法律文档改标"定稿"而未过审（A9 部分）。
- 净变化: 6.5 → 6.0（修了 3 项但引入 2 项新 P0 + 1 项新 P1）。

## 给下一 round 的 3 个必做

1. **A1/A2/A3 一个决策**: 确认 R104 是否真要启用 vent 录音。要启用 → 恢复 iOS mic/speech 权限描述（3 语）+ Android RECORD_AUDIO + 同步 3 个 test + 更新 privacy_policy §0.6。不启用 → `feature_flags.dart:70` 回滚 `false`, 保留本批权限删除。**目前状态既报崩溃又报测试红, 不能提交**。
2. **A6 域名**: 不注册 `chroniccare.app`, 任何上架流程 100% 阻塞（support/privacy URL 不可达）。
3. **A5 锁屏通知脱敏**: 精神心理用药场景, 药名+剂量上锁屏是病耻感 + 5.1.1 双重风险, 优先级高于 A8 截图。
